-- Gaming mode (files/bin/gaming-mode): on while the gaming workspace is on
-- screen with a window on it, however it got there (Super+G, or a game
-- opening there); off when it leaves the screen or its last window closes.
-- The script works out the wanted state itself under a lock (`sync`), so
-- events may reach it in any order; this only saves it the calls where
-- nothing it cares about changed: whether the workspace is shown, and which
-- windows are on it.

local lastSeen = nil

local function syncGamingMode()
    local ws = hl.get_workspace("name:gaming")
    local seen = "off"
    if ws ~= nil and ws.visible and ws.windows > 0 then
        local addresses = {}
        for _, w in ipairs(hl.get_workspace_windows("name:gaming")) do
            addresses[#addresses + 1] = w.address
        end
        table.sort(addresses)
        seen = "on " .. table.concat(addresses, " ")
    end
    if seen ~= lastSeen then
        lastSeen = seen
        hl.exec_cmd("~/.local/bin/gaming-mode sync")
    end
end

for _, event in ipairs({
    "workspace.active", "workspace.removed", "workspace.move_to_monitor",
    "window.open", "window.close", "window.destroy", "window.move_to_workspace",
    "monitor.added", "monitor.removed",
}) do
    hl.on(event, syncGamingMode)
end
