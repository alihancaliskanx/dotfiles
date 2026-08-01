# ~/.zshrc — loader only. The real content lives in the ~/.config/zsh/*.zsh modules:
#
#   00-env.zsh        definitions: PATH, EDITOR, env variables
#   10-plugins.zsh    oh-my-zsh, powerlevel10k, fzf
#   20-aliases.zsh    aliases
#   30-proxy.zsh      proxy + tor (env functions and shortcuts)
#   40-functions.zsh  other custom functions
#   50-local.zsh      machine specific: conda/mamba, nvm, distrobox
#
# To add a new module just drop <order>-<name>.zsh into the directory.

# Powerlevel10k instant prompt — this block must stay at the very top, nothing
# that produces output may run before it.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

ZSH_MODULE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
for _zmod in "$ZSH_MODULE_DIR"/*.zsh(N); do
  source "$_zmod"
done
unset _zmod

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
