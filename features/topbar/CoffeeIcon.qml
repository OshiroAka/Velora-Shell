import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property color color: "white"
    property bool active: false
    property bool animate: true
    property real smokeReveal: active ? 1 : 0
    implicitWidth: 24; implicitHeight: 22
    Behavior on smokeReveal { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    BarIcon { anchors.fill: parent; name: "caffeine"; color: root.color }
    Item {
        objectName: "coffeeSmoke"
        width: 24; height: 24
        transform: Scale { xScale: root.width / 24; yScale: root.height / 24 }
        opacity: root.smokeReveal
        y: (1 - root.smokeReveal) * 2
        visible: opacity > 0.001
        Repeater {
            model: 2
            Item {
                id: strand
                objectName: "coffeeSmokeStrand" + index
                required property int index
                property real progress: 0
                property real drift: 0
                readonly property real cycle: (progress + index * 0.5) % 1
                x: 8 + index * 5 + drift
                y: 5 - cycle * 6
                opacity: 0.38 * Math.sin(Math.PI * cycle)
                NumberAnimation on progress {
                    from: 0; to: 1; duration: 2600; loops: Animation.Infinite
                    running: root.visible && root.animate && root.smokeReveal > 0.001
                }
                SequentialAnimation on drift {
                    loops: Animation.Infinite
                    running: root.visible && root.animate && root.smokeReveal > 0.001
                    NumberAnimation { from: -0.6; to: 0.6; duration: 1300; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.6; to: -0.6; duration: 1300; easing.type: Easing.InOutSine }
                }
                Shape {
                    ShapePath {
                        fillColor: "transparent"; strokeColor: root.color
                        strokeWidth: 1.05; capStyle: ShapePath.RoundCap
                        startX: 0; startY: 0
                        PathCubic { x: 0.3; y: -5; control1X: -1.5; control1Y: -1.4; control2X: 1.7; control2Y: -3.1 }
                    }
                }
            }
        }
    }
}
