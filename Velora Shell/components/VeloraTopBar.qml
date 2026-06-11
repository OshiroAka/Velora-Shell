import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower

Item {
    id: root

    property var theme: null
    property alias maskItem: surface
    property string clockText: Qt.formatDateTime(new Date(), "HH:mm")
    property string dateText: formatLocalizedDate(new Date())
    property var batteryDevice: null
    property int volume: 70
    property bool muted: false
    property int notificationCount: 0
    property string activePopupType: ""
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string uiFont: theme ? theme.uiFont : "Noto Sans CJK JP"
    readonly property string monoFont: theme ? theme.monoFont : "JetBrainsMono Nerd Font"
    readonly property bool pywalStyle: theme && theme.themeId === "pywal16"
    readonly property bool darkSoft: theme && theme.themeMode === "dark"
    readonly property real glassAlpha: theme ? Math.max(theme.minOpacityForRole("sidebar"), Math.min(theme.barOpacity + 0.02, 0.92)) : 0.84
    readonly property color glass: theme ? theme.withAlpha(theme.surfaceSidebar, glassAlpha) : Qt.rgba(1, 0.97, 0.995, 0.84)
    readonly property color card: theme ? theme.withAlpha(theme.surfaceCard, Math.max(0.38, Math.min(theme.surfaceCard.a + 0.08, 0.82))) : Qt.rgba(1, 1, 1, 0.62)
    readonly property color ink: theme ? theme.textPrimary : "#4d3f63"
    readonly property color inkSoft: theme ? theme.textSecondary : "#8d7ca3"
    readonly property color mutedInk: theme ? theme.textMuted : "#b7a9c7"
    readonly property color accent: theme ? (pywalStyle ? theme.accentSecondary : theme.accentPrimary) : "#e8a6c8"
    readonly property color accent2: theme ? (pywalStyle ? theme.accentPrimary : theme.accentSecondary) : "#c894f2"
    readonly property int motionHover: theme ? theme.motionHover : 120
    readonly property int motionNormal: theme ? theme.motionNormal : 200

    signal searchRequested(real centerX)
    signal themeRequested(real centerX)
    signal settingsRequested(real centerX)
    signal quickPopupRequested(string popupType, real centerX)
    signal quickPopupHovered(string popupType, real centerX)
    signal quickPopupHoverEnded(string popupType)

    implicitHeight: 64
    clip: false

    function alpha(colorValue, opacity) {
        return root.theme ? root.theme.alpha(colorValue, opacity) : Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacity)
    }

    function fontGlowEnabled() {
        return root.theme && root.theme.textGlow.a > 0.001
    }

    function formatLocalizedDate(date) {
        const lang = root.theme ? root.theme.language : "ja"
        if (lang === "en")
            return Qt.formatDateTime(date, "MMM d")
        if (lang === "pt-BR") {
            const weekdays = ["dom", "seg", "ter", "qua", "qui", "sex", "sab"]
            return date.getDate() + "/" + (date.getMonth() + 1) + " (" + weekdays[date.getDay()] + ")"
        }

        const weekdaysJa = ["日", "月", "火", "水", "木", "金", "土"]
        return (date.getMonth() + 1) + "月" + date.getDate() + "日 (" + weekdaysJa[date.getDay()] + ")"
    }

    function updateClockText() {
        const now = new Date()
        clockText = Qt.formatDateTime(now, "HH:mm")
        dateText = formatLocalizedDate(now)
        clockMinuteTimer.interval = Math.max(1000, 60050 - now.getSeconds() * 1000 - now.getMilliseconds())
        clockMinuteTimer.restart()
    }

    function pickBattery() {
        batteryDevice = null
        for (let i = 0; i < UPower.devices.count; i += 1) {
            const dev = UPower.devices.get(i)
            if (dev && dev.isLaptopBattery) {
                batteryDevice = dev
                return
            }
        }
    }

    function batteryLevel() {
        if (!batteryDevice || !batteryDevice.ready)
            return 0

        const value = Number(batteryDevice.percentage)
        if (isNaN(value))
            return 0
        return Math.max(0, Math.min(1, value > 1 ? value / 100 : value))
    }

    function runCommand(command) {
        if (commandRunner.running)
            commandRunner.running = false
        commandRunner.command = ["bash", "-lc", command]
        commandRunner.running = true
    }

    function launchFiles() {
        runCommand("if command -v dolphin >/dev/null 2>&1; then dolphin >/dev/null 2>&1 & elif command -v thunar >/dev/null 2>&1; then thunar >/dev/null 2>&1 & elif command -v nautilus >/dev/null 2>&1; then nautilus >/dev/null 2>&1 & fi")
    }

    function launchBrowser() {
        runCommand("if command -v zen-browser >/dev/null 2>&1; then zen-browser >/dev/null 2>&1 & elif command -v firefox >/dev/null 2>&1; then firefox >/dev/null 2>&1 & fi")
    }

    function launchDiscord() {
        runCommand("if command -v discord >/dev/null 2>&1; then discord >/dev/null 2>&1 & elif command -v vesktop >/dev/null 2>&1; then vesktop >/dev/null 2>&1 & elif command -v webcord >/dev/null 2>&1; then webcord >/dev/null 2>&1 & fi")
    }

    component FontGlowEffect: MultiEffect {
        shadowEnabled: true
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        shadowColor: root.theme ? root.theme.textGlow : Qt.rgba(0, 0, 0, 0)
        shadowOpacity: root.theme ? Math.min(1, 0.28 + root.theme.textGlowLevel * 0.42) : 0
        shadowBlur: root.theme ? Math.min(1, 0.20 + root.theme.textGlowLevel * 0.46) : 0
        blurMax: 16
        autoPaddingEnabled: true
    }

    DropShadow {
        anchors.fill: surface
        horizontalOffset: 0
        verticalOffset: 7
        radius: 22
        samples: 41
        color: root.theme ? root.alpha(root.theme.shadowColor, root.darkSoft ? 0.34 : 0.22) : Qt.rgba(0.40, 0.25, 0.55, 0.14)
        source: surface
        transparentBorder: true
    }

    Rectangle {
        id: surface

        anchors.fill: parent
        radius: 16
        color: root.glass
        border.width: 1
        border.color: root.theme ? root.alpha(root.theme.borderSoft, root.darkSoft ? 0.16 : 0.34) : Qt.rgba(1, 1, 1, 0.36)
        antialiasing: true

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            color: "transparent"
            border.width: 1
            border.color: root.theme ? root.alpha(root.theme.activeText, root.darkSoft ? 0.05 : 0.18) : Qt.rgba(1, 1, 1, 0.18)
            antialiasing: true
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.topMargin: 9
            anchors.bottomMargin: 9
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 232
                Layout.fillHeight: true
                radius: 10
                color: root.alpha(root.card, root.darkSoft ? 0.42 : 0.50)
                border.width: 1
                border.color: root.theme ? root.alpha(root.theme.borderSoft, root.darkSoft ? 0.10 : 0.24) : Qt.rgba(1, 1, 1, 0.22)
                antialiasing: true

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 9
                    anchors.rightMargin: 12
                    spacing: 10

                    Item {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: root.alpha(root.accent, 0.18)
                            border.width: 1
                            border.color: root.alpha(root.accent, 0.42)
                            antialiasing: true
                        }

                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: root.homeDir + "/.face"
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: 30
                                    height: 30
                                    radius: 15
                                }
                            }
                        }
                    }

                    Text {
                        text: root.clockText
                        color: root.ink
                        font.family: root.uiFont
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        layer.enabled: root.fontGlowEnabled()
                        layer.effect: FontGlowEffect {}
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.dateText
                        color: root.inkSoft
                        font.family: root.uiFont
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        layer.enabled: root.fontGlowEnabled()
                        layer.effect: FontGlowEffect {}
                    }
                }
            }

            TopButton {
                Layout.preferredWidth: 164
                Layout.fillHeight: true
                iconName: "search"
                label: root.theme && root.theme.language === "pt-BR" ? "Buscar" : (root.theme && root.theme.language === "en" ? "Search" : "検索")
                hoverPopupType: "search"
                selected: root.activePopupType === "search"
                onClicked: function(centerX) { root.searchRequested(centerX) }
            }

            Rectangle {
                Layout.preferredWidth: 236
                Layout.fillHeight: true
                radius: 10
                color: root.alpha(root.card, root.darkSoft ? 0.34 : 0.42)
                border.width: 1
                border.color: root.theme ? root.alpha(root.theme.borderSoft, root.darkSoft ? 0.08 : 0.22) : Qt.rgba(1, 1, 1, 0.22)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    spacing: 7

                    Repeater {
                        model: 4
                        WorkspaceButton {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            number: index + 1
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 200
                Layout.fillHeight: true
                radius: 10
                color: root.alpha(root.card, root.darkSoft ? 0.34 : 0.42)
                border.width: 1
                border.color: root.theme ? root.alpha(root.theme.borderSoft, root.darkSoft ? 0.08 : 0.22) : Qt.rgba(1, 1, 1, 0.22)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 9

                    TopIconButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        iconName: "files"
                        onClicked: root.launchFiles()
                    }

                    TopIconButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        iconName: "theme"
                        onClicked: function(centerX) { root.themeRequested(centerX) }
                    }

                    TopIconButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        iconName: "discord"
                        onClicked: root.launchDiscord()
                    }

                    TopIconButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        iconName: "browser"
                        onClicked: root.launchBrowser()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.minimumWidth: 306
                Layout.fillHeight: true
                radius: 10
                color: root.alpha(root.card, root.darkSoft ? 0.28 : 0.34)
                border.width: 1
                border.color: root.theme ? root.alpha(root.theme.borderSoft, root.darkSoft ? 0.07 : 0.18) : Qt.rgba(1, 1, 1, 0.18)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 11
                    anchors.rightMargin: 11
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    spacing: 12

                    TopIconButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        iconName: "volume"
                        badgeText: root.muted ? "0" : ""
                        hoverPopupType: "volume"
                        selected: root.activePopupType === "volume"
                        onClicked: function(centerX) { root.quickPopupRequested("volume", centerX) }
                    }

                    TopIconButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        iconName: "wifi"
                        hoverPopupType: "wifi"
                        selected: root.activePopupType === "wifi"
                        onClicked: function(centerX) { root.quickPopupRequested("wifi", centerX) }
                    }

                    TopIconButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        iconName: "brightness"
                        hoverPopupType: "brightness"
                        selected: root.activePopupType === "brightness"
                        onClicked: function(centerX) { root.quickPopupRequested("brightness", centerX) }
                    }

                    TopIconButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        iconName: "notifications"
                        badgeText: root.notificationCount > 0 ? String(Math.min(99, root.notificationCount)) : ""
                        hoverPopupType: "notifications"
                        selected: root.activePopupType === "notifications"
                        onClicked: function(centerX) { root.quickPopupRequested("notifications", centerX) }
                    }

                    TopIconButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        iconName: "bluetooth"
                        hoverPopupType: "bluetooth"
                        selected: root.activePopupType === "bluetooth"
                        onClicked: function(centerX) { root.quickPopupRequested("bluetooth", centerX) }
                    }

                    TopIconButton {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        iconName: "battery"
                        progress: root.batteryLevel()
                        onClicked: function(centerX) { root.settingsRequested(centerX) }
                    }
                }
            }
        }
    }

    Timer {
        id: clockMinuteTimer
        interval: 60000
        running: false
        repeat: false
        onTriggered: root.updateClockText()
    }

    Timer {
        interval: 15000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.pickBattery()
            if (!volumeQuery.running)
                volumeQuery.running = true
            if (!notificationCountQuery.running)
                notificationCountQuery.running = true
        }
    }

    Component.onCompleted: root.updateClockText()

    Process {
        id: commandRunner

        running: false
        command: ["bash", "-lc", "true"]
        onExited: running = false
    }

    Process {
        id: volumeQuery

        running: false
        command: ["bash", "-lc", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo 'Volume: 0.70'"]

        stdout: SplitParser {
            onRead: function(data) {
                const text = String(data || "").trim()
                const match = text.match(/[0-9]+\\.?[0-9]*/)
                root.muted = text.indexOf("MUTED") >= 0
                if (match)
                    root.volume = Math.max(0, Math.min(100, Math.round(parseFloat(match[0]) * 100)))
            }
        }

        onExited: running = false
    }

    Process {
        id: notificationCountQuery

        running: false
        command: ["bash", "-lc", "if command -v makoctl >/dev/null 2>&1; then makoctl list -j 2>/dev/null | python3 -c 'import sys,json; raw=sys.stdin.read().strip() or \"[]\"; print(len(json.loads(raw)))' 2>/dev/null || printf '0\\n'; else printf '0\\n'; fi"]

        stdout: SplitParser {
            onRead: function(data) {
                const value = parseInt(String(data || "").trim())
                root.notificationCount = isNaN(value) ? 0 : Math.max(0, value)
            }
        }

        onExited: running = false
    }

    component TopButton: Rectangle {
        id: button

        property string iconName: "search"
        property string label: ""
        property bool selected: false
        property string hoverPopupType: ""
        signal clicked(real centerX)

        radius: 10
        color: selected ? root.alpha(root.accent, 0.22) : (mouse.containsMouse ? root.alpha(root.accent, 0.14) : root.alpha(root.card, root.darkSoft ? 0.30 : 0.42))
        border.width: 1
        border.color: selected ? root.alpha(root.accent, 0.58) : (mouse.containsMouse ? root.alpha(root.accent, 0.42) : root.alpha(root.inkSoft, 0.10))
        scale: mouse.pressed ? 0.98 : (mouse.containsMouse ? 1.012 : 1)
        antialiasing: true

        function centerX() {
            return button.mapToItem(root, button.width / 2, button.height / 2).x
        }

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 15
            anchors.rightMargin: 12
            spacing: 8

            IconCanvas {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                iconName: button.iconName
            }

            Text {
                Layout.fillWidth: true
                text: button.label
                color: root.ink
                font.family: root.uiFont
                font.pixelSize: 12
                font.weight: Font.Bold
                elide: Text.ElideRight
                layer.enabled: root.fontGlowEnabled()
                layer.effect: FontGlowEffect {}
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                if (button.hoverPopupType.length > 0)
                    root.quickPopupHovered(button.hoverPopupType, button.centerX())
            }
            onExited: {
                if (button.hoverPopupType.length > 0)
                    root.quickPopupHoverEnded(button.hoverPopupType)
            }
            onClicked: button.clicked(button.centerX())
        }
    }

    component WorkspaceButton: Rectangle {
        id: button

        property int number: 1
        readonly property bool active: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === number

        radius: 8
        color: active ? root.alpha(root.accent, 0.72) : (mouse.containsMouse ? root.alpha(root.accent, 0.18) : root.alpha(root.card, root.darkSoft ? 0.30 : 0.54))
        border.width: 1
        border.color: active ? root.alpha(root.accent, 0.74) : root.alpha(root.inkSoft, 0.10)
        scale: mouse.pressed ? 0.96 : (mouse.containsMouse ? 1.035 : 1)
        antialiasing: true

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }

        Text {
            anchors.centerIn: parent
            text: String(button.number)
            color: button.active ? (root.theme ? root.theme.buttonPrimaryText : "white") : root.ink
            font.family: root.uiFont
            font.pixelSize: 12
            font.weight: Font.Bold
            layer.enabled: root.fontGlowEnabled()
            layer.effect: FontGlowEffect {}
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Hyprland.dispatch("workspace " + button.number)
        }
    }

    component TopIconButton: Rectangle {
        id: button

        property string iconName: "files"
        property string badgeText: ""
        property real progress: -1
        property bool selected: false
        property string hoverPopupType: ""
        signal clicked(real centerX)

        radius: 9
        color: selected ? root.alpha(root.accent, 0.24) : (mouse.containsMouse ? root.alpha(root.accent, 0.16) : root.alpha(root.card, root.darkSoft ? 0.26 : 0.48))
        border.width: 1
        border.color: selected ? root.alpha(root.accent, 0.62) : (mouse.containsMouse ? root.alpha(root.accent, 0.44) : root.alpha(root.inkSoft, 0.10))
        scale: mouse.pressed ? 0.95 : (mouse.containsMouse ? 1.04 : 1)
        antialiasing: true

        function centerX() {
            return button.mapToItem(root, button.width / 2, button.height / 2).x
        }

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }

        IconCanvas {
            anchors.centerIn: parent
            width: Math.min(22, parent.width - 8)
            height: width
            iconName: button.iconName
            progress: button.progress
        }

        Rectangle {
            visible: button.badgeText.length > 0
            x: parent.width - width + 2
            y: -5
            width: Math.max(16, badgeLabel.implicitWidth + 8)
            height: 16
            radius: 8
            color: root.alpha(root.accent, 0.84)
            border.width: 1
            border.color: root.alpha(root.theme ? root.theme.activeText : Qt.rgba(1, 1, 1, 1), 0.50)

            Text {
                id: badgeLabel
                anchors.centerIn: parent
                text: button.badgeText
                color: root.theme ? root.theme.buttonPrimaryText : "white"
                font.family: root.uiFont
                font.pixelSize: 9
                font.weight: Font.Bold
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                if (button.hoverPopupType.length > 0)
                    root.quickPopupHovered(button.hoverPopupType, button.centerX())
            }
            onExited: {
                if (button.hoverPopupType.length > 0)
                    root.quickPopupHoverEnded(button.hoverPopupType)
            }
            onClicked: button.clicked(button.centerX())
        }
    }

    component IconCanvas: Canvas {
        id: canvas

        property string iconName: "search"
        property real progress: -1

        antialiasing: true
        onIconNameChanged: requestPaint()
        onProgressChanged: requestPaint()

        function roundedRect(ctx, x, y, w, h, r) {
            const radius = Math.min(r, w / 2, h / 2)
            ctx.moveTo(x + radius, y)
            ctx.lineTo(x + w - radius, y)
            ctx.quadraticCurveTo(x + w, y, x + w, y + radius)
            ctx.lineTo(x + w, y + h - radius)
            ctx.quadraticCurveTo(x + w, y + h, x + w - radius, y + h)
            ctx.lineTo(x + radius, y + h)
            ctx.quadraticCurveTo(x, y + h, x, y + h - radius)
            ctx.lineTo(x, y + radius)
            ctx.quadraticCurveTo(x, y, x + radius, y)
        }

        onPaint: {
            const ctx = getContext("2d")
            const w = width
            const h = height
            const cx = w / 2
            const cy = h / 2
            const fg = root.accent2
            const fg2 = root.accent
            const soft = root.alpha(root.inkSoft, 0.78)

            ctx.reset()
            ctx.clearRect(0, 0, w, h)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.lineWidth = Math.max(1.7, w * 0.095)
            ctx.strokeStyle = fg
            ctx.fillStyle = fg

            if (iconName === "search") {
                ctx.beginPath()
                ctx.arc(cx - w * 0.08, cy - h * 0.08, w * 0.28, 0, Math.PI * 2)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(cx + w * 0.13, cy + h * 0.13)
                ctx.lineTo(cx + w * 0.34, cy + h * 0.34)
                ctx.stroke()
            } else if (iconName === "files") {
                ctx.fillStyle = root.alpha(root.theme ? root.theme.accentTertiary : Qt.rgba(0.50, 0.78, 1, 1), 0.88)
                ctx.beginPath()
                roundedRect(ctx, w * 0.11, h * 0.27, w * 0.78, h * 0.52, w * 0.10)
                ctx.fill()
                ctx.fillStyle = root.alpha(root.theme ? root.theme.accentTertiary : Qt.rgba(0.50, 0.78, 1, 1), 0.68)
                ctx.beginPath()
                roundedRect(ctx, w * 0.15, h * 0.18, w * 0.33, h * 0.20, w * 0.07)
                ctx.fill()
            } else if (iconName === "theme") {
                ctx.fillStyle = root.alpha(fg2, 0.86)
                ctx.beginPath()
                ctx.arc(cx, cy, w * 0.33, 0, Math.PI * 2)
                ctx.fill()
                ctx.fillStyle = root.alpha(root.theme ? root.theme.accentTertiary : Qt.rgba(0.62, 0.84, 1, 1), 0.86)
                ctx.beginPath()
                ctx.arc(cx + w * 0.08, cy - h * 0.08, w * 0.17, 0, Math.PI * 2)
                ctx.fill()
                ctx.strokeStyle = root.alpha(root.theme ? root.theme.activeText : Qt.rgba(1, 1, 1, 1), 0.78)
                ctx.lineWidth = Math.max(1, w * 0.055)
                ctx.beginPath()
                ctx.arc(cx, cy, w * 0.30, Math.PI * 0.20, Math.PI * 1.52)
                ctx.stroke()
            } else if (iconName === "discord") {
                ctx.strokeStyle = fg
                ctx.fillStyle = root.alpha(fg, 0.16)
                ctx.lineWidth = Math.max(1.6, w * 0.085)
                ctx.beginPath()
                roundedRect(ctx, w * 0.18, h * 0.31, w * 0.64, h * 0.42, w * 0.17)
                ctx.fill()
                ctx.stroke()
                ctx.fillStyle = fg
                ctx.beginPath()
                ctx.arc(w * 0.40, h * 0.52, w * 0.045, 0, Math.PI * 2)
                ctx.arc(w * 0.60, h * 0.52, w * 0.045, 0, Math.PI * 2)
                ctx.fill()
                ctx.beginPath()
                ctx.moveTo(w * 0.30, h * 0.33)
                ctx.lineTo(w * 0.21, h * 0.19)
                ctx.moveTo(w * 0.70, h * 0.33)
                ctx.lineTo(w * 0.79, h * 0.19)
                ctx.stroke()
            } else if (iconName === "browser") {
                const grad = ctx.createLinearGradient(0, 0, w, h)
                grad.addColorStop(0, root.theme ? root.theme.accentTertiary : "#8ed8ff")
                grad.addColorStop(0.56, fg2)
                grad.addColorStop(1, fg)
                ctx.fillStyle = grad
                ctx.beginPath()
                ctx.arc(cx, cy, w * 0.34, 0, Math.PI * 2)
                ctx.fill()
                ctx.strokeStyle = root.alpha(root.theme ? root.theme.activeText : Qt.rgba(1, 1, 1, 1), 0.64)
                ctx.lineWidth = Math.max(1, w * 0.055)
                ctx.beginPath()
                ctx.arc(cx + w * 0.04, cy, w * 0.20, Math.PI * 0.12, Math.PI * 1.55)
                ctx.stroke()
            } else if (iconName === "volume") {
                ctx.fillStyle = soft
                ctx.beginPath()
                ctx.moveTo(w * 0.17, h * 0.43)
                ctx.lineTo(w * 0.35, h * 0.43)
                ctx.lineTo(w * 0.54, h * 0.27)
                ctx.lineTo(w * 0.54, h * 0.73)
                ctx.lineTo(w * 0.35, h * 0.57)
                ctx.lineTo(w * 0.17, h * 0.57)
                ctx.closePath()
                ctx.fill()
                ctx.strokeStyle = soft
                ctx.beginPath()
                ctx.arc(w * 0.56, h * 0.50, w * 0.17, -0.65, 0.65)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(w * 0.56, h * 0.50, w * 0.28, -0.55, 0.55)
                ctx.stroke()
            } else if (iconName === "wifi") {
                ctx.strokeStyle = soft
                for (let i = 0; i < 3; i += 1) {
                    ctx.beginPath()
                    ctx.arc(cx, h * 0.68, w * (0.17 + i * 0.15), Math.PI * (1.13 + i * 0.015), Math.PI * (1.87 - i * 0.015))
                    ctx.stroke()
                }
                ctx.fillStyle = soft
                ctx.beginPath()
                ctx.arc(cx, h * 0.73, w * 0.045, 0, Math.PI * 2)
                ctx.fill()
            } else if (iconName === "brightness") {
                ctx.strokeStyle = soft
                ctx.fillStyle = root.alpha(fg2, 0.22)
                ctx.beginPath()
                ctx.arc(cx, cy, w * 0.20, 0, Math.PI * 2)
                ctx.fill()
                ctx.stroke()
                for (let i = 0; i < 8; i += 1) {
                    const a = i * Math.PI / 4
                    ctx.beginPath()
                    ctx.moveTo(cx + Math.cos(a) * w * 0.31, cy + Math.sin(a) * w * 0.31)
                    ctx.lineTo(cx + Math.cos(a) * w * 0.42, cy + Math.sin(a) * w * 0.42)
                    ctx.stroke()
                }
            } else if (iconName === "notifications") {
                ctx.strokeStyle = soft
                ctx.beginPath()
                ctx.moveTo(cx - w * 0.24, cy + h * 0.18)
                ctx.quadraticCurveTo(cx - w * 0.18, cy - h * 0.28, cx, cy - h * 0.28)
                ctx.quadraticCurveTo(cx + w * 0.18, cy - h * 0.28, cx + w * 0.24, cy + h * 0.18)
                ctx.lineTo(cx + w * 0.31, cy + h * 0.30)
                ctx.lineTo(cx - w * 0.31, cy + h * 0.30)
                ctx.closePath()
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(cx, cy + h * 0.38, w * 0.06, 0, Math.PI * 2)
                ctx.fill()
            } else if (iconName === "bluetooth") {
                ctx.strokeStyle = soft
                ctx.beginPath()
                ctx.moveTo(cx - w * 0.04, h * 0.14)
                ctx.lineTo(cx + w * 0.23, h * 0.34)
                ctx.lineTo(cx - w * 0.11, h * 0.50)
                ctx.lineTo(cx + w * 0.23, h * 0.66)
                ctx.lineTo(cx - w * 0.04, h * 0.86)
                ctx.lineTo(cx - w * 0.04, h * 0.14)
                ctx.moveTo(cx - w * 0.04, h * 0.50)
                ctx.lineTo(cx - w * 0.27, h * 0.31)
                ctx.moveTo(cx - w * 0.04, h * 0.50)
                ctx.lineTo(cx - w * 0.27, h * 0.69)
                ctx.stroke()
            } else if (iconName === "battery") {
                const p = progress >= 0 ? Math.max(0, Math.min(1, progress)) : 0.70
                ctx.strokeStyle = soft
                ctx.lineWidth = Math.max(1.5, w * 0.075)
                ctx.beginPath()
                roundedRect(ctx, w * 0.13, h * 0.34, w * 0.62, h * 0.32, w * 0.08)
                ctx.stroke()
                ctx.fillStyle = root.alpha(fg2, 0.64)
                ctx.beginPath()
                roundedRect(ctx, w * 0.19, h * 0.40, w * 0.50 * p, h * 0.20, w * 0.04)
                ctx.fill()
                ctx.fillStyle = soft
                ctx.fillRect(w * 0.78, h * 0.43, w * 0.06, h * 0.14)
            }
        }
    }
}
