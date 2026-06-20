import QtQuick
import Quickshell.Io
import qs.modules.globals
import qs.modules.services
import qs.config
import qs.modules.components

ToggleButton {
    id: launcherButton

    buttonIcon: "󰣇"
    textIconFont: "Symbols Nerd Font Mono"
    iconTint: false
    iconFullTint: false
    iconSize: Config.bar.launcherIconSize
    tooltipText: PackageUpdateService.isChecking ? "Checking package updates..." : PackageUpdateService.tooltip

    Process {
        id: updateProcess
        running: false
        command: ["ghostty", "-e", "bash", "-c", "sudo pacman -Syu --noconfirm"]
        onExited: PackageUpdateService.refresh()
    }

    onToggle: function () {
        if (!updateProcess.running)
            updateProcess.running = true;
    }
}
