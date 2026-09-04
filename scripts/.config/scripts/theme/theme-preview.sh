#!/bin/bash
# ~/.config/scripts/theme/theme-preview.sh

set -euo pipefail

# The image path passed from Quickshell
IMAGE="${1:-}"
COLORS_FILE="$HOME/.config/quickshell/colors.json"

if [[ -z "$IMAGE" || ! -r "$IMAGE" ]]; then
    echo "theme-preview.sh: readable image path required" >&2
    exit 1
fi

# Calculate image luminance to determine light/dark mode
LUMINANCE=$(magick "$IMAGE" -colorspace gray -format "%[fx:mean*100]" info: | awk '{print int($1)}')

# Default to dark mode
PALETTE="harddark"

# If the image is bright use light mode
if (( LUMINANCE > 55 )); then
    PALETTE="light"
fi

# Run Wallust silently (skipping sequences and hooks) with the correct palette
wallust run -s "$IMAGE" --palette "$PALETTE" --dynamic-threshold 2>/dev/null

# Read the generated JSON and push it to Quickshell instantly.
if [[ ! -r "$COLORS_FILE" ]]; then
    echo "theme-preview.sh: Wallust did not write $COLORS_FILE" >&2
    exit 1
fi

JSON_DATA=$(<"$COLORS_FILE")

if command -v qs > /dev/null 2>&1; then
    qs ipc call Colors update "$JSON_DATA"
elif command -v quickshell > /dev/null 2>&1; then
    quickshell ipc call Colors update "$JSON_DATA"
fi