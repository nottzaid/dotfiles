--!nonstrict
-- i3bar-style workspace buttons for Hyprland, romanticized: square boxes with
-- a 1px border, i3's blue for the focused workspace, soft Catppuccin tones for
-- the rest, one per workspace on this bar's monitor. Clicking or scrolling
-- goes through ~/.local/bin/workspace-stream, like the keybinds.

local COLORS = {
  focused = { border = "#4c7899", bg = "#285577", hover = "#3e6685", fg = "#ffffff", weight = "bold" },
  active = { border = "#45475a", bg = "#313244", hover = "#414257", fg = "#cdd6f4" }, -- visible on an unfocused monitor
  occupied = { border = "#313244", bg = "#1e1e2e", hover = "#2c2c3d", fg = "#a6adc8" },
  empty = { border = "#1e1e2e", bg = "#181825", hover = "#20212f", fg = "#6c7086" },
  urgent = { border = "#f38ba8", bg = "#f38ba8", hover = "#f59cb5", fg = "#1e1e2e", weight = "bold" },
}
-- Buttons span the full bar height; keep in sync with [bar.default] thickness.
local BAR_THICKNESS = 36
local SWITCH = noctalia.expandPath("~/.local/bin/workspace-stream")

local workspaces, monitors, urgent = {}, {}, {}
local hoveredWorkspace = nil

local function hyprctlJson(what, onValue)
  noctalia.runAsync({ "hyprctl", "-j", what }, function(result)
    if result.exitCode == 0 then
      local value = noctalia.json.decode(result.stdout)
      if value then
        onValue(value)
      end
    end
  end)
end

local function switchTo(target)
  noctalia.runAsync({ SWITCH, "workspace", target })
end

local function render()
  local output = barWidget.outputName()
  local focusedMonitor, visibleOn = nil, {}
  for _, m in ipairs(monitors) do
    visibleOn[m.activeWorkspace.id] = m.name
    if m.focused then
      focusedMonitor = m.name
    end
  end

  local shown = {}
  for _, ws in ipairs(workspaces) do
    if ws.id > 0 and (output == nil or ws.monitor == output) then
      table.insert(shown, ws)
    end
  end
  table.sort(shown, function(a, b)
    return a.id < b.id
  end)

  local buttons = {}
  for _, ws in ipairs(shown) do
    local state = ws.windows > 0 and "occupied" or "empty"
    if urgent[ws.id] then
      state = "urgent"
    elseif visibleOn[ws.id] then
      state = visibleOn[ws.id] == focusedMonitor and "focused" or "active"
    end
    local c = COLORS[state]
    local id = tostring(ws.id)
    table.insert(buttons, ui.row({
      key = id,
      fill = hoveredWorkspace == id and c.hover or c.bg,
      border = c.border,
      borderWidth = 1,
      paddingH = 12,
      align = "center",
      justify = "center",
      onHover = "onWorkspaceHover",
      onClick = function()
        switchTo(id)
      end,
    }, {
      ui.label({ text = ws.name ~= "" and ws.name or id, color = c.fg, fontWeight = c.weight or "medium", baseline = "inkCentered" }),
    }))
  end
  barWidget.render(ui.row({ gap = 2, height = BAR_THICKNESS }, buttons))
end

-- A named, keyed handler also receives leave events when a workspace disappears.
function onWorkspaceHover(state, id)
  if state == "true" then
    if hoveredWorkspace == id then return end
    hoveredWorkspace = id
  elseif hoveredWorkspace == id then
    hoveredWorkspace = nil
  else
    return
  end
  render()
end

local function refresh()
  hyprctlJson("workspaces", function(value)
    workspaces = value
    render()
  end)
  hyprctlJson("monitors", function(value)
    monitors = value
    for _, m in ipairs(value) do
      urgent[m.activeWorkspace.id] = nil -- a workspace stops being urgent once shown
    end
    render()
  end)
end

local function onEvent(line)
  local event, data = line:match("^(%w+)>>(.*)$")
  if event == "urgent" then
    hyprctlJson("clients", function(clients)
      for _, c in ipairs(clients) do
        if c.address == "0x" .. data then
          urgent[c.workspace.id] = true
        end
      end
      refresh()
    end)
  elseif event and (event:find("workspace") or event:find("mon") or event:find("window")) then
    refresh()
  end
end

-- Scrolling over the buttons walks the monitor's workspaces, like i3bar:
-- one move per gesture, down for next, up for previous.
function onScroll(axis, steps, startsGesture)
  if axis == "vertical" and startsGesture and steps ~= 0 then
    switchTo(steps > 0 and "m+1" or "m-1")
  end
end

noctalia.runStream("python3 -u '" .. noctalia.pluginDir() .. "/hypr-events.py'", onEvent)
refresh()

-- Resync occasionally in case an event was missed.
function update()
  noctalia.setUpdateInterval(10000)
  refresh()
end
