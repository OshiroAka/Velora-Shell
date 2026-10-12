import QtQuick

GlassPanel {
    id: root

    required property var theme
    required property var clock
    property var itemStyle: ({})
    property string variantId: "classic"
    readonly property bool editorial: variantId === "editorial"
    readonly property bool minimal: variantId === "minimal"
    readonly property string contentFont: customFont.name.length
        ? customFont.name : String(itemStyle.fontFamily || root.theme.bodyFont)
    readonly property string displayFont: String(itemStyle.displayFontFamily || "").length
        ? String(itemStyle.displayFontFamily) : orbitronVariable.name
    readonly property real fontScale: Number(itemStyle.fontScale || 1)
    readonly property color contentColor: String(itemStyle.textColor || "").length
        ? itemStyle.textColor : root.theme.moduleInk

    FontLoader {
        id: orbitronVariable
        source: "../../assets/fonts/Orbitron-Variable.ttf"
    }

    FontLoader { id: customFont; source: String(root.itemStyle.fontAsset || "") }

    width: 282
    height: 120
    radius: Number(itemStyle.radius === undefined
        ? (editorial ? 24 : (minimal ? 14 : 27)) : itemStyle.radius)
    materialMode: root.theme.resolvedMaterial(itemStyle)
    solidColor: String(itemStyle.solidColor || "#20222a")
    materialOpacity: Number(itemStyle.surfaceOpacity === undefined
        ? 0.82 : itemStyle.surfaceOpacity)
    surfaceColor: root.theme.moduleSurface
    flatSurface: Boolean(itemStyle.matchBarSurface)
    borderColor: root.theme.moduleBorder
    shadowColor: Qt.rgba(root.theme.shadow.r, root.theme.shadow.g,
                         root.theme.shadow.b, 0.12)

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.editorial ? Math.max(8, parent.height * 0.08) : 8
        text: root.clock.timeText
        visible: !root.editorial
        color: root.contentColor
        font.family: root.displayFont
        font.pixelSize: (root.editorial
            ? Math.min(parent.width * 0.205, parent.height * 0.50)
            : (root.minimal ? 52 : 64)) * root.fontScale
        font.weight: Number(root.itemStyle.fontWeight || Font.Medium)
        font.letterSpacing: Number(root.itemStyle.letterSpacing === undefined
            ? 1.5 : root.itemStyle.letterSpacing)
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.max(8, parent.height * 0.08)
        spacing: 0
        visible: root.editorial

        Text {
            text: root.clock.timeText.slice(0, 3)
            color: root.contentColor
            font.family: root.displayFont
            font.pixelSize: Math.min(root.width * 0.205,
                root.height * 0.50) * root.fontScale
            font.weight: Number(root.itemStyle.fontWeight || Font.Medium)
            font.letterSpacing: Number(root.itemStyle.letterSpacing === undefined
                ? 1.5 : root.itemStyle.letterSpacing)
        }
        Text {
            text: root.clock.timeText.slice(3)
            color: root.theme.accentAlt
            font.family: root.displayFont
            font.pixelSize: Math.min(root.width * 0.205,
                root.height * 0.50) * root.fontScale
            font.weight: Number(root.itemStyle.fontWeight || Font.Medium)
            font.letterSpacing: Number(root.itemStyle.letterSpacing === undefined
                ? 1.5 : root.itemStyle.letterSpacing)
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.editorial ? parent.height * 0.68 : 79
        text: root.clock.dateText
        color: root.contentColor
        font.family: root.contentFont
        font.pixelSize: (root.editorial ? 16 : (root.minimal ? 13 : 15))
            * root.fontScale
        font.weight: Number(root.itemStyle.fontWeight || Font.Light)
    }
}
