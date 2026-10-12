pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: root
    
    property real level: 0.0
    property real _maxLevel: 1.0
    property real _pendingLevel: -1.0

    Process {
        id: maxProcess
        command: ["brightnessctl", "max"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let maxVal = parseFloat(this.text.trim())
                if (!isNaN(maxVal) && maxVal > 0) {
                    root._maxLevel = maxVal
                    currentProcess.running = true
                }
            }
        }
    }

    Process {
        id: currentProcess
        command: ["brightnessctl", "get"]
        running: false 
        stdout: StdioCollector {
            onStreamFinished: {
                let currentVal = parseFloat(this.text.trim())
                if (!isNaN(currentVal)) {
                    root.level = currentVal / root._maxLevel
                }
            }
        }
    }

    Process {
        id: setProcess
        command: []
        running: false

        onExited: {
            if (root._pendingLevel >= 0)
                setTimer.restart()
        }
    }

    function setBrightness(percent) {
        let safePercent = Math.max(0.02, Math.min(1.0, percent))
        root._pendingLevel = safePercent
        root.level = safePercent
        setTimer.restart()
    }

    Timer {
        id: setTimer
        interval: 40
        repeat: false
        onTriggered: {
            if (setProcess.running) {
                setTimer.restart()
                return
            }

            if (root._pendingLevel < 0)
                return

            const pending = root._pendingLevel
            root._pendingLevel = -1.0
            setProcess.command = ["brightnessctl", "set", Math.round(pending * 100) + "%"]
            setProcess.running = true
        }
    }

    Timer {
        interval: Variables.brightnessPoll
        running: !Variables.lockScreen
        repeat: true
        onTriggered: if (root._maxLevel > 1.0 && !currentProcess.running)
            currentProcess.running = true
    }

    Connections {
        target: Variables

        function onLockScreenChanged() {
            if (!Variables.lockScreen && root._maxLevel > 1.0)
                currentProcess.running = true
        }
    }
}
