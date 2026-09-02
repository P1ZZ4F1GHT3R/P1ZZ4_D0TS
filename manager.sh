#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
#   Colors & formatting
# ============================================================
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
MAGENTA="\033[1;35m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"

# ============================================================
#   Helpers
# ============================================================
info()    { echo -e "${CYAN}  •${RESET} $*"; }
success() { echo -e "${GREEN}  ✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}  ⚠${RESET}  $*"; }
error()   { echo -e "${RED}  ✗${RESET} $*" >&2; }
step()    { echo -e "\n${BOLD}${BLUE}▶ $*${RESET}"; }
header()  { echo -e "\n${BOLD}${MAGENTA}══════════════════════════════════════${RESET}"; \
            echo -e "${BOLD}${MAGENTA}  $*${RESET}"; \
            echo -e "${BOLD}${MAGENTA}══════════════════════════════════════${RESET}"; }

# Ask yes/no — $1 = question, $2 = default (y/n, optional)
confirm() {
    local question="$1"
    local default="${2:-n}"
    local prompt

    [[ "$default" == "y" ]] && prompt="${BOLD}[Y/n]${RESET}" || prompt="${BOLD}[y/N]${RESET}"

    while true; do
        echo -en "\n${YELLOW}  ?${RESET}  $question $prompt: "
        read -r REPLY
        REPLY="${REPLY:-$default}"
        case "$REPLY" in
            y|Y|yes|YES) return 0 ;;
            n|N|no|NO)   return 1 ;;
            *) echo -e "${RED}  Please answer y or n.${RESET}" ;;
        esac
    done
}

# ============================================================
#   Paths & state
# ============================================================
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$HOME/.dotfiles-backup"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
STOWALL="$REPO_ROOT/scripts/.config/scripts/system/stowall.sh"
UPDATE_CHECK="$REPO_ROOT/scripts/.config/scripts/system/package-updates.sh"
UPDATE_SERVICE="$REPO_ROOT/scripts/.config/scripts/system/update-service"
MANAGER_LOG="$HOME/hyprland-manager-$TIMESTAMP.log"

# Keep this in sync with stowall.sh. These are the only package paths the
# manager may remove from $HOME.
PACKAGES=(
    "hypr" "wallust" "bash" "btop" "chrome-flags.conf" "code-flags.conf"
    "fastfetch" "ghostty" "nvim" "quickshell" "scripts" "shell.env"
    "Thunar" "vicinae" "yazi" "zsh" ".zshenv" "waybound" "cli.sh"
)

# Log everything to file without suppressing terminal output.
exec > >(tee -a "$MANAGER_LOG") 2>&1

# ============================================================
#   Update helpers
# ============================================================
check_system_updates() {
    header "Checking for package updates"

    if [[ ! -x "$UPDATE_CHECK" ]]; then
        warn "package-updates.sh is not executable; skipping the package check."
        return 0
    fi

    local update_output update_count
    if ! update_output="$("$UPDATE_CHECK" 2>&1)"; then
        warn "Package update check could not finish. You can still update with pacman."
        info "$update_output"
        return 0
    fi

    update_count="$(sed -nE 's/.*"text"[[:space:]]*:[[:space:]]*"([0-9]+)".*/\1/p' <<< "$update_output" | tail -n 1)"
    if [[ -z "$update_count" ]]; then
        warn "Could not read the package update count."
        return 0
    fi

    if (( update_count > 0 )); then
        info "$update_count package update(s) available."
        if confirm "Update the system before checking the dotfiles repository?" "y"; then
            if "$UPDATE_SERVICE"; then
                success "System updated"
            else
                warn "One or more update steps failed. Review update-service output above."
            fi
        else
            warn "System update skipped."
        fi
    else
        success "System is up to date"
    fi
}

update_dotfiles() {
    check_system_updates

    header "Checking P1ZZ4_D0TS"
    if [[ ! -d "$REPO_ROOT/.git" ]]; then
        error "This manager must be run from a Git clone of the dotfiles repository."
        return 1
    fi

    if [[ -n "$(git -C "$REPO_ROOT" status --porcelain)" ]]; then
        warn "Local changes were found; refusing to pull so none of your work is overwritten."
        info "Commit, stash, or discard those changes, then run the manager again."
        return 0
    fi

    step "Checking GitHub for changes..."
    if ! git -C "$REPO_ROOT" fetch --quiet origin; then
        error "Could not contact the remote repository. Check your connection and Git remote."
        return 1
    fi

    local branch local_commit remote_commit
    branch="$(git -C "$REPO_ROOT" symbolic-ref --quiet --short HEAD || true)"
    if [[ -z "$branch" ]]; then
        warn "Detached HEAD detected; skipping repository update."
        return 0
    fi

    local_commit="$(git -C "$REPO_ROOT" rev-parse HEAD)"
    remote_commit="$(git -C "$REPO_ROOT" rev-parse "origin/$branch" 2>/dev/null || true)"
    if [[ -z "$remote_commit" ]]; then
        warn "No origin/$branch branch was found; skipping repository update."
        return 0
    fi
    if [[ "$local_commit" == "$remote_commit" ]]; then
        success "Dotfiles are already up to date"
        return 0
    fi

    info "Updates are available on origin/$branch."
    if ! confirm "Pull and re-stow the updated dotfiles?" "y"; then
        info "Repository update skipped."
        return 0
    fi

    git -C "$REPO_ROOT" pull --ff-only origin "$branch"
    success "Repository updated"

    step "Re-stowing dotfiles..."
    "$STOWALL"
    success "Updated dotfiles are active"
}

# ============================================================
#   Backup & removal helpers
# ============================================================
list_backups() {
    local backup
    BACKUPS=()
    shopt -s nullglob
    for backup in "$BACKUP_ROOT"/config-*; do
        [[ -d "$backup" ]] && BACKUPS+=("$backup")
    done
    shopt -u nullglob
}

restore_backup() {
    header "Restore a configuration backup"
    list_backups
    if (( ${#BACKUPS[@]} == 0 )); then
        warn "No config-* backups were found in $BACKUP_ROOT"
        return 0
    fi

    local selected
    echo -e "${DIM}  Available backups:${RESET}"
    select selected in "${BACKUPS[@]##*/}" "Cancel"; do
        if [[ "$selected" == "Cancel" ]]; then
            info "Restore cancelled."
            return 0
        elif [[ -z "$selected" ]]; then
            warn "Please choose a listed backup."
            continue
        fi
        selected="$BACKUP_ROOT/$selected"
        break
    done

    if ! confirm "Restore $selected into ~/.config? Existing files with the same names will be replaced." "n"; then
        info "Restore cancelled."
        return 0
    fi

    mkdir -p "$HOME/.config"
    cp -a "$selected/." "$HOME/.config/"
    success "Your pre-install configuration has been restored"
}

delete_dotfiles() {
    header "Delete stowed dotfiles"
    warn "This removes only symlinks that point from your home directory into this repository."
    warn "The repository and normal files are left untouched."
    if ! confirm "Remove the managed dotfile symlinks now?" "n"; then
        info "Deletion cancelled."
        return 0
    fi

    local package source target source_real target_real removed=0
    for package in "${PACKAGES[@]}"; do
        [[ -d "$REPO_ROOT/$package" ]] || continue
        while IFS= read -r -d '' source; do
            target="$HOME/${source#"$REPO_ROOT/$package/"}"
            [[ -L "$target" ]] || continue
            source_real="$(readlink -f -- "$source")"
            target_real="$(readlink -f -- "$target" 2>/dev/null || true)"
            if [[ "$target_real" == "$source_real" ]]; then
                rm -- "$target"
                ((removed += 1))
            fi
        done < <(find "$REPO_ROOT/$package" -type f -print0)
    done

    success "Removed $removed managed symlink(s)"
    if confirm "Restore one of your saved ~/.config backups now?" "y"; then
        restore_backup
    else
        info "Your backups remain in $BACKUP_ROOT"
    fi
}

# ============================================================
#   Banner & pre-flight checks
# ============================================================
clear
echo -e "${BOLD}${MAGENTA}"
cat << 'EOF'

██████╗  ██╗███████╗███████╗██╗  ██╗        ██████╗  ██████╗ ████████╗███████╗
██╔══██╗███║╚══███╔╝╚══███╔╝██║  ██║        ██╔══██╗██╔═████╗╚══██╔══╝██╔════╝
██████╔╝╚██║  ███╔╝   ███╔╝ ███████║        ██║  ██║██║██╔██║   ██║   ███████╗
██╔═══╝  ██║ ███╔╝   ███╔╝  ╚════██║        ██║  ██║████╔╝██║   ██║   ╚════██║
██║      ██║███████╗███████╗     ██║███████╗██████╔╝╚██████╔╝   ██║   ███████║
╚═╝      ╚═╝╚══════╝╚══════╝     ╚═╝╚══════╝╚═════╝  ╚═════╝    ╚═╝   ╚══════╝

EOF
echo -e "${RESET}"
echo -e "${DIM}  dotfiles manager  •  $(date '+%Y-%m-%d %H:%M:%S')${RESET}"
echo -e "${DIM}  log: $MANAGER_LOG${RESET}"

header "Pre-flight checks"
step "Verifying environment..."

if ! command -v pacman >/dev/null 2>&1; then
    error "Not running on Arch Linux (pacman not found). Exiting."
    exit 1
fi
success "Arch Linux detected"

if [[ ! -x "$STOWALL" ]]; then
    error "stowall.sh not found or not executable at: $STOWALL"
    exit 1
fi
success "stowall.sh found"

if [[ "$EUID" -eq 0 ]]; then
    error "Don't run this script as root or with sudo."
    exit 1
fi
success "Running as regular user: ${WHITE}$USER${RESET}"

# ============================================================
#   Main menu
# ============================================================
while true; do
    echo
    info "What would you like to do?"
    select option in "Update dotfiles" "Delete dotfiles" "Exit"; do
        case "$option" in
            "Update dotfiles") update_dotfiles; break ;;
            "Delete dotfiles") delete_dotfiles; break ;;
            "Exit") info "Goodbye."; exit 0 ;;
            *) warn "Please enter a number between 1 and 3." ;;
        esac
    done
done
