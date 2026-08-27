#!/usr/bin/env bash
#
# mavproxy.sh — MAVProxy and pymavlink, the ArduPilot ground-station tooling.
#
# There is no package for these: MAVProxy tracks ArduPilot's own release pace and
# only ever ships on PyPI. Everything lands in ~/.local (mavproxy.py, mavgraph,
# mavlogdump and the rest end up in ~/.local/bin), so nothing here needs root.
#
# ARCH MARKS ITS PYTHON EXTERNALLY MANAGED (PEP 668), which makes plain
# `pip install --user` refuse to run. --break-system-packages is what says "yes,
# I mean my own ~/.local, not /usr/lib/python*" — pacman's files are never
# touched, only ~/.local/lib/python*/site-packages is written to.
#
# The GUI half — the map window, the console, the graphs — is wxPython, matplotlib
# and OpenCV. Those come from pacman rather than pip: the wheels would compile
# wxPython from source for an hour and then link against the wrong wxGTK anyway.
#
# Usage:
#   ./mavproxy.sh          install/upgrade into ~/.local
#   ./mavproxy.sh -n       skip the pacman half, pip only
#
#   PROXY=192.168.49.1:8000 ./mavproxy.sh   over the phone's proxy

set -euo pipefail

PY_PKGS=(MAVProxy pymavlink pyserial)
PAC_PKGS=(python-wxpython python-matplotlib python-opencv python-lxml python-pip)
SKIP_PACMAN=0

usage() { awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "${BASH_SOURCE[0]}"; }
die()   { echo "   ✗ $*" >&2; exit 1; }

while getopts "nh" opt; do
  case "$opt" in
    n) SKIP_PACMAN=1 ;;
    h) usage; exit 0 ;;
    *) exit 1 ;;
  esac
done

PROXY="${PROXY:-${http_proxy:-${https_proxy:-${HTTP_PROXY:-${HTTPS_PROXY:-}}}}}"
if [[ -n "$PROXY" ]]; then
  [[ "$PROXY" == http* ]] || PROXY="http://$PROXY"
  export http_proxy="$PROXY" https_proxy="$PROXY" all_proxy="$PROXY"
  export HTTP_PROXY="$PROXY" HTTPS_PROXY="$PROXY"
fi

if [[ $SKIP_PACMAN -eq 0 ]]; then
  echo ">> GUI dependencies from pacman..."
  if [[ -n "$PROXY" ]]; then
    sudo env http_proxy="$PROXY" https_proxy="$PROXY" HTTP_PROXY="$PROXY" HTTPS_PROXY="$PROXY" \
      pacman -S --needed --noconfirm "${PAC_PKGS[@]}"
  else
    sudo pacman -S --needed --noconfirm "${PAC_PKGS[@]}"
  fi
fi

echo ">> MAVProxy from PyPI into ~/.local..."
pip install --user --upgrade --break-system-packages "${PY_PKGS[@]}" \
  || die "pip failed — if it complains about an externally-managed environment, this script is out of date"

BIN="$HOME/.local/bin"
[[ -x "$BIN/mavproxy.py" ]] || die "installed, but $BIN/mavproxy.py is missing"
echo "   ✔ $("$BIN/mavproxy.py" --version 2>&1 | head -1)"

grep -qx uucp <<<"$(id -nG | tr ' ' '\n')" \
  || echo "   ! not in the uucp group, the flight controller's serial port stays closed:  sudo usermod -aG uucp $USER"

# The alias in the shell package used to point at a virtualenv. If that venv is
# gone the alias is a dead path, and `mavproxy` fails while `mavproxy.py` works.
ALIASES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/shell/.config/zsh/20-aliases.zsh"
if [[ -f "$ALIASES" ]]; then
  target="$(grep -m1 "^alias mavproxy=" "$ALIASES" | cut -d"'" -f2 || true)"
  target="${target/#\~/$HOME}"
  if [[ -n "$target" && ! -x "$target" ]]; then
    echo "   ! the mavproxy alias points at $target, which does not exist"
    echo "     fix it in shell/.config/zsh/20-aliases.zsh:  alias mavproxy='mavproxy.py'"
  fi
fi

echo
echo "   Connect over USB:  mavproxy.py --master=/dev/ttyACM0 --baudrate 115200 --console --map"
