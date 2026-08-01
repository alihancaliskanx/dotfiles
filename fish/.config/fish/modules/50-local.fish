# 50-local — machine specific tool initialisers. All of them are guarded: if the
# tool is not installed the block is skipped entirely.

# ── distrobox / inside a container ───────────────────────────────────────────
if test -n "$CONTAINER_ID"; or test -n "$DISTROBOX_ENTER"
    set -gx TERM xterm-256color
    if test -f /opt/ros/noetic/setup.fish
        source /opt/ros/noetic/setup.fish
    end
end

# ── conda / mamba ────────────────────────────────────────────────────────────
# If miniforge3 is not installed the whole block is skipped.
if test -d $HOME/miniforge3
    if test -x $HOME/miniforge3/bin/conda
        eval $HOME/miniforge3/bin/conda "shell.fish" "hook" $argv | source
    end
    if test -x $HOME/miniforge3/bin/mamba
        set -gx MAMBA_EXE $HOME/miniforge3/bin/mamba
        set -gx MAMBA_ROOT_PREFIX $HOME/miniforge3
        $MAMBA_EXE shell hook --shell fish --root-prefix $MAMBA_ROOT_PREFIX | source
    end
end

# ── nvm ──────────────────────────────────────────────────────────────────────
# nvm is bash based and does not work directly in fish. Install the fish port if you want it:
#   fisher install jorgebucaran/nvm.fish
