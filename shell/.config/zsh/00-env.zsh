# 00-env — definitions. Variables/PATH only; no command execution.

# ── Omarchy bootstrap ───────────────────────────────────────────────────────
# Source Omarchy's environment setup so that OMARCHY_PATH, mise shims,
# and ~/.local/bin are all on PATH — the same chain bash gets from
# env-bootstrap. Without this, tools installed via mise (node, python, etc.)
# are invisible to zsh.
if [[ -r /usr/share/omarchy/default/bash/env-bootstrap ]]; then
  source /usr/share/omarchy/default/bash/env-bootstrap
fi

# ── editor ───────────────────────────────────────────────────────────────────
# Omarchy sets EDITOR to its own launcher; override for our terminal sessions.
# vim instead of nvim in an SSH session (so plugins don't load on a remote machine).
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

export ARCHFLAGS="-arch $(uname -m)"

# Terminal emulator for tools that spawn one ($TERMINAL is a de-facto standard).
# fuzzel has its own `terminal=` setting in fuzzel.ini — keep the two in sync.
export TERMINAL=alacritty

# Same idea for the file manager. What actually decides which one opens is the
# inode/directory entry in mimeapps.list (xdg-mime); this is only for the
# scripts that read $FILEMANAGER instead of calling xdg-open.
export FILEMANAGER=dolphin

# Phone (PdaNet) HTTP proxy address. net-proxy, tor-net and the functions in
# 30-proxy.zsh all read it from here — this is the only place to change it.
export PROXY_ADDR="${PROXY_ADDR:-192.168.49.1:8000}"

# ssh-agent: the systemd user unit in the services package opens this socket.
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

export PATH="$HOME/.local/bin:$PATH"

# aurapilot autotest — only if the directory exists.
[ -d "$HOME/Documents/Code/aurapilot/ardupilot/Tools/autotest" ] \
  && export PATH="$HOME/Documents/Code/aurapilot/ardupilot/Tools/autotest:$PATH"

# ── Omarchy env vars ────────────────────────────────────────────────────────
# Mirror useful env vars from Omarchy's bash/envs so that the same tools
# (bat, man, browser) behave the same in zsh.
export BAT_THEME="${BAT_THEME:-ansi}"
export MANROFFOPT="-c"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export BROWSER="${BROWSER:-omarchy-launch-browser}"

# ── gum ──────────────────────────────────────────────────────────────────────
# Blue, to match the desktop. gum reads these on every call, so the scripts that
# use it (tor-control, link.sh) get one look without passing flags each time —
# and anything added later inherits it for free.
export GUM_CHOOSE_CURSOR_FOREGROUND="#89b4fa"
export GUM_CHOOSE_SELECTED_FOREGROUND="#89b4fa"
export GUM_CHOOSE_HEADER_FOREGROUND="#7d8291"
export GUM_FILTER_INDICATOR_FOREGROUND="#89b4fa"
export GUM_FILTER_MATCH_FOREGROUND="#89b4fa"
export GUM_FILTER_PROMPT_FOREGROUND="#89b4fa"
export GUM_INPUT_CURSOR_FOREGROUND="#89b4fa"
export GUM_INPUT_PROMPT_FOREGROUND="#89b4fa"
export GUM_CONFIRM_SELECTED_BACKGROUND="#89b4fa"
export GUM_CONFIRM_PROMPT_FOREGROUND="#89b4fa"
export GUM_SPIN_SPINNER_FOREGROUND="#89b4fa"
