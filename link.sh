#!/usr/bin/env bash
#
# link.sh — symlinks the dotfiles packages into $HOME.
#
# No external dependencies. The directory layout matches GNU Stow exactly, so if
# you prefer you can do the same job with "stow -t ~ shell hypr ..."; this script
# only exists so that stow does not have to be installed.
#
# Usage:
#   ./link.sh                      link the default profile
#   ./link.sh -n                   show what it would do, touch nothing (dry-run)
#   ./link.sh -f                   back up conflicting real files and link over them
#   ./link.sh link gtk fish        link specific packages
#   ./link.sh profile              list the profiles
#   ./link.sh profile niri         link the packages of a profile
#   ./link.sh unlink [package...]  remove the symlinks pointing at this repo
#   ./link.sh status [package...]  which package is linked, which is not
#   ./link.sh adopt <package>      pull the real files from $HOME into the repo (CAUTION: overwrites repo content)
#   ./link.sh adopt <package> <path>  move a new file from $HOME into the package

set -uo pipefail

DOTFILES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${TARGET:-$HOME}"

# Packages wanted in every install, independent of the compositor.
#
# kdeglobals is its own package rather than part of `theme` because it is the
# one file in there something else may want to take over: it is where Qt apps
# read their palette from, so anything that colours the desktop from the
# wallpaper writes it. Kept separable, it can be unlinked on its own.
#
# `wallpapers` is separate from `theme` for a plainer reason: it is 27 MB of
# photographs and `theme` is a handful of text files. The StarrySky image is NOT in it:
# that one has to be real inside its KPackage directory, so it stays in `theme`
# and the copy here is a symlink to it, the same way extras/backgrounds does.
COMMON_PACKAGES="shell terminal nvim vscode cli scripts services theme wallpapers kdeglobals git xdg"

# Profiles: package sets per desktop environment.
declare -A PROFILES=(
    [hyprland]="$COMMON_PACKAGES hypr desktop"
    [niri]="$COMMON_PACKAGES niri desktop"
    [kde]="$COMMON_PACKAGES"
)
DEFAULT_PROFILE="${DOTFILES_PROFILE:-hyprland}"

# Packages in no profile at all, to be asked for by hand (reason in the README).
EXTRA_PACKAGES=(fish gtk)

# Directories linked as a whole instead of file by file, as paths relative to
# $HOME. KPackage — what Plasma reads a global theme or a wallpaper out of —
# refuses every file whose canonical path leaves the package directory, and a
# per-file symlink always resolves back into the repo. It refuses them without a
# word: the global theme is selected, its `defaults` is never read, and Plasma
# falls back to stock *light* Breeze. One symlink for the package root keeps
# every file inside it. Nothing under these paths may be a symlink either.
LINK_AS_DIR=(
    .local/share/plasma/look-and-feel/my-dotfiles
    .local/share/wallpapers/StarrySky
)

DRY=0
FORCE=0
STAMP="$(date +%Y%m%d-%H%M%S)"

# Paths a dry run said it would unlink. A real run has deleted them by the time
# the next thing is linked over them; a dry run has not, so without remembering
# them here a file that is unlinked and then linked again in the same run would
# preview as a conflict that will never happen.
declare -A DRY_REMOVED=()

RED=$'\e[31m'; GRN=$'\e[32m'; YLW=$'\e[33m'; CYN=$'\e[36m'; DIM=$'\e[2m'; RST=$'\e[0m'

die()  { printf '%s✘ %s%s\n' "$RED" "$*" "$RST" >&2; exit 1; }
warn() { printf '%s! %s%s\n' "$YLW" "$*" "$RST" >&2; }
ok()   { printf '%s✔%s %s\n' "$GRN" "$RST" "$*"; }
dim()  { printf '%s  %s%s\n' "$DIM" "$*" "$RST"; }

# Prints the header comment block: every line from 2 up to the first
# non-comment line. Line-number ranges went stale whenever the header changed.
usage() { awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "${BASH_SOURCE[0]}"; }

# Lists every file inside a package as a path relative to $HOME.
# Not directories, only files and symlinks; directories in the target are
# created as needed. This way local files that are not in the repo
# (e.g. ~/.config/btop/btop.conf) are left untouched. The exception is
# LINK_AS_DIR: such a directory is printed as itself and not descended into, so
# the rest of the script links it with a single symlink.
pkg_files() {
    local pkg="$1" d
    local -a whole=()
    [ -d "$DOTFILES/$pkg" ] || die "no such package: $pkg"
    for d in "${LINK_AS_DIR[@]}"; do
        [ -d "$DOTFILES/$pkg/$d" ] || continue
        whole+=(-path "$DOTFILES/$pkg/$d" -prune -printf '%P\n' -o)
    done
    find "$DOTFILES/$pkg" -mindepth 1 "${whole[@]+"${whole[@]}"}" \
        \( -type f -o -type l \) -printf '%P\n' | sort
}

# Everything `status` walks when it is given no arguments. The exclusions are the
# directories that are not packages: nothing in them is meant to reach $HOME as a
# symlink, and listing them as "not linked" reads as a package someone forgot.
all_packages() {
    find "$DOTFILES" -mindepth 1 -maxdepth 1 -type d -printf '%P\n' \
        | grep -vE '^(\.git|\.github|extras|programs)$' | sort
}

resolve_packages() {
    if [ "$#" -gt 0 ]; then
        printf '%s\n' "$@"
    else
        printf '%s\n' ${PROFILES[$DEFAULT_PROFILE]}
    fi
}

# A compositor rewrites its own example config the moment the real one goes
# missing — which is what unlinking leaves behind until the next link puts the
# real one back. The file that appears is not the user's work and says so in its
# first lines, so it is cleared instead of being reported as a conflict that
# stops the link.
#
# Hyprland 0.56 reads hyprland.lua in preference to hyprland.conf and generates
# a stub for whichever it was looking for, under a header of its own wording
# ("-- AUTOGENERATED HYPRLAND CONFIG"). That one matters more than the .conf
# stub ever did: lua wins, so a stub left at ~/.config/hypr/hyprland.lua
# shadows this repo's hyprland.conf completely and the desktop comes up as bare
# Hyprland with no explanation.
is_generated_stub() {
    [ -f "$1" ] && head -n 5 "$1" 2>/dev/null \
        | grep -qiE "config is a STUB|autogenerated (hyprland )?config"
}

# Links one file. src is absolute, rel is relative to $TARGET, and own is the
# directory tree the caller owns — a symlink already pointing inside it is ours
# to refresh, anything else is the user's and is left alone unless -f.
# Returns 0 linked, 1 already correct, 2 conflict.
link_one() {
    local src="$1" rel="$2" own="$3" dst="$TARGET/$2" cur

    # Already reported as unlinked earlier in this same dry run: the path is
    # free as far as the preview is concerned.
    if [ "$DRY" -eq 1 ] && [ -n "${DRY_REMOVED[$rel]+x}" ]; then
        dim "will link  ~/${rel}"
        return 0
    fi

    if [ -L "$dst" ]; then
        cur="$(readlink "$dst")"
        [ "$cur" = "$src" ] && return 1
        case "$cur" in
            "$own"/*)        # an old path inside the same tree, safe to refresh
                [ "$DRY" -eq 1 ] || { rm -f "$dst" && ln -s "$src" "$dst"; }
                dim "refreshed  ~/${rel}"; return 0 ;;
            *)               # points somewhere else — another checkout, or the user's own
                if [ "$FORCE" -eq 1 ]; then
                    [ "$DRY" -eq 1 ] || { rm -f "$dst" && ln -s "$src" "$dst"; }
                    warn "foreign symlink replaced  ~/${rel}"; return 0
                fi
                warn "CONFLICT (symlink → $cur)  ~/${rel}"; return 2 ;;
        esac
    fi

    if [ -e "$dst" ] && [ ! -L "$dst" ] && is_generated_stub "$dst"; then
        # Linked over in one step rather than removed first: the compositor
        # rewrites this file the instant it disappears, and it wins that race —
        # removing it and then creating the link finds a fresh stub in between.
        if [ "$DRY" -eq 1 ]; then
            dim "will replace compositor stub  ~/${rel}"
        else
            mkdir -p "$(dirname "$dst")"
            ln -sfn "$src" "$dst" || { warn "could not link: ~/${rel}"; return 2; }
            dim "replaced compositor stub  ~/${rel}"
        fi
        return 0
    fi

    if [ -e "$dst" ]; then
        if [ "$FORCE" -eq 1 ]; then
            [ "$DRY" -eq 1 ] || mv "$dst" "$dst.bak.$STAMP"
            warn "backed up  ~/${rel}.bak.$STAMP"
        else
            warn "CONFLICT (real file; back it up with -f, pull it into the repo with adopt)  ~/${rel}"
            return 2
        fi
    fi

    if [ "$DRY" -eq 1 ]; then
        dim "will link  ~/${rel}"
    else
        mkdir -p "$(dirname "$dst")" || { warn "could not create directory: $(dirname "$dst")"; return 2; }
        ln -s "$src" "$dst" || { warn "could not link: ~/${rel}"; return 2; }
    fi
    return 0
}

link_pkg() {
    local pkg="$1" rel n_ok=0 n_new=0 n_conf=0
    # pkg_files reads in a process substitution, so its `die` only ever kills
    # that subshell: without this the caller went on to report 0 new, 0 linked
    # and a clean exit for a package that does not exist.
    [ -d "$DOTFILES/$pkg" ] || { warn "no such package: $pkg"; return 1; }

    while IFS= read -r rel; do
        link_one "$DOTFILES/$pkg/$rel" "$rel" "$DOTFILES"
        case "$?" in
            0) n_new=$((n_new + 1)) ;;
            1) n_ok=$((n_ok + 1)) ;;
            *) n_conf=$((n_conf + 1)) ;;
        esac
    done < <(pkg_files "$pkg")

    if [ "$n_conf" -gt 0 ]; then
        printf '%s✘%s %-10s %d new, %d already linked, %s%d conflicts%s\n' \
            "$RED" "$RST" "$pkg" "$n_new" "$n_ok" "$RED" "$n_conf" "$RST"
        return 1
    fi
    ok "$(printf '%-10s %d new, %d already linked' "$pkg" "$n_new" "$n_ok")"
    return 0
}

unlink_pkg() {
    local pkg="$1" rel dst n=0
    [ -d "$DOTFILES/$pkg" ] || { warn "no such package: $pkg"; return 1; }
    while IFS= read -r rel; do
        dst="$TARGET/$rel"
        # Only remove symlinks pointing at this repo; leave real files alone.
        if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$DOTFILES/$pkg/$rel" ]; then
            if [ "$DRY" -eq 1 ]; then DRY_REMOVED["$rel"]=1; else rm -f "$dst"; fi
            n=$((n + 1))
        fi
    done < <(pkg_files "$pkg")
    ok "$(printf '%-10s %d symlinks removed' "$pkg" "$n")"
}

status_pkg() {
    local pkg="$1" rel dst n_ok=0 n_miss=0 n_conf=0
    [ -d "$DOTFILES/$pkg" ] || { warn "no such package: $pkg"; return 1; }
    while IFS= read -r rel; do
        dst="$TARGET/$rel"
        if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$DOTFILES/$pkg/$rel" ]; then
            n_ok=$((n_ok + 1))
        elif [ -e "$dst" ] || [ -L "$dst" ]; then
            n_conf=$((n_conf + 1))
        else
            n_miss=$((n_miss + 1))
        fi
    done < <(pkg_files "$pkg")

    local mark color
    if   [ "$n_conf" -gt 0 ];                       then mark="conflict";   color="$RED"
    elif [ "$n_miss" -gt 0 ] && [ "$n_ok" -gt 0 ];  then mark="partial";    color="$YLW"
    elif [ "$n_miss" -gt 0 ];                       then mark="not linked"; color="$DIM"
    else                                                 mark="linked";     color="$GRN"
    fi
    printf '%s%-12s%s %-12s (%d linked, %d missing, %d conflicts)\n' \
        "$color" "$pkg" "$RST" "$mark" "$n_ok" "$n_miss" "$n_conf"
}

# ─── adopt ───────────────────────────────────────────────────────────────────
# Form 1: adopt <package>
#   For files the package already contains, moves the REAL file from $HOME into
#   the repo and puts a symlink in its place. Repo content is OVERWRITTEN —
#   check its state with git first.
adopt_pkg() {
    local pkg="$1" rel src dst n=0
    while IFS= read -r rel; do
        src="$DOTFILES/$pkg/$rel"
        dst="$TARGET/$rel"
        [ -e "$dst" ] && [ ! -L "$dst" ] || continue   # real files only
        if [ "$DRY" -eq 1 ]; then
            dim "adopt  ~/${rel}  →  $pkg/$rel"
        else
            mv -f "$dst" "$src" || { warn "could not move: ~/${rel}"; continue; }
            ln -s "$src" "$dst" || { warn "could not link: ~/${rel}"; continue; }
            dim "adopt  ~/${rel}"
        fi
        n=$((n + 1))
    done < <(pkg_files "$pkg")
    ok "$(printf '%-10s %d files pulled into the repo' "$pkg" "$n")"
    [ "$n" -gt 0 ] && [ "$DRY" -eq 0 ] && warn "repo content changed — check it with 'git diff'."
    return 0
}

# Form 2: adopt <package> <home-path>...
#   Moves a file that is not yet in the repo into the package. For writing the
#   niri/fish config in $HOME first and then pulling it into the repo.
adopt_paths() {
    local pkg="$1"; shift
    local p abs rel src
    [ -d "$DOTFILES/$pkg" ] || { mkdir -p "$DOTFILES/$pkg"; dim "new package created: $pkg"; }

    for p in "$@"; do
        abs="$(cd -- "$(dirname -- "$p")" 2>/dev/null && printf '%s/%s' "$(pwd)" "$(basename -- "$p")")" \
            || { warn "could not resolve path: $p"; continue; }
        [ -e "$abs" ] || { warn "no such file: $p"; continue; }
        [ -L "$abs" ] && { warn "already a symlink, skipped: $p"; continue; }
        [ -d "$abs" ] && { warn "directories not accepted, pass a file: $p"; continue; }

        case "$abs" in
            "$TARGET"/*) rel="${abs#"$TARGET"/}" ;;
            *) warn "outside \$HOME, skipped: $p"; continue ;;
        esac

        src="$DOTFILES/$pkg/$rel"
        if [ "$DRY" -eq 1 ]; then
            dim "adopt  ~/${rel}  →  $pkg/$rel"
            continue
        fi
        mkdir -p "$(dirname "$src")"
        mv -f "$abs" "$src" || { warn "could not move: $p"; continue; }
        ln -s "$src" "$abs" || { warn "could not link: $p"; continue; }
        ok "$pkg/$rel  ←  ~/${rel}"
    done
}

# ─── profile ─────────────────────────────────────────────────────────────────
list_profiles() {
    printf '%sProfiles%s  (default: %s%s%s)\n\n' "$CYN" "$RST" "$GRN" "$DEFAULT_PROFILE" "$RST"
    local p
    for p in $(printf '%s\n' "${!PROFILES[@]}" | sort); do
        printf '  %s%-10s%s %s\n' "$GRN" "$p" "$RST" "${PROFILES[$p]}"
    done
    printf '\n  %soutside profiles (manual):%s %s\n' "$DIM" "$RST" "${EXTRA_PACKAGES[*]}"
    printf '  %susage: ./link.sh profile <name>%s\n' "$DIM" "$RST"
}

# ─── argument parsing ────────────────────────────────────────────────────────
CMD=""
ARGS=()
while [ "$#" -gt 0 ]; do
    case "$1" in
        -n|--dry-run) DRY=1 ;;
        -f|--force)   FORCE=1 ;;
        -h|--help)    usage; exit 0 ;;
        link|unlink|status|adopt|profile) CMD="$1" ;;
        -*)           die "unknown option: $1" ;;
        *)            ARGS+=("$1") ;;
    esac
    shift
done

# A bare ./link.sh links the default profile — no prompt, so nothing that calls
# this can hang on a question it cannot answer.
CMD="${CMD:-link}"

[ "$DRY" -eq 1 ] && printf '%s(dry-run — nothing will change)%s\n' "$DIM" "$RST"

rc=0
case "$CMD" in
    link)
        while IFS= read -r p; do link_pkg "$p" || rc=1; done < <(resolve_packages "${ARGS[@]+"${ARGS[@]}"}")
        if [ "${#ARGS[@]}" -eq 0 ]; then
            printf '\n%sProfile: %s — not included in the profile: %s%s\n' \
                "$DIM" "$DEFAULT_PROFILE" "${EXTRA_PACKAGES[*]}" "$RST"
        fi
        [ "$rc" -ne 0 ] && printf '\n%sTo back up conflicts and link over them: ./link.sh -f%s\n' "$YLW" "$RST"
        ;;
    profile)
        if [ "${#ARGS[@]}" -eq 0 ]; then
            list_profiles
        else
            prof="${ARGS[0]}"
            [ -n "${PROFILES[$prof]+x}" ] || die "no such profile: $prof  (${!PROFILES[*]})"
            printf '%sProfile: %s%s → %s\n\n' "$CYN" "$prof" "$RST" "${PROFILES[$prof]}"
            for p in ${PROFILES[$prof]}; do link_pkg "$p" || rc=1; done
            [ "$rc" -ne 0 ] && printf '\n%sFor conflicts: ./link.sh -f profile %s%s\n' "$YLW" "$prof" "$RST"
        fi
        ;;
    unlink)
        while IFS= read -r p; do unlink_pkg "$p"; done < <(resolve_packages "${ARGS[@]+"${ARGS[@]}"}")
        ;;
    status)
        while IFS= read -r p; do status_pkg "$p"; done \
            < <( [ "${#ARGS[@]}" -gt 0 ] && printf '%s\n' "${ARGS[@]}" || all_packages )
        ;;
    adopt)
        [ "${#ARGS[@]}" -ge 1 ] || die "usage: ./link.sh adopt <package> [home-path...]"
        if [ "${#ARGS[@]}" -eq 1 ]; then
            warn "adopt: files from your home directory will OVERWRITE the ones in the repo (${ARGS[0]})."
            adopt_pkg "${ARGS[0]}"
        else
            adopt_paths "${ARGS[@]}"
        fi
        ;;
esac

exit "$rc"
