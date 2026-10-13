"""Self-check for the onesie key stripping: python3 test_drop_field.py"""
import os
import sys
import types

for name in ["mitmproxy", "mitmproxy.dns", "mitmproxy.http", "mitmproxy.proxy", "mitmproxy.proxy.server_hooks"]:
    sys.modules[name] = types.SimpleNamespace(HTTPFlow=object, DNSFlow=object, ServerConnectionHookData=object)
sys.modules["mitmproxy"].dns = sys.modules["mitmproxy.dns"]
sys.modules["mitmproxy"].http = sys.modules["mitmproxy.http"]
sys.modules["mitmproxy.proxy"].server_hooks = sys.modules["mitmproxy.proxy.server_hooks"]
os.environ.setdefault("YTSTRIP_IP", "127.0.0.1")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import addon as a  # noqa: E402


def f(num, payload):
    return a.enc_varint(num << 3 | 2) + a.enc_varint(len(payload)) + payload


onesie = f(1, b"client-key") + f(2, b"encrypt-key")
msg = f(1, f(16, f(7, f(138536474, f(146311580, onesie) + f(5, b"keep")) + f(9, b"sibling")))) + a.enc_varint(2 << 3) + a.enc_varint(150)
out = a.drop_field(msg, a.ONESIE_PATH, a.ONESIE_FIELD)
assert out is not None and b"client-key" not in out and b"keep" in out and b"sibling" in out
assert out.endswith(a.enc_varint(2 << 3) + a.enc_varint(150))
assert a.drop_field(out, a.ONESIE_PATH, a.ONESIE_FIELD) is None
print("ok")
