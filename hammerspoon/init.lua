-- Claude Code Desktop: Shift+Tab переключает plan <-> bypass permissions
-- (эмуляция Cmd+Shift+M -> цифра; нативного действия "поставить режим" у приложения нет).

local PLAN, BYPASS = "4", "5"

local nextMode = PLAN
local function toggleMode()
  hs.eventtap.keyStroke({"cmd","shift"}, "m", 0)
  local pick = nextMode
  nextMode = (pick == PLAN) and BYPASS or PLAN
  -- ponytail: без паузы; если цифра начнёт проскакивать в чат — вернуть hs.timer.doAfter(0.05, ...)
  hs.eventtap.keyStroke({}, pick, 0)
end

-- Биндинг живёт только пока Claude в фокусе.
local hotkey = hs.hotkey.new({"shift"}, "tab", toggleMode)

-- application.watcher вместо window.filter: у Electron AX-события окон флаки,
-- активация/деактивация приложения ловится надёжно.
watcher = hs.application.watcher.new(function(name, event)
  if name == "Claude" then
    if event == hs.application.watcher.activated then hotkey:enable()
    elseif event == hs.application.watcher.deactivated then hotkey:disable() end
  end
end)
watcher:start()

local front = hs.application.frontmostApplication()
if front and front:name() == "Claude" then hotkey:enable() end

require("hs.ipc")  -- для `hs -c` из терминала
