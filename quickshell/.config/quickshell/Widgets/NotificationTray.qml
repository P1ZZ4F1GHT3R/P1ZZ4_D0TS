import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"

Rectangle {
    id: root

    implicitWidth: Variables.notificationTraySize
    implicitHeight: Variables.notificationTraySize
    radius: Variables.radius
    color: Variables.backgroundColorUI
    border.color: Variables.borderColor
    border.width: Variables.borderWidth

    property var daemon
    property bool isClearingAll: false
    property var expandedGroups: []

    readonly property int cardAnimDuration: Math.round(Variables.activeDurationUI * 0.45)

    function toggleGroup(groupKey) {
        var next = expandedGroups.slice()
        var idx = next.indexOf(groupKey)
        if (idx === -1) next.push(groupKey)
        else next.splice(idx, 1)
        expandedGroups = next
    }

    RowLayout {
        id: headerLayout
        anchors {
            top: parent.top
            right: parent.right
            left: parent.left
            margins: Variables.topMargin * 2
        }
        spacing: Variables.spacing * 0.75

        Rectangle {
            id: titleRect
            Layout.fillWidth: true
            Layout.preferredHeight: Variables.circleHeight * 1.5
            color: Variables.uiColor
            radius: Variables.radius
            border.color: Variables.borderColor
            border.width: Variables.borderWidth

            Text {
                text: "Notifications"
                color: Variables.textColor
                anchors.centerIn: parent
                font.pixelSize: Variables.fontSize
            }
        }

        Rectangle {
            id: togglePopupsButton
            Layout.preferredHeight: Variables.circleHeight * 1.5
            Layout.preferredWidth: Variables.circleWidth * 1.5
            radius: width / 2
            color: Variables.disablePopups
                ? (togglePopupsMouse.containsMouse ? Variables.iconColor : Variables.buttonColor)
                : (togglePopupsMouse.containsMouse ? Variables.iconColor : Variables.uiColor)
            border.color: togglePopupsMouse.containsMouse ? Variables.buttonColor : Variables.borderColor
            border.width: Variables.borderWidth
            scale: togglePopupsMouse.pressed ? 0.92 : (togglePopupsMouse.containsMouse ? 1.06 : 1.0)

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
            Behavior on scale {
                NumberAnimation {
                    duration: Variables.activeDurationUI * 0.5
                    easing.type: Variables.activeAnimationUI
                }
            }

            Text {
                anchors.centerIn: parent
                text: Variables.disablePopups ? "" : ""
                font.pixelSize: Variables.fontSize * 1.15
                color: (Variables.disablePopups || togglePopupsMouse.containsMouse)
                    ? Variables.uiColor
                    : Variables.iconColor

                Behavior on color { ColorAnimation { duration: 140 } }
            }

            MouseArea {
                id: togglePopupsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Variables.disablePopups = !Variables.disablePopups
            }
        }

        Rectangle {
            id: closeAllRect
            Layout.preferredHeight: Variables.circleHeight * 1.5
            Layout.preferredWidth: Variables.circleWidth * 1.5
            radius: width / 2
            color: (closeAllMouse.containsMouse && notifList.count > 0) ? Variables.iconColor : Variables.uiColor
            border.color: (closeAllMouse.containsMouse && notifList.count > 0) ? Variables.buttonColor : Variables.borderColor
            border.width: Variables.borderWidth
            opacity: notifList.count > 0 ? 1.0 : 0.45
            scale: (closeAllMouse.pressed && notifList.count > 0) ? 0.92
                : ((closeAllMouse.containsMouse && notifList.count > 0) ? 1.06 : 1.0)

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
            Behavior on opacity { NumberAnimation { duration: Variables.fadeAnimation; easing.type: Easing.OutCubic } }
            Behavior on scale {
                NumberAnimation {
                    duration: Variables.activeDurationUI * 0.5
                    easing.type: Variables.activeAnimationUI
                }
            }

            Text {
                anchors.centerIn: parent
                text: ""
                color: (closeAllMouse.containsMouse && notifList.count > 0) ? Variables.uiColor : Variables.iconColor
                font.pixelSize: Variables.fontSize * 1.15

                Behavior on color { ColorAnimation { duration: 140 } }
            }

            MouseArea {
                id: closeAllMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: notifList.count > 0 && !root.isClearingAll
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (root.isClearingAll || notifList.count === 0) return;
                    root.isClearingAll = true;
                    clearAllTimer.start();
                }
            }

            Timer {
                id: clearAllTimer
                interval: root.cardAnimDuration
                onTriggered: {
                    if (root.daemon) root.daemon.clearAll();
                    root.isClearingAll = false;
                    root.expandedGroups = [];
                }
            }
        }
    }

    ListView {
        id: notifList
        anchors {
            top: headerLayout.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: Variables.topMargin * 2
            topMargin: Variables.spacing * 0.75
        }
        spacing: Variables.spacing * 0.75
        clip: true
        cacheBuffer: 0

        model: root.daemon ? root.daemon.groupedNotifications : []

        add: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: Variables.fadeAnimation
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "scale"
                    from: 0.94
                    to: 1.0
                    duration: root.cardAnimDuration
                    easing.type: Variables.activeAnimationUI
                }
            }
        }

        displaced: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: root.cardAnimDuration
                easing.type: Easing.OutCubic
            }
        }

        delegate: Column {
            id: groupColumn
            width: ListView.view.width
            spacing: isExpanded ? Variables.spacing * 0.5 : 0

            property var group: modelData
            property bool isExpanded: root.expandedGroups.indexOf(group.key) !== -1

            Behavior on spacing {
                NumberAnimation {
                    duration: root.cardAnimDuration
                    easing.type: Easing.OutCubic
                }
            }

            Repeater {
                model: groupColumn.group.notifications

                delegate: Item {
                    id: delegateWrapper
                    width: groupColumn.width

                    property var notification: modelData
                    property bool localRemoving: false
                    readonly property bool isRemoving: localRemoving || root.isClearingAll
                    readonly property int stackCount: groupColumn.group.notifications.length
                    readonly property bool isStackTop: !groupColumn.isExpanded && index === 0 && stackCount > 1
                    readonly property bool isVisibleInStack: (groupColumn.isExpanded || index === 0) && !isRemoving

                    property real stackOffset: isStackTop ? Math.min(2, stackCount - 1) * (Variables.spacing * 0.65) : 0
                    Behavior on stackOffset {
                        NumberAnimation {
                            duration: root.cardAnimDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    readonly property real targetCardHeight: contentLayout.implicitHeight + (Variables.spacing * 2)
                    height: isVisibleInStack ? (targetCardHeight + stackOffset) : 0
                    opacity: isVisibleInStack ? 1.0 : 0.0
                    scale: isVisibleInStack ? 1.0 : 0.95
                    visible: height > 0.5 || isVisibleInStack
                    clip: height < (targetCardHeight + stackOffset - 0.5)

                    Behavior on height {
                        NumberAnimation {
                            duration: root.cardAnimDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Variables.fadeAnimation * 0.85
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: root.cardAnimDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        id: backCardTwo
                        anchors {
                            left: parent.left
                            right: parent.right
                            leftMargin: Variables.spacing * 0.7
                            rightMargin: Variables.spacing * 0.7
                        }
                        y: delegateWrapper.isStackTop ? Variables.spacing * 1.3 : 0
                        height: contentCard.height
                        color: Variables.uiColor
                        radius: Variables.radius
                        border.color: Variables.borderColor
                        border.width: Variables.borderWidth
                        opacity: (delegateWrapper.isStackTop && delegateWrapper.stackCount > 2) ? 0.75 : 0.0
                        visible: opacity > 0.01

                        Behavior on y { NumberAnimation { duration: root.cardAnimDuration; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: Variables.fadeAnimation * 0.8; easing.type: Easing.OutCubic } }
                    }

                    Rectangle {
                        id: backCardOne
                        anchors {
                            left: parent.left
                            right: parent.right
                            leftMargin: Variables.spacing * 0.35
                            rightMargin: Variables.spacing * 0.35
                        }
                        y: delegateWrapper.isStackTop ? Variables.spacing * 0.65 : 0
                        height: contentCard.height
                        color: Variables.uiColor
                        radius: Variables.radius
                        border.color: Variables.borderColor
                        border.width: Variables.borderWidth
                        opacity: (delegateWrapper.isStackTop && delegateWrapper.stackCount > 1) ? 0.9 : 0.0
                        visible: opacity > 0.01

                        Behavior on y { NumberAnimation { duration: root.cardAnimDuration; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: Variables.fadeAnimation * 0.8; easing.type: Easing.OutCubic } }
                    }

                    Rectangle {
                        id: contentCard
                        width: parent.width
                        height: delegateWrapper.targetCardHeight

                        property bool itemExpanded: false

                        color: Variables.uiColor
                        radius: Variables.radius
                        border.color: cardMouse.containsMouse ? Variables.iconColor : Variables.borderColor
                        border.width: Variables.borderWidth
                        scale: cardMouse.pressed ? 0.985 : 1.0
                        clip: true

                        Behavior on height {
                            NumberAnimation {
                                duration: root.cardAnimDuration
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on border.color {
                            ColorAnimation { duration: 140 }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 140
                                easing.type: Easing.OutCubic
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton && delegateWrapper.stackCount > 1) {
                                    root.toggleGroup(groupColumn.group.key)
                                } else if (mouse.button === Qt.LeftButton) {
                                    contentCard.itemExpanded = !contentCard.itemExpanded
                                }
                            }
                        }

                        RowLayout {
                            id: contentLayout
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: Variables.spacing
                            }
                            spacing: Variables.spacing * 0.75

                            Rectangle {
                                Layout.preferredWidth: Variables.fontSize * 2
                                Layout.preferredHeight: Variables.fontSize * 2
                                radius: Variables.imgRadius
                                color: "transparent"
                                Layout.alignment: Qt.AlignTop
                                visible: daemon && notification && daemon.notificationImage(notification) !== ""

                                Image {
                                    anchors.fill: parent
                                    source: daemon && notification ? daemon.notificationImage(notification) : ""
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: Variables.spacing * 0.35

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Variables.spacing * 0.5

                                    Text {
                                        Layout.fillWidth: true
                                        color: Variables.textColor
                                        elide: Text.ElideRight
                                        font.bold: true
                                        font.pixelSize: Variables.fontSize
                                        text: {
                                            if (!daemon || !notification) return "";
                                            let title = daemon.notificationTitle(notification);
                                            let app = daemon.notificationApp(notification);
                                            return app + " - " + title;
                                        }
                                    }

                                    Rectangle {
                                        id: stackBadge
                                        visible: index === 0 && delegateWrapper.stackCount > 1
                                        Layout.preferredHeight: Variables.circleHeight * 0.9
                                        implicitWidth: stackBadgeRow.implicitWidth + Variables.spacing
                                        radius: height / 2
                                        color: stackBadgeMouse.containsMouse ? Variables.iconColor : Variables.backgroundColorUI
                                        border.color: stackBadgeMouse.containsMouse ? Variables.buttonColor : Variables.borderColor
                                        border.width: 1
                                        scale: stackBadgeMouse.pressed ? 0.92 : 1.0

                                        Behavior on color { ColorAnimation { duration: 140 } }
                                        Behavior on border.color { ColorAnimation { duration: 140 } }
                                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                                        Row {
                                            id: stackBadgeRow
                                            anchors.centerIn: parent
                                            spacing: 3

                                            Text {
                                                text: delegateWrapper.stackCount
                                                font.pixelSize: Variables.fontSize * 0.72
                                                font.bold: true
                                                color: stackBadgeMouse.containsMouse ? Variables.uiColor : Variables.textColor
                                            }

                                            Text {
                                                text: "▾"
                                                font.pixelSize: Variables.fontSize * 0.72
                                                color: stackBadgeMouse.containsMouse ? Variables.uiColor : Variables.iconColor
                                                rotation: groupColumn.isExpanded ? 180 : 0

                                                Behavior on rotation {
                                                    NumberAnimation {
                                                        duration: root.cardAnimDuration
                                                        easing.type: Easing.OutCubic
                                                    }
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: stackBadgeMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.toggleGroup(groupColumn.group.key)
                                        }
                                    }

                                    Text {
                                        color: Variables.textColor
                                        opacity: 0.6
                                        font.pixelSize: Variables.fontSize * 0.8
                                        text: daemon && notification ? daemon.notificationTime(notification) : ""
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    color: Variables.textColor
                                    elide: Text.ElideRight
                                    wrapMode: Text.Wrap
                                    maximumLineCount: contentCard.itemExpanded ? 999 : 2
                                    font.pixelSize: Variables.fontSize * 0.92
                                    text: daemon && notification ? daemon.notificationBody(notification) : ""
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.topMargin: Variables.spacing * 0.25
                                    visible: contentCard.itemExpanded && notification && notification.actions && notification.actions.length > 0
                                    spacing: Variables.spacing / 2

                                    Repeater {
                                        model: parent.visible && notification && notification.actions ? Math.min(notification.actions.length, 2) : 0

                                        delegate: Rectangle {
                                            id: actionPill
                                            required property int index
                                            readonly property var action: notification.actions[index]

                                            Layout.preferredHeight: Variables.circleHeight
                                            Layout.fillWidth: true
                                            radius: Variables.radius
                                            color: actionPillMouse.containsMouse ? Variables.iconColor : Variables.buttonColor
                                            border.color: actionPillMouse.containsMouse ? Variables.buttonColor : Variables.borderColor
                                            border.width: 1
                                            scale: actionPillMouse.pressed ? 0.95 : 1.0

                                            Behavior on color { ColorAnimation { duration: 140 } }
                                            Behavior on border.color { ColorAnimation { duration: 140 } }
                                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                                            Text {
                                                anchors.centerIn: parent
                                                color: actionPillMouse.containsMouse ? Variables.uiColor : Variables.textColor
                                                font.pixelSize: Variables.fontSize * 0.85
                                                text: action && action.text ? action.text : ""

                                                Behavior on color { ColorAnimation { duration: 140 } }
                                            }

                                            MouseArea {
                                                id: actionPillMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (action && root.daemon) root.daemon.invokeAction(action, notification)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: dismissBtn
                                Layout.preferredWidth: Variables.circleWidth
                                Layout.preferredHeight: Variables.circleHeight
                                Layout.alignment: Qt.AlignTop
                                radius: width / 2
                                color: dismissMouse.containsMouse ? Variables.buttonColor : Variables.backgroundColorUI
                                border.color: dismissMouse.containsMouse ? Variables.iconColor : Variables.borderColor
                                border.width: 1
                                scale: dismissMouse.pressed ? 0.9 : (dismissMouse.containsMouse ? 1.08 : 1.0)

                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: Variables.activeDurationUI * 0.45
                                        easing.type: Variables.activeAnimationUI
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    color: dismissMouse.containsMouse ? Variables.uiColor : Variables.textColor
                                    text: "✕"
                                    font.pixelSize: Variables.fontSize * 0.78
                                    font.bold: true

                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }

                                MouseArea {
                                    id: dismissMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (delegateWrapper.isRemoving) return;
                                        if (delegateWrapper.isStackTop) {
                                            contentCard.itemExpanded = false;
                                            if (root.daemon) root.daemon.dismissNotification(notification);
                                            return;
                                        }
                                        delegateWrapper.localRemoving = true;
                                        collapsedRemovalTimer.start();
                                    }
                                }

                                Timer {
                                    id: collapsedRemovalTimer
                                    interval: root.cardAnimDuration
                                    onTriggered: {
                                        if (root.daemon) root.daemon.dismissNotification(notification);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: "A tumbleweed tumbles..."
            color: Variables.textColor
            font.pixelSize: Variables.fontSize
            opacity: (notifList.count === 0 && !root.isClearingAll) ? 0.5 : 0.0
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation {
                    duration: Variables.fadeAnimation
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}