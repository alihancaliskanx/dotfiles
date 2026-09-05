# 10-plugins — oh-my-zsh, theme, completion. Loaded BEFORE the aliases so that
# oh-my-zsh's own aliases can be overridden by 20-aliases.zsh.

bindkey -v

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# ── Autosuggestions (Real-time inline ghost text) ─────────────────────────────
# Suggests from history first, then falls back to completion engine.
# Always visible as you type — no manual trigger needed.
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

plugins=(
    history
    git
    colorize
    python
    ssh
    sudo
    tmux
    copybuffer
    you-should-use
    web-search
    autoswitch_virtualenv
    zsh-interactive-cd
    z
    fzf
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Guard: keeps the shell from blowing up entirely on a clean machine where
# oh-my-zsh is not installed yet. To install it: install.sh, or the bootstrap
# step in the README.
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  print -u2 "! oh-my-zsh not found ($ZSH) — run dotfiles/install.sh."
fi

# ── zsh-autocomplete (live completion dropdown as you type) ──────────────────
# Must be loaded AFTER oh-my-zsh (needs compinit to have run).
# Loaded outside the plugins array because it needs precise init ordering.
zstyle ':autocomplete:*' min-input 1
zstyle ':autocomplete:*' min-delay 0.05
zstyle ':autocomplete:*' list-lines 16
zstyle ':autocomplete:*' widget-style menu-select
if [[ -r "$ZSH/custom/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh" ]]; then
  source "$ZSH/custom/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
fi

# ── Autosuggestions: always-on in vi-mode ────────────────────────────────────
# By default vi-mode (bindkey -v) breaks inline ghost-text acceptance.
# These bindings ensure suggestions are always visible and can be accepted
# with Right Arrow, Ctrl+F (forward-char, fish-style), or Ctrl+E (end of line).
# No Alt+A toggle needed.
bindkey -M viins '^[[C' autosuggest-accept        # Right Arrow
bindkey -M viins '^[OC' autosuggest-accept        # Right Arrow (application mode)
bindkey -M viins '^E'   autosuggest-accept        # Ctrl+E  (end of line)
bindkey -M viins '^F'   autosuggest-accept        # Ctrl+F  (forward char)

# ── fzf (Ctrl+R, Ctrl+T, Alt+C) ──────────────────────────────────────────────
command -v fzf >/dev/null && source <(fzf --zsh)
