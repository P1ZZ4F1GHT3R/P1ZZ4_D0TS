import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import QtQuick.Controls
import "../"

Rectangle {
    id: pomodoroWidget

    implicitWidth: 216
    implicitHeight: 256 
    
    color: Variables.backgroundColorUI
    radius: Variables.radius
    border.color: Variables.borderColor
    border.width: Variables.borderWidth

    function formatTime(seconds) {
        let m = Math.floor(seconds / 60)
        let s = seconds % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    function sendNotification(title, body) {
        timerNotification.command = [
            "notify-send",
            "--app-name=Pomodoro Timer",
            "--icon=preferences-system-time",
            title,
            body
        ]
        timerNotification.running = true
    }

    function updateFocusState() {
        if (Variables.pomodoroIsRunning && !Variables.pomodoroIsBreak) {
            Variables.workspacesHidden = true
            Variables.systemHidden = true
            Variables.pomodoroClock = true
        } else {
            Variables.workspacesHidden = false
            Variables.systemHidden = false
            Variables.pomodoroClock = false
        }
    }

    Connections {
        target: Variables
        function onPomodoroIsRunningChanged() { pomodoroWidget.updateFocusState() }
        function onPomodoroIsBreakChanged() { pomodoroWidget.updateFocusState() }
    }

    Process {
        id: timerNotification
        command: []
    }

    Timer {
        id: countdown
        interval: 1000
        running: Variables.pomodoroIsRunning
        repeat: true
        onTriggered: {
            if (Variables.pomodoroTimeLeft > 0) {
                Variables.pomodoroTimeLeft -= 1
            } else {
                Variables.pomodoroIsBreak = !Variables.pomodoroIsBreak;
                
                if (Variables.pomodoroIsBreak) {
                    Variables.pomodoroTimeLeft = Variables.breakTime;
                    pomodoroWidget.sendNotification("Timer Complete", "Time is up! Take a break.");
                } else {
                    Variables.pomodoroTimeLeft = Variables.pomodoroTime;
                    pomodoroWidget.sendNotification("Break Complete", "Break is over! Time to focus.");
                }
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Variables.spacing

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Variables.pomodoroIsBreak ? "Break" : "Focus"
            color: Variables.textColor
            font.pixelSize: Variables.fontSize * 1.5
            opacity: 0.7 
        }

        Text {
            id: timeText
            Layout.alignment: Qt.AlignHCenter
            text: pomodoroWidget.formatTime(Variables.pomodoroTimeLeft)
            color: Variables.textColor
            font.pixelSize: Variables.fontSize * 3
            font.bold: true
        }

        RowLayout {
            id: buttonRow

            Layout.alignment: Qt.AlignHCenter
            spacing: Variables.spacing * 2

            Button {
                id: playPause

                contentItem: Text {
                    text: Variables.pomodoroIsRunning ? "" : ""
                    font.pixelSize: Variables.fontSize * 1.5
                    color: Variables.textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    implicitWidth: Variables.circleWidth * 2
                    implicitHeight: Variables.circleHeight * 2
                    radius: Variables.circleRadius * 2
                    color: Variables.uiColor
                    border.color: Variables.textColor
                    opacity: parent.down ? 0.85 : 1.0
                }

                onClicked: {
                    Variables.pomodoroIsRunning = !Variables.pomodoroIsRunning
                    }
            }

            Button {
                id: reset

                contentItem: Text {
                    text: ""
                    font.pixelSize: Variables.fontSize * 1.5
                    color: Variables.textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    implicitWidth: Variables.circleWidth * 2
                    implicitHeight: Variables.circleHeight * 2
                    radius: Variables.circleRadius * 2
                    color: Variables.uiColor
                    border.color: Variables.textColor
                    opacity: parent.down ? 0.85 : 1.0
                }

                onClicked: {
                        Variables.pomodoroIsRunning = false
                        Variables.pomodoroIsBreak = false
                        Variables.pomodoroTimeLeft = Variables.pomodoroTime
                    }
            }
        }
    }
}