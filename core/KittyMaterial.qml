import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    required property var config
    property color background: "#242430"
    property real opacity: 0.56
    property bool ready: false
    readonly property string path: (Quickshell.env("VELORA_HOST_XDG_CONFIG_HOME")
        || config.homeDir + "/.config") + "/kitty/velora-pywal.conf"
    function apply(text) {
        const color = /(?:^|\n)\s*background\s+(#[0-9a-fA-F]{6})(?:\s|$)/.exec(text)
        const alpha = /(?:^|\n)\s*background_opacity\s+([0-9.]+)(?:\s|$)/.exec(text)
        const value = alpha ? Number(alpha[1]) : NaN
        if (!color || !Number.isFinite(value) || value < 0 || value > 1) return
        background = color[1]; opacity = value; ready = true
    }
    FileView {
        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.apply(text())
    }
}
