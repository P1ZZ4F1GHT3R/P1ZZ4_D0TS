# P1ZZ4F1GHT3R's Hyprland Dotfiles

A modern, highly customized Hyprland configuration featuring a bespoke Quickshell-based UI, dynamic terminal theming, and a streamlined workflow. This setup is managed using **GNU Stow** for easy symlinking and maintenance.

> Warning: The installer is untested. Use at your own risk and review the install script before running.

## The Core Stack

- **Compositor:** [Hyprland](https://hyprland.org/) (Git version)
- **Shell UI:** [Ambxst](https://github.com/Axenide/Ambxst) (Heavily modified Quickshell implementation)
- **Launcher:** [Vicinae](https://github.com/JustPreston/vicinae)
- **Terminal:** [Ghostty](https://ghostty.org/)
- **Theming:** [Wallust](https://github.com/fufexan/wallust) & [Matugen](https://github.com/InioAsman/matugen) (Material You generation)
- **Wallpaper Picker:** [skwd-wall](https://github.com/liixini/skwd-wall)

## Custom Ambxst Shell

The highlight of this rice is a custom "Portable" version of the **Ambxst** shell. I took the full shell and used AI to strip it down and refactor it into a lightweight, modular UI.

**Key modifications:**
- **Stripped down:** Reduced the shell to strictly the Bar, the Notch/Dashboard, and the AI panel.
- **Refactored Modules:** Removed redundant components like the built-in wallpaper manager, settings window, and dock.
- **Behavior Adjustments:** Customized bar modules and interaction behavior to fit a more minimal aesthetic while retaining the Matugen color integration.

## Installation

- Arch Linux (or an Arch-based distribution) (btw)
- sudo access
- Internet connection

## What the script does

- Installs required base packages (via pacman).
- Backs up your existing `~/.config` directory.
- Symlinks configuration files using `stow`.
- Installs additional dependencies required by the rice.
- Installs required base and AUR packages.
- Builds and installs multiple Colloid GTK theme variants.
- Backs up your existing `~/.config` directory to `~/.dotfiles-backup`.
- Symlinks configuration files using a custom stow script.
- Patches configurations (like `waytrogen`) with your local username automatically.

### Setup

1. Update the system and install essential packages:
```bash
sudo pacman -Syu --noconfirm
sudo pacman -S --needed base-devel git sudo
```

2. Clone this repository:
```bash
git clone https://github.com/P1ZZ4F1GHT3R/P1ZZ4F1GHT3RS-Hyprland-Dotfiles.git
cd P1ZZ4F1GHT3RS-Hyprland-Dotfiles
```

3. Make the installer executable and run it:
```bash
chmod +x ./install.sh
./install.sh
```

The script will create a backup of `~/.config` before applying the stow-managed symlinks.

## Uninstallation / Restore

- The installer creates a backup of your original `~/.config` at `~/.dotfiles-backup/config`.
- To remove the stowed configs:
```bash
cd P1ZZ4F1GHT3RS-Hyprland-Dotfiles
stow -D *
```
- Restore your backed-up `~/.config` manually from the backup location if needed.

## Customization

- Edit or add dotfiles inside the repo's stow package folders.
- Use the integrated `stowall` command to apply changes without rerunning the full installer.
> Note: if you add a new package to the repo, you also have to add it in the stowall.sh script under the section PACKAGES.

## Credits & Inspiration

- **Saatvik333:** The original foundation for the Hyprland configuration.
- **Axenide:** The creator of the Ambxst shell.
- **ilyamiro:** For the Quickshell components and inspiration from imperative-dots.
- **liixini:** For the sleek `skwd-wall` wallpaper picker.
- **ericbrand97:** For the Vimix Hyprcursor theme.

## License

This configuration is provided as-is for educational and personal use. Individual components may have their own licenses.

## Disclaimer

This script is provided as-is and has not been fully tested across all environments. Review `install.sh` and all included files before running. I am not responsible for any system changes or data loss.
