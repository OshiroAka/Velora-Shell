import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property bool active: false
    property color ink: "#f5f5f2"
    property color accent: "#cba9c9"
    property color surfaceColor: Qt.rgba(1, 1, 1, 0.06)
    property color borderColor: Qt.rgba(1, 1, 1, 0.16)
    property real extent: 0
    property real windReveal: 0
    implicitWidth: 44
    implicitHeight: 44 * extent
    visible: extent > 0.001

    // Match the coffee widget's compact reveal and two drifting strokes.
    Behavior on extent { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on windReveal { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    onActiveChanged: {
        if (active) {
            exitDelay.stop(); collapseDelay.stop(); spinDown.stop()
            extent = 1
            spinUp.restart(); windDelay.restart()
        } else {
            windDelay.stop(); windReveal = 0; exitDelay.restart()
        }
    }
    Timer { id: windDelay; interval: 550; onTriggered: if (root.active) root.windReveal = 1 }
    Timer {
        id: exitDelay; interval: 160
        onTriggered: {
            spinUp.stop(); cruising.stop()
            spinDown.from = rotor.rotation; spinDown.to = rotor.rotation + 100
            spinDown.restart(); collapseDelay.restart()
        }
    }
    Timer { id: collapseDelay; interval: 170; onTriggered: root.extent = 0 }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 3 + (1 - root.extent) * 2
        width: 34; height: 34
        radius: 8
        color: root.surfaceColor
        border.width: 1; border.color: root.borderColor
        opacity: root.extent
        scale: 0.85 + 0.15 * root.extent

        Canvas {
            id: rotor
            anchors.centerIn: parent
            width: 26; height: 26
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset(); ctx.translate(13, 13)
                ctx.strokeStyle = root.ink
                ctx.fillStyle = Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.12)
                ctx.lineWidth = 1.25; ctx.lineJoin = "round"
                for (let i = 0; i < 4; i++) {
                    ctx.save(); ctx.rotate(i * Math.PI / 2)
                    ctx.beginPath(); ctx.moveTo(1.5, -2)
                    ctx.bezierCurveTo(2.5, -5, 2, -10, 6, -10)
                    ctx.bezierCurveTo(9.5, -10, 10, -6, 7, -4)
                    ctx.bezierCurveTo(5, -2.5, 3, -2, 1.5, -2)
                    ctx.closePath(); ctx.fill(); ctx.stroke(); ctx.restore()
                }
                ctx.beginPath(); ctx.arc(0, 0, 2.3, 0, Math.PI * 2); ctx.stroke()
            }
            Connections {
                target: root
                function onInkChanged() { rotor.requestPaint() }
            }
        }
        Item {
            anchors.fill: parent
            opacity: root.windReveal
            visible: opacity > 0.001
            Repeater {
                model: 2
                Item {
                    id: strand
                    required property int index
                    property real progress: 0
                    property real drift: 0
                    readonly property real cycle: (progress + index * 0.5) % 1
                    x: 25 + cycle * 6
                    y: 13 + index * 6 + drift
                    opacity: 0.38 * Math.sin(Math.PI * cycle)
                    NumberAnimation on progress {
                        from: 0; to: 1; duration: 2600; loops: Animation.Infinite
                        running: root.visible && root.active && root.windReveal > 0.001
                    }
                    SequentialAnimation on drift {
                        loops: Animation.Infinite
                        running: root.visible && root.active && root.windReveal > 0.001
                        NumberAnimation { from: -0.6; to: 0.6; duration: 1300; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.6; to: -0.6; duration: 1300; easing.type: Easing.InOutSine }
                    }
                    Shape {
                        ShapePath {
                            fillColor: "transparent"; strokeColor: root.ink
                            strokeWidth: 1.05; capStyle: ShapePath.RoundCap
                            startX: 0; startY: 0
                            PathCubic { x: 5; y: 0.3; control1X: 1.4; control1Y: -1.5; control2X: 3.1; control2Y: 1.7 }
                        }
                    }
                }
            }
        }
    }
    NumberAnimation {
        id: spinUp; target: rotor; property: "rotation"
        from: 0; to: 360; duration: 1100; easing.type: Easing.InCubic
        onStopped: if (root.active) cruising.start()
    }
    RotationAnimator {
        id: cruising; target: rotor; from: 0; to: 360
        duration: 800; loops: Animation.Infinite
    }
    NumberAnimation {
        id: spinDown; target: rotor; property: "rotation"
        duration: 440; easing.type: Easing.OutCubic
    }
}
