"""Decision desk: serves index.html, the cards agents write and the answers the owner gives.

Data lives in $DESK_DATA (default ~/.local/share/desk): cards/<id>.json, answers/<id>.json, media/*.
Usage: server.py [port]
"""

import hashlib
import json
import mimetypes
import os
import re
import sys
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).resolve().parent
DATA = Path(os.environ.get("DESK_DATA", Path.home() / ".local/share/desk"))
ID = re.compile(r"^[A-Za-z0-9_.-]{1,80}$")
MEDIA = re.compile(r"^[A-Za-z0-9_.-]{1,200}$")


def read_dir(name):
    out = {}
    for f in sorted((DATA / name).glob("*.json")):
        try:
            out[f.stem] = json.loads(f.read_text())
        except (OSError, ValueError) as e:
            out[f.stem] = {"_error": str(e)}
    return out


def card_problem(c):
    if "_error" in c:
        return c["_error"]
    if not isinstance(c.get("options"), list):
        return "options is not a list"
    for part in [c.get("now")] + c["options"]:
        if isinstance(part, dict) and "keys" in part and not isinstance(part["keys"], list):
            return "keys is not a list"
    return None


def state():
    cards, broken = [], []
    for cid, c in read_dir("cards").items():
        if c.get("status") == "archived":
            continue
        problem = card_problem(c)
        if problem:
            broken.append({"id": cid, "problem": problem})
        else:
            cards.append({**c, "id": cid})
    cards.sort(key=lambda c: (c.get("order", 0), c["id"]))
    body = {"cards": cards, "answers": read_dir("answers"), "broken": broken}
    raw = json.dumps(body, ensure_ascii=False).encode()
    return raw, hashlib.sha1(raw).hexdigest()[:16]


def write_json(path, doc):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(doc, ensure_ascii=False, indent=2))
    tmp.replace(path)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def send(self, code, body=b"", ctype="application/json; charset=utf-8", headers=()):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        for k, v in headers:
            self.send_header(k, v)
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)

    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path in ("/", "/index.html"):
            return self.send(200, (HERE / "index.html").read_bytes(), "text/html; charset=utf-8",
                             [("Cache-Control", "no-cache")])
        if path == "/api/state":
            raw, tag = state()
            if self.headers.get("If-None-Match") == tag:
                return self.send(304, headers=[("ETag", tag)])
            return self.send(200, raw, headers=[("ETag", tag), ("Cache-Control", "no-cache")])
        if path.startswith("/media/") and MEDIA.match(path[7:]):
            return self.media(DATA / "media" / path[7:])
        self.send(404, b"{}")

    do_HEAD = do_GET

    def media(self, f):
        if not f.is_file():
            return self.send(404, b"{}")
        size = f.stat().st_size
        ctype = mimetypes.guess_type(f.name)[0] or "application/octet-stream"
        common = [("Accept-Ranges", "bytes"), ("Cache-Control", "max-age=86400")]
        m = re.match(r"bytes=(\d*)-(\d*)$", self.headers.get("Range", ""))
        if not m or not (m[1] or m[2]):
            return self.send(200, f.read_bytes(), ctype, common)
        start, end = (int(m[1]), int(m[2] or size - 1)) if m[1] else (max(size - int(m[2]), 0), size - 1)
        end = min(end, size - 1)
        if start > end:
            return self.send(416, headers=[("Content-Range", f"bytes */{size}")])
        with f.open("rb") as fh:
            fh.seek(start)
            body = fh.read(end - start + 1)
        self.send(206, body, ctype, common + [("Content-Range", f"bytes {start}-{end}/{size}")])

    def do_POST(self):
        m = re.match(r"^/api/answers/([^/]+)$", self.path)
        if not m or not ID.match(m[1]):
            return self.send(404, b"{}")
        try:
            doc = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))))
        except ValueError:
            return self.send(400, b'{"error":"bad json"}')
        if not isinstance(doc, dict):
            return self.send(400, b'{"error":"not an object"}')
        doc = {k: doc[k] for k in ("pick", "status", "note") if k in doc}
        doc["at"] = datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")
        write_json(DATA / "answers" / f"{m[1]}.json", doc)
        self.send(200, json.dumps(doc, ensure_ascii=False).encode())


if __name__ == "__main__":
    for d in ("cards", "answers", "media"):
        (DATA / d).mkdir(parents=True, exist_ok=True)
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8741
    ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
