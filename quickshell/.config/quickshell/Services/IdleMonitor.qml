import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../"

Scope {
    IdleMonitor {
        id: lockMonitor

        timeout: Variables.idleLockTime
        respectInhibitors: true
        enabled: Variables.idleMonitor

        onIsIdleChanged: {
            if (isIdle) lockProcess.running = true
        }
    }

    IdleMonitor {
        id: sleepMonitor

        timeout: Variables.idleSleepTime
        respectInhibitors: true
        enabled: Variables.idleMonitor

        onIsIdleChanged: {
            if (isIdle) sleepProcess.running = true
        }
    }

    Process {
        id: lockProcess

        command: ["qs", "ipc", "call", "PC", "lock"]
    }

    Process {
        id: sleepProcess

        command: ["systemctl", "suspend"]
    }
}