#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="${HOME}/.dotfiles-backups/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=0
RUN_MACOS=0
RUN_POWER=0
SKIP_BREW=0

usage() {
  cat <<USAGE
Usage: ./install.sh [--dry-run] [--macos] [--power] [--skip-brew] [--help]

Options:
  --dry-run    Print actions without changing files, packages, or settings.
  --macos      Also apply macOS defaults from macos/defaults.sh.
  --power      Also apply sleep timers and screen lock from macos/power.sh.
               Interactive: asks for the sudo and the login password.
  --skip-brew  Skip brew bundle. Useful when packages are already installed and
               some apps live in /Applications outside of brew's control.
  --help       Show this help message.
USAGE
}

log() {
  printf '%s\n' "$*"
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    --macos)
      RUN_MACOS=1
      ;;
    --power)
      RUN_POWER=1
      ;;
    --skip-brew)
      SKIP_BREW=1
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
  shift
done

run_or_print() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY-RUN: $*"
  else
    "$@"
  fi
}

install_homebrew_packages() {
  if [[ "$SKIP_BREW" -eq 1 ]]; then
    log "Skipping brew bundle (--skip-brew)."
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY-RUN: brew bundle install --file $DOTFILES_DIR/Brewfile --no-upgrade"
    return
  fi

  command -v brew >/dev/null 2>&1 || die "Homebrew is not installed. Install it first: https://brew.sh"
  brew bundle install --file "$DOTFILES_DIR/Brewfile" --no-upgrade
}

install_oh_my_zsh() {
  if [[ -d "${HOME}/.oh-my-zsh" ]]; then
    log "OK: oh-my-zsh already installed"
    return
  fi

  # Трекнутый .zshrc требует oh-my-zsh, а brew его не ставит.
  # KEEP_ZSHRC, чтобы установщик не трогал наш файл/симлинк.
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY-RUN: install oh-my-zsh (RUNZSH=no CHSH=no KEEP_ZSHRC=yes)"
    return
  fi

  command -v curl >/dev/null 2>&1 || die "curl is required to install oh-my-zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

backup_path_for() {
  local target="$1"
  local relative="${target#"$HOME"/}"
  printf '%s/%s\n' "$BACKUP_ROOT" "$relative"
}

backup_existing_path() {
  local target="$1"
  local backup_path
  backup_path="$(backup_path_for "$target")"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY-RUN: backup $target -> $backup_path"
  else
    mkdir -p "$(dirname "$backup_path")"
    mv "$target" "$backup_path"
    log "Backed up $target -> $backup_path"
  fi
}

link_file() {
  local source="$1"
  local target="$2"

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    log "OK: $target already links to $source"
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    backup_existing_path "$target"
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY-RUN: mkdir -p $(dirname "$target")"
    log "DRY-RUN: symlink $source -> $target"
  else
    mkdir -p "$(dirname "$target")"
    ln -s "$source" "$target"
    log "Linked $source -> $target"
  fi
}

preserve_local_gitconfig() {
  local gitconfig="${HOME}/.gitconfig"
  local local_gitconfig="${HOME}/.gitconfig.local"

  if [[ -e "$local_gitconfig" || -L "$local_gitconfig" ]]; then
    return
  fi

  if [[ -f "$gitconfig" && ! -L "$gitconfig" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "DRY-RUN: copy $gitconfig -> $local_gitconfig"
      log "DRY-RUN: chmod 600 $local_gitconfig"
    else
      cp "$gitconfig" "$local_gitconfig"
      chmod 600 "$local_gitconfig"
      log "Preserved local git config at $local_gitconfig"
    fi
  fi
}

link_dotfiles() {
  preserve_local_gitconfig

  link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  link_file "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"
  link_file "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
  link_file "$DOTFILES_DIR/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
  link_file "$DOTFILES_DIR/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"

  if [[ -d "$DOTFILES_DIR/vscode/snippets" ]]; then
    link_file "$DOTFILES_DIR/vscode/snippets" "$HOME/Library/Application Support/Code/User/snippets"
  fi

  link_file "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
  link_file "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  link_file "$DOTFILES_DIR/claude/skills/visual-teacher" "$HOME/.claude/skills/visual-teacher"
  link_file "$DOTFILES_DIR/claude/skills/design-taste-frontend" "$HOME/.claude/skills/design-taste-frontend"

  # pitwall lives in its own repo; link it only if that checkout is present.
  if [[ -d "$HOME/open-source/pitwall/skills/pitwall" ]]; then
    link_file "$HOME/open-source/pitwall/skills/pitwall" "$HOME/.claude/skills/pitwall"
  fi
  link_file "$DOTFILES_DIR/claude/scheduled-tasks/mail-triage" "$HOME/.claude/scheduled-tasks/mail-triage"
  link_file "$DOTFILES_DIR/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
  link_file "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"
  link_file "$DOTFILES_DIR/mailctl/mailctl" "$HOME/.local/bin/mailctl"

  # Хуки не переносятся при clone, поэтому включает их установщик.
  run_or_print git -C "$DOTFILES_DIR" config core.hooksPath .githooks

  # То же и с фильтром из .gitattributes: срезает model/effortLevel из
  # claude/settings.json, чтобы переключение модели в UI не было изменением репы.
  run_or_print git -C "$DOTFILES_DIR" config filter.claude-volatile.clean "jq -S 'del(.model, .effortLevel, .modelSettings)'"
  run_or_print git -C "$DOTFILES_DIR" config filter.claude-volatile.required true

  # Same idea for VS Code: day/night theme flips are not a settings change.
  # sed, not jq — VS Code writes JSONC (trailing commas) that jq refuses to parse.
  # The pinned value is the canonical theme a fresh install gets.
  run_or_print git -C "$DOTFILES_DIR" config filter.vscode-volatile.clean 'sed '"'"'s/"workbench.colorTheme": *"[^"]*"/"workbench.colorTheme": "Shokunin Light"/'"'"''
  run_or_print git -C "$DOTFILES_DIR" config filter.vscode-volatile.required true
}

apply_macos_defaults() {
  if [[ "$RUN_MACOS" -eq 0 ]]; then
    log "Skipping macOS defaults. Re-run with --macos to apply them."
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY-RUN: bash $DOTFILES_DIR/macos/defaults.sh"
  else
    bash "$DOTFILES_DIR/macos/defaults.sh"
  fi
}

apply_power_settings() {
  if [[ "$RUN_POWER" -eq 0 ]]; then
    log "Skipping power settings. Re-run with --power to apply them."
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY-RUN: bash $DOTFILES_DIR/macos/power.sh"
  else
    bash "$DOTFILES_DIR/macos/power.sh"
  fi
}

install_homebrew_packages
install_oh_my_zsh
link_dotfiles
apply_macos_defaults
apply_power_settings
