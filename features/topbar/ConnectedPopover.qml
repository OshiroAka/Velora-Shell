import QtQuick
import "TopBarGeometry.js" as Geometry

FocusScope {
    id: root
    required property var controller
    required property var host
    required property var config
    required property var theme
    required property var status
    required property var system
    required property var fanPlus
    required property var timerService
    required property var clock
    required property var calendar
    required property var media
    required property var actions
    required property var weather
    property real barHeight: 40
    readonly property string desiredType: controller.owner === host ? controller.activeType : ""
    readonly property bool wantsMotion: controller.supportsHover(desiredType)
    readonly property string genericType: wantsMotion ? "" : desiredType
    readonly property bool motionMounted: motion.mounted
    readonly property real neckHalfWidth: motionMounted ? motion.neckHalfWidth
        : Math.min(120, Math.max(0, panelRect.width / 2 - 18))
    property string presentedType: ""
    property real reveal: 0
    property real contentReveal: 0
    property real genericAnchorX: width / 2
    readonly property real anchorX: motionMounted ? motion.anchorX : genericAnchorX
    readonly property bool mounted: presentedType.length > 0 || motionMounted
    readonly property var preferred: Geometry.size(presentedType === "calendar" ? "clock" : presentedType)
    readonly property var geometry: Geometry.panel(width, height, barHeight, genericAnchorX, preferred[0], preferred[1], reveal)
    readonly property rect panelRect: motionMounted ? motion.panelRect : Qt.rect(geometry.x, geometry.y, geometry.width, geometry.height)
    readonly property bool interactive: desiredType === presentedType && desiredType.length > 0 && reveal > 0.95

    function settle() {
        if (reveal > 0.001 || motionMounted) return
        presentedType = genericType
        if (!presentedType.length) { contentReveal = 0; return }
        const item = controller.anchorItem
        genericAnchorX = item ? item.mapToItem(root, item.width / 2, item.height).x : width / 2
        reveal = 1
        contentDelay.restart()
        root.forceActiveFocus()
    }
    function synchronize() {
        contentDelay.stop()
        contentReveal = 0
        if (reveal <= 0.001) settle()
        else reveal = 0
    }
    onGenericTypeChanged: synchronize()
    onMotionMountedChanged: if (!motionMounted) Qt.callLater(settle)
    onWidthChanged: if (presentedType.length) Qt.callLater(function() {
        if (root.controller.anchorItem)
            root.genericAnchorX = root.controller.anchorItem.mapToItem(root, root.controller.anchorItem.width / 2, 0).x
    })
    Keys.onEscapePressed: controller.close()
    Behavior on reveal {
        NumberAnimation {
            duration: root.config.reducedMotion ? 0 : root.reveal > 0 ? 200 : 150
            easing.type: Easing.OutCubic
            onRunningChanged: if (!running) root.settle()
        }
    }
    Behavior on contentReveal { NumberAnimation { duration: root.config.reducedMotion ? 0 : root.contentReveal > 0 ? 160 : 90; easing.type: Easing.OutCubic } }
    Timer { id: contentDelay; interval: root.config.reducedMotion ? 1 : 55; onTriggered: root.contentReveal = 1 }
    MouseArea {
        x: root.panelRect.x; y: root.barHeight
        width: root.panelRect.width; height: Math.max(0, root.panelRect.y + root.panelRect.height - y)
        visible: root.presentedType.length > 0
        acceptedButtons: Qt.AllButtons
        onWheel: wheel => { wheel.accepted = true }
    }
    Item {
        visible: root.presentedType.length > 0
        x: root.panelRect.x + 16
        y: root.panelRect.y + 16
        width: Math.max(0, root.panelRect.width - 32)
        height: Math.max(0, root.panelRect.height - 32)
        clip: true
        enabled: root.interactive
        opacity: root.contentReveal
        BarPanelContent {
            width: root.geometry.targetWidth - 32
            height: root.geometry.targetHeight - 32
            y: (1 - root.contentReveal) * 5
            active: root.presentedType.length > 0
            type: root.presentedType
            theme: root.theme; systemStatus: root.status; system: root.system
            fanPlus: root.fanPlus
            timerService: root.timerService; clock: root.clock; calendar: root.calendar
            media: root.media; weather: root.weather
            controller: root.controller; actions: root.actions
        }
    }
    function syncPresence() {
        controller.panelPresence(host, motionMounted && motion.pointerInside,
            motionMounted && (motion.pointerHeld || motionContent.interactionHeld))
    }
    Connections {
        target: root.controller
        function onOwnerChanged() { Qt.callLater(root.syncPresence) }
        function onActiveTypeChanged() { Qt.callLater(root.syncPresence) }
    }
    MorphPopover {
        id: motion
        anchors.fill: parent
        controller: root.controller
        barHeight: root.barHeight
        desiredType: root.wantsMotion && root.presentedType.length === 0
            ? root.desiredType : ""
        onPointerInsideChanged: root.syncPresence()
        onPointerHeldChanged: root.syncPresence()
        onMountedChanged: root.syncPresence()
        BarPanelContent {
            id: motionContent
            anchors.fill: parent
            active: motion.mounted
            type: motion.presentedType
            theme: root.theme; systemStatus: root.status; system: root.system
            fanPlus: root.fanPlus
            timerService: root.timerService; clock: root.clock; calendar: root.calendar
            media: root.media; weather: root.weather
            controller: root.controller; actions: root.actions
            onInteractionHeldChanged: root.syncPresence()
        }
    }
}
