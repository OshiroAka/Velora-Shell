import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
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
    property int notificationCountOverride: -1
    property string wifiConnectionState: "unknown"
    property string wifiConnectedSsid: ""
    property string bluetoothPowerState: "unknown"
    property string activePopupType: ""
    property string activeSystemPage: "settings"
    property var cavaValues: []
    property var mediaPlayer: null
    property real mediaPosition: 0
    property int mediaVersion: 0
    readonly property int effectiveNotificationCount: notificationCountOverride >= 0 ? notificationCountOverride : notificationCount
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string uiFont: theme ? theme.uiFont : "Noto Sans CJK JP"
    readonly property string monoFont: theme ? theme.monoFont : "JetBrainsMono Nerd Font"
    readonly property color surfaceBase: theme ? theme.surfaceSidebar : Qt.rgba(0.018, 0.024, 0.040, 1)
    readonly property bool lightPalette: luminance(surfaceBase) >= 0.58
    readonly property real effectiveBarOpacity: theme ? Math.max(0, Math.min(1, theme.topBarOpacity)) : 0.18
    readonly property color glass: alpha(surfaceBase, effectiveBarOpacity)
    readonly property color card: theme
        ? alpha(theme.surfaceCard, lightPalette ? 0.14 : 0.10)
        : Qt.rgba(0.055, 0.070, 0.105, 0.10)
    readonly property color cardHover: theme
        ? alpha(theme.surfaceButton, lightPalette ? 0.22 : 0.18)
        : Qt.rgba(0.095, 0.120, 0.165, 0.18)
    readonly property color controlCard: theme
        ? theme.mix(theme.surfaceCard, theme.accentPrimary, 0.07, lightPalette ? 0.44 : 0.38)
        : Qt.rgba(0.065, 0.082, 0.110, 0.38)
    readonly property color controlCardHover: theme
        ? theme.mix(theme.surfaceButton, theme.accentPrimary, 0.14, lightPalette ? 0.54 : 0.48)
        : Qt.rgba(0.105, 0.132, 0.176, 0.48)
    readonly property color cardActive: theme
        ? theme.mix(theme.surfaceCard, theme.accentPrimary, 0.26, lightPalette ? 0.62 : 0.56)
        : Qt.rgba(0.22, 0.68, 0.68, 0.56)
    readonly property color ink: theme ? theme.textPrimary : "#fbf8f2"
    readonly property color inkSoft: theme ? theme.alpha(theme.textSecondary, 0.86) : "#d5d1c8"
    readonly property color mutedInk: theme ? theme.alpha(theme.textMuted, 0.78) : "#aaa59c"
    readonly property color accent: theme ? theme.accentPrimary : "#8ccdd9"
    readonly property color accent2: theme ? theme.activeText : "#f3eee6"
    readonly property color accentSecondary: theme ? theme.accentSecondary : "#a98cd9"
    readonly property color accentTertiary: theme ? theme.accentTertiary : "#73b7da"
    readonly property color moduleBorder: alpha(lightPalette ? ink : accent2, lightPalette ? 0.20 : 0.18)
    readonly property color controlBorder: alpha(lightPalette ? ink : accent2, lightPalette ? 0.20 : 0.16)
    readonly property color moduleHighlight: alpha(lightPalette ? ink : "#ffffff", lightPalette ? 0.055 : 0.075)
    readonly property color pink: theme ? (theme.themeId === "pywal16" ? theme.accentSecondary : theme.accentPrimary) : Qt.rgba(0.88, 0.45, 0.66, 0.86)
    readonly property color lilac: theme ? (theme.themeId === "pywal16" ? theme.accentPrimary : theme.accentSecondary) : Qt.rgba(0.58, 0.47, 0.76, 0.78)
    readonly property real configuredIconScale: theme ? Math.max(0.72, Math.min(1.18, theme.barIconSize / 48.0)) : 1.0
    readonly property real configuredIconOpacity: theme ? theme.barIconOpacity : 0.80
    readonly property real configuredIconGap: theme ? theme.barIconSpacing : 16
    readonly property int topControlHeight: Math.round(34 * configuredIconScale)
    readonly property int topIconButtonSize: topControlHeight
    readonly property int topIconCanvasSize: Math.round(19 * configuredIconScale)
    readonly property int utilityButtonWidth: Math.round(26 * configuredIconScale)
    readonly property int utilityIconSize: Math.round(17 * configuredIconScale)
    readonly property int workspaceButtonWidth: Math.round(37 * configuredIconScale)
    readonly property int topButtonGap: Math.round(Math.max(6, Math.min(12, configuredIconGap * 0.48)))
    readonly property int topBarVerticalMargin: Math.max(4, Math.round(6 - (configuredIconScale - 1) * 3))
    readonly property int sectionInset: 34
    readonly property int motionHover: theme ? theme.motionHover : 120
    readonly property int motionNormal: theme ? theme.motionNormal : 200
    readonly property bool hoverMotionEnabled: !theme || theme.motionEnabled
    readonly property int hoverEnterDuration: hoverMotionEnabled ? 160 : 1
    readonly property int hoverExitDuration: hoverMotionEnabled ? 130 : 1
    readonly property bool topBarGradientEnabled: theme
        && theme.themeId === "pywal16"
        && theme.topBarGradientEnabled
    readonly property real topBarGradientStrength: theme
        ? Math.max(0, Math.min(1, Number(theme.topBarGradientStrength)))
        : 0.82
    readonly property bool topBarBubbleGradientEnabled: theme
        && theme.themeId === "pywal16"
        && theme.topBarBubbleGradientEnabled
    readonly property real topBarBubbleGradientStrength: theme
        ? Math.max(0, Math.min(1, Number(theme.topBarBubbleGradientStrength)))
        : 0.82
    readonly property bool topBarGradientMotionEnabled: (topBarGradientEnabled || topBarBubbleGradientEnabled)
        && hoverMotionEnabled
        && activePopupType.length > 0
    readonly property color topBarGradientStart: theme
        ? theme.mix(surfaceBase, accent, 0.92 * topBarGradientStrength, effectiveBarOpacity)
        : glass
    readonly property color topBarGradientMiddle: theme
        ? theme.mix(surfaceBase, accentTertiary, 0.76 * topBarGradientStrength, effectiveBarOpacity)
        : glass
    readonly property color topBarGradientEnd: theme
        ? theme.mix(surfaceBase, accentSecondary, 0.90 * topBarGradientStrength, effectiveBarOpacity)
        : glass
    readonly property real topBarBubbleOpacity: lightPalette ? 0.16 : 0.12
    readonly property color topBarBubbleStart: topBarBubbleTone(accent, 0.94)
    readonly property color topBarBubbleMiddle: topBarBubbleTone(accentTertiary, 0.80)
    readonly property color topBarBubbleEnd: topBarBubbleTone(accentSecondary, 0.92)
    property real topBarGradientPhase: 0
    readonly property int utilityInnerGap: 2
    readonly property int rightSectionSpacing: 3
    readonly property int rightDividerWidth: 1
    readonly property int avatarButtonSize: Math.round(32 * configuredIconScale)
    readonly property int systemUtilityRowWidth: root.utilityButtonWidth * root.systemUtilityOrder.length
        + root.utilityInnerGap * Math.max(0, root.systemUtilityOrder.length - 1)
    readonly property int rightModulePreferredWidth: 26
        + root.systemUtilityRowWidth
        + root.utilityButtonWidth
        + root.avatarButtonSize
        + root.rightDividerWidth * 2
        + root.rightSectionSpacing * 4
    readonly property string networkControlScript: Quickshell.shellDir + "/scripts/velora-network-control"
    readonly property string bluetoothControlScript: Quickshell.shellDir + "/scripts/velora-bluetooth-control"
    property bool editMode: false
    property var appOrder: ["files", "launcher", "terminal"]
    property var utilityOrder: ["volume", "wifi", "brightness", "bluetooth", "battery", "notifications", "settings"]
    readonly property var systemUtilityOrder: ["volume", "wifi", "brightness", "bluetooth", "battery", "notifications"]
    readonly property bool mediaAvailable: mediaPlayer !== null
    readonly property bool mediaPlaying: Boolean(mediaPlayer && mediaPlayer.isPlaying)
    readonly property real mediaLength: mediaPlayer && mediaPlayer.length > 0 ? Number(mediaPlayer.length) : 0
    readonly property real mediaProgress: mediaLength > 0 ? Math.max(0, Math.min(1, mediaPosition / mediaLength)) : 0
    readonly property string mediaTitle: mediaPlayer && String(mediaPlayer.trackTitle || "").trim().length > 0 ? String(mediaPlayer.trackTitle).trim() : "Nenhuma faixa"
    readonly property string mediaArtist: mediaPlayer && String(mediaPlayer.trackArtist || "").trim().length > 0 ? String(mediaPlayer.trackArtist).trim() : "Spotify / MPRIS"
    readonly property string mediaArtUrl: mediaPlayer ? String(mediaPlayer.trackArtUrl || "") : ""

    signal searchRequested(real centerX)
    signal themeRequested(real centerX)
    signal settingsRequested(real centerX)
    signal layoutRequested(real centerX)
    signal quickPopupRequested(string popupType, real centerX)
    signal quickPopupHovered(string popupType, real centerX)
    signal quickPopupHoverEnded(string popupType)

    implicitHeight: 56
    clip: false

    function alpha(colorValue, opacity) {
        return root.theme ? root.theme.alpha(colorValue, opacity) : Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacity)
    }

    function luminance(colorValue) {
        return colorValue.r * 0.2126 + colorValue.g * 0.7152 + colorValue.b * 0.0722
    }

    function mixGradientColor(first, second, amount) {
        const value = Math.max(0, Math.min(1, Number(amount) || 0))
        return Qt.rgba(
            first.r + (second.r - first.r) * value,
            first.g + (second.g - first.g) * value,
            first.b + (second.b - first.b) * value,
            first.a + (second.a - first.a) * value
        )
    }

    function cycleTopBarGradientColor(offset) {
        const wrapped = topBarGradientPhase + Number(offset || 0)
        const segment = (wrapped - Math.floor(wrapped)) * 3
        if (segment < 1)
            return mixGradientColor(topBarGradientStart, topBarGradientMiddle, segment)
        if (segment < 2)
            return mixGradientColor(topBarGradientMiddle, topBarGradientEnd, segment - 1)
        return mixGradientColor(topBarGradientEnd, topBarGradientStart, segment - 2)
    }

    function topBarBubbleTone(tintColor, amount) {
        return theme
            ? theme.mix(card, tintColor, amount * topBarBubbleGradientStrength, topBarBubbleOpacity)
            : mixGradientColor(card, tintColor, amount * topBarBubbleGradientStrength)
    }

    function topBarControlTone(baseColor, tintColor, amount) {
        const mixed = theme
            ? theme.mix(baseColor, tintColor, amount * topBarBubbleGradientStrength, baseColor.a)
            : mixGradientColor(baseColor, tintColor, amount * topBarBubbleGradientStrength)
        return alpha(mixed, baseColor.a)
    }

    function sampleTopBarBubbleGradient(globalUnit) {
        const wrapped = topBarGradientPhase + Math.max(0, Math.min(1, Number(globalUnit) || 0))
        const segment = (wrapped - Math.floor(wrapped)) * 3
        if (segment < 1)
            return mixGradientColor(topBarBubbleStart, topBarBubbleMiddle, segment)
        if (segment < 2)
            return mixGradientColor(topBarBubbleMiddle, topBarBubbleEnd, segment - 1)
        return mixGradientColor(topBarBubbleEnd, topBarBubbleStart, segment - 2)
    }

    function fontGlowEnabled() {
        return false
    }

    function profileImageSource() {
        const customPath = root.theme ? String(root.theme.profileImagePath || "").trim() : ""
        return customPath.length > 0 ? customPath : Qt.resolvedUrl("../assets/profile-avatar.svg")
    }

    function pickMediaPlayer() {
        const players = Mpris.players.values || []
        if (players.length <= 0)
            return null

        for (let i = 0; i < players.length; ++i) {
            if (players[i] && players[i].isPlaying)
                return players[i]
        }
        return players[0]
    }

    function refreshMediaPlayer() {
        mediaPlayer = pickMediaPlayer()
        mediaPosition = mediaPlayer ? Number(mediaPlayer.position || 0) : 0
        mediaVersion += 1
    }

    function normalizedMediaArt() {
        const art = String(mediaArtUrl || "").trim()
        if (art.length <= 0)
            return ""
        if (art.charAt(0) === "/")
            return "file://" + art
        return art
    }

    function toggleMedia() {
        if (mediaPlayer)
            mediaPlayer.togglePlaying()
    }

    function previousMedia() {
        if (mediaPlayer && mediaPlayer.canGoPrevious)
            mediaPlayer.previous()
    }

    function nextMedia() {
        if (mediaPlayer && mediaPlayer.canGoNext)
            mediaPlayer.next()
    }

    function formatMediaTime(value) {
        const seconds = Math.max(0, Math.floor(Number(value) || 0))
        const minutes = Math.floor(seconds / 60)
        const remainder = seconds % 60
        return minutes + ":" + (remainder < 10 ? "0" : "") + remainder
    }

    function formatLocalizedDate(date) {
        const lang = root.theme ? root.theme.language : "pt-BR"
        const weekdays = ["dom", "seg", "ter", "qua", "qui", "sex", "sab"]
        return date.getDate() + "/" + (date.getMonth() + 1) + " (" + weekdays[date.getDay()] + ")"
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

    function batteryCharging() {
        return Boolean(batteryDevice
            && batteryDevice.ready
            && batteryDevice.state === UPowerDeviceState.Charging)
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

    function launchTerminal() {
        runCommand("if command -v kitty >/dev/null 2>&1; then kitty >/dev/null 2>&1 & elif command -v foot >/dev/null 2>&1; then foot >/dev/null 2>&1 & elif command -v alacritty >/dev/null 2>&1; then alacritty >/dev/null 2>&1 & fi")
    }

    function scrollUtility(type, deltaY) {
        const up = Number(deltaY) > 0
        if (type === "volume") {
            runCommand("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (up ? "5%+" : "5%-") + " >/dev/null 2>&1")
            return true
        }
        if (type === "brightness") {
            runCommand("brightnessctl set " + (up ? "+5%" : "5%-") + " >/dev/null 2>&1")
            return true
        }
        return false
    }

    function moveListItem(list, fromIndex, toIndex) {
        const source = Array.isArray(list) ? list.slice() : []
        if (fromIndex < 0 || fromIndex >= source.length || toIndex < 0 || toIndex >= source.length || fromIndex === toIndex)
            return source

        const item = source.splice(fromIndex, 1)[0]
        source.splice(toIndex, 0, item)
        return source
    }

    function moveApp(fromIndex, toIndex) {
        appOrder = moveListItem(appOrder, fromIndex, toIndex)
    }

    function moveUtility(fromIndex, toIndex) {
        utilityOrder = moveListItem(utilityOrder, fromIndex, toIndex)
    }

    function appIconName(key) {
        if (key === "files")
            return "folder"
        if (key === "browser")
            return "browser"
        if (key === "discord")
            return "discord"
        if (key === "launcher")
            return "grid"
        if (key === "terminal")
            return "terminal"
        return "folder"
    }

    function launchApp(key, centerX) {
        if (key === "files") {
            launchFiles()
            return
        }
        if (key === "browser") {
            launchBrowser()
            return
        }
        if (key === "discord") {
            launchDiscord()
            return
        }
        if (key === "launcher") {
            root.quickPopupRequested("apps", Number(centerX) || root.width / 2)
            return
        }
        if (key === "terminal") {
            launchTerminal()
            return
        }
    }

    function utilityPopupType(key) {
        if (key === "settings")
            return "settingsQuick"
        return key
    }

    function utilityIconName(key) {
        if (key === "volume")
            return root.muted ? "volume-muted" : "volume"
        if (key === "wifi")
            return "wifi"
        if (key === "brightness")
            return "sun"
        if (key === "notifications")
            return "bell"
        if (key === "bluetooth")
            return "bluetooth"
        if (key === "battery")
            return "battery"
        if (key === "settings")
            return "settings"
        return key
    }

    function utilityBadgeText(key) {
        if (key === "volume" && root.muted)
            return "0"
        if (key === "notifications" && root.effectiveNotificationCount > 0)
            return String(Math.min(99, root.effectiveNotificationCount))
        return ""
    }

    function utilityProgress(key) {
        return key === "battery" ? root.batteryLevel() : -1
    }

    function utilityStatus(key) {
        if (key === "wifi")
            return root.wifiConnectionState === "connected" ? "ok" : (root.wifiConnectionState === "no-internet" ? "error" : (root.wifiConnectionState === "unknown" ? "normal" : "off"))
        if (key === "bluetooth")
            return root.bluetoothPowerState === "yes" ? "ok" : (root.bluetoothPowerState === "unknown" ? "normal" : "off")
        return "normal"
    }

    function activateUtility(key, centerX) {
        root.quickPopupRequested(root.utilityPopupType(key), centerX)
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

    component TopBarInnerBevel: Item {
        id: bevel

        property real cornerRadius: 8

        anchors.fill: parent
        z: 100

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 1
            }
            height: Math.round(parent.height * 0.48)
            radius: Math.max(0, bevel.cornerRadius - 1)
            color: root.alpha(
                root.lightPalette ? root.ink : "#ffffff",
                root.lightPalette ? 0.065 : 0.055
            )
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: Math.max(5, bevel.cornerRadius * 0.42)
                rightMargin: Math.max(5, bevel.cornerRadius * 0.42)
                topMargin: 1
            }
            height: 1
            radius: 0.5
            color: root.alpha(
                root.lightPalette ? root.ink : "#ffffff",
                root.lightPalette ? 0.12 : 0.16
            )
        }
    }

    component TopBarBubbleGradient: Gradient {
        id: bubbleGradient

        property color baseColor: root.card
        property Item hostItem: null
        property Item spanItem: null
        readonly property real geometryRevision: (hostItem
            ? hostItem.x + hostItem.y + hostItem.width + hostItem.height
            : 0) + (spanItem
                ? spanItem.x + spanItem.y + spanItem.width + spanItem.height
                : 0)
        readonly property real globalStart: {
            const spanWidth = spanItem ? spanItem.width + geometryRevision * 0 : 0
            if (!hostItem || !spanItem || spanItem.width <= 0)
                return 0
            return Math.max(0, Math.min(1, hostItem.mapToItem(spanItem, 0, 0).x / spanWidth))
        }
        readonly property real globalEnd: {
            const spanWidth = spanItem ? spanItem.width + geometryRevision * 0 : 0
            if (!hostItem || !spanItem || spanItem.width <= 0)
                return 1
            return Math.max(0, Math.min(1, hostItem.mapToItem(spanItem, hostItem.width, 0).x / spanWidth))
        }

        function globalPosition(localPosition) {
            return globalStart + (globalEnd - globalStart) * localPosition
        }

        orientation: Gradient.Horizontal

        GradientStop {
            position: 0
            color: root.topBarBubbleGradientEnabled
                ? root.sampleTopBarBubbleGradient(bubbleGradient.globalPosition(0))
                : bubbleGradient.baseColor
        }
        GradientStop {
            position: 0.25
            color: root.topBarBubbleGradientEnabled
                ? root.sampleTopBarBubbleGradient(bubbleGradient.globalPosition(0.25))
                : bubbleGradient.baseColor
        }
        GradientStop {
            position: 0.5
            color: root.topBarBubbleGradientEnabled
                ? root.sampleTopBarBubbleGradient(bubbleGradient.globalPosition(0.5))
                : bubbleGradient.baseColor
        }
        GradientStop {
            position: 0.75
            color: root.topBarBubbleGradientEnabled
                ? root.sampleTopBarBubbleGradient(bubbleGradient.globalPosition(0.75))
                : bubbleGradient.baseColor
        }
        GradientStop {
            position: 1
            color: root.topBarBubbleGradientEnabled
                ? root.sampleTopBarBubbleGradient(bubbleGradient.globalPosition(1))
                : bubbleGradient.baseColor
        }
    }

    component TopBarControlGradient: Gradient {
        id: controlGradient

        property color baseColor: root.controlCard

        orientation: Gradient.Horizontal

        GradientStop {
            position: 0
            color: root.topBarBubbleGradientEnabled
                ? root.topBarControlTone(controlGradient.baseColor, root.accent, 0.14)
                : controlGradient.baseColor
        }
        GradientStop {
            position: 0.5
            color: root.topBarBubbleGradientEnabled
                ? root.topBarControlTone(controlGradient.baseColor, root.accentTertiary, 0.08)
                : controlGradient.baseColor
        }
        GradientStop {
            position: 1
            color: root.topBarBubbleGradientEnabled
                ? root.topBarControlTone(controlGradient.baseColor, root.accentSecondary, 0.10)
                : controlGradient.baseColor
        }
    }

    NumberAnimation on topBarGradientPhase {
        from: 0
        to: 1
        duration: 8200
        easing.type: Easing.Linear
        loops: Animation.Infinite
        running: root.topBarGradientMotionEnabled
            && root.visible
            && root.width > 0
            && root.height > 0
    }

    Rectangle {
        id: surface

        anchors.fill: parent
        radius: 0
        color: "transparent"
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: root.topBarGradientEnabled
                    ? root.cycleTopBarGradientColor(0)
                    : root.glass
            }
            GradientStop {
                position: 0.25
                color: root.topBarGradientEnabled
                    ? root.cycleTopBarGradientColor(0.25)
                    : root.glass
            }
            GradientStop {
                position: 0.5
                color: root.topBarGradientEnabled
                    ? root.cycleTopBarGradientColor(0.5)
                    : root.glass
            }
            GradientStop {
                position: 0.75
                color: root.topBarGradientEnabled
                    ? root.cycleTopBarGradientColor(0.75)
                    : root.glass
            }
            GradientStop {
                position: 1
                color: root.topBarGradientEnabled
                    ? root.cycleTopBarGradientColor(1)
                    : root.glass
            }
        }
        border.width: root.effectiveBarOpacity > 0.01 ? 1 : 0
        border.color: root.alpha(root.lightPalette ? root.ink : root.accent2, root.effectiveBarOpacity * 0.16)
        antialiasing: true

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 12
                rightMargin: 12
                topMargin: 1
            }
            height: 1
            color: root.alpha(root.lightPalette ? root.ink : "#ffffff", root.effectiveBarOpacity * (root.lightPalette ? 0.055 : 0.075))
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 9
            visible: root.effectiveBarOpacity > 0.01
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                    position: 0
                    color: "transparent"
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(
                        0,
                        0,
                        0,
                        root.effectiveBarOpacity * (root.lightPalette ? 0.22 : 0.42)
                    )
                }
            }
        }

        RowLayout {
            id: contentRow
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }
            width: Math.min(parent.width, implicitWidth)
            height: parent.height - root.topBarVerticalMargin * 2
            spacing: root.theme ? root.theme.topBarCategoryGap : 8

            RowLayout {
                id: leftModules
                Layout.preferredWidth: implicitWidth
                Layout.fillHeight: true
                spacing: root.theme ? root.theme.topBarCategoryGap : 8

            ModuleFrame {
                id: clockBlock
                Layout.preferredWidth: Math.round(96 * root.configuredIconScale)
                Layout.fillHeight: true
                color: clockMouse.containsMouse ? root.cardHover : root.card

                Behavior on color {
                    ColorAnimation {
                        duration: clockMouse.containsMouse ? root.hoverEnterDuration : root.hoverExitDuration
                        easing.type: clockMouse.containsMouse ? Easing.OutCubic : Easing.InOutQuad
                    }
                }

                function centerX() {
                    return clockBlock.mapToItem(root, clockBlock.width / 2, clockBlock.height / 2).x
                }

                Item {
                    id: clockContent

                    anchors.fill: parent
                    scale: root.hoverMotionEnabled && clockMouse.containsMouse ? 1.06 : 1
                    transformOrigin: Item.Center

                    Behavior on scale {
                        NumberAnimation {
                            duration: clockMouse.containsMouse ? root.hoverEnterDuration : root.hoverExitDuration
                            easing.type: clockMouse.containsMouse ? Easing.OutCubic : Easing.InOutQuad
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.clockText
                        color: root.ink
                        font.family: root.monoFont
                        font.pixelSize: Math.round(18 * root.configuredIconScale)
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                MouseArea {
                    id: clockMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.quickPopupRequested("time", clockBlock.centerX())
                }
            }

            ModuleFrame {
                Layout.preferredWidth: root.workspaceButtonWidth * 4 + 20
                Layout.fillHeight: true

                RowLayout {
                    anchors {
                        fill: parent
                        margins: 4
                    }
                    spacing: 4

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

            ModuleFrame {
                Layout.preferredWidth: root.topIconButtonSize * root.appOrder.length + 18
                Layout.fillHeight: true

                RowLayout {
                    anchors {
                        fill: parent
                        margins: 4
                    }
                    spacing: 3

                    Repeater {
                        model: root.appOrder

                        TopIconButton {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            iconName: root.appIconName(modelData)
                            editable: root.editMode
                            orderIndex: index
                            orderCount: root.appOrder.length
                            onClicked: function(centerX) { root.launchApp(modelData, centerX) }
                            onReorderRequested: function(fromIndex, toIndex) { root.moveApp(fromIndex, toIndex) }
                        }
                    }
                }
            }
        }

            MediaCard {
                id: mediaCard
                Layout.minimumWidth: 280
                Layout.preferredWidth: 280
                Layout.maximumWidth: 280
                Layout.fillWidth: false
                Layout.fillHeight: true
            }

            ModuleFrame {
                id: rightModules
                Layout.preferredWidth: root.rightModulePreferredWidth
                Layout.fillHeight: true

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 13
                        rightMargin: 13
                        topMargin: 3
                        bottomMargin: 3
                    }
                    spacing: root.rightSectionSpacing

                    RowLayout {
                        id: systemUtilityRow
                        Layout.preferredWidth: root.systemUtilityRowWidth
                        Layout.fillHeight: true
                        spacing: root.utilityInnerGap

                        Repeater {
                            model: root.systemUtilityOrder

                            UtilityIconButton {
                                flatSurface: true
                                utilityKey: modelData
                                iconName: root.utilityIconName(modelData)
                                badgeText: root.utilityBadgeText(modelData)
                                progress: root.utilityProgress(modelData)
                                hoverPopupType: root.utilityPopupType(modelData)
                                selected: root.activePopupType === root.utilityPopupType(modelData)
                                    || (root.activePopupType === "system" && root.activeSystemPage === (modelData === "brightness" ? "display" : modelData))
                                status: root.utilityStatus(modelData)
                                onClicked: function(centerX) { root.activateUtility(modelData, centerX) }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: root.rightDividerWidth
                        Layout.preferredHeight: 26
                        radius: width / 2
                        color: root.alpha(root.inkSoft, 0.18)
                    }

                    UtilityIconButton {
                        flatSurface: true
                        utilityKey: "settings"
                        iconName: root.utilityIconName(utilityKey)
                        badgeText: root.utilityBadgeText(utilityKey)
                        progress: root.utilityProgress(utilityKey)
                        hoverPopupType: root.utilityPopupType(utilityKey)
                        selected: root.activePopupType === root.utilityPopupType(utilityKey)
                            || (root.activePopupType === "system" && root.activeSystemPage === utilityKey)
                        status: root.utilityStatus(utilityKey)
                        onClicked: function(centerX) { root.activateUtility(utilityKey, centerX) }
                    }

                    Rectangle {
                        Layout.preferredWidth: root.rightDividerWidth
                        Layout.preferredHeight: 26
                        radius: width / 2
                        color: root.alpha(root.inkSoft, 0.18)
                    }

                    Item {
                        id: avatarButton
                        Layout.preferredWidth: root.avatarButtonSize
                        Layout.preferredHeight: Layout.preferredWidth

                        function centerX() {
                            return avatarButton.mapToItem(root, avatarButton.width / 2, avatarButton.height / 2).x
                        }

                        DropShadow {
                            anchors.fill: avatarSurface
                            source: avatarSurface
                            horizontalOffset: 0
                            verticalOffset: 2
                            radius: 5
                            samples: 11
                            color: Qt.rgba(0, 0, 0, 0.22)
                            transparentBorder: true
                            z: -1
                        }

                        Rectangle {
                            id: avatarSurface
                            anchors.fill: parent
                            radius: 8
                            color: avatarMouse.containsMouse ? root.controlCardHover : root.controlCard
                            border.width: 1
                            border.color: root.alpha(root.accent, avatarMouse.containsMouse ? 0.62 : 0.46)

                        Behavior on color {
                            ColorAnimation {
                                duration: avatarMouse.containsMouse ? root.hoverEnterDuration : root.hoverExitDuration
                                easing.type: avatarMouse.containsMouse ? Easing.OutCubic : Easing.InOutQuad
                            }
                        }

                        Behavior on border.color {
                            ColorAnimation {
                                duration: avatarMouse.containsMouse ? root.hoverEnterDuration : root.hoverExitDuration
                                easing.type: avatarMouse.containsMouse ? Easing.OutCubic : Easing.InOutQuad
                            }
                        }

                        TopBarInnerBevel {
                            cornerRadius: avatarSurface.radius
                        }
                    }

                    Image {
                        anchors.fill: parent
                        anchors.margins: 2
                        source: root.profileImageSource()
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: avatarButton.width - 4
                                height: avatarButton.height - 4
                                radius: 6
                            }
                        }
                    }

                    MouseArea {
                        id: avatarMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.quickPopupRequested("quickSettings", avatarButton.centerX())
                    }
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
            if (!networkStatusQuery.running)
                networkStatusQuery.running = true
            if (!bluetoothStatusQuery.running)
                bluetoothStatusQuery.running = true
        }
    }

    Timer {
        interval: 1000
        running: root.visible && root.mediaAvailable
        repeat: true
        triggeredOnStart: true
        onTriggered: root.mediaPosition = root.mediaPlayer ? Number(root.mediaPlayer.position || 0) : 0
    }

    Connections {
        target: Mpris.players

        function onValuesChanged() {
            root.refreshMediaPlayer()
        }
    }

    Component.onCompleted: {
        root.updateClockText()
        root.refreshMediaPlayer()
    }

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
                if (root.notificationCountOverride >= 0)
                    return
                const value = parseInt(String(data || "").trim())
                root.notificationCount = isNaN(value) ? 0 : Math.max(0, value)
            }
        }

        onExited: running = false
    }

    Process {
        id: networkStatusQuery

        running: false
        command: [root.networkControlScript, "status"]

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data || "").trim()
                if (line.indexOf("STATUS|") !== 0)
                    return
                const parts = line.split("|")
                root.wifiConnectionState = parts.length > 1 ? parts[1] : "unknown"
                root.wifiConnectedSsid = parts.length > 2 ? parts[2] : ""
            }
        }

        onExited: running = false
    }

    Process {
        id: bluetoothStatusQuery

        running: false
        command: [root.bluetoothControlScript, "status"]

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data || "").trim()
                if (line.indexOf("POWER|") !== 0)
                    return
                root.bluetoothPowerState = (line.split("|")[1] || "unknown").toLowerCase()
            }
        }

        onExited: running = false
    }

    component ModuleFrame: Item {
        id: moduleFrame

        property real radius: 10
        property color color: root.card

        DropShadow {
            anchors.fill: moduleSurface
            source: moduleSurface
            horizontalOffset: 0
            verticalOffset: 3
            radius: 12
            samples: 25
            color: Qt.rgba(0, 0, 0, 0.24)
            transparentBorder: true
            z: -2
        }

        Rectangle {
            id: moduleSurface

            anchors.fill: parent
            radius: moduleFrame.radius
            color: moduleFrame.color
            gradient: TopBarBubbleGradient {
                baseColor: moduleSurface.color
                hostItem: moduleSurface
                spanItem: contentRow
            }
            border.width: 1
            border.color: root.moduleBorder
            antialiasing: true
            z: -1

            TopBarInnerBevel {
                cornerRadius: moduleSurface.radius
            }
        }
    }

    component MediaCard: Item {
        id: media

        property bool hovered: false
        property real radius: 10
        property color color: media.hovered ? root.cardHover : root.card
        property color borderColor: media.hovered || root.mediaPlaying
            ? root.alpha(root.accent, 0.38)
            : root.moduleBorder

        DropShadow {
            anchors.fill: mediaSurface
            source: mediaSurface
            horizontalOffset: 0
            verticalOffset: 3
            radius: 12
            samples: 25
            color: Qt.rgba(0, 0, 0, 0.24)
            transparentBorder: true
            z: -2
        }

        Rectangle {
            id: mediaSurface

            anchors.fill: parent
            radius: media.radius
            color: media.color
            gradient: TopBarBubbleGradient {
                baseColor: mediaSurface.color
                hostItem: mediaSurface
                spanItem: contentRow
            }
            border.width: 1
            border.color: media.borderColor
            antialiasing: true
            z: -1

            TopBarInnerBevel {
                cornerRadius: mediaSurface.radius
            }
        }

        function centerX() {
            return media.mapToItem(root, media.width / 2, media.height / 2).x
        }

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }
        Behavior on borderColor { ColorAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 6
                rightMargin: 6
                topMargin: 4
                bottomMargin: 4
            }
            spacing: 5

            Item {
                id: mediaArtFrame
                Layout.preferredWidth: height
                Layout.fillHeight: true
                clip: false

                Rectangle {
                    id: mediaArtVisual

                    anchors.fill: parent
                    radius: 7
                    color: root.controlCardHover
                    border.width: 1
                    border.color: root.controlBorder
                    clip: true
                    scale: root.hoverMotionEnabled && mediaArtHover.hovered ? 1.06 : 1
                    transformOrigin: Item.Center

                    Behavior on scale {
                        NumberAnimation {
                            duration: mediaArtHover.hovered ? root.hoverEnterDuration : root.hoverExitDuration
                            easing.type: mediaArtHover.hovered ? Easing.OutCubic : Easing.InOutQuad
                        }
                    }

                    Image {
                        id: mediaArt
                        anchors.fill: parent
                        source: root.normalizedMediaArt()
                        visible: false
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                    }

                    Rectangle {
                        id: mediaArtMask
                        anchors.fill: parent
                        radius: mediaArtVisual.radius
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: mediaArt
                        maskSource: mediaArtMask
                        visible: mediaArt.status === Image.Ready && mediaArt.source.toString().length > 0
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: mediaArt.status !== Image.Ready || mediaArt.source.toString().length <= 0
                        text: "♫"
                        color: root.inkSoft
                        font.family: root.monoFont
                        font.pixelSize: 17
                    }
                }

                HoverHandler { id: mediaArtHover }

                TapHandler {
                    onTapped: root.quickPopupRequested("media", media.centerX())
                }
            }

            Item {
                id: mediaMetadataFrame

                Layout.preferredWidth: 76
                Layout.fillHeight: true
                clip: false

                ColumnLayout {
                    id: mediaMetadataVisual

                    anchors.fill: parent
                    spacing: 1
                    scale: root.hoverMotionEnabled && mediaMetadataHover.hovered ? 1.06 : 1
                    transformOrigin: Item.Center

                    Behavior on scale {
                        NumberAnimation {
                            duration: mediaMetadataHover.hovered ? root.hoverEnterDuration : root.hoverExitDuration
                            easing.type: mediaMetadataHover.hovered ? Easing.OutCubic : Easing.InOutQuad
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.mediaTitle
                        color: root.ink
                        font.family: root.uiFont
                        font.pixelSize: Math.round(10 * root.configuredIconScale)
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.mediaArtist
                        color: root.mutedInk
                        font.family: root.uiFont
                        font.pixelSize: Math.round(8 * root.configuredIconScale)
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 2
                        radius: 1
                        color: root.moduleBorder

                        Rectangle {
                            width: parent.width * root.mediaProgress
                            height: parent.height
                            radius: parent.radius
                            color: root.alpha(root.accent, 0.76)
                            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                HoverHandler { id: mediaMetadataHover }

                TapHandler {
                    onTapped: root.quickPopupRequested("media", media.centerX())
                }
            }

            Item {
                id: mediaActions

                Layout.minimumWidth: 132
                Layout.preferredWidth: 142
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    id: mediaActionsSurface

                    anchors {
                        fill: parent
                        topMargin: 3
                        bottomMargin: 3
                    }
                    radius: 7
                    color: root.theme
                        ? root.theme.mix(root.theme.surfaceButton, root.accent, 0.04, root.lightPalette ? 0.24 : 0.20)
                        : Qt.rgba(0.065, 0.082, 0.110, 0.20)
                    border.width: 1
                    border.color: root.alpha(root.inkSoft, 0.08)
                    antialiasing: true
                }

                RowLayout {
                    anchors {
                        fill: mediaActionsSurface
                        leftMargin: 4
                        rightMargin: 4
                        topMargin: 3
                        bottomMargin: 3
                    }
                    spacing: 0

                    MediaControl {
                        label: "‹"
                        enabledControl: Boolean(root.mediaPlayer && root.mediaPlayer.canGoPrevious)
                        onTriggered: root.previousMedia()
                    }

                    MediaControl {
                        primary: true
                        label: root.mediaPlaying ? "Ⅱ" : "▶"
                        enabledControl: root.mediaAvailable
                        onTriggered: root.toggleMedia()
                    }

                    MediaControl {
                        label: "›"
                        enabledControl: Boolean(root.mediaPlayer && root.mediaPlayer.canGoNext)
                        onTriggered: root.nextMedia()
                    }

                    Item {
                        Layout.preferredWidth: 4
                        Layout.fillHeight: true
                    }

                    Item {
                        id: compactWaveform
                        Layout.minimumWidth: 52
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        VeloraGlavaTopSpectrum {
                            anchors {
                                fill: parent
                                topMargin: 2
                                bottomMargin: 2
                            }
                            theme: root.theme
                            values: root.cavaValues
                            // The screen-wide spectrum already represents all
                            // monitor audio.  This compact media waveform only
                            // needs frames while an MPRIS track is playing;
                            // otherwise it caused a second QSG redraw stream
                            // behind the "Nenhuma faixa ativa" state.
                            active: root.visible && root.mediaPlaying
                            growFromCenter: true
                            minimumLevel: 0.09
                            referenceHeight: Math.max(8, height - 4)
                            strength: root.theme
                                ? Math.max(0, Math.min(1, Number(root.theme.visualizerStrength)))
                                : 0.46
                            opacity: root.mediaPlaying ? 0.82 : 0.42

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: root.hoverExitDuration
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: media.hovered = true
            onExited: media.hovered = false
        }
    }

    component MediaControl: Item {
        id: control

        property string label: "▶"
        property bool primary: false
        property bool enabledControl: true
        signal triggered()

        Layout.preferredWidth: 22
        Layout.fillHeight: true
        opacity: enabledControl ? 1 : 0.34

        Item {
            id: mediaControlVisual

            anchors.fill: parent
            scale: root.hoverMotionEnabled && controlMouse.containsMouse ? 1.06 : 1
            transformOrigin: Item.Center

            Behavior on scale {
                NumberAnimation {
                    duration: controlMouse.containsMouse ? root.hoverEnterDuration : root.hoverExitDuration
                    easing.type: controlMouse.containsMouse ? Easing.OutCubic : Easing.InOutQuad
                }
            }

            Rectangle {
                id: mediaControlSurface

                anchors.centerIn: parent
                width: control.primary ? 22 : 20
                height: 22
                radius: 7
                color: controlMouse.containsMouse ? root.controlCardHover : "transparent"
                border.width: controlMouse.containsMouse ? 1 : 0
                border.color: controlMouse.containsMouse ? root.controlBorder : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: controlMouse.containsMouse ? root.hoverEnterDuration : root.hoverExitDuration
                        easing.type: controlMouse.containsMouse ? Easing.OutCubic : Easing.InOutQuad
                    }
                }

                Behavior on border.color {
                    ColorAnimation {
                        duration: controlMouse.containsMouse ? root.hoverEnterDuration : root.hoverExitDuration
                        easing.type: controlMouse.containsMouse ? Easing.OutCubic : Easing.InOutQuad
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: control.label
                color: root.inkSoft
                font.family: root.monoFont
                font.pixelSize: control.primary ? 12 : 17
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: controlMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: control.enabledControl
            cursorShape: Qt.PointingHandCursor
            onClicked: control.triggered()
        }
    }

    component TopDivider: Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 30
        color: Qt.rgba(1, 1, 1, 0.085)
    }

    component TopSection: Item {
        id: section

        property string title: ""
        property int contentInset: root.sectionInset

        Layout.fillHeight: true

        Text {
            anchors.left: parent.left
            anchors.leftMargin: section.contentInset
            anchors.top: parent.top
            text: section.title
            color: root.ink
            font.family: root.uiFont
            font.pixelSize: 11
            font.weight: Font.Bold
        }
    }

    component TopButton: Rectangle {
        id: button

        property string iconName: "search"
        property string label: ""
        property bool selected: false
        property string hoverPopupType: ""
        signal clicked(real centerX)

        radius: height / 2
        color: selected ? root.cardActive : (mouse.containsMouse ? root.cardHover : "transparent")
        border.width: 1
        border.color: selected ? Qt.rgba(1, 1, 1, 0.16) : (mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.11) : "transparent")
        scale: mouse.pressed ? 0.98 : (mouse.containsMouse ? 1.012 : 1)
        antialiasing: true

        function centerX() {
            return button.mapToItem(root, button.width / 2, button.height / 2).x
        }

        function iconLineColor() {
            if (button.selected)
                return root.pink
            if (button.iconName === "folder")
                return root.theme ? root.theme.accentTertiary : Qt.rgba(0.46, 0.64, 0.90, 0.94)
            if (button.iconName === "browser")
                return root.theme ? root.theme.accentPrimary : Qt.rgba(0.91, 0.46, 0.36, 0.90)
            if (button.iconName === "discord")
                return root.theme ? root.theme.accentSecondary : Qt.rgba(0.53, 0.47, 0.84, 0.90)
            if (button.iconName === "palette")
                return root.pink
            return root.inkSoft
        }

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Math.round(10 * root.configuredIconScale)
            anchors.rightMargin: Math.round(11 * root.configuredIconScale)
            spacing: Math.round(7 * root.configuredIconScale)

                    IconCanvas {
                        Layout.preferredWidth: Math.round(16 * root.configuredIconScale)
                        Layout.preferredHeight: Layout.preferredWidth
                        iconName: button.iconName
                        lineColor: button.selected ? root.accent2 : root.inkSoft
                    }

            Text {
                Layout.fillWidth: true
                text: button.label
                color: root.ink
                font.family: root.uiFont
                font.pixelSize: Math.round(11 * root.configuredIconScale)
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
            onWheel: function(wheel) {
                if (root.scrollUtility(button.hoverPopupType, wheel.angleDelta.y))
                    wheel.accepted = true
            }
            onClicked: button.clicked(button.centerX())
        }
    }

    component WorkspaceButton: Item {
        id: button

        property int number: 1
        readonly property bool active: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === number

        function centerX() {
            return button.mapToItem(root, button.width / 2, button.height / 2).x
        }

        DropShadow {
            anchors.fill: workspaceVisual
            source: workspaceVisual
            horizontalOffset: 0
            verticalOffset: 2
            radius: 5
            samples: 11
            color: Qt.rgba(0, 0, 0, 0.22)
            transparentBorder: true
            z: -1
        }

        Rectangle {
            id: workspaceVisual

            anchors.fill: parent
            radius: 8
            color: button.active ? root.cardActive : (mouse.containsMouse ? root.controlCardHover : root.controlCard)
            gradient: TopBarControlGradient {
                baseColor: workspaceVisual.color
            }
            border.width: 1
            border.color: button.active ? root.alpha(root.accent, 0.34) : root.controlBorder
            scale: root.hoverMotionEnabled
                ? (mouse.pressed ? 0.96 : (mouse.containsMouse ? 1.06 : 1))
                : 1
            transformOrigin: Item.Center
            antialiasing: true

            TopBarInnerBevel {
                cornerRadius: workspaceVisual.radius
                opacity: button.active || mouse.containsMouse ? 1 : 0.72
            }

            Behavior on color {
                ColorAnimation {
                    duration: mouse.containsMouse ? root.hoverEnterDuration : root.hoverExitDuration
                    easing.type: mouse.containsMouse ? Easing.OutCubic : Easing.InOutQuad
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: mouse.containsMouse ? root.hoverEnterDuration : root.hoverExitDuration
                    easing.type: mouse.containsMouse ? Easing.OutCubic : Easing.InOutQuad
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: mouse.containsMouse ? root.hoverEnterDuration : root.hoverExitDuration
                    easing.type: mouse.containsMouse ? Easing.OutCubic : Easing.InOutQuad
                }
            }

            Text {
                anchors.centerIn: parent
                text: String(button.number)
                color: button.active ? "#ffffff" : root.ink
                font.family: root.uiFont
                font.pixelSize: Math.round(12 * root.configuredIconScale)
                font.weight: Font.DemiBold
                layer.enabled: root.fontGlowEnabled()
                layer.effect: FontGlowEffect {}
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: function(event) {
                if (event.button === Qt.RightButton || button.active)
                    root.quickPopupRequested("workspaces", button.centerX())
                else
                    Hyprland.dispatch("workspace " + button.number)
            }
        }
    }

    component TopIconButton: Item {
        id: button

        property string iconName: "files"
        property string badgeText: ""
        property real progress: -1
        property bool selected: false
        property string hoverPopupType: ""
        property bool editable: false
        property int orderIndex: -1
        property int orderCount: 0
        property real dragStartX: 0
        property real dragStartY: 0
        signal clicked(real centerX)
        signal reorderRequested(int fromIndex, int toIndex)

        z: mouse.pressed ? 20 : 0

        function centerX() {
            return button.mapToItem(root, button.width / 2, button.height / 2).x
        }

        function targetIndexFromDrag() {
            if (!button.parent || button.orderCount <= 0)
                return button.orderIndex

            const local = button.mapToItem(button.parent, button.width / 2, button.height / 2)
            const span = Math.max(1, button.width + root.topButtonGap)
            return Math.max(0, Math.min(button.orderCount - 1, Math.round((local.x - button.width / 2) / span)))
        }

        function iconLineColor() {
            if (button.selected)
                return root.pink
            if (button.iconName === "folder")
                return root.theme ? root.theme.accentTertiary : Qt.rgba(0.46, 0.64, 0.90, 0.94)
            if (button.iconName === "browser")
                return root.theme ? root.theme.accentPrimary : Qt.rgba(0.91, 0.46, 0.36, 0.90)
            if (button.iconName === "discord")
                return root.theme ? root.theme.accentSecondary : Qt.rgba(0.53, 0.47, 0.84, 0.90)
            if (button.iconName === "palette")
                return root.pink
            return root.inkSoft
        }

        DropShadow {
            anchors.fill: topIconVisual
            source: topIconVisual
            horizontalOffset: 0
            verticalOffset: 2
            radius: 5
            samples: 11
            color: Qt.rgba(0, 0, 0, 0.22)
            transparentBorder: true
            z: -1
        }

        Rectangle {
            id: topIconVisual

            anchors.fill: parent
            radius: 8
            color: button.selected ? root.cardActive : (mouse.containsMouse ? root.controlCardHover : root.controlCard)
            gradient: TopBarControlGradient {
                baseColor: topIconVisual.color
            }
            border.width: 1
            border.color: button.editable
                ? root.alpha(root.accent, 0.42)
                : (button.selected ? root.alpha(root.accent, 0.34) : root.controlBorder)
            scale: root.hoverMotionEnabled
                ? (mouse.pressed ? 0.95 : (mouse.containsMouse ? 1.06 : (button.editable ? 1.02 : 1)))
                : 1
            transformOrigin: Item.Center
            antialiasing: true

            TopBarInnerBevel {
                cornerRadius: topIconVisual.radius
                opacity: button.selected || mouse.containsMouse || button.editable ? 1 : 0.72
            }

            Behavior on color {
                ColorAnimation {
                    duration: mouse.containsMouse ? root.hoverEnterDuration : root.hoverExitDuration
                    easing.type: mouse.containsMouse ? Easing.OutCubic : Easing.InOutQuad
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: mouse.containsMouse ? root.hoverEnterDuration : root.hoverExitDuration
                    easing.type: mouse.containsMouse ? Easing.OutCubic : Easing.InOutQuad
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: mouse.containsMouse ? root.hoverEnterDuration : root.hoverExitDuration
                    easing.type: mouse.containsMouse ? Easing.OutCubic : Easing.InOutQuad
                }
            }

            SequentialAnimation on rotation {
                running: root.hoverMotionEnabled && button.editable && !mouse.pressed
                loops: Animation.Infinite
                NumberAnimation { to: -2.2; duration: 84; easing.type: Easing.InOutSine }
                NumberAnimation { to: 2.2; duration: 168; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0; duration: 84; easing.type: Easing.InOutSine }
                onStopped: topIconVisual.rotation = 0
            }
        }

        IconCanvas {
            parent: topIconVisual
            anchors.centerIn: parent
            width: Math.min(root.topIconCanvasSize, parent.width - 8)
            height: width
            iconName: button.iconName
            progress: button.progress
            lineColor: button.iconLineColor()
        }

        Rectangle {
            parent: topIconVisual
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
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: root.editMode ? Qt.OpenHandCursor : Qt.PointingHandCursor
            drag.target: button
            drag.axis: root.editMode ? Drag.XAxis : Drag.None
            drag.threshold: 3
            onPressed: function(event) {
                button.dragStartX = button.x
                button.dragStartY = button.y
                if (root.editMode)
                    cursorShape = Qt.ClosedHandCursor
            }
            onReleased: function(event) {
                if (root.editMode && event.button === Qt.LeftButton) {
                    const nextIndex = button.targetIndexFromDrag()
                    button.x = button.dragStartX
                    button.y = button.dragStartY
                    button.reorderRequested(button.orderIndex, nextIndex)
                }
                cursorShape = root.editMode ? Qt.OpenHandCursor : Qt.PointingHandCursor
            }
            onPressAndHold: root.editMode = true
            onClicked: function(event) {
                if (event.button === Qt.RightButton) {
                    root.editMode = !root.editMode
                    event.accepted = true
                    return
                }
                if (root.editMode) {
                    event.accepted = true
                    return
                }
                button.clicked(button.centerX())
            }
        }
    }

    component HoverWaveArc: Canvas {
        id: wave

        property int waveIndex: 0
        property color strokeColor: "white"

        antialiasing: true

        onPaint: {
            const ctx = getContext("2d")
            const size = Math.min(width, height)
            const radius = size * (0.15 + wave.waveIndex * 0.095)
            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = wave.strokeColor
            ctx.lineWidth = Math.max(1.15, size * 0.075)
            ctx.lineCap = "round"
            ctx.beginPath()
            ctx.arc(width * 0.47, height * 0.50, radius, -0.86, 0.86, false)
            ctx.stroke()
        }

        onStrokeColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
    }

    component HoverSunRays: Canvas {
        id: rays

        property color strokeColor: "white"

        antialiasing: true

        onPaint: {
            const ctx = getContext("2d")
            const size = Math.min(width, height)
            const cx = width / 2
            const cy = height / 2
            const innerRadius = size * 0.31
            const outerRadius = size * 0.46
            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = rays.strokeColor
            ctx.lineWidth = Math.max(1.1, size * 0.072)
            ctx.lineCap = "round"
            for (let index = 0; index < 8; ++index) {
                const angle = Math.PI * index / 4
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(angle) * innerRadius,
                           cy + Math.sin(angle) * innerRadius)
                ctx.lineTo(cx + Math.cos(angle) * outerRadius,
                           cy + Math.sin(angle) * outerRadius)
                ctx.stroke()
            }
        }

        onStrokeColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
    }

    component SystemHoverIcon: Item {
        id: motionIcon

        property string utilityKey: "volume"
        property string iconName: "volume"
        property real progress: -1
        property color lineColor: root.inkSoft
        property bool motionActive: false
        property bool muted: false
        property bool charging: false

        property real volumeWave1Opacity: 0
        property real volumeWave2Opacity: 0
        property real volumeWave3Opacity: 0
        property real volumeWave1Scale: 0.88
        property real volumeWave2Scale: 0.88
        property real volumeWave3Scale: 0.88
        property real muteLineProgress: 0
        property real muteJitter: 0
        property real wifiInnerOpacity: 0
        property real wifiMiddleOpacity: 0
        property real wifiOuterOpacity: 0
        property real wifiInnerScale: 0.85
        property real wifiMiddleScale: 0.85
        property real wifiOuterScale: 0.85
        property real brightnessRayScale: 1
        property real brightnessRayRotation: 0
        property real brightnessRayOpacity: 0.72
        property real bluetoothTopOpacity: 0
        property real bluetoothCenterOpacity: 0
        property real bluetoothBottomOpacity: 0
        property real bluetoothPulseScale: 1
        property real bluetoothPulseRotation: 0
        property real batterySweep: -0.35
        property real batteryBoltScale: 1
        property real bellRotation: 0
        property real badgeScale: 1
        property real settingsRotation: 0

        readonly property bool replaceBase: motionActive && (
            (utilityKey === "volume" && !muted)
            || utilityKey === "wifi"
            || utilityKey === "brightness"
            || utilityKey === "notifications"
            || utilityKey === "settings")

        function stopAllLoops() {
            volumeLoop.stop()
            muteLoop.stop()
            wifiLoop.stop()
            brightnessLoop.stop()
            bluetoothLoop.stop()
            batteryLoop.stop()
            chargingLoop.stop()
            bellLoop.stop()
            badgeLoop.stop()
            settingsLoop.stop()
        }

        function resetVisualState(resetBadge) {
            volumeWave1Opacity = 0
            volumeWave2Opacity = 0
            volumeWave3Opacity = 0
            volumeWave1Scale = 0.88
            volumeWave2Scale = 0.88
            volumeWave3Scale = 0.88
            muteLineProgress = 0
            muteJitter = 0
            wifiInnerOpacity = 0
            wifiMiddleOpacity = 0
            wifiOuterOpacity = 0
            wifiInnerScale = 0.85
            wifiMiddleScale = 0.85
            wifiOuterScale = 0.85
            brightnessRayScale = 1
            brightnessRayRotation = 0
            brightnessRayOpacity = 0.72
            bluetoothTopOpacity = 0
            bluetoothCenterOpacity = 0
            bluetoothBottomOpacity = 0
            bluetoothPulseScale = 1
            bluetoothPulseRotation = 0
            batterySweep = -0.35
            batteryBoltScale = 1
            bellRotation = 0
            settingsRotation = 0
            if (resetBadge)
                badgeScale = 1
        }

        function startActiveLoop() {
            stopAllLoops()
            badgeReturn.stop()
            resetVisualState(true)
            if (!motionActive)
                return

            if (utilityKey === "volume") {
                if (muted)
                    muteLoop.restart()
                else
                    volumeLoop.restart()
            } else if (utilityKey === "wifi") {
                wifiLoop.restart()
            } else if (utilityKey === "brightness") {
                brightnessLoop.restart()
            } else if (utilityKey === "bluetooth") {
                bluetoothLoop.restart()
            } else if (utilityKey === "battery") {
                batteryLoop.restart()
                if (charging)
                    chargingLoop.restart()
            } else if (utilityKey === "notifications") {
                bellLoop.restart()
                badgeLoop.restart()
            } else if (utilityKey === "settings") {
                settingsLoop.restart()
            }
        }

        onMotionActiveChanged: {
            if (motionActive) {
                startActiveLoop()
            } else {
                stopAllLoops()
                resetVisualState(false)
                badgeReturn.restart()
            }
        }
        onUtilityKeyChanged: if (motionActive) startActiveLoop()
        onMutedChanged: if (motionActive && utilityKey === "volume") startActiveLoop()
        onChargingChanged: if (motionActive && utilityKey === "battery") startActiveLoop()
        Component.onCompleted: if (motionActive) startActiveLoop()

        IconCanvas {
            id: baseSystemIcon

            anchors.fill: parent
            opacity: motionIcon.replaceBase ? 0 : 1
            iconName: motionIcon.iconName
            progress: motionIcon.progress
            lineColor: motionIcon.lineColor
        }

        // Active volume keeps the speaker body fixed and draws each wave separately.
        Item {
            anchors.fill: parent
            visible: motionIcon.motionActive && motionIcon.utilityKey === "volume" && !motionIcon.muted

            Item {
                id: volumeBodyClip
                x: 0
                y: 0
                width: parent.width * 0.55
                height: parent.height
                clip: true

                IconCanvas {
                    width: motionIcon.width
                    height: motionIcon.height
                    iconName: motionIcon.iconName
                    progress: motionIcon.progress
                    lineColor: motionIcon.lineColor
                }
            }

            HoverWaveArc {
                anchors.fill: parent
                waveIndex: 0
                strokeColor: motionIcon.lineColor
                opacity: motionIcon.volumeWave1Opacity
                scale: motionIcon.volumeWave1Scale
                transformOrigin: Item.Center
            }

            HoverWaveArc {
                anchors.fill: parent
                waveIndex: 1
                strokeColor: motionIcon.lineColor
                opacity: motionIcon.volumeWave2Opacity
                scale: motionIcon.volumeWave2Scale
                transformOrigin: Item.Center
            }

            HoverWaveArc {
                anchors.fill: parent
                waveIndex: 2
                strokeColor: motionIcon.lineColor
                opacity: motionIcon.volumeWave3Opacity
                scale: motionIcon.volumeWave3Scale
                transformOrigin: Item.Center
            }
        }

        Rectangle {
            visible: motionIcon.motionActive && motionIcon.utilityKey === "volume" && motionIcon.muted
            x: parent.width * 0.16 + motionIcon.muteJitter
            y: parent.height * 0.14
            width: parent.width * 0.90 * motionIcon.muteLineProgress
            height: Math.max(1, parent.height * 0.075)
            radius: height / 2
            color: motionIcon.lineColor
            opacity: 0.82
            rotation: 45
            transformOrigin: Item.Left
        }

        // Wi-Fi is the same Material glyph split into a fixed point and three bands.
        Item {
            anchors.fill: parent
            visible: motionIcon.motionActive && motionIcon.utilityKey === "wifi"

            Item {
                id: wifiPointClip
                x: 0
                y: parent.height * 0.68
                width: parent.width
                height: parent.height * 0.32
                clip: true

                IconCanvas {
                    width: motionIcon.width
                    height: motionIcon.height
                    y: -wifiPointClip.y
                    iconName: motionIcon.iconName
                    progress: motionIcon.progress
                    lineColor: motionIcon.lineColor
                }
            }

            Item {
                id: wifiInnerLayer
                anchors.fill: parent
                opacity: motionIcon.wifiInnerOpacity
                scale: motionIcon.wifiInnerScale
                transformOrigin: Item.Bottom

                Item {
                    id: wifiInnerClip
                    x: 0
                    y: parent.height * 0.48
                    width: parent.width
                    height: parent.height * 0.28
                    clip: true
                    IconCanvas {
                        width: motionIcon.width
                        height: motionIcon.height
                        y: -wifiInnerClip.y
                        iconName: motionIcon.iconName
                        progress: motionIcon.progress
                        lineColor: motionIcon.lineColor
                    }
                }
            }

            Item {
                anchors.fill: parent
                opacity: motionIcon.wifiMiddleOpacity
                scale: motionIcon.wifiMiddleScale
                transformOrigin: Item.Bottom

                Item {
                    id: wifiMiddleClip
                    x: 0
                    y: parent.height * 0.27
                    width: parent.width
                    height: parent.height * 0.29
                    clip: true
                    IconCanvas {
                        width: motionIcon.width
                        height: motionIcon.height
                        y: -wifiMiddleClip.y
                        iconName: motionIcon.iconName
                        progress: motionIcon.progress
                        lineColor: motionIcon.lineColor
                    }
                }
            }

            Item {
                anchors.fill: parent
                opacity: motionIcon.wifiOuterOpacity
                scale: motionIcon.wifiOuterScale
                transformOrigin: Item.Bottom

                Item {
                    id: wifiOuterClip
                    x: 0
                    y: 0
                    width: parent.width
                    height: parent.height * 0.37
                    clip: true
                    IconCanvas {
                        width: motionIcon.width
                        height: motionIcon.height
                        y: -wifiOuterClip.y
                        iconName: motionIcon.iconName
                        progress: motionIcon.progress
                        lineColor: motionIcon.lineColor
                    }
                }
            }
        }

        Item {
            anchors.fill: parent
            visible: motionIcon.motionActive && motionIcon.utilityKey === "brightness"

            HoverSunRays {
                anchors.fill: parent
                strokeColor: motionIcon.lineColor
                opacity: motionIcon.brightnessRayOpacity
                scale: motionIcon.brightnessRayScale
                rotation: motionIcon.brightnessRayRotation
                transformOrigin: Item.Center
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.34
                height: width
                radius: width / 2
                color: "transparent"
                border.width: Math.max(1, parent.width * 0.07)
                border.color: motionIcon.lineColor
                antialiasing: true
            }
        }

        // Bluetooth keeps a readable base while clipped highlights travel through it.
        Item {
            anchors.fill: parent
            visible: motionIcon.motionActive && motionIcon.utilityKey === "bluetooth"

            Item {
                id: bluetoothTopClip
                x: 0
                y: 0
                width: parent.width
                height: parent.height * 0.43
                clip: true
                opacity: motionIcon.bluetoothTopOpacity
                IconCanvas {
                    width: motionIcon.width
                    height: motionIcon.height
                    iconName: motionIcon.iconName
                    progress: motionIcon.progress
                    lineColor: motionIcon.lineColor
                }
            }

            Item {
                id: bluetoothCenterClip
                x: 0
                y: parent.height * 0.32
                width: parent.width
                height: parent.height * 0.36
                clip: true
                opacity: motionIcon.bluetoothCenterOpacity
                IconCanvas {
                    width: motionIcon.width
                    height: motionIcon.height
                    y: -bluetoothCenterClip.y
                    iconName: motionIcon.iconName
                    progress: motionIcon.progress
                    lineColor: motionIcon.lineColor
                }
            }

            Item {
                id: bluetoothBottomClip
                x: 0
                y: parent.height * 0.57
                width: parent.width
                height: parent.height * 0.43
                clip: true
                opacity: motionIcon.bluetoothBottomOpacity
                IconCanvas {
                    width: motionIcon.width
                    height: motionIcon.height
                    y: -bluetoothBottomClip.y
                    iconName: motionIcon.iconName
                    progress: motionIcon.progress
                    lineColor: motionIcon.lineColor
                }
            }

            IconCanvas {
                anchors.fill: parent
                opacity: motionIcon.bluetoothPulseScale > 1.001 ? 0.55 : 0
                iconName: motionIcon.iconName
                progress: motionIcon.progress
                lineColor: motionIcon.lineColor
                scale: motionIcon.bluetoothPulseScale
                rotation: motionIcon.bluetoothPulseRotation
                transformOrigin: Item.Center
            }
        }

        // The shimmer is clipped both by the glyph and by the real battery progress.
        Item {
            id: batteryFillClip
            visible: motionIcon.motionActive && motionIcon.utilityKey === "battery" && motionIcon.progress > 0
            x: parent.width * 0.19
            y: 0
            width: Math.max(0, parent.width * 0.56 * Math.max(0, Math.min(1, motionIcon.progress)))
            height: parent.height
            clip: true

            Item {
                id: batterySweepBand
                x: motionIcon.batterySweep * (batteryFillClip.width + width) - width
                width: Math.max(3, motionIcon.width * 0.20)
                height: parent.height
                clip: true
                opacity: 0.52

                IconCanvas {
                    width: motionIcon.width
                    height: motionIcon.height
                    x: -batteryFillClip.x - batterySweepBand.x
                    iconName: motionIcon.iconName
                    progress: motionIcon.progress
                    lineColor: root.alpha(root.ink, 0.94)
                }
            }
        }

        VeloraMaterialIcon {
            anchors.centerIn: parent
            visible: motionIcon.motionActive && motionIcon.utilityKey === "battery" && motionIcon.charging
            width: parent.width * 0.54
            height: width
            iconName: "bolt"
            iconColor: motionIcon.lineColor
            filled: true
            glyphScale: 0.86
            opacity: 0.72
            scale: motionIcon.batteryBoltScale
            transformOrigin: Item.Center
        }

        // Bell body and clapper are separate; the badge remains outside this component.
        Item {
            id: bellSwing
            anchors.fill: parent
            visible: motionIcon.motionActive && motionIcon.utilityKey === "notifications"
            rotation: motionIcon.bellRotation
            transformOrigin: Item.Top

            Item {
                id: bellBodyClip
                x: 0
                y: 0
                width: parent.width
                height: parent.height * 0.76
                clip: true
                IconCanvas {
                    width: motionIcon.width
                    height: motionIcon.height
                    iconName: motionIcon.iconName
                    progress: motionIcon.progress
                    lineColor: motionIcon.lineColor
                }
            }

            Item {
                id: bellClapperMotion
                anchors.fill: parent
                x: -motionIcon.bellRotation / 7

                Item {
                    id: bellClapperClip
                    x: 0
                    y: parent.height * 0.68
                    width: parent.width
                    height: parent.height * 0.32
                    clip: true
                    IconCanvas {
                        width: motionIcon.width
                        height: motionIcon.height
                        y: -bellClapperClip.y
                        iconName: motionIcon.iconName
                        progress: motionIcon.progress
                        lineColor: motionIcon.lineColor
                    }
                }
            }
        }

        IconCanvas {
            anchors.fill: parent
            visible: motionIcon.motionActive && motionIcon.utilityKey === "settings"
            iconName: motionIcon.iconName
            progress: motionIcon.progress
            lineColor: motionIcon.lineColor
            rotation: motionIcon.settingsRotation
            transformOrigin: Item.Center
        }

        NumberAnimation {
            id: badgeReturn
            target: motionIcon
            property: "badgeScale"
            to: 1
            duration: root.hoverExitDuration
            easing.type: Easing.InOutQuad
        }

        ParallelAnimation {
            id: volumeReveal
            SequentialAnimation {
                NumberAnimation { target: motionIcon; property: "volumeWave1Opacity"; to: 1; duration: 160; easing.type: Easing.OutCubic }
            }
            SequentialAnimation {
                NumberAnimation { target: motionIcon; property: "volumeWave1Scale"; to: 1; duration: 160; easing.type: Easing.OutCubic }
            }
            SequentialAnimation {
                PauseAnimation { duration: 90 }
                NumberAnimation { target: motionIcon; property: "volumeWave2Opacity"; to: 1; duration: 160; easing.type: Easing.OutCubic }
            }
            SequentialAnimation {
                PauseAnimation { duration: 90 }
                NumberAnimation { target: motionIcon; property: "volumeWave2Scale"; to: 1; duration: 160; easing.type: Easing.OutCubic }
            }
            SequentialAnimation {
                PauseAnimation { duration: 180 }
                NumberAnimation { target: motionIcon; property: "volumeWave3Opacity"; to: 1; duration: 160; easing.type: Easing.OutCubic }
            }
            SequentialAnimation {
                PauseAnimation { duration: 180 }
                NumberAnimation { target: motionIcon; property: "volumeWave3Scale"; to: 1; duration: 160; easing.type: Easing.OutCubic }
            }
        }

        AnimationController {
            id: volumeRevealController
            animation: volumeReveal
        }

        SequentialAnimation {
            id: volumeLoop
            loops: Animation.Infinite
            ScriptAction { script: motionIcon.resetVisualState(true) }
            PropertyAction { target: volumeRevealController; property: "progress"; value: 0 }
            NumberAnimation { target: volumeRevealController; property: "progress"; to: 1; duration: 340; easing.type: Easing.Linear }
            PauseAnimation { duration: 400 }
            ParallelAnimation {
                NumberAnimation { target: motionIcon; property: "volumeWave1Opacity"; to: 0; duration: 160; easing.type: Easing.InOutQuad }
                NumberAnimation { target: motionIcon; property: "volumeWave2Opacity"; to: 0; duration: 160; easing.type: Easing.InOutQuad }
                NumberAnimation { target: motionIcon; property: "volumeWave3Opacity"; to: 0; duration: 160; easing.type: Easing.InOutQuad }
            }
            PauseAnimation { duration: 100 }
        }

        SequentialAnimation {
            id: muteLoop
            loops: Animation.Infinite
            ScriptAction { script: { motionIcon.muteLineProgress = 0; motionIcon.muteJitter = 0 } }
            ParallelAnimation {
                NumberAnimation { target: motionIcon; property: "muteLineProgress"; to: 1; duration: 360; easing.type: Easing.OutCubic }
                SequentialAnimation {
                    PauseAnimation { duration: 180 }
                    NumberAnimation { target: motionIcon; property: "muteJitter"; to: 1; duration: 70; easing.type: Easing.InOutSine }
                    NumberAnimation { target: motionIcon; property: "muteJitter"; to: -1; duration: 140; easing.type: Easing.InOutSine }
                    NumberAnimation { target: motionIcon; property: "muteJitter"; to: 0; duration: 70; easing.type: Easing.InOutSine }
                }
            }
            PauseAnimation { duration: 400 }
            NumberAnimation { target: motionIcon; property: "muteLineProgress"; to: 0; duration: 160; easing.type: Easing.InOutQuad }
            PauseAnimation { duration: 100 }
        }

        ParallelAnimation {
            id: wifiReveal
            SequentialAnimation {
                NumberAnimation { target: motionIcon; property: "wifiInnerOpacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
            }
            SequentialAnimation {
                NumberAnimation { target: motionIcon; property: "wifiInnerScale"; to: 1; duration: 180; easing.type: Easing.OutCubic }
            }
            SequentialAnimation {
                PauseAnimation { duration: 100 }
                NumberAnimation { target: motionIcon; property: "wifiMiddleOpacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
            }
            SequentialAnimation {
                PauseAnimation { duration: 100 }
                NumberAnimation { target: motionIcon; property: "wifiMiddleScale"; to: 1; duration: 180; easing.type: Easing.OutCubic }
            }
            SequentialAnimation {
                PauseAnimation { duration: 200 }
                NumberAnimation { target: motionIcon; property: "wifiOuterOpacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
            }
            SequentialAnimation {
                PauseAnimation { duration: 200 }
                NumberAnimation { target: motionIcon; property: "wifiOuterScale"; to: 1; duration: 180; easing.type: Easing.OutCubic }
            }
        }

        AnimationController {
            id: wifiRevealController
            animation: wifiReveal
        }

        SequentialAnimation {
            id: wifiLoop
            loops: Animation.Infinite
            ScriptAction { script: motionIcon.resetVisualState(true) }
            PropertyAction { target: wifiRevealController; property: "progress"; value: 0 }
            NumberAnimation { target: wifiRevealController; property: "progress"; to: 1; duration: 380; easing.type: Easing.Linear }
            PauseAnimation { duration: 150 }
            ParallelAnimation {
                NumberAnimation { target: motionIcon; property: "wifiInnerOpacity"; to: 0; duration: 170; easing.type: Easing.InOutQuad }
                NumberAnimation { target: motionIcon; property: "wifiMiddleOpacity"; to: 0; duration: 170; easing.type: Easing.InOutQuad }
                NumberAnimation { target: motionIcon; property: "wifiOuterOpacity"; to: 0; duration: 170; easing.type: Easing.InOutQuad }
            }
            PauseAnimation { duration: 300 }
        }

        SequentialAnimation {
            id: brightnessLoop
            loops: Animation.Infinite
            ParallelAnimation {
                NumberAnimation { target: motionIcon; property: "brightnessRayScale"; to: 1.07; duration: 450; easing.type: Easing.InOutSine }
                NumberAnimation { target: motionIcon; property: "brightnessRayRotation"; to: 8; duration: 450; easing.type: Easing.InOutSine }
                NumberAnimation { target: motionIcon; property: "brightnessRayOpacity"; to: 1; duration: 450; easing.type: Easing.InOutSine }
            }
            ParallelAnimation {
                NumberAnimation { target: motionIcon; property: "brightnessRayScale"; to: 1; duration: 450; easing.type: Easing.InOutSine }
                NumberAnimation { target: motionIcon; property: "brightnessRayRotation"; to: 0; duration: 450; easing.type: Easing.InOutSine }
                NumberAnimation { target: motionIcon; property: "brightnessRayOpacity"; to: 0.72; duration: 450; easing.type: Easing.InOutSine }
            }
            PauseAnimation { duration: 200 }
        }

        SequentialAnimation {
            id: bluetoothLoop
            loops: Animation.Infinite
            NumberAnimation { target: motionIcon; property: "bluetoothTopOpacity"; to: 0.95; duration: 130; easing.type: Easing.OutCubic }
            NumberAnimation { target: motionIcon; property: "bluetoothTopOpacity"; to: 0.12; duration: 90; easing.type: Easing.InOutQuad }
            NumberAnimation { target: motionIcon; property: "bluetoothCenterOpacity"; to: 0.95; duration: 130; easing.type: Easing.OutCubic }
            NumberAnimation { target: motionIcon; property: "bluetoothCenterOpacity"; to: 0.12; duration: 90; easing.type: Easing.InOutQuad }
            NumberAnimation { target: motionIcon; property: "bluetoothBottomOpacity"; to: 0.95; duration: 130; easing.type: Easing.OutCubic }
            NumberAnimation { target: motionIcon; property: "bluetoothBottomOpacity"; to: 0.12; duration: 90; easing.type: Easing.InOutQuad }
            ParallelAnimation {
                NumberAnimation { target: motionIcon; property: "bluetoothPulseScale"; to: 1.05; duration: 150; easing.type: Easing.OutCubic }
                NumberAnimation { target: motionIcon; property: "bluetoothPulseRotation"; to: 3; duration: 150; easing.type: Easing.InOutSine }
            }
            ParallelAnimation {
                NumberAnimation { target: motionIcon; property: "bluetoothPulseScale"; to: 1; duration: 150; easing.type: Easing.InOutQuad }
                NumberAnimation { target: motionIcon; property: "bluetoothPulseRotation"; to: 0; duration: 150; easing.type: Easing.InOutSine }
            }
            PauseAnimation { duration: 140 }
        }

        SequentialAnimation {
            id: batteryLoop
            loops: Animation.Infinite
            ScriptAction { script: motionIcon.batterySweep = -0.35 }
            NumberAnimation { target: motionIcon; property: "batterySweep"; to: 1.25; duration: 900; easing.type: Easing.InOutSine }
            PauseAnimation { duration: 350 }
            ScriptAction { script: motionIcon.batterySweep = -0.35 }
            PauseAnimation { duration: 100 }
        }

        SequentialAnimation {
            id: chargingLoop
            loops: Animation.Infinite
            NumberAnimation { target: motionIcon; property: "batteryBoltScale"; to: 1.06; duration: 300; easing.type: Easing.InOutSine }
            NumberAnimation { target: motionIcon; property: "batteryBoltScale"; to: 0.94; duration: 300; easing.type: Easing.InOutSine }
            NumberAnimation { target: motionIcon; property: "batteryBoltScale"; to: 1; duration: 240; easing.type: Easing.InOutSine }
            PauseAnimation { duration: 360 }
        }

        SequentialAnimation {
            id: bellLoop
            loops: Animation.Infinite
            NumberAnimation { target: motionIcon; property: "bellRotation"; to: -7; duration: 180; easing.type: Easing.InOutSine }
            NumberAnimation { target: motionIcon; property: "bellRotation"; to: 7; duration: 260; easing.type: Easing.InOutSine }
            NumberAnimation { target: motionIcon; property: "bellRotation"; to: -4; duration: 220; easing.type: Easing.InOutSine }
            NumberAnimation { target: motionIcon; property: "bellRotation"; to: 0; duration: 180; easing.type: Easing.InOutSine }
            PauseAnimation { duration: 320 }
        }

        SequentialAnimation {
            id: badgeLoop
            loops: Animation.Infinite
            NumberAnimation { target: motionIcon; property: "badgeScale"; to: 1.08; duration: 180; easing.type: Easing.OutCubic }
            NumberAnimation { target: motionIcon; property: "badgeScale"; to: 1; duration: 180; easing.type: Easing.InOutQuad }
            PauseAnimation { duration: 800 }
        }

        SequentialAnimation {
            id: settingsLoop
            loops: Animation.Infinite
            NumberAnimation { target: motionIcon; property: "settingsRotation"; to: 30; duration: 360; easing.type: Easing.InOutSine }
            NumberAnimation { target: motionIcon; property: "settingsRotation"; to: 0; duration: 400; easing.type: Easing.InOutSine }
            PauseAnimation { duration: 440 }
        }
    }

    component UtilityIconButton: Item {
        id: button

        property string utilityKey: "volume"
        property string iconName: "volume"
        property string badgeText: ""
        property real progress: -1
        property bool selected: false
        property string hoverPopupType: ""
        property string status: "normal"
        property bool flatSurface: false
        readonly property bool hovered: mouse.containsMouse
        readonly property bool motionActive: root.hoverMotionEnabled
            && root.visible
            && button.hovered
            && !root.editMode
        signal clicked(real centerX)

        Layout.preferredWidth: root.utilityButtonWidth
        Layout.preferredHeight: root.topControlHeight
        z: mouse.pressed ? 20 : 0

        function centerX() {
            return button.mapToItem(root, button.width / 2, button.height / 2).x
        }

        function statusColor() {
            if (button.selected)
                return root.pink
            if (button.status === "ok")
                return root.accent
            if (button.status === "error")
                return root.pink
            if (button.status === "off")
                return root.alpha(root.inkSoft, 0.42)
            return root.inkSoft
        }

        Item {
            id: utilityVisual

            anchors.centerIn: parent
            width: root.utilityButtonWidth
            height: root.utilityButtonWidth
            scale: root.hoverMotionEnabled && mouse.pressed ? 0.94 : 1

            Behavior on scale {
                NumberAnimation {
                    duration: mouse.pressed ? 70 : root.hoverExitDuration
                    easing.type: mouse.pressed ? Easing.OutCubic : Easing.InOutQuad
                }
            }

            DropShadow {
                anchors.fill: utilitySurface
                source: utilitySurface
                visible: !button.flatSurface
                horizontalOffset: 0
                verticalOffset: 2
                radius: 5
                samples: 11
                color: Qt.rgba(0, 0, 0, 0.22)
                transparentBorder: true
                z: -1
            }

            Rectangle {
                id: utilitySurface

                anchors.fill: parent
                visible: !button.flatSurface || button.selected || mouse.containsMouse
                radius: button.flatSurface ? 7 : height / 2
                color: button.flatSurface
                    ? (button.selected
                        ? root.alpha(root.accent, 0.18)
                        : (mouse.containsMouse ? root.alpha(root.controlCardHover, 0.68) : "transparent"))
                    : (button.selected
                        ? root.cardActive
                        : (mouse.containsMouse || button.status === "ok" || button.status === "error"
                            ? root.controlCardHover
                            : root.controlCard))
                border.width: button.flatSurface ? (button.selected ? 1 : 0) : 1
                border.color: button.status === "error"
                    ? root.alpha(root.pink, 0.42)
                    : (button.selected ? root.alpha(root.accent, 0.34) : root.controlBorder)

                Behavior on color {
                    ColorAnimation {
                        duration: button.hovered ? root.hoverEnterDuration : root.hoverExitDuration
                        easing.type: button.hovered ? Easing.OutCubic : Easing.InOutQuad
                    }
                }

                Behavior on border.color {
                    ColorAnimation {
                        duration: button.hovered ? root.hoverEnterDuration : root.hoverExitDuration
                        easing.type: button.hovered ? Easing.OutCubic : Easing.InOutQuad
                    }
                }
            }

            SystemHoverIcon {
                id: systemHoverIcon

                anchors.centerIn: parent
                width: root.utilityIconSize
                height: root.utilityIconSize
                utilityKey: button.utilityKey
                iconName: button.iconName
                progress: button.progress
                lineColor: button.statusColor()
                motionActive: button.motionActive
                muted: root.muted
                charging: root.batteryCharging()
            }
        }

        Rectangle {
            visible: button.badgeText.length > 0
            x: parent.width - width + 5
            y: 0
            width: Math.max(14, utilityBadgeLabel.implicitWidth + 7)
            height: 14
            radius: 7
            color: root.cardActive
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.20)
            scale: button.utilityKey === "notifications" ? systemHoverIcon.badgeScale : 1
            transformOrigin: Item.Center

            Text {
                id: utilityBadgeLabel
                anchors.centerIn: parent
                text: button.badgeText
                color: "#ffffff"
                font.family: root.uiFont
                font.pixelSize: Math.round(8 * root.configuredIconScale)
                font.weight: Font.Bold
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            anchors.margins: -5
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked(button.centerX())
        }
    }

    component BatteryPill: Rectangle {
        id: pill

        radius: 8
        color: root.card
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.07)
        antialiasing: true
        scale: mouse.pressed ? 0.96 : (mouse.containsMouse ? 1.035 : 1)

        function centerX() {
            return pill.mapToItem(root, pill.width / 2, pill.height / 2).x
        }

        function batteryPercentText() {
            const value = Math.round(root.batteryLevel() * 100)
            return value > 0 ? String(value) : "50"
        }

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: root.motionHover; easing.type: Easing.OutCubic } }

        IconCanvas {
            anchors.centerIn: parent
            width: Math.round(20 * root.configuredIconScale)
            height: width
            iconName: "battery"
            progress: root.batteryLevel()
            lineColor: root.inkSoft
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.quickPopupRequested("battery", pill.centerX())
        }
    }

    component IconCanvas: Canvas {
        id: canvas

        property string iconName: "search"
        property real progress: -1
        property color lineColor: root.inkSoft

        antialiasing: true
        onIconNameChanged: requestPaint()
        onProgressChanged: requestPaint()
        onLineColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        VeloraMaterialIcon {
            anchors.fill: parent
            z: 2
            iconName: canvas.normalizedName()
            iconColor: canvas.lineColor
            filled: canvas.progress >= 0.50
            glyphScale: 0.94
        }

        function roundedRect(ctx, x, y, w, h, r) {
            const radius = Math.min(r, w / 2, h / 2)
            ctx.beginPath()
            ctx.moveTo(x + radius, y)
            ctx.lineTo(x + w - radius, y)
            ctx.quadraticCurveTo(x + w, y, x + w, y + radius)
            ctx.lineTo(x + w, y + h - radius)
            ctx.quadraticCurveTo(x + w, y + h, x + w - radius, y + h)
            ctx.lineTo(x + radius, y + h)
            ctx.quadraticCurveTo(x, y + h, x, y + h - radius)
            ctx.lineTo(x, y + radius)
            ctx.quadraticCurveTo(x, y, x + radius, y)
            ctx.closePath()
        }

        function normalizedName() {
            if (iconName === "files")
                return "folder"
            if (iconName === "theme")
                return "palette"
            if (iconName === "brightness")
                return "sun"
            if (iconName === "notifications")
                return "bell"
            return iconName
        }

        function colorString(colorValue, opacity) {
            const a = opacity === undefined ? colorValue.a : opacity
            return "rgba("
                + Math.round(colorValue.r * 255) + ", "
                + Math.round(colorValue.g * 255) + ", "
                + Math.round(colorValue.b * 255) + ", "
                + Math.max(0, Math.min(1, a)) + ")"
        }

        function mixedColorString(colorValue, r, g, b, amount, opacity) {
            const t = Math.max(0, Math.min(1, amount))
            const rr = colorValue.r + (r - colorValue.r) * t
            const gg = colorValue.g + (g - colorValue.g) * t
            const bb = colorValue.b + (b - colorValue.b) * t
            const a = opacity === undefined ? colorValue.a : opacity
            return "rgba("
                + Math.round(rr * 255) + ", "
                + Math.round(gg * 255) + ", "
                + Math.round(bb * 255) + ", "
                + Math.max(0, Math.min(1, a)) + ")"
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            return
            const w = width
            const h = height
            const s = Math.min(w, h)
            const cx = w / 2
            const cy = h / 2
            const name = normalizedName()
            const fg = lineColor
            const value = progress >= 0 ? Math.max(0, Math.min(1, progress)) : 1.0

            ctx.reset()
            ctx.clearRect(0, 0, w, h)
            ctx.strokeStyle = fg
            ctx.fillStyle = fg
            ctx.lineWidth = Math.max(1.5, s * 0.085)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            if (name === "clock") {
                ctx.strokeStyle = root.alpha(root.inkSoft, 0.82)
                ctx.lineWidth = Math.max(1.15, w * 0.040)
                ctx.beginPath()
                ctx.arc(cx, cy, w * 0.38, 0, Math.PI * 2)
                ctx.stroke()

                ctx.strokeStyle = root.alpha(root.inkSoft, 0.42)
                ctx.lineWidth = Math.max(0.75, w * 0.020)
                for (let i = 0; i < 12; i += 1) {
                    const a = -Math.PI / 2 + i * Math.PI / 6
                    const outer = w * 0.34
                    const inner = i % 3 === 0 ? w * 0.29 : w * 0.31
                    ctx.beginPath()
                    ctx.moveTo(cx + Math.cos(a) * inner, cy + Math.sin(a) * inner)
                    ctx.lineTo(cx + Math.cos(a) * outer, cy + Math.sin(a) * outer)
                    ctx.stroke()
                }

                ctx.strokeStyle = root.ink
                ctx.lineWidth = Math.max(1.1, w * 0.035)
                ctx.beginPath()
                ctx.moveTo(cx, cy)
                ctx.lineTo(cx + w * 0.15, cy - h * 0.18)
                ctx.moveTo(cx, cy)
                ctx.lineTo(cx - w * 0.03, cy - h * 0.26)
                ctx.stroke()

                ctx.fillStyle = root.ink
                ctx.beginPath()
                ctx.arc(cx, cy, w * 0.035, 0, Math.PI * 2)
                ctx.fill()
            } else if (name === "palette") {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.34, Math.PI * 0.20, Math.PI * 1.95, false)
                ctx.quadraticCurveTo(s * 0.20, s * 0.86, s * 0.48, s * 0.72)
                ctx.stroke()
                for (let i = 0; i < 4; i += 1) {
                    const a = -1.9 + i * 0.78
                    ctx.beginPath()
                    ctx.arc(cx + Math.cos(a) * s * 0.16, cy + Math.sin(a) * s * 0.15, s * 0.026, 0, Math.PI * 2, false)
                    ctx.fill()
                }
            } else if (name === "search") {
                ctx.beginPath()
                ctx.arc(cx - s * 0.07, cy - s * 0.07, s * 0.25, 0, Math.PI * 2, false)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(cx + s * 0.13, cy + s * 0.13)
                ctx.lineTo(cx + s * 0.32, cy + s * 0.32)
                ctx.stroke()
            } else if (name === "grid") {
                ctx.lineWidth = Math.max(1.3, s * 0.065)
                for (let row = 0; row < 2; ++row) {
                    for (let column = 0; column < 2; ++column) {
                        roundedRect(ctx, s * (0.18 + column * 0.36), s * (0.18 + row * 0.36), s * 0.27, s * 0.27, s * 0.055)
                        ctx.stroke()
                    }
                }
            } else if (name === "terminal") {
                ctx.lineWidth = Math.max(1.4, s * 0.070)
                roundedRect(ctx, s * 0.13, s * 0.19, s * 0.74, s * 0.62, s * 0.08)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(s * 0.28, s * 0.39)
                ctx.lineTo(s * 0.40, s * 0.50)
                ctx.lineTo(s * 0.28, s * 0.61)
                ctx.moveTo(s * 0.49, s * 0.62)
                ctx.lineTo(s * 0.68, s * 0.62)
                ctx.stroke()
            } else if (name === "folder") {
                ctx.save()
                ctx.fillStyle = colorString(fg, 0.78)
                roundedRect(ctx, s * 0.16, s * 0.34, s * 0.68, s * 0.44, s * 0.08)
                ctx.fill()
                ctx.fillStyle = mixedColorString(fg, 1, 1, 1, 0.26, 0.86)
                roundedRect(ctx, s * 0.18, s * 0.25, s * 0.31, s * 0.20, s * 0.06)
                ctx.fill()
                ctx.fillStyle = mixedColorString(fg, 1, 1, 1, 0.74, 0.34)
                roundedRect(ctx, s * 0.23, s * 0.43, s * 0.50, s * 0.09, s * 0.04)
                ctx.fill()
                ctx.strokeStyle = mixedColorString(fg, 0, 0, 0, 0.28, 0.58)
                ctx.lineWidth = Math.max(1, s * 0.045)
                roundedRect(ctx, s * 0.16, s * 0.34, s * 0.68, s * 0.44, s * 0.08)
                ctx.stroke()
                ctx.restore()
            } else if (name === "discord") {
                ctx.save()
                ctx.fillStyle = mixedColorString(fg, 1, 1, 1, 0.26, 0.46)
                ctx.strokeStyle = colorString(fg, 0.84)
                ctx.lineWidth = Math.max(1.4, s * 0.070)
                ctx.beginPath()
                ctx.moveTo(s * 0.21, s * 0.45)
                ctx.quadraticCurveTo(s * 0.29, s * 0.27, s * 0.44, s * 0.31)
                ctx.quadraticCurveTo(s * 0.50, s * 0.35, s * 0.56, s * 0.31)
                ctx.quadraticCurveTo(s * 0.71, s * 0.27, s * 0.79, s * 0.45)
                ctx.quadraticCurveTo(s * 0.88, s * 0.62, s * 0.75, s * 0.75)
                ctx.quadraticCurveTo(s * 0.67, s * 0.82, s * 0.57, s * 0.72)
                ctx.quadraticCurveTo(s * 0.50, s * 0.76, s * 0.43, s * 0.72)
                ctx.quadraticCurveTo(s * 0.33, s * 0.82, s * 0.25, s * 0.75)
                ctx.quadraticCurveTo(s * 0.12, s * 0.62, s * 0.21, s * 0.45)
                ctx.closePath()
                ctx.fill()
                ctx.stroke()
                ctx.fillStyle = mixedColorString(fg, 1, 1, 1, 0.72, 0.94)
                ctx.beginPath()
                ctx.arc(s * 0.39, s * 0.53, s * 0.038, 0, Math.PI * 2, false)
                ctx.arc(s * 0.61, s * 0.53, s * 0.038, 0, Math.PI * 2, false)
                ctx.fill()
                ctx.strokeStyle = mixedColorString(fg, 1, 1, 1, 0.68, 0.86)
                ctx.lineWidth = Math.max(1, s * 0.040)
                ctx.beginPath()
                ctx.moveTo(s * 0.35, s * 0.64)
                ctx.quadraticCurveTo(s * 0.50, s * 0.70, s * 0.65, s * 0.64)
                ctx.stroke()
                ctx.restore()
            } else if (name === "browser") {
                ctx.save()
                const grad = ctx.createLinearGradient(s * 0.22, s * 0.18, s * 0.82, s * 0.78)
                grad.addColorStop(0, mixedColorString(fg, 1, 1, 1, 0.34, 0.94))
                grad.addColorStop(0.48, colorString(fg, 0.90))
                grad.addColorStop(1, colorString(root.lilac, 0.82))
                ctx.fillStyle = grad
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.34, 0, Math.PI * 2, false)
                ctx.fill()
                ctx.fillStyle = mixedColorString(fg, 1, 1, 1, 0.58, 0.66)
                ctx.beginPath()
                ctx.arc(cx - s * 0.11, cy - s * 0.06, s * 0.20, Math.PI * 0.12, Math.PI * 1.62, false)
                ctx.lineTo(cx + s * 0.16, cy - s * 0.16)
                ctx.closePath()
                ctx.fill()
                ctx.fillStyle = colorString(root.lilac, 0.78)
                ctx.beginPath()
                ctx.arc(cx + s * 0.04, cy + s * 0.05, s * 0.16, 0, Math.PI * 2, false)
                ctx.fill()
                ctx.restore()
            } else if (name === "volume" || name === "volume-muted") {
                ctx.beginPath()
                ctx.moveTo(s * 0.16, s * 0.43)
                ctx.lineTo(s * 0.32, s * 0.43)
                ctx.lineTo(s * 0.52, s * 0.27)
                ctx.lineTo(s * 0.52, s * 0.73)
                ctx.lineTo(s * 0.32, s * 0.57)
                ctx.lineTo(s * 0.16, s * 0.57)
                ctx.closePath()
                ctx.stroke()
                if (name === "volume-muted") {
                    ctx.beginPath()
                    ctx.moveTo(s * 0.66, s * 0.40)
                    ctx.lineTo(s * 0.84, s * 0.58)
                    ctx.moveTo(s * 0.84, s * 0.40)
                    ctx.lineTo(s * 0.66, s * 0.58)
                    ctx.stroke()
                } else {
                    ctx.beginPath()
                    ctx.arc(s * 0.55, s * 0.50, s * (0.14 + value * 0.10), Math.PI * 1.68, Math.PI * 0.32, false)
                    ctx.stroke()
                }
            } else if (name === "wifi") {
                for (let i = 0; i < 3; i += 1) {
                    ctx.globalAlpha = 0.52 + i * 0.14
                    ctx.beginPath()
                    ctx.arc(cx, cy + s * 0.16, s * (0.16 + i * 0.14), Math.PI * 1.18, Math.PI * 1.82, false)
                    ctx.stroke()
                }
                ctx.globalAlpha = 1
                ctx.beginPath()
                ctx.arc(cx, cy + s * 0.20, s * 0.035, 0, Math.PI * 2, false)
                ctx.fill()
            } else if (name === "sun") {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.16, 0, Math.PI * 2, false)
                ctx.stroke()
                for (let i = 0; i < 8; i += 1) {
                    const a = (i / 8) * Math.PI * 2
                    ctx.beginPath()
                    ctx.moveTo(cx + Math.cos(a) * s * 0.29, cy + Math.sin(a) * s * 0.29)
                    ctx.lineTo(cx + Math.cos(a) * s * 0.40, cy + Math.sin(a) * s * 0.40)
                    ctx.stroke()
                }
            } else if (name === "bell") {
                ctx.beginPath()
                ctx.moveTo(s * 0.29, s * 0.64)
                ctx.lineTo(s * 0.71, s * 0.64)
                ctx.quadraticCurveTo(s * 0.65, s * 0.53, s * 0.65, s * 0.42)
                ctx.quadraticCurveTo(s * 0.65, s * 0.24, s * 0.50, s * 0.24)
                ctx.quadraticCurveTo(s * 0.35, s * 0.24, s * 0.35, s * 0.42)
                ctx.quadraticCurveTo(s * 0.35, s * 0.53, s * 0.29, s * 0.64)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(s * 0.44, s * 0.74)
                ctx.quadraticCurveTo(s * 0.50, s * 0.81, s * 0.56, s * 0.74)
                ctx.stroke()
            } else if (name === "bluetooth") {
                ctx.beginPath()
                ctx.moveTo(cx, s * 0.18)
                ctx.lineTo(s * 0.69, s * 0.35)
                ctx.lineTo(cx, s * 0.50)
                ctx.lineTo(s * 0.69, s * 0.65)
                ctx.lineTo(cx, s * 0.82)
                ctx.lineTo(cx, s * 0.18)
                ctx.moveTo(cx, s * 0.50)
                ctx.lineTo(s * 0.31, s * 0.35)
                ctx.moveTo(cx, s * 0.50)
                ctx.lineTo(s * 0.31, s * 0.65)
                ctx.stroke()
            } else if (name === "settings") {
                ctx.lineWidth = Math.max(1.5, s * 0.070)
                ctx.beginPath()
                for (let i = 0; i < 16; i += 1) {
                    const a = -Math.PI / 2 + (i / 16) * Math.PI * 2
                    const r = i % 2 === 0 ? s * 0.38 : s * 0.30
                    const x = cx + Math.cos(a) * r
                    const y = cy + Math.sin(a) * r
                    if (i === 0)
                        ctx.moveTo(x, y)
                    else
                        ctx.lineTo(x, y)
                }
                ctx.closePath()
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.13, 0, Math.PI * 2, false)
                ctx.stroke()
            } else if (name === "display") {
                ctx.save()
                ctx.strokeStyle = colorString(fg, 0.86)
                ctx.lineWidth = Math.max(1.35, s * 0.060)
                roundedRect(ctx, s * 0.18, s * 0.22, s * 0.64, s * 0.45, s * 0.07)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(cx, s * 0.67)
                ctx.lineTo(cx, s * 0.79)
                ctx.moveTo(s * 0.40, s * 0.80)
                ctx.lineTo(s * 0.60, s * 0.80)
                ctx.stroke()
                ctx.lineWidth = Math.max(1.1, s * 0.048)
                ctx.globalAlpha = 0.80
                ctx.beginPath()
                ctx.moveTo(cx, s * 0.31)
                ctx.lineTo(cx, s * 0.22)
                ctx.moveTo(cx, s * 0.58)
                ctx.lineTo(cx, s * 0.67)
                ctx.moveTo(s * 0.30, s * 0.445)
                ctx.lineTo(s * 0.18, s * 0.445)
                ctx.moveTo(s * 0.70, s * 0.445)
                ctx.lineTo(s * 0.82, s * 0.445)
                ctx.stroke()
                ctx.restore()
            } else if (name === "battery") {
                const level = progress >= 0 ? Math.max(0, Math.min(1, progress)) : 0.70
                const bodyX = s * 0.19
                const bodyY = s * 0.34
                const bodyW = s * 0.56
                const bodyH = s * 0.32
                const capW = s * 0.07
                const capH = s * 0.14
                const pad = s * 0.055
                const fillW = Math.max(0, (bodyW - pad * 2) * level)

                ctx.lineWidth = Math.max(1.4, s * 0.060)
                roundedRect(ctx, bodyX, bodyY, bodyW, bodyH, s * 0.070)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(bodyX + bodyW, cy - capH / 2)
                ctx.lineTo(bodyX + bodyW + capW, cy - capH / 2)
                ctx.lineTo(bodyX + bodyW + capW, cy + capH / 2)
                ctx.lineTo(bodyX + bodyW, cy + capH / 2)
                ctx.stroke()

                if (fillW > 0) {
                    ctx.fillStyle = colorString(fg, level <= 0.18 ? 0.52 : 0.74)
                    roundedRect(ctx, bodyX + pad, bodyY + pad, fillW, bodyH - pad * 2, s * 0.042)
                    ctx.fill()
                }
            } else {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.28, 0, Math.PI * 2, false)
                ctx.stroke()
            }
        }
    }
}
