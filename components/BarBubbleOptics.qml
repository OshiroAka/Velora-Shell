import QtQuick
import QtQuick.Window
import QtQml.Models
import "../core" as Core
import "../platform" as Platform

Item {
    id: root
    required property var bubble
    readonly property var window: bubble.Window.window
    readonly property string token: Platform.NativeBlur.barBubbleEpoch + "_bubble" + Math.random().toString(16).slice(2)
    property string publishedMonitor: ""
    property string publishedLayer: ""
    property string lastMessage: ""
    property int geometryRevision: 0
    readonly property var ancestors: {
        geometryRevision
        const result = []
        for (let item = bubble.parent; item; item = item.parent) result.push(item)
        return result
    }
    onWindowChanged: publisher.dirty = true
    function clear() {
        if (publishedMonitor) Platform.NativeBlur.dispatch("velora-blur:bar-bubble-liquid "
            + publishedMonitor + " " + publishedLayer + " " + token + " 0")
        publishedMonitor = ""; lastMessage = ""
    }
    function sync() {
        if (!window || window.width <= 0 || window.height <= 0) { clear(); return }
        const monitor = bubble.monitorName || (window.screen ? window.screen.name : "")
        if (!monitor) { clear(); return }
        const layer = bubble.materialLayer
        if (publishedMonitor && (publishedMonitor !== monitor || publishedLayer !== layer)) clear()
        const point = bubble.mapToItem(null, 0, 0)
        const end = bubble.mapToItem(null, bubble.width, bubble.height)
        const visualWidth = end.x - point.x, visualHeight = end.y - point.y
        let left = Math.max(0, point.x), top = Math.max(0, point.y)
        let right = Math.min(window.width, end.x)
        let bottom = Math.min(window.height, end.y)
        let alpha = bubble.opacity
        for (const item of ancestors) {
            alpha *= item.opacity
            if (!item.visible) alpha = 0
            if (item.clip) {
                const p = item.mapToItem(null, 0, 0)
                left = Math.max(left, p.x); top = Math.max(top, p.y)
                right = Math.min(right, p.x + item.width); bottom = Math.min(bottom, p.y + item.height)
            }
        }
        if (!bubble.visible || alpha <= .001 || right <= left || bottom <= top) { clear(); return }
        // Optical material keeps its own transparency; manual flat fills stay exact.
        const tint = Qt.rgba(bubble.tint.r, bubble.tint.g, bubble.tint.b, .16)
        const values = [point.x/window.width, point.y/window.height, visualWidth/window.width,
            visualHeight/window.height, left/window.width, top/window.height,
            (right-left)/window.width, (bottom-top)/window.height, bubble.radius * visualWidth / Math.max(1,bubble.width) / window.width,
            alpha, tint.r, tint.g, tint.b, tint.a]
        const message = "velora-blur:bar-bubble-liquid " + monitor + " " + layer + " " + token + " 1 "
            + values.map(value => Number(value).toFixed(7)).join(" ")
        if (message !== lastMessage) {
            Platform.NativeBlur.dispatch(message)
            publishedMonitor = monitor; publishedLayer = layer; lastMessage = message
        }
    }
    Core.FramePublisher { id: publisher; onPublish: root.sync() }
    Connections {
        target: root.bubble
        function onXChanged() { publisher.dirty = true }
        function onYChanged() { publisher.dirty = true }
        function onWidthChanged() { publisher.dirty = true }
        function onHeightChanged() { publisher.dirty = true }
        function onRadiusChanged() { publisher.dirty = true }
        function onOpacityChanged() { publisher.dirty = true }
        function onVisibleChanged() { publisher.dirty = true }
        function onBubbleColorChanged() { publisher.dirty = true }
        function onTintChanged() { publisher.dirty = true }
        function onMaterialLayerChanged() { publisher.dirty = true }
        function onMonitorNameChanged() { publisher.dirty = true }
        function onParentChanged() { root.geometryRevision++; publisher.dirty = true }
    }
    Instantiator {
        model: root.ancestors
        delegate: Connections {
            required property var modelData
            target: modelData
            ignoreUnknownSignals: true
            function onXChanged() { publisher.dirty = true }
            function onYChanged() { publisher.dirty = true }
            function onWidthChanged() { publisher.dirty = true }
            function onHeightChanged() { publisher.dirty = true }
            function onScaleChanged() { publisher.dirty = true }
            function onRotationChanged() { publisher.dirty = true }
            function onOpacityChanged() { publisher.dirty = true }
            function onVisibleChanged() { publisher.dirty = true }
            function onContentXChanged() { publisher.dirty = true }
            function onContentYChanged() { publisher.dirty = true }
            function onParentChanged() { root.geometryRevision++; publisher.dirty = true }
        }
    }
    Connections {
        target: root.window
        function onWidthChanged() { publisher.dirty = true }
        function onHeightChanged() { publisher.dirty = true }
        function onScreenChanged() { publisher.dirty = true }
    }
    Connections {
        target: Platform.NativeBlur
        function onRevisionChanged() { root.lastMessage = ""; publisher.dirty = true }
    }
    Component.onDestruction: clear()
}
