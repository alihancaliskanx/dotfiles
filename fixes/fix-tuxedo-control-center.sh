#!/usr/bin/env bash
#
# fixes/fix-tuxedo-control-center.sh
# ------------------------------------------------------------------------------
# Installs Tuxedo Control Center and its kernel drivers for keyboard backlight.
# ------------------------------------------------------------------------------

set -euo pipefail

INFO='\033[0;34m[INFO]\033[0m'
SUCCESS='\033[0;32m[OK]\033[0m'
WARNING='\033[0;33m[WARN]\033[0m'

echo -e "${INFO} Installing Tuxedo Control Center and Keyboard Drivers..."

if ! command -v yay &> /dev/null; then
    echo -e "${WARNING} yay is not installed. Please install yay to proceed."
    exit 1
fi

echo -e "${INFO} Installing packages via yay..."
yay -S --needed --noconfirm tuxedo-control-center-bin tuxedo-drivers-nocompatcheck-dkms

echo -e "${INFO} Enabling and starting tccd service..."
sudo systemctl enable --now tccd.service 2>/dev/null || echo -e "${WARNING} Service tccd not found or failed to start."

echo -e "${INFO} Configuring autostart..."
mkdir -p "$HOME/.config/autostart"
cat << 'EOF' > "$HOME/.config/autostart/tuxedo-control-center.desktop"
[Desktop Entry]
Name=TUXEDO Control Center
Comment=TUXEDO Control Center Tray
Exec=tuxedo-control-center
Terminal=false
Type=Application
Icon=tuxedo-control-center
Categories=System;Utility;
X-GNOME-Autostart-enabled=true
EOF

echo -e "${SUCCESS} Tuxedo Control Center and keyboard backlight drivers installed, and set to autostart!"
echo -e "${INFO} Please note: You may need to reboot your system for the DKMS drivers to fully load."
