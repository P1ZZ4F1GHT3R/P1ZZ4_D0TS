import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

PanelWindow {
    id: screenCorners

    property bool fullscreenActive: false

    visible: Config.theme.enableCorners && Config.roundness > 0 && !fullscreenActive

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ambxst:screenCorners"
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region {
        item: null
    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    ScreenCornersContent {
        id: cornersContent
        anchors.fill: parent
        hasFullscreenWindow: screenCorners.fullscreenActive
    }
}
