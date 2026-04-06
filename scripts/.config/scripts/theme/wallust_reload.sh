#!/usr/bin/env bash
# wallust_reload.sh - called by WallpaperPicker after setting a wallpaper
# Usage: wallust_reload.sh <image_file>
#
# Runs wallust on the given image, then reloads all shell components
# the same way theme-sync.sh does, but without the swww query overhead.

IMAGE="$1"

if [ -z "$IMAGE" ] || [ ! -f "$IMAGE" ]; then
    # Fallback: query swww directly (same as theme-sync.sh does)
    IMAGE=$(swww query 2>/dev/null | grep -oP '(?<=image: ).*' | head -n1 | tr -d '\n\r')
fi

if [ -z "$IMAGE" ]; then
    echo "wallust_reload.sh: no image found, aborting" >&2
    exit 1
fi

# Generate colorscheme
wallust run "$IMAGE" --dynamic-threshold 2>/dev/null

# Reload hyprland (picks up new border.conf etc.)
hyprctl reload 2>/dev/null

# Reload swaync notification center
swaync-client -rs 2>/dev/null

# Restart hyprswitch with the updated CSS
CSS="$HOME/.config/hypr/config/hyprswitch.css"
if pgrep -x hyprswitch >/dev/null; then
    killall hyprswitch 2>/dev/null || true
    sleep 0.1
fi
hyprswitch init \
    --show-title \
    --size-factor 5 \
    --workspaces-per-row 4 \
    --custom-css "$CSS" \
    &>/dev/null &
