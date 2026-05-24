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
INSTALL_LOG="$HOME/hyprland-install-$TIMESTAMP.log"

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
echo -e "  ${DIM}  6. Install custom Waybar modules${RESET}"

if ! confirm "Ready to begin?" "y"; then
    info "Aborted. Nothing was changed."
    exit 0
fi

# ============================================================
#   System update
# ============================================================
header "System update"

step "Running pacman -Syu..."
if confirm "Update the system now? (recommended)" "y"; then
    sudo pacman -Syu --noconfirm
    success "System updated"
else
    warn "Skipping system update. Things may break if packages are stale."
fi

# ============================================================
#   Base tools
# ============================================================
header "Base tools"

step "Installing git, base-devel, stow, curl, wget..."
sudo pacman -S --needed --noconfirm \
    git \
    base-devel \
    stow \
    curl \
    wget
success "Base tools ready"

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
        makepkg -si --noconfirm
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
    hyprland-git bash zsh
    thunar fastfetch
    yazi
    btop ghostty swww vscodium
    sddm neovim python python-edev python-pip
    zen-browser quickshell-git matugen
)

step "The following packages will be installed:"
echo -e "${DIM}"
printf '    %s\n' "${PACMAN_PACKAGES[@]}"
echo -e "${RESET}"

if confirm "Install these packages?" "y"; then
    sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"
    success "Official packages installed"
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
)

if command -v yay >/dev/null 2>&1; then
    step "The following AUR packages will be installed:"
    echo -e "${DIM}"
    printf '    %s\n' "${AUR_PACKAGES[@]}"
    echo -e "${RESET}"

    if confirm "Install AUR packages?" "y"; then
        set +e
        yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"
        AUR_EXIT=$?
        set -e
        if [ $AUR_EXIT -ne 0 ]; then
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
    header "Installing Hyprland Plugins"
    hyprpm add https://github.com/virtcode/hypr-dynamic-cursors
    hyprpm enable dynamic-cursors
    hyprpm add https://github.com/yayuuu/hyprland-scroll-overview
    hyprpm enable scrolloverview

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
#   Replace username in config
# ============================================================
header "Patching config — skwd-wall"

TARGET_FILE="./skwd-wall/.config/skwd-wall/config.json"
step "Replacing hardcoded user 'p1zz4f1ght3r' → '${USER}' in $TARGET_FILE"

if [ -f "$TARGET_FILE" ]; then
    if confirm "Apply path patch to skwd-wall config?" "y"; then
        sed -i "s/p1zz4f1ght3r/$USER/g" "$TARGET_FILE"
        success "Paths updated to /home/$USER"
    else
        warn "Skipping patch. skwd-wall will likely fail to find wallpapers."
    fi
else
    warn "Target file not found at $TARGET_FILE — skipping patch."
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
#   Custom Waybar modules
# ============================================================
header "Custom Waybar modules"

step "Will install:"
echo -e "  ${DIM}wpm-waybar  (words-per-minute module)${RESET}"
echo -e "  ${DIM}gpu-usage-waybar  (via cargo)${RESET}"

if confirm "Install custom Waybar modules?" "y"; then

    # wpm-waybar
    info "Cloning and installing wpm-waybar..."
    sudo usermod -aG input $USER
    git clone https://github.com/andriy-koz/wpm-waybar.git
    cd wpm-waybar
    git checkout 8b201bb
    bash install.sh
    cd -
    rm -rf wpm-waybar
    success "wpm-waybar installed"

    # gpu-usage-waybar
info "Installing gpu-usage-waybar via cargo..."

# Check for Rust/cargo and install if missing
if ! command -v cargo >/dev/null 2>&1; then
    warn "Rust not found — installing via rustup..."
    if confirm "Install Rust (via rustup)?" "y"; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        success "Rust installed"
    else
        warn "Skipping Rust — gpu-usage-waybar will not be installed."
    fi
fi

if command -v cargo >/dev/null 2>&1; then
    if ! echo "$PATH" | grep -q "$HOME/.cargo/bin"; then
        warn "~/.cargo/bin not in PATH — adding it..."
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.bashrc"
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.zshrc"
        mkdir -p "$HOME/.config/fish"
        echo 'set -gx PATH $HOME/.cargo/bin $PATH' >> "$HOME/.config/fish/config.fish"
        export PATH="$HOME/.cargo/bin:$PATH"
        success "Added ~/.cargo/bin to PATH (bash, zsh, fish)"
    fi
    cargo install gpu-usage-waybar
    success "gpu-usage-waybar installed"
else
    warn "Rust/cargo still not available — skipping gpu-usage-waybar."
fi
else
    warn "Skipping custom Waybar modules."
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