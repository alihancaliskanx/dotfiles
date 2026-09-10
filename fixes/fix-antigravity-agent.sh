#!/usr/bin/env bash
#
# fixes/fix-antigravity-agent.sh
# ------------------------------------------------------------------------------
# Configures Antigravity as the default agent in Omarchy.
# ------------------------------------------------------------------------------

set -euo pipefail

INFO='\033[0;34m[INFO]\033[0m'
SUCCESS='\033[0;32m[OK]\033[0m'

echo -e "${INFO} Setting up Antigravity as the default Omarchy agent..."

mkdir -p ~/.config/omarchy/extensions
mkdir -p ~/.config/omarchy/defaults
mkdir -p ~/.local/bin

echo -e "${INFO} Updating omarchy-menu.jsonc..."
cat << 'EOF' > ~/.config/omarchy/extensions/omarchy-menu.jsonc
{
  "setup.default.agent.gemini": {"when": "false"},
  "setup.default.agent.antigravity": {
    "icon": "󰚩",
    "label": "Antigravity",
    "checked": "[[ \"$(omarchy-default-agent)\" == \"antigravity\" ]]",
    "action": "omarchy-default-agent antigravity"
  }
}
EOF

echo -e "${INFO} Creating wrapper script for omarchy-default-agent..."
cat << 'EOF' > ~/.local/bin/omarchy-default-agent
#!/bin/bash

# omarchy:summary=Set and launch the default coding agent
# omarchy:args=[pi|omp|opencode|claude|codex|grok|gemini|openclaw|hermes|copilot|crush|cursor-agent|muse|antigravity]
# omarchy:examples=omarchy default agent | omarchy default agent antigravity

agent_file="$HOME/.config/omarchy/defaults/agent"

installing=false
if [[ ${1:-} == "--install" ]]; then
  installing=true
  shift
fi

if (($# == 0)); then
  if [[ -f $agent_file ]]; then
    read -r agent <"$agent_file"
  fi
  [[ -n ${agent:-} ]] && echo "$agent"
  exit 0
fi

if [[ "$1" == "antigravity" ]]; then
  mkdir -p "$(dirname "$agent_file")"
  echo "antigravity" > "$agent_file"
  if [[ $installing == "true" ]]; then
    printf '\033[2J\033[3J\033[H'
    exec omarchy-agent --inline
  else
    exec omarchy-agent
  fi
else
  if [[ $installing == "true" ]]; then
    exec /usr/share/omarchy/bin/omarchy-default-agent --install "$@"
  else
    exec /usr/share/omarchy/bin/omarchy-default-agent "$@"
  fi
fi
EOF
chmod +x ~/.local/bin/omarchy-default-agent

echo -e "${INFO} Creating wrapper script for omarchy-agent..."
cat << 'EOF' > ~/.local/bin/omarchy-agent
#!/bin/bash

# omarchy:summary=Launch the default coding agent in a terminal
# omarchy:args=[--inline] [--pick]
# omarchy:examples=omarchy agent | omarchy agent --inline

inline=false
pick=false

while (($#)); do
  case "$1" in
    --inline)
      inline=true
      shift
      ;;
    --pick)
      pick=true
      shift
      ;;
    --prompt)
      prompt=${2:?--prompt needs a value}
      shift 2
      ;;
    *)
      if [[ "$1" == "--" ]]; then
        shift
        break
      fi
      break
      ;;
  esac
done

agent=$(omarchy-default-agent)

if [[ "$agent" == "antigravity" ]]; then
  [[ $PWD == "$HOME" && -d $HOME/Work ]] && cd "$HOME/Work"
  
  if [[ -n ${prompt:-} ]]; then
    command=(agy --prompt-interactive "$prompt")
  else
    command=(agy)
  fi

  if [[ $inline == "true" ]]; then
    exec "${command[@]}"
  else
    exec omarchy-launch-tui --app-id=org.omarchy.agent "${command[@]}"
  fi
else
  args=()
  [[ $inline == "true" ]] && args+=(--inline)
  [[ $pick == "true" ]] && args+=(--pick)
  [[ -n ${prompt:-} ]] && args+=(--prompt "$prompt")
  args+=("$@")
  
  exec /usr/share/omarchy/bin/omarchy-agent "${args[@]}"
fi
EOF
chmod +x ~/.local/bin/omarchy-agent

echo -e "${INFO} Creating wrapper script for omarchy main command..."
cat << 'EOF' > ~/.local/bin/omarchy
#!/bin/bash
if [[ "$1" == "agent" || ( "$1" == "default" && "$2" == "agent" ) ]]; then
  if [[ "$1" == "agent" ]]; then
    shift
    exec omarchy-agent "$@"
  else
    shift 2
    exec omarchy-default-agent "$@"
  fi
fi
exec /usr/share/omarchy/bin/omarchy "$@"
EOF
chmod +x ~/.local/bin/omarchy

echo -e "${INFO} Setting antigravity as the default agent..."
omarchy default agent antigravity

echo -e "${SUCCESS} Antigravity agent configuration complete!"
