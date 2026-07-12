export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git virtualenv)
fpath=("$HOME/.grok/completions/zsh" $fpath)

source $ZSH/oh-my-zsh.sh
ZSH_THEME_VIRTUALENV_PREFIX='('
ZSH_THEME_VIRTUALENV_SUFFIX=') '
PROMPT='$(virtualenv_prompt_info)'"$PROMPT"

_zsh_config_dir="${${(%):-%N}:A:h}"
[ -f "$_zsh_config_dir/aliases.zsh" ] && source "$_zsh_config_dir/aliases.zsh"
unset _zsh_config_dir

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:/opt/homebrew/opt/python@3.13/bin:$PATH"

# Added by Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

. "$HOME/.local/bin/env"

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
# <<< grok installer <<<

[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
