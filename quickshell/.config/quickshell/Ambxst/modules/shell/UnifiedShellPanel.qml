import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.modules.bar
import qs.modules.notch
import qs.modules.frame
import qs.modules.sidebar
import qs.modules.services
import qs.modules.globals
import qs.modules.components
import qs.config

PanelWindow {
    id: unifiedPanel

    required property ShellScreen targetScreen
    required property bool fullscreenActive
    screen: targetScreen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    // Dynamic keyboard focus: Exclusive when a notch module is open (so text fields work),
    // None otherwise (so compositor receives normal input).
    WlrLayershell.keyboardFocus: {
        if (notchContent.screenNotchOpen || assistantSidebar.active) {
            return WlrKeyboardFocus.Exclusive;
        }
        return WlrKeyboardFocus.None;
    }
    WlrLayershell.namespace: "ambxst"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore

    // Whether we need to capture full-screen input for click-outside detection.
    // True when notch modules are open OR any FocusGrab is active (e.g., BarPopups).
    readonly property bool needsFullScreenInput: notchContent.screenNotchOpen || FocusGrabManager.hasActiveGrab

    readonly property bool barEnabled: {
        if (!Config.barReady) return false;
        const list = Config.bar.screenList;
        return (!list || list.length === 0 || list.indexOf(targetScreen.name) !== -1);
    }

    readonly property alias barPosition: barContent.barPosition
    readonly property alias barPinned: barContent.pinned
    readonly property alias barHoverActive: barContent.hoverActive
    readonly property alias barFullscreen: barContent.activeWindowFullscreen
    readonly property bool barReveal: barEnabled && barContent.reveal
    readonly property alias barTargetWidth: barContent.barTargetWidth
    readonly property alias barTargetHeight: barContent.barTargetHeight
    readonly property alias barOuterMargin: barContent.baseOuterMargin

    readonly property string dockPosition: "bottom"
    readonly property bool dockPinned: false
    readonly property bool dockReveal: false
    readonly property bool dockFullscreen: false
    readonly property int dockHeight: 0

    readonly property alias notchHoverActive: notchContent.hoverActive
    readonly property alias notchOpen: notchContent.screenNotchOpen
    readonly property alias notchReveal: notchContent.reveal

    // Generic names for external compatibility (Visibilities expects these on the panel object)
    readonly property alias pinned: barContent.pinned
    readonly property bool reveal: barEnabled ? barContent.reveal : false
    readonly property alias hoverActive: barContent.hoverActive // Default hoverActive points to bar
    readonly property alias notch_hoverActive: notchContent.hoverActive // Used by bar to check notch

    readonly property bool unifiedEffectActive: false // Flag to notify children to disable internal borders

    readonly property bool hasFullscreenWindow: fullscreenActive

    // Proxy properties for Bar/Notch synchronization
    // Note: BarContent and NotchContent already handle their internal sync using Visibilities.

    // Helper properties for shadow logic
    readonly property bool keepBarShadow: Config.bar.keepBarShadow ?? false
    readonly property bool keepBarBorder: Config.bar.keepBarBorder ?? false
    readonly property bool containBar: Config.bar.containBar && (Config.bar.frameEnabled ?? false)

    Component.onCompleted: {
        Visibilities.registerBarPanel(screen.name, unifiedPanel);
        Visibilities.registerNotchPanel(screen.name, unifiedPanel);
        Visibilities.registerBar(screen.name, barContent);
        Visibilities.registerNotch(screen.name, notchContent.notchContainerRef);
    }

    Component.onDestruction: {
        Visibilities.unregisterBarPanel(screen.name);
        Visibilities.unregisterNotchPanel(screen.name);
        Visibilities.unregisterBar(screen.name);
        Visibilities.unregisterNotch(screen.name);
    }

    // Full-screen mask item (used when modules/popups are open)
    Item {
        id: fullScreenMask
        anchors.fill: parent
    }

    // Mask Region Logic
    // When a module or popup is open, expand to full-screen to capture click-outside.
    // Otherwise, restrict input to Bar, Notch, and Dock hitboxes only.
    mask: Region {
        // Full-screen capture when any module/popup is open
        item: unifiedPanel.needsFullScreenInput ? fullScreenMask : null
        regions: [
            Region {
                item: barContent.visible ? barContent.barHitbox : null
            },
            Region {
                item: notchContent.notchHitbox
            },
            Region {
                item: assistantSidebar.active ? assistantSidebar.hitbox : null
            }
        ]
    }

    // Focus Grab for Notch — registers with FocusGrabManager for click-outside coordination
    FocusGrab {
        id: focusGrab
        windows: [unifiedPanel]
        active: notchContent.screenNotchOpen

        onCleared: {
            Visibilities.setActiveModule("");
        }
    }

    FocusGrab {
        id: assistantFocusGrab
        windows: [unifiedPanel]
        active: assistantSidebar.active

        onCleared: {
            GlobalStates.hideAssistant();
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // CLICK-OUTSIDE BACKDROP
    // ═══════════════════════════════════════════════════════════════

    // Transparent backdrop that captures clicks on empty areas when modules/popups are open.
    // z: -1 ensures it's below all visual content (bar, notch, dock).
    MouseArea {
        id: backdropArea
        anchors.fill: parent
        visible: unifiedPanel.needsFullScreenInput
        z: -1

        onClicked: {
            FocusGrabManager.clearTopGrab();
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // VISUAL CONTENT
    // ═══════════════════════════════════════════════════════════════

    Item {
        id: visualContent
        anchors.fill: parent

        layer.enabled: true
        layer.effect: Shadow {}

        ScreenFrameContent {
            id: frameContent
            anchors.fill: parent
            targetScreen: unifiedPanel.targetScreen
            hasFullscreenWindow: unifiedPanel.hasFullscreenWindow
            z: 1
        }

        BarContent {
            id: barContent
            anchors.fill: parent
            screen: unifiedPanel.targetScreen
            fullscreenActive: unifiedPanel.fullscreenActive
            z: 2
            visible: unifiedPanel.barEnabled
        }

        NotchContent {
            id: notchContent
            unifiedEffectActive: unifiedPanel.unifiedEffectActive
            anchors.fill: parent
            screen: unifiedPanel.targetScreen
            z: 4
        }

        AssistantSidebar {
            id: assistantSidebar
            anchors.fill: parent
            targetScreen: unifiedPanel.targetScreen
            z: 5
        }
    }
}
