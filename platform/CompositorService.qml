import QtQuick
import Quickshell
import Quickshell.Hyprland

Scope {
    id: root

    readonly property string backend: "hyprland"
    readonly property string surfaceNamespace: "velora-shell-lock-preview"
    readonly property string focusedMonitorName: Hyprland.focusedMonitor
        ? String(Hyprland.focusedMonitor.name || "") : ""
    readonly property var activeToplevel: Hyprland.activeToplevel
    readonly property bool activeToplevelFullscreen: isFullscreen(activeToplevel)
    readonly property var screens: Quickshell.screens
    readonly property var focusedScreen: selectScreen(focusedMonitorName, screens.length)

    function selectScreen(name, count) {
        count
        const available = Quickshell.screens
        if (!available || available.length === 0)
            return null
        for (let index = 0; index < available.length; index += 1) {
            if (String(available[index].name || "") === String(name || ""))
                return available[index]
        }
        return available[0]
    }

    function isFullscreen(toplevel) {
        if (!toplevel)
            return false
        if (toplevel.wayland && Boolean(toplevel.wayland.fullscreen))
            return true
        const client = toplevel.lastIpcObject || ({})
        return Number(client.fullscreen || 0) !== 0
            || Number(client.fullscreenClient || 0) !== 0
    }
}
