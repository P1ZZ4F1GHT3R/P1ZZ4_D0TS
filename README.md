# P1ZZ4_D0TS

A modern, highly customized Hyprland configuration featuring a bespoke Quickshell-based UI, dynamic terminal theming, and a streamlined workflow. This setup is managed using **GNU Stow** for easy symlinking and maintenance.

> Warning: The installer is untested. Use at your own risk and review the install script before running.

## The Core Stack

- **Compositor:** [Hyprland](https://hyprland.org/) (Git version)
- **Launcher:** [Vicinae](https://github.com/JustPreston/vicinae)
- **Terminal:** [Ghostty](https://ghostty.org/)
- **Theming:** [Wallust](https://github.com/fufexan/wallust) (wallpaper-driven color generation)

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
- Patches path-sensitive configs with your local home directory automatically.

### Setup

1. Update the system and install essential packages:
```bash
sudo pacman -Syu --noconfirm
sudo pacman -S --needed base-devel git sudo
```

2. Clone this repository:
```bash
git clone https://github.com/P1ZZ4F1GHT3R/P1ZZ4_D0TS.git
cd P1ZZ4_D0TS
```

3. Make the installer executable and run it:
```bash
chmod +x ./install.sh
./install.sh
```

The script will create a backup of `~/.config` before applying the stow-managed symlinks.

### Managing an existing installation

The installer marks the manager executable. Run it from the repository (or by its full path):

```bash
./manager.sh
```

The manager can:

- check available Arch/AUR package updates with `package-updates.sh` before it contacts GitHub, then offer the shared `update-service` updater with a clean package queue and progress display;
- update the repository with a fast-forward-only pull and re-run the existing `stowall.sh` routine;
- remove only symlinks that point into this repository; and
- remove the managed symlinks and restore an installer-created user configuration backup from `~/.dotfiles-backup/config-*`.

It will not pull while the local clone has uncommitted changes.

## Uninstallation / Restore

Use `./manager.sh` and select **Delete dotfiles**. It removes only the symlinks managed by GNU Stow and keeps the repository itself. It then offers to restore one of the dated backups from `~/.dotfiles-backup`.

## Customization

- Edit or add dotfiles inside the repo's stow package folders.
- Use the integrated `stowall` command to apply changes without rerunning the full installer.
> Note: if you add a new package to the repo, you also have to add it in the stowall.sh script under the section PACKAGES.

## Credits & Inspiration

- **Saatvik333:** The original foundation for the Hyprland configuration.
- **ericbrand97:** For the Vimix Hyprcursor theme.

## License

This configuration is provided as-is for educational and personal use. Individual components may have their own licenses.

## Disclaimer

- This script is provided as-is and has not been fully tested across all environments. Review `install.sh` and all included files before running. I am not responsible for any system changes or data loss.
- I use AI to assist me in creating my dotfiles.
