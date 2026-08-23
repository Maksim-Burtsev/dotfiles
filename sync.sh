#!/usr/bin/env bash
set -euo pipefail

# Снимает текущее состояние машины в репу. Запускать перед коммитом.
# Симлинкнутые файлы (zsh, git, vscode, claude, hammerspoon) синка не требуют —
# они и есть файлы репы. Здесь только то, что симлинком быть не может.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

brew bundle dump --file "$DOTFILES_DIR/Brewfile" --force

# Приложения, установленные мимо brew: dump их не видит и затирает при каждом запуске.
# ponytail: список руками; убрать строку, когда `brew install --cask --adopt <имя>`
# пройдёт (нужен sudo для chmod на /Applications/<имя>.app).
for c in firefox visual-studio-code; do
  grep -qx "cask \"$c\"" "$DOTFILES_DIR/Brewfile" || echo "cask \"$c\"" >> "$DOTFILES_DIR/Brewfile"
done
echo "Brewfile обновлён"

# Claude Code переписывает settings.json через rename при смене настроек в UI,
# что заменяет симлинк обычным файлом. Возвращаем на место.
claude_settings="$HOME/.claude/settings.json"
if [[ -f "$claude_settings" && ! -L "$claude_settings" ]]; then
  cp "$claude_settings" "$DOTFILES_DIR/claude/settings.json"
  ln -sf "$DOTFILES_DIR/claude/settings.json" "$claude_settings"
  echo "claude/settings.json: симлинк был затёрт, содержимое сохранено и линк восстановлен"
fi

gitleaks detect --source "$DOTFILES_DIR" --no-banner
