import QtQuick
import Quickshell

Scope {
    id: root

    required property var controller
    required property var config
    required property var settings
    property var shell: null
    property var editorController: null

    function openLauncher() {
        Quickshell.execDetached(["wofi", "--show", "drun", "--allow-images"])
    }

    function openSearch() {
        if (shell) { shell.toggleTopSearch(); return }
        Quickshell.execDetached([
            "wofi", "--show", "drun", "--allow-images", "--prompt", "Search"
        ])
    }

    function openDiscord() {
        Quickshell.execDetached(["discord"])
    }

    function openGallery() {
        Quickshell.execDetached(["xdg-open", root.config.homeDir + "/Templates de imagens"])
    }

    function openMusic() {
        Quickshell.execDetached(["brave", "--new-window", "https://music.youtube.com"])
    }

    function openSettings() {
        if (editorController) editorController.show("desktop")
        else root.settings.show()
    }

    function openNetworkSettings() {
        if (shell) { shell.openAdaptiveBarPopup("wifi", 400); return }
        Quickshell.execDetached(["kitty", "--class", "velora-shell-network", "-e", "nmtui"])
    }

    function restoreNotification() {
        if (shell) { shell.openAdaptiveBarPopup("notifications", 500); return }
        Quickshell.execDetached(["makoctl", "restore"])
    }

    function showLockPreview() {
        root.controller.show()
    }
}
