pragma ComponentBehavior: Bound
import QtQuick
import "../components" as Components
import Quickshell
import Quickshell.Wayland

Variants {
    id: root
    required property var screens
    required property var palette
    required property var config
    required property url source
    property bool blocked: false
    onBlockedChanged: { if (blocked) palette.pickingColor = false }
    model: palette.pickingColor && !blocked ? screens : []
    PanelWindow {
        id: window
        required property var modelData
        screen: modelData
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        color: "black"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "velora-wallpaper-color-picker"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        Components.VeloraWallpaperColorSampler {
            anchors.fill: parent
            source: root.source
            fit: root.config.wallpaperFit
            onCancelled: root.palette.pickingColor = false
            onSelected: color => {
                if (root.config.setPickedWallpaperColor(color)) {
                    root.palette.pickingColor = false
                }
            }
        }
    }
}
