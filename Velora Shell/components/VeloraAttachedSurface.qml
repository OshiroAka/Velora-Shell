import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property var theme: null
    property real radius: 22
    property real revealProgress: visible ? 1 : 0
    property string attachSide: "left"
    readonly property bool pywalStyle: theme && theme.themeId === "pywal16"
    readonly property bool neon: pywalStyle && theme.themeMode === "dark"
    readonly property bool attachedRight: attachSide === "right"
    readonly property color glass: theme ? theme.surfaceSidebar : Qt.rgba(1.0, 0.986, 1.0, 0.84)
    readonly property color borderSoft: theme ? (neon ? theme.popupBorderGlow : theme.borderSoft) : Qt.rgba(1, 1, 1, 0.74)
    readonly property color borderLine: theme ? theme.alpha(borderSoft, neon ? 0.52 : 0.34) : Qt.rgba(1, 1, 1, 0.34)
    readonly property color shadow: theme ? (neon ? theme.popupBorderGlow : theme.shadowColor) : Qt.rgba(0.48, 0.30, 0.50, 0.10)
    readonly property int slideOffset: 34

    opacity: revealProgress
    scale: 0.982 + revealProgress * 0.018
    transformOrigin: attachedRight ? Item.Right : Item.Left
    transform: Translate {
        x: Math.round((1 - root.revealProgress) * (root.attachedRight ? root.slideOffset : -root.slideOffset))
        y: Math.round((1 - root.revealProgress) * 5)
    }
    layer.enabled: false

    Rectangle {
        z: -1
        x: root.attachedRight ? -10 : 10
        y: root.neon ? 8 : 12
        width: parent.width
        height: parent.height
        radius: root.radius + 2
        color: root.theme ? root.theme.alpha(root.shadow, root.neon ? 0.18 : 0.22) : Qt.rgba(0.48, 0.30, 0.50, 0.06)
        antialiasing: true
    }

    Shape {
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.glass
            strokeColor: "transparent"
            strokeWidth: 0
            startX: 0
            startY: Math.min(root.radius, root.height / 2)

        PathArc {
            relativeX: Math.min(root.radius, root.width / 2)
            relativeY: -Math.min(root.radius, root.height / 2)
            radiusX: Math.min(root.radius, root.width / 2)
            radiusY: Math.min(root.radius, root.height / 2)
            direction: PathArc.Clockwise
        }

            PathLine {
                x: Math.max(root.radius, root.width - root.radius)
                y: 0
            }
            PathArc {
                relativeX: root.radius
                relativeY: root.radius
                radiusX: root.radius
                radiusY: root.radius
            }
            PathLine {
                x: root.width
                y: Math.max(root.radius, root.height - root.radius)
            }
            PathArc {
                relativeX: -root.radius
                relativeY: root.radius
                radiusX: root.radius
                radiusY: root.radius
            }
            PathLine {
                x: Math.min(root.radius, root.width / 2)
                y: root.height
            }

        PathArc {
            relativeX: -Math.min(root.radius, root.width / 2)
            relativeY: -Math.min(root.radius, root.height / 2)
            radiusX: Math.min(root.radius, root.width / 2)
            radiusY: Math.min(root.radius, root.height / 2)
            direction: PathArc.Clockwise
        }
            PathLine {
                x: 0
                y: Math.min(root.radius, root.height / 2)
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.attachedRight ? "transparent" : root.borderLine
            strokeWidth: 1
            startX: Math.min(root.radius, root.width / 2)
            startY: 0

            PathLine {
                x: Math.max(root.radius, root.width - root.radius)
                y: 0
            }
            PathArc {
                relativeX: root.radius
                relativeY: root.radius
                radiusX: root.radius
                radiusY: root.radius
            }
            PathLine {
                x: root.width
                y: Math.max(root.radius, root.height - root.radius)
            }
            PathArc {
                relativeX: -root.radius
                relativeY: root.radius
                radiusX: root.radius
                radiusY: root.radius
            }
            PathLine {
                x: Math.min(root.radius, root.width / 2)
                y: root.height
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.attachedRight ? root.borderLine : "transparent"
            strokeWidth: 1
            startX: Math.max(root.radius, root.width - root.radius)
            startY: 0

            PathLine {
                x: Math.min(root.radius, root.width / 2)
                y: 0
            }
            PathArc {
                relativeX: -Math.min(root.radius, root.width / 2)
                relativeY: Math.min(root.radius, root.height / 2)
                radiusX: Math.min(root.radius, root.width / 2)
                radiusY: Math.min(root.radius, root.height / 2)
                direction: PathArc.Counterclockwise
            }
            PathLine {
                x: 0
                y: Math.max(root.radius, root.height - root.radius)
            }
            PathArc {
                relativeX: Math.min(root.radius, root.width / 2)
                relativeY: Math.min(root.radius, root.height / 2)
                radiusX: Math.min(root.radius, root.width / 2)
                radiusY: Math.min(root.radius, root.height / 2)
                direction: PathArc.Counterclockwise
            }
            PathLine {
                x: Math.max(root.radius, root.width - root.radius)
                y: root.height
            }
        }
    }
}
