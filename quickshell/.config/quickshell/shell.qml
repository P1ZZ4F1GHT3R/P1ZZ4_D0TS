//@ pragma IconTheme Papirus-Dark

import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "./Components"
import "./Services"
import "./Modules"
import "./"

Scope {

    Bar{}
    IdleMonitor{}

    Loader {
        active: Variables.snippingMode
        sourceComponent: Component { SnippingOverlay {} }
    }
}