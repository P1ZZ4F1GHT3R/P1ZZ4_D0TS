import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick.Effects
import Quickshell.Io
import "../"   
import "../Modules"   
            
        
RowLayout {
    id: mpris

    property var activePlayer: {
        let players = Mpris.players.values;
        for (let i = 0; i < players.length; i++) {
            let p = players[i];
            if (p.identity.toLowerCase() === "spotify" || p.desktopEntry.toLowerCase() === "spotify") {
                return p;
            }
        }
        return null; 
    }

    property var lyricLines: []
    property bool lyricsSynced: false
    property bool lyricsLoading: false
    property string lyricsStatus: ""
    property int currentLyricIndex: -1
    property int lyricsRequestId: 0
    property string lyricTrackKey: {
        const player = mpris.activePlayer
        return player ? `${player.trackArtist || ""}\u0000${player.trackTitle || ""}` : ""
    }

    function resetLyrics(status) {
        lyricLines = []
        lyricsSynced = false
        currentLyricIndex = -1
        lyricsStatus = status
    }

    function updateCurrentLyric() {
        if (!lyricsSynced || lyricLines.length === 0 || !mpris.activePlayer) {
            currentLyricIndex = -1
            return
        }

        const position = Number(mpris.activePlayer.position || 0)
        
        for (let i = lyricLines.length - 1; i >= 0; i--) {
            if (position >= lyricLines[i].time) {
                if (currentLyricIndex !== i) {
                    currentLyricIndex = i
                }
                return
            }
        }
        currentLyricIndex = -1
    }

    function parseLyrics(syncedLyrics, plainLyrics) {
        const parsedLines = []
        const syncedText = String(syncedLyrics || "")
        const timestampPattern = /\[(\d+):(\d+(?:\.\d+)?)\]/g

        syncedText.split(/\r?\n/).forEach(line => {
            const timestamps = []
            let match
            while ((match = timestampPattern.exec(line)) !== null) {
                timestamps.push((Number(match[1]) * 60) + Number(match[2]))
            }
            timestampPattern.lastIndex = 0

            const text = line.replace(/\[\d+:\d+(?:\.\d+)?\]/g, "").trim()
            if (text === "") return
            timestamps.forEach(time => parsedLines.push({ time: time, text: text }))
        })

        if (parsedLines.length > 0) {
            parsedLines.sort((a, b) => a.time - b.time)
            lyricLines = parsedLines
            lyricsSynced = true
            lyricsStatus = ""
        } else {
            const plainLines = String(plainLyrics || "")
                .split(/\r?\n/)
                .map(line => line.trim())
                .filter(line => line !== "")
                .map(line => ({ time: -1, text: line }))

            lyricLines = plainLines
            lyricsSynced = false
            lyricsStatus = plainLines.length > 0 ? "Unsynced lyrics" : "No lyrics found"
        }
        updateCurrentLyric()
    }

    function fetchLyrics() {
        const player = mpris.activePlayer
        const requestId = ++lyricsRequestId
        const artist = player ? String(player.trackArtist || "").trim() : ""
        const title = player ? String(player.trackTitle || "").trim() : ""

        if (!artist || !title) {
            lyricsLoading = false
            resetLyrics("No lyrics available")
            return
        }

        lyricsLoading = true
        resetLyrics("Loading lyrics…")

        const params = `artist_name=${encodeURIComponent(artist)}&track_name=${encodeURIComponent(title)}`
        const request = new XMLHttpRequest()
        request.onreadystatechange = function() {
            if (request.readyState !== 4 || requestId !== lyricsRequestId) return

            lyricsLoading = false
            if (request.status < 200 || request.status >= 300) {
                resetLyrics("(╯°□°)╯︵ ┻━┻")
                return
            }

            try {
                const response = JSON.parse(request.responseText)
                parseLyrics(response.syncedLyrics, response.plainLyrics)
            } catch (error) {
                resetLyrics("(╯°□°)╯︵ ┻━┻")
            }
        }
        request.open("GET", `https://lrclib.net/api/get?${params}`)
        request.setRequestHeader("Accept", "application/json")
        request.send()
    }

    onLyricTrackKeyChanged: lyricsFetchTimer.restart()
    onActivePlayerChanged: lyricsFetchTimer.restart()

    Component.onCompleted: lyricsFetchTimer.start()

    Timer {
        id: lyricsFetchTimer
        interval: 100
        repeat: false
        onTriggered: mpris.fetchLyrics()
    }

    Timer {
        id: lyricsUpdateTimer
        interval: 250
        running: mpris.lyricsSynced && mpris.lyricLines.length > 0 && mpris.activePlayer !== null
        repeat: true
        onTriggered: mpris.updateCurrentLyric()
    }

    Connections {
        target: mpris.activePlayer
        ignoreUnknownSignals: true

        function onTrackTitleChanged() { lyricsFetchTimer.restart() }
        function onTrackArtistChanged() { lyricsFetchTimer.restart() }
        function onPositionChanged() { mpris.updateCurrentLyric() }
    }

    visible: mpris.activePlayer !== null

    ClippingWrapperRectangle{
        id: musicIcon

        Layout.topMargin: -(Variables.topMargin)
        Layout.preferredHeight: Variables.imgHeight
        Layout.preferredWidth: Variables.imgWidth
        radius: Variables.imgRadius

        opacity: Variables.expandedState || Variables.powerMenu || Variables.notifWidget ? 0.0 : 1.0
        visible: !Variables.expandedState
    
        Behavior on opacity {
            NumberAnimation { duration: Variables.fadeAnimation }
        }

        Image {
            source: mpris.activePlayer ? (mpris.activePlayer.trackArtUrl || "") : ""

            fillMode: Image.PreserveAspectCrop
            visible: source != ""
        }

    }

   Item {
        id: expandedContainer
        
        visible: mpris.activePlayer !== null && Variables.expandedState
        opacity: !Variables.expandedState ? 0.0 : 1.0

        Layout.fillWidth: true
        Layout.preferredHeight: expandedContent.implicitHeight + (Variables.spacing * 4)

        Behavior on opacity {
            NumberAnimation { duration: Variables.fadeAnimation }
        }

        Rectangle {
            anchors.fill: parent
            radius: Variables.radius
            color: Variables.backgroundColorUI
            border.color: Variables.borderColor
            border.width: Variables.borderWidth

            ClippingWrapperRectangle {
                anchors.fill: parent
                anchors.margins: Variables.borderWidth
                radius: Math.max(0, Variables.radius - Variables.borderWidth)

                Item {
                    anchors.fill: parent

                    Image {
                        id: blurredBgSource
                        source: mpris.activePlayer ? (mpris.activePlayer.trackArtUrl || "") : ""
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        visible: false 
                    }

                    MultiEffect {
                        source: blurredBgSource
                        anchors.fill: parent
                        blurEnabled: true
                        blurMax: Variables.musicBlurMax
                        blur: 0.69 //heh nice
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Variables.borderColor
                        opacity: 0.5
                    }
                }
            }
        }

        RowLayout {
            id: expandedContent

            anchors.fill: parent
            anchors.margins: Variables.spacing * 2
            spacing: Variables.spacing * 2

            ClippingWrapperRectangle {
                Layout.preferredWidth: Variables.musicArtSize
                Layout.preferredHeight: Variables.musicArtSize
                Layout.alignment: Qt.AlignVCenter
                radius: Variables.imgRadius

                Image {
                    source: mpris.activePlayer ? (mpris.activePlayer.trackArtUrl || "") : ""
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                }
            }

            ColumnLayout {
                id: controlsColumn

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Variables.spacing

                Item {
                    id: textContainer

                    clip: true
                    Layout.fillWidth: true
                    implicitHeight: trackText.implicitHeight

                    onWidthChanged: {
                        if (marqueeAnim.running) marqueeAnim.restart()
                    }

                    Text {
                        id: trackText
                        
                        x: (textContainer.width > implicitWidth) ? (textContainer.width - implicitWidth) / 2 : 0

                        text: {
                            const player = mpris.activePlayer
                            if (!player) return ""
                            return `${player.trackTitle || "Unknown"} - ${player.trackArtist || "Unknown"}`
                        }
                        color: Variables.uiColor
                        font.bold: true

                        onImplicitWidthChanged: {
                            if (marqueeAnim.running) marqueeAnim.restart()
                        }

                        SequentialAnimation on x {
                            id: marqueeAnim

                            running: textContainer.width > 0 && trackText.implicitWidth > textContainer.width && Variables.expandedState === true
                                     
                            loops: Animation.Infinite

                            PauseAnimation { duration: 1500 }
                            NumberAnimation {
                                to: -(trackText.implicitWidth - textContainer.width)
                                duration: 3000
                            }
                            PauseAnimation { duration: 1500 }
                            NumberAnimation {
                                to: 0
                                duration: 600
                            }

                            onRunningChanged: {
                                if (!running) {
                                    trackText.x = Qt.binding(function() {
                                        return (textContainer.width > trackText.implicitWidth) ? (textContainer.width - trackText.implicitWidth) / 2 : 0
                                    })
                                }
                            }
                        }
                    }
                }

                Item {
                    id: visualizerProgressContainer

                    Layout.topMargin: Variables.height / 4
                    Layout.fillWidth: true
                    Layout.preferredHeight: Variables.height * 3
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

                    property real barScale: 0.3
                    property int minBarHeight: Variables.mprisVisualizerMinHeight
                    property int barCount: 30
                    property var audioData: new Array(barCount).fill(0)

                    Process {
                        id: cavaProc
                        command: ["sh", "-c", "cava -p ~/.config/cava/config_quickshell"]
                        running: mpris.activePlayer !== null && mpris.activePlayer.isPlaying
                        
                        stdout: SplitParser {
                            onRead: data => {
                                let val = data.trim()
                                if (val === "") return
                                let parts = val.split(";")
                                
                                if (parts.length >= visualizerProgressContainer.barCount) {
                                    let newData = []
                                    for (let i = 0; i < visualizerProgressContainer.barCount; i++) {
                                        newData.push((parseInt(parts[i]) || 0) / 300.0)
                                    }
                                    visualizerProgressContainer.audioData = newData
                                }
                            }
                        }
                    }

                    Connections {
                        target: mpris.activePlayer
                        ignoreUnknownSignals: true
                        function onIsPlayingChanged() {
                            if (!mpris.activePlayer || !mpris.activePlayer.isPlaying) {
                                Qt.callLater(function() {
                                    visualizerProgressContainer.audioData = new Array(visualizerProgressContainer.barCount).fill(0)
                                })
                            }
                        }
                    }

                    Column {
                        id: bgVisualizer
                        anchors.fill: parent
                        spacing: -visualizerProgressContainer.minBarHeight / 1.5

                        Row {
                            width: parent.width
                            height: parent.height / 2
                            spacing: Variables.visualizerGap

                            Repeater {
                                model: visualizerProgressContainer.barCount
                                Rectangle {
                                    width: (parent.width - (parent.spacing * (visualizerProgressContainer.barCount - 1))) / visualizerProgressContainer.barCount
                                    height: Math.min(parent.height, Math.max(visualizerProgressContainer.minBarHeight, (visualizerProgressContainer.audioData[index] || 0) * parent.height * visualizerProgressContainer.barScale))
                                    color: Variables.uiColor
                                    radius: Variables.barRadius
                                    anchors.bottom: parent.bottom
                                    
                                    Behavior on height {
                                        NumberAnimation { 
                                            duration: (mpris.activePlayer && mpris.activePlayer.isPlaying) ? 0 : Variables.animationDurationUI
                                            easing.type: Easing.InOutCubic
                                        }
                                    }
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            height: parent.height / 2
                            spacing: Variables.visualizerGap

                            Repeater {
                                model: visualizerProgressContainer.barCount
                                Rectangle {
                                    width: (parent.width - (parent.spacing * (visualizerProgressContainer.barCount - 1))) / visualizerProgressContainer.barCount
                                    height: Math.min(parent.height, Math.max(visualizerProgressContainer.minBarHeight, (visualizerProgressContainer.audioData[index] || 0) * parent.height * visualizerProgressContainer.barScale))
                                    color: Variables.uiColor
                                    radius: Variables.barRadius
                                    anchors.top: parent.top
                                    
                                    Behavior on height {
                                        NumberAnimation { 
                                            duration: (mpris.activePlayer && mpris.activePlayer.isPlaying) ? 0 : Variables.animationDurationUI
                                            easing.type: Easing.InOutCubic
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        
                        width: {
                            if (mpris.activePlayer && mpris.activePlayer.length > 0) {
                                return parent.width * (mpris.activePlayer.position / mpris.activePlayer.length)
                            }
                            return 0
                        }
                        
                        clip: true 

                        Behavior on width { 
                            NumberAnimation { 
                                duration: (mpris.activePlayer && mpris.activePlayer.isPlaying) ? 0 : Variables.fadeAnimation 
                                easing.type: Easing.InOutCubic
                            } 
                        }

                        Column {
                            width: visualizerProgressContainer.width
                            height: visualizerProgressContainer.height
                            spacing: -visualizerProgressContainer.minBarHeight / 1.5

                            Row {
                                width: parent.width
                                height: parent.height / 2
                                spacing: Variables.visualizerGap

                                Repeater {
                                    model: visualizerProgressContainer.barCount
                                    Rectangle {
                                        width: (parent.width - (parent.spacing * (visualizerProgressContainer.barCount - 1))) / visualizerProgressContainer.barCount
                                        height: Math.min(parent.height, Math.max(visualizerProgressContainer.minBarHeight, (visualizerProgressContainer.audioData[index] || 0) * parent.height * visualizerProgressContainer.barScale))
                                        color: Variables.iconColor
                                        radius: Variables.barRadius
                                        anchors.bottom: parent.bottom
                                        
                                        Behavior on height {
                                            NumberAnimation { 
                                                duration: (mpris.activePlayer && mpris.activePlayer.isPlaying) ? 0 : Variables.animationDurationUI
                                                easing.type: Easing.InOutCubic
                                            }
                                        }
                                    }
                                }
                            }

                            Row {
                                width: parent.width
                                height: parent.height / 2
                                spacing: Variables.visualizerGap

                                Repeater {
                                    model: visualizerProgressContainer.barCount
                                    Rectangle {
                                        width: (parent.width - (parent.spacing * (visualizerProgressContainer.barCount - 1))) / visualizerProgressContainer.barCount
                                        height: Math.min(parent.height, Math.max(visualizerProgressContainer.minBarHeight, (visualizerProgressContainer.audioData[index] || 0) * parent.height * visualizerProgressContainer.barScale))
                                        color: Variables.buttonColor
                                        radius: Variables.barRadius
                                        anchors.top: parent.top
                                        
                                        Behavior on height {
                                            NumberAnimation { 
                                                duration: (mpris.activePlayer && mpris.activePlayer.isPlaying) ? 0 : Variables.animationDurationUI
                                                easing.type: Easing.InOutCubic
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Variables.topMargin
                    spacing: Variables.spacing * 4

                    Rectangle {
                        Layout.preferredWidth: Variables.circleWidth; Layout.preferredHeight: Variables.circleHeight; radius: Variables.circleRadius; color: Variables.uiColor

                        Text { anchors.fill: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; text: ""; color: Variables.textColor}

                        MouseArea {
                            anchors.fill: parent
                            onClicked: mpris.activePlayer && mpris.activePlayer.previous()
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: Variables.circleWidth; Layout.preferredHeight: Variables.circleHeight; radius: Variables.circleRadius; color: Variables.iconColor

                        Text { 
                            anchors.fill: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: mpris.activePlayer && mpris.activePlayer.isPlaying ? "" : "" 
                            color: Variables.textColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: mpris.activePlayer && mpris.activePlayer.togglePlaying()
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: Variables.circleWidth; Layout.preferredHeight: Variables.circleHeight; radius: Variables.circleRadius; color: Variables.uiColor

                        Text { anchors.fill: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; text: ""; color: Variables.textColor }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: mpris.activePlayer && mpris.activePlayer.next()
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }

            ColumnLayout {
                id: lyricsColumn

                Layout.preferredWidth: Variables.musicArtSize
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Variables.spacing

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Variables.musicArtSize
                    Layout.minimumHeight: 0
                    clip: true

                    Text {
                        anchors.fill: parent
                        visible: mpris.lyricLines.length === 0
                        text: mpris.lyricsStatus
                        color: Variables.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.Wrap
                    }

                    ListView {
                        id: lyricsList

                        anchors.fill: parent
                        visible: mpris.lyricLines.length > 0
                        clip: true
                        model: mpris.lyricLines
                        currentIndex: mpris.currentLyricIndex
                        preferredHighlightBegin: height / 2 - Variables.fontSize
                        preferredHighlightEnd: height / 2 + Variables.fontSize
                        highlightRangeMode: ListView.StrictlyEnforceRange
                        spacing: Variables.spacing / 2

                        onVisibleChanged: {
                            if (visible && mpris.currentLyricIndex >= 0) {
                                positionViewAtIndex(mpris.currentLyricIndex, ListView.Center)
                            }
                        }

                        delegate: Text {
                            required property var modelData
                            required property int index

                            width: lyricsList.width
                            text: modelData.text
                            color: Variables.uiColor
                            font.pixelSize: Variables.fontSize
                            font.bold: index === mpris.currentLyricIndex
                            scale: index === mpris.currentLyricIndex ? 0.9 : 0.8
                            opacity: index === mpris.currentLyricIndex ? 1.0 : 0.4

                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            transformOrigin: Item.Center

                            Behavior on opacity {
                                NumberAnimation { duration: Variables.fadeAnimation; easing.type: Easing.InOutCubic }
                            }
                            Behavior on scale {
                                NumberAnimation { duration: Variables.fadeAnimation; easing.type: Easing.InOutCubic }
                            }
                        }
                    }
                }
            }
        }
    }
}
