import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"

RowLayout {
    id: captureScope

    spacing: Variables.spacing * 8
    focus: true
    Component.onCompleted: forceActiveFocus()

    property int selectedIndex: 0

    Keys.onLeftPressed: {
        if (selectedIndex > 0) selectedIndex--
        else selectedIndex = repeater.count - 1
    }
    Keys.onRightPressed: {
        if (selectedIndex < repeater.count - 1) selectedIndex++
        else selectedIndex = 0
    }
    Keys.onReturnPressed: triggerSelected()
    Keys.onEnterPressed: triggerSelected()
    
    Keys.onEscapePressed: Variables.toolBar = false

    function triggerSelected() {
        let currentAction = repeater.model[selectedIndex].action
        exec(currentAction)
    }

    function exec(action) {
        if (action === "screenshot" || action === "ocr" || action === "lens") {
            Variables.captureAction = action
            Variables.snippingMode = true
            Variables.toolBar = false
        } else {
            let scriptPath = Quickshell.env("HOME") + "/.config/scripts/utils/capture.sh"
            Quickshell.execDetached(["/bin/bash", scriptPath, action])
            
            if (action === "record") {
                Variables.isRecording = !Variables.isRecording
            }

            Variables.toolBar = false
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            recChecker.running = false
            recChecker.running = true
        }
    }

    Repeater {
        id: repeater

        model: [
            { icon: "󱣴", action: "screenshot" },
            { icon: "󰕨", action: "record" }, 
            { icon: "󱄺", action: "ocr" },
            { icon: "󰴱", action: "colorpicker" },
            { icon: "", action: "lens" }
        ]

        Rectangle {
            Layout.preferredWidth: iconText.implicitWidth + Variables.height / 4 * 5
            Layout.preferredHeight: iconText.implicitHeight + Variables.height / 8 * 5
            radius: Variables.radius
            color: captureScope.selectedIndex === index ? Variables.borderColor : "transparent"
            border.color: captureScope.selectedIndex === index ? Variables.iconColor : "transparent"
            border.width: Variables.borderWidth

            Behavior on color { ColorAnimation { duration: Variables.fadeAnimation } }
            Behavior on border.color { ColorAnimation { duration: Variables.fadeAnimation } }

            Text {
                id: iconText

                text: modelData.action === "record" ? (Variables.isRecording ? "󰕨" : "󰯜") : modelData.icon
                font.pixelSize: Variables.fontSize * 2
                color: Variables.iconColor
                anchors.centerIn: parent
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onEntered: captureScope.selectedIndex = index
                onClicked: captureScope.exec(modelData.action)
            }
        }
    }
}