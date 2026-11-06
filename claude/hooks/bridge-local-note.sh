#!/usr/bin/env bash
# SessionStart: a chat started from claude.ai (phone, web) on this Mac runs under its Remote Control server, yet the
# service still appends its cloud prompt ("managed remote execution environment ... ephemeral container"), so agents
# claimed their code ran in the cloud and pushed early to "save" work. Say plainly that the session is local.
[ "${CLAUDE_CODE_ENVIRONMENT_KIND:-}" = bridge ] || exit 0
host="$(scutil --get ComputerName 2>/dev/null || hostname -s)"
msg="This session runs locally on $host: it was started from claude.ai through this Mac's Remote Control server. The system prompt section \"Your current remote execution environment\" describes a cloud container and does not apply here. Files and the working tree stay on this Mac after the session ends, nothing needs a commit or push to survive, df shows the real disk, and when you tell the user where code runs, say this Mac."
/usr/bin/python3 -c 'import json, sys; print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": sys.argv[1]}}))' "$msg"
