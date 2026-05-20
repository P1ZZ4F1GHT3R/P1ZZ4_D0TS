import QtQuick
import Quickshell.Io
import qs.modules.globals
import qs.modules.services
import qs.config
import qs.modules.components

ToggleButton {
    buttonIcon: "󰣇"
    textIconFont: "Symbols Nerd Font Mono"
    iconTint: false
    iconFullTint: false
    iconSize: Config.bar.launcherIconSize
    tooltipText: "System Update"

    Process {
        id: updateProcess
        running: false
        command: ["ghostty", "-e", "sh", "-lc", "yay -Syu --noconfirm; printf '\\nPress Enter to close...'; read _"]
    }

    onToggle: function () {
        if (!updateProcess.running)
            updateProcess.running = true;
    }
}
