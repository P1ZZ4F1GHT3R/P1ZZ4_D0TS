require("hyprcolors")

if hl.plugin.dynamic_cursors then
    hl.config { plugin = { dynamic_cursors = {

        -- enables the plugin
        enabled = true,

        -- sets the cursor behaviour, supports these values:
        -- tilt    - tilt the cursor based on x-velocity
        -- rotate  - rotate the cursor based on movement direction
        -- stretch - stretch the cursor shape based on direction and velocity
        -- none    - do not change the cursor's behaviour
        mode = "stretch",

        -- minimum angle difference in degrees after which the shape is changed
        -- smaller values are smoother, but more expensive for hw cursors
        threshold = 2,

        -- for mode = "rotate"
        rotate = {

            -- length in px of the simulated stick used to rotate the cursor
            -- most realistic if this is your actual cursor size
            length = 20,

            -- clockwise offset applied to the angle in degrees
            -- this will apply to ALL shapes
            offset = 0.0,
        },

        -- for mode = "tilt"
        tilt = {

            -- controls how powerful the tilt is, the lower, the more power
            -- this value controls at which speed (px/s) the full tilt is reached
            limit = 5000,

            -- relationship between speed and tilt, supports these values:
            -- linear             - a linear function is used
            -- quadratic          - a quadratic function is used (most realistic to actual air drag)
            -- negative_quadratic - negative version of the quadratic one, feels more aggressive
            -- see `activation` in `src/mode/utils.cpp` for how exactly the calculation is done
            activation = "negative_quadratic",

            -- time window (ms) over which the speed is calculated
            -- higher values will make slow motions smoother but more delayed
            window = 100,

            -- full tilt for each side (°)
            full = 60,
        },

        -- for mode = "stretch"
        stretch = {

            -- controls how much the cursor is stretched
            -- this value controls at which speed (px/s) the full stretch is reached
            -- the full stretch being twice the original length
            limit = 3000,

            -- relationship between speed and stretch amount, supports these values:
            -- linear             - a linear function is used
            -- quadratic          - a quadratic function is used
            -- negative_quadratic - negative version of the quadratic one, feels more aggressive
            -- see `activation` in `src/mode/utils.cpp` for how exactly the calculation is done
            activation = "negative_quadratic",

            -- time window (ms) over which the speed is calculated
            -- higher values will make slow motions smoother but more delayed
            window = 200,
        },

        -- configure shake to find
        -- magnifies the cursor if its is being shaken
        shake = {

            -- enables shake to find
            enabled = true,

            -- controls how soon a shake is detected
            -- lower values mean sooner
            threshold = 3.5,

            -- magnification level immediately after shake start
            base = 2.0,
            -- magnification increase per second when continuing to shake
            speed = 1.0,
            -- how much the speed is influenced by the current shake intensity
            influence = 0.0,

            -- maximal magnification the cursor can reach
            -- values below 1 disable the limit (e.g. 0)
            limit = 8.0,

            -- time in milliseconds the cursor will stay magnified after a shake has ended
            timeout = 750,

            -- show cursor behaviour `tilt`, `rotate`, etc. while shaking
            effects = true,

            -- enable ipc events for shake
            -- see the `ipc` section below
            ipc = false,
        },

        -- use hyprcursor to get a higher resolution texture when the cursor is magnified
        -- see the `hyprcursor` section below
        hyprcursor = {

            -- use nearest-neighbour (pixelated) scaling when magnifying beyond texture size
            -- this will also have effect without hyprcursor support being enabled
            -- 0 - never use pixelated scaling
            -- 1 - use pixelated when no highres image
            -- 2 - always use pixelated scaling
            nearest = 1,

            -- enable dedicated hyprcursor support
            enabled = true,

            -- resolution in pixels to load the magnified shapes at
            -- be warned that loading a very high-resolution image will take a long time and might impact memory consumption
            -- -1 means we use [normal cursor size] * [shake:base option]
            resolution = -1,

            -- shape to use when clientside cursors are being magnified
            -- see the shape-name property of shape rules for possible names
            -- specifying clientside will use the actual shape, but will be pixelated
            fallback = "clientside",
        },
    }}}
end

if hl.plugin.scrolloverview then
    hl.exec_cmd("waybound --config ~/.config/waybound/waybound.toml")
    hl.config({
        plugin = {
            scrolloverview = {
                scale = 0.6, -- preferred overview scale
                workspace_gap = 50,
                layout = "vertical", -- vertical or horizontal
                wallpaper = 0, -- 0: global only, 1: per-workspace only, 2: both
                blur = false, -- blur only the main overview wallpaper
            },
        },
    })
end

if hl.plugin.hyprglass then
    local hg = hl.plugin.hyprglass

    hg.preset("clear", {
        glass_opacity = 0.8,
        blur_strength = 1.0,
        dark = { brightness = 0.82 },
        light = { brightness = 1.2 },
    })

    hg.preset("contrasted", {
        inherits = "high_contrast",
        contrast = 1.2,
        adaptive_dim = 1.9,
        dark = { tint_color = 0x82142aa9 },

    })

    local function tint(c, alpha)
    return tonumber(c:match ( "%x%x%x%x%x%x"), 16) * 256
        + math.floor(alpha * 255 + 0.5)
    end
        
    hg.preset("glass", {
        blur_strength = 2.0,
        blur_iterations = 3,
        chromatic_aberration = 0.8,
        fresnel_strength = 0.8,
        edge_thickness = 0.08,
        tint_color = tint(colors.background, 0.12),
        lens_distortion = 0.9,
        brightness = 1.0,
        contrast = 1.7,
        saturataon = 1,
        vibrancy = 0.8,
        vibrancy_darkness = 1,
        adaptive_boost = 0.5,
    })

    hg.preset("apple", {
        blur_strength = 2.2,
        blur_iterations = 3,
        refraction_strength = 0.55,
        chromatic_aberration = 0.3,
        fresnel_strength = 0.5,
        specular_strength = 0.75,
        edge_thickness = 0.05,
        lens_distortion = 0.3,
        dark = { brightness = 0.82, contrast = 0.90, saturation = 0.80, vibrancy = 0.15, adaptive_dim = 0.4 },
        light = { brightness = 1.12, contrast = 0.92, saturataon = 0.85, vibrancy = 0.12, adaptive_boost = 0.4 },
    })

    hg.config({
        enabled = true,
        default_theme = "dark",
        default_preset = "glass",
        layers = { enabled = false },
    })
end




