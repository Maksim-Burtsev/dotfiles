"""mitmproxy addon: strips YouTube app ads using Maasea's script (via worker.js) and answers DNS for youtubei."""
import base64
import ipaddress
import json
import os
import re
import subprocess
import threading

from mitmproxy import dns, http

HERE = os.path.dirname(os.path.abspath(__file__))
NODE_IP = ipaddress.ip_address(os.environ["YTSTRIP_IP"])  # tailnet IP of the yt-proxy node
HOST = "youtubei.googleapis.com"
PATTERN = re.compile(
    r"^https://youtubei\.googleapis\.com/youtubei/v1/"
    r"(browse|next|player|search|reel/reel_watch_sequence|guide|account/get_setting|get_watch|config)(\?.*)?$"
)


class YtStrip:
    def __init__(self):
        self.lock = threading.Lock()
        self.proc = None

    def worker(self):
        if self.proc is None or self.proc.poll() is not None:
            self.proc = subprocess.Popen(
                ["/opt/homebrew/bin/node", os.path.join(HERE, "worker.js")],
                stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True,
            )
        return self.proc

    def dns_request(self, flow: dns.DNSFlow):
        q = flow.request.question
        if q and q.name.rstrip(".").lower() == HOST:
            answers = [dns.ResourceRecord.A(q.name, NODE_IP, ttl=300)] if q.type == dns.types.A else []
            flow.response = flow.request.succeed(answers)
        else:
            flow.response = flow.request.fail(dns.response_codes.REFUSED)  # not an open resolver

    def response(self, flow: http.HTTPFlow):
        if not PATTERN.match(flow.request.pretty_url) or flow.response.status_code != 200:
            return
        msg = json.dumps({
            "url": flow.request.pretty_url,
            "reqHeaders": dict(flow.request.headers),
            "status": flow.response.status_code,
            "headers": dict(flow.response.headers),
            "body": base64.b64encode(flow.response.content or b"").decode(),
        })
        with self.lock:
            p = self.worker()
            p.stdin.write(msg + "\n")
            p.stdin.flush()
            out = json.loads(p.stdout.readline() or '{"body": null}')
        if out["body"]:
            flow.response.content = base64.b64decode(out["body"])


addons = [YtStrip()]
