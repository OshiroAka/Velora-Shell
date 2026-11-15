import QtQuick
import "../core/DockWaveform.js" as Waveform

Canvas {
    id: root
    property var analyzer: null
    property bool reducedMotion: false
    property color ink: "white"
    property real unit: 1
    readonly property bool active: visible && width > 0 && height > 0
    property real level: 0
    property real bass: 0
    property real treble: 0
    property real phase: Math.PI/2
    property bool dirty: false
    property bool settling: false
    antialiasing: true
    clip: true

    function reset() {
        dirty = active
        settling = false
        level = 0; bass = 0; treble = 0
        requestPaint()
    }
    function updateAudio() {
        const frame = analyzer && analyzer.running && typeof analyzer.materialFrame === "function"
            ? String(analyzer.materialFrame()).trim().split(/\s+/).map(Number) : []
        const next = Waveform.response(frame)
        const target = next.level < .015 ? 0 : Math.min(1, Math.pow(next.level,.7)*1.25)
        const delta = target-level
        const smoothed = level+delta*(delta > 0 ? .5 : .2)
        level = Math.abs(target-smoothed) < .002 ? target : smoothed
        bass = next.bass; treble = next.treble
        if (level > .002 && !reducedMotion) phase=(phase+.16+treble*.12)%(Math.PI*2)
        dirty = false
        settling = level !== target
        requestPaint()
    }
    onActiveChanged: reset()
    onAnalyzerChanged: reset()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onInkChanged: requestPaint()
    onUnitChanged: requestPaint()
    Component.onCompleted: reset()
    Connections {
        target: root.active ? root.analyzer : null
        function onBandsChanged() { root.dirty=true }
        function onRunningChanged() { root.dirty=true }
    }
    Timer {
        objectName: "dockWaveformClock"
        interval: 33; repeat: true
        running: root.active && (root.dirty || root.settling)
        onTriggered: root.updateAudio()
    }
    onPaint: {
        const c=getContext("2d")
        c.reset(); c.clearRect(0,0,width,height)
        const samples=Waveform.points(width,height,level,bass,treble,phase)
        c.lineCap="round"; c.lineJoin="round"; c.strokeStyle=ink
        function stroke(thickness, opacity) {
            c.beginPath(); c.moveTo(samples[0].x,samples[0].y)
            for (let i=1;i<samples.length;i++) c.lineTo(samples[i].x,samples[i].y)
            c.lineWidth=thickness; c.globalAlpha=opacity; c.stroke()
        }
        stroke(Math.max(3,6*unit),.055)
        stroke(Math.max(2,3.5*unit),.12)
        stroke(Math.max(1,1.6*unit),.94)
    }
}
