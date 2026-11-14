import QtQuick

// Batch invalidations into the next animation tick, without restarting the
// driver between consecutive poses. One trailing tick drains a burst; at rest
// this stops completely. Clear dirty before publishing so callbacks can requeue.
FrameAnimation {
    id: root
    property bool dirty: true
    property bool draining: false
    signal publish()
    running: dirty || draining
    onTriggered: {
        draining = dirty
        if (!dirty) return
        dirty = false
        publish()
    }
}
