# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
source "$OMARCHY_PATH/default/bash/rc"

# ── personal additions ───────────────────────────────────────────────────────
# ardupilot venv — only if it exists.
[ -f "$HOME/venv-ardupilot/bin/activate" ] && source "$HOME/venv-ardupilot/bin/activate"

# aurapilot autotest — only if the directory exists.
[ -d "$HOME/Documents/Code/aurapilot/ardupilot/Tools/autotest" ] \
  && export PATH="$HOME/Documents/Code/aurapilot/ardupilot/Tools/autotest:$PATH"
