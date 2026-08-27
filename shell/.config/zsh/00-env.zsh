# 00-env — definitions. Variables/PATH only; no command execution.

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

# aurapilot autotest — sim_vehicle.py and the rest, only if the checkout is here.
[ -d "$HOME/Documents/Code/stars/aurapilot/Tools/autotest" ] \
  && export PATH="$HOME/Documents/Code/stars/aurapilot/Tools/autotest:$PATH"

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
