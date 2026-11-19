import QtQuick
import "../../components" as Components

Row {
    id: root
    required property var forecast
    required property var clock
    required property string fontFamily
    required property color ink
    required property color muted

    Repeater {
        model: 4
        Item {
            required property int index
            readonly property var day: root.forecast[index] || ({})
            width: root.width / 4
            height: 64
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: parent.day.date ? root.clock.locale().toString(new Date(parent.day.date + "T12:00:00"), "ddd").toUpperCase() : "—"
                color: root.muted; font.family: root.fontFamily; font.pixelSize: 9
            }
            Components.VeloraWeatherIcon {
                anchors.horizontalCenter: parent.horizontalCenter; y: 17; width: 24; height: 24
                visible: Boolean(parent.day.date)
                name: parent.day.icon || "partly"; ink: root.ink
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter; y: 47
                text: parent.day.max === undefined ? "—" : parent.day.max + "° / " + parent.day.min + "°"
                color: root.muted; font.family: root.fontFamily; font.pixelSize: 9
            }
        }
    }
}
