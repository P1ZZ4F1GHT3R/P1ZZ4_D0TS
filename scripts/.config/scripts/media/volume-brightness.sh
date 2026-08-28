#!/bin/bash

#===============================================================================
# Volume, Brightness & Media Control
# Description: Controls system volume, brightness, and media playback
# Dependencies: pactl, brightnessctl, playerctl
#===============================================================================

set -euo pipefail

# Source common utilities (keep this if you still have the lib file)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# --- Configuration ---
readonly VOLUME_STEP=5
readonly BRIGHTNESS_STEP=5
readonly MAX_VOLUME=100

# --- Volume Functions ---
get_volume() {
    pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '[0-9]{1,3}(?=%)' | head -1
}

# --- Control Functions ---
volume_up() {
    pactl set-sink-mute @DEFAULT_SINK@ 0
    local current_volume
    current_volume=$(get_volume)
    
    if (( current_volume + VOLUME_STEP > MAX_VOLUME )); then
        pactl set-sink-volume @DEFAULT_SINK@ "${MAX_VOLUME}%"
    else
        pactl set-sink-volume @DEFAULT_SINK@ "+${VOLUME_STEP}%"
    fi
}

volume_down() {
    pactl set-sink-volume @DEFAULT_SINK@ "-${VOLUME_STEP}%"
}

volume_mute() {
    pactl set-sink-mute @DEFAULT_SINK@ toggle
}

mic_mute() {
    pactl set-source-mute @DEFAULT_SOURCE@ toggle
}

brightness_up() {
    brightnessctl set "${BRIGHTNESS_STEP}%+"
}

brightness_down() {
    brightnessctl set "${BRIGHTNESS_STEP}%-"
}

next_track() {
    playerctl --player=spotify,%any next
}

prev_track() {
    playerctl --player=spotify,%any previous
}

play_pause() {
    playerctl --player=spotify,%any play-pause
}

main() {
    local -r action="${1:-}"
    
    case "$action" in
        volume_up) volume_up ;;
        volume_down) volume_down ;;
        volume_mute) volume_mute ;;
        mic_mute) mic_mute ;;
        brightness_up) brightness_up ;;
        brightness_down) brightness_down ;;
        next_track) next_track ;;
        prev_track) prev_track ;;
        play_pause) play_pause ;;
        *)
            echo "Usage: $0 {volume_up|volume_down|volume_mute|mic_mute|brightness_up|brightness_down|next_track|prev_track|play_pause}"
            exit 1
            ;;
    esac
}

# --- Script Entry Point ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi