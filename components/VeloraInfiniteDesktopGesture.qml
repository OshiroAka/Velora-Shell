import QtQuick
import Quickshell.Io
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    required property string bridgePath
    property string monitorName: ""
    property bool scrolling: false
    property bool dragging: false
    property bool bridgeReady: false
    property bool releasePending: false
    property real lastPointerX: 0
    property real lastPointerY: 0
    property real pendingX: 0
    property real pendingY: 0

    function resetGesture() {
        dragging = false
        scrolling = false
        bridgeReady = false
        releasePending = false
        pendingX = 0
        pendingY = 0
    }

    function flushMotion() {
        if (!bridgeReady || (!pendingX && !pendingY))
            return

        const dx = pendingX
        const dy = pendingY
        pendingX = 0
        pendingY = 0
        dragBridge.write("MOVE " + dx.toFixed(3) + " " + dy.toFixed(3) + "\n")
    }

    function beginGesture(mouse) {
        if (!enabled || dragging || dragBridge.running || bridgePath.length <= 0)
            return

        dragging = true
        bridgeReady = false
        releasePending = false
        pendingX = 0
        pendingY = 0
        lastPointerX = mouse.x
        lastPointerY = mouse.y
        dragBridge.running = true
    }

    function updateGesture(mouse) {
        if (!dragging)
            return

        pendingX += mouse.x - lastPointerX
        pendingY += mouse.y - lastPointerY
        lastPointerX = mouse.x
        lastPointerY = mouse.y
    }

    function finishGesture() {
        if (!dragging)
            return

        dragging = false
        scrolling = false
        releasePending = true
        if (!bridgeReady)
            return

        flushMotion()
        dragBridge.write("END\n")
        releasePending = false
    }

    function scrollBy(dx, dy) {
        if (!enabled || !Number.isFinite(dx) || !Number.isFinite(dy) || (!dx && !dy)) return
        if (dragging && !scrolling) return
        if (!dragging) {
            beginGesture({x: 0, y: 0})
            if (!dragging) return
            scrolling = true
        }
        pendingX += dx
        pendingY += dy
        scrollEnd.restart()
    }
    Timer { id: scrollEnd; interval: 220; onTriggered: if (root.scrolling) root.finishGesture() }
    Socket {
        path: Hyprland.eventSocketPath
        connected: root.enabled && root.monitorName.length > 0 && path.length > 0
            && Quickshell.env("VELORA_VALIDATE") !== "1"
        parser: SplitParser {
            onRead: line => {
                const prefix = "velora-infinite-scroll>>"
                if (!line.startsWith(prefix)) return
                const fields = line.slice(prefix.length).split(",")
                if (fields.length === 3 && fields[0] === root.monitorName)
                    root.scrollBy(Number(fields[1]), Number(fields[2]))
            }
        }
    }

    Process {
        id: dragBridge

        running: false
        stdinEnabled: true
        command: root.monitorName.length > 0 ? [root.bridgePath, "stream-drag", root.monitorName]
            : [root.bridgePath, "stream-drag"]

        stdout: SplitParser {
            onRead: function(data) {
                if (String(data || "").trim() !== "READY")
                    return

                root.bridgeReady = true
                root.flushMotion()
                if (root.releasePending) {
                    dragBridge.write("END\n")
                    root.releasePending = false
                }
            }
        }

        onExited: root.resetGesture()
    }

    FrameAnimation {
        running: root.dragging && root.bridgeReady
        onTriggered: root.flushMotion()
    }

    MouseArea {
        objectName: "infiniteDesktopPanInput"
        anchors.fill: parent
        enabled: root.enabled
        acceptedButtons: Qt.RightButton
        preventStealing: true
        cursorShape: Qt.ArrowCursor

        onPressed: function(mouse) {
            root.beginGesture(mouse)
        }
        onPositionChanged: function(mouse) {
            root.updateGesture(mouse)
        }
        onReleased: root.finishGesture()
        onCanceled: root.finishGesture()
    }

    Component.onDestruction: {
        if (dragBridge.running)
            dragBridge.signal(15)
    }
}
