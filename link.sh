#!/usr/bin/env bash
#
# link.sh — symlinks the dotfiles packages into $HOME.
#
# No external dependencies. The directory layout matches GNU Stow exactly, so if
# you prefer you can do the same job with "stow -t ~ shell hypr ..."; this script
# only exists so that stow does not have to be installed.
#
# Usage:
#   ./link.sh                      ask which desktop to use (menu), then link it
#   ./link.sh -n                   show what it would do, touch nothing (dry-run)
#   ./link.sh -f                   back up conflicting real files and link over them
#   ./link.sh link gtk fish        link specific packages
#   ./link.sh profile              list the profiles
#   ./link.sh profile niri         link the packages of a profile
#   ./link.sh rice                 list the desktops and show which one is on
#   ./link.sh rice own             switch to the desktop of this repo
#   ./link.sh rice imperative-dots switch to the quickshell desktop
#   ./link.sh rice caelestia       switch to the caelestia desktop
#   ./link.sh unlink [package...]  remove the symlinks pointing at this repo
#   ./link.sh status [package...]  which package is linked, which is not
#   ./link.sh adopt <package>      pull the real files from $HOME into the repo (CAUTION: overwrites repo content)
#   ./link.sh adopt <package> <path>  move a new file from $HOME into the package
#
# Without a terminal on stdin (a script, CI) the menu is skipped and the default
# profile is linked, which is what this did before the menu existed.

set -uo pipefail

DOTFILES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${TARGET:-$HOME}"

# Packages wanted in every install, independent of the compositor.
#
# kdeglobals is its own package rather than part of `theme` because it is the
# one file in there a rice may need to take over: it is where Qt apps read
# their palette from, so a rice that colours the desktop from the wallpaper has
# to own it. Everything else in `theme` is rice neutral and stays put.
COMMON_PACKAGES="shell terminal nvim vscode cli scripts services theme kdeglobals git xdg"

# Profiles: package sets per desktop environment.
declare -A PROFILES=(
    [hyprland]="$COMMON_PACKAGES hypr desktop"
    [niri]="$COMMON_PACKAGES niri desktop"
    [kde]="$COMMON_PACKAGES"
)
DEFAULT_PROFILE="${DOTFILES_PROFILE:-hyprland}"

# Packages in no profile at all, to be asked for by hand (reason in the README).
EXTRA_PACKAGES=(fish gtk)

# ─── rices ───────────────────────────────────────────────────────────────────
# A profile picks the compositor; a rice picks the desktop on top of it — which
# bar, launcher, notification daemon and lock screen you end up with. "own" is
# this repo. Every other rice lives in a repo of its own and is linked straight
# out of it, so upstream stays one `git pull` away and none of it is vendored
# in here. Each such repo says where its directories go under $HOME in a
# .linkmap at its root; for a repo that is not ours to write into, the same file
# is kept here as extras/linkmaps/<rice>.linkmap. Without either there is
# nothing to link and link.sh says so.
#
# caelestia is only half a checkout. Its shell — the bar, launcher, lock screen
# — is not a config tree at all: on Arch it is the caelestia-shell AUR package,
# a quickshell config compiled against a C++ plugin and installed system wide,
# which is why RICE_PKGS below exists and there is nothing of it to symlink.
# What is left over, the Hyprland config, is the caelestia-dots/caelestia
# checkout this points at. Do not run `caelestia install`: it is the CLI's own
# installer and copies those dots over ~/.config, which is exactly the job this
# script is doing, only without a way back.
declare -A RICES=(
    [imperative-dots]="$HOME/Documents/Code/imperative-dots"
    [caelestia]="$HOME/Documents/Code/caelestia"
)

# One line per rice, shown in the menu.
declare -A RICE_ABOUT=(
    [own]="waybar, fuzzel, mako, satty, hyprpaper"
    [imperative-dots]="quickshell: bar, launcher, notifications, lock, wallpaper"
    [caelestia]="quickshell from the AUR + its own lua Hyprland config"
)

# Packages a rice needs and no profile installs. install.sh carries these in its
# AUR list, but a machine it never ran on — or one where the AUR build failed —
# would otherwise link the whole rice and then come up to an empty screen, so
# they are checked before anything is touched.
declare -A RICE_PKGS=(
    [caelestia]="caelestia-shell caelestia-cli"
)

# Packages of this repo that a rice takes the paths of. They are unlinked before
# it goes in and linked back on the way to "own", so the two never fight over
# the same file. Everything else (scripts, git, services, xdg...) is rice
# neutral and stays linked throughout.
#
# caelestia keeps kdeglobals, unlike the other one. It sets
# QT_QPA_PLATFORMTHEME=qtengine and colours Qt apps through ~/.config/qtengine,
# a path nothing here owns, so kdeglobals is simply not read while it is on and
# there is nothing to take away. `cli` is on its list for one file: the CLI
# rewrites ~/.config/cava/config every time the scheme changes.
declare -A RICE_REPLACES=(
    [imperative-dots]="hypr desktop cli kdeglobals"
    [caelestia]="hypr desktop cli"
)

# The other direction: packages of this repo that exist *for* a rice and are
# linked alongside it. A rice is somebody else's checkout, so there is nowhere
# in it to keep what this machine has to say back to it — the tr keyboard, the
# panel scale, the keybinds these dotfiles keep, the blur that a GT1 iGPU can
# afford. caelestia reads all of that out of ~/.config/caelestia, a directory
# neither repo owned, so none of it survived a reinstall and none of it was
# ever reviewed in a diff.
#
# Kept out of every profile on purpose: the files are meaningless with the rice
# off, and linking them anyway would leave a config for a shell that is not
# running. They go in with the rice and come out with it.
#
# Only safe because nothing generates these. caelestia-cli renders its
# templates to a temp file and os.replace()s them into place, which destroys a
# symlink rather than writing through it — see RICE_GENERATES below — but
# hypr-vars.lua, hypr-user.lua and shell.json are all read and never written,
# by either the CLI or the shell. Check that again before adding a fourth.
declare -A RICE_LOCAL=(
    [caelestia]="caelestia-local"
)

# The compositor a rice needs, when it only runs on one. imperative-dots calls
# hyprctl from 15 of its files — monitors, keyboard layout, workspaces, submaps
# — so under niri its bar comes up and everything behind it is dead. Warned
# about rather than refused: linking it while still in niri, to log into
# Hyprland afterwards, is the normal way to install it.
declare -A RICE_NEEDS=(
    [imperative-dots]="Hyprland"
    [caelestia]="Hyprland"
)

# A line printed after a rice goes in, for what is worth saying once it is on.
# caelestia's Hyprland config is upstream's and stays upstream's: it hard codes
# a us keyboard and a single preferred monitor, and knows nothing about this
# laptop. hypr-user.lua is the file it reads last, so anything put there wins —
# and it is the caelestia-local package above, so it is tracked here rather
# than sitting loose in ~/.config.
declare -A RICE_NOTE=(
    [caelestia]="what this machine says back to it — keyboard, scale, keybinds, blur — is the caelestia-local package, linked alongside"
)

# What each rice actually runs. A rice is not only its symlinks: a bar left
# running after its config was unlinked keeps drawing from a file that is no
# longer there, and starting the other one on top gives you two bars fighting
# over the same strip of screen. Switching stops one set and starts the other.
#
# Both quickshell rices are the same binary under two names: imperative-dots
# execs `quickshell`, caelestia is started through its CLI and ends up as `qs`.
# pgrep -x tells them apart, which is the only reason switching between the two
# stops the right one.
declare -A RICE_RUNS=(
    [own]="waybar hyprpaper"
    [imperative-dots]="quickshell awww-daemon"
    [caelestia]="qs"
)

# Real files a rice's own tooling writes at paths this repo also owns.
#
# matugen rewrites every theme file it knows about whenever the wallpaper or the
# colour scheme changes, and one of its sixteen outputs lands on
# ~/.config/swayosd/style.css -- which the desktop package wants to symlink. The
# switch back then stopped with a CONFLICT that reads like something valuable is
# about to be lost, when the file is generated and comes back the moment that
# rice is used again.
#
# ~/.config/kdeglobals is the same story with a sharper edge. It is what Qt apps
# read their palette from -- dolphin above all -- so imperative-dots generates it
# to colour them from the wallpaper, the way it colours everything else.
#
# The edge: matugen writes *through* a symlink rather than replacing it. Left
# linked, its first run would not have produced a conflict at all; it would have
# quietly overwritten kdeglobals/.config/kdeglobals inside this repo, and the
# rainynight palette would have been gone with the next commit. That is why
# kdeglobals is a package of its own and sits in RICE_REPLACES above: unlinked
# before that rice runs, so matugen only ever writes a real file of its own.
#
# Only paths that are genuinely regenerated belong here. Removed on the way out,
# and only when they really are files rather than symlinks: a symlink at one of
# these paths belongs to a package and the loop above has already dealt with it.
# caelestia writes its files the other way round: caelestia-cli renders every
# template to a temporary file and os.replace()s it into place, so a symlink at
# the target is destroyed rather than written through and this repo is never in
# danger. What it leaves behind is a real file at a path a package wants back —
# fuzzel.ini and the cava config above all, both of which it rewrites on every
# `caelestia scheme set`. hypr/scheme/current.lua is the colour scheme its own
# lua config copies out of scheme/default.lua on first load.
#
# gtk.css is here without gtk being in RICE_REPLACES on purpose: `gtk` is an
# extra package, outside every profile, so the way back to "own" would not
# relink it. Removing what caelestia wrote is still right — a stale caelestia
# palette on a Rainy-Night desktop is worse than no gtk.css — but if you use
# that package, put it back with `./link.sh -f link gtk`.
declare -A RICE_GENERATES=(
    [imperative-dots]=".config/swayosd/style.css .config/kdeglobals"
    [caelestia]=".config/hypr/scheme/current.lua .config/fuzzel/fuzzel.ini .config/cava/config .config/gtk-3.0/gtk.css .config/gtk-4.0/gtk.css"
)

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
# them here every file two rices share would preview as a conflict that will
# never happen.
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

# A compositor rewrites its own example config the moment the real one goes
# missing — which is exactly what unlinking a rice does, in the split second
# before the next one is linked. The file that appears is not the user's work
# and says so in its first lines, so it is cleared instead of being reported as
# a conflict that stops the switch.
#
# Hyprland 0.56 reads hyprland.lua in preference to hyprland.conf and generates
# a stub for whichever it was looking for, under a header of its own wording
# ("-- AUTOGENERATED HYPRLAND CONFIG"). That one matters more than the .conf
# stub ever did: lua wins, so a stub left at ~/.config/hypr/hyprland.lua after
# caelestia is taken out shadows this repo's hyprland.conf completely and the
# desktop comes up as bare Hyprland with no explanation.
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
            *)               # points somewhere else — another rice, or the user's own
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

# ─── rice ────────────────────────────────────────────────────────────────────
# Emits "<absolute source>\t<path under $HOME>" for every file a rice owns.
# The two halves differ here, unlike a package: .linkmap renames directories on
# the way out (config/sessions/hyprland becomes .config/hypr), because those
# trees were laid out for home-manager, not for a symlinker.
rice_pairs() {
    local rice="$1" root="${RICES[$rice]:-}" map src dst rel
    [ -n "$root" ] || die "no such rice: $rice  (own ${!RICES[*]})"
    [ -d "$root" ] || die "$rice: its repo is not at $root — clone it first"
    # A fork can carry its .linkmap at its own root and keep it under version
    # control there. An upstream checkout we do not own cannot: a file added to
    # it is untracked noise in someone else's `git status` and is gone the next
    # time the thing is re-cloned. For those the map lives here instead.
    map="$root/.linkmap"
    [ -f "$map" ] || map="$DOTFILES/extras/linkmaps/$rice.linkmap"
    [ -f "$map" ] || die "$rice: no .linkmap in $root nor in extras/linkmaps, nothing says where its files go"

    while read -r src dst _; do
        case "$src" in ''|\#*) continue ;; esac
        [ -n "$dst" ] || continue
        [ -d "$root/$src" ] || { warn "$rice: .linkmap points at a missing directory: $src"; continue; }
        while IFS= read -r rel; do
            printf '%s/%s/%s\t%s/%s\n' "$root" "$src" "$rel" "$dst" "$rel"
        done < <(find "$root/$src" -mindepth 1 \( -type f -o -type l \) ! -name '*.nix' -printf '%P\n' | sort)
    done < "$map"
}

rice_link() {
    local rice="$1" root="${RICES[$rice]}" src rel n_ok=0 n_new=0 n_conf=0
    while IFS=$'\t' read -r src rel; do
        link_one "$src" "$rel" "$root"
        case "$?" in
            0) n_new=$((n_new + 1)) ;;
            1) n_ok=$((n_ok + 1)) ;;
            *) n_conf=$((n_conf + 1)) ;;
        esac
    done < <(rice_pairs "$rice")

    if [ "$n_conf" -gt 0 ]; then
        printf '%s✘%s %-16s %d new, %d already linked, %s%d conflicts%s\n' \
            "$RED" "$RST" "$rice" "$n_new" "$n_ok" "$RED" "$n_conf" "$RST"
        return 1
    fi
    ok "$(printf '%-16s %d new, %d already linked' "$rice" "$n_new" "$n_ok")"
    return 0
}

rice_unlink() {
    local rice="$1" src rel dst gen p n=0 g=0
    # Ahead of the guard below on purpose: the local package is in this repo,
    # so it is linked whether or not the rice itself was ever cloned.
    for p in ${RICE_LOCAL[$rice]:-}; do unlink_pkg "$p"; done
    [ -d "${RICES[$rice]:-}" ] || return 0      # not cloned, nothing of it is linked
    while IFS=$'\t' read -r src rel; do
        dst="$TARGET/$rel"
        if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
            if [ "$DRY" -eq 1 ]; then DRY_REMOVED["$rel"]=1; else rm -f "$dst"; fi
            n=$((n + 1))
        fi
    done < <(rice_pairs "$rice")

    for gen in ${RICE_GENERATES[$rice]:-}; do
        dst="$TARGET/$gen"
        [ -f "$dst" ] && [ ! -L "$dst" ] || continue
        if [ "$DRY" -eq 1 ]; then DRY_REMOVED["$gen"]=1; else rm -f "$dst"; fi
        g=$((g + 1))
    done

    if [ "$g" -gt 0 ]; then
        ok "$(printf '%-16s %d symlinks removed, %d generated' "$rice" "$n" "$g")"
    else
        ok "$(printf '%-16s %d symlinks removed' "$rice" "$n")"
    fi
}

# How many of a rice's files are actually linked right now.
rice_count() {
    local rice="$1" src rel n=0
    [ -d "${RICES[$rice]:-}" ] || { printf '0 0\n'; return; }
    local total=0
    while IFS=$'\t' read -r src rel; do
        total=$((total + 1))
        [ -L "$TARGET/$rel" ] && [ "$(readlink "$TARGET/$rel")" = "$src" ] && n=$((n + 1))
    done < <(rice_pairs "$rice" 2>/dev/null)
    printf '%d %d\n' "$n" "$total"
}

# The rice that is on: the one with files linked. "own" is the fallback, since
# its packages are what a bare ./link.sh has always put down.
current_rice() {
    local r n total
    for r in "${!RICES[@]}"; do
        read -r n total < <(rice_count "$r")
        [ "$n" -gt 0 ] && { printf '%s' "$r"; return; }
    done
    printf 'own'
}

list_rices() {
    local cur r n total mark
    cur="$(current_rice)"
    printf '%sDesktops%s  (on now: %s%s%s)\n\n' "$CYN" "$RST" "$GRN" "$cur" "$RST"

    [ "$cur" = own ] && mark="●" || mark=" "
    printf '  %s %s%-16s%s %s%s%s\n' "$mark" "$GRN" "own" "$RST" "$DIM" "${RICE_ABOUT[own]}" "$RST"

    for r in $(printf '%s\n' "${!RICES[@]}" | sort); do
        [ "$cur" = "$r" ] && mark="●" || mark=" "
        read -r n total < <(rice_count "$r")
        if [ ! -d "${RICES[$r]}" ]; then
            printf '  %s %s%-16s%s %s%s%s\n' "$mark" "$YLW" "$r" "$RST" "$DIM" "not cloned: ${RICES[$r]}" "$RST"
        else
            printf '  %s %s%-16s%s %s%s (%d/%d linked)%s\n' \
                "$mark" "$GRN" "$r" "$RST" "$DIM" "${RICE_ABOUT[$r]:-}" "$n" "$total" "$RST"
        fi
    done
    printf '\n  %susage: ./link.sh rice <name>%s\n' "$DIM" "$RST"
}

# waybar is a systemd user unit so that it comes back on its own after a crash;
# the others are plain processes the compositor would normally exec-once.
proc_start() {
    case "$1" in
        waybar)      systemctl --user start waybar >/dev/null 2>&1 ;;
        quickshell)  setsid quickshell -p "$HOME/.config/hypr/scripts/quickshell/Shell.qml" >/dev/null 2>&1 & ;;
        # `caelestia shell -d` is `qs -c caelestia -n -d`, and -c only resolves
        # against the search path the AUR package installs into. Running the
        # binary bare, the way the default branch does, finds no config at all.
        qs)          caelestia shell -d >/dev/null 2>&1 ;;
        *)           setsid "$1" >/dev/null 2>&1 & ;;
    esac
}

proc_stop() {
    case "$1" in
        waybar) systemctl --user stop waybar >/dev/null 2>&1 ;;
        qs)     caelestia shell -k >/dev/null 2>&1 || pkill -x qs 2>/dev/null ;;
        *)      pkill -x "$1" 2>/dev/null ;;
    esac
}

# Re-read the compositor config, so the new keybindings are live before the new
# bar is. Without this the desktop is half of each until the next login.
#
# Except when the two rices disagree on the config *language*. Hyprland 0.56
# chooses between hyprland.lua and hyprland.conf once, at startup, and
# `hyprctl reload` only ever re-reads the file it already chose — so switching
# from imperative-dots to caelestia reloads the .conf that is no longer there,
# Hyprland regenerates a stub in its place, and the session carries on as bare
# Hyprland with the new rice's bar drawn on top of it. Nothing errors and
# nothing looks obviously broken; `hyprctl getoption decoration:rounding` just
# quietly says 0.
#
# There is no fixing that from here — the only way to change a compositor's
# mind about it is to restart the compositor, which means the session. So it is
# named instead. `hyprctl systeminfo` reports the provider in use, and the
# legacy one calls itself hyprlang; anything else is the lua path.
compositor_reload() {
    local provider want_lua running_lua
    case "${XDG_CURRENT_DESKTOP:-}" in
        *Hyprland*)
            hyprctl reload >/dev/null 2>&1
            provider="$(hyprctl systeminfo 2>/dev/null | awk -F': ' '/^configProvider:/ {print $2}')"
            [ -n "$provider" ] || return 0
            [ -e "$TARGET/.config/hypr/hyprland.lua" ] && want_lua=1 || want_lua=0
            [ "$provider" = hyprlang ] && running_lua=0 || running_lua=1
            [ "$want_lua" = "$running_lua" ] && return 0
            warn "this session started on Hyprland's ${provider} config and only picks that at startup — log out and back in for the new one to apply"
            ;;
        *niri*)     niri msg action load-config-file >/dev/null 2>&1 ;;
    esac
    return 0
}

# Stops what the other rices run, starts what this one does. Skipped entirely
# without a Wayland session — linking from a tty is a legitimate thing to do
# (setting a machine up before logging in) and there is nothing to restart there.
rice_procs() {
    local want="$1" r p
    [ "$DRY" -eq 1 ] && { dim "would restart: ${RICE_RUNS[$want]:-none}"; return 0; }
    [ -n "${WAYLAND_DISPLAY:-}" ] || { dim "no wayland session — not touching any processes"; return 0; }

    for r in own "${!RICES[@]}"; do
        [ "$r" = "$want" ] && continue
        for p in ${RICE_RUNS[$r]:-}; do
            pgrep -x "$p" >/dev/null 2>&1 || continue
            proc_stop "$p"; dim "stopped  $p"
        done
    done

    compositor_reload

    for p in ${RICE_RUNS[$want]:-}; do
        if pgrep -x "$p" >/dev/null 2>&1; then dim "running  $p"; continue; fi
        command -v "$p" >/dev/null 2>&1 || { warn "$p is not installed"; continue; }
        proc_start "$p"; dim "started  $p"
    done
}

# Warns about the packages a rice needs and pacman does not have. Only a
# warning: the packages can be installed after the symlinks are down, and
# refusing to link would make the recommended order (link it, log into
# Hyprland, then build the AUR half) impossible.
rice_check_pkgs() {
    local rice="$1" p
    local -a missing=()
    for p in ${RICE_PKGS[$rice]:-}; do
        pacman -Qq "$p" >/dev/null 2>&1 || missing+=("$p")
    done
    [ "${#missing[@]}" -eq 0 ] && return 0
    warn "$rice: not installed — ${missing[*]}"
    dim "install with:  paru -S ${missing[*]}"
    return 1
}

# Switching is always "take the other one out, then put this one in", never a
# merge: both rices want ~/.config/hypr and whoever is linked there wins.
rice_apply() {
    local rice="$1" p r
    case "$rice" in
        own)
            for r in "${!RICES[@]}"; do rice_unlink "$r"; done
            printf '\n'
            for p in ${PROFILES[$DEFAULT_PROFILE]}; do link_pkg "$p" || rc=1; done
            printf '\n%sDesktop: own  (profile: %s)%s\n' "$DIM" "$DEFAULT_PROFILE" "$RST"
            ;;
        *)
            [ -n "${RICES[$rice]+x}" ] || die "no such rice: $rice  (own ${!RICES[*]})"
            local needs="${RICE_NEEDS[$rice]:-}"
            if [ -n "$needs" ]; then
                case "${XDG_CURRENT_DESKTOP:-}" in
                    *"$needs"*) ;;
                    *) warn "$rice needs $needs; this session is ${XDG_CURRENT_DESKTOP:-unset}" ;;
                esac
            fi
            rice_check_pkgs "$rice"
            # The other rices come out first, the same way the "own" branch
            # does it. While there was one of them this loop was unreachable —
            # you could only arrive here from "own" — and going straight from
            # one foreign rice to another left the first one's symlinks lying
            # in ~/.config/hypr. Not even as a conflict: imperative-dots writes
            # hyprland.conf and caelestia writes hyprland.lua, so the two sit
            # side by side under different names and Hyprland, which prefers
            # lua, quietly keeps running the rice you just switched away from.
            for r in "${!RICES[@]}"; do
                [ "$r" = "$rice" ] || rice_unlink "$r"
            done
            # ...and then give back what they had taken. rice_unlink only ever
            # removes, and nothing here put anything back, so going from a rice
            # that replaces a package straight to one that does not left that
            # package unlinked with nothing said about it. kdeglobals is where
            # it showed: imperative-dots replaces it, caelestia does not, and
            # after the switch there was no kdeglobals at all. KDE wrote a stub
            # of its own into the gap, Qt fell back to the default light
            # palette, and everything that reads the portal's color-scheme --
            # which kde-gtk-config derives from that same file -- went light
            # with it. A white dolphin and a white zen, from a missing symlink.
            #
            # Only packages of the profile are handed back, the same list the
            # "own" branch links, and only the ones this rice does not want for
            # itself. link_pkg is a no-op on a package that is already linked.
            local -A reclaim=()
            for r in "${!RICES[@]}"; do
                [ "$r" = "$rice" ] && continue
                for p in ${RICE_REPLACES[$r]:-}; do reclaim["$p"]=1; done
            done
            for p in ${RICE_REPLACES[$rice]:-}; do unset "reclaim[$p]"; done
            for p in ${PROFILES[$DEFAULT_PROFILE]}; do
                if [ -n "${reclaim[$p]:-}" ]; then link_pkg "$p" || rc=1; fi
            done
            for p in ${RICE_REPLACES[$rice]:-}; do unlink_pkg "$p"; done
            printf '\n'
            rice_link "$rice" || rc=1
            for p in ${RICE_LOCAL[$rice]:-}; do link_pkg "$p" || rc=1; done
            printf '\n%sDesktop: %s  (own packages put aside: %s)%s\n' \
                "$DIM" "$rice" "${RICE_REPLACES[$rice]:-none}" "$RST"
            [ -n "${RICE_NOTE[$rice]:-}" ] && dim "${RICE_NOTE[$rice]}"
            ;;
    esac
    if [ "$rc" -eq 0 ]; then
        printf '\n'
        rice_procs "$rice"
    fi
}

# ─── menu ────────────────────────────────────────────────────────────────────
# Sets RICE_CHOICE. Only ever reached from a terminal; see the argument parsing.
#
# gum draws it when it is installed — arrow keys and a highlight instead of
# typing a number. Its colours come from the GUM_* variables in the shell env,
# so this passes no flags and stays in step with anything else that uses gum.
# Without gum it falls back to a numbered prompt, so the script keeps working on
# a machine where nothing has been installed yet.
#
# The list is built from RICES rather than written out, because it was written
# out while there were two of them and adding a third meant editing the gum
# branch, the printf branch and the "(1 or 2)" in the error, any one of which
# could be forgotten and only the last would ever say so.
menu() {
    local cur choice r i=0
    local -a names=(own)
    cur="$(current_rice)"
    while IFS= read -r r; do names+=("$r"); done < <(printf '%s\n' "${!RICES[@]}" | sort)

    if command -v gum >/dev/null 2>&1; then
        choice=$(for r in "${names[@]}"; do
                printf '%-16s %s\n' "$r" "${RICE_ABOUT[$r]:-}"
            done | gum choose --header "Which desktop?  (on now: $cur)") || exit 0
        [ -n "$choice" ] || exit 0
        RICE_CHOICE="${choice%% *}"
        return
    fi

    printf '%sWhich desktop?%s  (on now: %s%s%s)\n\n' "$CYN" "$RST" "$GRN" "$cur" "$RST"
    for r in "${names[@]}"; do
        i=$((i + 1))
        printf '  %s%d)%s %-16s %s%s%s\n' "$GRN" "$i" "$RST" "$r" "$DIM" "${RICE_ABOUT[$r]:-}" "$RST"
    done
    printf '\n'
    read -r -p "  Choice [1]: " choice
    printf '\n'
    choice="${choice:-1}"
    case "$choice" in
        q|Q) exit 0 ;;
        *[!0-9]*)
            for r in "${names[@]}"; do
                [ "$r" = "${choice,,}" ] && { RICE_CHOICE="$r"; return; }
            done
            die "invalid choice: $choice  (1-${#names[@]}, or a name)"
            ;;
        *)
            [ "$choice" -ge 1 ] && [ "$choice" -le "${#names[@]}" ] \
                || die "invalid choice: $choice  (1-${#names[@]})"
            RICE_CHOICE="${names[$((choice - 1))]}"
            ;;
    esac
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
RICE_CHOICE=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        -n|--dry-run) DRY=1 ;;
        -f|--force)   FORCE=1 ;;
        -h|--help)    usage; exit 0 ;;
        link|unlink|status|adopt|profile|rice) CMD="$1" ;;
        -*)           die "unknown option: $1" ;;
        *)            ARGS+=("$1") ;;
    esac
    shift
done

# Nothing asked for, and a terminal to ask on: show the menu. Anywhere else — a
# script, CI, a pipe — keep doing what a bare ./link.sh has always done, so
# nothing that calls this starts hanging on a prompt it cannot answer.
if [ -z "$CMD" ] && [ "${#ARGS[@]}" -eq 0 ] && [ -t 0 ]; then
    CMD="menu"
fi
CMD="${CMD:-link}"

[ "$DRY" -eq 1 ] && printf '%s(dry-run — nothing will change)%s\n' "$DIM" "$RST"

rc=0
case "$CMD" in
    menu)
        menu
        rice_apply "$RICE_CHOICE"
        ;;
    rice)
        if [ "${#ARGS[@]}" -eq 0 ]; then
            list_rices
        else
            rice_apply "${ARGS[0]}"
        fi
        ;;
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
