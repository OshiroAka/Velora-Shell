import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../core" as Core

Scope {
    id: root
    property alias views: state.views
    property int connectionGeneration: 0
    property int probeGeneration: -1
    property var probeViews: ({})
    readonly property bool supported: NativeBlur.supports("infinite-widget-camera")
        && Quickshell.env("VELORA_VALIDATE") !== "1"
    Core.InfiniteDesktopCameraState { id: state }

    function refresh() {
        if (!supported || probe.running || !events.connected) return
        probeGeneration = connectionGeneration
        probeViews = state.views
        probe.running = true
    }
    onSupportedChanged: {
        connectionGeneration++
        state.clear()
        events.connected = supported && events.path.length > 0
        if (supported) Qt.callLater(refresh)
    }
    Connections {
        target: NativeBlur
        function onRevisionChanged() { root.refresh() }
    }
    Component.onCompleted: refresh()
    Socket {
        id: events
        path: Hyprland.eventSocketPath
        connected: root.supported && path.length > 0
        onConnectedChanged: {
            root.connectionGeneration++
            if (connected) Qt.callLater(root.refresh)
            else state.clear()
        }
        parser: SplitParser {
            onRead: function(line) {
                if (root.supported) state.readEvent(line)
            }
        }
    }
    // Bootstrap once after connecting/reloading, then consume only frame events.
    // An older subprocess reply must never overwrite a newer rendered pose.
    Process {
        id: probe
        command: ["hyprctl", "-j", "velora-infinite-camera-status"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.supported || root.probeGeneration !== root.connectionGeneration) return
                try { state.applySnapshot(JSON.parse(text), root.probeViews) } catch (error) { }
            }
        }
        onExited: if (root.supported && root.probeGeneration !== root.connectionGeneration
            && Object.keys(state.views).length === 0) Qt.callLater(root.refresh)
    }
    Timer {
        interval: 1000
        running: root.supported && !events.connected
        repeat: true
        onTriggered: if (events.path.length > 0) events.connected = true
    }
}
