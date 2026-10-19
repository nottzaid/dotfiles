-- Gaming mode (files/bin/gaming-mode): on while the gaming workspace is on
-- screen with a window on it, however it got there (Super+G, or a game
-- opening there), and still on once the game closes, until the workspace
-- leaves the screen; shown empty before that, it is the lobby (the backdrop,
-- the desktop awake). The script works out the wanted state itself under a
-- lock (`sync`), so events may reach it in any order; this only saves it the
-- calls where nothing it cares about changed: whether the workspace is
-- shown, empty or not, and which windows are on it. A config reload (a
-- layout switch reloads) syncs once: what gaming mode set at runtime is
-- undone by it and has to be set again. Its backdrop shows on the gaming workspace's screen
-- while nothing covers that screen (a fullscreen window, or one over 85% of
-- it): a change to only that runs the lighter `backdrop` (a game going
-- fullscreen must not cost a whole sync). A game may grow to cover the
-- screen without going fullscreen, so focus changes, which come with that,
-- are looked at too. The sync comes first: nothing about the backdrop may
-- keep it from being sent.

local lastSeen = nil
local lastBackdrop = nil

-- Whether what a screen shows covers it (files/bin/gaming-mode, backdrop_place).
local function covered(monitor)
    local shown = monitor.active_workspace
    if shown == nil then return false end
    if shown.has_fullscreen then return true end
    local area = (monitor.width / monitor.scale) * (monitor.height / monitor.scale)
    for _, w in ipairs(shown:get_windows()) do
        if not w.hidden and w.size.x * w.size.y >= 0.85 * area then return true end
    end
    return false
end

local function syncGamingMode()
    local ws = hl.get_workspace("name:gaming")
    local seen = "off"
    local backdrop = "none"
    if ws ~= nil and ws.visible and ws.windows == 0 then
        seen = "empty"
    elseif ws ~= nil and ws.visible then
        local addresses = {}
        for _, w in ipairs(hl.get_workspace_windows("name:gaming")) do
            addresses[#addresses + 1] = w.address
        end
        table.sort(addresses)
        seen = "on " .. table.concat(addresses, " ")
    end
    if seen ~= lastSeen then
        lastSeen = seen
        lastBackdrop = nil -- (sync follows the backdrop too)
        hl.exec_cmd("~/.local/bin/gaming-mode sync")
    end
    if ws ~= nil and ws.monitor ~= nil then
        local ok, isCovered = pcall(covered, ws.monitor)
        backdrop = ws.monitor.name .. " " .. (ok and tostring(isCovered) or "unknown")
    end
    if lastBackdrop == nil then
        lastBackdrop = backdrop
    elseif backdrop ~= lastBackdrop then
        lastBackdrop = backdrop
        hl.exec_cmd("~/.local/bin/gaming-mode backdrop")
    end
end

for _, event in ipairs({
    "workspace.active", "workspace.removed", "workspace.move_to_monitor",
    "window.open", "window.close", "window.destroy", "window.move_to_workspace",
    "monitor.added", "monitor.removed", "window.fullscreen", "window.active",
}) do
    hl.on(event, syncGamingMode)
end

syncGamingMode()
