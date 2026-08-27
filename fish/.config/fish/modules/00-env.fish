# 00-env — definitions. Variables/PATH only.

# vim instead of nvim in an SSH session.
if test -n "$SSH_CONNECTION"
    set -gx EDITOR vim
else
    set -gx EDITOR nvim
end

set -gx ARCHFLAGS "-arch "(uname -m)

# Terminal emulator for tools that spawn one ($TERMINAL is a de-facto standard).
# fuzzel has its own `terminal=` setting in fuzzel.ini — keep the two in sync.
set -gx TERMINAL alacritty

# Same idea for the file manager. What actually decides which one opens is the
# inode/directory entry in mimeapps.list (xdg-mime); this is only for the
# scripts that read $FILEMANAGER instead of calling xdg-open.
set -gx FILEMANAGER dolphin

# Phone (PdaNet) HTTP proxy address. net-proxy, tor-net and 30-proxy.fish all
# read it from here — this is the only place to change it.
set -q PROXY_ADDR; or set -gx PROXY_ADDR "192.168.49.1:8000"

# ssh-agent: the systemd user unit in the services package opens this socket.
set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket

# The shared scripts (net-proxy, tor-net, tor-control, gclink...) live here.
fish_add_path $HOME/.local/bin

# aurapilot autotest — sim_vehicle.py and the rest, only if the checkout is here.
if test -d $HOME/Documents/Code/stars/aurapilot/Tools/autotest
    fish_add_path $HOME/Documents/Code/stars/aurapilot/Tools/autotest
end

# ── gum ──────────────────────────────────────────────────────────────────────
# Blue, matching the desktop. See the zsh module for why these live in env
# rather than as flags in each script.
set -gx GUM_CHOOSE_CURSOR_FOREGROUND "#89b4fa"
set -gx GUM_CHOOSE_SELECTED_FOREGROUND "#89b4fa"
set -gx GUM_CHOOSE_HEADER_FOREGROUND "#7d8291"
set -gx GUM_FILTER_INDICATOR_FOREGROUND "#89b4fa"
set -gx GUM_FILTER_MATCH_FOREGROUND "#89b4fa"
set -gx GUM_FILTER_PROMPT_FOREGROUND "#89b4fa"
set -gx GUM_INPUT_CURSOR_FOREGROUND "#89b4fa"
set -gx GUM_INPUT_PROMPT_FOREGROUND "#89b4fa"
set -gx GUM_CONFIRM_SELECTED_BACKGROUND "#89b4fa"
set -gx GUM_CONFIRM_PROMPT_FOREGROUND "#89b4fa"
set -gx GUM_SPIN_SPINNER_FOREGROUND "#89b4fa"
