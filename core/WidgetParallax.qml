import QtQuick

// Blend the camera's screen-space affine transform with the fixed desktop.
// At depth 0 the wallpaper is still; at 1 widgets follow application windows.
QtObject {
    property var camera: null
    property bool active: false
    property real depth: .35
    property real viewportWidth: 0
    property real viewportHeight: 0
    readonly property bool moving: active && !!camera && camera.active === true
        && viewportWidth > 0 && viewportHeight > 0
    readonly property real amount: moving ? Math.max(0, Math.min(1, depth)) : 0
    readonly property real scale: moving ? 1 + (camera.zoom - 1) * amount : 1
    readonly property real x: moving ? amount * (camera.viewport[0] / 2
        + (camera.origin[0] - camera.center[0]) * camera.zoom)
        * viewportWidth / camera.viewport[0] : 0
    readonly property real y: moving ? amount * (camera.viewport[1] / 2
        + (camera.origin[1] - camera.center[1]) * camera.zoom)
        * viewportHeight / camera.viewport[1] : 0
}
