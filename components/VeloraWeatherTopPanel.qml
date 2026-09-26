import QtQuick

Item {
    id: root

    property var theme: null
    property var weather: null
    property bool open: false
    property bool embeddedInFrame: false
    property bool fahrenheit: false
    property int metric: 0
    property color barSurface: theme ? theme.surfacePopup : "#172820"
    readonly property color ink: theme ? theme.textPrimary : "#f2f5f4"
    readonly property color muted: theme ? theme.textSecondary : "#a8b8b2"
    readonly property color accent: theme ? theme.accentPrimary : "#8bcab3"
    readonly property color line: theme ? theme.borderSoft : "#53625e"
    readonly property string uiFont: theme ? theme.uiFont : "Noto Sans"
    readonly property var hours: weather ? weather.hourly : []
    readonly property var days: weather ? weather.forecast : []

    signal closeRequested()
    signal activated()
    signal pointerInsideChanged(bool inside)

    function temperature(value) {
        if (value === undefined || value === null || String(value).trim() === "")
            return "--"
        const number = Number(value)
        if (!isFinite(number)) return "--"
        return String(Math.round(fahrenheit ? number * 9 / 5 + 32 : number))
    }

    function metricValue(entry) {
        if (!entry) return 0
        const number = Number(metric === 0 ? entry.temp
            : (metric === 1 ? entry.rain : entry.wind))
        return isFinite(number) ? number : 0
    }

    function metricLabel(entry) {
        const value = metricValue(entry)
        if (metric === 0) return temperature(entry ? entry.temp : "") + "°"
        return metric === 1 ? Math.round(value) + "%" : Math.round(value) + " km/h"
    }

    function weatherIcon(name) {
        if (name === "sun") return "sun"
        if (name === "rain" || name === "storm") return "rain"
        if (name === "cloud") return "cloud"
        if (name === "snow") return "cloud"
        return "partly"
    }

    function dayLabel(day) {
        if (!day || !day.date) return "—"
        return Qt.locale("pt_BR").toString(new Date(day.date + "T12:00:00"), "ddd").toUpperCase()
    }

    HoverHandler { onHoveredChanged: root.pointerInsideChanged(hovered) }
    Keys.onEscapePressed: root.closeRequested()

    Rectangle {
        anchors.fill: parent
        radius: 24
        color: root.embeddedInFrame ? "transparent" : root.barSurface
        border.width: root.embeddedInFrame ? 0 : 1
        border.color: root.line
    }

    Text {
        x: 28; y: 18
        text: "PREVISÃO DO TEMPO"
        color: root.accent
        font.family: root.uiFont
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 1.2
    }
    Text {
        x: 28; y: 38; width: 214
        text: root.weather && root.weather.location
            ? root.weather.location : "Localização atual"
        color: root.muted
        font.family: root.uiFont
        font.pixelSize: 12
        elide: Text.ElideRight
    }
    MouseArea {
        id: refreshButton
        x: 202; y: 14; width: 28; height: 28
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.weather) root.weather.refresh(true)
        VeloraMaterialIcon {
            anchors.centerIn: parent
            width: 17; height: 17
            iconName: "refresh"
            iconColor: refreshButton.containsMouse ? root.ink : root.muted
        }
    }

    VeloraMaterialIcon {
        x: 28; y: 74; width: 58; height: 58
        iconName: root.weather ? root.weatherIcon(root.weather.iconName) : "partly"
        iconColor: root.accent
        filled: true
    }
    Text {
        x: 96; y: 67
        text: root.temperature(root.weather ? root.weather.temperature : "") + "°"
        color: root.ink
        font.family: root.uiFont
        font.pixelSize: 52
        font.weight: Font.Light
    }
    Row {
        x: 179; y: 81; spacing: 3
        Repeater {
            model: [{ label: "C", active: !root.fahrenheit },
                    { label: "F", active: root.fahrenheit }]
            Rectangle {
                required property int index
                required property var modelData
                width: 24; height: 23; radius: 8
                color: modelData.active
                    ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.24)
                    : "transparent"
                border.width: 1
                border.color: modelData.active ? root.accent : root.line
                Text {
                    anchors.centerIn: parent
                    text: parent.modelData.label
                    color: parent.modelData.active ? root.ink : root.muted
                    font.family: root.uiFont; font.pixelSize: 10
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.fahrenheit = index === 1
                }
            }
        }
    }
    Text {
        x: 30; y: 139; width: 198
        text: root.weather ? root.weather.description : "Clima indisponível"
        color: root.ink
        font.family: root.uiFont
        font.pixelSize: 14
        elide: Text.ElideRight
    }
    Text {
        x: 30; y: 164; width: 206
        text: "Máx. " + root.temperature(root.weather ? root.weather.maximum : "")
            + "°   ·   Mín. " + root.temperature(root.weather ? root.weather.minimum : "") + "°"
        color: root.muted
        font.family: root.uiFont
        font.pixelSize: 11
    }
    Rectangle { x: 28; y: 191; width: 205; height: 1; color: root.line; opacity: 0.45 }

    Repeater {
        model: [
            { label: "Umidade", value: root.weather ? root.weather.humidity + "%" : "--" },
            { label: "Precipitação", value: root.weather ? root.weather.rain + "%" : "--" },
            { label: "Vento", value: root.weather ? root.weather.wind + " km/h" : "--" }
        ]
        Item {
            required property var modelData
            required property int index
            x: 28; y: 201 + index * 27; width: 205; height: 25
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: parent.modelData.label
                color: root.muted; font.family: root.uiFont; font.pixelSize: 11
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: parent.modelData.value
                color: root.ink; font.family: root.uiFont; font.pixelSize: 11
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: root.line; opacity: 0.24 }
        }
    }

    Rectangle {
        id: chartCard
        x: 252; y: 16; width: parent.width - x - 28; height: 265
        radius: 16
        color: Qt.rgba(1, 1, 1, 0.025)
        border.width: 1
        border.color: root.line

        Row {
            x: 14; y: 12; spacing: 4
            Repeater {
                model: ["Temperatura", "Precipitação", "Vento"]
                Rectangle {
                    required property int index
                    required property string modelData
                    width: label.implicitWidth + 20; height: 28; radius: 9
                    color: root.metric === index ? Qt.rgba(1, 1, 1, 0.10) : "transparent"
                    Text {
                        id: label; anchors.centerIn: parent
                        text: modelData
                        color: root.metric === index ? root.ink : root.muted
                        font.family: root.uiFont; font.pixelSize: 11
                        font.weight: root.metric === index ? Font.DemiBold : Font.Normal
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.metric = index }
                }
            }
        }

        Canvas {
            id: graph
            x: 15; y: 70; width: parent.width - 30; height: 125
            antialiasing: true
            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                const values = root.hours.map(function(entry) { return root.metricValue(entry) })
                if (values.length < 2) return
                const low = Math.min.apply(null, values)
                const high = Math.max.apply(null, values)
                const span = Math.max(2, high - low)
                const points = values.map(function(value, index) {
                    return { x: index * width / (values.length - 1),
                        y: 16 + (high - value) / span * (height - 35) }
                })
                ctx.beginPath()
                ctx.moveTo(points[0].x, points[0].y)
                for (let index = 1; index < points.length; index++)
                    ctx.lineTo(points[index].x, points[index].y)
                ctx.lineTo(width, height)
                ctx.lineTo(0, height)
                ctx.closePath()
                const fill = ctx.createLinearGradient(0, 0, 0, height)
                fill.addColorStop(0, root.metric === 1
                    ? "rgba(93,146,171,0.5)" : "rgba(180,157,82,0.46)")
                fill.addColorStop(1, "rgba(0,0,0,0)")
                ctx.fillStyle = fill
                ctx.fill()
                ctx.beginPath()
                ctx.moveTo(points[0].x, points[0].y)
                for (let index = 1; index < points.length; index++)
                    ctx.lineTo(points[index].x, points[index].y)
                ctx.strokeStyle = root.ink
                ctx.lineWidth = 1.7
                ctx.stroke()
            }
        }
        Repeater {
            model: root.hours.length
            Item {
                required property int index
                readonly property var hour: root.hours[index]
                x: 14 + index * (chartCard.width - 28 - width) /
                    Math.max(1, root.hours.length - 1)
                y: 59; width: 55; height: 195
                Text {
                    anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                    text: root.metricLabel(parent.hour)
                    color: root.muted; font.family: root.uiFont; font.pixelSize: 10
                }
                Text {
                    anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                    text: parent.hour.time || "—"
                    color: root.muted; font.family: root.uiFont; font.pixelSize: 10
                }
            }
        }
        Text {
            anchors.centerIn: parent
            visible: root.hours.length === 0
            text: root.weather && root.weather.error ? root.weather.error : "Previsão horária indisponível"
            color: root.muted; font.family: root.uiFont; font.pixelSize: 12
        }
    }

    Rectangle { x: 28; y: 296; width: parent.width - 56; height: 1; color: root.line; opacity: 0.55 }
    Row {
        x: 28; y: 307; width: parent.width - 56; height: 72; spacing: 10
        Repeater {
            model: root.days.length
            Rectangle {
                required property int index
                readonly property var day: root.days[index]
                width: Math.max(100, (root.width - 56 - 20) / Math.max(1, root.days.length))
                height: 68; radius: 13
                color: index === 0 ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
                    : Qt.rgba(1, 1, 1, 0.035)
                Text {
                    x: 13; y: 7
                    text: root.dayLabel(parent.day)
                    color: root.muted; font.family: root.uiFont; font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
                VeloraMaterialIcon {
                    x: 12; y: 27; width: 30; height: 30
                    iconName: root.weatherIcon(parent.day.icon)
                    iconColor: root.accent; filled: true
                }
                Text {
                    x: 52; y: 34
                    text: root.temperature(parent.day.max) + "° / "
                        + root.temperature(parent.day.min) + "°"
                    color: root.ink; font.family: root.uiFont; font.pixelSize: 12
                }
            }
        }
        Text {
            visible: root.days.length === 0
            text: "Próximos dias indisponíveis"
            color: root.muted; font.family: root.uiFont; font.pixelSize: 12
        }
    }

    Connections {
        target: root.weather
        function onHourlyChanged() { graph.requestPaint() }
    }
    onMetricChanged: graph.requestPaint()
    Component.onCompleted: graph.requestPaint()
}
