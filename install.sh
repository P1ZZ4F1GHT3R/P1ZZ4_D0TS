#!/usr/bin/env bash
set -e

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

    if [[ "$default" == "y" ]]; then
        prompt="${BOLD}[Y/n]${RESET}"
    else
        prompt="${BOLD}[y/N]${RESET}"
    fi

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
BACKUP_ROOT="$HOME/.dotfiles-backup"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
CONFIG_BACKUP="$BACKUP_ROOT/config-$TIMESTAMP"
STOWALLINSTALL="./scripts/.config/scripts/system/stowall-install.sh"
STOWALL="./scripts/.config/scripts/system/stowall.sh"
SCRIPTS_DIR="./scripts/.config/scripts"
UPDATE_SERVICE="./scripts/.config/scripts/system/update-service"
INSTALL_LOG="$HOME/hyprland-install-$TIMESTAMP.log"

# Reuse update-service's quiet, package-by-package progress wrapper for the
# installer package transactions. Its main routine only runs when executed.
source "$UPDATE_SERVICE"

# Log everything to file without suppressing terminal output
exec > >(tee -a "$INSTALL_LOG") 2>&1

# ============================================================
#   Banner
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
echo -e "${DIM}  dotfiles installer  •  $(date '+%Y-%m-%d %H:%M:%S')${RESET}"
echo -e "${DIM}  log: $INSTALL_LOG${RESET}"

# ============================================================
#   Sanity checks
# ============================================================
header "Pre-flight checks"

step "Verifying environment..."

if ! command -v pacman >/dev/null 2>&1; then
    error "Not running on Arch Linux (pacman not found). Exiting."
    exit 1
fi
success "Arch Linux detected"

if [ ! -f "$STOWALL" ]; then
    error "stowall.sh not found at: $STOWALL"
    info  "Make sure you're running this script from the repository root."
    exit 1
fi
success "stowall.sh found"

if [ "$EUID" -eq 0 ]; then
    error "Don't run this script as root or with sudo."
    exit 1
fi
success "Running as regular user: ${WHITE}$USER${RESET}"

echo
info "This script will:"
echo -e "  ${DIM}  1. Update your system (pacman -Syu)${RESET}"
echo -e "  ${DIM}  2. Install base tools, official packages, and AUR packages${RESET}"
echo -e "  ${DIM}  3. Build and install Colloid GTK theme variants${RESET}"
echo -e "  ${DIM}  4. Back up your current ~/.config${RESET}"
echo -e "  ${DIM}  5. Stow the dotfiles into place${RESET}"

if ! confirm "Ready to begin?" "y"; then
    info "Aborted. Nothing was changed."
    exit 0
fi

# ============================================================
#   System update
# ============================================================
header "System update"

step "Running update-service..."
if confirm "Update the system now? (recommended)" "y"; then
    if "$UPDATE_SERVICE"; then
        success "System updated"
    else
        warn "One or more update steps failed. Review the summary above; installation will continue."
    fi
else
    warn "Skipping system update. Things may break if packages are stale."
fi

# ============================================================
#   Base tools
# ============================================================
header "Base tools"

step "Installing git, base-devel, stow, curl, wget, pacman-contrib..."
if run_update "Base tools (pacman)" sudo pacman -S --needed --noconfirm \
    git \
    base-devel \
    stow \
    curl \
    wget \
    pacman-contrib; then
    success "Base tools ready"
else
    warn "Some base tools failed to install. Review the errors above."
fi

# ============================================================
#   yay (AUR helper)
# ============================================================
header "AUR helper — yay"

if command -v yay >/dev/null 2>&1; then
    success "yay is already installed ($(yay --version | head -1))"
else
    step "yay not found — will clone and build from AUR"
    if confirm "Install yay?" "y"; then
        YAY_TMP="/tmp/yay-install-$$"
        git clone https://aur.archlinux.org/yay.git "$YAY_TMP"
        cd "$YAY_TMP"
        run_update "AUR helper (makepkg)" makepkg -si --noconfirm
        cd -
        rm -rf "$YAY_TMP"
        success "yay installed"
    else
        warn "Skipping yay. AUR packages will not be installed."
    fi
fi

# ============================================================
#   Official packages
# ============================================================
header "Official packages (pacman)"

PACMAN_PACKAGES=(
    bash zsh
    thunar fastfetch
    yazi
    btop ghostty swww vscodium
    sddm neovim python python-pip
    zen-browser quickshell-git matugen
    rsync
)

step "The following packages will be installed:"
echo -e "${DIM}"
printf '    %s\n' "${PACMAN_PACKAGES[@]}"
echo -e "${RESET}"

if confirm "Install these packages?" "y"; then
    if run_update "Official packages (pacman)" sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"; then
        success "Official packages installed"
    else
        warn "Some official packages failed to install. Review the errors above."
    fi
else
    warn "Skipping official packages. The dotfiles may not work correctly."
fi

# ============================================================
#   AUR packages
# ============================================================
header "AUR packages (yay)"

AUR_PACKAGES=(
    vicinae wallust sunsetr
    cmatrix-git ttf-material-symbols-variable-git
    waybound skwd-wall skwd-daemon-bin pipes-rs
    plymouth python-edev hyprland-git
)

if command -v yay >/dev/null 2>&1; then
    step "The following AUR packages will be installed:"
    echo -e "${DIM}"
    printf '    %s\n' "${AUR_PACKAGES[@]}"
    echo -e "${RESET}"

    if confirm "Install AUR packages?" "y"; then
        if ! run_update "AUR packages (yay)" yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"; then
            warn "Some AUR packages failed to install. Continuing anyway."
        else
            success "AUR packages installed"
        fi
    else
        warn "Skipping AUR packages."
    fi
else
    warn "yay not available — skipping AUR packages."
fi

# ============================================================
#   Hyprland Plugins
# ============================================================
header "Hyprland plugins"

HYPRPM_FAILED=()

run_hyprpm_step() {
    local label="$1"
    shift
    local log status had_errexit=0

    step "$label"
    log="$(mktemp -t p1zz4-dots-hyprpm.XXXXXX)"
    [[ "$-" == *e* ]] && had_errexit=1
    set +e
    "$@" >"$log" 2>&1
    status=$?
    if (( had_errexit )); then
        set -e
    else
        set +e
    fi

    if (( status == 0 )); then
        success "$label"
        rm -f "$log"
        return 0
    fi

    warn "$label failed (exit code $status); continuing."
    show_failure_details "$log"
    HYPRPM_FAILED+=("$label")
    rm -f "$log"
    return 1
}

if command -v hyprpm >/dev/null 2>&1; then
    run_hyprpm_step "Updating Hyprpm headers" hyprpm update || true
    run_hyprpm_step "Adding dynamic-cursors plugin" hyprpm add https://github.com/virtcode/hypr-dynamic-cursors || true
    run_hyprpm_step "Enabling dynamic-cursors plugin" hyprpm enable dynamic-cursors || true
    run_hyprpm_step "Adding scrolloverview plugin" hyprpm add https://github.com/yayuuu/hyprland-scroll-overview || true
    run_hyprpm_step "Enabling scrolloverview plugin" hyprpm enable scrolloverview || true
    run_hyprpm_step "Adding hyprglass plugin" hyprpm add https://github.com/hyprnux/hyprglass || true
    run_hyprpm_step "Enabling hyprglass plugin" hyprpm enable hyprglass || true

    if (( ${#HYPRPM_FAILED[@]} == 0 )); then
        success "Hyprland plugins installed"
    else
        warn "Some Hyprland plugin steps failed:"
        printf '  %s\n' "${HYPRPM_FAILED[@]}"
    fi
else
    warn "hyprpm is not installed; skipping Hyprland plugin setup."
fi

# ============================================================
#   GTK themes — Colloid variants
# ============================================================
header "GTK themes — Colloid"

COLLOID_VARIANTS=(catppuccin everforest gruvbox nord dracula)
step "Will build the following Colloid dark variants:"
echo -e "  ${DIM}Colloid-Dark (base)${RESET}"
for v in "${COLLOID_VARIANTS[@]}"; do
    echo -e "  ${DIM}Colloid-Dark-${v^}${RESET}"
done

if confirm "Build and install Colloid GTK themes? (requires internet + a few minutes)" "y"; then
    COLLOID_TMP="/tmp/colloid-theme-$$"
    [ -d "$COLLOID_TMP" ] && rm -rf "$COLLOID_TMP"
    git clone https://github.com/vinceliuice/Colloid-gtk-theme.git "$COLLOID_TMP"
    cd "$COLLOID_TMP"

    ./install.sh -t default -c dark --tweaks black rimless
    for v in "${COLLOID_VARIANTS[@]}"; do
        info "Building Colloid-Dark-${v^}..."
        ./install.sh -t default -c dark --tweaks "$v" black rimless
    done

    cd -
    rm -rf "$COLLOID_TMP"
    success "Colloid themes installed"
else
    warn "Skipping GTK themes."
fi

# ============================================================
#   Hyprcursor — Vimix cursor theme
# ============================================================
header "Hyprcursor — Vimix"

CURSOR_URL="https://github.com/ericbrand97/vimix-cursors/releases/download/hyprcursors-v0.1/vimix-hyprcursors-v0.1.tar.gz"
CURSOR_TMP="/tmp/vimix-hyprcursors-$$"
CURSOR_ARCHIVE="$CURSOR_TMP/vimix-hyprcursors-v0.1.tar.gz"

step "Will download and install Vimix hyprcursor theme to /usr/share/icons"

if confirm "Install Vimix hyprcursor theme?" "y"; then
    mkdir -p "$CURSOR_TMP"
    info "Downloading..."
    curl -L "$CURSOR_URL" -o "$CURSOR_ARCHIVE"
    info "Unpacking..."
    tar -xzf "$CURSOR_ARCHIVE" -C "$CURSOR_TMP"
    info "Installing to /usr/share/icons..."
    sudo cp -r "$CURSOR_TMP/Vimix Hyprcursors - Dark" /usr/share/icons/
    sudo chmod -R a+rX "/usr/share/icons/Vimix Hyprcursors - Dark"
    rm -rf "$CURSOR_TMP"
    success "Vimix hyprcursor theme installed"
else
    warn "Skipping Vimix hyprcursor theme."
fi

# ============================================================
#   Backup ~/.config
# ============================================================
header "Backing up ~/.config"

if [ -d "$HOME/.config" ]; then
    step "Destination: ${WHITE}$CONFIG_BACKUP${RESET}"
    if confirm "Back up your current ~/.config before stowing?" "y"; then
        mkdir -p "$BACKUP_ROOT"
        cp -r "$HOME/.config" "$CONFIG_BACKUP"
        success "Backup saved at: $CONFIG_BACKUP"
        info  "To restore later: ${DIM}rm -rf ~/.config && mv $CONFIG_BACKUP ~/.config${RESET}"
    else
        warn "Skipping backup. If stowing breaks things, there's no fallback."
    fi
else
    info "~/.config doesn't exist yet — nothing to back up."
fi

# ============================================================
#   Replace username in absolute paths
# ============================================================
header "Patching absolute home paths"

PATH_PATCH_FILES=(
    "./hypr/.config/hypr/hyprlock.conf"
    "./hypr/.config/hypr/hyprlock.conf.save"
    "./.zshrc/.zshrc"
)

step "Replacing /home/p1zz4f1ght3r with $HOME in current path-sensitive configs"
if confirm "Apply the home-path patch?" "y"; then
    for target_file in "${PATH_PATCH_FILES[@]}"; do
        if [ -f "$target_file" ]; then
            sed -i "s|/home/p1zz4f1ght3r|$HOME|g" "$target_file"
            success "Patched $target_file"
        else
            warn "Target file not found at $target_file — skipping."
        fi
    done
else
    warn "Skipping home-path patch. Hyprlock or shell paths may not work correctly."
fi

# ============================================================
#   Make scripts executable
# ============================================================
header "Script permissions"

step "Setting +x on all .sh files in $SCRIPTS_DIR"
if [ -d "$SCRIPTS_DIR" ]; then
    find "$SCRIPTS_DIR" -type f -name "*.sh" -exec chmod +x {} \;
    success "Scripts marked executable"
else
    warn "Scripts directory not found at $SCRIPTS_DIR"
fi

if [ -f "./manager.sh" ]; then
    chmod +x ./manager.sh
    success "manager.sh marked executable"
else
    warn "manager.sh not found at ./manager.sh"
fi

# ============================================================
#   Stow dotfiles
# ============================================================
header "Stowing dotfiles"

step "Running stowall-install.sh — this will symlink everything into place"
info  "If this fails, your backup is at: ${WHITE}$CONFIG_BACKUP${RESET}"

if confirm "Stow dotfiles now?" "y"; then
    if ! "$STOWALLINSTALL"; then
        error "Stowing failed!"
        info  "Restore with: ${DIM}rm -rf ~/.config && mv $CONFIG_BACKUP ~/.config${RESET}"
        exit 1
    fi
    success "Dotfiles stowed successfully"
else
    warn "Skipping stow. Dotfiles are NOT active yet."
fi


# ============================================================
#   Done!
# ============================================================
header "Installation complete!"

success "Everything is set up."
echo -e "${DIM}  Full log saved to: $INSTALL_LOG${RESET}"

echo
if confirm "Reboot now to apply all changes?" "n"; then
    echo -e "\n${YELLOW}  Rebooting in 3 seconds... (Ctrl+C to cancel)${RESET}"
    sleep 3
    sudo systemctl reboot
else
    info "Reboot skipped."
    echo -e "${DIM}  When you're ready: ${WHITE}sudo systemctl reboot${RESET}"
fi
