pragma Singleton
import QtQuick
import QtCore      // Required for Settings in Qt 6
import Quickshell
import Quickshell.Io

Item {
    id: root

    // The Settings block automatically saves and loads these values to disk
    Settings {
        id: themeSettings
        category: "WallustColors"

        // Default values act as a fallback on the very first boot
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
    }

    // Expose the settings to the rest of your shell so you can still use `Colors.background`
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

    // Function to parse the incoming JSON and save it into Settings
    function applyColors(jsonString) {
        try {
            var colors = JSON.parse(jsonString);
            
            themeSettings.background = colors.background;
            themeSettings.foreground = colors.foreground;
            themeSettings.cursor = colors.cursor;
            
            themeSettings.color0 = colors.color0;
            themeSettings.color1 = colors.color1;
            themeSettings.color2 = colors.color2;
            themeSettings.color3 = colors.color3;
            themeSettings.color4 = colors.color4;
            themeSettings.color5 = colors.color5;
            themeSettings.color6 = colors.color6;
            themeSettings.color7 = colors.color7;
            
            themeSettings.color8 = colors.color8;
            themeSettings.color9 = colors.color9;
            themeSettings.color10 = colors.color10;
            themeSettings.color11 = colors.color11;
            themeSettings.color12 = colors.color12;
            themeSettings.color13 = colors.color13;
            themeSettings.color14 = colors.color14;
            themeSettings.color15 = colors.color15;
            
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