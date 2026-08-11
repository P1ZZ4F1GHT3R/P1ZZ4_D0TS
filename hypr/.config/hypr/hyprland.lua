-- Main Hyprland config

-- Core config
require("config/variables")
require("config/environment")
require("config/border")
require("config/autostart")
require("config/appearance")
require("config/animations")
require("config/layouts")
require("config/input")
require("config/plugins")
require("hyprcolors")

-- Keybinds
require("keybinds/applications")
require("keybinds/windows")
require("keybinds/workspaces")
require("keybinds/media")

-- System config
require("monitors")
require("hyprrules")
