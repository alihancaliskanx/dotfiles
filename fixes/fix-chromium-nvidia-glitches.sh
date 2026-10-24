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

# The files below are symlinks into the dotfiles repo once it is linked, so they
# are edited in place: what is missing is added and every other line is kept.

add_missing_lines() {
    local file="$1" line
    shift
    [ -e "$file" ] || : > "$file"
    if [ -s "$file" ] && [ -n "$(tail -c 1 "$file")" ]; then
        echo >> "$file"
    fi
    for line in "$@"; do
        grep -qxF -- "$line" "$file" || printf '%s\n' "$line" >> "$file"
    done
}

# Not kwriteconfig6: KConfig saves by rename, which turns a symlink into a real file.
set_kconfig_key() {
    local file="$1" group="$2" key="$3" value="$4" new
    [ -e "$file" ] || : > "$file"
    new="$(awk -v g="[$group]" -v k="$key" -v v="$value" '
        function add() { if (in_g && !done) { print k "=" v; done = 1 } }
        /^$/ { blanks++; next }
        /^\[/ { add() }
        { while (blanks) { print ""; blanks-- } }
        /^\[/ { in_g = ($0 == g) }
        in_g && index($0, k "=") == 1 { if (!done) print k "=" v; done = 1; next }
        { print }
        END { add(); if (!done) { if (NR) print ""; print g; print k "=" v } }
    ' "$file")"
    [ "$new" = "$(cat "$file")" ] || printf '%s\n' "$new" > "$file"
}

# 1. Chromium & Chrome flags
FLAGS=(
    --ozone-platform-hint=auto
    --disable-gpu-compositing
    --disable-features=WaylandFractionalScaleV1
    --enable-features=TouchpadOverscrollHistoryNavigation
    --password-store=basic
    "--load-extension=/usr/share/omarchy/default/chromium/extensions/copy-url,/usr/share/omarchy/default/chromium/extensions/yt-dlp,/usr/share/omarchy/default/chromium/extensions/whatsapp-slim"
)

add_missing_lines "$HOME/.config/chromium-flags.conf" "${FLAGS[@]}"
add_missing_lines "$HOME/.config/chrome-flags.conf" "${FLAGS[@]}"
echo -e "${SUCCESS} Configured ~/.config/chromium-flags.conf and chrome-flags.conf"

# 2. Disable KDE Wallet prompts
set_kconfig_key "$HOME/.config/kwalletrc" Wallet Enabled false
set_kconfig_key "$HOME/.config/kwalletrc" Wallet "First Use" false
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
