import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../" 

Rectangle {
    id: root

    implicitWidth: 368
    implicitHeight: 368
    radius: Variables.radius
    color: Variables.backgroundColorUI
    border.color: Variables.borderColor
    border.width: Variables.borderWidth

    property var daemon 
    property var seenNotifs: []
    property bool isClearingAll: false
    property string expandedGroupKey: ""

    RowLayout {
        id: headerLayout

        anchors {
            top: parent.top
            right: parent.right
            left: parent.left
            margins: Variables.topMargin * 2
        }
        spacing: Variables.spacing

        Rectangle {
            id: titleRect

            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Variables.uiColor
            radius: Variables.radius

            Text { 
                text: "Notifications"
                color: Variables.textColor
                anchors.centerIn: parent
                font.pixelSize: Variables.fontSize
            }
        }

        Button {
            id: togglePopupsButton

            Layout.preferredHeight: Variables.circleHeight * 1.5
            Layout.preferredWidth: Variables.circleWidth * 1.5

            text: Variables.disablePopups ? "" : ""

            contentItem: Text {
                text: parent.text
                font.pixelSize: Variables.fontSize * 1.2
                color: Variables.disablePopups ? Variables.uiColor : Variables.buttonColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            background: Rectangle {
                id: togglePopupsBg

                radius: Variables.circleRadius * 1.5
                color: Variables.disablePopups ? Variables.buttonColor : Variables.uiColor
                border.color: Variables.disablePopups ? Variables.uiColor : Variables.buttonColor
                border.width: Variables.borderWidth

                Behavior on color {
                    ColorAnimation { duration: Variables.animationDurationUI }
                } 
            }

            onClicked: {
                Variables.disablePopups = !Variables.disablePopups
            }
        }

        Rectangle {
            id: closeAllRect

            Layout.alignment: Qt.AlignRight
            Layout.preferredHeight: Variables.circleHeight * 1.5
            Layout.preferredWidth: Variables.circleWidth * 1.5
            
            radius: Variables.circleRadius * 1.5
            color: Variables.uiColor
            border.color: Variables.iconColor
            border.width: Variables.borderWidth
            opacity: closeAllMouse.pressed ? 0.85 : 1

            Text { 
                text: ""
                color: Variables.iconColor
                anchors.centerIn: parent
                font.pixelSize: Variables.fontSize * 1.2
            }

            MouseArea {
                id: closeAllMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.isClearingAll || notifList.count === 0) return; 
                    
                    root.isClearingAll = true;
                    clearAllTimer.start();
                }
            }

            Timer {
                id: clearAllTimer

                interval: Variables.animationDurationUI
                repeat: false
                onTriggered: {
                    daemon.clearAll();
                    root.isClearingAll = false; 
                    root.seenNotifs = []; 
                    root.expandedGroupKey = "";
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
            margins: Variables.topMargin
        }

        spacing: Variables.topMargin
        clip: true

        model: daemon ? daemon.groupedNotifications : []

        delegate: Item {
            id: delegateRect

            width: notifList.width
            
            property var group: modelData
            property string groupKey: group && group.key ? group.key : Math.random().toString()
            property var notifications: group ? group.notifications : []
            property var latestNotification: notifications.length > 0 ? notifications[0] : null
            property real maxStackOffset: notifications.length > 2 ? Variables.spacing * 1.5 : (notifications.length > 1 ? Variables.spacing * 0.75 : 0)
            property bool isExpanded: root.expandedGroupKey !== "" && root.expandedGroupKey === groupKey
            property real targetHeight: isExpanded
                ? expandedLayout.implicitHeight
                : collapsedContainer.implicitHeight

            property bool isReady: false
            property bool localRemoving: false
            property bool isRemoving: localRemoving || root.isClearingAll
            property bool animationsEnabled: false

            height: (isReady && !isRemoving) ? targetHeight : 0
            opacity: (isReady && !isRemoving) ? 1.0 : 0.0
            scale: (isReady && !isRemoving) ? 1.0 : 0.9
            
            clip: true 

            Behavior on height {
                enabled: animationsEnabled
                NumberAnimation { duration: Variables.animationDurationUI; easing.type: Variables.animationTypeUI }
            }
            Behavior on opacity {
                enabled: animationsEnabled
                NumberAnimation { duration: Variables.animationDurationUI; easing.type: Variables.animationTypeUI }
            }
            Behavior on scale {
                enabled: animationsEnabled
                NumberAnimation { duration: Variables.animationDurationUI; easing.type: Variables.animationTypeUI }
            }

            function markNotificationsSeen() {
                for (var i = 0; i < notifications.length; i++) {
                    if (root.seenNotifs.indexOf(notifications[i].id) === -1)
                        root.seenNotifs.push(notifications[i].id)
                }
            }

            onNotificationsChanged: markNotificationsSeen()

            Component.onCompleted: {
                markNotificationsSeen()
                isReady = true
                Qt.callLater(function() { animationsEnabled = true })
            }

            Item {
                id: collapsedContainer

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                
                implicitHeight: mainCollapsedCard.height + delegateRect.maxStackOffset
                
                opacity: delegateRect.isExpanded ? 0.0 : 1.0
                visible: opacity > 0
                Behavior on opacity {
                    enabled: delegateRect.animationsEnabled
                    NumberAnimation { duration: Variables.animationDurationUI }
                }

                Rectangle {
                    id: stackBottomCard

                    visible: delegateRect.notifications.length > 2
                    y: Variables.spacing * 1.5
                    z: -2
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - (Variables.spacing * 4)
                    height: mainCollapsedCard.height
                    color: Variables.uiColor
                    radius: Variables.radius
                    opacity: 0.5
                    border.color: Variables.borderColor
                    border.width: Variables.borderWidth
                }

                Rectangle {
                    id: stackMiddleCard

                    visible: delegateRect.notifications.length > 1
                    y: Variables.spacing * 0.75
                    z: -1
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - (Variables.spacing * 2)
                    height: mainCollapsedCard.height
                    color: Variables.uiColor
                    radius: Variables.radius
                    opacity: 0.8
                    border.color: Variables.borderColor
                    border.width: Variables.borderWidth
                }

                Rectangle {
                    id: mainCollapsedCard

                    y: 0
                    z: 0
                    width: parent.width
                    height: contentLayout.implicitHeight + (Variables.spacing * 2)
                    color: Variables.uiColor
                    radius: Variables.radius
                    border.color: Variables.borderColor
                    border.width: Variables.borderWidth

                    MouseArea {
                        id: collapsedMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: delegateRect.notifications.length > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (delegateRect.notifications.length > 1) {
                                root.expandedGroupKey = delegateRect.groupKey
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
                        spacing: Variables.spacing

                        Rectangle {
                            id: collapsedIconBox

                            Layout.preferredWidth: Variables.fontSize * 2
                            Layout.preferredHeight: Variables.fontSize * 2
                            radius: Variables.imgRadius
                            color: "transparent"
                            Layout.alignment: Qt.AlignTop
                            visible: daemon && delegateRect.latestNotification
                                && daemon.notificationImage(delegateRect.latestNotification) !== ""

                            Image {
                                id: collapsedIconImage

                                anchors.fill: parent
                                source: daemon && delegateRect.latestNotification
                                    ? daemon.notificationImage(delegateRect.latestNotification) : ""
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                            }
                        }

                        ColumnLayout {
                            id: collapsedTextColumn

                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            RowLayout {
                                id: collapsedHeaderRow

                                Layout.fillWidth: true
                                
                                Text {
                                    id: collapsedAppText

                                    Layout.fillWidth: true
                                    color: Variables.textColor
                                    elide: Text.ElideRight
                                    font.bold: true
                                    font.pixelSize: Variables.fontSize
                                    text: daemon && delegateRect.latestNotification
                                        ? daemon.notificationApp(delegateRect.latestNotification)
                                          + (delegateRect.notifications.length > 1
                                              ? " (" + delegateRect.notifications.length + ")" : "")
                                          + " - " + daemon.notificationTitle(delegateRect.latestNotification)
                                        : ""
                                }

                                Text {
                                    id: collapsedTimeText

                                    color: Variables.textColor
                                    opacity: 0.6
                                    font.pixelSize: Variables.fontSize * 0.8
                                    text: daemon && delegateRect.latestNotification
                                        ? daemon.notificationTime(delegateRect.latestNotification) : ""
                                }
                            }

                            Text {
                                id: collapsedBodyText

                                Layout.fillWidth: true
                                color: Variables.textColor
                                elide: Text.ElideRight
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                font.pixelSize: Variables.fontSize
                                text: daemon && delegateRect.latestNotification
                                    ? daemon.notificationBody(delegateRect.latestNotification) : ""
                            }
                        }

                        Rectangle {
                            id: collapsedCloseBtn

                            Layout.preferredWidth: Variables.circleWidth
                            Layout.preferredHeight: Variables.circleHeight 
                            Layout.alignment: Qt.AlignTop
                            radius: Variables.circleRadius
                            color: Variables.buttonColor

                            Text {
                                id: collapsedCloseText

                                anchors.fill: parent
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                color: Variables.textColor
                                text: "X"
                                font.bold: true
                            }

                            MouseArea {
                                id: collapsedCloseMouse
                                
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (delegateRect.isRemoving) return; 
                                    delegateRect.localRemoving = true;
                                    delegateRect.opacity = 0.0
                                    delegateRect.scale = 0.9
                                    
                                    collapsedRemovalTimer.start()
                                }
                            }

                            Timer {
                                id: collapsedRemovalTimer

                                interval: Variables.animationDurationUI
                                repeat: false
                                onTriggered: daemon.dismissNotification(delegateRect.latestNotification)
                            }
                        }
                    }
                }
            }

            Column {
                id: expandedLayout

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                spacing: Variables.topMargin
                
                opacity: delegateRect.isExpanded ? 1.0 : 0.0
                visible: opacity > 0
                Behavior on opacity {
                    enabled: delegateRect.animationsEnabled
                    NumberAnimation { duration: Variables.animationDurationUI }
                }

                Rectangle {
                    id: collapseGroupBtn

                    width: parent.width
                    height: Variables.fontSize * 2 + Variables.spacing
                    color: Variables.uiColor
                    radius: Variables.radius
                    border.color: Variables.borderColor
                    border.width: Variables.borderWidth

                    Text {
                        anchors.centerIn: parent
                        text: "▴ Collapse Stack"
                        color: Variables.textColor
                        font.pixelSize: Variables.fontSize * 0.9
                        font.bold: true
                    }

                    MouseArea {
                        id: collapseGroupMouse

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root.expandedGroupKey = ""
                    }
                    
                    opacity: collapseGroupMouse.containsMouse ? 0.8 : 1.0
                    Behavior on opacity { NumberAnimation { duration: Variables.animationDurationUI } }
                }

                Repeater {
                    id: expandedRepeater

                    model: delegateRect.notifications

                    delegate: Item {
                        id: groupedNotificationWrapper

                        required property int index
                        required property var modelData

                        width: expandedLayout.width
                        height: groupedNotification.localRemoving
                            ? 0 : groupedNotification.implicitHeight
                        clip: true

                        Behavior on height {
                            NumberAnimation {
                                duration: Variables.animationDurationUI
                                easing.type: Variables.animationTypeUI
                            }
                        }

                        Rectangle {
                            id: groupedNotification

                            property var notification: groupedNotificationWrapper.modelData
                            property bool localRemoving: false
                            property bool itemExpanded: false

                            width: parent.width
                            
                            implicitHeight: groupedCardLayout.implicitHeight + (Variables.spacing * 2)
                            color: Variables.uiColor
                            radius: Variables.radius
                            opacity: localRemoving ? 0 : 1
                            scale: localRemoving ? 0.9 : 1
                            border.color: Variables.borderColor
                            border.width: Variables.borderWidth

                            Behavior on opacity {
                                NumberAnimation { duration: Variables.animationDurationUI }
                            }
                            Behavior on scale {
                                NumberAnimation { duration: Variables.animationDurationUI }
                            }

                            MouseArea {
                                id: itemToggleMouse

                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                z: -1
                                onClicked: groupedNotification.itemExpanded = !groupedNotification.itemExpanded
                            }

                            RowLayout {
                                id: groupedCardLayout

                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: Variables.spacing
                                }
                                spacing: Variables.spacing

                                Rectangle {
                                    id: expandedIconBox

                                    Layout.preferredWidth: Variables.fontSize * 2
                                    Layout.preferredHeight: Variables.fontSize * 2
                                    radius: Variables.imgRadius
                                    color: "transparent"
                                    Layout.alignment: Qt.AlignTop
                                    visible: daemon && groupedNotification.notification
                                        && daemon.notificationImage(groupedNotification.notification) !== ""

                                    Image {
                                        id: expandedIconImage

                                        anchors.fill: parent
                                        source: daemon && groupedNotification.notification
                                            ? daemon.notificationImage(groupedNotification.notification) : ""
                                        fillMode: Image.PreserveAspectCrop
                                        smooth: true
                                    }
                                }

                                ColumnLayout {
                                    id: expandedTextColumn

                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter

                                    RowLayout {
                                        id: expandedHeaderRow

                                        Layout.fillWidth: true

                                        Text {
                                            id: expandedAppText

                                            Layout.fillWidth: true
                                            color: Variables.textColor
                                            elide: Text.ElideRight
                                            font.bold: true
                                            font.pixelSize: Variables.fontSize
                                            text: daemon && groupedNotification.notification
                                                ? daemon.notificationApp(groupedNotification.notification)
                                                  + " - "
                                                  + daemon.notificationTitle(groupedNotification.notification)
                                                : ""
                                        }

                                        Text {
                                            id: expandedTimeText

                                            color: Variables.textColor
                                            opacity: 0.6
                                            font.pixelSize: Variables.fontSize * 0.8
                                            text: daemon && groupedNotification.notification
                                                ? daemon.notificationTime(groupedNotification.notification) : ""
                                        }
                                    }

                                    Text {
                                        id: expandedBodyText

                                        Layout.fillWidth: true
                                        color: Variables.textColor
                                        wrapMode: Text.Wrap
                                        elide: Text.ElideRight
                                        
                                        maximumLineCount: groupedNotification.itemExpanded ? 999 : 2
                                        
                                        font.pixelSize: Variables.fontSize
                                        text: daemon && groupedNotification.notification
                                            ? daemon.notificationBody(groupedNotification.notification) : ""
                                    }

                                    RowLayout {
                                        id: expandedActionsRow

                                        Layout.fillWidth: true
                                
                                        visible: groupedNotification.itemExpanded
                                            && groupedNotification.notification
                                            && groupedNotification.notification.actions
                                            ? groupedNotification.notification.actions.length > 0 : false
                                        spacing: Variables.spacing / 2

                                        Repeater {
                                            id: actionsRepeater

                                            model: parent.visible && groupedNotification.notification
                                                && groupedNotification.notification.actions
                                                ? Math.min(groupedNotification.notification.actions.length, 2) : 0

                                            delegate: Rectangle {
                                                id: groupedActionButton

                                                required property int index
                                                readonly property var action: groupedNotification.notification
                                                    && groupedNotification.notification.actions
                                                    ? groupedNotification.notification.actions[index] : null

                                                Layout.preferredHeight: Variables.circleHeight
                                                Layout.fillWidth: true
                                                radius: Variables.radius
                                                color: Variables.buttonColor
                                                opacity: groupedActionMouse.pressed ? 0.85 : 1

                                                Text {
                                                    id: actionButtonText

                                                    anchors.centerIn: parent
                                                    color: Variables.textColor
                                                    textFormat: Text.PlainText
                                                    elide: Text.ElideRight
                                                    font.pixelSize: Variables.fontSize * 0.9
                                                    text: groupedActionButton.action && groupedActionButton.action.text
                                                        ? groupedActionButton.action.text : ""
                                                }

                                                MouseArea {
                                                    id: groupedActionMouse

                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (groupedActionButton.action)
                                                            daemon.invokeAction(groupedActionButton.action,
                                                                groupedNotification.notification)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: expandedCloseBtn

                                    Layout.preferredWidth: Variables.circleWidth
                                    Layout.preferredHeight: Variables.circleHeight
                                    Layout.alignment: Qt.AlignTop
                                    radius: Variables.circleRadius
                                    color: Variables.buttonColor

                                    Text {
                                        id: expandedCloseText

                                        anchors.fill: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        color: Variables.textColor
                                        text: "X"
                                        font.bold: true
                                    }

                                    MouseArea {
                                        id: expandedCloseMouse

                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (groupedNotification.localRemoving)
                                                return

                                            groupedNotification.localRemoving = true
                                            groupedRemovalTimer.start()
                                        }
                                    }

                                    Timer {
                                        id: groupedRemovalTimer

                                        interval: Variables.animationDurationUI
                                        repeat: false
                                        onTriggered: {
                                            if (daemon)
                                                daemon.dismissNotification(groupedNotification.notification)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Text {
            id: emptyStateText

            anchors.centerIn: parent
            text: "A tumbleweed tumbles..."
            color: Variables.textColor
            font.pixelSize: Variables.fontSize
            opacity: 0.5
            visible: notifList.count === 0
        }
    }
}