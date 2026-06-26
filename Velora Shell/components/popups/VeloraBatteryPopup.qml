import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var popup: null
    function adaptedNeutral(r, g, b, a, tintAmount) {
        if (!popup || !popup.theme || !popup.pywalStyle)
            return Qt.rgba(r, g, b, a)

        const tint = popup.theme.surfaceSidebar
        const amount = Math.max(0, Math.min(1, tintAmount))
        return Qt.rgba(
            r * (1 - amount) + tint.r * amount,
            g * (1 - amount) + tint.g * amount,
            b * (1 - amount) + tint.b * amount,
            a
        )
    }

    readonly property color neutralInk: Qt.rgba(0.94, 0.95, 0.98, 0.97)
    readonly property color neutralInkSoft: Qt.rgba(0.80, 0.86, 0.95, 0.76)
    readonly property color neutralInkMuted: Qt.rgba(0.66, 0.75, 0.88, 0.52)
    readonly property color neutralCard: adaptedNeutral(0.070, 0.120, 0.205, 0.42, 0.34)
    readonly property color neutralCardHover: adaptedNeutral(0.105, 0.165, 0.270, 0.56, 0.34)
    readonly property color neutralCardActive: adaptedNeutral(0.145, 0.225, 0.355, 0.64, 0.30)
    readonly property color neutralLine: Qt.rgba(0.62, 0.75, 0.96, 0.24)
    readonly property color neutralLineSoft: Qt.rgba(0.62, 0.75, 0.96, 0.115)
    readonly property color neutralAccent: popup && popup.theme ? popup.theme.accentPrimary : Qt.rgba(0.42, 0.70, 1.0, 1)
    readonly property color neutralAccent2: popup && popup.theme ? popup.theme.accentSecondary : Qt.rgba(0.25, 0.58, 1.0, 1)
    readonly property real dialCardHeight: Math.max(380, Math.min(410, root.height - 220))
    readonly property real quickTileHeight: Math.max(84, Math.min(94, (root.height - dialCardHeight - 24) / 2))
    readonly property real introProgress: popup ? popup.lineRevealContentProgress : 1
    readonly property string displayProfile: dragProfile.length > 0
        ? dragProfile
        : (previewProfile.length > 0 ? previewProfile : normalizedProfile())
    property string previewProfile: ""
    property string dragProfile: ""
    property bool ringPressed: false
    property real actionPulse: 0
    property bool dndEnabled: false

    NumberAnimation {
        id: actionPulseAnimation

        target: root
        property: "actionPulse"
        from: 1
        to: 0
        duration: 540
        easing.type: Easing.OutCubic
    }

    Timer {
        id: previewProfileClearTimer

        interval: 900
        repeat: false
        onTriggered: root.previewProfile = ""
    }

    function clamp01(value) {
        return Math.max(0, Math.min(1, value))
    }

    function introStage(delay) {
        const progress = (introProgress - delay) / Math.max(0.01, 1 - delay)
        return clamp01(progress)
    }

    function introScale(delay) {
        const t = introStage(delay)
        return 0.965 + t * 0.035
    }

    function pulseAction() {
        actionPulseAnimation.stop()
        actionPulse = 1
        actionPulseAnimation.restart()
    }

    function modeAngle(profile) {
        const mode = normalizedProfile(profile)
        if (mode === "performance")
            return Math.PI * 0.82
        if (mode === "power-saver")
            return Math.PI * 1.50
        return Math.PI * 0.18
    }

    function modeSeed(profile) {
        const mode = normalizedProfile(profile)
        if (mode === "performance")
            return 0.35
        if (mode === "power-saver")
            return 1.45
        return 2.35
    }

    function modeParticleColor(profile, index) {
        const mode = normalizedProfile(profile)
        const even = index % 2 === 0
        if (mode === "performance")
            return even ? Qt.rgba(0.98, 0.90, 0.72, 1) : Qt.rgba(0.90, 0.84, 0.70, 1)
        if (mode === "power-saver")
            return even ? Qt.rgba(0.74, 0.88, 0.76, 1) : Qt.rgba(0.82, 0.86, 0.74, 1)
        return even ? Qt.rgba(0.84, 0.86, 0.88, 1) : Qt.rgba(0.76, 0.80, 0.82, 1)
    }

    function particleSize(index) {
        return 3 + (index % 4) * 1.7
    }

    function particleOpacity(index) {
        return 0.07 + (index % 5) * 0.018
    }

    function particleX(index, areaWidth) {
        const t = modeSeed(displayProfile) + index * 1.73
        return Math.round(areaWidth * (0.12 + (Math.sin(t) * 0.5 + 0.5) * 0.76))
    }

    function particleY(index, areaHeight) {
        const t = modeSeed(displayProfile) + index * 1.21
        return Math.round(areaHeight * (0.16 + (Math.cos(t) * 0.5 + 0.5) * 0.55))
    }

    function normalizedAngle(angle) {
        const full = Math.PI * 2
        let value = angle % full
        if (value < 0)
            value += full
        return value
    }

    function angularDistance(a, b) {
        const full = Math.PI * 2
        const delta = Math.abs(normalizedAngle(a) - normalizedAngle(b))
        return Math.min(delta, full - delta)
    }

    function profileFromPoint(x, y, width, height) {
        const angle = normalizedAngle(Math.atan2(y - height / 2, x - width / 2))
        const modes = ["performance", "power-saver", "balanced"]
        let bestMode = "balanced"
        let bestDistance = 999

        for (let i = 0; i < modes.length; i += 1) {
            const distance = angularDistance(angle, modeAngle(modes[i]))
            if (distance < bestDistance) {
                bestDistance = distance
                bestMode = modes[i]
            }
        }

        return bestMode
    }

    function rgbaCss(r, g, b, a) {
        return "rgba(" + Math.round(r * 255) + "," + Math.round(g * 255) + "," + Math.round(b * 255) + "," + Math.max(0, Math.min(1, a)) + ")"
    }

    function colorCss(colorValue, opacity) {
        const alpha = Math.max(0, Math.min(1, opacity)) * (colorValue.a === undefined ? 1 : colorValue.a)
        return rgbaCss(colorValue.r, colorValue.g, colorValue.b, alpha)
    }

    function percentValue() {
        return popup && popup.batteryAvailable() ? popup.batteryPercent() : 0
    }

    function percentNumberText() {
        return popup && popup.batteryAvailable() ? String(Math.round(percentValue() * 100)) : "--"
    }

    function normalizedProfile(profile) {
        const raw = String(profile || (popup ? popup.powerProfile : "") || "").toLowerCase()
        if (raw.indexOf("performance") >= 0 || raw.indexOf("desempen") >= 0)
            return "performance"
        if (raw.indexOf("power-saver") >= 0 || raw.indexOf("power saver") >= 0 || raw.indexOf("save") >= 0 || raw.indexOf("econom") >= 0)
            return "power-saver"
        if (raw.indexOf("balanced") >= 0 || raw.indexOf("equil") >= 0)
            return "balanced"
        return "balanced"
    }

    function profileLabel(profile) {
        const mode = normalizedProfile(profile)
        if (mode === "performance")
            return "Performance"
        if (mode === "power-saver")
            return "Economia"
        return "Equilibrado"
    }

    function profileSubtitle(profile) {
        const mode = normalizedProfile(profile)
        if (mode === "performance")
            return "Desempenho"
        if (mode === "power-saver")
            return "Economia"
        return "Equilibrado"
    }

    function applyProfile(profile) {
        if (!popup || !popup.setPowerProfile)
            return
        popup.setPowerProfile(normalizedProfile(profile))
    }

    function commitProfile(profile) {
        const mode = normalizedProfile(profile)
        dragProfile = ""
        previewProfile = mode
        pulseAction()
        applyProfile(mode)
        previewProfileClearTimer.restart()
    }

    function cycleProfile(direction) {
        const order = ["performance", "balanced", "power-saver"]
        const mode = displayProfile
        let index = order.indexOf(mode)
        if (index < 0)
            index = 1

        const step = direction === -1 ? -1 : 1
        commitProfile(order[(index + step + order.length) % order.length])
    }

    function quickCommand(kind) {
        if (!popup)
            return

        pulseAction()
        if (kind === "wifi")
            popup.toggleWifi()
        else if (kind === "bluetooth")
            popup.toggleBluetoothPower()
        else if (kind === "brightness")
            popup.popupRequested("brightness")
        else if (kind === "dnd") {
            dndEnabled = !dndEnabled
            popup.runCommand("makoctl mode -t do-not-disturb >/dev/null 2>&1 || true")
        }
        else if (kind === "dark")
            popup.openSettings("kcm_colors")
        else if (kind === "lock")
            popup.runDetached("loginctl lock-session >/dev/null 2>&1 || hyprlock >/dev/null 2>&1 || swaylock >/dev/null 2>&1 || true")
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        opacity: root.introProgress
        scale: 0.985 + root.introProgress * 0.015
        transformOrigin: Item.Right

        Behavior on opacity { NumberAnimation { duration: root.popup ? root.popup.motionPanelIn : 220; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: root.popup ? root.popup.motionPanelIn : 220; easing.type: Easing.OutCubic } }

        EnergyDialCard {
            Layout.fillWidth: true
            Layout.preferredHeight: root.dialCardHeight
            opacity: root.introStage(0.00)
            scale: root.introScale(0.00) + root.actionPulse * 0.010
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 7
            rowSpacing: 8

            QuickToggleTile {
                Layout.fillWidth: true
                Layout.preferredHeight: root.quickTileHeight
                iconName: "wifi"
                title: "Wi-Fi"
                subtitle: root.popup && root.popup.wifiEnabled ? "Conectado" : "Desligado"
                active: root.popup && root.popup.wifiEnabled
                entryDelay: 0.06
                onClicked: root.quickCommand("wifi")
            }

            QuickToggleTile {
                Layout.fillWidth: true
                Layout.preferredHeight: root.quickTileHeight
                iconName: "bluetooth"
                title: "Bluetooth"
                subtitle: root.popup && root.popup.bluetoothIsPowered ? "Ativo" : "Desligado"
                active: root.popup && root.popup.bluetoothIsPowered
                entryDelay: 0.10
                onClicked: root.quickCommand("bluetooth")
            }

            QuickToggleTile {
                Layout.fillWidth: true
                Layout.preferredHeight: root.quickTileHeight
                iconName: "sun"
                title: "Brilho"
                subtitle: root.popup ? Math.round(root.popup.brightnessPercent * 100) + "%" : "--"
                active: false
                entryDelay: 0.14
                onClicked: root.quickCommand("brightness")
            }

            QuickToggleTile {
                Layout.fillWidth: true
                Layout.preferredHeight: root.quickTileHeight
                iconName: "moon"
                title: "Não perturbe"
                subtitle: root.dndEnabled ? "Ativo" : "Desligado"
                active: root.dndEnabled
                entryDelay: 0.18
                onClicked: root.quickCommand("dnd")
            }

            QuickToggleTile {
                Layout.fillWidth: true
                Layout.preferredHeight: root.quickTileHeight
                iconName: "moon"
                title: "Modo escuro"
                subtitle: root.popup && root.popup.neon ? "Ativo" : "Tema"
                active: root.popup && root.popup.neon
                entryDelay: 0.22
                onClicked: root.quickCommand("dark")
            }

            QuickToggleTile {
                Layout.fillWidth: true
                Layout.preferredHeight: root.quickTileHeight
                iconName: "lock"
                title: "Bloquear"
                subtitle: "Tela"
                active: false
                entryDelay: 0.26
                onClicked: root.quickCommand("lock")
            }
        }

        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
        }
    }

    component EnergyDialCard: Rectangle {
        id: card

        radius: 16
        color: "transparent"
        border.width: 0
        border.color: "transparent"
        antialiasing: true
        clip: false

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            opacity: 0
            gradient: Gradient {
                GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, 0.055) }
                GradientStop { position: 0.38; color: Qt.rgba(1, 1, 1, 0.020) }
                GradientStop { position: 1.00; color: Qt.rgba(0, 0, 0, 0.16) }
            }
        }

        Item {
            id: cardContent

            anchors.fill: parent
            anchors.margins: 10

            Repeater {
                model: 10

                Rectangle {
                    width: root.particleSize(index)
                    height: width
                    radius: width / 2
                    x: root.particleX(index, cardContent.width)
                    y: root.particleY(index, cardContent.height)
                    color: root.modeParticleColor(root.displayProfile, index)
                    opacity: root.introStage(0.08) * root.particleOpacity(index)
                    antialiasing: true

                    Behavior on x { NumberAnimation { duration: root.popup ? root.popup.motionPanelGeometry : 420; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: root.popup ? root.popup.motionPanelGeometry : 420; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: root.popup ? root.popup.motionNormal : 200; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: root.popup ? root.popup.motionPanelGeometry : 420; easing.type: Easing.OutCubic } }
                }
            }

            EnergyRing {
                id: ring

                width: Math.min(parent.width - 12, 258)
                height: width
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -2
                popup: root.popup
                value: root.percentValue()
                profile: root.displayProfile
                pressed: ringInput.pressed
                hovered: ringInput.containsMouse
                pulse: root.actionPulse
            }

            MouseArea {
                id: ringInput

                z: 1
                anchors.fill: ring
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: function(mouse) {
                    root.ringPressed = true
                    root.dragProfile = root.profileFromPoint(mouse.x, mouse.y, width, height)
                    root.pulseAction()
                }
                onPositionChanged: function(mouse) {
                    if (!pressed)
                        return

                    const nextProfile = root.profileFromPoint(mouse.x, mouse.y, width, height)
                    if (nextProfile !== root.dragProfile)
                        root.pulseAction()
                    root.dragProfile = nextProfile
                }
                onReleased: function(mouse) {
                    const nextProfile = root.dragProfile.length > 0
                        ? root.dragProfile
                        : root.profileFromPoint(mouse.x, mouse.y, width, height)
                    root.ringPressed = false
                    root.commitProfile(nextProfile)
                }
                onCanceled: {
                    root.ringPressed = false
                    root.dragProfile = ""
                }
                onWheel: function(wheel) {
                    wheel.accepted = true
                    root.cycleProfile(wheel.angleDelta.y < 0 ? -1 : 1)
                }
            }

            ModeMarker {
                z: 3
                width: 98
                height: 46
                x: Math.round((parent.width - width) / 2)
                y: Math.max(5, ring.y - 20)
                mode: "power-saver"
                active: root.displayProfile === "power-saver"
                onClicked: root.commitProfile("power-saver")
            }

            ModeMarker {
                z: 3
                width: 102
                height: 46
                x: Math.max(2, Math.round(ring.x - 10))
                y: Math.round(ring.y + ring.height * 0.70)
                mode: "performance"
                active: root.displayProfile === "performance"
                onClicked: root.commitProfile("performance")
            }

            ModeMarker {
                z: 3
                width: 102
                height: 46
                x: Math.min(parent.width - width - 2, Math.round(ring.x + ring.width - width + 10))
                y: Math.round(ring.y + ring.height * 0.70)
                mode: "balanced"
                active: root.displayProfile === "balanced"
                onClicked: root.commitProfile("balanced")
            }

            Column {
                id: centerValue

                anchors.centerIn: ring
                spacing: 6
                z: 2

                CenterBatteryIcon {
                    width: 30
                    height: 22
                    anchors.horizontalCenter: parent.horizontalCenter
                    popup: root.popup
                    value: root.percentValue()
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.percentNumberText() + "%"
                    color: root.neutralInk
                    font.family: root.popup ? root.popup.monoFont : "monospace"
                    font.pixelSize: 42
                    font.weight: Font.Light
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Bateria"
                    color: root.neutralInkSoft
                    font.family: root.popup ? root.popup.uiFont : "sans"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }
            }
        }
    }

    component ModeMarker: Item {
        id: marker

        property string mode: "balanced"
        property bool active: false
        property bool hovered: false
        property bool pressed: false
        signal clicked()

        scale: pressed ? 0.965 : (hovered ? 1.030 : 1.0)

        Behavior on scale { NumberAnimation { duration: root.popup ? root.popup.motionHover : 120; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 1
            width: marker.active || marker.hovered ? 32 : 28
            height: width
            radius: width / 2
            color: marker.active
                ? root.colorCss(root.neutralAccent, 0.12)
                : (marker.hovered ? Qt.rgba(1, 1, 1, 0.060) : Qt.rgba(1, 1, 1, 0.0))
            border.width: marker.active || marker.hovered ? 1 : 0
            border.color: marker.active ? root.colorCss(root.neutralAccent, 0.28) : Qt.rgba(1, 1, 1, 0.08)

            Behavior on width { NumberAnimation { duration: root.popup ? root.popup.motionHover : 120; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: root.popup ? root.popup.motionHover : 120; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: root.popup ? root.popup.motionHover : 120; easing.type: root.popup ? root.popup.motionEaseHover : Easing.OutCubic } }
        }

        Column {
            anchors.centerIn: parent
            spacing: 3

            ModeIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 20
                height: 20
                mode: marker.mode
                active: marker.active
                hovered: marker.hovered
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: marker.width - 10
                text: root.profileLabel(marker.mode)
                color: marker.active ? root.neutralInk : root.neutralInkSoft
                font.family: root.popup ? root.popup.uiFont : "sans"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: marker.hovered = true
            onExited: {
                marker.hovered = false
                marker.pressed = false
            }
            onPressed: marker.pressed = true
            onReleased: marker.pressed = false
            onCanceled: marker.pressed = false
            onClicked: marker.clicked()
        }
    }

    component CenterBatteryIcon: Canvas {
        id: batteryIcon

        property var popup: null
        property real value: 0

        onPopupChanged: requestPaint()
        onValueChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            const s = Math.min(width, height)
            const x = (width - s) / 2
            const y = (height - s) / 2
            const clamped = Math.max(0, Math.min(1, value))

            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            if (!popup)
                return

            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.lineWidth = Math.max(2, s * 0.075)
            ctx.strokeStyle = root.rgbaCss(0.90, 0.91, 0.92, 0.92)
            ctx.fillStyle = root.rgbaCss(0.90, 0.91, 0.92, 0.20)

            roundRect(ctx, x + s * 0.12, y + s * 0.30, s * 0.64, s * 0.40, s * 0.06)
            ctx.stroke()

            roundRect(ctx, x + s * 0.79, y + s * 0.40, s * 0.10, s * 0.20, s * 0.035)
            ctx.stroke()

            ctx.fillStyle = root.rgbaCss(0.90, 0.91, 0.92, 0.92)
            roundRect(ctx, x + s * 0.20, y + s * 0.39, Math.max(s * 0.10, s * 0.47 * clamped), s * 0.22, s * 0.035)
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

    component ModeIcon: Canvas {
        id: modeIcon

        property string mode: "balanced"
        property bool active: false
        property bool hovered: false

        onModeChanged: requestPaint()
        onActiveChanged: requestPaint()
        onHoveredChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            const s = Math.min(width, height)
            const x = (width - s) / 2
            const y = (height - s) / 2
            const accent = active ? root.rgbaCss(0.95, 0.97, 1.0, 0.96) : root.rgbaCss(0.76, 0.82, 0.92, 0.78)

            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = accent
            ctx.fillStyle = accent
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.lineWidth = Math.max(1.8, s * 0.075)

            if (mode === "performance") {
                ctx.beginPath()
                ctx.moveTo(x + s * 0.56, y + s * 0.10)
                ctx.lineTo(x + s * 0.28, y + s * 0.54)
                ctx.lineTo(x + s * 0.50, y + s * 0.54)
                ctx.lineTo(x + s * 0.40, y + s * 0.90)
                ctx.lineTo(x + s * 0.74, y + s * 0.42)
                ctx.lineTo(x + s * 0.52, y + s * 0.42)
                ctx.closePath()
                ctx.fill()
            } else if (mode === "power-saver") {
                ctx.beginPath()
                ctx.moveTo(x + s * 0.50, y + s * 0.82)
                ctx.bezierCurveTo(x + s * 0.16, y + s * 0.58, x + s * 0.24, y + s * 0.18, x + s * 0.72, y + s * 0.16)
                ctx.bezierCurveTo(x + s * 0.78, y + s * 0.52, x + s * 0.62, y + s * 0.78, x + s * 0.50, y + s * 0.82)
                ctx.closePath()
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(x + s * 0.50, y + s * 0.82)
                ctx.quadraticCurveTo(x + s * 0.48, y + s * 0.48, x + s * 0.68, y + s * 0.24)
                ctx.stroke()
            } else {
                ctx.beginPath()
                ctx.moveTo(x + s * 0.50, y + s * 0.18)
                ctx.lineTo(x + s * 0.50, y + s * 0.78)
                ctx.moveTo(x + s * 0.30, y + s * 0.34)
                ctx.lineTo(x + s * 0.70, y + s * 0.34)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x + s * 0.30, y + s * 0.34)
                ctx.lineTo(x + s * 0.18, y + s * 0.58)
                ctx.lineTo(x + s * 0.42, y + s * 0.58)
                ctx.closePath()
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x + s * 0.70, y + s * 0.34)
                ctx.lineTo(x + s * 0.58, y + s * 0.58)
                ctx.lineTo(x + s * 0.82, y + s * 0.58)
                ctx.closePath()
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x + s * 0.34, y + s * 0.82)
                ctx.lineTo(x + s * 0.66, y + s * 0.82)
                ctx.stroke()
            }
        }
    }

    component QuickToggleTile: Rectangle {
        id: tile

        property string iconName: "box"
        property string title: ""
        property string subtitle: ""
        property bool active: false
        property bool hovered: false
        property bool pressed: false
        property real entryDelay: 0
        signal clicked()

        radius: 12
        color: active
            ? (hovered ? Qt.rgba(0.175, 0.285, 0.455, 0.70) : root.neutralCardActive)
            : (hovered ? root.neutralCardHover : root.neutralCard)
        border.width: 1
        border.color: active
            ? root.colorCss(root.neutralAccent, 0.36)
            : (hovered ? Qt.rgba(1, 1, 1, 0.13) : root.neutralLineSoft)
        antialiasing: true
        opacity: root.introStage(entryDelay)
        scale: root.introScale(entryDelay) * (pressed ? 0.965 : (hovered ? 1.018 : 1.0))

        Behavior on color { ColorAnimation { duration: root.popup ? root.popup.motionHover : 120; easing.type: root.popup ? root.popup.motionEaseHover : Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: root.popup ? root.popup.motionHover : 120; easing.type: root.popup ? root.popup.motionEaseHover : Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: root.popup ? root.popup.motionNormal : 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: root.popup ? root.popup.motionHover : 120; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Qt.rgba(1, 1, 1, 0.15)
            opacity: tile.pressed ? 0.22 : (tile.hovered ? 0.075 : 0)

            Behavior on opacity { NumberAnimation { duration: root.popup ? root.popup.motionHover : 120; easing.type: Easing.OutCubic } }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 3

            VeloraPopupIcon {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                popup: root.popup
                iconName: tile.iconName
                lineColor: tile.active ? root.neutralInk : root.neutralInkSoft
            }

            Text {
                Layout.fillWidth: true
                text: tile.title
                color: root.neutralInk
                horizontalAlignment: Text.AlignHCenter
                font.family: root.popup ? root.popup.uiFont : "sans"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: tile.subtitle
                color: tile.active ? Qt.rgba(0.86, 0.87, 0.88, 0.82) : root.neutralInkSoft
                horizontalAlignment: Text.AlignHCenter
                font.family: root.popup ? root.popup.uiFont : "sans"
                font.pixelSize: 9
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: tile.hovered = true
            onExited: {
                tile.hovered = false
                tile.pressed = false
            }
            onPressed: tile.pressed = true
            onReleased: tile.pressed = false
            onCanceled: tile.pressed = false
            onClicked: tile.clicked()
        }
    }

    component EnergyRing: Canvas {
        id: gauge

        property var popup: null
        property real value: 0
        property string profile: "balanced"
        property bool pressed: false
        property bool hovered: false
        property real pulse: 0
        property real shownValue: value
        property real modeDotAngle: root.modeAngle(profile)
        readonly property real touchGlow: pressed ? 1 : (hovered ? 0.42 : 0)

        onPopupChanged: requestPaint()
        onValueChanged: requestPaint()
        onProfileChanged: requestPaint()
        onPressedChanged: requestPaint()
        onHoveredChanged: requestPaint()
        onPulseChanged: requestPaint()
        onShownValueChanged: requestPaint()
        onModeDotAngleChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Behavior on modeDotAngle {
            NumberAnimation {
                duration: root.popup ? Math.max(360, root.popup.motionPanelGeometry) : 460
                easing.type: Easing.OutCubic
            }
        }

        onPaint: {
            const ctx = getContext("2d")
            const size = Math.min(width, height)
            const cx = width / 2
            const cy = height / 2
            const ringRadius = size * 0.365
            const orbitRadius = size * 0.455
            const clamped = Math.max(0, Math.min(1, shownValue))
            const start = Math.PI * 0.74
            const end = Math.PI * 2.26
            const visualValue = Math.max(clamped, 0.40)
            const progressEnd = start + (end - start) * visualValue
            const pulsePhase = 1 - Math.max(0, Math.min(1, pulse))
            const shimmer = start + (end - start) * pulsePhase

            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            if (!popup)
                return

            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            ctx.fillStyle = root.rgbaCss(0.020, 0.050, 0.105, 0.23 + touchGlow * 0.06)
            ctx.beginPath()
            ctx.arc(cx, cy, size * (0.420 + pulse * 0.010), 0, Math.PI * 2)
            ctx.fill()

            ctx.fillStyle = root.colorCss(root.neutralAccent, 0.24 + touchGlow * 0.09)
            for (let i = 0; i < 20; i += 1) {
                const a = start + (end - start) * (i / 19)
                ctx.beginPath()
                ctx.arc(cx + Math.cos(a) * orbitRadius, cy + Math.sin(a) * orbitRadius, Math.max(1.1, size * 0.0046), 0, Math.PI * 2)
                ctx.fill()
            }

            ctx.strokeStyle = root.colorCss(root.neutralAccent, 0.18)
            ctx.lineWidth = Math.max(1.4, size * 0.006)
            ctx.beginPath()
            ctx.arc(cx, cy, orbitRadius - size * 0.030, start, end)
            ctx.stroke()

            ctx.strokeStyle = root.rgbaCss(0, 0, 0, 0.16)
            ctx.lineWidth = Math.max(16, size * 0.047)
            ctx.beginPath()
            ctx.arc(cx, cy, ringRadius, start, end)
            ctx.stroke()

            ctx.strokeStyle = root.colorCss(root.neutralAccent, 0.24 + touchGlow * 0.05)
            ctx.lineWidth = Math.max(5, size * 0.016)
            ctx.beginPath()
            ctx.arc(cx, cy, ringRadius, start, end)
            ctx.stroke()

            ctx.strokeStyle = root.colorCss(root.neutralAccent2, 0.22 + touchGlow * 0.14 + pulse * 0.12)
            ctx.lineWidth = Math.max(15, size * 0.044)
            ctx.beginPath()
            ctx.arc(cx, cy, ringRadius, start, progressEnd)
            ctx.stroke()

            ctx.strokeStyle = root.colorCss(root.neutralAccent, 0.98)
            ctx.lineWidth = Math.max(5, size * 0.016)
            ctx.beginPath()
            ctx.arc(cx, cy, ringRadius, start, progressEnd)
            ctx.stroke()

            if (pulse > 0.02 || touchGlow > 0.05) {
                ctx.strokeStyle = root.rgbaCss(1, 1, 1, 0.11 + touchGlow * 0.10 + pulse * 0.12)
                ctx.lineWidth = Math.max(2.2, size * 0.008)
                ctx.beginPath()
                ctx.arc(cx, cy, ringRadius, shimmer, Math.min(end, shimmer + Math.PI * 0.16))
                ctx.stroke()
            }

            if (progressEnd > start + 0.08) {
                ctx.strokeStyle = root.rgbaCss(1, 1, 1, 0.38 + touchGlow * 0.06)
                ctx.lineWidth = Math.max(1.3, size * 0.0045)
                ctx.beginPath()
                ctx.arc(cx, cy, ringRadius - size * 0.037, start + 0.02, progressEnd - 0.04)
                ctx.stroke()
            }

            const batteryKnobX = cx + Math.cos(progressEnd) * ringRadius
            const batteryKnobY = cy + Math.sin(progressEnd) * ringRadius
            ctx.fillStyle = root.colorCss(root.neutralAccent2, 0.34)
            ctx.beginPath()
            ctx.arc(batteryKnobX, batteryKnobY, Math.max(18, size * 0.056), 0, Math.PI * 2)
            ctx.fill()
            ctx.fillStyle = root.colorCss(root.neutralAccent, 1.0)
            ctx.beginPath()
            ctx.arc(batteryKnobX, batteryKnobY, Math.max(12, size * 0.037), 0, Math.PI * 2)
            ctx.fill()
            ctx.strokeStyle = root.rgbaCss(1, 1, 1, 0.96)
            ctx.lineWidth = Math.max(2, size * 0.006)
            ctx.stroke()

            const modeKnobX = cx + Math.cos(modeDotAngle) * ringRadius
            const modeKnobY = cy + Math.sin(modeDotAngle) * ringRadius
            ctx.fillStyle = root.rgbaCss(0.97, 0.97, 0.94, 0.98)
            ctx.beginPath()
            ctx.arc(modeKnobX, modeKnobY, Math.max(4.5, size * (0.014 + touchGlow * 0.002 + pulse * 0.003)), 0, Math.PI * 2)
            ctx.fill()

            ctx.strokeStyle = root.colorCss(root.neutralAccent, 0.22)
            ctx.lineWidth = Math.max(1, size * 0.004)
            ctx.beginPath()
            ctx.arc(cx, cy, size * 0.29, 0, Math.PI * 2)
            ctx.stroke()

            ctx.fillStyle = root.rgbaCss(0.020, 0.045, 0.090, 0.36)
            ctx.beginPath()
            ctx.arc(cx, cy, size * 0.252, 0, Math.PI * 2)
            ctx.fill()

            ctx.strokeStyle = root.colorCss(root.neutralAccent, 0.10)
            ctx.lineWidth = Math.max(1, size * 0.004)
            ctx.beginPath()
            ctx.arc(cx, cy, size * 0.235, 0, Math.PI * 2)
            ctx.stroke()
        }
    }
}
