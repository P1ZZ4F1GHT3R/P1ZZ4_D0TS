#!/usr/bin/env bash
set -euo pipefail

TMP="$HOME/.config-staging"
TARGET="$HOME/.config"

echo "Step 1: Copying files to ~/.config..."
rm -rf "$TMP"
mkdir -p "$TMP"

# Stow to staging
for pkg in */; do
    pkg_name="${pkg%/}"
    if [ -d "$pkg_name/.config" ]; then
        echo "  Staging $pkg_name..."
        stow -t "$TMP" "$pkg_name"
    fi
done

# Copy actual files (dereferencing symlinks)
echo "  Deploying to ~/.config..."
rsync -avL --delete "$TMP/.config/" "$TARGET/"

# Cleanup staging
rm -rf "$TMP"

echo ""
echo "Step 2: Symlinking back to repo with stow --adopt..."

# Now adopt those files back as symlinks
for pkg in */; do
    pkg_name="${pkg%/}"
    if [ -d "$pkg_name/.config" ]; then
        echo "  Adopting $pkg_name..."
        stow --adopt -t "$HOME" "$pkg_name"
    fi
done

echo ""
echo "✓ Done! Files copied and symlinked to repo."
