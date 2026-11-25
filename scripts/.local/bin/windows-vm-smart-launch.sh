#!/usr/bin/env bash
#
# windows-vm-smart-launch.sh
# ------------------------------------------------------------------------------
# Smart launcher for Windows VM:
# 1. If RDP window is already open in Hyprland -> Focus it immediately.
# 2. If Docker container is stopped -> Start it in background.
# 3. Wait for the actual RDP X.224 handshake (not just docker-proxy port open).
# 4. Connect via FreeRDP (xfreerdp3) passing credentials over stdin.
# 5. Never kills/shuts down the VM when RDP closes (keeps it alive in background).
# ------------------------------------------------------------------------------

set -euo pipefail

osd() {
  omarchy-shell -q osd show "{\"icon\":\"$1\",\"message\":\"$2\"}" 2>/dev/null || true
}

rdp_ready() {
  python3 - <<'PYEOF'
import socket, sys
req = bytes([
    0x03, 0x00, 0x00, 0x13,
    0x0e, 0xe0, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x01, 0x00, 0x08, 0x00, 0x03, 0x00, 0x00, 0x00,
])
try:
    with socket.create_connection(("127.0.0.1", 3389), timeout=2) as s:
        s.settimeout(2)
        s.sendall(req)
        resp = s.recv(64)
        if len(resp) >= 11 and resp[0] == 0x03 and resp[1] == 0x00 and resp[5] == 0xd0:
            sys.exit(0)
except OSError:
    pass
sys.exit(1)
PYEOF
}

# 1. If window is already open in Hyprland, just focus it.
if command -v hyprctl >/dev/null 2>&1; then
  if hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.class == "xfreerdp")' >/dev/null 2>&1; then
    hyprctl dispatch focuswindow "class:xfreerdp"
    exit 0
  fi
fi

# Prevent duplicate cold-boot launches while waiting for RDP.
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/windows-vm-smart-launch.lock"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  osd "󰍲" "Windows · Booting"
  exit 0
fi

# 2. Read credentials strictly from the private per-user file.
CREDENTIALS_FILE="$HOME/.config/windows/credentials"
WIN_USER=""
WIN_PASS=""
if [[ -r "$CREDENTIALS_FILE" ]]; then
  WIN_USER="$(grep -E '^USERNAME=' "$CREDENTIALS_FILE" | head -n1 | cut -d= -f2- || true)"
  WIN_PASS="$(grep -E '^PASSWORD=' "$CREDENTIALS_FILE" | head -n1 | cut -d= -f2- || true)"
fi
if [[ -z "$WIN_USER" || -z "$WIN_PASS" ]]; then
  osd "󰀦" "No credentials"
  echo "Missing credentials in $CREDENTIALS_FILE (expected USERNAME= and PASSWORD=)" >&2
  exit 1
fi

COMPOSE_FILE="/var/lib/omarchy/windows/docker-compose.yml"
if [[ ! -f "$COMPOSE_FILE" ]]; then
  COMPOSE_FILE="$HOME/.config/windows/docker-compose.yml"
fi

# 3. Start container if stopped.
CONTAINER_STATUS="$(docker inspect --format='{{.State.Status}}' omarchy-windows 2>/dev/null || echo "stopped")"
JUST_STARTED=0
if [[ "$CONTAINER_STATUS" != "running" ]]; then
  JUST_STARTED=1
  osd "󰍲" "Windows · Start"
  if [[ -f "$COMPOSE_FILE" ]]; then
    docker compose -f "$COMPOSE_FILE" up -d
  else
    omarchy-windows-vm launch -k &
  fi
fi

# 4. Wait until Windows RDP actually answers an X.224 Connection Confirm.
RDP_UP=0
for _ in $(seq 1 60); do
  if rdp_ready; then
    RDP_UP=1
    break
  fi
  STATUS_NOW="$(docker inspect --format='{{.State.Status}}' omarchy-windows 2>/dev/null || echo "stopped")"
  if [[ "$STATUS_NOW" != "running" ]]; then
    osd "󰀦" "VM stopped"
    echo "Container omarchy-windows is no longer running ($STATUS_NOW)." >&2
    exit 1
  fi
  sleep 1.5
done

if [[ "$RDP_UP" -ne 1 ]]; then
  osd "󰀦" "RDP timeout"
  echo "Timed out waiting for Windows RDP on 127.0.0.1:3389." >&2
  exit 1
fi

if [[ "$JUST_STARTED" -eq 1 ]]; then
  osd "󰍲" "Windows · Ready"
fi

# 5. FreeRDP scale detection & Kerberos fix.
KRB5_CONF="$HOME/.config/windows/krb5.conf"
mkdir -p "$(dirname "$KRB5_CONF")"
if [[ ! -f "$KRB5_CONF" ]]; then
  printf '[libdefaults]\n  dns_lookup_kdc = false\n  dns_lookup_realm = false\n' >"$KRB5_CONF"
fi
export KRB5_CONFIG="$KRB5_CONF"

RDP_SCALE=""
if command -v hyprctl >/dev/null 2>&1; then
  HYPR_SCALE="$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .scale' 2>/dev/null || echo "1")"
  SCALE_PERCENT="$(echo "${HYPR_SCALE:-1}" | awk '{print int($1 * 100)}')"
  if ((SCALE_PERCENT >= 170)); then
    RDP_SCALE="/scale:180"
  elif ((SCALE_PERCENT >= 130)); then
    RDP_SCALE="/scale:140"
  fi
fi

# Release boot lock before launching RDP so focus/reopen works normally.
exec 9>&-

RDP_ARGS=(
  "/u:$WIN_USER"
  "/p:$WIN_PASS"
  /v:127.0.0.1:3389
  -grab-keyboard
  /sound
  /microphone
  /clipboard
  /cert:ignore
  "/title:Windows VM - Omarchy"
  /dynamic-resolution
  /gfx:AVC444
  "/floatbar:sticky:off,default:visible,show:fullscreen"
)
if [[ -n "$RDP_SCALE" ]]; then
  RDP_ARGS+=("$RDP_SCALE")
fi

# 6. Launch FreeRDP with credentials on stdin (keeps password out of /proc).
printf '%s\n' "${RDP_ARGS[@]}" | xfreerdp3 /args-from:stdin
