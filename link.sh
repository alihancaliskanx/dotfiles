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
COMMON_PACKAGES="shell terminal nvim vscode cli scripts services theme git xdg"

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

all_packages() {
    find "$DOTFILES" -mindepth 1 -maxdepth 1 -type d -printf '%P\n' \
        | grep -vE '^(\.git|extras)$' | sort
}

resolve_packages() {
    if [ "$#" -gt 0 ]; then
        printf '%s\n' "$@"
    else
        printf '%s\n' ${PROFILES[$DEFAULT_PROFILE]}
    fi
}

link_pkg() {
    local pkg="$1" rel src dst n_ok=0 n_new=0 n_conf=0

    while IFS= read -r rel; do
        src="$DOTFILES/$pkg/$rel"
        dst="$TARGET/$rel"

        if [ -L "$dst" ]; then
            if [ "$(readlink "$dst")" = "$src" ]; then
                n_ok=$((n_ok + 1)); continue
            fi
            case "$(readlink "$dst")" in
                "$DOTFILES"/*)   # points at an old path inside the repo, safe to refresh
                    [ "$DRY" -eq 1 ] || { rm -f "$dst" && ln -s "$src" "$dst"; }
                    dim "refreshed  ~/${rel}"; n_new=$((n_new + 1)); continue ;;
                *)               # symlink pointing outside the repo — the user's own setup
                    if [ "$FORCE" -eq 1 ]; then
                        [ "$DRY" -eq 1 ] || { rm -f "$dst" && ln -s "$src" "$dst"; }
                        warn "foreign symlink replaced  ~/${rel}"; n_new=$((n_new + 1))
                    else
                        warn "CONFLICT (symlink → $(readlink "$dst"))  ~/${rel}"; n_conf=$((n_conf + 1))
                    fi
                    continue ;;
            esac
        fi

        if [ -e "$dst" ]; then
            if [ "$FORCE" -eq 1 ]; then
                [ "$DRY" -eq 1 ] || mv "$dst" "$dst.bak.$STAMP"
                warn "backed up  ~/${rel}.bak.$STAMP"
            else
                warn "CONFLICT (real file; back it up with -f, pull it into the repo with adopt)  ~/${rel}"
                n_conf=$((n_conf + 1)); continue
            fi
        fi

        if [ "$DRY" -eq 1 ]; then
            dim "will link  ~/${rel}"
        else
            mkdir -p "$(dirname "$dst")" || { warn "could not create directory: $(dirname "$dst")"; n_conf=$((n_conf + 1)); continue; }
            ln -s "$src" "$dst" || { warn "could not link: ~/${rel}"; n_conf=$((n_conf + 1)); continue; }
        fi
        n_new=$((n_new + 1))
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
    while IFS= read -r rel; do
        dst="$TARGET/$rel"
        # Only remove symlinks pointing at this repo; leave real files alone.
        if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$DOTFILES/$pkg/$rel" ]; then
            [ "$DRY" -eq 1 ] || rm -f "$dst"
            n=$((n + 1))
        fi
    done < <(pkg_files "$pkg")
    ok "$(printf '%-10s %d symlinks removed' "$pkg" "$n")"
}

status_pkg() {
    local pkg="$1" rel dst n_ok=0 n_miss=0 n_conf=0
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
