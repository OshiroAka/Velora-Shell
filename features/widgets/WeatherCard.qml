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
        objectName: "weather.animatedIcon"
        anchors.right: parent.right; anchors.rightMargin: 19; y: 18
        width: 48; height: 48; name: root.weather.iconName
        ink: root.contentColor
        drawRain: !rain.visible
        transform: Translate {
            y: drift.running ? driftOffset : 0
            property real driftOffset: 0
            SequentialAnimation on driftOffset {
                id: drift
                running: root.animateContent
                loops: Animation.Infinite
                NumberAnimation { from: 0; to: -4; duration: root.motionDuration * 6; easing.type: Easing.InOutSine }
                NumberAnimation { from: -4; to: 0; duration: root.motionDuration * 6; easing.type: Easing.InOutSine }
            }
        }
        Item {
            id: rain
            objectName: "weather.rain"
            anchors.fill: parent
            visible: root.animateContent && root.weather.iconName === "rain"
            property real phase: 0
            NumberAnimation on phase {
                running: rain.visible
                from: 0; to: 1
                duration: root.motionDuration * 3
                loops: Animation.Infinite
            }
            Repeater {
                model: 3
                Rectangle {
                    required property int index
                    readonly property real fall: (rain.phase + index / 3) % 1
                    x: 14 + index * 10 - fall * 5; y: 33 + fall * 9
                    width: 2.2; height: 7; radius: 1.1; rotation: 29
                    color: root.contentColor
                    opacity: Math.sin(fall * Math.PI)
                }
            }
        }
    }
    Text {
        x: 20; y: 34; visible: !root.dotted
        text: root.weather.temperature + "°"; color: root.contentColor
        font.family: root.contentFont; font.pixelSize: 54 * root.fontScale; font.weight: Font.Light
    }
    DotMatrixText {
        visible: root.dotted; x: 20; y: 43; width: parent.width - 95; height: 58
        text: root.weather.temperature + "°"; color: root.contentColor
        duration: root.motionDuration
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
    WidgetForecastStrip {
        visible: root.expanded; x: 20; y: 165; width: parent.width - 40
        forecast: root.weather.forecast || []
        clock: root.clock
        fontFamily: root.contentFont
        ink: root.contentColor
        muted: root.mutedColor
    }
}
