import QtQuick

Item {
    id: root
    property bool highlighted: false
    property bool reducedMotion: false
    property bool outgoing: false
    property real scrollVelocity: 0
    property real presence: 1
    property real hoverAmount: highlighted ? 1 : 0
    property real scrollLag: reducedMotion ? 0 : Math.max(-5,Math.min(5,-scrollVelocity/700))
    property real scrollEnergy: reducedMotion ? 0 : Math.min(1,Math.abs(scrollVelocity)/2600)
    readonly property real lift: reducedMotion ? 0 : -2 * hoverAmount + scrollLag
    readonly property real slide: reducedMotion ? 0 : (outgoing ? 18 : -14) * (1-presence)
    readonly property real rise: reducedMotion ? 0 : 12 * (1-presence)
    readonly property real zoom: reducedMotion ? 1 : .975 + .025*presence + .008*hoverAmount
    readonly property real arrivalLight: 4*presence*(1-presence)
    function arrive() { if (!reducedMotion) entrance.restart() }
    onReducedMotionChanged: if (reducedMotion) { entrance.stop(); presence = 1 }
    Behavior on hoverAmount { NumberAnimation { duration: root.reducedMotion ? 0 : 190; easing.type: Easing.OutCubic } }
    Behavior on scrollLag { NumberAnimation { duration: root.reducedMotion ? 0 : 110; easing.type: Easing.OutCubic } }
    Behavior on scrollEnergy { NumberAnimation { duration: root.reducedMotion ? 0 : 160; easing.type: Easing.OutCubic } }
    NumberAnimation { id: entrance; target: root; property: "presence"; from: 0; to: 1; duration: root.outgoing ? 360 : 440; easing.type: Easing.OutCubic }
}
