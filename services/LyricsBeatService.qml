import QtQuick
import "PercussionDetector.js" as Percussion

// Uses the one shared capture/FFT. No second audio stream or idle poller.
QtObject {
    id: root
    property var analyzer: null
    property bool active: false
    property var detector: Percussion.create()
    property int beatCount: 0
    signal beat(real strength)

    function reset() { detector = Percussion.create() }
    onActiveChanged: reset()
    onAnalyzerChanged: reset()
    function consume() {
        if (!active || !analyzer || !analyzer.running || typeof analyzer.materialFrame !== "function") return
        const frame = String(analyzer.materialFrame()).trim().split(/\s+/).map(Number)
        const strength = Percussion.update(detector, frame, Date.now())
        if (strength > 0) { beatCount += 1; beat(strength) }
    }
    property Connections updates: Connections {
        target: root.active ? root.analyzer : null
        function onBandsChanged() { root.consume() }
        function onRunningChanged() { root.reset() }
    }
}
