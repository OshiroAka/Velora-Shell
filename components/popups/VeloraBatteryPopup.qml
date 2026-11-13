import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var popup: null
    readonly property string activeProfile: normalizedProfile(popup ? popup.powerProfile : "")
    readonly property real charge: popup && popup.batteryAvailable() ? popup.batteryPercent() : 0
    readonly property color ink: popup ? popup.ink : "#edf7f1"
    readonly property color inkSoft: popup ? popup.alpha(popup.inkSoft, 0.78) : Qt.rgba(0.80, 0.91, 0.85, 0.78)
    readonly property color accent: popup ? popup.winAccent2 : "#48c99d"
    readonly property color card: popup ? popup.alpha(popup.card, 0.30) : Qt.rgba(1, 1, 1, 0.06)
    readonly property color cardHover: popup ? popup.alpha(popup.card, 0.46) : Qt.rgba(1, 1, 1, 0.11)
    readonly property color line: popup ? popup.alpha(popup.borderSoft, 0.16) : Qt.rgba(1, 1, 1, 0.16)

    function normalizedProfile(value) {
        const raw = String(value || "").toLowerCase()
        if (raw.indexOf("performance") >= 0 || raw.indexOf("desempen") >= 0)
            return "performance"
        if (raw.indexOf("power-saver") >= 0 || raw.indexOf("econom") >= 0 || raw.indexOf("save") >= 0)
            return "power-saver"
        return "balanced"
    }

    function profileLabel(profile) {
        if (profile === "power-saver")
            return "Economia"
        if (profile === "performance")
            return "Desempenho"
        return "Equilibrado"
    }

    function profileHint(profile) {
        if (profile === activeProfile && estimatedTime().length > 0)
            return "Até " + estimatedTime()
        if (profile === "power-saver")
            return "Maior autonomia"
        if (profile === "performance")
            return "Maior potência"
        return "Recomendado"
    }

    function stateLabel() {
        const state = String(popup ? popup.batteryStateText : "").toLowerCase()
        if (state.indexOf("charg") >= 0 || state.indexOf("carreg") >= 0)
            return "Carregando"
        if (state.indexOf("full") >= 0 || state.indexOf("cheia") >= 0)
            return "Carregada"
        if (state.indexOf("discharg") >= 0 || state.indexOf("descarreg") >= 0)
            return "Na bateria"
        return popup && popup.acOnline ? "Conectada à energia" : "Na bateria"
    }

    function estimatedTime() {
        const value = String(popup ? popup.batteryTimeText : "").trim()
        return value.length > 0 ? value : ""
    }

    function healthText() {
        if (!popup || !popup.batteryDevice)
            return "Indisponível"
        const device = popup.batteryDevice
        const value = Number(device.healthPercentage !== undefined ? device.healthPercentage : device.capacity)
        if (!isNaN(value) && value > 0)
            return Math.round(value > 1 ? value : value * 100) + "%"
        return "Indisponível"
    }

    function applyProfile(profile) {
        if (popup && popup.setPowerProfile)
            popup.setPowerProfile(profile)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            spacing: 14

            BatteryIcon {
                Layout.preferredWidth: 62
                Layout.preferredHeight: 40
                value: root.charge
                color: root.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: popup && popup.batteryAvailable() ? Math.round(root.charge * 100) + "%" : "--"
                    color: root.ink
                    font.family: popup ? popup.uiFont : "sans"
                    font.pixelSize: 29
                    font.weight: Font.Light
                }

                Text {
                    text: root.stateLabel()
                    color: root.inkSoft
                    font.family: popup ? popup.uiFont : "sans"
                    font.pixelSize: 12
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 9
            radius: height / 2
            color: root.card

            Rectangle {
                width: Math.max(parent.height, parent.width * root.charge)
                height: parent.height
                radius: height / 2
                color: root.accent

                Behavior on width { NumberAnimation { duration: popup ? popup.motionNormal : 200; easing.type: Easing.OutCubic } }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 132
            spacing: 8

            Repeater {
                model: ["power-saver", "balanced", "performance"]

                EnergyModeCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    mode: modelData
                    active: root.activeProfile === mode
                    label: root.profileLabel(mode)
                    hint: root.profileHint(mode)
                    onClicked: root.applyProfile(mode)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.line
        }

        InfoRow {
            Layout.fillWidth: true
            iconName: "clock"
            label: "Tempo restante estimado"
            value: root.estimatedTime().length > 0 ? root.estimatedTime() : "Indisponível"
        }

        InfoRow {
            Layout.fillWidth: true
            iconName: "heart"
            label: "Saúde da bateria"
            value: root.healthText()
        }

        Item { Layout.fillHeight: true }
    }

    component EnergyModeCard: Rectangle {
        id: tile

        property string mode: "balanced"
        property string label: ""
        property string hint: ""
        property bool active: false
        readonly property bool hovered: mouse.containsMouse
        signal clicked()

        radius: 15
        color: active ? root.popup.alpha(root.accent, hovered ? 0.26 : 0.18) : (hovered ? root.cardHover : root.card)
        border.width: 1
        border.color: active ? root.popup.alpha(root.accent, 0.72) : root.line
        antialiasing: true

        Behavior on color { ColorAnimation { duration: root.popup ? root.popup.motionHover : 120; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: root.popup ? root.popup.motionHover : 120; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 5

            ModeIcon {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                mode: tile.mode
                color: tile.active ? root.accent : root.inkSoft
            }

            Text {
                Layout.fillWidth: true
                text: tile.label
                color: root.ink
                font.family: root.popup ? root.popup.uiFont : "sans"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                text: tile.hint
                color: root.inkSoft
                font.family: root.popup ? root.popup.uiFont : "sans"
                font.pixelSize: 9
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }
    }

    component InfoRow: RowLayout {
        property string iconName: "clock"
        property string label: ""
        property string value: ""
        spacing: 10
        Layout.preferredHeight: 34

        SimpleIcon {
            Layout.preferredWidth: 19
            Layout.preferredHeight: 19
            iconName: parent.iconName
            color: root.inkSoft
        }

        Text {
            Layout.fillWidth: true
            text: parent.label
            color: root.ink
            font.family: root.popup ? root.popup.uiFont : "sans"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            text: parent.value
            color: root.inkSoft
            font.family: root.popup ? root.popup.uiFont : "sans"
            font.pixelSize: 11
            elide: Text.ElideLeft
        }
    }

    component BatteryIcon: Canvas {
        property real value: 0
        property color color: "#48c99d"
        onValueChanged: requestPaint()
        onColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            const bodyH = height * 0.72
            const bodyY = (height - bodyH) / 2
            const bodyW = width * 0.82
            const radius = Math.max(3, bodyH * 0.13)
            ctx.reset()
            ctx.strokeStyle = "rgba(238,247,241,0.92)"
            ctx.lineWidth = Math.max(2, height * 0.075)
            ctx.beginPath()
            ctx.roundedRect(1, bodyY, bodyW, bodyH, radius, radius)
            ctx.stroke()
            ctx.fillStyle = color
            ctx.beginPath()
            ctx.roundedRect(4, bodyY + 3, Math.max(3, (bodyW - 7) * Math.max(0, Math.min(1, value))), bodyH - 6, Math.max(2, radius - 1), Math.max(2, radius - 1))
            ctx.fill()
            ctx.fillStyle = "rgba(238,247,241,0.92)"
            ctx.beginPath()
            ctx.roundedRect(bodyW + 2, bodyY + bodyH * 0.28, width - bodyW - 2, bodyH * 0.44, 2, 2)
            ctx.fill()
        }
    }

    component ModeIcon: Canvas {
        property string mode: "balanced"
        property color color: "#dcebe3"
        onModeChanged: requestPaint()
        onColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.strokeStyle = color
            ctx.lineWidth = 1.8
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            if (mode === "power-saver") {
                ctx.beginPath(); ctx.moveTo(width * .5, 2); ctx.bezierCurveTo(width * .20, height * .35, width * .38, height * .68, width * .5, height - 2); ctx.bezierCurveTo(width * .78, height * .62, width * .88, height * .32, width * .5, 2); ctx.stroke()
            } else if (mode === "performance") {
                ctx.beginPath(); ctx.moveTo(3, height - 4); ctx.lineTo(width - 3, 3); ctx.lineTo(width * .67, height * .58); ctx.lineTo(width - 7, height - 3); ctx.lineTo(width * .40, height * .76); ctx.closePath(); ctx.stroke()
            } else {
                ctx.beginPath(); ctx.moveTo(width * .5, 2); ctx.lineTo(width * .5, height - 2); ctx.moveTo(3, height * .36); ctx.lineTo(width - 3, height * .36); ctx.moveTo(4, height - 3); ctx.lineTo(width - 4, height - 3); ctx.stroke()
            }
        }
    }

    component SimpleIcon: Canvas {
        property string iconName: "clock"
        property color color: "#dcebe3"
        onIconNameChanged: requestPaint()
        onColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            const s = Math.min(width, height)
            const x = (width - s) / 2
            const y = (height - s) / 2
            ctx.reset(); ctx.strokeStyle = color; ctx.lineWidth = 1.65; ctx.lineCap = "round"; ctx.lineJoin = "round"
            if (iconName === "heart") {
                ctx.beginPath(); ctx.moveTo(x + s*.5, y + s*.82); ctx.bezierCurveTo(x + s*.12, y + s*.58, x + s*.10, y + s*.22, x + s*.30, y + s*.18); ctx.bezierCurveTo(x + s*.43, y + s*.15, x + s*.5, y + s*.30, x + s*.5, y + s*.30); ctx.bezierCurveTo(x + s*.58, y + s*.15, x + s*.72, y + s*.15, x + s*.84, y + s*.28); ctx.bezierCurveTo(x + s*.98, y + s*.48, x + s*.73, y + s*.70, x + s*.5, y + s*.82); ctx.stroke()
            } else {
                ctx.beginPath(); ctx.arc(x + s*.5, y + s*.5, s*.34, 0, Math.PI*2); ctx.moveTo(x + s*.5, y + s*.5); ctx.lineTo(x + s*.5, y + s*.29); ctx.moveTo(x + s*.5, y + s*.5); ctx.lineTo(x + s*.66, y + s*.59); ctx.stroke()
            }
        }
    }
}
