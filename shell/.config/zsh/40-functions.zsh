# 40-functions — custom functions.
#
# Rule: anything that does not change the current shell's environment (env, cwd)
# is written as a script under scripts/.local/bin, not here — that way fish calls
# the same code. What stays here are the ones that change env/cwd.

# ── ardupilot development environment ────────────────────────────────────────
ardudev() {
    export PATH="/opt/gcc-arm-none-eabi-10-2020-q4-major/bin:$PATH"
    export PATH="$HOME/Documents/Code/ardupilot/Tools/autotest:$PATH"
    echo "🛩  ardupilot toolchain added to PATH"
}

ardupilot_dev() {
    if [ -f "$HOME/venv-ardupilot/bin/activate" ]; then
        source "$HOME/venv-ardupilot/bin/activate"
    else
        echo "❌ no venv: $HOME/venv-ardupilot" >&2
        return 1
    fi
}

# ── sart_checker timer status ────────────────────────────────────────────────
sart_status() {
    systemctl --user status sart_checker.timer
    systemctl --user list-timers sart_checker.timer
}

# ── clear under kitty ────────────────────────────────────────────────────────
# The xterm-kitty terminfo has no E3 capability, so /usr/bin/clear only sends
# \E[H\E[2J: the screen goes blank but everything is still in the scrollback,
# which is exactly what Ctrl+L does. \E[3J is the sequence that drops the
# scrollback (kitty documents it in its own kitty.conf). Other terminals here —
# alacritty, ghostty — do carry E3, so their clear is left alone.
if [[ $TERM == xterm-kitty ]]; then
    clear() { printf '\033[H\033[2J\033[3J' }
fi

# ── old names for the shared scripts ─────────────────────────────────────────
alias sha256_kontrol='sha256-check'
alias ros_docker='ros-docker'
