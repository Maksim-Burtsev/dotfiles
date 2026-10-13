# ytstrip

Strips ads from the stock YouTube app on the iPhone and iPad. Runs on the Mac mini.

How a request flows:

1. Tailscale split DNS (admin console → DNS → nameserver = the `yt-proxy` node, restricted to
   `youtubei.googleapis.com`) sends the app's API host to `yt-proxy`. Everything else, including
   the video streams from `*.googlevideo.com`, goes direct.
2. `yt-proxy` is a second, userspace `tailscaled` on the Mac mini (`dev.mburtsev.ytstrip-node`).
   It needs its own IP because the main node's port 443 belongs to Batcave's `tailscale serve`.
   Its `serve` forwards 443 to mitmproxy on `127.0.0.1:8443`, and inbound UDP 53 reaches
   mitmproxy's DNS mode, which answers only `youtubei.googleapis.com`.
3. `addon.py` hands the API responses to `worker.js`, which runs
   [Maasea's YouTube script](https://github.com/Maasea/sgmodule) (a Surge script) and pulls its
   latest version daily into `~/.local/share/ytstrip`.

The CA in `~/.local/share/ytstrip/ca` is name-constrained to `youtubei.googleapis.com`, so the
phones trust it for nothing else. It is not in the repo. On a fresh machine:

```sh
C=~/.local/share/ytstrip/ca; mkdir -p $C ~/.local/share/ytstrip/pub && cd $C
openssl req -x509 -new -newkey rsa:2048 -nodes -keyout key.pem -out cert.pem -days 3650 \
  -subj "/CN=ytstrip (youtubei only)/O=Mac mini" \
  -addext "basicConstraints=critical,CA:TRUE,pathlen:0" -addext "keyUsage=critical,keyCertSign,cRLSign" \
  -addext "nameConstraints=critical,permitted;DNS:youtubei.googleapis.com"
cat key.pem cert.pem > mitmproxy-ca.pem && cp cert.pem mitmproxy-ca-cert.pem && cp cert.pem ../pub/ytstrip.crt
/opt/homebrew/opt/tailscale/bin/tailscale --socket=$HOME/.local/share/ytstrip/ts.sock up --hostname=yt-proxy --accept-dns=false
```

Then on each phone open `http://yt-proxy/ytstrip.crt` in Safari, install the profile, and turn
it on in Settings → General → About → Certificate Trust Settings.

Turning it off: remove the split DNS entry in the Tailscale admin console.
