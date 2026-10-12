import QtQuick
import Quickshell.Io

Item {
    id: root

    required property string bridgePath
    property bool dragging: false
    property bool bridgeReady: false
    property bool releasePending: false
    property real lastPointerX: 0
    property real lastPointerY: 0
    property real pendingX: 0
    property real pendingY: 0

    function resetGesture() {
        dragging = false
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
        releasePending = true
        if (!bridgeReady)
            return

        flushMotion()
        dragBridge.write("END\n")
        releasePending = false
    }

    Process {
        id: dragBridge

        running: false
        stdinEnabled: true
        command: [root.bridgePath, "stream-drag"]

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

    Timer {
        interval: 22
        repeat: true
        running: root.dragging && root.bridgeReady
        onTriggered: root.flushMotion()
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        acceptedButtons: Qt.RightButton
        preventStealing: true
        cursorShape: root.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor

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
