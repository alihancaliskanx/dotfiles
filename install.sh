#!/usr/bin/env bash
#
# install.sh — prepares a clean CachyOS/Arch machine for these dotfiles.
#
# Usage:
#   ./install.sh                 asks for the profile
#   ./install.sh hyprland        Hyprland desktop + common packages
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
  echo "Which desktop profile?  [1] hyprland  [2] kde"
  read -rp "  choice (1-3): " sel
  case "$sel" in
    1) PROFILE=hyprland ;;
    2) PROFILE=kde ;;
    *) echo "Invalid choice."; exit 1 ;;
  esac
fi
case "$PROFILE" in
  hyprland|kde) ;;
  *) echo "Unknown profile: $PROFILE  (hyprland|kde)"; exit 1 ;;
esac

# ─── packages ────────────────────────────────────────────────────────────────
# Everything needed in every profile, independent of the desktop.
PKGS=(
  # terminals and editor
  kitty alacritty ghostty neovim
  # shells and what .zshrc/config.fish directly need
  zsh fish fzf eza git
  # network / proxy tools — net-proxy, tor-net, tor-control rely on these.
  # net-proxy tunnels ssh through corkscrew, or ncat (from nmap) if corkscrew
  # is not around — the fallback was silently in use on this machine.
  # net-tunnel is built out of these two: glider does the redir->HTTP-CONNECT
  # forwarding, nftables holds the redirect table. (Not redsocks — see the
  # net-tunnel section of the README for why.)
  tor proxychains-ng gum corkscrew nftables glider
  # what the scripts package shells out to and nothing else pulls in: jq
  # (window-switch, hotkeys, the force-kill and screenshot bindings),
  # powerprofilesctl (power-profile), notify-send (libnotify)
  jq libnotify power-profiles-daemon
  # cli
  btop cava fastfetch glances duf ripgrep tmux vim micro termscp superfile
  # wayland common
  qt5-wayland qt6-wayland
  brightnessctl playerctl pamixer
  wl-clipboard cliphist grim slurp satty swappy xsettingsd
  # KDE integration outside Plasma: Qt apps read kdeglobals, and kdialog and
  # kio-admin are what KDE apps shell out to. The portal file dialog is pinned
  # to gtk in *-portals.conf, so the kde backend is not what serves it.
  xdg-desktop-portal-kde kdialog kio-admin
  # the icon theme kdeglobals names. Without it Qt has no Inherits chain to
  # follow and falls through to hicolor, which carries app icons and none of
  # the freedesktop naming-spec ones — Konsole, KCalc and a dozen others lose
  # their icon and draw a placeholder instead.
  papirus-icon-theme
  # libadwaita's stylesheet ported to GTK3, so a GTK3 window takes its colours
  # from the @define-color block in gtk-3.0/gtk.css instead of hardcoding them.
  # That is what lets the caelestia rice recolour GTK applications from the
  # wallpaper; every other theme ignores the file and stays as it was.
  adw-gtk-theme
  # gui helpers
  nautilus dolphin pavucontrol nm-connection-editor network-manager-applet
  filelight partitionmanager btrfs-assistant snapper ffmpegthumbnailer
  # fonts
  ttf-jetbrains-mono-nerd ttf-meslo-nerd
  # development
  cmake ninja ccache docker docker-compose github-cli meld luarocks
  qemu-full virt-manager paru yay
  # embedded / ArduPilot toolchain
  arm-none-eabi-gcc arm-none-eabi-binutils arm-none-eabi-newlib stlink
  # ai
  claude-code
  # network and security
  nmap wireshark-qt bettercap wifite dnscrypt-proxy ufw ufw-extras putty
  torbrowser-launcher networkmanager-openvpn xl2tpd speedtest-cli
  # bluetooth
  bluez bluez-utils bluedevil
  # applications
  firefox chromium discord webcord telegram-desktop
  # the viewer and the player mimeapps.list makes default; both were only here
  # by accident before (gwenview via a KDE pull-in, mpv via ani-cli), and a
  # machine that missed them fell back to opening images in a sandboxed Zen
  gwenview mpv
  vlc vlc-plugins-all obs-studio obs-studio-plugin-browser obs-gstreamer
  gimp drawio-desktop qbittorrent localsend impression gnome-text-editor
  motion shelly winboat
  # system and quality of life
  flatpak xdg-user-dirs profile-sync-daemon
  nano-syntax-highlighting zsh-autocomplete
)

# The bar/launcher/notification stack, and the wallpaper daemon.
WM_SHARED=(waybar swayosd fuzzel mako hyprlock hypridle hyprpaper xdg-desktop-portal-gtk)

case "$PROFILE" in
  hyprland)
    PKGS+=("${WM_SHARED[@]}"
           hyprland hyprpicker
           xdg-desktop-portal-hyprland hyprpolkitagent)
    ;;
  kde)
    # KDE is assumed to be installed already; only the common packages go in.
    ;;
esac

# walker used to require the 9 elephant-* backend packages; fuzzel replaced it
# and lives in the repos. What is left needs paru or yay — the block below says
# so and carries on if neither is installed.
AUR_PKGS=(
  # editors: the official VS Code build is the one the settings in the vscode
  # package are written for (code-oss ships a different marketplace and half
  # the extension ids resolve to nothing)
  visual-studio-code-bin claude-desktop-bin
  # drone / ArduPilot
  ardupilot-mission-planner qgroundcontrol-bin qgroundcontrol-appimage
  python-pymavlink-git
  # security research
  ida-free backdoor-apk blackarch-mirrorlist redsocks
  # this laptop's hardware
  tuxedo-drivers-dkms tuxedo-control-center-bin
  # applications
  stremio ani-cli manga-tui legacylauncher appimagelauncher termius
  gnome-network-displays platypus gem debtap
  # music: a terminal player that speaks MPRIS, so the media keys and waybar's
  # mpris module drive it without any glue
  cliamp-bin
  # the caelestia rice (./link.sh rice caelestia). Its shell is not a config
  # tree to symlink but a quickshell config compiled against a C++ plugin, so
  # the AUR package is the whole of it; the CLI is the `caelestia` command its
  # keybindings call and what starts the shell. Only the Hyprland half is a
  # checkout, cloned below.
  #
  # caelestia-shell depends on quickshell-git, which replaces the quickshell
  # package the imperative-dots rice runs on. It provides the same two binaries
  # (quickshell, qs), so that rice keeps working — but this is the line that
  # swaps it, in case a later quickshell-git ever breaks it.
  caelestia-shell caelestia-cli
)

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

# ─── flatpak ─────────────────────────────────────────────────────────────────
# Zen — the browser Mod+B opens and mimeapps.list points at — is a flatpak, not
# a pacman package. Without this step a fresh machine has no browser at all.
# The list is written by `pkg-snapshot save`.
FLATPAK_LIST="$REPO/extras/flatpak-apps.txt"
if [[ -f "$FLATPAK_LIST" ]] && command -v flatpak >/dev/null; then
  echo ">> Flatpak apps..."
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
    || echo "   ! could not add the flathub remote"
  while IFS=$'\t' read -r origin app; do
    [[ -n "$app" ]] || continue
    echo "   ↓ $app"
    flatpak install -y "$origin" "$app" >/dev/null 2>&1 || echo "     ! could not install: $app"
  done < "$FLATPAK_LIST"
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

# ─── rices ───────────────────────────────────────────────────────────────────
# link.sh links a rice straight out of its own checkout, so the checkout has to
# exist before `./link.sh rice caelestia` can do anything. Only caelestia is
# cloned here: imperative-dots is a fork of the user's own, pushed to over ssh,
# and cloning it read-only over https would put the wrong remote in place.
#
# This is the clone link.sh reads, not the one `caelestia install` makes for
# itself under ~/.local/state. Do not run that command: it copies these dots
# over ~/.config, which is this script's job and has no way back.
echo ">> rice checkouts..."
clone_if_missing https://github.com/caelestia-dots/caelestia.git "$HOME/Documents/Code/caelestia"

# ─── desktop settings that are not files ─────────────────────────────────────
# The portal reads the GTK theme out of gsettings, not out of gtk-3.0/settings.ini
# — org.freedesktop.impl.portal.Settings is pinned to the gtk backend in
# *-portals.conf and that backend answers from gsettings. So a name here that is
# not an installed theme leaves every portal dialog unstyled: the Open/Save
# window comes up with GTK's bare built-in look while every other GTK app is
# themed, which is confusing precisely because it is only the dialogs.
#
# adw-gtk3-dark, because it is the only GTK3 theme that reads the colours the
# caelestia rice regenerates from the wallpaper: it is libadwaita's stylesheet
# ported to GTK3, so the @define-color block in gtk-3.0/gtk.css reaches it. Every
# other theme hardcodes its palette and ignores that file. Naming a theme that is
# not installed is worse than naming none, so adw-gtk-theme is in the list above.
echo ">> desktop settings..."
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true

# GTK3 itself does not read gsettings — it reads settings.ini, and over the top of
# that whatever xsettingsd is serving. Both of those belong to kde-gtk-config's
# kded module, which regenerates them from kdeglobals at every login and cannot be
# talked out of it: [Module-gtkconfig] autoload=false in kdedrc is ignored, tested
# on a clean kded6 start. So these two files are deliberately NOT in the repo.
# Symlinking them only means the module writes through the symlink and the repo
# gets a login's worth of churn in it.
#
# What the module does do is merge rather than overwrite: it keeps a theme name it
# finds and adds its own keys around it. So the name only has to be put there once,
# which is what this is. From then on the module carries it forward, and the shell
# recolours the theme through gtk.css without touching the name.
for v in 3.0 4.0; do
    ini="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-$v/settings.ini"
    mkdir -p "${ini%/*}"
    [ -f "$ini" ] || printf '[Settings]\n' > "$ini"
    grep -q '^gtk-application-prefer-dark-theme=' "$ini" ||
        sed -i '1a gtk-application-prefer-dark-theme=true' "$ini"
    # GTK4 gets no theme name: adw-gtk3 is GTK3 only, and a GTK4 application either
    # uses libadwaita, which ignores the name, or falls back to Adwaita — and both
    # take their colours from the same regenerated gtk.css.
    [ "$v" = 3.0 ] || continue
    if grep -q '^gtk-theme-name=' "$ini"; then
        sed -i 's/^gtk-theme-name=.*/gtk-theme-name=adw-gtk3-dark/' "$ini"
    else
        sed -i '1a gtk-theme-name=adw-gtk3-dark' "$ini"
    fi
done

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
  • VS Code:        code-extensions install   (the 30 extensions in extras/)
  • the rest:       pkg-snapshot install      (everything this machine had, beyond the curated list)
  • powerlevel10k:  to change the prompt run  p10k configure
  • GTK theme:      $REPO/link.sh -f link gtk   (overwrites KDE's, see the README)
  • The KDE session was left alone; you can pick $PROFILE from the session selector at login.

EOF
