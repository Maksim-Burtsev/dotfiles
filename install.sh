#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="${HOME}/.dotfiles-backups/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=0
RUN_MACOS=0

usage() {
  cat <<USAGE
Usage: ./install.sh [--dry-run] [--macos] [--help]

Options:
  --dry-run  Print actions without changing files, packages, or settings.
  --macos    Also apply macOS defaults from macos/defaults.sh.
  --help     Show this help message.
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
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY-RUN: brew bundle install --file $DOTFILES_DIR/Brewfile --no-upgrade"
    return
  fi

  command -v brew >/dev/null 2>&1 || die "Homebrew is not installed. Install it first: https://brew.sh"
  brew bundle install --file "$DOTFILES_DIR/Brewfile" --no-upgrade
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

preserve_private_gitconfig() {
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
      log "Preserved private git config at $local_gitconfig"
    fi
  fi
}

link_dotfiles() {
  preserve_private_gitconfig

  link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  link_file "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
  link_file "$DOTFILES_DIR/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
  link_file "$DOTFILES_DIR/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"

  if [[ -d "$DOTFILES_DIR/vscode/snippets" ]]; then
    link_file "$DOTFILES_DIR/vscode/snippets" "$HOME/Library/Application Support/Code/User/snippets"
  fi
}

install_vscode_extensions() {
  local extensions_file="$DOTFILES_DIR/vscode/extensions.txt"

  [[ -f "$extensions_file" ]] || return

  if [[ "$DRY_RUN" -eq 0 ]] && ! command -v code >/dev/null 2>&1; then
    log "WARN: VSCode 'code' CLI is not installed; skipping extensions."
    return
  fi

  while IFS= read -r extension || [[ -n "$extension" ]]; do
    [[ -n "$extension" ]] || continue
    run_or_print code --install-extension "$extension"
  done < "$extensions_file"
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

install_homebrew_packages
link_dotfiles
install_vscode_extensions
apply_macos_defaults
