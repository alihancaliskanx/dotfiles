#!/usr/bin/env bash
#
# sonarview.sh — SonarView, Cerulean Sonar's viewer for the imaging sonars.
#
# The website hides the download behind a JavaScript page, but the releases sit
# in the open on GitHub, which is what this reads. It is an Electron app shipped
# as an AppImage; there is no package for it anywhere.
#
# --no-sandbox is in the menu entry on purpose: the AppImage carries its own
# Chromium, and its SUID sandbox helper cannot work from a user directory on a
# kernel with unprivileged user namespaces restricted. Without the flag the
# window never appears.
#
# AppImageLauncher is installed on this machine and integrates anything under
# ~/Applications the first time it runs. Without it, this writes a .desktop file.
#
# Usage:
#   ./sonarview.sh             newest release into ~/Applications
#   ./sonarview.sh -v 1.14.70  a specific version
#
#   PROXY=192.168.49.1:8000 ./sonarview.sh   over the phone's proxy

set -euo pipefail

REPO="CeruleanSonar/SonarView"
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

# The tags carry a leading v, the AppImage names do not.
if [[ -n "$VERSION" ]]; then
  API="https://api.github.com/repos/$REPO/releases/tags/v${VERSION#v}"
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
  echo ">> Downloading $FILE (~150 MB)..."
  curl -fL --retry 3 -o "$APP_DIR/$FILE.part" "$URL" || die "could not download: $URL"
  mv "$APP_DIR/$FILE.part" "$APP_DIR/$FILE"
fi
chmod +x "$APP_DIR/$FILE"
echo "   ✔ $APP_DIR/$FILE"

if ! command -v AppImageLauncher >/dev/null && [[ ! -x /usr/lib/appimagelauncher/remove ]]; then
  mkdir -p "$HOME/.local/share/applications"
  cat > "$HOME/.local/share/applications/sonarview.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=SonarView
Comment=Friendly graphical frontend for your sonar devices
Exec=$APP_DIR/$FILE --no-sandbox %U
Terminal=false
Categories=Science;Maps;
StartupWMClass=SonarView
EOF
  echo "   ✔ menu entry written (no AppImageLauncher here)"
fi

echo
echo "   Start it with:  $APP_DIR/$FILE --no-sandbox"
