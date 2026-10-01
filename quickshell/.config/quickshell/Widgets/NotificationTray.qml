import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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
    property var seenNotifs: []
    property bool isClearingAll: false
    property string expandedGroupKey: ""
    property var ungroupedGroupKeys: []

    readonly property var displayGroups: buildDisplayGroups(
        daemon ? daemon.groupedNotifications : [], ungroupedGroupKeys)

    function buildDisplayGroups(groups, ungroupedKeys) {
        var result = []

        for (var i = 0; i < groups.length; i++) {
            var group = groups[i]
            var isUngrouped = ungroupedKeys.indexOf(group.key) !== -1

            if (isUngrouped) {
                for (var j = 0; j < group.notifications.length; j++) {
                    var notification = group.notifications[j]
                    result.push({
                        key: group.key + ":" + notification.id,
                        groupKey: group.key,
                        appName: group.appName,
                        notifications: [notification],
                        isUngrouped: true,
                        groupCount: group.notifications.length
                    })
                }
            } else {
                result.push({
                    key: group.key,
                    groupKey: group.key,
                    appName: group.appName,
                    notifications: group.notifications,
                    isUngrouped: false,
                    groupCount: group.notifications.length
                })
            }
        }

        return result
    }

    function toggleGroupGrouping(groupKey) {
        var next = ungroupedGroupKeys.slice()
        var index = next.indexOf(groupKey)

        if (index === -1)
            next.push(groupKey)
        else
            next.splice(index, 1)

        ungroupedGroupKeys = next
        expandedGroupKey = ""
    }

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
                    root.ungroupedGroupKeys = [];
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

        model: root.displayGroups

        delegate: Item {
            id: delegateRect

            implicitWidth: notifList.width
            
            property var group: modelData
            property string groupKey: group && group.groupKey ? group.groupKey
                : (group && group.key ? group.key : Math.random().toString())
            property var notifications: group ? group.notifications : []
            property var latestNotification: notifications.length > 0 ? notifications[0] : null
            property bool isUngrouped: group && group.isUngrouped === true
            property int relatedCount: group && group.groupCount ? group.groupCount : notifications.length
            property bool isExpanded: !isUngrouped && root.expandedGroupKey !== "" && root.expandedGroupKey === groupKey
            property real targetHeight: isExpanded
                ? expandedLayout.implicitHeight
                : groupCard.implicitHeight

            property bool isReady: false
            property bool localRemoving: false
            property bool isRemoving: localRemoving || root.isClearingAll
            property bool animationsEnabled: false

            implicitHeight: (isReady && !isRemoving) ? targetHeight : 0
            opacity: (isReady && !isRemoving) ? 1.0 : 0.0
            scale: (isReady && !isRemoving) ? 1.0 : 0.9
            
            clip: true 

            Behavior on implicitHeight {
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
                id: groupCard

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                implicitHeight: groupCardBackground.implicitHeight
                
                opacity: delegateRect.isExpanded ? 0.0 : 1.0
                visible: opacity > 0
                Behavior on opacity {
                    enabled: delegateRect.animationsEnabled
                    NumberAnimation { duration: Variables.animationDurationUI }
                }

                Rectangle {
                    id: groupCardBackground

                    anchors.left: parent.left
                    anchors.right: parent.right
                    implicitHeight: contentLayout.implicitHeight + (Variables.spacing * 2)
                    color: Variables.uiColor
                    radius: Variables.radius
                    border.color: delegateRect.isUngrouped ? Variables.iconColor : Variables.borderColor
                    border.width: Variables.borderWidth

                    MouseArea {
                        id: collapsedMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: delegateRect.relatedCount > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton && delegateRect.relatedCount > 1) {
                                root.toggleGroupGrouping(delegateRect.groupKey)
                            } else if (mouse.button === Qt.LeftButton
                                       && !delegateRect.isUngrouped
                                       && delegateRect.notifications.length > 1) {
                                root.expandedGroupKey = delegateRect.groupKey
                            }
                        }
                    }

                    Rectangle {
                        id: ungroupedMarker

                        visible: delegateRect.isUngrouped && delegateRect.relatedCount > 1
                        implicitWidth: Variables.borderWidth * 2
                        implicitHeight: parent.height - Variables.spacing * 2
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        radius: Variables.barRadius
                        color: Variables.iconColor
                    }

                    RowLayout {
                        id: contentLayout

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            topMargin: Variables.spacing
                            rightMargin: Variables.spacing
                            bottomMargin: Variables.spacing
                            leftMargin: Variables.spacing
                                + (ungroupedMarker.visible ? Variables.spacing : 0)
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
                                          + (delegateRect.relatedCount > 1
                                              ? (delegateRect.isUngrouped
                                                  ? " [" + delegateRect.relatedCount + " related]"
                                                  : " (" + delegateRect.notifications.length + ")") : "")
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
                    id: expandedGroupHeader

                    anchors.left: parent.left
                    anchors.right: parent.right
                    implicitHeight: Variables.fontSize * 2 + Variables.spacing
                    color: Variables.uiColor
                    radius: Variables.radius
                    border.color: Variables.borderColor
                    border.width: Variables.borderWidth

                    Text {
                        anchors.centerIn: parent
                        color: Variables.textColor
                        font.pixelSize: Variables.fontSize * 0.9
                        font.bold: true
                        text: daemon && delegateRect.latestNotification
                            ? daemon.notificationApp(delegateRect.latestNotification)
                              + " (" + delegateRect.relatedCount + " notifications)"
                            : "Notifications"
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton)
                                root.toggleGroupGrouping(delegateRect.groupKey)
                            else
                                root.expandedGroupKey = ""
                        }
                    }
                }

                Repeater {
                    id: expandedRepeater

                    model: delegateRect.notifications

                    delegate: Item {
                        id: groupedNotificationWrapper

                        required property int index
                        required property var modelData

                        anchors.left: parent.left
                        anchors.right: parent.right
                        implicitHeight: groupedNotification.localRemoving
                            ? 0 : groupedNotification.implicitHeight
                        clip: true

                        Behavior on implicitHeight {
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

                            anchors.left: parent.left
                            anchors.right: parent.right
                            
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
