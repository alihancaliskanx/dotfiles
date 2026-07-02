#!/usr/bin/env bash
#
# install-hyprland.sh — CachyOS/Arch üzerine Hyprland ekosistemini kurar.
# Proxy üzerinden çalışır (telefon/USB tethering). KDE'ye DOKUNMAZ; yan yana kurulur,
# oturumu girişte (SDDM/plasmalogin) seçersin.
#
# Kullanım:   ./install-hyprland.sh
# (sudo şifresi sorulur; proxy pacman'e sudo env ile geçirilir)

set -euo pipefail

# ─────────────────────────────────────────────────────────────
# Proxy (telefon tethering). Değiştirmek istersen burayı düzenle.
# ─────────────────────────────────────────────────────────────
PROXY="${PROXY:-http://192.168.49.1:8000}"

export http_proxy="$PROXY"  https_proxy="$PROXY"  ftp_proxy="$PROXY"  all_proxy="$PROXY"
export HTTP_PROXY="$PROXY"  HTTPS_PROXY="$PROXY"
export no_proxy="localhost,127.0.0.1,::1,192.168.49.1"
export NO_PROXY="$no_proxy"

# ─────────────────────────────────────────────────────────────
# Paketler (hepsi CachyOS/extra depolarında; AUR gerekmez)
# ─────────────────────────────────────────────────────────────
PKGS=(
  # Hyprland çekirdek
  hyprland hyprlock hypridle hyprpaper
  xdg-desktop-portal-hyprland hyprpolkitagent
  # Bar / bildirim / OSD / launcher   (mako zaten kurulu)
  waybar swayosd walker
  # Terminal                          (alacritty zaten kurulu)
  kitty
  # Wayland / Qt
  qt5-wayland qt6-wayland
  # Araçlar: parlaklık, medya, ses, pano, ekran görüntüsü, renk seçici
  brightnessctl playerctl pamixer
  wl-clipboard cliphist grim slurp swappy hyprpicker
  # Font
  ttf-jetbrains-mono-nerd
)

echo "════════════════════════════════════════════════════════════"
echo "  Hyprland kurulumu (CachyOS)  —  proxy: $PROXY"
echo "  Paketler: ${#PKGS[@]} adet"
echo "════════════════════════════════════════════════════════════"

# ─────────────────────────────────────────────────────────────
# 1) Proxy erişilebilir mi? (10 sn timeout)
# ─────────────────────────────────────────────────────────────
echo ">> Proxy bağlantısı test ediliyor..."
if curl -x "$PROXY" -s -o /dev/null -w '%{http_code}' --max-time 10 https://archlinux.org | grep -qE '^(200|301|302)$'; then
  echo "   ✔ Proxy çalışıyor."
else
  echo "   ✗ Proxy üzerinden internete ulaşılamadı ($PROXY)."
  echo "     Telefonda proxy/hotspot açık mı? IP:port doğru mu? Kontrol edip tekrar dene."
  read -rp "   Yine de devam edilsin mi? [e/H] " ans
  [[ "${ans,,}" == "e" ]] || { echo "İptal edildi."; exit 1; }
fi

# ─────────────────────────────────────────────────────────────
# 2) pacman ile kurulum
#    pacman root olarak çalışır → proxy env'ini 'sudo env' ile içeri veriyoruz.
#    -Syu: kısmi yükseltme (partial upgrade) riskini önlemek için tam senkron+yükseltme
#          (Arch'te doğru yöntem). Sadece kurmak istersen -Syu yerine -S kullan.
# ─────────────────────────────────────────────────────────────
echo ">> pacman başlatılıyor (sudo şifresi sorulabilir)..."
sudo env \
  http_proxy="$PROXY"   https_proxy="$PROXY" \
  HTTP_PROXY="$PROXY"   HTTPS_PROXY="$PROXY" \
  all_proxy="$PROXY"    no_proxy="$no_proxy" \
  pacman -Syu --needed "${PKGS[@]}"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  ✅ Kurulum bitti."
echo ""
echo "  Sıradaki adımlar:"
echo "   • Henüz config YOK → çıkış yapıp Hyprland oturumuna geçme."
echo "     Önce dotfiles yapısını + configleri kuracağız (bir sonraki adım)."
echo "   • KDE oturumun olduğu gibi duruyor; hiçbir KDE dosyasına dokunulmadı."
echo "════════════════════════════════════════════════════════════"
