import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.UPower

Item {
    id: root

    property var theme: null
    property alias panelMaskItem: panelSurface
    readonly property bool rightSoft: theme && theme.barPosition === "right"
    readonly property bool rightDark: rightSoft && theme && theme.themeMode === "dark"
    readonly property bool softStyle: true
    readonly property bool darkSoft: softStyle && theme && theme.themeMode === "dark"
    readonly property int cornerRadius: softStyle ? 24 : 20
    readonly property bool pywalStyle: theme && theme.themeId === "pywal16"
    readonly property bool neon: pywalStyle && theme.themeMode === "dark"
    readonly property color ink: theme ? theme.textPrimary : Qt.rgba(0.46, 0.37, 0.54, 0.82)
    readonly property color inkSoft: theme ? theme.textSecondary : Qt.rgba(0.58, 0.48, 0.64, 0.62)
    readonly property color pink: theme ? (pywalStyle ? theme.accentSecondary : theme.accentPrimary) : Qt.rgba(0.88, 0.45, 0.66, 0.86)
    readonly property color lilac: theme ? (pywalStyle ? theme.accentPrimary : theme.accentSecondary) : Qt.rgba(0.58, 0.47, 0.76, 0.78)
    readonly property bool popupAttached: activePopupType.length > 0
    readonly property real barGlassAlpha: theme
        ? Math.max(theme.minOpacityForRole("sidebar"), Math.min(theme.barOpacity, 0.98))
        : 0.66
    readonly property color glass: theme
        ? theme.withAlpha(theme.surfaceSidebar, barGlassAlpha)
        : Qt.rgba(1, 0.988, 0.997, 0.66)
    readonly property color card: theme
        ? (darkSoft ? theme.withAlpha(theme.surfaceCard, Math.min(theme.surfaceCard.a, 0.62)) : theme.surfaceCard)
        : Qt.rgba(1, 1, 1, 0.70)
    readonly property color borderSoft: theme ? (pywalStyle ? theme.withAlpha(theme.sidebarBorderGlow, Math.min(0.18, Math.max(0.08, theme.sidebarBorderGlow.a * 0.50))) : theme.withAlpha(theme.borderSoft, theme.themeMode === "dark" ? 0.11 : 0.26)) : Qt.rgba(1, 1, 1, 0.26)
    readonly property string uiFont: theme ? theme.uiFont : "Noto Sans CJK JP"
    readonly property string monoFont: theme ? theme.monoFont : "JetBrainsMono Nerd Font"
    readonly property int motionFast: theme ? theme.motionFast : 120
    readonly property int motionNormal: theme ? theme.motionNormal : 200
    readonly property int motionHover: theme ? theme.motionHover : 120
    readonly property int motionEaseHover: theme ? theme.motionEaseHover : Easing.OutCubic
    property int notificationCountOverride: -1
    readonly property int notificationCount: notificationCountOverride >= 0 ? notificationCountOverride : Math.max(trackedNotificationValues().length, makoNotificationCount)
    readonly property real uiScale: softStyle ? Math.min(1.08, Math.max(1.0, height / 1080)) : Math.min(1.12, Math.max(1.0, height / 1032))
    readonly property int stretchGap: Math.round(Math.min(softStyle ? 10 : 14, Math.max(0, (height - (softStyle ? 1080 : 1032)) / 7)))
    property int makoNotificationCount: 0
    property int lastNotificationCount: 0
    property real notificationRingAngle: 0
    property string clockText: Qt.formatDateTime(new Date(), "HH:mm")
    property string dateText: formatLocalizedDate(new Date())
    property var batteryDevice: null
    property int volume: 70
    property bool muted: false
    property bool focusMode: false
    property int focusIndex: 0
    property string focusTarget: "clock"
    property string activePopupType: ""
    property real focusX: 0
    property real focusY: 0
    property real focusW: 42
    property real focusH: 34
    property bool visualizerActive: true
    property bool shellDrawsPanelSurface: false
    property var cavaValues: []
    property int cavaSettledFrames: 0
    property int cavaSkippedFrames: 0
    readonly property int cavaBandCount: 28
    readonly property real cavaSettledDelta: 0.010
    readonly property int cavaSettleFrameThreshold: 6
    readonly property int cavaMaxSkippedFrames: 14
    readonly property bool cavaWanted: visualizerActive && visible && width > 0 && height > 0
    readonly property string cavaScript: Quickshell.shellDir + "/scripts/velora-cava"
    readonly property string popupStatusScript: Quickshell.shellDir + "/scripts/velora-popup-status"

    function trackedNotificationValues() {
        const tracked = NotificationServer.trackedNotifications
        return tracked && tracked.values ? tracked.values : []
    }

    onNotificationCountChanged: {
        if (notificationCount > lastNotificationCount) {
            notificationRingAnimation.stop()
            notificationRingAnimation.restart()
        }

        lastNotificationCount = notificationCount
    }

    property var trailSegments: []
    property string focusActionCommand: ""
    property string hoverProbeType: ""
    readonly property real focusPad: 4
    readonly property real trailSpeed: 0.05
    readonly property real trailTailDelay: 0.30
    readonly property real trailFade: 0.12
    readonly property real trailOpacity: 0.22
    signal themeRequested(real centerY)
    signal settingsRequested(real centerY)
    signal layoutRequested(real centerY)
    signal quickPopupRequested(string popupType, real centerY)
    signal quickPopupHovered(string popupType, real centerY)
    signal quickPopupHoverEnded(string popupType)
    signal moveFocusRequested(int dir)
    signal exitFocusRequested()

    function alpha(colorValue, opacity) {
        return root.theme ? root.theme.alpha(colorValue, opacity) : Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacity)
    }

    function fontGlowEnabled() {
        return root.theme && root.theme.textGlow.a > 0.001
    }

    component FontGlowEffect: MultiEffect {
        shadowEnabled: true
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        shadowColor: root.theme ? root.theme.textGlow : Qt.rgba(0, 0, 0, 0)
        shadowOpacity: root.theme ? Math.min(1, 0.34 + root.theme.textGlowLevel * 0.66) : 0
        shadowBlur: root.theme ? Math.min(1, 0.24 + root.theme.textGlowLevel * 0.72) : 0
        blurMax: root.theme ? Math.round(12 + root.theme.textGlowLevel * 22) : 12
        autoPaddingEnabled: true
    }

    function itemCenterY(item) {
        if (!item)
            return height / 2

        const point = item.mapToItem(root, item.width / 2, item.height / 2)
        return Math.round(point.y)
    }

    function itemContainsY(item, y, pad) {
        if (!item)
            return false

        const point = item.mapToItem(root, 0, 0)
        return y >= point.y - pad && y <= point.y + item.height + pad
    }

    function popupProbeAt(y) {
        const pad = Math.round(4 * root.uiScale)
        const probes = [
            { item: slotClock, type: "time" },
            { item: slotSearch, type: "search" },
            { item: slotVolume, type: "volume" },
            { item: slotWifi, type: "wifi" },
            { item: slotBrightness, type: "brightness" },
            { item: slotNotifications, type: "notifications" },
            { item: slotBluetooth, type: "bluetooth" },
            { item: slotBattery, type: "battery" },
            { item: slotAvatar, type: "profile" }
        ]

        for (let i = 0; i < probes.length; i += 1) {
            const probe = probes[i]

            if (itemContainsY(probe.item, y, pad))
                return probe
        }

        return null
    }

    function updateHoverProbe(y) {
        const probe = popupProbeAt(y)

        if (probe) {
            hoverProbeType = probe.type
            root.quickPopupHovered(probe.type, root.itemCenterY(probe.item))
            return
        }

        clearHoverProbe()
    }

    function clearHoverProbe() {
        if (hoverProbeType.length > 0) {
            const previous = hoverProbeType
            hoverProbeType = ""
            root.quickPopupHoverEnded(previous)
        }
    }

    function notificationBadgeText() {
        if (notificationCount <= 0)
            return ""

        return notificationCount > 99 ? "99+" : String(notificationCount)
    }

    function normalizedBatteryLevel() {
        if (!batteryDevice || !batteryDevice.ready)
            return 0

        const value = Number(batteryDevice.percentage)
        if (isNaN(value))
            return 0

        return Math.max(0, Math.min(1, value > 1 ? value / 100 : value))
    }

    function visualizerValue(index) {
        if (!cavaValues || cavaValues.length <= 0)
            return 0.06

        const value = Number(cavaValues[Math.max(0, Math.min(index, cavaValues.length - 1))])
        return Math.max(0.06, Math.min(1, isNaN(value) ? 0.06 : value))
    }

    function syncCavaProcess() {
        if (typeof cavaProcess === "undefined" || typeof cavaRestartTimer === "undefined")
            return

        if (root.cavaWanted) {
            if (!cavaProcess.running)
                cavaProcess.running = true
            return
        }

        cavaRestartTimer.stop()
        if (cavaProcess.running)
            cavaProcess.running = false
    }

    function parseCavaLine(data) {
        var text = String(data || "")
        text = text.replace(/\x1b\][^\x07]*\x07/g, "")
        const parts = text.split(";")
        var next = []

        for (var i = 0; i < parts.length; ++i) {
            const raw = parts[i].trim()
            if (raw.length <= 0)
                continue

            const parsed = parseInt(raw)
            if (!isNaN(parsed))
                next.push(Math.max(0, Math.min(1, parsed / 1000)))
        }

        if (next.length <= 0)
            return

        while (next.length > root.cavaBandCount)
            next.shift()

        while (next.length < root.cavaBandCount)
            next.push(0.06)

        const previous = root.cavaValues || []
        if (previous.length === next.length) {
            var maxDelta = 0
            for (var j = 0; j < next.length; ++j)
                maxDelta = Math.max(maxDelta, Math.abs(Number(previous[j]) - next[j]))

            if (maxDelta < root.cavaSettledDelta) {
                root.cavaSettledFrames += 1
                if (root.cavaSettledFrames >= root.cavaSettleFrameThreshold
                        && root.cavaSkippedFrames < root.cavaMaxSkippedFrames) {
                    root.cavaSkippedFrames += 1
                    return
                }
            } else {
                root.cavaSettledFrames = 0
            }
        } else {
            root.cavaSettledFrames = 0
        }

        root.cavaSkippedFrames = 0
        root.cavaValues = next
    }

    onCavaWantedChanged: syncCavaProcess()
    onVisualizerActiveChanged: {
        if (!visualizerActive) {
            cavaValues = []
            cavaSettledFrames = 0
            cavaSkippedFrames = 0
        }

        syncCavaProcess()
    }

    readonly property string themeCommand: "if command -v nwg-look >/dev/null 2>&1; then nwg-look >/dev/null 2>&1 & elif command -v qt6ct >/dev/null 2>&1; then qt6ct >/dev/null 2>&1 & fi"
    readonly property string searchCommand: "if command -v wofi >/dev/null 2>&1; then pkill wofi 2>/dev/null; wofi --show drun --prompt 検索 >/dev/null 2>&1 & elif command -v rofi >/dev/null 2>&1; then rofi -show drun >/dev/null 2>&1 & fi"
    readonly property string filesCommand: "if command -v dolphin >/dev/null 2>&1; then dolphin \"$HOME\" >/dev/null 2>&1 & elif command -v thunar >/dev/null 2>&1; then thunar \"$HOME\" >/dev/null 2>&1 & else xdg-open \"$HOME\" >/dev/null 2>&1 & fi"
    readonly property string terminalCommand: "if command -v kitty >/dev/null 2>&1; then kitty >/dev/null 2>&1 & elif command -v foot >/dev/null 2>&1; then foot >/dev/null 2>&1 & elif command -v alacritty >/dev/null 2>&1; then alacritty >/dev/null 2>&1 & fi"
    readonly property string browserCommand: "if command -v zen-browser >/dev/null 2>&1; then zen-browser >/dev/null 2>&1 & elif command -v firefox >/dev/null 2>&1; then firefox >/dev/null 2>&1 & fi"
    readonly property string discordCommand: "if command -v discord >/dev/null 2>&1; then discord >/dev/null 2>&1 & elif command -v vesktop >/dev/null 2>&1; then vesktop >/dev/null 2>&1 & elif command -v webcord >/dev/null 2>&1; then webcord >/dev/null 2>&1 & fi"
    readonly property string brightnessCommand: "if command -v brightnessctl >/dev/null 2>&1; then brightnessctl set +10% >/dev/null 2>&1; elif command -v light >/dev/null 2>&1; then light -A 10 >/dev/null 2>&1; fi"
    readonly property string settingsCommand: "if command -v systemsettings >/dev/null 2>&1; then systemsettings >/dev/null 2>&1 & elif command -v gnome-control-center >/dev/null 2>&1; then gnome-control-center >/dev/null 2>&1 & elif command -v nwg-look >/dev/null 2>&1; then nwg-look >/dev/null 2>&1 & fi"

    focus: root.focusMode

    function clamp01(v) {
        return Math.max(0, Math.min(1, v))
    }

    function lerp(a, b, t) {
        return a + (b - a) * t
    }

    function emphasizedDecel(t) {
        t = clamp01(t)
        return 1 - Math.pow(1 - t, 3.0)
    }

    function focusSlot() {
        if (focusTarget === "search") return slotSearch
        if (focusTarget === "workspace1") return slotWorkspace1
        if (focusTarget === "workspace2") return slotWorkspace2
        if (focusTarget === "workspace3") return slotWorkspace3
        if (focusTarget === "workspace4") return slotWorkspace4
        if (focusTarget === "files") return slotFiles
        if (focusTarget === "browser") return slotBrowser
        if (focusTarget === "discord") return slotDiscord
        if (focusTarget === "volume") return slotVolume
        if (focusTarget === "wifi") return slotWifi
        if (focusTarget === "brightness") return slotBrightness
        if (focusTarget === "notifications") return slotNotifications
        if (focusTarget === "bluetooth") return slotBluetooth
        if (focusTarget === "battery") return slotBattery
        if (focusTarget === "settings") return slotSettings
        if (focusTarget === "layout") return slotLayout
        if (focusTarget === "avatar") return slotAvatar
        return slotClock
    }

    function measureSlot(slot) {
        if (!slot)
            return { x: 0, y: 0, w: 42, h: 34 }

        const p = slot.mapToItem(root, 0, 0)
        const w = Math.max(18, slot.width)
        const h = Math.max(18, slot.height)

        return {
            x: Math.round(p.x - focusPad),
            y: Math.round(p.y - focusPad),
            w: Math.round(w + focusPad * 2),
            h: Math.round(h + focusPad * 2)
        }
    }

    function rectAt(oldR, newR, t) {
        return {
            x: lerp(oldR.x, newR.x, t),
            y: lerp(oldR.y, newR.y, t),
            w: lerp(oldR.w, newR.w, t),
            h: lerp(oldR.h, newR.h, t)
        }
    }

    function capsuleBetween(a, b) {
        const left = Math.min(a.x, b.x)
        const right = Math.max(a.x + a.w, b.x + b.w)
        const top = Math.min(a.y, b.y)
        const bottom = Math.max(a.y + a.h, b.y + b.h)

        return {
            x: Math.round(left),
            y: Math.round(top),
            w: Math.round(right - left),
            h: Math.round(bottom - top)
        }
    }

    function setFocusRectFromCurrent() {
        const r = measureSlot(focusSlot())
        focusX = r.x
        focusY = r.y
        focusW = r.w
        focusH = r.h
    }

    function pushElasticTrail(oldR, newR) {
        const arr = trailSegments.slice()

        arr.unshift({
            oldX: oldR.x,
            oldY: oldR.y,
            oldW: oldR.w,
            oldH: oldR.h,
            newX: newR.x,
            newY: newR.y,
            newW: newR.w,
            newH: newR.h,
            raw: 0.0,
            life: 1.0,
            x: oldR.x,
            y: oldR.y,
            w: oldR.w,
            h: oldR.h
        })

        while (arr.length > 2)
            arr.pop()

        trailSegments = arr
    }

    function requestMoveFocus(dir) {
        const oldR = {
            x: focusX,
            y: focusY,
            w: focusW,
            h: focusH
        }

        root.moveFocusRequested(dir)

        Qt.callLater(function() {
            const newR = measureSlot(focusSlot())
            pushElasticTrail(oldR, newR)
            focusX = newR.x
            focusY = newR.y
            focusW = newR.w
            focusH = newR.h
        })
    }

    function runFocusCommand(command) {
        if (command.length === 0)
            return

        focusActionCommand = command
        if (!focusActionProcess.running)
            focusActionProcess.running = true

        root.exitFocusRequested()
    }

    function activateFocused() {
        if (focusTarget === "search") {
            root.quickPopupRequested("search", root.itemCenterY(slotSearch))
            return
        }

        if (focusTarget.indexOf("workspace") === 0) {
            Hyprland.dispatch("workspace " + focusTarget.replace("workspace", ""))
            root.exitFocusRequested()
            return
        }

        if (focusTarget === "files") {
            runFocusCommand(filesCommand)
            return
        }

        if (focusTarget === "browser") {
            runFocusCommand(browserCommand)
            return
        }

        if (focusTarget === "discord") {
            runFocusCommand(discordCommand)
            return
        }

        if (focusTarget === "volume") {
            root.quickPopupRequested("volume", root.itemCenterY(slotVolume))
            return
        }

        if (focusTarget === "wifi") {
            root.quickPopupRequested("wifi", root.itemCenterY(slotWifi))
            return
        }

        if (focusTarget === "brightness") {
            root.quickPopupRequested("brightness", root.itemCenterY(slotBrightness))
            return
        }

        if (focusTarget === "notifications") {
            root.quickPopupRequested("notifications", root.itemCenterY(slotNotifications))
            return
        }

        if (focusTarget === "bluetooth") {
            root.quickPopupRequested("bluetooth", root.itemCenterY(slotBluetooth))
            return
        }

        if (focusTarget === "battery") {
            root.quickPopupRequested("battery", root.itemCenterY(slotBattery))
            return
        }

        if (focusTarget === "settings") {
            root.settingsRequested(root.itemCenterY(slotSettings))
            root.exitFocusRequested()
            return
        }

        if (focusTarget === "layout") {
            root.layoutRequested(root.itemCenterY(slotLayout))
            root.exitFocusRequested()
            return
        }

        if (focusTarget === "avatar") {
            root.quickPopupRequested("profile", root.itemCenterY(slotAvatar))
            return
        }

        if (focusTarget === "clock") {
            root.quickPopupRequested("time", root.itemCenterY(slotClock))
            return
        }
    }

    function tr(key) {
        const lang = root.theme ? root.theme.language : "pt-BR"
        const texts = {
            "ja": {
                "tools": "ツール",
                "theme": "テーマ",
                "search": "検索",
                "workspaces": "ワークスペース",
                "apps": "アプリ",
                "utilities": "ユーティリティ"
            },
            "en": {
                "tools": "Tools",
                "theme": "Theme",
                "search": "Search",
                "workspaces": "Workspaces",
                "apps": "Apps",
                "utilities": "Utilities"
            },
            "pt-BR": {
                "tools": "Ferramentas",
                "theme": "Tema",
                "search": "Busca",
                "workspaces": "Áreas",
                "apps": "Apps",
                "utilities": "Utilitários"
            }
        }
        const table = texts[lang] || texts["pt-BR"]
        return table[key] || texts["pt-BR"][key] || key
    }

    function formatLocalizedDate(date) {
        const lang = root.theme ? root.theme.language : "pt-BR"
        if (lang === "en") {
            const weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            return (date.getMonth() + 1) + "/" + date.getDate() + " (" + weekdays[date.getDay()] + ")"
        }
        if (lang === "pt-BR") {
            const weekdays = ["dom", "seg", "ter", "qua", "qui", "sex", "sab"]
            return date.getDate() + "/" + (date.getMonth() + 1) + " (" + weekdays[date.getDay()] + ")"
        }
        const weekdays = ["日", "月", "火", "水", "木", "金", "土"]
        return (date.getMonth() + 1) + "月" + date.getDate() + "日 (" + weekdays[date.getDay()] + ")"
    }

    function updateClockText() {
        const now = new Date()
        root.clockText = Qt.formatDateTime(now, "HH:mm")
        root.dateText = root.formatLocalizedDate(now)
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

    SequentialAnimation {
        id: notificationRingAnimation

        NumberAnimation { target: root; property: "notificationRingAngle"; to: -14; duration: 45; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "notificationRingAngle"; to: 12; duration: 55; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "notificationRingAngle"; to: -9; duration: 55; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "notificationRingAngle"; to: 6; duration: 55; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "notificationRingAngle"; to: 0; duration: 90; easing.type: Easing.OutCubic }
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
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!notificationCountQuery.running)
                notificationCountQuery.running = true
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.pickBattery()
            if (!volumeQuery.running)
                volumeQuery.running = true
        }
    }

    Process {
        id: volumeQuery

        running: false
        command: [root.popupStatusScript, "audio"]

        stdout: SplitParser {
            onRead: function(data) {
                const parts = data.trim().split("|")
                if (parts.length < 3 || parts[0] !== "AUDIO_SINK")
                    return

                const value = parseFloat(parts[1])
                if (!isNaN(value))
                    root.volume = Math.max(0, Math.min(100, Math.round(value * 100)))
                root.muted = parts[2] === "1"
            }
        }

        onExited: running = false
    }

    Process {
        id: notificationCountQuery

        running: false
        command: [root.popupStatusScript, "notification-count"]

        stdout: SplitParser {
            onRead: function(data) {
                const value = parseInt(data.trim())
                root.makoNotificationCount = isNaN(value) ? 0 : Math.max(0, value)
            }
        }

        onExited: running = false
    }

    Process {
        id: focusActionProcess

        running: false
        command: ["bash", "-lc", root.focusActionCommand]
        onExited: running = false
    }

    Process {
        id: cavaProcess

        running: false
        command: [root.cavaScript, String(root.cavaBandCount)]

        stdout: SplitParser {
            onRead: function(data) {
                root.parseCavaLine(data)
            }
        }

        onExited: {
            running = false
            if (root.cavaWanted)
                cavaRestartTimer.restart()
        }
    }

    Timer {
        id: cavaRestartTimer

        interval: 1600
        repeat: false
        onTriggered: {
            if (root.cavaWanted && !cavaProcess.running)
                cavaProcess.running = true
        }
    }

    Timer {
        id: trailTimer

        interval: 16
        repeat: true
        running: root.focusMode || root.trailSegments.length > 0

        onTriggered: {
            const arr = root.trailSegments.slice()

            for (let i = 0; i < arr.length; i += 1) {
                const s = arr[i]

                if (s.raw < 1.0)
                    s.raw = Math.min(1.0, s.raw + root.trailSpeed)
                else
                    s.life = Math.max(0.0, s.life - root.trailFade)

                const oldR = { x: s.oldX, y: s.oldY, w: s.oldW, h: s.oldH }
                const newR = { x: s.newX, y: s.newY, w: s.newW, h: s.newH }
                const headT = root.emphasizedDecel(s.raw)
                const tailRaw = Math.max(0.0, (s.raw - root.trailTailDelay) / (1.0 - root.trailTailDelay))
                const tailT = root.emphasizedDecel(tailRaw)
                const head = root.rectAt(oldR, newR, headT)
                const tail = root.rectAt(oldR, newR, tailT)
                const cap = root.capsuleBetween(tail, head)

                s.x = cap.x
                s.y = cap.y
                s.w = cap.w
                s.h = cap.h
            }

            root.trailSegments = arr.filter(function(s) {
                return s.life > 0.02
            })
        }
    }

    onFocusModeChanged: {
        if (focusMode) {
            Qt.callLater(function() {
                root.forceActiveFocus()
                root.trailSegments = []
                root.setFocusRectFromCurrent()
            })
        } else {
            root.trailSegments = []
        }
    }

    onFocusIndexChanged: {
        if (focusMode)
            Qt.callLater(function() {
                root.setFocusRectFromCurrent()
            })
    }

    onFocusTargetChanged: {
        if (focusMode)
            Qt.callLater(function() {
                root.setFocusRectFromCurrent()
            })
    }

    onWidthChanged: Qt.callLater(function() {
        root.setFocusRectFromCurrent()
    })
    onHeightChanged: Qt.callLater(function() {
        root.setFocusRectFromCurrent()
    })
    Component.onCompleted: Qt.callLater(function() {
        root.setFocusRectFromCurrent()
        root.syncCavaProcess()
        root.updateClockText()
    })

    Keys.onEscapePressed: root.exitFocusRequested()
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Up || event.key === Qt.Key_W) {
            root.requestMoveFocus(-1)
            event.accepted = true
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_S) {
            root.requestMoveFocus(1)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.activateFocused()
            event.accepted = true
        }
    }

    Rectangle {
        x: panelSurface.x + 4
        y: panelSurface.y + 12
        width: panelSurface.width
        height: panelSurface.height - 8
        radius: root.cornerRadius + 2
        visible: !root.shellDrawsPanelSurface
        color: root.softStyle
            ? root.alpha(root.theme ? root.theme.shadowColor : Qt.rgba(0, 0, 0, 1), root.popupAttached ? 0 : (root.darkSoft ? 0.16 : 0.08))
            : root.alpha(root.theme ? root.theme.shadowColor : Qt.rgba(0.56, 0.36, 0.52, 1), root.popupAttached ? 0 : (root.pywalStyle && root.theme ? 0.035 + root.theme.generalGlow * 0.02 : 0.07))
    }

    Rectangle {
        id: panelSurface

        anchors.fill: parent
        radius: root.cornerRadius
        color: root.shellDrawsPanelSurface ? "transparent" : root.glass
        border.width: root.shellDrawsPanelSurface || root.popupAttached ? 0 : 1
        border.color: root.softStyle
            ? root.borderSoft
            : root.pywalStyle && root.theme
            ? root.alpha(root.theme.popupBorderGlow, root.popupAttached ? root.theme.popupBorderGlow.a * 0.26 : root.theme.sidebarBorderGlow.a)
            : root.alpha(root.borderSoft, root.popupAttached ? 0.34 : root.borderSoft.a)
        clip: true
        antialiasing: true
        layer.enabled: !root.shellDrawsPanelSurface && !root.popupAttached && (!root.pywalStyle || (root.theme && root.theme.sidebarBorderGlow.a > 0.001))
        layer.effect: DropShadow {
            transparentBorder: true
            radius: root.pywalStyle ? 34 : 34
            samples: root.pywalStyle ? 69 : 65
            horizontalOffset: 0
            verticalOffset: root.softStyle ? 7 : (root.pywalStyle ? 0 : 11)
            color: root.softStyle
                ? root.alpha(root.theme ? root.theme.shadowColor : Qt.rgba(0, 0, 0, 1), root.popupAttached ? 0.03 : (root.darkSoft ? 0.20 : 0.11))
                : root.pywalStyle && root.theme
                ? root.alpha(root.theme.popupBorderGlow, root.theme.popupBorderGlow.a * (root.popupAttached ? 0.08 : 0.50))
                : root.alpha(root.theme ? root.theme.shadowColor : Qt.rgba(0.38, 0.25, 0.42, 1), root.popupAttached ? 0.035 : 0.15)
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: !root.shellDrawsPanelSurface && !root.popupAttached
            color: root.alpha(root.card, 0.18)
        }

        Rectangle {
            anchors {
                fill: parent
                margins: 1
            }

            radius: parent.radius - 1
            color: "transparent"
            visible: !root.shellDrawsPanelSurface && !root.popupAttached
            border.width: 1
            border.color: root.softStyle
                ? (root.darkSoft ? Qt.rgba(1, 1, 1, 0.055) : root.alpha(root.borderSoft, 0.30))
                : root.pywalStyle && root.theme
                ? root.alpha(root.theme.popupBorderGlow, root.theme.popupBorderGlow.a * (root.popupAttached ? 0.16 : 0.58))
                : root.alpha(root.borderSoft, root.popupAttached ? 0.12 : 0.28)
        }

    }

    ColumnLayout {
        id: contentLayer
        z: 10

        anchors {
            fill: panelSurface
            leftMargin: root.softStyle ? 17 : 16
            rightMargin: root.softStyle ? 17 : 16
            topMargin: root.softStyle ? Math.round(20 * root.uiScale) : Math.round(18 * root.uiScale)
            bottomMargin: root.softStyle ? Math.round(18 * root.uiScale) : Math.round(14 * root.uiScale)
        }

        spacing: 0

        ClockBlock {
            id: slotClock

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 72
            Layout.preferredHeight: Math.round(110 * root.uiScale)
        }

        Divider {
            Layout.fillWidth: true
            Layout.topMargin: Math.round(13 * root.uiScale) + Math.round(root.stretchGap * 0.35)
            Layout.bottomMargin: Math.round(13 * root.uiScale) + Math.round(root.stretchGap * 0.35)
        }

        SectionLabel {
            Layout.fillWidth: true
            text: root.tr("tools")
        }

        ToolRow {
            id: slotSearch

            Layout.fillWidth: true
            Layout.topMargin: Math.round(8 * root.uiScale)
            label: root.tr("search")
            iconName: "search"
            selected: root.activePopupType === "search"
            command: ""
            hoverPopupType: "search"
            onTriggered: root.quickPopupRequested("search", root.itemCenterY(slotSearch))
        }

        Divider {
            Layout.fillWidth: true
            Layout.topMargin: Math.round(15 * root.uiScale) + root.stretchGap
            Layout.bottomMargin: Math.round(13 * root.uiScale)
        }

        SectionLabel {
            Layout.fillWidth: true
            text: root.tr("workspaces")
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Math.round(8 * root.uiScale)
            spacing: Math.round(6 * root.uiScale)

            WorkspaceButton {
                id: slotWorkspace1

                Layout.preferredWidth: 66
                Layout.preferredHeight: Math.round(32 * root.uiScale)
                number: 1
            }

            WorkspaceButton {
                id: slotWorkspace2

                Layout.preferredWidth: 66
                Layout.preferredHeight: Math.round(32 * root.uiScale)
                number: 2
            }

            WorkspaceButton {
                id: slotWorkspace3

                Layout.preferredWidth: 66
                Layout.preferredHeight: Math.round(32 * root.uiScale)
                number: 3
            }

            WorkspaceButton {
                id: slotWorkspace4

                Layout.preferredWidth: 66
                Layout.preferredHeight: Math.round(32 * root.uiScale)
                number: 4
            }
        }

        Divider {
            Layout.fillWidth: true
            Layout.topMargin: Math.round(15 * root.uiScale) + root.stretchGap
            Layout.bottomMargin: Math.round(12 * root.uiScale)
        }

        SectionLabel {
            Layout.fillWidth: true
            text: root.tr("apps")
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Math.round(9 * root.uiScale)
            spacing: Math.round(8 * root.uiScale)

            AppButton {
                id: slotFiles

                iconName: "folder"
                tint: root.theme ? root.theme.accentTertiary : Qt.rgba(0.46, 0.64, 0.90, 0.94)
                command: root.filesCommand
            }

            AppButton {
                id: slotBrowser

                iconName: "browser"
                tint: root.theme ? root.theme.accentPrimary : Qt.rgba(0.91, 0.46, 0.36, 0.90)
                command: root.browserCommand
            }

            AppButton {
                id: slotDiscord

                iconName: "discord"
                tint: root.theme ? root.theme.accentSecondary : Qt.rgba(0.53, 0.47, 0.84, 0.90)
                command: root.discordCommand
            }
        }

        Divider {
            Layout.fillWidth: true
            Layout.topMargin: Math.round(15 * root.uiScale) + root.stretchGap
            Layout.bottomMargin: Math.round(12 * root.uiScale)
        }

        SectionLabel {
            Layout.fillWidth: true
            text: root.tr("utilities")
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Math.round(9 * root.uiScale)
            spacing: Math.round(9 * root.uiScale)

            UtilityButton {
                id: slotVolume

                iconName: root.muted ? "volume-muted" : "volume"
                hoverPopupType: "volume"
                selected: root.activePopupType === "volume"
                onTriggered: root.quickPopupRequested("volume", root.itemCenterY(slotVolume))
            }

            UtilityButton {
                id: slotWifi

                iconName: "wifi"
                hoverPopupType: "wifi"
                selected: root.activePopupType === "wifi"
                onTriggered: root.quickPopupRequested("wifi", root.itemCenterY(slotWifi))
            }

            UtilityButton {
                id: slotBrightness

                iconName: "sun"
                hoverPopupType: "brightness"
                selected: root.activePopupType === "brightness"
                onTriggered: root.quickPopupRequested("brightness", root.itemCenterY(slotBrightness))
            }

            UtilityButton {
                id: slotNotifications

                iconName: "bell"
                badge: root.notificationBadgeText()
                iconRotation: root.notificationRingAngle
                hoverPopupType: "notifications"
                selected: root.activePopupType === "notifications"
                onTriggered: root.quickPopupRequested("notifications", root.itemCenterY(slotNotifications))
            }

            UtilityButton {
                id: slotBluetooth

                iconName: "bluetooth"
                hoverPopupType: "bluetooth"
                selected: root.activePopupType === "bluetooth"
                onTriggered: root.quickPopupRequested("bluetooth", root.itemCenterY(slotBluetooth))
            }

            UtilityButton {
                id: slotBattery

                hoverPopupType: "battery"
                selected: root.activePopupType === "battery"
                iconName: "battery"
                onTriggered: root.quickPopupRequested("battery", root.itemCenterY(slotBattery))
            }

            UtilityButton {
                id: slotSettings

                iconName: "settings"
                selected: false
                onTriggered: root.settingsRequested(root.itemCenterY(slotSettings))
            }

            UtilityButton {
                id: slotLayout

                iconName: "display"
                selected: false
                onTriggered: root.layoutRequested(root.itemCenterY(slotLayout))
            }
        }

        Item {
            Layout.fillHeight: true
            Layout.minimumHeight: 18
        }

        Divider {
            Layout.fillWidth: true
            Layout.bottomMargin: Math.round(8 * root.uiScale)
        }

        UserAvatar {
            id: slotAvatar

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.round(48 * root.uiScale)
            Layout.preferredHeight: Math.round(48 * root.uiScale)
        }
    }

    MouseArea {
        id: popoutHoverProbe
        z: 25

        anchors.fill: panelSurface
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: event => root.updateHoverProbe(event.y)
        onContainsMouseChanged: {
            if (!containsMouse)
                root.clearHoverProbe()
            else
                root.updateHoverProbe(mouseY)
        }
    }

    Repeater {
        model: root.trailSegments

        Rectangle {
            z: 8

            x: modelData.x
            y: modelData.y
            width: modelData.w
            height: modelData.h
            radius: Math.min(root.cornerRadius, height / 2)
            antialiasing: true
            color: root.alpha(root.pink, root.trailOpacity * modelData.life)
            border.width: 1
            border.color: root.alpha(root.pink, 0.34 * modelData.life)
        }
    }

    Rectangle {
        visible: root.focusMode
        z: 30

        x: root.focusX
        y: root.focusY
        width: root.focusW
        height: root.focusH
        radius: Math.min(root.cornerRadius, height / 2)
        color: "transparent"
        border.width: 2
        border.color: root.alpha(root.pink, 0.95)
        antialiasing: true

        Behavior on x { NumberAnimation { duration: root.motionNormal; easing.type: root.motionEaseHover } }
        Behavior on y { NumberAnimation { duration: root.motionNormal; easing.type: root.motionEaseHover } }
        Behavior on width { NumberAnimation { duration: root.motionNormal; easing.type: root.motionEaseHover } }
        Behavior on height { NumberAnimation { duration: root.motionNormal; easing.type: root.motionEaseHover } }
    }

    Timer {
        id: volumeRefresh

        interval: 220
        repeat: false
        onTriggered: {
            if (!volumeQuery.running)
                volumeQuery.running = true
        }
    }

    component AudioVisualizer: Rectangle {
        id: visualizer

        radius: Math.round(14 * root.uiScale)
        color: root.alpha(root.card, root.darkSoft ? 0.20 : 0.28)
        border.width: 1
        border.color: root.alpha(root.borderSoft, root.darkSoft ? 0.16 : 0.34)
        clip: true
        antialiasing: true

        Rectangle {
            anchors {
                fill: parent
                margins: 1
            }

            radius: parent.radius - 1
            color: root.alpha(root.theme ? root.theme.surfaceBase : root.card, root.darkSoft ? 0.05 : 0.12)
        }

        Column {
            id: bandColumn

            anchors {
                fill: parent
                margins: Math.round(8 * root.uiScale)
            }

            spacing: Math.max(1, Math.round(2 * root.uiScale))

            Repeater {
                model: root.cavaBandCount

                Item {
                    width: bandColumn.width
                    height: Math.max(2, (bandColumn.height - bandColumn.spacing * (root.cavaBandCount - 1)) / root.cavaBandCount)

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.max(Math.round(7 * root.uiScale), Math.round(parent.width * root.visualizerValue(index)))
                        height: Math.max(2, Math.min(Math.round(4 * root.uiScale), parent.height))
                        radius: height / 2
                        color: index % 3 === 0
                            ? root.alpha(root.lilac, root.darkSoft ? 0.72 : 0.62)
                            : root.alpha(root.pink, root.darkSoft ? 0.82 : 0.70)

                        Behavior on width {
                            NumberAnimation {
                                duration: Math.max(1, Math.round(root.motionFast * 0.6))
                                easing.type: root.motionEaseHover
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 1
            }

            height: Math.round(18 * root.uiScale)
            radius: parent.radius - 1
            color: root.alpha(root.theme ? root.theme.activeText : Qt.rgba(1, 1, 1, 1), root.darkSoft ? 0.025 : 0.08)
        }
    }

    component ClockBlock: Item {
        property bool hovered: false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 4

            MiniClock {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.round(40 * root.uiScale)
                Layout.preferredHeight: Math.round(40 * root.uiScale)
            }

            Text {
                Layout.fillWidth: true
                text: root.clockText
                color: root.ink
                horizontalAlignment: Text.AlignHCenter
                font.family: root.monoFont
                font.pixelSize: Math.round(21 * root.uiScale)
                font.weight: Font.Medium
                layer.enabled: root.fontGlowEnabled()
                layer.effect: FontGlowEffect {}
            }

            Text {
                Layout.fillWidth: true
                text: root.dateText
                color: root.inkSoft
                horizontalAlignment: Text.AlignHCenter
                font.family: root.uiFont
                font.pixelSize: Math.round(10 * root.uiScale)
                font.weight: Font.DemiBold
                layer.enabled: root.fontGlowEnabled()
                layer.effect: FontGlowEffect {}
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                parent.hovered = true
                root.quickPopupHovered("time", root.itemCenterY(parent))
            }
            onExited: {
                parent.hovered = false
                root.quickPopupHoverEnded("time")
            }
            onClicked: root.quickPopupRequested("time", root.itemCenterY(parent))
        }
    }

    component SectionLabel: Text {
        color: root.pink
        horizontalAlignment: Text.AlignHCenter
        font.family: root.uiFont
        font.pixelSize: Math.round(11 * root.uiScale)
        font.weight: Font.Bold
        layer.enabled: root.fontGlowEnabled()
        layer.effect: FontGlowEffect {}
    }

    component Divider: Rectangle {
        height: 1
        radius: 1
        color: root.darkSoft ? Qt.rgba(1, 1, 1, 0.08) : root.alpha(root.lilac, 0.22)
    }

    component WorkspaceButton: Rectangle {
        id: button

        property int number: 1
        property bool active: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === number
        property bool hovered: false
        property real activeProgress: active ? 1 : 0
        property real switchPulse: 0

        Layout.alignment: Qt.AlignHCenter
        radius: 6
        scale: 1 + activeProgress * 0.035 + switchPulse * 0.025
        color: active ? root.alpha(root.pink, 0.48) : (hovered ? root.alpha(root.card, 0.70) : root.alpha(root.card, 0.34))
        border.width: 1
        border.color: active ? root.alpha(root.pink, 0.38) : root.alpha(root.lilac, 0.18)
        layer.enabled: active || hovered
        layer.effect: DropShadow {
            transparentBorder: true
            radius: button.active ? 12 : 9
            samples: button.active ? 25 : 19
            horizontalOffset: 0
            verticalOffset: button.active ? 4 : 3
            color: root.alpha(root.theme ? root.theme.shadowColor : Qt.rgba(0.45, 0.28, 0.42, 1), button.active ? 0.12 : 0.07)
        }

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on activeProgress {
            NumberAnimation {
                duration: root.motionNormal
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: root.motionHover
                easing.type: Easing.OutCubic
            }
        }

        onActiveChanged: if (active) workspaceSwitchPulse.restart()

        SequentialAnimation {
            id: workspaceSwitchPulse
            running: false
            NumberAnimation { target: button; property: "switchPulse"; from: 0; to: 1; duration: 90; easing.type: Easing.OutCubic }
            NumberAnimation { target: button; property: "switchPulse"; from: 1; to: 0; duration: 210; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            color: root.alpha(root.pink, 0.14 * button.activeProgress + 0.08 * button.switchPulse)
            opacity: button.activeProgress > 0.01 || button.switchPulse > 0.01 ? 1 : 0
            antialiasing: true
        }

        Text {
            anchors.centerIn: parent
            text: String(button.number)
            color: button.active ? root.pink : root.ink
            font.family: root.monoFont
            font.pixelSize: Math.round(15 * root.uiScale)
            font.weight: Font.Medium
            layer.enabled: root.fontGlowEnabled()
            layer.effect: FontGlowEffect {}
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: button.hovered = true
            onExited: button.hovered = false
            onClicked: Hyprland.dispatch("workspace " + button.number)
        }
    }

    component ToolRow: Item {
        id: row

        property string label: ""
        property string iconName: "search"
        property string command: ""
        property bool hovered: false
        property bool clickable: true
        property bool selected: false
        property string hoverPopupType: ""
        signal triggered()

        implicitHeight: Math.round(30 * root.uiScale)

        Process {
            id: rowProcess
            running: false
            command: ["bash", "-lc", row.command]
            onExited: running = false
        }

        Rectangle {
            anchors.fill: parent
            radius: Math.round(13 * root.uiScale)
            visible: row.selected || row.hovered
            color: row.selected ? root.alpha(root.pink, root.pywalStyle ? 0.24 : 0.18) : root.alpha(root.card, 0.28)
            border.width: row.selected ? 1 : 0
            border.color: row.selected && root.pywalStyle ? root.alpha(root.lilac, 0.46) : root.alpha(root.pink, 0.35)
        }

        VeloraIcon {
            id: toolIcon

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: 4
            }

            width: Math.round(24 * root.uiScale)
            height: Math.round(24 * root.uiScale)
            iconName: row.iconName
            lineColor: row.selected ? (root.softStyle ? root.pink : root.lilac) : root.inkSoft
            layer.enabled: root.pywalStyle && (row.selected || row.hovered)
            layer.effect: DropShadow {
                transparentBorder: true
                radius: 8
                samples: 17
                horizontalOffset: 0
                verticalOffset: 0
                color: root.theme ? root.theme.iconGlow : Qt.rgba(0, 0, 0, 0)
            }
        }

        Text {
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: Math.round(29 * root.uiScale)
            }

            text: row.label
            color: row.selected ? root.pink : root.ink
            font.family: root.uiFont
            font.pixelSize: Math.round(11 * root.uiScale)
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            layer.enabled: root.fontGlowEnabled()
            layer.effect: FontGlowEffect {}
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            cursorShape: row.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
            onEntered: {
                row.hovered = true
                if (row.hoverPopupType.length > 0)
                    root.quickPopupHovered(row.hoverPopupType, root.itemCenterY(row))
            }
            onExited: {
                row.hovered = false
                if (row.hoverPopupType.length > 0)
                    root.quickPopupHoverEnded(row.hoverPopupType)
            }
            onClicked: function(mouse) {
                mouse.accepted = true
                if (row.command.length > 0 && !rowProcess.running)
                    rowProcess.running = true

                row.triggered()
            }
        }
    }

    component AppButton: Rectangle {
        id: button

        property string iconName: "folder"
        property string command: ""
        property color tint: root.lilac
        property bool hovered: false
        property bool selected: false
        property string hoverPopupType: ""

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: Math.round(34 * root.uiScale)
        Layout.preferredHeight: Math.round(34 * root.uiScale)
        radius: Math.round(8 * root.uiScale)
        color: selected ? root.alpha(root.pink, 0.30) : (hovered ? root.alpha(root.card, 0.84) : root.alpha(root.card, 0.58))
        border.width: 1
        border.color: selected ? root.alpha(root.pink, 0.34) : (root.darkSoft ? Qt.rgba(1, 1, 1, 0.14) : root.alpha(root.borderSoft, 0.76))
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            radius: button.hovered ? 13 : 10
            samples: button.hovered ? 27 : 21
            horizontalOffset: 0
            verticalOffset: button.hovered ? 5 : 3
            color: root.alpha(root.theme ? root.theme.shadowColor : Qt.rgba(0.38, 0.25, 0.42, 1), button.hovered ? 0.13 : 0.08)
        }

        Process {
            id: appProcess
            running: false
            command: ["bash", "-lc", button.command]
            onExited: running = false
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.round(26 * root.uiScale)
            height: Math.round(26 * root.uiScale)
            radius: Math.round(6 * root.uiScale)
            color: button.iconName === "terminal" ? root.alpha(root.ink, 0.88) : (button.iconName === "discord" ? root.alpha(root.lilac, 0.20) : root.alpha(root.card, 0.18))
        }

        VeloraIcon {
            anchors.centerIn: parent
            width: Math.round(26 * root.uiScale)
            height: Math.round(26 * root.uiScale)
            iconName: button.iconName
            lineColor: button.tint
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                button.hovered = true
                if (button.hoverPopupType.length > 0)
                    root.quickPopupHovered(button.hoverPopupType, root.itemCenterY(button))
            }
            onExited: {
                button.hovered = false
                if (button.hoverPopupType.length > 0)
                    root.quickPopupHoverEnded(button.hoverPopupType)
            }
            onClicked: {
                if (button.hoverPopupType.length > 0) {
                    root.quickPopupRequested(button.hoverPopupType, root.itemCenterY(button))
                    return
                }
                if (button.command.length > 0 && !appProcess.running)
                    appProcess.running = true
            }
        }
    }

    component UtilityButton: Item {
        id: button

        property string iconName: "volume"
        property string command: ""
        property string badge: ""
        property bool hovered: false
        property bool selected: false
        property bool passive: false
        property bool compact: false
        property real iconRotation: 0
        property string hoverPopupType: ""
        signal triggered()

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: Math.round(32 * root.uiScale)
        Layout.preferredHeight: Math.round(32 * root.uiScale)

        Rectangle {
            anchors.fill: parent
            radius: Math.round(7 * root.uiScale)
            visible: button.selected || button.hovered
            color: button.selected ? root.alpha(root.pink, 0.26) : root.alpha(root.card, 0.30)
            border.width: button.selected ? 1 : 0
            border.color: root.alpha(root.pink, 0.30)
        }

        Process {
            id: utilityProcess
            running: false
            command: ["bash", "-lc", button.command]
            onExited: running = false
        }

        VeloraIcon {
            anchors.centerIn: parent
            width: Math.round(26 * root.uiScale)
            height: Math.round(26 * root.uiScale)
            iconName: button.iconName
            lineColor: button.selected ? (root.softStyle ? root.pink : root.lilac) : root.inkSoft
            value: button.iconName === "battery" ? root.normalizedBatteryLevel() : Math.max(0.08, Math.min(1, root.volume / 100))
            rotation: button.iconRotation
            transformOrigin: Item.Center
            layer.enabled: root.pywalStyle && (button.selected || button.hovered)
            layer.effect: DropShadow {
                transparentBorder: true
                radius: 9
                samples: 19
                horizontalOffset: 0
                verticalOffset: 0
                color: root.theme ? root.theme.iconGlow : Qt.rgba(0, 0, 0, 0)
            }
        }

        Rectangle {
            visible: button.badge.length > 0
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: -8
            }

            width: Math.max(Math.round(16 * root.uiScale), badgeText.implicitWidth + Math.round(8 * root.uiScale))
            height: Math.round(15 * root.uiScale)
            radius: width / 2
            color: root.pink
            border.width: 1
            border.color: root.alpha(root.theme ? root.theme.activeText : Qt.rgba(1, 1, 1, 1), 0.38)
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                radius: 8
                samples: 17
                horizontalOffset: 0
                verticalOffset: 2
                color: root.alpha(root.theme ? root.theme.shadowColor : Qt.rgba(0, 0, 0, 1), 0.18)
            }

            Text {
                id: badgeText

                anchors.centerIn: parent
                text: button.badge
                color: root.theme ? root.theme.activeText : "white"
                font.family: root.monoFont
                font.pixelSize: Math.round(8 * root.uiScale)
                font.weight: Font.Bold
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: !button.passive
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                button.hovered = true
                if (button.hoverPopupType.length > 0)
                    root.quickPopupHovered(button.hoverPopupType, root.itemCenterY(button))
            }
            onExited: {
                button.hovered = false
                if (button.hoverPopupType.length > 0)
                    root.quickPopupHoverEnded(button.hoverPopupType)
            }
            onClicked: function(mouse) {
                mouse.accepted = true
                if (button.command.length > 0 && !utilityProcess.running)
                    utilityProcess.running = true

                button.triggered()
            }
        }
    }

    component UserAvatar: Rectangle {
        property bool hovered: false

        radius: width / 2
        color: root.alpha(root.card, 0.62)
        border.width: 1
        border.color: root.softStyle ? root.alpha(root.pink, 0.42) : root.alpha(root.borderSoft, 0.84)
        clip: true
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            radius: 16
            samples: 33
            horizontalOffset: 0
            verticalOffset: 5
            color: root.softStyle
                ? root.alpha(root.theme ? root.theme.shadowColor : Qt.rgba(0, 0, 0, 1), root.darkSoft ? 0.20 : 0.12)
                : root.alpha(root.theme ? root.theme.shadowColor : Qt.rgba(0.38, 0.25, 0.42, 1), 0.13)
        }

        Image {
            id: avatarImage

            anchors.fill: parent
            anchors.margins: 3
            source: Qt.resolvedUrl("../assets/profile-avatar.png")
            sourceSize.width: 256
            sourceSize.height: 256
            fillMode: Image.PreserveAspectCrop
            visible: false
            smooth: true
            mipmap: true
        }

        Rectangle {
            id: avatarMask

            anchors.fill: avatarImage
            radius: width / 2
            visible: false
        }

        OpacityMask {
            anchors.fill: avatarImage
            source: avatarImage
            maskSource: avatarMask
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                parent.hovered = true
                root.quickPopupHovered("profile", root.itemCenterY(parent))
            }
            onExited: {
                parent.hovered = false
                root.quickPopupHoverEnded("profile")
            }
            onClicked: root.quickPopupRequested("profile", root.itemCenterY(parent))
        }
    }

    component MiniClock: Canvas {
        id: clock

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clock.requestPaint()
        }

        onPaint: {
            const ctx = getContext("2d")
            const s = Math.min(width, height)
            const cx = width / 2
            const cy = height / 2
            const now = new Date()
            const second = now.getSeconds()
            const minute = now.getMinutes() + second / 60
            const hour = now.getHours() % 12

            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = root.pink
            ctx.fillStyle = root.pink
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            ctx.globalAlpha = 0.70
            ctx.lineWidth = 1.5
            ctx.beginPath()
            ctx.arc(cx, cy, s * 0.42, 0, Math.PI * 2, false)
            ctx.stroke()

            for (let i = 0; i < 12; i += 1) {
                const a = (i / 12) * Math.PI * 2 - Math.PI / 2
                ctx.globalAlpha = i % 3 === 0 ? 0.55 : 0.30
                ctx.lineWidth = i % 3 === 0 ? 1.2 : 0.9
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(a) * s * 0.32, cy + Math.sin(a) * s * 0.32)
                ctx.lineTo(cx + Math.cos(a) * s * 0.37, cy + Math.sin(a) * s * 0.37)
                ctx.stroke()
            }

            ctx.globalAlpha = 0.85
            ctx.lineWidth = 1.7
            const minuteAngle = (minute / 60) * Math.PI * 2 - Math.PI / 2
            ctx.beginPath()
            ctx.moveTo(cx, cy)
            ctx.lineTo(cx + Math.cos(minuteAngle) * s * 0.28, cy + Math.sin(minuteAngle) * s * 0.28)
            ctx.stroke()

            ctx.lineWidth = 2.0
            const hourAngle = ((hour + minute / 60) / 12) * Math.PI * 2 - Math.PI / 2
            ctx.beginPath()
            ctx.moveTo(cx, cy)
            ctx.lineTo(cx + Math.cos(hourAngle) * s * 0.20, cy + Math.sin(hourAngle) * s * 0.20)
            ctx.stroke()

            ctx.globalAlpha = 1
            ctx.beginPath()
            ctx.arc(cx, cy, s * 0.035, 0, Math.PI * 2, false)
            ctx.fill()
        }
    }

    component VeloraIcon: Canvas {
        id: icon

        property string iconName: "search"
        property color lineColor: root.lilac
        property real value: 1.0

        onIconNameChanged: requestPaint()
        onLineColorChanged: requestPaint()
        onValueChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        function roundedRect(ctx, x, y, w, h, r) {
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

        function setup(ctx) {
            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = lineColor
            ctx.fillStyle = lineColor
            ctx.lineWidth = Math.max(1.5, Math.min(width, height) * 0.085)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
        }

        onPaint: {
            const ctx = getContext("2d")
            const s = Math.min(width, height)
            const cx = width / 2
            const cy = height / 2

            setup(ctx)

            if (iconName === "palette") {
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
            } else if (iconName === "search") {
                ctx.beginPath()
                ctx.arc(cx - s * 0.07, cy - s * 0.07, s * 0.25, 0, Math.PI * 2, false)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(cx + s * 0.13, cy + s * 0.13)
                ctx.lineTo(cx + s * 0.32, cy + s * 0.32)
                ctx.stroke()
            } else if (iconName === "folder") {
                ctx.save()
                ctx.fillStyle = colorString(lineColor, 0.78)
                roundedRect(ctx, s * 0.16, s * 0.34, s * 0.68, s * 0.44, s * 0.08)
                ctx.fill()
                ctx.fillStyle = mixedColorString(lineColor, 1, 1, 1, 0.26, 0.86)
                roundedRect(ctx, s * 0.18, s * 0.25, s * 0.31, s * 0.20, s * 0.06)
                ctx.fill()
                ctx.fillStyle = mixedColorString(lineColor, 1, 1, 1, 0.74, 0.34)
                roundedRect(ctx, s * 0.23, s * 0.43, s * 0.50, s * 0.09, s * 0.04)
                ctx.fill()
                ctx.strokeStyle = mixedColorString(lineColor, 0, 0, 0, 0.28, 0.58)
                ctx.lineWidth = Math.max(1, s * 0.045)
                roundedRect(ctx, s * 0.16, s * 0.34, s * 0.68, s * 0.44, s * 0.08)
                ctx.stroke()
                ctx.restore()
            } else if (iconName === "terminal") {
                ctx.save()
                ctx.strokeStyle = "rgba(247, 244, 250, 0.92)"
                ctx.lineWidth = Math.max(1.6, s * 0.075)
                ctx.beginPath()
                ctx.moveTo(s * 0.28, s * 0.40)
                ctx.lineTo(s * 0.40, s * 0.50)
                ctx.lineTo(s * 0.28, s * 0.60)
                ctx.moveTo(s * 0.49, s * 0.63)
                ctx.lineTo(s * 0.70, s * 0.63)
                ctx.stroke()
                ctx.restore()
            } else if (iconName === "browser") {
                ctx.save()
                const grad = ctx.createLinearGradient(s * 0.22, s * 0.18, s * 0.82, s * 0.78)
                grad.addColorStop(0, mixedColorString(lineColor, 1, 1, 1, 0.34, 0.94))
                grad.addColorStop(0.48, colorString(lineColor, 0.90))
                grad.addColorStop(1, colorString(root.lilac, 0.82))
                ctx.fillStyle = grad
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.34, 0, Math.PI * 2, false)
                ctx.fill()
                ctx.fillStyle = mixedColorString(lineColor, 1, 1, 1, 0.58, 0.66)
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
            } else if (iconName === "discord") {
                ctx.save()
                ctx.fillStyle = mixedColorString(lineColor, 1, 1, 1, 0.26, 0.46)
                ctx.strokeStyle = colorString(lineColor, 0.84)
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
                ctx.fillStyle = mixedColorString(lineColor, 1, 1, 1, 0.72, 0.94)
                ctx.beginPath()
                ctx.arc(s * 0.39, s * 0.53, s * 0.038, 0, Math.PI * 2, false)
                ctx.arc(s * 0.61, s * 0.53, s * 0.038, 0, Math.PI * 2, false)
                ctx.fill()
                ctx.strokeStyle = mixedColorString(lineColor, 1, 1, 1, 0.68, 0.86)
                ctx.lineWidth = Math.max(1, s * 0.040)
                ctx.beginPath()
                ctx.moveTo(s * 0.35, s * 0.64)
                ctx.quadraticCurveTo(s * 0.50, s * 0.70, s * 0.65, s * 0.64)
                ctx.stroke()
                ctx.restore()
            } else if (iconName === "volume" || iconName === "volume-muted") {
                ctx.beginPath()
                ctx.moveTo(s * 0.16, s * 0.43)
                ctx.lineTo(s * 0.32, s * 0.43)
                ctx.lineTo(s * 0.52, s * 0.27)
                ctx.lineTo(s * 0.52, s * 0.73)
                ctx.lineTo(s * 0.32, s * 0.57)
                ctx.lineTo(s * 0.16, s * 0.57)
                ctx.closePath()
                ctx.stroke()
                if (iconName === "volume-muted") {
                    ctx.beginPath()
                    ctx.moveTo(s * 0.66, s * 0.40)
                    ctx.lineTo(s * 0.84, s * 0.58)
                    ctx.moveTo(s * 0.84, s * 0.40)
                    ctx.lineTo(s * 0.66, s * 0.58)
                    ctx.stroke()
                } else {
                    ctx.beginPath()
                    ctx.arc(s * 0.55, s * 0.50, s * (0.14 + Math.max(0, Math.min(1, value)) * 0.10), Math.PI * 1.68, Math.PI * 0.32, false)
                    ctx.stroke()
                }
            } else if (iconName === "wifi") {
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
            } else if (iconName === "sun") {
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
            } else if (iconName === "bell") {
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
            } else if (iconName === "bluetooth") {
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
            } else if (iconName === "settings") {
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
            } else if (iconName === "display") {
                ctx.save()
                ctx.strokeStyle = colorString(lineColor, 0.86)
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
            } else if (iconName === "battery") {
                const level = Math.max(0, Math.min(1, value))
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
                    ctx.fillStyle = colorString(lineColor, level <= 0.18 ? 0.52 : 0.74)
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
