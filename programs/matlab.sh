#!/usr/bin/env bash
#
# matlab.sh — installs MATLAB the way it actually went onto this machine.
#
# There is no MATLAB package anywhere. MathWorks ships mpm, their own package
# manager: it downloads a release into whatever directory you point it at, and
# needs no license to do so. Activation happens on first start, with a MathWorks
# account.
#
# TWO ARCH-SPECIFIC THINGS BREAK THAT FIRST START, and both are fixed here by
# dropping libraries into MATLAB's own lib directory rather than touching the
# system. MATLAB's RPATH is $ORIGIN, so it loads those copies first and nothing
# else on the machine ever sees them:
#
#   gtk2    left the Arch repos. The login/activation window is a GTK2
#           MATLABWindow, so without libgtk-x11-2.0.so.0 it simply never opens.
#   gnutls  3.8.10 and later break FlexLM's TLS handshake — MATLAB segfaults in
#           lc_new_job. 3.8.9 is the last version that works, and it wants the
#           older libnettle.so.8 / libhogweed.so.6 next to it.
#
# Both come out of the Arch package archive, which keeps every old version
# around; that is why the URLs below are pinned to a version and not to "latest".
#
# IF THE LOGIN WINDOW STILL REFUSES TO COME UP, go around it: activate at
# mathworks.com/licensecenter (Linux, this machine's host ID and login name),
# download the .lic file, and feed it in with `matlab.sh license`. With a license
# file in place MATLAB never reaches for the login window — FlexLM reads the file.
#
# Usage:
#   ./matlab.sh                        R2025b, MATLAB alone
#   ./matlab.sh -r R2024b              a different release
#   ./matlab.sh -p "MATLAB Simulink"   extra products, space separated
#   ./matlab.sh -d ~/MATLAB/R2025b     a different destination
#   ./matlab.sh license [file.lic]     put an offline license in place and test it
#
#   PROXY=192.168.49.1:8000 ./matlab.sh   over the phone's proxy
#
# With sudo it installs into /opt/MATLAB/<release>, without it into
# ~/MATLAB/<release>. MATLAB alone is around 15 GB.

set -euo pipefail

RELEASE="R2025b"
PRODUCTS=(MATLAB)
DEST=""

MPM_URL="https://www.mathworks.com/mpm/glnxa64/mpm"
GTK2_PKG="https://archive.archlinux.org/packages/g/gtk2/gtk2-2.24.33-5-x86_64.pkg.tar.zst"
GNUTLS_PKG="https://archive.archlinux.org/packages/g/gnutls/gnutls-3.8.9-1-x86_64.pkg.tar.zst"
NETTLE_PKG="https://archive.archlinux.org/packages/n/nettle/nettle-3.10.2-1-x86_64.pkg.tar.zst"

usage() { awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "${BASH_SOURCE[0]}"; }
die()   { echo "   ✗ $*" >&2; exit 1; }

PROXY="${PROXY:-${http_proxy:-${https_proxy:-${HTTP_PROXY:-${HTTPS_PROXY:-}}}}}"
if [[ -n "$PROXY" ]]; then
  [[ "$PROXY" == http* ]] || PROXY="http://$PROXY"
  export http_proxy="$PROXY" https_proxy="$PROXY" all_proxy="$PROXY"
  export HTTP_PROXY="$PROXY" HTTPS_PROXY="$PROXY"
  export no_proxy="localhost,127.0.0.1,::1" NO_PROXY="localhost,127.0.0.1,::1"
fi

# ─── license mode ────────────────────────────────────────────────────────────
# Separate path through the script: no download, no install, just a file copy
# and a headless start to prove FlexLM accepted it.
install_license() {
  local src="${1:-}" root="" lic_dir
  for root in "/opt/MATLAB/$RELEASE" "$HOME/MATLAB/$RELEASE"; do
    if [[ -x "$root/bin/matlab" ]]; then break; fi
    root=""
  done
  [[ -n "$root" ]] || die "no MATLAB $RELEASE found (looked in /opt and \$HOME)"

  if [[ -z "$src" ]]; then
    echo ">> Looking for a .lic file in the download folders..."
    src="$(find "$HOME/Downloads" "$HOME/İndirilenler" "$HOME/Desktop" "$HOME/Masaüstü" \
           -maxdepth 1 -iname '*.lic' 2>/dev/null | head -1 || true)"
  fi
  [[ -n "$src" && -f "$src" ]] || die "no license file. Pass it: ./matlab.sh license /path/license.lic"

  # A real FlexLM license opens with one of these keywords. Anything else is
  # usually the activation *key* page saved as text, which MATLAB cannot read.
  grep -qiE '^[[:space:]]*(INCREMENT|SERVER|DAEMON|FEATURE)\b' "$src" \
    || echo "   ! this does not look like a FlexLM license (no INCREMENT/SERVER line)"

  lic_dir="$root/licenses"
  mkdir -p "$lic_dir"
  cp -f "$src" "$lic_dir/license.lic"
  echo "   ✔ $src → $lic_dir/license.lic"

  echo ">> Starting MATLAB headless to check the license..."
  local out
  out="$(MLM_LICENSE_FILE="$lic_dir/license.lic" timeout 120 \
         "$root/bin/matlab" -nodesktop -nosplash -batch "disp(['LICENSE_OK ' version])" \
         </dev/null 2>&1 || true)"
  if grep -q LICENSE_OK <<<"$out"; then
    echo "   ✔ $(grep LICENSE_OK <<<"$out")"
    echo "   MATLAB is ready:  matlab"
    return 0
  fi
  if grep -qi segmentation <<<"$out"; then
    echo "   ✗ still segfaulting — the license was probably issued for another machine." >&2
    echo "     Host ID: $(cat "/sys/class/net/$(ip -o link | awk -F': ' '!/lo/{print $2; exit}')/address" 2>/dev/null | tr -d ':')" >&2
    echo "     Login name: $USER   OS: Linux" >&2
  fi
  echo "$out" | tail -15 >&2
  exit 1
}

if [[ "${1:-}" == "license" ]]; then
  shift
  install_license "${1:-}"
  exit 0
fi

while getopts "r:p:d:h" opt; do
  case "$opt" in
    r) RELEASE="$OPTARG" ;;
    p) read -r -a PRODUCTS <<<"$OPTARG" ;;
    d) DEST="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) exit 1 ;;
  esac
done

[[ "$(uname -m)" == "x86_64" ]] || die "MATLAB on Linux is x86_64 only."

# ─── system-wide or into $HOME ───────────────────────────────────────────────
# Asking for sudo once here decides both the destination and where the symlinks
# and the .desktop file go, so the two halves cannot disagree later.
SUDO=()
SYSTEM=0
if [[ $EUID -eq 0 ]]; then
  SYSTEM=1
elif sudo -n true 2>/dev/null || { [[ -t 0 ]] && sudo -v; }; then
  SUDO=(sudo)
  SYSTEM=1
else
  echo "   ! no sudo — installing into \$HOME/MATLAB instead"
fi

if [[ -z "$DEST" ]]; then
  if [[ $SYSTEM -eq 1 ]]; then DEST="/opt/MATLAB/$RELEASE"; else DEST="$HOME/MATLAB/$RELEASE"; fi
fi

echo "════════════════════════════════════════════════════════════"
echo "  MATLAB $RELEASE  →  $DEST"
echo "  products: ${PRODUCTS[*]}"
if [[ -n "$PROXY" ]]; then echo "  proxy: $PROXY"; fi
echo "════════════════════════════════════════════════════════════"

# ─── dependencies ────────────────────────────────────────────────────────────
# What MATLAB shells out to at runtime rather than what it links against:
# zenity for its dialogs, nss/gtk3 for the CEF-based desktop, libxcrypt-compat
# for the libcrypt.so.1 its binaries still ask for.
DEPS=(ca-certificates curl libxcrypt-compat alsa-lib libxss libxtst nss gtk3 zenity)
if [[ $SYSTEM -eq 1 ]]; then
  echo ">> Dependencies..."
  if [[ -n "$PROXY" ]]; then
    "${SUDO[@]}" env http_proxy="$PROXY" https_proxy="$PROXY" \
      HTTP_PROXY="$PROXY" HTTPS_PROXY="$PROXY" pacman -S --needed --noconfirm "${DEPS[@]}"
  else
    "${SUDO[@]}" pacman -S --needed --noconfirm "${DEPS[@]}"
  fi
else
  missing=()
  for p in "${DEPS[@]}"; do pacman -Q "$p" &>/dev/null || missing+=("$p"); done
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "   ! missing, MATLAB may not start: sudo pacman -S --needed ${missing[*]}"
  fi
fi

# ─── room on disk ────────────────────────────────────────────────────────────
parent="$DEST"
while [[ ! -d "$parent" ]]; do parent="$(dirname "$parent")"; done
avail="$(df -BG --output=avail "$parent" | tail -1 | tr -dc '0-9')"
[[ "$avail" -ge 15 ]] || die "only ${avail}GB free on $parent, MATLAB alone wants 15GB"

# ─── mpm ─────────────────────────────────────────────────────────────────────
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo ">> mpm (MATLAB Package Manager)..."
curl -fL --retry 3 -o "$TMP/mpm" "$MPM_URL" || die "could not download mpm"
chmod +x "$TMP/mpm"

echo ">> Installing MATLAB $RELEASE — several GB, this takes a while..."
"${SUDO[@]}" mkdir -p "$DEST"
# mpm runs as the invoking user, so the destination has to belong to them.
if [[ ${#SUDO[@]} -gt 0 ]]; then "${SUDO[@]}" chown "$USER" "$DEST"; fi
"$TMP/mpm" install --release="$RELEASE" --destination="$DEST" --products "${PRODUCTS[@]}" \
  || die "mpm failed — log: /tmp/mathworks_$USER.log"
[[ -x "$DEST/bin/matlab" ]] || die "installed, but $DEST/bin/matlab is missing"

# ─── the two Arch fixes (see the header) ─────────────────────────────────────
GX="$DEST/bin/glnxa64"
fetch_pkg() {  # url → prints the directory it was extracted into
  local url="$1" td
  td="$(mktemp -d)"
  curl -fL --retry 3 -o "$td/pkg.tar.zst" "$url" >/dev/null 2>&1 || return 1
  tar -xf "$td/pkg.tar.zst" -C "$td" || return 1
  echo "$td"
}

# Read into a variable rather than piping into `grep -q`: grep exits at the
# first match, ldconfig dies of SIGPIPE, and under `pipefail` that reads as a
# failed pipeline — the test would always claim gtk2 is missing.
libs="$(ldconfig -p 2>/dev/null || true)"
if ! grep -q 'libgtk-x11-2.0.so.0' <<<"$libs"; then
  echo ">> No GTK2 on the system — copying it into MATLAB (for the login window)..."
  if t="$(fetch_pkg "$GTK2_PKG")"; then
    cp -a "$t"/usr/lib/libgtk-x11-2.0.so* "$t"/usr/lib/libgdk-x11-2.0.so* "$GX/"
    rm -rf "$t"
    echo "   ✔ gtk2 → $GX"
  else
    echo "   ! could not fetch gtk2 — the login window may not open"
  fi
fi

# sort -VC succeeds when the list is already in version order, so this is true
# exactly when the installed gnutls is 3.8.10 or newer — the versions that break
# FlexLM.
gnutls_ver="$(pacman -Q gnutls 2>/dev/null | awk '{print $2}')"
gnutls_ver="${gnutls_ver%%-*}"
if [[ -n "$gnutls_ver" ]] && printf '3.8.10\n%s\n' "$gnutls_ver" | sort -VC; then
  echo ">> gnutls $gnutls_ver breaks FlexLM — copying 3.8.9 into MATLAB..."
  if t="$(fetch_pkg "$GNUTLS_PKG")"; then
    cp -a "$t"/usr/lib/libgnutls.so* "$t"/usr/lib/libgnutlsxx.so* "$t"/usr/lib/libgnutls-openssl.so* "$GX/"
    rm -rf "$t"
    if n="$(fetch_pkg "$NETTLE_PKG")"; then
      cp -a "$n"/usr/lib/libnettle.so.8* "$n"/usr/lib/libhogweed.so.6* "$GX/"
      rm -rf "$n"
    fi
    echo "   ✔ gnutls 3.8.9 + nettle 3.10 → $GX"
  else
    echo "   ! could not fetch gnutls 3.8.9 — activation may segfault"
  fi
fi

# ─── symlinks and menu entry ─────────────────────────────────────────────────
if [[ $SYSTEM -eq 1 ]]; then
  BIN=/usr/local/bin
  "${SUDO[@]}" ln -sfn "$DEST/bin/matlab" "$BIN/matlab"
  "${SUDO[@]}" ln -sfn "$DEST/bin/mex" "$BIN/mex"
else
  BIN="$HOME/.local/bin"
  mkdir -p "$BIN"
  ln -sfn "$DEST/bin/matlab" "$BIN/matlab"
  ln -sfn "$DEST/bin/mex" "$BIN/mex"
fi
echo "   ✔ $BIN/matlab → $DEST/bin/matlab"

ICON="$(find "$DEST" -maxdepth 5 -iname 'matlab*icon*.png' 2>/dev/null | head -1 || true)"
ENTRY="[Desktop Entry]
Type=Application
Name=MATLAB $RELEASE
Comment=MATLAB technical computing environment
Exec=$DEST/bin/matlab -desktop
Terminal=false
Categories=Development;Science;Math;
StartupNotify=true
${ICON:+Icon=$ICON}"
if [[ $SYSTEM -eq 1 ]]; then
  echo "$ENTRY" | "${SUDO[@]}" tee /usr/share/applications/matlab.desktop >/dev/null
else
  mkdir -p "$HOME/.local/share/applications"
  echo "$ENTRY" > "$HOME/.local/share/applications/matlab.desktop"
fi

# `matlab -h` exits 1 by design, so the usage text is what proves it runs.
help_out="$("$DEST/bin/matlab" -h 2>&1 || true)"
grep -q "Usage:" <<<"$help_out" || echo "   ! matlab -h printed no usage — check the install"

echo
echo "   ✔ MATLAB $RELEASE installed: $DEST"
echo "   Sign in with your MathWorks account on the first start:  matlab"
echo "   If that window will not open:  ./matlab.sh license /path/license.lic"
echo "   Graphics trouble:  matlab -softwareopengl"
