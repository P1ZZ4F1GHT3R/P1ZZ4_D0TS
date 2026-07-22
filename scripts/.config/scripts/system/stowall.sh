#!/usr/bin/env bash
set -euo pipefail

STOW_DIR="$HOME/P1ZZ4_D0TS"
echo "Re-stowing dotfiles from: $STOW_DIR"

PACKAGES=(
    "hypr"
    "wallust"
    "bash"
    "btop"
    "chrome-flags.conf"
    "code-flags.conf"
    "fastfetch"
    "ghostty"
    "nvim"
    "quickshell"
    "scripts"
    "shell.env"
    "Thunar"
    "vicinae"
    "yazi"
    "zsh"
    ".zshenv"
    "matugen"
    "waybound"
    "cli.sh"
)

# These packages may have real files at target (themer overwrites symlinks).
# Conflicting real files are removed before linking.
FORCE_PACKAGES=(
    "hypr"
    "wallust"
)

is_force_package() {
    local pkg="$1"
    for fp in "${FORCE_PACKAGES[@]}"; do
        [ "$pkg" = "$fp" ] && return 0
    done
    return 1
}

# Remove all symlinks that point into this package's directory
unstow_package() {
    local pkg="$1"
    local pkg_dir="$STOW_DIR/$pkg"

    while IFS= read -r -d '' src; do
        local rel="${src#$pkg_dir/}"
        local target="$HOME/$rel"

        if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
            rm "$target"
        fi
    done < <(find "$pkg_dir" -type f -print0)
}

# Symlink every file in the package to $HOME, creating dirs as needed
stow_package() {
    local pkg="$1"
    local pkg_dir="$STOW_DIR/$pkg"
    local force=false
    is_force_package "$pkg" && force=true

    while IFS= read -r -d '' src; do
        local rel="${src#$pkg_dir/}"
        local target="$HOME/$rel"
        local target_dir
        target_dir="$(dirname "$target")"

        mkdir -p "$target_dir"

        if [ -L "$target" ]; then
            rm "$target"
        elif [ -e "$target" ]; then
            if $force; then
                echo "  Removing conflicting real file: $target"
                rm -f "$target"
            else
                echo "  SKIP (conflict, not a symlink): $target"
                continue
            fi
        fi

        ln -s "$src" "$target"
    done < <(find "$pkg_dir" -type f -print0)
}

# --- Validate ---
echo "Validating packages..."
missing=()
for pkg in "${PACKAGES[@]}"; do
    [ ! -d "$STOW_DIR/$pkg" ] && missing+=("$pkg")
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

existing=()
for pkg in "${PACKAGES[@]}"; do
    [ -d "$STOW_DIR/$pkg" ] && existing+=("$pkg")
done

# --- Step 1: Remove existing symlinks ---
echo ""
echo "Step 1: Removing existing symlinks..."
for pkg in "${existing[@]}"; do
    unstow_package "$pkg" && echo "  Unstowed: $pkg"
done

# --- Step 2: Symlink every file ---
echo ""
echo "Step 2: Symlinking all files..."
failed=()
for pkg in "${existing[@]}"; do
    if stow_package "$pkg"; then
        echo "  Stowed: $pkg"
    else
        echo "  FAILED: $pkg"
        failed+=("$pkg")
    fi
done

# --- Summary ---
echo ""
if [ ${#failed[@]} -gt 0 ]; then
    echo "WARNING: The following packages failed:"
    for f in "${failed[@]}"; do
        echo "  - $f"
    done
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
