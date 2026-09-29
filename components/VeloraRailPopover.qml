pragma ComponentBehavior: Bound
import QtQuick
import "../features/topbar" as TopBar

// Shared motion and input for panels extending out of the sidebar.
FocusScope {
    id: root
    required property var theme
    required property var system
    property string toolType: "caffeine"
    property real preferredWidth: 300
    property real preferredHeight: 268
    property Component customContent: null
    property real contentPadding: 16
    property bool extraHovered: false
    property var extension: null
    property bool closeOnLeave: true
    property bool rightSide: false
    property real railWidth: 64
    property real anchorY: 260
    property bool triggerHovered: false
    property bool blocked: false
    property bool opened: false
    property bool mounted: false
    property real reveal: 0
    property real contentReveal: 0
    property var handoffSource: null
    property bool handoffActive: false
    property real handoffProgress: 1
    property real handoffFromWidth: 0
    property real handoffFromHeight: 0
    property real handoffFromY: 0
    readonly property bool handoffShrinking: handoffFromWidth > targetWidth + 4 || handoffFromHeight > targetHeight + 4
    readonly property real targetWidth: Math.min(preferredWidth, Math.max(0, width - railWidth - 16))
    readonly property real targetHeight: Math.min(preferredHeight, Math.max(0, height - 48))
    readonly property real bodyWidth: handoffActive ? handoffFromWidth + (targetWidth - handoffFromWidth) * handoffProgress : targetWidth * reveal
    readonly property real bodyHeight: handoffActive ? handoffFromHeight + (targetHeight - handoffFromHeight) * handoffProgress : 34 + (targetHeight - 34) * reveal
    readonly property real targetY: Math.max(24, Math.min(height - targetHeight - 24, anchorY - targetHeight / 2))
    readonly property real bodyY: handoffActive ? handoffFromY + (targetY - handoffFromY) * handoffProgress : Math.max(24, Math.min(height - bodyHeight - 24, anchorY - bodyHeight / 2))
    readonly property var outline: ({visible: mounted, y: bodyY, width: bodyWidth, height: bodyHeight, extension: extension})
    property alias maskItem: presenceArea
    readonly property bool panelHovered: presence.hovered || extraHovered
    readonly property bool panelHeld: hold.active || !!(contentLoader.item && contentLoader.item.interactionHeld)
    signal opening()
    signal shapeChanged()
    onOutlineChanged: shapeChanged()
    onPanelHoveredChanged: updatePresence()
    onPanelHeldChanged: updatePresence()
    onTriggerHoveredChanged: {
        if (!triggerHovered) blocked = false
        updatePresence()
    }
    onEnabledChanged: if (!enabled) close()

    function updatePresence() {
        if ((triggerHovered && !blocked) || panelHovered || panelHeld) {
            leaveDelay.stop()
            if (!opened && enabled && !blocked) {
                if (handoffSource && handoffSource !== root && handoffSource.opened) open()
                else enterDelay.restart()
            }
        } else {
            enterDelay.stop()
            if (mounted && closeOnLeave) leaveDelay.restart()
        }
    }
    function open() {
        if (!enabled || !system) return
        enterDelay.stop(); leaveDelay.stop(); closing.stop()
        const previous = handoffSource && handoffSource !== root && handoffSource.opened ? handoffSource : null
        if (previous) {
            handoffFromWidth = previous.bodyWidth
            handoffFromHeight = previous.bodyHeight
            handoffFromY = previous.bodyY
            previous.closeInstant()
            handoffActive = true
            handoffProgress = 0
            reveal = 1
        }
        opened = true; mounted = true
        opening()
        forceActiveFocus()
        if (previous) handoffMotion.restart()
        else expanding.restart()
        contentDelay.restart()
    }
    function closeInstant() {
        enterDelay.stop(); leaveDelay.stop(); closing.stop(); expanding.stop()
        contentDelay.stop(); entering.stop(); handoffMotion.stop()
        opened = false; mounted = false; reveal = 0; contentReveal = 0
        handoffActive = false; handoffProgress = 1
    }
    function close() {
        enterDelay.stop(); leaveDelay.stop(); expanding.stop()
        contentDelay.stop(); entering.stop()
        if (handoffActive) { handoffMotion.stop(); handoffActive = false; handoffProgress = 1 }
        opened = false
        if (mounted) closing.restart()
    }
    function toggle() {
        if (opened) { blocked = triggerHovered; close() }
        else { blocked = false; open() }
    }
    Keys.onEscapePressed: { blocked = triggerHovered; close() }
    Timer { id: enterDelay; interval: 70; onTriggered: root.open() }
    Timer { id: leaveDelay; interval: 180; onTriggered: if (root.closeOnLeave && !root.triggerHovered && !root.panelHovered && !root.panelHeld) root.close() }
    NumberAnimation { id: expanding; target: root; property: "reveal"; to: 1; duration: 210; easing.type: Easing.OutCubic }
    NumberAnimation { id: handoffMotion; target: root; property: "handoffProgress"; to: 1; duration: root.handoffShrinking ? 350 : 270; easing.type: Easing.InOutCubic; onFinished: root.handoffActive = false }
    Timer { id: contentDelay; interval: root.handoffActive && root.handoffShrinking ? 205 : 135; onTriggered: entering.restart() }
    NumberAnimation { id: entering; target: root; property: "contentReveal"; to: 1; duration: 150; easing.type: Easing.OutCubic }
    SequentialAnimation {
        id: closing
        NumberAnimation { target: root; property: "contentReveal"; to: 0; duration: 65; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "reveal"; to: 0; duration: 125; easing.type: Easing.InOutCubic }
        ScriptAction { script: if (!root.opened) root.mounted = false }
    }
    Item {
        id: presenceArea
        // Include the rail's edge and the curved join while crossing to buttons.
        x: root.rightSide ? root.width - root.railWidth - root.bodyWidth : root.railWidth - 16
        y: root.bodyY - 12
        width: root.mounted ? root.bodyWidth + 16 : 0
        height: root.mounted ? root.bodyHeight + 24 : 0
        visible: root.mounted
        HoverHandler { id: presence; blocking: false }
        PointHandler { id: hold; acceptedButtons: Qt.LeftButton | Qt.RightButton }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            // Consume clicks on empty or disabled controls inside the panel.
            // Otherwise the full-screen outside catcher closes the popover.
            onPressed: mouse => mouse.accepted = true
        }
        Item {
            x: root.rightSide ? 0 : 16; y: 12
            width: root.bodyWidth; height: root.bodyHeight
            clip: true
            Item {
                x: root.contentPadding; y: root.contentPadding - (1 - root.contentReveal) * 6
                width: root.targetWidth - 2 * root.contentPadding; height: root.targetHeight - 2 * root.contentPadding
                opacity: root.contentReveal
                enabled: root.opened && root.reveal > 0.98 && root.contentReveal > 0.9
                Loader {
                    id: contentLoader
                    anchors.fill: parent
                    sourceComponent: root.customContent || toolsContent
                }
                Component {
                    id: toolsContent
                    TopBar.MicroToolsPanel {
                        active: root.mounted && !!root.theme && !!root.system
                        type: root.toolType
                        theme: root.theme; system: root.system
                        controller: root; actions: null
                    }
                }
            }
        }
    }
}
