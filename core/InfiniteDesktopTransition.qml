import QtQuick

Item {
    id: root
    property bool active: false
    property bool transformBars: true
    readonly property bool effectiveActive: active && transformBars
    property bool reducedMotion: false
    property real pace: 1
    property real progress: 0
    readonly property real frameFold: progress
    readonly property real sourceReveal: 1 - smoothRange(0, .28, progress)
    readonly property real targetReveal: smoothRange(.68, 1, progress)
    readonly property bool moving: morph.running
    readonly property real remaining: 1 - progress
    readonly property real railRemaining: remaining
    function smoothRange(start, end, value) {
        const t = Math.max(0, Math.min(1, (value-start)/(end-start)))
        return t*t*(3-2*t)
    }
    function settle() { progress = effectiveActive ? 1 : 0 }
    function retarget() {
        morph.stop()
        if (reducedMotion) { settle(); return }
        const destination = effectiveActive ? 1 : 0
        if (Math.abs(destination-progress) < .00001) { settle(); return }
        morph.to = destination
        morph.duration = Math.max(1, 620 * pace * Math.abs(destination-progress))
        morph.start()
    }
    onEffectiveActiveChanged: retarget()
    onReducedMotionChanged: if (reducedMotion) retarget()
    Component.onCompleted: settle()
    NumberAnimation {
        id: morph
        target: root; property: "progress"
        easing.type: Easing.InOutCubic
    }
}
