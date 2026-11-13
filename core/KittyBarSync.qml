import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    required property var config
    required property var theme
    required property bool available
    readonly property bool active: config.ready && config.terminalLiquidEnabled
        && config.terminalFollowBar && available
    readonly property color surface: theme.independentBarSurface
    property bool managed: false
    property bool pending: false

    function schedule() {
        if (active || managed) delay.restart()
    }
    onActiveChanged: schedule()
    onSurfaceChanged: schedule()
    Component.onCompleted: schedule()

    Timer {
        id: delay
        interval: 220
        onTriggered: {
            if (writer.running) { root.pending = true; return }
            if (!root.active && !root.managed) return
            root.managed = root.active
            const args = ["python3", Quickshell.shellDir + "/scripts/velora-terminal-theme.py", "--quiet", "--reload"]
            if (root.active) args.push("--follow-bar", Qt.rgba(root.surface.r,
                root.surface.g, root.surface.b, 1).toString(), String(root.surface.a))
            else args.push("--independent")
            writer.command = args
            writer.running = true
        }
    }
    Process {
        id: writer
        onExited: function(code) {
            if (code !== 0) console.warn("Velora Kitty: falha ao sincronizar o material da barra.")
            if (root.pending) { root.pending = false; root.schedule() }
        }
    }
}
