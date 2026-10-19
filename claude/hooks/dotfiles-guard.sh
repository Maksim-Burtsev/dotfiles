#!/usr/bin/env bash
# PostToolUse/Bash: after a command that changes the system, remind the agent once that a
# general setting belongs in the repo and a personal one in the untracked private/ folder.
# There is no Stop check: it nagged every session about other sessions' leftovers.
set -uo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/open-source/dotfiles}"

# Команды, после которых состояние машины разошлось с репой.
SYSTEM_MUTATORS='defaults (write|delete)|pmset|sysadminctl|nvram|chflags|launchctl (load|unload|enable|disable|bootstrap|bootout)|brew (install|uninstall|remove|untap)|brew tap +[[:alnum:]]|mas install|npm (install|i) +(-g|--global)|uv tool (install|uninstall)|go install|pipx install|code --install-extension'

json_escape() { printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'; }

input="$(cat)"
[[ -d "$DOTFILES_DIR/.git" ]] || exit 0

case "${1:-}" in
post)
  cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
  [[ -n "$cmd" ]] || exit 0
  # Только в позиции команды (начало строки или после ; && || |), иначе ловим
  # упоминания вроде "brew install" внутри текста, который агент куда-то пишет.
  printf '%s' "$cmd" | grep -Eq "(^|[;&|]|&&|\|\|)[[:space:]]*($SYSTEM_MUTATORS)" || exit 0

  msg="This command changed the machine. The repo $DOTFILES_DIR is PUBLIC. A general setting worth restoring on a fresh Mac (defaults, power, Brewfile via ./sync.sh, zsh, git, editor) goes into the repo as one commit at the end of the task. Anything personal (own or work projects, folder paths, accounts, people, LaunchAgents for them) goes into private/ (gitignored, never committed). Temporary or debugging changes go nowhere; tell the user."
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":%s},"suppressOutput":true}\n' "$(json_escape "$msg")"
  ;;

esac
exit 0
