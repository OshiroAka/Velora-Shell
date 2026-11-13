import QtQuick
import QtQuick.Shapes

// Settings join the right frame with an open edge and concave shoulders.
// The launcher retains the connected bottom contour. Both follow the same
// presentation geometry.
Item {
    id: root
    property bool bottomAttached: true
    property color tint: "#99162028"
    property bool fadeEnabled: false
    property real fadeHeight: height
    property color rim: "#558eb9ca"
    property real join: Math.min(42, width*.04, height*.3)
    property real corner: Math.min(24, height*.3)
    property real wallInset: 0
    readonly property real wall: Math.max(0,width-wallInset)
    Shape {
        anchors.fill: parent
        visible: !root.bottomAttached
        preferredRendererType: Shape.CurveRenderer
        antialiasing: true
        ShapePath {
            fillColor: root.tint
            strokeColor: "transparent"
            fillGradient: root.fadeEnabled ? sideFade : null
            property var artworkFill: LinearGradient {
                id: sideFade
                x1: 0; y1: 0; x2: 0; y2: Math.max(1,root.fadeHeight)
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: .25; color: "#b3ffffff" }
                GradientStop { position: .72; color: "#b3ffffff" }
                GradientStop { position: .90; color: "#59ffffff" }
                GradientStop { position: 1; color: "transparent" }
            }
            startX: root.wall; startY: 0
            PathQuad { x: root.wall-root.join; y: root.join; controlX: root.wall; controlY: root.join }
            PathLine { x: root.corner; y: root.join }
            PathQuad { x: 0; y: root.join+root.corner; controlX: 0; controlY: root.join }
            PathLine { x: 0; y: root.height-root.join-root.corner }
            PathQuad { x: root.corner; y: root.height-root.join; controlX: 0; controlY: root.height-root.join }
            PathLine { x: root.wall-root.join; y: root.height-root.join }
            PathQuad { x: root.wall; y: root.height; controlX: root.wall; controlY: root.height-root.join }
            PathLine { x: root.wall; y: 0 }
        }
        ShapePath {
            fillColor: "transparent"; strokeColor: root.rim; strokeWidth: 1
            startX: root.wall; startY: 0
            PathQuad { x: root.wall-root.join; y: root.join; controlX: root.wall; controlY: root.join }
            PathLine { x: root.corner; y: root.join }
            PathQuad { x: .5; y: root.join+root.corner; controlX: .5; controlY: root.join }
            PathLine { x: .5; y: root.height-root.join-root.corner }
            PathQuad { x: root.corner; y: root.height-root.join; controlX: .5; controlY: root.height-root.join }
            PathLine { x: root.wall-root.join; y: root.height-root.join }
            PathQuad { x: root.wall; y: root.height; controlX: root.wall; controlY: root.height-root.join }
        }
    }
    Shape {
        anchors.fill: parent
        visible: root.bottomAttached
        preferredRendererType: Shape.CurveRenderer
        antialiasing: true
        ShapePath {
            fillColor: root.tint
            fillGradient: root.fadeEnabled ? artworkGradient : null
            property var artworkFill: LinearGradient {
                id: artworkGradient
                x1: 0; y1: 0; x2: 0; y2: Math.max(1, root.fadeHeight)
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: .25; color: "#b3ffffff" }
                GradientStop { position: .72; color: "#b3ffffff" }
                GradientStop { position: .90; color: "#59ffffff" }
                GradientStop { position: 1; color: "transparent" }
            }
            strokeColor: "transparent"
            startX: 0; startY: root.height
            PathQuad { x: root.join; y: root.height-root.join; controlX: root.join; controlY: root.height }
            PathLine { x: root.join; y: root.corner }
            PathQuad { x: root.join+root.corner; y: 0; controlX: root.join; controlY: 0 }
            PathLine { x: root.width-root.join-root.corner; y: 0 }
            PathQuad { x: root.width-root.join; y: root.corner; controlX: root.width-root.join; controlY: 0 }
            PathLine { x: root.width-root.join; y: root.height-root.join }
            PathQuad { x: root.width; y: root.height; controlX: root.width-root.join; controlY: root.height }
            PathLine { x: 0; y: root.height }
        }
        ShapePath {
            fillColor: "transparent"; strokeColor: root.rim; strokeWidth: 1
            startX: 0; startY: root.height-.5
            PathQuad { x: root.join; y: root.height-root.join; controlX: root.join; controlY: root.height }
            PathLine { x: root.join; y: root.corner }
            PathQuad { x: root.join+root.corner; y: .5; controlX: root.join; controlY: .5 }
            PathLine { x: root.width-root.join-root.corner; y: .5 }
            PathQuad { x: root.width-root.join; y: root.corner; controlX: root.width-root.join; controlY: .5 }
            PathLine { x: root.width-root.join; y: root.height-root.join }
            PathQuad { x: root.width; y: root.height-.5; controlX: root.width-root.join; controlY: root.height }
        }
    }
}
