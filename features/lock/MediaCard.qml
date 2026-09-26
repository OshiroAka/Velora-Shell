import QtQuick

GlassPanel {
    id: root

    required property var media
    required property var theme
    required property var motion
    property url fallbackArt
    property var itemStyle: ({})
    property string variantId: "classic"
    readonly property bool editorial: variantId === "editorial"
    readonly property bool minimal: variantId === "minimal"
    readonly property string contentFont: customFont.name.length
        ? customFont.name : String(itemStyle.fontFamily || root.theme.bodyFont)
    readonly property real fontScale: Number(itemStyle.fontScale || 1)
    readonly property color contentColor: String(itemStyle.textColor || "").length
        ? itemStyle.textColor : root.theme.textPrimary

    FontLoader { id: customFont; source: String(root.itemStyle.fontAsset || "") }

    width: 294
    height: 76
    radius: Number(itemStyle.radius === undefined
        ? (editorial ? 22 : (minimal ? 14 : 24)) : itemStyle.radius)
    materialMode: root.theme.resolvedMaterial(itemStyle)
    solidColor: String(itemStyle.solidColor || "#20222a")
    materialOpacity: Number(itemStyle.surfaceOpacity === undefined
        ? root.theme.requestedOpacity : itemStyle.surfaceOpacity)
    surfaceColor: theme.moduleSurface
    flatSurface: Boolean(itemStyle.matchBarSurface)
    borderColor: theme.moduleBorder
    shadowColor: Qt.rgba(theme.shadow.r, theme.shadow.g, theme.shadow.b, 0.16)
    transformOrigin: Item.Center
    scale: cardHover.hovered ? 1.008 : 1

    Behavior on scale {
        NumberAnimation { duration: root.motion.hover; easing.type: Easing.OutCubic }
    }
    HoverHandler { id: cardHover }

    RoundedImage {
        id: cover
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(parent.height - 20, 72)
        height: width
        radius: root.editorial ? 15 : width / 2
        source: root.media.artUrl.length ? root.media.artUrl : root.fallbackArt
        visible: root.media.hasPlayer
        transformOrigin: Item.Center
        scale: coverHover.hovered ? 1.025 : 1
        Behavior on scale {
            NumberAnimation { duration: root.motion.hover; easing.type: Easing.OutCubic }
        }
    }
    HoverHandler { id: coverHover; target: cover }

    Rectangle {
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(parent.height - 20, 72)
        height: width
        radius: root.editorial ? 15 : width / 2
        visible: !root.media.hasPlayer
        color: root.theme.surfaceSoft
        Text {
            anchors.centerIn: parent
            text: "♫"
            color: root.theme.textSecondary
            font.family: root.contentFont
            font.pixelSize: 27 * root.fontScale
        }
    }

    Text {
        x: 98
        y: parent.height / 2 - 24
        width: Math.max(20, transport.x - x - 12)
        text: root.media.hasPlayer ? root.media.title : "Nenhuma mídia"
        color: root.contentColor
        font.family: root.contentFont
        font.pixelSize: (root.editorial ? 14 : 13) * root.fontScale
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }

    Text {
        x: 98
        y: parent.height / 2 + 2
        width: Math.max(20, transport.x - x - 12)
        text: root.media.hasPlayer ? root.media.artist
            : "Selecione algo para reproduzir"
        color: root.theme.textSecondary
        font.family: root.contentFont
        font.pixelSize: 10 * root.fontScale
        elide: Text.ElideRight
    }

    Row {
        id: transport
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5
        visible: true

        Repeater {
            model: [
                { id: "previous", symbol: "‹", enabled: root.media.canPrevious },
                { id: "toggle", symbol: root.media.playing ? "Ⅱ" : "▶", enabled: root.media.canToggle },
                { id: "next", symbol: "›", enabled: root.media.canNext }
            ]

            Rectangle {
                id: control
                required property var modelData
                width: control.modelData.id === "toggle" ? 34 : 30
                height: width
                radius: width / 2
                opacity: modelData.enabled ? 1 : 0.36
                color: control.modelData.id === "toggle"
                    ? root.theme.accentMuted : root.theme.surfaceSoft
                scale: pointer.pressed ? 0.92 : (pointer.containsMouse ? 1.06 : 1)
                Behavior on scale { NumberAnimation { duration: root.motion.micro; easing.type: Easing.OutCubic } }
                Text {
                    anchors.centerIn: parent
                    text: control.modelData.symbol
                    color: root.contentColor
                    font.family: root.contentFont
                    font.pixelSize: 14 * root.fontScale
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    id: pointer
                    anchors.fill: parent
                    enabled: control.modelData.enabled
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (control.modelData.id === "previous") root.media.previous()
                        else if (control.modelData.id === "toggle") root.media.togglePlaying()
                        else root.media.next()
                    }
                }
            }
        }
    }

    Rectangle {
        x: 98
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        width: parent.width - x - 18
        height: 2
        radius: 1
        color: root.theme.borderSubtle
        visible: root.media.hasPlayer
        Rectangle {
            width: parent.width * root.media.progress
            height: parent.height
            radius: parent.radius
            color: root.theme.accentAlt
            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.Linear } }
        }
    }
}
