import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property real radius: 28
    property string materialMode: "liquid"
    property color solidColor: "#20222a"
    // "Solid" is a distinct accessibility/material choice, not glass with
    // its blur disabled. Keep only a trace of backdrop so it reads as an
    // opaque graphite plate instead of an unblurred transparent rectangle.
    property real materialOpacity: 0.97
    property color surfaceColor: Qt.rgba(0.85, 0.92, 1.0, 0.55)
    property color borderColor: Qt.rgba(1.0, 1.0, 1.0, 0.45)
    property color shadowColor: Qt.rgba(0.02, 0.07, 0.16, 0.28)
    property bool consumeInput: true
    property bool clipContent: false
    property bool nativeOptics: false
    // Used by shared widgets in "same as bar" mode. A flat fill preserves
    // the bar's exact tint/alpha instead of multiplying it through a second
    // widget-only gradient.
    property bool flatSurface: false
    property bool causticsEnabled: false
    property real causticsIntensity: 0.32
    property real causticsPhase: 0
    property point causticsOrigin: Qt.point(0, 0)
    property real causticsScale: 1
    property real causticsRotation: 0
    property real leftOpeningCenter: -1
    property real leftOpeningHalfHeight: 0
    readonly property bool leftOpeningActive: leftOpeningCenter >= 0
        && leftOpeningHalfHeight > 0.5
    readonly property bool liquidMaterial: materialMode === "liquid"
    readonly property bool solidMaterial: materialMode === "solid"
    default property alias contentData: contentLayer.data

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.leftMargin: -3
        anchors.rightMargin: -3
        anchors.bottomMargin: -10
        radius: root.radius
        color: root.shadowColor
        visible: root.liquidMaterial
        opacity: root.nativeOptics && root.liquidMaterial ? 0.16 : 0.30
    }

    Rectangle {
        id: glassBody
        anchors.fill: parent
        radius: root.radius
        visible: root.materialMode !== "none"
        color: root.solidMaterial
            ? Qt.rgba(root.solidColor.r, root.solidColor.g,
                      root.solidColor.b, root.materialOpacity)
            : (root.flatSurface ? root.surfaceColor : "transparent")
        gradient: root.solidMaterial || root.flatSurface ? null : liquidGradient
        Gradient {
            id: liquidGradient
            GradientStop {
                position: 0
                color: Qt.rgba(root.surfaceColor.r, root.surfaceColor.g,
                               root.surfaceColor.b,
                               Math.min(1, root.surfaceColor.a
                                   * (root.nativeOptics && root.liquidMaterial ? 0.78 : 1.42)))
            }
            GradientStop {
                position: 0.46
                color: Qt.rgba(root.surfaceColor.r, root.surfaceColor.g,
                               root.surfaceColor.b,
                               root.surfaceColor.a
                                   * (root.nativeOptics && root.liquidMaterial ? 0.70 : 1.0))
            }
            GradientStop {
                position: 1
                color: Qt.rgba(root.surfaceColor.r, root.surfaceColor.g,
                               root.surfaceColor.b,
                               root.surfaceColor.a
                                   * (root.nativeOptics && root.liquidMaterial ? 0.64 : 0.58))
            }
        }
        border.width: root.leftOpeningActive ? 0 : 1
        border.color: root.solidMaterial ? Qt.rgba(0.78, 0.84, 1, 0.12 * root.materialOpacity)
            : (root.nativeOptics && root.liquidMaterial
                ? Qt.rgba(1.0, 1.0, 1.0, 0.045) : root.borderColor)
    }

    PoolCausticsOverlay {
        anchors.fill: parent
        active: root.liquidMaterial && root.causticsEnabled && !root.nativeOptics
        phase: root.causticsPhase
        strength: root.causticsIntensity
        designOrigin: root.causticsOrigin
        designScale: root.causticsScale
        designRotation: root.causticsRotation
        cornerRadius: root.radius
    }

    // The main panel can open its left rim while the profile surface morphs
    // out of the wall. This is the same outline, with only that segment
    // omitted, so there is never a vertical seam behind the morph.
    Shape {
        id: segmentedOutline
        anchors.fill: parent
        visible: root.materialMode !== "none" && root.leftOpeningActive

        readonly property real kappa: 0.5522847498
        readonly property real gapTop: Math.max(root.radius,
            root.leftOpeningCenter - root.leftOpeningHalfHeight)
        readonly property real gapBottom: Math.min(root.height - root.radius,
            root.leftOpeningCenter + root.leftOpeningHalfHeight)

        ShapePath {
            strokeWidth: 1
            strokeColor: root.nativeOptics && root.liquidMaterial
                ? Qt.rgba(1.0, 1.0, 1.0, 0.045) : root.borderColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 0
            startY: segmentedOutline.gapBottom

            PathLine { x: 0; y: root.height - root.radius }
            PathCubic {
                control1X: 0
                control1Y: root.height - root.radius
                    + segmentedOutline.kappa * root.radius
                control2X: root.radius - segmentedOutline.kappa * root.radius
                control2Y: root.height
                x: root.radius
                y: root.height
            }
            PathLine { x: root.width - root.radius; y: root.height }
            PathCubic {
                control1X: root.width - root.radius
                    + segmentedOutline.kappa * root.radius
                control1Y: root.height
                control2X: root.width
                control2Y: root.height - root.radius
                    + segmentedOutline.kappa * root.radius
                x: root.width
                y: root.height - root.radius
            }
            PathLine { x: root.width; y: root.radius }
            PathCubic {
                control1X: root.width
                control1Y: root.radius - segmentedOutline.kappa * root.radius
                control2X: root.width - root.radius
                    + segmentedOutline.kappa * root.radius
                control2Y: 0
                x: root.width - root.radius
                y: 0
            }
            PathLine { x: root.radius; y: 0 }
            PathCubic {
                control1X: root.radius - segmentedOutline.kappa * root.radius
                control1Y: 0
                control2X: 0
                control2Y: root.radius - segmentedOutline.kappa * root.radius
                x: 0
                y: root.radius
            }
            PathLine { x: 0; y: segmentedOutline.gapTop }
        }
    }

    // A clear glass surface is defined by the light caught at its rim. These
    // highlights stay independent of the compositor blur beneath the panel.
    Rectangle {
        visible: root.liquidMaterial && !root.nativeOptics
        anchors.fill: parent
        anchors.margins: 2
        radius: Math.max(0, root.radius - 2)
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1.0, 1.0, 1.0, 0.16)
    }

    Rectangle {
        visible: root.liquidMaterial && !root.nativeOptics
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 3
        height: Math.min(96, root.height * 0.20)
        radius: Math.max(0, root.radius - 3)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.115) }
            GradientStop { position: 0.52; color: Qt.rgba(1, 1, 1, 0.035) }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    Rectangle {
        visible: root.liquidMaterial && !root.nativeOptics
        x: root.radius * 0.62
        y: 1
        width: Math.max(0, root.width - root.radius * 1.24)
        height: 2
        radius: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.18; color: Qt.rgba(1, 1, 1, 0.64) }
            GradientStop { position: 0.50; color: Qt.rgba(1, 1, 1, 0.88) }
            GradientStop { position: 0.82; color: Qt.rgba(1, 1, 1, 0.64) }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    Rectangle {
        visible: root.liquidMaterial && !root.nativeOptics
        x: 1
        y: root.radius * 0.72
        width: 2
        height: Math.max(0, root.height - root.radius * 1.44)
        radius: 1
        gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.35; color: Qt.rgba(1, 1, 1, 0.34) }
            GradientStop { position: 0.72; color: Qt.rgba(1, 1, 1, 0.15) }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    Item {
        id: contentLayer
        anchors.fill: parent
        clip: root.clipContent

        MouseArea {
            anchors.fill: parent
            enabled: root.consumeInput
            z: -1
            onClicked: function(mouse) { mouse.accepted = true }
        }
    }
}
