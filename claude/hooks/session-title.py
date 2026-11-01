#!/usr/bin/env python3
"""UserPromptSubmit: keep every chat's title readable in the session lists (desktop, web, phone).

On a session's first prompt a quick Haiku call names it; the format lives in ~/.claude/session-titles/legend.md
(a generic "Project · what · stage" without it). Later an agent writes a new title to
~/.claude/session-titles/<session_id> when the chat moves on, and the next prompt applies it: a hook can rename
a session only from a prompt.

A chat started from claude.ai (web, phone) runs under a `claude remote-control` server, which sets its claude.ai
title once, from the first message, and never forwards a rename. For those chats the hook also asks Claude to push
the title with claude.ai's own set_session_title tool."""
import json, os, pathlib, re, subprocess, sys

DIR = pathlib.Path.home() / ".claude" / "session-titles"
DEFAULT = ('Format: "Project · what · stage", 2-6 words, at most ~40 characters, the project first because '
           "lists cut the end; in the language of the first message.")
SYNC = ("Title sync from the session-title hook: claude.ai doesn't pick up this chat's local renames. First thing "
        "this turn, call mcp__claude-code-remote__set_session_title with session_id {cse} and title {title}. "
        "Don't mention it in your reply.")


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


def remote_session_id():
    """The claude.ai session id (cse_...) when a Remote Control server spawned this chat, else None."""
    pid = os.getppid()
    for _ in range(4):  # python <- shell <- claude, with room to spare
        r = subprocess.run(["ps", "-ww", "-o", "ppid=,command=", "-p", str(pid)], capture_output=True, text=True)
        parts = r.stdout.split(None, 1)
        if len(parts) < 2:
            return None
        if os.path.basename(parts[1].split()[0]) in ("claude", "claude.exe"):  # the chat's own process
            m = re.search(r"--session-id (cse_\w+)", parts[1])
            return m.group(1) if m else None
        pid = int(parts[0])
        if pid <= 1:
            return None
    return None


def main():
    if os.environ.get("SESSION_TITLE_HOOK"):  # the Haiku call above is a claude run too
        return
    d = json.load(sys.stdin)
    sid = d.get("session_id")
    if not sid:
        return
    DIR.mkdir(parents=True, exist_ok=True)
    want, applied, synced = DIR / sid, DIR / f"{sid}.applied", DIR / f"{sid}.synced"
    title = want.read_text().strip() if want.exists() else ""
    if not title and not applied.exists():
        title = generate(d.get("prompt") or "", d.get("cwd") or "")
        if title:
            want.write_text(title + "\n")
    out = {}
    if title and (not applied.exists() or applied.read_text() != title):
        applied.write_text(title)
        out["sessionTitle"] = title
    elif not applied.exists():
        applied.write_text("")  # the name call failed: don't retry on every prompt
    # ponytail: asks on two prompts per title, which covers losing a race with claude.ai's own first-message
    # title and one skipped call; read the call's result from the transcript if that ever falls short
    asks, _, asked = (synced.read_text() if synced.exists() else "").partition("\t")
    asks = int(asks) if asked == title and asks.isdigit() else 0
    cse = remote_session_id() if title and asks < 2 else None
    if cse:
        synced.write_text(f"{asks + 1}\t{title}")
        out["additionalContext"] = SYNC.format(cse=json.dumps(cse), title=json.dumps(title, ensure_ascii=False))
    if out:
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", **out}}, ensure_ascii=False))


if __name__ == "__main__":
    main()
