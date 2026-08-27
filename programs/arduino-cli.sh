#!/usr/bin/env bash
#
# arduino-cli.sh — arduino-cli straight from the upstream release.
#
# It is a single static Go binary, which is why it lives in ~/.local/bin instead
# of coming from a package: no root, no dependencies, and the release it pulls is
# the one the Arduino project just published rather than whatever the AUR has
# caught up to. Board cores and libraries go under ~/.arduino15 either way.
#
# Serial ports on Arch belong to the `uucp` group. Without membership every
# upload fails on /dev/ttyUSB0 with a permission error, so that is checked below.
#
# Usage:
#   ./arduino-cli.sh            newest release into ~/.local/bin
#   ./arduino-cli.sh -v 1.5.1   a specific version
#   ./arduino-cli.sh -f         reinstall even if the same version is there
#
#   PROXY=192.168.49.1:8000 ./arduino-cli.sh   over the phone's proxy

set -euo pipefail

BIN_DIR="$HOME/.local/bin"
VERSION=""
FORCE=0

usage() { awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "${BASH_SOURCE[0]}"; }
die()   { echo "   ✗ $*" >&2; exit 1; }

while getopts "v:fh" opt; do
  case "$opt" in
    v) VERSION="$OPTARG" ;;
    f) FORCE=1 ;;
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

if [[ -z "$VERSION" ]]; then
  echo ">> Asking GitHub for the newest release..."
  # Read the whole answer before grepping it: closing the pipe early makes curl
  # print a "failure writing output" error over the top of the real output.
  json="$(curl -fsSL https://api.github.com/repos/arduino/arduino-cli/releases/latest || true)"
  VERSION="$(grep -m1 '"tag_name"' <<<"$json" | cut -d'"' -f4)" || true
  VERSION="${VERSION#v}"
  [[ -n "$VERSION" ]] || die "could not read the release list — pass one:  ./arduino-cli.sh -v 1.5.1"
fi

have=""
if [[ -x "$BIN_DIR/arduino-cli" ]]; then
  have="$("$BIN_DIR/arduino-cli" version 2>/dev/null | grep -oP 'Version: \K[0-9.]+' || true)"
fi
if [[ "$have" == "$VERSION" && $FORCE -eq 0 ]]; then
  echo "   • arduino-cli $have is already in $BIN_DIR"
  exit 0
fi

TARBALL="arduino-cli_${VERSION}_Linux_64bit.tar.gz"
URL="https://github.com/arduino/arduino-cli/releases/download/v${VERSION}/${TARBALL}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo ">> Downloading arduino-cli $VERSION..."
curl -fL --retry 3 -o "$TMP/$TARBALL" "$URL" || die "could not download: $URL"
tar -xzf "$TMP/$TARBALL" -C "$TMP" arduino-cli || die "arduino-cli is not inside the tarball"

mkdir -p "$BIN_DIR"
install -m 755 "$TMP/arduino-cli" "$BIN_DIR/arduino-cli"
echo "   ✔ $("$BIN_DIR/arduino-cli" version | head -1)"

grep -qx uucp <<<"$(id -nG | tr ' ' '\n')" \
  || echo "   ! not in the uucp group, uploads will be denied:  sudo usermod -aG uucp $USER"

echo
echo "   Board index:   arduino-cli core update-index"
echo "   AVR support:   arduino-cli core install arduino:avr"
echo "   Boards found:  arduino-cli board list"
