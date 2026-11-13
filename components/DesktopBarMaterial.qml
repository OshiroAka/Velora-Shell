import QtQuick
import "../platform" as Platform
import "../core" as Core

// Publish the latest audio on consecutive display ticks, up to 60 times/s.
// The shared publisher stops when the audio/material stops changing. The compositor
// shades the union of the frame and peaks once, with one tint and backdrop.
QtObject {
    id: root
    required property string monitorName
    required property var composition
    property bool enabled: true
    readonly property bool supported: Platform.NativeBlur.supportsBarMaterial(composition.audioVisualizer)
    readonly property bool spectrumEnabled: enabled && composition.desktopVisualizerVisible
    readonly property color tint: composition.unifiedBarSurface
    readonly property string style: [composition.barMaterial === "solid" ? 0
        : composition.barMaterial === "glass" ? 1
        : composition.barMaterial === "liquid-glass" ? (Platform.NativeBlur.supports("optical-glass") ? 3 : 1) : 2,
        tint.r, tint.g, tint.b, tint.a, composition.barBlurEnabled ? 1 : 0,
        spectrumEnabled ? 1 : 0].join(" ")
    property alias dirty: publish.dirty
    property double nextSendAt: 0
    property string lastMessage: ""
    onStyleChanged: dirty = true
    onSupportedChanged: dirty = true
    property int revision: Platform.NativeBlur.revision
    onRevisionChanged: { lastMessage = ""; dirty = true }
    function sync() {
        if (!supported || !composition.audioVisualizer) return
        const now = Date.now()
        if (spectrumEnabled && now+1 < nextSendAt) { dirty=true; return }
        const message = "velora-blur:desktop-bar-material "
            + monitorName + " " + style
            + (typeof composition.audioVisualizer.desktopFrame === "function"
                ? composition.audioVisualizer.desktopFrame()
                : composition.audioVisualizer.materialFrame())
        if (message !== lastMessage) {
            Platform.NativeBlur.dispatch(message)
            lastMessage = message
            nextSendAt = (nextSendAt<now-1000/60 ? now : nextSendAt)+1000/60
        }
    }
    property Connections samples: Connections {
        target: root.composition.audioVisualizer
        function onBandsChanged() { if (root.spectrumEnabled) root.dirty = true }
    }
    property Core.FramePublisher publish: Core.FramePublisher {
        id: publish
        objectName: "desktopMaterialPublisher"
        running: root.supported && (dirty || draining)
        onPublish: root.sync()
    }
    Component.onDestruction: Platform.NativeBlur.dispatch(
        "velora-blur:desktop-bar-material " + monitorName + " -1")
}
