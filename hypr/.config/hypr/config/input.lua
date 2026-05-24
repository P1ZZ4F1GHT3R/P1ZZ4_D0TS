hl.config({
    input = {
        kb_layout = "us",
        kb_variant = "intl",
        kb_options = "", --"compose:ralt",
        kb_model = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,

        touchpad = {
            natural_scroll = true,
            scroll_factor = 0.69,-- he nice
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})