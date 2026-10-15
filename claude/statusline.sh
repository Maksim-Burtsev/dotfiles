#!/bin/bash
in=$(cat)
limits=$(jq -c --argjson now "$(date +%s)" 'select(.rate_limits) | .rate_limits + {updated: $now}' <<<"$in" 2>/dev/null)
if [ -n "$limits" ]; then
  mkdir -p "$HOME/.claude/state"
  tmp=$(mktemp "$HOME/.claude/state/.rate-limits.XXXXXX") && printf '%s\n' "$limits" >"$tmp" && mv "$tmp" "$HOME/.claude/state/rate-limits.json"
fi
jq -r '[.model.display_name, (.rate_limits.seven_day.used_percentage // empty | "week \(floor)%"), (.rate_limits.five_hour.used_percentage // empty | "5h \(floor)%")] | join(" · ")' <<<"$in" 2>/dev/null
