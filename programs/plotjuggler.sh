#!/usr/bin/env bash
#
# plotjuggler.sh — PlotJuggler, the timeseries plotter used on flight logs.
#
# Upstream ships an AppImage per release and that is what this fetches into
# ~/Applications. The AUR builds it against whatever ROS and Qt happen to be on
# the machine, which breaks every time either of those moves; the AppImage
# carries its own and keeps working.
#
# VERSIONS ARE CONFUSING HERE: upstream tags the PlotJuggler 4 previews as
# 3.999.x and marks them as the latest release, so `-v 3.17.2` is how you ask for
# the last classic 3.x line.
#
# AppImageLauncher is installed on this machine and integrates anything under
# ~/Applications the first time it runs — that is where the menu entry and the
# icon come from. Without it, this writes a .desktop file itself.
#
# Usage:
#   ./plotjuggler.sh            newest release into ~/Applications
#   ./plotjuggler.sh -v 3.17.2  a specific version
#
#   PROXY=192.168.49.1:8000 ./plotjuggler.sh   over the phone's proxy

set -euo pipefail

REPO="PlotJuggler/PlotJuggler"
APP_DIR="$HOME/Applications"
VERSION=""

usage() { awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "${BASH_SOURCE[0]}"; }
die()   { echo "   ✗ $*" >&2; exit 1; }

while getopts "v:h" opt; do
  case "$opt" in
    v) VERSION="$OPTARG" ;;
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

if [[ -n "$VERSION" ]]; then
  API="https://api.github.com/repos/$REPO/releases/tags/$VERSION"
else
  API="https://api.github.com/repos/$REPO/releases/latest"
fi

echo ">> Asking GitHub which AppImage to take..."
# Read the whole answer before grepping it: closing the pipe early makes curl
# print a "failure writing output" error over the top of the real output.
json="$(curl -fsSL "$API" || true)"
URL="$(grep -oE '"browser_download_url": "[^"]+"' <<<"$json" | cut -d'"' -f4 \
       | grep -iE 'x86_64.*\.AppImage$' | head -1)" || true
[[ -n "$URL" ]] || die "no x86_64 AppImage in that release${VERSION:+ ($VERSION)}"

FILE="$(basename "$URL")"
mkdir -p "$APP_DIR"
if [[ -f "$APP_DIR/$FILE" ]]; then
  echo "   • already downloaded: $APP_DIR/$FILE"
else
  echo ">> Downloading $FILE..."
  curl -fL --retry 3 -o "$APP_DIR/$FILE.part" "$URL" || die "could not download: $URL"
  mv "$APP_DIR/$FILE.part" "$APP_DIR/$FILE"
fi
chmod +x "$APP_DIR/$FILE"
echo "   ✔ $APP_DIR/$FILE"

# AppImageLauncher owns the menu entry when it is installed — writing one here
# too would put PlotJuggler in the launcher twice.
if ! command -v AppImageLauncher >/dev/null && [[ ! -x /usr/lib/appimagelauncher/remove ]]; then
  mkdir -p "$HOME/.local/share/applications"
  cat > "$HOME/.local/share/applications/plotjuggler.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=PlotJuggler
Comment=Visualize timeseries like a pro
Exec=$APP_DIR/$FILE
Terminal=false
Categories=Development;Science;
StartupWMClass=plotjuggler
EOF
  echo "   ✔ menu entry written (no AppImageLauncher here)"
fi

echo
echo "   Start it from the launcher, or:  $APP_DIR/$FILE"
