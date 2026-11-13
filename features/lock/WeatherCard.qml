import QtQuick

GlassPanel {
    id: root

    required property var theme
    required property var motion
    required property var clock
    required property var weather
    property var itemStyle: ({})
    property string variantId: "classic"
    readonly property bool editorial: variantId === "editorial"
    readonly property bool minimal: variantId === "minimal"
    readonly property bool expanded: height >= 205
    readonly property string contentFont: customFont.name.length
        ? customFont.name : String(itemStyle.fontFamily || root.theme.bodyFont)
    readonly property real fontScale: Number(itemStyle.fontScale || 1)
    readonly property color contentColor: String(itemStyle.textColor || "").length
        ? itemStyle.textColor : root.theme.moduleInk
    property real iconLift: weatherHover.hovered && !root.motion.reduced ? 1 : 0

    HoverHandler { id: weatherHover }
    Behavior on iconLift {
        NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
    }

    FontLoader { id: customFont; source: String(root.itemStyle.fontAsset || "") }

    width: 282
    height: 128
    radius: Number(itemStyle.radius === undefined
        ? (editorial ? 24 : (minimal ? 14 : 27)) : itemStyle.radius)
    materialMode: root.theme.resolvedMaterial(itemStyle)
    solidColor: String(itemStyle.solidColor || "#20222a")
    materialOpacity: Number(itemStyle.surfaceOpacity === undefined
        ? root.theme.requestedOpacity : itemStyle.surfaceOpacity)
    surfaceColor: theme.moduleSurface
    flatSurface: Boolean(itemStyle.matchBarSurface)
    borderColor: theme.moduleBorder
    shadowColor: Qt.rgba(theme.shadow.r, theme.shadow.g, theme.shadow.b, 0.16)

    function iconGlyph(name) {
        if (name === "sun") return "☀"
        if (name === "cloud") return "☁"
        if (name === "rain") return "☂"
        if (name === "storm") return "ϟ"
        if (name === "snow") return "❄"
        return "◒"
    }

    Text {
        x: 24
        y: 18
        width: parent.width - 96
        text: root.expanded
            ? root.clock.locale().toString(root.clock.now, "dddd, dd MMMM")
            : root.weather.description
        color: root.theme.textSecondary
        font.family: root.contentFont
        font.pixelSize: (root.editorial ? 13 : 11) * root.fontScale
        font.weight: Font.Medium
        elide: Text.ElideRight
        font.capitalization: Font.Capitalize
    }

    Text {
        x: 24
        y: root.expanded ? 43 : 34
        text: root.weather.temperature + "°"
        color: root.contentColor
        font.family: root.contentFont
        font.pixelSize: (root.expanded ? 62 : 52) * root.fontScale
        font.weight: Font.Light
    }

    Text {
        x: 25
        y: root.expanded ? 111 : 94
        width: parent.width * 0.55
        text: root.weather.description
        visible: root.expanded
        color: root.contentColor
        font.family: root.contentFont
        font.pixelSize: 14 * root.fontScale
        font.weight: Font.Medium
        elide: Text.ElideRight
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 26
        y: (root.expanded ? 31 : 28) - root.iconLift * 3
        width: 68
        height: 68
        text: root.iconGlyph(root.weather.iconName)
        color: root.theme.accentSoft
        font.family: "Noto Sans Symbols 2"
        font.pixelSize: (root.expanded ? 52 : 44) * root.fontScale
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 23
        y: root.expanded ? 105 : 102
        text: "↑ " + root.weather.maximum + "°   ↓ " + root.weather.minimum + "°"
        color: root.theme.textSecondary
        font.family: root.contentFont
        font.pixelSize: 11 * root.fontScale
    }

    Rectangle {
        x: 22
        y: 145
        width: parent.width - 44
        height: 1
        visible: root.expanded
        color: root.theme.borderSubtle
    }

    Row {
        id: forecastRow
        x: 18
        y: 158
        width: parent.width - 36
        height: parent.height - y - 12
        spacing: 0
        visible: root.expanded

        Repeater {
            model: 4

            Item {
                required property int index
                readonly property var day: index < root.weather.forecast.length
                    ? root.weather.forecast[index] : ({})
                width: forecastRow.width / 4
                height: forecastRow.height

                HoverHandler { id: dayHover; enabled: !root.motion.reduced }
                Rectangle {
                    anchors.fill: parent
                    radius: 11
                    color: root.theme.accentSoft
                    opacity: dayHover.hovered ? 0.13 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: 170; easing.type: Easing.OutCubic }
                    }
                }

                Text {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: parent.day.date
                        ? root.clock.locale().toString(
                            new Date(parent.day.date + "T12:00:00"), "ddd") : "—"
                    color: root.theme.textSecondary
                    font.family: root.contentFont
                    font.pixelSize: 10 * root.fontScale
                    font.weight: Font.DemiBold
                    font.capitalization: Font.AllUppercase
                }
                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -1
                    text: root.iconGlyph(parent.day.icon || "partly")
                    color: root.contentColor
                    font.family: "Noto Sans Symbols 2"
                    font.pixelSize: 22 * root.fontScale
                    scale: dayHover.hovered && !root.motion.reduced ? 1.12 : 1
                    Behavior on scale {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }
                }
                Text {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: String(parent.day.max || "--") + "°/"
                        + String(parent.day.min || "--") + "°"
                    color: root.theme.textSecondary
                    font.family: root.contentFont
                    font.pixelSize: 9 * root.fontScale
                }
            }
        }
    }
}
