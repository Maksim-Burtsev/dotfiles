# This machine's settings live in git

Repo: `~/open-source/dotfiles` (github.com/Maksim-Burtsev/dotfiles).
Rule: **changed the state of the machine — reflect it in the repo and push in the same pass.**
Applied live without a commit = a change that dies on the next reinstall.

Where things go:

| What you changed | File in the repo |
|---|---|
| `defaults write`, appearance, Finder, keyboard, Dock, screenshots | `macos/defaults.sh` |
| `pmset`, `sysadminctl`, sleep and lock screen | `macos/power.sh` |
| installed/removed a package, cask, npm/go/uv tool, VSCode extension | `Brewfile` — via `./sync.sh`, not by hand |
| zsh, aliases, PATH | `zsh/` |
| git config | `git/` |
| VSCode settings/keybindings | `vscode/` |
| Claude Code settings, skills, hooks | `claude/` |
| iTerm | `iterm/` — export the profile manually |

`zsh/`, `git/`, `vscode/`, `claude/`, `hammerspoon/` are symlinked into `$HOME`: editing the file in `$HOME` **is** editing the repo, all that is left is to commit.
Everything else has no sync — a command applied live has to be duplicated as a line in the matching script.

Order: apply live → reflect in the repo → `./sync.sh` (if you touched brew or Claude settings through the UI) → `git commit` → `git push`.

**The repo's language is English.** Commit messages, README, and any docs or code comments you write here are in English, no matter what language the conversation is in. Talk to the user in whatever language they use; write English into the repo.

Do not commit temporary or debugging changes — say so to the user explicitly instead of committing.
The checkout is shared with parallel sessions: re-read a file before editing it, and commit only your own changes (`git add <paths>`, not `git add -A`).
