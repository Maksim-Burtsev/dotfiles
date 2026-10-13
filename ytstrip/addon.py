"""mitmproxy addon: strips YouTube app ads using Maasea's script (via worker.js) and answers DNS for youtubei."""
import base64
import ipaddress
import json
import os
import re
import subprocess
import socket
import threading
import time

from mitmproxy import dns, http
from mitmproxy.proxy import server_hooks

HERE = os.path.dirname(os.path.abspath(__file__))
NODE_IP = ipaddress.ip_address(os.environ["YTSTRIP_IP"])  # tailnet IP of the yt-proxy node
HOST = "youtubei.googleapis.com"
PATTERN = re.compile(
    r"^/youtubei/v1/"
    r"(browse|next|player|search|reel/reel_watch_sequence|guide|account/get_setting|get_watch|config)(\?.*)?$"
)


def log(line):
    with open(os.path.expanduser("~/Library/Logs/ytstrip/strip.log"), "a") as f:
        f.write(time.strftime("%H:%M:%S ") + line + "\n")


class YtStrip:
    def __init__(self):
        self.lock = threading.Lock()
        self.proc = None
        self.upstream = None  # (ip, expires_at)

    def worker(self):
        if self.proc is None or self.proc.poll() is not None:
            self.proc = subprocess.Popen(
                ["/opt/homebrew/bin/node", os.path.join(HERE, "worker.js")],
                stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True,
            )
        return self.proc

    def real_ip(self):
        # The Mac mini's own resolver follows the same split DNS rule and would hand back
        # yt-proxy, so the proxy would dial itself. Ask a public resolver instead.
        if self.upstream and time.time() < self.upstream[1]:
            return self.upstream[0]
        qname = b"".join(bytes([len(p)]) + p.encode() for p in HOST.split(".")) + b"\0"
        query = b"\x12\x34\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00" + qname + b"\x00\x01\x00\x01"
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.settimeout(3)
            s.sendto(query, ("1.1.1.1", 53))
            r = s.recv(4096)
        i, ancount = len(query), int.from_bytes(r[6:8], "big")
        for _ in range(ancount):  # answer names are 2-byte compression pointers
            rtype, ttl, rdlen = int.from_bytes(r[i + 2:i + 4], "big"), int.from_bytes(r[i + 6:i + 10], "big"), int.from_bytes(r[i + 10:i + 12], "big")
            if rtype == 1:
                a = socket.inet_ntoa(r[i + 12:i + 16])
                break
            i += 12 + rdlen
        else:
            raise RuntimeError(f"no A record for {HOST}")
        self.upstream = (a, time.time() + max(ttl, 60))
        return self.upstream[0]

    def server_connect(self, data: server_hooks.ServerConnectionHookData):
        if data.server.address and data.server.address[0] == HOST:
            data.server.address = (self.real_ip(), data.server.address[1])

    def request(self, flow: http.HTTPFlow):
        flow.request.host_header = HOST  # keep the real name when dialing the resolved IP

    def dns_request(self, flow: dns.DNSFlow):
        q = flow.request.question
        if q and q.name.rstrip(".").lower() == HOST:
            answers = [dns.ResourceRecord.A(q.name, NODE_IP, ttl=300)] if q.type == dns.types.A else []
            flow.response = flow.request.succeed(answers)
        else:
            flow.response = flow.request.fail(dns.response_codes.REFUSED)  # not an open resolver

    def response(self, flow: http.HTTPFlow):
        if not PATTERN.match(flow.request.path) or flow.response.status_code != 200:
            return
        started = time.time()
        msg = json.dumps({
            "url": f"https://{HOST}{flow.request.path}",
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
        size = len(flow.response.content or b"")
        if out["body"]:
            flow.response.content = base64.b64decode(out["body"])
        log(f"strip {flow.request.path[:60]} {size} -> {len(flow.response.content) if out['body'] else 'unchanged'} {time.time() - started:.2f}s")


addons = [YtStrip()]
