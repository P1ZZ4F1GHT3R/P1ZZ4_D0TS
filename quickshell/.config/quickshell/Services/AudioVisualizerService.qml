pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../"

Item {
    id: root

    readonly property var activePlayer: {
        const players = Mpris.players.values
        for (let i = 0; i < players.length; i++) {
            const player = players[i]
            const identity = String(player.identity || "").toLowerCase()
            const desktopEntry = String(player.desktopEntry || "").toLowerCase()
            if (identity === "spotify" || desktopEntry === "spotify")
                return player
        }
        return null
    }

    readonly property bool shouldRun: activePlayer !== null
        && activePlayer.isPlaying
        && !Variables.powerMenu
        && !Variables.notifWidget
        && !Variables.pomodoroClock
        && !Variables.focusMode
        && !Variables.volumeOSD
        && !Variables.brightnessOSD

    readonly property int barCount: 30
    readonly property var emptyData: new Array(barCount).fill(0)
    property var audioData: emptyData

    readonly property var compactAudioData: {
        const compact = []
        const binSize = audioData.length / 4

        for (let i = 0; i < 4; i++) {
            const start = Math.floor(i * binSize)
            const end = Math.min(audioData.length, Math.floor((i + 1) * binSize))
            let sum = 0
            let count = 0

            for (let j = start; j < end; j++) {
                sum += audioData[j]
                count++
            }

            // audioData is normalized to /300; the compact visualizer
            // historically normalized its averaged values to /600.
            compact.push(count > 0 ? (sum / count) / 2 : 0)
        }

        return compact
    }

    function clearData() {
        root.audioData = root.emptyData
    }

    Process {
        id: cavaProcess

        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/cava/config_quickshell"]
        running: root.shouldRun

        stdout: SplitParser {
            onRead: data => {
                const parts = String(data).trim().split(";")
                if (parts.length < root.barCount)
                    return

                const next = []
                for (let i = 0; i < root.barCount; i++)
                    next.push((parseInt(parts[i], 10) || 0) / 300.0)

                root.audioData = next
            }
        }

        onRunningChanged: {
            if (!running)
                root.clearData()
        }
    }
}
