# dotfiles

Personal macOS dotfiles and bootstrap scripts.

## Structure

- `Brewfile` - Homebrew packages and casks.
- `git/` - tracked Git config; local-only values are included from `~/.gitconfig.local`.
- `iterm/` - exported iTerm profile JSON for manual import.
- `macos/` - macOS defaults script for Finder, keyboard, screenshots, and Dock.
- `vscode/` - VSCode settings, keybindings, and extension list.
- `zsh/` - zsh config split into aliases and functions.

## Install

Preview actions without changing the system:

```bash
./install.sh --dry-run
```

Install Homebrew packages, create backups of existing config files, create symlinks, and install VSCode extensions:

```bash
./install.sh
```

Apply macOS defaults as well:

```bash
./install.sh --macos
```

The installer backs up existing files into `~/.dotfiles-backups/<timestamp>/` before replacing them with symlinks.

## Local Values

This repository stores public configuration only. Keep machine-local or sensitive values in files outside the repo, for example:

- `~/.zshrc.local`
- `~/.gitconfig.local`
- local `.env` files

The `.gitignore` is configured to keep common local credential files and key material out of Git.
