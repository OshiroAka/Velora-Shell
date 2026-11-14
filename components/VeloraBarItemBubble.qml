import QtQuick
import "../platform" as Platform

Rectangle {
    id: root
    // A decorative fill behind the content; no input, blur or extra surface.
    property bool shown: false
    required property color tint
    required property color surfaceTint
    property bool solid: false
    property bool exactColor: false
    property bool liquid: false
    property string materialLayer: "topbar"
    property string monitorName: ""
    readonly property bool nativeLiquid: shown && liquid && !solid && Platform.NativeBlur.supports("bar-bubble-liquid")
    readonly property color bubbleColor: exactColor
        ? Qt.rgba(tint.r, tint.g, tint.b, 1) : solid
        ? Qt.tint(Qt.rgba(surfaceTint.r, surfaceTint.g, surfaceTint.b, 1),
            Qt.rgba(tint.r, tint.g, tint.b, 0.16))
        : Qt.rgba(tint.r, tint.g, tint.b, 0.16)
    visible: shown
    color: nativeLiquid ? "transparent" : bubbleColor
    Loader {
        active: root.nativeLiquid
        sourceComponent: BarBubbleOptics { bubble: root }
    }
    radius: Math.min(7, width / 2, height / 2)
    antialiasing: true
    Accessible.ignored: true
}
