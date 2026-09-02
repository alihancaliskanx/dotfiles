# 20-aliases — shortcuts. The proxy/tor related ones live in 30-proxy.fish.
#
# NOTE: the CachyOS default config maps ls/la/ll/lt to eza. Below, ll and lt are
# made to match the zsh behaviour; if you want eza, delete those two lines and
# the CachyOS ones take effect.

# ── basics ───────────────────────────────────────────────────────────────────
alias c='clear'
alias s='sudo'
alias se='sudo -E'
alias v='vim'
alias n='nvim'
alias t='tmux'
alias f='flatpak'
alias ll='command ls -lah'
alias lt='eza -lT'

# ── ssh ──────────────────────────────────────────────────────────────────────
# kitty uses xterm-kitty as its TERM and remote machines usually lack this
# terminfo; so clear/less/htop/nano break remotely. `kitten ssh` copies the
# terminfo to the remote machine's ~/.terminfo on first connection. Only inside
# kitty; other terminals fall back to plain ssh. kitten ssh only runs interactively,
# so if stdin is not a terminal (piped/scripted use), it falls back to plain ssh.
if set -q KITTY_WINDOW_ID; and type -q kitten
    function ssh --description 'kitten ssh that carries terminfo when inside kitty'
        if isatty stdin
            kitten ssh $argv
        else
            command ssh $argv
        end
    end
end

# ── git ──────────────────────────────────────────────────────────────────────
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gco='git checkout'

# ── config files ─────────────────────────────────────────────────────────────
alias fconf='nvim ~/.config/fish/modules'          # fish module directory
alias reloadfish='source ~/.config/fish/config.fish'
alias zc='nvim ~/.config/zsh'                      # zsh module directory
alias hconfig='nvim ~/.config/hypr/hyprland.conf'
alias terconf='nvim ~/.config/alacritty/alacritty.toml'
alias gconfig='nvim ~/.config/git/config'
alias dotfiles='cd ~/Documents/Code/dotfiles'

# ── pacman / AUR ─────────────────────────────────────────────────────────────
alias yayp='sudo -E yay'
alias pacsil='sudo rm -rf /var/lib/pacman/db.lck'

# ── applications ─────────────────────────────────────────────────────────────
alias code_path='cd ~/Documents/Code'
alias stmcube='pc $HOME/st/stm32cubeide_1.19.0/stm32cubeide_wayland'
alias mavproxy='~/.mavproxy_env/bin/mavproxy.py'

function qgc --description 'QGroundControl in the background'
    ~/Documents/Code/qgroundcontrol/build/Release/QGroundControl >/dev/null 2>&1 &
end

# The 'goo' alias in zsh relied on the oh-my-zsh web-search plugin, which has no
# fish equivalent — search in the browser instead:
function goo --description 'Search on Google'
    xdg-open "https://www.google.com/search?q="(string escape --style=url -- "$argv")
end

# ── windows vm ───────────────────────────────────────────────────────────────
alias win='~/.local/bin/windows-vm-smart-launch.sh'
alias win-stop='~/.local/bin/windows-vm-stop.sh'
alias win-status='omarchy-windows-vm status'
