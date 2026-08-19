import QtQuick
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: root

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/scripts/system/package-updates.sh"

    Process {
    id: notifyProc
    }

    property int count: 0
    property string tooltip: "Checking package updates..."
    property string cssClass: "transparent"
    property bool isChecking: false
    property bool hasError: false
    property string lastError: ""

    function refresh() {
        if (checkProcess.running)
            return;

        root.isChecking = true;
        root.hasError = false;
        root.lastError = "";
        checkProcess.running = true;
    }

    function applyResult(rawText, exitCode) {
        const raw = (rawText || "").trim();
        root.isChecking = false;

        if (raw.length === 0) {
            root.hasError = true;
            root.lastError = "No update data returned";
            root.tooltip = "Package update check failed";
            root.cssClass = "transparent";
            return;
        }

        try {
            const data = JSON.parse(raw.split("\n").pop());
            root.count = parseInt(data.text || "0", 10) || 0;
            root.tooltip = data.tooltip || (root.count + " packages require updates");
            root.cssClass = data.class || "transparent";
            root.hasError = exitCode !== 0;
        } catch (e) {
            root.hasError = true;
            root.lastError = String(e);
            root.tooltip = "Package update check failed";
            root.cssClass = "transparent";
            console.warn("[PackageUpdateService] Failed to parse output:", raw, e);
        }

        if (root.count >= Variables.updateTreshold) {
        notifyProc.command = [
            "notify-send", 
            "System Updates", 
            root.count + " packages are ready to update", 
            "--app-name= " + Quickshell.env("USER"), 
            "--icon=update-medium"
        ];
        notifyProc.running = true;
        }
    }

    Timer {
        id: startTimer
        interval: Variables.updateNotifStart
        running: true
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        interval: Variables.updateNotifRunning
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: checkProcess
        running: false
        command: ["bash", "-lc", root.scriptPath]

        stdout: StdioCollector {
            id: stdoutCollector
        }

        stderr: StdioCollector {
            id: stderrCollector
        }

        onExited: exitCode => {
            root.applyResult(stdoutCollector.text, exitCode);
            if (exitCode !== 0 && stderrCollector.text.trim().length > 0) {
                root.lastError = stderrCollector.text.trim();
                console.warn("[PackageUpdateService]", root.lastError);
            }
        }
    }
}