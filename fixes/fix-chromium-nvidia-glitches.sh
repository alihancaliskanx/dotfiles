#!/usr/bin/env bash
#
# fixes/fix-chromium-nvidia-glitches.sh
# ------------------------------------------------------------------------------
# Fixes visual artifacts/glitches, screen tearing, canvas flickering on Grok,
# ChatGPT, and other Chromium-based web apps on NVIDIA + Intel Wayland setups.
# Also disables "The KDE Wallet System" popup prompt by switching password-store
# to basic and disabling KWallet popups.
# ------------------------------------------------------------------------------

set -euo pipefail

INFO='\033[0;34m[INFO]\033[0m'
SUCCESS='\033[0;32m[OK]\033[0m'

echo -e "${INFO} Applying Chromium & Electron GPU glitch + KDE Wallet fix..."

mkdir -p "$HOME/.config"

# 1. Chromium & Chrome flags
FLAGS_CONTENT="--ozone-platform-hint=auto
--disable-gpu-compositing
--disable-features=WaylandFractionalScaleV1
--enable-features=TouchpadOverscrollHistoryNavigation
--password-store=basic
--load-extension=/usr/share/omarchy/default/chromium/extensions/copy-url,/usr/share/omarchy/default/chromium/extensions/yt-dlp,/usr/share/omarchy/default/chromium/extensions/whatsapp-slim"

echo "$FLAGS_CONTENT" > "$HOME/.config/chromium-flags.conf"
echo "$FLAGS_CONTENT" > "$HOME/.config/chrome-flags.conf"
echo -e "${SUCCESS} Configured ~/.config/chromium-flags.conf and chrome-flags.conf"

# 2. Disable KDE Wallet prompts
cat << 'KWALLET' > "$HOME/.config/kwalletrc"
[Wallet]
Enabled=false
First Use=false
KWALLET
echo -e "${SUCCESS} Disabled KDE Wallet popups in ~/.config/kwalletrc"

# 3. Clear corrupted GPU shader caches
rm -rf "$HOME/.config/chromium/Default/GPUCache" \
       "$HOME/.config/chromium/GrShaderCache" \
       "$HOME/.config/google-chrome/Default/GPUCache" \
       "$HOME/.config/google-chrome/GrShaderCache" 2>/dev/null || true
echo -e "${SUCCESS} Cleared corrupted GPU and shader caches"

# 4. Terminate lingering browser instances safely
pkill -x chromium 2>/dev/null || true
pkill -x chrome 2>/dev/null || true
pkill -x kwalletd5 2>/dev/null || true
pkill -x kwalletd6 2>/dev/null || true

echo -e "${SUCCESS} Chromium Wayland & KWallet fixes applied successfully!"
