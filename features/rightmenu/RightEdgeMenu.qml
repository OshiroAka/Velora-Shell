import QtQuick
import QtQuick.Shapes
import Quickshell.Hyprland

Item {
    id: root

    required property var motion
    required property var actions
    required property int opticsGeneration

    property real nativeSurfaceWidth: width
    property real nativeSurfaceHeight: height

    width: 126
    height: 900

    property real morphTarget: 0
    property real morphLevel: morphTarget
    property int carouselTop: 2
    property bool nativeShapeDirty: true

    readonly property real centerY: height * 0.5
    readonly property real railWidth: 9
    readonly property real tabStop: 0.34
    readonly property real surfaceDepth: staged(morphLevel, 0, 56, 64)
    readonly property real surfaceHalfHeight: staged(morphLevel, 34, 86, 178)
    readonly property real straightHalfHeight: staged(morphLevel, 18, 52, 103)
    readonly property real shoulderHeight: Math.max(14,
        surfaceHalfHeight - straightHalfHeight)
    readonly property real iconReveal: Math.max(0,
        Math.min(1, (morphLevel - 0.48) / 0.34))
    readonly property real tabReveal: Math.max(0,
        1 - Math.abs(morphLevel - tabStop) / 0.26)

    // Exported to the host: only the live edge and its growing silhouette
    // receive pointer input; the rest of this transparent window is inert.
    readonly property real inputX: width - railWidth
        - Math.max(12, surfaceDepth)
    readonly property real inputY: centerY - surfaceHalfHeight - 12
    readonly property real inputWidth: width - inputX
    readonly property real inputHeight: surfaceHalfHeight * 2 + 24

    readonly property var menuItems: [
        { glyph: "\uf0c1", color: "#45e0a1", name: "Network" },
        { glyph: "\uf067", color: "#ffd247", name: "Lock" },
        { glyph: "\uf007", color: "#45a7ff", name: "Profile" },
        { glyph: "\uf002", color: "#ff795f", name: "Search" },
        { glyph: "\uf015", color: "#9b58ff", name: "Home" }
    ]

    function queueNativeShape() {
        nativeShapeDirty = true
    }

    function syncNativeShape() {
        if (nativeSurfaceWidth <= 0 || nativeSurfaceHeight <= 0)
            return
        Hyprland.dispatch("velora-blur:right-menu-shape 1 "
            + (surfaceDepth / nativeSurfaceWidth).toFixed(6) + " "
            + (surfaceHalfHeight / nativeSurfaceHeight).toFixed(6) + " "
            + (straightHalfHeight / nativeSurfaceHeight).toFixed(6) + " "
            + (railWidth / nativeSurfaceWidth).toFixed(6) + " "
            + (centerY / nativeSurfaceHeight).toFixed(6))
    }

    onSurfaceDepthChanged: queueNativeShape()
    onSurfaceHalfHeightChanged: queueNativeShape()
    onStraightHalfHeightChanged: queueNativeShape()
    onRailWidthChanged: queueNativeShape()
    onCenterYChanged: queueNativeShape()
    onNativeSurfaceWidthChanged: queueNativeShape()
    onNativeSurfaceHeightChanged: queueNativeShape()
    onOpticsGenerationChanged: queueNativeShape()

    FrameAnimation {
        id: nativeShapeSync
        running: root.nativeShapeDirty
        onTriggered: {
            root.syncNativeShape()
            root.nativeShapeDirty = false
        }
    }

    Component.onCompleted: queueNativeShape()
    Component.onDestruction:
        Hyprland.dispatch("velora-blur:right-menu-shape 0 0 0 0 0.005 0.5")

    function staged(level, hiddenValue, tabValue, openValue) {
        const value = Math.max(0, Math.min(1, level))
        if (value <= tabStop)
            return hiddenValue + (tabValue - hiddenValue) * value / tabStop
        return tabValue + (openValue - tabValue)
            * (value - tabStop) / (1 - tabStop)
    }

    function reveal() {
        closeDelay.stop()
        if (morphLevel < 0.48)
            morphTarget = tabStop
        expandDelay.restart()
    }

    function queueClose() {
        expandDelay.stop()
        closeDelay.restart()
    }

    function activate(index) {
        if (index === 0)
            actions.openNetworkSettings()
        else if (index === 1)
            actions.showLockPreview()
        else if (index === 2)
            actions.openSettings()
        else if (index === 3)
            actions.openSearch()
        else
            actions.openLauncher()
    }

    function scrollCarousel(delta) {
        carouselTop = Math.max(0, Math.min(2, carouselTop + delta))
        morphTarget = 1
    }

    Behavior on morphLevel {
        NumberAnimation {
            duration: root.morphTarget > root.morphLevel ? 330 : 360
            easing.type: root.morphTarget > root.morphLevel
                ? Easing.OutCubic : Easing.InOutCubic
        }
    }

    Timer {
        id: expandDelay
        interval: 310
        repeat: false
        onTriggered: {
            if (edgeHover.hovered)
                root.morphTarget = 1
        }
    }

    Timer {
        id: closeDelay
        interval: 170
        repeat: false
        onTriggered: {
            if (!edgeHover.hovered)
                root.morphTarget = 0
        }
    }

    // The thin wall and the bulge deliberately share one exact color and
    // overlap by two pixels.  There is no seam between trigger and menu.
    Rectangle {
        visible: false
        x: parent.width - root.railWidth
        y: 0
        width: root.railWidth
        height: parent.height
        color: Qt.rgba(0.055, 0.015, 0.19, 0.12)
    }

    Shape {
        visible: false
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillColor: Qt.rgba(0.055, 0.015, 0.19, 0.12)
            startX: root.width - root.railWidth + 2
            startY: root.centerY - root.surfaceHalfHeight

            PathCubic {
                x: root.width - root.railWidth - root.surfaceDepth
                y: root.centerY - root.straightHalfHeight
                control1X: root.width - root.railWidth
                control1Y: root.centerY - root.surfaceHalfHeight
                    + root.shoulderHeight * 0.58
                control2X: root.width - root.railWidth - root.surfaceDepth
                    + Math.min(17, root.surfaceDepth * 0.30)
                control2Y: root.centerY - root.straightHalfHeight
            }
            PathLine {
                x: root.width - root.railWidth - root.surfaceDepth
                y: root.centerY + root.straightHalfHeight
            }
            PathCubic {
                x: root.width - root.railWidth + 2
                y: root.centerY + root.surfaceHalfHeight
                control1X: root.width - root.railWidth - root.surfaceDepth
                    + Math.min(17, root.surfaceDepth * 0.30)
                control1Y: root.centerY + root.straightHalfHeight
                control2X: root.width - root.railWidth
                control2Y: root.centerY + root.surfaceHalfHeight
                    - root.shoulderHeight * 0.58
            }
            PathLine {
                x: root.width - root.railWidth + 2
                y: root.centerY - root.surfaceHalfHeight
            }
        }
    }

    Item {
        id: compactLabel
        x: root.width - root.railWidth - root.surfaceDepth + 4
        y: root.centerY - 54
        width: Math.max(34, root.surfaceDepth - 6)
        height: 108
        opacity: root.tabReveal
        scale: 0.92 + root.tabReveal * 0.08

        Behavior on opacity { NumberAnimation { duration: 120 } }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 10
            text: "\uf00a"
            color: "#f3efff"
            font.family: "FontAwesome"
            font.pixelSize: 16
        }

        Text {
            anchors.centerIn: parent
            text: "Menu"
            rotation: 90
            color: "#f3efff"
            font.family: "Poppins"
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }
    }

    Item {
        id: carouselViewport
        x: root.width - root.railWidth - root.surfaceDepth
        y: root.centerY - 98
        width: Math.max(44, root.surfaceDepth)
        height: 196
        clip: true
        opacity: root.iconReveal

        Behavior on opacity { NumberAnimation { duration: 145 } }

        Repeater {
            model: root.menuItems

            delegate: Item {
                id: actionNode
                required property int index
                required property var modelData

                readonly property int slot: index - root.carouselTop
                x: (carouselViewport.width - 42) * 0.5
                y: slot * 62 + 5
                width: 42
                height: 46
                visible: slot >= -1 && slot <= 3
                opacity: slot >= 0 && slot <= 2 ? 1 : 0
                scale: actionPress.pressed ? 0.88
                    : (actionHover.hovered ? 1.10 : 1)

                Behavior on y {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }
                Behavior on opacity { NumberAnimation { duration: 130 } }
                Behavior on scale {
                    NumberAnimation { duration: 150; easing.type: Easing.OutBack }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 32
                    height: 32
                    radius: 16
                    color: Qt.rgba(1, 1, 1,
                        actionHover.hovered ? 0.10 : 0)
                    border.width: actionHover.hovered ? 1 : 0
                    border.color: Qt.rgba(1, 1, 1,
                        actionHover.hovered ? 0.16 : 0)

                    Text {
                        anchors.centerIn: parent
                        text: actionNode.modelData.glyph
                        color: actionNode.modelData.color
                        font.family: "FontAwesome"
                        font.pixelSize: 18
                    }
                }

                HoverHandler { id: actionHover }
                TapHandler {
                    id: actionPress
                    onTapped: root.activate(actionNode.index)
                }
            }
        }
    }

    HoverHandler {
        id: edgeHover
        margin: 0
        onHoveredChanged: hovered ? root.reveal() : root.queueClose()
    }

    WheelHandler {
        enabled: root.morphLevel > 0.48
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(event) {
            root.scrollCarousel(event.angleDelta.y > 0 ? -1 : 1)
            event.accepted = true
        }
    }
}
