import Quickshell
import Quickshell.Io
import QtQuick
import "qml"
import "qml/daemon-services"

ShellRoot {
    id: root

    property string _shellQmlPath: ""

    Component.onCompleted: _pathResolver.running = true

    Process {
        id: _pathResolver
        command: ["bash", "-c",
            "qml=$(tr '\\0' '\\n' < /proc/$PPID/cmdline | grep '\\.qml$' | head -1); " +
            "dir=$(dirname \"$(realpath \"$qml\")\"); " +
            "echo \"$dir/shell.qml\""
        ]
        stdout: SplitParser {
            onRead: data => root._shellQmlPath = data.trim()
        }
    }

    property bool bootstrapReady: BootstrapService.ready
    onBootstrapReadyChanged: if (bootstrapReady) WallpaperApplyService.restore()

    property bool _servicesStarted: false
    property bool configLoaded: Config.configLoaded
    onConfigLoadedChanged: {
        if (configLoaded && !_servicesStarted) {
            Qt.callLater(root._startServices)
        }
    }

    function _startServices() {
        if (_servicesStarted) return
        _servicesStarted = true
        WallpaperCacheService.rebuild()
        ImageOptimizeService.cleanTrash()
        VideoConvertService.cleanTrash()
    }

    Connections {
        target: WatcherService
        function onFileAdded(name, path, type) {
            WallpaperCacheService.processFiles([{name: name, src: path, type: type}])
        }
        function onFileRemoved(name, type) {
            WallpaperCacheService.removeFiles([{name: name, type: type}])
        }
        function onWeItemAdded(weId, weDir) {
            WallpaperCacheService.processWeItem(weId, weDir)
        }
        function onWeItemRemoved(weId) {
            WallpaperCacheService.removeFiles([{name: weId, type: "we"}])
        }
    }

    Connections {
        target: WallpaperCacheService
        function onCacheReady(result) {
            WatcherService.start()
            root._autoOptimizeTimer.restart()
        }
        function onFileProcessed(key, entry) {
            root._notifyUi()
            root._autoOptimizeTimer.restart()
        }
        function onFileRemoved(key) {
            root._notifyUi()
        }
    }

    Connections {
        target: ImageOptimizeService
        function onFinished(optimized, skippedCount, failed) {
            if (optimized > 0) root._notifyUi()
        }
    }

    property var _uiNotifyTimer: Timer {
        interval: 500
        onTriggered: root._sendUiRefresh()
    }

    function _notifyUi() {
        if (uiProcess.running)
            _uiNotifyTimer.restart()
    }

    property var _uiIpcProc: Process {}

    function _sendUiRefresh() {
        if (!uiProcess.running || !_shellQmlPath) return
        _uiIpcProc.command = ["quickshell", "ipc", "-p", _shellQmlPath, "call", "wallpaper-ui", "refresh"]
        _uiIpcProc.running = true
    }

    property var _autoOptimizeTimer: Timer {
        interval: 5000
        onTriggered: {
            if (Config.autoOptimizeImages && !ImageOptimizeService.running)
                ImageOptimizeService.optimize(Config.imageOptimizePreset, Config.imageOptimizeResolution)
        }
    }

    IpcHandler {
        target: "wallpaper"

        function toggle() {
            if (uiProcess.running)
                uiProcess.running = false
            else
                root._launchUi()
        }

        function open()  { if (!uiProcess.running) root._launchUi() }
        function close() { uiProcess.running = false }
    }

    function _launchUi() {
        if (!_shellQmlPath) return
        uiProcess.command = ["quickshell", "-p", _shellQmlPath]
        uiProcess.running = true
    }

    Process {
        id: uiProcess
    }
}
