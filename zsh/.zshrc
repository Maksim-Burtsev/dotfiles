export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git virtualenv)

source $ZSH/oh-my-zsh.sh
ZSH_THEME_VIRTUALENV_PREFIX='('
ZSH_THEME_VIRTUALENV_SUFFIX=') '
PROMPT='$(virtualenv_prompt_info)'"$PROMPT"

_zsh_config_dir="${${(%):-%N}:A:h}"
[ -f "$_zsh_config_dir/aliases.zsh" ] && source "$_zsh_config_dir/aliases.zsh"
unset _zsh_config_dir

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
_zsh_autosuggestions="/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[ -f "$_zsh_autosuggestions" ] && source "$_zsh_autosuggestions"
unset _zsh_autosuggestions

export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:/opt/homebrew/opt/python@3.13/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
