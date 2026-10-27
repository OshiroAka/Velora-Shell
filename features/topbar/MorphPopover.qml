import QtQuick
import "../../core" as Core
import "TimerGeometry.js" as Geometry
import "TopBarGeometry.js" as PanelSizes

// One persistent connected surface; geometry leads, content follows.
FocusScope {
    id: root
    required property var controller
    property string desiredType: ""
    property string presentedType: ""
    property real barHeight: 40
    property real leftInset: 8
    property real rightInset: 8
    property var motion: defaultMotion
    Core.Motion { id: defaultMotion }
    property bool reducedMotion: motion.reduced
    property bool mounted: false
    property real reveal: 0
    property real contentReveal: 0
    // Same handoff as VeloraRailPopover: snapshot the current pose and
    // interpolate every dimension with one progress and one animation.
    property var handoffFrom: [width / 2, 74, 300, 154, 0]
    property var handoffTarget: [width / 2, 74, 300, 154, 0]
    property real handoffProgress: 1
    readonly property real anchorX: handoffFrom[0] + (handoffTarget[0] - handoffFrom[0]) * handoffProgress
    readonly property real anchorWidth: handoffFrom[1] + (handoffTarget[1] - handoffFrom[1]) * handoffProgress
    readonly property real bodyWidth: handoffFrom[2] + (handoffTarget[2] - handoffFrom[2]) * handoffProgress
    readonly property real bodyHeight: handoffFrom[3] + (handoffTarget[3] - handoffFrom[3]) * handoffProgress
    readonly property real cornerAttachment: handoffFrom[4] + (handoffTarget[4] - handoffFrom[4]) * handoffProgress
    property var anchorItem: controller.anchorItem
    default property alias content: contentHost.data
    readonly property var geometry: Geometry.panel(width, height, barHeight, anchorX,
        anchorWidth, bodyWidth, bodyHeight, reveal, leftInset, rightInset, cornerAttachment)
    readonly property rect panelRect: Qt.rect(geometry.x, geometry.y, geometry.width, geometry.height)
    readonly property real neckHalfWidth: geometry.neck
    readonly property bool interactive: desiredType === presentedType && desiredType.length > 0
        && reveal > 0.98 && contentReveal > 0.9 && !swapping.running
    readonly property bool geometryMoving: handoffMotion.running
    readonly property bool pointerInside: presence.hovered
    readonly property bool pointerHeld: dragPresence.active || contentViewport.dragging || contentViewport.flicking
    readonly property real contentWidth: Math.max(0, PanelSizes.size(presentedType === "calendar" ? "clock" : presentedType)[0] - 32)
    readonly property real contentHeight: Math.max(0, PanelSizes.size(presentedType === "calendar" ? "clock" : presentedType)[1] - 32)
    visible: mounted

    function currentPose() { return [anchorX, anchorWidth, bodyWidth, bodyHeight, cornerAttachment] }
    function updateAnchor() { if (desiredType) aim() }
    function aim() {
        const size = PanelSizes.size(desiredType === "calendar" ? "clock" : desiredType)
        const next = [anchorItem ? anchorItem.mapToItem(root, anchorItem.width / 2, 0).x : anchorX,
            anchorItem ? anchorItem.width : anchorWidth, size[0], size[1], desiredType === "toolbox" ? 1 : 0]
        if (next.every((value, i) => Math.abs(value - handoffTarget[i]) < .001)) return
        const pose = currentPose()
        handoffMotion.stop()
        handoffFrom = pose
        handoffTarget = next
        handoffProgress = mounted && !reducedMotion ? 0 : 1
        if (handoffProgress === 0) handoffMotion.restart()
    }
    function freezeGeometry() {
        const pose = currentPose()
        handoffMotion.stop()
        handoffFrom = pose
        handoffTarget = pose
        handoffProgress = 1
    }
    function present() { presentedType = desiredType }
    function queueContentEntrance(delay) {
        contentDelay.interval = Math.max(0, delay)
        contentDelay.restart()
    }
    function synchronize() {
        if (reducedMotion) {
            contentDelay.stop(); opening.stop(); entering.stop(); closing.stop(); swapping.stop()
            mounted = false
            handoffMotion.stop()
            handoffProgress = 1
            if (desiredType) { aim(); present() }
            else presentedType = ""
            reveal = desiredType ? 1 : 0
            contentReveal = reveal
            mounted = !!desiredType
            if (mounted) forceActiveFocus()
            return
        }
        if (!desiredType) {
            contentDelay.stop(); opening.stop(); entering.stop(); swapping.stop()
            freezeGeometry()
            if (mounted && !closing.running) closing.start()
        } else if (!mounted) {
            aim(); present()
            mounted = true
            forceActiveFocus()
            opening.start(); queueContentEntrance(motion.contentDelay)
        } else {
            const moving = geometryMoving || opening.running || entering.running
                || contentDelay.running || swapping.running || closing.running
            closing.stop()
            aim()
            if (reveal < .999 && !opening.running) opening.start()
            if (desiredType !== presentedType) {
                // A running exit presents the latest destination at its end.
                // Further destinations keep the entrance clock and opacity,
                // rather than repeatedly fading an already empty panel.
                if (swapping.running) return
                if (moving) {
                    present(); forceActiveFocus()
                } else {
                    swapping.start()
                    return
                }
            }
            if (!swapping.running && contentReveal < 1
                    && !entering.running && !contentDelay.running)
                queueContentEntrance(motion.contentDelay - motion.contentExit)
        }
    }
    onReducedMotionChanged: synchronize()
    onDesiredTypeChanged: synchronize()
    onAnchorItemChanged: if (desiredType) Qt.callLater(updateAnchor)
    onWidthChanged: if (mounted) Qt.callLater(updateAnchor)
    Keys.onEscapePressed: controller.close()
    NumberAnimation {
        id: handoffMotion
        target: root; property: "handoffProgress"; to: 1
        duration: root.motion.handoffDuration
        easing.type: root.motion.easeHandoff
    }

    NumberAnimation { id: opening; target: root; property: "reveal"; to: 1; duration: root.motion.geometryDuration; easing.type: root.motion.easeGeometry }
    Timer { id: contentDelay; interval: root.motion.contentDelay; onTriggered: if (root.desiredType) entering.start() }
    NumberAnimation { id: entering; target: root; property: "contentReveal"; to: 1; duration: root.motion.contentDuration; easing.type: root.motion.easeContent }
    SequentialAnimation {
        id: swapping
        NumberAnimation { target: root; property: "contentReveal"; to: 0; duration: root.motion.contentExit; easing.type: Easing.InCubic }
        ScriptAction { script: {
            root.present(); root.forceActiveFocus()
            root.queueContentEntrance(root.motion.contentDelay - root.motion.contentExit)
        } }
    }
    SequentialAnimation {
        id: closing
        NumberAnimation { target: root; property: "contentReveal"; to: 0; duration: root.motion.contentExit; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "reveal"; to: 0; duration: root.motion.closeDuration; easing.type: root.motion.easeHandoff }
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
        Flickable {
            id: contentViewport
            anchors.fill: parent
            anchors.margins: 12
            contentWidth: root.contentWidth
            contentHeight: root.contentHeight
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentWidth > width || contentHeight > height
            clip: true
        Item {
            id: contentHost
            y: -(1 - root.contentReveal) * 6
            width: root.contentWidth; height: root.contentHeight
            scale: 0.98 + 0.02 * root.contentReveal
            transformOrigin: Item.Top
        }
        }
    }
    }
}
