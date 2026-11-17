import QtQuick
import Quickshell.Io
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    required property string bridgePath
    property string monitorName: ""
    property color selectionAccent: "#d8d8d8"
    property bool scrolling: false
    property bool dragging: false
    property bool bridgeReady: false
    property bool releasePending: false
    property real lastPointerX: 0
    property real lastPointerY: 0
    property real pendingX: 0
    property real pendingY: 0
    property var terminalSelection: null
    property var terminalQueue: []

    function readTerminalEvent(line) {
        const prefix = "velora-terminal-rectangle>>"
        if (!line.startsWith(prefix)) return false
        try {
            const data = JSON.parse(line.slice(prefix.length))
            if (data.monitor !== monitorName) return false
            const validBox = box => Array.isArray(box) && box.length === 4
                && box.every(n => typeof n === "number" && Number.isFinite(n))
                && box[2] >= 0 && box[3] >= 0
            if (!validBox(data.screen) || !validBox(data.world)
                    || !Number.isInteger(data.workspace) || data.workspace <= 0) return false
            if (data.phase === "cancel" || data.phase === "end") {
                terminalSelection = null
                selectionTimeout.stop()
                if (data.phase === "end" && data.screen[2] >= 80 && data.screen[3] >= 48) {
                    terminalQueue = terminalQueue.concat([data])
                    startNextTerminal()
                }
            } else if (data.phase === "begin" || data.phase === "update") {
                terminalSelection = data
                selectionTimeout.restart()
            } else return false
            return true
        } catch (error) { return false }
    }
    function startNextTerminal() {
        if (terminalLaunch.running || terminalQueue.length === 0) return
        const data = terminalQueue[0]
        terminalQueue = terminalQueue.slice(1)
        terminalLaunch.command = [bridgePath, "terminal-rectangle", monitorName,
            String(data.workspace)].concat(data.world.map(n => String(n)))
        terminalLaunch.running = true
    }
    Timer { id: selectionTimeout; interval: 30000; onTriggered: root.terminalSelection = null }
    Process {
        id: terminalLaunch
        onExited: root.startNextTerminal()
        stderr: SplitParser { onRead: data => console.warn("Terminal rectangle:", data) }
    }
    Rectangle {
        objectName: "terminalRectanglePreview"
        visible: root.terminalSelection !== null
        x: root.terminalSelection ? root.terminalSelection.screen[0] : 0
        y: root.terminalSelection ? root.terminalSelection.screen[1] : 0
        width: root.terminalSelection ? root.terminalSelection.screen[2] : 0
        height: root.terminalSelection ? root.terminalSelection.screen[3] : 0
        color: Qt.rgba(root.selectionAccent.r, root.selectionAccent.g, root.selectionAccent.b, 0.10)
        border.color: Qt.rgba(root.selectionAccent.r, root.selectionAccent.g, root.selectionAccent.b, 0.90)
        border.width: 1
        radius: 3
    }

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
                if (root.readTerminalEvent(line)) return
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
