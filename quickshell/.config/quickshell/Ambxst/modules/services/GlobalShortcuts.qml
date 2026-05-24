pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.globals
import qs.modules.services
import qs.config

import Quickshell.Io

QtObject {
    id: root

    readonly property string appId: "ambxst"
    readonly property string ipcPipe: "/tmp/ambxst_ipc.pipe"

    // High-performance Pipe Listener (Daemon mode)
    property Process pipeListener: Process {
        command: ["bash", "-c", "rm -f " + root.ipcPipe + "; mkfifo " + root.ipcPipe + "; tail -f " + root.ipcPipe]
        running: true
        
        stdout: SplitParser {
            onRead: data => {
                const cmd = data.trim();
                if (cmd !== "") {
                    root.run(cmd);
                }
            }
        }
    }

    function run(command) {
        console.log("IPC run command received:", command);
        if (command.indexOf("matugen ") === 0) {
            const parts = command.substring(8).trim().split(/\s+/);
            const scheme = parts.length > 1 ? parts[parts.length - 1] : "";
            const source = parts.length > 1 && scheme.indexOf("scheme-") === 0 ? parts.slice(0, -1).join(" ") : parts.join(" ");
            MatugenService.run(source, scheme.indexOf("scheme-") === 0 ? scheme : "");
            return;
        }
        if (command.indexOf("theme ") === 0) {
            const parts = command.substring(6).trim().split(/\s+/);
            const scheme = parts.length > 1 ? parts[parts.length - 1] : "";
            const source = parts.length > 1 && scheme.indexOf("scheme-") === 0 ? parts.slice(0, -1).join(" ") : parts.join(" ");
            MatugenService.runTheme(source, scheme.indexOf("scheme-") === 0 ? scheme : "");
            return;
        }
        if (command.indexOf("wallust ") === 0) {
            MatugenService.runWallustOnly(command.substring(8).trim());
            return;
        }

        switch (command) {
            // Launcher (Standalone Notch Module)
            case "launcher": toggleLauncher(); break;
            case "clipboard": toggleLauncherWithPrefix(1, Config.prefix.clipboard + " "); break;
            case "emoji": toggleLauncherWithPrefix(2, Config.prefix.emoji + " "); break;
            case "tmux": toggleLauncherWithPrefix(3, Config.prefix.tmux + " "); break;
            case "notes": toggleLauncherWithPrefix(4, Config.prefix.notes + " "); break;

            // Notch dashboard
            case "dashboard": toggleDashboardTab(0); break;
            case "default": toggleDashboardTab(0); break;
            case "system-monitor": toggleDashboardTab(1); break;
            case "metrics": toggleDashboardTab(1); break;
            case "assistant": GlobalStates.toggleAssistant(); break;

            // System
            case "powermenu": toggleSimpleModule("powermenu"); break;
            case "tools": toggleSimpleModule("tools"); break;
            case "close": Visibilities.setActiveModule(""); break;
            case "screenshot": Screenshot.initialize(); GlobalStates.screenshotToolVisible = true; break;
            case "screenrecord": ScreenRecorder.initialize(); GlobalStates.screenRecordToolVisible = true; break;
            case "lens": 
                Screenshot.initialize();
                Screenshot.captureMode = "lens";
                GlobalStates.screenshotToolVisible = true;
                break;
            case "lockscreen": GlobalStates.lockscreenVisible = true; break;
            case "matugen-rerun": MatugenService.rerun(); break;
            
            default: console.warn("Unknown IPC command:", command);
        }
    }

    property IpcHandler ipcHandler: IpcHandler {
        target: "ambxst"

        function run(command: string) {
            root.run(command);
        }
    }

    function toggleSettings() {
        console.warn("Settings window is disabled in the portable shell build.");
    }

    function toggleSimpleModule(moduleName) {
        if (Visibilities.currentActiveModule === moduleName) {
            Visibilities.setActiveModule("");
        } else {
            Visibilities.setActiveModule(moduleName);
        }
    }

    function toggleLauncher() {
        const isActive = Visibilities.currentActiveModule === "launcher";
        if (isActive && GlobalStates.widgetsTabCurrentIndex === 0 && GlobalStates.launcherSearchText === "") {
            Visibilities.setActiveModule("");
        } else {
            GlobalStates.widgetsTabCurrentIndex = 0;
            GlobalStates.launcherSearchText = "";
            GlobalStates.launcherSelectedIndex = -1;
            if (!isActive) {
                Visibilities.setActiveModule("launcher");
            }
        }
    }

    function toggleLauncherWithPrefix(tabIndex, prefix) {
        const isActive = Visibilities.currentActiveModule === "launcher";
        const currentTab = GlobalStates.widgetsTabCurrentIndex;
        const currentText = GlobalStates.launcherSearchText;

        if (isActive && currentTab === tabIndex && (currentText === prefix || currentText === "")) {
            Visibilities.setActiveModule("");
            GlobalStates.clearLauncherState();
            return;
        }

        GlobalStates.widgetsTabCurrentIndex = tabIndex;
        GlobalStates.launcherSearchText = prefix;
        
        if (!isActive) {
            Visibilities.setActiveModule("launcher");
        }
    }

    function toggleDashboardTab(tabIndex) {
        const isActive = Visibilities.currentActiveModule === "dashboard";

        if (isActive && GlobalStates.dashboardCurrentTab === tabIndex) {
            Visibilities.setActiveModule("");
            return;
        }

        GlobalStates.dashboardCurrentTab = tabIndex;
        if (!isActive) {
            Visibilities.setActiveModule("dashboard");
        }
    }
}
