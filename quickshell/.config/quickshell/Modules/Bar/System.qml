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
    implicitWidth: rowLayout.implicitWidth + Variables.width
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
        NumberAnimation { id: widthAnim; duration: Variables.animationDurationUI; easing.type: Variables.animationTypeUI}
    }

    Behavior on implicitHeight {
        NumberAnimation { duration: Variables.animationDurationUI; easing.type: Variables.animationTypeUI}
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

        width: Variables.radius
        height: Variables.radius
        anchors.top: parent.top
        anchors.right: parent.left

        ShapePath {
            fillColor: Variables.uiColor
            strokeWidth: 0

            PathMove { x: Variables.radius; y: 0 }
            PathLine { x: Variables.radius; y: Variables.radius }
            PathArc {
                x: 0; y: 0
                radiusX: Variables.radius
                radiusY: Variables.radius
                direction: PathArc.Counterclockwise
            }
            PathLine { x: Variables.radius; y: 0 }
        }
    }

    Shape {
        width: Variables.radius
        height: Variables.radius
        anchors.top: parent.bottom
        anchors.right: parent.right

        ShapePath {
            fillColor: Variables.uiColor
            strokeWidth: 0

            PathMove { x: Variables.radius; y: 0 }
            PathLine { x: Variables.radius; y: Variables.radius }
            PathArc {
                x: 0; y: 0
                radiusX: Variables.radius
                radiusY: Variables.radius
                direction: PathArc.Counterclockwise
            }
            PathLine { x: Variables.radius; y: 0 }
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