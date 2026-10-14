import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"

PanelWindow {
    id: snipOverlay
    
    anchors { top: true; bottom: true; left: true; right: true }
    color: "#33ffffff" 

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    property real startX: 0
    property real startY: 0
    property bool isSelecting: false

    Rectangle { id: horizontalLine; color: "#ffffff"; height: 1; width: parent.width; y: mouseArea.mouseY; visible: !isSelecting }
    Rectangle { id: verticalLine; color: "#ffffff"; width: 1; height: parent.height; x: mouseArea.mouseX; visible: !isSelecting }

    Rectangle {
        visible: isSelecting
        color: "#44000000"
        border.color: "#ffffff"
        border.width: 1
        x: Math.min(startX, mouseArea.mouseX)
        y: Math.min(startY, mouseArea.mouseY)
        width: Math.abs(mouseArea.mouseX - startX)
        height: Math.abs(mouseArea.mouseY - startY)
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.CrossCursor

        onPressed: (mouse) => {
            startX = mouse.x
            startY = mouse.y
            isSelecting = true
        }

        onReleased: (mouse) => {
            isSelecting = false
            
            let rawW = Math.abs(mouse.x - startX)
            let rawH = Math.abs(mouse.y - startY)

            if (rawW < 5 || rawH < 5) {
                Variables.snippingMode = false
                return
            }

            let offsetX = snipOverlay.screen ? snipOverlay.screen.x : 0
            let offsetY = snipOverlay.screen ? snipOverlay.screen.y : 0

            let rx = Math.round(offsetX + Math.min(startX, mouse.x))
            let ry = Math.round(offsetY + Math.min(startY, mouse.y))
            let rw = Math.round(rawW)
            let rh = Math.round(rawH)

            let geometry = rx + "," + ry + " " + rw + "x" + rh
            let action = Variables.captureAction
            let scriptPath = Quickshell.env("HOME") + "/.config/scripts/utils/capture.sh"

            snipOverlay.visible = false

            delayTimer.action = action
            delayTimer.scriptPath = scriptPath
            delayTimer.geometry = geometry
            delayTimer.start()
        }
    }

    Timer {
        id: delayTimer
        interval: 150
        repeat: false
        property string action: ""
        property string scriptPath: ""
        property string geometry: ""
        onTriggered: {
            Quickshell.execDetached(["/bin/bash", scriptPath, action, geometry])
            Variables.snippingMode = false
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: Variables.snippingMode = false
    }
}