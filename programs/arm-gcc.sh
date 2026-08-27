#!/usr/bin/env bash
#
# arm-gcc.sh — the ARM bare-metal toolchain ArduPilot builds with.
#
# Arch has arm-none-eabi-gcc in the repos, but it tracks the newest release and
# ArduPilot pins 10-2020-q4-major: build with anything else and the linker script
# stops matching. So this is the exact tarball ARM published, unpacked under /opt
# and left alone. Nothing goes on PATH permanently — the `ardudev` shell function
# (shell/.config/zsh/40-functions.zsh) prepends it for the shell that asks.
#
# arm-none-eabi-gdb from this release links against libncursesw.so.5, which Arch
# has not shipped for years. That is what ncurses5-compat-libs in the AUR is for;
# without it the compiler still works and only the debugger fails to start.
#
# Usage:
#   ./arm-gcc.sh                 download, verify, unpack into /opt
#   ./arm-gcc.sh -f              reinstall even if it is already there
#   ./arm-gcc.sh -k file.tar.bz2 use a tarball that is already downloaded
#
#   PROXY=192.168.49.1:8000 ./arm-gcc.sh   over the phone's proxy

set -euo pipefail

NAME="gcc-arm-none-eabi-10-2020-q4-major"
TARBALL="$NAME-x86_64-linux.tar.bz2"
URL="https://developer.arm.com/-/media/Files/downloads/gnu-rm/10-2020q4/$TARBALL"
SHA256="21134caa478bbf5352e239fbc6e2da3038f8d2207e089efc96c3b55f1edcd618"
DEST="/opt/$NAME"

FORCE=0
LOCAL=""

usage() { awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "${BASH_SOURCE[0]}"; }
die()   { echo "   ✗ $*" >&2; exit 1; }

while getopts "fk:h" opt; do
  case "$opt" in
    f) FORCE=1 ;;
    k) LOCAL="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) exit 1 ;;
  esac
done

PROXY="${PROXY:-${http_proxy:-${https_proxy:-${HTTP_PROXY:-${HTTPS_PROXY:-}}}}}"
if [[ -n "$PROXY" ]]; then
  [[ "$PROXY" == http* ]] || PROXY="http://$PROXY"
  export http_proxy="$PROXY" https_proxy="$PROXY" all_proxy="$PROXY"
  export HTTP_PROXY="$PROXY" HTTPS_PROXY="$PROXY"
fi

if [[ -x "$DEST/bin/arm-none-eabi-gcc" && $FORCE -eq 0 ]]; then
  echo "   • already installed: $("$DEST/bin/arm-none-eabi-gcc" -dumpversion) in $DEST"
  exit 0
fi

SUDO=()
[[ $EUID -eq 0 ]] || SUDO=(sudo)

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# The download is ~155 MB and ARM's CDN is slow from here, so an already
# downloaded copy — including the one a previous run left in /opt — is reused.
if [[ -z "$LOCAL" ]]; then
  for c in "$HOME/Downloads/$TARBALL" "/opt/$TARBALL"; do
    if [[ -f "$c" ]]; then LOCAL="$c"; break; fi
  done
fi

if [[ -n "$LOCAL" ]]; then
  echo "   • using the tarball already here: $LOCAL"
  SRC="$LOCAL"
else
  echo ">> Downloading $TARBALL (~155 MB)..."
  curl -fL --retry 3 -o "$TMP/$TARBALL" "$URL" || die "could not download: $URL"
  SRC="$TMP/$TARBALL"
fi

echo ">> Checking the sha256..."
have="$(sha256sum "$SRC" | awk '{print $1}')"
[[ "$have" == "$SHA256" ]] || die "sha256 does not match — do not use this file
     expected: $SHA256
     got:      $have"
echo "   ✔ $have"

echo ">> Unpacking into /opt..."
tar -xjf "$SRC" -C "$TMP" || die "could not unpack the tarball"
[[ -d "$TMP/$NAME" ]] || die "$NAME is not inside the tarball"
if [[ -d "$DEST" ]]; then "${SUDO[@]}" rm -rf "$DEST"; fi
"${SUDO[@]}" cp -a "$TMP/$NAME" "$DEST" || die "could not copy into /opt"

ver="$("$DEST/bin/arm-none-eabi-gcc" -dumpversion 2>/dev/null || true)"
[[ -n "$ver" ]] || die "installed, but arm-none-eabi-gcc does not run"
echo "   ✔ arm-none-eabi-gcc $ver → $DEST"

# ldconfig's output is read into a variable first. Piping it into `grep -q`
# looks tidier, but grep exits at the first match and ldconfig then dies of
# SIGPIPE — which under `pipefail` is a failed pipeline, so the test would
# always say the library is missing.
libs="$(ldconfig -p 2>/dev/null || true)"
if ! grep -q 'libncursesw\.so\.5' <<<"$libs"; then
  echo "   ! arm-none-eabi-gdb needs libncursesw.so.5:  gclink ncurses5-compat-libs"
fi

echo
echo "   Put it on PATH for a shell with:  ardudev"
