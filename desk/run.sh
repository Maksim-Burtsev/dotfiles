#!/bin/bash
# Decision desk on 127.0.0.1:8741, published to the tailnet at /desk beside Batcave's /.
set -euo pipefail
/usr/local/bin/tailscale serve --bg --set-path /desk http://127.0.0.1:8741 >/dev/null || true
exec /opt/homebrew/bin/python3 "$(dirname "$0")/server.py" 8741
