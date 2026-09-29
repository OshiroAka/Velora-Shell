import QtQuick
import "TimerGeometry.js" as Geometry
import "TopBarGeometry.js" as PanelSizes

// The approved timer sequence, shared only by the opted-in topbar menus.
FocusScope {
    id: root
    required property var controller
    property string desiredType: ""
    property string presentedType: ""
    property real barHeight: 40
    property bool reducedMotion: false
    property bool mounted: false
    property real reveal: 0
    property real contentReveal: 0
    property real anchorX: width / 2
    property real anchorWidth: 74
    property real bodyWidth: 300
    property real bodyHeight: 154
    property var anchorItem: controller.anchorItem
    default property alias content: contentHost.data
    readonly property var geometry: Geometry.panel(width, height, barHeight, anchorX,
        anchorWidth, bodyWidth, bodyHeight, reveal)
    readonly property rect panelRect: Qt.rect(geometry.x, geometry.y, geometry.width, geometry.height)
    readonly property real neckHalfWidth: geometry.neck
    readonly property bool interactive: desiredType === presentedType && desiredType.length > 0
        && reveal > 0.98 && contentReveal > 0.9 && !swapping.running
    readonly property bool pointerInside: presence.hovered
    readonly property bool pointerHeld: dragPresence.active
    readonly property real contentWidth: Math.max(0, geometry.targetWidth - 32)
    readonly property real contentHeight: Math.max(0, geometry.targetHeight - 32)
    visible: mounted

    function updateAnchor() {
        if (!anchorItem || !desiredType) return
        anchorWidth = anchorItem.width
        anchorX = anchorItem.mapToItem(root, anchorItem.width / 2, 0).x
    }
    function present() {
        presentedType = desiredType
        const size = PanelSizes.size(presentedType)
        bodyWidth = size[0]
        bodyHeight = size[1]
        updateAnchor()
    }
    function synchronize() {
        contentDelay.stop()
        opening.stop()
        entering.stop()
        closing.stop()
        swapping.stop()
        if (!desiredType) {
            if (mounted) closing.start()
        } else if (!mounted) {
            present()
            mounted = true
            forceActiveFocus()
            opening.start()
            contentDelay.restart()
        } else if (desiredType !== presentedType) {
            // Clear the old content before changing its layout; retain the shell.
            swapping.start()
        } else {
            updateAnchor()
            opening.start()
            contentDelay.restart()
        }
    }
    onDesiredTypeChanged: synchronize()
    onAnchorItemChanged: if (desiredType) Qt.callLater(updateAnchor)
    onWidthChanged: if (mounted) Qt.callLater(updateAnchor)
    Keys.onEscapePressed: controller.close()
    Behavior on anchorX { enabled: root.mounted; NumberAnimation { duration: root.reducedMotion ? 0 : 220; easing.type: Easing.InOutCubic } }
    Behavior on anchorWidth { enabled: root.mounted; NumberAnimation { duration: root.reducedMotion ? 0 : 220; easing.type: Easing.InOutCubic } }
    Behavior on bodyWidth { enabled: root.mounted; NumberAnimation { duration: root.reducedMotion ? 0 : 220; easing.type: Easing.InOutCubic } }
    Behavior on bodyHeight { enabled: root.mounted; NumberAnimation { duration: root.reducedMotion ? 0 : 220; easing.type: Easing.InOutCubic } }

    NumberAnimation { id: opening; target: root; property: "reveal"; to: 1; duration: root.reducedMotion ? 0 : 210; easing.type: Easing.OutCubic }
    Timer { id: contentDelay; interval: root.reducedMotion ? 1 : 135; onTriggered: entering.start() }
    NumberAnimation { id: entering; target: root; property: "contentReveal"; to: 1; duration: root.reducedMotion ? 0 : 150; easing.type: Easing.OutCubic }
    SequentialAnimation {
        id: swapping
        NumberAnimation { target: root; property: "contentReveal"; to: 0; duration: root.reducedMotion ? 0 : 65; easing.type: Easing.InCubic }
        ScriptAction { script: { root.present(); opening.start(); contentDelay.restart(); root.forceActiveFocus() } }
    }
    SequentialAnimation {
        id: closing
        NumberAnimation { target: root; property: "contentReveal"; to: 0; duration: root.reducedMotion ? 0 : 65; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "reveal"; to: 0; duration: root.reducedMotion ? 0 : 125; easing.type: Easing.InOutCubic }
        ScriptAction { script: if (!root.desiredType) { root.mounted = false; root.presentedType = "" } }
    }
    Item {
        // Include the curved seam and the small antialiasing fringe. Handlers
        // observe child controls without stealing their clicks or drags.
        x: root.panelRect.x - 8; y: root.barHeight
        width: root.panelRect.width + 16
        height: Math.max(0, root.panelRect.y + root.panelRect.height + 8 - y)
        HoverHandler { id: presence; blocking: false }
        PointHandler { id: dragPresence; acceptedButtons: Qt.AllButtons }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onWheel: wheel => { wheel.accepted = true }
        }
    Item {
        // Keep controls below the same pointer-observing ancestor. A sibling
        // hover area loses delivery when a Button or TextField takes the mouse.
        x: 12; y: root.panelRect.y + 4 - root.barHeight
        width: Math.max(0, root.panelRect.width - 8)
        height: Math.max(0, root.panelRect.height - 8)
        clip: true
        enabled: root.interactive
        opacity: root.contentReveal
        Item {
            id: contentHost
            x: 12; y: 12 - (1 - root.contentReveal) * 6
            width: root.contentWidth; height: root.contentHeight
            scale: 0.98 + 0.02 * root.contentReveal
            transformOrigin: Item.Top
        }
    }
    }
}
