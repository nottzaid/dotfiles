-- Laptop (Dell Inspiron 5583): the built-in panel and its touchpad.

hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "0x0",
    scale    = 1.5,
})
-- Screens plugged in later get their preferred mode, placed automatically.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

hl.config({
    input = {
        -- Inverted mouse-wheel scrolling.
        natural_scroll = true,
        -- Touchpads ignore the global key and need their own.
        touchpad = {
            natural_scroll = true,
        },
    },
})
