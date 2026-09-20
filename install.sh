#!/usr/bin/env bash

set -uo pipefail

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

info()    { echo -e "${CYAN}  •${RESET} $*"; }
success() { echo -e "${GREEN}  ✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}  ⚠${RESET}  $*"; }
error()   { echo -e "${RED}  ✗${RESET} $*" >&2; }
step()    { echo -e "\n${BOLD}${BLUE}▶ $*${RESET}"; }
header() {
    echo -e "\n${BOLD}${MAGENTA}══════════════════════════════════════${RESET}"
    echo -e "${BOLD}${MAGENTA}  $*${RESET}"
    echo -e "${BOLD}${MAGENTA}══════════════════════════════════════${RESET}"
}

confirm() {
    local question="$1" default="${2:-n}" prompt reply
    if [[ "$default" == y ]]; then prompt="${BOLD}[Y/n]${RESET}"; else prompt="${BOLD}[y/N]${RESET}"; fi
    while true; do
        echo -en "\n${YELLOW}  ?${RESET}  $question $prompt: "
        read -r reply
        reply="${reply:-$default}"
        case "$reply" in
            y|Y|yes|YES) return 0 ;;
            n|N|no|NO) return 1 ;;
            *) echo -e "${RED}  Please answer y or n.${RESET}" ;;
        esac
    done
}

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT" || exit 1
INSTALL_USER="$(id -un)"
BACKUP_ROOT="$HOME/.dotfiles-backup"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
CONFIG_BACKUP="$BACKUP_ROOT/config-$TIMESTAMP"
INSTALL_LOG="$HOME/hyprland-install-$TIMESTAMP.log"

SCRIPTS_DIR="$REPO_ROOT/scripts/.config/scripts"
STOWALL="$SCRIPTS_DIR/system/stowall.sh"
STOWALLINSTALL="$SCRIPTS_DIR/system/stowall-install.sh"
QUICKSHELL_PAM_SOURCE="$REPO_ROOT/quickshell_pam"
AUTOLOGIN_SOURCE="$REPO_ROOT/autologin.conf"

FAILED_PACKAGES=()
FAILED_STEPS=()
TEMP_DIRS=()

cleanup_temp_dirs() {
    local temp_dir
    for temp_dir in "${TEMP_DIRS[@]}"; do
        [[ -d "$temp_dir" ]] && rm -rf -- "$temp_dir"
    done
}
trap cleanup_temp_dirs EXIT

record_step_failure() {
    FAILED_STEPS+=("$1 (exit code $2)")
}

run_step() {
    local label="$1"
    shift
    local status
    step "$label"
    "$@"
    status=$?
    if (( status == 0 )); then
        success "$label"
        return 0
    fi
    error "$label failed (exit code $status)."
    record_step_failure "$label" "$status"
    return "$status"
}

install_pacman_packages() {
    local package
    for package in "$@"; do
        step "Installing pacman package: $package"
        if sudo pacman -S --needed --noconfirm "$package"; then
            success "$package installed or already present"
        else
            error "pacman could not install: $package"
            FAILED_PACKAGES+=("pacman: $package")
        fi
    done
}

install_yay_packages() {
    local package
    for package in "$@"; do
        step "Installing AUR package: $package"
        if yay -S --needed --noconfirm "$package"; then
            success "$package installed or already present"
        else
            error "yay could not install: $package"
            FAILED_PACKAGES+=("yay: $package")
        fi
    done
}

run_hyprpm_step() {
    local label="$1"
    shift
    run_step "$label" hyprpm "$@"
}

show_failure_summary() {
    header "Installation summary"
    if (( ${#FAILED_PACKAGES[@]} == 0 )); then
        success "No package installation failures were detected."
    else
        error "The following packages failed to install:"
        printf '  %s\n' "${FAILED_PACKAGES[@]}"
    fi
    if (( ${#FAILED_STEPS[@]} > 0 )); then
        warn "The following non-package steps failed or were incomplete:"
        printf '  %s\n' "${FAILED_STEPS[@]}"
    fi
}

exec > >(tee -a "$INSTALL_LOG") 2>&1

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

header "Pre-flight checks"
step "Verifying environment..."

if ! command -v pacman >/dev/null 2>&1; then
    error "Not running on Arch Linux (pacman not found). Exiting."
    exit 1
fi
success "Arch Linux detected"

if ! command -v sudo >/dev/null 2>&1; then
    error "sudo was not found. Install sudo and run this script again."
    exit 1
fi
success "sudo found"

if [[ ! -f "$STOWALL" ]]; then
    error "stowall.sh not found at: $STOWALL"
    info "Make sure you're running this script from the repository root."
    exit 1
fi
success "stowall.sh found"

if [[ ! -f "$STOWALLINSTALL" ]]; then
    error "stowall-install.sh not found at: $STOWALLINSTALL"
    exit 1
fi
success "stowall-install.sh found"

if [[ "$EUID" -eq 0 ]]; then
    error "Don't run this script as root or with sudo."
    exit 1
fi
success "Running as regular user: ${WHITE}${INSTALL_USER}${RESET}"

echo
info "This script will:"
echo -e "  ${DIM}  1. Update the system with pacman, yay, and hyprpm where available${RESET}"
echo -e "  ${DIM}  2. Install base tools, official packages, and AUR packages${RESET}"
echo -e "  ${DIM}  3. Install Hyprland plugins, Colloid Light/Dark, Vimix, and VSCodium theming${RESET}"
echo -e "  ${DIM}  4. Set zsh as the default shell and install PAM/SDDM configuration${RESET}"
echo -e "  ${DIM}  5. Back up ~/.config, patch local usernames, and stow the dotfiles${RESET}"

if ! confirm "Ready to begin?" y; then
    info "Aborted. Nothing was changed."
    exit 0
fi

header "System update"
if confirm "Update the system now? (recommended)" y; then
    run_step "Updating official packages with pacman" sudo pacman -Syu --noconfirm || true
    if command -v yay >/dev/null 2>&1; then
        run_step "Updating AUR packages with yay" yay -Syu --noconfirm || true
    else
        info "yay is not installed yet; its update will be available after installation."
    fi
    if command -v hyprpm >/dev/null 2>&1; then
        run_step "Updating Hyprland plugin headers with hyprpm" hyprpm update || true
    else
        info "hyprpm is not installed yet; plugin headers will be updated later."
    fi
else
    warn "Skipping system update. Packages may be stale."
fi

header "Base tools"
BASE_PACKAGES=(
    git base-devel stow rsync curl wget tar ripgrep pacman-contrib
    sassc gtk-engine-murrine gnome-themes-extra
)
step "The following base tools will be installed:"
printf '    %s\n' "${BASE_PACKAGES[@]}"
install_pacman_packages "${BASE_PACKAGES[@]}"

header "AUR helper — yay"
if command -v yay >/dev/null 2>&1; then
    success "yay is already installed ($(yay --version | head -1))"
else
    warn "yay is not installed."
    if confirm "Install yay from the AUR?" y; then
        YAY_TMP="$(mktemp -d -t p1zz4-dots-yay.XXXXXX)"
        TEMP_DIRS+=("$YAY_TMP")
        if git clone --depth 1 https://aur.archlinux.org/yay.git "$YAY_TMP/yay"; then
            if (cd "$YAY_TMP/yay" && makepkg -si --noconfirm); then
                success "yay installed"
            else
                error "yay could not be built or installed."
                record_step_failure "Installing yay" 1
            fi
        else
            error "Could not clone the yay AUR repository."
            record_step_failure "Cloning yay" 1
        fi
    else
        warn "Skipping yay. AUR packages will not be installed."
    fi
fi

header "Official packages (pacman)"
PACMAN_PACKAGES=(
    bash zsh thunar fastfetch yazi btop ghostty awww vscodium
    sddm python python-pip zen-browser quickshell
    imagemagick hyprpm
)
step "The following official packages will be installed:"
printf '    %s\n' "${PACMAN_PACKAGES[@]}"
install_pacman_packages "${PACMAN_PACKAGES[@]}"

header "VSCodium theme"
if command -v codium >/dev/null 2>&1; then
    run_step "Installing the Wallust theme extension for VSCodium" \
        codium --install-extension saatvik333.wallust-theme || true
else
    error "codium was not found; could not install the Wallust VSCodium extension."
    record_step_failure "Installing the Wallust VSCodium extension" 1
fi

header "Default shell"
ZSH_PATH="$(command -v zsh || true)"
if [[ -z "$ZSH_PATH" ]]; then
    error "zsh was not found; the default shell was not changed."
    record_step_failure "Setting zsh as the default shell" 1
elif ! command -v chsh >/dev/null 2>&1; then
    error "chsh was not found; the default shell was not changed."
    record_step_failure "Setting zsh as the default shell" 1
else
    CURRENT_LOGIN_SHELL="$(getent passwd "$INSTALL_USER" 2>/dev/null | cut -d: -f7)"
    if [[ "$CURRENT_LOGIN_SHELL" == "$ZSH_PATH" ]]; then
        success "zsh is already the default shell for $INSTALL_USER"
    elif chsh -s "$ZSH_PATH" "$INSTALL_USER"; then
        success "Set zsh as the default shell for $INSTALL_USER"
    else
        error "Could not set zsh as the default shell for $INSTALL_USER."
        record_step_failure "Setting zsh as the default shell" 1
    fi
fi

header "AUR packages (yay)"
AUR_PACKAGES=(
    vicinae wallust sunsetr ttf-material-symbols-variable-git
    waybound pipes-rs papirus-icon-theme quicksnip-git
)
if command -v yay >/dev/null 2>&1; then
    step "The following AUR packages will be installed:"
    printf '    %s\n' "${AUR_PACKAGES[@]}"
    install_yay_packages "${AUR_PACKAGES[@]}"
else
    warn "yay is not available — skipping AUR packages."
fi

header "Hyprland plugins"
if command -v hyprpm >/dev/null 2>&1; then
    run_hyprpm_step "Updating Hyprpm headers" update || true
    run_hyprpm_step "Adding dynamic-cursors plugin" add https://github.com/virtcode/hypr-dynamic-cursors || true
    run_hyprpm_step "Enabling dynamic-cursors plugin" enable dynamic-cursors || true
    run_hyprpm_step "Adding scrolloverview plugin" add https://github.com/yayuuu/hyprland-scroll-overview || true
    run_hyprpm_step "Enabling scrolloverview plugin" enable scrolloverview || true
    run_hyprpm_step "Adding hyprglass plugin" add https://github.com/hyprnux/hyprglass || true
    run_hyprpm_step "Enabling hyprglass plugin" enable hyprglass || true
else
    warn "hyprpm is not installed; skipping Hyprland plugin setup."
fi

header "GTK themes — regular Colloid Light and Dark"
if confirm "Build and install regular Colloid Light and Dark themes?" y; then
    COLLOID_TMP="$(mktemp -d -t p1zz4-dots-colloid.XXXXXX)"
    TEMP_DIRS+=("$COLLOID_TMP")
    if git clone --depth 1 https://github.com/vinceliuice/Colloid-gtk-theme.git "$COLLOID_TMP/Colloid-gtk-theme"; then
        if (
            cd "$COLLOID_TMP/Colloid-gtk-theme" || exit 1
            ./install.sh -t default -c light
            ./install.sh -t default -c dark
        ); then
            success "Regular Colloid Light and Dark themes installed"
        else
            error "Colloid Light/Dark theme installation failed."
            record_step_failure "Installing Colloid Light/Dark themes" 1
        fi
    else
        error "Could not clone the Colloid GTK theme repository."
        record_step_failure "Cloning Colloid GTK theme" 1
    fi
else
    warn "Skipping Colloid themes."
fi

header "Hyprcursor — Vimix"
CURSOR_URL="https://github.com/ericbrand97/vimix-cursors/releases/download/hyprcursors-v0.1/vimix-hyprcursors-v0.1.tar.gz"
if confirm "Install the Vimix hyprcursor theme?" y; then
    CURSOR_TMP="$(mktemp -d -t p1zz4-dots-vimix.XXXXXX)"
    TEMP_DIRS+=("$CURSOR_TMP")
    CURSOR_ARCHIVE="$CURSOR_TMP/vimix-hyprcursors-v0.1.tar.gz"
    CURSOR_SOURCE="$CURSOR_TMP/Vimix Hyprcursors - Dark"
    CURSOR_USER_DIR="$HOME/.local/share/icons/Vimix"
    CURSOR_SYSTEM_DIR="/usr/share/icons/Vimix"
    if curl -fL "$CURSOR_URL" -o "$CURSOR_ARCHIVE" &&
        tar -xzf "$CURSOR_ARCHIVE" -C "$CURSOR_TMP"; then
        if [[ -d "$CURSOR_SOURCE" ]] &&
            mkdir -p "$CURSOR_USER_DIR" &&
            cp -a "$CURSOR_SOURCE"/. "$CURSOR_USER_DIR/" &&
            sudo install -d "$CURSOR_SYSTEM_DIR" &&
            sudo cp -r "$CURSOR_SOURCE"/. "$CURSOR_SYSTEM_DIR/" &&
            sudo chmod -R a+rX "$CURSOR_SYSTEM_DIR"; then
            success "Vimix installed in $HOME/.local/share/icons/Vimix and /usr/share/icons/Vimix"
        else
            error "Vimix was downloaded but could not be installed in the icon directories."
            record_step_failure "Installing Vimix hyprcursor theme" 1
        fi
    else
        error "Could not download or unpack the Vimix hyprcursor theme."
        record_step_failure "Downloading Vimix hyprcursor theme" 1
    fi
else
    warn "Skipping Vimix hyprcursor theme."
fi

header "System authentication files"
if [[ -f "$QUICKSHELL_PAM_SOURCE" ]]; then
    step "Installing quickshell_pam to /etc/pam.d/quickshell_pam"
    if sudo install -Dm644 "$QUICKSHELL_PAM_SOURCE" /etc/pam.d/quickshell_pam; then
        success "quickshell_pam installed"
    else
        error "Could not install quickshell_pam."
        record_step_failure "Installing quickshell_pam" 1
    fi
else
    error "quickshell_pam was not found at $QUICKSHELL_PAM_SOURCE"
    record_step_failure "Installing quickshell_pam" 1
fi

if [[ -f "$AUTOLOGIN_SOURCE" ]]; then
    if confirm "Enable SDDM autologin for $INSTALL_USER?" n; then
        AUTOLOGIN_TMP="$(mktemp -t p1zz4-dots-autologin.XXXXXX)"
        TEMP_DIRS+=("$AUTOLOGIN_TMP")
        if sed -e "s/^User=.*/User=$INSTALL_USER/" \
            -e "s/p1zz4fighter/$INSTALL_USER/g" \
            -e "s/p1zz4f1ght3r/$INSTALL_USER/g" \
            "$AUTOLOGIN_SOURCE" > "$AUTOLOGIN_TMP" &&
            sudo install -Dm644 "$AUTOLOGIN_TMP" /etc/sddm.conf.d/autologin.conf; then
            success "SDDM autologin enabled for $INSTALL_USER"
        else
            error "Could not install the SDDM autologin configuration."
            record_step_failure "Installing SDDM autologin configuration" 1
        fi
    else
        info "SDDM autologin skipped."
    fi
else
    warn "autologin.conf was not found; skipping SDDM autologin."
fi

header "Backing up ~/.config"
if [[ -d "$HOME/.config" ]]; then
    step "Saving the current ~/.config to $CONFIG_BACKUP"
    if mkdir -p "$BACKUP_ROOT" && cp -a "$HOME/.config" "$CONFIG_BACKUP"; then
        success "Backup saved at: $CONFIG_BACKUP"
        info "To restore later: ${DIM}rm -rf ~/.config && mv $CONFIG_BACKUP ~/.config${RESET}"
    else
        error "Could not back up ~/.config. Stowing will not run."
        record_step_failure "Backing up ~/.config" 1
        show_failure_summary
        exit 1
    fi
else
    info "~/.config does not exist yet; creating it."
    mkdir -p "$HOME/.config"
fi

header "Patching local username paths"
step "Replacing old P1ZZ4_D0TS usernames with $INSTALL_USER"
PATCHED_FILES=()
while IFS= read -r target_file; do
    [[ -z "$target_file" ]] && continue
    if sed -i \
        -e "s/p1zz4f1ght3r/$INSTALL_USER/g" \
        -e "s/p1zz4fighter/$INSTALL_USER/g" \
        "$target_file"; then
        PATCHED_FILES+=("${target_file#"$REPO_ROOT/"}")
    else
        warn "Could not patch $target_file"
    fi
done < <(
    if command -v rg >/dev/null 2>&1; then
        rg -l --hidden --no-messages \
            -e 'p1zz4f1ght3r' \
            -e 'p1zz4fighter' \
            "$REPO_ROOT" \
            --glob '!.git/**' \
            --glob '!install.sh' \
            --glob '!autologin.conf' || true
    else
        grep -IlRE \
            --exclude=install.sh \
            --exclude=autologin.conf \
            --exclude-dir=.git \
            'p1zz4f1ght3r|p1zz4fighter' "$REPO_ROOT" || true
    fi
)
if (( ${#PATCHED_FILES[@]} > 0 )); then
    printf '  %s\n' "${PATCHED_FILES[@]}"
    success "Patched local username paths"
else
    info "No repository files needed username patching."
fi

header "Script permissions"
if [[ -d "$SCRIPTS_DIR" ]]; then
    while IFS= read -r -d '' script_file; do
        if [[ "$(head -n 1 "$script_file")" == '#!'* ]]; then
            chmod +x "$script_file"
        fi
    done < <(find "$SCRIPTS_DIR" -type f -print0)
    success "Scripts in $SCRIPTS_DIR marked executable"
else
    warn "Scripts directory not found at $SCRIPTS_DIR"
fi
if [[ -f "$REPO_ROOT/manager.sh" ]]; then
    chmod +x "$REPO_ROOT/manager.sh"
    success "manager.sh marked executable"
else
    warn "manager.sh not found at $REPO_ROOT/manager.sh"
fi

header "Stowing dotfiles"
step "Running stowall-install.sh — this will copy and symlink the dotfiles"
info "The pre-stow backup is at: ${WHITE}$CONFIG_BACKUP${RESET}"
if "$STOWALLINSTALL"; then
    success "Dotfiles stowed successfully"
else
    error "Stowing failed."
    record_step_failure "Stowing dotfiles" 1
    info "Restore with: ${DIM}rm -rf ~/.config && mv $CONFIG_BACKUP ~/.config${RESET}"
fi

show_failure_summary
header "Installation complete"
if (( ${#FAILED_PACKAGES[@]} == 0 && ${#FAILED_STEPS[@]} == 0 )); then
    success "Everything is set up."
else
    warn "Installation finished with warnings. Review the summary above."
fi
echo -e "${DIM}  Full log saved to: $INSTALL_LOG${RESET}"

echo
if confirm "Everything is done. Reboot now to apply all changes?" n; then
    echo -e "\n${YELLOW}  Rebooting in 3 seconds... (Ctrl+C to cancel)${RESET}"
    sleep 3
    sudo systemctl reboot
else
    info "Reboot skipped."
    echo -e "${DIM}  When you're ready: ${WHITE}sudo systemctl reboot${RESET}"
fi
