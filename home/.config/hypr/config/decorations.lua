-- Look and feel: a romanticized i3. Square windows with
-- 2px borders, no gaps, i3's blue shading into the theme's lavender on the
-- focused window; no rounding, transparency, blur, or shadows. Tabbed groups
-- are drawn like i3's tabbed containers.

hl.config({
    general = {
        gaps_in = 0,
        gaps_out = 0,
        border_size = 2,
        extend_border_grab_area = 10,
        resize_on_border = true,
        col = {
            active_border = {
                colors = { I3_FOCUSED_BORDER, LAVENDER },
                angle = 45,
            },
            inactive_border = MUTED,
        },
    },
    group = {
        col = {
            border_active = { colors = { I3_FOCUSED_BORDER, LAVENDER }, angle = 45 },
            border_inactive = MUTED,
            border_locked_active = { colors = { I3_FOCUSED_BORDER, LAVENDER }, angle = 45 },
            border_locked_inactive = MUTED,
        },
        groupbar = {
            font_family = "FantasqueSansM Nerd Font",
            font_size = 12,
            height = 20,
            gradients = true,
            rounding = 0,
            gradient_rounding = 0,
            indicator_height = 0,
            gaps_in = 2,
            gaps_out = 0,
            keep_upper_gap = false,
            text_color = I3_TEXT,
            text_color_inactive = SUBTEXT,
            text_color_locked_active = I3_TEXT,
            text_color_locked_inactive = SUBTEXT,
            col = {
                active = I3_FOCUSED,
                inactive = MUTED,
                locked_active = I3_FOCUSED,
                locked_inactive = MUTED,
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
