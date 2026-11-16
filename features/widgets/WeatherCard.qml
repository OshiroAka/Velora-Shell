import QtQuick
import "../../components" as Components

WidgetSurface {
    id: root
    required property var motion
    required property var clock
    required property var weather
    readonly property bool dotted: variantId === "dots"
    readonly property bool expanded: variantId === "forecast" || height >= 220
    width: 282; height: 160
    Text {
        x: 20; y: 17; width: parent.width - 90
        text: root.weather.location || "TEMPO AGORA"
        color: root.mutedColor; font.family: root.contentFont
        font.pixelSize: 10 * root.fontScale; font.letterSpacing: 1
        elide: Text.ElideRight
    }
    Components.VeloraWeatherIcon {
        anchors.right: parent.right; anchors.rightMargin: 19; y: 18
        width: 48; height: 48; name: root.weather.iconName
        ink: root.contentColor
    }
    Text {
        x: 20; y: 34; visible: !root.dotted
        text: root.weather.temperature + "°"; color: root.contentColor
        font.family: root.contentFont; font.pixelSize: 54 * root.fontScale; font.weight: Font.Light
    }
    DotMatrixText {
        visible: root.dotted; x: 20; y: 43; width: parent.width - 95; height: 58
        text: root.weather.temperature + "°"; color: root.contentColor
    }
    Text {
        x: 21; y: root.dotted ? 112 : 99; width: parent.width - 42
        text: root.weather.description; color: root.contentColor
        font.family: root.contentFont; font.pixelSize: 11 * root.fontScale
        elide: Text.ElideRight
    }
    Text {
        x: 21; y: root.dotted ? 137 : 123; width: parent.width - 42
        text: "↑ " + root.weather.maximum + "°    ↓ " + root.weather.minimum + "°"
        color: root.mutedColor; font.family: root.contentFont; font.pixelSize: 10 * root.fontScale
    }
    Row {
        id: days; visible: root.expanded; x: 20; y: 165; width: parent.width - 40; height: 62
        Repeater {
            model: 4
            Item {
                required property int index
                readonly property var day: root.weather.forecast[index] || ({})
                width: days.width / 4; height: days.height
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: parent.day.date ? root.clock.locale().toString(new Date(parent.day.date + "T12:00:00"), "ddd").toUpperCase() : "—"
                    color: root.mutedColor; font.family: root.contentFont; font.pixelSize: 9
                }
                Components.VeloraWeatherIcon {
                    anchors.horizontalCenter: parent.horizontalCenter; y: 17; width: 24; height: 24
                    name: parent.day.icon || "partly"; ink: root.contentColor
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter; y: 47
                    text: (parent.day.max === undefined ? "—" : parent.day.max) + "° / " + (parent.day.min === undefined ? "—" : parent.day.min) + "°"
                    color: root.mutedColor; font.family: root.contentFont; font.pixelSize: 9
                }
            }
        }
    }
}
