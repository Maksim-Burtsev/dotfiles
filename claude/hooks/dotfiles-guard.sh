#!/usr/bin/env bash
# Следит, чтобы агенты не забывали класть изменения настроек машины в репу дотфайлов.
#
#   dotfiles-guard.sh post  — PostToolUse/Bash: команда поменяла систему → напомнить сразу.
#   dotfiles-guard.sh stop  — Stop: репа грязная или есть неотправленные коммиты → не дать закончить.
#
# Оба режима читают hook input JSON со stdin и пишут hook output JSON в stdout.
set -uo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/open-source/dotfiles}"
MARKER_DIR="$HOME/.claude/.dotfiles-guard"

# Команды, после которых состояние машины разошлось с репой.
SYSTEM_MUTATORS='defaults (write|delete)|pmset|sysadminctl|nvram|chflags|launchctl (load|unload|enable|disable|bootstrap|bootout)|brew (install|uninstall|remove|tap|untap)|mas install|npm (install|i) +(-g|--global)|uv tool (install|uninstall)|go install|pipx install|code --install-extension'

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

  msg="Эта команда изменила состояние машины. Настройки ОС живут в $DOTFILES_DIR — отрази изменение там, пока не забыл: правь соответствующий файл (macos/defaults.sh, macos/power.sh, Brewfile через ./sync.sh, zsh/, git/, vscode/ и т.д.), затем закоммить и запушь. Если изменение временное или отладочное — скажи об этом пользователю явно вместо коммита."
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":%s},"suppressOutput":true}\n' "$(json_escape "$msg")"
  ;;

stop)
  # Без этого блокировка зациклится: наш же reason снова доводит модель до Stop.
  [[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)" == "true" ]] && exit 0

  # Не status --porcelain: он сравнивает по stat и не прогоняет clean-фильтры,
  # поэтому переписанный Claude Code settings.json вечно висит как " M", хотя
  # после claude-volatile он совпадает с индексом. diff сравнивает содержимое.
  dirty="$( { git -C "$DOTFILES_DIR" diff --name-only
              git -C "$DOTFILES_DIR" diff --cached --name-only
              git -C "$DOTFILES_DIR" ls-files --others --exclude-standard; } 2>/dev/null | sort -u )"
  git -C "$DOTFILES_DIR" fetch --quiet origin 2>/dev/null
  ahead="$(git -C "$DOTFILES_DIR" log --oneline @{u}..HEAD 2>/dev/null)"
  [[ -z "$dirty" && -z "$ahead" ]] && exit 0

  # Блокируем один раз за сессию: чекаут общий с параллельными сессиями,
  # и чужая грязь не должна долбить бесконечно.
  session="$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null)"
  mkdir -p "$MARKER_DIR"
  marker="$MARKER_DIR/$session"
  [[ -f "$marker" ]] && exit 0
  : > "$marker"
  find "$MARKER_DIR" -type f -mtime +7 -delete 2>/dev/null

  reason="В $DOTFILES_DIR есть неотправленные изменения настроек."
  [[ -n "$dirty" ]] && reason="$reason

Незакоммиченное:
$dirty"
  [[ -n "$ahead" ]] && reason="$reason

Закоммичено, но не запушено:
$ahead"
  reason="$reason

Если это твои изменения — прогони ./sync.sh при необходимости, закоммить и запушь. Если это работа параллельной сессии или мусор не по твоей теме — не трогай, просто скажи пользователю, что там лежит, и заканчивай."

  printf '{"decision":"block","reason":%s}\n' "$(json_escape "$reason")"
  ;;
esac
exit 0
