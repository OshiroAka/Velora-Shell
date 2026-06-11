import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property var theme: null
    property real radius: 22
    property real revealProgress: visible ? 1 : 0
    property string attachSide: "left"
    property bool sidebarMaterial: false
    property bool useCustomGlass: false
    property color customGlass: "transparent"
    property bool flattenAttachedEdge: false
    property bool lineReveal: false
    property real transitionContrast: 0
    property real slideOffsetOverride: -1
    readonly property bool pywalStyle: theme && theme.themeId === "pywal16"
    readonly property bool neon: pywalStyle && theme.themeMode === "dark"
    readonly property bool darkSoft: theme && theme.themeMode === "dark"
    readonly property bool attachedRight: attachSide === "right"
    readonly property color baseGlass: useCustomGlass ? customGlass : (theme ? (sidebarMaterial && darkSoft ? theme.withAlpha(theme.surfaceSidebar, Math.min(theme.surfaceSidebar.a, 0.72)) : theme.surfaceSidebar) : Qt.rgba(1.0, 0.986, 1.0, 0.84))
    readonly property real boundedTransitionContrast: Math.max(0, Math.min(1, transitionContrast))
    readonly property color glass: theme && boundedTransitionContrast > 0
        ? theme.withAlpha(baseGlass, Math.min(0.96, baseGlass.a + boundedTransitionContrast * (darkSoft ? 0.08 : 0.10)))
        : baseGlass
    readonly property color borderSoft: theme ? (neon ? theme.popupBorderGlow : theme.borderSoft) : Qt.rgba(1, 1, 1, 0.74)
    readonly property int slideOffset: sidebarMaterial ? 0 : Math.round(slideOffsetOverride >= 0 ? slideOffsetOverride : 34)
    readonly property real maxCornerRadius: Math.max(0, Math.min(radius, width / 2, height / 2))
    readonly property real leftCornerRadius: flattenAttachedEdge && !attachedRight ? 0 : maxCornerRadius
    readonly property real rightCornerRadius: flattenAttachedEdge && attachedRight ? 0 : maxCornerRadius
    readonly property real boundedRevealProgress: Math.max(0, Math.min(1, revealProgress))
    readonly property real lineRevealMinHeightProgress: Math.min(1, 2 / Math.max(1, height))
    readonly property real lineRevealWidthProgress: lineReveal ? Math.max(0.006, Math.min(1, boundedRevealProgress / 0.34)) : 1
    readonly property real lineRevealHeightProgress: lineReveal ? Math.max(lineRevealMinHeightProgress, Math.min(1, (boundedRevealProgress - 0.34) / 0.66)) : 1

    opacity: lineReveal ? Math.min(1, boundedRevealProgress * 2.8) : revealProgress
    scale: lineReveal || sidebarMaterial ? 1 : 0.982 + revealProgress * 0.018
    transformOrigin: attachedRight ? Item.Right : Item.Left
    transform: Translate {
        x: root.lineReveal ? 0 : Math.round((1 - root.revealProgress) * (root.attachedRight ? root.slideOffset : -root.slideOffset))
        y: root.lineReveal ? 0 : Math.round((1 - root.revealProgress) * (root.sidebarMaterial ? 0 : 5))
    }
    layer.enabled: false

    Rectangle {
        z: -1
        visible: false
        x: root.attachedRight ? -10 : 10
        y: root.neon ? 8 : 12
        width: parent.width
        height: parent.height
        radius: root.radius + 2
        color: "transparent"
        antialiasing: true
    }

    Shape {
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer
        transform: Scale {
            origin.x: root.attachedRight ? root.width : 0
            origin.y: root.height / 2
            xScale: root.lineRevealWidthProgress
            yScale: root.lineRevealHeightProgress
        }

        ShapePath {
            fillColor: root.glass
            strokeColor: "transparent"
            strokeWidth: 0
            startX: 0
            startY: root.leftCornerRadius

        PathArc {
            relativeX: root.leftCornerRadius
            relativeY: -root.leftCornerRadius
            radiusX: root.leftCornerRadius
            radiusY: root.leftCornerRadius
            direction: PathArc.Clockwise
        }

            PathLine {
                x: Math.max(root.leftCornerRadius, root.width - root.rightCornerRadius)
                y: 0
            }
            PathArc {
                relativeX: root.rightCornerRadius
                relativeY: root.rightCornerRadius
                radiusX: root.rightCornerRadius
                radiusY: root.rightCornerRadius
            }
            PathLine {
                x: root.width
                y: Math.max(root.rightCornerRadius, root.height - root.rightCornerRadius)
            }
            PathArc {
                relativeX: -root.rightCornerRadius
                relativeY: root.rightCornerRadius
                radiusX: root.rightCornerRadius
                radiusY: root.rightCornerRadius
            }
            PathLine {
                x: root.leftCornerRadius
                y: root.height
            }

        PathArc {
            relativeX: -root.leftCornerRadius
            relativeY: -root.leftCornerRadius
            radiusX: root.leftCornerRadius
            radiusY: root.leftCornerRadius
            direction: PathArc.Clockwise
        }
            PathLine {
                x: 0
                y: root.leftCornerRadius
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: "transparent"
            strokeWidth: 0
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
            strokeColor: "transparent"
            strokeWidth: 0
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
