#!/usr/bin/env bash
set -euo pipefail

STOW_DIR="$HOME/P11Z4_D0TS"

echo "Re-stowing dotfiles from: $STOW_DIR"

# Explicit package list - only packages that actually exist in the repo
# If you add a new stow package, add it here
PACKAGES=(
    "hypr"
    "wallust"
    "waybar"
    "bash"
    "bongocat"
    "btop"
    "chrome-flags.conf"
    "code-flags.conf"
    "dunst"
    "easyeffects"
    "fastfetch"
    "fish"
    "ghostty"
    "kew"
    "neofetch"
    "nvim"
    "QtProject.conf"
    "quickshell"
    "scripts"
    "shell.env"
    "starship"
    "swaync"
    "Thunar"
    "vicinae"
    "wlogout"
    "wofi"
    "yazi"
    "zsh"
    "pavucontrol.ini"
    ".zshenv"
    "matugen"
    "waybound"
    "skwd-wall"
)

# Packages where the themer overwrites symlinks with real files.
# Before stowing these, any conflicting real files at the target are removed.
FORCE_PACKAGES=(
    "hypr"
    "wallust"
    "waybar"
)

# Removes real files (not symlinks) at stow target paths for a given package
clear_theme_conflicts() {
    local pkg="$1"
    while IFS= read -r -d '' src; do
        local rel="${src#$STOW_DIR/$pkg/}"
        local target="$HOME/$rel"
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            echo "  Removing conflicting file: $target"
            rm -f "$target"
        fi
    done < <(find "$STOW_DIR/$pkg" -type f -print0)
}

# --- Validate all packages exist before touching anything ---
echo "Validating packages..."
missing=()
for pkg in "${PACKAGES[@]}"; do
    if [ ! -d "$STOW_DIR/$pkg" ]; then
        missing+=("$pkg")
    fi
done

if [ ${#missing[@]} -gt 0 ]; then
    echo "WARNING: The following packages don't exist as directories and will be skipped:"
    for m in "${missing[@]}"; do
        echo "  - $m"
    done
    read -r -p "Continue anyway? [y/N]: " CONTINUE
    case "$CONTINUE" in
        y|Y|yes|YES) ;;
        *) echo "Aborted."; exit 1 ;;
    esac
fi

# Filter to only existing packages
existing=()
for pkg in "${PACKAGES[@]}"; do
    [ -d "$STOW_DIR/$pkg" ] && existing+=("$pkg")
done

# --- Step 1: Unstow everything cleanly ---
echo ""
echo "Step 1: Removing existing symlinks..."
for pkg in "${existing[@]}"; do
    stow --no-folding -d "$STOW_DIR" -D "$pkg" 2>/dev/null && echo "  Unstowed: $pkg" || true
done

# --- Step 2: Stow everything with file-level symlinks ---
echo ""
echo "Step 2: Stowing all packages (file-level symlinks)..."
failed=()
for pkg in "${existing[@]}"; do
    # For packages known to have themer-overwritten files, clear conflicts first
    for fp in "${FORCE_PACKAGES[@]}"; do
        if [ "$pkg" = "$fp" ]; then
            clear_theme_conflicts "$pkg"
            break
        fi
    done
    if stow --no-folding -d "$STOW_DIR" "$pkg"; then
        echo "  Stowed: $pkg"
    else
        echo "  FAILED: $pkg"
        failed+=("$pkg")
    fi
done

# --- Summary ---
echo ""
if [ ${#failed[@]} -gt 0 ]; then
    echo "WARNING: The following packages failed to stow:"
    for f in "${failed[@]}"; do
        echo "  - $f"
    done
    echo "Run 'stow -v --no-folding <package>' to see why."
else
    echo "All packages stowed successfully."
fi

echo ""
read -r -p "Reboot now? [y/N]: " REBOOT_CHOICE
case "$REBOOT_CHOICE" in
    y|Y|yes|YES)
        echo "Rebooting in 3 seconds... (Ctrl+C to cancel)"
        sleep 3
        sudo systemctl reboot
        ;;
    *)
        echo "Reboot skipped. Run 'sudo systemctl reboot' when ready."
        ;;
esac