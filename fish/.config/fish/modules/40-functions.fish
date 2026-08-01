# 40-functions — custom functions.
#
# Rule: anything that does not change the current shell's environment (env, cwd)
# is written as a script under scripts/.local/bin, not here — that way the same
# code runs under zsh. What stays here are the ones that change env/cwd.

# ── ardupilot development environment ────────────────────────────────────────
function ardudev --description 'Add the ardupilot toolchain to PATH'
    fish_add_path /opt/gcc-arm-none-eabi-10-2020-q4-major/bin
    fish_add_path $HOME/Documents/Code/ardupilot/Tools/autotest
    echo "🛩  ardupilot toolchain added to PATH"
end

function ardupilot_dev --description 'Activate the ardupilot venv'
    # fish has its own venv activate script: activate.fish
    if test -f $HOME/venv-ardupilot/bin/activate.fish
        source $HOME/venv-ardupilot/bin/activate.fish
    else
        echo "❌ no venv, or it has no activate.fish: $HOME/venv-ardupilot" >&2
        return 1
    end
end

# ── sart_checker timer status ────────────────────────────────────────────────
function sart_status --description 'sart_checker timer status'
    systemctl --user status sart_checker.timer
    systemctl --user list-timers sart_checker.timer
end

# ── old names for the shared scripts ─────────────────────────────────────────
alias sha256_kontrol='sha256-check'
alias ros_docker='ros-docker'
