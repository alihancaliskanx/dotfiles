#!/usr/bin/env bash
#
# windows-vm-smart-launch.sh
# ------------------------------------------------------------------------------
# Smart launcher for Windows VM:
# 1. If RDP window is already open in Hyprland -> Focus it immediately.
# 2. If Docker container is stopped -> Start it in background and wait for port 3389.
# 3. Connect via FreeRDP (xfreerdp3).
# 4. Never kills/shuts down the VM when RDP closes (keeps it alive in background).
# ------------------------------------------------------------------------------

set -eo pipefail

# 1. If window is already open in Hyprland, just focus it!
if command -v hyprctl >/dev/null 2>&1; then
  if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class == "xfreerdp")' >/dev/null 2>&1; then
    hyprctl dispatch focuswindow "class:xfreerdp"
    exit 0
  fi
fi

# 2. Check credentials
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

# 3. Check if container is running; if not, start it
CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' omarchy-windows 2>/dev/null || echo "stopped")
if [[ "$CONTAINER_STATUS" != "running" ]]; then
  omarchy-shell osd show '{"icon":"󰍲","message":"Starting Windows VM..."}' 2>/dev/null || true
  if [[ -f "$COMPOSE_FILE" ]]; then
    docker compose -f "$COMPOSE_FILE" up -d
  else
    omarchy-windows-vm launch -k &
  fi

  # Wait for port 3389 to become ready (up to 45 seconds)
  for i in {1..45}; do
    if nc -z 127.0.0.1 3389 2>/dev/null; then
      break
    fi
    sleep 1
  done
fi

# 4. FreeRDP scale detection & Kerberos fix
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

# 5. Launch FreeRDP (without killing the VM on exit)
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
