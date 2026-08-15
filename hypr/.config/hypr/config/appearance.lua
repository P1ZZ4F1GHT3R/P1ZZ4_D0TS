hl.config({
    general = {
        border_size = borderSize,
        gaps_in = gapsIn,
        gaps_out = gapsOut,
        resize_on_border = true,
        no_focus_fallback = true,
        allow_tearing = true,
        layout = "scrolling",

        snap = {
            enabled = true,
        },
    },

    cursor = {
        hide_on_key_press = true,
        inactive_timeout = 4,
        warp_on_toggle_special = 1,
        default_monitor = "DP-1",
        no_hardware_cursors = 0,
    },

    decoration = {
        rounding = rounding,
        active_opacity = opacityActive,
        inactive_opacity = opacityInactive,
        fullscreen_opacity = opacityFull,
        dim_special = opacitySpecial,

        shadow = {
            enabled = false,
            range = 0,
            render_power = 3,
            color = 0xee1a1a1a,
        },

        blur = {
            enabled = true,
            size = 1,
            noise = 0.03,
            passes = 2,
            vibrancy = 0,
            xray = false,
            special = true,
            popups = true,
            input_methods = true,
            input_methods_ignorealpha = 0.8,
        },
    },

    misc = {
        force_default_wallpaper = 0,
        font_family = fontFamily,
        vrr = 2,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        animate_manual_resizes = true,
        animate_mouse_windowdragging = true,
        on_focus_under_fullscreen = 2,
        allow_session_lock_restore = true,
        initial_workspace_tracking = false,
        focus_on_activate = true,
    }
})