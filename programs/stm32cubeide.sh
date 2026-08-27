#!/usr/bin/env bash
#
# stm32cubeide.sh — installs STM32CubeIDE from ST's own installer.
#
# ST puts the download behind a my.st.com login, so no script can fetch it: you
# download `en.st-stm32cubeide_<version>_<build>_amd64.sh.zip` from
# st.com/en/development-tools/stm32cubeide.html and this takes it from there —
# unzip, mark the installer executable, run it against ~/st.
#
# The AUR package is not used on purpose. It lags ST's releases, and CubeIDE
# carries its own JRE and its own CDT plugins, so an out-of-tree copy under $HOME
# is exactly as good and never fights pacman over /opt.
#
# Two things the installer asks about are worth saying yes to: the ST-LINK udev
# rules (without them the debugger only sees the board as root) and the SEGGER
# J-Link rules if you use one. Both need the root password, which the installer
# asks for itself.
#
# WAYLAND: `stm32cubeide` is an Eclipse — the GTK3 Wayland backend garbles its
# dialogs. ST ships `stm32cubeide_wayland` next to it, which is the same launcher
# with GDK_BACKEND=x11, and that is what the `stmcube` alias runs.
#
# Usage:
#   ./stm32cubeide.sh                  find the archive in ~/Downloads and install
#   ./stm32cubeide.sh path/to.sh.zip   use this archive (.zip or the .sh inside it)
#   ./stm32cubeide.sh -t               text-mode installer, no window
#
# It installs into ~/st/stm32cubeide_<version>, which is where the alias looks.

set -euo pipefail

PREFIX_BASE="$HOME/st"
TEXT_MODE=0

usage() { awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "${BASH_SOURCE[0]}"; }
die()   { echo "   ✗ $*" >&2; exit 1; }

while getopts "th" opt; do
  case "$opt" in
    t) TEXT_MODE=1 ;;
    h) usage; exit 0 ;;
    *) exit 1 ;;
  esac
done
shift $((OPTIND - 1))

ARCHIVE="${1:-}"
if [[ -z "$ARCHIVE" ]]; then
  echo ">> Looking for the ST installer in the download folders..."
  ARCHIVE="$(find "$HOME/Downloads" "$HOME/İndirilenler" "$HOME/Desktop" "$HOME/Masaüstü" \
             -maxdepth 1 \( -iname 'en.st-stm32cubeide*' -o -iname 'st-stm32cubeide*' \) \
             2>/dev/null | sort -V | tail -1 || true)"
fi
[[ -n "$ARCHIVE" && -f "$ARCHIVE" ]] || die "no installer found.
     Download it from st.com/en/development-tools/stm32cubeide.html (a login is needed)
     and pass it in:  ./stm32cubeide.sh ~/Downloads/en.st-stm32cubeide_*.sh.zip"
echo "   • $ARCHIVE"

command -v unzip >/dev/null || die "unzip is missing:  sudo pacman -S unzip"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ST wraps the installer in a zip; the .sh inside it is the real thing. Either
# one can be handed to this script.
if [[ "$ARCHIVE" == *.zip ]]; then
  echo ">> Unpacking..."
  unzip -q -o "$ARCHIVE" -d "$TMP" || die "could not unpack the archive"
  INSTALLER="$(find "$TMP" -maxdepth 2 -name '*.sh' | head -1)"
else
  INSTALLER="$ARCHIVE"
fi
[[ -n "$INSTALLER" && -f "$INSTALLER" ]] || die "no .sh installer inside the archive"
chmod +x "$INSTALLER"

# It is an InstallBuilder installer, but ST has changed which flags it accepts
# between releases, so the help text decides rather than an assumption.
HELP="$("$INSTALLER" --help 2>&1 || true)"
ARGS=()
if grep -q -- '--prefix' <<<"$HELP"; then ARGS+=(--prefix "$PREFIX_BASE"); fi
if [[ $TEXT_MODE -eq 1 || -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]] && grep -q -- '--mode' <<<"$HELP"; then
  ARGS+=(--mode text)
fi

echo ">> Starting ST's installer${ARGS:+ (${ARGS[*]})}..."
echo "   Say yes to the ST-LINK udev rules; it asks for the root password itself."
mkdir -p "$PREFIX_BASE"
"$INSTALLER" "${ARGS[@]}" || die "the installer exited with an error"

IDE="$(find "$PREFIX_BASE" -maxdepth 2 -name 'stm32cubeide' -type f 2>/dev/null | sort -V | tail -1)"
[[ -n "$IDE" ]] || die "the installer finished but no stm32cubeide turned up under $PREFIX_BASE"
DIR="$(dirname "$IDE")"
echo "   ✔ $DIR"

# The alias pins the version in its path, so a new version silently stops the
# old alias from working. Say so rather than let `stmcube` fail later.
ALIASES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/shell/.config/zsh/20-aliases.zsh"
if [[ -f "$ALIASES" ]] && ! grep -q "$(basename "$DIR")" "$ALIASES"; then
  echo "   ! the stmcube alias points somewhere else — update it in"
  echo "     shell/.config/zsh/20-aliases.zsh:"
  echo "     alias stmcube='pc \$HOME/st/$(basename "$DIR")/stm32cubeide_wayland'"
fi

echo
echo "   Start it with:  stmcube        (${DIR}/stm32cubeide_wayland)"
