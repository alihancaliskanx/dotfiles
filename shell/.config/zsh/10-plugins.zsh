# 10-plugins — oh-my-zsh, theme, completion. Loaded BEFORE the aliases so that
# oh-my-zsh's own aliases can be overridden by 20-aliases.zsh.

bindkey -v

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# ── Autosuggestions (Real-time suggestions without Tab) ───────────────────────
# Automatically suggests from both history and directory/command completions on disk.
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

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
    web-search
    autoswitch_virtualenv
)

# Guard: keeps the shell from blowing up entirely on a clean machine where
# oh-my-zsh is not installed yet. To install it: install.sh, or the bootstrap
# step in the README.
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  print -u2 "! oh-my-zsh not found ($ZSH) — run dotfiles/install.sh."
fi

# ── Completion Menu & Arrow Key Navigation ──────────────────────────────────
# Enables interactive menu selection on Tab/Down Arrow, navigated with Arrow Keys / hjkl.
zmodload zsh/complist
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Keybindings in menuselect mode (Arrow keys + hjkl + Tab/Shift-Tab)
bindkey -M menuselect '^[[A' up-line-or-history        # Up Arrow
bindkey -M menuselect '^[[B' down-line-or-history      # Down Arrow
bindkey -M menuselect '^[[C' forward-char              # Right Arrow
bindkey -M menuselect '^[[D' backward-char             # Left Arrow
bindkey -M menuselect '^[OA' up-line-or-history        # Up Arrow (application mode)
bindkey -M menuselect '^[OB' down-line-or-history      # Down Arrow (application mode)
bindkey -M menuselect '^[OC' forward-char              # Right Arrow (application mode)
bindkey -M menuselect '^[OD' backward-char             # Left Arrow (application mode)
bindkey -M menuselect 'k'    up-line-or-history        # k
bindkey -M menuselect 'j'    down-line-or-history      # j
bindkey -M menuselect 'l'    forward-char              # l
bindkey -M menuselect 'h'    backward-char             # h
bindkey -M menuselect '^I'   menu-complete             # Tab: next match
bindkey -M menuselect '^[[Z' reverse-menu-complete     # Shift+Tab: prev match

# Arrow keys in insert mode (viins)
bindkey -M viins '^[[A' up-line-or-history
bindkey -M viins '^[[B' menu-select
bindkey -M viins '^[[C' forward-char
bindkey -M viins '^[[D' backward-char
bindkey -M viins '^[OA' up-line-or-history
bindkey -M viins '^[OB' menu-select
bindkey -M viins '^[OC' forward-char
bindkey -M viins '^[OD' backward-char

# Tab & Down Arrow open menu selection
bindkey -M viins '^I' menu-select
bindkey '^I' menu-select

# ── fzf (Ctrl+R, Ctrl+T, Alt+C) ──────────────────────────────────────────────
# Load fzf widgets, then ensure Tab remains bound to menu-select instead of fzf-completion.
if command -v fzf >/dev/null; then
  source <(fzf --zsh)
  bindkey -M viins '^I' menu-select
  bindkey '^I' menu-select
fi
