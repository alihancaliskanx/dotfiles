# 05-omarchy — Omarchy tool initialisers for zsh.
#
# This mirrors what /usr/share/omarchy/default/bash/init does for bash:
# mise, zoxide, fzf. Starship is skipped because we use powerlevel10k.

# ── mise (replaces nvm/pyenv/rbenv — Omarchy's default version manager) ─────
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# ── zoxide (smart cd) ───────────────────────────────────────────────────────
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# ── Omarchy shell helpers ────────────────────────────────────────────────────
# open() — xdg-open wrapper that backgrounds and silences output.
open() ( xdg-open "$@" >/dev/null 2>&1 & )
