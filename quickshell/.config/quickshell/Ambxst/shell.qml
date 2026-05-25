//@ pragma UseQApplication
//@ pragma ShellId ambxst
//@ pragma DataDir $BASE/ambxst
//@ pragma StateDir $BASE/ambxst

import QtQuick
import Quickshell
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
    property int fullscreenRefreshSerial: 0

    Process {
        running: true
        command: ["bash", Quickshell.shellDir + "/scripts/daemon_priority.sh"]
    }

    Process {
        id: hyprFullscreenEvents
        running: true
        command: ["bash", "-lc", "while true; do sock=\"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock\"; if command -v socat >/dev/null 2>&1 && [ -S \"$sock\" ]; then socat - UNIX-CONNECT:\"$sock\"; fi; sleep 1; done"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const eventName = data.split(">>")[0];
                if (["fullscreen", "fullscreenstate", "openwindow", "closewindow", "movewindow", "movewindowv2", "workspace", "workspacev2", "focusedmon"].indexOf(eventName) !== -1)
                    root.fullscreenRefreshSerial++;
            }
        }
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
            property bool screenHasFullscreen: false
            property bool fullscreenCheckPending: false
            property int fullscreenRefreshSerial: root.fullscreenRefreshSerial

            function requestFullscreenCheck() {
                if (fullscreenChecker.running) {
                    fullscreenCheckPending = true;
                    return;
                }
                fullscreenChecker.running = true;
            }

            onFullscreenRefreshSerialChanged: requestFullscreenCheck()

            Process {
                id: fullscreenChecker
                running: false
                command: ["bash", "-lc", "screen=\"$1\"; monitors=$(hyprctl -j monitors 2>/dev/null) || exit 0; clients=$(hyprctl -j clients 2>/dev/null) || exit 0; jq -n -c --arg screen \"$screen\" --argjson monitors \"$monitors\" --argjson clients \"$clients\" '(($monitors[]? | select(.name == $screen)) // null) as $m | if $m == null then false else any($clients[]?; ((.fullscreen // 0) > 0) and ((.monitor == $m.id) or (.monitor == $m.name)) and ((.workspace.id // -999999) == ($m.activeWorkspace.id // -999998))) end'", "ambxst-fullscreen-check", screenShellContainer.modelData.name]
                stdout: SplitParser {
                    splitMarker: "\n"
                    onRead: output => {
                        const trimmed = output.trim();
                        if (trimmed === "true")
                            screenShellContainer.screenHasFullscreen = true;
                        else if (trimmed === "false")
                            screenShellContainer.screenHasFullscreen = false;
                    }
                }

                onExited: {
                    if (screenShellContainer.fullscreenCheckPending) {
                        screenShellContainer.fullscreenCheckPending = false;
                        fullscreenChecker.running = true;
                    }
                }
            }

            Component.onCompleted: requestFullscreenCheck()

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
