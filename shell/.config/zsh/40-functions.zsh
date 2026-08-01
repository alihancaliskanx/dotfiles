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

# ── old names for the shared scripts ─────────────────────────────────────────
alias sha256_kontrol='sha256-check'
alias ros_docker='ros-docker'
