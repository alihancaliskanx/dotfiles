#!/usr/bin/env bash
set -euo pipefail

PROXY="${PROXY:-${http_proxy:-${https_proxy:-${HTTP_PROXY:-${HTTPS_PROXY:-}}}}}"

if [[ -n "$PROXY" ]]; then
  export http_proxy="$PROXY" https_proxy="$PROXY" ftp_proxy="$PROXY" all_proxy="$PROXY"
  export HTTP_PROXY="$PROXY" HTTPS_PROXY="$PROXY"
  export no_proxy="localhost,127.0.0.1,::1"
  export NO_PROXY="$no_proxy"
fi

PKGS=(
  hyprland hyprlock hypridle hyprpaper
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk hyprpolkitagent
  waybar swayosd walker mako
  kitty alacritty ghostty
  qt5-wayland qt6-wayland
  brightnessctl playerctl pamixer
  wl-clipboard cliphist grim slurp swappy hyprpicker
  btop cava neovim
  nautilus pavucontrol nm-connection-editor
  stow
  ttf-jetbrains-mono-nerd
)

AUR_PKGS=(
  elephant-bin
  elephant-desktopapplications-bin
  elephant-runner-bin
  elephant-calc-bin
  elephant-symbols-bin
  elephant-websearch-bin
  elephant-files-bin
  elephant-menus-bin
  elephant-clipboard-bin
)

echo "════════════════════════════════════════════════════════════"
if [[ -n "$PROXY" ]]; then
  echo "  Hyprland kurulumu (CachyOS)  —  proxy: $PROXY"
else
  echo "  Hyprland kurulumu (CachyOS)  —  doğrudan bağlantı"
fi
echo "  Paketler: ${#PKGS[@]} adet + ${#AUR_PKGS[@]} AUR"
echo "════════════════════════════════════════════════════════════"

echo ">> İnternet bağlantısı test ediliyor..."
if curl -s -o /dev/null -w '%{http_code}' --max-time 10 https://archlinux.org | grep -qE '^(200|301|302)$'; then
  echo "   ✔ Bağlantı çalışıyor."
else
  echo "   ✗ İnternete ulaşılamadı${PROXY:+ (proxy: $PROXY)}."
  read -rp "   Yine de devam edilsin mi? [e/H] " ans
  [[ "${ans,,}" == "e" ]] || { echo "İptal edildi."; exit 1; }
fi

echo ">> pacman başlatılıyor (sudo şifresi sorulabilir)..."
if [[ -n "$PROXY" ]]; then
  sudo env \
    http_proxy="$PROXY" https_proxy="$PROXY" \
    HTTP_PROXY="$PROXY" HTTPS_PROXY="$PROXY" \
    all_proxy="$PROXY" no_proxy="$no_proxy" \
    pacman -Syu --needed "${PKGS[@]}"
else
  sudo pacman -Syu --needed "${PKGS[@]}"
fi

echo ">> AUR paketleri kuruluyor..."
if command -v paru >/dev/null; then
  paru -S --needed "${AUR_PKGS[@]}"
elif command -v yay >/dev/null; then
  yay -S --needed "${AUR_PKGS[@]}"
else
  echo "   ! paru/yay bulunamadı, AUR paketlerini elle kur: ${AUR_PKGS[*]}"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  ✅ Paket kurulumu bitti."
echo ""
echo "  Configleri bağlamak için:"
echo "    cd $(dirname "${BASH_SOURCE[0]}") && stow -t ~ ."
echo ""
echo "  • KDE oturumuna dokunulmadı; girişte Hyprland'i seçebilirsin."
echo "════════════════════════════════════════════════════════════"
