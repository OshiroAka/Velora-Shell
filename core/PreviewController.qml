import QtQuick
import Quickshell

Scope {
    id: root

    required property var motion
    property bool keepWarm: true
    property bool mounted: false
    property bool shown: false
    // Remains true through the closing animation. Surfaces outside the lock
    // use this instead of `mounted`, because a warmed scene stays resident.
    property bool occluding: false
    property int serial: 0

    signal opened
    signal closed

    function prewarm() {
        if (mounted)
            return false
        mounted = true
        serial += 1
        return true
    }

    function show() {
        warmupTimer.stop()
        closeTimer.stop()
        occluding = true
        prewarm()
        Qt.callLater(function() {
            if (!root.mounted)
                return
            root.shown = true
            root.serial += 1
            root.opened()
        })
        return true
    }

    function hide() {
        if (!mounted || !shown)
            return false
        shown = false
        serial += 1
        closeTimer.restart()
        return true
    }

    function toggle() {
        if (mounted && shown)
            return hide()
        return show()
    }

    function finishClose() {
        closeTimer.stop()
        if (!keepWarm)
            mounted = false
        shown = false
        occluding = false
        serial += 1
        closed()
    }

    function status() {
        return {
            mounted: mounted,
            shown: shown,
            occluding: occluding,
            lifecycle: !mounted ? "unloaded"
                : (shown ? "active" : (occluding ? "closing" : "warm"))
        }
    }

    Timer {
        id: warmupTimer
        interval: 650
        running: true
        repeat: false
        onTriggered: root.prewarm()
    }

    Timer {
        id: closeTimer
        // reveal already owns the complete exit duration. The old 80 ms tail
        // held an invisible Overlay surface after the final visual frame,
        // which read as a pause before the desktop/topbar returned.
        // The shared transition normally calls finishClose() as soon as its
        // remaining distance settles. This is only a defensive fallback.
        interval: root.motion.widgetExit + 80
        repeat: false
        onTriggered: root.finishClose()
    }
}
