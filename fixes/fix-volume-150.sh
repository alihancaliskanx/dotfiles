#!/bin/bash
# Enables 150% max volume in Omarchy (Panel slider + Keyboard shortcuts)

echo "Applying 150% max volume fix for Omarchy..."

# 1. Update the background script for keyboard shortcuts
mkdir -p ~/.local/bin
if [ -f /usr/share/omarchy/bin/omarchy-audio-output-volume ]; then
    cp /usr/share/omarchy/bin/omarchy-audio-output-volume ~/.local/bin/
    # Modify 100 to 150 for volume limits
    sed -i 's/next=100/next=150/g' ~/.local/bin/omarchy-audio-output-volume
    sed -i 's/next <= 100/next <= 150/g' ~/.local/bin/omarchy-audio-output-volume
    chmod +x ~/.local/bin/omarchy-audio-output-volume
    echo "Updated local omarchy-audio-output-volume script."
fi

# 2. Update Hyprland bindings
BINDINGS_FILE="$HOME/.config/hypr/bindings.lua"
if [ -f "$BINDINGS_FILE" ]; then
    # The file is a symlink into the dotfiles repo; plain sed -i would replace
    # it with a copy, so every call follows the link.
    # Make replacements idempotent (remove existing ones first)
    sed -i --follow-symlinks "s|/home/$USER/.local/bin/omarchy-audio-output-volume|omarchy-audio-output-volume|g" "$BINDINGS_FILE"
    sed -i --follow-symlinks 's|~/.local/bin/omarchy-audio-output-volume|omarchy-audio-output-volume|g' "$BINDINGS_FILE"
    sed -i --follow-symlinks 's/--max-volume 150 //g' "$BINDINGS_FILE"

    # Call the copy by path: Omarchy's bin directory is ahead of ~/.local/bin
    # on the compositor's PATH
    sed -i --follow-symlinks 's|omarchy-audio-output-volume|~/.local/bin/omarchy-audio-output-volume|g' "$BINDINGS_FILE"
    
    # Reload hyprland to apply binding changes
    if command -v hyprctl &> /dev/null; then
        hyprctl reload &>/dev/null
    fi
    echo "Updated Hyprland bindings."
fi

# 3. Clone and update the Omarchy shell audio plugin
PLUGIN_DIR="$HOME/.config/omarchy/plugins/${USER}.audio"
if [ ! -d "$PLUGIN_DIR" ]; then
    echo "Cloning omarchy.audio plugin..."
    omarchy plugin clone omarchy.audio 2>/dev/null
fi

if [ -f "$PLUGIN_DIR/Panel.qml" ]; then
    # Change slider maximum: 1 to 1.5
    sed -i 's/maximum: 1$/maximum: 1.5/g' "$PLUGIN_DIR/Panel.qml"
    
    # Change Math.min clamping logic in setOutputVolume
    sed -i 's/Math.min(1, v)/Math.min(1.5, v)/g' "$PLUGIN_DIR/Panel.qml"
    echo "Updated Omarchy shell audio plugin slider bounds."
fi

echo "Volume 150% fix applied successfully!"
