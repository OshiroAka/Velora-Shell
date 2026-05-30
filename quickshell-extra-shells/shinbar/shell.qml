import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "."

ShellRoot {
    property bool wallpaperPanelLoaded: false
    property bool workspacesExpandedLoaded: false

    IpcHandler {
        target: "shinbar"

        function focus(): void {
            ShinPopup.enterFocus()
        }

        function unfocus(): void {
            ShinPopup.exitFocus()
        }

        function toggleFocus(): void {
            ShinPopup.toggleFocus()
        }

        function media(): void {
            ShinPopup.enterFocus()
            ShinPopup.active = "media-tab"
        }

        function search(): void {
            ShinPopup.active = "search"
        }

        function settings(): void {
            ShinPopup.active = "settings"
        }

        function wallpapers(): void {
            if (ShinConfig.wallpaperSelectorEnabled)
                ShinPopup.active = "wallpapers"
            else
                ShinPopup.active = "settings"
        }

        function wallpaper(): void {
            wallpapers()
        }

        function lock(): void {
            if (ShinConfig.lockEnabled)
                shinLock.lockNow()
            else
                console.log("[shinlock] disabled by settings")
        }

        function lockscreen(): void {
            if (ShinConfig.lockEnabled)
                shinLock.lockNow()
            else
                console.log("[shinlock] disabled by settings")
        }

        function setConfig(key: string, value: string): void {
            ShinData.save(key, value)
        }

        function saveConfig(): void {
            ShinData.saveAll()
        }

        function refreshColors(): void {
            ShinColors.refreshWalColors()
        }

        function setColors(bg: string, fg: string, accent: string, surface: string, muted: string, warn: string, signature: string): void {
            ShinColors.applyPalette(bg, fg, accent, surface, muted, warn, signature)
        }
    }

    ShinBar {}
    ShinNotifications {}
    Loader {
        id: shinWallpaperPanelLoader
        active: wallpaperPanelLoaded
        asynchronous: true
        sourceComponent: Component {
            ShinWallpaperPanel {}
        }
    }
    ShinLock { id: shinLock }

    Process {
        id: pywalBridgeStart
        running: false
        command: [
            "/home/shira/.config/quickshell/shinbar/scripts/shinbar-pywal-bridge",
            "--start-watch"
        ]
        onExited: running = false
    }

    Process {
        id: pywalBridgeStop
        running: false
        command: [
            "/home/shira/.config/quickshell/shinbar/scripts/shinbar-pywal-bridge",
            "--stop-watch"
        ]
        onExited: running = false
    }

    Connections {
        target: ShinColors
        function onPywalActiveChanged() {
            if (ShinColors.pywalActive)
                pywalBridgeStart.running = true
            else
                pywalBridgeStop.running = true
        }
    }

    Component.onCompleted: {
        ShinColors.refreshWalColors()
        if (ShinColors.pywalActive)
            pywalBridgeStart.running = true
    }

    Loader {
        id: shinWorkspacesExpandedLoader
        active: workspacesExpandedLoaded
        asynchronous: true
        source: Qt.resolvedUrl("ShinWorkspacesExpanded.qml")
    }

    Connections {
        target: ShinPopup
        function onActiveChanged() {
            if (ShinPopup.active === "wallpapers")
                wallpaperPanelLoaded = true
            if (ShinPopup.active === "workspaces")
                workspacesExpandedLoaded = true
        }
    }


}
