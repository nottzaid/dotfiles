-- Look and feel: i3's defaults (2px borders in i3's colors; no gaps,
-- rounding, transparency, blur, or shadows). Tabbed groups are drawn like
-- i3's tabbed containers.

hl.config({
    general = {
        gaps_in = 0,
        gaps_out = 0,
        border_size = 2,
        extend_border_grab_area = 10,
        resize_on_border = true,
        col = {
            active_border = I3_FOCUSED,
            inactive_border = I3_UNFOCUSED,
        },
    },
    group = {
        col = {
            border_active = I3_FOCUSED,
            border_inactive = I3_UNFOCUSED,
            border_locked_active = I3_FOCUSED,
            border_locked_inactive = I3_UNFOCUSED,
        },
        groupbar = {
            font_family = "monospace",
            font_size = 11,
            height = 18,
            gradients = true,
            rounding = 0,
            gradient_rounding = 0,
            indicator_height = 0,
            gaps_in = 0,
            gaps_out = 0,
            keep_upper_gap = false,
            text_color = I3_TEXT,
            text_color_inactive = I3_TEXT_UNFOCUSED,
            text_color_locked_active = I3_TEXT,
            text_color_locked_inactive = I3_TEXT_UNFOCUSED,
            col = {
                active = I3_FOCUSED,
                inactive = I3_UNFOCUSED,
                locked_active = I3_FOCUSED,
                locked_inactive = I3_UNFOCUSED,
            },
        },
    },
    decoration = {
        rounding = 0,
        active_opacity = 1,
        inactive_opacity = 1,
        fullscreen_opacity = 1,
        dim_special = 0,
        blur = {
            enabled = false,
        },
        shadow = {
            enabled = false,
        },
    },
})
