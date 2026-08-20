import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Io
import Quickshell.Widgets
import QtQuick.Effects
import QtQuick.Shapes
import "../"

Scope {
    id: lockScreen

    property url currentWallpaper: ""
    readonly property string txtDir: Quickshell.env("HOME") + "/.config/wallpaper/wallpaper.txt"

    Process {
        id: imagePath
        command: ["cat", txtDir]
        running: true 
        
        stdout: StdioCollector {
            onStreamFinished: {
                lockScreen.currentWallpaper = "file://" + this.text.trim();
            }
        }
    }

    IpcHandler {
        target: "PC" 
        function lock(): void {
            sessionLock.locked = true;
            Variables.lockScreen = true;
            Variables.expandedState = false;
            pam.start();
        }
    }

    PamContext {
        id: pam
        config: "quickshell_pam"

        onCompleted: (result) => {
            if (result === PamResult.Success) {
                sessionLock.locked = false; 
                Variables.lockScreen = false;
            } else {
                pam.start(); 
            }
        }
    }

    

    WlSessionLock {
        id: sessionLock
        locked: false

        WlSessionLockSurface {
            Rectangle {
                id: rectangle

                anchors.fill: parent

                Image{
                    id: lockscreenBackground

                    anchors.fill: parent
                    visible: true
                    source: lockScreen.currentWallpaper
                }

                MultiEffect {
                    anchors.fill: rectangle
                    source: lockscreenBackground

                    blurEnabled: true
                    blurMax: 64
                    blur: 1.0
                }
                Rectangle {
                    id: clockRectangle

                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -100

                    implicitWidth: clockColumn.implicitWidth + (Variables.spacing * 4)
                    implicitHeight: clockColumn.implicitHeight + (Variables.spacing * 4)

                    color: Variables.uiColor
                    radius: Variables.radius
                    opacity: 0.5

                    Column {
                        id: clockColumn

                        anchors.centerIn: parent
                        spacing: Variables.spacing
                        opacity: 1.0

                        Text {
                            id: timeDisplay
                            anchors.horizontalCenter: parent.horizontalCenter
                            
                            text: Qt.formatTime(new Date(), "hh:mm") 
                            
                            color: Variables.lockscreenColor
                            font.pixelSize: Variables.fontSize * 6
                            font.weight: Font.Bold
                        }

                        Text {
                            id: dateDisplay
                            anchors.horizontalCenter: parent.horizontalCenter
                            
                            text: Qt.formatDate(new Date(), "dddd, d MMMM") 
                            
                            color: Variables.lockscreenColor
                            font.pixelSize: Variables.fontSize * 2
                        }

                        Timer {
                            interval: 1000 
                            running: true
                            repeat: true
                            onTriggered: {
                                timeDisplay.text = Qt.formatTime(new Date(), "hh:mm");
                                dateDisplay.text = Qt.formatDate(new Date(), "dddd, d MMMM");
                            }
                        }
                    }
                }
                
                Rectangle{
                    id: inputHolder

                    anchors{
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                    }

                    implicitHeight: Variables.lockScreen ? rectangle.height / 12.5 : 0
                    implicitWidth: rectangle.width / 7
                    color: Variables.uiColor
                    topLeftRadius: Variables.radius
                    topRightRadius: Variables.radius

                    Shape {
                        id: bottomLeftConcave

                        width: Variables.radius
                        height: Variables.radius
                        anchors.bottom: parent.bottom
                        anchors.right: parent.left

                        ShapePath {
                            fillColor: Variables.uiColor
                            strokeWidth: 0

                            PathMove { x: Variables.radius; y: Variables.radius }
                            
                            PathLine { x: 0; y: Variables.radius }

                            PathArc {
                                x: Variables.radius; y: 0
                                radiusX: Variables.radius
                                radiusY: Variables.radius
                                direction: PathArc.Counterclockwise
                            }
                            
                            PathLine { x: Variables.radius; y: Variables.radius }
                        }
                    }

                    Shape {
                        id: bottomRightConcave

                        width: Variables.radius
                        height: Variables.radius
                        anchors.bottom: parent.bottom
                        anchors.left: parent.right

                        ShapePath {
                            fillColor: Variables.uiColor
                            strokeWidth: 0

                            PathMove { x: 0; y: Variables.radius }
                            
                            PathLine { x: Variables.radius; y: Variables.radius }
                            
                            PathArc {
                                x: 0; y: 0
                                radiusX: Variables.radius
                                radiusY: Variables.radius
                                direction: PathArc.Clockwise
                            }
                            
                            PathLine { x: 0; y: Variables.radius }
                        }
                    }

                    Behavior on implicitHeight {
                        NumberAnimation { duration: Variables.bouncingDurationUI; easing.type: Variables.bouncingAnimationUI}
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: Variables.spacing

                        TextField {
                            id: passwordInput
                            anchors.centerIn: parent

                            echoMode: TextInput.Password
                            focus: true
                            color: Variables.uiColor

                            background: Rectangle {
                                implicitHeight: inputHolder.implicitHeight / 2
                                implicitWidth: inputHolder.implicitWidth / 1.2
                                color: Variables.lockscreenColor
                                radius: Variables.radius
                            }
                            
                            onAccepted: {
                                if (pam.responseRequired) {
                                    pam.respond(passwordInput.text);
                                    passwordInput.text = ""; 
                                }
                            }
                        }
                    }
                }
            }
        }
    } 
}
