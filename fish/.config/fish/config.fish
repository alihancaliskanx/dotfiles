# ~/.config/fish/config.fish — loader only.
# The real content lives in ~/.config/fish/modules/*.fish:
#
#   00-env.fish       definitions: PATH, EDITOR, env variables
#   20-aliases.fish   aliases
#   30-proxy.fish     proxy + tor (env functions and shortcuts)
#   40-functions.fish other custom functions
#   50-local.fish     machine specific: conda/mamba, distrobox
#
# WHY NOT conf.d/: fish loads conf.d/*.fish files BEFORE config.fish. Since
# CachyOS's default config defines the ls/ll/lt aliases at the config.fish
# stage, ours would have been overridden if the modules lived in conf.d/. By
# sourcing them explicitly from here we give the modules the last word.

if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# If you want to turn off the greeting message:
# function fish_greeting; end

for _mod in $__fish_config_dir/modules/*.fish
    source $_mod
end
set -e _mod
