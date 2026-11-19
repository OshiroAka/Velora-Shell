import QtQuick
import "../../components" as Components

WidgetSurface {
    id: root

    required property string kind
    required property var clock
    required property var weather
    required property var status
    signal closeRequested()

    implicitHeight: body.y + body.height + 14
    itemStyle: ({material: "solid", solidColor: String(theme.moduleSurface), radius: 19})

    function close() { closeRequested() }
    function batteryEstimate() {
        const device = status.battery
        if (!status.hasBattery || !device)
            return ""
        const seconds = Number(status.batteryCharging ? device.timeToFull : device.timeToEmpty)
        if (!(seconds > 0))
            return ""
        const minutes = Math.ceil(seconds / 60)
        const hours = Math.floor(minutes / 60)
        const duration = hours > 0 ? hours + " h " + minutes % 60 + " min" : minutes + " min"
        return status.batteryCharging ? duration + " até a carga completa" : duration + " de autonomia estimada"
    }

    component DetailText: Text {
        font.family: root.contentFont
        font.pixelSize: 12
        color: root.contentColor
        elide: Text.ElideRight
    }

    DetailText {
        x: 16; y: 13; width: parent.width - 60
        text: ({clock: root.clock.locale().toString(root.clock.now, "MMMM yyyy"),
                weather: "Previsão", system: "Tráfego de rede", battery: "Bateria"})[root.kind] || ""
        font.weight: Font.DemiBold
    }
    Item {
        id: closeButton
        width: 34; height: 34; x: parent.width - 39; y: 4
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: "Fechar detalhes"
        Accessible.onPressAction: root.close()
        Keys.onSpacePressed: root.close()
        Keys.onReturnPressed: root.close()
        Components.VeloraMaterialIcon {
            anchors.centerIn: parent; width: 16; height: 16
            iconName: "close"; iconColor: root.mutedColor
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.close() }
    }
    Loader {
        id: body
        x: 16; y: 42
        width: parent.width - 32
        height: item ? item.implicitHeight : 0
        sourceComponent: ({clock: calendarDetails, weather: forecastDetails,
                           system: networkDetails, battery: batteryDetails})[root.kind] || null
    }

    Component {
        id: calendarDetails
        Grid {
            id: month
            columns: 7
            readonly property date date: root.clock.now
            readonly property int offset: new Date(date.getFullYear(), date.getMonth(), 1).getDay()
            readonly property int dayCount: new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate()
            Repeater {
                model: 7
                DetailText {
                    required property int index
                    width: month.width / 7; height: 18
                    horizontalAlignment: Text.AlignHCenter
                    color: root.mutedColor
                    text: root.clock.locale().standaloneDayName(index === 0 ? 7 : index, Locale.NarrowFormat)
                }
            }
            Repeater {
                model: month.offset + month.dayCount
                Item {
                    required property int index
                    readonly property int day: index - month.offset + 1
                    width: month.width / 7; height: 22
                    Rectangle {
                        anchors.centerIn: parent; width: 22; height: 22; radius: 11
                        visible: parent.day === month.date.getDate()
                        color: root.theme.accentMuted
                    }
                    DetailText {
                        anchors.centerIn: parent
                        text: parent.day > 0 ? parent.day : ""
                    }
                }
            }
        }
    }
    Component {
        id: forecastDetails
        WidgetForecastStrip {
            forecast: root.weather.forecast || []
            clock: root.clock
            fontFamily: root.contentFont
            ink: root.contentColor
            muted: root.mutedColor
        }
    }
    Component {
        id: networkDetails
        Column {
            spacing: 8
            DetailText {
                width: parent.width
                text: root.status.performanceAvailable
                    ? "↓ " + Math.round(root.status.networkDownKbps) + " KB/s     ↑ " + Math.round(root.status.networkUpKbps) + " KB/s"
                    : "Métricas indisponíveis"
            }
            WidgetNetworkTrace {
                id: trace
                width: parent.width; height: 38
                visible: samples.length > 1
                samples: root.status.networkHistory || []
                ink: root.theme.accentSoft
            }
        }
    }
    Component {
        id: batteryDetails
        Column {
            spacing: 5
            DetailText {
                width: parent.width
                text: !root.status.hasBattery ? "Sem bateria" : root.status.batteryPercent + "% · "
                    + (root.status.batteryCharging ? "Carregando" : root.status.batteryPercent >= 99 ? "Carga completa" : "Em uso")
            }
            DetailText {
                width: parent.width
                text: root.batteryEstimate()
                visible: text.length > 0
                color: root.mutedColor
            }
        }
    }
}
