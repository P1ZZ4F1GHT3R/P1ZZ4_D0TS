#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

echo "Re-stowing dotfiles from: $REPO_DIR"

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
    #"quickshell"
    "scripts"
    "shell.env"
    "starship"
    "swaync"
    "Thunar"
    "vicinae"
    "waytrogen"
    "wlogout"
    "wofi"
    "yazi"
    "zsh"
    "pavucontrol.ini"
    "waypaper"
    ".zshenv"
)

# --- Validate all packages exist before touching anything ---
echo "Validating packages..."
missing=()
for pkg in "${PACKAGES[@]}"; do
    if [ ! -d "$REPO_DIR/$pkg" ]; then
        missing+=("$pkg")
    fi
done

if [ ${#missing[@]} -gt 0 ]; then
    echo "ERROR: The following packages don't exist as directories and will be skipped:"
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
    [ -d "$REPO_DIR/$pkg" ] && existing+=("$pkg")
done

# --- Step 1: Unstow everything cleanly ---
echo ""
echo "Step 1: Removing existing symlinks..."
for pkg in "${existing[@]}"; do
    stow -D "$pkg" 2>/dev/null && echo "  Unstowed: $pkg" || true
done

# --- Step 2: Adopt any conflicting files back into repo ---
# This handles the case where a file exists on disk but not as a symlink
echo ""
echo "Step 2: Adopting conflicting files..."
for pkg in "${existing[@]}"; do
    stow --adopt "$pkg" 2>/dev/null && echo "  Adopted: $pkg" || true
done

# Restore repo versions after adopt (adopt overwrites repo files with system files)
echo "  Restoring repo versions after adopt..."
git checkout -- . 2>/dev/null || {
    echo "  WARNING: git checkout failed, repo files may have been overwritten by --adopt"
    echo "  Run 'git diff' to check and 'git checkout -- .' to restore if needed"
}

# --- Step 3: Stow everything ---
echo ""
echo "Step 3: Stowing all packages..."
failed=()
for pkg in "${existing[@]}"; do
    if stow "$pkg" 2>/dev/null; then
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
    echo "Run 'stow -v <package>' to see why."
else
    echo "✓ All packages stowed successfully."
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