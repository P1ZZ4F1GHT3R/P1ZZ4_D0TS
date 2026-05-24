hl.config({
    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = false,
    },
})

hl.config({
    master = {
        new_status = "master",
        mfact = masterRatio,
    },
})

hl.config({
    scrolling = {
        follow_focus = true,
        column_width = scrollingRatio,
        direction = "left",
    },
})