import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "."

ShellRoot {
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
    }

    ShinBar {}
    ShinNotifications {}

    Timer {
        interval: 700
        running: ShinColors.pywalActive
        repeat: true
        triggeredOnStart: true
        onTriggered: ShinColors.refreshWalColors()
    }

    Loader {
        id: shinWorkspacesExpandedLoader
        active: true
        source: Qt.resolvedUrl("ShinWorkspacesExpanded.qml")
    }


}
