export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git virtualenv)

source $ZSH/oh-my-zsh.sh

_zsh_config_dir="${${(%):-%N}:A:h}"
[ -f "$_zsh_config_dir/functions.zsh" ] && source "$_zsh_config_dir/functions.zsh"
[ -f "$_zsh_config_dir/aliases.zsh" ] && source "$_zsh_config_dir/aliases.zsh"
unset _zsh_config_dir

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export PATH="/opt/homebrew/opt/python@3.13/bin:$PATH"

[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# Added by Antigravity
export PATH="/Users/zadro/.antigravity/antigravity/bin:$PATH"

. "$HOME/.local/bin/env"
