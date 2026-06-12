pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string scriptPath: Quickshell.env("HOME") + "/.config/scripts/system/package-updates.sh"

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
    }

    Timer {
        interval: 3000
        running: true
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        interval: 900000
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
