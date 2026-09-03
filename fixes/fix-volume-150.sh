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
    # Make replacements idempotent (remove existing ones first)
    sed -i "s|/home/$USER/.local/bin/omarchy-audio-output-volume|omarchy-audio-output-volume|g" "$BINDINGS_FILE"
    sed -i 's|~/.local/bin/omarchy-audio-output-volume|omarchy-audio-output-volume|g' "$BINDINGS_FILE"
    sed -i 's/--max-volume 150 //g' "$BINDINGS_FILE"

    # Apply the absolute path
    sed -i "s|omarchy-audio-output-volume|/home/$USER/.local/bin/omarchy-audio-output-volume|g" "$BINDINGS_FILE"
    
    # Apply max-volume to swayosd-client if present
    sed -i 's/swayosd-client --output-volume raise/swayosd-client --output-volume raise --max-volume 150/g' "$BINDINGS_FILE"
    sed -i 's/swayosd-client --output-volume lower/swayosd-client --output-volume lower --max-volume 150/g' "$BINDINGS_FILE"
    
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
