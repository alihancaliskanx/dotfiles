#!/usr/bin/env bash
#
# fixes/fix-windows-vm.sh
# ------------------------------------------------------------------------------
# Fixes Windows VM reconnection and window management issues:
# 1. Installs windows-vm-smart-launch.sh and configures windows-vm.desktop.
#    - If Windows VM window is already open -> Focuses it immediately.
#    - If VM is stopped -> Starts it in background.
#    - Never kills the VM on window close (instant reconnection).
# 2. Ensures Hyprland tiles xfreerdp windows automatically instead of floating.
# 3. Validates Docker daemon connectivity.
# ------------------------------------------------------------------------------

set -euo pipefail

INFO='\033[0;34m[INFO]\033[0m'
SUCCESS='\033[0;32m[OK]\033[0m'
WARN='\033[0;33m[WARN]\033[0m'

echo -e "${INFO} Applying Windows VM Smart Launcher & Window Rules fix..."

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"

# 1. Install smart launcher script
cat << 'LAUNCHER' > "$HOME/.local/bin/windows-vm-smart-launch.sh"
#!/usr/bin/env bash
set -eo pipefail

if command -v hyprctl >/dev/null 2>&1; then
  if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class == "xfreerdp")' >/dev/null 2>&1; then
    hyprctl dispatch focuswindow "class:xfreerdp"
    exit 0
  fi
fi

CREDENTIALS_FILE="$HOME/.config/windows/credentials"
WIN_USER="sups"
WIN_PASS="183461"
if [[ -f "$CREDENTIALS_FILE" ]]; then
  WIN_USER=$(grep -E "^USERNAME=" "$CREDENTIALS_FILE" | cut -d= -f2- || echo "sups")
  WIN_PASS=$(grep -E "^PASSWORD=" "$CREDENTIALS_FILE" | cut -d= -f2- || echo "183461")
fi

COMPOSE_FILE="/var/lib/omarchy/windows/docker-compose.yml"
if [[ ! -f "$COMPOSE_FILE" ]]; then
  COMPOSE_FILE="$HOME/.config/windows/docker-compose.yml"
fi

CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' omarchy-windows 2>/dev/null || echo "stopped")
if [[ "$CONTAINER_STATUS" != "running" ]]; then
  omarchy-shell osd show '{"icon":"󰍲","message":"Starting Windows VM..."}' 2>/dev/null || true
  if [[ -f "$COMPOSE_FILE" ]]; then
    docker compose -f "$COMPOSE_FILE" up -d
  else
    omarchy-windows-vm launch -k &
  fi

  for i in {1..45}; do
    if nc -z 127.0.0.1 3389 2>/dev/null; then
      break
    fi
    sleep 1
  done
fi

KRB5_CONF="$HOME/.config/windows/krb5.conf"
mkdir -p "$(dirname "$KRB5_CONF")"
if [[ ! -f "$KRB5_CONF" ]]; then
  printf '[libdefaults]\n  dns_lookup_kdc = false\n  dns_lookup_realm = false\n' >"$KRB5_CONF"
fi
export KRB5_CONFIG="$KRB5_CONF"

RDP_SCALE=""
if command -v hyprctl >/dev/null 2>&1; then
  HYPR_SCALE=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select (.focused == true) | .scale' 2>/dev/null || echo "1")
  SCALE_PERCENT=$(echo "$HYPR_SCALE" | awk '{print int($1 * 100)}')
  if ((SCALE_PERCENT >= 170)); then
    RDP_SCALE="/scale:180"
  elif ((SCALE_PERCENT >= 130)); then
    RDP_SCALE="/scale:140"
  fi
fi

exec xfreerdp3 \
  /u:"$WIN_USER" \
  /p:"$WIN_PASS" \
  /v:127.0.0.1:3389 \
  -grab-keyboard \
  /sound \
  /microphone \
  /clipboard \
  /cert:ignore \
  /title:"Windows VM - Omarchy" \
  /dynamic-resolution \
  /gfx:AVC444 \
  /floatbar:sticky:off,default:visible,show:fullscreen \
  $RDP_SCALE
LAUNCHER
chmod +x "$HOME/.local/bin/windows-vm-smart-launch.sh"
echo -e "${SUCCESS} Installed ~/.local/bin/windows-vm-smart-launch.sh"

# 2. Update desktop file
cat << 'DESKTOP' > "$HOME/.local/share/applications/windows-vm.desktop"
[Desktop Entry]
Name=Windows
Comment=Start Windows VM via Docker and connect with RDP
Exec=uwsm app -- /home/sups/.local/bin/windows-vm-smart-launch.sh
Icon=windows
Terminal=false
Type=Application
Categories=System;Virtualization;
DESKTOP
echo -e "${SUCCESS} Configured ~/.local/share/applications/windows-vm.desktop"

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
