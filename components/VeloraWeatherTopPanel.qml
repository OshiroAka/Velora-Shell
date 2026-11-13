pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

// Content only: the connected host supplies the bar's single liquid surface.
Item {
    id: root
    property var theme: null
    property var weather: null
    property var motionTokens: null
    property bool open: false
    property real contentPadding: 16
    property bool fahrenheit: false
    property int metric: 0
    property bool reducedMotion: (motionTokens ? motionTokens.reduced : !!theme && !!theme.config && theme.config.reducedMotion)
        || (!!theme && theme.motionEnabled === false)
    readonly property color ink: theme ? theme.textPrimary : "#f1f4f7"
    readonly property color muted: theme ? theme.textSecondary : "#bac5ce"
    readonly property color accent: theme ? (theme.accent || theme.accentPrimary || ink) : ink
    readonly property string uiFont: theme ? (theme.bodyFont || theme.uiFont || "Sans Serif") : "Sans Serif"
    readonly property var hours: weather && Array.isArray(weather.hourly) ? weather.hourly : []
    readonly property var days: weather && Array.isArray(weather.forecast) ? weather.forecast.slice(0,4) : []
    readonly property bool interactionHeld: chart.interactionHeld
    signal closeRequested()
    signal activated()
    signal pointerInsideChanged(bool inside)

    function number(value) {
        return value === undefined || value === null || String(value).trim() === "" ? NaN : Number(value)
    }
    function temperature(value) {
        const n = number(value)
        return isFinite(n) ? String(Math.round(fahrenheit ? n * 9 / 5 + 32 : n)) : "—"
    }
    function measurement(value, suffix) {
        const n = number(value)
        return isFinite(n) ? Math.round(n) + suffix : "—"
    }
    function reading(key) { return weather ? weather[key] : undefined }
    function dayLabel(day, index) {
        if (day && String(day.label || "").toLowerCase() === "hoje") return "Hoje"
        const date = new Date(String(day ? day.date : "") + "T12:00:00")
        return isNaN(date.getTime()) ? "—" : Qt.locale("pt_BR").toString(date,"ddd").replace(/\./g,"")
    }
    HoverHandler { onHoveredChanged: root.pointerInsideChanged(hovered) }
    Keys.onEscapePressed: root.closeRequested()

    component Label: Text {
        color: root.ink; font.family: root.uiFont; font.pixelSize: 11
        elide: Text.ElideRight
    }
    component Action: Button {
        id: action
        property string glyph: ""
        property bool weatherGlyph: false
        property bool selected: false
        implicitWidth: 28; implicitHeight: 28
        hoverEnabled: true
        scale: down ? .93 : 1
        Behavior on scale { NumberAnimation { duration: root.reducedMotion ? 0 : 110; easing.type: Easing.OutCubic } }
        background: Rectangle {
            radius: 9
            color: Qt.rgba(root.ink.r,root.ink.g,root.ink.b,action.down ? .19 : action.selected ? .12 : action.hovered ? .06 : 0)
            border.width: action.activeFocus ? 1 : 0; border.color: root.muted
            Behavior on color { ColorAnimation { duration: root.reducedMotion ? 0 : 120 } }
        }
        contentItem: Item {
            VeloraWeatherIcon {
                visible: action.weatherGlyph
                anchors.centerIn: parent; width: 20; height: 20
                name: action.glyph; ink: root.ink
            }
            VeloraMaterialIcon {
                visible: !action.weatherGlyph && action.glyph.length > 0
                anchors.centerIn: parent; width: 18; height: 18
                iconName: action.glyph; iconColor: root.ink
            }
            Label { anchors.centerIn: parent; text: action.text; font.pixelSize: 11 }
        }
    }
    Item {
        id: body
        anchors.fill: parent; anchors.margins: root.contentPadding
        enabled: root.open
        Item {
            width: parent.width; height: 28
            Label {
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0,parent.width - 72)
                text: root.reading("location") || "Localização atual"
                color: root.muted; font.pixelSize: 12
            }
            Action {
                objectName: "weatherUnit"
                x: parent.width - 66; width: 32
                text: root.fahrenheit ? "°F" : "°C"
                Accessible.name: root.fahrenheit ? "Mudar para Celsius" : "Mudar para Fahrenheit"
                onClicked: { root.fahrenheit = !root.fahrenheit; root.activated() }
            }
            Action {
                id: refresh
                objectName: "weatherRefresh"
                anchors.right: parent.right
                glyph: "refresh"
                Accessible.name: "Atualizar previsão"
                enabled: !!root.weather && !root.weather.refreshing
                onClicked: { root.weather.refresh(true); root.activated() }
                RotationAnimation {
                    target: refresh.contentItem; property: "rotation"
                    running: root.open && !root.reducedMotion && !!root.weather && root.weather.refreshing
                    from: 0; to: 360; duration: 1200; loops: Animation.Infinite
                    onStopped: refresh.contentItem.rotation = 0
                }
            }
        }
        Item {
            objectName: "weatherSummary"
            y: 36; width: parent.width; height: 64
            VeloraWeatherIcon {
                anchors.verticalCenter: parent.verticalCenter
                width: 50; height: 50
                name: root.reading("iconName") || "partly"
                ink: root.ink
            }
            Label {
                x: 60; width: parent.width < 300 ? 92 : 104; height: 64
                text: root.temperature(root.reading("temperature")) + "°"
                font.pixelSize: 42; font.weight: Font.Light
                verticalAlignment: Text.AlignVCenter
                Accessible.name: "Temperatura atual: " + text
                MouseArea { anchors.fill: parent; onClicked: { root.metric = 0; root.activated() } }
            }
            Column {
                x: parent.width < 300 ? 156 : 168; y: 4
                width: Math.max(0,parent.width - x); spacing: 4
                Label { width: parent.width; text: root.reading("description") || "Clima indisponível"; font.pixelSize: 12 }
                Label { width: parent.width; text: "Sensação " + root.temperature(root.reading("feelsLike")) + "°"; color: root.muted; font.pixelSize: 10 }
                Label { width: parent.width; text: "↑ " + root.temperature(root.reading("maximum")) + "°   ↓ " + root.temperature(root.reading("minimum")) + "°"; font.pixelSize: 10 }
            }
        }
        Row {
            y: 108; width: parent.width; height: 24
            Repeater {
                model: [
                    {icon:"humidity", key:"humidity", unit:"%", label:"Umidade"},
                    {icon:"rain", key:"rain", unit:"%", label:"Chance de chuva"},
                    {icon:"wind", key:"wind", unit:" km/h", label:"Vento"}
                ]
                Item {
                    id: fact
                    required property var modelData
                    width: body.width / 3; height: 24
                    Accessible.role: Accessible.StaticText
                    Accessible.name: modelData.label + ": " + value.text
                    Row {
                        anchors.verticalCenter: parent.verticalCenter; spacing: 6
                        VeloraWeatherIcon { width: 18; height: 18; name: fact.modelData.icon; ink: root.muted }
                        Label { id: value; anchors.verticalCenter: parent.verticalCenter; text: root.measurement(root.reading(fact.modelData.key),fact.modelData.unit) }
                    }
                }
            }
        }
        Row {
            y: 140; height: 28; spacing: 4
            Repeater {
                model: ["temperature","rain","wind"]
                Action {
                    required property int index
                    required property string modelData
                    objectName: "weatherMetric" + index
                    glyph: modelData; weatherGlyph: true; selected: root.metric === index
                    Accessible.name: ["Temperatura por hora","Chuva por hora","Vento por hora"][index]
                    onClicked: { root.metric = index; root.activated() }
                }
            }
        }
        Label {
            x: 104; y: 145; width: Math.max(0,parent.width - x)
            horizontalAlignment: Text.AlignRight; color: root.muted
            text: root.hours.length ? (chart.selectedHour.time || "—") + " · " + chart.label(chart.selectedHour) : ""
        }
        VeloraWeatherChart {
            id: chart
            objectName: "weatherChart"
            y: 172; width: parent.width; height: 74
            hours: root.hours; metric: root.metric; fahrenheit: root.fahrenheit
            presented: root.open; reducedMotion: root.reducedMotion
            ink: root.ink; muted: root.muted; accent: root.ink; uiFont: root.uiFont
            emptyText: root.reading("error") || "Previsão indisponível"
            onInteractionRequested: root.activated()
        }
        Row {
            objectName: "weatherForecast"
            y: 258; width: parent.width; height: 64
            Repeater {
                model: root.days
                Item {
                    id: day
                    required property var modelData
                    required property int index
                    objectName: "weatherDay" + index
                    width: body.width / Math.max(1,root.days.length); height: 64
                    Accessible.role: Accessible.StaticText
                    Accessible.name: root.dayLabel(modelData,index) + ", " + (modelData.desc || "")
                        + ", máxima " + root.temperature(modelData.max) + ", mínima " + root.temperature(modelData.min)
                    Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: root.dayLabel(day.modelData,day.index); color: root.muted; font.pixelSize: 10 }
                    VeloraWeatherIcon { anchors.horizontalCenter: parent.horizontalCenter; y: 18; width: 24; height: 24; name: day.modelData.icon || "partly"; ink: root.ink }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter; y: 48; spacing: 6
                        Label { text: root.temperature(day.modelData.max) + "°"; font.pixelSize: 10 }
                        Label { text: root.temperature(day.modelData.min) + "°"; color: root.muted; font.pixelSize: 10 }
                    }
                }
            }
            Label { visible: root.days.length === 0; text: "Próximos dias indisponíveis"; color: root.muted }
        }
    }
}
