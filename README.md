# dotfiles

Personal macOS dotfiles and bootstrap scripts.

## Structure

- `Brewfile` - Homebrew packages, casks, npm/go/uv tools, and VSCode extensions.
- `claude/` - Claude Code settings and custom skills.
- `git/` - tracked Git config; local-only values are included from `~/.gitconfig.local`.
- `hammerspoon/` - Hammerspoon config (Shift+Tab toggles plan/bypass mode in Claude).
- `iterm/` - exported iTerm profile JSON for manual import.
- `macos/` - macOS defaults script for appearance, menu bar, Finder, keyboard, screenshots, sound, Dock, and Mission Control.
- `vscode/` - VSCode settings and keybindings.
- `zsh/` - zsh startup config (`.zshrc`, `.zprofile`) and aliases.

## Install

Preview actions without changing the system:

```bash
./install.sh --dry-run
```

Install everything from the `Brewfile`, back up existing config files, and create symlinks:

```bash
./install.sh
```

Apply macOS defaults as well:

```bash
./install.sh --macos
```

The installer backs up existing files into `~/.dotfiles-backups/<timestamp>/` before replacing them with symlinks. This includes `.zshrc` and `.zprofile`.

It also installs `oh-my-zsh` when `~/.oh-my-zsh` is missing - the tracked `.zshrc` sources it, and Homebrew does not ship it.

## Setup from scratch (new machine)

1. `xcode-select --install`
2. Install Homebrew:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
3. Clone this repo:
   ```bash
   git clone https://github.com/Maksim-Burtsev/dotfiles.git ~/open-source/dotfiles
   ```
4. Adopt any app that is already installed outside of brew, otherwise `brew bundle` aborts on "There is already an App at ...":
   ```bash
   brew install --cask --adopt <name>
   ```
5. Preview, then install with macOS defaults:
   ```bash
   cd ~/open-source/dotfiles && ./install.sh --dry-run && ./install.sh --macos
   ```
6. Optional: `$(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc` - creates the `~/.fzf.zsh` that `.zshrc` sources.
7. Create `~/.zshrc.local` and `~/.gitconfig.local` with machine-local values (see **Local Values** below).
8. iTerm: *Settings → Profiles → Other Actions → Import JSON Profiles* → `iterm/profile.json`.
9. Grant Hammerspoon Accessibility permission in *System Settings → Privacy & Security → Accessibility*. Without it `hs.eventtap` silently does nothing and Shift+Tab will not switch Claude modes.
10. Run `claude` and sign in. Plugins are restored from `enabledPlugins` in the tracked settings.
11. VSCode extensions are already installed by `brew bundle` - no extra step.

## Keeping the repo current

```bash
./sync.sh
```

Regenerates the `Brewfile` from the current machine, restores the `~/.claude/settings.json` symlink if Claude Code overwrote it, and scans for secrets. Everything else is symlinked, so it needs no syncing. Run before committing.

## Local Values

This repository stores public configuration only. Keep machine-local or sensitive values outside the repo:

- `~/.zshrc.local` - sourced last by the tracked `.zshrc`. Registry tokens and per-machine `PATH` entries go here:
  ```bash
  export GITLAB_REGISTRY_ACCESS_TOKEN_NAME=...
  export GITLAB_REGISTRY_ACCESS_TOKEN=...
  export UV_INDEX_GITLAB_USERNAME="$GITLAB_REGISTRY_ACCESS_TOKEN_NAME"
  export UV_INDEX_GITLAB_PASSWORD="$GITLAB_REGISTRY_ACCESS_TOKEN"
  ```
- `~/.gitconfig.local` - included by the tracked `.gitconfig`. Holds `url.*.insteadOf` entries with embedded credentials and `includeIf` blocks for work directories. The installer copies an existing untracked `~/.gitconfig` here automatically, with mode 600.
- local `.env` files

A `gitleaks` pre-commit hook scans staged content and blocks the commit if it finds a secret. It is enabled by `install.sh` via `core.hooksPath` - hooks are not carried over by `git clone`, so a fresh clone needs the installer to run once. The `.gitignore` only filters *filenames*; the hook is what actually inspects file contents.
