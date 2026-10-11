#!/usr/bin/env bash
#
# test.sh — runs link.sh against a throwaway repo and a throwaway home.
#
# link.sh holds every decision about what lands in $HOME, and the only way it
# was ever checked was by running it on the machine it was written for. This
# builds a copy of it beside a handful of fixture packages, points TARGET at an
# empty directory, and asserts what each command leaves behind. Nothing outside
# the temporary directory is read or written.
#
#   ./test.sh

set -uo pipefail

SRC="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

RED=$'\e[31m'; GRN=$'\e[32m'; RST=$'\e[0m'
fail=0
n=0

t() {
    local name="$1"; shift
    n=$((n + 1))
    if "$@"; then
        printf '%s✔%s %s\n' "$GRN" "$RST" "$name"
    else
        printf '%s✘ %s%s\n' "$RED" "$name" "$RST"
        fail=1
    fi
}

REPO="$T/repo"
HOME_DIR="$T/home"
mkdir -p "$REPO" "$HOME_DIR"
cp "$SRC/link.sh" "$REPO/link.sh"

lnk() { TARGET="$HOME_DIR" bash "$REPO/link.sh" "$@" 2>&1; }
plain() { sed 's/\x1b\[[0-9;]*m//g'; }

# The fixture has one package for every name the hyprland profile lists, so the
# profile can be linked as it is; link.sh itself says what those names are.
packages="$(lnk profile | plain | awk '$1 == "hyprland" { $1 = ""; print }')"
for p in $packages gtk; do
    mkdir -p "$REPO/$p/.config/$p"
    printf 'repo %s\n' "$p" > "$REPO/$p/.config/$p/a.conf"
done
mkdir -p "$REPO/theme/.local/share/wallpapers/StarrySky/contents"
printf '{}\n' > "$REPO/theme/.local/share/wallpapers/StarrySky/metadata.json"
printf 'x\n' > "$REPO/theme/.local/share/wallpapers/StarrySky/contents/image"
mkdir -p "$REPO/extras/notes" "$REPO/fixes"
printf 'x\n' > "$REPO/extras/notes/file"

snapshot() { (cd "$HOME_DIR" && find . -mindepth 1 -printf '%p %y %l\n' | sort); }
is_link_to() { [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]; }
holds() { [ -f "$1" ] && [ "$(cat "$1")" = "$2" ]; }

# ─── dry run ─────────────────────────────────────────────────────────────────
lnk -n profile hyprland >/dev/null
t "dry run creates nothing" [ -z "$(snapshot)" ]

# ─── link ────────────────────────────────────────────────────────────────────
lnk profile hyprland >/dev/null; rc=$?
t "profile links cleanly" [ "$rc" -eq 0 ]
t "a file is linked by itself, not its directory" \
    is_link_to "$HOME_DIR/.config/shell/a.conf" "$REPO/shell/.config/shell/a.conf"
t "the directory above it is a real directory" [ ! -L "$HOME_DIR/.config/shell" ]
t "a LINK_AS_DIR directory is one symlink" \
    is_link_to "$HOME_DIR/.local/share/wallpapers/StarrySky" "$REPO/theme/.local/share/wallpapers/StarrySky"
t "a package outside the profile is left alone" [ ! -e "$HOME_DIR/.config/gtk" ]

status="$(lnk status | plain)"
t "status reports every profile package as linked" \
    [ "$(printf '%s\n' "$status" | grep -cE '^[a-z]+ +linked ')" -eq "$(printf '%s\n' $packages | wc -l)" ]
t "status does not list extras or fixes" \
    [ -z "$(printf '%s\n' "$status" | grep -E '^(extras|fixes) ')" ]

# ─── idempotency ─────────────────────────────────────────────────────────────
before="$(snapshot)"
again="$(lnk profile hyprland | plain)"
t "a second run links nothing new" [ -z "$(printf '%s\n' "$again" | grep -E '[1-9][0-9]* new')" ]
t "a second run changes nothing" [ "$before" = "$(snapshot)" ]

# ─── conflicts ───────────────────────────────────────────────────────────────
rm "$HOME_DIR/.config/cli/a.conf"
printf 'mine\n' > "$HOME_DIR/.config/cli/a.conf"
lnk link cli >/dev/null; rc=$?
t "a real file in the way is an error" [ "$rc" -ne 0 ]
t "and it is left as it was" [ "$(cat "$HOME_DIR/.config/cli/a.conf")" = "mine" ]

lnk -f link cli >/dev/null; rc=$?
backup="$(find "$HOME_DIR/.config/cli" -name 'a.conf.bak.*' | head -n 1)"
t "-f links over it" is_link_to "$HOME_DIR/.config/cli/a.conf" "$REPO/cli/.config/cli/a.conf"
t "-f keeps the old file as a backup" holds "$backup" "mine"

rm "$HOME_DIR/.config/git/a.conf"
ln -s /nonexistent/elsewhere "$HOME_DIR/.config/git/a.conf"
lnk link git >/dev/null; rc=$?
t "a symlink that points elsewhere is an error" [ "$rc" -ne 0 ]
t "and it still points elsewhere" is_link_to "$HOME_DIR/.config/git/a.conf" /nonexistent/elsewhere
lnk -f link git >/dev/null

# ─── unlink ──────────────────────────────────────────────────────────────────
printf 'local\n' > "$HOME_DIR/.config/nvim/local.conf"
lnk unlink nvim >/dev/null
t "unlink removes the package's symlinks" [ ! -e "$HOME_DIR/.config/nvim/a.conf" ]
t "unlink leaves a real file beside them" [ -f "$HOME_DIR/.config/nvim/local.conf" ]
t "unlink leaves other packages linked" [ -L "$HOME_DIR/.config/shell/a.conf" ]

# ─── adopt ───────────────────────────────────────────────────────────────────
printf 'new\n' > "$HOME_DIR/.config/cli/b.conf"
lnk adopt cli "$HOME_DIR/.config/cli/b.conf" >/dev/null
t "adopt moves a new file into the package" [ "$(cat "$REPO/cli/.config/cli/b.conf" 2>/dev/null)" = "new" ]
t "adopt leaves a symlink where it was" \
    is_link_to "$HOME_DIR/.config/cli/b.conf" "$REPO/cli/.config/cli/b.conf"

rm "$HOME_DIR/.config/xdg/a.conf"
printf 'edited at home\n' > "$HOME_DIR/.config/xdg/a.conf"
lnk adopt xdg >/dev/null
t "adopt of a package takes the home copy" [ "$(cat "$REPO/xdg/.config/xdg/a.conf")" = "edited at home" ]
t "and links it again" is_link_to "$HOME_DIR/.config/xdg/a.conf" "$REPO/xdg/.config/xdg/a.conf"

# ─── clean ───────────────────────────────────────────────────────────────────
rm "$REPO/cli/.config/cli/b.conf"
ln -s /nonexistent/foreign "$HOME_DIR/.config/cli/foreign"
lnk -n clean >/dev/null
t "clean -n removes nothing" [ -L "$HOME_DIR/.config/cli/b.conf" ]
lnk clean >/dev/null
t "clean removes a link to a file the repo dropped" [ ! -L "$HOME_DIR/.config/cli/b.conf" ]
t "clean keeps links that still resolve" [ -L "$HOME_DIR/.config/cli/a.conf" ]
t "clean keeps a dangling link that is not this repo's" [ -L "$HOME_DIR/.config/cli/foreign" ]

rm -r "$REPO/terminal"
lnk clean >/dev/null
t "clean finds the links of a package removed whole" [ ! -L "$HOME_DIR/.config/terminal/a.conf" ]

# ─── errors ──────────────────────────────────────────────────────────────────
lnk link no-such-package >/dev/null; rc=$?
t "an unknown package is an error" [ "$rc" -ne 0 ]
lnk status no-such-package >/dev/null; rc=$?
t "also for status" [ "$rc" -ne 0 ]
lnk --no-such-option >/dev/null; rc=$?
t "an unknown option is an error" [ "$rc" -ne 0 ]

echo
if [ "$fail" -eq 0 ]; then
    printf '%s✔%s %d tests passed\n' "$GRN" "$RST" "$n"
else
    printf '%s✘ some of %d tests failed%s\n' "$RED" "$n" "$RST"
fi
exit "$fail"
