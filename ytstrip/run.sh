#!/bin/bash
# Strips ads from the YouTube iOS app: Tailscale split DNS sends youtubei.googleapis.com to the
# yt-proxy node, whose port 443 forwards to mitmproxy on :8443; addon.py rewrites the responses.
set -euo pipefail
TS="/opt/homebrew/opt/tailscale/bin/tailscale --socket=$HOME/.local/share/ytstrip/ts.sock"
until YTSTRIP_IP=$($TS ip -4 2>/dev/null); do sleep 5; done
export YTSTRIP_IP
$TS serve --bg --tcp 443 tcp://127.0.0.1:8443 >/dev/null
# The CA for phones to install (serve may not read files without root, so a tiny local server).
/usr/bin/python3 -m http.server 8081 --bind 127.0.0.1 --directory "$HOME/.local/share/ytstrip/pub" >/dev/null 2>&1 &
$TS serve --bg --http 80 http://127.0.0.1:8081 >/dev/null
exec /opt/homebrew/bin/mitmdump -q -s "$(dirname "$0")/addon.py" --set confdir="$HOME/.local/share/ytstrip/ca" --set upstream_cert=false \
  --mode reverse:https://youtubei.googleapis.com@127.0.0.1:8443 --mode dns@53
