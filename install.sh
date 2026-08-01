#!/usr/bin/env bash
#
# install.sh — prepares a clean CachyOS/Arch machine for these dotfiles.
#
# Usage:
#   ./install.sh                 asks for the profile
#   ./install.sh hyprland        Hyprland desktop + common packages
#   ./install.sh niri            niri desktop + common packages
#   ./install.sh kde             common packages only (if KDE is already installed)
#
# If you are behind a proxy such as PdaNet:
#   PROXY=192.168.49.1:8000 ./install.sh hyprland
#   (or it is picked up automatically if http_proxy is already exported)

set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

PROXY="${PROXY:-${http_proxy:-${https_proxy:-${HTTP_PROXY:-${HTTPS_PROXY:-}}}}}"
if [[ -n "$PROXY" ]]; then
  [[ "$PROXY" == http* ]] || PROXY="http://$PROXY"
  export http_proxy="$PROXY" https_proxy="$PROXY" ftp_proxy="$PROXY" all_proxy="$PROXY"
  export HTTP_PROXY="$PROXY" HTTPS_PROXY="$PROXY"
  export no_proxy="localhost,127.0.0.1,::1"
  export NO_PROXY="$no_proxy"
fi

# ─── profile ─────────────────────────────────────────────────────────────────
PROFILE="${1:-}"
if [[ -z "$PROFILE" ]]; then
  echo "Which desktop profile?  [1] hyprland  [2] niri  [3] kde"
  read -rp "  choice (1-3): " sel
  case "$sel" in
    1) PROFILE=hyprland ;;
    2) PROFILE=niri ;;
    3) PROFILE=kde ;;
    *) echo "Invalid choice."; exit 1 ;;
  esac
fi
case "$PROFILE" in
  hyprland|niri|kde) ;;
  *) echo "Unknown profile: $PROFILE  (hyprland|niri|kde)"; exit 1 ;;
esac

# ─── packages ────────────────────────────────────────────────────────────────
# Everything needed in every profile, independent of the desktop.
PKGS=(
  # terminals and editor
  kitty alacritty ghostty neovim
  # shells and what .zshrc/config.fish directly need
  zsh fish fzf eza git
  # network / proxy tools — net-proxy, tor-net, tor-control rely on these
  tor proxychains-ng gum corkscrew
  # cli
  btop cava
  # wayland common
  qt5-wayland qt6-wayland
  brightnessctl playerctl pamixer
  wl-clipboard cliphist grim slurp swappy
  # gui helpers
  dolphin pavucontrol nm-connection-editor
  ttf-jetbrains-mono-nerd
)

# Hyprland and niri share the same bar/launcher/notification stack.
WM_SHARED=(waybar swayosd fuzzel mako hyprlock hypridle xdg-desktop-portal-gtk)

case "$PROFILE" in
  hyprland)
    PKGS+=("${WM_SHARED[@]}"
           hyprland hyprpaper hyprpicker
           xdg-desktop-portal-hyprland hyprpolkitagent)
    ;;
  niri)
    PKGS+=("${WM_SHARED[@]}"
           niri xwayland-satellite
           xdg-desktop-portal-gnome hyprpolkitagent)
    ;;
  kde)
    # KDE is assumed to be installed already; only the common packages go in.
    ;;
esac

# Nothing from the AUR is needed any more. walker used to require the 9
# elephant-* backend packages; fuzzel replaced it and lives in the repos.
# The block below still works if you ever add something here.
AUR_PKGS=()

echo "════════════════════════════════════════════════════════════"
echo "  dotfiles install  —  profile: $PROFILE"
if [[ -n "$PROXY" ]]; then
  echo "  proxy: $PROXY"
else
  echo "  direct connection"
fi
echo "  ${#PKGS[@]} pacman packages + ${#AUR_PKGS[@]} AUR packages"
echo "════════════════════════════════════════════════════════════"

echo ">> Testing the internet connection..."
if curl -s -o /dev/null -w '%{http_code}' --max-time 10 https://archlinux.org | grep -qE '^(200|301|302)$'; then
  echo "   ✔ Connection works."
else
  echo "   ✗ Could not reach the internet${PROXY:+ (proxy: $PROXY)}."
  read -rp "   Continue anyway? [y/N] " ans
  [[ "${ans,,}" == "y" ]] || { echo "Cancelled."; exit 1; }
fi

echo ">> Starting pacman (it may ask for your sudo password)..."
if [[ -n "$PROXY" ]]; then
  sudo env \
    http_proxy="$PROXY" https_proxy="$PROXY" \
    HTTP_PROXY="$PROXY" HTTPS_PROXY="$PROXY" \
    all_proxy="$PROXY" no_proxy="$no_proxy" \
    pacman -Syu --needed "${PKGS[@]}"
else
  sudo pacman -Syu --needed "${PKGS[@]}"
fi

if [[ ${#AUR_PKGS[@]} -gt 0 ]]; then
  echo ">> Installing AUR packages..."
  if command -v paru >/dev/null; then
    paru -S --needed "${AUR_PKGS[@]}"
  elif command -v yay >/dev/null; then
    yay -S --needed "${AUR_PKGS[@]}"
  else
    echo "   ! paru/yay not found, install the AUR packages by hand: ${AUR_PKGS[*]}"
  fi
fi

# ─── oh-my-zsh + plugins ─────────────────────────────────────────────────────
# shell/.config/zsh/10-plugins.zsh expects these. If they are not installed zsh
# prints a warning on startup but does not blow up.
echo ">> oh-my-zsh and zsh plugins..."

OMZ="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$OMZ/custom"

clone_if_missing() {
  local url="$1" dest="$2"
  if [[ -d "$dest" ]]; then
    echo "   • $(basename "$dest") already exists"
  else
    echo "   ↓ $(basename "$dest")"
    git clone --depth=1 "$url" "$dest" >/dev/null 2>&1 \
      || echo "     ! could not clone: $url"
  fi
}

clone_if_missing https://github.com/ohmyzsh/ohmyzsh.git "$OMZ"
mkdir -p "$ZSH_CUSTOM/themes" "$ZSH_CUSTOM/plugins"
clone_if_missing https://github.com/romkatv/powerlevel10k.git                  "$ZSH_CUSTOM/themes/powerlevel10k"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting.git      "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions.git          "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/MichaelAquilina/zsh-you-should-use.git     "$ZSH_CUSTOM/plugins/you-should-use"
clone_if_missing https://github.com/marlonrichert/zsh-autocomplete.git         "$ZSH_CUSTOM/plugins/zsh-autocomplete"
clone_if_missing https://github.com/MichaelAquilina/zsh-autoswitch-virtualenv.git "$ZSH_CUSTOM/plugins/autoswitch_virtualenv"

# ─── link the configs ────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════════"
echo "  ✅ Package installation finished."
echo "════════════════════════════════════════════════════════════"
echo ""
read -rp "  Link the configs now? (./link.sh profile $PROFILE) [Y/n] " ans
if [[ "${ans,,}" != "n" ]]; then
  "$REPO/link.sh" profile "$PROFILE"
else
  echo "  To link them later:  $REPO/link.sh profile $PROFILE"
fi

cat <<EOF

  Remaining manual steps
  ──────────────────────
  • ssh-agent:      systemctl --user enable --now ssh-agent
  • try fish:       $REPO/link.sh link fish   and   chsh -s /usr/bin/fish
  • nvim:           LazyVim plugins install themselves on first launch (:Lazy sync)
  • powerlevel10k:  to change the prompt run  p10k configure
  • GTK theme:      $REPO/link.sh -f link gtk   (overwrites KDE's, see the README)
  • The KDE session was left alone; you can pick $PROFILE from the session selector at login.

EOF
