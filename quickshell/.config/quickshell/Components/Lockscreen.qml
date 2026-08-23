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
import "../Components"

Scope {
    id: lockScreen
    
    property real screenOpacity: 1.0
    property url currentWallpaper: ""
    readonly property string txtDir: Quickshell.env("HOME") + "/.config/wallpaper/wallpaper.txt"
    property bool wait: false

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

    SequentialAnimation {
        id: lockAnimation

        ScriptAction {
            script: {
                Variables.lockScreen = true; 
                lockScreen.screenOpacity = 1.0;
                Variables.expandedState = false;
                wait = false;
            }
        }

        PauseAnimation { duration: Variables.pauseDuration}

        ScriptAction {
            script: {
                sessionLock.locked = true; 
                pam.start();
            }
        }

        PauseAnimation { duration: Variables.pauseDuration}

        NumberAnimation {
            target: lockScreen
            property: "screenOpacity"
            to: 0.0
            duration: 200
            easing.type: Variables.fadeAnimation
        }
    }

   SequentialAnimation {
        id: unlockAnimation
        
        ScriptAction {
            script: {
                Variables.lockScreen = false; 
            }
        }

        PauseAnimation { duration: Variables.pauseDuration } 

        NumberAnimation {
            target: lockScreen
            property: "screenOpacity"
            to: 1.0
            duration: 200
            easing.type: Variables.fadeAnimation
        }

        ScriptAction {
            script: {
                sessionLock.locked = false; 
            }
        }
    }

    IpcHandler {
        target: "PC" 
        function lock(): void {
            lockAnimation.start();
        }
    }

    Timer {
        id: waitTimer
        interval: 69 //heh nice
        repeat: false
        running: false
        onTriggered: {
            pam.start();
            wait = false;
            passwordInput.forceActiveFocus();
        }
    }

    PamContext {
        id: pam
        config: "quickshell_pam"

        onCompleted: (result) => {
            if (result === PamResult.Success) {
                unlockAnimation.start();
            } else {
                waitTimer.start();
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
                        bottomMargin: Variables.borderWidth * 4
                    }

                    implicitHeight: Variables.lockScreen ? rectangle.height / 12.5 : 0
                    implicitWidth: rectangle.width / 7
                    color: Variables.uiColor
                    topLeftRadius: Variables.radius
                    topRightRadius: Variables.radius

                    Shape {
                        id: bottomLeftConcave
                        
                        readonly property real cornerSize: Math.max(0, Math.min(Variables.radius, Math.min(parent.width, parent.height)))
                        visible: cornerSize > 0

                        width: cornerSize
                        height: cornerSize
                        anchors.bottom: parent.bottom
                        anchors.right: parent.left

                        ShapePath {
                            fillColor: Variables.uiColor
                            strokeWidth: 0

                            PathMove { x: bottomLeftConcave.cornerSize; y: bottomLeftConcave.cornerSize }
                            PathLine { x: 0; y: bottomLeftConcave.cornerSize }
                            PathArc {
                                x: bottomLeftConcave.cornerSize; y: 0
                                radiusX: bottomLeftConcave.cornerSize
                                radiusY: bottomLeftConcave.cornerSize
                                direction: PathArc.Counterclockwise
                            }
                            PathLine { x: bottomLeftConcave.cornerSize; y: bottomLeftConcave.cornerSize }
                        }
                    }

                    Shape {
                        id: bottomRightConcave
                        
                        readonly property real cornerSize: Math.max(0, Math.min(Variables.radius, Math.min(parent.width, parent.height)))
                        visible: cornerSize > 0

                        width: cornerSize
                        height: cornerSize
                        anchors.bottom: parent.bottom
                        anchors.left: parent.right

                        ShapePath {
                            fillColor: Variables.uiColor
                            strokeWidth: 0

                            PathMove { x: 0; y: bottomRightConcave.cornerSize }
                            PathLine { x: bottomRightConcave.cornerSize; y: bottomRightConcave.cornerSize }
                            PathArc {
                                x: 0; y: 0
                                radiusX: bottomRightConcave.cornerSize
                                radiusY: bottomRightConcave.cornerSize
                                direction: PathArc.Clockwise
                            }
                            PathLine { x: 0; y: bottomRightConcave.cornerSize }
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

                            enabled: !wait

                            width: inputHolder.implicitWidth / 1.2
                            height: inputHolder.implicitHeight / 2

                            echoMode: TextInput.Normal
                            focus: true
                            color: Variables.uiColor
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter

                            font.pixelSize: Variables.fontSize

                            property string realPassword: ""
                            property var symbolPool: Variables.oneZero

                            onTextEdited: {
                            if (text.length < realPassword.length) {
                                realPassword = realPassword.substring(0, text.length);
                            } else if (text.length > realPassword.length) {
                                let newChars = text.substring(realPassword.length);
                                realPassword += newChars;
                                
                                let updatedMask = text.substring(0, text.length - newChars.length);
                                
                                for (let i = 0; i < newChars.length; i++) {
                                    let randomIndex = Math.floor(Math.random() * symbolPool.length);
                                    updatedMask += symbolPool[randomIndex];
                                }
                                
                                text = updatedMask;
                            }
                            
                            cursorPosition = text.length; 
                            }

                            background: Rectangle {
                                implicitHeight: inputHolder.implicitHeight / 2
                                implicitWidth: inputHolder.implicitWidth / 1.2
                                color: wait ? Variables.uiColor : Variables.lockscreenColor
                                radius: Variables.radius

                                Behavior on color{
                                    ColorAnimation {duration: Variables.animationDurationUI}

                                }
                            }
                            
                            onAccepted: {
                                if (pam.responseRequired) {
                                    wait = true;

                                    pam.respond(passwordInput.realPassword);
                                    
                                    passwordInput.realPassword = "";
                                    passwordInput.text = ""; 
                                }
                            }

                            Text{ 
                                anchors {
                                    verticalCenter: parent.verticalCenter
                                    left: parent.left
                                    leftMargin: Variables.leftMargin
                                }
                                text: "Arch, btw"
                                color: Variables.uiColor
                                visible: passwordInput.realPassword.length === 0
                            }
                        }
                    }
                }
                Shape {
                    id: screenBorder
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
                        PathLine { x: screenBorder.width; y: 0 }
                        PathLine { x: screenBorder.width; y: screenBorder.height }
                        PathLine { x: 0; y: screenBorder.height }
                        PathLine { x: 0; y: 0 }

                        PathMove { x: screenBorder.bw + screenBorder.r; y: screenBorder.bw }
                        PathLine { x: screenBorder.width - screenBorder.bw - screenBorder.r; y: screenBorder.bw }
                        PathArc { x: screenBorder.width - screenBorder.bw; y: screenBorder.bw + screenBorder.r; radiusX: screenBorder.r; radiusY: screenBorder.r }
                        PathLine { x: screenBorder.width - screenBorder.bw; y: screenBorder.height - screenBorder.bw - screenBorder.r }
                        PathArc { x: screenBorder.width - screenBorder.bw - screenBorder.r; y: screenBorder.height - screenBorder.bw; radiusX: screenBorder.r; radiusY: screenBorder.r }
                        PathLine { x: screenBorder.bw + screenBorder.r; y: screenBorder.height - screenBorder.bw }
                        PathArc { x: screenBorder.bw; y: screenBorder.height - screenBorder.bw - screenBorder.r; radiusX: screenBorder.r; radiusY: screenBorder.r }
                        PathLine { x: screenBorder.bw; y: screenBorder.bw + screenBorder.r }
                        PathArc { x: screenBorder.bw + screenBorder.r; y: screenBorder.bw; radiusX: screenBorder.r; radiusY: screenBorder.r }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Variables.uiColor
                    opacity: lockScreen.screenOpacity
                }
            }
        }
    } 
}