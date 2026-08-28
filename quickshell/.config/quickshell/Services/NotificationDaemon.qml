import QtQuick
import Quickshell.Services.Notifications
import "../"

Item {
    id: root

    width: 0
    height: 0

    readonly property alias server: notificationServer
    readonly property var trackedNotifications: notificationServer.trackedNotifications
    readonly property int trackedCount: notificationServer.trackedNotifications.values.length
    readonly property int popupCount: popupNotifications.length
    readonly property var currentPopup: popupNotifications.length > 0 ? popupNotifications[0] : null

    property int maxPopupCount: 4
    property var popupNotifications: []

    signal popupAdded(var notification)
    signal notificationClosed(var notification)

    function cleanText(value) {
        if (!value)
            return ""

        return String(value)
            .replace(/<br\s*\/?>/gi, "\n")
            .replace(/<\/p>/gi, "\n")
            .replace(/<[^>]*>/g, "")
            .replace(/&amp;/g, "&")
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">")
            .replace(/&quot;/g, "\"")
            .replace(/&#39;/g, "'")
            .trim()
    }

    function notificationTitle(notification) {
        if (!notification)
            return ""

        return cleanText(notification.summary || notification.appName || "Notification")
    }

    function notificationBody(notification) {
        return notification ? cleanText(notification.body || "") : ""
    }

    function notificationApp(notification) {
        return notification ? cleanText(notification.appName || "Notification") : "Notification"
    }

    function notificationImage(notification) {
        if (!notification)
            return ""

        return notification.image || notification.appIcon || ""
    }

    function timeoutFor(notification) {
        if (!notification || notification.expireTimeout < 0)
            return Math.max(Variables.notifInterval, 5000)

        if (notification.expireTimeout === 0)
            return 7000

        return Math.max(2500, notification.expireTimeout * 1000)
    }

    function showPopup(notification) {
        if (!notification || notification.transient)
            return

        var next = popupNotifications.filter(n => n && n.id !== notification.id)
        next.unshift(notification)
        popupNotifications = next.slice(0, maxPopupCount)

        Variables.currentNotif = notification
        Variables.notifWidget = true
        popupAdded(notification)
    }

    function removePopup(notification) {
        if (!notification)
            return

        popupNotifications = popupNotifications.filter(n => n && n.id !== notification.id)
        Variables.currentNotif = currentPopup
        Variables.notifWidget = popupNotifications.length > 0
        notificationClosed(notification)
    }

    function dismissNotification(notification) {
        if (!notification)
            return

        removePopup(notification)

        if (notification.tracked)
            notification.dismiss()
    }

    function expireNotification(notification) {
        if (!notification)
            return

        removePopup(notification)

        if (notification.tracked)
            notification.expire()
    }

    function invokeAction(action, notification) {
        if (!action)
            return

        action.invoke()

        if (notification && !notification.resident)
            removePopup(notification)
    }

    function clearPopups() {
        popupNotifications = []
        Variables.currentNotif = null
        Variables.notifWidget = false
    }

    function clearAll() {
        var list = trackedNotifications.values.slice();
        for (var i = 0; i < list.length; i++) {
            dismissNotification(list[i]);
        }
        clearPopups();
    }

    NotificationServer {
        id: notificationServer

        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: true
        imageSupported: true
        actionsSupported: true
        actionIconsSupported: true

        onNotification: notification => {
            notification.tracked = true

            if (!notification.lastGeneration && !Variables.disablePopups)
                root.showPopup(notification)
        }
    }
}
