import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property color color: "white"
    property real cpuUsage: -1
    property bool animate: true
    property real phase: 0
    property real cadence: 0.65
    readonly property real targetCadence: 1000 / (4 * (420 - Math.max(0, Math.min(100, cpuUsage)) * 3.1))
    readonly property real stride: Math.sin(phase)
    readonly property real lift: Math.cos(phase)
    implicitWidth: 34; implicitHeight: 22

    FrameAnimation {
        running: root.visible && root.animate && root.cpuUsage >= 0
        onTriggered: {
            const dt = Math.min(frameTime, 0.05)
            root.cadence += (root.targetCadence - root.cadence) * (1 - Math.exp(-dt / 0.45))
            root.phase = (root.phase + dt * root.cadence * Math.PI * 2) % (Math.PI * 2)
        }
    }
    Item {
        width: 34; height: 24
        scale: 1
        transform: Scale { xScale: root.width / 34; yScale: root.height / 24 }
        Shape {
            y: Math.cos(root.phase * 2) * 0.45
            // Preserve the existing silhouette; only the gait, tail and subtle
            // body rise change. Scene-graph paths avoid per-frame canvas uploads.
            ShapePath {
                strokeColor: "transparent"; fillColor: root.color
                fillRule: ShapePath.OddEvenFill
                PathSvg { path: "M9 13 C12 7 19 9 23 7 L25 3 L27 6 L30 3 L30 8 C34 11 29 14 25 12 C21 16 16 16 10 16 Z M28.7 8 A.7 .8 0 1 0 27.3 8 A.7 .8 0 1 0 28.7 8 Z" }
            }
            ShapePath {
                strokeColor: root.color; strokeWidth: 2; fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: 11; startY: 13
                PathCubic { x: 1; y: 15 + root.lift * 0.9; control1X: 6; control1Y: 10 + root.stride * 0.6; control2X: 5; control2Y: 17 + root.lift * 0.7 }
            }
            ShapePath {
                strokeColor: root.color; strokeWidth: 2.3; fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: 12; startY: 15
                PathQuad { x: 10 - root.stride * 3; y: 20 - Math.max(0, root.lift) * 1.2; controlX: 11 - root.stride; controlY: 18 }
            }
            ShapePath {
                strokeColor: root.color; strokeWidth: 2.3; fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: 15; startY: 15
                PathQuad { x: 17 + root.stride * 3; y: 20 - Math.max(0, -root.lift) * 1.2; controlX: 15 + root.stride; controlY: 18 }
            }
            ShapePath {
                strokeColor: root.color; strokeWidth: 2.3; fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: 23; startY: 12
                PathQuad { x: 22 + root.stride * 3; y: 18 - Math.max(0, -root.lift); controlX: 23 + root.stride; controlY: 15 }
            }
            ShapePath {
                strokeColor: root.color; strokeWidth: 2.3; fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: 25; startY: 12
                PathQuad { x: 28 - root.stride * 2; y: 17 - Math.max(0, root.lift); controlX: 26 - root.stride; controlY: 15 }
            }
        }
    }
}
