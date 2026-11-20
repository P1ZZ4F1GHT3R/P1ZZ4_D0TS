import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell.Io
import Quickshell.Services.Notifications
import "../Modules"
import "../Services"
import "../Widgets"
import "../"

Scope {
    id: root
    
    property bool focused

    NotificationDaemon {
        id: notifDaemon
    }

    PackageUpdateService{
        id: packageUpdateService
    }

    Lockscreen{
        id: lockScreen
        notifServer: notifDaemon
    }

    Process {
        id: applyWallpaperProcess
    }

    function applyWallpaper(path) {
        applyWallpaperProcess.command = ["/bin/bash", root.syncScript, path];
        applyWallpaperProcess.running = true;
    }
    
    PanelWindow {
        id: exclusiveZoneReserve

        screen: Quickshell.screens[parseInt(Variables.preferredMonitorIndex)] || Quickshell.screens[0]

        anchors {
            top: true
            left: true
            right: true
        }

        color: "transparent"
        implicitHeight: 0
        exclusiveZone: Variables.focused ? 0 : Variables.exclusiveZoneTop + Variables.frameBorderWidth
        mask: Region {}
    }

    PanelWindow {
        id: unifiedPanel 

        screen: Quickshell.screens[parseInt(Variables.preferredMonitorIndex)] || Quickshell.screens[0]

        Component.onCompleted: Variables.monitor = screen
        onScreenChanged: Variables.monitor = screen

        HyprlandFocusGrab {
            active: Variables.powerMenu || Variables.wallpaperPicker || Variables.toolBar || Variables.launcherOpen || Variables.settingsOpen
            windows: [ unifiedPanel ] 
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        color: "transparent"
        WlrLayershell.layer: Variables.wallpaperPicker ? WlrLayer.Overlay : WlrLayer.Top
        WlrLayershell.keyboardFocus: (Variables.launcherOpen || Variables.settingsOpen) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore 

        mask: Region {
            item: left
            Region { item: center }
            Region { item: right }
            Region { item: controlCenter }
            Region { item: launcher }
            Region { item: settingsInputRegion }
        }

        IpcHandler {
            target: "focusmode"

            function toggle(): void {
                Variables.focusMode = !Variables.focusMode
                Variables.notchHidden = Variables.focusMode
                Variables.workspacesHidden = Variables.settingsOpen ? true : Variables.focusMode
                Variables.systemHidden = Variables.settingsOpen ? true : Variables.focusMode
                if (!Variables.focused) {
                    focusTimer.start();
                }
                else {
                    Variables.focused = false
                }
            }
        }

        IpcHandler {
            target: "launcher"

            function toggle(): void {
                if (Variables.launcherOpen) {
                    if (Variables.settingsOpen && launcher.item && !launcher.item.searchFocused) {
                        launcher.item.focusSearch();
                    } else {
                        Variables.launcherOpen = false;
                    }
                } else {
                    Variables.launcherMode = Variables.settingsOpen ? "settings" : "apps";
                    Variables.launcherOpen = true; 
                }
            }

            function toggleMode(mode: string): void {
                if (Variables.settingsOpen) {
                    Variables.launcherMode = "settings";
                    Variables.launcherOpen = !Variables.launcherOpen;
                    return;
                }

                if (Variables.launcherOpen && Variables.launcherMode === mode) {
                    Variables.launcherOpen = false;
                } else {
                    Variables.launcherMode = mode;
                    if (mode === "wallpaper") Variables.wallpaperPreview = true;
                    Variables.launcherOpen = true; 
                }
            }
        }

        Timer {
            id: focusTimer
            interval: Variables.animationDurationUI / 1.7
            running: false
            repeat: false
            triggeredOnStart: false
            onTriggered: Variables.focused = true
        }

        Timer {
            id: wallpaperTimer
            interval: Variables.animationDurationUI
            running: false
            repeat: false
            triggeredOnStart: false
            onTriggered: Variables.wallpaperPicker = true
        }

        Timer {
            id: closeWallpaperTimer

            interval: Variables.animationDurationUI
            running: false
            repeat: false
            onTriggered: Variables.wallpaperPreview = false
        }

        Loader {
            id: wallpaperPreviewLoader
            anchors.fill: parent
            active: Variables.wallpaperPreview && Variables.wallpaperPreviewEnabled
            sourceComponent: Component {
                Item {
                    anchors.fill: parent

                    Image {
                        id: oldWallpaper
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                    }

                    Image {
                        id: previewWallpaper
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop

                        Connections {
                            target: Variables
                            function onPreviewPathChanged() {
                                if (String(previewWallpaper.source) === String(Variables.previewPath))
                                    return;

                                oldWallpaper.source = previewWallpaper.source;
                                previewWallpaper.source = Variables.previewPath;
                                previewWallpaper.opacity = 0.0;
                                crossfadeAnim.restart();
                            }

                            function onWallpaperPickerChanged() {
                                if (!Variables.wallpaperPicker) {
                                    previewWallpaper.source = "";
                                    oldWallpaper.source = "";
                                    Variables.previewPath = "";

                                    crossfadeAnim.stop();
                                    previewWallpaper.opacity = 1.0;
                                }
                            }
                        }

                        NumberAnimation on opacity {
                            id: crossfadeAnim; to: 1.0; duration: Variables.fadeAnimation
                        }
                    }
                }
            }
        }

        Rectangle {
            id: settingsScrim
            anchors.fill: parent
            color: Variables.shadowColor
            opacity: Variables.settingsOpen ? Variables.settingsScrimOpacity : 0.0
            visible: opacity > 0.001

            Behavior on opacity {
                NumberAnimation {
                    duration: Variables.fadeAnimation
                    easing.type: Easing.OutCubic
                }
            }
        }

        Item {
            id: compositeContainer
            anchors.fill: parent

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Variables.shadowColor
                shadowBlur: Variables.shadowBlur
                shadowVerticalOffset: 0
                shadowHorizontalOffset: 0
            }

            Shape {
                id: screenBorderShape
                anchors.fill: parent
                antialiasing: true

                readonly property real bw: Variables.frameBorderWidth
                readonly property real r: Variables.radius

                ShapePath {
                    id: framePath
                    fillColor: Variables.uiColor
                    strokeWidth: -1
                    fillRule: ShapePath.OddEvenFill

                    startX: 0
                    startY: 0
                    PathLine { x: screenBorderShape.width; y: 0 }
                    PathLine { x: screenBorderShape.width; y: screenBorderShape.height }
                    PathLine { x: 0; y: screenBorderShape.height }
                    PathLine { x: 0; y: 0 }

                    PathMove { x: screenBorderShape.bw + screenBorderShape.r; y: screenBorderShape.bw }
                    PathLine { x: screenBorderShape.width - screenBorderShape.bw - screenBorderShape.r; y: screenBorderShape.bw }
                    PathArc { x: screenBorderShape.width - screenBorderShape.bw; y: screenBorderShape.bw + screenBorderShape.r; radiusX: screenBorderShape.r; radiusY: screenBorderShape.r }
                    PathLine { x: screenBorderShape.width - screenBorderShape.bw; y: screenBorderShape.height - screenBorderShape.bw - screenBorderShape.r }
                    PathArc { x: screenBorderShape.width - screenBorderShape.bw - screenBorderShape.r; y: screenBorderShape.height - screenBorderShape.bw; radiusX: screenBorderShape.r; radiusY: screenBorderShape.r }
                    PathLine { x: screenBorderShape.bw + screenBorderShape.r; y: screenBorderShape.height - screenBorderShape.bw }
                    PathArc { x: screenBorderShape.bw; y: screenBorderShape.height - screenBorderShape.bw - screenBorderShape.r; radiusX: screenBorderShape.r; radiusY: screenBorderShape.r }
                    PathLine { x: screenBorderShape.bw; y: screenBorderShape.bw + screenBorderShape.r }
                    PathArc { x: screenBorderShape.bw + screenBorderShape.r; y: screenBorderShape.bw; radiusX: screenBorderShape.r; radiusY: screenBorderShape.r }
                }
            }

            SettingsPanel {
                id: settingsOverlay
                x: Variables.frameBorderWidth
                y: Variables.frameBorderWidth + Variables.settingsHeaderHeight
                width: parent.width - (Variables.frameBorderWidth * 2)
                height: parent.height - (Variables.frameBorderWidth * 2) - Variables.settingsHeaderHeight
                launcherHeight: launcher.height
            }

            Item {
                id: settingsInputRegion
                x: settingsOverlay.x
                y: settingsOverlay.y
                width: Variables.settingsOpen ? settingsOverlay.width : 0
                height: Variables.settingsOpen ? settingsOverlay.height : 0
            }

            RowLayout {
                id: left
                anchors { left: parent.left; top: parent.top }
                spacing: Variables.spacing

                Loader {
                    active: true
                    asynchronous: true
                    source: "../Modules/Workspaces.qml"
                }
                UpdateButton {}
            }

            RowLayout {
                id: center
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }

                Notch {
                    notifServer: notifDaemon
                }
            }

            RowLayout {
                id: right
                anchors { right: parent.right; top: parent.top }

                Loader {
                    active: !Variables.systemHidden && !Variables.lockScreen
                    source: "../Modules/PowerProfiles.qml"
                }
                Item { Layout.fillWidth: true }
                Loader {
                    active: true
                    asynchronous: true
                    source: "../Modules/System.qml"
                }
            }

            ControlCenter {
                id: controlCenter
                notifServer: notifDaemon
                anchors {
                    right: parent.right
                }
                implicitWidth: Variables.barControlCenterWidth
                opacity: Variables.settingsOpen ? 0.0 : 1.0
                enabled: !Variables.settingsOpen

                transform: Translate {
                    x: Variables.settingsOpen ? (Variables.controlCenterClosedWidth + Variables.settingsTransitionOffset) : 0
                    Behavior on x {
                        NumberAnimation {
                            duration: Variables.settingsOpen ? Variables.activeDurationUI * 0.64 : Variables.activeDurationUI
                            easing.type: Variables.activeAnimationUI
                        }
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Variables.fadeAnimation
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Loader {
                id: launcher
                active: true
                focus: Variables.launcherOpen
                source: "../Modules/Launcher.qml"
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    PanelWindow {
        id: activateLinux

        implicitHeight: activateLinuxLoader.implicitHeight + Variables.borderWidth * 12
        implicitWidth: activateLinuxLoader.implicitWidth + Variables.borderWidth * 12

        visible: activateLinuxLoader.active
        color: "transparent"

        anchors {
            bottom: true
            right: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        Loader {
            id: activateLinuxLoader
            active: Variables.activateLinux
            source: "../Widgets/ActivateLinux.qml"
            anchors {
                top: parent.top
                left: parent.left
            }
        }
    }
}