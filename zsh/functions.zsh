python() {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    "$VIRTUAL_ENV/bin/python" "$@"
  else
    /opt/homebrew/bin/python3.13 "$@"
  fi
}

autoload -Uz add-zsh-hook

function _prepend_venv_to_prompt() {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    local venv="($(basename $VIRTUAL_ENV))"
    # если PROMPT не начинается с этого префикса — добавляем
    if [[ $PROMPT != $venv* ]]; then
      PROMPT="$venv $PROMPT"
    fi
  fi
}

add-zsh-hook precmd _prepend_venv_to_prompt
