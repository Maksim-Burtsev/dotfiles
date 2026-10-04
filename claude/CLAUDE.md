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

# Finishing a task

When a task is finished, make it unmistakable whether this chat is done: either that nothing is left for me and I can close it, or exactly what you need from me and where. Use your own words. I should never have to ask.

I often read the end of a long report on the phone or only its first lines: say done or what you need from me at the top. A turn that ends waiting on my answers repeats the questions in full, not "see Q9–Q15 above".

# How to work with me

- A result for me is a link (artifact, PR, issue), never a local path.
- A small fix inside the task (a stale line, the follow-up issue the repo's rules call for) is done, not offered as "say yes and I'll…".
- Facts about this machine (screen, font, terminal size, what runs) are read, never asked.
- When you stop without finishing, comment on the issue: the branch, where it stands, and what unblocks it. A chat is not where state lives.
- When I interrupt with a question, answer it and go back to the interrupted work.
- In a stack of PRs, merge the base without `--delete-branch`: deleting its branch closes the PR stacked on it for good.

# Kimi: a second opinion on design

You and your subagents do all the work, design included. Kimi Code (`kimi-task`, subscription until about 25.10) is only a second opinion on visual design (UI layout and styling, diagrams, HTML artifacts): its 5-hour limit is spent most of the time and your work is better, so nothing waits on Kimi.

On such a task, start one Kimi run in the background as you begin your own version: `kimi-task "brief" 2>/tmp/kimi-<slug>.log`, from a separate worktree or scratch folder, since Kimi writes its files where it runs. Kimi sees nothing from this chat or your memory: the brief carries the goal and every constraint the owner set. An empty report and `usage limit` in the log mean no quota: finish without Kimi. A finished run is the alternative: check its rendered result and show it to the owner next to yours.

# The `agent-ok` label

In a repo that has it, `agent-ok` marks an issue that is settled: a fresh agent given only its link can do it without asking the owner anything, and the owner never re-reads it. It is not delegation: the owner has already made every decision, the label saves them a second read. Put it yourself:

- on an issue you file after the owner settled it in chat, with no question to them left;
- on an open issue once any chat settles its remaining details;
- on a bug fix whose right behaviour is obvious and that changes no key, screen, animation or default.

Before labelling, write every decision from the chat into the issue: the next agent sees only the issue. An issue that still holds a question to the owner gets no label. When an issue looks settled but is unlabelled, offer in one line to label it; do not label it silently.

# merl

merl is my code editor. When I ask to prepare something in merl (branches to review, a project to read), run `merl --for-agents` first and do what it says.

@~/open-source/second-brain/system/claude.md
