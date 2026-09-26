import QtQuick

Item {
    id: root

    required property var config
    required property var theme
    required property var motion
    property bool profileTransitioning: false
    property int profileTransitionDuration: 680
    property bool interactionsEnabled: true
    property bool nativeOptics: false
    property var itemStyle: ({})
    property string variantId: "classic"
    readonly property bool editorial: variantId === "editorial"
    readonly property bool minimal: variantId === "minimal"

    readonly property var order: root.config.galleryOrder || [0, 1, 2]
    property bool transitioning: false

    width: 302
    height: 294

    GlassPanel {
        anchors.fill: parent
        radius: Number(root.itemStyle.radius === undefined
            ? (root.editorial ? 24 : (root.minimal ? 14 : 28))
            : root.itemStyle.radius)
        materialMode: root.theme.resolvedMaterial(root.itemStyle)
        solidColor: String(root.itemStyle.solidColor || "#20222a")
        materialOpacity: Number(root.itemStyle.surfaceOpacity === undefined
            ? 0.82 : root.itemStyle.surfaceOpacity)
        surfaceColor: root.theme.moduleSurface
        flatSurface: Boolean(root.itemStyle.matchBarSurface)
        borderColor: root.theme.moduleBorder
        shadowColor: Qt.rgba(root.theme.shadow.r, root.theme.shadow.g,
                             root.theme.shadow.b, 0.12)
        nativeOptics: root.nativeOptics
        consumeInput: false
    }

    function promote(assetIndex) {
        const slot = order.indexOf(assetIndex)
        if (slot <= 0)
            return
        const next = order.slice()
        const previousMain = next[0]
        next[0] = assetIndex
        next[slot] = previousMain
        transitioning = true
        root.config.setGalleryOrder(next)
        transitionTimer.restart()
    }

    Timer {
        id: transitionTimer
        interval: root.motion.depth + 30
        repeat: false
        onTriggered: root.transitioning = false
    }

    Repeater {
        model: 3

        Item {
            id: tile
            required property int index
            readonly property int slot: root.order.indexOf(index)
            readonly property bool hovered: tileMouse.containsMouse

            x: root.editorial ? 12 + slot * ((root.width - 40) / 3 + 8)
                : (slot === 0 ? 0 : 157)
            y: root.editorial ? 12 : (slot === 0 ? 0 : (slot === 1 ? 0 : 154))
            width: root.editorial ? (root.width - 40) / 3
                : (slot === 0 ? 144 : 145)
            height: root.editorial ? root.height - 24
                : (slot === 0 ? 294 : 140)
            z: hovered ? 10 : (slot === 0 ? 3 : (3 - slot))
            transformOrigin: Item.Center
            scale: root.transitioning && slot !== 0 ? 0.97
                : (tileMouse.pressed ? 0.985 : (hovered ? (slot === 0 ? 1.035 : 1.05) : 1))

            transform: Translate {
                y: tile.hovered && !root.transitioning ? -4 : 0
                Behavior on y {
                    NumberAnimation { duration: root.motion.hover; easing.type: Easing.OutCubic }
                }
            }

            Behavior on x {
                NumberAnimation { duration: root.motion.depth; easing.type: Easing.InOutCubic }
            }
            Behavior on y {
                NumberAnimation { duration: root.motion.depth; easing.type: Easing.InOutCubic }
            }
            Behavior on width {
                NumberAnimation { duration: root.motion.depth; easing.type: Easing.InOutCubic }
            }
            Behavior on height {
                NumberAnimation { duration: root.motion.depth; easing.type: Easing.InOutCubic }
            }
            Behavior on scale {
                NumberAnimation { duration: root.motion.hover; easing.type: Easing.OutCubic }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -7
                radius: 24
                color: Qt.rgba(0.02, 0.04, 0.08, 0.42)
                opacity: tile.hovered ? 0.52 : 0
                scale: tile.hovered ? 1 : 0.96

                Behavior on opacity {
                    NumberAnimation { duration: root.motion.hover; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    NumberAnimation { duration: root.motion.hover; easing.type: Easing.OutCubic }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: root.editorial ? 17 : 18
                color: root.theme.glassSoft
            }

            CrossfadeRoundedImage {
                anchors.fill: parent
                source: root.config.galleryPaths[tile.index] || ""
                radius: root.editorial ? 17 : 18
                blurAmount: root.transitioning && tile.slot !== 0 ? 0.10 : 0
                contentScale: root.config.galleryScales[tile.index] || 1
                contentOffsetX: root.config.galleryOffsetsX[tile.index] || 0
                contentOffsetY: root.config.galleryOffsetsY[tile.index] || 0
                mirrored: root.config.galleryFlipX[tile.index] || false
                reducedMotion: root.motion.reduced
                duration: root.profileTransitioning
                    ? root.profileTransitionDuration : (root.motion.reduced ? 0 : 170)
            }

            Rectangle {
                anchors.fill: parent
                radius: root.editorial ? 17 : 18
                color: "transparent"
                border.width: tile.hovered ? 2 : 1
                border.color: tile.hovered
                    ? Qt.rgba(1.0, 1.0, 1.0, 0.76)
                    : Qt.rgba(1.0, 1.0, 1.0, 0.30)

                Behavior on border.color {
                    ColorAnimation { duration: root.motion.hover }
                }
            }

            MouseArea {
                id: tileMouse
                anchors.fill: parent
                enabled: root.interactionsEnabled
                hoverEnabled: enabled
                cursorShape: Qt.PointingHandCursor
                onClicked: root.promote(tile.index)
            }
        }
    }
}
