-- Display layout. Set MODE, then `hyprctl reload`.
--
--   "mirror"    the big HDMI-A-2 mirrors the small HDMI-A-1.
--   "extended"  two independent screens: the big one (4K, right of the small
--               one) gets exclusive workspaces 6-10, the small one keeps 1-5.
local MODE = "mirror"

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
    -- 4K native; raise `scale` to 1.5-2 if text looks too small.
    hl.monitor({
        output   = "HDMI-A-2",
        mode     = "3840x2160@30",
        position = "1920x0",
        scale    = 1.5,
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
