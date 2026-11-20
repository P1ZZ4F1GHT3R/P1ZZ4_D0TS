import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell.Services.Mpris
import "../"
import "../Common"
import "../Widgets"

Rectangle {
    id: notchRoot

    readonly property bool effectivelyHidden: Variables.notchHidden && !Variables.settingsOpen
    readonly property real availableHeaderWidth: (Variables.monitor && Variables.monitor.width > 0
        ? Variables.monitor.width
        : Variables.referenceScreenWidth) - (Variables.frameBorderWidth * 4)

    implicitHeight: effectivelyHidden
        ? 0
        : (Variables.settingsOpen
            ? Variables.settingsHeaderHeight + Variables.frameBorderWidth
            : notch.implicitHeight + Variables.height + Variables.frameBorderWidth)
    implicitWidth: effectivelyHidden
        ? 0
        : (Variables.settingsOpen
            ? Math.min(Variables.settingsHeaderWidth, availableHeaderWidth)
            : notch.implicitWidth + Variables.width)
    bottomLeftRadius: Variables.radius
    bottomRightRadius: Variables.radius
    color: Variables.uiColor
    scale: Variables.lockScreen ? 1.2 : 1.0
    transformOrigin: Item.Top

    property var notifServer
    property bool enablePowerMenuIpc: true

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

    Process {
        id: recChecker

        command: [
            "/bin/bash", 
            "-c", 
            "pgrep -x wf-recorder >/dev/null || " +
            "pgrep -x wl-screenrec >/dev/null || " +
            "pgrep -x gpu-screen-recorder >/dev/null || " +
            "pw-cli list-objects Node 2>/dev/null | grep -E 'media.class = \"Video/Source\"|media.role = \"Screen\"' >/dev/null " +
            "&& echo 1 || echo 0"
        ]
        
        stdout: StdioCollector {
            onStreamFinished: {
                let status = this.text.trim()
                Variables.isRecording = (status === "1")
            }
        }
    }

    Behavior on scale {
        NumberAnimation { duration: Variables.activeDurationUI * 0.64; easing.type: Variables.activeAnimationUI }
    }

    IpcHandler {
        target: "powermenu"
        enabled: notchRoot.enablePowerMenuIpc

        function toggle(): void {
            if (!Variables.powerMenu) {
                Variables.closeSettings();
                Variables.powerMenu = true;
                Variables.toolBar = false;
                Variables.expandedState = false;
                volumeOsd.cancelOsd();
                brightnessOSD.cancelOsd();
            } else {
                Variables.powerMenu = false;
            }
        }
    }

    IpcHandler {
        target: "capture"
        enabled: notchRoot.enablePowerMenuIpc

        function toggle(): void {
            if (!Variables.toolBar) {
                Variables.closeSettings();
                Variables.toolBar = true;
                Variables.powerMenu = false;
                Variables.expandedState = false;
                volumeOsd.cancelOsd();
                brightnessOSD.cancelOsd();
            } else {
                Variables.toolBar = false;
            }
        }
    }

    onActivePlayerChanged: {
        if (Variables.lockScreen && Variables.lockScreenMpris && !Variables.pomodoroClock) {
            if (notchRoot.activePlayer !== null) {
                Variables.expandedState = true;
                Variables.notchHidden = false;
            } else {
                Variables.expandedState = false;
                Variables.notchHidden = true;
            }
        }
    }

    Connections {
        target: Variables
        
        function onLockScreenChanged() {
            lockTransitionTimer.stop();
            if (Variables.lockScreen) {
                Variables.closeSettings();
                Variables.powerMenu = false;
                Variables.expandedState = false;
                Variables.notchHidden = true;
                Variables.workspacesHidden = true;
                Variables.systemHidden = true;
                Variables.launcherOpen = false;
                hovertimer.stop();

                lockTransitionTimer.isLocking = true;
                lockTransitionTimer.start();
            }
            else {
                Variables.expandedState = false; 
                Variables.notchHidden = true;
                hovertimer.stop();

                lockTransitionTimer.isLocking = false;
                lockTransitionTimer.start();
            }
        }

        function onPomodoroClockChanged() {
            if (Variables.lockScreen) {
                if (Variables.pomodoroClock) {
                    Variables.expandedState = false;
                    Variables.notchHidden = true;
                } else if (Variables.lockScreenMpris && notchRoot.activePlayer !== null) {
                    Variables.expandedState = true;
                    Variables.notchHidden = false;
                }
            }
        }
    }

    Shape {
        id: leftConcave
        
        readonly property real cornerSize: Math.max(0, Math.min(Variables.radius, Math.min(parent.width, parent.height))) / notchRoot.scale
        
        visible: cornerSize > 0

        width: cornerSize
        height: cornerSize
        anchors.top: parent.top
        anchors.right: parent.left
        anchors.topMargin: Variables.frameBorderWidth / notchRoot.scale

        ShapePath {
            fillColor: Variables.uiColor
            strokeWidth: 0

            PathMove { x: leftConcave.cornerSize; y: 0 }
            PathLine { x: leftConcave.cornerSize; y: leftConcave.cornerSize }
            PathArc {
                x: 0; y: 0
                radiusX: leftConcave.cornerSize
                radiusY: leftConcave.cornerSize
                direction: PathArc.Counterclockwise
            }
            PathLine { x: leftConcave.cornerSize; y: 0 }
        }
    }

    Shape {
        id: rightConcave

        readonly property real cornerSize: Math.max(0, Math.min(Variables.radius, Math.min(parent.width, parent.height))) / notchRoot.scale
        
        visible: cornerSize > 0
        
        width: cornerSize
        height: cornerSize
        anchors.top: parent.top
        anchors.left: parent.right
        anchors.topMargin: Variables.frameBorderWidth / notchRoot.scale

        ShapePath {
            fillColor: Variables.uiColor
            strokeWidth: 0

            PathMove { x: 0; y: 0 }
            PathLine { x: 0; y: rightConcave.cornerSize }
            PathArc {
                x: rightConcave.cornerSize; y: 0
                radiusX: rightConcave.cornerSize
                radiusY: rightConcave.cornerSize
                direction: PathArc.Clockwise
            }
            PathLine { x: 0; y: 0 }
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: (Variables.expandedState || Variables.settingsOpen || Variables.activeAnimationUI === Variables.bouncingAnimationUI)
                ? Variables.activeDurationUI : Variables.activeDurationUI * 0.64
            easing.type: Variables.activeAnimationUI
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: (Variables.expandedState || Variables.activeAnimationUI === Variables.bouncingAnimationUI)
                ? Variables.activeDurationUI * 0.64 : Variables.activeDurationUI
            easing.type: Variables.activeAnimationUI
        }
    }

    MouseArea {
        id: mousearea

        anchors.fill: parent
        hoverEnabled: true
        enabled: !Variables.settingsOpen

        onClicked: {
            if (Variables.lockScreen || Variables.settingsOpen) return;
            Variables.clickEnabled && !Variables.expandedState && !Variables.powerMenu && !Variables.toolBar && !Variables.notifWidget ? Variables.expandedState = true : Variables.expandedState = false
        }
        onEntered: {
            if (Variables.lockScreen || Variables.settingsOpen) return;
            Variables.hoverEnabled && !Variables.powerMenu && !Variables.toolBar && !Variables.notifWidget ? hovertimer.start() : null
        }
        onExited: {
            if (Variables.lockScreen || Variables.settingsOpen) return;
            Variables.hoverEnabled ? (Variables.expandedState = false, hovertimer.stop()) : null
        }
    }

    Timer {
        id: lockTransitionTimer
        
        interval: 250
        repeat: false
        property bool isLocking: false

        onTriggered: {
            if (isLocking) {
                if (Variables.lockScreenMpris && notchRoot.activePlayer !== null && !Variables.pomodoroClock) {
                    Variables.expandedState = true;
                    Variables.notchHidden = false;
                }
            } else {
                Variables.activeAnimationUI = Variables.bouncingAnimationUI;
                Variables.activeDurationUI = Variables.bouncingDurationUI;
                Variables.expandedState = false;
                Variables.notchHidden = false;
                if (!Variables.pomodoroClock) {
                    Variables.workspacesHidden = false;
                    Variables.systemHidden = false;
                }
                animationSwitch.start();
            }
        }
    }

    Timer {
        id: hovertimer

        interval: Variables.hoverTimer
        running: false
        repeat: false
        triggeredOnStart: false
        onTriggered: if (!Variables.settingsOpen && !Variables.lockScreen) Variables.expandedState = true
    }

    Timer {
        id: animationSwitch

        interval: 200
        running: false
        repeat: false
        onTriggered: {
            Variables.activeDurationUI = Variables.animationDurationUI;
            Variables.activeAnimationUI = Variables.animationTypeUI;
        }
    }

    Timer {
        id: recCheckerTimer

        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            recChecker.running = false
            recChecker.running = true
        }
    }

    Rectangle {
        id: clipContainer
        
        color: "transparent"
        radius: Variables.radius
        clip: true
        anchors {
            fill: parent
        }
        
        RowLayout {
            id: notch

            anchors.fill: parent
            anchors.margins: Variables.rightMargin
            spacing: (Variables.enableMusicIcon && Variables.enableVisualizer)
                ? Variables.spacing * 1.5
                : Variables.spacing * 0.5
            opacity: Variables.settingsOpen ? 0.0 : 1.0
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation {
                    duration: Variables.fadeAnimation * 0.65
                    easing.type: Easing.OutCubic
                }
            }

            Loader {
                id: mprisWidgetLoader

                Layout.preferredWidth: item ? item.implicitWidth : 0
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                visible: active && (Variables.enableMusicIcon || Variables.expandedState)
                active: !Variables.settingsOpen && !Variables.powerMenu && !Variables.notifWidget && !Variables.pomodoroClock && notchRoot.activePlayer !== null && !Variables.volumeOSD && !Variables.brightnessOSD && !Variables.notchHidden && !Variables.toolBar
                
                sourceComponent: Component {
                    MprisWidget {
                        activePlayer: notchRoot.activePlayer
                    }
                }
            }

            Loader {
                id: clockWidgetLoader

                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                visible: active
                active: !Variables.settingsOpen && !(notchRoot.activePlayer !== null && Variables.expandedState) && !Variables.powerMenu && !Variables.notifWidget && !Variables.volumeOSD && !Variables.brightnessOSD && !Variables.notchHidden && !Variables.toolBar
                sourceComponent: Component {
                    ClockWidget {
                        activePlayer: notchRoot.activePlayer
                    }
                }
            }

            Loader {
                id: notificationWidgetLoader

                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                visible: active
                active: !Variables.settingsOpen && Variables.notifWidget && !Variables.powerMenu  && !Variables.notchHidden && !Variables.toolBar && !Variables.lockScreen
                sourceComponent: Component {
                    NotificationWidget {
                        daemon: notchRoot.notifServer
                    }
                }
            }

            Loader {
                id: powerMenuLoader
                active: !Variables.settingsOpen && Variables.powerMenu && !Variables.notchHidden
                visible: active
                source: "../Widgets/PowerMenuWidget.qml"
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                focus: true
            }

            Loader {
                id: captureMenuLoader
                active: !Variables.settingsOpen && Variables.toolBar && !Variables.notchHidden
                visible: active
                source: "ToolBar.qml" 
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                focus: true
            }

            Loader {
                id: visualizerWidgetLoader

                Layout.alignment: Qt.AlignVCenter
                
                visible: active
                active: !Variables.settingsOpen && Variables.enableVisualizer && !Variables.powerMenu && !Variables.expandedState && !Variables.lockScreen && !Variables.notifWidget && !Variables.pomodoroClock && notchRoot.activePlayer !== null && !Variables.volumeOSD && !Variables.brightnessOSD  && !Variables.notchHidden && !Variables.toolBar
                sourceComponent: Component {
                    VisualizerWidget {
                        activePlayer: notchRoot.activePlayer
                    }
                }
            }

            VolumeOSD {
                id: volumeOsd

                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                z: 10

                opacity: Variables.volumeOSD ? 1.0 : 0.0
                visible: !Variables.settingsOpen && Variables.volumeOSD && !Variables.powerMenu && !Variables.notifWidget && !Variables.brightnessOSD && !Variables.notchHidden && !Variables.toolBar

                Behavior on opacity {
                    NumberAnimation { duration: Variables.fadeAnimation }
                }
            }

            BrightnessOSD {
                id: brightnessOSD

                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                z: 10

                opacity: Variables.brightnessOSD ? 1.0 : 0.0
                visible: !Variables.settingsOpen && Variables.brightnessOSD && !Variables.powerMenu && !Variables.notifWidget && !Variables.volumeOSD && !Variables.notchHidden && !Variables.toolBar

                Behavior on opacity {
                    NumberAnimation { duration: Variables.fadeAnimation }
                }
            }

            Loader {
                id: recordingIndicatorLoader

                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                visible: active
                active: !Variables.settingsOpen && Variables.isRecording && !Variables.powerMenu && !Variables.notifWidget && !Variables.expandedState && !Variables.toolBar

                sourceComponent: Component {
                    RecordingIndicator{}
                }
            }
        }

        Item {
            id: settingsHeader

            anchors {
                fill: parent
                topMargin: Variables.frameBorderWidth
                leftMargin: Variables.spacing * 1.5
                rightMargin: Variables.spacing * 1.5
            }
            opacity: Variables.settingsOpen ? 1.0 : 0.0
            visible: opacity > 0.01
            enabled: Variables.settingsOpen

            Behavior on opacity {
                NumberAnimation {
                    duration: Variables.fadeAnimation
                    easing.type: Easing.OutCubic
                }
            }

            RowLayout {
                id: categoryCenterRow

                anchors.centerIn: parent
                width: Math.min(implicitWidth, parent.width)
                spacing: Variables.spacing * 0.75

                property string displayedIcon: Variables.currentSettingsCategory.icon || ""
                property string displayedLabel: formatCategoryLabel(Variables.currentSettingsCategory)

                function formatCategoryLabel(cat) {
                    if (!cat || !cat.name) return "";
                    return cat.subtitle ? (cat.name + "  ·  " + cat.subtitle) : cat.name;
                }

                transform: Translate {
                    id: categoryTextTranslate
                    y: 0
                }

                SequentialAnimation {
                    id: categorySwitchAnim

                    ParallelAnimation {
                        NumberAnimation {
                            target: categoryCenterRow
                            property: "opacity"
                            to: 0.0
                            duration: Variables.fadeAnimation * 0.35
                            easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: categoryTextTranslate
                            property: "y"
                            to: -Variables.spacing * 0.6
                            duration: Variables.fadeAnimation * 0.35
                            easing.type: Easing.InCubic
                        }
                    }

                    ScriptAction {
                        script: {
                            categoryCenterRow.displayedIcon = Variables.currentSettingsCategory.icon || "";
                            categoryCenterRow.displayedLabel = categoryCenterRow.formatCategoryLabel(Variables.currentSettingsCategory);
                            categoryTextTranslate.y = Variables.spacing * 0.6;
                        }
                    }

                    ParallelAnimation {
                        NumberAnimation {
                            target: categoryCenterRow
                            property: "opacity"
                            to: 1.0
                            duration: Variables.fadeAnimation * 0.65
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: categoryTextTranslate
                            property: "y"
                            to: 0
                            duration: Variables.fadeAnimation * 0.65
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Connections {
                    target: Variables

                    function onCurrentSettingsCategoryChanged() {
                        const nextLabel = categoryCenterRow.formatCategoryLabel(Variables.currentSettingsCategory);
                        if (!Variables.settingsOpen) {
                            categorySwitchAnim.stop();
                            categoryCenterRow.displayedIcon = Variables.currentSettingsCategory.icon || "";
                            categoryCenterRow.displayedLabel = nextLabel;
                            categoryTextTranslate.y = 0;
                            categoryCenterRow.opacity = 1.0;
                        } else if (categoryCenterRow.displayedLabel !== nextLabel) {
                            categorySwitchAnim.restart();
                        }
                    }

                    function onSettingsOpenChanged() {
                        if (Variables.settingsOpen) {
                            categorySwitchAnim.stop();
                            categoryCenterRow.displayedIcon = Variables.currentSettingsCategory.icon || "";
                            categoryCenterRow.displayedLabel = categoryCenterRow.formatCategoryLabel(Variables.currentSettingsCategory);
                            categoryTextTranslate.y = 0;
                            categoryCenterRow.opacity = 1.0;
                        }
                    }
                }

                Text {
                    text: categoryCenterRow.displayedIcon
                    font.pixelSize: Variables.fontSize * 0.95
                    color: Variables.iconColor
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: categoryCenterRow.displayedLabel
                    textFormat: Text.PlainText
                    font.pixelSize: Variables.fontSize * 0.88
                    font.weight: Font.DemiBold
                    color: Variables.textColor
                    elide: Text.ElideRight
                }
            }
        }
    }
}