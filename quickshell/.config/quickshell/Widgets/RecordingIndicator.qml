import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../"

Rectangle {
    id: recordingIndicator

    implicitHeight: Variables.circleHeight / 3
    implicitWidth: Variables.circleWidth / 3
    color: Variables.iconColor
    radius: Variables.circleRadius / 3
}