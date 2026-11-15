import QtQuick
import "../core" as Core

// Animate the glyph only: its trigger and menu anchor stay stationary.
Item {
    id: root
    property bool highlighted: false
    property bool reducedMotion: false
    property real emphasis: settling.value
    property real pointerX: pointer.hovered && parent && parent.width > 0
        ? Math.max(-1,Math.min(1,pointer.point.position.x/parent.width*2-1)) : 0
    property real pointerY: pointer.hovered && parent && parent.height > 0
        ? Math.max(-1,Math.min(1,pointer.point.position.y/parent.height*2-1)) : 0
    readonly property real drift: reducedMotion ? 0 : pointerX * 1.25
    readonly property real zoom: reducedMotion ? 1 : 1 + .12 * emphasis
    readonly property real lift: reducedMotion ? 0 : -2 * emphasis + pointerY * .75
    readonly property real inkOpacity: .76 + .24 * emphasis
    Core.SettleValue { id: settling;target: root.highlighted ? 1 : 0;reducedMotion: root.reducedMotion;enabled: root.visible;duration: 240;overshoot: .45 }
    Behavior on pointerX { enabled: !root.reducedMotion; NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
    Behavior on pointerY { enabled: !root.reducedMotion; NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
    HoverHandler { id: pointer; parent: root.parent; enabled: root.visible && !root.reducedMotion; blocking: false }
}
