import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes
import "../"
import "../Modules"

PanelWindow {
    id: root

    readonly property real bw: Variables.borderWidth * 4
    readonly property real r: Variables.radius

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {}
    exclusionMode: ExclusionMode.Ignore

    Shape {
        id: shape
        anchors.fill: parent
        antialiasing: true

        ShapePath {
            id: framePath
            fillColor: Variables.uiColor
            strokeWidth: -1
            fillRule: ShapePath.OddEvenFill

            startX: 0
            startY: 0
            PathLine { x: shape.width; y: 0 }
            PathLine { x: shape.width; y: shape.height }
            PathLine { x: 0; y: shape.height }
            PathLine { x: 0; y: 0 }

            PathMove { x: root.bw + root.r; y: root.bw }
            PathLine { x: shape.width - root.bw - root.r; y: root.bw }
            PathArc { x: shape.width - root.bw; y: root.bw + root.r; radiusX: root.r; radiusY: root.r }
            PathLine { x: shape.width - root.bw; y: shape.height - root.bw - root.r }
            PathArc { x: shape.width - root.bw - root.r; y: shape.height - root.bw; radiusX: root.r; radiusY: root.r }
            PathLine { x: root.bw + root.r; y: shape.height - root.bw }
            PathArc { x: root.bw; y: shape.height - root.bw - root.r; radiusX: root.r; radiusY: root.r }
            PathLine { x: root.bw; y: root.bw + root.r }
            PathArc { x: root.bw + root.r; y: root.bw; radiusX: root.r; radiusY: root.r }
        }
    }
}