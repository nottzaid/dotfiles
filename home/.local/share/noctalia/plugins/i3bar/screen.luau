--!nonstrict
-- The TV's link, as an i3bar block: whether it mirrors the monitor, extends
-- it, or is disconnected (display-mode off: Hyprland drops it and frees what
-- it held for it), or has nothing attached. Click: disconnect it, or connect
-- it again. Right click: mirror or extend. Follows Hyprland's monitor events;
-- all the work is ~/.local/bin/display-mode's.

local MODE = noctalia.expandPath("~/.local/bin/display-mode")
-- Spans the full bar height; keep in sync with [bar.default] thickness.
local BAR_THICKNESS = 36

local LOOK = {
  mirror = { glyph = "\u{F037A}", text = "TV mirror", fg = "#94e2d5" },
  extended = { glyph = "\u{F0379}", text = "TV extended", fg = "#94e2d5" },
  off = { glyph = "\u{F0D90}", text = "TV off", fg = "#7f849c" },
  none = { glyph = "\u{F0D90}", text = "no TV", fg = "#6c7086" },
}

local state = nil
local busy = false

local render, refresh

local function run(action)
  if busy then return end
  busy = true
  render()
  noctalia.runAsync({ MODE, action }, function(_)
    busy = false
    refresh()
  end)
end

render = function()
  local look = LOOK[state or ""]
  if look == nil then
    barWidget.render(ui.row({ height = BAR_THICKNESS }, {}))
    return
  end
  local actionable = state ~= "none"
  barWidget.render(ui.row({
    key = "tv",
    height = BAR_THICKNESS,
    align = "center",
    justify = "center",
    gap = 6, -- (the built-in widgets' icon gap)
    onClick = actionable and function()
      run(state == "off" and "on" or "off")
    end or nil,
    onRightClick = actionable and function()
      run("toggle")
    end or nil,
  }, {
    ui.label({ text = look.glyph, color = look.fg, baseline = "inkCentered" }),
    ui.label({
      text = busy and "…" or look.text,
      color = look.fg,
      fontWeight = "medium",
      baseline = "inkCentered",
    }),
  }))
end

refresh = function()
  noctalia.runAsync({ MODE, "status" }, function(result)
    if result.exitCode == 0 then
      state = result.stdout:match("%a+")
    end
    render()
  end)
end

noctalia.runStream("python3 -u '" .. noctalia.pluginDir() .. "/hypr-events.py'", function(line)
  local event = line:match("^(%w+)>>")
  if event and (event:find("^monitor") or event == "configreloaded") then
    refresh()
  end
end)
refresh()

-- Resync occasionally in case an event was missed.
function update()
  noctalia.setUpdateInterval(30000)
  refresh()
end
