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
# Ghost text from history. Colour 8 is near-black on light themes (Claude Light), so pin a mid grey.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#8a8a8a"
unset _zsh_autosuggestions

export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:/opt/homebrew/opt/python@3.13/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# agterm: a local shell opened (+, Cmd+N, duplicate) inside a work-project workspace becomes an ssh
# shell in that project on the laptop. WORK_PROJECTS is set only on the home machine, so this is
# a no-op on the laptop itself. See agterm/work-term.
if [ -n "$AGTERM_WORKSPACE_ID" ] && [ -n "$WORK_PROJECTS" ] && [ -z "$SSH_CONNECTION" ]; then
  _ws=$(agtermctl tree --json 2>/dev/null | jq -r --arg id "$AGTERM_WORKSPACE_ID" '.result.tree.workspaces[] | select(.id==$id) | .name')
  for _p in ${=WORK_PROJECTS}; do
    [ "${_p:t}" = "$_ws" ] && exec ssh -t work "cd $_p && exec zsh -l"
  done
  unset _ws _p
fi

# >>> agterm agent-status >>>
[ -f "$HOME/.config/agterm/agent-status/shell/integration.sh" ] && source "$HOME/.config/agterm/agent-status/shell/integration.sh"
# <<< agterm agent-status <<<
