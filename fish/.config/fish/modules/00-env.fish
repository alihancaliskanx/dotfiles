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

# Phone (PdaNet) HTTP proxy address. net-proxy, tor-net and 30-proxy.fish all
# read it from here — this is the only place to change it.
set -q PROXY_ADDR; or set -gx PROXY_ADDR "192.168.49.1:8000"

# ssh-agent: the systemd user unit in the services package opens this socket.
set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket

# The shared scripts (net-proxy, tor-net, tor-control, gclink...) live here.
fish_add_path $HOME/.local/bin

# aurapilot autotest — only if the directory exists. (It does not exist right now.)
if test -d $HOME/Documents/Code/aurapilot/ardupilot/Tools/autotest
    fish_add_path $HOME/Documents/Code/aurapilot/ardupilot/Tools/autotest
end
