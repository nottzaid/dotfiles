local mainMod = "SUPER"
local noctCall = "noctalia msg "
local launchPrefix = "uwsm app -- " -- if you are not using UWSM, make this empty (e.g. "")
-- Workspace keys go through scratch-world, so they act on whichever world is
-- shown: the normal workspaces, or the scratchpad world over them (Super+S).
local worldCall = "~/.local/bin/scratch-world "

-- Bind number-row shortcuts by physical keycode so they work across keyboard layouts.
local function digitCode(d)
    return "code:" .. (d == 0 and 19 or (9 + d))
end

-- Vim-style navigation and the deliberate local shortcuts are retained while
-- Noctalia provides the launcher, clipboard, screenshots, media, and session UI.

---------------------------
---- WINDOW MANAGEMENT ----
---------------------------

-- Window manipulation
hl.bind(mainMod .. " + Escape",      hl.dsp.exec_cmd("hyprctl kill"))
hl.bind(mainMod .. " + Q",           hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Space", hl.dsp.window.float({ action = "toggle" })) -- (repo) float toggle
hl.bind(mainMod .. " + ALT + Space",   hl.dsp.window.float({ action = "toggle" }))   -- kept from default too
hl.bind(mainMod .. " + F",             hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })) -- (repo) maximized, panels stay visible
hl.bind(mainMod .. " + SHIFT + F",     hl.dsp.window.fullscreen())                   -- (repo) bar-covering fullscreen

-- Focus Vim-style HJKL (repo): replaces the default arrow-key binds
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Window cycling (repo)
hl.bind(mainMod .. " + Tab",         hl.dsp.window.cycle_next())
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))

-- Move active window around workspaces & monitors
-- Move: Vim-style HJKL (repo), replaces the default SHIFT+arrow-key binds
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
-- Monitor moves by number are superseded by the repo-style workspace loop
-- below: mainMod + SHIFT + [0-9] moves the active window to workspace [1-10].
hl.bind(mainMod .. " + CONTROL + SHIFT + Right",      hl.dsp.exec_cmd(worldCall .. "move m+1"))
hl.bind(mainMod .. " + CONTROL + SHIFT + Left",       hl.dsp.exec_cmd(worldCall .. "move m-1"))
for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(mainMod .. " + SHIFT + CONTROL + " .. digitCode(key), hl.dsp.exec_cmd(worldCall .. "move m~" .. i))
end

-- Move & Resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

-- Zoom
local function zoomfunction(value)
    local zoomvalue = hl.get_config("cursor:zoom_factor")
    if (zoomvalue + value) > 3.0 then
        hl.config({ cursor = { zoom_factor = 3.0 } })
    elseif (zoomvalue + value) < 1.0 then
        hl.config({ cursor = { zoom_factor = 1.0 } })
    else
        hl.config({ cursor = { zoom_factor = zoomvalue + value } })
    end
end
hl.bind(mainMod .. " + Minus", function() zoomfunction(-0.3) end, { repeating = true})
hl.bind(mainMod .. " + Plus", function() zoomfunction(0.3) end, { repeating = true })

--# Zoom with keypad
hl.bind(mainMod .. " + code:82", function() zoomfunction(-0.3) end, { repeating = true })
hl.bind(mainMod .. " + code:86", function() zoomfunction(0.3) end, { repeating = true })


------------------
---- LAUNCHER ----
------------------

hl.bind(mainMod .. " + Return",     hl.dsp.exec_cmd(launchPrefix .. TERMINAL))
-- Launch the Noctalia application picker.
hl.bind(mainMod .. " + D",          hl.dsp.exec_cmd(noctCall .. "panel-toggle launcher"))
hl.bind(mainMod .. " + E",          hl.dsp.exec_cmd(launchPrefix .. "emacsclient -c -a emacs"))
hl.bind(mainMod .. " + T",          hl.dsp.exec_cmd(launchPrefix .. EDITOR))
hl.bind(mainMod .. " + C",          hl.dsp.exec_cmd(launchPrefix .. CALCULATOR))
hl.bind("XF86Calculator",           hl.dsp.exec_cmd(launchPrefix .. CALCULATOR))
hl.bind(mainMod .. " + W",          hl.dsp.exec_cmd(launchPrefix .. BROWSER))
hl.bind("CONTROL + SHIFT + Escape", hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e btop"))
hl.bind(mainMod .. " + Z",          hl.dsp.exec_cmd(noctCall .. "settings-toggle"))
hl.bind(mainMod .. " + X",          hl.dsp.exec_cmd(noctCall .. "panel-toggle control-center"))
hl.bind(mainMod .. " + Space",      hl.dsp.exec_cmd(noctCall .. "panel-toggle launcher"))
hl.bind(mainMod .. " + period",     hl.dsp.exec_cmd(noctCall .. "panel-toggle launcher /emo"))
hl.bind(mainMod .. " + ALT + C",    hl.dsp.exec_cmd(noctCall .. "panel-toggle session"))

---------------------------
---- HARDWARE CONTROLS ----
---------------------------

-- Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(noctCall .. "volume-up"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(noctCall .. "volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd(noctCall .. "volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd(noctCall .. "mic-mute"),    { locked = true })

-- Media
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd(noctCall .. "media toggle"),   { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(noctCall .. "media toggle"),   { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd(noctCall .. "media next"),     { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd(noctCall .. "media previous"), { locked = true })

-- Brightness
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(noctCall .. "brightness-up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(noctCall .. "brightness-down"), { locked = true, repeating = true })

-------------------
---- UTILITIES ----
-------------------

-- Screen Capture
hl.bind(mainMod .. " + P",     hl.dsp.exec_cmd("hyprpicker -a -n"))
hl.bind("Print",               hl.dsp.exec_cmd(noctCall .. "screenshot-region"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(noctCall .. "screenshot-fullscreen"))

-- Theming and Wallpaper
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(noctCall .. "panel-toggle wallpaper"))

-- Clipboard
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(noctCall .. "panel-toggle clipboard"))

-- Notifications
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(noctCall .. "panel-toggle control-center notifications"))

-------------------------------
---- WORKSPACES & MONITORS ----
-------------------------------

-- (repo) Switch workspaces / move the active window, same scheme as
-- muradkant/dotfiles: mainMod + [0-9] focuses workspace [1-10] (10 maps to 0),
-- mainMod + SHIFT + [0-9] moves the window there. Focus routes through the
-- workspace-stream wrapper (via scratch-world) so the stream workspace stays
-- pinned to the YT-STREAM output during normal navigation (the repo's exact wiring).
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. digitCode(key),         hl.dsp.exec_cmd(worldCall .. "focus " .. i))
    hl.bind(mainMod .. " + SHIFT + " .. digitCode(key), hl.dsp.exec_cmd(worldCall .. "move " .. i .. " --silent"))
end

-- Move to adjacent workspaces and next empty on a given monitor
hl.bind(mainMod .. " + CONTROL + Right",       hl.dsp.exec_cmd(worldCall .. "focus m+1"))
hl.bind(mainMod .. " + CONTROL + Left",        hl.dsp.exec_cmd(worldCall .. "focus m-1"))
hl.bind(mainMod .. " + CONTROL + Down",        hl.dsp.exec_cmd(worldCall .. "focus emptym"))

-- Scroll through existing workspaces & monitors
-- (repo) Scroll through workspaces via the wrapper (mouse wheel down = next,
-- up = previous), keeping the stream workspace pinned like the dotfiles config.
hl.bind(mainMod .. " + mouse_down", hl.dsp.exec_cmd(worldCall .. "focus m+1"))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.exec_cmd(worldCall .. "focus m-1"))
hl.bind(mainMod .. " + CONTROL + mouse_up",   hl.dsp.exec_cmd(worldCall .. "focus m-1"))
hl.bind(mainMod .. " + CONTROL + mouse_down", hl.dsp.exec_cmd(worldCall .. "focus m+1"))

-- Scratchpad world: Super+S enters it at the last workspace used there, or
-- leaves it; Super+Shift+S sends the window to the other world.
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(worldCall .. "send"))
hl.bind(mainMod .. " + S",         hl.dsp.exec_cmd(worldCall .. "toggle"))

-- Gaming workspace: the named one the game window rules fill. It has no
-- number, so the workspace keys and the bar never reach it. Super+G goes there
-- and, pressed again, back to the workspace it left (Hyprland's previous one
-- when you arrived another way, such as a game opening); Super+Shift+G sends
-- the focused window there, or back, without following it.
local gamingWorkspace = "name:gaming"
local gamingHome = nil -- selector of the workspace Super+G left

-- The workspace the focused screen shows.
local function shownWorkspace()
    local monitor = hl.get_active_monitor()
    return monitor and monitor.active_workspace
end

-- Numbered workspaces by id; named ones have negative ids, so by name.
local function selectorOf(ws)
    return ws.id > 0 and tostring(ws.id) or ("name:" .. ws.name)
end

-- Focus goes through the stream module when it is loaded, like the workspace keys.
local function focusWorkspace(selector)
    if YTWS then
        YTWS.workspace(selector)
    else
        hl.dispatch(hl.dsp.focus({ workspace = selector }))
    end
end

hl.bind(mainMod .. " + G", function()
    local shown = shownWorkspace()
    if shown and shown.name == "gaming" then
        focusWorkspace(gamingHome or "previous")
    else
        gamingHome = shown and selectorOf(shown) or nil
        focusWorkspace(gamingWorkspace)
    end
end)

hl.bind(mainMod .. " + SHIFT + G", function()
    local shown = shownWorkspace()
    local target = gamingWorkspace
    if shown and shown.name == "gaming" then
        target = gamingHome or "previous"
    end
    hl.dispatch(hl.dsp.window.move({ workspace = target, follow = false }))
end)
