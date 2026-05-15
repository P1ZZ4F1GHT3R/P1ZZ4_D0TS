#!/bin/bash

# 1. Get the full JSON output of the currently focused window
window_data=$(hyprctl activewindow -j)

# 2. If no window is active (e.g., focused on the empty desktop), exit safely
if [ -z "$window_data" ] || [ "$window_data" == "{}" ]; then
    exit 0
fi

# 3. Extract the title, initial title, and class 
title=$(echo "$window_data" | jq -r '.title // "none"')
initial_title=$(echo "$window_data" | jq -r '.initialTitle // "none"')
class=$(echo "$window_data" | jq -r '.class // "none"')

# 4. If ANY of these match your Quickshell widget, spare it and exit
if [ "$title" = "qs-master" ] || [ "$initial_title" = "qs-master" ] || [ "$class" = "quickshell" ]; then
    ~/.config/scripts/quickshell/qs_manager.sh close
else
    # 5. Otherwise, kill the active window
    hyprctl dispatch killactive
fi