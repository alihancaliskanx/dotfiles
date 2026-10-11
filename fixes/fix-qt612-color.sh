#!/bin/bash
# Fix for the Omarchy shell's Color singleton under Qt 6.12
# The name collides with one in Qt 6.12's QML namespace, so the singleton and
# every reference to it are renamed to ThemeColor.

set -euo pipefail

OMARCHY_DIR="${OMARCHY_PATH:-/usr/share/omarchy}"
SHELL_DIR="$OMARCHY_DIR/shell"
QMLDIR="$SHELL_DIR/Commons/qmldir"

echo "Applying Qt 6.12 Color singleton fix..."

if [ ! -f "$QMLDIR" ]; then
    echo "Error: $QMLDIR not found. Is the Omarchy shell installed?"
    exit 1
fi

# The shell tree is owned by root
sudo sed -i 's/\bsingleton Color 1.0/singleton ThemeColor 1.0/g' "$QMLDIR"
sudo find "$SHELL_DIR" \( -name "*.qml" -o -name "*.js" \) -exec sed -i 's/\bColor\./ThemeColor\./g' {} +

rm -rf ~/.cache/quickshell/qmlcache

# The launcher treats a clean exit as a deliberate stop and does not relaunch,
# so a plain kill can leave the session without a bar.
"$OMARCHY_DIR/bin/omarchy-restart-shell"

echo "Shell patched and restarted!"
