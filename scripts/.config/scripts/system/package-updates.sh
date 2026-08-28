#!/bin/bash

#===============================================================================
# Package Updates Checker
# ~/.config/scripts/system/package-updates.sh
# Description: Checks for available package updates (Arch + AUR)
# Author: saatvik333 (modified)
# Version: 2.1
# Dependencies: checkupdates (pacman-contrib), yay (optional for AUR)
#===============================================================================

set -euo pipefail

# Source common utilities (kept for acquire_lock)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# --- Configuration ---
readonly SCRIPT_NAME="${0##*/}"
readonly LOCK_FILE="/tmp/${SCRIPT_NAME%.sh}.lock"
readonly THRESHOLD_YELLOW=50
readonly THRESHOLD_RED=100

# --- Functions ---
check_database_locks() {
    local -r pacman_lock="/var/lib/pacman/db.lck"
    local -r checkup_lock="${TMPDIR:-/tmp}/checkup-db-${UID}/db.lck"
    local -r timeout=30
    local elapsed=0

    while [[ -f "$pacman_lock" || -f "$checkup_lock" ]]; do
        if (( elapsed >= timeout )); then
            echo '{"tooltip": "Database locked - try again later", "class": "transparent"}'
            exit 1
        fi
        sleep 1
        ((elapsed++))
    done
}

get_update_count() {
    local arch_updates=0 aur_updates=0 updates
    local arch_output aur_output status

    # Arch repo updates
    # checkupdates returns 2 when updates are available, which is not an error.
    set +e
    arch_output=$(checkupdates 2>/dev/null)
    status=$?
    set -e
    if (( status != 0 && status != 2 )); then
        return "$status"
    fi
    if [[ -n "$arch_output" ]]; then
        arch_updates=$(printf '%s\n' "$arch_output" | wc -l)
    fi

    # AUR updates (if yay is installed)
    if command -v yay >/dev/null 2>&1; then
        # yay commonly returns 1 when there are no AUR updates.
        set +e
        aur_output=$(yay -Qua 2>/dev/null)
        status=$?
        set -e
        if (( status != 0 && status != 1 )); then
            return "$status"
        fi
        if [[ -n "$aur_output" ]]; then
            aur_updates=$(printf '%s\n' "$aur_output" | wc -l)
        fi
    fi

    updates=$((arch_updates + aur_updates))
    echo "$updates"
}

determine_css_class() {
    local -r updates=$1
    
    if (( updates == 0 )); then
        echo "transparent"
    elif (( updates <= THRESHOLD_YELLOW )); then
        echo "green"
    elif (( updates <= THRESHOLD_RED )); then
        echo "yellow"
    else
        echo "red"
    fi
}

output_waybar_json() {
    local -r updates=$1
    local -r css_class=$2
    
    if (( updates > 0 )); then
        printf '{"text": "%d", "tooltip": "%d packages require updates", "class": "%s"}\n' \
            "$updates" "$updates" "$css_class"
    else
        printf '{"text": "0", "tooltip": "System is up to date", "class": "transparent"}\n'
    fi
}

main() {
    acquire_lock "$LOCK_FILE" "$SCRIPT_NAME"

    # Validate dependencies
    if ! command -v checkupdates >/dev/null 2>&1; then
        echo '{"tooltip": "checkupdates not found", "class": "transparent"}'
        exit 1
    fi

    check_database_locks

    local updates css_class
    updates=$(get_update_count)
    css_class=$(determine_css_class "$updates")

    output_waybar_json "$updates" "$css_class"
}

# --- Script Entry Point ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi