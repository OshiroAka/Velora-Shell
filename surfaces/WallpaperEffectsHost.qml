pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

// Above wallpaper background surfaces and below desktop widgets and clients.
Variants {
    id: root
    required property var compositor
    required property var config
    required property var wallpaper
    property bool mapped: true
    // Wallpaper backends may replace their background surface when changing
    // files. Remap after the new source is applied so effects stay above it.
    Connections {
        target: root.wallpaper
        function onAppliedPathChanged() { restack.restart() }
    }
    Timer {
        id: restack
        interval: 120
        onTriggered: {
            root.mapped = false
            Qt.callLater(function() { root.mapped = true })
        }
    }
    model: root.mapped && (root.config.wallpaperBlurEnabled || root.config.wallpaperDimming > 0)
        ? root.compositor.screens : []
    PanelWindow {
        required property var modelData
        screen: modelData
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "velora-shell-wallpaper-effects"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}
        BackgroundEffect.blurRegion: Region {
            item: root.config.wallpaperBlurEnabled && root.config.wallpaperBlurStrength > 0
                ? wallpaperShade : null
        }
        Rectangle {
            id: wallpaperShade
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, Math.max(0.004, root.config.wallpaperDimming))
        }
    }
}
