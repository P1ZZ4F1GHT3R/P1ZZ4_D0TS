#!/bin/bash

#===============================================================================
# Theme Synchronization Master Script
# ~/.config/scripts/theme/theme-sync.sh
# Description: Orchestrates system-wide theme updates based on current wallpaper
# Author: saatvik333 (Modified by P1ZZ4_F1GHT3R)
# Version: 3.1
# Dependencies: awww, wallust, hyprctl, imagemagick
#===============================================================================

set -euo pipefail

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/color-utils.sh"

# Keep the normal no-argument sync forgiving during startup, but do not add a
# needless delay when the picker explicitly passes a selected wallpaper.
if [[ $# -eq 0 ]]; then
    sleep 1
fi

# --- Configuration ---
readonly SCRIPT_NAME="${0##*/}"
readonly CONFIG_DIR="$HOME/.config"
readonly CACHE_DIR="$HOME/.cache"

# File paths
readonly HYPRLOCK_CONF="$CONFIG_DIR/hypr/hyprlock.conf"
readonly WALLPAPER_CACHE="$CONFIG_DIR/wallpaper/wallpaper.txt"
readonly GIF_FRAME="$CONFIG_DIR/wallpaper/gif-frame.jpg"
readonly LOG_FILE="$CACHE_DIR/${SCRIPT_NAME%.sh}.log"
readonly LOCK_FILE="/tmp/${SCRIPT_NAME%.sh}.lock"

# Script paths
readonly GTK_SCRIPT="$CONFIG_DIR/scripts/theme/gtk-colors.sh"
readonly GHOSTTY_SCRIPT="$CONFIG_DIR/scripts/theme/ghostty-colors.sh"

# --- Wallpaper Management Functions ---
get_current_wallpaper() {
    local requested_wallpaper="${1:-}"

    if [[ -n "$requested_wallpaper" ]]; then
        requested_wallpaper="${requested_wallpaper#file://}"
        if [[ ! -f "$requested_wallpaper" ]]; then
            die "Wallpaper file does not exist: $requested_wallpaper"
        fi

        echo "$requested_wallpaper"
        return
    fi

    log_debug "Retrieving current wallpaper from awww"
    
    local wallpaper
    wallpaper=$(awww query 2>/dev/null | grep -oP '(?<=image: ).*' | head -n1 | tr -d '\n\r')
    
    if [[ -z "$wallpaper" ]]; then
        die "No wallpaper detected from awww query"
    fi
    
    if [[ ! -f "$wallpaper" ]]; then
        die "Wallpaper file does not exist: $wallpaper"
    fi
    
    log_debug "Found wallpaper: $wallpaper"
    echo "$wallpaper"
}

set_wallpaper() {
    local -r wallpaper="$1"

    log_info "Setting wallpaper with awww: $wallpaper"
    if ! awww img -t fade --transition-duration 9 "$wallpaper" >/dev/null 2>&1; then
        die "Failed to set wallpaper with awww: $wallpaper"
    fi
}

cache_wallpaper_path() {
    local -r wallpaper="$1"
    
    ensure_directory "$(dirname "$WALLPAPER_CACHE")"
    
    echo "$wallpaper" >"$WALLPAPER_CACHE" || die "Failed to cache wallpaper path"
    
    log_debug "Cached wallpaper path: $wallpaper"
}

process_wallpaper() {
    local wallpaper
    wallpaper=$(get_current_wallpaper "${1:-}")
    
    # Cache the original wallpaper path
    cache_wallpaper_path "$wallpaper"
    
    # Handle GIF wallpapers
    if [[ "$wallpaper" =~ \.(gif|GIF)$ ]]; then
        log_info "Detected GIF wallpaper, extracting frame for color processing"
        wallpaper=$(extract_gif_frame "$wallpaper" "$GIF_FRAME")
    fi
    
    log_info "Using wallpaper for color processing: $wallpaper"
    echo "$wallpaper"
}

# --- Configuration Update Functions ---
update_hyprlock_config() {
    local -r wallpaper="$1"
    
    log_debug "Updating hyprlock configuration"
    
    validate_file "$HYPRLOCK_CONF" "Hyprlock config"
    
    # Create timestamped backup
    local -r backup="${HYPRLOCK_CONF}.backup.$(date +%s)"
    if ! cp "$HYPRLOCK_CONF" "$backup"; then
        die "Failed to create backup of hyprlock config"
    fi
    
    # Update wallpaper path using awk
    local -r temp_file="${HYPRLOCK_CONF}.tmp"
    
    if ! awk -v new_path="$wallpaper" '
        /^background {/ { in_bg = 1 }
        in_bg && /^[ \t]*path[ \t]*=/ {
            print "    path = " new_path
            next
        }
        /^}/ && in_bg { in_bg = 0 }
        { print }
    ' "$HYPRLOCK_CONF" >"$temp_file"; then
        log_error "Failed to process hyprlock config with awk"
        rm -f "$temp_file"
        mv "$backup" "$HYPRLOCK_CONF"
        die "Hyprlock config update failed"
    fi
    
    # Replace original with updated version
    if ! mv "$temp_file" "$HYPRLOCK_CONF"; then
        log_error "Failed to replace hyprlock config"
        rm -f "$temp_file"
        mv "$backup" "$HYPRLOCK_CONF"
        die "Hyprlock config replacement failed"
    fi
    
    # Clean up backup on success
    rm -f "$backup"
    log_success "Updated hyprlock background configuration"
}

# --- Theme Script Execution Functions ---

execute_gtk_theme_update() {
    validate_executable "$GTK_SCRIPT" "GTK theme script"
    
    log_debug "Executing GTK theme update"
    if ! "$GTK_SCRIPT"; then
        die "GTK theme script failed"
    fi
    
    log_success "GTK theme update completed"
}

execute_wallust_generation() {
    local -r wallpaper="$1"
    
    log_debug "Executing wallust theme generation"
    
    # Verify wallpaper accessibility
    if [[ ! -r "$wallpaper" ]]; then
        die "Wallpaper file not readable: $wallpaper"
    fi
    
    # Get absolute path for wallust
    local abs_wallpaper
    abs_wallpaper=$(realpath "$wallpaper" 2>/dev/null) || die "Failed to resolve absolute path for: $wallpaper"
    
    log_debug "Using absolute wallpaper path: $abs_wallpaper"
    
    # --- NEW: LUMINANCE DETECTION ---
    log_debug "Calculating image luminance..."
    
    # Uses ImageMagick to get the mean brightness of the image (0 to 100)
    local luminance
    luminance=$(magick "$abs_wallpaper" -colorspace gray -format "%[fx:mean*100]" info: | awk '{print int($1)}')
    
    # Set defaults
    local mode="dark"
    local palette="harddark"
    
    # If the image is mostly bright (adjust the 60 threshold to your liking), go light!
    if (( luminance > 60 )); then
        mode="light"
        palette="light"
    fi
    
    log_info "Wallpaper luminance is $luminance. Applying $mode theme."
    
    # Export the mode as an environment variable so your other scripts can read it
    export THEME_MODE="$mode"
    
    # Cache the mode so Quickshell can grab it via IPC or a file read if needed
    echo "$mode" > "$CACHE_DIR/theme-mode.txt"
    # --------------------------------
    
    # Run wallust, passing the dynamic palette flag
    if ! wallust run "$abs_wallpaper" --palette "$palette" --dynamic-threshold 2>/dev/null; then
        die "Wallust theme generation failed for: $abs_wallpaper"
    fi
    
    log_success "Wallust theme generation completed ($mode mode)"
}

execute_ghostty_update() {
    validate_executable "$GHOSTTY_SCRIPT" "Ghostty color script"

    log_debug "Executing Ghostty color update"
    if ! "$GHOSTTY_SCRIPT"; then
        die "Ghostty color script failed"
    fi

    log_success "Ghostty color update completed"
}

execute_theme_scripts() {
    local -r wallpaper="$1"
    
    log_info "Executing theme update scripts"
    
    # Execute scripts in order
    execute_wallust_generation "$wallpaper"
    execute_gtk_theme_update
    execute_ghostty_update
    
    log_success "All theme scripts executed successfully"
}

# --- System Component Reload Functions ---
reload_hyprland() {
    log_debug "Reloading Hyprland configuration"
    
    if ! hyprctl reload 2>/dev/null; then
        die "Failed to reload Hyprland configuration"
    fi
    
    log_success "Hyprland configuration reloaded"
}

reload_hyprland_plugins() {
    log_debug "Reloading Hyprland plugins"
    
    if hyprpm reload 2>/dev/null; then
        log_success "Hyprland plugins reloaded successfully"
    else
        die "Failed to reload Hyprland plugins"
    fi
}

reload_ghostty() {
    sleep 0.5
    pkill ghostty 2>/dev/null || true
    sleep 0.5
    hyprctl dispatch 'hl.dsp.focus({workspace = "6"})' 
    sleep 0.5
    hyprctl dispatch 'hl.dsp.exec_cmd("ghostty -e pipes-rs -f 45 -k heavy,light -r 0.6", {fullscreen = true})'
    sleep 0.5
    hyprctl dispatch 'hl.dsp.focus({workspace = "previous"})'
}

vicinae_update(){
        if command -v vicinae > /dev/null 2>&1; then
        vicinae theme set wallust || log_info "Failed to set vicinae theme"
        else
        log_info "vicinae not found, skipping vicinae theme update"
        fi
}

reload_quickshell() {
    log_debug "Pushing new colors to Quickshell via IPC"
    
    local json_file="$CONFIG_DIR/quickshell/colors.json"
    
    if [[ ! -f "$json_file" ]]; then
        log_error "JSON file not found: $json_file"
        return
    fi

    # Read the file contents into a variable
    local json_data
    json_data=$(<"$json_file")

    # Pass the raw JSON string as an argument to the update function
    if command -v qs > /dev/null 2>&1; then
        qs ipc call Colors update "$json_data" || log_error "Failed to send IPC command to Quickshell"
        log_success "Quickshell colors updated"
    elif command -v quickshell > /dev/null 2>&1; then
        quickshell ipc call Colors update "$json_data" || log_error "Failed to send IPC command to Quickshell"
        log_success "Quickshell colors updated"
    else
        log_info "Quickshell IPC tools not found, skipping Quickshell update"
    fi
}

reload_system_components() {
    log_info "Reloading system components"
    
    # Reload components in order
    reload_hyprland
    reload_hyprland_plugins
    #`reload_ghostty
    vicinae_update
    reload_quickshell
    
    log_success "All system components reloaded successfully"
}

# --- Main Function ---
main() {
    log_info "Starting theme synchronization"
    
    # Initialize script environment
    acquire_lock "$LOCK_FILE" "$SCRIPT_NAME"
    
    # Create necessary directories
    ensure_directory "$(dirname "$LOG_FILE")"
    ensure_directory "$(dirname "$WALLPAPER_CACHE")"
    
    # Validate system dependencies
    validate_dependencies "awww" "wallust" "hyprctl"

    if [[ $# -gt 1 ]]; then
        die "Usage: $SCRIPT_NAME [wallpaper-image]"
    fi

    local requested_wallpaper="${1:-}"
    if [[ -n "$requested_wallpaper" ]]; then
        requested_wallpaper="${requested_wallpaper#file://}"
        [[ -r "$requested_wallpaper" ]] || die "Wallpaper file not readable: $requested_wallpaper"
        set_wallpaper "$requested_wallpaper"
    fi
    
    # Process current wallpaper (handles GIF extraction)
    local wallpaper
    wallpaper=$(process_wallpaper "$requested_wallpaper")
    
    # Get original wallpaper path for hyprlock
    local original_wallpaper hyprlock_wallpaper
    original_wallpaper=$(cat "$WALLPAPER_CACHE" 2>/dev/null) || die "Failed to read cached wallpaper path"
    
    # Determine appropriate wallpaper for hyprlock
    if [[ "$original_wallpaper" =~ \.(gif|GIF)$ ]]; then
        hyprlock_wallpaper="$GIF_FRAME"
        log_debug "Using extracted GIF frame for hyprlock: $hyprlock_wallpaper"
    else
        hyprlock_wallpaper="$original_wallpaper"
        log_debug "Using original wallpaper for hyprlock: $hyprlock_wallpaper"
    fi
    
    # Execute theme update pipeline
    log_info "Executing theme update pipeline"
    update_hyprlock_config "$hyprlock_wallpaper"
    execute_theme_scripts "$wallpaper"
    reload_system_components
    
}

# --- Script Entry Point ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
