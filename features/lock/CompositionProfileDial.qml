import QtQuick
import QtQuick.Shapes

Item {
    id: root

    required property bool presented
    required property var profileService
    required property var theme
    required property var motion

    // The extra width lives *inside* the main panel.  It lets this single
    // surface round its shoulders into the wall instead of ending in a
    // visibly clipped vertical edge.
    width: 184
    height: 330
    clip: true
    visible: presented && profileService.ready
    opacity: visible ? 1 : 0

    property int selectedIndex: 0
    property real previousDragY: 0
    property real dragDistance: 0
    property string gestureStartProfileId: ""
    property bool forcedOpen: false
    property real morphTarget: 0
    property real morphLevel: morphTarget
    property bool waveClosing: false
    readonly property bool dragging: dialDrag.active
    readonly property bool pointerPresent: edgeHover.hovered
        || railHover.hovered || dialHover.hovered
    readonly property bool expanded: morphLevel > 0.54 || forcedOpen || dragging
    readonly property bool railVisible: morphLevel > 0.006
        || pointerPresent || forcedOpen || dragging
    readonly property int pageSize: 7
    readonly property int pageCount: Math.max(1,
        Math.ceil(profileService.profiles.length / pageSize))
    readonly property int currentPage: Math.floor(selectedIndex / pageSize)
    readonly property int pageStart: currentPage * pageSize
    readonly property real joinOverlap: 22
    readonly property real wallX: width - joinOverlap
    readonly property real centerX: wallX - 10
    readonly property real centerY: height / 2
    readonly property real arcRadius: 132

    function stagedValue(level, hiddenValue, tabValue, openValue) {
        const clamped = Math.max(0, Math.min(1, level))
        const tabStop = 0.32
        if (clamped <= tabStop)
            return hiddenValue + (tabValue - hiddenValue) * clamped / tabStop
        return tabValue + (openValue - tabValue)
            * (clamped - tabStop) / (1 - tabStop)
    }

    // While retracting, the same scalar that shrinks the surface adds a small
    // damped swell.  QML and the native SDF receive this exact geometry, so
    // the highlight moves like water instead of cross-fading two shapes.
    readonly property real waveEnvelope: waveClosing
        ? Math.sin(Math.PI * Math.max(0, Math.min(1, morphLevel))) : 0
    // One restrained outward breath is enough to suggest water.  The former
    // multi-cycle oscillation bent the capsule while it was retracting.
    readonly property real waveSwell: waveEnvelope * 2.4
    readonly property real surfaceDepth: stagedValue(morphLevel, 0, 44,
        arcRadius + 9) + waveSwell
    readonly property real surfaceHalfHeight: stagedValue(morphLevel, 0, 110,
        arcRadius + 9) + waveEnvelope * 1.6
    readonly property real surfaceStraightHalfHeight: stagedValue(morphLevel,
        0, 54, 0)
    readonly property real shoulderInset: Math.min(18,
        surfaceHalfHeight * 0.45, surfaceDepth * 0.80)

    function revealFromPointer() {
        closeDelay.stop()
        waveClosing = false
        // Re-entering the still expanded liquid keeps it expanded.  The
        // first edge hover only reveals the compact brush tab.
        morphTarget = morphLevel > 0.50 ? 1 : 0.32
    }

    function queueLiquidClose() {
        if (dragging)
            return
        if (morphTarget <= 0 && morphLevel <= 0.01)
            return
        closeDelay.restart()
    }

    function updatePointerState() {
        if (pointerPresent)
            revealFromPointer()
        else
            queueLiquidClose()
    }

    onPointerPresentChanged: updatePointerState()
    onForcedOpenChanged: {
        if (forcedOpen) {
            closeDelay.stop()
            waveClosing = false
            morphTarget = 1
        } else if (pointerPresent) {
            waveClosing = false
            morphTarget = 0.32
        } else {
            queueLiquidClose()
        }
    }

    Timer {
        id: closeDelay
        interval: 160
        repeat: false
        onTriggered: {
            if (root.dragging || root.pointerPresent)
                return
            root.forcedOpen = false
            root.waveClosing = true
            root.morphTarget = 0
        }
    }

    Behavior on morphLevel {
        NumberAnimation {
            duration: root.waveClosing ? 850 : root.motion.morph
            easing.type: root.waveClosing ? Easing.InOutSine : Easing.OutCubic
            onStopped: {
                if (root.morphTarget <= 0.001 && root.morphLevel <= 0.01)
                    root.waveClosing = false
            }
        }
    }

    function syncSelection() {
        const activeId = String(profileService.activeProfileId || "")
        for (let index = 0; index < profileService.profiles.length; index += 1) {
            if (String(profileService.profiles[index].id) === activeId) {
                selectedIndex = index
                return
            }
        }
        selectedIndex = 0
    }

    function selectStep(delta) {
        const count = profileService.profiles.length
        if (count < 1 || profileService.busy)
            return false
        selectedIndex = (selectedIndex + delta + count) % count
        const profile = profileService.profiles[selectedIndex]
        return profileService.applyProfile(String(profile.id), true)
    }

    function beginGesture() {
        gestureStartProfileId = String(profileService.activeProfileId || "")
        previousDragY = dialDrag.translation.y
        dragDistance = 0
        forcedOpen = true
    }

    function updateGesture() {
        const currentY = dialDrag.translation.y
        dragDistance += currentY - previousDragY
        previousDragY = currentY
        while (Math.abs(dragDistance) >= 28) {
            const direction = dragDistance > 0 ? 1 : -1
            selectStep(direction)
            dragDistance -= direction * 28
        }
    }

    function finishGesture() {
        forcedOpen = false
        gestureStartProfileId = ""
        dragDistance = 0
        if (!pointerPresent)
            queueLiquidClose()
    }

    function cancelGesture() {
        if (!dragging && !forcedOpen)
            return false
        const restoreId = gestureStartProfileId
        forcedOpen = false
        gestureStartProfileId = ""
        if (restoreId.length > 0)
            profileService.applyProfile(restoreId, true)
        return true
    }

    Behavior on opacity {
        NumberAnimation { duration: root.motion.selection }
    }

    HoverHandler {
        id: dialHover
        enabled: root.railVisible
    }

    // One path morphs from the hover tab into the complete roulette surface.
    // Keeping the translucent material in a single fill avoids darker seams
    // where several glass rectangles used to overlap.
    Shape {
        id: dialSurface
        anchors.fill: parent
        // The material remains present until its geometry reaches zero.  A
        // fade here made the final millimetres vanish before the morph ended.
        opacity: root.railVisible ? 1 : 0

        ShapePath {
            strokeWidth: -1
            fillGradient: LinearGradient {
                x1: 0
                y1: 0
                x2: 0
                y2: root.height

                // These are the same native-optics alpha stops as the main
                // panel, sampled over the dial's vertical slice.
                GradientStop {
                    position: 0
                    color: Qt.rgba(root.theme.glass.r, root.theme.glass.g,
                                   root.theme.glass.b,
                                   root.theme.glass.a * 0.16)
                }
                GradientStop {
                    position: 0.426
                    color: Qt.rgba(root.theme.glass.r, root.theme.glass.g,
                                   root.theme.glass.b,
                                   root.theme.glass.a * 0.12)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(root.theme.glass.r, root.theme.glass.g,
                                   root.theme.glass.b,
                                   root.theme.glass.a * 0.10)
                }
            }
            // Begin inside the panel and curve back to its wall.  Those two
            // short shoulder curves are what remove the square <|) seam and
            // make the silhouette read as one continuous < ) membrane.
            startX: root.width
            startY: root.centerY - root.surfaceHalfHeight
                + root.shoulderInset

            PathCubic {
                control1X: root.width
                control1Y: root.centerY - root.surfaceHalfHeight
                    + root.shoulderInset * 0.38
                control2X: root.wallX + root.shoulderInset * 0.50
                control2Y: root.centerY - root.surfaceHalfHeight
                x: root.wallX
                y: root.centerY - root.surfaceHalfHeight
            }

            PathCubic {
                control1X: root.wallX
                control1Y: root.centerY - root.surfaceHalfHeight * 0.67
                control2X: root.wallX - root.surfaceDepth
                control2Y: root.centerY - root.surfaceStraightHalfHeight - 14
                x: root.wallX - root.surfaceDepth
                y: root.centerY - root.surfaceStraightHalfHeight
            }
            PathLine {
                x: root.wallX - root.surfaceDepth
                y: root.centerY + root.surfaceStraightHalfHeight
            }
            PathCubic {
                control1X: root.wallX - root.surfaceDepth
                control1Y: root.centerY + root.surfaceStraightHalfHeight + 14
                control2X: root.wallX
                control2Y: root.centerY + root.surfaceHalfHeight * 0.67
                x: root.wallX
                y: root.centerY + root.surfaceHalfHeight
            }
            PathCubic {
                control1X: root.wallX + root.shoulderInset * 0.50
                control1Y: root.centerY + root.surfaceHalfHeight
                control2X: root.width
                control2Y: root.centerY + root.surfaceHalfHeight
                    - root.shoulderInset * 0.38
                x: root.width
                y: root.centerY + root.surfaceHalfHeight
                    - root.shoulderInset
            }
            PathLine {
                x: root.width
                y: root.centerY - root.surfaceHalfHeight
                    + root.shoulderInset
            }
        }
    }

    Repeater {
        model: root.pageSize

        Item {
            id: profileNode
            required property int index
            readonly property int profileIndex: root.pageStart + index
            readonly property bool valid: profileIndex < root.profileService.profiles.length
            readonly property var profile: valid
                ? root.profileService.profiles[profileIndex] : ({})
            readonly property bool selected: valid && profileIndex === root.selectedIndex
            readonly property real angle: (112 + index * (136 / Math.max(1, root.pageSize - 1)))
                * Math.PI / 180
            width: 36
            height: 36
            x: root.centerX + Math.cos(angle) * (root.arcRadius - 21) - width / 2
            y: root.centerY + Math.sin(angle) * (root.arcRadius - 21) - height / 2
            visible: valid
            opacity: Math.max(0, Math.min(1, (root.morphLevel - 0.48) / 0.32))
            scale: 0.58 + 0.42 * opacity
            z: selected ? 8 : 4

            Behavior on opacity { NumberAnimation { duration: root.motion.selection } }
            Behavior on scale {
                NumberAnimation { duration: root.motion.morph; easing.type: Easing.OutBack }
            }

            Rectangle {
                anchors.centerIn: parent
                width: profileNode.selected ? 20 : 11
                height: width
                radius: width / 2
                color: String(profileNode.profile.accent || root.theme.accent)
                opacity: profileNode.selected ? 1 : 0.76

                Behavior on width {
                    NumberAnimation {
                        duration: root.motion.hover
                        easing.type: Easing.OutBack
                    }
                }
                Behavior on opacity {
                    NumberAnimation { duration: root.motion.hover }
                }
            }

            TapHandler {
                onTapped: {
                    root.selectedIndex = profileNode.profileIndex
                    root.profileService.applyProfile(String(profileNode.profile.id), true)
                }
            }
        }
    }

    Text {
        x: 28
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5
        visible: root.morphLevel > 0.52 && root.pageCount > 1
        opacity: Math.max(0, Math.min(1, (root.morphLevel - 0.52) / 0.30))
        text: (root.currentPage + 1) + " / " + root.pageCount
        color: Qt.rgba(root.theme.inverseInk.r, root.theme.inverseInk.g,
                       root.theme.inverseInk.b, 0.72)
        font.family: root.theme.bodyFont
        font.pixelSize: 9
    }

    Item {
        id: edgeHandle
        x: root.wallX - (root.railVisible ? 38 : 17)
        anchors.verticalCenter: parent.verticalCenter
        width: root.railVisible ? 42 : 20
        height: root.railVisible ? 118 : 96
        // On close the brush leaves first; it no longer hangs around until
        // the very end of the liquid geometry animation.
        opacity: root.waveClosing ? 0
            : Math.max(0, Math.min(1, root.morphLevel / 0.14))
        scale: edgePress.pressed ? 0.96 : 1
        z: 20

        Behavior on x { NumberAnimation { duration: root.motion.morph; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: root.motion.morph; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: root.motion.morph; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: root.motion.hover } }

        Item {
            anchors.centerIn: parent
            width: 31
            height: 31

            Text {
                anchors.centerIn: parent
                text: "\uf1fc"
                color: root.expanded ? root.theme.profileGlyphInk : root.theme.ink
                font.family: "FontAwesome"
                font.pixelSize: root.expanded ? 17 : 15

                Behavior on font.pixelSize {
                    NumberAnimation { duration: root.motion.hover; easing.type: Easing.OutBack }
                }
            }
        }

        HoverHandler { id: edgeHover; margin: 8 }
        HoverHandler { id: railHover; enabled: root.railVisible; margin: 5 }
        TapHandler { id: edgePress; onTapped: root.forcedOpen = !root.forcedOpen }
    }

    DragHandler {
        id: dialDrag
        target: null
        enabled: root.railVisible && !root.profileService.busy
        grabPermissions: PointerHandler.CanTakeOverFromAnything
        onActiveChanged: {
            if (active)
                root.beginGesture()
            else
                root.finishGesture()
        }
        onTranslationChanged: {
            if (active)
                root.updateGesture()
        }
    }

    WheelHandler {
        enabled: root.railVisible && !root.profileService.busy
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(event) {
            root.forcedOpen = true
            root.selectStep(event.angleDelta.y > 0 ? -1 : 1)
            event.accepted = true
        }
    }

    Connections {
        target: root.profileService
        function onProfileApplied() { root.syncSelection() }
        function onProfilesChangedExternally() { root.syncSelection() }
    }

    Component.onCompleted: syncSelection()
}
