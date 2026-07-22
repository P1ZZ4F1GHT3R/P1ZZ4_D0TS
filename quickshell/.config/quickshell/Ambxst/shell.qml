//@ pragma UseQApplication
//@ pragma ShellId ambxst
//@ pragma DataDir $BASE/ambxst
//@ pragma StateDir $BASE/ambxst

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.bar
import qs.modules.bar.workspaces
import qs.modules.notifications

import qs.modules.notch
import qs.modules.services
import qs.modules.corners
import qs.modules.frame
import qs.modules.components
import qs.modules.lockscreen
import qs.modules.globals
import qs.modules.shell
import qs.config
import qs.modules.shell.osd
import "config/defaults/bar.js" as BarDefaults
import "modules/tools"

ShellRoot {
    id: root

    Process {
        running: true
        command: ["bash", Quickshell.shellDir + "/scripts/daemon_priority.sh"]
    }

    function configuredBarScreens() {
        if (!Config.barReady || !Config.bar)
            return [];

        const list = Config.bar.screenList || [];
        return list.length > 0 ? list : (BarDefaults.data.screenList || []);
    }

    readonly property var targetScreens: {
        const list = root.configuredBarScreens();
        return Quickshell.screens.filter(screen => list.indexOf(screen.name) !== -1);
    }

    ContextMenu {
        id: contextMenu
        screen: Quickshell.screens[0]
        Component.onCompleted: Visibilities.setContextMenu(contextMenu)
    }

    // Visual panel & reservations
    Variants {
        model: root.targetScreens

        Item {
            id: screenShellContainer
            required property ShellScreen modelData
            readonly property bool screenHasFullscreen: {
                const monitor = Hyprland.monitorFor(modelData);
                return !!(monitor && monitor.activeWorkspace && monitor.activeWorkspace.hasFullscreen);
            }

            // Panel components (Bar, Notch, Dock, Frame, Corners)
            UnifiedShellPanel {
                id: unifiedPanel
                targetScreen: screenShellContainer.modelData
                fullscreenActive: screenShellContainer.screenHasFullscreen
            }

            Loader {
                active: Config.theme.enableCorners && Config.roundness > 0
                sourceComponent: ScreenCorners {
                    screen: screenShellContainer.modelData
                    fullscreenActive: screenShellContainer.screenHasFullscreen
                }
            }

            // Exclusive zone reservations
            ReservationWindows {
                screen: screenShellContainer.modelData

                // Bar status for reservations
                barEnabled: {
                    const list = root.configuredBarScreens();
                    return list.indexOf(screen.name) !== -1;
                }
                barPosition: unifiedPanel.barPosition
                barPinned: unifiedPanel.pinned
                barFullscreenActive: screenShellContainer.screenHasFullscreen
                barSize: (unifiedPanel.barPosition === "left" || unifiedPanel.barPosition === "right") ? unifiedPanel.barTargetWidth : unifiedPanel.barTargetHeight
                barOuterMargin: unifiedPanel.barOuterMargin

                // No dock reservation in the portable shell build.
                dockEnabled: false

                frameEnabled: (Config.bar && Config.bar.frameEnabled !== undefined ? Config.bar.frameEnabled : false)
                frameThickness: (Config.bar && Config.bar.frameThickness !== undefined ? Config.bar.frameThickness : 6)

                sidebarEnabled: false
            }
        }
    }

    // Secure WlSessionLock lockscreen
    WlSessionLock {
        id: sessionLock
        locked: GlobalStates.lockscreenVisible

        // Surface auto-created per screen
        LockScreen {}
    }

    // Screenshot tool
    Variants {
        model: Quickshell.screens

        Loader {
            id: screenshotLoader
            active: GlobalStates.screenshotToolVisible
            required property ShellScreen modelData
            sourceComponent: ScreenshotTool {
                targetScreen: screenshotLoader.modelData
            }
        }
    }

    // Screenshot preview overlay
    Variants {
        model: Quickshell.screens

        Loader {
            id: screenshotOverlayLoader
            active: SuspendManager.wakeReady
            required property ShellScreen modelData
            sourceComponent: ScreenshotOverlay {
                targetScreen: screenshotOverlayLoader.modelData
            }
        }
    }

    // Screen recording tool
    Loader {
        id: screenRecordLoader
        active: SuspendManager.wakeReady && GlobalStates.screenRecordToolVisible
        source: "modules/tools/ScreenrecordTool.qml"

        onLoaded: {
            if (GlobalStates.screenRecordToolVisible && item) {
                item.open();
            }
        }

        Connections {
            target: GlobalStates
            function onScreenRecordToolVisibleChanged() {
                if (screenRecordLoader.status === Loader.Ready) {
                    if (GlobalStates.screenRecordToolVisible) {
                        screenRecordLoader.item.open();
                    } else {
                        screenRecordLoader.item.close();
                    }
                }
            }
        }

        Connections {
            target: screenRecordLoader.item
            ignoreUnknownSignals: true
            function onVisibleChanged() {
                if (!screenRecordLoader.item.visible && GlobalStates.screenRecordToolVisible) {
                    GlobalStates.screenRecordToolVisible = false;
                }
            }
        }
    }

    // Mirror tool
    Loader {
        id: mirrorLoader
        active: SuspendManager.wakeReady && GlobalStates.mirrorWindowVisible
        source: "modules/tools/MirrorWindow.qml"
    }

    // On-screen display
    Variants {
        model: Quickshell.screens

        Loader {
            id: osdLoader
            active: SuspendManager.wakeReady
            required property ShellScreen modelData
            sourceComponent: OSD {
                targetScreen: osdLoader.modelData
            }
        }
    }

    // Init clipboard service
    Connections {
        target: ClipboardService
        function onListCompleted() {
        // Service initialized and ready
        }
    }

    // Force service init at startup but defer it slightly so it doesn't block the UI
    QtObject {
        id: serviceInitializer

        Component.onCompleted: {
            // Critical services — init immediately (next tick)
            Qt.callLater(() => {
                let _ = CaffeineService.inhibit;
                _ = IdleService.lockCmd; // Force init
                _ = GlobalShortcuts.appId; // Force init (IPC pipe listener)
            });
        }
    }

    // Non-critical services — defer 2s after startup
    Timer {
        interval: 2000
        running: true
        onTriggered: {
            let _ = NightLightService.active;
            _ = GameModeService.toggled;
        }
    }
}
