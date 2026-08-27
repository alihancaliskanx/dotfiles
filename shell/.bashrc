#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

export PATH="$HOME/.local/bin:$PATH"

# ardupilot venv — only if it exists. Without the guard this errored on every bash startup.
[ -f "$HOME/venv-ardupilot/bin/activate" ] && source "$HOME/venv-ardupilot/bin/activate"

# aurapilot autotest — sim_vehicle.py and the rest, only if the checkout is here.
[ -d "$HOME/Documents/Code/stars/aurapilot/Tools/autotest" ] \
  && export PATH="$HOME/Documents/Code/stars/aurapilot/Tools/autotest:$PATH"
