#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_home="$(mktemp -d)"
trap 'rm -rf "$tmp_home"' EXIT

mkdir -p "$tmp_home/Library/Application Support/Code/User"
printf 'existing zshrc\n' > "$tmp_home/.zshrc"
printf 'existing zprofile\n' > "$tmp_home/.zprofile"
printf 'existing gitconfig\n' > "$tmp_home/.gitconfig"
printf 'existing vscode settings\n' > "$tmp_home/Library/Application Support/Code/User/settings.json"

output="$tmp_home/install.out"
HOME="$tmp_home" "$repo_dir/install.sh" --dry-run --macos > "$output"

grep -F "DRY-RUN: brew bundle install --file $repo_dir/Brewfile --no-upgrade" "$output" >/dev/null
grep -F "DRY-RUN: backup $tmp_home/.zshrc" "$output" >/dev/null
grep -F "DRY-RUN: symlink $repo_dir/zsh/.zshrc -> $tmp_home/.zshrc" "$output" >/dev/null
grep -F "DRY-RUN: backup $tmp_home/.zprofile" "$output" >/dev/null
grep -F "DRY-RUN: symlink $repo_dir/zsh/.zprofile -> $tmp_home/.zprofile" "$output" >/dev/null
grep -F "DRY-RUN: copy $tmp_home/.gitconfig -> $tmp_home/.gitconfig.local" "$output" >/dev/null
grep -F "DRY-RUN: symlink $repo_dir/claude/settings.json -> $tmp_home/.claude/settings.json" "$output" >/dev/null
grep -F "DRY-RUN: symlink $repo_dir/claude/skills/visual-teacher -> $tmp_home/.claude/skills/visual-teacher" "$output" >/dev/null
grep -F "DRY-RUN: symlink $repo_dir/hammerspoon/init.lua -> $tmp_home/.hammerspoon/init.lua" "$output" >/dev/null
grep -F "DRY-RUN: git -C $repo_dir config core.hooksPath .githooks" "$output" >/dev/null
grep -F "DRY-RUN: bash $repo_dir/macos/defaults.sh" "$output" >/dev/null

test "$(cat "$tmp_home/.zshrc")" = "existing zshrc"
test "$(cat "$tmp_home/.zprofile")" = "existing zprofile"
test "$(cat "$tmp_home/.gitconfig")" = "existing gitconfig"
test ! -e "$tmp_home/.gitconfig.local"
