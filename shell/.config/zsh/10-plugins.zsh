# 10-plugins — oh-my-zsh, theme, completion. Loaded BEFORE the aliases so that
# oh-my-zsh's own aliases can be overridden by 20-aliases.zsh.

bindkey -v

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    history
    git
    colorize
    python
    ssh
    sudo
    tmux
    copybuffer
    zsh-syntax-highlighting
    zsh-autosuggestions
    you-should-use
    zsh-autocomplete
    web-search
    autoswitch_virtualenv
    zsh-interactive-cd
    z
    fzf
)

# Guard: keeps the shell from blowing up entirely on a clean machine where
# oh-my-zsh is not installed yet. To install it: install.sh, or the bootstrap
# step in the README.
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  print -u2 "! oh-my-zsh not found ($ZSH) — run dotfiles/install.sh."
fi

command -v fzf >/dev/null && source <(fzf --zsh)
