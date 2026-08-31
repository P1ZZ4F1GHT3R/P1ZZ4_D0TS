import QtQuick
import "../"

Text {
    id: clockItem

    property bool showSeconds: true
    property string format: "HH:mm"

    function formatPomodoro(seconds) {
        let m = Math.floor(seconds / 60)
        let s = seconds % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    function updateText() {
        if (Variables.pomodoroIsRunning) {
            clockItem.text = formatPomodoro(Variables.pomodoroTimeLeft)
        } else {
            clockItem.text = new Date().toLocaleTimeString(
                Qt.locale(), 
                clockItem.showSeconds ? clockItem.format + ":ss" : clockItem.format
            )
        }
    }

    font.pixelSize: Variables.fontSize
    color: Variables.textColor
    opacity: mprisWidget.activePlayer && Variables.expandedState || Variables.powerMenu || Variables.notifWidget ? 0.0 : 1.0

    Behavior on opacity {
        NumberAnimation { duration: 200 }
    } 

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clockItem.updateText()
    }

    Connections {
        target: Variables
        function onPomodoroIsRunningChanged() { clockItem.updateText() }
    }
}