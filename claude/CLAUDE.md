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
Exception: scheduled tasks in `~/.claude/scheduled-tasks` are copies, not symlinks (the desktop app refuses symlinked task files): editing one there does not change the repo.
Everything else has no sync — a command applied live has to be duplicated as a line in the matching script.

Order: apply live → reflect in the repo → `./sync.sh` (if you touched brew or Claude settings through the UI) → `git commit` → `git push`.

**Not triggers — never commit, push, or nag about these:**
- Claude Code model/effort changes (`model`, `effortLevel`, `modelSettings` in `claude/settings.json`) — stripped by the `claude-volatile` git filter.
- VS Code theme flips (`workbench.colorTheme` in `vscode/settings.json`) — pinned by the `vscode-volatile` git filter; the user switches light/dark during the day on purpose.

Both files can show a phantom ` M` in `git status` (stat-based, ignores clean filters). Trust `git diff` — if it is empty, the repo is clean.

**The repo's language is English.** Commit messages, README, and any docs or code comments you write here are in English, no matter what language the conversation is in. Talk to the user in whatever language they use; write English into the repo.

Do not commit temporary or debugging changes — say so to the user explicitly instead of committing.
The checkout is shared with parallel sessions: re-read a file before editing it, and commit only your own changes (`git add <paths>`, not `git add -A`).

# Delegating to Kimi

Kimi Code (subscription until about 25.10) is a second pair of hands: `kimi-task "brief"` runs one task in the current directory on `kimi-for-coding` and prints Kimi's report. You stay the lead: you decide what to build, Kimi types it, you review it. Quality outranks savings: work you cannot verify, keep.

Delegate: tests, boilerplate, refactors by an agreed plan, mechanical edits across files, code search and reading (ask for `file:line` references). Keep: architecture and code design decisions, specs, review, tricky logic (concurrency, migrations, money, permissions), the tracker and MRs.

Until 28.09 the Claude weekly limit is almost spent, so Kimi writes the bulk of the code: hand it everything on the Delegate list. From 28.09 Kimi owns the visuals (UI layout and styling, diagrams, HTML artifacts) and takes from the Delegate list whatever it does at least as well as you; the rest you do yourself.

1. **Brief.** Kimi sees the repo and its `AGENTS.md`, nothing from this chat or your memory. Write a self-contained brief: goal, the decided design, files to touch, acceptance criteria, checks to run, facts it cannot find by looking (env quirks, decisions from chat). One task per call.
2. **Isolate.** Start from a clean tree on the task branch; someone's uncommitted work or a second Kimi run in the same repo means a git worktree. Kimi's git writes are blocked by a hook, so its changes arrive uncommitted.
3. **Run** from the repo dir: `kimi-task "brief" 2>/tmp/kimi-<slug>.log`, in the background if it may take more than a couple of minutes. The log holds Kimi's thinking; open it only when the report does not explain a failure.
4. **Verify.** Read the whole `git diff` yourself, not the report, and rerun the checks; for visuals, look at the rendered result. Hunt for scope creep, weakened or deleted tests, invented APIs, hardcoded values, drift from the surrounding style. Done = a diff you would sign as your own, green checks you ran yourself.
5. **Fix** small things yourself; send larger ones back with concrete notes: `kimi-task "notes" -c` continues Kimi's last session in that dir. After two failed rounds, finish it yourself.

@~/open-source/second-brain/system/claude.md
