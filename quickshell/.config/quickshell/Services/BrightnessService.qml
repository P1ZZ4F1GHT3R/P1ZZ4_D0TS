pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    
    property real level: 0.0
    property real _maxLevel: 1.0

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
    }

    function setBrightness(percent) {
        let safePercent = Math.max(0.02, Math.min(1.0, percent))
        let stringPercent = Math.round(safePercent * 100) + "%"
        
        setProcess.command = ["brightnessctl", "set", stringPercent]
        setProcess.running = true
        root.level = safePercent 
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            if (root._maxLevel > 1.0) {
                currentProcess.running = true 
            }
        }
    }
}