--!nonstrict
-- i3bar-style workspace buttons for Hyprland, romanticized: square boxes with
-- a 1px border, i3's blue for the focused workspace, soft Catppuccin tones for
-- the rest, one per workspace on this bar's monitor. Clicking or scrolling
-- goes through ~/.local/bin/scratch-world, like the keybinds. While this
-- monitor shows its scratchpad world (Super+S), the buttons are that world's
-- workspaces instead; a last button enters or leaves it.

local COLORS = {
  focused = { border = "#4c7899", bg = "#285577", hover = "#3e6685", fg = "#ffffff", weight = "bold" },
  active = { border = "#45475a", bg = "#313244", hover = "#414257", fg = "#cdd6f4" }, -- visible on an unfocused monitor
  occupied = { border = "#313244", bg = "#1e1e2e", hover = "#2c2c3d", fg = "#a6adc8" },
  empty = { border = "#1e1e2e", bg = "#181825", hover = "#20212f", fg = "#6c7086" },
  urgent = { border = "#f38ba8", bg = "#f38ba8", hover = "#f59cb5", fg = "#1e1e2e", weight = "bold" },
  scratchpad = { border = "#fab387", bg = "#fab387", hover = "#fbbb93", fg = "#1e1e2e", weight = "bold" }, -- world shown here
}
-- Workspaces above this id are scratchpad world ones, in blocks of a hundred
-- per monitor: 101-110 are one monitor's 1-10. scratch-world records which
-- block is whose; a block stays its monitor's even when Hyprland moves its
-- workspaces elsewhere (say, while that monitor is unplugged).
local HIDDEN, SIZE = 100, 10
local BASES = "~/.local/state/scratch-world/bases"
-- Buttons span the full bar height; keep in sync with [bar.default] thickness.
local BAR_THICKNESS = 36
local WORLD = noctalia.expandPath("~/.local/bin/scratch-world")

local workspaces, monitors, urgent, baseOf = {}, {}, {}, {}
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

local function barOutput()
  local configured = noctalia.getConfig("monitor")
  return barWidget.outputName() or (configured ~= "" and configured or nil)
end

-- Acts on this bar's monitor, whichever one has focus.
local function world(...)
  local output = barOutput()
  local args = output and { WORLD, "--monitor", output } or { WORLD }
  for _, arg in ipairs({ ... }) do
    table.insert(args, arg)
  end
  noctalia.runAsync(args)
end

local function switchTo(target)
  world("focus", target)
end

local function toggleWorld()
  world("toggle")
end

local function button(key, text, c, onClick)
  return ui.row({
    key = key,
    fill = hoveredWorkspace == key and c.hover or c.bg,
    border = c.border,
    borderWidth = 1,
    paddingH = 12,
    align = "center",
    justify = "center",
    onHover = "onWorkspaceHover",
    onClick = onClick,
  }, {
    ui.label({ text = text, color = c.fg, fontWeight = c.weight or "medium", baseline = "inkCentered" }),
  })
end

local function render()
  local output = barOutput()
  local focusedMonitor, visibleOn, activeHere = nil, {}, nil
  for _, m in ipairs(monitors) do
    visibleOn[m.activeWorkspace.id] = m.name
    if m.focused then
      focusedMonitor = m.name
    end
    if m.name == (output or focusedMonitor) then
      activeHere = m.activeWorkspace.id
    end
  end
  -- In its scratchpad world, a monitor's buttons are that world's workspaces.
  local here = activeHere ~= nil and activeHere > HIDDEN
  local base = baseOf[output or focusedMonitor] or (here and activeHere - activeHere % HIDDEN) or nil

  local shown, scratchWindows = {}, 0
  for _, ws in ipairs(workspaces) do
    local mine = base ~= nil and ws.id > base and ws.id <= base + SIZE
    if mine then
      scratchWindows = scratchWindows + ws.windows
    end
    -- Like i3: a workspace shows while it has windows or is on screen.
    local exists = ws.windows > 0 or visibleOn[ws.id] ~= nil
    local normal = ws.id > 0 and ws.id <= HIDDEN and (output == nil or ws.monitor == output)
    if exists and (if here then mine else normal) then
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
    -- A scratchpad world workspace is its number within the world.
    local id = tostring(if here then ws.id % HIDDEN else ws.id)
    table.insert(buttons, button(id, (here or ws.name == "") and id or ws.name, COLORS[state], function()
      switchTo(id)
    end))
  end

  -- The scratchpad world covers the normal workspaces: peach while it is shown
  -- here, dim with its window count while hidden. Clicking enters or leaves it.
  if here or scratchWindows > 0 then
    local text = here and "scratchpad" or ("scratchpad · " .. scratchWindows)
    table.insert(buttons, button("scratchpad", text, here and COLORS.scratchpad or COLORS.occupied, toggleWorld))
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
  noctalia.readFileAsync(BASES, function(data)
    baseOf = {}
    for name, base in string.gmatch(data or "", "(%S+)%s+(%d+)") do
      baseOf[name] = tonumber(base)
    end
    render()
  end)
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
