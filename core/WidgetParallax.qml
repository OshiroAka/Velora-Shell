import QtQuick

// Blend the camera's screen-space affine transform with the fixed desktop.
// At depth 0 the wallpaper is still; at 1 widgets follow application windows.
QtObject {
    id: root
    property var camera: null
    property bool active: false
    property bool snapToRest: false
    property real pace: 1
    property real depth: .35
    property real viewportWidth: 0
    property real viewportHeight: 0
    property bool tracking: false
    property var targetPose: ({x: 0, y: 0, scale: 1})
    property real fromX: 0
    property real fromY: 0
    property real fromScale: 1
    property real blend: 1
    readonly property bool moving: settling.running
    readonly property real x: fromX + (targetPose.x - fromX) * blend
    readonly property real y: fromY + (targetPose.y - fromY) * blend
    readonly property real scale: fromScale + (targetPose.scale - fromScale) * blend

    function update() {
        if (!settling) return
        const nextTracking = active && !snapToRest && !!camera && camera.active === true
            && viewportWidth > 0 && viewportHeight > 0
        const amount = Math.max(0, Math.min(1, depth))
        const target = nextTracking ? {
            x: amount * (camera.viewport[0] / 2
                + (camera.origin[0] - camera.center[0]) * camera.zoom)
                * viewportWidth / camera.viewport[0],
            y: amount * (camera.viewport[1] / 2
                + (camera.origin[1] - camera.center[1]) * camera.zoom)
                * viewportHeight / camera.viewport[1],
            scale: 1 + (camera.zoom - 1) * amount
        } : {x: 0, y: 0, scale: 1}
        // Capture the displayed pose before changing the target. Camera-off
        // events can arrive either before or after the mode's state update.
        const retarget = !snapToRest && ((tracking && !nextTracking)
            || (!tracking && nextTracking && settling.running))
        const presentedX = x, presentedY = y, presentedScale = scale
        if (snapToRest || retarget) settling.stop()
        if (retarget) {
            fromX = presentedX; fromY = presentedY; fromScale = presentedScale
            blend = 0
        } else if (snapToRest) blend = 1
        targetPose = target
        tracking = nextTracking
        if (retarget) settling.start()
    }

    onCameraChanged: update()
    onActiveChanged: update()
    onSnapToRestChanged: update()
    onDepthChanged: update()
    onViewportWidthChanged: update()
    onViewportHeightChanged: update()
    Component.onCompleted: update()
    property NumberAnimation settling: NumberAnimation {
        target: root; property: "blend"; to: 1
        duration: Math.max(1, 620 * root.pace)
        easing.type: Easing.InOutCubic
    }
}
