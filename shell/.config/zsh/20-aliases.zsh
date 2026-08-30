# 20-aliases — shortcuts. The proxy/tor related ones live in 30-proxy.zsh.

# ── basics ───────────────────────────────────────────────────────────────────
alias cl='clear'
alias s='sudo'
alias se='sudo -E'
alias v='vim'
alias n='nvim'
alias t='tmux'
alias f='flatpak'
alias c='clear'

# ── eza (better ls) ─────────────────────────────────────────────────────────
if command -v eza &>/dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias ll='eza -lah --group-directories-first --icons=auto'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
else
  alias ll='ls -lah'
  alias lt='ls -lT'
fi

# ── fzf preview ──────────────────────────────────────────────────────────────
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
alias eff='$EDITOR "$(ff)"'

# ── directory navigation ────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ── ssh ──────────────────────────────────────────────────────────────────────
# kitty TERM'i olarak xterm-kitty kullanıyor ve karşı tarafta bu terminfo genelde
# yok; o yüzden clear/less/htop/nano uzakta bozuluyor. `kitten ssh` ilk bağlantıda
# terminfo'yu karşı makinenin ~/.terminfo dizinine kopyalıyor. Sadece kitty
# içindeyken; diğer terminallerde düz ssh kalıyor.
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
alias g='git'
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gco='git checkout'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

# ── config files ─────────────────────────────────────────────────────────────
alias zc='nvim ~/.config/zsh'                      # zsh module directory
alias reloadzsh='exec zsh'
alias hconfig='nvim ~/.config/hypr/hyprland.conf'
alias terconf='nvim ~/.config/alacritty/alacritty.toml'
alias gconfig='nvim ~/.config/git/config'
alias dotfiles='cd ~/Documents/Code/dotfiles'

# ── pacman / AUR ─────────────────────────────────────────────────────────────
alias yayp='sudo -E yay'
alias pacsil='sudo rm -rf /var/lib/pacman/db.lck'

# ── Omarchy AI tools ────────────────────────────────────────────────────────
# These match what Omarchy defines in its bash aliases for muscle memory
# across shells. `c` is kept as `clear` here (personal preference);
# use `oc` for opencode instead.
alias a='omarchy-agent --inline'
alias oc='opencode --auto'
alias cx='printf "\033[2J\033[3J\033[H" && claude --permission-mode auto'
alias cy='codex --approve-for-me'
alias h='herdr'
alias d='docker'

# ── applications ─────────────────────────────────────────────────────────────
alias goo=google
alias code_path='cd ~/Documents/Code'
alias qgc='~/Documents/Code/qgroundcontrol/build/Release/QGroundControl > /dev/null 2>&1 &'
alias stmcube='pc $HOME/st/stm32cubeide_1.19.0/stm32cubeide_wayland'
alias mavproxy='~/.mavproxy_env/bin/mavproxy.py'
