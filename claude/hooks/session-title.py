#!/usr/bin/env python3
"""UserPromptSubmit: keep every chat's title readable in the session lists (desktop, web, phone).

On a session's first prompt a quick Haiku call names it; the format lives in ~/.claude/session-titles/legend.md
(a generic "Project · what · stage" without it). Later an agent writes a new title to
~/.claude/session-titles/<session_id> when the chat moves on, and the next prompt applies it: a hook can rename
a session only from a prompt.

A chat started from claude.ai (web, phone) runs under a `claude remote-control` server, which sets its claude.ai
title once, from the first message, and never forwards a rename. For those chats the hook also asks Claude to push
the title with claude.ai's own set_session_title tool.

When a long chat fills up, the owner opens a new one in the same folder and carries on, and the old one keeps its ★
in the desktop app's sidebar. So on a desktop chat's first prompt the hook lists the folder's other ★ chats and asks
Claude to take the ★ off the ones this chat replaces, with the desktop app's own set_session_title tool. It doesn't
archive them: the owner goes back to old chats for an artifact or a file."""
import json, os, pathlib, re, subprocess, sys, time

DIR = pathlib.Path.home() / ".claude" / "session-titles"
DESKTOP = pathlib.Path.home() / "Library" / "Application Support" / "Claude" / "claude-code-sessions"
DEFAULT = ('Format: "Project · what · stage", 2-6 words, at most ~40 characters, the project first because '
           "lists cut the end; in the language of the first message.")
SYNC = ("Title sync from the session-title hook: claude.ai doesn't pick up this chat's local renames. First thing "
        "this turn, call mcp__claude-code-remote__set_session_title with session_id {cse} and title {title}. "
        "Don't mention it in your reply.")
UNSTAR = ("Chat titles from the session-title hook: when a chat gets too long, the user opens a new one and carries on "
          "there. A ★ marks a live main stream, so a chat this one replaces should lose it. Other ★ chats in this "
          "folder:\n{chats}\nIf this chat carries on the work of any of them (the same video, task or stream, which the "
          "user moved here from), rename each with mcp__ccd_session_mgmt__set_session_title to its title without the "
          "leading ★; the user asked for this. Don't archive them: the user goes back to old chats. Leave chats on "
          "other work alone, and when unsure, leave it. Don't mention it in your reply.")


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


def starred_desktop_chats(sid, cwd):
    """The desktop app's other unarchived ★ chats in this folder, newest first, one line each."""
    chats = []
    for p in DESKTOP.glob("*/*/local_*.json"):
        try:
            s = json.loads(p.read_text())
        except (OSError, ValueError):
            continue
        # a chat without a CLI id yet may be this very one, still starting
        if (s.get("cwd") == cwd and not s.get("isArchived") and (s.get("title") or "").startswith("★")
                and s.get("cliSessionId") not in (None, "", sid)):
            chats.append(s)
    chats.sort(key=lambda s: s.get("lastActivityAt") or 0, reverse=True)
    lines = []
    for s in chats[:8]:
        when = time.strftime("%d.%m %H:%M", time.localtime((s.get("lastActivityAt") or 0) / 1000))
        wait = (s.get("postTurnSummary") or {}).get("needs_action")
        lines.append(f"- {s.get('sessionId')} «{s.get('title')}», last active {when}"
                     + (f", waiting for: {wait}" if wait else ""))
    return "\n".join(lines)


def main():
    if os.environ.get("SESSION_TITLE_HOOK"):  # the Haiku call above is a claude run too
        return
    d = json.load(sys.stdin)
    sid = d.get("session_id")
    if not sid:
        return
    DIR.mkdir(parents=True, exist_ok=True)
    want, applied, synced = DIR / sid, DIR / f"{sid}.applied", DIR / f"{sid}.synced"
    first = not applied.exists()
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
    if first and os.environ.get("CLAUDE_CODE_ENTRYPOINT") == "claude-desktop":
        chats = starred_desktop_chats(sid, d.get("cwd") or "")
        if chats:
            out["additionalContext"] = UNSTAR.format(chats=chats)
    if out:
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", **out}}, ensure_ascii=False))


if __name__ == "__main__":
    main()
