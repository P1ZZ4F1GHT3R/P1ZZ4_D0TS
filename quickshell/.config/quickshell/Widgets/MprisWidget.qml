import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick.Effects
import "../Services"
import "../"   
import "../Modules"   
            
RowLayout {
    id: mpris

    Layout.preferredWidth: item ? item.implicitWidth : 0

    property var activePlayer: null

    property var lyricLines: []
    property bool lyricsSynced: false
    property bool lyricsLoading: false
    property string lyricsStatus: ""
    property int currentLyricIndex: -1
    property int lyricsRequestId: 0
    property var lyricsCache: ({})
    property real currentPosition: 0

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

        const position = Number(mpris.currentPosition || 0)
        
        let low = 0
        let high = lyricLines.length - 1
        let found = -1

        while (low <= high) {
            const middle = Math.floor((low + high) / 2)
            if (position >= lyricLines[middle].time) {
                found = middle
                low = middle + 1
            } else {
                high = middle - 1
            }
        }

        if (currentLyricIndex !== found)
            currentLyricIndex = found
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
        const cacheKey = `${artist}\u0000${title}`

        if (!Variables.enableLyrics || !Variables.expandedState) return

        if (!artist || !title) {
            lyricsLoading = false
            resetLyrics("No lyrics available")
            return
        }

        if (Object.prototype.hasOwnProperty.call(mpris.lyricsCache, cacheKey)) {
            const cached = mpris.lyricsCache[cacheKey]
            mpris.parseLyrics(cached.syncedLyrics, cached.plainLyrics)
            return
        }

        lyricsLoading = true
        resetLyrics("Loading lyrics…")

        const params = `artist_name=${encodeURIComponent(artist)}&track_name=${encodeURIComponent(title)}`

        function requestLyrics(url, isSearchFallback) {
            const request = new XMLHttpRequest()
            request.timeout = 10000
            request.onreadystatechange = function() {
                if (request.readyState !== 4 || requestId !== lyricsRequestId) return
                if (request.status === 404 && !isSearchFallback) {
                    requestLyrics(`https://lrclib.net/api/search?${params}`, true)
                    return
                }

                lyricsLoading = false
                if (request.status < 200 || request.status >= 300) {
                    resetLyrics("Could not load lyrics")
                    return
                }

                try {
                    const response = JSON.parse(request.responseText)
                    const lyrics = isSearchFallback && Array.isArray(response) ? response[0] : response
                    if (!lyrics) {
                        resetLyrics("No lyrics found")
                        return
                    }
                    mpris.lyricsCache[cacheKey] = {
                        syncedLyrics: lyrics.syncedLyrics || "",
                        plainLyrics: lyrics.plainLyrics || ""
                    }
                    parseLyrics(lyrics.syncedLyrics, lyrics.plainLyrics)
                } catch (error) {
                    resetLyrics("Could not read lyrics")
                }
            }
            request.onerror = function() {
                if (requestId === lyricsRequestId) {
                    lyricsLoading = false
                    resetLyrics("Lyrics network error")
                }
            }
            request.ontimeout = function() {
                if (requestId === lyricsRequestId) {
                    lyricsLoading = false
                    resetLyrics("Lyrics request timed out")
                }
            }
            request.open("GET", url)
            request.setRequestHeader("Accept", "application/json")
            request.send()
        }

        requestLyrics(`https://lrclib.net/api/get?${params}`, false)
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
        id: uiUpdateTimer
        interval: 250
        running: Variables.expandedState && mpris.activePlayer !== null
        repeat: true
        onTriggered: {
            mpris.currentPosition = mpris.activePlayer.position || 0
            if (Variables.enableLyrics && mpris.lyricsSynced && mpris.lyricLines.length > 0) {
                mpris.updateCurrentLyric()
            }
        }
    }

    Timer {
        id: lyricsRetryTimer
        interval: 10000 
        running: Variables.enableLyrics && Variables.expandedState && mpris.activePlayer !== null && mpris.lyricLines.length === 0 && !mpris.lyricsLoading
        repeat: true
        
        onTriggered: {
            if (mpris.lyricsStatus === "Could not load lyrics"
                    || mpris.lyricsStatus === "Lyrics network error"
                    || mpris.lyricsStatus === "Lyrics request timed out") {
                mpris.fetchLyrics()
            }
        }
    }

    Connections {
        target: mpris.activePlayer
        ignoreUnknownSignals: true

        function onTrackTitleChanged() { 
            lyricsFetchTimer.restart()
            mpris.currentPosition = 0
        }
        function onTrackArtistChanged() { lyricsFetchTimer.restart() }
        function onPositionChanged() { mpris.currentPosition = mpris.activePlayer.position }
    }

    Connections {
        target: Variables

        function onExpandedStateChanged() {
            if (Variables.expandedState) {
                lyricsFetchTimer.restart()
                if (mpris.activePlayer) mpris.currentPosition = mpris.activePlayer.position || 0
                mpris.updateCurrentLyric()
            }
        }

        function onEnableLyricsChanged() {
            if (Variables.enableLyrics && Variables.expandedState) {
                lyricsFetchTimer.restart()
                mpris.updateCurrentLyric()
            } else if (!Variables.enableLyrics) {
                lyricsFetchTimer.stop()
            }
        }
    }

    ClippingWrapperRectangle{
        id: musicIcon

        Layout.topMargin: -(Variables.topMargin)
        Layout.preferredHeight: visible ? Variables.imgHeight : 0
        Layout.preferredWidth: visible ? Variables.imgWidth : 0
        radius: Variables.imgRadius

        opacity: Variables.expandedState || Variables.powerMenu || Variables.notifWidget ? 0.0 : 1.0
        visible: !Variables.expandedState && Variables.enableMusicIcon
    
        Behavior on opacity {
            NumberAnimation { duration: Variables.fadeAnimation }
        }

        Image {
            source: mpris.activePlayer ? (mpris.activePlayer.trackArtUrl || "") : ""

            fillMode: Image.PreserveAspectCrop
            visible: source != ""
        }

    }

    Loader {
        id: expandedContainerLoader

        active: mpris.activePlayer !== null
        Layout.preferredWidth: Variables.expandedState && active && item ? item.implicitWidth : 0
        Layout.preferredHeight: Variables.expandedState && active && item ? item.implicitHeight : 0

        opacity: Variables.expandedState ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: Variables.fadeAnimation }
        }

        sourceComponent: Component {
            Item {
                id: expandedContainer

                implicitWidth: Variables.musicArtSize + (Variables.width * 5)
                    + Variables.musicArtSize + (Variables.spacing * 8)
                implicitHeight: expandedContent.implicitHeight + (Variables.spacing * 4)

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

                        Layout.preferredWidth: Variables.width * 5
                        Layout.minimumWidth: Variables.width * 5
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: Variables.spacing

                        Item {
                            id: textContainer

                            Layout.fillWidth: true
                            implicitHeight: metadataHeader.implicitHeight

                            Column {
                                id: metadataHeader
                                width: textContainer.width
                                spacing: Variables.topMargin / 2

                                Item {
                                    id: titleClip
                                    width: metadataHeader.width
                                    height: trackTitle.implicitHeight
                                    clip: true

                                    onWidthChanged: {
                                        if (marqueeAnim.running) marqueeAnim.restart()
                                    }

                                    Text {
                                        id: trackTitle
                                        x: (titleClip.width > implicitWidth) ? (titleClip.width - implicitWidth) / 2 : 0
                                        text: mpris.activePlayer ? (mpris.activePlayer.trackTitle || "Unknown title") : ""
                                        color: Variables.uiColor
                                        font.weight: Font.DemiBold
                                        font.pixelSize: Variables.fontSize * 1.05
                                        elide: Text.ElideNone

                                        onImplicitWidthChanged: {
                                            if (marqueeAnim.running) marqueeAnim.restart()
                                        }

                                        SequentialAnimation on x {
                                            id: marqueeAnim
                                            running: titleClip.width > 0 && trackTitle.implicitWidth > titleClip.width
                                                && Variables.expandedState === true
                                            loops: Animation.Infinite

                                            PauseAnimation { duration: 1500 }
                                            NumberAnimation {
                                                to: -(trackTitle.implicitWidth - titleClip.width)
                                                duration: 3000
                                            }
                                            PauseAnimation { duration: 1500 }
                                            NumberAnimation { to: 0; duration: 600 }

                                            onRunningChanged: {
                                                if (!running) {
                                                    trackTitle.x = Qt.binding(function() {
                                                        return (titleClip.width > trackTitle.implicitWidth)
                                                            ? (titleClip.width - trackTitle.implicitWidth) / 2 : 0
                                                    })
                                                }
                                            }
                                        }
                                    }
                                }

                                Text {
                                    width: metadataHeader.width
                                    text: mpris.activePlayer ? (mpris.activePlayer.trackArtist || "Unknown artist") : ""
                                    color: Variables.uiColor
                                    opacity: 0.78
                                    font.pixelSize: Variables.fontSize * 0.68
                                    font.weight: Font.Medium
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }
                            }

                            onWidthChanged: {
                                if (marqueeAnim.running) marqueeAnim.restart()
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
                            readonly property var audioData: AudioVisualizerService.audioData

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
                                        return parent.width * (mpris.currentPosition / mpris.activePlayer.length)
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

                                Text { anchors.fill: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; text: ""; color: Variables.textColor; font.pixelSize: Variables.fontSize}

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
                                    font.pixelSize: Variables.fontSize
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: mpris.activePlayer && mpris.activePlayer.togglePlaying()
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: Variables.circleWidth; Layout.preferredHeight: Variables.circleHeight; radius: Variables.circleRadius; color: Variables.uiColor

                                Text { anchors.fill: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; text: ""; color: Variables.textColor; font.pixelSize: Variables.fontSize}

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

                        Layout.preferredWidth: Variables.enableLyrics ? Variables.musicArtSize : 0
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: Variables.spacing
                        visible: Variables.enableLyrics

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Variables.musicArtSize
                            Layout.minimumHeight: 0
                            clip: true

                            Text {
                                anchors.fill: parent
                                visible: mpris.lyricLines.length === 0 || !mpris.lyricsSynced
                                text: mpris.lyricsStatus
                                font.pixelSize: Variables.fontSize
                                color: Variables.textColor
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.Wrap
                            }

                            Text {
                                id: currentLyricText

                                readonly property string targetText: (mpris.lyricsSynced
                                    && mpris.currentLyricIndex >= 0
                                    && mpris.currentLyricIndex < mpris.lyricLines.length)
                                    ? mpris.lyricLines[mpris.currentLyricIndex].text : ""

                                anchors.fill: parent
                                visible: mpris.lyricsSynced && (text !== "" || targetText !== "")
                                color: Variables.uiColor
                                font.pixelSize: Variables.fontSize
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.Wrap
                                transformOrigin: Item.Center

                                Component.onCompleted: {
                                    text = targetText
                                    opacity = targetText !== "" ? 1.0 : 0.0
                                    scale = 1.0
                                }

                                onTargetTextChanged: {
                                    if (text === "" && targetText !== "") {
                                        lyricTransition.stop()
                                        text = targetText
                                        scale = 0.85
                                        opacity = 0.0
                                        lyricInAnimation.restart()
                                    } else {
                                        lyricInAnimation.stop()
                                        lyricTransition.restart()
                                    }
                                }

                                ParallelAnimation {
                                    id: lyricInAnimation

                                    NumberAnimation {
                                        target: currentLyricText
                                        property: "opacity"
                                        to: 1.0
                                        duration: Variables.fadeAnimation * 0.5
                                        easing.type: Easing.InOutCubic
                                    }
                                    NumberAnimation {
                                        target: currentLyricText
                                        property: "scale"
                                        to: 1.0
                                        duration: Variables.fadeAnimation * 0.5
                                        easing.type: Easing.InOutCubic
                                    }
                                }

                                SequentialAnimation {
                                    id: lyricTransition

                                    ParallelAnimation {
                                        NumberAnimation {
                                            target: currentLyricText
                                            property: "opacity"
                                            to: 0.0
                                            duration: Variables.fadeAnimation * 0.5
                                            easing.type: Easing.InOutCubic
                                        }
                                        NumberAnimation {
                                            target: currentLyricText
                                            property: "scale"
                                            to: 0.85
                                            duration: Variables.fadeAnimation * 0.5
                                            easing.type: Easing.InOutCubic
                                        }
                                    }

                                    ScriptAction {
                                        script: currentLyricText.text = currentLyricText.targetText
                                    }

                                    ParallelAnimation {
                                        NumberAnimation {
                                            target: currentLyricText
                                            property: "opacity"
                                            to: currentLyricText.targetText !== "" ? 1.0 : 0.0
                                            duration: Variables.fadeAnimation * 0.5
                                            easing.type: Easing.InOutCubic
                                        }
                                        NumberAnimation {
                                            target: currentLyricText
                                            property: "scale"
                                            to: 1.0
                                            duration: Variables.fadeAnimation * 0.5
                                            easing.type: Easing.InOutCubic
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
