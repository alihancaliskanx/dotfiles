#!/usr/bin/env bash
#
# windows-vm-stop.sh
# ------------------------------------------------------------------------------
# Gracefully stops the Windows VM:
# 1. Closes any open FreeRDP client windows.
# 2. Sends notification.
# 3. Stops the Docker container safely.
# ------------------------------------------------------------------------------

set -eo pipefail

omarchy-shell osd show '{"icon":"󰐥","message":"Stopping Windows VM..."}' 2>/dev/null || true

# 1. Close FreeRDP window if open
pkill -f "xfreerdp.*127.0.0.1:3389" 2>/dev/null || true

# 2. Stop the container
COMPOSE_FILE="/var/lib/omarchy/windows/docker-compose.yml"
if [[ ! -f "$COMPOSE_FILE" ]]; then
  COMPOSE_FILE="$HOME/.config/windows/docker-compose.yml"
fi

if [[ -f "$COMPOSE_FILE" ]]; then
  docker compose -f "$COMPOSE_FILE" stop 2>/dev/null || docker stop omarchy-windows 2>/dev/null || true
else
  docker stop omarchy-windows 2>/dev/null || true
fi

omarchy-shell osd show '{"icon":"󰍲","message":"Windows VM Stopped"}' 2>/dev/null || true
echo "Windows VM stopped successfully."
