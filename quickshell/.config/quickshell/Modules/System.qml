import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick.Shapes
import "../"

Rectangle {
    id: system

    Layout.alignment: Qt.AlignTop
    implicitHeight: rowLayout.implicitHeight + Variables.height + Variables.borderWidth * 4
    implicitWidth: Variables.systemHidden ? 0 : rowLayout.implicitWidth + Variables.width
    color: Variables.uiColor
    topLeftRadius: 0
    topRightRadius: 0
    bottomLeftRadius: Variables.radius
    bottomRightRadius: 0

    property string cpuUsage: "0%"
    property string ramUsage: "0%"
    property string diskUsage: "0 GB"
    property var previousCpu: null

    function refresh() {
        cpuFile.reload()
        memoryFile.reload()
        if (system.previousCpu === null)
            cpuWarmupTimer.restart()
    }

    function refreshDisk() {
        if (!diskProc.running)
            diskProc.running = true
    }

    function updateCpu() {
        const lines = String(cpuFile.text() || "").split("\n")
        let cpuLine = ""
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].indexOf("cpu ") === 0) {
                cpuLine = lines[i]
                break
            }
        }

        const fields = cpuLine.trim().split(/\s+/).slice(1).map(Number)
        if (fields.length < 4 || fields.some(value => !isFinite(value)))
            return

        const idle = fields[3]
        const total = fields[0] + fields[1] + fields[2] + fields[3]
        if (system.previousCpu !== null) {
            const idleDelta = idle - system.previousCpu.idle
            const totalDelta = total - system.previousCpu.total
            if (totalDelta > 0)
                system.cpuUsage = Math.round((totalDelta - idleDelta) * 100 / totalDelta) + "%"
        }
        system.previousCpu = { idle: idle, total: total }
    }

    function updateMemory() {
        const text = String(memoryFile.text() || "")
        const totalMatch = text.match(/^MemTotal:\s+(\d+)/m)
        const availableMatch = text.match(/^MemAvailable:\s+(\d+)/m)
        if (!totalMatch || !availableMatch)
            return

        const total = Number(totalMatch[1])
        const available = Number(availableMatch[1])
        if (total > 0)
            system.ramUsage = Math.round((1 - available / total) * 100) + "%"
    }

    
    Behavior on implicitWidth {
        NumberAnimation { id: widthAnim; duration: Variables.activeDurationUI; easing.type: Variables.activeAnimationUI}
    }


    Behavior on implicitHeight {
        NumberAnimation { duration: Variables.activeDurationUI; easing.type: Variables.activeAnimationUI}
    }

    FileView {
        id: cpuFile
        path: "/proc/stat"
        watchChanges: false
        onTextChanged: system.updateCpu()
    }

    FileView {
        id: memoryFile
        path: "/proc/meminfo"
        watchChanges: false
        onTextChanged: system.updateMemory()
    }

    Process {
        id: diskProc
        command: ["df", "--output=avail", "-h", "/"]

        stdout: SplitParser {
            onRead: data => {
                const value = String(data).trim().replace(/[^0-9.]/g, "")
                if (value !== "")
                    system.diskUsage = value + " GB"
            }
        }
    }

    Timer {
        id: cpuWarmupTimer
        interval: 250
        repeat: false
        onTriggered: system.refresh()
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
        running: !Variables.systemHidden && !Variables.lockScreen
        repeat: true
        triggeredOnStart: true
        onTriggered: system.refresh()
    }

    Timer {
        interval: 60000
        running: !Variables.systemHidden && !Variables.lockScreen
        repeat: true
        triggeredOnStart: true
        onTriggered: system.refreshDisk()
    }

    Connections {
        target: Variables

        function onSystemHiddenChanged() {
            if (!Variables.systemHidden) {
                system.refresh()
                system.refreshDisk()
            }
        }

        function onLockScreenChanged() {
            if (!Variables.lockScreen && !Variables.systemHidden) {
                system.refresh()
                system.refreshDisk()
            }
        }
    }

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: Variables.spacing
        visible: !Variables.systemHidden

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
