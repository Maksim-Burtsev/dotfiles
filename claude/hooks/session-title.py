#!/usr/bin/env python3
"""UserPromptSubmit: keep every chat's title readable in the session lists (desktop, web, phone).

On a session's first prompt a quick Haiku call names it; the format lives in ~/.claude/session-titles/legend.md
(a generic "Project · what · stage" without it). Later an agent writes a new title to
~/.claude/session-titles/<session_id> when the chat moves on, and the next prompt applies it: a hook can rename
a session only from a prompt."""
import json, os, pathlib, subprocess, sys

DIR = pathlib.Path.home() / ".claude" / "session-titles"
DEFAULT = ('Format: "Project · what · stage", 2-6 words, at most ~40 characters, the project first because '
           "lists cut the end; in the language of the first message.")


def generate(prompt, cwd):
    legend = (DIR / "legend.md").read_text() if (DIR / "legend.md").exists() else DEFAULT
    ask = (f"Name this Claude Code chat for a session list.\n\n{legend}\n\nFolder: {cwd}\n"
           f"First message:\n{prompt[:4000]}\n\nReply with the title only.")
    claude = os.environ.get("CLAUDE_CODE_EXECPATH") or "claude"
    try:
        r = subprocess.run([claude, "-p", "--model", "haiku", "--no-session-persistence",
                            "--settings", '{"disableAllHooks": true}', ask], capture_output=True, text=True,
                           timeout=25, cwd=DIR, env=dict(os.environ, SESSION_TITLE_HOOK="1"))
    except (OSError, subprocess.TimeoutExpired):
        return ""
    lines = r.stdout.strip().splitlines() if r.returncode == 0 else []
    return lines[0].strip().strip('"')[:60] if lines else ""


def main():
    if os.environ.get("SESSION_TITLE_HOOK"):  # the Haiku call above is a claude run too
        return
    d = json.load(sys.stdin)
    sid = d.get("session_id")
    if not sid:
        return
    DIR.mkdir(parents=True, exist_ok=True)
    want, applied = DIR / sid, DIR / f"{sid}.applied"
    title = want.read_text().strip() if want.exists() else ""
    if not title and not applied.exists():
        title = generate(d.get("prompt") or "", d.get("cwd") or "")
        if title:
            want.write_text(title + "\n")
    if title and (not applied.exists() or applied.read_text() != title):
        applied.write_text(title)
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "sessionTitle": title}},
                         ensure_ascii=False))
    elif not applied.exists():
        applied.write_text("")  # the name call failed: don't retry on every prompt


if __name__ == "__main__":
    main()
