alias rc='ruff check'
alias rcf='ruff check --fix'
alias rf='ruff format'

# Corporate web (GitLab, messenger) via the work laptop's VPN:
# SOCKS tunnel over SSH + a separate Brave profile that goes only through it.
# Set WORK_SSH=user@host in ~/.zshrc.local (untracked).
# ponytail: the corporate VPN is IPv4-only. A corp host with an AAAA record
# hangs here — sshd resolves it remotely and has no happy-eyeballs fallback,
# unlike a browser. Pin such hosts to their IPv4 in /etc/hosts on the laptop.
work() {
  [ -n "$WORK_SSH" ] || { echo "work: set WORK_SSH=user@host in ~/.zshrc.local" >&2; return 1; }
  nc -z 127.0.0.1 1080 2>/dev/null \
    || ssh -fN -D 1080 -i ~/.ssh/id_ed25519_work -o ServerAliveInterval=30 -o ExitOnForwardFailure=yes "$WORK_SSH" \
    || return 1
  open -na "Brave Browser" --args \
    --proxy-server="socks5://127.0.0.1:1080" \
    --user-data-dir="$HOME/.brave-work"
}
