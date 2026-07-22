#!/bin/bash

#===============================================================================
# GTK Theme Update
# ~/.config/scripts/theme/gtk-colors.sh
# Description: Updates GTK themes based on current wallpaper folder structure
# Author: saatvik333
# Version: 2.0
# Dependencies: gsettings, sed
#===============================================================================

set -euo pipefail

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# --- Configuration ---
readonly CONFIG_DIR="$HOME/.config"
readonly WALLPAPER_FILE="$CONFIG_DIR/waytrogen/wallpaper.txt"
readonly DEFAULT_THEME="Colloid-Dark"
readonly COLOR_SCHEME="prefer-dark"
readonly GTK_VERSIONS=("3.0" "4.0")

declare -rA THEME_MAP=(
    ["Catppuccin"]="Colloid-Dark-Catppuccin"
    ["Everforest"]="Colloid-Dark-Everforest"
    ["Gruvbox"]="Colloid-Dark-Gruvbox"
    ["Nord"]="Colloid-Dark-Nord"
    ["Onedark"]="Colloid-Dark-Dracula"
    ["Black"]="Colloid-Dark"
    ["Animated"]="Colloid-Dark"
)

# --- Functions ---
get_wallpaper_folder() {
    validate_file "$WALLPAPER_FILE"
    
    local wallpaper_path
    wallpaper_path=$(<"$WALLPAPER_FILE") || die "Failed to read wallpaper file"
    
    if [[ "$wallpaper_path" =~ Wallpapers/([^/]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        die "Invalid wallpaper path pattern: $wallpaper_path"
    fi
}

resolve_theme_name() {
    local -r folder="${1:-}"
    
    if [[ -z "$folder" ]]; then
        echo "$DEFAULT_THEME"
        return
    fi
    
    echo "${THEME_MAP[$folder]:-$DEFAULT_THEME}"
}

verify_theme_installation() {
    local -r theme="${1:?Theme name required}"
    local -ra theme_paths=(
        "$HOME/.themes/$theme"
        "$HOME/.local/share/themes/$theme"
        "/usr/share/themes/$theme"
    )
    
    for path in "${theme_paths[@]}"; do
        [[ -d "$path" ]] && return 0
    done
    
    die "Theme not installed: '$theme'"
}

update_gtk_settings() {
    local -r theme="$1"
    
    gsettings set org.gnome.desktop.interface gtk-theme "$theme" || die "Failed to set GTK theme"
    gsettings set org.gnome.desktop.interface color-scheme "$COLOR_SCHEME" || die "Failed to set color scheme"
}

set_ini_value() {
    local -r file="$1"
    local -r section="$2"
    local -r key="$3"
    local -r value="$4"
    
    [[ -f "$file" ]] || touch "$file"
    
    if grep -q "^\[$section\]" "$file"; then
        if grep -q "^$key=" "$file"; then
            sed -i "/^\[$section\]/,/^\[/ s/^$key=.*/$key=$value/" "$file"
        else
            sed -i "/^\[$section\]/a $key=$value" "$file"
        fi
    else
        printf '\n[%s]\n%s=%s\n' "$section" "$key" "$value" >>"$file"
    fi
}

manage_gtk_config() {
    local -r version="$1"
    local -r theme="$2"
    local -r config_file="$CONFIG_DIR/gtk-$version/settings.ini"
    
    ensure_directory "$(dirname "$config_file")"
    
    set_ini_value "$config_file" "Settings" "gtk-theme-name" "$theme"
    set_ini_value "$config_file" "Settings" "gtk-application-prefer-dark-theme" "1"
}

manage_symlinks() {
    local -r theme="$1"
    local target_dir=""
    local -r gtk4_dir="$CONFIG_DIR/gtk-4.0"
    
    declare -A links=(
        ["$gtk4_dir/gtk.css"]="gtk-4.0/gtk.css"
        ["$gtk4_dir/gtk-dark.css"]="gtk-4.0/gtk-dark.css"
        ["$gtk4_dir/assets"]="gtk-4.0/assets"
        ["$CONFIG_DIR/assets"]="assets"
    )
    
    # Find theme directory
    local -ra theme_paths=(
        "$HOME/.themes/$theme"
        "$HOME/.local/share/themes/$theme"
        "/usr/share/themes/$theme"
    )
    
    for path in "${theme_paths[@]}"; do
        if [[ -d "$path" ]]; then
            target_dir="$path"
            break
        fi
    done
    
    [[ -n "$target_dir" ]] || die "Theme assets not found: $theme"
    
    # Create symlinks
    for link in "${!links[@]}"; do
        local target="$target_dir/${links[$link]}"
        [[ -e "$target" ]] || continue
        
        ensure_directory "$(dirname "$link")"
        ln -sf "$target" "$link" && log_info "Created symlink: ${link##*/}"
    done
}

update_xsettingsd() {
    local -r theme="$1"
    local -r config_file="$CONFIG_DIR/xsettingsd/xsettingsd.conf"
    
    [[ -f "$config_file" ]] || return 0
    
    sed -i "s/Net\/ThemeName \".*\"/Net\/ThemeName \"$theme\"/" "$config_file" || \
        log_warn "Failed to update xsettingsd config"
}

main() {
    local current_theme target_theme wallpaper_folder
    
    # Get current state
    current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'") || \
        die "Failed to get current GTK theme"
    
    wallpaper_folder=$(get_wallpaper_folder)
    target_theme=$(resolve_theme_name "$wallpaper_folder")
    
    [[ -n "$target_theme" ]] || die "Failed to resolve theme name"
    
    # Skip if already using target theme
    if [[ "$current_theme" == "$target_theme" ]]; then
        log_info "Already using theme: $target_theme"
        exit 0
    fi
    
    # Apply theme changes
    verify_theme_installation "$target_theme"
    update_gtk_settings "$target_theme"
    
    for version in "${GTK_VERSIONS[@]}"; do
        manage_gtk_config "$version" "$target_theme"
    done
    
    manage_symlinks "$target_theme"
    update_xsettingsd "$target_theme"
    
    # Verify changes
    local new_theme
    new_theme=$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'") || \
        die "Failed to verify theme change"
    
    [[ "$new_theme" == "$target_theme" ]] || die "Theme verification failed"
      
    log_success "Theme successfully updated to $target_theme"
}

# --- Script Entry Point ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi