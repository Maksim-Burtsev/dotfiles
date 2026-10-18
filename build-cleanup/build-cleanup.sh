#!/bin/bash
# Weekly: delete the cargo build output agents leave behind (session scratchpads, merl batch
# runs, merl worktrees, /tmp), then `uv cache prune`. A dir goes only when cargo made it
# (CACHEDIR.TAG and .rustc_info.json inside), nothing in it changed for 3 days, and no process
# has a file or its cwd in it. `-n` lists what would go and deletes nothing.
set -u
PATH=/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin
dry=0; [[ ${1-} == -n ]] && dry=1
days=3

open=$(mktemp); trap 'rm -f "$open"' EXIT
lsof -n -Fn 2>/dev/null | sed -n 's/^n//p' >"$open"

roots=("/private/tmp/claude-$UID" "$HOME/.cache/merl-batch")
for wt in "$HOME"/open-source/merl-*; do
  [[ -f $wt/.git ]] && roots+=("$wt")   # worktrees only; ~/open-source/merl itself never matches
done

echo "$(date '+%F %T') build-cleanup$([[ $dry == 1 ]] && echo ' (dry run)'), $(df -h / | awk 'NR==2{print $4}') free"
total=0
while IFS= read -r d; do
  [[ -f $d/CACHEDIR.TAG && -f $d/.rustc_info.json ]] || continue
  [[ -z $(find "$d" -maxdepth 3 -mtime -"$days" -print -quit 2>/dev/null) ]] || { echo "  recent  $d"; continue; }
  if grep -qxF -- "$d" "$open" || grep -qF -- "$d/" "$open"; then echo "  in use  $d"; continue; fi
  kb=$(du -sk "$d" 2>/dev/null | cut -f1)
  total=$((total + kb))
  printf '  %5dM  %s\n' $((kb / 1024)) "$d"
  [[ $dry == 1 ]] || rm -rf "$d"
done < <(
  find "${roots[@]}" -type d \( -name target -o -name '*-target' -o -name 'target-*' \) -prune -print 2>/dev/null
  find /private/tmp -maxdepth 1 -type d -name '*-target' 2>/dev/null
)
echo "  $((total / 1024))M in build dirs$([[ $dry == 1 ]] && echo ' would go' || echo ' deleted') (du; APFS clones share blocks, so df frees less)"

if [[ $dry == 1 ]]; then
  echo "  would run: uv cache prune"
else
  # A running `uv run` holds the cache lock; skip this week instead of hanging (Batcave's server always holds it).
  UV_LOCK_TIMEOUT=60 uv cache prune 2>&1 | sed 's/^/  uv: /'
  echo "$(date '+%F %T') done, $(df -h / | awk 'NR==2{print $4}') free"
fi
