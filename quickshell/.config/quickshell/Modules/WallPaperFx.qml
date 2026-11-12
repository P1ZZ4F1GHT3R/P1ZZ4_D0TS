
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "../"

Scope {
    id: root

    readonly property string onlyScreen: Quickshell.env("WALLFX_ONLY") || ""
    readonly property bool dry: Quickshell.env("WALLFX_DRY") === "1"

    property int msContagion: 1800
    property int msProfile: 2000
    property int msFade: 130          
    property real glow: 0.9
    property real lineW: 1.5

    property string oldPath: ""
    property string newPath: ""
    property string kind: "contagion"
    property string fieldPath: ""
    property string linePath: ""
    property bool autoGo: true
    property string phase: "idle"
    property real t: 0
    property real fade: 0
    property bool swapped: false
    property int gen: 0
    property int swapGen: -1
    property color ember: "orange"
    property color ink: "white"
    property real seed: 0
    property int readyCount: 0
    readonly property int screenCount: screens.instances.length
    readonly property bool active: phase !== "idle"
    function lifted(c) {
        return Qt.hsla(c.hslHue, Math.max(c.hslSaturation, 0.55),
                       Math.min(Math.max(c.hslLightness, 0.62), 0.82), 1)
    }

    function prepare(o, n, k, f, l, go) {
        if (root.active) root.finish()
        root.oldPath = o; root.newPath = n
        root.kind = k === "profile" ? "profile" : "contagion"
        root.fieldPath = f; root.linePath = l || f
        root.autoGo = go
        root.t = 0; root.fade = 0; root.readyCount = 0; root.swapped = false
        root.gen++
        root.phase = "loading"
        watchdog.restart()
    }
    function screenReady() {
        if (root.phase !== "loading") return
        root.readyCount++
        if (root.readyCount < root.screenCount) return
        watchdog.stop()
        if (root.dry) { root.fade = 1; root.phase = "ready"; if (root.autoGo) root.go(); return }
        root.go()
    }
    function go() {
        if (root.phase !== "ready" && root.phase !== "loading") return

        const rawPal = [
            Variables.uiColor,
            Variables.textColor,
            Variables.iconColor,
            Variables.borderColor,
            Variables.buttonColor,
            Variables.lockscreenColor,
            Variables.backgroundColorUI,
            Variables.shadowColor
        ]

        const pal = rawPal.filter(c => c && c.hslSaturation !== undefined)

        if (pal.length > 0) {
            const chroma = c => (c.hslSaturation || 0) * (1 - Math.abs(2 * (c.hslLightness || 0) - 1))
            const light = c => 0.299 * (c.r || 0) + 0.587 * (c.g || 0) + 0.114 * (c.b || 0)
            
            root.ember = root.lifted(pal.reduce((a, b) => chroma(b) > chroma(a) ? b : a, pal[0]))
            root.ink = pal.reduce((a, b) => light(b) > light(a) ? b : a, pal[0])
        }

        root.seed = Math.random() * 100
        root.phase = "run"
        run.duration = root.kind === "profile" ? root.msProfile : root.msContagion
        run.restart()
        if (!root.dry) fadeIn.restart()
    }
    function maybeFinish() {
        if (root.dry) { if (!run.running) root.phase = "done"; return }
        if (run.running) return
        if (!root.swapped) { root.phase = "held"; watchdog.restart(); return }
        root.phase = "fadeout"
        fadeOut.restart()
    }
    function awwwImg(path, extra) {
        return ["awww", "img", path].concat(root.onlyScreen ? ["--outputs", root.onlyScreen] : [], extra)
    }
    function swap() {
        root.swapGen = root.gen
        awww.command = root.awwwImg(root.newPath, ["--transition-type", "none"])
        awww.running = true
    }
    function finish() {
        fadeIn.stop(); run.stop(); fadeOut.stop(); watchdog.stop(); settle.stop()
        root.phase = "idle"; root.fade = 0; root.t = 0
        root.oldPath = ""; root.newPath = ""; root.fieldPath = ""; root.linePath = ""
    }

    NumberAnimation { id: fadeIn; target: root; property: "fade"; from: 0; to: 1
        duration: root.msFade; easing.type: Easing.OutQuad
        onFinished: root.swap() }
    NumberAnimation { id: run; target: root; property: "t"; from: 0; to: 1
        easing.type: Easing.Linear
        onFinished: root.maybeFinish() }
    property int statFrames: 0
    property real statWorst: 0
    property string lastStats: ""
    FrameAnimation {
        running: root.phase === "run"
        onRunningChanged: if (running) { root.statFrames = 0; root.statWorst = 0 }
                          else if (root.statFrames > 0)
                              root.lastStats = root.kind + ": " + root.statFrames + " frames in "
                                  + run.duration + " ms (" + Math.round(root.statFrames * 1000 / run.duration)
                                  + " fps), worst was " + Math.round(root.statWorst * 1000) + " ms"
        onTriggered: { root.statFrames++; if (root.statFrames > 2) root.statWorst = Math.max(root.statWorst, frameTime) }
    }

    NumberAnimation { id: fadeOut; target: root; property: "fade"; from: 1; to: 0
        duration: root.msFade; easing.type: Easing.OutQuad
        onFinished: root.finish() }

    Process {
        id: awww
        onExited: (code) => {
            if (root.swapGen !== root.gen) return
            if (code === 0) { settle.restart(); return }
            const n = root.newPath
            root.finish()
            Quickshell.execDetached(root.awwwImg(n, ["--transition-type", "fade", "--transition-duration", "0.5"]))
        }
    }

    Timer { id: settle; interval: 40; onTriggered: { root.swapped = true; root.maybeFinish() } }

    Timer {
        id: watchdog; interval: 2500
        onTriggered: {
            const n = root.newPath, loading = root.phase === "loading"
            root.finish()
            if (loading && !root.dry && n)
                Quickshell.execDetached(root.awwwImg(n, ["--transition-type", "fade", "--transition-duration", "0.5"]))
        }
    }

    IpcHandler {
        target: "wallfx"
        function play(oldImg: string, newImg: string, kind: string, field: string, line: string): string {
            root.prepare(oldImg, newImg, kind, field, line, true); return "ok"
        }
        function prepare(oldImg: string, newImg: string, kind: string, field: string, line: string): string {
            root.prepare(oldImg, newImg, kind, field, line, false); return "ok"
        }
        function go(): string { root.go(); return root.phase }
        function state(): string { return root.phase }
        function stats(): string { return root.lastStats }
        function stop(): string { root.finish(); return "ok" }
        function tune(key: string, value: string): string {
            root[key] = Number(value)
            return key + "=" + root[key]
        }
    }


    Variants {
        id: screens
        model: Quickshell.screens.filter(s => !root.onlyScreen || s.name === root.onlyScreen)

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: root.active
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "quickshell:wallfx"

            readonly property bool loaded: (oldImg.status === Image.Ready || oldImg.status === Image.Null)
                && newImg.status === Image.Ready
                && fieldImg.status === Image.Ready
                && (lineImg.status === Image.Ready || lineImg.status === Image.Null)
            onLoadedChanged: if (loaded) root.screenReady()

            Image { id: oldImg; visible: false; asynchronous: true; cache: false
                source: root.oldPath ? (root.oldPath.startsWith("file://") ? root.oldPath : "file://" + root.oldPath) : ""
                sourceSize: Qt.size(win.width, win.height); fillMode: Image.PreserveAspectCrop
                onStatusChanged: if (status === Image.Error) console.warn("[WallFx] Error loading oldImg:", source) }
            Image { id: newImg; visible: false; asynchronous: true; cache: false
                source: root.newPath ? (root.newPath.startsWith("file://") ? root.newPath : "file://" + root.newPath) : ""
                sourceSize: Qt.size(win.width, win.height); fillMode: Image.PreserveAspectCrop
                onStatusChanged: if (status === Image.Error) console.warn("[WallFx] Error loading newImg:", source) }
            Image { id: fieldImg; visible: false; asynchronous: true; cache: false
                smooth: root.kind === "profile"
                source: root.fieldPath ? (root.fieldPath.startsWith("file://") ? root.fieldPath : "file://" + root.fieldPath) : ""
                onStatusChanged: if (status === Image.Error) console.warn("[WallFx] Error loading fieldImg:", source) }
            Image { id: lineImg; visible: false; asynchronous: true; cache: false
                source: root.linePath ? (root.linePath.startsWith("file://") ? root.linePath : "file://" + root.linePath) : ""
                onStatusChanged: if (status === Image.Error) console.warn("[WallFx] Error loading lineImg:", source) }

            function crop(img) {
                const iw = Math.max(img.implicitWidth, 1), ih = Math.max(img.implicitHeight, 1)
                const s = Math.max(win.width / iw, win.height / ih)
                const w = win.width / (iw * s), h = win.height / (ih * s)
                return Qt.vector4d((1 - w) / 2, (1 - h) / 2, w, h)
            }

            ShaderEffect {
                anchors.fill: parent
                visible: win.loaded
                opacity: root.fade
                property var oldTex: oldImg
                property var newTex: newImg
                property var fieldTex: fieldImg
                property var lineTex: lineImg
                property real t: root.t
                property real mode: root.kind === "profile" ? 1 : 0
                property real sw: win.width
                property real sh: win.height
                property real fw: Math.max(fieldImg.implicitWidth, 1)
                property real fh: Math.max(fieldImg.implicitHeight, 1)
                property real lw: Math.max(lineImg.implicitWidth, 1)
                property real lh: Math.max(lineImg.implicitHeight, 1)
                property real glow: root.glow
                property real lineW: root.lineW
                property real sdRange: 16
                property real seed: root.seed
                property vector4d cropOld: win.crop(oldImg)
                property vector4d cropNew: win.crop(newImg)
                property color ember: root.ember
                property color ink: root.ink
                fragmentShader: Qt.resolvedUrl("wallfx.frag.qsb")
            }
        }
    }
}