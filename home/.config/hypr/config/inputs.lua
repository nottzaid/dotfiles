-- Input configuration

hl.config({
    input = {
        -- sensitivity = -0.25,
        accel_profile = "flat",
        -- Arabic support: US as the base layout with Arabic toggleable via
        -- Alt+Shift. The layout code is "ara" — XKB's canonical identifier
        -- for the standard Arabic layout ("ar" is not a valid layout name,
        -- which is what caused the "Invalid keyboard layout" error).
        -- Order matters: first entry is the default active layout.
        kb_layout = "us,ara",
        kb_variant = ",",
        kb_options = "grp:alt_shift_toggle",
    },
    -- Uncomment the section below to enable software cursors; this can help with cursor display or behavior issues
    -- cursor = {
    --     no_hardware_cursors = 1,
    -- },
})

-- Swipes step to the next workspace number (r+1), not the next workspace on
-- the screen (m+1), which could be a hidden scratchpad world one (scratch-world).
hl.config({ gestures = { workspace_swipe_use_r = true } })
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "down",       action = "close" })
hl.gesture({ fingers = 3, direction = "up",         action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "left",       action = "float" })
