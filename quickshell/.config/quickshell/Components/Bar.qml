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
    }
    
    PanelWindow {
        id: exclusiveZoneReserve
        anchors {
            top: true
            left: true
            right: true
        }
        color: "transparent"
        implicitHeight: 0
        exclusiveZone: Variables.focused ? 0 : Variables.exclusiveZoneTop + Variables.borderWidth * 4
        mask: Region {}
    }

    PanelWindow {
        id: unifiedPanel 

        HyprlandFocusGrab {
            active: Variables.powerMenu || Variables.wallpaperPicker
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
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        
        exclusionMode: ExclusionMode.Ignore 

        mask: Region {
            item: left
            Region { item: center }
            Region { item: right }
            Region { item: controlCenter }
            Region { item: wallpaperSwitcher }
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

        IpcHandler {
            target: "wallpaper"

            function toggle(): void {
                if (Variables.wallpaperPicker) {
                    Variables.wallpaperPicker = false;
                    closeWallpaperTimer.start();
                }
                else {
                    Variables.wallpaperPreview = true;
                    Variables.wallpaperPicker = true; 
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

        Item {
            anchors.fill: parent
            visible: Variables.wallpaperPreview

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

                readonly property real bw: Variables.borderWidth * 4
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

            RowLayout {
                id: left
                anchors { left: parent.left; top: parent.top }
                spacing: Variables.spacing

                Workspaces {}
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

                PowerProfiles{}
                Item { Layout.fillWidth: true }
                System {}
            }

            ControlCenter {
                id: controlCenter
                notifServer: notifDaemon
                anchors {
                    right: parent.right
                }
                implicitWidth: 500
            }

            WallpaperPicker {
                id: wallpaperSwitcher
                visible: Variables.wallpaperPreview
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    PanelWindow {
        id: activateLinux

        implicitHeight: watermark.implicitHeight + Variables.borderWidth * 12
        implicitWidth: watermark.implicitWidth + Variables.borderWidth * 12

        visible: Variables.activateLinux
        color: "transparent"

        anchors {
            bottom: true
            right: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        ActivateLinux{
            id: watermark

            anchors {
                top: parent.top
                left: parent.left
            }
        }
    }
}