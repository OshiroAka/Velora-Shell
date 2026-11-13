import QtQuick

Item {
    id: root

    required property var theme
    property var items: []
    property var itemStyle: ({})
    property bool nativeOptics: false
    readonly property string layoutMode: String(itemStyle.galleryLayout || "grid2")
    readonly property int columns: layoutMode === "grid4" ? 4
        : (layoutMode === "grid3" ? 3 : 2)
    readonly property int rows: Math.max(1, Math.ceil(Math.min(16, items.length) / columns))
    readonly property real gap: Number(itemStyle.gap === undefined ? 10 : itemStyle.gap)
    readonly property real padding: String(itemStyle.material || "none") === "none"
        ? 0 : Math.max(6, gap)

    GlassPanel {
        anchors.fill: parent
        radius: Number(root.itemStyle.radius === undefined ? 28 : root.itemStyle.radius)
        materialMode: root.theme.resolvedMaterial(root.itemStyle)
        solidColor: String(root.itemStyle.solidColor || "#20222a")
        materialOpacity: Number(root.itemStyle.surfaceOpacity === undefined
            ? 0.82 : root.itemStyle.surfaceOpacity)
        surfaceColor: root.theme.moduleSurface
        borderColor: root.theme.moduleBorder
        shadowColor: Qt.rgba(root.theme.shadow.r, root.theme.shadow.g,
                             root.theme.shadow.b, 0.12)
        nativeOptics: root.nativeOptics
        consumeInput: false
    }

    Repeater {
        model: Math.min(16, root.items.length)

        CroppedImage {
            required property int index
            readonly property var entry: root.items[index] || ({})
            readonly property bool feature: root.layoutMode === "feature"
            readonly property real usableWidth: root.width - root.padding * 2
            readonly property real usableHeight: root.height - root.padding * 2
            readonly property real smallWidth: (usableWidth - root.gap) * 0.48
            readonly property real largeWidth: usableWidth - smallWidth - root.gap

            x: root.padding + (feature
                ? (index === 0 ? 0 : largeWidth + root.gap)
                : (index % root.columns) * ((usableWidth
                    - root.gap * (root.columns - 1)) / root.columns + root.gap))
            y: root.padding + (feature
                ? (index === 0 ? 0 : (index - 1) * ((usableHeight
                    - root.gap * Math.max(0, root.items.length - 2))
                    / Math.max(1, root.items.length - 1) + root.gap))
                : Math.floor(index / root.columns) * ((usableHeight
                    - root.gap * (root.rows - 1)) / root.rows + root.gap))
            width: feature ? (index === 0 ? largeWidth : smallWidth)
                : (usableWidth - root.gap * (root.columns - 1)) / root.columns
            height: feature ? (index === 0 ? usableHeight
                : (usableHeight - root.gap * Math.max(0, root.items.length - 2))
                    / Math.max(1, root.items.length - 1))
                : (usableHeight - root.gap * (root.rows - 1)) / root.rows
            source: String(entry.path || "")
            crop: entry.crop || ({ x: 0, y: 0, width: 1, height: 1 })
            mirrored: Boolean(entry.flipX)
            radius: Math.max(0, Number(root.itemStyle.radius || 22) * 0.55)
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.items.length === 0
        text: "Galeria vazia"
        color: root.theme.moduleInk
        font.family: root.theme.bodyFont
        font.pixelSize: 15
        font.weight: Font.DemiBold
        opacity: 0.72
    }
}
