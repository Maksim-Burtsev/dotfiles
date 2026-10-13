// Runs Maasea's Surge script (youtube.response.js) outside Surge.
// Protocol: one JSON line in {url, status, headers, body: base64}, one JSON line out {body: base64 | null}.
const fs = require("fs");
const path = require("path");
const vm = require("vm");
const readline = require("readline");

const dir = path.join(process.env.HOME, ".local/share/ytstrip");
const storeFile = path.join(dir, "store.json");
const scriptFile = path.join(dir, "youtube.response.js");
const SCRIPT_URL = "https://raw.githubusercontent.com/Maasea/sgmodule/master/Script/Youtube/youtube.response.js";
let store = {};
try { store = JSON.parse(fs.readFileSync(storeFile, "utf8")); } catch {}

let script, scriptMtime = 0;
function load() {
  const m = fs.statSync(scriptFile).mtimeMs;
  if (m !== scriptMtime) { script = new vm.Script(fs.readFileSync(scriptFile, "utf8")); scriptMtime = m; }
}

// YouTube changes its responses now and then; the script's author follows. Pull the latest daily.
async function refresh() {
  try {
    const res = await fetch(SCRIPT_URL);
    const text = await res.text();
    if (!res.ok || text.length < 10000) return;
    new vm.Script(text); // refuse a file that does not parse
    fs.writeFileSync(scriptFile + ".tmp", text);
    fs.renameSync(scriptFile + ".tmp", scriptFile);
  } catch {}
}
refresh();
setInterval(refresh, 24 * 3600 * 1000).unref();

function run(req) {
  load();
  return new Promise((resolve) => {
    const timer = setTimeout(() => resolve(null), 3000);
    const ctx = {
      console: { log() {} },
      $argument: JSON.stringify({ captionLang: "off", blockUpload: true, blockImmersive: true, blockShorts: false, debug: false }),
      $request: { url: req.url, method: "POST", headers: req.reqHeaders || {} },
      $response: { status: req.status, headers: req.headers, body: new Uint8Array(Buffer.from(req.body, "base64")) },
      $persistentStore: {
        read: (k) => store[k] ?? null,
        write: (v, k) => { store[k] = v; fs.writeFile(storeFile, JSON.stringify(store), () => {}); return true; },
      },
      $httpClient: { post: (_o, cb) => cb("unsupported"), get: (_o, cb) => cb("unsupported") },
      $notification: { post() {} },
      $done: (r) => {
        clearTimeout(timer);
        const b = r && (r.body ?? r.bodyBytes);
        resolve(b ? Buffer.from(b instanceof ArrayBuffer ? new Uint8Array(b) : b).toString("base64") : null);
      },
      setTimeout, clearTimeout, TextEncoder, TextDecoder, Uint8Array, ArrayBuffer, URL, URLSearchParams,
    };
    try { script.runInNewContext(ctx); } catch { clearTimeout(timer); resolve(null); }
  });
}

const rl = readline.createInterface({ input: process.stdin });
let queue = Promise.resolve();
rl.on("line", (line) => {
  queue = queue.then(async () => {
    let out = null;
    try { out = await run(JSON.parse(line)); } catch {}
    process.stdout.write(JSON.stringify({ body: out }) + "\n");
  });
});
