#!/usr/bin/env bash
#
# fixes/fix-windows-vm.sh
# ------------------------------------------------------------------------------
# Fixes Windows VM reconnection and window management issues:
# 1. Links/installs windows-vm-smart-launch.sh and windows-vm.desktop (never
#    overwrites existing dotfiles symlinks).
# 2. Ensures Hyprland tiles xfreerdp windows automatically instead of floating.
# 3. Checks for stale Docker proxy drop-in.
# ------------------------------------------------------------------------------

set -euo pipefail

INFO='\033[0;34m[INFO]\033[0m'
SUCCESS='\033[0;32m[OK]\033[0m'
WARN='\033[0;33m[WARN]\033[0m'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_LAUNCHER="$REPO_ROOT/scripts/.local/bin/windows-vm-smart-launch.sh"
SRC_DESKTOP="$REPO_ROOT/desktop/.local/share/applications/windows-vm.desktop"

echo -e "${INFO} Applying Windows VM Smart Launcher & Window Rules fix..."

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"

# 1. Install smart launcher script (skip overwriting if already symlinked)
DST_LAUNCHER="$HOME/.local/bin/windows-vm-smart-launch.sh"
if [[ -L "$DST_LAUNCHER" ]]; then
  echo -e "${SUCCESS} $DST_LAUNCHER is already symlinked (kept intact)"
elif [[ -f "$SRC_LAUNCHER" ]]; then
  cp "$SRC_LAUNCHER" "$DST_LAUNCHER"
  chmod +x "$DST_LAUNCHER"
  echo -e "${SUCCESS} Installed $DST_LAUNCHER from repo"
else
  echo -e "${WARN} Source launcher not found at $SRC_LAUNCHER"
fi

# 2. Install desktop entry (skip overwriting if already symlinked)
DST_DESKTOP="$HOME/.local/share/applications/windows-vm.desktop"
if [[ -L "$DST_DESKTOP" ]]; then
  echo -e "${SUCCESS} $DST_DESKTOP is already symlinked (kept intact)"
elif [[ -f "$SRC_DESKTOP" ]]; then
  cp "$SRC_DESKTOP" "$DST_DESKTOP"
  echo -e "${SUCCESS} Configured $DST_DESKTOP from repo"
else
  echo -e "${WARN} Source desktop file not found at $SRC_DESKTOP"
fi

# 3. Ensure Hyprland window rule for xfreerdp is present
LOOKNFEEL="$HOME/.config/hypr/looknfeel.lua"
if [[ -f "$LOOKNFEEL" ]]; then
  if ! grep -q 'o.window("xfreerdp"' "$LOOKNFEEL"; then
    echo 'o.window("xfreerdp", { tile = true })' >> "$LOOKNFEEL"
    echo -e "${SUCCESS} Added xfreerdp tile rule to ~/.config/hypr/looknfeel.lua"
    if command -v hyprctl >/dev/null 2>&1; then
      hyprctl reload >/dev/null 2>&1 || true
    fi
  else
    echo -e "${SUCCESS} Hyprland xfreerdp tile rule already present"
  fi
fi

# 4. Check for stale Docker proxy
if [[ -f /etc/systemd/system/docker.service.d/http-proxy.conf ]]; then
  echo -e "${WARN} Stale Docker proxy drop-in detected at /etc/systemd/system/docker.service.d/http-proxy.conf"
  echo -e "${WARN} Run: sudo rm -f /etc/systemd/system/docker.service.d/http-proxy.conf && sudo systemctl daemon-reload && sudo systemctl restart docker"
fi

echo -e "${SUCCESS} Windows VM smart fixes applied successfully!"
