import QtQuick

GlassPanel {
    id: root
    required property var theme
    property var itemStyle: ({})
    property string variantId: "editorial"
    property int motionDuration: 0
    readonly property bool animateContent: motionDuration > 0 && visible
    readonly property string contentFont: customFont.name.length ? customFont.name
        : String(itemStyle.fontFamily || theme.bodyFont)
    readonly property real fontScale: Number(itemStyle.fontScale || 1)
    readonly property color contentColor: String(itemStyle.textColor || "").length
        ? itemStyle.textColor : theme.moduleInk
    readonly property color mutedColor: Qt.rgba(contentColor.r, contentColor.g, contentColor.b, .58)
    readonly property color quietColor: Qt.rgba(contentColor.r, contentColor.g, contentColor.b, .12)
    FontLoader { id: customFont; source: String(root.itemStyle.fontAsset || "") }
    radius: Number(itemStyle.radius === undefined ? 28 : itemStyle.radius)
    materialMode: theme.resolvedMaterial(itemStyle)
    solidColor: String(itemStyle.solidColor || "#20222a")
    materialOpacity: Number(itemStyle.surfaceOpacity === undefined ? 1 : itemStyle.surfaceOpacity)
    surfaceColor: theme.moduleSurface
    flatSurface: Boolean(itemStyle.matchBarSurface)
    borderColor: theme.moduleBorder
    shadowColor: Qt.rgba(theme.shadow.r, theme.shadow.g, theme.shadow.b, .12)
}
