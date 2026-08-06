# 20-aliases — shortcuts. The proxy/tor related ones live in 30-proxy.zsh.

# ── basics ───────────────────────────────────────────────────────────────────
alias c='clear'
alias s='sudo'
alias se='sudo -E'
alias v='vim'
alias n='nvim'
alias t='tmux'
alias f='flatpak'
alias ll='ls -lah'
alias lt='eza -lT'

# ── ssh ──────────────────────────────────────────────────────────────────────
# kitty TERM'i olarak xterm-kitty kullanıyor ve karşı tarafta bu terminfo genelde
# yok; o yüzden clear/less/htop/nano uzakta bozuluyor. `kitten ssh` ilk bağlantıda
# terminfo'yu karşı makinenin ~/.terminfo dizinine kopyalıyor. Sadece kitty
# içindeyken; diğer terminallerde düz ssh kalıyor. kitten ssh sadece interaktif
# çalıştığı için stdin terminal değilse (borulu/scriptli kullanım) düz ssh'a düşüyor.
if [[ -n $KITTY_WINDOW_ID ]] && (( $+commands[kitten] )); then
  ssh() {
    if [[ -t 0 ]]; then
      kitten ssh "$@"
    else
      command ssh "$@"
    fi
  }
fi

# ── git ──────────────────────────────────────────────────────────────────────
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gco='git checkout'

# ── config files ─────────────────────────────────────────────────────────────
alias zc='nvim ~/.config/zsh'                      # zsh module directory
alias reloadzsh='source ~/.zshrc'
alias hconfig='nvim ~/.config/hypr/hyprland.conf'
alias nconfig='nvim ~/.config/niri/config.kdl'
alias terconf='nvim ~/.config/alacritty/alacritty.toml'
alias gconfig='nvim ~/.config/git/config'
alias dotfiles='cd ~/Documents/Code/dotfiles'

# ── pacman / AUR ─────────────────────────────────────────────────────────────
alias yayp='sudo -E yay'
alias pacsil='sudo rm -rf /var/lib/pacman/db.lck'

# ── applications ─────────────────────────────────────────────────────────────
alias goo=google
alias code_path='cd ~/Documents/Code'
alias qgc='~/Documents/Code/qgroundcontrol/build/Release/QGroundControl > /dev/null 2>&1 &'
alias stmcube='pc $HOME/st/stm32cubeide_1.19.0/stm32cubeide_wayland'
alias mavproxy='~/.mavproxy_env/bin/mavproxy.py'
