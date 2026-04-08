# Hyprland Rice (stow-managed)

A Hyprland rice based on [Saatvik333's](https://github.com/saatvik333/hyprland-dotfiles) configuration and uses quickshell elements from [ilyamiro's](https://github.com/ilyamiro/imperative-dots) configuration. The wallpaper picker is from [liixini](https://github.com/liixini/skwd-wall). Everything is managed with GNU Stow for simple dotfile symlinking.

> Warning: The installer is untested. Use at your own risk and review the install script before running.

## Requirements

- Arch Linux (or an Arch-based distribution) (btw)
- sudo access
- Internet connection

## What the script does

- Installs required base packages (via pacman).
- Backs up your existing `~/.config` directory.
- Symlinks configuration files using `stow`.
- Installs additional dependencies required by the rice.

## Installation

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

## Contributing

- Contributions are welcome. Open an issue or submit a pull request with clear changes.

## License

This configuration is provided as-is for educational and personal use. Individual components may have their own licenses.

## Disclaimer

This script is provided as-is and has not been fully tested. Review `install.sh` and all included files before running. The author is not responsible for any system changes or data loss.
