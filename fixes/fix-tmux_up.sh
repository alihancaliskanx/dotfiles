#!/bin/bash
# fixes/fix-tmux_up.sh
# Creates the "tmux_up" configuration with HOME, CODE, and AURA sessions.

echo "Setting up tmux_up..."

mkdir -p ~/.local/bin

# 1. Create the tmux initialization script
cat <<'EOF' >~/.local/bin/tmux_up.sh
#!/bin/bash

# HOME Session
tmux has-session -t HOME 2>/dev/null
if [ $? != 0 ]; then
  tmux new-session -d -s HOME -c "$HOME"
fi

# AURA Session
tmux has-session -t AURA 2>/dev/null
if [ $? != 0 ]; then
  tmux new-session -d -s AURA -c "$HOME/Documents/Code/aura_dev_enviroment"
fi

# CODE Session
tmux has-session -t CODE 2>/dev/null
if [ $? != 0 ]; then
  tmux new-session -d -s CODE -c "$HOME/Documents/Code/"
fi

# HACK Session
tmux has-session -t HACK 2>/dev/null
if [ $? != 0 ]; then
  tmux new-session -d -s HACK -c "$HOME/Documents/Hack/"
fi



# Attach to HOME session (since it's the primary one)
if [ -z "$TMUX" ]; then
    tmux attach -t HOME
else
    tmux switch-client -t HOME
fi
EOF

chmod +x ~/.local/bin/tmux_up.sh

# 2. Create the omarchy launch wrapper
cat <<'EOF' >~/.local/bin/omarchy-launch-terminal-tmux_up
#!/bin/bash
exec omarchy-launch-terminal bash -c "~/.local/bin/tmux_up.sh"
EOF

chmod +x ~/.local/bin/omarchy-launch-terminal-tmux_up

# 3. Modify the hyprland bindings in dotfiles
# The file is a symlink into the dotfiles repo, wherever that is cloned;
# --follow-symlinks edits the tracked file instead of replacing the link.
BINDINGS_FILE="$HOME/.config/hypr/bindings.lua"

if [ -f "$BINDINGS_FILE" ]; then
  # Replace the existing Herdr shortcut with the new tmux_up wrapper
  sed -i --follow-symlinks 's/o.bind("SUPER + CTRL + RETURN", "Herdr", { omarchy = "terminal-herdr" })/o.bind("SUPER + CTRL + RETURN", "Tmux Up", "omarchy-launch-terminal-tmux_up")/g' "$BINDINGS_FILE"
  echo "Updated hyprland bindings in $BINDINGS_FILE"
else
  echo "Could not find $BINDINGS_FILE"
fi

echo "Done! The tmux_up script has been installed."
echo "Please reload your Hyprland configuration or restart Hyprland to apply the shortcut."
