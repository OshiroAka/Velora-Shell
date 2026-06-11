import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var popup: null

    function percentValue() {
        return popup && popup.batteryAvailable() ? popup.batteryPercent() : 0
    }

    function percentText() {
        return popup ? popup.batteryText() : "N/A"
    }

    function stateText() {
        if (!popup)
            return ""
        if (!popup.batteryAvailable())
            return popup.acOnline ? "AC conectado" : "Bateria indisponivel"
        const time = popup.batteryTimeText && popup.batteryTimeText.length > 0 ? " / " + popup.batteryTimeText : ""
        return popup.batteryStateText + time
    }

    function profileText() {
        if (!popup || !popup.powerProfile || popup.powerProfile === "unknown")
            return "Perfil automatico"
        return popup.powerProfile
    }

    function charging() {
        return popup && popup.batteryStateText.toLowerCase().indexOf("charg") >= 0
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: "Energia"
                    color: root.popup ? root.popup.ink : "white"
                    font.family: root.popup ? root.popup.uiFont : "sans"
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.stateText()
                    color: root.popup ? root.popup.inkSoft : Qt.rgba(1, 1, 1, 0.62)
                    font.family: root.popup ? root.popup.uiFont : "sans"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }

            StatusPill {
                label: root.popup && root.popup.acOnline ? "AC" : "BAT"
                active: root.popup && root.popup.acOnline
            }
        }

        VeloraPopupCard {
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            popup: root.popup
            color: root.popup ? root.popup.alpha(root.popup.winCardHover, 0.46) : Qt.rgba(1, 1, 1, 0.08)
            border.color: root.popup ? root.popup.alpha(root.popup.winAccent, 0.28) : Qt.rgba(1, 1, 1, 0.14)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                BatteryGauge {
                    Layout.preferredWidth: 112
                    Layout.preferredHeight: 112
                    popup: root.popup
                    value: root.percentValue()
                    charging: root.charging()
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: root.percentText()
                        color: root.popup ? root.popup.ink : "white"
                        font.family: root.popup ? root.popup.monoFont : "monospace"
                        font.pixelSize: 42
                        font.weight: Font.Light
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.profileText()
                        color: root.popup ? root.popup.winAccent2 : Qt.rgba(1, 1, 1, 0.72)
                        font.family: root.popup ? root.popup.uiFont : "sans"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        radius: 4
                        color: root.popup ? root.popup.alpha(root.popup.winCard, 0.68) : Qt.rgba(1, 1, 1, 0.12)
                        clip: true

                        Rectangle {
                            width: Math.max(parent.height, parent.width * root.percentValue())
                            height: parent.height
                            radius: parent.radius
                            color: root.popup ? root.popup.winAccent2 : "white"
                        }
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 10
            rowSpacing: 10

            MetricCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 62
                label: "Estado"
                value: root.popup && root.popup.batteryAvailable() ? root.popup.batteryStateText : "N/A"
            }

            MetricCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 62
                label: "Tempo"
                value: root.popup && root.popup.batteryTimeText.length > 0 ? root.popup.batteryTimeText : "--"
            }

            MetricCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 62
                label: "Perfil"
                value: root.profileText()
            }

            MetricCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 62
                label: "Fonte"
                value: root.popup && root.popup.acOnline ? "Conectado" : "Bateria"
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 9
            rowSpacing: 9

            Repeater {
                model: [
                    ["battery", root.popup && root.popup.powerProfile === "performance" ? "Perf." : "Equil."],
                    ["moon", "Noite"],
                    ["sun", "Tela"],
                    ["settings", "Sistema"]
                ]

                VeloraPopupIconTile {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 76
                    popup: root.popup
                    iconName: modelData[0]
                    label: modelData[1]
                    active: root.popup ? (index === 0 ? root.popup.powerProfile === "performance" : (index === 1 ? root.popup.nightLightEnabled : false)) : false
                    onClicked: {
                        if (!root.popup)
                            return
                        if (index === 0)
                            root.popup.togglePowerSaver()
                        else if (index === 1)
                            root.popup.toggleNightLight()
                        else if (index === 2)
                            root.popup.openDisplaySettings()
                        else
                            root.popup.openSettings("powerdevilprofilesconfig")
                    }
                }
            }
        }
    }

    component StatusPill: Rectangle {
        property string label: ""
        property bool active: false

        Layout.preferredWidth: 58
        Layout.preferredHeight: 26
        radius: 13
        color: root.popup ? root.popup.alpha(active ? root.popup.winAccent : root.popup.winCardHover, active ? 0.34 : 0.48) : Qt.rgba(1, 1, 1, 0.10)
        border.width: 1
        border.color: root.popup ? root.popup.alpha(active ? root.popup.winAccent2 : root.popup.winAccent, active ? 0.44 : 0.18) : Qt.rgba(1, 1, 1, 0.14)

        Text {
            anchors.centerIn: parent
            text: parent.label
            color: root.popup ? (parent.active ? root.popup.winAccent2 : root.popup.inkSoft) : "white"
            font.family: root.popup ? root.popup.uiFont : "sans"
            font.pixelSize: 10
            font.weight: Font.Bold
        }
    }

    component MetricCard: VeloraPopupCard {
        id: metric

        property string label: ""
        property string value: ""

        popup: root.popup
        color: root.popup ? root.popup.alpha(root.popup.winCard, 0.62) : Qt.rgba(1, 1, 1, 0.08)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 3

            Text {
                Layout.fillWidth: true
                text: metric.label
                color: root.popup ? root.popup.inkSoft : Qt.rgba(1, 1, 1, 0.62)
                font.family: root.popup ? root.popup.uiFont : "sans"
                font.pixelSize: 9
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: metric.value
                color: root.popup ? root.popup.ink : "white"
                font.family: root.popup ? root.popup.uiFont : "sans"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }
    }

    component BatteryGauge: Canvas {
        id: gauge

        property var popup: null
        property real value: 0
        property bool charging: false

        onPopupChanged: requestPaint()
        onValueChanged: requestPaint()
        onChargingChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            const size = Math.min(width, height)
            const cx = width / 2
            const cy = height / 2
            const radius = size * 0.38
            const start = Math.PI * 0.72
            const end = Math.PI * 2.28
            const clamped = Math.max(0, Math.min(1, value))

            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            if (!popup)
                return

            ctx.lineCap = "round"
            ctx.lineWidth = Math.max(6, size * 0.075)
            ctx.strokeStyle = popup.alpha(popup.winCard, 0.82)
            ctx.beginPath()
            ctx.arc(cx, cy, radius, start, end)
            ctx.stroke()

            ctx.strokeStyle = charging ? popup.winAccent2 : popup.winAccent
            ctx.beginPath()
            ctx.arc(cx, cy, radius, start, start + (end - start) * clamped)
            ctx.stroke()

            ctx.fillStyle = popup.alpha(popup.winCardHover, 0.52)
            ctx.beginPath()
            ctx.arc(cx, cy, radius * 0.56, 0, Math.PI * 2)
            ctx.fill()

            ctx.strokeStyle = popup.alpha(popup.winAccent2, charging ? 0.82 : 0.42)
            ctx.lineWidth = Math.max(1.4, size * 0.018)
            roundRect(ctx, cx - radius * 0.22, cy - radius * 0.30, radius * 0.44, radius * 0.62, radius * 0.08)
            ctx.stroke()
            roundRect(ctx, cx - radius * 0.08, cy - radius * 0.42, radius * 0.16, radius * 0.08, radius * 0.03)
            ctx.stroke()
            ctx.fillStyle = popup.alpha(popup.winAccent2, 0.78)
            roundRect(ctx, cx - radius * 0.15, cy + radius * (0.20 - clamped * 0.42), radius * 0.30, radius * 0.34 * Math.max(0.12, clamped), radius * 0.04)
            ctx.fill()
        }

        function roundRect(ctx, x, y, w, h, r) {
            ctx.beginPath()
            ctx.moveTo(x + r, y)
            ctx.lineTo(x + w - r, y)
            ctx.quadraticCurveTo(x + w, y, x + w, y + r)
            ctx.lineTo(x + w, y + h - r)
            ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h)
            ctx.lineTo(x + r, y + h)
            ctx.quadraticCurveTo(x, y + h, x, y + h - r)
            ctx.lineTo(x, y + r)
            ctx.quadraticCurveTo(x, y, x + r, y)
            ctx.closePath()
        }
    }
}
