pragma Singleton
import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Item {
    id: root

    Settings {
        id: themeSettings
        category: "WallustColors"

        property color background: "#03040A"
        property color foreground: "#A9ABB1"
        property color cursor:     "#A6BDD3"

        property color color0:  "#46433B"
        property color color1:  "#414553"
        property color color2:  "#867680"
        property color color3:  "#8178BC"
        property color color4:  "#A49387"
        property color color5:  "#A3CFF5"
        property color color6:  "#E1CCEB"
        property color color7:  "#7C7F88"

        property color color8:  "#56595F"
        property color color9:  "#414553"
        property color color10: "#867680"
        property color color11: "#8178BC"
        property color color12: "#A49387"
        property color color13: "#A3CFF5"
        property color color14: "#E1CCEB"
        property color color15: "#7C7F88"

        Behavior on background { ColorAnimation { duration: Variables.animationDurationUI } }
        Behavior on foreground { ColorAnimation { duration: Variables.animationDurationUI } }
        Behavior on cursor     { ColorAnimation { duration: Variables.animationDurationUI } }

        Behavior on color0  { ColorAnimation { duration: Variables.animationDurationUI } }
        Behavior on color1  { ColorAnimation { duration: Variables.animationDurationUI } }
        Behavior on color2  { ColorAnimation { duration: Variables.animationDurationUI } }
        Behavior on color3  { ColorAnimation { duration: Variables.animationDurationUI } }
        Behavior on color4  { ColorAnimation { duration: Variables.animationDurationUI } }
        Behavior on color5  { ColorAnimation { duration: Variables.animationDurationUI } }
        Behavior on color6  { ColorAnimation { duration: Variables.animationDurationUI } }
        Behavior on color7  { ColorAnimation { duration: Variables.animationDurationUI } }

        Behavior on color8  { ColorAnimation { duration: Variables.animationDurationUI } }
        Behavior on color9  { ColorAnimation { duration: Variables.animationDurationUI } }
        Behavior on color10 { ColorAnimation { duration: Variables.animationDurationUI } }
        Behavior on color11 { ColorAnimation { duration: Variables.animationDurationUI } }
        Behavior on color12 { ColorAnimation { duration: Variables.animationDurationUI } }
        Behavior on color13 { ColorAnimation { duration: Variables.animationDurationUI } }
        Behavior on color14 { ColorAnimation { duration: Variables.animationDurationUI } }
        Behavior on color15 { ColorAnimation { duration: Variables.animationDurationUI } }
    }

    property alias background: themeSettings.background
    property alias foreground: themeSettings.foreground
    property alias cursor:     themeSettings.cursor
    
    property alias color0:  themeSettings.color0
    property alias color1:  themeSettings.color1
    property alias color2:  themeSettings.color2
    property alias color3:  themeSettings.color3
    property alias color4:  themeSettings.color4
    property alias color5:  themeSettings.color5
    property alias color6:  themeSettings.color6
    property alias color7:  themeSettings.color7
    
    property alias color8:  themeSettings.color8
    property alias color9:  themeSettings.color9
    property alias color10: themeSettings.color10
    property alias color11: themeSettings.color11
    property alias color12: themeSettings.color12
    property alias color13: themeSettings.color13
    property alias color14: themeSettings.color14
    property alias color15: themeSettings.color15

    function applyColors(jsonString) {
        try {
            var data = JSON.parse(jsonString);
            var colors = data.colors || data;
            var special = data.special || data;

            function valueOr(current, value) {
                return typeof value === "string" && value.length > 0 ? value : current;
            }
            
            themeSettings.background = valueOr(themeSettings.background, special.background);
            themeSettings.foreground = valueOr(themeSettings.foreground, special.foreground);
            themeSettings.cursor = valueOr(themeSettings.cursor, special.cursor);
            
            themeSettings.color0 = valueOr(themeSettings.color0, colors.color0);
            themeSettings.color1 = valueOr(themeSettings.color1, colors.color1);
            themeSettings.color2 = valueOr(themeSettings.color2, colors.color2);
            themeSettings.color3 = valueOr(themeSettings.color3, colors.color3);
            themeSettings.color4 = valueOr(themeSettings.color4, colors.color4);
            themeSettings.color5 = valueOr(themeSettings.color5, colors.color5);
            themeSettings.color6 = valueOr(themeSettings.color6, colors.color6);
            themeSettings.color7 = valueOr(themeSettings.color7, colors.color7);
            
            themeSettings.color8 = valueOr(themeSettings.color8, colors.color8);
            themeSettings.color9 = valueOr(themeSettings.color9, colors.color9);
            themeSettings.color10 = valueOr(themeSettings.color10, colors.color10);
            themeSettings.color11 = valueOr(themeSettings.color11, colors.color11);
            themeSettings.color12 = valueOr(themeSettings.color12, colors.color12);
            themeSettings.color13 = valueOr(themeSettings.color13, colors.color13);
            themeSettings.color14 = valueOr(themeSettings.color14, colors.color14);
            themeSettings.color15 = valueOr(themeSettings.color15, colors.color15);
            
        } catch(e) {
            console.error("Failed to parse colors JSON via IPC: " + e);
        }
    }

    IpcHandler {
        target: "Colors"

        function update(jsonStr: string): void {
            applyColors(jsonStr)
        }
    }
}