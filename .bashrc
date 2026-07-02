#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
source /home/sups/venv-ardupilot/bin/activate
export PATH=/home/sups/Documents/Code/aurapilot/ardupilot/Tools/autotest:$PATH
