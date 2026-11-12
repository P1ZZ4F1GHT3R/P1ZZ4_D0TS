import QtQuick
import QtQuick.Controls
import "../"

FocusScope {
    id: root
    implicitWidth: 240
    implicitHeight: Variables.launcherSearchHeight

    property color bgColor: Variables.lockscreenColor
    property color textColor: Variables.uiColor
    property color placeholderColor: Qt.rgba(Variables.uiColor.r, Variables.uiColor.g, Variables.uiColor.b, 0.5)
    property color caretColor: Variables.uiColor
    property real cornerRadius: Variables.radius
    property real horizontalPadding: Variables.spacing * 1.5
    property int fontPixelSize: Variables.fontSize
    property string fontFamily: Variables.fontFamily

    property string text: ""
    property string placeholderText: ""
    property int horizontalAlignment: TextInput.AlignLeft
    property real charSpacing: 1
    property bool masked: false
    property bool revealTyping: true
    property int revealDuration: 300

    property real scrollShift: 0
    property real focusPop: 1.0
    readonly property bool hasFocus: innerInput.activeFocus
    readonly property alias inputItem: innerInput

    signal textEdited(string newText)
    signal accepted()

    Behavior on scrollShift { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

    function forceInputFocus() { innerInput.forceActiveFocus(); }

    function triggerShake() { shakeAnim.restart(); }

    function widthUpTo(index) {
        let w = 0;
        let limit = Math.min(index, charModel.count);
        for (let i = 0; i < limit; i++) {
            w += charModel.get(i).w + root.charSpacing;
        }
        return w;
    }

    readonly property real totalTextWidth: Math.max(0, widthUpTo(charModel.count) - (charModel.count > 0 ? root.charSpacing : 0))
    readonly property real alignOffset: {
        if (totalTextWidth > fieldArea.width) return 0;
        if (root.horizontalAlignment === TextInput.AlignHCenter) return (fieldArea.width - totalTextWidth) / 2;
        if (root.horizontalAlignment === TextInput.AlignRight) return fieldArea.width - totalTextWidth;
        return 0;
    }
    readonly property real scrollOffset: alignOffset + scrollShift

    function updateScroll() {
        let visibleW = fieldArea.width;
        if (visibleW <= 0 || totalTextWidth <= visibleW) {
            root.scrollShift = 0;
            return;
        }
        let curX = widthUpTo(innerInput.cursorPosition);
        let minOffset = visibleW - totalTextWidth;
        let curScreenX = curX + root.scrollOffset;
        if (curScreenX < 4) {
            root.scrollShift = Math.min(0, Math.max(minOffset, 4 - curX));
        } else if (curScreenX > visibleW - 6) {
            root.scrollShift = Math.min(0, Math.max(minOffset, visibleW - 6 - curX));
        } else {
            root.scrollShift = Math.min(0, Math.max(minOffset, root.scrollShift));
        }
    }

    onTextChanged: {
        if (innerInput.text !== root.text) {
            innerInput.text = root.text;
            syncModel();
        }
    }

    onHasFocusChanged: if (hasFocus) focusPopAnim.restart()

    function measureChar(ch) {
        charMetrics.text = ch;
        return Math.max(1, charMetrics.advanceWidth);
    }

    function syncModel() {
        let str = innerInput.text;
        let oldCount = charModel.count;
        let newCount = str.length;

        let prefix = 0;
        while (prefix < oldCount && prefix < newCount && charModel.get(prefix).ch === str[prefix]) prefix++;

        let suffix = 0;
        while (suffix < (oldCount - prefix) && suffix < (newCount - prefix)
               && charModel.get(oldCount - 1 - suffix).ch === str[newCount - 1 - suffix]) suffix++;

        let deleteCount = oldCount - prefix - suffix;
        if (deleteCount > 0) charModel.remove(prefix, deleteCount);

        let insertStr = str.slice(prefix, newCount - suffix);
        for (let i = 0; i < insertStr.length; i++) {
            let c = insertStr[i];
            charModel.insert(prefix + i, {
                ch: c,
                w: measureChar(c),
                stillPeeking: true
            });
        }

        if (root.masked && root.revealTyping) globalRevealTimer.restart();
        updateScroll();
    }

    TextMetrics {
        id: charMetrics
        font.family: root.fontFamily
        font.pixelSize: root.fontPixelSize
    }

    ListModel { id: charModel }

    Timer {
        id: globalRevealTimer
        interval: root.revealDuration
        onTriggered: {
            for (let i = 0; i < charModel.count; i++) {
                charModel.setProperty(i, "stillPeeking", false);
            }
        }
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: shakeT; property: "x"; from: 0; to: -6; duration: 45 }
        NumberAnimation { target: shakeT; property: "x"; from: -6; to: 6; duration: 45 }
        NumberAnimation { target: shakeT; property: "x"; from: 6; to: -4; duration: 45 }
        NumberAnimation { target: shakeT; property: "x"; from: -4; to: 4; duration: 45 }
        NumberAnimation { target: shakeT; property: "x"; from: 4; to: 0; duration: 45 }
    }

    SequentialAnimation {
        id: focusPopAnim
        NumberAnimation { target: root; property: "focusPop"; to: 1.03; duration: 100; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "focusPop"; to: 1.0; duration: 320; easing.type: Easing.OutQuint }
    }

    Rectangle {
        id: bgShape
        anchors.fill: parent
        radius: root.cornerRadius
        color: root.bgColor
        scale: root.focusPop
        Behavior on color { ColorAnimation { duration: Variables.animationDurationUI } }
        transform: Translate { id: shakeT; x: 0 }
    }

    Item {
        id: fieldArea
        anchors.fill: parent
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: root.horizontalPadding
        clip: true
        onWidthChanged: root.updateScroll()

        Text {
            text: root.placeholderText
            font.family: root.fontFamily
            font.pixelSize: root.fontPixelSize
            color: root.placeholderColor
            anchors.verticalCenter: parent.verticalCenter
            x: root.horizontalAlignment === TextInput.AlignHCenter ? (parent.width - implicitWidth) / 2 : 0
            opacity: charModel.count === 0 ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Rectangle {
            readonly property int selMin: Math.min(innerInput.selectionStart, innerInput.selectionEnd)
            readonly property int selMax: Math.max(innerInput.selectionStart, innerInput.selectionEnd)
            readonly property bool hasSelection: selMax > selMin
            anchors.verticalCenter: parent.verticalCenter
            height: root.fontPixelSize * 1.5
            radius: 4
            color: root.textColor
            opacity: hasSelection ? 0.25 : 0.0
            x: root.scrollOffset + root.widthUpTo(selMin)
            width: hasSelection ? Math.max(0, root.widthUpTo(selMax) - root.widthUpTo(selMin) - root.charSpacing) : 0
            Behavior on opacity { NumberAnimation { duration: 100 } }
            Behavior on x { NumberAnimation { duration: 60; easing.type: Easing.OutQuad } }
            Behavior on width { NumberAnimation { duration: 60; easing.type: Easing.OutQuad } }
        }

        ListView {
            id: charRow
            height: parent.height
            width: contentWidth
            x: root.scrollOffset
            orientation: ListView.Horizontal
            interactive: false
            spacing: root.charSpacing
            model: charModel

            add: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "scale"; from: 0.3; to: 1.0; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 3.0 }
                    NumberAnimation { property: "y"; from: 10; to: 0; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 2.4 }
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 140; easing.type: Easing.OutCubic }
                }
            }

            remove: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "scale"; to: 0.3; duration: 150; easing.type: Easing.InBack }
                    NumberAnimation { property: "y"; to: -8; duration: 150; easing.type: Easing.InCubic }
                    NumberAnimation { property: "opacity"; to: 0; duration: 130; easing.type: Easing.InCubic }
                }
            }

            displaced: Transition {
                NumberAnimation { properties: "x,y"; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
            }

            delegate: Item {
                required property string ch
                required property real w
                required property bool stillPeeking

                width: w
                height: charRow.height
                transformOrigin: Item.Center

                Text {
                    anchors.centerIn: parent
                    text: (!root.masked || (root.revealTyping && stillPeeking)) ? ch : "•"
                    color: root.textColor
                    font.family: root.fontFamily
                    font.pixelSize: root.fontPixelSize
                }
            }
        }

        Rectangle {
            id: caretRect
            width: 2
            height: root.fontPixelSize * 1.2
            color: root.caretColor
            visible: root.hasFocus
            anchors.verticalCenter: parent.verticalCenter
            property real slotX: root.widthUpTo(innerInput.cursorPosition)
            x: root.scrollOffset + slotX
            Behavior on slotX { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }

            SequentialAnimation on opacity {
                running: caretRect.visible
                loops: Animation.Infinite
                NumberAnimation { to: 0; duration: 100 }
                PauseAnimation { duration: 400 }
                NumberAnimation { to: 1; duration: 100 }
                PauseAnimation { duration: 400 }
            }
        }


        TextInput {
            id: innerInput
            anchors.fill: parent
            focus: true
            opacity: 0
            color: "transparent"
            selectByMouse: true
            font.family: root.fontFamily
            font.pixelSize: root.fontPixelSize

            onCursorPositionChanged: root.updateScroll()
            onSelectionStartChanged: root.updateScroll()
            onSelectionEndChanged: root.updateScroll()

            onTextEdited: {
                root.text = text;
                syncModel();
                root.textEdited(text);
            }

            onAccepted: root.accepted()
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        acceptedButtons: Qt.NoButton
    }
}