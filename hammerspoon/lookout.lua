-- Lookout: a focus-block timer plus a Mattermost alert for urgent messages only.
-- ⌃⌥T: pick the block length (Enter = 40, or type any number of minutes) or stop the block.
-- While a block runs, lookout.py reads Mattermost every 10 minutes and asks Claude once.
-- Urgent: a panel above every window, with a sound, until clicked. A failure: ⚠ in the menu bar.
-- No digest and nothing else on screen: the owner reads the chats in the break.

local M = {}
local dir = (hs.fs.pathToAbsolute(hs.configdir .. "/init.lua") or ""):match("(.*/)") or (hs.configdir .. "/")
local script = dir .. "lookout.py"
local CHECK_EVERY = 600

local bar = hs.menubar.new()
local ending, tick, poll, err, panel

local function left() return ending and math.max(0, math.ceil((ending - os.time()) / 60)) or 0 end

local function render()
  if not ending then bar:setTitle("◯") return end
  bar:setTitle("◐ " .. left() .. (err and " ⚠" or ""))
end

local function run(args, cb)
  local t = hs.task.new("/usr/bin/python3", function(code, out, stderr)
    if cb then
      local ok, res = pcall(hs.json.decode, out or "")
      if code ~= 0 or not ok or not res then res = { alerts = {}, error = "lookout.py упал: " .. (stderr or ""):sub(1, 160) } end
      cb(res)
    end
  end, { script, table.unpack(args) })
  t:setEnvironment({ PATH = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin", HOME = os.getenv("HOME") })
  t:start()
end

local function esc(s) return (s or ""):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;") end

local function closePanel() if panel then panel:delete() panel = nil end end

local uc = hs.webview.usercontent.new("lookout")
uc:setCallback(function(msg)
  if msg.body and msg.body ~= "" then hs.urlevent.openURL(msg.body) end
  closePanel()
end)

local function showAlerts(alerts)
  closePanel()
  local items = {}
  for _, a in ipairs(alerts) do
    items[#items + 1] = string.format(
      '<div class="a" onclick="send(\'%s\')"><div class="h">%s · %s</div><div class="t">%s</div><div class="w">%s</div></div>',
      esc(a.url), esc(a.who), esc(a.where), esc(a.text), esc(a.why))
  end
  local html = [[<html><head><meta charset="utf-8"><style>
    body{margin:0;background:transparent;font:17px -apple-system,sans-serif;color-scheme:light dark}
    .p{margin:8px;background:Canvas;color:CanvasText;border:2px solid #d07a12;border-radius:14px;padding:14px 16px;box-shadow:0 8px 30px rgba(0,0,0,.35)}
    .k{font:600 13px ui-monospace,monospace;letter-spacing:.08em;color:#d07a12;text-transform:uppercase;margin-bottom:6px}
    .a{padding:8px 0;border-top:1px solid color-mix(in srgb,CanvasText 15%,transparent);cursor:pointer}
    .a:first-of-type{border-top:0}.h{font-weight:600}.t{margin:3px 0}.w{opacity:.65;font-size:15px}
    .b{display:flex;gap:8px;margin-top:10px}button{font:600 15px -apple-system;padding:8px 18px;border-radius:7px;border:0;cursor:pointer}
    .o{background:#d07a12;color:#fff}.c{background:transparent;color:CanvasText;border:1px solid color-mix(in srgb,CanvasText 25%,transparent)}
    </style></head><body><div class="p"><div class="k">Mattermost · срочно</div>]] .. table.concat(items) ..
    [[<div class="b"><button class="o" onclick="send(']] .. esc(alerts[1].url) .. [[')">Открыть</button>
    <button class="c" onclick="send('')">Закрыть</button></div></div>
    <script>function send(u){window.webkit.messageHandlers.lookout.postMessage(u)}</script></body></html>]]
  local f = hs.screen.mainScreen():frame()
  local w, h = 620, 170 + 110 * #alerts
  panel = hs.webview.new({ x = f.x + (f.w - w) / 2, y = f.y + 24, w = w, h = h }, {}, uc)
    :windowStyle({ "borderless", "nonactivating" })
    :level(hs.drawing.windowLevels.modalPanel)
    :behavior(hs.drawing.windowBehaviors.canJoinAllSpaces)
    :transparent(true)
    :allowTextEntry(false)
    :html(html)
    :show()
  local s = hs.sound.getByName("Sosumi")
  if s then s:play() end
end

local function check()
  run({ "check" }, function(res)
    err = res.error ~= hs.json.null and res.error or nil
    if res.alerts and #res.alerts > 0 then showAlerts(res.alerts) end
    render()
  end)
end

local function stop()
  if tick then tick:stop() end
  if poll then poll:stop() end
  ending, tick, poll, err = nil, nil, nil, nil
  hs.settings.clear("lookout.ending")
  render()
end

local function finish()
  stop()
  local s = hs.sound.getByName("Glass")
  if s then s:play() end
  hs.alert.show("Блок закончен", 4)
end

local function arm()
  tick = hs.timer.doEvery(20, function() if os.time() >= ending then finish() else render() end end)
  poll = hs.timer.doEvery(CHECK_EVERY, check)
  render()
end

local function start(minutes)
  stop()
  ending = os.time() + minutes * 60
  hs.settings.set("lookout.ending", ending)
  run({ "start" })
  arm()
end

local chooser = hs.chooser.new(function(c)
  if not c then return end
  if c.stop then stop() else start(c.minutes) end
end)
chooser:placeholderText("Минут в блоке (Enter — 40)")

local function choices(q)
  local list = {}
  local n = tonumber(q or "")
  if n and n > 0 and n <= 240 then list[#list + 1] = { text = n .. " мин", minutes = n } end
  if ending then list[#list + 1] = { text = "Стоп", subText = "осталось " .. left() .. " мин", stop = true } end
  for _, m in ipairs({ 40, 20, 50, 15, 90 }) do
    if m ~= n then list[#list + 1] = { text = m .. " мин", minutes = m } end
  end
  return list
end
chooser:queryChangedCallback(function(q) chooser:choices(choices(q)) end)

local function open()
  chooser:query("")
  chooser:choices(choices(""))
  chooser:show()
end

bar:setMenu(function()
  local items = { { title = ending and ("Осталось " .. left() .. " мин") or "Начать блок…", fn = open } }
  if ending then items[#items + 1] = { title = "Стоп", fn = stop } end
  if err then items[#items + 1] = { title = "⚠ " .. err, disabled = true } end
  return items
end)

M.hotkey = hs.hotkey.bind({ "ctrl", "alt" }, "t", open)
-- For checks from a terminal: hs -c 'lookout.showAlerts({...})'
M.showAlerts, M.close, M.check, M.start, M.stop = showAlerts, closePanel, check, start, stop
M.state = function() return { title = bar:title(), error = err, panel = panel ~= nil } end
M.webview = function() return panel end

-- A config reload does not cut a running block.
local saved = hs.settings.get("lookout.ending")
if saved and saved > os.time() then ending = saved arm() else render() end

return M
