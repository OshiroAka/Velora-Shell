import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.UPower
import "popups"

Item {
    id: root

    property var theme: null
    property alias surfaceItem: panelSurface
    property string popupType: "search"
    property bool open: visible
    property bool externalSurface: false
    property bool lineReveal: false
    property bool holdOpen: false
    property real revealProgressOverride: -1
    property bool warmSwitch: false
    property bool interactiveFocus: false
    property string attachSide: "left"
    property real volumePercent: 0.60
    property real micVolumePercent: 0.00
    property real brightnessPercent: 0.86
    property bool muted: false
    property bool micMuted: false
    property bool wifiEnabled: true
    property bool nightLightEnabled: true
    property bool bluetoothPowered: false
    property bool bluetoothAvailable: false
    property string audioOutputName: "Default output"
    property string audioInputName: "Default input"
    property string brightnessDevice: ""
    property string diskUsageText: "Loading..."
    property real diskUsagePercent: 0
    property string diskMountPoint: ""
    property string batteryStateText: "unknown"
    property string batteryTimeText: ""
    property string powerProfile: "unknown"
    property bool acOnline: false
    property string pendingCommand: ""
    property string activeCommand: ""
    property string searchQuery: ""
    property string searchMode: "apps"
    property int searchSelectedIndex: 0
    property var searchResults: []
    property bool searchReady: false
    property int searchFocusRequest: 0
    property bool eventsLoaded: false
    property bool eventsSaveQueued: false
    property string agendaSection: "events"
    property int agendaSelectedIndex: -1
    property bool agendaEditing: false
    property int agendaEditingIndex: -1
    property string agendaTitleDraft: ""
    property string agendaDateDraft: ""
    property string agendaStartDraft: ""
    property string agendaEndDraft: ""
    property string agendaLocationDraft: ""
    property string agendaCategoryDraft: ""
    property string agendaDescriptionDraft: ""
    property bool labelsLoaded: false
    property bool labelsSaveQueued: false
    property int labelSelectedIndex: -1
    property bool labelEditing: false
    property int labelEditingIndex: -1
    property int labelMenuIndex: -1
    property string labelNameDraft: ""
    property string labelDescriptionDraft: ""
    property string labelAccentDraft: "blue"
    property bool weatherLoaded: false
    property string weatherCity: "Localizacao atual"
    property string weatherTempText: "--°C"
    property string weatherDesc: "Carregando clima"
    property string weatherHighLowText: "↑ --°C    ↓ --°C"
    property string weatherHumidityText: "Umidade: --"
    property string weatherWindText: "Vento: --"
    property string weatherUpdatedText: ""
    property string weatherFeelsText: "Sensação térmica --°C"
    property string weatherRainChanceText: "Chance de chuva --"
    property string weatherUvText: "--"
    property string weatherSunriseText: "--"
    property string weatherSunsetText: "--"
    property string weatherWindDirectionText: ""
    property string weatherIconName: "partly"
    property var weatherHourlyItems: []
    property var weatherDailyItems: []
    property var weatherAirQuality: ({ label: "Sem dados", aqi: "--", detail: "Qualidade do ar nao disponivel." })
    property var weatherRainMap: ({ label: "Sem mapa real", detail: "Radar de chuva indisponivel." })
    readonly property string eventsScript: Quickshell.shellDir + "/scripts/velora-events-state"
    readonly property string weatherScript: Quickshell.shellDir + "/scripts/velora-weather-state"
    readonly property int cornerRadius: 18
    readonly property int arrowCenterY: {
        if (popupType === "volume")
            return 78
        if (popupType === "wifi")
            return 288
        if (popupType === "brightness")
            return 248
        if (popupType === "notifications")
            return 414
        if (popupType === "bluetooth")
            return 456
        if (popupType === "wallpaperVisibility")
            return 132
        return 38
    }
    readonly property bool pywalStyle: theme && theme.themeId === "pywal16"
    readonly property bool neon: pywalStyle && theme.themeMode === "dark"
    readonly property bool attachedRight: attachSide === "right"
    readonly property color ink: theme ? theme.textPrimary : Qt.rgba(0.47, 0.38, 0.55, 0.88)
    readonly property color inkSoft: theme ? theme.textSecondary : Qt.rgba(0.57, 0.48, 0.64, 0.66)
    readonly property color pink: theme ? (pywalStyle ? theme.accentSecondary : theme.accentPrimary) : Qt.rgba(0.88, 0.43, 0.66, 0.92)
    readonly property color lilac: theme ? (pywalStyle ? theme.accentPrimary : theme.accentSecondary) : Qt.rgba(0.58, 0.48, 0.73, 0.78)
    readonly property color glass: theme ? theme.surfacePopup : Qt.rgba(1, 0.992, 1, 0.92)
    readonly property color card: theme ? theme.popupBubbleSurface() : Qt.rgba(1, 1, 1, 0.70)
    readonly property color line: theme ? theme.alpha(theme.borderActive, 0.18) : Qt.rgba(0.70, 0.52, 0.64, 0.18)
    readonly property color borderSoft: theme ? theme.borderSoft : Qt.rgba(1, 1, 1, 0.78)
    readonly property color winSurface: theme ? alpha(theme.surfacePopup, theme.themeMode === "dark" ? 0.88 : 0.78) : Qt.rgba(0.035, 0.075, 0.12, 0.88)
    readonly property color winSurfaceDeep: theme ? alpha(theme.surfaceBase, theme.themeMode === "dark" ? 0.76 : 0.62) : Qt.rgba(0.015, 0.045, 0.075, 0.76)
    readonly property color winCard: theme ? alpha(card, theme.themeMode === "dark" ? 0.42 : 0.54) : Qt.rgba(0.12, 0.20, 0.29, 0.48)
    readonly property color winCardHover: theme ? alpha(card, theme.themeMode === "dark" ? 0.58 : 0.72) : Qt.rgba(0.16, 0.26, 0.36, 0.62)
    readonly property color winLine: theme ? alpha(theme.borderSoft, theme.themeMode === "dark" ? 0.24 : 0.34) : Qt.rgba(1, 1, 1, 0.14)
    readonly property color winAccent: theme ? (pywalStyle ? theme.accentPrimary : theme.accentSecondary) : Qt.rgba(0.10, 0.70, 0.94, 1)
    readonly property color winAccent2: theme ? (pywalStyle ? theme.accentSecondary : theme.accentPrimary) : Qt.rgba(0.17, 0.86, 0.92, 1)
    readonly property bool agendaDark: theme && theme.themeMode === "dark"
    readonly property color agendaPage: Qt.rgba(0, 0, 0, 0)
    readonly property color agendaPanel: agendaDark ? alpha(winCardHover, 0.18) : Qt.rgba(1.0, 0.982, 0.940, 0.44)
    readonly property color agendaCard: agendaDark ? alpha(winCardHover, 0.14) : Qt.rgba(0.965, 0.925, 0.850, 0.34)
    readonly property color agendaCardActive: agendaDark ? alpha(winAccent, 0.13) : Qt.rgba(0.840, 0.760, 0.570, 0.26)
    readonly property color agendaInk: agendaDark ? alpha(ink, 0.88) : Qt.rgba(0.075, 0.070, 0.055, 0.95)
    readonly property color agendaSoft: agendaDark ? alpha(inkSoft, 0.70) : Qt.rgba(0.250, 0.220, 0.170, 0.62)
    readonly property color agendaLine: agendaDark ? alpha(winAccent, 0.12) : Qt.rgba(0.410, 0.330, 0.190, 0.13)
    readonly property color agendaFieldFill: agendaDark ? alpha(winCardHover, 0.16) : Qt.rgba(1, 1, 1, 0.36)
    readonly property color agendaFieldBorder: agendaDark ? alpha(winAccent, 0.12) : Qt.rgba(0.34, 0.28, 0.18, 0.13)
    readonly property color agendaFieldBorderActive: agendaDark ? alpha(winAccent2, 0.34) : Qt.rgba(0.42, 0.34, 0.18, 0.34)
    readonly property string uiFont: theme ? theme.uiFont : "Noto Sans CJK JP"
    readonly property string monoFont: theme ? theme.monoFont : "JetBrainsMono Nerd Font"
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string wallpaperDir: homeDir + "/Pictures/Wallpapers"
    readonly property string scanScript: Quickshell.shellDir + "/scripts/velora-wallpaper-scan"
    readonly property string visibilityScript: Quickshell.shellDir + "/scripts/velora-wallpaper-visibility"
    readonly property string popupStatusScript: Quickshell.shellDir + "/scripts/velora-popup-status"
    readonly property string geminiScript: Quickshell.shellDir + "/scripts/velora-gemini-ask"
    readonly property bool nativeBluetoothAvailable: Bluetooth.defaultAdapter !== null
    readonly property bool bluetoothIsAvailable: nativeBluetoothAvailable || bluetoothAvailable
    readonly property bool bluetoothIsPowered: nativeBluetoothAvailable ? (Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false) : bluetoothPowered
    readonly property var nativeBluetoothItems: nativeBluetoothAvailable ? [...Bluetooth.devices.values].sort(function(a, b) {
        const aConnected = a && a.state === BluetoothDeviceState.Connected ? 1 : 0
        const bConnected = b && b.state === BluetoothDeviceState.Connected ? 1 : 0
        const aPaired = a && (a.bonded || a.paired) ? 1 : 0
        const bPaired = b && (b.bonded || b.paired) ? 1 : 0
        return (bConnected - aConnected) || (bPaired - aPaired) || root.textOf(a ? a.name : "").localeCompare(root.textOf(b ? b.name : ""))
    }) : []
    readonly property var fallbackWallpapers: [
        { kind: "static", label: "Tokyo Fuji", title: "Tokyo Fuji", category: "Static", path: wallpaperDir + "/static/aerial-view-tokyo-cityscape-with-fuji-mountain-japan.jpg", preview: wallpaperDir + "/static/aerial-view-tokyo-cityscape-with-fuji-mountain-japan.jpg" }
    ]
    property var wallpaperItems: []
    property var hiddenWallpapers: []
    property bool wallpaperVisibilityLoaded: false
    property bool wallpaperVisibilitySaveQueued: false
    property var batteryDevice: null
    property real revealProgress: 0
    property real entryProgress: 0
    property real popupIntroProgress: 1
    property real agendaSectionIntroProgress: 1
    property real agendaDetailIntroProgress: 1
    property real agendaLoopProgress: 0
    property real arrowVisualCenterY: arrowCenterY
    readonly property real effectiveRevealProgress: revealProgressOverride >= 0 ? Math.max(0, Math.min(1, revealProgressOverride)) : revealProgress
    readonly property real lineRevealContentStart: warmSwitch ? 0.06 : 0.16
    readonly property real lineRevealContentProgress: lineReveal ? Math.max(0, Math.min(1, (effectiveRevealProgress - lineRevealContentStart) / Math.max(0.01, 1 - lineRevealContentStart))) : effectiveRevealProgress
    readonly property bool backgroundPollingActive: open && visible
    readonly property int motionFast: theme ? theme.motionFast : 120
    readonly property int motionNormal: theme ? theme.motionNormal : 200
    readonly property int motionSlow: theme ? theme.motionSlow : 320
    readonly property int motionPanelIn: theme ? theme.motionPanelIn : 220
    readonly property int motionPanelOut: theme ? theme.motionPanelOut : 140
    readonly property int motionPanelGeometry: theme ? theme.motionPanelGeometry : 220
    readonly property int motionHover: theme ? theme.motionHover : 120
    readonly property int motionPanelOffset: theme ? Math.max(theme.motionPanelOffset, 46) : 46
    readonly property int effectiveMotionPanelOffset: popupType === "search" ? Math.max(motionPanelOffset, 64) : motionPanelOffset
    readonly property int motionEaseEnter: theme ? theme.motionEaseEnter : Easing.OutCubic
    readonly property int motionEaseExit: theme ? theme.motionEaseExit : Easing.InCubic
    readonly property int motionEaseHover: theme ? theme.motionEaseHover : Easing.OutCubic
    readonly property int motionEaseEmphasized: theme ? theme.motionEaseEmphasized : Easing.BezierSpline
    readonly property var motionEmphasizedCurve: theme ? theme.motionEmphasizedCurve : [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]

    signal closeRequested()
    signal pointerInsideChanged(bool inside)
    signal popupRequested(string type)

    function alpha(colorValue, opacity) {
        const nextOpacity = root.theme && root.theme.popupBubblesSolid && root.isPopupBubbleColor(colorValue)
            ? root.theme.popupBubbleOpacity(opacity)
            : opacity
        return root.theme ? root.theme.alpha(colorValue, nextOpacity) : Qt.rgba(colorValue.r, colorValue.g, colorValue.b, nextOpacity)
    }

    function isPopupBubbleColor(colorValue) {
        if (!root.theme || !root.theme.popupBubblesSolid)
            return false
        const base = root.card
        return Math.abs(colorValue.r - base.r) < 0.002
            && Math.abs(colorValue.g - base.g) < 0.002
            && Math.abs(colorValue.b - base.b) < 0.002
    }

    function canvasFont(weight, size, family) {
        const safeFamily = String(family || root.uiFont).replace(/"/g, "")
        return weight + " " + size + "px \"" + safeFamily + "\""
    }

    function tr(key) {
        const lang = root.theme ? root.theme.language : "ja"
        const texts = {
            "ja": {
                "bluetoothOff": "Bluetooth オフ",
                "btReady": "接続できます",
                "btDisabled": "無線が無効です",
                "btMissing": "bluetoothctl 未検出",
                "btInstall": "BlueZ tools をインストール",
                "btDevices": "デバイス",
                "btNoDevices": "デバイスなし",
                "btUnavailable": "Bluetooth は利用できません",
                "connect": "接",
                "disconnect": "切"
            },
            "en": {
                "bluetoothOff": "Bluetooth off",
                "btReady": "Ready to connect",
                "btDisabled": "Radio disabled",
                "btMissing": "bluetoothctl not found",
                "btInstall": "Install BlueZ tools",
                "btDevices": "devices",
                "btNoDevices": "No devices",
                "btUnavailable": "Bluetooth unavailable",
                "connect": "Connect",
                "disconnect": "Disconnect"
            },
            "pt-BR": {
                "bluetoothOff": "Bluetooth desligado",
                "btReady": "Pronto para conectar",
                "btDisabled": "Radio desativado",
                "btMissing": "bluetoothctl nao encontrado",
                "btInstall": "Instale as ferramentas BlueZ",
                "btDevices": "dispositivos",
                "btNoDevices": "Sem dispositivos",
                "btUnavailable": "Bluetooth indisponivel",
                "connect": "Conectar",
                "disconnect": "Desconectar"
            }
        }
        const table = texts[lang] || texts["ja"]
        return table[key] || texts["ja"][key] || key
    }

    function clamp01(value) {
        return Math.max(0, Math.min(1, value))
    }

    function staged(delay, duration) {
        return clamp01((entryProgress * motionSlow - delay * 0.16) / Math.max(1, duration * 0.58))
    }

    function stageOpacity(delay, duration) {
        return staged(delay, duration)
    }

    function stageTranslateY(delay, distance) {
        return Math.round((1 - staged(delay, 180)) * distance)
    }

    function stageTranslateX(delay, distance) {
        return Math.round((1 - staged(delay, 180)) * distance)
    }

    function stageScale(delay, start, end) {
        const t = staged(delay, 180)
        return start + (end - start) * t
    }

    function stagePopScale(delay, start, peak, end) {
        const t = staged(delay, 260)
        if (t < 0.62)
            return start + (peak - start) * (t / 0.62)
        return peak + (end - peak) * ((t - 0.62) / 0.38)
    }

    function stageRotation(delay, start) {
        return start * (1 - staged(delay, 240))
    }

    function overshootValue(value, delay) {
        const actual = clamp01(value)
        const start = Math.max(0, actual - 0.20)
        const peak = Math.min(1, actual + 0.06)
        const t = staged(delay, 360)

        if (t < 0.72)
            return start + (peak - start) * (t / 0.72)
        return peak + (actual - peak) * ((t - 0.72) / 0.28)
    }

    function usesPopupIntro(type) {
        return type === "search" || type === "time" || type === "agenda" || type === "weatherPanel"
    }

    function introStaged(progress, delay, duration) {
        return clamp01((progress * 620 - delay) / Math.max(1, duration))
    }

    function introTranslateY(progress, delay, distance) {
        return Math.round((1 - introStaged(progress, delay, 210)) * distance)
    }

    function introTranslateX(progress, delay, distance) {
        return Math.round((1 - introStaged(progress, delay, 210)) * distance)
    }

    function introScale(progress, delay, start, end) {
        const t = introStaged(progress, delay, 220)
        return start + (end - start) * t
    }

    function introPopScale(progress, delay, start, peak, end) {
        const t = introStaged(progress, delay, 260)
        if (t < 0.68)
            return start + (peak - start) * (t / 0.68)
        return peak + (end - peak) * ((t - 0.68) / 0.32)
    }

    function popupIntroOpacity(delay, duration) {
        return introStaged(popupIntroProgress, delay, duration)
    }

    function popupIntroTranslateY(delay, distance) {
        return introTranslateY(popupIntroProgress, delay, distance)
    }

    function popupIntroTranslateX(delay, distance) {
        return introTranslateX(popupIntroProgress, delay, distance)
    }

    function popupIntroScale(delay, start, end) {
        return introScale(popupIntroProgress, delay, start, end)
    }

    function popupIntroPopScale(delay, start, peak, end) {
        return introPopScale(popupIntroProgress, delay, start, peak, end)
    }

    function agendaSectionOpacity(delay, duration) {
        return introStaged(agendaSectionIntroProgress, delay, duration)
    }

    function agendaSectionTranslateY(delay, distance) {
        return introTranslateY(agendaSectionIntroProgress, delay, distance)
    }

    function agendaSectionTranslateX(delay, distance) {
        return introTranslateX(agendaSectionIntroProgress, delay, distance)
    }

    function agendaSectionScale(delay, start, end) {
        return introScale(agendaSectionIntroProgress, delay, start, end)
    }

    function agendaSectionPopScale(delay, start, peak, end) {
        return introPopScale(agendaSectionIntroProgress, delay, start, peak, end)
    }

    function agendaDetailOpacity(delay, duration) {
        return introStaged(agendaDetailIntroProgress, delay, duration)
    }

    function agendaDetailTranslateY(delay, distance) {
        return introTranslateY(agendaDetailIntroProgress, delay, distance)
    }

    function agendaDetailScale(delay, start, end) {
        return introScale(agendaDetailIntroProgress, delay, start, end)
    }

    function agendaLoopWave(offset, start, end) {
        const phase = (agendaLoopProgress + offset) * Math.PI * 2
        const t = (Math.sin(phase) + 1) / 2
        return start + (end - start) * t
    }

    function agendaLoopGlow(offset, maxOpacity) {
        return agendaLoopWave(offset, maxOpacity * 0.28, maxOpacity)
    }

    function scopedIntroOpacity(scope, delay, duration) {
        if (scope === "popup")
            return popupIntroOpacity(delay, duration)
        if (scope === "detail")
            return agendaDetailOpacity(delay, duration)
        if (scope === "section")
            return agendaSectionOpacity(delay, duration)
        return 1
    }

    function scopedIntroTranslateY(scope, delay, distance) {
        if (scope === "popup")
            return popupIntroTranslateY(delay, distance)
        if (scope === "detail")
            return agendaDetailTranslateY(delay, distance)
        if (scope === "section")
            return agendaSectionTranslateY(delay, distance)
        return 0
    }

    function scopedIntroTranslateX(scope, delay, distance) {
        if (scope === "popup")
            return popupIntroTranslateX(delay, distance)
        if (scope === "section")
            return agendaSectionTranslateX(delay, distance)
        return 0
    }

    function scopedIntroScale(scope, delay, start, end) {
        if (scope === "popup")
            return popupIntroScale(delay, start, end)
        if (scope === "detail")
            return agendaDetailScale(delay, start, end)
        if (scope === "section")
            return agendaSectionScale(delay, start, end)
        return end
    }

    function restartEntryAnimation() {
        const startProgress = lineReveal && warmSwitch ? 0.72 : 0
        entryAnimation.stop()
        entryProgress = startProgress
        entryAnimation.from = startProgress
        entryAnimation.to = 1
        entryAnimation.duration = lineReveal
            ? (warmSwitch ? Math.max(220, Math.round(motionSlow * 0.50)) : Math.max(motionNormal, Math.round(motionSlow * 0.94)))
            : motionSlow
        entryAnimation.restart()
    }

    function exitEntryAnimation() {
        entryAnimation.stop()
        entryAnimation.from = entryProgress
        entryAnimation.to = 0
        entryAnimation.duration = motionPanelOut
        entryAnimation.restart()
    }

    function restartPopupIntroAnimation() {
        if (!usesPopupIntro(popupType))
            return

        const startProgress = lineReveal && warmSwitch ? 0.70 : 0
        const baseDuration = (popupType === "agenda" || popupType === "weatherPanel") ? 620 : 540
        popupIntroAnimation.stop()
        popupIntroProgress = startProgress
        popupIntroAnimation.from = startProgress
        popupIntroAnimation.to = 1
        popupIntroAnimation.duration = lineReveal
            ? (warmSwitch ? Math.max(240, Math.round(baseDuration * 0.48)) : Math.max(360, Math.round(baseDuration * 0.82)))
            : baseDuration
        popupIntroAnimation.restart()

        if (popupType === "agenda") {
            restartAgendaSectionAnimation()
            restartAgendaDetailAnimation()
        }
    }

    function restartAgendaSectionAnimation() {
        if (popupType !== "agenda" || !open)
            return

        agendaSectionAnimation.stop()
        agendaSectionIntroProgress = 0
        agendaSectionAnimation.from = 0
        agendaSectionAnimation.to = 1
        agendaSectionAnimation.duration = 560
        agendaSectionAnimation.restart()
    }

    function restartAgendaDetailAnimation() {
        if (popupType !== "agenda" || !open)
            return

        agendaDetailAnimation.stop()
        agendaDetailIntroProgress = 0
        agendaDetailAnimation.from = 0
        agendaDetailAnimation.to = 1
        agendaDetailAnimation.duration = 470
        agendaDetailAnimation.restart()
    }

    function animateReveal() {
        revealAnimation.stop()
        revealAnimation.from = revealProgress
        revealAnimation.to = open ? 1 : 0
        revealAnimation.duration = open || lineReveal ? motionPanelIn : motionPanelOut
        revealAnimation.easing.type = open || lineReveal ? motionEaseEnter : motionEaseExit
        revealAnimation.restart()
    }

    function refreshStatusQueries() {
        if (!backgroundPollingActive || typeof volumeQuery === "undefined")
            return

        if (!volumeQuery.running)
            volumeQuery.running = true
        if (!brightnessQuery.running)
            brightnessQuery.running = true
        if (!wifiQuery.running)
            wifiQuery.running = true
        if (!notificationQuery.running)
            notificationQuery.running = true
        if (!root.nativeBluetoothAvailable && !bluetoothQuery.running)
            bluetoothQuery.running = true
        if ((popupType === "files" || popupType === "profile") && !filesQuery.running)
            filesQuery.running = true
        if ((popupType === "battery" || popupType === "notifications") && !batteryQuery.running)
            batteryQuery.running = true
    }

    HoverHandler {
        onHoveredChanged: root.pointerInsideChanged(hovered)
    }

    onOpenChanged: {
        animateReveal()
        if (open) {
            restartEntryAnimation()
            restartPopupIntroAnimation()
            if (popupType === "search")
                ensureSearchReady()
            refreshStatusQueries()
            if (popupType === "wallpaperVisibility")
                ensureWallpaperVisibilityLoaded()
            if (popupType === "time" || popupType === "agenda")
                ensureEventsLoaded(false)
            if (popupType === "time" || popupType === "weatherPanel")
                ensureWeatherLoaded(false)
            if (popupType === "weatherPanel")
                ensureWeatherDetailsLoaded(false)
            if (popupType === "agenda")
                ensureLabelsLoaded(false)
        } else {
            exitEntryAnimation()
        }
    }

    onVisibleChanged: {
        if (visible && open) {
            if (revealProgress <= 0.001 && !revealAnimation.running)
                animateReveal()
            if (!entryAnimation.running && entryProgress <= 0.001)
                restartEntryAnimation()
            if (usesPopupIntro(popupType) && !popupIntroAnimation.running && popupIntroProgress <= 0.001)
                restartPopupIntroAnimation()
            refreshStatusQueries()
        }
    }

    onPopupTypeChanged: {
        if (visible) {
            restartEntryAnimation()
            restartPopupIntroAnimation()
        }
        if (open) {
            refreshStatusQueries()
        }
        if (popupType === "search" && open)
            ensureSearchReady()
        if (popupType === "wallpaperVisibility" && open)
            ensureWallpaperVisibilityLoaded()
        if ((popupType === "time" || popupType === "agenda") && open)
            ensureEventsLoaded(false)
        if ((popupType === "time" || popupType === "weatherPanel") && open)
            ensureWeatherLoaded(false)
        if (popupType === "weatherPanel" && open)
            ensureWeatherDetailsLoaded(false)
        if (popupType === "agenda" && open)
            ensureLabelsLoaded(false)
    }

    onAgendaSectionChanged: {
        restartAgendaSectionAnimation()
        labelMenuIndex = -1
        if (popupType === "agenda" && agendaSection === "labels")
            ensureLabelsLoaded(false)
    }
    onAgendaEditingChanged: restartAgendaDetailAnimation()
    onAgendaSelectedIndexChanged: {
        if (!agendaEditing)
            restartAgendaDetailAnimation()
    }
    onLabelEditingChanged: restartAgendaDetailAnimation()
    onLabelSelectedIndexChanged: {
        if (!labelEditing)
            restartAgendaDetailAnimation()
    }

    function shellQuote(text) {
        return "'" + String(text || "").replace(/'/g, "'\\''") + "'"
    }

    function runCommand(command) {
        if (!command || command.length <= 0)
            return

        root.pendingCommand = command
        commandDebounce.restart()
    }

    function runDetached(command) {
        if (!command || command.length <= 0)
            return

        runCommand(command + " >/dev/null 2>&1 &")
    }

    function openPath(path) {
        const target = textOf(path)
        if (target.length <= 0)
            return

        runDetached("xdg-open " + shellQuote(target))
    }

    function openUrl(url) {
        const target = textOf(url)
        if (target.length <= 0)
            return

        runDetached("(command -v zen-browser >/dev/null 2>&1 && zen-browser " + shellQuote(target) + " || xdg-open " + shellQuote(target) + ")")
    }

    function openSettings(module) {
        const suffix = textOf(module)
        var command = "if command -v systemsettings >/dev/null 2>&1; then systemsettings"
        if (suffix.length > 0)
            command += " " + suffix
        command += "; elif command -v gnome-control-center >/dev/null 2>&1; then gnome-control-center"
        command += "; elif command -v nwg-look >/dev/null 2>&1; then nwg-look"
        command += "; fi"
        runDetached(command)
    }

    function openFileSearch() {
        runDetached("if command -v fsearch >/dev/null 2>&1; then fsearch; elif command -v dolphin >/dev/null 2>&1; then dolphin --new-window " + shellQuote(homeDir) + "; else xdg-open " + shellQuote(homeDir) + "; fi")
    }

    function openTrash() {
        runDetached("xdg-open trash:/// || xdg-open " + shellQuote(homeDir + "/.local/share/Trash/files"))
    }

    function browserSearch() {
        const query = searchQuery.trim().length > 0 ? searchQuery.trim() : "Velora Shell"
        openUrl("https://www.google.com/search?q=" + encodeURIComponent(query))
    }

    function browserCommand(action) {
        if (action === "new-window") {
            runDetached("if command -v zen-browser >/dev/null 2>&1; then zen-browser --new-window about:newtab; else xdg-open about:blank; fi")
            return
        }
        if (action === "private") {
            runDetached("if command -v zen-browser >/dev/null 2>&1; then zen-browser --private-window; elif command -v firefox >/dev/null 2>&1; then firefox --private-window; else xdg-open about:blank; fi")
            return
        }
        if (action === "downloads") {
            runDetached("if command -v zen-browser >/dev/null 2>&1; then zen-browser about:downloads; else xdg-open " + shellQuote(homeDir + "/Downloads") + "; fi")
            return
        }
        if (action === "bookmarks") {
            runDetached("if command -v zen-browser >/dev/null 2>&1; then zen-browser about:preferences#search; else xdg-open about:blank; fi")
            return
        }
        openUrl("about:newtab")
    }

    function openCalendarApp() {
        runDetached("if command -v kalendar >/dev/null 2>&1; then kalendar; elif command -v gnome-calendar >/dev/null 2>&1; then gnome-calendar; else xdg-open https://calendar.google.com; fi")
    }

    function openClockApp() {
        runDetached("if command -v kclock >/dev/null 2>&1; then kclock; elif command -v gnome-clocks >/dev/null 2>&1; then gnome-clocks; fi")
    }

    function textOf(value) {
        if (value === undefined || value === null)
            return ""
        return String(value)
    }

    function searchEntryText(entry) {
        if (!entry)
            return ""

        return (textOf(entry.name) + " "
            + textOf(entry.genericName) + " "
            + textOf(entry.comment) + " "
            + textOf(entry.execString) + " "
            + textOf(entry.id) + " "
            + textOf(entry.categories ? entry.categories.join(" ") : "") + " "
            + textOf(entry.keywords ? entry.keywords.join(" ") : "")).toLowerCase()
    }

    function searchEntryKind(entry) {
        var data = searchEntryText(entry)

        if (data.indexOf("settings") >= 0 || data.indexOf("configuration") >= 0 || data.indexOf("control") >= 0)
            return "settings"
        if (data.indexOf("filemanager") >= 0 || data.indexOf("file manager") >= 0 || data.indexOf("folder") >= 0 || data.indexOf("files") >= 0)
            return "files"
        return "apps"
    }

    function searchModeMatches(entry) {
        if (searchMode === "settings" || searchMode === "files")
            return searchEntryKind(entry) === searchMode
        return true
    }

    function rebuildSearch() {
        var list = DesktopEntries.applications.values || []
        var query = textOf(searchQuery).toLowerCase().trim()
        var out = []
        var scanLimit = query.length > 0 ? 48 : 10

        for (var i = 0; i < list.length; ++i) {
            var entry = list[i]

            if (!entry || entry.noDisplay || !searchModeMatches(entry))
                continue
            if (query.length > 0 && searchEntryText(entry).indexOf(query) < 0)
                continue

            out.push(entry)
            if (out.length >= scanLimit)
                break
        }

        if (query.length > 0)
            out.sort(function(a, b) {
                return textOf(a.name).localeCompare(textOf(b.name))
            })

        searchResults = out.slice(0, 4)
        searchSelectedIndex = Math.max(0, Math.min(searchSelectedIndex, Math.max(0, searchResults.length - 1)))
        searchReady = true
    }

    function ensureSearchReady() {
        if (!searchReady)
            rebuildSearch()
    }

    function setSearchMode(mode) {
        searchMode = mode
        searchSelectedIndex = 0
        if (!open || popupType !== "search")
            searchReady = false
    }

    function stepSearch(delta) {
        if (searchResults.length <= 0)
            return

        searchSelectedIndex = Math.max(0, Math.min(searchResults.length - 1, searchSelectedIndex + delta))
    }

    function launchSearchEntry(entry) {
        if (!entry)
            return

        entry.execute()
        searchQuery = ""
        searchSelectedIndex = 0
        rebuildSearch()
        closeRequested()
    }

    function launchSelectedSearchEntry() {
        if (searchResults.length <= 0)
            return

        launchSearchEntry(searchResults[searchSelectedIndex])
    }

    function requestSearchFocus() {
        if (popupType === "search")
            searchFocusRequest += 1
    }

    function ensureEventsLoaded(force) {
        if (!force && (eventsLoaded || eventsLoadProcess.running))
            return

        eventsLoadProcess.command = [root.eventsScript, "list"]
        eventsLoadProcess.running = true
    }

    function ensureLabelsLoaded(force) {
        if (!force && (labelsLoaded || labelsLoadProcess.running))
            return

        labelsLoadProcess.command = [root.eventsScript, "labels-list"]
        labelsLoadProcess.running = true
    }

    function ensureWeatherLoaded(force) {
        if (!force && weatherQuery.running)
            return

        weatherQuery.command = force ? [root.weatherScript, "--force"] : [root.weatherScript]
        weatherQuery.running = true
    }

    function ensureWeatherDetailsLoaded(force) {
        if (!force && weatherDetailQuery.running)
            return

        weatherDetailQuery.command = force ? [root.weatherScript, "json", "--force"] : [root.weatherScript, "json"]
        weatherDetailQuery.running = true
    }

    function weatherCelsiusText(value) {
        const raw = textOf(value).replace("+", "").trim()
        if (raw.length <= 0 || raw === "--")
            return "--°C"
        return raw + "°C"
    }

    function weatherPercentText(value) {
        const raw = textOf(value).replace("%", "").trim()
        if (raw.length <= 0 || raw === "--")
            return "--"
        return raw + "%"
    }

    function weatherWindTextFrom(value, dir) {
        const raw = textOf(value).trim()
        if (raw.length <= 0 || raw === "--")
            return "--"
        const suffix = textOf(dir).trim()
        return raw + " km/h" + (suffix.length > 0 ? " " + suffix : "")
    }

    function weatherHourlyModel() {
        if (weatherHourlyItems && weatherHourlyItems.length > 0)
            return weatherHourlyItems
        return [{
            time: "Agora",
            temp: textOf(weatherTempText).replace("°C", ""),
            desc: weatherDesc,
            icon: weatherIconName,
            rain: "--"
        }]
    }

    function weatherDailyModel() {
        if (weatherDailyItems && weatherDailyItems.length > 0)
            return weatherDailyItems
        return [{
            label: "Hoje",
            date: todayIso(),
            max: textOf(weatherTempText).replace("°C", ""),
            min: textOf(weatherTempText).replace("°C", ""),
            desc: weatherDesc,
            rain: "--",
            icon: weatherIconName
        }]
    }

    function todayIso() {
        return Qt.formatDateTime(new Date(), "yyyy-MM-dd")
    }

    function eventAccentName(index) {
        const names = ["blue", "orange", "green", "purple"]
        return names[Math.max(0, index) % names.length]
    }

    function eventAccentColor(name) {
        const key = textOf(name)
        if (key === "orange")
            return Qt.rgba(0.86, 0.48, 0.12, 1)
        if (key === "green")
            return Qt.rgba(0.35, 0.68, 0.32, 1)
        if (key === "purple")
            return Qt.rgba(0.50, 0.35, 0.82, 1)
        return root.winAccent2
    }

    function eventIconForCategory(category) {
        const lower = textOf(category).toLowerCase()
        if (lower.indexOf("almoco") >= 0 || lower.indexOf("almoço") >= 0 || lower.indexOf("restaurante") >= 0)
            return "utensils"
        if (lower.indexOf("design") >= 0 || lower.indexOf("revis") >= 0)
            return "pencil"
        if (lower.indexOf("apresent") >= 0 || lower.indexOf("cliente") >= 0)
            return "display"
        if (lower.indexOf("entrevista") >= 0 || lower.indexOf("candidato") >= 0)
            return "search"
        return "calendar"
    }

    function normalizeEvent(raw, index) {
        const item = raw || {}
        const title = textOf(item.title).trim()
        const date = textOf(item.date).trim()
        const start = textOf(item.start).trim()
        const end = textOf(item.end).trim()
        const category = textOf(item.category).trim()
        const icon = textOf(item.iconName).trim()

        return {
            id: textOf(item.id).length > 0 ? textOf(item.id) : String(Date.now()) + "-" + String(index),
            title: title.length > 0 ? title : "Evento sem titulo",
            subtitle: textOf(item.subtitle).trim(),
            date: date.length > 0 ? date : todayIso(),
            start: start.length > 0 ? start : "09:00",
            end: end.length > 0 ? end : "10:00",
            location: textOf(item.location).trim(),
            category: category.length > 0 ? category : "Pessoal",
            description: textOf(item.description).trim(),
            iconName: icon.length > 0 ? icon : eventIconForCategory(category),
            accent: textOf(item.accent).length > 0 ? textOf(item.accent) : eventAccentName(index)
        }
    }

    function sortEventList(list) {
        return list.slice().sort(function(a, b) {
            const left = textOf(a.date) + " " + textOf(a.start) + " " + textOf(a.title)
            const right = textOf(b.date) + " " + textOf(b.start) + " " + textOf(b.title)
            return left.localeCompare(right)
        })
    }

    function eventsArray() {
        var out = []
        for (var i = 0; i < eventModel.count; ++i)
            out.push(normalizeEvent(eventModel.get(i), i))
        return sortEventList(out)
    }

    function eventTimeText(item) {
        if (!item)
            return ""
        const start = textOf(item.start)
        const end = textOf(item.end)
        if (start.length > 0 && end.length > 0)
            return start + " - " + end
        return start.length > 0 ? start : end
    }

    function eventSubtitle(item) {
        if (!item)
            return ""
        const explicit = textOf(item.subtitle)
        if (explicit.length > 0)
            return explicit
        return textOf(item.description).length > 0 ? textOf(item.description) : textOf(item.category)
    }

    function eventDateObject(value) {
        const parts = textOf(value).split("-")
        if (parts.length !== 3)
            return new Date()
        const y = Number(parts[0])
        const m = Number(parts[1])
        const d = Number(parts[2])
        if (isNaN(y) || isNaN(m) || isNaN(d))
            return new Date()
        return new Date(y, m - 1, d)
    }

    function eventDateLabel(value, withYear) {
        const d = eventDateObject(value)
        const months = ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"]
        const base = d.getDate() + " de " + months[d.getMonth()]
        return withYear ? base + " de " + d.getFullYear() : base
    }

    function eventRelativeDate(item) {
        if (!item)
            return ""
        const date = textOf(item.date)
        if (date === todayIso())
            return "Hoje"
        return eventDateLabel(date, false)
    }

    function normalizeLabel(raw, index) {
        const item = raw || {}
        const name = textOf(item.name).trim()
        const accent = textOf(item.accent).trim()
        const icon = textOf(item.iconName).trim()

        return {
            id: textOf(item.id).length > 0 ? textOf(item.id) : "label-" + String(Date.now()) + "-" + String(index),
            name: name.length > 0 ? name : "Nova etiqueta",
            description: textOf(item.description).trim(),
            accent: accent.length > 0 ? accent : eventAccentName(index),
            iconName: icon.length > 0 ? icon : "box"
        }
    }

    function labelsArray() {
        var out = []
        for (var i = 0; i < labelModel.count; ++i)
            out.push(normalizeLabel(labelModel.get(i), i))
        return out
    }

    function selectedLabel() {
        if (labelModel.count <= 0)
            return null
        const next = Math.max(0, Math.min(labelModel.count - 1, labelSelectedIndex))
        return labelModel.get(next)
    }

    function loadLabelsFromArray(items) {
        const source = Array.isArray(items) ? items : []

        labelModel.clear()
        for (var i = 0; i < source.length; ++i)
            labelModel.append(normalizeLabel(source[i], i))

        labelsLoaded = true
        labelMenuIndex = -1
        if (labelModel.count <= 0) {
            labelSelectedIndex = -1
            labelEditing = false
            labelEditingIndex = -1
            fillLabelDraft({})
            return
        }

        if (labelSelectedIndex < 0 || labelSelectedIndex >= labelModel.count)
            labelSelectedIndex = 0
        if (!labelEditing)
            fillLabelDraft(labelModel.get(labelSelectedIndex))
    }

    function flushLabelsSave() {
        if (labelsSaveProcess.running) {
            labelsSaveQueued = true
            return
        }

        labelsSaveQueued = false
        labelsSaveProcess.command = [root.eventsScript, "labels-save", JSON.stringify(labelsArray())]
        labelsSaveProcess.running = true
    }

    function fillLabelDraft(item) {
        const label = normalizeLabel(item || {}, labelEditingIndex)
        labelNameDraft = label.name
        labelDescriptionDraft = label.description
        labelAccentDraft = label.accent
    }

    function selectLabel(index) {
        labelMenuIndex = -1
        if (labelModel.count <= 0) {
            labelSelectedIndex = -1
            labelEditing = false
            labelEditingIndex = -1
            fillLabelDraft({})
            return
        }

        const next = Math.max(0, Math.min(labelModel.count - 1, index))
        labelSelectedIndex = next
        labelEditing = false
        labelEditingIndex = next
        fillLabelDraft(labelModel.get(next))
        restartAgendaDetailAnimation()
    }

    function newLabel() {
        labelMenuIndex = -1
        labelSelectedIndex = -1
        labelEditing = true
        labelEditingIndex = -1
        labelNameDraft = ""
        labelDescriptionDraft = ""
        labelAccentDraft = eventAccentName(labelModel.count)
        restartAgendaDetailAnimation()
    }

    function editLabel(index) {
        if (index < 0 || index >= labelModel.count) {
            newLabel()
            return
        }

        labelMenuIndex = -1
        labelSelectedIndex = index
        labelEditing = true
        labelEditingIndex = index
        fillLabelDraft(labelModel.get(index))
        restartAgendaDetailAnimation()
    }

    function saveLabelDraft() {
        const name = textOf(labelNameDraft).trim()
        if (name.length <= 0)
            return

        const existing = labelEditingIndex >= 0 && labelEditingIndex < labelModel.count ? labelModel.get(labelEditingIndex) : null
        const item = normalizeLabel({
            id: existing ? existing.id : "label-" + String(Date.now()) + "-" + Math.floor(Math.random() * 100000),
            name: name,
            description: textOf(labelDescriptionDraft).trim(),
            accent: textOf(labelAccentDraft).trim(),
            iconName: existing ? existing.iconName : "box"
        }, existing ? labelEditingIndex : labelModel.count)

        if (existing) {
            labelModel.set(labelEditingIndex, item)
            labelSelectedIndex = labelEditingIndex
        } else {
            labelModel.append(item)
            labelSelectedIndex = labelModel.count - 1
        }

        labelEditing = false
        labelEditingIndex = labelSelectedIndex
        fillLabelDraft(labelModel.get(labelSelectedIndex))
        flushLabelsSave()
        restartAgendaDetailAnimation()
    }

    function deleteLabel(index) {
        if (index < 0 || index >= labelModel.count)
            return

        labelModel.remove(index)
        labelMenuIndex = -1
        flushLabelsSave()

        if (labelModel.count > 0)
            selectLabel(Math.min(index, labelModel.count - 1))
        else {
            labelSelectedIndex = -1
            labelEditing = false
            labelEditingIndex = -1
            fillLabelDraft({})
            restartAgendaDetailAnimation()
        }
    }

    function cancelLabelEdit() {
        labelMenuIndex = -1
        if (labelModel.count > 0)
            selectLabel(Math.max(0, labelSelectedIndex))
        else {
            labelEditing = false
            labelEditingIndex = -1
            fillLabelDraft({})
            restartAgendaDetailAnimation()
        }
    }

    function labelEventCount(name) {
        const target = textOf(name).toLowerCase()
        if (target.length <= 0)
            return 0

        var count = 0
        for (var i = 0; i < eventModel.count; ++i) {
            if (textOf(eventModel.get(i).category).toLowerCase() === target)
                count += 1
        }
        return count
    }

    function agendaTopActionText() {
        if (agendaSection === "labels")
            return "Nova etiqueta"
        if (agendaSection === "reminders")
            return "Novo lembrete"
        return "Novo evento"
    }

    function agendaTopPlaceholder() {
        if (agendaSection === "labels")
            return "Buscar etiquetas..."
        if (agendaSection === "reminders")
            return "Buscar lembretes..."
        return "Buscar eventos..."
    }

    function agendaDefaultAction() {
        if (agendaSection === "labels") {
            ensureLabelsLoaded(false)
            newLabel()
            return
        }
        if (agendaSection === "reminders")
            return
        newAgendaEvent()
    }

    function loadEventsFromArray(items) {
        const source = Array.isArray(items) ? items : []
        const sorted = sortEventList(source.map(function(item, index) { return normalizeEvent(item, index) }))

        eventModel.clear()
        for (var i = 0; i < sorted.length; ++i)
            eventModel.append(sorted[i])

        eventsLoaded = true
        if (agendaSelectedIndex >= eventModel.count)
            agendaSelectedIndex = eventModel.count - 1
        if (agendaSelectedIndex < 0 && eventModel.count > 0)
            agendaSelectedIndex = 0
    }

    function flushEventsSave() {
        if (eventsSaveProcess.running) {
            eventsSaveQueued = true
            return
        }

        eventsSaveQueued = false
        eventsSaveProcess.command = [root.eventsScript, "save", JSON.stringify(eventsArray())]
        eventsSaveProcess.running = true
    }

    function fillAgendaDraft(item) {
        const event = normalizeEvent(item || {}, agendaEditingIndex)
        agendaTitleDraft = event.title
        agendaDateDraft = event.date
        agendaStartDraft = event.start
        agendaEndDraft = event.end
        agendaLocationDraft = event.location
        agendaCategoryDraft = event.category
        agendaDescriptionDraft = event.description
    }

    function selectAgendaEvent(index) {
        if (eventModel.count <= 0) {
            agendaSelectedIndex = -1
            agendaEditing = false
            agendaEditingIndex = -1
            fillAgendaDraft({})
            return
        }

        const next = Math.max(0, Math.min(eventModel.count - 1, index))
        agendaSelectedIndex = next
        agendaEditing = false
        agendaEditingIndex = next
        fillAgendaDraft(eventModel.get(next))
    }

    function newAgendaEvent() {
        agendaSelectedIndex = -1
        agendaEditing = true
        agendaEditingIndex = -1
        agendaTitleDraft = ""
        agendaDateDraft = todayIso()
        agendaStartDraft = "09:00"
        agendaEndDraft = "10:00"
        agendaLocationDraft = ""
        agendaCategoryDraft = "Pessoal"
        agendaDescriptionDraft = ""
    }

    function editAgendaEvent(index) {
        if (index < 0 || index >= eventModel.count) {
            newAgendaEvent()
            return
        }
        agendaSelectedIndex = index
        agendaEditing = true
        agendaEditingIndex = index
        fillAgendaDraft(eventModel.get(index))
    }

    function saveAgendaDraft() {
        const title = textOf(agendaTitleDraft).trim()
        if (title.length <= 0)
            return

        const existing = agendaEditingIndex >= 0 && agendaEditingIndex < eventModel.count ? eventModel.get(agendaEditingIndex) : null
        const item = normalizeEvent({
            id: existing ? existing.id : String(Date.now()) + "-" + Math.floor(Math.random() * 100000),
            title: title,
            date: textOf(agendaDateDraft).trim().length > 0 ? textOf(agendaDateDraft).trim() : todayIso(),
            start: textOf(agendaStartDraft).trim(),
            end: textOf(agendaEndDraft).trim(),
            location: textOf(agendaLocationDraft).trim(),
            category: textOf(agendaCategoryDraft).trim(),
            description: textOf(agendaDescriptionDraft).trim(),
            iconName: eventIconForCategory(agendaCategoryDraft),
            accent: existing ? existing.accent : eventAccentName(eventModel.count)
        }, eventModel.count)

        if (existing)
            eventModel.set(agendaEditingIndex, item)
        else
            eventModel.append(item)

        loadEventsFromArray(eventsArray())
        for (var i = 0; i < eventModel.count; ++i) {
            if (eventModel.get(i).id === item.id) {
                selectAgendaEvent(i)
                break
            }
        }
        flushEventsSave()
    }

    function deleteAgendaEvent(index) {
        if (index < 0 || index >= eventModel.count)
            return
        eventModel.remove(index)
        flushEventsSave()
        if (eventModel.count > 0)
            selectAgendaEvent(Math.min(index, eventModel.count - 1))
        else {
            agendaSelectedIndex = -1
            agendaEditing = false
            agendaEditingIndex = -1
            fillAgendaDraft({})
        }
    }

    function setVolume(value) {
        root.volumePercent = Math.max(0, Math.min(1, value))
        runCommand("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + Math.round(root.volumePercent * 100) + "%")
    }

    function setMicVolume(value) {
        root.micVolumePercent = Math.max(0, Math.min(1, value))
        runCommand("wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + Math.round(root.micVolumePercent * 100) + "%")
    }

    function toggleMute() {
        root.muted = !root.muted
        runCommand("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
    }

    function toggleMicMute() {
        root.micMuted = !root.micMuted
        runCommand("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
    }

    function setBrightness(value) {
        root.brightnessPercent = Math.max(0.05, Math.min(1, value))
        runCommand("brightnessctl set " + Math.round(root.brightnessPercent * 100) + "% >/dev/null 2>&1")
    }

    function toggleNightLight() {
        root.nightLightEnabled = !root.nightLightEnabled
        runCommand(root.nightLightEnabled ? "hyprctl hyprsunset temperature 4500 >/dev/null 2>&1 || true" : "hyprctl hyprsunset identity >/dev/null 2>&1 || true")
    }

    function toggleWifi() {
        root.wifiEnabled = !root.wifiEnabled
        runCommand("nmcli radio wifi " + (root.wifiEnabled ? "on" : "off") + " >/dev/null 2>&1")
        wifiRefresh.restart()
    }

    function connectWifi(ssid) {
        if (!ssid || ssid.length <= 0)
            return

        const quotedSsid = shellQuote(ssid)
        runCommand("if nmcli -t -f NAME connection show | grep -Fx -- " + quotedSsid + " >/dev/null 2>&1; then nmcli connection up id " + quotedSsid + " >/dev/null 2>&1 || nmcli dev wifi connect " + quotedSsid + " >/dev/null 2>&1 || true; else nmcli dev wifi connect " + quotedSsid + " >/dev/null 2>&1 || (command -v nm-connection-editor >/dev/null 2>&1 && nm-connection-editor >/dev/null 2>&1 &); fi")
        wifiRefresh.restart()
    }

    function toggleAirplaneMode() {
        root.wifiEnabled = false
        runCommand("nmcli radio all off >/dev/null 2>&1 || nmcli radio wifi off >/dev/null 2>&1 || true")
        wifiRefresh.restart()
        bluetoothRefresh.restart()
    }

    function toggleHotspot() {
        runDetached("if command -v nm-connection-editor >/dev/null 2>&1; then nm-connection-editor; elif command -v systemsettings >/dev/null 2>&1; then systemsettings kcm_networkmanagement; fi")
    }

    function setPowerProfile(profile) {
        const value = textOf(profile)
        if (value.length <= 0)
            return

        powerProfile = value
        runCommand("powerprofilesctl set " + shellQuote(value) + " >/dev/null 2>&1 || true")
    }

    function togglePowerSaver() {
        setPowerProfile(powerProfile === "performance" ? "balanced" : "performance")
    }

    function openDisplaySettings() {
        openSettings("kcm_kscreen")
    }

    function openAudioSettings() {
        runDetached("if command -v pavucontrol >/dev/null 2>&1; then pavucontrol; else " + "systemsettings kcm_pulseaudio 2>/dev/null || gnome-control-center sound 2>/dev/null || true; fi")
    }

    function openNetworkSettings() {
        runDetached("if command -v nm-connection-editor >/dev/null 2>&1; then nm-connection-editor; elif command -v systemsettings >/dev/null 2>&1; then systemsettings kcm_networkmanagement; elif command -v gnome-control-center >/dev/null 2>&1; then gnome-control-center wifi; fi")
    }

    function deviceKnown(address) {
        const addr = textOf(address)
        if (addr.length <= 0)
            return true

        for (var i = 0; i < deviceModel.count; ++i) {
            if (deviceModel.get(i).address === addr)
                return true
        }

        return false
    }

    function deviceIconLabel(name) {
        const lower = textOf(name).toLowerCase()
        if (lower.indexOf("key") >= 0 || lower.indexOf("keyboard") >= 0)
            return "⌨"
        if (lower.indexOf("mouse") >= 0 || lower.indexOf("mx master") >= 0)
            return "▯"
        return ""
    }

    function deviceIconName(name) {
        const lower = textOf(name).toLowerCase()
        if (lower.indexOf("airpods") >= 0 || lower.indexOf("buds") >= 0 || lower.indexOf("head") >= 0 || lower.indexOf("speaker") >= 0)
            return "volume"
        return "bluetooth"
    }

    function setBluetoothPower(enabled) {
        if (!bluetoothIsAvailable)
            return

        if (nativeBluetoothAvailable) {
            const adapter = Bluetooth.defaultAdapter
            if (adapter) {
                adapter.enabled = enabled
                if (enabled)
                    adapter.discovering = true
            }
            return
        }

        bluetoothPowered = enabled
        runCommand("bluetoothctl power " + (enabled ? "on" : "off") + " >/dev/null 2>&1 || true")
        bluetoothRefresh.restart()
    }

    function toggleBluetoothPower() {
        setBluetoothPower(!bluetoothIsPowered)
    }

    function setBluetoothDeviceConnection(address, active) {
        const addr = textOf(address)
        if (!bluetoothIsAvailable || addr.length <= 0)
            return

        if (nativeBluetoothAvailable) {
            const device = nativeBluetoothDevice(addr)
            if (!device)
                return
            if (device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting)
                return
            if (device.connected)
                device.disconnect()
            else if (device.bonded || device.paired)
                device.connect()
            else
                device.pair()
            return
        }

        runCommand("bluetoothctl " + (active ? "disconnect " : "connect ") + root.shellQuote(addr) + " >/dev/null 2>&1 || true")
        bluetoothRefresh.restart()
    }

    function nativeBluetoothDevice(address) {
        const addr = textOf(address)
        for (var i = 0; i < nativeBluetoothItems.length; ++i) {
            const device = nativeBluetoothItems[i]
            if (device && device.address === addr)
                return device
        }
        return null
    }

    function bluetoothDeviceCount() {
        return nativeBluetoothAvailable ? nativeBluetoothItems.length : deviceModel.count
    }

    function bluetoothDeviceAt(index) {
        if (nativeBluetoothAvailable) {
            const device = nativeBluetoothItems[index]
            if (!device)
                return { address: "", name: "", detail: "", active: false, loading: false, iconName: "bluetooth", iconLabel: "" }
            const loading = device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting
            const active = device.state === BluetoothDeviceState.Connected || device.connected
            var detail = active ? "connected" : ((device.bonded || device.paired) ? "paired" : "known")
            if (loading)
                detail = device.state === BluetoothDeviceState.Connecting ? "connecting" : "disconnecting"
            if (device.batteryAvailable)
                detail += " · " + Math.round(device.battery * 100) + "%"
            return {
                address: device.address,
                name: device.name || device.deviceName || device.address,
                detail: detail,
                active: active,
                loading: loading,
                iconName: root.deviceIconName(device.name || device.deviceName || device.icon || ""),
                iconLabel: root.deviceIconLabel(device.name || device.deviceName || "")
            }
        }
        if (index >= 0 && index < deviceModel.count)
            return deviceModel.get(index)
        return { address: "", name: "", detail: "", active: false, loading: false, iconName: "bluetooth", iconLabel: "" }
    }

    function activeWifi() {
        for (var i = 0; i < wifiModel.count; ++i) {
            var item = wifiModel.get(i)
            if (item.active)
                return item
        }

        return null
    }

    function signalBars(signal) {
        if (signal >= 75)
            return 4
        if (signal >= 50)
            return 3
        if (signal >= 25)
            return 2
        return 1
    }

    function refreshBatteryDevice() {
        batteryDevice = null
        for (const dev of UPower.devices.values) {
            if (dev && dev.isLaptopBattery) {
                batteryDevice = dev
                return
            }
        }
    }

    function batteryAvailable() {
        return batteryDevice && batteryDevice.ready
    }

    function batteryPercent() {
        if (!batteryAvailable())
            return 0
        const value = Number(batteryDevice.percentage)
        if (isNaN(value))
            return 0
        return Math.max(0, Math.min(1, value > 1 ? value / 100 : value))
    }

    function batteryText() {
        return batteryAvailable() ? Math.round(batteryPercent() * 100) + "%" : "N/A"
    }

    function wallpaperKey(entry) {
        if (!entry)
            return ""
        return String(entry.path || "")
    }

    function wallpaperTitle(entry) {
        if (!entry)
            return "Wallpaper"
        return entry.title || entry.label || basename(entry.path)
    }

    function displaySource(entry) {
        if (!entry)
            return ""
        if (entry.preview && String(entry.preview).length > 0)
            return entry.preview
        if ((entry.kind || "static") !== "engine")
            return entry.path || ""
        return ""
    }

    function basename(path) {
        var name = String(path || "").split("/").pop()
        var dot = name.lastIndexOf(".")
        if (dot > 0)
            name = name.slice(0, dot)
        return name.replace(/[-_]+/g, " ")
    }

    function kindCategory(kind) {
        if (kind === "live")
            return "MPV"
        if (kind === "engine")
            return "Engine"
        return "Static"
    }

    function isWallpaperHidden(entry) {
        const key = wallpaperKey(entry)
        return key.length > 0 && hiddenWallpapers.indexOf(key) >= 0
    }

    function visibleWallpaperCount() {
        var count = 0
        for (var i = 0; i < wallpaperItems.length; ++i) {
            if (!isWallpaperHidden(wallpaperItems[i]))
                count += 1
        }
        return count
    }

    function ensureWallpaperVisibilityLoaded() {
        if (!wallpaperVisibilityLoaded && !wallpaperScanProcess.running) {
            wallpaperScanProcess.running = true
            wallpaperVisibilityLoaded = true
        }
        if (!wallpaperVisibilityLoadProcess.running)
            wallpaperVisibilityLoadProcess.running = true
    }

    function toggleWallpaperHidden(entry) {
        const key = wallpaperKey(entry)
        if (key.length <= 0)
            return

        var next = hiddenWallpapers.slice()
        const idx = next.indexOf(key)
        if (idx >= 0)
            next.splice(idx, 1)
        else
            next.push(key)

        hiddenWallpapers = next
        queueWallpaperVisibilitySave()
    }

    function hideAllWallpapers() {
        var next = []
        var seen = {}
        for (var i = 0; i < wallpaperItems.length; ++i) {
            const key = wallpaperKey(wallpaperItems[i])
            if (key.length > 0 && !seen[key]) {
                seen[key] = true
                next.push(key)
            }
        }

        hiddenWallpapers = next
        queueWallpaperVisibilitySave()
    }

    function showAllWallpapers() {
        hiddenWallpapers = []
        queueWallpaperVisibilitySave()
    }

    function queueWallpaperVisibilitySave() {
        wallpaperVisibilitySaveQueued = true
        wallpaperVisibilitySaveDebounce.restart()
    }

    function flushWallpaperVisibilitySave() {
        if (wallpaperVisibilitySaveProcess.running)
            return

        wallpaperVisibilitySaveQueued = false
        wallpaperVisibilitySaveProcess.command = [visibilityScript, "set", JSON.stringify(hiddenWallpapers)]
        wallpaperVisibilitySaveProcess.running = true
    }

    function dismissNotification(notificationId) {
        if (notificationId === undefined || notificationId === null || String(notificationId).length <= 0)
            return

        removeNotificationById(notificationId)
        if (!dismissTrackedNotification(notificationId))
            runCommand("makoctl dismiss -n " + String(notificationId) + " >/dev/null 2>&1 || true")
        notificationRefresh.restart()
    }

    function clearNotifications() {
        var values = trackedNotificationValues()
        for (var i = values.length - 1; i >= 0; --i) {
            if (values[i])
                values[i].dismiss()
        }

        notificationModel.clear()
        runCommand("makoctl dismiss --all >/dev/null 2>&1 || true")
    }

    function notificationTitle(notification) {
        return (notification && (notification.summary || notification.title || notification["summary"])) || "通知"
    }

    function notificationBody(notification) {
        return (notification && (notification.body || notification["body"])) || ""
    }

    function notificationApp(notification) {
        return (notification && (notification.appName || notification.app || notification.app_name || notification.application || notification.desktopEntry || notification.desktop_entry || notification["app-name"])) || "System"
    }

    function notificationTime(notification) {
        var value = notification && (notification.time || notification.timestamp)
        if (!value)
            return "now"
        if (typeof value === "string")
            return value

        var d = new Date(value)
        if (isNaN(d.getTime()))
            return "now"

        return Qt.formatDateTime(d, "HH:mm")
    }

    function normalizeNotification(raw) {
        return {
            id: raw.id || raw.ID || raw.notificationId || "",
            app: root.notificationApp(raw),
            summary: root.notificationTitle(raw),
            body: root.notificationBody(raw),
            timeText: root.notificationTime(raw)
        }
    }

    function upsertNotification(raw) {
        if (!raw)
            return

        var item = root.normalizeNotification(raw)
        item.id = String(item.id || "")
        if (item.summary.length <= 0 && item.body.length <= 0)
            return
        if (item.timeText === "now")
            item.timeText = Qt.formatTime(new Date(), "HH:mm")

        for (var i = 0; i < notificationModel.count; ++i) {
            var current = notificationModel.get(i)
            if ((item.id.length > 0 && current.id === item.id)
                    || (current.app === item.app && current.summary === item.summary)) {
                notificationModel.set(i, item)
                return
            }
        }

        notificationModel.insert(0, item)
        while (notificationModel.count > 8)
            notificationModel.remove(notificationModel.count - 1)
    }

    function dismissTrackedNotification(notificationId) {
        const id = String(notificationId || "")
        if (id.length <= 0)
            return false

        var values = trackedNotificationValues()
        for (var i = 0; i < values.length; ++i) {
            if (values[i] && String(values[i].id || "") === id) {
                values[i].dismiss()
                return true
            }
        }

        return false
    }

    function removeNotificationById(notificationId) {
        const id = String(notificationId || "")
        if (id.length <= 0)
            return

        for (var i = notificationModel.count - 1; i >= 0; --i) {
            if (notificationModel.get(i).id === id)
                notificationModel.remove(i)
        }
    }

    function trackedNotificationValues() {
        const tracked = NotificationServer.trackedNotifications
        return tracked && tracked.values ? tracked.values : []
    }

    function syncTrackedNotifications() {
        var values = trackedNotificationValues()
        notificationModel.clear()

        for (var i = values.length - 1; i >= 0; --i)
            upsertNotification(values[i])
    }

    Component.onCompleted: {
        refreshBatteryDevice()
        syncTrackedNotifications()
        if (open && popupType === "search")
            ensureSearchReady()
        if (open && (popupType === "time" || popupType === "agenda"))
            ensureEventsLoaded(false)
        refreshStatusQueries()
    }

    Connections {
        target: UPower.devices

        function onValuesChanged() {
            root.refreshBatteryDevice()
        }
    }

    onSearchQueryChanged: {
        searchSelectedIndex = 0
        if (open && popupType === "search")
            rebuildSearch()
        else
            searchReady = false
    }

    onSearchModeChanged: {
        searchSelectedIndex = 0
        if (open && popupType === "search")
            rebuildSearch()
        else
            searchReady = false
    }

    Connections {
        target: DesktopEntries.applications

        function onValuesChanged() {
            if (root.open && root.popupType === "search")
                root.rebuildSearch()
            else
                root.searchReady = false
        }
    }

    Connections {
        target: NotificationServer

        function onNotification(notification) {
            if (!notification)
                return

            notification.tracked = true
            root.upsertNotification(notification)
            notification.closed.connect(function() {
                root.removeNotificationById(notification.id)
            })
        }

        function onTrackedNotificationsChanged() {
            root.syncTrackedNotifications()
        }
    }

    Timer {
        interval: 7000
        running: root.backgroundPollingActive
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.refreshStatusQueries()
        }
    }

    Timer {
        id: wifiRefresh
        interval: 800
        repeat: false
        onTriggered: {
            if (!root.backgroundPollingActive)
                return
            if (!wifiQuery.running)
                wifiQuery.running = true
            if (!notificationQuery.running)
                notificationQuery.running = true
        }
    }

    Timer {
        id: notificationRefresh
        interval: 1200
        repeat: false
        onTriggered: {
            if (!root.backgroundPollingActive)
                return
            if (!notificationQuery.running)
                notificationQuery.running = true
        }
    }

    Timer {
        id: bluetoothRefresh
        interval: 900
        repeat: false
        onTriggered: {
            if (!root.backgroundPollingActive)
                return
            if (!root.nativeBluetoothAvailable && !bluetoothQuery.running)
                bluetoothQuery.running = true
        }
    }

    Timer {
        id: commandDebounce
        interval: 80
        repeat: false
        onTriggered: {
            if (commandRunner.running || root.pendingCommand.length <= 0)
                return

            root.activeCommand = root.pendingCommand
            commandRunner.command = ["bash", "-lc", root.activeCommand]
            commandRunner.running = true
        }
    }

    Process {
        id: commandRunner

        running: false
        command: ["bash", "-lc", ""]
        onExited: {
            running = false
            if (root.pendingCommand !== root.activeCommand)
                commandDebounce.restart()
            if (root.backgroundPollingActive) {
                if (!volumeQuery.running)
                    volumeQuery.running = true
                if (!brightnessQuery.running)
                    brightnessQuery.running = true
                wifiRefresh.restart()
                bluetoothRefresh.restart()
                if ((root.popupType === "files" || root.popupType === "profile") && !filesQuery.running)
                    filesQuery.running = true
                if ((root.popupType === "battery" || root.popupType === "notifications") && !batteryQuery.running)
                    batteryQuery.running = true
            }
        }
    }

    Process {
        id: volumeQuery

        running: false
        command: [root.popupStatusScript, "audio"]

        stdout: SplitParser {
            onRead: function(data) {
                var parts = data.trim().split("|")
                if (parts.length < 3)
                    return

                if (parts[0] === "AUDIO_SINK") {
                    var sinkValue = parseFloat(parts[1])
                    if (!isNaN(sinkValue))
                        root.volumePercent = Math.max(0, Math.min(1, sinkValue))
                    root.muted = parts[2] === "1"
                    root.audioOutputName = parts.length > 3 && parts[3].length > 0 ? parts[3] : "Default output"
                } else if (parts[0] === "AUDIO_SOURCE") {
                    var sourceValue = parseFloat(parts[1])
                    if (!isNaN(sourceValue))
                        root.micVolumePercent = Math.max(0, Math.min(1, sourceValue))
                    root.micMuted = parts[2] === "1"
                    root.audioInputName = parts.length > 3 && parts[3].length > 0 ? parts[3] : "Default input"
                }
            }
        }

        onExited: running = false
    }

    Process {
        id: brightnessQuery

        running: false
        command: [root.popupStatusScript, "brightness"]

        stdout: SplitParser {
            onRead: function(data) {
                var parts = data.trim().split("|")
                var value = parseFloat(parts.length > 1 ? parts[1] : data.trim())
                if (!isNaN(value))
                    root.brightnessPercent = Math.max(0.05, Math.min(1, value))
                if (parts.length > 2)
                    root.brightnessDevice = parts[2]
            }
        }

        onExited: running = false
    }

    ListModel {
        id: wifiModel
    }

    ListModel {
        id: notificationModel
    }

    ListModel {
        id: deviceModel
    }

    ListModel {
        id: recentFolderModel
    }

    ListModel {
        id: recentFileModel
    }

    ListModel {
        id: eventModel
    }

    ListModel {
        id: labelModel
    }

    Process {
        id: eventsLoadProcess

        running: false
        property var stagedEvents: []
        command: [root.eventsScript, "list"]

        onStarted: stagedEvents = []

        stdout: SplitParser {
            onRead: function(data) {
                const raw = String(data || "").trim()
                if (raw.length <= 0)
                    return
                try {
                    const parsed = JSON.parse(raw)
                    eventsLoadProcess.stagedEvents = Array.isArray(parsed) ? parsed : []
                } catch (e) {
                    console.log("Velora events parse error:", e)
                    eventsLoadProcess.stagedEvents = []
                }
            }
        }

        onExited: {
            running = false
            root.loadEventsFromArray(stagedEvents)
        }
    }

    Process {
        id: eventsSaveProcess

        running: false
        command: [root.eventsScript, "save", "[]"]
        onExited: {
            running = false
            if (root.eventsSaveQueued)
                root.flushEventsSave()
        }
    }

    Process {
        id: labelsLoadProcess

        running: false
        property var stagedLabels: []
        command: [root.eventsScript, "labels-list"]

        onStarted: stagedLabels = []

        stdout: SplitParser {
            onRead: function(data) {
                const raw = String(data || "").trim()
                if (raw.length <= 0)
                    return
                try {
                    const parsed = JSON.parse(raw)
                    labelsLoadProcess.stagedLabels = Array.isArray(parsed) ? parsed : []
                } catch (e) {
                    console.log("Velora labels parse error:", e)
                    labelsLoadProcess.stagedLabels = []
                }
            }
        }

        onExited: {
            running = false
            root.loadLabelsFromArray(stagedLabels)
        }
    }

    Process {
        id: labelsSaveProcess

        running: false
        command: [root.eventsScript, "labels-save", "[]"]
        onExited: {
            running = false
            if (root.labelsSaveQueued)
                root.flushLabelsSave()
        }
    }

    Process {
        id: weatherQuery

        running: false
        command: [root.weatherScript]

        stdout: SplitParser {
            onRead: function(data) {
                const raw = String(data || "").trim()
                if (raw.length <= 0)
                    return

                const parts = raw.split("|")
                if (parts.length < 10 || parts[0] !== "WEATHER")
                    return

                root.weatherCity = parts[1]
                root.weatherTempText = root.weatherCelsiusText(parts[2])
                root.weatherHighLowText = "↑ " + root.weatherCelsiusText(parts[3]) + "    ↓ " + root.weatherCelsiusText(parts[4])
                root.weatherDesc = parts[5]
                root.weatherHumidityText = "Umidade: " + (parts[6] === "--" ? "--" : parts[6] + "%")
                root.weatherWindText = "Vento: " + (parts[7] === "--" ? "--" : parts[7] + " km/h")
                root.weatherUpdatedText = parts[9] === "1" ? "Dados em cache" : ""
                root.weatherLoaded = true
            }
        }

        onExited: running = false
    }

    Process {
        id: weatherDetailQuery

        running: false
        command: [root.weatherScript, "json"]

        stdout: SplitParser {
            onRead: function(data) {
                const raw = String(data || "").trim()
                if (raw.length <= 0)
                    return

                try {
                    const parsed = JSON.parse(raw)
                    root.weatherCity = root.textOf(parsed.location) || root.weatherCity
                    root.weatherTempText = root.weatherCelsiusText(parsed.temp)
                    root.weatherHighLowText = "Máx. " + root.weatherCelsiusText(parsed.max) + " · Mín. " + root.weatherCelsiusText(parsed.min)
                    root.weatherDesc = root.textOf(parsed.desc) || root.weatherDesc
                    root.weatherHumidityText = "Umidade: " + root.weatherPercentText(parsed.humidity)
                    root.weatherWindDirectionText = root.textOf(parsed.wind_dir)
                    root.weatherWindText = "Vento: " + root.weatherWindTextFrom(parsed.wind, parsed.wind_dir)
                    root.weatherFeelsText = "Sensação térmica " + root.weatherCelsiusText(parsed.feels)
                    root.weatherRainChanceText = "Chance de chuva " + root.weatherPercentText(parsed.rain)
                    root.weatherUvText = root.textOf(parsed.uv) || "--"
                    root.weatherSunriseText = root.textOf(parsed.sunrise) || "--"
                    root.weatherSunsetText = root.textOf(parsed.sunset) || "--"
                    root.weatherIconName = root.textOf(parsed.icon) || "partly"
                    root.weatherHourlyItems = Array.isArray(parsed.hourly) ? parsed.hourly : []
                    root.weatherDailyItems = Array.isArray(parsed.daily) ? parsed.daily : []
                    root.weatherAirQuality = parsed.air_quality || { label: "Sem dados", aqi: "--", detail: "Qualidade do ar nao disponivel." }
                    root.weatherRainMap = parsed.rain_map || { label: "Sem mapa real", detail: "Radar de chuva indisponivel." }
                    root.weatherUpdatedText = parsed.from_cache ? "Dados em cache" : ""
                    root.weatherLoaded = true
                } catch (e) {
                    console.log("Velora weather detail parse error:", e)
                }
            }
        }

        onExited: running = false
    }

    Timer {
        interval: 15 * 60 * 1000
        repeat: true
        running: root.open && root.visible && (root.popupType === "time" || root.popupType === "weatherPanel")
        onTriggered: {
            root.ensureWeatherLoaded(true)
            if (root.popupType === "weatherPanel")
                root.ensureWeatherDetailsLoaded(true)
        }
    }

    Process {
        id: wifiQuery

        running: false
        command: [root.popupStatusScript, "wifi"]

        stdout: SplitParser {
            onRead: function(lineRaw) {
                var line = lineRaw.trim()
                if (!line)
                    return

                if (line.indexOf("RADIO|") === 0) {
                    root.wifiEnabled = line.indexOf("enabled") >= 0
                    wifiModel.clear()
                    return
                }

                var parts = line.split("|")
                var ssid = parts[1] || ""
                var signal = parseInt(parts[2] || "0")
                var known = false

                for (var i = 0; i < wifiModel.count; ++i) {
                    if (wifiModel.get(i).ssid === ssid) {
                        known = true
                        break
                    }
                }

                if (!known)
                    wifiModel.append({
                        active: (parts[0] || "").toLowerCase() === "yes",
                        ssid: ssid,
                        signal: isNaN(signal) ? 0 : signal,
                        secure: (parts[3] || "").length > 0
                    })
            }
        }

        onExited: running = false
    }

    Process {
        id: notificationQuery

        running: false
        command: [root.popupStatusScript, "notifications"]

        stdout: SplitParser {
            onRead: function(lineRaw) {
                var line = lineRaw.trim()
                if (!line)
                    line = "[]"

                try {
                    var parsed = JSON.parse(line)
                    var items = Array.isArray(parsed) ? parsed : (parsed.data || parsed.notifications || [])

                    if (trackedNotificationValues().length > 0) {
                        root.syncTrackedNotifications()
                        return
                    }

                    notificationModel.clear()
                    for (var i = 0; i < items.length; ++i) {
                        var item = root.normalizeNotification(items[i])
                        notificationModel.append(item)
                    }
                } catch (e) {
                    console.log("Velora notifications parse error:", e)
                }
            }
        }

        onExited: running = false
    }

    Process {
        id: bluetoothQuery

        running: false
        property var stagedDevices: []
        command: [root.popupStatusScript, "bluetooth"]

        onStarted: stagedDevices = []

        stdout: SplitParser {
            onRead: function(lineRaw) {
                var line = lineRaw.trim()
                if (!line)
                    return

                var parts = line.split("|")
                if (parts[0] === "POWER") {
                    var state = (parts[1] || "").toLowerCase()
                    root.bluetoothAvailable = state !== "unavailable"
                    root.bluetoothPowered = state === "yes"
                    deviceModel.clear()
                    bluetoothQuery.stagedDevices = []
                    return
                }

                var kind = parts[0] || ""
                var address = parts[1] || ""
                var name = parts.slice(2).join("|")
                if (address.length <= 0 || name.length <= 0)
                    return

                var active = kind === "CONNECTED"
                var known = false
                for (var i = 0; i < bluetoothQuery.stagedDevices.length; ++i) {
                    if (bluetoothQuery.stagedDevices[i].address === address) {
                        known = true
                        if (active)
                            bluetoothQuery.stagedDevices[i].active = true
                        break
                    }
                }

                if (!known) {
                    bluetoothQuery.stagedDevices.push({
                        address: address,
                        name: name,
                        detail: active ? "connected" : (kind === "PAIRED" ? "paired" : "known"),
                        active: active,
                        iconName: root.deviceIconName(name),
                        iconLabel: root.deviceIconLabel(name)
                    })
                }
            }
        }

        onExited: {
            running = false
            deviceModel.clear()
            for (var i = 0; i < stagedDevices.length; ++i)
                deviceModel.append(stagedDevices[i])
        }
    }

    Process {
        id: filesQuery

        running: false
        command: [root.popupStatusScript, "files"]

        onStarted: {
            recentFolderModel.clear()
            recentFileModel.clear()
        }

        stdout: SplitParser {
            onRead: function(lineRaw) {
                var parts = lineRaw.trim().split("|")
                if (parts.length <= 0 || parts[0].length <= 0)
                    return

                if (parts[0] === "DISK") {
                    root.diskUsageText = parts.length > 1 ? parts[1] : ""
                    var pct = parseFloat(parts.length > 2 ? parts[2] : "0")
                    root.diskUsagePercent = isNaN(pct) ? 0 : Math.max(0, Math.min(1, pct))
                    root.diskMountPoint = parts.length > 3 ? parts[3] : ""
                    return
                }

                if (parts.length < 5)
                    return

                var item = {
                    icon: parts[1],
                    title: parts[2],
                    subtitle: parts[3],
                    path: parts.slice(4).join("|")
                }

                if (parts[0] === "FOLDER" && recentFolderModel.count < 8)
                    recentFolderModel.append(item)
                else if (parts[0] === "FILE" && recentFileModel.count < 8)
                    recentFileModel.append(item)
            }
        }

        onExited: running = false
    }

    Process {
        id: batteryQuery

        running: false
        command: [root.popupStatusScript, "battery"]

        stdout: SplitParser {
            onRead: function(lineRaw) {
                var parts = lineRaw.trim().split("|")
                if (parts.length <= 0)
                    return

                if (parts[0] === "BATTERY") {
                    var value = parseFloat(parts.length > 1 ? parts[1] : "0")
                    if (!isNaN(value) && value > 0)
                        root.batteryDevice = { ready: true, percentage: value }
                    root.batteryStateText = parts.length > 2 && parts[2].length > 0 ? parts[2] : "unknown"
                    root.batteryTimeText = parts.length > 3 ? parts[3] : ""
                } else if (parts[0] === "POWER") {
                    root.powerProfile = parts.length > 1 && parts[1].length > 0 ? parts[1] : "unknown"
                    var online = parts.length > 2 ? parts[2].toLowerCase() : "unknown"
                    root.acOnline = online === "yes" || online === "1" || online === "true" || online === "online"
                }
            }
        }

        onExited: running = false
    }

    Process {
        id: wallpaperScanProcess

        running: false
        property var tmp: []
        command: [root.scanScript]

        onStarted: tmp = []

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data).trim()
                if (!line || line === "BEGIN")
                    return

                if (line === "END") {
                    root.wallpaperItems = wallpaperScanProcess.tmp.length > 0 ? wallpaperScanProcess.tmp.slice() : root.fallbackWallpapers
                    return
                }

                const parts = line.split("|")
                if (parts.length < 3)
                    return

                const kind = parts[0].toLowerCase()
                const path = parts[1]
                const preview = parts[2]
                const title = parts.length > 3 && parts.slice(3).join("|").length > 0
                    ? parts.slice(3).join("|")
                    : root.basename(path)

                wallpaperScanProcess.tmp.push({
                    kind: kind,
                    path: path,
                    preview: preview,
                    title: title,
                    label: title,
                    category: root.kindCategory(kind)
                })
            }
        }

        onExited: {
            running = false
            if (tmp.length > 0)
                root.wallpaperItems = tmp.slice()
            else if (root.wallpaperItems.length <= 0)
                root.wallpaperItems = root.fallbackWallpapers
        }
    }

    Process {
        id: wallpaperVisibilityLoadProcess

        running: false
        command: [root.visibilityScript, "list"]

        stdout: SplitParser {
            onRead: function(data) {
                try {
                    const parsed = JSON.parse(String(data).trim() || "[]")
                    root.hiddenWallpapers = Array.isArray(parsed) ? parsed : []
                } catch(e) {
                    root.hiddenWallpapers = []
                }
            }
        }

        onExited: running = false
    }

    Timer {
        id: wallpaperVisibilitySaveDebounce

        interval: 180
        repeat: false
        onTriggered: root.flushWallpaperVisibilitySave()
    }

    Process {
        id: wallpaperVisibilitySaveProcess

        running: false
        command: [root.visibilityScript, "set", "[]"]
        onExited: {
            running = false
            if (root.wallpaperVisibilitySaveQueued)
                wallpaperVisibilitySaveDebounce.restart()
        }
    }

    opacity: lineReveal ? lineRevealContentProgress : effectiveRevealProgress
    scale: lineReveal ? 1 : 0.972 + effectiveRevealProgress * 0.028
    transformOrigin: attachedRight ? Item.Right : Item.Left
    activeFocusOnTab: true

    transform: Translate {
        x: root.lineReveal ? 0 : Math.round((1 - root.effectiveRevealProgress) * (root.attachedRight ? root.effectiveMotionPanelOffset : -root.effectiveMotionPanelOffset))
        y: 0
    }

    NumberAnimation {
        id: revealAnimation

        target: root
        property: "revealProgress"
        from: root.revealProgress
        to: root.open ? 1 : 0
        duration: root.open ? (root.popupType === "search" ? Math.max(400, root.motionPanelIn) : root.motionPanelIn) : root.motionPanelOut
        easing.type: root.open ? root.motionEaseEnter : root.motionEaseExit
    }

    NumberAnimation {
        id: entryAnimation

        target: root
        property: "entryProgress"
        from: 0
        to: 1
        duration: root.motionSlow
        easing.type: root.motionEaseEmphasized
        easing.bezierCurve: root.motionEmphasizedCurve
    }

    NumberAnimation {
        id: popupIntroAnimation

        target: root
        property: "popupIntroProgress"
        from: 0
        to: 1
        duration: 540
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: agendaSectionAnimation

        target: root
        property: "agendaSectionIntroProgress"
        from: 0
        to: 1
        duration: 560
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: agendaDetailAnimation

        target: root
        property: "agendaDetailIntroProgress"
        from: 0
        to: 1
        duration: 470
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: agendaLoopAnimation

        target: root
        property: "agendaLoopProgress"
        from: 0
        to: 1
        duration: 4200
        loops: Animation.Infinite
        running: root.open && root.visible && (root.popupType === "agenda" || root.popupType === "weatherPanel")
        easing.type: Easing.Linear
    }

    Rectangle {
        visible: !root.externalSurface
        x: 15
        y: 12
        width: panelSurface.width - 2
        height: panelSurface.height - 4
        radius: root.cornerRadius + 1
        color: root.alpha(root.theme ? root.theme.shadowColor : Qt.rgba(0.48, 0.31, 0.47, 1), 0.07)
    }

    Rectangle {
        visible: false
        x: 2
        y: Math.round(root.arrowVisualCenterY - height / 2)
        width: 26
        height: 26
        radius: 5
        rotation: 45
        color: root.glass
        border.width: 1
        border.color: root.neon && root.theme ? root.theme.popupBorderGlow : root.alpha(root.borderSoft, 0.72)
        antialiasing: true

        Behavior on y {
            NumberAnimation {
                duration: root.motionPanelGeometry
                easing.type: root.motionEaseEmphasized
                easing.bezierCurve: root.motionEmphasizedCurve
            }
        }
    }

    Rectangle {
        id: panelSurface

        x: 0
        y: 0
        width: root.width - x
        height: root.height
        radius: root.cornerRadius
        color: root.externalSurface ? "transparent" : root.winSurface
        border.width: root.externalSurface ? 0 : 1
        border.color: root.neon && root.theme ? root.alpha(root.theme.popupBorderGlow, 0.62) : root.winLine
        clip: true
        antialiasing: true
        layer.enabled: !root.externalSurface
        layer.effect: DropShadow {
            transparentBorder: true
            radius: root.neon ? 42 : 30
            samples: root.neon ? 85 : 61
            horizontalOffset: 0
            verticalOffset: root.neon ? 0 : 10
            color: root.neon && root.theme ? root.alpha(root.theme.popupBorderGlow, root.theme.popupBorderGlow.a * 0.50) : root.alpha(root.theme ? root.theme.shadowColor : Qt.rgba(0.40, 0.26, 0.43, 1), 0.13)
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: mouse.accepted = true
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: !root.externalSurface
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.winSurface }
                GradientStop { position: 0.62; color: root.winSurfaceDeep }
                GradientStop { position: 1.0; color: root.alpha(root.winAccent, 0.08) }
            }
        }

        Rectangle {
            visible: !root.externalSurface
            anchors {
                fill: parent
                margins: 1
            }

            radius: parent.radius - 1
            color: "transparent"
            border.width: 1
            border.color: root.alpha(root.theme ? root.theme.borderSoft : Qt.rgba(1, 1, 1, 1), root.neon ? 0.22 : 0.18)
        }

        PopupViewLoader {
            viewType: "profile"
            viewMargins: 18
            sourceComponent: Component { ProfileView {} }
        }

        PopupViewLoader {
            viewType: "time"
            viewMargins: 18
            sourceComponent: Component { TimeView {} }
        }

        PopupViewLoader {
            viewType: "agenda"
            sourceComponent: Component { AgendaView {} }
        }

        PopupViewLoader {
            viewType: "weatherPanel"
            sourceComponent: Component { WeatherView {} }
        }

        PopupViewLoader {
            viewType: "search"
            viewMargins: 18
            sourceComponent: Component {
                VeloraSearchPopup {
                    popup: root
                }
            }
        }

        PopupViewLoader {
            viewType: "files"
            viewMargins: 18
            sourceComponent: Component { FilesView {} }
        }

        PopupViewLoader {
            viewType: "browser"
            viewMargins: 22
            sourceComponent: Component { BrowserView {} }
        }

        PopupViewLoader {
            viewType: "volume"
            viewMargins: 22
            sourceComponent: Component { VolumeView {} }
        }

        PopupViewLoader {
            viewType: "wifi"
            viewMargins: 16
            sourceComponent: Component { WifiView {} }
        }

        PopupViewLoader {
            viewType: "brightness"
            viewMargins: 22
            sourceComponent: Component { BrightnessView {} }
        }

        PopupViewLoader {
            viewType: "notifications"
            viewMargins: 16
            sourceComponent: Component {
                VeloraNotificationsPopup {
                    popup: root
                    notificationsModel: notificationModel
                }
            }
        }

        PopupViewLoader {
            viewType: "battery"
            viewMargins: 18
            sourceComponent: Component {
                VeloraBatteryPopup {
                    popup: root
                }
            }
        }

        PopupViewLoader {
            viewType: "bluetooth"
            viewMargins: 16
            sourceComponent: Component { BluetoothView {} }
        }

        PopupViewLoader {
            viewType: "wallpaperVisibility"
            viewMargins: 15
            sourceComponent: Component { WallpaperVisibilityView {} }
        }
    }

    component PopupViewLoader: Loader {
        property string viewType: ""
        property int viewMargins: 0

        anchors.fill: parent
        anchors.margins: viewMargins
        active: root.popupType === viewType
        visible: active
        asynchronous: false
    }

    component WinCard: Rectangle {
        radius: 12
        color: root.alpha(root.winCard, 0.82)
        border.width: 1
        border.color: root.alpha(root.winAccent, 0.18)
        antialiasing: true
    }

    component WinLabel: Text {
        color: root.ink
        font.family: root.uiFont
        font.pixelSize: 13
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }

    component WinSubLabel: Text {
        color: root.inkSoft
        font.family: root.uiFont
        font.pixelSize: 10
        font.weight: Font.Medium
        elide: Text.ElideRight
    }

    component WinIconTile: Rectangle {
        id: iconTile

        property string iconName: "box"
        property string label: ""
        property bool active: false
        property bool hovered: false
        signal clicked()

        radius: 10
        color: active ? root.alpha(root.winAccent, hovered ? 0.32 : 0.24) : root.alpha(root.winCardHover, hovered ? 0.72 : 0.52)
        border.width: 1
        border.color: active ? root.alpha(root.winAccent, 0.54) : root.alpha(root.winAccent, hovered ? 0.32 : 0.16)

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            PopupIcon {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                iconName: parent.parent.iconName
                lineColor: parent.parent.active ? root.winAccent2 : root.inkSoft
            }

            Text {
                Layout.fillWidth: true
                text: parent.parent.label
                color: parent.parent.active ? root.winAccent2 : root.ink
                horizontalAlignment: Text.AlignHCenter
                font.family: root.uiFont
                font.pixelSize: 10
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            preventStealing: true
            cursorShape: Qt.PointingHandCursor
            onEntered: iconTile.hovered = true
            onExited: iconTile.hovered = false
            onClicked: function(mouse) {
                mouse.accepted = true
                iconTile.clicked()
            }
        }
    }

    component WinActionRow: Rectangle {
        id: row

        property string iconName: "box"
        property string title: ""
        property string subtitle: ""
        property bool accent: false
        property bool hovered: false
        property bool showArrow: true
        signal clicked()

        height: 44
        implicitHeight: height
        radius: 8
        color: hovered ? root.winCardHover : (accent ? root.alpha(root.winAccent, 0.18) : root.alpha(root.winCardHover, 0.40))
        border.width: 1
        border.color: accent ? root.alpha(root.winAccent, 0.48) : root.alpha(root.winAccent, 0.12)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 10

            PopupIcon {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                iconName: row.iconName
                lineColor: row.accent ? root.winAccent2 : root.inkSoft
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                WinLabel {
                    Layout.fillWidth: true
                    text: row.title
                    font.pixelSize: 12
                }

                WinSubLabel {
                    Layout.fillWidth: true
                    visible: row.subtitle.length > 0
                    text: row.subtitle
                }
            }

            Text {
                visible: row.showArrow
                text: "›"
                color: root.inkSoft
                font.family: root.uiFont
                font.pixelSize: 20
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: row.hovered = true
            onExited: row.hovered = false
            onClicked: row.clicked()
        }
    }

    component ProfileView: Item {
        opacity: root.stageOpacity(35, 220)
        transform: Translate { y: root.stageTranslateY(35, 10) }

        RowLayout {
            anchors.fill: parent
            spacing: 20

            WinCard {
                Layout.preferredWidth: 292
                Layout.fillHeight: true
                clip: true

                Image {
                    anchors.fill: parent
                    source: Qt.resolvedUrl("../assets/profile-avatar.png")
                    fillMode: Image.PreserveAspectCrop
                    opacity: 0.36
                    smooth: true
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0.03, 0.07, 0.11, 0.54)
                }

                Rectangle {
                    x: 28
                    y: parent.height * 0.36
                    width: 58
                    height: 58
                    radius: 29
                    color: root.alpha(root.winCardHover, 0.82)
                    border.width: 2
                    border.color: root.alpha(root.borderSoft, 0.78)
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 3
                        source: Qt.resolvedUrl("../assets/profile-avatar.png")
                        fillMode: Image.PreserveAspectCrop
                    }
                }

                Column {
                    x: 28
                    y: parent.height * 0.56
                    width: parent.width - 56
                    spacing: 8

                    Text {
                        width: parent.width
                        text: "レイ"
                        color: root.ink
                        font.family: root.uiFont
                        font.pixelSize: 22
                        font.weight: Font.Bold
                    }

                    Row {
                        spacing: 6
                        Rectangle { width: 8; height: 8; radius: 4; color: "#36d66b"; anchors.verticalCenter: parent.verticalCenter }
                        WinSubLabel { text: "オンライン"; font.pixelSize: 11 }
                    }

                    Rectangle { width: parent.width; height: 1; color: root.winLine }

                    WinSubLabel {
                        width: parent.width
                        text: "“静寂の中で、自分だけの答えを見つける。”"
                        wrapMode: Text.WordWrap
                        font.pixelSize: 11
                    }

                    Item { width: 1; height: 10 }

                    WinSubLabel { text: "テーマ概要"; color: root.winAccent2; font.weight: Font.Bold }
                    WinSubLabel {
                        width: parent.width
                        text: "青空と静寂を基調にした、集中と癒しのためのワークスペースです。"
                        wrapMode: Text.WordWrap
                    }

                    Row {
                        spacing: 7
                        Repeater {
                            model: ["集中", "ミニマル", "ブルー", "癒し"]
                            Rectangle {
                                width: label.implicitWidth + 16
                                height: 24
                                radius: 7
                                color: root.alpha(root.winAccent, 0.13)
                                Text {
                                    id: label
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: root.winAccent2
                                    font.family: root.uiFont
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 8 }

                    WinSubLabel { text: "ストレージ使用状況"; color: root.winAccent2; font.weight: Font.Bold }
                    SliderBar { width: parent.width; value: root.diskUsagePercent; entryDelay: 120 }
                    Row {
                        width: parent.width
                        WinSubLabel { text: root.diskUsageText; width: parent.width - 42 }
                        WinSubLabel { text: Math.round(root.diskUsagePercent * 100) + "%" }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 14

                WinSubLabel {
                    Layout.fillWidth: true
                    text: "ショートカット"
                    color: root.winAccent2
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }

                Repeater {
                    model: [
                        { icon: "download", title: "ダウンロード", cmd: "xdg-open \"$HOME/Downloads\"" },
                        { icon: "memo", title: "ドキュメント", cmd: "xdg-open \"$HOME/Documents\"" },
                        { icon: "image", title: "ピクチャ", cmd: "xdg-open \"$HOME/Pictures\"" },
                        { icon: "volume", title: "ミュージック", cmd: "xdg-open \"$HOME/Music\"" },
                        { icon: "display", title: "ビデオ", cmd: "xdg-open \"$HOME/Videos\"" }
                    ]

                    WinActionRow {
                        Layout.fillWidth: true
                        iconName: modelData.icon
                        title: modelData.title
                        onClicked: root.runCommand(modelData.cmd + " >/dev/null 2>&1 &")
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.winLine }

                WinSubLabel { text: "クイックアクション"; color: root.winAccent2; font.pixelSize: 12; font.weight: Font.Bold }

                Repeater {
                    model: [
                        { icon: "palette", title: "外観のカスタマイズ" },
                        { icon: "box", title: "ウィジェットを管理" },
                        { icon: "display", title: "デスクトップ設定" },
                        { icon: "memo", title: "システム情報" }
                    ]
                    WinActionRow {
                        Layout.fillWidth: true
                        iconName: modelData.icon
                        title: modelData.title
                        accent: index === 0
                        onClicked: {
                            if (modelData.icon === "palette")
                                root.openSettings("")
                            else if (modelData.icon === "box")
                                root.openPath(root.homeDir + "/.config/quickshell/velora-shell")
                            else if (modelData.icon === "display")
                                root.openDisplaySettings()
                            else
                                root.runDetached("if command -v kinfocenter >/dev/null 2>&1; then kinfocenter; elif command -v hardinfo2 >/dev/null 2>&1; then hardinfo2; else uname -a | wl-copy 2>/dev/null || true; fi")
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.winLine }

                WinSubLabel { text: "アカウント"; color: root.winAccent2; font.pixelSize: 12; font.weight: Font.Bold }
                WinActionRow { Layout.fillWidth: true; iconName: "user"; title: "アカウント設定"; onClicked: root.openSettings("kcm_users") }
                WinActionRow {
                    Layout.fillWidth: true
                    iconName: "logout"
                    title: "サインアウト"
                    subtitle: "logout menu"
                    onClicked: root.runDetached("if command -v wlogout >/dev/null 2>&1; then wlogout; elif command -v nwg-bar >/dev/null 2>&1; then nwg-bar; fi")
                }
            }
        }
    }

    component TimeView: Item {
        id: timeView

        property date now: new Date()
        readonly property var weekdays: ["D", "S", "T", "Q", "Q", "S", "S"]
        readonly property var weekdayNames: ["domingo", "segunda", "terça", "quarta", "quinta", "sexta", "sábado"]
        readonly property var monthNames: ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"]

        opacity: root.popupIntroOpacity(20, 220)
        scale: root.popupIntroScale(20, 0.985, 1.0)
        transformOrigin: Item.TopLeft
        clip: true

        transform: Translate {
            y: root.popupIntroTranslateY(20, 12)
        }

        function calendarWeekRows() {
            const first = new Date(now.getFullYear(), now.getMonth(), 1)
            const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()
            return Math.max(5, Math.ceil((first.getDay() + daysInMonth) / 7))
        }

        function dateText() {
            return weekdayNames[now.getDay()] + ", " + now.getDate() + " de " + monthNames[now.getMonth()]
        }

        function monthTitle() {
            return monthNames[now.getMonth()] + " de " + now.getFullYear()
        }

        function calendarCells() {
            const year = now.getFullYear()
            const month = now.getMonth()
            const first = new Date(year, month, 1)
            const start = new Date(year, month, 1 - first.getDay())
            const totalCells = 7 + calendarWeekRows() * 7
            var cells = []

            for (var i = 0; i < totalCells; ++i) {
                if (i < 7) {
                    cells.push({ label: weekdays[i], header: true, currentMonth: true, today: false })
                    continue
                }

                const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i - 7)
                cells.push({
                    label: String(d.getDate()),
                    header: false,
                    currentMonth: d.getMonth() === month,
                    today: d.getFullYear() === year && d.getMonth() === month && d.getDate() === now.getDate()
                })
            }

            return cells
        }

        onVisibleChanged: {
            if (!visible)
                return
            root.ensureEventsLoaded(false)
            root.ensureWeatherLoaded(false)
        }

        Timer {
            interval: 1000
            running: root.open && root.visible && timeView.visible
            repeat: true
            onTriggered: timeView.now = new Date()
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 9

            Text {
                Layout.fillWidth: true
                text: "Hoje"
                color: root.alpha(root.inkSoft, 0.88)
                font.family: root.uiFont
                font.pixelSize: 11
                font.weight: Font.Bold
                elide: Text.ElideRight
                opacity: root.popupIntroOpacity(25, 170)
                transform: Translate { y: root.popupIntroTranslateY(25, 5) }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: root.winLine
                opacity: root.popupIntroOpacity(55, 170)
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 92
                opacity: root.popupIntroOpacity(70, 210)
                transform: Translate { y: root.popupIntroTranslateY(70, 12) }

                Rectangle {
                    id: clockBubble

                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 3
                    width: Math.min(parent.width - 12, 392)
                    height: Math.min(parent.height - 6, 82)
                    radius: height / 2.5
                    color: root.theme ? root.theme.alpha(root.card, root.theme.themeMode === "dark" ? 0.07 : 0.10) : Qt.rgba(1, 1, 1, 0.09)
                    border.width: 1
                    border.color: root.theme ? root.theme.alpha(root.borderSoft, root.theme.themeMode === "dark" ? 0.09 : 0.13) : Qt.rgba(1, 1, 1, 0.12)
                }

                Canvas {
                    id: outlineClock

                    anchors.fill: parent
                    property string displayTime: Qt.formatDateTime(timeView.now, "HH:mm:ss")

                    onDisplayTimeChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    onPaint: {
                        const ctx = getContext("2d")
                        const size = Math.max(42, Math.min(78, Math.round(Math.min(height * 0.86, width * 0.18))))
                        ctx.reset()
                        ctx.clearRect(0, 0, width, height)
                        ctx.font = "italic 700 " + size + "px \"Adwaita Sans\""
                        ctx.textAlign = "center"
                        ctx.textBaseline = "middle"
                        ctx.lineJoin = "round"
                        ctx.lineWidth = Math.max(1.25, size * 0.026)
                        ctx.shadowColor = root.alpha(root.winAccent2, 0.18)
                        ctx.shadowBlur = 10
                        ctx.strokeStyle = root.alpha(root.inkSoft, 0.64)
                        ctx.strokeText(displayTime, width / 2, height / 2 + 3)
                        ctx.shadowBlur = 0
                        ctx.lineWidth = Math.max(0.75, size * 0.012)
                        ctx.strokeStyle = root.alpha(root.ink, 0.18)
                        ctx.strokeText(displayTime, width / 2, height / 2 + 3)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: root.winLine
                opacity: root.popupIntroOpacity(110, 170)
            }

            TimeCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 238
                entryDelay: 115

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: timeView.monthTitle()
                            color: root.winAccent2
                            font.family: root.uiFont
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "‹"
                            color: root.winAccent2
                            font.family: root.uiFont
                            font.pixelSize: 22
                            font.weight: Font.Medium
                        }

                        Text {
                            text: "›"
                            color: root.winAccent2
                            font.family: root.uiFont
                            font.pixelSize: 22
                            font.weight: Font.Medium
                        }
                    }

                    GridLayout {
                        id: calendarGrid

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 7
                        columnSpacing: 6
                        rowSpacing: 3

                        Repeater {
                            model: timeView.calendarCells()

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: modelData.header ? 16 : (timeView.calendarWeekRows() > 5 ? 22 : 25)
                                radius: 7
                                color: modelData.today ? root.alpha(root.winAccent, 0.46) : "transparent"
                                border.width: modelData.today ? 1 : 0
                                border.color: root.alpha(root.winAccent, 0.30)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: modelData.header ? root.inkSoft : (modelData.currentMonth ? root.ink : root.alpha(root.inkSoft, 0.34))
                                    font.family: root.uiFont
                                    font.pixelSize: modelData.header ? 10 : 12
                                    font.weight: modelData.today || modelData.header ? Font.Bold : Font.Medium
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openCalendarApp()
                }
            }

            TimeCard {
                Layout.fillWidth: true
                Layout.preferredHeight: eventModel.count > 0 ? 204 : 116
                entryDelay: 175

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        TimeSectionTitle {
                            Layout.fillWidth: true
                            text: "Próximos eventos/marcações"
                        }

                        TimeIconButton {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            iconName: "plus"
                            entryDelay: 225
                            onClicked: {
                                root.ensureEventsLoaded(false)
                                root.newAgendaEvent()
                                root.popupRequested("agenda")
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: eventModel.count > 0
                        spacing: 0

                        Repeater {
                            model: Math.min(eventModel.count, 3)

                            TimeEventRow {
                                readonly property var eventItem: eventModel.get(index)

                                Layout.fillWidth: true
                                Layout.preferredHeight: 48
                                iconName: eventItem.iconName
                                iconColor: root.eventAccentColor(eventItem.accent)
                                title: eventItem.title
                                subtitle: root.eventSubtitle(eventItem)
                                time: root.eventRelativeDate(eventItem) + " · " + root.eventTimeText(eventItem)
                                showDivider: index < Math.min(eventModel.count, 3) - 1
                                entryDelay: 220 + index * 36
                                onClicked: {
                                    root.selectAgendaEvent(index)
                                    root.popupRequested("agenda")
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: eventModel.count <= 0
                        text: "Sem eventos"
                        color: root.inkSoft
                        font.family: root.uiFont
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        opacity: root.popupIntroOpacity(220, 180)
                        transform: Translate { y: root.popupIntroTranslateY(220, 6) }
                    }
                }
            }

            TimeCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 122
                entryDelay: 245

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10

                    TimeSectionTitle {
                        Layout.fillWidth: true
                        text: "Clima"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 12

                        WeatherGlyph {
                            Layout.preferredWidth: 54
                            Layout.preferredHeight: 42
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: root.weatherTempText
                                    color: root.ink
                                    font.family: root.uiFont
                                    font.pixelSize: 24
                                    font.weight: Font.Medium
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.weatherDesc
                                color: root.ink
                                font.family: root.uiFont
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.weatherUpdatedText.length > 0 ? root.weatherCity + " · " + root.weatherUpdatedText : root.weatherCity
                                color: root.inkSoft
                                font.family: root.uiFont
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 1
                            Layout.fillHeight: true
                            color: root.alpha(root.winAccent, 0.12)
                        }

                        ColumnLayout {
                            Layout.preferredWidth: 86
                            spacing: 2

                            Text { Layout.fillWidth: true; text: root.weatherHighLowText; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 10; font.weight: Font.Medium; elide: Text.ElideRight }
                            Text { Layout.fillWidth: true; text: root.weatherHumidityText; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 10; font.weight: Font.Medium; elide: Text.ElideRight }
                            Text { Layout.fillWidth: true; text: root.weatherWindText; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 10; font.weight: Font.Medium; elide: Text.ElideRight }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.ensureWeatherDetailsLoaded(false)
                        root.popupRequested("weatherPanel")
                    }
                }
            }

            TimeCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 108
                entryDelay: 315

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 8

                    TimeSectionTitle {
                        Layout.fillWidth: true
                        text: "Temporizadores"
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Nenhum temporizador ativo"
                        color: root.inkSoft
                        font.family: root.uiFont
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    TimeActionButton {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 166
                        Layout.preferredHeight: 32
                        text: "Criar temporizador"
                        entryDelay: 390
                        onClicked: root.openClockApp()
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }

    component WeatherView: Item {
        id: weatherView

        readonly property color page: root.agendaPage
        readonly property color panel: root.agendaPanel
        readonly property color card: root.agendaCard
        readonly property color ink: root.agendaInk
        readonly property color soft: root.agendaSoft
        readonly property color line: root.agendaLine
        readonly property var hourly: root.weatherHourlyModel()
        readonly property var daily: root.weatherDailyModel()

        opacity: root.popupIntroOpacity(15, 230)
        scale: root.popupIntroScale(15, 0.985, 1)
        transformOrigin: Item.TopRight
        transform: Translate { y: root.popupIntroTranslateY(15, 12) }

        onVisibleChanged: {
            if (!visible)
                return
            root.ensureWeatherLoaded(false)
            root.ensureWeatherDetailsLoaded(false)
        }

        Rectangle {
            anchors.fill: parent
            radius: root.cornerRadius
            color: weatherView.page
            border.width: 0
            antialiasing: true
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            ColumnLayout {
                Layout.preferredWidth: 260
                Layout.fillHeight: true
                Layout.margins: 24
                spacing: 18
                opacity: root.popupIntroOpacity(45, 220)
                transform: Translate { x: root.popupIntroTranslateX(45, -16) }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9

                    Repeater {
                        model: [Qt.rgba(0.94, 0.35, 0.25, 1), Qt.rgba(0.96, 0.68, 0.22, 1), Qt.rgba(0.34, 0.70, 0.35, 1)]
                        Rectangle {
                            Layout.preferredWidth: 11
                            Layout.preferredHeight: 11
                            radius: 6
                            color: modelData
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    WeatherMiniGlyph {
                        Layout.preferredWidth: 52
                        Layout.preferredHeight: 52
                        iconName: root.weatherIconName
                        accent: root.winAccent
                        lineColor: weatherView.ink
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "Clima"
                            color: weatherView.ink
                            font.family: root.uiFont
                            font.pixelSize: 27
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Previsão, condições e\ndetalhes do dia."
                            color: weatherView.soft
                            font.family: root.uiFont
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            lineHeight: 1.35
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: weatherView.line }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    AgendaSidebarButton { Layout.fillWidth: true; iconName: "user"; title: "Visão geral"; active: true; introMode: "popup"; entryDelay: 120 }
                    AgendaSidebarButton { Layout.fillWidth: true; iconName: "calendar"; title: "Hoje"; active: false; introMode: "popup"; entryDelay: 150 }
                    AgendaSidebarButton { Layout.fillWidth: true; iconName: "clock"; title: "Por hora"; active: false; introMode: "popup"; entryDelay: 180 }
                    AgendaSidebarButton { Layout.fillWidth: true; iconName: "calendar"; title: "Próximos 7 dias"; active: false; introMode: "popup"; entryDelay: 210 }
                    AgendaSidebarButton { Layout.fillWidth: true; iconName: "map"; title: "Mapa"; active: false; introMode: "popup"; entryDelay: 240 }
                    AgendaSidebarButton { Layout.fillWidth: true; iconName: "spark"; title: "Qualidade do ar"; active: false; introMode: "popup"; entryDelay: 270 }
                }

                Item { Layout.fillHeight: true }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: weatherView.line }
                AgendaSidebarButton { Layout.fillWidth: true; iconName: "settings"; title: "Configurações"; active: false; introMode: "popup"; entryDelay: 320 }
            }

            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: weatherView.line }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 24
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 54
                    spacing: 20
                    opacity: root.popupIntroOpacity(70, 220)
                    transform: Translate { y: root.popupIntroTranslateY(70, 10) }

                    AgendaField {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 360
                        Layout.preferredHeight: 40
                        iconName: "search"
                        placeholder: "Buscar cidade..."
                        text: ""
                        editable: false
                        introMode: "popup"
                        entryDelay: 75
                    }

                    AgendaField {
                        Layout.preferredWidth: 320
                        Layout.preferredHeight: 40
                        iconName: "map"
                        placeholder: root.weatherCity
                        text: root.weatherCity
                        editable: false
                        introMode: "popup"
                        entryDelay: 95
                    }

                    AgendaButton {
                        Layout.preferredWidth: 190
                        Layout.preferredHeight: 40
                        text: "Adicionar cidade"
                        iconName: "plus"
                        dark: true
                        introMode: "popup"
                        entryDelay: 115
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    spacing: 12

                    WeatherPanelCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 200
                        title: "Condições atuais"
                        entryDelay: 115

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            anchors.topMargin: 48
                            spacing: 18

                            WeatherMiniGlyph {
                                Layout.preferredWidth: 110
                                Layout.preferredHeight: 88
                                iconName: root.weatherIconName
                                accent: root.winAccent
                                lineColor: weatherView.ink
                            }

                            ColumnLayout {
                                Layout.preferredWidth: 170
                                spacing: 5

                                Text {
                                    Layout.fillWidth: true
                                    text: root.weatherTempText
                                    color: weatherView.ink
                                    font.family: root.uiFont
                                    font.pixelSize: 58
                                    font.weight: Font.Light
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.weatherHighLowText
                                    color: weatherView.soft
                                    font.family: root.uiFont
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 7

                                Text {
                                    Layout.fillWidth: true
                                    text: root.weatherDesc
                                    color: weatherView.ink
                                    font.family: root.uiFont
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.weatherFeelsText
                                    color: weatherView.soft
                                    font.family: root.uiFont
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                WeatherStatLine { iconName: "drop"; title: "Umidade"; value: root.weatherPercentText(root.weatherHumidityText.replace("Umidade:", "")); entryDelay: 160 }
                                WeatherStatLine { iconName: "wind"; title: "Vento"; value: root.weatherWindText.replace("Vento: ", ""); entryDelay: 190 }
                                WeatherStatLine { iconName: "rain"; title: "Chance de chuva"; value: root.weatherRainChanceText.replace("Chance de chuva ", ""); entryDelay: 220 }
                            }
                        }
                    }

                    WeatherPanelCard {
                        Layout.preferredWidth: 355
                        Layout.preferredHeight: 200
                        title: "Nascer e pôr do sol"
                        entryDelay: 150

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            anchors.topMargin: 52
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true

                                Text { Layout.fillWidth: true; text: "☀ " + root.weatherSunriseText + "\nNascer do sol"; color: weatherView.ink; font.family: root.uiFont; font.pixelSize: 12; font.weight: Font.Medium }
                                Text { Layout.fillWidth: true; text: root.weatherSunsetText + "\nPôr do sol"; color: weatherView.ink; font.family: root.uiFont; font.pixelSize: 12; font.weight: Font.Medium; horizontalAlignment: Text.AlignRight }
                            }

                            WeatherSunArc {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 70
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Duração do dia\n--"
                                color: weatherView.soft
                                font.family: root.uiFont
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }

                WeatherPanelCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 138
                    title: "Previsão por hora"
                    entryDelay: 190

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 12
                        anchors.topMargin: 42
                        contentWidth: hourlyRow.implicitWidth
                        contentHeight: height
                        clip: true
                        interactive: contentWidth > width

                        Row {
                            id: hourlyRow
                            height: parent.height
                            spacing: 8

                            Repeater {
                                model: weatherView.hourly.slice(0, 12)

                                WeatherHourlyTile {
                                    width: 78
                                    height: hourlyRow.height
                                    time: modelData.time || "--"
                                    temp: root.weatherCelsiusText(modelData.temp)
                                    iconName: modelData.icon || "partly"
                                    rain: root.weatherPercentText(modelData.rain)
                                    entryDelay: 220 + index * 18
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    WeatherPanelCard {
                        Layout.preferredWidth: 420
                        Layout.fillHeight: true
                        title: "Próximos 7 dias"
                        entryDelay: 235

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            anchors.topMargin: 48
                            spacing: 4

                            Repeater {
                                model: weatherView.daily.slice(0, 7)

                                WeatherDailyRow {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 35
                                    label: modelData.label || modelData.date || "--"
                                    desc: modelData.desc || "--"
                                    iconName: modelData.icon || "partly"
                                    maxTemp: root.weatherCelsiusText(modelData.max)
                                    minTemp: root.weatherCelsiusText(modelData.min)
                                    rain: root.weatherPercentText(modelData.rain)
                                    entryDelay: 260 + index * 22
                                }
                            }

                            Item { Layout.fillHeight: true }

                            AgendaButton {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 210
                                Layout.preferredHeight: 34
                                text: "Ver previsão completa"
                                iconName: "calendar"
                                introMode: "popup"
                                entryDelay: 380
                                onClicked: root.ensureWeatherDetailsLoaded(true)
                            }
                        }
                    }

                    Item {
                        Layout.preferredWidth: 330
                        Layout.minimumWidth: 330
                        Layout.maximumWidth: 330
                        Layout.fillHeight: true

                        GridLayout {
                            anchors.fill: parent
                            columns: 2
                            columnSpacing: 12
                            rowSpacing: 12

                            WeatherMetricTile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumWidth: 0; Layout.minimumHeight: 0; iconName: "spark"; title: "Índice UV"; value: root.weatherUvText; detail: "Proteção recomendada"; accent: root.winAccent; entryDelay: 270 }
                            WeatherMetricTile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumWidth: 0; Layout.minimumHeight: 0; iconName: "leaf"; title: "Qualidade do ar"; value: root.weatherAirQuality.label || "Sem dados"; detail: root.weatherAirQuality.aqi === "--" ? root.weatherAirQuality.detail : "AQI " + root.weatherAirQuality.aqi; accent: root.eventAccentColor("green"); entryDelay: 295 }
                            WeatherMetricTile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumWidth: 0; Layout.minimumHeight: 0; iconName: "drop"; title: "Umidade"; value: root.weatherPercentText(root.weatherHumidityText.replace("Umidade:", "")); detail: "Nível atual"; accent: root.winAccent2; entryDelay: 320 }
                            WeatherMetricTile { Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumWidth: 0; Layout.minimumHeight: 0; iconName: "wind"; title: "Vento"; value: root.weatherWindText.replace("Vento: ", ""); detail: root.weatherWindDirectionText.length > 0 ? "Direção " + root.weatherWindDirectionText : "Atualizado agora"; accent: root.winAccent; entryDelay: 345 }
                        }
                    }

                    WeatherPanelCard {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 300
                        Layout.fillHeight: true
                        title: "Mapa de chuvas"
                        entryDelay: 280

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 18
                            anchors.topMargin: 48
                            spacing: 10

                            WeatherRainMap {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.weatherRainMap.detail || "Radar de chuva indisponivel."
                                color: weatherView.soft
                                font.family: root.uiFont
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }

    component AgendaView: Item {
        id: agendaView

        readonly property color page: root.agendaPage
        readonly property color panel: root.agendaPanel
        readonly property color card: root.agendaCard
        readonly property color cardActive: root.agendaCardActive
        readonly property color ink: root.agendaInk
        readonly property color soft: root.agendaSoft
        readonly property color line: root.agendaLine
        readonly property var weekdays: ["DOM", "SEG", "TER", "QUA", "QUI", "SEX", "SÁB"]
        readonly property var weekdayNames: ["domingo", "segunda-feira", "terça-feira", "quarta-feira", "quinta-feira", "sexta-feira", "sábado"]
        readonly property var monthNames: ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]
        property date now: new Date()

        opacity: root.popupIntroOpacity(15, 230)
        scale: root.popupIntroScale(15, 0.985, 1)
        transformOrigin: Item.TopRight

        transform: Translate {
            y: root.popupIntroTranslateY(15, 12)
        }

        function monthTitle() {
            return monthNames[now.getMonth()] + " de " + now.getFullYear()
        }

        function fullTodayLabel() {
            return "Hoje · " + weekdayNames[now.getDay()] + ", " + now.getDate() + " de " + monthNames[now.getMonth()]
        }

        function calendarCells() {
            const year = now.getFullYear()
            const month = now.getMonth()
            const first = new Date(year, month, 1)
            const start = new Date(year, month, 1 - first.getDay())
            var cells = []

            for (var i = 0; i < 42; ++i) {
                const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
                const iso = Qt.formatDateTime(d, "yyyy-MM-dd")
                cells.push({
                    label: String(d.getDate()),
                    iso: iso,
                    currentMonth: d.getMonth() === month,
                    today: iso === root.todayIso(),
                    selected: root.agendaSelectedIndex >= 0 && root.agendaSelectedIndex < eventModel.count && eventModel.get(root.agendaSelectedIndex).date === iso,
                    events: eventCountForDay(iso)
                })
            }

            return cells
        }

        function eventCountForDay(iso) {
            var total = 0
            for (var i = 0; i < eventModel.count; ++i) {
                if (eventModel.get(i).date === iso)
                    total += 1
            }
            return total
        }

        function selectedEvent() {
            if (root.agendaSelectedIndex >= 0 && root.agendaSelectedIndex < eventModel.count)
                return eventModel.get(root.agendaSelectedIndex)
            return null
        }

        onVisibleChanged: {
            if (!visible)
                return
            root.ensureEventsLoaded(false)
            if (eventModel.count > 0 && root.agendaSelectedIndex < 0)
                root.selectAgendaEvent(0)
            else if (eventModel.count <= 0 && !root.agendaEditing)
                root.selectAgendaEvent(-1)
        }

            Rectangle {
                anchors.fill: parent
                radius: root.cornerRadius
                color: agendaView.page
                border.width: 0
                border.color: agendaView.line
                antialiasing: true
                opacity: root.popupIntroOpacity(0, 220)
            }

            Item {
                anchors.fill: parent
                clip: true
                opacity: root.popupType === "agenda" ? Math.max(0, 1 - root.popupIntroProgress) : 0

                Rectangle {
                    width: Math.max(180, parent.width * 0.22)
                    height: parent.height * 1.35
                    x: -width + (parent.width + width * 2) * root.popupIntroProgress
                    y: -parent.height * 0.18
                    rotation: 7
                    radius: 28
                    color: root.alpha(root.winAccent2, root.agendaDark ? 0.13 : 0.18)
                    antialiasing: true
                }
            }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            ColumnLayout {
                Layout.preferredWidth: 260
                Layout.fillHeight: true
                Layout.margins: 24
                spacing: 18
                opacity: root.popupIntroOpacity(45, 220)
                transform: Translate { x: root.popupIntroTranslateX(45, -16) }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9

                    Repeater {
                        model: [Qt.rgba(0.94, 0.35, 0.25, 1), Qt.rgba(0.96, 0.68, 0.22, 1), Qt.rgba(0.34, 0.70, 0.35, 1)]
                        Rectangle {
                            Layout.preferredWidth: 11
                            Layout.preferredHeight: 11
                            radius: 6
                            color: modelData
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Item {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36

                        Rectangle {
                            anchors.centerIn: parent
                            width: 34
                            height: 34
                            radius: 10
                            color: "transparent"
                            border.width: 1
                            border.color: root.alpha(root.winAccent2, root.agendaLoopGlow(0.05, 0.42))
                            scale: root.agendaLoopWave(0.05, 0.94, 1.06)
                            opacity: root.popupIntroOpacity(80, 220)
                        }

                        PopupIcon {
                            anchors.centerIn: parent
                            width: 30
                            height: 30
                            iconName: "calendar"
                            lineColor: agendaView.ink
                            opacity: root.agendaLoopWave(0.18, 0.86, 1.0)
                        }
                    }

                    AgendaAnimatedTitle {
                        Layout.fillWidth: true
                        text: "Agenda"
                        color: agendaView.ink
                        pixelSize: 27
                        entryDelay: 90
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Organize reuniões, lembretes\ne compromissos."
                    color: agendaView.soft
                    font.family: root.uiFont
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    lineHeight: 1.45
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: agendaView.line }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    AgendaSidebarButton { Layout.fillWidth: true; iconName: "user"; title: "Visão geral"; active: root.agendaSection === "overview"; introMode: "popup"; entryDelay: 120; onClicked: root.agendaSection = "overview" }
                    AgendaSidebarButton { Layout.fillWidth: true; iconName: "calendar"; title: "Calendário"; active: root.agendaSection === "calendar"; introMode: "popup"; entryDelay: 150; onClicked: root.agendaSection = "calendar" }
                    AgendaSidebarButton { Layout.fillWidth: true; iconName: "calendar"; title: "Eventos"; active: root.agendaSection === "events"; introMode: "popup"; entryDelay: 180; onClicked: root.agendaSection = "events" }
                    AgendaSidebarButton { Layout.fillWidth: true; iconName: "box"; title: "Etiquetas"; active: root.agendaSection === "labels"; introMode: "popup"; entryDelay: 210; onClicked: root.agendaSection = "labels" }
                    AgendaSidebarButton { Layout.fillWidth: true; iconName: "bell"; title: "Lembretes"; active: root.agendaSection === "reminders"; introMode: "popup"; entryDelay: 240; onClicked: root.agendaSection = "reminders" }
                }

                Item { Layout.fillHeight: true }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: agendaView.line }

                AgendaSidebarButton {
                    Layout.fillWidth: true
                    iconName: "settings"
                    title: "Configurações"
                    active: false
                    introMode: "popup"
                    entryDelay: 300
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: agendaView.line
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 24
                spacing: 18
                opacity: root.popupIntroOpacity(70, 230)
                transform: Translate { x: root.popupIntroTranslateX(70, 18) }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    spacing: 18
                    opacity: root.popupIntroOpacity(85, 190)
                    transform: Translate { y: root.popupIntroTranslateY(85, 9) }

                    AgendaField {
                        Layout.preferredWidth: 345
                        Layout.preferredHeight: 40
                        text: ""
                        placeholder: root.agendaTopPlaceholder()
                        iconName: "search"
                        editable: false
                        introMode: "popup"
                        entryDelay: 95
                    }

                    AgendaMonthControl {
                        Layout.preferredWidth: 240
                        Layout.preferredHeight: 40
                        title: agendaView.monthTitle()
                        introMode: "popup"
                        entryDelay: 125
                    }

                    Item { Layout.fillWidth: true }

                    AgendaButton {
                        Layout.preferredWidth: 145
                        Layout.preferredHeight: 40
                        text: root.agendaTopActionText()
                        iconName: "plus"
                        dark: true
                        introMode: "popup"
                        entryDelay: 155
                        onClicked: root.agendaDefaultAction()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.agendaSection === "events"
                    spacing: 18
                    opacity: root.agendaSectionOpacity(10, 220)
                    transform: Translate { x: root.agendaSectionTranslateX(10, 16) }

                    ColumnLayout {
                        Layout.preferredWidth: 365
                        Layout.fillHeight: true
                        spacing: 16

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 350
                            radius: 13
                            color: agendaView.panel
                            border.width: 1
                            border.color: agendaView.line
                            opacity: root.agendaSectionOpacity(35, 210)
                            scale: root.agendaSectionScale(35, 0.982, 1.0)
                            transform: Translate { y: root.agendaSectionTranslateY(35, 10) }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 22
                                spacing: 16

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        Layout.fillWidth: true
                                        text: agendaView.monthTitle()
                                        color: agendaView.ink
                                        font.family: root.uiFont
                                        font.pixelSize: 14
                                        font.weight: Font.Bold
                                    }

                                    Text { text: "‹"; color: agendaView.ink; font.family: root.uiFont; font.pixelSize: 22 }
                                    Text { text: "›"; color: agendaView.ink; font.family: root.uiFont; font.pixelSize: 22 }
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 7
                                    columnSpacing: 7
                                    rowSpacing: 8

                                    Repeater {
                                        model: agendaView.weekdays
                                        Text {
                                            Layout.preferredWidth: 36
                                            Layout.preferredHeight: 20
                                            text: modelData
                                            color: agendaView.soft
                                            font.family: root.uiFont
                                            font.pixelSize: 10
                                            font.weight: Font.Bold
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }

                                    Repeater {
                                        model: agendaView.calendarCells()

                                        AgendaCalendarCell {
                                            Layout.preferredWidth: 36
                                            Layout.preferredHeight: 32
                                            label: modelData.label
                                            currentMonth: modelData.currentMonth
                                            today: modelData.today
                                            selected: modelData.selected
                                            eventCount: modelData.events
                                            accent: modelData.events > 0 ? root.eventAccentColor(eventModel.count > 0 ? eventModel.get(0).accent : "blue") : root.winAccent
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 13
                            color: agendaView.panel
                            border.width: 1
                            border.color: agendaView.line
                            opacity: root.agendaSectionOpacity(110, 210)
                            scale: root.agendaSectionScale(110, 0.982, 1.0)
                            transform: Translate { y: root.agendaSectionTranslateY(110, 10) }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 12

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        Layout.fillWidth: true
                                        text: "Próximos eventos"
                                        color: agendaView.ink
                                        font.family: root.uiFont
                                        font.pixelSize: 14
                                        font.weight: Font.Bold
                                    }
                                    Text {
                                        text: eventModel.count + " itens"
                                        color: agendaView.soft
                                        font.family: root.uiFont
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                    }
                                }

                                Flickable {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    contentWidth: width
                                    contentHeight: upcomingList.implicitHeight

                                    ColumnLayout {
                                        id: upcomingList
                                        width: parent.width
                                        spacing: 4

                                        Repeater {
                                            model: eventModel.count

                                            AgendaCompactRow {
                                                readonly property var eventItem: eventModel.get(index)

                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 54
                                                iconName: eventItem.iconName
                                                accent: root.eventAccentColor(eventItem.accent)
                                                title: eventItem.title
                                                timeText: root.eventRelativeDate(eventItem) + " · " + root.eventTimeText(eventItem)
                                                location: eventItem.location.length > 0 ? eventItem.location : eventItem.category
                                                introMode: "section"
                                                entryDelay: 160 + index * 30
                                                onClicked: root.selectAgendaEvent(index)
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            Layout.topMargin: 24
                                            visible: eventModel.count <= 0
                                            text: "Sem eventos"
                                            color: agendaView.soft
                                            font.family: root.uiFont
                                            font.pixelSize: 13
                                            font.weight: Font.Medium
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        color: agendaView.line
                    }

                    ColumnLayout {
                        Layout.preferredWidth: 355
                        Layout.fillHeight: true
                        spacing: 14

                        Text {
                            Layout.fillWidth: true
                            text: agendaView.fullTodayLabel()
                            color: agendaView.ink
                            font.family: root.uiFont
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            opacity: root.agendaSectionOpacity(140, 180)
                            transform: Translate { y: root.agendaSectionTranslateY(140, 7) }
                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: width
                            contentHeight: eventList.implicitHeight

                            ColumnLayout {
                                id: eventList
                                width: parent.width
                                spacing: 8

                                Repeater {
                                    model: eventModel.count

                                    AgendaEventCard {
                                        readonly property var eventItem: eventModel.get(index)

                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 72
                                        selected: index === root.agendaSelectedIndex
                                        iconName: eventItem.iconName
                                        accent: root.eventAccentColor(eventItem.accent)
                                        title: eventItem.title
                                        subtitle: root.eventSubtitle(eventItem)
                                        timeText: root.eventTimeText(eventItem)
                                        introMode: "section"
                                        entryDelay: 175 + index * 34
                                        onClicked: root.selectAgendaEvent(index)
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 24
                                    visible: eventModel.count <= 0
                                    text: "Sem eventos cadastrados"
                                    color: agendaView.soft
                                    font.family: root.uiFont
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 340
                        Layout.fillHeight: true
                        radius: 13
                        color: agendaView.panel
                        border.width: 1
                        border.color: agendaView.line
                        opacity: root.agendaDetailOpacity(25, 210)
                        scale: root.agendaDetailScale(25, 0.982, 1.0)
                        transform: Translate { y: root.agendaDetailTranslateY(25, 10) }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true
                                    text: root.agendaEditing ? (root.agendaEditingIndex >= 0 ? "Editar evento" : "Novo evento") : "Detalhes do evento"
                                    color: agendaView.ink
                                    font.family: root.uiFont
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                }
                                Text {
                                    text: "×"
                                    color: agendaView.soft
                                    font.family: root.uiFont
                                    font.pixelSize: 21
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.popupRequested("time")
                                    }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: agendaView.line }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: root.agendaEditing
                                spacing: 10

                                AgendaField {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    label: "Título"
                                    placeholder: "Nome do evento"
                                    text: root.agendaTitleDraft
                                    introMode: "detail"
                                    entryDelay: 55
                                    onTextChanged: root.agendaTitleDraft = text
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    AgendaField {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 40
                                        label: "Data"
                                        placeholder: "YYYY-MM-DD"
                                        text: root.agendaDateDraft
                                        introMode: "detail"
                                        entryDelay: 85
                                        onTextChanged: root.agendaDateDraft = text
                                    }
                                    AgendaField {
                                        Layout.preferredWidth: 76
                                        Layout.preferredHeight: 40
                                        label: "Início"
                                        placeholder: "09:00"
                                        text: root.agendaStartDraft
                                        introMode: "detail"
                                        entryDelay: 105
                                        onTextChanged: root.agendaStartDraft = text
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    AgendaField {
                                        Layout.preferredWidth: 76
                                        Layout.preferredHeight: 40
                                        label: "Fim"
                                        placeholder: "10:00"
                                        text: root.agendaEndDraft
                                        introMode: "detail"
                                        entryDelay: 135
                                        onTextChanged: root.agendaEndDraft = text
                                    }
                                    AgendaField {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 40
                                        label: "Etiqueta"
                                        placeholder: "Trabalho"
                                        text: root.agendaCategoryDraft
                                        introMode: "detail"
                                        entryDelay: 155
                                        onTextChanged: root.agendaCategoryDraft = text
                                    }
                                }

                                AgendaField {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    label: "Local"
                                    placeholder: "Sala, link ou endereço"
                                    text: root.agendaLocationDraft
                                    introMode: "detail"
                                    entryDelay: 185
                                    onTextChanged: root.agendaLocationDraft = text
                                }

                                AgendaTextArea {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    label: "Descrição"
                                    placeholder: "Detalhes, contexto ou lembrete"
                                    text: root.agendaDescriptionDraft
                                    introMode: "detail"
                                    entryDelay: 215
                                    onTextChanged: root.agendaDescriptionDraft = text
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    AgendaButton {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 38
                                        text: "Salvar"
                                        iconName: "plus"
                                        dark: true
                                        introMode: "detail"
                                        entryDelay: 260
                                        onClicked: root.saveAgendaDraft()
                                    }
                                    AgendaButton {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 38
                                        text: "Cancelar"
                                        iconName: "logout"
                                        dark: false
                                        introMode: "detail"
                                        entryDelay: 285
                                        onClicked: {
                                            if (eventModel.count > 0)
                                                root.selectAgendaEvent(Math.max(0, root.agendaSelectedIndex))
                                            else
                                                root.newAgendaEvent()
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: !root.agendaEditing
                                spacing: 14

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 42

                                    PopupIcon {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 34
                                        height: 34
                                        iconName: agendaView.selectedEvent() ? agendaView.selectedEvent().iconName : "calendar"
                                        lineColor: agendaView.selectedEvent() ? root.eventAccentColor(agendaView.selectedEvent().accent) : agendaView.soft
                                    }
                                }

                                AgendaDetailRow {
                                    label: agendaView.selectedEvent() ? agendaView.selectedEvent().title : "Sem evento selecionado"
                                    value: agendaView.selectedEvent() ? root.eventSubtitle(agendaView.selectedEvent()) : "Crie um evento para preencher a agenda."
                                    accent: agendaView.selectedEvent() ? root.eventAccentColor(agendaView.selectedEvent().accent) : root.winAccent2
                                    entryDelay: 70
                                }

                                AgendaDetailRow {
                                    label: "Data"
                                    value: agendaView.selectedEvent() ? root.eventDateLabel(agendaView.selectedEvent().date, true) : "-"
                                    entryDelay: 115
                                }

                                AgendaDetailRow {
                                    label: "Horário"
                                    value: agendaView.selectedEvent() ? root.eventTimeText(agendaView.selectedEvent()) : "-"
                                    entryDelay: 150
                                }

                                AgendaDetailRow {
                                    label: "Local"
                                    value: agendaView.selectedEvent() && agendaView.selectedEvent().location.length > 0 ? agendaView.selectedEvent().location : "-"
                                    entryDelay: 185
                                }

                                AgendaDetailRow {
                                    label: "Etiqueta"
                                    value: agendaView.selectedEvent() ? agendaView.selectedEvent().category : "-"
                                    entryDelay: 220
                                }

                                AgendaDetailRow {
                                    label: "Descrição"
                                    value: agendaView.selectedEvent() && agendaView.selectedEvent().description.length > 0 ? agendaView.selectedEvent().description : "-"
                                    fill: true
                                    entryDelay: 255
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    AgendaButton {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 36
                                        text: "Editar evento"
                                        iconName: "pencil"
                                        dark: false
                                        enabled: agendaView.selectedEvent() !== null
                                        opacity: (enabled ? 1 : 0.45) * root.agendaDetailOpacity(295, 170)
                                        introMode: "detail"
                                        entryDelay: 295
                                        onClicked: root.editAgendaEvent(root.agendaSelectedIndex)
                                    }
                                    AgendaButton {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 36
                                        text: "Excluir"
                                        iconName: "logout"
                                        danger: true
                                        enabled: agendaView.selectedEvent() !== null
                                        opacity: (enabled ? 1 : 0.45) * root.agendaDetailOpacity(315, 170)
                                        introMode: "detail"
                                        entryDelay: 315
                                        onClicked: root.deleteAgendaEvent(root.agendaSelectedIndex)
                                    }
                                }
                            }
                        }
                    }
                }

                AgendaOverviewSection {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.agendaSection === "overview"
                }

                AgendaCalendarSection {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.agendaSection === "calendar"
                }

                AgendaLabelsSection {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.agendaSection === "labels"
                }

                AgendaRemindersSection {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.agendaSection === "reminders"
                }
            }
        }
    }

    component AgendaPanel: Rectangle {
        id: agendaPanel

        property string title: ""
        property string subtitle: ""
        property string introMode: "section"
        property int entryDelay: 80
        default property alias content: panelBody.data

        radius: 13
        color: root.agendaPanel
        border.width: 1
        border.color: root.agendaLine
        opacity: root.scopedIntroOpacity(introMode, entryDelay, 210)
        scale: root.scopedIntroScale(introMode, entryDelay, 0.982, 1.0)
        transform: Translate { y: root.scopedIntroTranslateY(agendaPanel.introMode, agendaPanel.entryDelay, 10) }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: agendaPanel.title
                    color: root.agendaInk
                    font.family: root.uiFont
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: agendaPanel.subtitle.length > 0
                    text: agendaPanel.subtitle
                    color: root.agendaSoft
                    font.family: root.uiFont
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }

            ColumnLayout {
                id: panelBody
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10
            }
        }
    }

    component AgendaMetric: RowLayout {
        id: metric

        property string iconName: "calendar"
        property string title: ""
        property string value: ""
        property string detail: ""
        property color accent: root.winAccent2
        property string introMode: "section"
        property int entryDelay: 120

        Layout.fillWidth: true
        spacing: 12
        opacity: root.scopedIntroOpacity(introMode, entryDelay, 180)
        transform: Translate { y: root.scopedIntroTranslateY(metric.introMode, metric.entryDelay, 7) }

        Rectangle {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            radius: 17
            color: root.alpha(accent, root.agendaDark ? 0.20 : 0.14)

            PopupIcon {
                anchors.centerIn: parent
                width: 18
                height: 18
                iconName: metric.iconName
                lineColor: metric.accent
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: title
                color: root.agendaInk
                font.family: root.uiFont
                font.pixelSize: 11
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: value
                    color: root.agendaInk
                    font.family: root.uiFont
                    font.pixelSize: 20
                    font.weight: Font.Bold
                }

                Text {
                    Layout.fillWidth: true
                    text: detail
                    color: root.agendaSoft
                    font.family: root.uiFont
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }
        }
    }

    component AgendaMiniRow: Rectangle {
        id: miniRow

        property string iconName: "calendar"
        property color accent: root.winAccent2
        property string title: ""
        property string detail: ""
        property bool checked: false
        property string introMode: "section"
        property int entryDelay: 120

        Layout.fillWidth: true
        implicitHeight: 42
        radius: 9
        color: root.alpha(root.agendaFieldFill, checked ? 0.34 : 0.58)
        opacity: root.scopedIntroOpacity(introMode, entryDelay, 180)
        transform: Translate { y: root.scopedIntroTranslateY(miniRow.introMode, miniRow.entryDelay, 7) }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            PopupIcon {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                iconName: miniRow.iconName
                lineColor: miniRow.checked ? root.agendaSoft : miniRow.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: miniRow.title
                    color: miniRow.checked ? root.agendaSoft : root.agendaInk
                    font.family: root.uiFont
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: miniRow.detail
                    color: root.agendaSoft
                    font.family: root.uiFont
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }
        }
    }

    component AgendaOverviewSection: GridLayout {
        columns: 3
        columnSpacing: 14
        rowSpacing: 14
        opacity: root.agendaSectionOpacity(0, 220)
        transform: Translate { y: root.agendaSectionTranslateY(0, 12) }

        AgendaPanel {
            Layout.fillWidth: true
            Layout.preferredHeight: 230
            title: "Hoje"
            subtitle: eventModel.count > 0 ? eventModel.count + " eventos cadastrados" : "Sem eventos hoje"
            entryDelay: 45

            AgendaMiniRow {
                iconName: eventModel.count > 0 ? eventModel.get(0).iconName : "calendar"
                accent: eventModel.count > 0 ? root.eventAccentColor(eventModel.get(0).accent) : root.winAccent2
                title: eventModel.count > 0 ? eventModel.get(0).title : "Sem eventos"
                detail: eventModel.count > 0 ? root.eventTimeText(eventModel.get(0)) : "Use o botão Novo evento para começar"
            }

            Item { Layout.fillHeight: true }

            Text {
                Layout.fillWidth: true
                text: eventModel.count > 0 ? "Ver todos os eventos →" : "Nada agendado por enquanto"
                color: root.agendaSoft
                font.family: root.uiFont
                font.pixelSize: 11
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignRight
            }
        }

        AgendaPanel {
            Layout.fillWidth: true
            Layout.preferredHeight: 230
            title: "Resumo do mês"
            subtitle: "Visão geral rápida"
            entryDelay: 75

            AgendaMetric { iconName: "calendar"; title: "Total de eventos"; value: String(eventModel.count); detail: "este mês"; accent: root.winAccent2; entryDelay: 115 }
            AgendaMetric { iconName: "bell"; title: "Lembretes ativos"; value: "0"; detail: "pendentes"; accent: root.winAccent; entryDelay: 145 }
            AgendaMetric { iconName: "clock"; title: "Horas agendadas"; value: eventModel.count > 0 ? String(eventModel.count) + "h" : "0h"; detail: "estimado"; accent: root.eventAccentColor("green"); entryDelay: 175 }
        }

        AgendaPanel {
            Layout.fillWidth: true
            Layout.preferredHeight: 230
            title: "Eventos por etiqueta"
            subtitle: "Distribuição"
            entryDelay: 105

            Repeater {
                model: [["Trabalho", "blue"], ["Pessoal", "orange"], ["Projetos", "green"], ["Outros", "purple"]]
                AgendaMiniRow {
                    iconName: "box"
                    accent: root.eventAccentColor(modelData[1])
                    title: modelData[0]
                    detail: "0 eventos"
                    entryDelay: 135 + index * 24
                }
            }
        }

        AgendaPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: "Próximos eventos"
            subtitle: "O que vem depois"
            entryDelay: 135

            Repeater {
                model: Math.min(eventModel.count, 5)
                AgendaMiniRow {
                    readonly property var eventItem: eventModel.get(index)
                    iconName: eventItem.iconName
                    accent: root.eventAccentColor(eventItem.accent)
                    title: eventItem.title
                    detail: root.eventRelativeDate(eventItem) + " · " + root.eventTimeText(eventItem)
                    entryDelay: 165 + index * 28
                }
            }

            Text {
                Layout.fillWidth: true
                visible: eventModel.count <= 0
                text: "Sem eventos"
                color: root.agendaSoft
                font.family: root.uiFont
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
            }
        }

        AgendaPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: "Esta semana"
            subtitle: "Agenda resumida"
            entryDelay: 165

            Repeater {
                model: Math.min(eventModel.count, 4)
                AgendaMiniRow {
                    readonly property var eventItem: eventModel.get(index)
                    iconName: eventItem.iconName
                    accent: root.eventAccentColor(eventItem.accent)
                    title: eventItem.title
                    detail: root.eventDateLabel(eventItem.date, false)
                    entryDelay: 195 + index * 28
                }
            }
        }

        AgendaPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: "Atividade recente"
            subtitle: "Últimas alterações"
            entryDelay: 195

            AgendaMiniRow { iconName: "plus"; accent: root.winAccent2; title: eventModel.count > 0 ? "Evento atualizado" : "Agenda pronta"; detail: eventModel.count > 0 ? "Dados salvos localmente" : "Nenhum evento criado ainda"; entryDelay: 225 }
            AgendaMiniRow { iconName: "settings"; accent: root.winAccent; title: "Etiquetas disponíveis"; detail: "Trabalho, Pessoal, Projetos e Outros"; entryDelay: 255 }
        }
    }

    component AgendaCalendarSection: RowLayout {
        spacing: 14
        opacity: root.agendaSectionOpacity(0, 220)
        transform: Translate { y: root.agendaSectionTranslateY(0, 12) }

        AgendaPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: "Calendário"
            subtitle: "Mês atual"
            entryDelay: 45

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 7
                columnSpacing: 1
                rowSpacing: 1

                Repeater {
                    model: ["DOM", "SEG", "TER", "QUA", "QUI", "SEX", "SÁB"]
                    Text {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        text: modelData
                        color: root.agendaSoft
                        font.family: root.uiFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Repeater {
                    model: 35
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 5
                        color: root.alpha(root.agendaFieldFill, 0.42)
                        border.width: 1
                        border.color: root.agendaLine

                        Text {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.leftMargin: 12
                            anchors.topMargin: 9
                            text: String(index + 1)
                            color: root.agendaInk
                            font.family: root.uiFont
                            font.pixelSize: 14
                            font.weight: index === 1 ? Font.Bold : Font.Medium
                        }

                        Rectangle {
                            visible: index % 6 === 1 || index % 7 === 3
                            anchors.centerIn: parent
                            width: 5
                            height: 5
                            radius: 3
                            color: root.eventAccentColor(index % 2 === 0 ? "green" : "orange")
                        }
                    }
                }
            }
        }

        AgendaPanel {
            Layout.preferredWidth: 360
            Layout.fillHeight: true
            title: "Agenda do dia"
            subtitle: root.todayIso()
            entryDelay: 130

            Repeater {
                model: Math.min(eventModel.count, 6)
                AgendaMiniRow {
                    readonly property var eventItem: eventModel.get(index)
                    iconName: eventItem.iconName
                    accent: root.eventAccentColor(eventItem.accent)
                    title: eventItem.title
                    detail: root.eventTimeText(eventItem)
                    entryDelay: 165 + index * 30
                }
            }

            Text {
                Layout.fillWidth: true
                visible: eventModel.count <= 0
                text: "Sem eventos para este dia"
                color: root.agendaSoft
                font.family: root.uiFont
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    component AgendaLabelsSection: RowLayout {
        spacing: 14
        opacity: root.agendaSectionOpacity(0, 220)
        transform: Translate { y: root.agendaSectionTranslateY(0, 12) }

        AgendaPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: "Etiquetas"
            subtitle: "Organize seus eventos por tema ou área"
            entryDelay: 45

            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: labelModel.count <= 0
                text: "Sem etiquetas"
                color: root.agendaSoft
                font.family: root.uiFont
                font.pixelSize: 12
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: root.agendaSectionOpacity(90, 180)
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: labelModel.count > 0
                clip: true
                contentWidth: width
                contentHeight: labelGrid.implicitHeight

                GridLayout {
                    id: labelGrid

                    width: parent.width
                    columns: 2
                    columnSpacing: 14
                    rowSpacing: 14

                    Repeater {
                        model: labelModel.count

                        Rectangle {
                            id: labelCard

                            readonly property var labelItem: labelModel.get(index)
                            readonly property bool selected: index === root.labelSelectedIndex && !root.labelEditing
                            property bool hovered: false

                            Layout.preferredWidth: (labelGrid.width - labelGrid.columnSpacing) / 2
                            Layout.preferredHeight: 144
                            z: root.labelMenuIndex === index ? 30 : 1
                            radius: 12
                            color: selected ? root.alpha(root.agendaCardActive, 0.80) : (hovered ? root.alpha(root.agendaFieldFill, 0.78) : root.alpha(root.agendaFieldFill, 0.58))
                            border.width: 1
                            border.color: selected ? root.alpha(root.winAccent, 0.48) : root.agendaLine
                            opacity: root.agendaSectionOpacity(95 + index * 28, 180)
                            scale: root.agendaSectionScale(95 + index * 28, 0.975, 1.0)
                            transform: Translate { y: root.agendaSectionTranslateY(95 + index * 28, 8) }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: labelCard.hovered = true
                                onExited: labelCard.hovered = false
                                onClicked: root.selectLabel(index)
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Rectangle {
                                        Layout.preferredWidth: 14
                                        Layout.preferredHeight: 14
                                        radius: 7
                                        color: root.eventAccentColor(labelCard.labelItem.accent)
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: labelCard.labelItem.name
                                        color: root.agendaInk
                                        font.family: root.uiFont
                                        font.pixelSize: 14
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 28
                                        Layout.preferredHeight: 28
                                        radius: 8
                                        color: root.labelMenuIndex === index ? root.alpha(root.agendaCardActive, 0.76) : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "⋮"
                                            color: root.agendaSoft
                                            font.family: root.uiFont
                                            font.pixelSize: 18
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.labelMenuIndex = root.labelMenuIndex === index ? -1 : index
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    text: labelCard.labelItem.description.length > 0 ? labelCard.labelItem.description : "Sem descrição."
                                    color: root.agendaSoft
                                    font.family: root.uiFont
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    wrapMode: Text.WordWrap
                                    elide: Text.ElideRight
                                }

                                AgendaButton {
                                    Layout.alignment: Qt.AlignRight
                                    Layout.preferredWidth: 96
                                    Layout.preferredHeight: 32
                                    text: "Editar"
                                    iconName: "pencil"
                                    onClicked: root.editLabel(index)
                                }
                            }

                            Rectangle {
                                visible: root.labelMenuIndex === index
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.topMargin: 44
                                anchors.rightMargin: 12
                                width: 128
                                height: 76
                                z: 20
                                radius: 10
                                color: root.alpha(root.winSurfaceDeep, root.agendaDark ? 0.86 : 0.72)
                                border.width: 1
                                border.color: root.agendaLine

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 4

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 30
                                        radius: 7
                                        color: menuEditArea.containsMouse ? root.alpha(root.agendaCardActive, 0.72) : "transparent"

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 8

                                            PopupIcon { Layout.preferredWidth: 14; Layout.preferredHeight: 14; iconName: "pencil"; lineColor: root.agendaInk }
                                            Text { Layout.fillWidth: true; text: "Editar"; color: root.agendaInk; font.family: root.uiFont; font.pixelSize: 11; font.weight: Font.Bold }
                                        }

                                        MouseArea {
                                            id: menuEditArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.editLabel(index)
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 30
                                        radius: 7
                                        color: menuDeleteArea.containsMouse ? Qt.rgba(0.95, 0.24, 0.20, 0.14) : "transparent"

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 8

                                            PopupIcon { Layout.preferredWidth: 14; Layout.preferredHeight: 14; iconName: "logout"; lineColor: Qt.rgba(0.86, 0.18, 0.14, 1) }
                                            Text { Layout.fillWidth: true; text: "Apagar"; color: Qt.rgba(0.86, 0.18, 0.14, 1); font.family: root.uiFont; font.pixelSize: 11; font.weight: Font.Bold }
                                        }

                                        MouseArea {
                                            id: menuDeleteArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.deleteLabel(index)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        AgendaPanel {
            Layout.preferredWidth: 340
            Layout.fillHeight: true
            title: root.labelEditing ? (root.labelEditingIndex >= 0 ? "Editar etiqueta" : "Nova etiqueta") : "Detalhes da etiqueta"
            subtitle: root.labelEditing ? "Organize seus eventos por tema" : (root.selectedLabel() ? root.selectedLabel().name : "Sem etiqueta")
            entryDelay: 140

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.labelEditing
                spacing: 10

                AgendaField {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    label: "Nome"
                    placeholder: "Nome da etiqueta"
                    text: root.labelNameDraft
                    introMode: "detail"
                    entryDelay: 45
                    onTextChanged: root.labelNameDraft = text
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    opacity: root.agendaDetailOpacity(75, 180)
                    transform: Translate { y: root.agendaDetailTranslateY(75, 7) }

                    Text {
                        Layout.fillWidth: true
                        text: "Cor"
                        color: root.agendaSoft
                        font.family: root.uiFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 9

                        Repeater {
                            model: ["blue", "green", "purple", "orange"]

                            Rectangle {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                radius: 14
                                color: root.eventAccentColor(modelData)
                                border.width: root.labelAccentDraft === modelData ? 2 : 1
                                border.color: root.labelAccentDraft === modelData ? root.agendaInk : root.agendaLine

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.labelAccentDraft = modelData
                                }
                            }
                        }
                    }
                }

                AgendaTextArea {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    label: "Descrição"
                    placeholder: "Detalhes da etiqueta"
                    text: root.labelDescriptionDraft
                    introMode: "detail"
                    entryDelay: 120
                    onTextChanged: root.labelDescriptionDraft = text
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    AgendaButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        text: "Salvar"
                        iconName: "plus"
                        dark: true
                        introMode: "detail"
                        entryDelay: 170
                        onClicked: root.saveLabelDraft()
                    }

                    AgendaButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        text: "Cancelar"
                        iconName: "logout"
                        introMode: "detail"
                        entryDelay: 195
                        onClicked: root.cancelLabelEdit()
                    }
                }

                AgendaButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    visible: root.labelEditingIndex >= 0
                    text: "Apagar etiqueta"
                    iconName: "logout"
                    danger: true
                    introMode: "detail"
                    entryDelay: 225
                    onClicked: root.deleteLabel(root.labelEditingIndex)
                }
            }

            ColumnLayout {
                readonly property var currentLabel: root.selectedLabel()

                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !root.labelEditing
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: parent.currentLabel === null
                    text: "Sem etiquetas"
                    color: root.agendaSoft
                    font.family: root.uiFont
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    visible: parent.currentLabel !== null

                    PopupIcon {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 34
                        height: 34
                        iconName: parent.parent.currentLabel ? parent.parent.currentLabel.iconName : "box"
                        lineColor: parent.parent.currentLabel ? root.eventAccentColor(parent.parent.currentLabel.accent) : root.agendaSoft
                    }
                }

                AgendaMetric {
                    visible: parent.currentLabel !== null
                    iconName: "box"
                    title: "Eventos vinculados"
                    value: parent.currentLabel ? String(root.labelEventCount(parent.currentLabel.name)) : "0"
                    detail: "eventos"
                    accent: parent.currentLabel ? root.eventAccentColor(parent.currentLabel.accent) : root.winAccent2
                    entryDelay: 80
                }

                AgendaMiniRow {
                    visible: parent.currentLabel !== null
                    iconName: "bell"
                    accent: root.winAccent
                    title: "Lembrete padrão"
                    detail: "15 minutos antes"
                    entryDelay: 115
                }

                AgendaMiniRow {
                    visible: parent.currentLabel !== null
                    iconName: "calendar"
                    accent: root.winAccent2
                    title: "Visibilidade"
                    detail: "Visível no calendário"
                    entryDelay: 145
                }

                AgendaMiniRow {
                    visible: parent.currentLabel !== null
                    iconName: "pencil"
                    accent: parent.currentLabel ? root.eventAccentColor(parent.currentLabel.accent) : root.eventAccentColor("green")
                    title: "Descrição"
                    detail: parent.currentLabel && parent.currentLabel.description.length > 0 ? parent.currentLabel.description : "Sem descrição."
                    entryDelay: 175
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    visible: parent.currentLabel !== null
                    spacing: 8

                    AgendaButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        text: "Editar"
                        iconName: "pencil"
                        introMode: "detail"
                        entryDelay: 210
                        onClicked: root.editLabel(root.labelSelectedIndex)
                    }

                    AgendaButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        text: "Apagar"
                        iconName: "logout"
                        danger: true
                        introMode: "detail"
                        entryDelay: 235
                        onClicked: root.deleteLabel(root.labelSelectedIndex)
                    }
                }
            }
        }
    }

    component AgendaRemindersSection: RowLayout {
        spacing: 14
        opacity: root.agendaSectionOpacity(0, 220)
        transform: Translate { y: root.agendaSectionTranslateY(0, 12) }

        AgendaPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: "Lembretes"
            subtitle: "Alertas e tarefas"
            entryDelay: 45

            Repeater {
                model: [
                    ["Enviar proposta para cliente", "Hoje · 09:00", "orange", false],
                    ["Reunião de alinhamento", "Hoje · 10:30", "blue", false],
                    ["Atualizar apresentação", "Hoje · 14:00", "green", false],
                    ["Ligar para Joana", "Hoje · 16:30", "purple", false],
                    ["Fazer backup dos arquivos", "Concluído · 08:00", "green", true]
                ]

                AgendaMiniRow {
                    iconName: modelData[3] ? "clock" : "bell"
                    accent: root.eventAccentColor(modelData[2])
                    title: modelData[0]
                    detail: modelData[1]
                    checked: modelData[3]
                    entryDelay: 95 + index * 30
                }
            }
        }

        ColumnLayout {
            Layout.preferredWidth: 340
            Layout.fillHeight: true
            spacing: 14

            AgendaPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: 260
                title: "Configurações de lembretes"
                entryDelay: 130

                AgendaMiniRow { iconName: "volume"; accent: root.winAccent2; title: "Som de notificação"; detail: "Gentle Ping"; entryDelay: 165 }
                AgendaMiniRow { iconName: "clock"; accent: root.winAccent; title: "Antecedência padrão"; detail: "15 minutos antes"; entryDelay: 195 }
                AgendaMiniRow { iconName: "calendar"; accent: root.eventAccentColor("green"); title: "Agrupar por dia"; detail: "Ativo"; entryDelay: 225 }
            }

            AgendaPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "Resumo"
                entryDelay: 190

                AgendaMetric { iconName: "bell"; title: "Total"; value: "5"; detail: "lembretes"; accent: root.winAccent2; entryDelay: 225 }
                AgendaMetric { iconName: "clock"; title: "Pendentes"; value: "4"; detail: "ativos"; accent: root.winAccent; entryDelay: 255 }
                AgendaMetric { iconName: "calendar"; title: "Concluídos"; value: "1"; detail: "finalizado"; accent: root.eventAccentColor("green"); entryDelay: 285 }
            }
        }
    }

    component AgendaAnimatedTitle: RowLayout {
        id: animatedTitle

        property string text: ""
        property color color: root.agendaInk
        property int pixelSize: 26
        property int entryDelay: 0

        spacing: 0
        opacity: root.popupIntroOpacity(entryDelay, 210)
        transform: Translate { y: root.popupIntroTranslateY(animatedTitle.entryDelay, 8) }

        Repeater {
            model: animatedTitle.text.length

            Text {
                text: animatedTitle.text.charAt(index)
                color: animatedTitle.color
                opacity: root.agendaLoopWave(index * 0.055, 0.82, 1.0)
                font.family: root.uiFont
                font.pixelSize: animatedTitle.pixelSize
                font.weight: Font.Bold
                transform: Translate { y: -root.agendaLoopWave(index * 0.055, 0, 1.5) }
            }
        }
    }

    component AgendaSidebarButton: Rectangle {
        id: sidebarButton

        property string iconName: "calendar"
        property string title: ""
        property bool active: false
        property bool hovered: false
        property string introMode: "none"
        property int entryDelay: 0
        signal clicked()

        implicitHeight: 42
        radius: 9
        color: active ? root.agendaCardActive : (hovered ? root.alpha(root.agendaCard, 0.72) : "transparent")
        border.width: active ? 1 : 0
        border.color: root.agendaLine
        opacity: root.scopedIntroOpacity(introMode, entryDelay, 170)
        scale: root.scopedIntroScale(introMode, entryDelay, 0.965, 1.0)
        transform: Translate { y: root.scopedIntroTranslateY(sidebarButton.introMode, sidebarButton.entryDelay, 8) }
        clip: true

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: sidebarButton.active
            color: root.alpha(root.winAccent2, root.agendaLoopGlow(sidebarButton.entryDelay * 0.001, 0.10))
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            PopupIcon {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                iconName: sidebarButton.iconName
                lineColor: root.agendaInk
            }

            Text {
                Layout.fillWidth: true
                text: sidebarButton.title
                color: root.agendaInk
                font.family: root.uiFont
                font.pixelSize: 12
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Rectangle {
                visible: sidebarButton.active
                Layout.preferredWidth: 5
                Layout.preferredHeight: 5
                radius: 3
                color: root.winAccent
                opacity: root.agendaLoopWave(sidebarButton.entryDelay * 0.001, 0.62, 1.0)
                scale: root.agendaLoopWave(sidebarButton.entryDelay * 0.001, 0.82, 1.42)
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: sidebarButton.hovered = true
            onExited: sidebarButton.hovered = false
            onClicked: sidebarButton.clicked()
        }
    }

    component AgendaField: Rectangle {
        id: agendaField

        property alias text: input.text
        property string placeholder: ""
        property string label: ""
        property string iconName: ""
        property bool editable: true
        property string introMode: "none"
        property int entryDelay: 0

        radius: 9
        color: root.agendaFieldFill
        border.width: 1
        border.color: input.activeFocus ? root.agendaFieldBorderActive : root.agendaFieldBorder
        opacity: root.scopedIntroOpacity(introMode, entryDelay, 170)
        scale: root.scopedIntroScale(introMode, entryDelay, 0.975, 1.0)
        transform: Translate { y: root.scopedIntroTranslateY(agendaField.introMode, agendaField.entryDelay, 7) }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 9

            PopupIcon {
                visible: agendaField.iconName.length > 0
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                iconName: agendaField.iconName
                lineColor: root.agendaSoft
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    visible: agendaField.label.length > 0
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 4
                    text: agendaField.label
                    color: root.agendaSoft
                    font.family: root.uiFont
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    visible: input.text.length <= 0
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: agendaField.label.length > 0 ? 7 : 0
                    text: agendaField.placeholder
                    color: root.alpha(root.agendaSoft, 0.66)
                    font.family: root.uiFont
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                TextInput {
                    id: input
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: agendaField.label.length > 0 ? 7 : 0
                    readOnly: !agendaField.editable
                    color: root.agendaInk
                    selectionColor: root.alpha(root.winAccent, 0.32)
                    selectedTextColor: root.agendaInk
                    font.family: root.uiFont
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    clip: true
                }
            }
        }
    }

    component AgendaTextArea: Rectangle {
        id: agendaTextArea

        property alias text: edit.text
        property string placeholder: ""
        property string label: ""
        property string introMode: "none"
        property int entryDelay: 0

        radius: 9
        color: root.agendaFieldFill
        border.width: 1
        border.color: edit.activeFocus ? root.agendaFieldBorderActive : root.agendaFieldBorder
        opacity: root.scopedIntroOpacity(introMode, entryDelay, 180)
        scale: root.scopedIntroScale(introMode, entryDelay, 0.982, 1.0)
        transform: Translate { y: root.scopedIntroTranslateY(agendaTextArea.introMode, agendaTextArea.entryDelay, 8) }

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 8
            text: agendaTextArea.label
            color: root.agendaSoft
            font.family: root.uiFont
            font.pixelSize: 8
            font.weight: Font.Bold
            elide: Text.ElideRight
        }

        Text {
            visible: edit.text.length <= 0
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 28
            text: agendaTextArea.placeholder
            color: root.alpha(root.agendaSoft, 0.66)
            font.family: root.uiFont
            font.pixelSize: 11
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        TextEdit {
            id: edit
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 26
            anchors.bottomMargin: 10
            wrapMode: TextEdit.Wrap
            color: root.agendaInk
            selectionColor: root.alpha(root.winAccent, 0.32)
            selectedTextColor: root.agendaInk
            font.family: root.uiFont
            font.pixelSize: 11
            font.weight: Font.Medium
            clip: true
        }
    }

    component AgendaButton: Rectangle {
        id: agendaButton

        property string text: ""
        property string iconName: "plus"
        property bool dark: false
        property bool danger: false
        property bool hovered: false
        property string introMode: "none"
        property int entryDelay: 0
        signal clicked()

        radius: 9
        color: danger ? (hovered ? Qt.rgba(0.95, 0.24, 0.20, 0.14) : root.alpha(root.agendaFieldFill, 0.72))
              : dark ? (root.agendaDark ? root.alpha(root.winAccent, hovered ? 0.44 : 0.32) : (hovered ? Qt.rgba(0.22, 0.20, 0.12, 0.94) : Qt.rgba(0.18, 0.17, 0.10, 0.92)))
              : (hovered ? root.alpha(root.agendaCardActive, 0.90) : root.alpha(root.agendaFieldFill, 0.78))
        border.width: 1
        border.color: danger ? Qt.rgba(0.86, 0.18, 0.14, 0.34) : root.agendaLine
        opacity: root.scopedIntroOpacity(introMode, entryDelay, 170)
        scale: root.scopedIntroScale(introMode, entryDelay, 0.96, 1.0)
        transform: Translate { y: root.scopedIntroTranslateY(agendaButton.introMode, agendaButton.entryDelay, 7) }
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: agendaButton.dark && root.popupType === "agenda"
            color: root.alpha(root.winAccent2, root.agendaLoopGlow(agendaButton.entryDelay * 0.001 + 0.12, 0.11))
        }

        Rectangle {
            visible: agendaButton.dark && root.popupType === "agenda"
            width: Math.max(28, parent.width * 0.26)
            height: parent.height * 1.4
            radius: 10
            x: -width + (parent.width + width) * root.agendaLoopWave(agendaButton.entryDelay * 0.001 + 0.28, 0, 1)
            y: -parent.height * 0.2
            rotation: 9
            color: root.alpha(root.agendaDark ? root.ink : Qt.rgba(1, 1, 1, 1), 0.075)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 7

            PopupIcon {
                Layout.preferredWidth: 15
                Layout.preferredHeight: 15
                iconName: agendaButton.iconName
                lineColor: agendaButton.danger ? Qt.rgba(0.86, 0.18, 0.14, 1) : (agendaButton.dark && !root.agendaDark ? Qt.rgba(1, 1, 1, 0.92) : root.agendaInk)
            }

            Text {
                Layout.fillWidth: true
                text: agendaButton.text
                color: agendaButton.danger ? Qt.rgba(0.86, 0.18, 0.14, 1) : (agendaButton.dark && !root.agendaDark ? Qt.rgba(1, 1, 1, 0.94) : root.agendaInk)
                font.family: root.uiFont
                font.pixelSize: 11
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                opacity: agendaButton.dark && root.popupType === "agenda" ? root.agendaLoopWave(agendaButton.entryDelay * 0.001 + 0.36, 0.86, 1.0) : 1
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            enabled: agendaButton.enabled
            cursorShape: Qt.PointingHandCursor
            onEntered: agendaButton.hovered = true
            onExited: agendaButton.hovered = false
            onClicked: agendaButton.clicked()
        }
    }

    component AgendaMonthControl: Rectangle {
        id: monthControl

        property string title: ""
        property string introMode: "none"
        property int entryDelay: 0

        radius: 9
        color: root.agendaFieldFill
        border.width: 1
        border.color: root.agendaFieldBorder
        opacity: root.scopedIntroOpacity(introMode, entryDelay, 170)
        scale: root.scopedIntroScale(introMode, entryDelay, 0.975, 1.0)
        transform: Translate { y: root.scopedIntroTranslateY(monthControl.introMode, monthControl.entryDelay, 7) }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            spacing: 10

            PopupIcon {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                iconName: "calendar"
                lineColor: root.agendaSoft
            }

            Text {
                Layout.fillWidth: true
                text: monthControl.title
                color: root.agendaInk
                font.family: root.uiFont
                font.pixelSize: 12
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text { text: "‹"; color: root.agendaSoft; font.family: root.uiFont; font.pixelSize: 19 }
            Text { text: "›"; color: root.agendaSoft; font.family: root.uiFont; font.pixelSize: 19 }
        }
    }

    component AgendaCalendarCell: Rectangle {
        id: calendarCell

        property string label: ""
        property bool currentMonth: true
        property bool today: false
        property bool selected: false
        property int eventCount: 0
        property color accent: root.winAccent2

        radius: 16
        color: today || selected ? (root.agendaDark ? root.alpha(root.winAccent, 0.48) : Qt.rgba(0.31, 0.27, 0.15, 0.88)) : "transparent"
        scale: (today || selected) && root.popupType === "agenda" ? root.agendaLoopWave(Number(label) * 0.017, 0.96, 1.03) : 1

        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 6
            height: parent.height + 6
            radius: parent.radius + 3
            visible: (calendarCell.today || calendarCell.selected) && root.popupType === "agenda"
            color: "transparent"
            border.width: 1
            border.color: root.alpha(calendarCell.accent, root.agendaLoopGlow(Number(calendarCell.label) * 0.017, 0.32))
        }

        Text {
            anchors.centerIn: parent
            text: calendarCell.label
            color: (today || selected) ? (root.agendaDark ? root.ink : Qt.rgba(1, 1, 1, 0.94)) : (currentMonth ? root.agendaInk : root.alpha(root.agendaSoft, 0.48))
            font.family: root.uiFont
            font.pixelSize: 12
            font.weight: today || selected ? Font.Bold : Font.Medium
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 2
            spacing: 2

            Repeater {
                model: Math.min(calendarCell.eventCount, 3)
                Rectangle {
                    width: 3
                    height: 3
                    radius: 2
                    color: calendarCell.accent
                    opacity: root.agendaLoopWave(index * 0.12 + Number(calendarCell.label) * 0.011, 0.55, 1.0)
                    scale: root.agendaLoopWave(index * 0.12 + Number(calendarCell.label) * 0.011, 0.8, 1.45)
                }
            }
        }
    }

    component AgendaCompactRow: Rectangle {
        id: compactRow

        property string iconName: "calendar"
        property color accent: root.winAccent2
        property string title: ""
        property string timeText: ""
        property string location: ""
        property bool hovered: false
        property string introMode: "section"
        property int entryDelay: 130
        signal clicked()

        radius: 9
        color: hovered ? root.alpha(root.agendaCardActive, 0.80) : "transparent"
        opacity: root.scopedIntroOpacity(introMode, entryDelay, 170)
        transform: Translate { y: root.scopedIntroTranslateY(compactRow.introMode, compactRow.entryDelay, 7) }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 12

            PopupIcon {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                iconName: compactRow.iconName
                lineColor: compactRow.accent
                opacity: root.popupType === "agenda" ? root.agendaLoopWave(compactRow.entryDelay * 0.001, 0.72, 1.0) : 1
                scale: root.popupType === "agenda" ? root.agendaLoopWave(compactRow.entryDelay * 0.001, 0.96, 1.05) : 1
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: compactRow.title
                    color: root.agendaInk
                    font.family: root.uiFont
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: compactRow.timeText
                    color: root.agendaSoft
                    font.family: root.uiFont
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: compactRow.location
                    color: root.alpha(root.agendaSoft, 0.82)
                    font.family: root.uiFont
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: compactRow.hovered = true
            onExited: compactRow.hovered = false
            onClicked: compactRow.clicked()
        }
    }

    component AgendaEventCard: Rectangle {
        id: eventCard

        property string iconName: "calendar"
        property color accent: root.winAccent2
        property string title: ""
        property string subtitle: ""
        property string timeText: ""
        property bool selected: false
        property bool hovered: false
        property string introMode: "section"
        property int entryDelay: 130
        signal clicked()

        radius: 11
        color: selected ? root.agendaCardActive : (hovered ? root.alpha(root.agendaFieldFill, 0.86) : root.alpha(root.agendaFieldFill, 0.62))
        border.width: 1
        border.color: selected ? root.alpha(root.winAccent, 0.30) : root.agendaLine
        opacity: root.scopedIntroOpacity(introMode, entryDelay, 180)
        scale: root.scopedIntroScale(introMode, entryDelay, 0.975, 1.0)
        transform: Translate { y: root.scopedIntroTranslateY(eventCard.introMode, eventCard.entryDelay, 8) }
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: eventCard.selected && root.popupType === "agenda"
            color: root.alpha(eventCard.accent, root.agendaLoopGlow(eventCard.entryDelay * 0.001 + 0.06, 0.13))
        }

        Rectangle {
            visible: eventCard.selected && root.popupType === "agenda"
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 2
            color: root.alpha(eventCard.accent, root.agendaLoopWave(eventCard.entryDelay * 0.001 + 0.16, 0.22, 0.66))
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 12

            PopupIcon {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                iconName: eventCard.iconName
                lineColor: eventCard.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 7

                    Rectangle {
                        Layout.preferredWidth: 6
                        Layout.preferredHeight: 6
                        radius: 3
                        color: eventCard.accent
                        opacity: eventCard.selected ? root.agendaLoopWave(eventCard.entryDelay * 0.001 + 0.24, 0.64, 1.0) : 1
                        scale: eventCard.selected ? root.agendaLoopWave(eventCard.entryDelay * 0.001 + 0.24, 0.88, 1.42) : 1
                    }

                    Text {
                        Layout.fillWidth: true
                        text: eventCard.title
                        color: root.agendaInk
                        font.family: root.uiFont
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: eventCard.timeText
                    color: root.agendaSoft
                    font.family: root.uiFont
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: eventCard.subtitle
                    color: root.alpha(root.agendaSoft, 0.86)
                    font.family: root.uiFont
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }

            Text {
                text: "›"
                color: root.agendaSoft
                font.family: root.uiFont
                font.pixelSize: 18
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: eventCard.hovered = true
            onExited: eventCard.hovered = false
            onClicked: eventCard.clicked()
        }
    }

    component AgendaDetailRow: ColumnLayout {
        id: detailRow

        property string label: ""
        property string value: ""
        property color accent: root.winAccent2
        property bool fill: false
        property string introMode: "detail"
        property int entryDelay: 80

        Layout.fillWidth: true
        Layout.fillHeight: fill
        spacing: 5
        opacity: root.scopedIntroOpacity(introMode, entryDelay, 170)
        transform: Translate { y: root.scopedIntroTranslateY(detailRow.introMode, detailRow.entryDelay, 7) }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 7
                Layout.preferredHeight: 7
                radius: 4
                color: detailRow.accent
            }

            Text {
                Layout.fillWidth: true
                text: detailRow.label
                color: root.agendaInk
                font.family: root.uiFont
                font.pixelSize: 12
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.fillHeight: detailRow.fill
            text: detailRow.value
            color: root.agendaSoft
            font.family: root.uiFont
            font.pixelSize: 11
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
            elide: detailRow.fill ? Text.ElideNone : Text.ElideRight
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.agendaLine
        }
    }

    component WeatherPanelCard: Rectangle {
        id: weatherCard

        default property alias content: contentHost.data
        property string title: ""
        property int entryDelay: 100

        radius: 12
        color: root.alpha(root.agendaCard, 0.72)
        border.width: 1
        border.color: root.alpha(root.winAccent, root.agendaDark ? 0.18 : 0.13)
        antialiasing: true
        clip: true
        opacity: root.popupIntroOpacity(entryDelay, 210)
        scale: root.popupIntroScale(entryDelay, 0.982, 1.0)
        transform: Translate { y: root.popupIntroTranslateY(weatherCard.entryDelay, 10) }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.alpha(root.winAccent2, root.agendaLoopGlow(weatherCard.entryDelay * 0.001, 0.055))
        }

        Rectangle {
            width: Math.max(40, parent.width * 0.20)
            height: parent.height * 1.35
            radius: 18
            x: -width + (parent.width + width) * root.agendaLoopWave(weatherCard.entryDelay * 0.001 + 0.18, 0, 1)
            y: -parent.height * 0.18
            rotation: 8
            color: root.alpha(root.ink, root.agendaDark ? 0.025 : 0.04)
        }

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            anchors.topMargin: 15
            text: weatherCard.title
            color: root.agendaInk
            font.family: root.uiFont
            font.pixelSize: 14
            font.weight: Font.Bold
            elide: Text.ElideRight
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 44
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            height: 1
            color: root.alpha(root.agendaLine, 0.62)
        }

        Item {
            id: contentHost

            anchors.fill: parent
        }
    }

    component WeatherMiniGlyph: Canvas {
        id: weatherGlyph

        property string iconName: "partly"
        property color accent: root.winAccent
        property color lineColor: root.agendaInk
        property int entryDelay: 80

        opacity: root.popupIntroOpacity(entryDelay, 190)
        scale: root.popupIntroPopScale(entryDelay, 0.92, 1.035, 1.0)

        onIconNameChanged: requestPaint()
        onAccentChanged: requestPaint()
        onLineColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            const s = Math.min(width, height)
            const cx = width / 2
            const cy = height / 2
            const name = (iconName || "partly").toLowerCase()

            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.lineWidth = Math.max(1.4, s * 0.055)

            function drawSun(x, y, r) {
                ctx.strokeStyle = accent
                ctx.fillStyle = root.alpha(accent, 0.18)
                ctx.beginPath()
                ctx.arc(x, y, r, 0, Math.PI * 2)
                ctx.fill()
                ctx.stroke()
                for (let i = 0; i < 8; i += 1) {
                    const a = i / 8 * Math.PI * 2
                    ctx.beginPath()
                    ctx.moveTo(x + Math.cos(a) * r * 1.55, y + Math.sin(a) * r * 1.55)
                    ctx.lineTo(x + Math.cos(a) * r * 2.05, y + Math.sin(a) * r * 2.05)
                    ctx.stroke()
                }
            }

            function drawCloud(x, y, scale) {
                ctx.strokeStyle = lineColor
                ctx.fillStyle = root.alpha(lineColor, root.agendaDark ? 0.08 : 0.10)
                ctx.beginPath()
                ctx.moveTo(x - 0.34 * scale, y + 0.16 * scale)
                ctx.lineTo(x + 0.36 * scale, y + 0.16 * scale)
                ctx.bezierCurveTo(x + 0.54 * scale, y + 0.16 * scale, x + 0.58 * scale, y - 0.08 * scale, x + 0.38 * scale, y - 0.12 * scale)
                ctx.bezierCurveTo(x + 0.30 * scale, y - 0.36 * scale, x + 0.04 * scale, y - 0.36 * scale, x - 0.04 * scale, y - 0.18 * scale)
                ctx.bezierCurveTo(x - 0.24 * scale, y - 0.30 * scale, x - 0.50 * scale, y - 0.06 * scale, x - 0.34 * scale, y + 0.16 * scale)
                ctx.closePath()
                ctx.fill()
                ctx.stroke()
            }

            if (name.indexOf("drop") >= 0 || name.indexOf("humid") >= 0) {
                ctx.strokeStyle = accent
                ctx.fillStyle = root.alpha(accent, 0.12)
                ctx.beginPath()
                ctx.moveTo(cx, cy - s * 0.34)
                ctx.bezierCurveTo(cx + s * 0.28, cy - s * 0.02, cx + s * 0.23, cy + s * 0.28, cx, cy + s * 0.32)
                ctx.bezierCurveTo(cx - s * 0.23, cy + s * 0.28, cx - s * 0.28, cy - s * 0.02, cx, cy - s * 0.34)
                ctx.fill()
                ctx.stroke()
                return
            }

            if (name.indexOf("wind") >= 0) {
                ctx.strokeStyle = lineColor
                for (let i = 0; i < 3; i += 1) {
                    const y = cy - s * 0.18 + i * s * 0.18
                    ctx.beginPath()
                    ctx.moveTo(cx - s * 0.32, y)
                    ctx.bezierCurveTo(cx - s * 0.02, y - s * 0.10, cx + s * 0.28, y - s * 0.02, cx + s * 0.34, y)
                    ctx.stroke()
                }
                return
            }

            if (name.indexOf("leaf") >= 0) {
                ctx.strokeStyle = accent
                ctx.fillStyle = root.alpha(accent, 0.13)
                ctx.beginPath()
                ctx.moveTo(cx - s * 0.28, cy + s * 0.22)
                ctx.bezierCurveTo(cx - s * 0.20, cy - s * 0.34, cx + s * 0.34, cy - s * 0.30, cx + s * 0.28, cy + s * 0.18)
                ctx.bezierCurveTo(cx + s * 0.02, cy + s * 0.36, cx - s * 0.16, cy + s * 0.32, cx - s * 0.28, cy + s * 0.22)
                ctx.fill()
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(cx - s * 0.22, cy + s * 0.18)
                ctx.lineTo(cx + s * 0.18, cy - s * 0.14)
                ctx.stroke()
                return
            }

            if (name.indexOf("spark") >= 0) {
                ctx.strokeStyle = accent
                for (let i = 0; i < 4; i += 1) {
                    const a = i * Math.PI / 2
                    ctx.beginPath()
                    ctx.moveTo(cx + Math.cos(a) * s * 0.08, cy + Math.sin(a) * s * 0.08)
                    ctx.lineTo(cx + Math.cos(a) * s * 0.34, cy + Math.sin(a) * s * 0.34)
                    ctx.stroke()
                }
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.08, 0, Math.PI * 2)
                ctx.stroke()
                return
            }

            if (name.indexOf("moon") >= 0 || name.indexOf("night") >= 0) {
                ctx.strokeStyle = lineColor
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.27, Math.PI * 0.35, Math.PI * 1.68)
                ctx.quadraticCurveTo(cx + s * 0.19, cy + s * 0.10, cx + s * 0.22, cy - s * 0.27)
                ctx.stroke()
                return
            }

            if (name.indexOf("rain") >= 0 || name.indexOf("shower") >= 0) {
                drawCloud(cx, cy - s * 0.06, s * 0.62)
                ctx.strokeStyle = accent
                for (let r = 0; r < 3; r += 1) {
                    ctx.beginPath()
                    ctx.moveTo(cx - s * 0.20 + r * s * 0.20, cy + s * 0.28)
                    ctx.lineTo(cx - s * 0.25 + r * s * 0.20, cy + s * 0.42)
                    ctx.stroke()
                }
                return
            }

            if (name.indexOf("cloud") >= 0) {
                drawCloud(cx, cy, s * 0.70)
                return
            }

            if (name.indexOf("sun") >= 0 || name.indexOf("clear") >= 0) {
                drawSun(cx, cy, s * 0.18)
                return
            }

            drawSun(cx - s * 0.16, cy - s * 0.18, s * 0.13)
            drawCloud(cx + s * 0.04, cy + s * 0.05, s * 0.62)
        }
    }

    component WeatherStatLine: Rectangle {
        id: statLine

        property string iconName: "drop"
        property string title: ""
        property string value: ""
        property int entryDelay: 120

        Layout.fillWidth: true
        Layout.preferredHeight: 28
        radius: 8
        color: root.alpha(root.agendaFieldFill, 0.40)
        border.width: 1
        border.color: root.alpha(root.agendaLine, 0.48)
        opacity: root.popupIntroOpacity(entryDelay, 180)
        transform: Translate { y: root.popupIntroTranslateY(statLine.entryDelay, 6) }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 9

            WeatherMiniGlyph {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                iconName: statLine.iconName
                accent: root.winAccent
                lineColor: root.agendaSoft
                entryDelay: statLine.entryDelay
            }

            Text {
                Layout.fillWidth: true
                text: statLine.title
                color: root.agendaInk
                font.family: root.uiFont
                font.pixelSize: 10
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                text: statLine.value
                color: root.agendaSoft
                font.family: root.uiFont
                font.pixelSize: 10
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }
    }

    component WeatherSunArc: Canvas {
        id: sunArc

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            const w = width
            const h = height
            const cx = w / 2
            const cy = h * 0.92
            const rx = w * 0.34
            const ry = h * 0.86

            ctx.reset()
            ctx.clearRect(0, 0, w, h)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.lineWidth = 1.3
            ctx.strokeStyle = root.alpha(root.agendaSoft, 0.36)
            ctx.beginPath()
            ctx.moveTo(w * 0.08, cy)
            ctx.lineTo(w * 0.92, cy)
            ctx.stroke()
            ctx.strokeStyle = root.alpha(root.agendaInk, 0.32)
            ctx.setLineDash([4, 4])
            ctx.beginPath()
            for (let i = 0; i <= 40; i += 1) {
                const t = i / 40
                const a = Math.PI + t * Math.PI
                const x = cx + Math.cos(a) * rx
                const y = cy + Math.sin(a) * ry
                if (i === 0)
                    ctx.moveTo(x, y)
                else
                    ctx.lineTo(x, y)
            }
            ctx.stroke()
            ctx.setLineDash([])

            ctx.strokeStyle = root.winAccent
            ctx.fillStyle = root.alpha(root.winAccent, 0.20)
            for (let p = 0; p < 2; p += 1) {
                const x = p === 0 ? w * 0.18 : w * 0.82
                const y = cy - h * 0.03
                ctx.beginPath()
                ctx.arc(x, y, h * 0.11, Math.PI, Math.PI * 2)
                ctx.fill()
                ctx.stroke()
                for (let r = 0; r < 5; r += 1) {
                    const a = Math.PI + r / 4 * Math.PI
                    ctx.beginPath()
                    ctx.moveTo(x + Math.cos(a) * h * 0.16, y + Math.sin(a) * h * 0.16)
                    ctx.lineTo(x + Math.cos(a) * h * 0.24, y + Math.sin(a) * h * 0.24)
                    ctx.stroke()
                }
            }
        }
    }

    component WeatherHourlyTile: Rectangle {
        id: hourlyTile

        property string time: "--"
        property string temp: "--°C"
        property string iconName: "partly"
        property string rain: "--"
        property int entryDelay: 120

        radius: 10
        color: root.alpha(root.agendaFieldFill, 0.54)
        border.width: 1
        border.color: root.alpha(root.agendaLine, 0.60)
        opacity: root.popupIntroOpacity(entryDelay, 185)
        scale: root.popupIntroScale(entryDelay, 0.96, 1.0)
        transform: Translate { y: root.popupIntroTranslateY(hourlyTile.entryDelay, 8) }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Text {
                Layout.fillWidth: true
                text: hourlyTile.time
                color: root.agendaSoft
                font.family: root.uiFont
                font.pixelSize: 10
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            WeatherMiniGlyph {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                iconName: hourlyTile.iconName
                accent: root.winAccent
                lineColor: root.agendaInk
                entryDelay: hourlyTile.entryDelay
            }

            Text {
                Layout.fillWidth: true
                text: hourlyTile.temp
                color: root.agendaInk
                font.family: root.uiFont
                font.pixelSize: 13
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: hourlyTile.rain
                color: root.agendaSoft
                font.family: root.uiFont
                font.pixelSize: 9
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }
    }

    component WeatherDailyRow: Item {
        id: dailyRow

        property string label: "--"
        property string desc: "--"
        property string iconName: "partly"
        property string maxTemp: "--°C"
        property string minTemp: "--°C"
        property string rain: "--"
        property int entryDelay: 120

        opacity: root.popupIntroOpacity(entryDelay, 175)
        transform: Translate { y: root.popupIntroTranslateY(dailyRow.entryDelay, 6) }

        RowLayout {
            anchors.fill: parent
            spacing: 10

            Text {
                Layout.preferredWidth: 98
                text: dailyRow.label
                color: root.agendaInk
                font.family: root.uiFont
                font.pixelSize: 11
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            WeatherMiniGlyph {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                iconName: dailyRow.iconName
                accent: root.winAccent
                lineColor: root.agendaInk
                entryDelay: dailyRow.entryDelay
            }

            Text {
                Layout.preferredWidth: 52
                text: dailyRow.maxTemp
                color: root.agendaInk
                font.family: root.uiFont
                font.pixelSize: 11
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                radius: 2
                color: root.alpha(root.agendaLine, 0.72)

                Rectangle {
                    width: parent.width * 0.64
                    height: parent.height
                    radius: parent.radius
                    color: root.alpha(root.winAccent, root.agendaLoopWave(dailyRow.entryDelay * 0.001, 0.58, 0.90))
                }
            }

            Text {
                Layout.preferredWidth: 52
                text: dailyRow.minTemp
                color: root.agendaSoft
                font.family: root.uiFont
                font.pixelSize: 11
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                Layout.preferredWidth: 44
                text: dailyRow.rain
                color: root.agendaSoft
                font.family: root.uiFont
                font.pixelSize: 10
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }
        }
    }

    component WeatherMetricTile: Rectangle {
        id: metricTile

        property string iconName: "spark"
        property string title: ""
        property string value: "--"
        property string detail: ""
        property color accent: root.winAccent
        property int entryDelay: 120

        radius: 12
        color: root.alpha(root.agendaCard, 0.62)
        border.width: 1
        border.color: root.alpha(root.agendaLine, 0.62)
        clip: true
        opacity: root.popupIntroOpacity(entryDelay, 185)
        scale: root.popupIntroScale(entryDelay, 0.97, 1.0)
        transform: Translate { y: root.popupIntroTranslateY(metricTile.entryDelay, 8) }

        Rectangle {
            width: parent.width * 0.92
            height: parent.height * 0.72
            radius: 16
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -parent.height * 0.40
            color: root.alpha(metricTile.accent, root.agendaLoopGlow(metricTile.entryDelay * 0.001 + 0.12, 0.12))
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 7

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                WeatherMiniGlyph {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    iconName: metricTile.iconName
                    accent: metricTile.accent
                    lineColor: root.agendaInk
                    entryDelay: metricTile.entryDelay
                }

                Text {
                    Layout.fillWidth: true
                    text: metricTile.title
                    color: root.agendaInk
                    font.family: root.uiFont
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
            }

            Text {
                Layout.fillWidth: true
                text: metricTile.value
                color: root.agendaInk
                font.family: root.uiFont
                font.pixelSize: metricTile.value.length > 8 ? 20 : 28
                font.weight: Font.Medium
                wrapMode: metricTile.value.length > 8 ? Text.WordWrap : Text.NoWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: metricTile.detail
                color: root.agendaSoft
                font.family: root.uiFont
                font.pixelSize: 10
                font.weight: Font.Medium
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
            }
        }
    }

    component WeatherRainMap: Canvas {
        id: rainMap

        property string city: root.weatherCity

        opacity: root.popupIntroOpacity(315, 200)
        scale: root.popupIntroScale(315, 0.985, 1.0)

        onCityChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            const w = width
            const h = height
            ctx.reset()
            ctx.clearRect(0, 0, w, h)

            ctx.fillStyle = root.alpha(root.agendaFieldFill, 0.72)
            roundRect(ctx, 0, 0, w, h, 12)
            ctx.fill()

            ctx.strokeStyle = root.alpha(root.agendaSoft, 0.18)
            ctx.lineWidth = 1
            for (let i = 1; i < 5; i += 1) {
                ctx.beginPath()
                ctx.moveTo(w * i / 5, h * 0.12)
                ctx.bezierCurveTo(w * (i / 5 + 0.05), h * 0.34, w * (i / 5 - 0.04), h * 0.56, w * i / 5, h * 0.88)
                ctx.stroke()
            }
            for (let j = 1; j < 4; j += 1) {
                ctx.beginPath()
                ctx.moveTo(w * 0.08, h * j / 4)
                ctx.bezierCurveTo(w * 0.32, h * (j / 4 + 0.05), w * 0.62, h * (j / 4 - 0.04), w * 0.92, h * j / 4)
                ctx.stroke()
            }

            const rainGradient = ctx.createLinearGradient(w * 0.18, h * 0.16, w * 0.80, h * 0.84)
            rainGradient.addColorStop(0, root.alpha(root.winAccent2, 0.10))
            rainGradient.addColorStop(0.42, root.alpha(root.eventAccentColor("green"), 0.42))
            rainGradient.addColorStop(1, root.alpha(root.winAccent, 0.16))
            ctx.fillStyle = rainGradient
            ctx.beginPath()
            ctx.moveTo(w * 0.12, h * 0.78)
            ctx.bezierCurveTo(w * 0.18, h * 0.44, w * 0.34, h * 0.26, w * 0.48, h * 0.20)
            ctx.bezierCurveTo(w * 0.62, h * 0.15, w * 0.76, h * 0.34, w * 0.84, h * 0.55)
            ctx.bezierCurveTo(w * 0.74, h * 0.74, w * 0.50, h * 0.86, w * 0.12, h * 0.78)
            ctx.closePath()
            ctx.fill()

            ctx.fillStyle = root.alpha(root.winAccent, root.agendaLoopWave(0.21, 0.16, 0.32))
            ctx.beginPath()
            ctx.arc(w * 0.54, h * 0.46, Math.min(w, h) * 0.18, 0, Math.PI * 2)
            ctx.fill()

            ctx.fillStyle = root.agendaInk
            ctx.font = root.canvasFont("bold", 12, root.uiFont)
            ctx.textAlign = "center"
            ctx.fillText(rainMap.city || "Local", w / 2, h * 0.52)
        }
    }

    component TimeCard: Rectangle {
            id: card

            property int entryDelay: 100

            radius: 8
            color: root.alpha(root.winCard, 0.82)
            border.width: 1
            border.color: root.alpha(root.winAccent, 0.18)
            antialiasing: true
            opacity: root.popupIntroOpacity(entryDelay, 190)
            scale: root.popupIntroScale(entryDelay, 0.975, 1.0)
            transform: Translate { y: root.popupIntroTranslateY(card.entryDelay, 8) }
        }

    component TimeSectionTitle: Text {
            color: root.alpha(root.inkSoft, 0.86)
            font.family: root.uiFont
            font.pixelSize: 10
            font.weight: Font.Bold
            elide: Text.ElideRight
        }

    component TimeEventRow: Item {
            id: eventRow

            property string iconName: "calendar"
            property color iconColor: root.winAccent2
            property string title: ""
            property string subtitle: ""
            property string time: ""
            property bool showDivider: false
            property int entryDelay: 210
            signal clicked()

            opacity: root.popupIntroOpacity(entryDelay, 180)
            transform: Translate { y: root.popupIntroTranslateY(eventRow.entryDelay, 6) }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 2
                anchors.rightMargin: 2
                spacing: 10

                PopupIcon {
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    iconName: eventRow.iconName
                    lineColor: root.alpha(root.inkSoft, 0.78)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            Layout.preferredWidth: 6
                            Layout.preferredHeight: 6
                            radius: 3
                            color: eventRow.iconColor
                        }

                        Text {
                            Layout.fillWidth: true
                            text: eventRow.title
                            color: root.ink
                            font.family: root.uiFont
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: eventRow.subtitle
                        color: root.inkSoft
                        font.family: root.uiFont
                        font.pixelSize: 9
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: eventRow.time
                        color: root.inkSoft
                        font.family: root.uiFont
                        font.pixelSize: 9
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                visible: eventRow.showDivider
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 38
                height: 1
                color: root.alpha(root.inkSoft, 0.08)
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: eventRow.clicked()
            }
        }

    component TimeActionButton: Rectangle {
            id: actionButton

            property string text: ""
            property bool hovered: false
            property int entryDelay: 100
            signal clicked()

            radius: 7
            color: hovered ? Qt.rgba(0.095, 0.100, 0.120, 0.70) : Qt.rgba(0.060, 0.064, 0.078, 0.58)
            border.width: 1
            border.color: root.alpha(root.inkSoft, hovered ? 0.22 : 0.10)
            opacity: root.popupIntroOpacity(entryDelay, 170)
            scale: root.popupIntroPopScale(entryDelay, 0.96, 1.025, 1.0)
            transform: Translate { y: root.popupIntroTranslateY(actionButton.entryDelay, 6) }

            Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
            Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 6

                PopupIcon {
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    iconName: "plus"
                    lineColor: root.alpha(root.ink, 0.82)
                }

                Text {
                    Layout.fillWidth: true
                    text: actionButton.text
                    color: root.ink
                    font.family: root.uiFont
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: actionButton.hovered = true
                onExited: actionButton.hovered = false
                onClicked: actionButton.clicked()
            }
        }

    component TimeIconButton: Rectangle {
            id: iconButton

            property string iconName: "plus"
            property bool hovered: false
            property int entryDelay: 100
            signal clicked()

            radius: 7
            color: hovered ? Qt.rgba(0.095, 0.100, 0.120, 0.70) : Qt.rgba(0.060, 0.064, 0.078, 0.58)
            border.width: 1
            border.color: root.alpha(root.inkSoft, hovered ? 0.22 : 0.10)
            opacity: root.popupIntroOpacity(entryDelay, 170)
            scale: root.popupIntroPopScale(entryDelay, 0.88, 1.08, 1.0)

            Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
            Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

            PopupIcon {
                anchors.centerIn: parent
                width: 15
                height: 15
                iconName: iconButton.iconName
                lineColor: root.alpha(root.ink, 0.82)
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: iconButton.hovered = true
                onExited: iconButton.hovered = false
                onClicked: iconButton.clicked()
            }
        }

    component WeatherGlyph: Canvas {
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                const s = Math.min(width, height)

                ctx.reset()
                ctx.clearRect(0, 0, width, height)

                ctx.fillStyle = root.winAccent
                ctx.strokeStyle = root.winAccent
                ctx.lineWidth = Math.max(1.6, s * 0.06)
                ctx.lineCap = "round"
                ctx.lineJoin = "round"

                ctx.beginPath()
                ctx.arc(width * 0.62, height * 0.30, s * 0.22, 0, Math.PI * 2)
                ctx.fill()

                for (let i = 0; i < 8; i += 1) {
                    const a = i / 8 * Math.PI * 2
                    ctx.beginPath()
                    ctx.moveTo(width * 0.62 + Math.cos(a) * s * 0.30, height * 0.30 + Math.sin(a) * s * 0.30)
                    ctx.lineTo(width * 0.62 + Math.cos(a) * s * 0.39, height * 0.30 + Math.sin(a) * s * 0.39)
                    ctx.stroke()
                }

                ctx.fillStyle = root.ink
                ctx.beginPath()
                ctx.arc(width * 0.30, height * 0.66, s * 0.22, Math.PI, Math.PI * 2)
                ctx.arc(width * 0.48, height * 0.58, s * 0.27, Math.PI, Math.PI * 2)
                ctx.arc(width * 0.68, height * 0.68, s * 0.18, Math.PI, Math.PI * 2)
                ctx.lineTo(width * 0.78, height * 0.84)
                ctx.lineTo(width * 0.18, height * 0.84)
                ctx.closePath()
                ctx.fill()
            }
    }

    component FilesView: Item {
        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                WinLabel {
                    Layout.fillWidth: true
                    text: "ファイルセンター"
                    color: root.ink
                    font.pixelSize: 16
                }

                WinSubLabel {
                    text: "−"
                    color: root.winAccent2
                    font.pixelSize: 18
                }

                WinSubLabel {
                    text: "↗"
                    color: root.winAccent2
                    font.pixelSize: 15
                }

                WinSubLabel {
                    text: "×"
                    color: root.winAccent2
                    font.pixelSize: 17
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

            WinCard {
                Layout.preferredWidth: 168
                Layout.fillHeight: true
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8
                    WinSubLabel { text: "最近使用したフォルダー"; color: root.winAccent2; font.weight: Font.Bold }
                    Repeater {
                        model: Math.min(recentFolderModel.count, 4)
                        WinActionRow {
                            Layout.fillWidth: true
                            iconName: recentFolderModel.get(index).icon
                            title: recentFolderModel.get(index).title
                            subtitle: recentFolderModel.get(index).subtitle
                            onClicked: root.openPath(recentFolderModel.get(index).path)
                        }
                    }
                    WinActionRow {
                        visible: recentFolderModel.count <= 0
                        Layout.fillWidth: true
                        iconName: "folder"
                        title: "読み込み中"
                        subtitle: "フォルダーをスキャンしています"
                    }
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.winLine }
                    WinSubLabel { text: "お気に入り"; color: root.winAccent2; font.weight: Font.Bold }
                    Repeater {
                        model: [
                            ["home", "ホーム", root.homeDir],
                            ["display", "デスクトップ", root.homeDir + "/Desktop"],
                            ["memo", "ドキュメント", root.homeDir + "/Documentos"],
                            ["download", "ダウンロード", root.homeDir + "/Downloads"],
                            ["image", "ピクチャ", root.homeDir + "/Pictures"],
                            ["volume", "ミュージック", root.homeDir + "/Music"]
                        ]
                        WinActionRow {
                            Layout.fillWidth: true
                            iconName: modelData[0]
                            title: modelData[1]
                            onClicked: root.openPath(modelData[2])
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                WinSubLabel { text: "ファイルセンター"; color: root.winAccent2; font.pixelSize: 15; font.weight: Font.Bold }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 8
                    WinActionRow { Layout.fillWidth: true; iconName: "folder"; title: "新しいフォルダー"; onClicked: root.runDetached("mkdir -p " + root.shellQuote(root.homeDir + "/New Folder") + "; xdg-open " + root.shellQuote(root.homeDir)) }
                    WinActionRow { Layout.fillWidth: true; iconName: "search"; title: "ファイルを検索"; onClicked: root.openFileSearch() }
                    WinActionRow { Layout.fillWidth: true; iconName: "box"; title: "ごみ箱"; onClicked: root.openTrash() }
                    WinActionRow { Layout.fillWidth: true; iconName: "settings"; title: "設定"; onClicked: root.openSettings("") }
                }
                WinCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 140
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12
                        WinSubLabel { text: "ストレージ"; color: root.winAccent2; font.weight: Font.Bold }
                        WinActionRow {
                            Layout.fillWidth: true
                            iconName: "drive"
                            title: root.diskMountPoint.length > 0 ? root.diskMountPoint : "Home"
                            subtitle: root.diskUsageText + " 使用中 (" + Math.round(root.diskUsagePercent * 100) + "%)"
                            accent: true
                            onClicked: root.openPath(root.diskMountPoint.length > 0 ? root.diskMountPoint : root.homeDir)
                        }
                        SliderBar { Layout.fillWidth: true; value: root.diskUsagePercent; entryDelay: 120 }
                    }
                }
                WinCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8
                        WinSubLabel { text: "最近のファイル"; color: root.winAccent2; font.weight: Font.Bold }
                        Repeater {
                            model: Math.min(recentFileModel.count, 4)
                            WinActionRow {
                                Layout.fillWidth: true
                                iconName: recentFileModel.get(index).icon
                                title: recentFileModel.get(index).title
                                subtitle: recentFileModel.get(index).subtitle
                                onClicked: root.openPath(recentFileModel.get(index).path)
                            }
                        }
                        WinActionRow {
                            visible: recentFileModel.count <= 0
                            Layout.fillWidth: true
                            iconName: "memo"
                            title: "ファイルなし"
                            subtitle: "最近のファイルが見つかりません"
                        }
                    }
                }
            }
        }
        }
    }

    component BrowserView: Item {
        ColumnLayout {
            anchors.fill: parent
            spacing: 18

            RowLayout {
                Layout.fillWidth: true
                spacing: 18
                Rectangle {
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                    radius: 32
                    color: root.alpha(root.winAccent, 0.18)
                    PopupIcon { anchors.centerIn: parent; width: 38; height: 38; iconName: "globe"; lineColor: root.winAccent2 }
                }
                ColumnLayout {
                    Layout.preferredWidth: 260
                    WinLabel { text: "おはようございます"; font.pixelSize: 22 }
                    WinSubLabel { text: "集中できる一日になりますように。"; font.pixelSize: 12 }
                }
                SearchBox { Layout.fillWidth: true; Layout.preferredHeight: 58 }
                Rectangle {
                    Layout.preferredWidth: 54
                    Layout.preferredHeight: 54
                    radius: 27
                    color: root.alpha(root.winAccent, 0.72)
                    Text { anchors.centerIn: parent; text: "→"; color: "white"; font.pixelSize: 27; font.weight: Font.Bold }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.browserSearch()
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 3
                columnSpacing: 18
                rowSpacing: 18

                WinCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ColumnLayout { anchors.fill: parent; anchors.margins: 16; spacing: 12
                        WinSubLabel { text: "お気に入り"; color: root.winAccent2; font.pixelSize: 13; font.weight: Font.Bold }
                        GridLayout { Layout.fillWidth: true; columns: 4; columnSpacing: 10; rowSpacing: 10
                            Repeater { model: [["globe", "ポータル", "https://www.google.com"], ["memo", "ドキュメント", "https://docs.google.com"], ["box", "コミュニティ", "https://github.com"], ["memo", "ニュース", "https://news.google.com"], ["palette", "クリエイティブ", "https://dribbble.com"], ["bell", "学習リソース", "https://developer.mozilla.org"], ["box", "ツール", "https://www.perplexity.ai"], ["plus", "追加", "about:preferences"]]
                                WinIconTile { Layout.preferredWidth: 74; Layout.preferredHeight: 74; iconName: modelData[0]; label: modelData[1]; onClicked: root.openUrl(modelData[2]) }
                            }
                        }
                    }
                }

                WinCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ColumnLayout { anchors.fill: parent; anchors.margins: 18; spacing: 12
                        RowLayout { Layout.fillWidth: true; WinSubLabel { Layout.fillWidth: true; text: "最近のタブ"; color: root.winAccent2; font.pixelSize: 13; font.weight: Font.Bold } WinSubLabel { text: "すべて表示"; color: root.winAccent2 } }
                        Repeater { model: [["デザインシステム・ダッシュボード", "https://www.figma.com"], ["プロジェクト進捗レポート", "https://github.com"], ["API ドキュメント | 開発者ガイド", "https://developer.mozilla.org"], ["インスピレーションギャラリー", "https://dribbble.com"], ["クラウドストレージ", "https://drive.google.com"]]
                            WinActionRow { Layout.fillWidth: true; iconName: "memo"; title: modelData[0]; subtitle: modelData[1]; onClicked: root.openUrl(modelData[1]) }
                        }
                    }
                }

                WinCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ColumnLayout { anchors.fill: parent; anchors.margins: 16; spacing: 12
                        WinSubLabel { text: "検索ショートカット"; color: root.winAccent2; font.pixelSize: 13; font.weight: Font.Bold }
                        GridLayout { Layout.fillWidth: true; columns: 2; columnSpacing: 10; rowSpacing: 10
                            Repeater { model: [["image", "画像を検索", "https://images.google.com"], ["play", "動画を検索", "https://www.youtube.com"], ["memo", "ニュースを検索", "https://news.google.com"], ["globe", "地図を検索", "https://maps.google.com"], ["lock", "ショッピング", "https://shopping.google.com"], ["language", "翻訳", "https://translate.google.com"]]
                                WinIconTile { Layout.fillWidth: true; Layout.preferredHeight: 70; iconName: modelData[0]; label: modelData[1]; onClicked: root.openUrl(modelData[2]) }
                            }
                        }
                    }
                }

                WinCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ColumnLayout { anchors.fill: parent; anchors.margins: 16; spacing: 8
                        WinSubLabel { text: "クイックアクション"; color: root.winAccent2; font.weight: Font.Bold }
                        Repeater { model: [["clock", "新しいタブ", "Ctrl + T", "new-tab"], ["box", "新しいウィンドウ", "Ctrl + N", "new-window"], ["lock", "シークレットウィンドウ", "Ctrl + Shift + N", "private"], ["memo", "ブックマークを管理", "", "bookmarks"], ["download", "ダウンロード", "", "downloads"]]
                            WinActionRow { Layout.fillWidth: true; iconName: modelData[0]; title: modelData[1]; subtitle: modelData[2]; onClicked: root.browserCommand(modelData[3]) }
                        }
                    }
                }

                WinCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ColumnLayout { anchors.fill: parent; anchors.margins: 16; spacing: 10
                        RowLayout { Layout.fillWidth: true; WinSubLabel { Layout.fillWidth: true; text: "リーディングリスト"; color: root.winAccent2; font.weight: Font.Bold } WinSubLabel { text: "すべて表示"; color: root.winAccent2 } }
                        Repeater { model: [["未来のインターフェースデザイン", "https://designjournal.dev"], ["人工知能が変える創造のかたち", "https://insights.tech"], ["ミニマルな暮らしのすすめ", "https://life-studies.jp"]]
                            WinActionRow { Layout.fillWidth: true; iconName: "image"; title: modelData[0]; subtitle: modelData[1]; onClicked: root.openUrl(modelData[1]) }
                        }
                    }
                }

                WinCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ColumnLayout { anchors.centerIn: parent; spacing: 18
                        WinSubLabel { text: "ヒント"; color: root.winAccent2; font.pixelSize: 14; font.weight: Font.Bold }
                        WinLabel { text: "小さな積み重ねが、\n大きな未来をつくります。"; horizontalAlignment: Text.AlignHCenter; lineHeight: 1.6 }
                    }
                }
            }
        }
    }

    component AudioBars: Canvas {
        id: audioBars

        Timer {
            interval: 140
            running: root.open && root.visible && audioBars.visible
            repeat: true
            onTriggered: audioBars.requestPaint()
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            const count = 28
            const gap = 5
            const barW = Math.max(3, (width - gap * (count - 1)) / count)
            for (let i = 0; i < count; i += 1) {
                const seed = (i * 37 + Math.floor(Date.now() / 140) * 11) % 100
                const h = Math.max(8, height * (0.18 + (seed / 100) * 0.72))
                ctx.fillStyle = i % 3 === 0 ? root.winAccent2 : root.winAccent
                roundRect(ctx, i * (barW + gap), height - h, barW, h, barW / 2)
                ctx.fill()
            }
        }
    }

    component WallpaperVisibilityView: Item {
        id: visibilityView

        opacity: root.stageOpacity(35, 220)
        scale: root.stageScale(35, 0.985, 1)
        transformOrigin: Item.TopRight

        transform: Translate {
            y: root.stageTranslateY(35, 10)
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    HeaderText {
                        Layout.fillWidth: true
                        text: "表示する壁紙"
                    }

                    SmallText {
                        Layout.fillWidth: true
                        text: root.visibleWallpaperCount() + "/" + root.wallpaperItems.length + " visible"
                    }
                }

                MiniButton {
                    label: "全部隠す"
                    onClicked: root.hideAllWallpapers()
                }

                MiniButton {
                    label: "全部戻す"
                    onClicked: root.showAllWallpapers()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: root.line
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 11
                color: root.alpha(root.card, 0.24)
                border.width: 1
                border.color: root.alpha(root.borderSoft, 0.34)
                clip: true

                ListView {
                    id: wallpaperVisibilityList

                    anchors.fill: parent
                    anchors.margins: 7
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    spacing: 7
                    model: root.wallpaperItems.length

                    delegate: VisibilityWallpaperRow {
                        required property int index

                        width: wallpaperVisibilityList.width
                        entry: root.wallpaperItems[index]
                        hidden: root.isWallpaperHidden(root.wallpaperItems[index])
                        onClicked: root.toggleWallpaperHidden(entry)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.wallpaperItems.length <= 0
                    text: wallpaperScanProcess.running ? "読み込み中..." : "壁紙が見つかりません"
                    color: root.inkSoft
                    font.family: root.uiFont
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }
        }
    }

    component VisibilityWallpaperRow: Rectangle {
        id: row

        property var entry: null
        property bool hidden: false
        property bool hovered: false
        signal clicked()

        height: 58
        radius: 11
        color: hidden
            ? root.alpha(root.card, hovered ? 0.25 : 0.17)
            : (hovered ? root.alpha(root.card, 0.54) : root.alpha(root.card, 0.34))
        border.width: 1
        border.color: hidden ? root.alpha(root.inkSoft, 0.18) : (hovered ? root.alpha(root.pink, 0.30) : root.alpha(root.borderSoft, 0.34))
        antialiasing: true
        opacity: hidden ? 0.72 : 1

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on opacity { NumberAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

        Image {
            id: preview

            x: 7
            y: 7
            width: 58
            height: 44
            source: root.displaySource(row.entry)
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 160
            sourceSize.height: 110
            asynchronous: true
            smooth: true
            mipmap: true
            opacity: row.hidden ? 0.42 : 1
        }

        Rectangle {
            x: preview.x
            y: preview.y
            width: preview.width
            height: preview.height
            radius: 8
            color: row.hidden ? Qt.rgba(0.08, 0.07, 0.10, 0.30) : "transparent"
            border.width: 1
            border.color: root.alpha(root.borderSoft, 0.28)

            Text {
                anchors.centerIn: parent
                visible: row.hidden
                text: "非表示"
                color: "white"
                font.family: root.uiFont
                font.pixelSize: 9
                font.weight: Font.Bold
            }
        }

        Column {
            x: 76
            y: 10
            width: Math.max(72, parent.width - 132)
            spacing: 4

            Text {
                width: parent.width
                text: row.entry ? root.wallpaperTitle(row.entry) : ""
                color: row.hidden ? root.inkSoft : root.ink
                font.family: root.uiFont
                font.pixelSize: 12
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: row.entry ? (root.kindCategory(row.entry.kind || "static") + " / " + (row.entry.kind || "static")) : ""
                color: root.inkSoft
                font.family: root.uiFont
                font.pixelSize: 10
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }

        Rectangle {
            anchors {
                right: parent.right
                rightMargin: 8
                verticalCenter: parent.verticalCenter
            }

            width: 42
            height: 23
            radius: 12
            color: row.hidden ? root.alpha(root.pink, 0.22) : root.alpha(root.inkSoft, 0.13)
            border.width: 1
            border.color: row.hidden ? root.alpha(root.pink, 0.34) : root.alpha(root.inkSoft, 0.18)

            Text {
                anchors.centerIn: parent
                text: row.hidden ? "表示" : "隠す"
                color: row.hidden ? root.pink : root.inkSoft
                font.family: root.uiFont
                font.pixelSize: 9
                font.weight: Font.Bold
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            cursorShape: Qt.PointingHandCursor
            onEntered: row.hovered = true
            onExited: row.hovered = false
            onClicked: function(mouse) {
                mouse.accepted = true
                row.clicked()
            }
        }
    }

    component VolumeView: Item {
        ColumnLayout {
            anchors.fill: parent
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                PopupIcon {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    iconName: "volume"
                    entryDelay: 40
                }

                TitleText {
                    Layout.fillWidth: true
                    text: "サウンド"
                    entryDelay: 45
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.winLine }

            WinSubLabel { Layout.fillWidth: true; text: "マスター音量"; color: root.ink; font.pixelSize: 12; font.weight: Font.Bold }

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                PopupIcon {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    iconName: root.muted ? "volume-muted" : "volume"
                    lineColor: root.ink
                }

                SliderBar {
                    Layout.fillWidth: true
                    value: root.volumePercent
                    entryDelay: 80
                    onMoved: function(value) {
                        root.setVolume(value)
                    }
                }

                Text {
                    text: Math.round(root.volumePercent * 100) + "%"
                    color: root.inkSoft
                    font.family: root.monoFont
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.winLine }

            WinSubLabel { Layout.fillWidth: true; text: "出力デバイス"; color: root.ink; font.pixelSize: 12; font.weight: Font.Bold }

            SelectRow {
                Layout.fillWidth: true
                text: root.audioOutputName
                onClicked: root.openAudioSettings()
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.winLine }

            WinSubLabel { Layout.fillWidth: true; text: "マイク音量"; color: root.ink; font.pixelSize: 12; font.weight: Font.Bold }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                PopupIcon { Layout.preferredWidth: 20; Layout.preferredHeight: 20; iconName: "memo"; lineColor: root.ink }
                SliderBar {
                    Layout.fillWidth: true
                    value: root.micVolumePercent
                    entryDelay: 140
                    onMoved: function(value) {
                        root.setMicVolume(value)
                    }
                }
                Text { text: Math.round(root.micVolumePercent * 100) + "%"; color: root.inkSoft; font.family: root.monoFont; font.pixelSize: 13 }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                PopupIcon { Layout.preferredWidth: 20; Layout.preferredHeight: 20; iconName: "settings"; lineColor: root.inkSoft }
                WinLabel { Layout.fillWidth: true; text: root.audioInputName.length > 0 ? root.audioInputName : "マイクをミュート"; font.pixelSize: 12 }
                SoftToggle {
                    checked: root.micMuted
                    entryDelay: 180
                    onClicked: root.toggleMicMute()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                PopupIcon { Layout.preferredWidth: 20; Layout.preferredHeight: 20; iconName: root.muted ? "volume-muted" : "volume"; lineColor: root.inkSoft }
                WinLabel { Layout.fillWidth: true; text: "出力をミュート"; font.pixelSize: 12 }
                SoftToggle {
                    checked: root.muted
                    entryDelay: 195
                    onClicked: root.toggleMute()
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.winLine }

            WinSubLabel { Layout.fillWidth: true; text: "オーディオ ビジュアライザー"; color: root.ink; font.pixelSize: 12; font.weight: Font.Bold }

            AudioBars {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    component WifiView: Item {
        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                PopupIcon {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    iconName: "wifi"
                    lineColor: root.ink
                }

                TitleText {
                    Layout.fillWidth: true
                    text: "ネットワーク"
                    entryDelay: 40
                }

                SoftToggle {
                    checked: root.wifiEnabled
                    entryDelay: 85
                    onClicked: root.toggleWifi()
                }
            }

            WinSubLabel {
                Layout.fillWidth: true
                text: root.wifiEnabled ? "接続中" : "Wi-Fi オフ"
                color: root.ink
                font.weight: Font.Bold
            }

            ConnectedWifiCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 86
                ssid: root.activeWifi() ? root.activeWifi().ssid : "ネットワークなし"
                signal: root.activeWifi() ? root.activeWifi().signal : 0
                secure: root.activeWifi() ? root.activeWifi().secure : false
            }

            WinSubLabel {
                Layout.fillWidth: true
                Layout.topMargin: 4
                text: "利用可能なネットワーク"
                color: root.ink
                font.weight: Font.Bold
            }

            WinCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 210

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 0

                    Repeater {
                        model: Math.min(wifiModel.count, 4)

                        WifiRow {
                            Layout.fillWidth: true
                            name: wifiModel.get(index).ssid
                            bars: root.signalBars(wifiModel.get(index).signal)
                            secure: wifiModel.get(index).secure
                            active: wifiModel.get(index).active
                            entryDelay: 140 + index * 38
                            onClicked: root.connectWifi(name)
                        }
                    }
                }
            }

            WinActionRow {
                Layout.fillWidth: true
                iconName: "wifi"
                title: "その他のネットワークを表示"
                onClicked: root.openNetworkSettings()
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10
                WinIconTile { Layout.fillWidth: true; Layout.preferredHeight: 92; iconName: "wifi"; label: "モバイル ホットスポット"; onClicked: root.toggleHotspot() }
                WinIconTile { Layout.fillWidth: true; Layout.preferredHeight: 92; iconName: "play"; label: "機内モード"; active: !root.wifiEnabled; onClicked: root.toggleAirplaneMode() }
            }

            WinActionRow {
                Layout.fillWidth: true
                iconName: "settings"
                title: "ネットワーク設定"
                subtitle: "Wi-Fi、機内モード、プロキシ、データ使用状況などを管理します"
                onClicked: {
                    root.runCommand("if command -v nm-connection-editor >/dev/null 2>&1; then nm-connection-editor >/dev/null 2>&1 & elif command -v systemsettings >/dev/null 2>&1; then systemsettings kcm_networkmanagement >/dev/null 2>&1 & fi")
                }
            }
        }
    }

    component BrightnessView: Item {
        ColumnLayout {
            anchors.fill: parent
            spacing: 18

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                PopupIcon {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    iconName: "sun"
                    entryDelay: 40
                    entryRotate: -18
                    entryStartScale: 0.75
                    entryPeakScale: 1.12
                }

                TitleText {
                    Layout.fillWidth: true
                    text: "ディスプレイ"
                    entryDelay: 50
                }
            }

            RowLayout {
                Layout.fillWidth: true
                WinLabel { Layout.fillWidth: true; text: "明るさ"; font.pixelSize: 13 }
                WinLabel { text: Math.round(root.brightnessPercent * 100) + "%"; font.pixelSize: 13 }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                PopupIcon { Layout.preferredWidth: 22; Layout.preferredHeight: 22; iconName: "sun"; lineColor: root.inkSoft }
                SliderBar {
                    Layout.fillWidth: true
                    value: root.brightnessPercent
                    entryDelay: 80
                    onMoved: function(value) {
                        root.setBrightness(value)
                    }
                }
            }

            DividerLine {
                Layout.fillWidth: true
                Layout.topMargin: 4
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                TitleText {
                    Layout.fillWidth: true
                    text: "色の温かみ"
                    entryDelay: 120
                }
            }

            SliderBar {
                Layout.fillWidth: true
                value: 0.48
                warm: true
                entryDelay: 160
                onMoved: function(value) {
                    root.runCommand("hyprctl hyprsunset temperature " + Math.round(6500 - value * 2500) + " >/dev/null 2>&1 || true")
                }
            }

            RowLayout {
                Layout.fillWidth: true

                SmallText {
                    Layout.fillWidth: true
                    text: "寒色"
                }

                SmallText {
                    text: "暖色"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                WinLabel { Layout.fillWidth: true; text: "ナイトライト"; font.pixelSize: 13 }
                SoftToggle {
                    checked: root.nightLightEnabled
                    entryDelay: 180
                    onClicked: root.toggleNightLight()
                }
            }

            WinSubLabel {
                Layout.fillWidth: true
                text: "目の負担を軽減するために画面を暖色に調整します"
                wrapMode: Text.WordWrap
            }

            DividerLine {
                Layout.fillWidth: true
                Layout.topMargin: 4
            }

            TitleText {
                Layout.fillWidth: true
                text: "ディスプレイモード"
                entryDelay: 215
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ModeButton {
                    Layout.fillWidth: true
                    label: "標準"
                    active: true
                    entryDelay: 240
                    onClicked: {
                        root.brightnessPercent = 0.70
                        root.runCommand("brightnessctl set 70% >/dev/null 2>&1; hyprctl hyprsunset identity >/dev/null 2>&1 || true")
                    }
                }

                ModeButton {
                    Layout.fillWidth: true
                    label: "鮮やか"
                    entryDelay: 280
                    onClicked: {
                        root.brightnessPercent = 0.90
                        root.runCommand("brightnessctl set 90% >/dev/null 2>&1; hyprctl hyprsunset temperature 6200 >/dev/null 2>&1 || true")
                    }
                }

                ModeButton {
                    Layout.fillWidth: true
                    label: "映画"
                    entryDelay: 320
                    onClicked: {
                        root.brightnessPercent = 0.45
                        root.runCommand("brightnessctl set 45% >/dev/null 2>&1; hyprctl hyprsunset temperature 4200 >/dev/null 2>&1 || true")
                    }
                }
            }

            WinSubLabel { Layout.fillWidth: true; text: "プレビュー"; color: root.ink; font.weight: Font.Bold; Layout.topMargin: 4 }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Repeater {
                    model: [
                        root.wallpaperDir + "/static/aerial-view-tokyo-cityscape-with-fuji-mountain-japan.jpg",
                        root.wallpaperDir + "/static/claudio-guglieri-G6X3OZqIIm8-unsplash.jpg",
                        root.wallpaperDir + "/static/clay-banks-hwLAI5lRhdM-unsplash.jpg"
                    ]
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 86
                        radius: 10
                        clip: true
                        border.width: index === 0 ? 2 : 1
                        border.color: index === 0 ? root.winAccent2 : root.winLine
                        Image { anchors.fill: parent; source: modelData; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                    }
                }
            }

            WinActionRow { Layout.fillWidth: true; iconName: "settings"; title: "詳細ディスプレイ設定"; subtitle: root.brightnessDevice; onClicked: root.openDisplaySettings() }
        }
    }

    component BluetoothView: Item {
        id: bluetoothView

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    radius: 13
                    color: root.alpha(root.bluetoothIsPowered ? root.pink : root.winCardHover, root.bluetoothIsPowered ? 0.22 : 0.48)
                    border.width: 1
                    border.color: root.alpha(root.bluetoothIsPowered ? root.pink : root.winAccent, root.bluetoothIsPowered ? 0.36 : 0.18)

                    PopupIcon {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        iconName: "bluetooth"
                        lineColor: root.bluetoothIsPowered ? root.pink : root.inkSoft
                        entryDelay: 38
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    TitleText {
                        Layout.fillWidth: true
                        text: root.bluetoothIsPowered ? "Bluetooth" : root.tr("bluetoothOff")
                        entryDelay: 44
                        elide: Text.ElideRight
                    }

                    SmallText {
                        Layout.fillWidth: true
                        text: root.bluetoothIsAvailable ? (root.bluetoothIsPowered ? root.tr("btReady") : root.tr("btDisabled")) : root.tr("btMissing")
                        elide: Text.ElideRight
                    }
                }

                SoftToggle {
                    visible: root.bluetoothIsAvailable
                    checked: root.bluetoothIsPowered
                    entryDelay: 58
                    onClicked: root.toggleBluetoothPower()
                }
            }

            WinCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 116
                color: root.alpha(root.winCardHover, 0.40)
                border.color: root.alpha(root.winAccent, 0.22)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    BluetoothOrb {
                        Layout.preferredWidth: 82
                        Layout.preferredHeight: 82
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: root.bluetoothIsAvailable ? String(root.bluetoothDeviceCount()) + " " + root.tr("btDevices") : root.tr("btInstall")
                            color: root.ink
                            font.family: root.uiFont
                            font.pixelSize: 17
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        SmallText {
                            Layout.fillWidth: true
                            text: root.bluetoothIsPowered ? "Pronto para conectar" : "Radio pausado"
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            BtChip {
                                label: root.bluetoothIsPowered ? "On" : "Off"
                                active: root.bluetoothIsPowered
                            }

                            BtChip {
                                label: root.nativeBluetoothAvailable ? "Native" : "ctl"
                                active: root.bluetoothIsAvailable
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2

                Text {
                    Layout.fillWidth: true
                    text: "Dispositivos"
                    color: root.ink
                    font.family: root.uiFont
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                SmallText {
                    text: root.bluetoothDeviceCount() > 4 ? "+ " + String(root.bluetoothDeviceCount() - 4) : ""
                }
            }

            Repeater {
                model: Math.min(root.bluetoothDeviceCount(), 4)

                BluetoothDeviceCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    deviceIndex: index
                }
            }

            WinCard {
                visible: root.bluetoothDeviceCount() <= 0
                Layout.fillWidth: true
                Layout.preferredHeight: 112
                color: root.alpha(root.winCard, 0.44)
                border.color: root.alpha(root.winAccent, 0.16)

                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.max(160, parent.width - 46)
                    spacing: 6

                    PopupIcon {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        iconName: "bluetooth"
                        lineColor: root.inkSoft
                        entryDelay: 120
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.bluetoothIsAvailable ? root.tr("btNoDevices") : root.tr("btUnavailable")
                        color: root.inkSoft
                        horizontalAlignment: Text.AlignHCenter
                        font.family: root.uiFont
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }

    component BluetoothOrb: Rectangle {
            radius: 24
            color: root.alpha(root.winAccent, root.bluetoothIsPowered ? 0.14 : 0.06)
            border.width: 1
            border.color: root.alpha(root.winAccent2, root.bluetoothIsPowered ? 0.28 : 0.12)

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.72
                height: width
                radius: width / 2
                color: root.alpha(root.winCardHover, 0.52)
                border.width: 1
                border.color: root.alpha(root.winAccent2, root.bluetoothIsPowered ? 0.28 : 0.12)
            }

            PopupIcon {
                anchors.centerIn: parent
                width: 38
                height: 38
                iconName: "bluetooth"
                lineColor: root.bluetoothIsPowered ? root.winAccent2 : root.inkSoft
                entryDelay: 88
            }
        }

    component BtChip: Rectangle {
            id: chip

            property string label: ""
            property bool active: false

            Layout.preferredWidth: 64
            Layout.preferredHeight: 26
            radius: 13
            color: root.alpha(active ? root.winAccent : root.winCard, active ? 0.24 : 0.62)
            border.width: 1
            border.color: root.alpha(active ? root.winAccent2 : root.borderSoft, active ? 0.38 : 0.18)

            Text {
                anchors.centerIn: parent
                text: chip.label
                color: chip.active ? root.winAccent2 : root.inkSoft
                font.family: root.uiFont
                font.pixelSize: 10
                font.weight: Font.Bold
            }
        }

    component BluetoothDeviceCard: Rectangle {
            id: card

            property int deviceIndex: 0
            readonly property var device: root.bluetoothDeviceAt(deviceIndex)
            readonly property bool activeDevice: device.active
            readonly property bool hovered: deviceMouse.containsMouse

            radius: 14
            color: root.alpha(activeDevice ? root.winAccent : root.winCardHover, activeDevice ? (hovered ? 0.24 : 0.18) : (hovered ? 0.58 : 0.42))
            border.width: 1
            border.color: root.alpha(activeDevice ? root.winAccent2 : root.borderSoft, activeDevice ? 0.42 : (hovered ? 0.32 : 0.18))
            antialiasing: true

            Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
            Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: 12
                    color: root.alpha(card.activeDevice ? root.winAccent : root.winCard, card.activeDevice ? 0.28 : 0.68)
                    border.width: 1
                    border.color: root.alpha(card.activeDevice ? root.winAccent2 : root.borderSoft, card.activeDevice ? 0.36 : 0.18)

                    Text {
                        anchors.centerIn: parent
                        visible: String(card.device.iconLabel || "").length > 0
                        text: card.device.iconLabel
                        color: root.ink
                        font.family: root.uiFont
                        font.pixelSize: 13
                        font.weight: Font.Bold
                    }

                    PopupIcon {
                        anchors.centerIn: parent
                        visible: String(card.device.iconLabel || "").length <= 0
                        width: 20
                        height: 20
                        iconName: card.device.iconName
                        lineColor: card.activeDevice ? root.winAccent2 : root.inkSoft
                        entryDelay: 100 + card.deviceIndex * 26
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: card.device.name
                        color: root.ink
                        font.family: root.uiFont
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    SmallText {
                        Layout.fillWidth: true
                        text: card.device.detail
                        elide: Text.ElideRight
                    }
                }

                Text {
                    text: card.device.loading ? "..." : (card.activeDevice ? root.tr("disconnect") : root.tr("connect"))
                    color: card.activeDevice ? root.winAccent2 : root.pink
                    font.family: root.uiFont
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }
            }

            MouseArea {
                id: deviceMouse

                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onClicked: root.setBluetoothDeviceConnection(card.device.address, card.device.active)
            }
    }

    component SearchBox: Rectangle {
        id: box

        radius: 12
        color: root.alpha(root.card, 0.42)
        border.width: 1
        border.color: input.activeFocus ? root.alpha(root.pink, 0.58) : root.alpha(root.lilac, 0.22)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 13
            anchors.rightMargin: 12
            spacing: 8

            PopupIcon {
                Layout.preferredWidth: 19
                Layout.preferredHeight: 19
                iconName: "search"
                lineColor: root.pink
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text.length <= 0
                    text: "検索..."
                    color: root.inkSoft
                    font.family: root.uiFont
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                TextInput {
                    id: input

                    anchors.fill: parent
                    text: root.searchQuery
                    color: root.ink
                    selectedTextColor: root.theme ? root.theme.activeText : "white"
                    selectionColor: root.pink
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    font.family: root.uiFont
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    onTextEdited: root.searchQuery = text
                    Keys.onReturnPressed: root.browserSearch()
                    Keys.onEnterPressed: root.browserSearch()
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.IBeamCursor
            onClicked: {
                root.forceActiveFocus()
                input.forceActiveFocus()
            }
        }
    }

    component RecentSearchRow: Item {
        property string iconName: "image"
        property string label: ""

        implicitHeight: 26

        PopupIcon {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 18
            iconName: parent.iconName
        }

        Text {
            anchors {
                left: parent.left
                right: closeMark.left
                verticalCenter: parent.verticalCenter
                leftMargin: 32
                rightMargin: 10
            }

            text: parent.label
            color: root.ink
            font.family: root.uiFont
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }

        Text {
            id: closeMark

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "×"
            color: root.inkSoft
            font.pixelSize: 16
            font.family: root.uiFont
        }
    }

    component PopupChip: Rectangle {
        id: chip

        property string text: ""
        property bool active: false
        property int entryDelay: 210
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 30
        radius: 8
        opacity: root.stageOpacity(entryDelay, 170)
        transform: Translate {
            y: root.stageTranslateY(chip.entryDelay, 7)
        }
        color: active ? root.alpha(root.pink, 0.24) : root.alpha(root.card, 0.42)
        border.width: 1
        border.color: active ? root.alpha(root.pink, 0.32) : root.line

        Text {
            anchors.centerIn: parent
            text: parent.text
            color: parent.active ? root.pink : root.ink
            font.family: root.uiFont
            font.pixelSize: 11
            font.weight: Font.Bold
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            preventStealing: true
            cursorShape: Qt.PointingHandCursor
            onClicked: function(mouse) {
                mouse.accepted = true
                chip.clicked()
            }
        }
    }

    component SelectRow: Rectangle {
        id: row

        property string text: ""
        property int entryDelay: 130
        property bool hovered: false
        signal clicked()

        Layout.preferredHeight: 42
        radius: 8
        opacity: root.stageOpacity(entryDelay, 170)
        transform: Translate {
            y: root.stageTranslateY(row.entryDelay, 7)
        }
        color: root.alpha(root.card, hovered ? 0.52 : 0.38)
        border.width: 1
        border.color: hovered ? root.alpha(root.pink, 0.24) : root.line

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 9

            PopupIcon {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                iconName: "headphones"
            }

            Text {
                Layout.fillWidth: true
                text: parent.parent.text
                color: root.ink
                font.family: root.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                text: "⌄"
                color: root.lilac
                font.family: root.uiFont
                font.pixelSize: 16
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            preventStealing: true
            cursorShape: Qt.PointingHandCursor
            onEntered: row.hovered = true
            onExited: row.hovered = false
            onClicked: function(mouse) {
                mouse.accepted = true
                row.clicked()
            }
        }
    }

    component ConnectedWifiCard: Rectangle {
        property string ssid: ""
        property int signal: 0
        property bool secure: false

        radius: 8
        color: root.alpha(root.pink, 0.22)
        border.width: 1
        border.color: root.alpha(root.pink, 0.36)

        RowLayout {
            anchors.fill: parent
            anchors.margins: 11
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 17
                color: root.alpha(root.pink, 0.22)

                PopupIcon {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    iconName: "wifi"
                    lineColor: root.pink
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: parent.parent.parent.ssid
                    color: root.ink
                    font.family: root.monoFont
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                SmallText {
                    Layout.fillWidth: true
                    text: parent.parent.parent.secure ? "接続済み・セキュリティ保護あり" : "接続済み"
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 10
                color: root.pink

                Text {
                    anchors.centerIn: parent
                    text: "✓"
                    color: root.theme ? root.theme.activeText : "white"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.family: root.uiFont
                }
            }
        }
    }

    component WifiRow: Item {
        id: wifiRow

        property string name: ""
        property int bars: 4
        property bool secure: true
        property bool active: false
        property bool hovered: false
        property int entryDelay: 130
        signal clicked()

        implicitHeight: 38
        scale: hovered ? 1.012 : 1
        opacity: root.stageOpacity(entryDelay, 180)
        transform: Translate {
            y: root.stageTranslateY(wifiRow.entryDelay, 7)
        }
        Behavior on scale {
            NumberAnimation {
                duration: root.motionHover
                easing.type: root.motionEaseHover
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: parent.active ? root.alpha(root.pink, 0.16) : (parent.hovered ? root.alpha(root.card, 0.30) : "transparent")
            border.width: 1
            border.color: parent.hovered ? root.alpha(root.pink, 0.22) : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: root.motionHover
                    easing.type: root.motionEaseHover
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            PopupIcon {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                iconName: "wifi"
                lineColor: root.lilac
            }

            Text {
                Layout.fillWidth: true
                text: parent.parent.name
                color: root.ink
                font.family: root.uiFont
                font.pixelSize: 12
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            PopupIcon {
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14
                iconName: "lock"
                visible: parent.parent.secure
                lineColor: root.inkSoft
            }

            SignalBars {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 18
                bars: parent.parent.bars
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            preventStealing: true
            onEntered: wifiRow.hovered = true
            onExited: wifiRow.hovered = false
            onCanceled: wifiRow.hovered = false
            onClicked: function(mouse) {
                mouse.accepted = true
                wifiRow.clicked()
            }
        }
    }

    component NotificationCard: Rectangle {
        id: card

        property var notification: null
        property string notificationId: ""
        property string iconName: "image"
        property string title: ""
        property string appName: ""
        property string timeText: ""
        property string body: ""
        property int entryDelay: 130
        signal dismissRequested()

        Layout.preferredHeight: 96
        radius: 10
        opacity: root.stageOpacity(entryDelay, 180)
        transform: Translate {
            y: root.stageTranslateY(card.entryDelay, 8)
        }
        color: root.card
        border.width: 1
        border.color: root.line

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            PopupIcon {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                iconName: card.iconName
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: card.title
                        color: root.ink
                        font.family: root.uiFont
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    SmallText {
                        text: card.timeText
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: card.body.length > 0 ? card.body : card.appName
                    color: root.inkSoft
                    font.family: root.uiFont
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    lineHeight: 1.1
                    wrapMode: Text.WordWrap
                }
            }

            Rectangle {
                Layout.preferredWidth: 7
                Layout.preferredHeight: 7
                radius: 4
                color: root.pink
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: card.dismissRequested()
        }
    }

    component ToggleRow: RowLayout {
        property string iconName: "bell"
        property string label: ""

        spacing: 11

        PopupIcon {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            iconName: parent.iconName
        }

        Text {
            Layout.fillWidth: true
            text: parent.label
            color: root.ink
            font.family: root.uiFont
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }

        SoftToggle {
            checked: false
        }
    }

    component ModeButton: Rectangle {
        id: modeButton

        property string label: ""
        property bool active: false
        property int entryDelay: 240
        property bool hovered: false
        signal clicked()

        Layout.preferredHeight: 46
        radius: 7
        opacity: root.stageOpacity(entryDelay, 180)
        scale: root.stageScale(entryDelay, 0.96, 1.0)
        transform: Translate {
            y: root.stageTranslateY(modeButton.entryDelay, 8)
        }
        color: active ? root.alpha(root.pink, hovered ? 0.34 : 0.25) : root.alpha(root.card, hovered ? 0.50 : 0.36)
        border.width: 1
        border.color: active ? root.alpha(root.pink, 0.30) : (hovered ? root.alpha(root.pink, 0.20) : root.line)

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 4

            PopupIcon {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 20
                Layout.preferredHeight: 16
                iconName: "display"
                lineColor: parent.parent.active ? root.pink : root.lilac
            }

            Text {
                text: parent.parent.label
                color: parent.parent.active ? root.pink : root.inkSoft
                font.family: root.uiFont
                font.pixelSize: 9
                font.weight: Font.Bold
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            preventStealing: true
            cursorShape: Qt.PointingHandCursor
            onEntered: modeButton.hovered = true
            onExited: modeButton.hovered = false
            onClicked: function(mouse) {
                mouse.accepted = true
                modeButton.clicked()
            }
        }
    }

    component MiniButton: Rectangle {
        id: miniButton

        property string label: ""
        property bool hovered: false
        signal clicked()

        Layout.preferredWidth: Math.max(68, miniLabel.implicitWidth + 22)
        Layout.preferredHeight: 28
        radius: 14
        color: hovered ? root.alpha(root.pink, 0.20) : root.alpha(root.card, 0.32)
        border.width: 1
        border.color: hovered ? root.alpha(root.pink, 0.34) : root.alpha(root.borderSoft, 0.34)
        antialiasing: true

        Behavior on color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }
        Behavior on border.color { ColorAnimation { duration: root.motionHover; easing.type: root.motionEaseHover } }

        Text {
            id: miniLabel

            anchors.centerIn: parent
            text: miniButton.label
            color: miniButton.hovered ? root.pink : root.inkSoft
            font.family: root.uiFont
            font.pixelSize: 10
            font.weight: Font.Bold
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onEntered: miniButton.hovered = true
            onExited: miniButton.hovered = false
            onClicked: function(mouse) {
                mouse.accepted = true
                miniButton.clicked()
            }
        }
    }

    component SliderBar: Item {
        id: slider

        property real value: 0.5
        property bool warm: false
        property int entryDelay: 85
        readonly property real visualValue: root.overshootValue(value, entryDelay)
        signal moved(real value)

        implicitHeight: 26
        opacity: root.stageOpacity(entryDelay, 190)

        function valueFromX(xPos) {
            return Math.max(0, Math.min(1, (xPos - sliderTrack.x) / Math.max(1, sliderTrack.width)))
        }

        Rectangle {
            id: sliderTrack

            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 2
                rightMargin: 2
            }

            height: 5
            radius: 3
            color: warm ? root.alpha(root.theme ? root.theme.accentTertiary : Qt.rgba(0.72, 0.80, 0.96, 1), 0.36) : root.alpha(root.lilac, 0.18)
        }

        Rectangle {
            anchors {
                left: sliderTrack.left
                verticalCenter: sliderTrack.verticalCenter
            }

            width: Math.round(sliderTrack.width * Math.max(0, Math.min(1, parent.visualValue)))
            height: sliderTrack.height
            radius: sliderTrack.radius
            color: warm ? root.alpha(root.theme ? root.theme.accentTertiary : Qt.rgba(0.96, 0.60, 0.50, 1), 0.66) : root.pink
        }

        Rectangle {
            x: Math.round(sliderTrack.x + sliderTrack.width * Math.max(0, Math.min(1, parent.visualValue)) - width / 2)
            anchors.verticalCenter: sliderTrack.verticalCenter
            width: 20
            height: 20
            radius: 10
            scale: root.stagePopScale(slider.entryDelay, 0.92, 1.06, 1.0)
            color: root.alpha(root.card, 0.92)
            border.width: 1
            border.color: root.alpha(root.pink, 0.22)
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: function(mouse) {
                mouse.accepted = true
                slider.moved(slider.valueFromX(mouse.x))
            }
            onPositionChanged: function(mouse) {
                if (pressed) {
                    mouse.accepted = true
                    slider.moved(slider.valueFromX(mouse.x))
                }
            }
        }
    }

    component SoftToggle: Rectangle {
        id: toggle

        property bool checked: false
        property int entryDelay: 120
        signal clicked()

        Layout.preferredWidth: 42
        Layout.preferredHeight: 24
        radius: height / 2
        opacity: root.stageOpacity(entryDelay, 160)
        scale: root.stagePopScale(entryDelay, 0.96, 1.018, 1.0)
        color: checked ? root.pink : root.alpha(root.lilac, 0.20)

        Rectangle {
            x: parent.checked ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 18
            radius: 9
            color: root.alpha(root.card, 0.92)

            Behavior on x {
                NumberAnimation {
                    duration: root.motionHover
                    easing.type: root.motionEaseHover
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            cursorShape: Qt.PointingHandCursor
            onClicked: function(mouse) {
                mouse.accepted = true
                toggle.clicked()
            }
        }
    }

    component DividerLine: Rectangle {
        Layout.preferredHeight: 1
        radius: 1
        color: root.line
    }

    component TitleText: Text {
        id: title

        property int entryDelay: 40

        opacity: root.stageOpacity(entryDelay, 160)
        transform: Translate {
            y: root.stageTranslateY(title.entryDelay, 4)
        }
        color: root.ink
        font.family: root.uiFont
        font.pixelSize: 13
        font.weight: Font.Bold
        layer.enabled: root.neon
        layer.effect: DropShadow {
            transparentBorder: true
            radius: 8
            samples: 17
            horizontalOffset: 0
            verticalOffset: 0
            color: root.theme ? root.theme.textGlow : Qt.rgba(0, 0, 0, 0)
        }
    }

    component HeaderText: Text {
        id: header

        property int entryDelay: 100

        opacity: root.stageOpacity(entryDelay, 170)
        transform: Translate {
            y: root.stageTranslateY(header.entryDelay, 5)
        }
        color: root.inkSoft
        font.family: root.uiFont
        font.pixelSize: 11
        font.weight: Font.Bold
    }

    component SmallText: Text {
        color: root.inkSoft
        font.family: root.uiFont
        font.pixelSize: 10
        font.weight: Font.Medium
    }

    component SignalBars: Canvas {
        property int bars: 4

        onBarsChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            const gap = width * 0.13
            const barW = (width - gap * 3) / 4

            for (let i = 0; i < 4; i += 1) {
                const h = height * (0.28 + i * 0.18)
                ctx.fillStyle = i < bars ? root.pink : root.alpha(root.inkSoft, 0.22)
                roundRect(ctx, i * (barW + gap), height - h, barW, h, barW / 2)
                ctx.fill()
            }
        }
    }

    component PopupIcon: Canvas {
        id: icon

        property string iconName: "search"
        property color lineColor: root.lilac
        property int entryDelay: 40
        property real entryRotate: 0
        property real entryStartScale: 0.88
        property real entryPeakScale: 1.025

        opacity: root.stageOpacity(entryDelay, 180)
        rotation: root.stageRotation(entryDelay, entryRotate)
        scale: root.stagePopScale(entryDelay, entryStartScale, entryPeakScale, 1.0)
        layer.enabled: root.neon && root.entryProgress < 0.98
        layer.effect: DropShadow {
            transparentBorder: true
            radius: 10
            samples: 21
            horizontalOffset: 0
            verticalOffset: 0
            color: root.theme ? root.theme.iconGlow : Qt.rgba(0, 0, 0, 0)
        }

        onIconNameChanged: requestPaint()
        onLineColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            const s = Math.min(width, height)
            const cx = width / 2
            const cy = height / 2

            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = lineColor
            ctx.fillStyle = lineColor
            ctx.lineWidth = Math.max(1.4, s * 0.085)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            if (iconName === "search") {
                ctx.beginPath()
                ctx.arc(cx - s * 0.08, cy - s * 0.08, s * 0.25, 0, Math.PI * 2)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(cx + s * 0.13, cy + s * 0.13)
                ctx.lineTo(cx + s * 0.32, cy + s * 0.32)
                ctx.stroke()
            } else if (iconName === "volume" || iconName === "volume-muted" || iconName === "headphones") {
                ctx.beginPath()
                ctx.moveTo(s * 0.16, s * 0.43)
                ctx.lineTo(s * 0.32, s * 0.43)
                ctx.lineTo(s * 0.52, s * 0.27)
                ctx.lineTo(s * 0.52, s * 0.73)
                ctx.lineTo(s * 0.32, s * 0.57)
                ctx.lineTo(s * 0.16, s * 0.57)
                ctx.closePath()
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(s * 0.56, s * 0.50, s * 0.20, Math.PI * 1.68, Math.PI * 0.32)
                ctx.stroke()
                if (iconName === "volume-muted") {
                    ctx.beginPath()
                    ctx.moveTo(s * 0.72, s * 0.36)
                    ctx.lineTo(s * 0.88, s * 0.64)
                    ctx.moveTo(s * 0.88, s * 0.36)
                    ctx.lineTo(s * 0.72, s * 0.64)
                    ctx.stroke()
                }
            } else if (iconName === "wifi") {
                for (let i = 0; i < 3; i += 1) {
                    ctx.globalAlpha = 0.54 + i * 0.15
                    ctx.beginPath()
                    ctx.arc(cx, cy + s * 0.18, s * (0.16 + i * 0.14), Math.PI * 1.18, Math.PI * 1.82)
                    ctx.stroke()
                }
                ctx.globalAlpha = 1
                ctx.beginPath()
                ctx.arc(cx, cy + s * 0.22, s * 0.035, 0, Math.PI * 2)
                ctx.fill()
            } else if (iconName === "sun") {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.16, 0, Math.PI * 2)
                ctx.stroke()
                for (let j = 0; j < 8; j += 1) {
                    const a = (j / 8) * Math.PI * 2
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
            } else if (iconName === "display") {
                roundRect(ctx, s * 0.18, s * 0.24, s * 0.64, s * 0.42, s * 0.05)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(cx, s * 0.67)
                ctx.lineTo(cx, s * 0.78)
                ctx.moveTo(s * 0.38, s * 0.80)
                ctx.lineTo(s * 0.62, s * 0.80)
                ctx.stroke()
            } else if (iconName === "settings") {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.25, 0, Math.PI * 2)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.08, 0, Math.PI * 2)
                ctx.stroke()
            } else if (iconName === "lock") {
                roundRect(ctx, s * 0.30, s * 0.44, s * 0.40, s * 0.34, s * 0.05)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(cx, s * 0.45, s * 0.16, Math.PI, 0)
                ctx.stroke()
            } else if (iconName === "moon") {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.28, Math.PI * 0.35, Math.PI * 1.70)
                ctx.quadraticCurveTo(s * 0.62, s * 0.56, s * 0.69, s * 0.28)
                ctx.stroke()
            } else if (iconName === "download") {
                ctx.beginPath()
                ctx.moveTo(cx, s * 0.22)
                ctx.lineTo(cx, s * 0.58)
                ctx.moveTo(s * 0.36, s * 0.46)
                ctx.lineTo(cx, s * 0.60)
                ctx.lineTo(s * 0.64, s * 0.46)
                ctx.moveTo(s * 0.25, s * 0.74)
                ctx.lineTo(s * 0.75, s * 0.74)
                ctx.stroke()
            } else if (iconName === "image") {
                roundRect(ctx, s * 0.20, s * 0.24, s * 0.60, s * 0.52, s * 0.05)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(s * 0.62, s * 0.38, s * 0.045, 0, Math.PI * 2)
                ctx.fill()
                ctx.beginPath()
                ctx.moveTo(s * 0.25, s * 0.68)
                ctx.lineTo(s * 0.43, s * 0.50)
                ctx.lineTo(s * 0.56, s * 0.63)
                ctx.lineTo(s * 0.67, s * 0.52)
                ctx.lineTo(s * 0.78, s * 0.68)
                ctx.stroke()
            } else if (iconName === "calendar") {
                roundRect(ctx, s * 0.22, s * 0.22, s * 0.56, s * 0.56, s * 0.05)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(s * 0.22, s * 0.38)
                ctx.lineTo(s * 0.78, s * 0.38)
                ctx.stroke()
            } else if (iconName === "map") {
                ctx.beginPath()
                ctx.moveTo(s * 0.20, s * 0.26)
                ctx.lineTo(s * 0.38, s * 0.18)
                ctx.lineTo(s * 0.62, s * 0.26)
                ctx.lineTo(s * 0.80, s * 0.18)
                ctx.lineTo(s * 0.80, s * 0.72)
                ctx.lineTo(s * 0.62, s * 0.80)
                ctx.lineTo(s * 0.38, s * 0.72)
                ctx.lineTo(s * 0.20, s * 0.80)
                ctx.closePath()
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(s * 0.38, s * 0.18)
                ctx.lineTo(s * 0.38, s * 0.72)
                ctx.moveTo(s * 0.62, s * 0.26)
                ctx.lineTo(s * 0.62, s * 0.80)
                ctx.stroke()
            } else if (iconName === "drop" || iconName === "rain") {
                ctx.beginPath()
                ctx.moveTo(cx, s * 0.18)
                ctx.bezierCurveTo(s * 0.70, s * 0.42, s * 0.66, s * 0.74, cx, s * 0.80)
                ctx.bezierCurveTo(s * 0.34, s * 0.74, s * 0.30, s * 0.42, cx, s * 0.18)
                ctx.stroke()
                if (iconName === "rain") {
                    ctx.beginPath()
                    ctx.moveTo(s * 0.30, s * 0.84)
                    ctx.lineTo(s * 0.24, s * 0.94)
                    ctx.moveTo(s * 0.52, s * 0.86)
                    ctx.lineTo(s * 0.46, s * 0.96)
                    ctx.moveTo(s * 0.72, s * 0.84)
                    ctx.lineTo(s * 0.66, s * 0.94)
                    ctx.stroke()
                }
            } else if (iconName === "wind") {
                for (let i = 0; i < 3; i += 1) {
                    const y = s * (0.32 + i * 0.17)
                    ctx.beginPath()
                    ctx.moveTo(s * 0.18, y)
                    ctx.bezierCurveTo(s * 0.38, y - s * 0.10, s * 0.62, y - s * 0.02, s * 0.80, y)
                    ctx.stroke()
                }
            } else if (iconName === "leaf") {
                ctx.beginPath()
                ctx.moveTo(s * 0.24, s * 0.70)
                ctx.bezierCurveTo(s * 0.28, s * 0.20, s * 0.78, s * 0.22, s * 0.72, s * 0.66)
                ctx.bezierCurveTo(s * 0.54, s * 0.84, s * 0.36, s * 0.78, s * 0.24, s * 0.70)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(s * 0.30, s * 0.66)
                ctx.lineTo(s * 0.66, s * 0.34)
                ctx.stroke()
            } else if (iconName === "spark") {
                ctx.beginPath()
                ctx.moveTo(cx, s * 0.18)
                ctx.lineTo(cx, s * 0.82)
                ctx.moveTo(s * 0.18, cy)
                ctx.lineTo(s * 0.82, cy)
                ctx.moveTo(s * 0.30, s * 0.30)
                ctx.lineTo(s * 0.70, s * 0.70)
                ctx.moveTo(s * 0.70, s * 0.30)
                ctx.lineTo(s * 0.30, s * 0.70)
                ctx.stroke()
            } else if (iconName === "utensils") {
                ctx.beginPath()
                ctx.moveTo(s * 0.32, s * 0.18)
                ctx.lineTo(s * 0.32, s * 0.82)
                ctx.moveTo(s * 0.22, s * 0.18)
                ctx.lineTo(s * 0.22, s * 0.42)
                ctx.quadraticCurveTo(s * 0.22, s * 0.52, s * 0.32, s * 0.52)
                ctx.moveTo(s * 0.42, s * 0.18)
                ctx.lineTo(s * 0.42, s * 0.42)
                ctx.quadraticCurveTo(s * 0.42, s * 0.52, s * 0.32, s * 0.52)
                ctx.moveTo(s * 0.66, s * 0.18)
                ctx.quadraticCurveTo(s * 0.52, s * 0.34, s * 0.60, s * 0.52)
                ctx.lineTo(s * 0.60, s * 0.82)
                ctx.stroke()
            } else if (iconName === "pencil") {
                ctx.beginPath()
                ctx.moveTo(s * 0.26, s * 0.74)
                ctx.lineTo(s * 0.34, s * 0.56)
                ctx.lineTo(s * 0.62, s * 0.28)
                ctx.quadraticCurveTo(s * 0.69, s * 0.21, s * 0.76, s * 0.28)
                ctx.quadraticCurveTo(s * 0.83, s * 0.35, s * 0.76, s * 0.42)
                ctx.lineTo(s * 0.48, s * 0.70)
                ctx.lineTo(s * 0.26, s * 0.74)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(s * 0.58, s * 0.32)
                ctx.lineTo(s * 0.72, s * 0.46)
                ctx.stroke()
            } else if (iconName === "memo") {
                roundRect(ctx, s * 0.24, s * 0.20, s * 0.52, s * 0.60, s * 0.05)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(s * 0.35, s * 0.42)
                ctx.lineTo(s * 0.64, s * 0.42)
                ctx.moveTo(s * 0.35, s * 0.55)
                ctx.lineTo(s * 0.58, s * 0.55)
                ctx.stroke()
            } else if (iconName === "mail") {
                roundRect(ctx, s * 0.20, s * 0.30, s * 0.60, s * 0.44, s * 0.05)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(s * 0.23, s * 0.35)
                ctx.lineTo(cx, s * 0.54)
                ctx.lineTo(s * 0.77, s * 0.35)
                ctx.stroke()
            } else if (iconName === "bluetooth") {
                ctx.beginPath()
                ctx.moveTo(cx, s * 0.18)
                ctx.lineTo(s * 0.68, s * 0.34)
                ctx.lineTo(cx, s * 0.50)
                ctx.lineTo(s * 0.68, s * 0.66)
                ctx.lineTo(cx, s * 0.82)
                ctx.lineTo(cx, s * 0.18)
                ctx.moveTo(cx, s * 0.50)
                ctx.lineTo(s * 0.32, s * 0.34)
                ctx.moveTo(cx, s * 0.50)
                ctx.lineTo(s * 0.32, s * 0.66)
                ctx.stroke()
            } else if (iconName === "battery") {
                roundRect(ctx, s * 0.24, s * 0.25, s * 0.46, s * 0.50, s * 0.06)
                ctx.stroke()
                roundRect(ctx, s * 0.38, s * 0.18, s * 0.18, s * 0.07, s * 0.03)
                ctx.stroke()
                roundRect(ctx, s * 0.31, s * 0.52, s * 0.32, s * 0.16, s * 0.03)
                ctx.fill()
            } else if (iconName === "clock") {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.31, 0, Math.PI * 2)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(cx, cy)
                ctx.lineTo(cx, s * 0.32)
                ctx.moveTo(cx, cy)
                ctx.lineTo(s * 0.64, s * 0.58)
                ctx.stroke()
            } else if (iconName === "folder" || iconName === "home") {
                ctx.beginPath()
                ctx.moveTo(s * 0.18, s * 0.34)
                ctx.lineTo(s * 0.38, s * 0.34)
                ctx.lineTo(s * 0.46, s * 0.42)
                ctx.lineTo(s * 0.82, s * 0.42)
                ctx.lineTo(s * 0.82, s * 0.74)
                ctx.lineTo(s * 0.18, s * 0.74)
                ctx.closePath()
                ctx.stroke()
                if (iconName === "home") {
                    ctx.beginPath()
                    ctx.moveTo(s * 0.34, s * 0.56)
                    ctx.lineTo(cx, s * 0.44)
                    ctx.lineTo(s * 0.66, s * 0.56)
                    ctx.stroke()
                }
            } else if (iconName === "drive") {
                roundRect(ctx, s * 0.22, s * 0.36, s * 0.56, s * 0.30, s * 0.06)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(s * 0.66, s * 0.51, s * 0.035, 0, Math.PI * 2)
                ctx.fill()
            } else if (iconName === "globe" || iconName === "language") {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.32, 0, Math.PI * 2)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(s * 0.18, cy)
                ctx.lineTo(s * 0.82, cy)
                ctx.moveTo(cx, s * 0.18)
                ctx.bezierCurveTo(s * 0.38, s * 0.34, s * 0.38, s * 0.66, cx, s * 0.82)
                ctx.moveTo(cx, s * 0.18)
                ctx.bezierCurveTo(s * 0.62, s * 0.34, s * 0.62, s * 0.66, cx, s * 0.82)
                ctx.stroke()
            } else if (iconName === "user") {
                ctx.beginPath()
                ctx.arc(cx, s * 0.36, s * 0.13, 0, Math.PI * 2)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(cx, s * 0.78, s * 0.28, Math.PI * 1.12, Math.PI * 1.88)
                ctx.stroke()
            } else if (iconName === "logout") {
                roundRect(ctx, s * 0.22, s * 0.26, s * 0.38, s * 0.48, s * 0.05)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(s * 0.48, cy)
                ctx.lineTo(s * 0.80, cy)
                ctx.moveTo(s * 0.68, s * 0.38)
                ctx.lineTo(s * 0.80, cy)
                ctx.lineTo(s * 0.68, s * 0.62)
                ctx.stroke()
            } else if (iconName === "palette") {
                ctx.beginPath()
                ctx.arc(cx, cy, s * 0.32, Math.PI * 0.15, Math.PI * 1.85)
                ctx.quadraticCurveTo(s * 0.72, s * 0.84, s * 0.61, s * 0.60)
                ctx.stroke()
                for (let p = 0; p < 4; p += 1) {
                    const a = Math.PI * (0.78 + p * 0.26)
                    ctx.beginPath()
                    ctx.arc(cx + Math.cos(a) * s * 0.18, cy + Math.sin(a) * s * 0.18, s * 0.025, 0, Math.PI * 2)
                    ctx.fill()
                }
            } else if (iconName === "plus") {
                ctx.beginPath()
                ctx.moveTo(cx, s * 0.24)
                ctx.lineTo(cx, s * 0.76)
                ctx.moveTo(s * 0.24, cy)
                ctx.lineTo(s * 0.76, cy)
                ctx.stroke()
            } else if (iconName === "play") {
                ctx.beginPath()
                ctx.moveTo(s * 0.34, s * 0.26)
                ctx.lineTo(s * 0.74, cy)
                ctx.lineTo(s * 0.34, s * 0.74)
                ctx.closePath()
                ctx.stroke()
            } else if (iconName === "keyboard") {
                roundRect(ctx, s * 0.18, s * 0.30, s * 0.64, s * 0.42, s * 0.05)
                ctx.stroke()
                for (let ky = 0; ky < 2; ky += 1) {
                    for (let kx = 0; kx < 4; kx += 1) {
                        ctx.beginPath()
                        ctx.arc(s * (0.30 + kx * 0.13), s * (0.43 + ky * 0.14), s * 0.015, 0, Math.PI * 2)
                        ctx.fill()
                    }
                }
            } else if (iconName === "box") {
                roundRect(ctx, s * 0.24, s * 0.28, s * 0.52, s * 0.44, s * 0.05)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(s * 0.34, s * 0.40)
                ctx.lineTo(s * 0.50, s * 0.52)
                ctx.lineTo(s * 0.66, s * 0.40)
                ctx.stroke()
            }
        }
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
