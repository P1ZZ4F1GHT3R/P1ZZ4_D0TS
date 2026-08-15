-- Global variables

-- Application variables
mainMod = "SUPER"
secondMod = "ALT"
terminal = "ghostty"
fileManager = "thunar"
browser = "zen-browser"
launcher = "vicinae"
volumeBrightness = os.getenv("HOME") .. "/.config/scripts/media/volume-brightness.sh"
 
-- Directory paths
configDir = os.getenv("HOME") .. "/.config/hypr"
scriptsDir = os.getenv("HOME") .. "/.config/scripts"
wallpaperDir = os.getenv("HOME") .. "/Pictures/wallpapers"
screenshotDir = os.getenv("HOME") .. "/Pictures/Screenshots"

-- Theme variables
cursorTheme = "Vimix"
cursorSize = "32"
fontFamily = "SF Pro"
fontMono = "Ligma SFMono Nerd Font" 

-- Layout Variables
gapsIn = 5
gapsOut = 10
borderSize = 2
rounding = 22
masterRatio = 0.6
scrollingRatio = 0.6

-- Animation timing
animSpeed = 3
animSpeedFast = 2
animSpeedSlow = 5

-- Opacity Values
opacityActive = 0.8
opacityInactive = 0.8
opacityFloat = 0.90
opacitySpecial = 0.6
opacityFull = 1

-- Timeout values in seconds
timeoutDim = 300000      -- 5 minutes
timeoutLock = 600000     -- 10 minutes
timeoutScreen = 900000   -- 15 minutes
timeoutSuspend = 1200000 -- 20 minutes

