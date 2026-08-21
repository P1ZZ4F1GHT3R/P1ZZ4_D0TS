import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick.Shapes
import "../../"

Rectangle {
    id: system

    Layout.alignment: Qt.AlignTop
    implicitHeight: rowLayout.implicitHeight + Variables.height
    implicitWidth: Variables.systemHidden ? 0 : rowLayout.implicitWidth + Variables.width
    color: Variables.uiColor
    topLeftRadius: 0
    topRightRadius: 0
    bottomLeftRadius: Variables.radius
    bottomRightRadius: 0
    //border.color: Variables.borderColor
    //border.width: Variables.borderWidth

    property string cpuUsage: "0%"
    property string ramUsage: "0%"
    property string diskUsage: "0 GB"

    
    Behavior on implicitWidth {
        NumberAnimation { id: widthAnim; duration: Variables.activeDurationUI; easing.type: Variables.activeAnimationUI}
    }


    Behavior on implicitHeight {
        NumberAnimation { duration: Variables.activeDurationUI; easing.type: Variables.activeAnimationUI}
    }

    Process {
        id: sysProc
            command: [
            "sh", "-c",
            "ram=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END {printf \"%d%%\", (1-a/t)*100}' /proc/meminfo); " +
            "read -r _ u1 n1 s1 i1 _ < /proc/stat; sleep 0.2; read -r _ u2 n2 s2 i2 _ < /proc/stat; " +
            "idle=$((i2 - i1)); total=$(( (u2+n2+s2+i2) - (u1+n1+s1+i1) )); " +
            "cpu=$(( (total - idle) * 100 / total )); " +
            "disk=$(df --output=avail -h / | tail -n 1 | tr -dc '0-9.'); " +
            "echo \"$cpu% $ram ${disk} GB\""
        ]

        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split(" ");
                if (parts.length === 4) {
                    system.cpuUsage = parts[0];
                    system.ramUsage = parts[1];
                    system.diskUsage = parts[2] + " " + parts[3];
                }
            }
        }
    }

    Shape {
        id: leftConcave
        
        readonly property real cornerSize: Math.max(0, Math.min(Variables.radius, Math.min(parent.width, parent.height)))
        visible: cornerSize > 0

        width: cornerSize
        height: cornerSize
        anchors.top: parent.top
        anchors.right: parent.left
        anchors.topMargin: Variables.borderWidth * 4

        ShapePath {
            fillColor: Variables.uiColor
            strokeWidth: 0

            PathMove { x: leftConcave.cornerSize; y: 0 }
            PathLine { x: leftConcave.cornerSize; y: leftConcave.cornerSize }
            PathArc {
                x: 0; y: 0
                radiusX: leftConcave.cornerSize
                radiusY: leftConcave.cornerSize
                direction: PathArc.Counterclockwise
            }
            PathLine { x: leftConcave.cornerSize; y: 0 }
        }
    }

    Shape {
        id: bottomRightConcave
        
        readonly property real cornerSize: Math.max(0, Math.min(Variables.radius, Math.min(parent.width, parent.height)))
        visible: cornerSize > 0

        width: cornerSize
        height: cornerSize
        anchors.top: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: Variables.borderWidth * 4

        ShapePath {
            fillColor: Variables.uiColor
            strokeWidth: 0

            PathMove { x: bottomRightConcave.cornerSize; y: 0 }
            PathLine { x: bottomRightConcave.cornerSize; y: bottomRightConcave.cornerSize }
            PathArc {
                x: 0; y: 0
                radiusX: bottomRightConcave.cornerSize
                radiusY: bottomRightConcave.cornerSize
                direction: PathArc.Counterclockwise
            }
            PathLine { x: bottomRightConcave.cornerSize; y: 0 }
        }
    }

    Timer {
        interval: Variables.systemPoll
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!sysProc.running) {
                sysProc.running = true;
            }
        }
    }

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: system.cpuUsage
            color: Variables.textColor
            font.pixelSize: Variables.fontSize
        }

        Text {
            text: "|"
            color: Variables.iconColor
            font.pixelSize: Variables.fontSize
        }

        Text {
            text: system.ramUsage
            color: Variables.textColor
            font.pixelSize: Variables.fontSize
        }

        Text {
            text: "|"
            color: Variables.iconColor
            font.pixelSize: Variables.fontSize
        }

        Text {
            text: system.diskUsage
            color: Variables.textColor
            font.pixelSize: Variables.fontSize
        }
    }
}