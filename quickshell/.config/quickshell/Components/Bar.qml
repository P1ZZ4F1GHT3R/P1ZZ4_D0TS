import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick.Shapes
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
    }

    PanelWindow {
        id: topBar 

        HyprlandFocusGrab {
            active: Variables.powerMenu
            windows: [ topBar ] 
        }

        anchors {
            top: true
            left: true
            right: true
        }

        color: "transparent"
        implicitHeight: 300
        exclusiveZone: Variables.focused ? 0 : Variables.exclusiveZoneTop + Variables.borderWidth * 4
        WlrLayershell.layer: Variables.wallpaperPicker ? WlrLayer.Overlay : WlrLayer.Top

        mask: Region {
            item: left
            Region { item: center }
            Region { item: right }
        }

        IpcHandler {
            target: "focusmode"

            function toggle(): void {
                Variables.notchHidden = !Variables.notchHidden
                Variables.workspacesHidden = !Variables.workspacesHidden
                Variables.systemHidden = !Variables.systemHidden
                Variables.focusMode = !Variables.focusMode
                if (!Variables.focused) {
                    focusTimer.start();
                }
                else {
                    Variables.focused = false
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

        RowLayout {
            id: left

            anchors {
                left: parent.left
            }
            spacing: Variables.spacing

            Workspaces {}
            UpdateButton {}

        }

        RowLayout {
            id: center

            anchors.horizontalCenter: parent.horizontalCenter

            Notch {
                notifServer: notifDaemon
            }
        }

        RowLayout {
            id: right

            anchors {
                right: parent.right
            }
            PowerProfiles{}
            Item { Layout.fillWidth: true }
            System {}
        }
    }

    PanelWindow {
        id: sideBar

        anchors {
            right: true
            top: true
            bottom: true
        }

        mask: Region {
            item: controlCenter
        }

        color: "transparent"
        implicitWidth: 500
        exclusiveZone: Variables.exclusiveZoneSide
        WlrLayershell.layer: Variables.wallpaperPicker ? WlrLayer.Overlay : WlrLayer.Top

        ControlCenter{
            id: controlCenter
            notifServer: notifDaemon
        }
    }

    PanelWindow {
        id: wallpaperPickerWindow

        visible: Variables.wallpaperPreview

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        color: "transparent"

        HyprlandFocusGrab {
            active: Variables.wallpaperPicker
            windows: [ wallpaperPickerWindow ] 
        }

        IpcHandler {
            target: "wallpaper"

            function toggle(): void {
                if (Variables.wallpaperPicker) {
                    Variables.wallpaperPicker = !Variables.wallpaperPicker
                    Variables.wallpaperPreview = !Variables.wallpaperPreview
                }
                else {
                    Variables.wallpaperPreview = !Variables.wallpaperPreview
                    wallpaperTimer.start()
                }
            }
        }

        mask: Region { item: wallpaperSwitcher }

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
                }

                NumberAnimation on opacity {
                    id: crossfadeAnim; to: 1.0; duration: Variables.fadeAnimation
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
        }

        Timer {
            id: wallpaperTimer

            interval: Variables.animationDurationUI
            running: false
            repeat: false
            triggeredOnStart: false
            onTriggered: Variables.wallpaperPicker = true
        }

        WallpaperPicker {
            id: wallpaperSwitcher

            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
