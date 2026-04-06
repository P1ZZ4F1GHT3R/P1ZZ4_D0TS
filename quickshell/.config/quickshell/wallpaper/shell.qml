import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "qml"
import "qml/services"

ShellRoot {
    id: root

    property bool configLoaded: Config.configLoaded
    onConfigLoadedChanged: {
        if (configLoaded) {
            Qt.callLater(function() {
                root._beginSelectorTiming()
                wallpaperSelectorLoader.active = true
            })
        }
    }

    property double selectorOpenRequestedMs: 0
    property bool selectorTimingPending: false
    property string selectorTimingLogFile: Config.cacheDir + "/wallpaper/selector-timing.log"
    property var _timingLogQueue: []

    function _enqueueTimingLine(message) {
        root._timingLogQueue.push(Date.now() + " " + message)
        root._flushTimingLogQueue()
    }

    function _flushTimingLogQueue() {
        if (_timingLogProcess.running || _timingLogQueue.length === 0)
            return

        var line = _timingLogQueue.shift()
        _timingLogProcess.command = [
            "bash", "-lc",
            "mkdir -p " + JSON.stringify(Config.cacheDir + "/wallpaper")
                + " && printf '%s\\n' " + JSON.stringify(line)
                + " >> " + JSON.stringify(selectorTimingLogFile)
        ]
        _timingLogProcess.running = true
    }

    function _beginSelectorTiming() {
        root.selectorOpenRequestedMs = Date.now()
        root.selectorTimingPending = true
        console.log("wallpaper-selector timing: open requested")
        root._enqueueTimingLine("wallpaper-selector timing: open requested")
    }

    Colors {
        id: colors
    }

    Loader {
        id: wallpaperSelectorLoader
        active: false
        source: "qml/wallpaper/WallpaperSelector.qml"
        onLoaded: {
            if (root.selectorTimingPending) {
                var qmlLoadMs = Date.now() - root.selectorOpenRequestedMs
                var qmlLoadMessage = "wallpaper-selector timing: qml loaded in " + qmlLoadMs + " ms"
                console.log(qmlLoadMessage)
                root._enqueueTimingLine(qmlLoadMessage)
            }
            item.colors = Qt.binding(() => colors)
            item.showing = true
            item.uiReady.connect(function() {
                if (!root.selectorTimingPending) return
                var elapsed = Date.now() - root.selectorOpenRequestedMs
                var count = item.selectorService ? item.selectorService.filteredModel.count : 0
                var readyMessage = "wallpaper-selector timing: ready in " + elapsed + " ms (items: " + count + ")"
                console.log(readyMessage)
                root._enqueueTimingLine(readyMessage)
                root.selectorTimingPending = false
            })
        }
    }

    property var _timingLogProcess: Process {
        id: timingLogProcess
        command: ["bash", "-lc", "true"]
        onExited: root._flushTimingLogQueue()
    }

    Connections {
        target: wallpaperSelectorLoader.item
        function onShowingChanged() {
            if (!wallpaperSelectorLoader.item) return
            if (!wallpaperSelectorLoader.item.showing)
                Qt.quit()
        }
    }

    IpcHandler {
        target: "wallpaper-ui"

        function refresh() {
            if (wallpaperSelectorLoader.item && wallpaperSelectorLoader.item.selectorService)
                wallpaperSelectorLoader.item.selectorService.refreshFromDb()
        }
    }
}
