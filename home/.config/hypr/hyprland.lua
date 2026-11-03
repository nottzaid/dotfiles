-- CachyOS Hyprland Configuration

require("config.animations")
require("config.autostart")
require("config.colors")
require("config.decorations")
require("config.variables")
require("config.inputs")
require("config.binds")
require("config.misc")
-- Per machine: hosts/<host>/.config/hypr/host.lua, linked beside this file.
-- Loaded by its path, since require() looks next to this file's real location
-- in the repository, where no host file is.
dofile(os.getenv("HOME") .. "/.config/hypr/host.lua")
require("config.windowrules")
require("config.workspaces")
