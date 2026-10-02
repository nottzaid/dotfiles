-- Desktop: two HDMI screens (a 24" monitor and a 4K TV).
--
-- Display layout. MODE is what every login starts in; Super+Shift+M switches
-- between the two until logout (display-mode). To change the default, set MODE
-- and run `hypr-display-reload` (a plain `hyprctl reload` leaves HDMI-A-2
-- without a Wayland output when switching from mirror to extended: no bar,
-- wallpaper, or launcher on it).
--
--   "mirror"    the big HDMI-A-2 mirrors the small HDMI-A-1.
--   "extended"  two independent screens: the big one (4K, right of the small
--               one) gets exclusive workspaces 6-10, the small one keeps 1-5.
local MODE = "extended"

-- display-mode records the mode it switched to in the runtime directory and
-- reloads; the reload reads it back here. No file means MODE above applies.
local function recorded_mode()
    local path = os.getenv("DISPLAY_MODE_FILE")
        or ((os.getenv("XDG_RUNTIME_DIR") or "") .. "/display-mode")
    local file = io.open(path)
    if not file then return nil end
    local mode = file:read("*l")
    file:close()
    if mode == "mirror" or mode == "extended" then return mode end
end
MODE = recorded_mode() or MODE

hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("~/.local/bin/display-mode toggle"))

hl.monitor({
    output   = "HDMI-A-1",
    mode     = "1920x1080@60",
    position = "0x0",
    scale    = 1,
})

if MODE == "mirror" then
    hl.monitor({
        output   = "HDMI-A-2",
        mode     = "1920x1080@60",
        position = "auto",
        scale    = 1,
        mirror   = "HDMI-A-1",
    })
elseif MODE == "extended" then
    -- 4K at scale 2: a 1920x1080 logical desktop, the same layout and text
    -- size as the small screen.
    hl.monitor({
        output   = "HDMI-A-2",
        mode     = "3840x2160@30",
        position = "1920x0",
        scale    = 2,
    })
    for ws = 1, 10 do
        hl.workspace_rule({
            workspace  = tostring(ws),
            monitor    = ws <= 5 and "HDMI-A-1" or "HDMI-A-2",
            default    = ws == 1 or ws == 6,
            persistent = true,
        })
    end
else
    error("monitors.lua: unknown MODE " .. tostring(MODE))
end
