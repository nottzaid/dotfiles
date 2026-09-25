-- CachyOS Hyprland Configuration

require("config.animations")
require("config.autostart")
require("config.colors")
require("config.decorations")
require("config.variables")
require("config.inputs")
require("config.binds")
require("config.misc")
require("config.host") -- per machine: files/hosts/<host>/hypr/config/host.lua
require("config.windowrules")
require("config.workspaces")

-- yt-stream-workspace: declares the YT-STREAM virtual output (used by
-- workspace-stream) and SUPER+F11/F12 stream control handoff.
require("yt-stream-workspace")
