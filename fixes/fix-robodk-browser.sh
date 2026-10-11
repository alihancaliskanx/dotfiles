#!/bin/bash
# Fix for the "Open" button of the RoboDK online library doing nothing
# A RoboDK installed by hand registers no handler for robodk:// links. This
# makes its desktop entry accept a URL and registers it for the scheme.

set -e

DESKTOP_FILE="$HOME/.local/share/applications/RoboDK.desktop"

echo "=> Fixing RoboDK browser integration (robodk:// scheme)..."

if [ ! -f "$DESKTOP_FILE" ]; then
    if [ -f "$HOME/Desktop/RoboDK.desktop" ]; then
        echo "=> Found the entry on the Desktop, copying it to the applications directory..."
        mkdir -p "$(dirname "$DESKTOP_FILE")"
        cp "$HOME/Desktop/RoboDK.desktop" "$DESKTOP_FILE"
    else
        echo "Error: RoboDK.desktop not found. Install RoboDK and create a shortcut first."
        exit 1
    fi
fi

if grep -q "Exec=.*%U" "$DESKTOP_FILE"; then
    echo "=> Exec line already takes a URL, skipping."
else
    echo "=> Adding %U to the Exec line..."
    sed -i 's/^Exec=.*/& %U/' "$DESKTOP_FILE"
fi

if grep -q "MimeType=x-scheme-handler/robodk" "$DESKTOP_FILE"; then
    echo "=> MimeType line already present, skipping."
else
    echo "=> Adding the MimeType line (robodk:// and RoboDK file types)..."
    echo "MimeType=x-scheme-handler/robodk;application/x-robodk;application/vnd.robodk.rdk;application/vnd.robodk.robot;application/vnd.robodk.tool;" >> "$DESKTOP_FILE"
fi

echo "=> Updating the desktop database and the default handler..."
update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
xdg-mime default RoboDK.desktop x-scheme-handler/robodk

echo "------------------------------------------------------"
echo "=> Done!"
echo "Quit and restart your web browser for the change to take effect."
