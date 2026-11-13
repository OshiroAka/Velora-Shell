import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property var theme: null
    property real radius: 22
    property real revealProgress: visible ? 1 : 0
    property string attachSide: "left"
    property bool sidebarMaterial: false
    property bool useCustomGlass: false
    property color customGlass: "transparent"
    property bool useCustomGradient: false
    property color gradientStartColor: customGlass
    property color gradientMiddleColor: customGlass
    property color gradientEndColor: customGlass
    property real gradientStartX: 0
    property real gradientStartY: 0
    property real gradientEndX: 1
    property real gradientEndY: 1
    property bool animateCustomGradient: false
    property int gradientAnimationDuration: 12000
    property real gradientMotionPhase: 0
    property bool flattenAttachedEdge: false
    property bool outwardMold: false
    property bool lineReveal: false
    property real transitionContrast: 0
    property real slideOffsetOverride: -1
    readonly property bool pywalStyle: theme && theme.themeId === "pywal16"
    readonly property bool neon: pywalStyle && theme.themeMode === "dark"
    readonly property bool darkSoft: theme && theme.themeMode === "dark"
    readonly property bool attachedRight: attachSide === "right"
    readonly property bool attachedBottom: attachSide === "bottom"
    readonly property real moldBleed: attachedRight
        ? Math.max(72, Math.min(96, radius * 3.2))
        : (attachedBottom ? Math.max(84, Math.min(108, radius * 3.5)) : 0)
    readonly property real moldShoulderDepth: attachedRight
        ? Math.max(48, Math.min(64, radius * 2.1))
        : (attachedBottom ? Math.max(56, Math.min(72, radius * 2.4)) : 0)
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
    readonly property bool gradientMotionEnabled: animateCustomGradient
        && useCustomGradient
        && (!theme || theme.motionEnabled)
    readonly property real gradientMotionRadians: gradientMotionPhase * Math.PI * 2
    readonly property real gradientMotionCenterX: 0.5 + 0.23 * Math.cos(gradientMotionRadians * 2)
    readonly property real gradientMotionCenterY: 0.5 + 0.18 * Math.sin(gradientMotionRadians * 2)
    readonly property real effectiveGradientStartX: gradientMotionEnabled
        ? gradientMotionCenterX + 0.92 * Math.cos(gradientMotionRadians)
        : gradientStartX
    readonly property real effectiveGradientStartY: gradientMotionEnabled
        ? gradientMotionCenterY + 0.74 * Math.sin(gradientMotionRadians)
        : gradientStartY
    readonly property real effectiveGradientEndX: gradientMotionEnabled
        ? gradientMotionCenterX + 0.92 * Math.cos(gradientMotionRadians + Math.PI)
        : gradientEndX
    readonly property real effectiveGradientEndY: gradientMotionEnabled
        ? gradientMotionCenterY + 0.74 * Math.sin(gradientMotionRadians + Math.PI)
        : gradientEndY
    readonly property color effectiveGradientStartColor: gradientMotionEnabled
        ? cycleGradientColor(0)
        : gradientStartColor
    readonly property color effectiveGradientMiddleColor: gradientMotionEnabled
        ? cycleGradientColor(1 / 3)
        : gradientMiddleColor
    readonly property color effectiveGradientEndColor: gradientMotionEnabled
        ? cycleGradientColor(2 / 3)
        : gradientEndColor
    readonly property string surfacePathData: buildSurfacePath()

    function mixGradientColor(first, second, amount) {
        const value = Math.max(0, Math.min(1, Number(amount) || 0))
        return Qt.rgba(
            first.r + (second.r - first.r) * value,
            first.g + (second.g - first.g) * value,
            first.b + (second.b - first.b) * value,
            first.a + (second.a - first.a) * value
        )
    }

    function cycleGradientColor(offset) {
        const wrapped = gradientMotionPhase + Number(offset || 0)
        const segment = (wrapped - Math.floor(wrapped)) * 3
        if (segment < 1)
            return mixGradientColor(gradientStartColor, gradientMiddleColor, segment)
        if (segment < 2)
            return mixGradientColor(gradientMiddleColor, gradientEndColor, segment - 1)
        return mixGradientColor(gradientEndColor, gradientStartColor, segment - 2)
    }

    function buildSurfacePath() {
        const w = Math.max(1, width)
        const h = Math.max(1, height)

        if (outwardMold && attachedRight) {
            const bleed = Math.max(1, Math.min(moldBleed, h * 0.34))
            const shoulder = Math.max(1, Math.min(moldShoulderDepth, w * 0.42))
            const bodyBottom = h - bleed
            const bodyRadius = Math.max(0, Math.min(radius, w * 0.32, (bodyBottom - bleed) * 0.28))
            return "M " + bodyRadius + " " + bleed
                + " Q 0 " + bleed + " 0 " + (bleed + bodyRadius)
                + " L 0 " + (bodyBottom - bodyRadius)
                + " Q 0 " + bodyBottom + " " + bodyRadius + " " + bodyBottom
                + " L " + (w - shoulder) + " " + bodyBottom
                + " C " + (w - shoulder * 0.34) + " " + bodyBottom
                + " " + w + " " + (h - bleed * 0.34)
                + " " + w + " " + h
                + " L " + w + " 0"
                + " C " + w + " " + (bleed * 0.34)
                + " " + (w - shoulder * 0.34) + " " + bleed
                + " " + (w - shoulder) + " " + bleed
                + " Z"
        }

        if (outwardMold && attachedBottom) {
            const bleed = Math.max(1, Math.min(moldBleed, w * 0.34))
            const shoulder = Math.max(1, Math.min(moldShoulderDepth, h * 0.42))
            const bodyRight = w - bleed
            const bodyRadius = Math.max(0, Math.min(radius, (bodyRight - bleed) * 0.28, h * 0.32))
            return "M " + (bleed + bodyRadius) + " 0"
                + " L " + (bodyRight - bodyRadius) + " 0"
                + " Q " + bodyRight + " 0 " + bodyRight + " " + bodyRadius
                + " L " + bodyRight + " " + (h - shoulder)
                + " C " + bodyRight + " " + (h - shoulder * 0.34)
                + " " + (w - bleed * 0.34) + " " + h
                + " " + w + " " + h
                + " L 0 " + h
                + " C " + (bleed * 0.34) + " " + h
                + " " + bleed + " " + (h - shoulder * 0.34)
                + " " + bleed + " " + (h - shoulder)
                + " L " + bleed + " " + bodyRadius
                + " Q " + bleed + " 0 " + (bleed + bodyRadius) + " 0"
                + " Z"
        }

        const leftRadius = Math.max(0, Math.min(leftCornerRadius, w / 2, h / 2))
        const rightRadius = Math.max(0, Math.min(rightCornerRadius, w / 2, h / 2))
        return "M " + leftRadius + " 0"
            + " L " + (w - rightRadius) + " 0"
            + " Q " + w + " 0 " + w + " " + rightRadius
            + " L " + w + " " + (h - rightRadius)
            + " Q " + w + " " + h + " " + (w - rightRadius) + " " + h
            + " L " + leftRadius + " " + h
            + " Q 0 " + h + " 0 " + (h - leftRadius)
            + " L 0 " + leftRadius
            + " Q 0 0 " + leftRadius + " 0"
            + " Z"
    }

    opacity: lineReveal ? Math.min(1, boundedRevealProgress * 2.8) : revealProgress
    scale: lineReveal || sidebarMaterial ? 1 : 0.982 + revealProgress * 0.018
    transformOrigin: attachedRight ? Item.Right : (attachedBottom ? Item.Bottom : Item.Left)
    transform: Translate {
        x: root.lineReveal ? 0 : Math.round((1 - root.revealProgress) * (root.attachedRight ? root.slideOffset : -root.slideOffset))
        y: root.lineReveal ? 0 : Math.round((1 - root.revealProgress) * (root.sidebarMaterial ? 0 : 5))
    }
    layer.enabled: false

    NumberAnimation on gradientMotionPhase {
        from: 0
        to: 1
        duration: Math.max(1000, root.gradientAnimationDuration)
        easing.type: Easing.Linear
        loops: Animation.Infinite
        running: root.gradientMotionEnabled
            && root.visible
            && root.width > 0
            && root.height > 0
    }

    Shape {
        id: surfaceShape
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer
        transform: Scale {
            origin.x: root.attachedRight ? root.width : (root.attachedBottom ? root.width / 2 : 0)
            origin.y: root.attachedBottom ? root.height : root.height / 2
            xScale: root.lineRevealWidthProgress
            yScale: root.lineRevealHeightProgress
        }

        ShapePath {
            fillColor: "transparent"
            fillGradient: LinearGradient {
                x1: root.width * root.effectiveGradientStartX
                y1: root.height * root.effectiveGradientStartY
                x2: root.width * root.effectiveGradientEndX
                y2: root.height * root.effectiveGradientEndY
                GradientStop {
                    position: 0
                    color: root.useCustomGradient ? root.effectiveGradientStartColor : root.glass
                }
                GradientStop {
                    position: root.gradientMotionEnabled
                        ? 0.25 + 0.08 * Math.sin(root.gradientMotionRadians)
                        : 0.26
                    color: root.useCustomGradient
                        ? (root.gradientMotionEnabled ? root.cycleGradientColor(1 / 6) : root.gradientStartColor)
                        : root.glass
                }
                GradientStop {
                    position: root.gradientMotionEnabled
                        ? 0.5 + 0.14 * Math.sin(root.gradientMotionRadians + Math.PI * 0.5)
                        : 0.52
                    color: root.useCustomGradient ? root.effectiveGradientMiddleColor : root.glass
                }
                GradientStop {
                    position: root.gradientMotionEnabled
                        ? 0.75 + 0.08 * Math.sin(root.gradientMotionRadians + Math.PI)
                        : 0.76
                    color: root.useCustomGradient
                        ? (root.gradientMotionEnabled ? root.cycleGradientColor(1 / 2) : root.gradientEndColor)
                        : root.glass
                }
                GradientStop {
                    position: 1
                    color: root.useCustomGradient ? root.effectiveGradientEndColor : root.glass
                }
            }
            strokeColor: "transparent"
            strokeWidth: 0

            PathSvg {
                path: root.surfacePathData
            }
        }
    }

}
