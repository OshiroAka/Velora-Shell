import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root

    property var theme: null
    property string popupType: "time"
    property bool open: visible
    property bool interactiveFocus: false
    property var notificationsModelOverride: null
    property var cavaValues: []
    property string systemPage: "settings"
    property int systemSlideDirection: 1
    property int availableWidth: 0
    property int availableHeight: 0
    property var lyricsContextLines: []
    property bool lyricsAvailable: false
    property string lyricsReason: ""
    property var lyricsWords: []
    property int lyricsActiveIndex: -1
    property string lyricsTimingMode: ""
    property bool lineReveal: true
    property bool warmSwitch: false
    property real revealProgressOverride: -1
    property string attachSide: "left"
    property bool batteryProfileExpanded: false
    property string bluetoothExpandedAddress: ""
    property string expandedNotificationGroup: ""
    property var notificationGroups: []
    property var wallpaperEntries: []
    property string wallpaperActiveKey: ""
    property bool wallpaperApplying: false
    property string wallpaperErrorMessage: ""
    property int wallpaperSessionSerial: 0
    property string systemDisplayedPage: ""
    property string systemIncomingPage: ""
    property string systemOutgoingPage: ""
    property int systemTransitionDirection: 1
    property real systemTransitionProgress: 1
    property real systemVisualWidth: 0
    property real systemVisualHeight: 0
    property bool rightActionsExpanded: false
    property bool systemOpeningIntro: false
    property bool systemTransitionInitialized: false
    property real systemOutgoingStartOpacity: 1
    property real systemOutgoingStartOffset: 0
    property real systemOutgoingStartScale: 1
    readonly property int cornerRadius: popupType === "system" ? 26 : 18
    readonly property bool holdOpen: (popupType === "apps" || popupType === "search") && open
    readonly property bool pointerInside: popupHover.hovered
    readonly property string effectiveType: popupType === "system" ? systemPage : popupType
    readonly property bool systemMaterial: popupType === "system"
    readonly property var systemPages: ["settings", "wallpaper", "volume", "wifi", "display", "notifications", "bluetooth", "battery"]
    readonly property var systemDetailPages: ["wallpaper", "volume", "wifi", "display", "notifications", "bluetooth", "battery"]
    readonly property bool rightControlCenterMode: popupType === "system"
        && theme
        && theme.controlCenterPosition === "right"
    readonly property bool rightControlCenter: rightControlCenterMode && systemPage === "settings"
    readonly property int rightControlCenterCollapsedHeight: Math.round(
        Math.min(550, Math.max(536, availableHeight > 0 ? availableHeight * 0.45 : 540))
    )
    readonly property int rightControlCenterExpandedHeight: Math.round(
        Math.min(1030, Math.max(750, availableHeight > 0 ? availableHeight * 0.705 : 846))
    )
    readonly property int bottomControlCenterCollapsedHeight: Math.round(
        Math.min(500, Math.max(440, availableHeight > 0 ? availableHeight * 0.39 : 468))
    )
    readonly property int bottomControlCenterExpandedHeight: Math.round(
        Math.min(720, Math.max(620, availableHeight > 0 ? availableHeight * 0.56 : 672))
    )
    readonly property int systemTransitionDuration: 340
    readonly property bool systemTransitionRunning: systemPageTransitionAnimation.running || systemGeometryAnimation.running
    readonly property bool systemMotionEnabled: !theme || theme.motionEnabled
    readonly property real systemIncomingContentProgress: systemIncomingProgress()
    readonly property int systemPreferredWidth: systemWidthForPage(systemPage)
    readonly property int systemPreferredHeight: systemHeightForPage(systemPage)
    readonly property real effectiveSystemVisualWidth: systemVisualWidth > 0 ? systemVisualWidth : width
    readonly property real effectiveSystemVisualHeight: systemVisualHeight > 0 ? systemVisualHeight : height
    function systemWidthForPage(page) {
        const value = String(page || "settings")
        if (value === "settings") return rightControlCenterMode
            ? Math.min(500, Math.max(360, availableWidth > 0 ? availableWidth * 0.194 : 372))
            : 720
        if (value === "wallpaper") return 660
        if (value === "volume") return 520
        if (value === "wifi") return 560
        if (value === "display" || value === "brightness") return 560
        if (value === "notifications" || value === "bluetooth" || value === "battery") return 560
        return 600
    }
    function systemHeightForPage(page) {
        const value = String(page || "settings")
        if (value === "settings") return rightControlCenterMode
            ? (rightActionsExpanded
                ? rightControlCenterExpandedHeight
                : rightControlCenterCollapsedHeight)
            : (rightActionsExpanded
                ? bottomControlCenterExpandedHeight
                : bottomControlCenterCollapsedHeight)
        if (value === "wallpaper") return 540
        if (value === "volume") return 500
        if (value === "wifi") {
            const passwordOpen = wifiSelectedSecure
                && !wifiSelectedEnterprise
                && !wifiHiddenForm
                && wifiSelectedSsid.length > 0
                && wifiSelectedUuid.length <= 0
            return wifiHiddenForm || passwordOpen || wifiSelectedEnterprise ? 560 : 500
        }
        if (value === "display" || value === "brightness") return 440
        if (value === "notifications") {
            if (notificationGroups.length <= 0)
                return 320
            return expandedNotificationGroup.length > 0
                ? 520
                : Math.max(320, Math.min(500, 104 + Math.min(5, notificationGroups.length) * 82))
        }
        if (value === "bluetooth") {
            const count = Math.min(5, root.bluetoothLayoutCount)
            if (bluetoothExpandedAddress.length > 0)
                return 440
            if (count <= 0)
                return 300
            if (count === 1)
                return 190
            return Math.min(500, 104 + count * 68)
        }
        if (value === "battery") return batteryProfileExpanded ? 420 : 340
        return 520
    }
    readonly property int preferredWidth: {
        if (popupType === "time") return 390
        if (popupType === "apps" || popupType === "search") return 470
        if (popupType === "workspaces") return 470
        if (popupType === "media") return lyricsAvailable ? 760 : 700
        if (popupType === "profile") return 390
        if (popupType === "system") return systemPreferredWidth
        return 410
    }
    readonly property int preferredHeight: {
        if (popupType === "time") return 520
        if (popupType === "apps" || popupType === "search") return 420
        if (popupType === "workspaces") return 360
        if (popupType === "media") return lyricsAvailable ? 350 : 330
        if (popupType === "profile") return 340
        if (popupType === "system") return systemPreferredHeight
        if (effectiveType === "volume") return 565
        if (effectiveType === "wifi") return 625
        if (effectiveType === "brightness" || effectiveType === "display") return 305
        if (effectiveType === "notifications") return Math.min(500, 165 + Math.min(4, notificationsModelOverride ? notificationsModelOverride.count : 0) * 72)
        if (effectiveType === "bluetooth") return Math.min(435, 155 + Math.max(1, Math.min(5, bluetoothDevices.count)) * 56)
        if (effectiveType === "battery") return 275
        return 440
    }
    readonly property string uiFont: theme ? theme.uiFont : "Noto Sans CJK JP"
    readonly property string monoFont: theme ? theme.monoFont : "JetBrainsMono Nerd Font"
    readonly property color ink: theme ? theme.textPrimary : Qt.rgba(0.94, 0.96, 1.0, 0.96)
    readonly property color inkSoft: theme ? theme.textSecondary : Qt.rgba(0.72, 0.76, 0.84, 0.76)
    readonly property color accent: theme ? theme.accentPrimary : Qt.rgba(0.20, 0.82, 0.76, 1.0)
    readonly property color accent2: theme ? theme.accentSecondary : Qt.rgba(0.58, 0.46, 0.88, 1.0)
    readonly property color accent3: theme ? theme.accentTertiary : Qt.rgba(0.42, 0.72, 0.86, 1.0)
    readonly property color card: theme
        ? theme.alpha(theme.surfaceCard, systemMaterial ? (theme.themeMode === "dark" ? 0.30 : 0.40) : (theme.themeMode === "dark" ? 0.42 : 0.62))
        : Qt.rgba(0.08, 0.10, 0.15, systemMaterial ? 0.34 : 0.72)
    readonly property color cardHover: theme
        ? theme.alpha(theme.surfaceCard, systemMaterial ? (theme.themeMode === "dark" ? 0.42 : 0.50) : (theme.themeMode === "dark" ? 0.62 : 0.78))
        : Qt.rgba(0.12, 0.15, 0.21, systemMaterial ? 0.46 : 0.88)
    readonly property color line: theme ? theme.alpha(theme.borderSoft, systemMaterial ? 0.16 : 0.22) : Qt.rgba(1, 1, 1, systemMaterial ? 0.10 : 0.14)
    readonly property color surfaceContainer: theme
        ? theme.alpha(theme.surfaceCard, systemMaterial ? (theme.themeMode === "dark" ? 0.40 : 0.46) : (theme.themeMode === "dark" ? 0.58 : 0.72))
        : card
    readonly property color surfaceContainerHigh: theme
        ? theme.alpha(theme.surfaceButton, systemMaterial ? (theme.themeMode === "dark" ? 0.50 : 0.56) : (theme.themeMode === "dark" ? 0.72 : 0.86))
        : cardHover
    readonly property color primaryContainer: theme
        ? theme.alpha(theme.accentPrimary, systemMaterial ? (theme.themeMode === "dark" ? 0.26 : 0.22) : (theme.themeMode === "dark" ? 0.30 : 0.24))
        : alpha(accent, 0.26)
    readonly property color onPrimaryContainer: theme ? theme.activeText : ink
    readonly property color outlineVariant: theme
        ? theme.alpha(theme.borderSoft, systemMaterial ? (theme.themeMode === "dark" ? 0.18 : 0.26) : (theme.themeMode === "dark" ? 0.28 : 0.38))
        : line
    property string appQuery: ""
    property var appResults: []
    property int appFocusRequest: 0
    property string searchQuery: ""
    property var searchResults: []
    property date now: new Date()
    property int calendarMonthOffset: 0
    property var calendarCells: []
    property real volumePercent: 0.70
    property bool muted: false
    property string audioOutputName: "Saída padrão"
    property real micVolumePercent: 0.50
    property bool micMuted: false
    property string audioInputName: "Microfone padrão"
    property string audioDeviceError: ""
    property real brightnessPercent: 0.70
    property string brightnessDevice: "Tela"
    property bool wifiEnabled: true
    property string wifiState: "unknown"
    property string wifiSsid: ""
    property string wifiIp: ""
    property var wifiSavedProfiles: ({})
    property var wifiQueryNetworks: []
    property string wifiSelectedSsid: ""
    property string wifiSelectedUuid: ""
    property bool wifiSelectedSecure: false
    property bool wifiSelectedEnterprise: false
    property string wifiPassword: ""
    property bool wifiPasswordVisible: false
    property bool wifiHiddenForm: false
    property string wifiHiddenSsid: ""
    property string wifiPendingSecret: ""
    property string wifiPendingAction: ""
    property string wifiError: ""
    property string wifiForgetConfirmUuid: ""
    property bool bluetoothPowered: false
    property bool bluetoothAvailable: true
    property int bluetoothLayoutCount: 0
    property string bluetoothPendingAction: ""
    property string bluetoothPendingAddress: ""
    property string bluetoothError: ""
    property bool bluetoothScanning: false
    property string bluetoothForgetConfirmAddress: ""
    property string bluetoothPairPrompt: ""
    property string bluetoothPairResponse: ""
    property real batteryPercent: 0.50
    property string batteryState: "unknown"
    property string batteryTime: ""
    property int batteryCycles: -1
    property real batteryHealth: -1
    property bool batteryAcOnline: false
    property string powerProfile: "balanced"
    property bool doNotDisturb: false
    property bool airplaneMode: false
    property bool nightLight: false
    property var worldClockItems: [
        { label: "New York", zone: "America/New_York", time: "--:--", offset: "" },
        { label: "Tokyo", zone: "Asia/Tokyo", time: "--:--", offset: "" }
    ]
    readonly property string popupStatusScript: Quickshell.shellDir + "/scripts/velora-popup-status"
    readonly property string networkControlScript: Quickshell.shellDir + "/scripts/velora-network-control"
    readonly property string bluetoothControlScript: Quickshell.shellDir + "/scripts/velora-bluetooth-control"
    readonly property string audioDevicesScript: Quickshell.shellDir + "/scripts/velora-audio-devices"
    readonly property string worldClockScript: Quickshell.shellDir + "/scripts/velora-world-clock-state"
    property var mediaPlayer: null
    property real mediaPosition: 0
    readonly property bool mediaAvailable: mediaPlayer !== null
    readonly property bool mediaPlaying: Boolean(mediaPlayer && mediaPlayer.isPlaying)
    readonly property bool mediaShuffle: Boolean(mediaPlayer && mediaPlayer.shuffle)
    readonly property bool mediaShuffleSupported: Boolean(mediaPlayer && mediaPlayer.shuffleSupported)
    readonly property int mediaLoopState: mediaPlayer
        ? mediaPlayer.loopState
        : MprisLoopState.None
    readonly property bool mediaLoopSupported: Boolean(mediaPlayer && mediaPlayer.loopSupported)
    readonly property bool mediaLoopActive: mediaLoopState !== MprisLoopState.None
    readonly property real mediaLength: mediaPlayer && mediaPlayer.length > 0 ? Number(mediaPlayer.length) : 0
    readonly property real mediaProgress: mediaLength > 0 ? Math.max(0, Math.min(1, mediaPosition / mediaLength)) : 0
    readonly property string mediaTitle: mediaPlayer && String(mediaPlayer.trackTitle || "").trim().length > 0 ? String(mediaPlayer.trackTitle).trim() : "Nenhuma faixa ativa"
    readonly property string mediaArtist: mediaPlayer && String(mediaPlayer.trackArtist || "").trim().length > 0 ? String(mediaPlayer.trackArtist).trim() : "Spotify / MPRIS"
    readonly property string mediaAlbum: mediaPlayer && String(mediaPlayer.trackAlbum || "").trim().length > 0 ? String(mediaPlayer.trackAlbum).trim() : "Player"
    readonly property string mediaArt: mediaPlayer ? normalizeArt(mediaPlayer.trackArtUrl) : ""
    readonly property bool batteryIsFull: batteryPercent >= 0.995 || String(batteryState || "").toLowerCase() === "full"

    signal closeRequested()
    signal popupRequested(string type)
    signal advancedSettingsRequested()
    signal systemPageRequested(string page)
    signal systemPageStepRequested(int direction)
    signal notificationActivated(string notificationId)
    signal notificationDismissRequested(string notificationId)
    signal notificationActionRequested(string notificationId, string actionIdentifier)
    signal notificationsClearRequested()
    signal wallpaperApplyRequested(var entry)
    signal wallpaperLibraryRequested(bool refresh)
    signal preferredGeometryChanged()

    // Notify consumers only after the public geometry properties themselves have
    // settled. Emitting from systemPreferred* made the parent read the previous
    // preferredHeight and cache it under the newly selected page.
    onPreferredWidthChanged: preferredGeometryChanged()
    onPreferredHeightChanged: preferredGeometryChanged()
    onSystemPreferredWidthChanged: systemGeometrySync.restart()
    onSystemPreferredHeightChanged: systemGeometrySync.restart()

    function motionClamp(value) {
        return Math.max(0, Math.min(1, Number(value) || 0))
    }

    function motionEaseOut(value) {
        const t = motionClamp(value)
        return 1 - Math.pow(1 - t, 3)
    }

    function motionEaseIn(value) {
        const t = motionClamp(value)
        return t * t * t
    }

    function systemMotionSegment(startMs, durationMs) {
        const elapsed = systemTransitionProgress * systemTransitionDuration
        return motionClamp((elapsed - startMs) / Math.max(1, durationMs))
    }

    function systemIncomingProgress() {
        if (systemOpeningIntro)
            return 1
        return motionEaseOut(systemMotionSegment(55, 190))
    }

    function systemOutgoingProgress() {
        return motionEaseIn(systemMotionSegment(0, 110))
    }

    function systemElementProgress(order) {
        const safeOrder = Math.max(0, Math.min(4, Number(order) || 0))
        return motionEaseOut(systemMotionSegment(70 + safeOrder * 24, 170))
    }

    function systemElementOffset(order, distance) {
        return Math.round((1 - systemElementProgress(order)) * (Number(distance) || 10))
    }

    function systemElementScale(order) {
        return 0.98 + systemElementProgress(order) * 0.02
    }

    function systemPageElementProgress(page, order) {
        return systemIncomingPage === String(page || "") ? systemElementProgress(order) : 1
    }

    function systemPageElementOffset(page, order, distance) {
        return systemIncomingPage === String(page || "") ? systemElementOffset(order, distance) : 0
    }

    function systemPageElementScale(page, order) {
        return systemIncomingPage === String(page || "") ? systemElementScale(order) : 1
    }

    function systemIncomingOpacity() {
        return systemOpeningIntro ? 1 : systemIncomingProgress()
    }

    function systemIncomingOffset() {
        return systemOpeningIntro ? 0 : systemTransitionDirection * 22 * (1 - systemIncomingProgress())
    }

    function systemIncomingScale() {
        return systemOpeningIntro ? 1 : 0.985 + systemIncomingProgress() * 0.015
    }

    function systemOutgoingOpacity() {
        return systemOutgoingStartOpacity * (1 - systemOutgoingProgress())
    }

    function systemOutgoingOffset() {
        const target = -systemTransitionDirection * 18
        return systemOutgoingStartOffset + (target - systemOutgoingStartOffset) * systemOutgoingProgress()
    }

    function systemOutgoingScale() {
        const target = 0.985
        return systemOutgoingStartScale + (target - systemOutgoingStartScale) * systemOutgoingProgress()
    }

    function resetInactiveSystemDetails() {
        if (systemPage !== "battery")
            batteryProfileExpanded = false
        if (systemPage !== "bluetooth")
            bluetoothExpandedAddress = ""
        if (systemPage !== "notifications")
            expandedNotificationGroup = ""
    }

    function setRightActionsExpanded(expanded) {
        const next = Boolean(expanded)
        if (rightActionsExpanded === next)
            return
        rightActionsExpanded = next
        systemGeometrySync.restart()
    }

    function initializeSystemTransition() {
        const page = String(systemPage || "settings")
        systemPageTransitionAnimation.stop()
        systemGeometryAnimation.stop()
        systemDisplayedPage = page
        systemIncomingPage = page
        systemOutgoingPage = ""
        systemTransitionDirection = systemSlideDirection < 0 ? -1 : 1
        systemTransitionProgress = 1
        systemVisualWidth = systemWidthForPage(page)
        systemVisualHeight = systemHeightForPage(page)
        systemOpeningIntro = false
        systemTransitionInitialized = true
    }

    function startSystemGeometryAnimation(targetWidth, targetHeight) {
        const nextWidth = Math.max(1, Number(targetWidth) || width)
        const nextHeight = Math.max(1, Number(targetHeight) || height)
        systemGeometryAnimation.stop()

        if (!systemMotionEnabled
                || (Math.abs(systemVisualWidth - nextWidth) < 0.5
                    && Math.abs(systemVisualHeight - nextHeight) < 0.5)) {
            systemVisualWidth = nextWidth
            systemVisualHeight = nextHeight
            return
        }

        systemVisualWidthAnimation.from = systemVisualWidth > 0 ? systemVisualWidth : nextWidth
        systemVisualWidthAnimation.to = nextWidth
        systemVisualHeightAnimation.from = systemVisualHeight > 0 ? systemVisualHeight : nextHeight
        systemVisualHeightAnimation.to = nextHeight
        systemGeometryAnimation.restart()
    }

    function finishSystemPageTransition() {
        systemTransitionProgress = 1
        systemDisplayedPage = systemIncomingPage.length > 0 ? systemIncomingPage : String(systemPage || "settings")
        systemIncomingPage = systemDisplayedPage
        systemOutgoingPage = ""
        systemOpeningIntro = false
        systemOutgoingStartOpacity = 1
        systemOutgoingStartOffset = 0
        systemOutgoingStartScale = 1
        resetInactiveSystemDetails()

        const targetWidth = systemWidthForPage(systemDisplayedPage)
        const targetHeight = systemHeightForPage(systemDisplayedPage)
        if (Math.abs(systemVisualWidth - targetWidth) > 0.5 || Math.abs(systemVisualHeight - targetHeight) > 0.5)
            startSystemGeometryAnimation(targetWidth, targetHeight)
    }

    function beginSystemPageTransition(nextPage) {
        const page = String(nextPage || "settings")
        if (!systemTransitionInitialized)
            initializeSystemTransition()

        if (popupType !== "system" || !open) {
            systemDisplayedPage = page
            systemIncomingPage = page
            systemOutgoingPage = ""
            systemTransitionProgress = 1
            systemVisualWidth = systemWidthForPage(page)
            systemVisualHeight = systemHeightForPage(page)
            return
        }

        if (systemDisplayedPage === page && !systemPageTransitionAnimation.running) {
            startSystemGeometryAnimation(systemWidthForPage(page), systemHeightForPage(page))
            return
        }

        const interrupted = systemPageTransitionAnimation.running
        const previousIncomingOpacity = systemIncomingOpacity()
        const previousIncomingOffset = systemIncomingOffset()
        const previousIncomingScale = systemIncomingScale()
        const previousPage = systemIncomingPage.length > 0 ? systemIncomingPage : systemDisplayedPage

        systemPageTransitionAnimation.stop()
        systemOutgoingPage = previousPage
        systemIncomingPage = page
        systemDisplayedPage = page
        systemTransitionDirection = systemSlideDirection < 0 ? -1 : 1
        systemOutgoingStartOpacity = interrupted ? Math.max(0.18, previousIncomingOpacity) : 1
        systemOutgoingStartOffset = interrupted ? previousIncomingOffset : 0
        systemOutgoingStartScale = interrupted ? previousIncomingScale : 1
        systemOpeningIntro = false
        systemTransitionProgress = 0
        startSystemGeometryAnimation(systemWidthForPage(page), systemHeightForPage(page))

        if (!systemMotionEnabled) {
            finishSystemPageTransition()
            return
        }
        systemPageTransitionAnimation.restart()
    }

    function beginSystemOpeningIntro() {
        if (!systemTransitionInitialized)
            initializeSystemTransition()

        const page = String(systemPage || "settings")
        systemPageTransitionAnimation.stop()
        systemGeometryAnimation.stop()
        systemDisplayedPage = page
        systemIncomingPage = page
        systemOutgoingPage = ""
        systemTransitionDirection = systemSlideDirection < 0 ? -1 : 1
        systemVisualWidth = systemWidthForPage(page)
        systemVisualHeight = systemHeightForPage(page)
        systemOpeningIntro = true
        systemTransitionProgress = 0

        if (!systemMotionEnabled) {
            finishSystemPageTransition()
            return
        }
        systemPageTransitionAnimation.restart()
    }

    function requestSearchFocus() {
        appFocusRequest += 1
    }

    function alpha(colorValue, opacity) {
        return theme ? theme.alpha(colorValue, opacity) : Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacity)
    }

    function mixTone(baseColor, tintColor, amount, opacity) {
        if (theme)
            return theme.mix(baseColor, tintColor, amount, opacity)

        const t = Math.max(0, Math.min(1, Number(amount) || 0))
        return Qt.rgba(
            baseColor.r + (tintColor.r - baseColor.r) * t,
            baseColor.g + (tintColor.g - baseColor.g) * t,
            baseColor.b + (tintColor.b - baseColor.b) * t,
            Math.max(0, Math.min(1, Number(opacity) || 0))
        )
    }

    function systemTone(tintColor, amount, opacity) {
        const base = theme ? theme.surfaceCard : card
        return mixTone(base, tintColor, amount, opacity)
    }

    function pastelTone(tintColor, lightAmount, opacity) {
        const light = theme && theme.themeMode === "light"
            ? Qt.rgba(1, 1, 1, 1)
            : Qt.rgba(0.94, 0.96, 0.98, 1)
        return mixTone(tintColor, light, lightAmount, opacity)
    }

    function deepTone(tintColor, opacity) {
        return mixTone(tintColor, Qt.rgba(0.015, 0.020, 0.022, 1), 0.72, opacity)
    }

    function canvasRgba(colorValue, opacity) {
        const alphaValue = opacity === undefined
            ? Number(colorValue.a)
            : Number(opacity)
        return "rgba("
            + Math.round(Math.max(0, Math.min(1, Number(colorValue.r))) * 255) + ","
            + Math.round(Math.max(0, Math.min(1, Number(colorValue.g))) * 255) + ","
            + Math.round(Math.max(0, Math.min(1, Number(colorValue.b))) * 255) + ","
            + Math.max(0, Math.min(1, isNaN(alphaValue) ? 1 : alphaValue)).toFixed(3)
            + ")"
    }

    function controlCenterVisualizerValue(index, count) {
        const values = cavaValues || []
        const bandCount = Math.max(2, Number(count) || 2)
        const unit = 1 - Math.max(0, Math.min(1, Number(index) / (bandCount - 1)))

        if (values.length <= 0)
            return 0.14 + 0.035 * (0.5 + 0.5 * Math.sin((Number(index) + 1) * 1.71))

        const position = unit * Math.max(0, values.length - 1)
        const lowerIndex = Math.floor(position)
        const upperIndex = Math.min(values.length - 1, lowerIndex + 1)
        const blend = position - lowerIndex
        const lowerValue = Number(values[lowerIndex])
        const upperValue = Number(values[upperIndex])
        const safeLower = isNaN(lowerValue) ? 0 : lowerValue
        const safeUpper = isNaN(upperValue) ? safeLower : upperValue
        const sampled = safeLower + (safeUpper - safeLower) * blend

        return Math.max(0.14, Math.min(1, 0.06 + Math.pow(Math.max(0, sampled), 0.68) * 0.98))
    }

    function controlCenterVisualizerColor(index, count, opacity) {
        const unit = Math.max(0, Math.min(1, Number(index) / Math.max(1, Number(count) - 1)))
        const tone = unit < 0.5
            ? mixTone(accent2, accent3, unit * 2, 1)
            : mixTone(accent3, accent, (unit - 0.5) * 2, 1)
        const lightAmount = theme && theme.themeMode === "light" ? 0.14 : 0.38
        return pastelTone(tone, lightAmount, opacity)
    }

    function normalizeArt(value) {
        const text = String(value || "").trim()
        if (text.length <= 0)
            return ""
        return text.charAt(0) === "/" ? "file://" + text : text
    }

    function rebuildApps() {
        const values = DesktopEntries.applications.values || []
        const query = String(appQuery || "").trim().toLowerCase()
        const next = []

        for (let i = 0; i < values.length; ++i) {
            const entry = values[i]
            if (!entry || entry.noDisplay)
                continue
            const name = String(entry.name || "")
            const generic = String(entry.genericName || "")
            if (query.length > 0 && (name + " " + generic).toLowerCase().indexOf(query) < 0)
                continue
            next.push(entry)
        }

        next.sort(function(a, b) { return String(a.name || "").localeCompare(String(b.name || "")) })
        appResults = next.slice(0, 12)
    }

    function rebuildSearch() {
        const values = DesktopEntries.applications.values || []
        const query = String(searchQuery || "").trim().toLowerCase()
        const next = []

        for (let i = 0; i < values.length; ++i) {
            const entry = values[i]
            if (!entry || entry.noDisplay)
                continue
            const haystack = (String(entry.name || "") + " " + String(entry.genericName || "")).toLowerCase()
            if (query.length > 0 && haystack.indexOf(query) < 0)
                continue
            next.push(entry)
        }

        next.sort(function(a, b) { return String(a.name || "").localeCompare(String(b.name || "")) })
        searchResults = next.slice(0, 6)
    }

    function rebuildCalendar() {
        const base = new Date(now.getFullYear(), now.getMonth() + calendarMonthOffset, 1)
        const firstOffset = (base.getDay() + 6) % 7
        const start = new Date(base.getFullYear(), base.getMonth(), 1 - firstOffset)
        const todayKey = now.getFullYear() + "-" + now.getMonth() + "-" + now.getDate()
        const next = []

        for (let i = 0; i < 42; ++i) {
            const value = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
            const key = value.getFullYear() + "-" + value.getMonth() + "-" + value.getDate()
            next.push({
                day: value.getDate(),
                inMonth: value.getMonth() === base.getMonth(),
                today: key === todayKey
            })
        }
        calendarCells = next
    }

    function calendarTitle() {
        const value = new Date(now.getFullYear(), now.getMonth() + calendarMonthOffset, 1)
        return Qt.formatDate(value, "MMMM 'de' yyyy")
    }

    function launchApp(entry) {
        if (!entry)
            return
        entry.execute()
        closeRequested()
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

    function refreshMedia() {
        mediaPlayer = pickMediaPlayer()
        mediaPosition = mediaPlayer ? Number(mediaPlayer.position || 0) : 0
    }

    function controlCenterLyricsFallback() {
        if (!mediaAvailable)
            return "Sem faixa ativa"

        const reason = String(lyricsReason || "")
        if (reason === "no-lyrics" || reason === "missing-metadata")
            return "Letra não encontrada"
        if (reason === "fetch-failed" || reason === "parse-error")
            return "Falha ao buscar a letra"
        if (reason === "no-player")
            return "Player indisponível"
        if (reason === "waiting-for-line" || reason === "between-lines" || reason === "empty-line")
            return "Aguardando o próximo verso…"
        return "Buscando letra…"
    }

    function toggleMedia() {
        if (mediaPlayer)
            mediaPlayer.togglePlaying()
    }

    function previousMedia() {
        if (!mediaAvailable)
            return

        if (mediaPlayer && mediaPlayer.canGoPrevious) {
            mediaPlayer.previous()
            return
        }

        runCommand("if command -v playerctl >/dev/null 2>&1; then playerctl previous >/dev/null 2>&1; fi")
    }

    function nextMedia() {
        if (!mediaAvailable)
            return

        if (mediaPlayer && mediaPlayer.canGoNext) {
            mediaPlayer.next()
            return
        }

        runCommand("if command -v playerctl >/dev/null 2>&1; then playerctl next >/dev/null 2>&1; fi")
    }

    function toggleShuffle() {
        if (mediaPlayer && mediaPlayer.shuffleSupported)
            mediaPlayer.shuffle = !mediaPlayer.shuffle
    }

    function toggleLoop() {
        if (!mediaPlayer || !mediaPlayer.loopSupported)
            return
        if (mediaPlayer.loopState === MprisLoopState.None)
            mediaPlayer.loopState = MprisLoopState.Playlist
        else if (mediaPlayer.loopState === MprisLoopState.Playlist)
            mediaPlayer.loopState = MprisLoopState.Track
        else
            mediaPlayer.loopState = MprisLoopState.None
    }

    function seekMedia(progress) {
        if (!mediaPlayer || !mediaPlayer.canSeek || mediaLength <= 0)
            return
        const value = Math.max(0, Math.min(1, Number(progress) || 0))
        mediaPlayer.position = value * mediaLength
        mediaPosition = mediaPlayer.position
    }

    function formatTime(value) {
        const seconds = Math.max(0, Math.floor(Number(value) || 0))
        const minutes = Math.floor(seconds / 60)
        const rest = seconds % 60
        return minutes + ":" + (rest < 10 ? "0" : "") + rest
    }

    function controlCenterClockText() {
        const hours = now.getHours()
        const minutes = now.getMinutes()
        return (hours < 10 ? "0" : "") + hours + ":" + (minutes < 10 ? "0" : "") + minutes
    }

    function controlCenterDateText() {
        const weekdays = ["dom.", "seg.", "ter.", "qua.", "qui.", "sex.", "sáb."]
        const months = ["jan.", "fev.", "mar.", "abr.", "mai.", "jun.", "jul.", "ago.", "set.", "out.", "nov.", "dez."]
        return weekdays[now.getDay()] + ", " + now.getDate() + " de " + months[now.getMonth()]
    }

    function profileSource() {
        const custom = theme ? String(theme.profileImagePath || "").trim() : ""
        return custom.length > 0 ? custom : Qt.resolvedUrl("../assets/profile-avatar.svg")
    }

    function runCommand(command) {
        if (commandProcess.running)
            commandProcess.running = false
        commandProcess.command = ["bash", "-lc", command]
        commandProcess.running = true
    }

    function refreshStatus() {
        if (!open)
            return
        const type = effectiveType
        if ((type === "volume" || type === "settingsQuick" || type === "quickSettings" || type === "settings") && !audioQuery.running)
            audioQuery.running = true
        if ((type === "brightness" || type === "display" || type === "settingsQuick" || type === "quickSettings" || type === "settings") && !brightnessQuery.running)
            brightnessQuery.running = true
        if ((type === "wifi" || type === "settingsQuick" || type === "quickSettings" || type === "settings") && !wifiQuery.running)
            wifiQuery.running = true
        if ((type === "bluetooth" || type === "settingsQuick" || type === "quickSettings" || type === "settings") && !bluetoothQuery.running)
            bluetoothQuery.running = true
        if ((type === "battery" || type === "settingsQuick" || type === "quickSettings" || type === "settings") && !batteryQuery.running)
            batteryQuery.running = true
        if (popupType === "time" && !worldClockQuery.running)
            worldClockQuery.running = true
    }

    function setVolume(value) {
        volumePercent = Math.max(0, Math.min(1, value))
        volumeCommit.restart()
    }

    function toggleMute() {
        muted = !muted
        runCommand("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
    }

    function setMicVolume(value) {
        micVolumePercent = Math.max(0, Math.min(1, value))
        micVolumeCommit.restart()
    }

    function toggleMicMute() {
        micMuted = !micMuted
        runCommand("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
    }

    function cycleAudioDevice(kind) {
        const model = kind === "source" ? audioSources : audioSinks
        if (model.count <= 1)
            return
        let current = 0
        for (let i = 0; i < model.count; ++i) {
            if (model.get(i).isDefault) {
                current = i
                break
            }
        }
        const next = model.get((current + 1) % model.count)
        audioDeviceError = ""
        audioDeviceAction.command = [audioDevicesScript, "set-default", String(next.nodeId)]
        audioDeviceAction.running = true
    }

    function setBrightness(value) {
        brightnessPercent = Math.max(0.05, Math.min(1, value))
        brightnessCommit.restart()
    }

    function toggleWifi() {
        wifiEnabled = !wifiEnabled
        networkAction.command = [networkControlScript, "radio", wifiEnabled ? "on" : "off"]
        networkAction.running = true
    }

    function connectWifi(ssid) {
        if (String(ssid || "").length <= 0)
            return
        wifiPendingAction = "Conectando"
        wifiError = ""
        networkAction.command = [networkControlScript, "connect", String(ssid)]
        networkAction.running = true
    }

    function selectWifiNetwork(network) {
        if (!network)
            return
        wifiSelectedSsid = String(network.ssid || "")
        wifiSelectedUuid = String(network.uuid || "")
        wifiSelectedSecure = Boolean(network.secure)
        wifiSelectedEnterprise = Boolean(network.enterprise)
        wifiHiddenForm = false
        wifiPassword = ""
        wifiError = ""
        wifiForgetConfirmUuid = ""
        if (Boolean(network.active))
            return
        if (Boolean(network.saved) || !wifiSelectedSecure) {
            connectWifi(wifiSelectedSsid)
            return
        }
        if (wifiSelectedEnterprise) {
            wifiError = "Rede corporativa: conclua identidade e certificado no editor avançado"
            return
        }
    }

    function openAdvancedNetworkSettings() {
        runCommand("if command -v nm-connection-editor >/dev/null 2>&1; then setsid -f nm-connection-editor >/dev/null 2>&1; elif command -v systemsettings >/dev/null 2>&1; then setsid -f systemsettings kcm_networkmanagement >/dev/null 2>&1; elif command -v gnome-control-center >/dev/null 2>&1; then setsid -f gnome-control-center wifi >/dev/null 2>&1; fi")
    }

    function submitWifiPassword() {
        const ssid = wifiHiddenForm ? String(wifiHiddenSsid || "").trim() : String(wifiSelectedSsid || "").trim()
        if (ssid.length <= 0) {
            wifiError = "Informe o nome da rede"
            return
        }
        if (wifiPassword.length <= 0) {
            wifiError = "Informe a senha"
            return
        }
        wifiPendingAction = "Autenticando"
        wifiError = ""
        wifiPendingSecret = wifiPassword
        networkSecretAction.command = [networkControlScript, "connect-secret", ssid, wifiHiddenForm ? "yes" : "no"]
        networkSecretAction.running = true
    }

    function forgetWifi(uuid) {
        if (String(uuid || "").length <= 0)
            return
        wifiPendingAction = "Esquecendo"
        wifiError = ""
        networkAction.command = [networkControlScript, "forget", String(uuid)]
        networkAction.running = true
    }

    function disconnectWifi() {
        wifiPendingAction = "Desconectando"
        wifiError = ""
        networkAction.command = [networkControlScript, "disconnect"]
        networkAction.running = true
    }

    function toggleBluetooth() {
        bluetoothPowered = !bluetoothPowered
        bluetoothAction.command = [bluetoothControlScript, "power", bluetoothPowered ? "on" : "off"]
        bluetoothAction.running = true
    }

    function setBluetoothConnection(address, connected) {
        if (String(address || "").length <= 0)
            return
        bluetoothPendingAddress = String(address)
        bluetoothPendingAction = connected ? "Desconectando" : "Conectando"
        bluetoothError = ""
        bluetoothAction.command = [bluetoothControlScript, connected ? "disconnect" : "connect", String(address)]
        bluetoothAction.running = true
    }

    function pairBluetoothDevice(address) {
        if (String(address || "").length <= 0)
            return
        bluetoothPendingAddress = String(address)
        bluetoothPendingAction = "Pareando"
        bluetoothPairPrompt = ""
        bluetoothPairResponse = ""
        bluetoothError = ""
        bluetoothPairSession.command = [bluetoothControlScript, "pair-session", String(address)]
        bluetoothPairSession.running = true
    }

    function answerBluetoothPairing(answer) {
        if (!bluetoothPairSession.running)
            return
        bluetoothPairSession.write(String(answer || "") + "\n")
        bluetoothPairPrompt = ""
        bluetoothPairResponse = ""
    }

    function scanBluetooth() {
        if (bluetoothScan.running)
            return
        bluetoothScanning = true
        bluetoothError = ""
        bluetoothScan.running = true
    }

    function setBluetoothDeviceIcon(address, iconType) {
        if (String(address || "").length <= 0)
            return
        bluetoothAction.command = [bluetoothControlScript, "icon-set", String(address), String(iconType || "auto")]
        bluetoothAction.running = true
    }

    function removeBluetoothDevice(address) {
        if (String(address || "").length <= 0)
            return
        bluetoothPendingAddress = String(address)
        bluetoothPendingAction = "Esquecendo"
        bluetoothError = ""
        bluetoothExpandedAddress = ""
        bluetoothAction.command = [bluetoothControlScript, "remove", String(address)]
        bluetoothAction.running = true
    }

    function bluetoothTypeIcon(type) {
        if (type === "headphones") return "headphones"
        if (type === "speaker") return "speaker"
        if (type === "controller") return "sports_esports"
        if (type === "phone") return "phone"
        if (type === "laptop") return "laptop"
        if (type === "keyboard") return "keyboard"
        if (type === "mouse") return "mouse"
        return "bluetooth"
    }

    function bluetoothTypeLabel(type) {
        if (type === "headphones") return "Fone"
        if (type === "speaker") return "Caixa"
        if (type === "controller") return "Controle"
        if (type === "phone") return "Celular"
        if (type === "laptop") return "Computador"
        if (type === "keyboard") return "Teclado"
        if (type === "mouse") return "Mouse"
        if (type === "auto") return "Automático"
        return "Bluetooth"
    }

    function bluetoothDeviceByAddress(address) {
        for (let i = 0; i < bluetoothDevices.count; ++i) {
            const device = bluetoothDevices.get(i)
            if (String(device.address || "") === String(address || ""))
                return device
        }
        return null
    }

    function connectedBluetoothName() {
        for (let i = 0; i < bluetoothDevices.count; ++i) {
            const device = bluetoothDevices.get(i)
            if (device && device.connected)
                return String(device.name || "Bluetooth")
        }
        return "Bluetooth"
    }

    function clearNotifications() {
        notificationsClearRequested()
    }

    function toggleDnd() {
        doNotDisturb = !doNotDisturb
        runCommand(doNotDisturb
            ? "makoctl mode -a do-not-disturb >/dev/null 2>&1 || dunstctl set-paused true >/dev/null 2>&1 || true"
            : "makoctl mode -r do-not-disturb >/dev/null 2>&1 || dunstctl set-paused false >/dev/null 2>&1 || true")
    }

    function toggleAirplane() {
        airplaneMode = !airplaneMode
        runCommand(airplaneMode
            ? "nmcli radio all off >/dev/null 2>&1; bluetoothctl power off >/dev/null 2>&1 || true"
            : "nmcli radio wifi on >/dev/null 2>&1; bluetoothctl power on >/dev/null 2>&1 || true")
    }

    function toggleNightLight() {
        nightLight = !nightLight
        runCommand(nightLight
            ? "hyprctl hyprsunset temperature 4500 >/dev/null 2>&1 || true"
            : "hyprctl hyprsunset identity >/dev/null 2>&1 || true")
    }

    function setPowerProfile(profile) {
        powerProfile = String(profile || "balanced")
        runCommand("powerprofilesctl set " + powerProfile + " >/dev/null 2>&1 || true")
    }

    function cyclePowerProfile() {
        if (powerProfile === "power-saver")
            setPowerProfile("balanced")
        else if (powerProfile === "balanced")
            setPowerProfile("performance")
        else
            setPowerProfile("power-saver")
    }

    function batteryStateLabel() {
        const state = String(batteryState || "").toLowerCase()
        if (batteryIsFull) return "Carga completa"
        if (state.indexOf("charg") >= 0 && state.indexOf("dis") < 0) return "Carregando"
        if (state.indexOf("dis") >= 0) return "Em uso"
        return "Bateria"
    }

    function powerProfileLabel(profile) {
        if (profile === "power-saver") return "Economia"
        if (profile === "performance") return "Desempenho"
        return "Equilibrado"
    }

    function powerProfileDescription(profile) {
        if (profile === "power-saver") return "Maior autonomia e menos atividade em segundo plano"
        if (profile === "performance") return "Mais desempenho com maior consumo de energia"
        return "Equilíbrio entre desempenho e duração da bateria"
    }

    function notificationValue(index, key, fallback) {
        if (!notificationsModelOverride || index < 0 || index >= notificationsModelOverride.count)
            return fallback
        const value = notificationsModelOverride.get(index)
        return value && value[key] !== undefined ? String(value[key]) : fallback
    }

    function notificationIconName(iconKey) {
        if (iconKey === "spotify") return "music_note"
        if (iconKey === "browser") return "language"
        if (iconKey === "discord") return "chat"
        if (iconKey === "whatsapp" || iconKey === "telegram") return "chat"
        if (iconKey === "velora") return "screenshot"
        return "notifications"
    }

    function notificationAccentColor(iconKey) {
        if (iconKey === "whatsapp" || iconKey === "spotify") return Qt.rgba(0.34, 0.80, 0.52, 1)
        if (iconKey === "telegram" || iconKey === "browser") return Qt.rgba(0.39, 0.68, 0.96, 1)
        if (iconKey === "discord") return Qt.rgba(0.56, 0.61, 0.98, 1)
        return accent2
    }

    function notificationActions(item) {
        if (!item)
            return []
        try {
            const actions = JSON.parse(String(item.actionsJson || "[]"))
            return Array.isArray(actions) ? actions.filter(function(action) {
                return action && String(action.identifier || "") !== "default"
            }).slice(0, 2) : []
        } catch (error) {
            return []
        }
    }

    function rebuildNotificationGroups() {
        const source = notificationsModelOverride
        const groupsByKey = ({})
        const ordered = []

        if (source) {
            for (let i = 0; i < source.count; ++i) {
                const value = source.get(i)
                if (!value)
                    continue
                const app = String(value.app || "Sistema")
                const key = app.toLowerCase().trim() || "sistema"
                let group = groupsByKey[key]
                const item = {
                    id: String(value.id || ""),
                    app: app,
                    summary: String(value.summary || "Notificação"),
                    body: String(value.body || ""),
                    timeText: String(value.timeText || "agora"),
                    iconKey: String(value.iconKey || "default"),
                    appIcon: String(value.appIcon || ""),
                    actionsJson: String(value.actionsJson || "[]")
                }
                if (!group) {
                    group = {
                        key: key,
                        app: app,
                        iconKey: item.iconKey,
                        appIcon: item.appIcon,
                        latestSummary: item.summary,
                        latestTime: item.timeText,
                        items: []
                    }
                    groupsByKey[key] = group
                    ordered.push(group)
                }
                group.items.push(item)
            }
        }

        notificationGroups = ordered.slice(0, 6)
        if (expandedNotificationGroup.length > 0 && !groupsByKey[expandedNotificationGroup])
            expandedNotificationGroup = ""
    }

    Timer {
        id: systemGeometrySync

        interval: 0
        repeat: false
        onTriggered: {
            if (!root.systemTransitionInitialized
                    || root.popupType !== "system"
                    || !root.open
                    || systemPageTransitionAnimation.running)
                return
            root.startSystemGeometryAnimation(
                root.systemWidthForPage(root.systemPage),
                root.systemHeightForPage(root.systemPage)
            )
        }
    }

    NumberAnimation {
        id: systemPageTransitionAnimation

        target: root
        property: "systemTransitionProgress"
        from: 0
        to: 1
        duration: root.systemTransitionDuration
        easing.type: Easing.Linear
        onFinished: root.finishSystemPageTransition()
    }

    ParallelAnimation {
        id: systemGeometryAnimation

        NumberAnimation {
            id: systemVisualWidthAnimation
            target: root
            property: "systemVisualWidth"
            duration: root.theme ? root.theme.motionPanelGeometry : 240
            easing.type: root.theme ? root.theme.motionEaseEmphasized : Easing.OutCubic
            easing.bezierCurve: root.theme ? root.theme.motionEmphasizedCurve : []
        }

        NumberAnimation {
            id: systemVisualHeightAnimation
            target: root
            property: "systemVisualHeight"
            duration: root.theme ? root.theme.motionPanelGeometry : 240
            easing.type: root.theme ? root.theme.motionEaseEmphasized : Easing.OutCubic
            easing.bezierCurve: root.theme ? root.theme.motionEmphasizedCurve : []
        }
    }

    Loader {
        id: customLoader

        anchors.fill: parent
        active: true
        visible: true
        asynchronous: false
        sourceComponent: {
            if (root.popupType === "time") return timeView
            if (root.popupType === "search" || root.popupType === "apps") return appsView
            if (root.popupType === "workspaces") return workspacesView
            if (root.popupType === "media") return mediaView
            if (root.popupType === "system") return systemView
            if (root.popupType === "volume") return volumeView
            if (root.popupType === "wifi") return wifiView
            if (root.popupType === "brightness") return brightnessView
            if (root.popupType === "bluetooth") return bluetoothView
            if (root.popupType === "battery") return batteryView
            if (root.popupType === "notifications") return notificationsView
            if (root.popupType === "profile") return profileView
            return settingsView
        }
    }

    HoverHandler {
        id: popupHover
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            root.rebuildApps()
            root.rebuildSearch()
        }
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() { root.refreshMedia() }
    }

    Connections {
        target: root.notificationsModelOverride
        ignoreUnknownSignals: true
        function onCountChanged() { root.rebuildNotificationGroups() }
        function onDataChanged() { root.rebuildNotificationGroups() }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.open
            && root.mediaAvailable
            && (root.popupType === "media"
                || (root.popupType === "system" && root.systemPage === "settings"))
        triggeredOnStart: true
        onTriggered: root.mediaPosition = root.mediaPlayer ? Number(root.mediaPlayer.position || 0) : 0
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.open
            && (root.popupType === "time"
                || (root.popupType === "system" && root.systemPage === "settings"))
        triggeredOnStart: true
        onTriggered: {
            root.now = new Date()
            if (root.popupType === "time")
                root.rebuildCalendar()
        }
    }

    Timer {
        interval: 6000
        repeat: true
        running: root.open && (root.popupType === "system" || root.popupType === "volume" || root.popupType === "wifi" || root.popupType === "brightness" || root.popupType === "bluetooth" || root.popupType === "battery" || root.popupType === "settingsQuick" || root.popupType === "quickSettings")
        triggeredOnStart: true
        onTriggered: root.refreshStatus()
    }

    Timer {
        id: volumeCommit
        interval: 100
        onTriggered: root.runCommand("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + Math.round(root.volumePercent * 100) + "%")
    }

    Timer {
        id: brightnessCommit
        interval: 100
        onTriggered: root.runCommand("brightnessctl set " + Math.round(root.brightnessPercent * 100) + "% >/dev/null 2>&1")
    }

    Timer {
        id: micVolumeCommit
        interval: 100
        onTriggered: root.runCommand("wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + Math.round(root.micVolumePercent * 100) + "%")
    }

    onAppQueryChanged: rebuildApps()
    onSearchQueryChanged: rebuildSearch()
    onPopupTypeChanged: {
        if (popupType !== "system")
            setRightActionsExpanded(false)
        if (popupType === "apps" || popupType === "search")
            rebuildApps()
        if (popupType === "media")
            refreshMedia()
        if (popupType === "time")
            rebuildCalendar()
        refreshStatus()
    }

    onSystemPageChanged: {
        refreshStatus()
        if (systemPage === "settings")
            refreshMedia()
        if (systemPage === "wallpaper" && open)
            wallpaperLibraryRequested(false)
        beginSystemPageTransition(systemPage)
        if (systemPage === "bluetooth" && open)
            scanBluetooth()
        else if (bluetoothScan.running) {
            bluetoothScan.running = false
            bluetoothScanning = false
        }
    }

    onNotificationsModelOverrideChanged: rebuildNotificationGroups()

    onOpenChanged: {
        if (open) {
            if (popupType === "system") {
                setRightActionsExpanded(false)
                wallpaperSessionSerial += 1
            }
            refreshStatus()
            if (popupType === "system") {
                beginSystemOpeningIntro()
                if (systemPage === "settings")
                    refreshMedia()
                if (systemPage === "bluetooth")
                    scanBluetooth()
                if (systemPage === "wallpaper")
                    wallpaperLibraryRequested(false)
            }
        } else if (popupType === "system") {
            setRightActionsExpanded(false)
            if (bluetoothScan.running)
                bluetoothScan.running = false
            if (bluetoothPairSession.running)
                bluetoothPairSession.running = false
            bluetoothScanning = false
            wifiPendingSecret = ""
            wifiPassword = ""
            initializeSystemTransition()
            resetInactiveSystemDetails()
        }
    }

    onRightControlCenterModeChanged: {
        if (!rightControlCenterMode)
            setRightActionsExpanded(false)
    }

    Component.onCompleted: {
        initializeSystemTransition()
        rebuildApps()
        rebuildSearch()
        rebuildCalendar()
        rebuildNotificationGroups()
        refreshMedia()
        if (open && popupType === "system")
            beginSystemOpeningIntro()
    }

    ListModel { id: wifiNetworks }
    ListModel { id: bluetoothDevices }
    ListModel { id: audioSinks }
    ListModel { id: audioSources }

    Process {
        id: commandProcess
        running: false
        command: ["true"]
        onExited: running = false
    }

    Process {
        id: audioQuery
        running: false
        command: [root.popupStatusScript, "audio"]
        stdout: SplitParser {
            onRead: function(data) {
                const parts = String(data || "").trim().split("|")
                const value = parseFloat(parts[1])
                if (parts[0] === "AUDIO_SINK") {
                    if (!isNaN(value))
                        root.volumePercent = Math.max(0, Math.min(1, value))
                    root.muted = parts[2] === "1"
                    if (parts.length > 3 && parts[3].length > 0)
                        root.audioOutputName = parts[3]
                } else if (parts[0] === "AUDIO_SOURCE") {
                    if (!isNaN(value))
                        root.micVolumePercent = Math.max(0, Math.min(1, value))
                    root.micMuted = parts[2] === "1"
                    if (parts.length > 3 && parts[3].length > 0)
                        root.audioInputName = parts[3]
                }
            }
        }
        onExited: {
            running = false
            if (!audioDevicesQuery.running)
                audioDevicesQuery.running = true
        }
    }

    Process {
        id: audioDevicesQuery
        running: false
        command: [root.audioDevicesScript, "status"]
        onStarted: {
            audioSinks.clear()
            audioSources.clear()
        }
        stdout: SplitParser {
            onRead: function(data) {
                const parts = String(data || "").trim().split("|")
                if ((parts[0] !== "SINK" && parts[0] !== "SOURCE") || !parts[1])
                    return
                const target = parts[0] === "SINK" ? audioSinks : audioSources
                target.append({
                    nodeId: String(parts[1]),
                    isDefault: String(parts[2]).toLowerCase() === "yes",
                    name: String(parts[3] || (parts[0] === "SINK" ? "Saída" : "Microfone"))
                })
            }
        }
        onExited: running = false
    }

    Process {
        id: audioDeviceAction
        running: false
        command: [root.audioDevicesScript, "status"]
        stdout: SplitParser {
            onRead: function(data) {
                const parts = String(data || "").trim().split("|")
                if (parts[0] === "ERR")
                    root.audioDeviceError = parts[2] || "Falha ao trocar dispositivo"
            }
        }
        onExited: {
            running = false
            if (!audioQuery.running)
                audioQuery.running = true
        }
    }

    Process {
        id: brightnessQuery
        running: false
        command: [root.popupStatusScript, "brightness"]
        stdout: SplitParser {
            onRead: function(data) {
                const parts = String(data || "").trim().split("|")
                const value = parseFloat(parts.length > 1 ? parts[1] : parts[0])
                if (!isNaN(value))
                    root.brightnessPercent = Math.max(0.05, Math.min(1, value))
                if (parts.length > 2 && parts[2].length > 0)
                    root.brightnessDevice = parts[2]
            }
        }
        onExited: running = false
    }

    Process {
        id: wifiQuery
        running: false
        command: [root.networkControlScript, "status"]
        onStarted: {
            root.wifiQueryNetworks = []
            root.wifiSavedProfiles = ({})
        }
        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data || "").trim()
                const parts = line.split("|")
                if (parts[0] === "ERR") {
                    root.wifiState = "unavailable"
                    root.wifiSsid = ""
                    return
                }
                if (parts[0] === "RADIO") {
                    root.wifiEnabled = line.indexOf("enabled") >= 0
                    return
                }
                if (parts[0] === "STATUS") {
                    root.wifiState = parts[1] || "unknown"
                    root.wifiSsid = parts[2] || ""
                    root.wifiIp = parts[4] || ""
                    return
                }
                if (parts[0] === "SAVED" && parts[1] && parts[2]) {
                    const profiles = Object.assign({}, root.wifiSavedProfiles)
                    profiles[String(parts[1])] = String(parts[2])
                    root.wifiSavedProfiles = profiles
                    return
                }
                if (parts[0] !== "NETWORK" || !parts[2])
                    return
                const ssid = String(parts[2])
                const uuid = String(root.wifiSavedProfiles[ssid] || "")
                const security = String(parts[4] || "")
                const securityLower = security.toLowerCase()
                root.wifiQueryNetworks = root.wifiQueryNetworks.concat([{
                    active: String(parts[1]).toLowerCase() === "yes",
                    ssid: ssid,
                    signal: parseInt(parts[3] || "0"),
                    security: security,
                    secure: security.length > 0 && security !== "--",
                    enterprise: securityLower.indexOf("802.1x") >= 0 || securityLower.indexOf("enterprise") >= 0,
                    saved: uuid.length > 0,
                    uuid: uuid
                }])
            }
        }
        onExited: {
            wifiNetworks.clear()
            for (let i = 0; i < root.wifiQueryNetworks.length; ++i)
                wifiNetworks.append(root.wifiQueryNetworks[i])
            root.wifiQueryNetworks = []
            running = false
        }
    }

    Process {
        id: networkAction
        running: false
        command: [root.networkControlScript, "status"]
        stdout: SplitParser {
            onRead: function(data) {
                const parts = String(data || "").trim().split("|")
                if (parts[0] === "ERR")
                    root.wifiError = parts[2] || "Não foi possível concluir a ação"
            }
        }
        onExited: {
            running = false
            root.wifiPendingAction = ""
            if (!wifiQuery.running)
                wifiQuery.running = true
        }
    }

    Process {
        id: networkSecretAction
        running: false
        stdinEnabled: true
        command: [root.networkControlScript, "status"]
        onStarted: {
            write(root.wifiPendingSecret + "\n")
            root.wifiPendingSecret = ""
            root.wifiPassword = ""
        }
        stdout: SplitParser {
            onRead: function(data) {
                const parts = String(data || "").trim().split("|")
                if (parts[0] === "ERR")
                    root.wifiError = parts[2] === "authentication failed" ? "Senha incorreta ou autenticação recusada" : (parts[2] || "Falha ao conectar")
                else if (parts[0] === "OK") {
                    root.wifiSelectedSsid = ""
                    root.wifiSelectedEnterprise = false
                    root.wifiHiddenSsid = ""
                    root.wifiHiddenForm = false
                }
            }
        }
        onExited: {
            running = false
            root.wifiPendingSecret = ""
            root.wifiPendingAction = ""
            if (!wifiQuery.running)
                wifiQuery.running = true
        }
    }

    Process {
        id: bluetoothQuery
        running: false
        command: [root.bluetoothControlScript, "status-detailed"]
        onStarted: bluetoothDevices.clear()
        stdout: SplitParser {
            onRead: function(data) {
                const parts = String(data || "").trim().split("|")
                if (parts[0] === "POWER") {
                    const state = String(parts[1] || "").toLowerCase()
                    root.bluetoothAvailable = state !== "unavailable"
                    root.bluetoothPowered = state === "yes"
                    return
                }
                if (parts[0] !== "DEVICE" || !parts[2])
                    return
                bluetoothDevices.append({
                    state: String(parts[1] || "KNOWN"),
                    connected: String(parts[7] || "").toLowerCase() === "yes",
                    paired: String(parts[5] || "").toLowerCase() === "yes",
                    trusted: String(parts[6] || "").toLowerCase() === "yes",
                    address: String(parts[2]),
                    name: String(parts[3] || "Dispositivo Bluetooth"),
                    type: String(parts[4] || "bluetooth"),
                    rssi: parseInt(parts[8] || "-127"),
                    battery: parseInt(parts[9] || "-1")
                })
            }
        }
        onExited: {
            running = false
            root.bluetoothLayoutCount = bluetoothDevices.count
            root.preferredGeometryChanged()
            if (root.bluetoothExpandedAddress.length > 0 && !root.bluetoothDeviceByAddress(root.bluetoothExpandedAddress))
                root.bluetoothExpandedAddress = ""
        }
    }

    Process {
        id: bluetoothAction
        running: false
        command: [root.bluetoothControlScript, "status"]
        stdout: SplitParser {
            onRead: function(data) {
                const parts = String(data || "").trim().split("|")
                if (parts[0] === "ERR")
                    root.bluetoothError = parts[2] || "Não foi possível concluir a ação"
            }
        }
        onExited: {
            running = false
            root.bluetoothPendingAction = ""
            root.bluetoothPendingAddress = ""
            if (!bluetoothQuery.running)
                bluetoothQuery.running = true
        }
    }

    Process {
        id: bluetoothScan
        running: false
        command: [root.bluetoothControlScript, "scan", "10"]
        onExited: {
            running = false
            root.bluetoothScanning = false
            if (!bluetoothQuery.running)
                bluetoothQuery.running = true
        }
    }

    Process {
        id: bluetoothPairSession
        running: false
        stdinEnabled: true
        command: [root.bluetoothControlScript, "status"]
        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data || "").replace(/\u001b\\[[0-9;?]*[ -/]*[@-~]/g, "").trim()
                const lower = line.toLowerCase()
                if (lower.indexOf("confirm passkey") >= 0 || lower.indexOf("yes/no") >= 0) {
                    root.bluetoothPairPrompt = line
                    return
                }
                if (lower.indexOf("enter pin") >= 0 || lower.indexOf("enter passkey") >= 0) {
                    root.bluetoothPairPrompt = line
                    return
                }
                if (lower.indexOf("failed") >= 0 || lower.indexOf("authentication") >= 0)
                    root.bluetoothError = line
            }
        }
        onExited: function(exitCode) {
            running = false
            if (exitCode !== 0 && root.bluetoothError.length <= 0)
                root.bluetoothError = "Pareamento cancelado ou não confirmado"
            root.bluetoothPendingAction = ""
            root.bluetoothPendingAddress = ""
            root.bluetoothPairPrompt = ""
            root.bluetoothPairResponse = ""
            if (!bluetoothQuery.running)
                bluetoothQuery.running = true
        }
    }

    Process {
        id: batteryQuery
        running: false
        command: [root.popupStatusScript, "battery", "--force"]
        stdout: SplitParser {
            onRead: function(data) {
                const parts = String(data || "").trim().split("|")
                if (parts[0] === "BATTERY") {
                    const value = parseFloat(parts[1] || "0")
                    if (!isNaN(value) && value > 0)
                        root.batteryPercent = Math.max(0, Math.min(1, value))
                    root.batteryState = parts[2] || "unknown"
                    root.batteryTime = parts[3] || ""
                    if (parts.length > 4)
                        root.batteryHealth = parseFloat(parts[4] || "-1")
                    if (parts.length > 5)
                        root.batteryCycles = parseInt(parts[5] || "-1")
                } else if (parts[0] === "POWER") {
                    root.powerProfile = parts[1] || "balanced"
                    root.batteryAcOnline = String(parts[2] || "").toLowerCase() === "yes" || parts[2] === "1"
                }
            }
        }
        onExited: running = false
    }

    Process {
        id: worldClockQuery
        running: false
        command: [root.worldClockScript, "status"]
        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data || "").trim()
                if (line.length <= 0)
                    return
                try {
                    const parsed = JSON.parse(line)
                    if (parsed && Array.isArray(parsed.items) && parsed.items.length >= 2)
                        root.worldClockItems = parsed.items.slice(0, 2)
                } catch (error) {
                    console.warn("VeloraTopBarPopup: invalid world clock state")
                }
            }
        }
        onExited: running = false
    }

    component PopupTitle: ColumnLayout {
        property string title: ""
        property string subtitle: ""
        spacing: 2

        Text {
            Layout.fillWidth: true
            text: parent.title
            color: root.ink
            font.family: root.uiFont
            font.pixelSize: 22
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: parent.subtitle
            color: root.inkSoft
            font.family: root.uiFont
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }

    component ActionCard: Rectangle {
        id: action
        property string iconText: "•"
        property string iconName: "help"
        property string title: ""
        property string subtitle: ""
        property bool active: false
        signal triggered()

        radius: 22
        color: active ? root.primaryContainer : (actionMouse.containsMouse ? root.surfaceContainerHigh : root.surfaceContainer)
        border.width: 1
        border.color: active ? root.alpha(root.accent, 0.54) : root.outlineVariant
        scale: actionMouse.pressed ? 0.975 : (actionMouse.containsMouse ? 1.012 : 1)

        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors { fill: parent; margins: 12 }
            spacing: 11

            Rectangle {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                radius: 21
                color: action.active ? root.alpha(root.accent, 0.26) : root.alpha(root.inkSoft, 0.10)

                VeloraMaterialIcon {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    iconName: action.iconName
                    iconColor: action.active ? root.onPrimaryContainer : root.inkSoft
                    filled: action.active
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    text: action.title
                    color: root.ink
                    font.family: root.uiFont
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: action.subtitle
                    color: root.inkSoft
                    font.family: root.uiFont
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.triggered()
        }
    }

    component CompactSlider: Item {
        id: slider
        property string label: "Controle"
        property string detail: ""
        property real value: 0.5
        property color fillColor: root.accent
        property string iconName: "tune"
        signal moved(real value)

        Layout.fillWidth: true
        Layout.preferredHeight: 72

        RowLayout {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            VeloraMaterialIcon { Layout.preferredWidth: 22; Layout.preferredHeight: 22; iconName: slider.iconName; iconColor: slider.fillColor; filled: true }
            Text { text: slider.label; color: root.ink; font.family: root.uiFont; font.pixelSize: 13; font.weight: Font.DemiBold }
            Item { Layout.fillWidth: true }
            Text { text: slider.detail; color: root.inkSoft; font.family: root.monoFont; font.pixelSize: 11; elide: Text.ElideLeft }
        }

        Rectangle {
            id: sliderTrack
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 10 }
            height: 10
            radius: 5
            color: root.alpha(root.inkSoft, 0.16)

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, slider.value))
                height: parent.height
                radius: parent.radius
                color: slider.fillColor
            }

            Rectangle {
                x: Math.max(0, Math.min(parent.width - width, parent.width * slider.value - width / 2))
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                radius: 11
                color: slider.fillColor
                border.width: 3
                border.color: root.onPrimaryContainer
            }

            MouseArea {
                anchors { fill: parent; margins: -10 }
                cursorShape: Qt.PointingHandCursor
                function apply(mouse) {
                    const local = mapToItem(sliderTrack, mouse.x, mouse.y)
                    slider.moved(Math.max(0, Math.min(1, local.x / Math.max(1, sliderTrack.width))))
                }
                onPressed: function(mouse) { apply(mouse) }
                onPositionChanged: function(mouse) { if (pressed) apply(mouse) }
            }
        }
    }

    component DenseIconButton: Rectangle {
        id: denseIconButton
        property string iconName: "settings"
        property int buttonSize: 40
        property bool active: false
        property bool enabledControl: true
        signal triggered()

        implicitWidth: buttonSize
        implicitHeight: buttonSize
        Layout.preferredWidth: buttonSize
        Layout.preferredHeight: buttonSize
        radius: buttonSize / 2
        opacity: enabledControl ? 1 : 0.34
        color: "transparent"
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: root.systemTone(
                    root.accent,
                    denseIconButton.active ? 0.26 : (denseIconMouse.containsMouse ? 0.14 : 0.07),
                    denseIconButton.active ? 0.56 : (denseIconMouse.containsMouse ? 0.48 : 0.38)
                )
            }
            GradientStop {
                position: 1
                color: root.systemTone(
                    root.accent2,
                    denseIconButton.active ? 0.18 : (denseIconMouse.containsMouse ? 0.10 : 0.04),
                    denseIconButton.active ? 0.54 : (denseIconMouse.containsMouse ? 0.46 : 0.36)
                )
            }
        }
        border.width: 1
        border.color: active ? root.alpha(root.accent, 0.42) : root.outlineVariant
        scale: denseIconMouse.pressed ? 0.94 : (denseIconMouse.containsMouse ? 1.04 : 1)

        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

        VeloraMaterialIcon {
            anchors.centerIn: parent
            width: Math.round(parent.buttonSize * 0.53)
            height: width
            iconName: parent.iconName
            iconColor: parent.active ? root.onPrimaryContainer : root.ink
            filled: parent.active
        }

        MouseArea {
            id: denseIconMouse
            anchors.fill: parent
            enabled: denseIconButton.enabledControl
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: denseIconButton.triggered()
        }
    }

    component TransportButton: Rectangle {
        id: transportButton
        property string action: "play"
        property int buttonSize: action === "play" || action === "pause" ? 38 : 34
        property bool primary: action === "play" || action === "pause"
        property bool enabledControl: true
        signal triggered()

        implicitWidth: buttonSize
        implicitHeight: buttonSize
        Layout.preferredWidth: buttonSize
        Layout.preferredHeight: buttonSize
        radius: buttonSize / 2
        opacity: enabledControl ? 1 : 0.30
        color: transportMouse.containsMouse ? root.alpha(root.inkSoft, 0.11) : "transparent"
        border.width: 0
        scale: transportMouse.pressed ? 0.92 : (transportMouse.containsMouse ? 1.05 : 1)

        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        Item {
            anchors.centerIn: parent
            width: 19
            height: 19

            Shape {
                anchors.fill: parent
                visible: transportButton.action === "play"
                antialiasing: true
                ShapePath {
                    strokeWidth: 0
                    fillColor: root.ink
                    startX: 4
                    startY: 2
                    PathLine { x: 17; y: 9.5 }
                    PathLine { x: 4; y: 17 }
                    PathLine { x: 4; y: 2 }
                }
            }

            Row {
                anchors.centerIn: parent
                visible: transportButton.action === "pause"
                spacing: 4
                Rectangle { width: 5; height: 17; radius: 2.5; color: root.ink }
                Rectangle { width: 5; height: 17; radius: 2.5; color: root.ink }
            }

            Rectangle {
                visible: transportButton.action === "previous"
                x: 1
                y: 3
                width: 3
                height: 13
                radius: 1.5
                color: root.ink
            }
            Shape {
                anchors.fill: parent
                visible: transportButton.action === "previous"
                antialiasing: true
                ShapePath {
                    strokeWidth: 0
                    fillColor: root.ink
                    startX: 16
                    startY: 2
                    PathLine { x: 5; y: 9.5 }
                    PathLine { x: 16; y: 17 }
                    PathLine { x: 16; y: 2 }
                }
            }

            Rectangle {
                visible: transportButton.action === "next"
                x: 15
                y: 3
                width: 3
                height: 13
                radius: 1.5
                color: root.ink
            }
            Shape {
                anchors.fill: parent
                visible: transportButton.action === "next"
                antialiasing: true
                ShapePath {
                    strokeWidth: 0
                    fillColor: root.ink
                    startX: 3
                    startY: 2
                    PathLine { x: 14; y: 9.5 }
                    PathLine { x: 3; y: 17 }
                    PathLine { x: 3; y: 2 }
                }
            }
        }

        MouseArea {
            id: transportMouse
            anchors.fill: parent
            enabled: transportButton.enabledControl
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: transportButton.triggered()
        }
    }

    component ControlCenterVinyl: Item {
        id: vinyl

        property bool playing: false
        property bool emphasized: false
        property bool animateAsEffectSource: false
        readonly property bool motionEnabled: !root.theme || root.theme.motionEnabled

        transformOrigin: Item.Center
        scale: emphasized ? 1.035 : 1

        Behavior on scale {
            NumberAnimation {
                duration: vinyl.motionEnabled ? 220 : 1
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: vinylShadowSource

            anchors.fill: parent
            radius: width / 2
            color: "black"
            visible: false
        }

        DropShadow {
            anchors.fill: parent
            source: vinylShadowSource
            horizontalOffset: 0
            verticalOffset: 5
            radius: 14
            samples: 29
            spread: 0.02
            color: Qt.rgba(0, 0, 0, 0.58)
            transparentBorder: true
        }

        Item {
            id: vinylArtwork

            anchors.fill: parent
            visible: false

            Rectangle {
                anchors.fill: parent
                color: "#08090b"
            }

            RadialGradient {
                anchors.fill: parent
                horizontalOffset: -Math.round(width * 0.10)
                verticalOffset: -Math.round(height * 0.12)
                gradient: Gradient {
                    GradientStop { position: 0; color: "#35383d" }
                    GradientStop { position: 0.12; color: "#111317" }
                    GradientStop { position: 0.28; color: "#25282c" }
                    GradientStop { position: 0.48; color: "#07080a" }
                    GradientStop { position: 0.72; color: "#1b1d20" }
                    GradientStop { position: 1; color: "#050607" }
                }
            }

            ConicalGradient {
                anchors.fill: parent
                angle: 28
                opacity: vinyl.emphasized ? 0.62 : 0.45
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.02) }
                    GradientStop { position: 0.11; color: Qt.rgba(1, 1, 1, 0.28) }
                    GradientStop { position: 0.20; color: Qt.rgba(1, 1, 1, 0.02) }
                    GradientStop { position: 0.47; color: Qt.rgba(1, 1, 1, 0.01) }
                    GradientStop { position: 0.60; color: root.alpha(root.accent3, 0.18) }
                    GradientStop { position: 0.72; color: Qt.rgba(1, 1, 1, 0.01) }
                    GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0.02) }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: vinyl.motionEnabled ? 220 : 1
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Canvas {
                id: vinylGrooves

                anchors.fill: parent
                antialiasing: true

                onPaint: {
                    const ctx = getContext("2d")
                    const cx = width / 2
                    const cy = height / 2
                    const maxRadius = Math.min(width, height) / 2
                    ctx.reset()
                    ctx.clearRect(0, 0, width, height)
                    ctx.lineWidth = 0.72

                    for (let ring = maxRadius * 0.25; ring < maxRadius * 0.91; ring += 3.15) {
                        const alternate = Math.round(ring) % 2 === 0
                        ctx.strokeStyle = alternate
                            ? root.canvasRgba(root.ink, 0.085)
                            : "rgba(0,0,0,0.48)"
                        ctx.beginPath()
                        ctx.arc(cx, cy, ring, 0, Math.PI * 2)
                        ctx.stroke()
                    }

                    ctx.lineWidth = 1.1
                    ctx.strokeStyle = root.canvasRgba(root.accent3, 0.20)
                    ctx.beginPath()
                    ctx.arc(cx, cy, maxRadius * 0.82, Math.PI * 1.08, Math.PI * 1.58)
                    ctx.stroke()
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
            }

            Rectangle {
                anchors.centerIn: parent
                width: Math.round(parent.width * 0.34)
                height: width
                radius: width / 2
                color: "transparent"
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: root.pastelTone(root.accent, 0.22, 1) }
                    GradientStop { position: 0.52; color: root.accent3 }
                    GradientStop { position: 1; color: root.accent2 }
                }
                border.width: 1
                border.color: root.alpha(root.ink, 0.28)

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.max(5, Math.round(parent.width * 0.16))
                    height: width
                    radius: width / 2
                    color: root.deepTone(root.accent, 0.96)
                    border.width: 1
                    border.color: root.alpha(root.ink, 0.50)
                }
            }
        }

        Rectangle {
            id: vinylCircleMask

            anchors.fill: parent
            radius: width / 2
            color: "white"
            visible: false
            antialiasing: true
        }

        OpacityMask {
            anchors.fill: parent
            source: vinylArtwork
            maskSource: vinylCircleMask
            cached: true
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: root.alpha(root.inkSoft, vinyl.emphasized ? 0.30 : 0.17)
            antialiasing: true
        }

        NumberAnimation on rotation {
            from: 0
            to: 360
            duration: 5600
            loops: Animation.Infinite
            running: vinyl.playing
                && (vinyl.visible || vinyl.animateAsEffectSource)
                && vinyl.motionEnabled
            easing.type: Easing.Linear
        }
    }

    component DensePill: Rectangle {
        id: densePill
        property string iconName: "settings"
        property string title: ""
        property string subtitle: ""
        property bool active: false
        property bool connectionStyle: false
        property color accentColor: root.accent
        property color secondaryAccentColor: root.accent2
        signal triggered()

        Layout.preferredHeight: 54
        radius: 22
        color: "transparent"
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: root.systemTone(
                    densePill.accentColor,
                    densePill.active
                        ? (densePill.connectionStyle ? 0.13 : 0.24)
                        : (densePillMouse.containsMouse ? 0.10 : 0.04),
                    densePill.active
                        ? (densePill.connectionStyle ? 0.50 : 0.56)
                        : (densePillMouse.containsMouse ? 0.51 : 0.43)
                )
            }
            GradientStop {
                position: 1
                color: root.systemTone(
                    densePill.secondaryAccentColor,
                    densePill.active
                        ? (densePill.connectionStyle ? 0.08 : 0.17)
                        : (densePillMouse.containsMouse ? 0.07 : 0.03),
                    densePill.active
                        ? (densePill.connectionStyle ? 0.48 : 0.54)
                        : (densePillMouse.containsMouse ? 0.49 : 0.41)
                )
            }
        }
        border.width: 1
        border.color: active
            ? root.alpha(accentColor, connectionStyle ? 0.28 : 0.38)
            : root.outlineVariant
        scale: densePillMouse.pressed ? 0.985 : 1

        RowLayout {
            anchors { fill: parent; leftMargin: 10; rightMargin: 12 }
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 19
                color: densePill.connectionStyle && densePill.active
                    ? root.pastelTone(densePill.accentColor, 0.82, 0.94)
                    : (densePill.active
                        ? root.systemTone(densePill.accentColor, 0.28, 0.48)
                        : root.alpha(root.inkSoft, 0.10))
                VeloraMaterialIcon {
                    anchors.centerIn: parent
                    width: 23
                    height: 23
                    iconName: densePill.iconName
                    iconColor: densePill.connectionStyle && densePill.active
                        ? root.pastelTone(densePill.accentColor, 0.12, 1)
                        : (densePill.active ? root.onPrimaryContainer : root.inkSoft)
                    filled: densePill.active
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text { Layout.fillWidth: true; text: densePill.title; color: root.ink; font.family: root.uiFont; font.pixelSize: 12; font.weight: Font.DemiBold; elide: Text.ElideRight }
                Text { Layout.fillWidth: true; text: densePill.subtitle; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 9; elide: Text.ElideRight }
            }
        }

        MouseArea {
            id: densePillMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: densePill.triggered()
        }
    }

    component RightConnectionPill: Item {
        id: connectionPill

        property string iconName: "wifi"
        property string title: ""
        property string subtitle: ""
        property bool active: false
        property color accentColor: root.accent
        property color secondaryAccentColor: root.accent3
        signal triggered()

        implicitWidth: 164
        implicitHeight: 62
        Layout.preferredHeight: 62
        scale: connectionMouse.pressed ? 0.985 : 1

        Behavior on scale {
            NumberAnimation {
                duration: root.systemMotionEnabled ? 90 : 1
                easing.type: Easing.OutCubic
            }
        }

        DropShadow {
            anchors.fill: connectionSurface
            source: connectionSurface
            horizontalOffset: 0
            verticalOffset: 4
            radius: 13
            samples: 27
            color: Qt.rgba(0, 0, 0, connectionMouse.containsMouse ? 0.30 : 0.24)
            transparentBorder: true
        }

        Rectangle {
            id: connectionSurface

            anchors.fill: parent
            radius: 20
            clip: true
            color: "transparent"
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0
                    color: root.systemTone(
                        connectionPill.accentColor,
                        connectionPill.active
                            ? (connectionMouse.containsMouse ? 0.18 : 0.13)
                            : (connectionMouse.containsMouse ? 0.11 : 0.07),
                        connectionPill.active ? 0.57 : 0.50
                    )
                }
                GradientStop {
                    position: 1
                    color: root.systemTone(
                        connectionPill.secondaryAccentColor,
                        connectionPill.active
                            ? (connectionMouse.containsMouse ? 0.15 : 0.10)
                            : (connectionMouse.containsMouse ? 0.09 : 0.05),
                        connectionPill.active ? 0.53 : 0.46
                    )
                }
            }
            border.width: 1
            border.color: root.alpha(
                connectionPill.active ? connectionPill.accentColor : root.inkSoft,
                connectionPill.active ? 0.38 : 0.24
            )

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 1
                }
                height: Math.round(parent.height * 0.48)
                radius: Math.max(0, parent.radius - 1)
                color: root.alpha(root.ink, connectionMouse.containsMouse ? 0.045 : 0.028)
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: 10
                    rightMargin: 10
                    bottomMargin: 1
                }
                height: 1
                radius: 0.5
                color: root.alpha(Qt.rgba(0, 0, 0, 1), 0.24)
            }
        }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 11
            }
            spacing: 9

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
                color: "transparent"
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop {
                        position: 0
                        color: connectionPill.active
                            ? root.pastelTone(connectionPill.secondaryAccentColor, 0.42, 0.96)
                            : root.systemTone(connectionPill.secondaryAccentColor, 0.14, 0.50)
                    }
                    GradientStop {
                        position: 1
                        color: connectionPill.active
                            ? root.pastelTone(connectionPill.accentColor, 0.68, 0.94)
                            : root.systemTone(connectionPill.accentColor, 0.08, 0.44)
                    }
                }
                border.width: 1
                border.color: root.alpha(
                    connectionPill.active ? connectionPill.accentColor : root.inkSoft,
                    connectionPill.active ? 0.40 : 0.20
                )

                VeloraMaterialIcon {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    iconName: connectionPill.iconName
                    iconColor: connectionPill.active
                        ? root.deepTone(connectionPill.accentColor, 0.90)
                        : root.inkSoft
                    filled: connectionPill.active
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: connectionPill.title
                    color: root.ink
                    font.family: root.uiFont
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: connectionPill.subtitle
                    color: root.inkSoft
                    font.family: root.uiFont
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                Layout.preferredWidth: 8
                Layout.preferredHeight: 8
                radius: 4
                color: root.pastelTone(
                    connectionPill.active
                        ? connectionPill.accentColor
                        : connectionPill.secondaryAccentColor,
                    connectionPill.active ? 0.46 : 0.62,
                    connectionPill.active ? 0.96 : 0.72
                )
                border.width: 1
                border.color: root.alpha(root.ink, 0.24)

                Rectangle {
                    anchors.centerIn: parent
                    width: 3
                    height: 3
                    radius: 1.5
                    color: root.alpha(root.ink, connectionPill.active ? 0.48 : 0.24)
                }
            }
        }

        MouseArea {
            id: connectionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: connectionPill.triggered()
        }
    }

    component RightVerticalTrack: Item {
        id: rightTrack

        property real value: 0.5
        property string iconName: "sun"
        property color fillColor: root.accent
        property color secondaryFillColor: root.accent3
        signal moved(real value)

        implicitWidth: 62
        implicitHeight: 164

        VeloraMaterialIcon {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: 11
            }
            width: 25
            height: 25
            iconName: rightTrack.iconName
            iconColor: root.ink
            filled: true
        }

        DropShadow {
            anchors.fill: rightTrackGroove
            source: rightTrackGroove
            horizontalOffset: 0
            verticalOffset: 3
            radius: 9
            samples: 19
            color: Qt.rgba(0, 0, 0, 0.24)
            transparentBorder: true
        }

        Rectangle {
            id: rightTrackGroove

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                bottom: parent.bottom
                topMargin: 47
                bottomMargin: 9
            }
            width: Math.min(58, parent.width - 6)
            radius: width / 2
            clip: true
            color: "transparent"
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: root.systemTone(root.accent3, 0.035, 0.32)
                }
                GradientStop {
                    position: 1
                    color: root.systemTone(root.accent, 0.065, 0.42)
                }
            }
            border.width: 1
            border.color: root.alpha(root.inkSoft, 0.25)

            Rectangle {
                id: rightTrackFill

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: 1
                }
                height: Math.max(
                    24,
                    Math.round((parent.height - 2) * Math.max(0, Math.min(1, rightTrack.value)))
                )
                radius: Math.min((parent.width - 2) / 2, height / 2)
                color: "transparent"
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: root.pastelTone(rightTrack.secondaryFillColor, 0.38, 0.92)
                    }
                    GradientStop {
                        position: 0.52
                        color: root.pastelTone(
                            root.mixTone(
                                rightTrack.secondaryFillColor,
                                rightTrack.fillColor,
                                0.48,
                                1
                            ),
                            0.54,
                            0.94
                        )
                    }
                    GradientStop {
                        position: 1
                        color: root.pastelTone(rightTrack.fillColor, 0.70, 0.96)
                    }
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 1
                    }
                    height: Math.min(20, parent.height * 0.34)
                    radius: Math.min(parent.radius, height / 2)
                    color: root.alpha(root.ink, 0.045)
                }

                Behavior on height {
                    enabled: !rightTrackMouse.pressed
                    NumberAnimation {
                        duration: root.systemMotionEnabled ? 130 : 1
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        MouseArea {
            id: rightTrackMouse

            anchors.fill: rightTrackGroove
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            function apply(mouseY) {
                rightTrack.moved(1 - Math.max(0, Math.min(1, mouseY / Math.max(1, height))))
            }

            onPressed: function(mouse) { apply(mouse.y) }
            onPositionChanged: function(mouse) {
                if (pressed)
                    apply(mouse.y)
            }
        }
    }

    component RightPriorityAction: Item {
        id: priorityAction

        property string iconName: "settings"
        property string tooltip: ""
        property bool active: false
        property bool expandControl: false
        property bool expanded: false
        property bool enabledControl: true
        property color accentColor: root.accent
        property color secondaryAccentColor: root.accent2
        signal triggered()

        implicitHeight: 60
        opacity: enabledControl ? 1 : 0.38

        DropShadow {
            anchors.fill: prioritySurface
            source: prioritySurface
            horizontalOffset: 0
            verticalOffset: 3
            radius: 9
            samples: 19
            color: Qt.rgba(0, 0, 0, priorityMouse.containsMouse ? 0.30 : 0.22)
            transparentBorder: true
        }

        Rectangle {
            id: prioritySurface

            anchors.centerIn: parent
            width: Math.min(52, parent.width - 5)
            height: width
            radius: 17
            scale: priorityMouse.pressed ? 0.94 : (priorityMouse.containsMouse ? 1.04 : 1)
            color: "transparent"
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0
                    color: priorityAction.active || priorityAction.expandControl
                        ? root.systemTone(
                            priorityAction.accentColor,
                            priorityMouse.containsMouse ? 0.30 : 0.22,
                            0.62
                        )
                        : root.systemTone(
                            priorityAction.accentColor,
                            priorityMouse.containsMouse ? 0.18 : 0.11,
                            0.52
                        )
                }
                GradientStop {
                    position: 1
                    color: priorityAction.active || priorityAction.expandControl
                        ? root.systemTone(
                            priorityAction.secondaryAccentColor,
                            priorityMouse.containsMouse ? 0.24 : 0.17,
                            0.57
                        )
                        : root.systemTone(
                            priorityAction.secondaryAccentColor,
                            priorityMouse.containsMouse ? 0.14 : 0.07,
                            0.47
                        )
                }
            }
            border.width: 1
            border.color: root.alpha(
                priorityAction.active || priorityAction.expandControl
                    ? priorityAction.accentColor
                    : root.inkSoft,
                priorityAction.active || priorityAction.expandControl ? 0.48 : 0.24
            )

            Behavior on scale {
                NumberAnimation {
                    duration: root.systemMotionEnabled ? 110 : 1
                    easing.type: Easing.OutCubic
                }
            }

            Item {
                id: priorityIconMask

                anchors.centerIn: parent
                width: 25
                height: 25
                visible: !priorityAction.expandControl

                VeloraMaterialIcon {
                    id: priorityIconSource

                    anchors.fill: parent
                    visible: false
                    iconName: priorityAction.iconName
                    iconColor: "white"
                    filled: priorityAction.active
                }

                Rectangle {
                    id: priorityIconGradient

                    anchors.fill: parent
                    visible: false
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop {
                            position: 0
                            color: root.pastelTone(
                                priorityAction.secondaryAccentColor,
                                priorityAction.active ? 0.34 : 0.46,
                                1
                            )
                        }
                        GradientStop {
                            position: 1
                            color: root.pastelTone(
                                priorityAction.accentColor,
                                priorityAction.active ? 0.58 : 0.70,
                                1
                            )
                        }
                    }
                }

                OpacityMask {
                    anchors.fill: parent
                    source: priorityIconGradient
                    maskSource: priorityIconSource
                    cached: false
                }
            }

            Item {
                anchors.centerIn: parent
                width: 22
                height: 22
                visible: priorityAction.expandControl

                Rectangle {
                    anchors.centerIn: parent
                    width: 18
                    height: 2
                    radius: 1
                    color: "transparent"
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0
                            color: root.pastelTone(priorityAction.secondaryAccentColor, 0.38, 1)
                        }
                        GradientStop {
                            position: 1
                            color: root.pastelTone(priorityAction.accentColor, 0.68, 1)
                        }
                    }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 2
                    height: 18
                    radius: 1
                    visible: !priorityAction.expanded
                    color: "transparent"
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop {
                            position: 0
                            color: root.pastelTone(priorityAction.secondaryAccentColor, 0.38, 1)
                        }
                        GradientStop {
                            position: 1
                            color: root.pastelTone(priorityAction.accentColor, 0.68, 1)
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: root.systemMotionEnabled ? 120 : 1 }
                    }
                }
            }
        }

        Rectangle {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: prioritySurface.bottom
                topMargin: 4
            }
            width: Math.max(48, priorityTooltipText.implicitWidth + 14)
            height: 24
            radius: 8
            z: 200
            visible: priorityMouse.containsMouse && priorityAction.tooltip.length > 0
            color: root.alpha(root.deepTone(root.surfaceContainerHigh, 0.92), 0.94)
            border.width: 1
            border.color: root.alpha(root.inkSoft, 0.26)

            Text {
                id: priorityTooltipText
                anchors.centerIn: parent
                text: priorityAction.tooltip
                color: root.ink
                font.family: root.uiFont
                font.pixelSize: 9
                font.weight: Font.Medium
            }
        }

        MouseArea {
            id: priorityMouse
            anchors.fill: parent
            enabled: priorityAction.enabledControl
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: priorityAction.triggered()
        }
    }

    component VerticalQuickControl: Rectangle {
        id: verticalControl
        property real value: 0.5
        property string iconName: "sun"
        property color fillColor: root.accent
        property color secondaryFillColor: root.accent3
        signal moved(real value)

        Layout.preferredWidth: 86
        radius: 24
        color: "transparent"
        gradient: Gradient {
            GradientStop { position: 0; color: root.systemTone(root.accent3, 0.05, 0.30) }
            GradientStop { position: 1; color: root.systemTone(root.accent, 0.07, 0.38) }
        }
        border.width: 1
        border.color: root.outlineVariant
        clip: true
        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 4
            radius: 11
            samples: 23
            color: Qt.rgba(0, 0, 0, 0.22)
            transparentBorder: true
        }

        Rectangle {
            id: verticalFill
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: Math.max(46, parent.height * Math.max(0, Math.min(1, verticalControl.value)))
            radius: Math.max(0, verticalControl.radius - 1)
            color: "transparent"
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: root.pastelTone(verticalControl.secondaryFillColor, 0.72, 0.78)
                }
                GradientStop {
                    position: 1
                    color: root.pastelTone(verticalControl.fillColor, 0.56, 0.88)
                }
            }

            Behavior on height {
                enabled: !verticalControlMouse.pressed
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
        }

        Text {
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 11 }
            text: Math.round(verticalControl.value * 100) + "%"
            color: verticalControl.value > 0.78
                ? root.deepTone(verticalControl.fillColor, 0.88)
                : root.inkSoft
            font.family: root.monoFont
            font.pixelSize: 9
            font.weight: Font.Medium
        }

        VeloraMaterialIcon {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 12 }
            width: 25
            height: 25
            visible: verticalControl.iconName !== "sun"
            iconName: verticalControl.iconName
            iconColor: root.deepTone(verticalControl.fillColor, 0.94)
            filled: true
        }

        Item {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 12 }
            width: 25
            height: 25
            visible: verticalControl.iconName === "sun"

            Repeater {
                model: 8
                Item {
                    required property int index
                    anchors.fill: parent
                    rotation: index * 45
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 0
                        width: 2
                        height: 5
                        radius: 1
                        color: root.deepTone(verticalControl.fillColor, 0.94)
                    }
                }
            }
            Rectangle {
                anchors.centerIn: parent
                width: 9
                height: 9
                radius: 4.5
                color: root.deepTone(verticalControl.fillColor, 0.94)
            }
        }

        MouseArea {
            id: verticalControlMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            function apply(mouseY) {
                const inset = 8
                verticalControl.moved(1 - Math.max(0, Math.min(1, (mouseY - inset) / Math.max(1, height - inset * 2))))
            }
            onPressed: function(mouse) { apply(mouse.y) }
            onPositionChanged: function(mouse) { if (pressed) apply(mouse.y) }
        }
    }

    component ControlCenterVisualizer: Rectangle {
        id: visualizer

        readonly property int bandCount: 22
        readonly property bool hasSignal: root.cavaValues && root.cavaValues.length > 0
        property real gradientPhase: 0

        Layout.preferredWidth: 62
        radius: 24
        color: "transparent"
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop {
                position: 0
                color: root.systemTone(root.accent2, visualizer.hasSignal ? 0.19 : 0.10, 0.54)
            }
            GradientStop {
                position: 0.50
                color: root.systemTone(root.accent3, visualizer.hasSignal ? 0.15 : 0.07, 0.46)
            }
            GradientStop {
                position: 1
                color: root.systemTone(root.accent, visualizer.hasSignal ? 0.21 : 0.11, 0.56)
            }
        }
        border.width: 1
        border.color: visualizer.hasSignal
            ? root.alpha(root.accent3, 0.38)
            : root.outlineVariant
        clip: true
        antialiasing: true

        NumberAnimation on gradientPhase {
            from: 0
            to: 1
            duration: 9200
            loops: Animation.Infinite
            running: root.systemMotionEnabled
                && root.open
                && root.popupType === "system"
                && root.systemPage === "settings"
        }

        Canvas {
            id: controlCenterAnimatedGradient

            readonly property color firstTone: root.systemTone(
                root.accent2,
                visualizer.hasSignal ? 0.48 : 0.35,
                1
            )
            readonly property color middleTone: root.systemTone(
                root.accent3,
                visualizer.hasSignal ? 0.42 : 0.30,
                1
            )
            readonly property color lastTone: root.systemTone(
                root.accent,
                visualizer.hasSignal ? 0.50 : 0.36,
                1
            )

            anchors {
                fill: parent
                margins: 1
            }
            antialiasing: true
            opacity: visualizer.hasSignal ? 0.96 : 0.76

            function roundedClip(ctx, radiusValue) {
                const radius = Math.max(0, Math.min(radiusValue, width / 2, height / 2))
                ctx.beginPath()
                ctx.moveTo(radius, 0)
                ctx.lineTo(width - radius, 0)
                ctx.quadraticCurveTo(width, 0, width, radius)
                ctx.lineTo(width, height - radius)
                ctx.quadraticCurveTo(width, height, width - radius, height)
                ctx.lineTo(radius, height)
                ctx.quadraticCurveTo(0, height, 0, height - radius)
                ctx.lineTo(0, radius)
                ctx.quadraticCurveTo(0, 0, radius, 0)
                ctx.closePath()
                ctx.clip()
            }

            onPaint: {
                const ctx = getContext("2d")
                const phase = visualizer.gradientPhase * Math.PI * 2
                const opposite = phase + Math.PI
                const cross = phase + Math.PI * 0.5

                ctx.reset()
                ctx.save()
                roundedClip(ctx, Math.max(0, visualizer.radius - 1))

                const baseGradient = ctx.createLinearGradient(
                    width * (0.5 + 0.78 * Math.cos(phase)),
                    height * (0.5 + 0.62 * Math.sin(phase)),
                    width * (0.5 + 0.78 * Math.cos(opposite)),
                    height * (0.5 + 0.62 * Math.sin(opposite))
                )
                baseGradient.addColorStop(0, root.canvasRgba(firstTone, 1))
                baseGradient.addColorStop(0.48, root.canvasRgba(middleTone, 1))
                baseGradient.addColorStop(1, root.canvasRgba(lastTone, 1))
                ctx.fillStyle = baseGradient
                ctx.fillRect(0, 0, width, height)

                const lightSweep = ctx.createLinearGradient(
                    width * (0.5 + 0.92 * Math.cos(cross)),
                    height * (0.5 + 0.74 * Math.sin(cross)),
                    width * (0.5 + 0.92 * Math.cos(cross + Math.PI)),
                    height * (0.5 + 0.74 * Math.sin(cross + Math.PI))
                )
                lightSweep.addColorStop(0, root.canvasRgba(root.accent, 0))
                lightSweep.addColorStop(0.42, root.canvasRgba(root.accent3, visualizer.hasSignal ? 0.30 : 0.18))
                lightSweep.addColorStop(0.66, root.canvasRgba(root.accent2, visualizer.hasSignal ? 0.22 : 0.13))
                lightSweep.addColorStop(1, root.canvasRgba(root.accent, 0))
                ctx.fillStyle = lightSweep
                ctx.fillRect(0, 0, width, height)
                ctx.restore()
            }

            onFirstToneChanged: requestPaint()
            onMiddleToneChanged: requestPaint()
            onLastToneChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Component.onCompleted: requestPaint()

            Connections {
                target: visualizer
                function onGradientPhaseChanged() {
                    controlCenterAnimatedGradient.requestPaint()
                }
            }
        }

        Rectangle {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                bottom: parent.bottom
                topMargin: 13
                bottomMargin: 13
            }
            width: 2
            radius: 1
            color: root.alpha(root.ink, visualizer.hasSignal ? 0.14 : 0.08)
        }

        Column {
            id: controlCenterVisualizerBands

            anchors {
                fill: parent
                leftMargin: 8
                rightMargin: 8
                topMargin: 10
                bottomMargin: 10
            }
            spacing: 2

            Repeater {
                model: visualizer.bandCount

                Item {
                    required property int index

                    width: controlCenterVisualizerBands.width
                    height: Math.max(3, (controlCenterVisualizerBands.height
                        - controlCenterVisualizerBands.spacing * (visualizer.bandCount - 1))
                        / visualizer.bandCount)

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.max(7, Math.round(parent.width
                            * root.controlCenterVisualizerValue(index, visualizer.bandCount)))
                        height: Math.max(2, Math.min(4, parent.height))
                        radius: height / 2
                        color: root.controlCenterVisualizerColor(
                            index,
                            visualizer.bandCount,
                            visualizer.hasSignal ? 0.96 : 0.50
                        )

                        Behavior on width {
                            enabled: root.systemMotionEnabled
                            NumberAnimation {
                                duration: 72
                                easing.type: Easing.OutCubic
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
            height: 28
            radius: Math.max(0, parent.radius - 1)
            color: root.alpha(root.ink, visualizer.hasSignal ? 0.035 : 0.02)
        }
    }

    component DenseQuickAction: Item {
        id: denseAction
        property string iconName: "settings"
        property string label: "Ação"
        property bool active: false
        property bool enabledControl: true
        signal triggered()

        Layout.preferredHeight: 48
        opacity: enabledControl ? 1 : 0.36
        scale: denseActionMouse.pressed ? 0.97 : 1

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 3
                rightMargin: 4
                topMargin: 4
                bottomMargin: 4
            }
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 19
                color: "transparent"
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0
                        color: denseAction.active
                            ? root.pastelTone(root.accent, 0.46, 0.91)
                            : root.systemTone(
                                root.accent,
                                denseActionMouse.containsMouse ? 0.19 : 0.11,
                                denseActionMouse.containsMouse ? 0.62 : 0.52
                            )
                    }
                    GradientStop {
                        position: 1
                        color: denseAction.active
                            ? root.pastelTone(root.accent2, 0.56, 0.89)
                            : root.systemTone(
                                root.accent2,
                                denseActionMouse.containsMouse ? 0.14 : 0.07,
                                denseActionMouse.containsMouse ? 0.60 : 0.50
                            )
                    }
                }
                border.width: 1
                border.color: denseAction.active
                    ? root.alpha(root.onPrimaryContainer, 0.32)
                    : root.outlineVariant

                VeloraMaterialIcon {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    iconName: denseAction.iconName
                    iconColor: denseAction.active
                        ? root.deepTone(root.accent, 0.94)
                        : root.ink
                    filled: denseAction.active
                }
            }

            Text {
                Layout.fillWidth: true
                text: denseAction.label
                color: root.ink
                font.family: root.uiFont
                font.pixelSize: 10
                font.weight: Font.Medium
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                style: Text.Outline
                styleColor: Qt.rgba(0.015, 0.018, 0.020, 0.72)
            }
        }

        MouseArea {
            id: denseActionMouse
            anchors.fill: parent
            enabled: denseAction.enabledControl
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: denseAction.triggered()
        }
    }

    component RightQuickAction: Item {
        id: rightAction
        property string iconName: "settings"
        property string label: "Ação"
        property bool active: false
        property bool enabledControl: true
        property color accentColor: root.accent
        property color secondaryAccentColor: root.accent2
        signal triggered()

        implicitHeight: 76
        Layout.preferredHeight: 76

        opacity: enabledControl ? 1 : 0.36
        scale: rightActionMouse.pressed ? 0.96 : 1

        Behavior on scale {
            NumberAnimation { duration: root.systemMotionEnabled ? 90 : 1; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 5
            width: 42
            height: 42
            radius: 21
            color: "transparent"
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0
                    color: rightAction.active
                        ? root.pastelTone(rightAction.accentColor, 0.44, 0.90)
                        : root.systemTone(rightAction.accentColor, rightActionMouse.containsMouse ? 0.19 : 0.12, 0.54)
                }
                GradientStop {
                    position: 1
                    color: rightAction.active
                        ? root.pastelTone(rightAction.secondaryAccentColor, 0.54, 0.88)
                        : root.systemTone(rightAction.secondaryAccentColor, rightActionMouse.containsMouse ? 0.14 : 0.08, 0.50)
                }
            }
            border.width: 1
            border.color: rightAction.active ? root.alpha(rightAction.accentColor, 0.60) : root.alpha(rightAction.accentColor, 0.34)

            VeloraMaterialIcon {
                anchors.centerIn: parent
                width: 22
                height: 22
                iconName: rightAction.iconName
                iconColor: rightAction.active
                    ? root.deepTone(rightAction.accentColor, 0.94)
                    : root.pastelTone(rightAction.accentColor, 0.16, 1)
                filled: rightAction.active
            }
        }

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 52
            text: rightAction.label
            color: rightAction.active ? root.ink : root.inkSoft
            font.family: root.uiFont
            font.pixelSize: 9
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignTop
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        MouseArea {
            id: rightActionMouse
            anchors.fill: parent
            enabled: rightAction.enabledControl
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: rightAction.triggered()
        }
    }

    component RightClockCard: Item {
        id: clockCard
        signal triggered()

        implicitHeight: 68
        Layout.preferredHeight: 68
        scale: clockMouse.pressed ? 0.985 : 1

        Behavior on scale {
            NumberAnimation {
                duration: root.systemMotionEnabled ? 90 : 1
                easing.type: Easing.OutCubic
            }
        }

        DropShadow {
            anchors.fill: clockSurface
            source: clockSurface
            horizontalOffset: 0
            verticalOffset: 4
            radius: 13
            samples: 27
            color: Qt.rgba(0, 0, 0, clockMouse.containsMouse ? 0.30 : 0.24)
            transparentBorder: true
        }

        Rectangle {
            id: clockSurface

            anchors.fill: parent
            radius: 20
            clip: true
            color: "transparent"
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                    position: 0
                    color: root.systemTone(
                        root.accent3,
                        clockMouse.containsMouse ? 0.13 : 0.08,
                        0.42
                    )
                }
                GradientStop {
                    position: 1
                    color: root.systemTone(
                        root.accent2,
                        clockMouse.containsMouse ? 0.09 : 0.045,
                        0.34
                    )
                }
            }
            border.width: 1
            border.color: root.alpha(root.accent3, clockMouse.containsMouse ? 0.42 : 0.30)

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
                radius: 0.5
                color: root.alpha(root.ink, clockMouse.containsMouse ? 0.11 : 0.065)
            }
        }

        Column {
            anchors.centerIn: parent
            width: parent.width - 18
            spacing: 0

            Text {
                width: parent.width
                text: root.controlCenterClockText()
                color: root.ink
                font.family: root.uiFont
                font.pixelSize: 29
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                width: parent.width
                text: root.controlCenterDateText()
                color: root.inkSoft
                font.family: root.uiFont
                font.pixelSize: 9
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: clockMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: clockCard.triggered()
        }
    }

    component RightBatteryCard: Item {
        id: batteryCard
        signal triggered()

        implicitHeight: 88
        Layout.preferredHeight: 88
        scale: batteryMouse.pressed ? 0.985 : 1

        Behavior on scale {
            NumberAnimation {
                duration: root.systemMotionEnabled ? 90 : 1
                easing.type: Easing.OutCubic
            }
        }

        DropShadow {
            anchors.fill: batterySurface
            source: batterySurface
            horizontalOffset: 0
            verticalOffset: 4
            radius: 13
            samples: 27
            color: Qt.rgba(0, 0, 0, batteryMouse.containsMouse ? 0.30 : 0.24)
            transparentBorder: true
        }

        Rectangle {
            id: batterySurface

            anchors.fill: parent
            radius: 22
            clip: true
            color: "transparent"
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0
                    color: root.systemTone(
                        root.accent2,
                        batteryMouse.containsMouse ? 0.17 : 0.11,
                        0.56
                    )
                }
                GradientStop {
                    position: 1
                    color: root.systemTone(
                        root.accent,
                        batteryMouse.containsMouse ? 0.14 : 0.08,
                        0.50
                    )
                }
            }
            border.width: 1
            border.color: root.alpha(
                root.accent2,
                root.batteryAcOnline
                    ? (batteryMouse.containsMouse ? 0.58 : 0.48)
                    : (batteryMouse.containsMouse ? 0.42 : 0.30)
            )

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
                radius: 0.5
                color: root.alpha(root.ink, batteryMouse.containsMouse ? 0.11 : 0.065)
            }
        }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 12
                rightMargin: 12
            }
            spacing: 11

            Rectangle {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                radius: 21
                color: "transparent"
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: root.systemTone(root.accent2, 0.28, 0.62) }
                    GradientStop { position: 1; color: root.systemTone(root.accent, 0.18, 0.54) }
                }
                border.width: 1
                border.color: root.alpha(root.accent2, 0.42)

                VeloraMaterialIcon {
                    anchors.centerIn: parent
                    width: 27
                    height: 27
                    iconName: "battery"
                    iconColor: root.pastelTone(root.accent2, 0.12, 1)
                    filled: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: "Bateria"
                    color: root.ink
                    font.family: root.uiFont
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: Math.round(root.batteryPercent * 100) + "% restante"
                    color: root.pastelTone(root.accent2, 0.12, 1)
                    font.family: root.uiFont
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            id: batteryMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: batteryCard.triggered()
        }
    }

    component MiniButton: Rectangle {
        id: mini
        property string label: "Ação"
        property bool active: false
        property bool enabledControl: true
        signal triggered()

        radius: Math.round(height / 2)
        opacity: enabledControl ? 1 : 0.38
        color: active ? root.primaryContainer : (miniMouse.containsMouse ? root.surfaceContainerHigh : root.surfaceContainer)
        border.width: 1
        border.color: active ? root.alpha(root.accent, 0.54) : root.outlineVariant

        Text {
            anchors.centerIn: parent
            text: mini.label
            color: mini.active ? root.accent : root.ink
            font.family: root.uiFont
            font.pixelSize: 11
            font.weight: Font.Medium
        }

        MouseArea {
            id: miniMouse
            anchors.fill: parent
            enabled: mini.enabledControl
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mini.triggered()
        }
    }

    component MaterialInfoRow: Rectangle {
        id: infoRow
        property string iconName: "help"
        property string title: "Item"
        property string subtitle: ""
        property string value: ""
        property bool active: false
        property bool clickable: true
        signal triggered()

        Layout.fillWidth: true
        Layout.preferredHeight: 58
        radius: 18
        color: active ? root.primaryContainer : (infoMouse.containsMouse ? root.surfaceContainerHigh : root.surfaceContainer)
        border.width: 1
        border.color: active ? root.alpha(root.accent, 0.48) : root.outlineVariant

        RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: infoRow.active ? root.alpha(root.accent, 0.24) : root.alpha(root.inkSoft, 0.10)
                VeloraMaterialIcon {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    iconName: infoRow.iconName
                    iconColor: infoRow.active ? root.onPrimaryContainer : root.inkSoft
                    filled: infoRow.active
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text { Layout.fillWidth: true; text: infoRow.title; color: root.ink; font.family: root.uiFont; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight }
                Text { Layout.fillWidth: true; visible: infoRow.subtitle.length > 0; text: infoRow.subtitle; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 10; elide: Text.ElideRight }
            }

            Text { text: infoRow.value; color: infoRow.active ? root.onPrimaryContainer : root.inkSoft; font.family: root.monoFont; font.pixelSize: 12; font.weight: Font.Medium }
        }

        MouseArea { id: infoMouse; anchors.fill: parent; enabled: infoRow.clickable; hoverEnabled: infoRow.clickable; cursorShape: infoRow.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: infoRow.triggered() }
    }

    component SystemPageIndicator: Item {
        id: pageIndicator

        implicitWidth: indicatorRow.implicitWidth
        implicitHeight: 24

        Row {
            id: indicatorRow
            anchors.centerIn: parent
            spacing: 4

            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: previousPageMouse.containsMouse
                    ? root.alpha(root.accent, 0.20)
                    : root.alpha(root.inkSoft, 0.08)
                border.width: 1
                border.color: root.alpha(
                    previousPageMouse.containsMouse
                        ? root.accent
                        : root.inkSoft,
                    previousPageMouse.containsMouse ? 0.52 : 0.20
                )

                VeloraMaterialIcon {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    iconName: "chevron_left"
                    iconColor: previousPageMouse.containsMouse
                        ? root.accent
                        : root.inkSoft
                }

                MouseArea {
                    id: previousPageMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.systemPageStepRequested(-1)
                }
            }

            Repeater {
                model: root.rightControlCenterMode ? root.systemDetailPages : root.systemPages

                Item {
                    required property string modelData
                    readonly property bool active: root.systemPage === modelData
                    width: active ? 34 : 14
                    height: 24

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.active ? 30 : 6
                        height: 6
                        radius: height / 2
                        color: parent.active
                            ? root.pastelTone(root.accent, 0.42, 0.88)
                            : root.alpha(root.inkSoft, indicatorMouse.containsMouse ? 0.72 : 0.36)

                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: indicatorMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (parent.modelData !== root.systemPage)
                                root.systemPageRequested(parent.modelData)
                        }
                    }
                }
            }

            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: nextPageMouse.containsMouse
                    ? root.alpha(root.accent, 0.20)
                    : root.alpha(root.inkSoft, 0.08)
                border.width: 1
                border.color: root.alpha(
                    nextPageMouse.containsMouse
                        ? root.accent
                        : root.inkSoft,
                    nextPageMouse.containsMouse ? 0.52 : 0.20
                )

                VeloraMaterialIcon {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    iconName: "chevron_right"
                    iconColor: nextPageMouse.containsMouse
                        ? root.accent
                        : root.inkSoft
                }

                MouseArea {
                    id: nextPageMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.systemPageStepRequested(1)
                }
            }
        }
    }

    Component {
        id: originalQuickSettingsView

        VeloraSidePopup {
            theme: root.theme
            popupType: "quickSettings"
            systemNavigationInset: true
            open: root.open && root.popupType === "system" && root.systemPage === "settings"
            externalSurface: true
            lineReveal: false
            revealProgressOverride: 1
            entryProgressOverride: root.systemIncomingPage === "settings" ? root.systemTransitionProgress : -1
            interactiveFocus: root.interactiveFocus
            attachSide: "bottom"
            notificationsModelOverride: root.notificationsModelOverride
            onCloseRequested: root.closeRequested()
            onAdvancedSettingsRequested: root.advancedSettingsRequested()
            onPopupRequested: function(type) {
                if (root.systemPages.indexOf(type) >= 0)
                    root.systemPageRequested(type)
                else
                    root.popupRequested(type)
            }
        }
    }

    Component {
        id: originalVolumeView

        VeloraSidePopup {
            theme: root.theme
            popupType: "volume"
            open: root.open && root.effectiveType === "volume"
            externalSurface: true
            lineReveal: false
            revealProgressOverride: 1
            interactiveFocus: root.interactiveFocus
            attachSide: "right"
            onCloseRequested: root.closeRequested()
            onPopupRequested: function(type) { root.systemPageRequested(type) }
        }
    }

    Component {
        id: originalWifiView

        VeloraSidePopup {
            theme: root.theme
            popupType: "wifi"
            systemNavigationInset: true
            open: root.open && root.effectiveType === "wifi"
            externalSurface: true
            lineReveal: false
            revealProgressOverride: 1
            entryProgressOverride: root.systemIncomingPage === "wifi" ? root.systemTransitionProgress : -1
            interactiveFocus: root.interactiveFocus
            attachSide: "right"
            onCloseRequested: root.closeRequested()
            onPopupRequested: function(type) { root.systemPageRequested(type) }
        }
    }

    component SystemPageLayer: Item {
        id: pageLayer

        property string pageKey: "settings"
        property var pageSource: null
        readonly property bool incoming: root.systemIncomingPage === pageKey
        readonly property bool outgoing: root.systemOutgoingPage === pageKey
        readonly property real directionalOffset: incoming
            ? root.systemIncomingOffset()
            : root.systemOutgoingOffset()

        width: root.systemWidthForPage(pageKey)
        height: root.systemHeightForPage(pageKey)
        x: Math.round((parent.width - width) / 2 + directionalOffset)
        y: root.rightControlCenterMode && pageKey === "settings"
            ? Math.round((parent.height - height) / 2)
            : Math.round(parent.height - height)
        z: incoming ? 2 : 1
        visible: incoming || outgoing
        enabled: incoming && (!root.systemTransitionRunning || root.systemTransitionProgress >= 0.25)
        opacity: incoming ? root.systemIncomingOpacity() : root.systemOutgoingOpacity()
        scale: incoming ? root.systemIncomingScale() : root.systemOutgoingScale()
        transformOrigin: Item.Bottom

        Loader {
            anchors.fill: parent
            asynchronous: false
            sourceComponent: pageLayer.pageSource
        }
    }

    Component {
        id: systemView

        Item {
            // The logical popup adopts the final geometry immediately. This visual
            // viewport keeps the previous bottom-aligned size long enough to morph
            // it smoothly, while its own clip reveals the larger page without a
            // hard cut and contains the outgoing page while shrinking.
            Item {
                id: systemTransitionViewport

                width: root.effectiveSystemVisualWidth
                height: root.effectiveSystemVisualHeight
                x: Math.round((parent.width - width) / 2)
                y: root.rightControlCenter
                    ? Math.round((parent.height - height) / 2)
                    : Math.round(parent.height - height)
                clip: true

                SystemPageLayer { pageKey: "settings"; pageSource: root.rightControlCenterMode ? rightSettingsView : bottomSettingsView }
                SystemPageLayer { pageKey: "wallpaper"; pageSource: wallpaperView }
                SystemPageLayer { pageKey: "volume"; pageSource: volumeView }
                SystemPageLayer { pageKey: "wifi"; pageSource: wifiView }
                SystemPageLayer { pageKey: "display"; pageSource: brightnessView }
                SystemPageLayer { pageKey: "notifications"; pageSource: notificationsView }
                SystemPageLayer { pageKey: "bluetooth"; pageSource: bluetoothView }
                SystemPageLayer { pageKey: "battery"; pageSource: batteryView }

                SystemPageIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    z: 20
                    visible: !root.rightControlCenter
                }
            }
        }
    }

    Component {
        id: timeView

        Item {
            ColumnLayout {
                anchors { fill: parent; margins: 20 }
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 78
                    radius: 24
                    color: root.primaryContainer
                    border.width: 1
                    border.color: root.alpha(root.accent, 0.38)
                    RowLayout {
                        anchors { fill: parent; margins: 14 }
                        Rectangle { Layout.preferredWidth: 48; Layout.preferredHeight: 48; radius: 24; color: root.alpha(root.accent, 0.24); VeloraMaterialIcon { anchors.centerIn: parent; width: 28; height: 28; iconName: "calendar"; iconColor: root.onPrimaryContainer; filled: true } }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text { Layout.fillWidth: true; text: Qt.formatDate(root.now, "dddd, d 'de' MMMM"); color: root.onPrimaryContainer; font.family: root.uiFont; font.pixelSize: 15; font.weight: Font.DemiBold; elide: Text.ElideRight }
                            Text { text: Qt.formatTime(root.now, "HH:mm"); color: root.onPrimaryContainer; font.family: root.monoFont; font.pixelSize: 24; font.weight: Font.Bold }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: 19
                    color: root.surfaceContainer
                    border.width: 1
                    border.color: root.line

                    RowLayout {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        MiniButton { Layout.preferredWidth: 28; Layout.preferredHeight: 26; label: "‹"; onTriggered: { root.calendarMonthOffset -= 1; root.rebuildCalendar() } }
                        Text { Layout.fillWidth: true; text: root.calendarTitle(); color: root.ink; font.family: root.uiFont; font.pixelSize: 11; font.weight: Font.Medium; horizontalAlignment: Text.AlignHCenter }
                        MiniButton { Layout.preferredWidth: 28; Layout.preferredHeight: 26; label: "›"; onTriggered: { root.calendarMonthOffset += 1; root.rebuildCalendar() } }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    columnSpacing: 2
                    rowSpacing: 2
                    Repeater {
                        model: ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"]
                        Text {
                            required property string modelData
                            Layout.fillWidth: true
                            text: modelData
                            color: root.inkSoft
                            font.family: root.uiFont
                            font.pixelSize: 8
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 210
                    columns: 7
                    columnSpacing: 2
                    rowSpacing: 2
                    Repeater {
                        model: root.calendarCells
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: height / 2
                            color: modelData.today ? root.alpha(root.accent, 0.52) : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData.day
                                color: parent.modelData.today ? root.ink : (parent.modelData.inMonth ? root.ink : root.alpha(root.inkSoft, 0.35))
                                font.family: root.monoFont
                                font.pixelSize: 10
                                font.weight: parent.modelData.today ? Font.DemiBold : Font.Normal
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 76
                    spacing: 8
                    Repeater {
                        model: root.worldClockItems
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 20
                            color: root.surfaceContainer
                            border.width: 1
                            border.color: root.line
                            ColumnLayout {
                                anchors { fill: parent; margins: 10 }
                                spacing: 1
                                Text { Layout.fillWidth: true; text: parent.parent.modelData.label || parent.parent.modelData.zone; color: root.ink; font.family: root.uiFont; font.pixelSize: 10; elide: Text.ElideRight }
                                Text { Layout.fillWidth: true; text: parent.parent.modelData.offset || parent.parent.modelData.zone; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 8; elide: Text.ElideRight }
                                Text { Layout.fillWidth: true; text: parent.parent.modelData.time || "--:--"; color: root.ink; font.family: root.monoFont; font.pixelSize: 17; font.weight: Font.DemiBold }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: wallpaperView

        VeloraControlCenterWallpaper {
            theme: root.theme
            entries: root.wallpaperEntries
            activeKey: root.wallpaperActiveKey
            applying: root.wallpaperApplying
            errorMessage: root.wallpaperErrorMessage
            sessionSerial: root.wallpaperSessionSerial
            onApplyRequested: function(entry) {
                root.wallpaperApplyRequested(entry)
            }
            onLibraryRequested: function(refresh) {
                root.wallpaperLibraryRequested(refresh)
            }
        }
    }

    Component {
        id: volumeView

        Item {
            ColumnLayout {
                anchors {
                    fill: parent
                    leftMargin: 24
                    rightMargin: 24
                    topMargin: 18
                    bottomMargin: 32
                }
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 136
                    opacity: root.systemPageElementProgress("volume", 0)
                    scale: root.systemPageElementScale("volume", 0)
                    transform: Translate { y: root.systemPageElementOffset("volume", 0, 10) }
                    radius: 26
                    color: root.surfaceContainer
                    border.width: 1
                    border.color: root.outlineVariant
                    ColumnLayout {
                        anchors { fill: parent; margins: 16 }
                        RowLayout {
                            Layout.fillWidth: true
                            Rectangle { Layout.preferredWidth: 42; Layout.preferredHeight: 42; radius: 21; color: root.muted ? root.alpha(root.accent2, 0.20) : root.primaryContainer; VeloraMaterialIcon { anchors.centerIn: parent; width: 24; height: 24; iconName: root.muted ? "volume-muted" : "volume"; iconColor: root.muted ? root.accent2 : root.onPrimaryContainer; filled: !root.muted } }
                            ColumnLayout { Layout.fillWidth: true; spacing: 1; Text { text: root.muted ? "Saída silenciada" : "Volume de mídia"; color: root.ink; font.family: root.uiFont; font.pixelSize: 15; font.weight: Font.DemiBold } Text { Layout.fillWidth: true; text: root.audioOutputName; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 11; elide: Text.ElideRight } }
                            Item { Layout.fillWidth: true }
                            MiniButton { Layout.preferredWidth: 82; Layout.preferredHeight: 36; label: root.muted ? "Ativar" : "Silenciar"; active: root.muted; onTriggered: root.toggleMute() }
                        }
                        CompactSlider { Layout.fillWidth: true; Layout.preferredHeight: 56; label: "Saída"; iconName: root.muted ? "volume-muted" : "volume"; detail: Math.round(root.volumePercent * 100) + "%"; value: root.volumePercent; onMoved: function(value) { root.setVolume(value) } }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 136
                    opacity: root.systemPageElementProgress("volume", 1)
                    scale: root.systemPageElementScale("volume", 1)
                    transform: Translate { y: root.systemPageElementOffset("volume", 1, 10) }
                    radius: 26
                    color: root.surfaceContainer
                    border.width: 1
                    border.color: root.outlineVariant
                    ColumnLayout {
                        anchors { fill: parent; margins: 16 }
                        RowLayout {
                            Layout.fillWidth: true
                            Rectangle { Layout.preferredWidth: 42; Layout.preferredHeight: 42; radius: 21; color: root.micMuted ? root.alpha(root.accent2, 0.20) : root.primaryContainer; VeloraMaterialIcon { anchors.centerIn: parent; width: 24; height: 24; iconName: root.micMuted ? "mic-muted" : "mic"; iconColor: root.micMuted ? root.accent2 : root.onPrimaryContainer; filled: !root.micMuted } }
                            ColumnLayout { Layout.fillWidth: true; spacing: 1; Text { text: root.micMuted ? "Microfone silenciado" : "Microfone"; color: root.ink; font.family: root.uiFont; font.pixelSize: 15; font.weight: Font.DemiBold } Text { Layout.fillWidth: true; text: root.audioInputName; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 11; elide: Text.ElideRight } }
                            Item { Layout.fillWidth: true }
                            MiniButton { Layout.preferredWidth: 82; Layout.preferredHeight: 36; label: root.micMuted ? "Ativar" : "Silenciar"; active: root.micMuted; onTriggered: root.toggleMicMute() }
                        }
                        CompactSlider { Layout.fillWidth: true; Layout.preferredHeight: 56; label: "Entrada"; iconName: root.micMuted ? "mic-muted" : "mic"; detail: Math.round(root.micVolumePercent * 100) + "%"; value: root.micVolumePercent; fillColor: root.accent2; onMoved: function(value) { root.setMicVolume(value) } }
                    }
                }

                MaterialInfoRow {
                    iconName: "speaker"
                    title: "Dispositivo de saída"
                    subtitle: root.audioOutputName
                    value: audioSinks.count > 1 ? "Trocar" : "Padrão"
                    clickable: audioSinks.count > 1
                    opacity: root.systemPageElementProgress("volume", 2)
                    scale: root.systemPageElementScale("volume", 2)
                    transform: Translate { y: root.systemPageElementOffset("volume", 2, 9) }
                    onTriggered: root.cycleAudioDevice("sink")
                }

                MaterialInfoRow {
                    iconName: "mic"
                    title: "Dispositivo de entrada"
                    subtitle: root.audioInputName
                    value: audioSources.count > 1 ? "Trocar" : "Padrão"
                    clickable: audioSources.count > 1
                    opacity: root.systemPageElementProgress("volume", 3)
                    scale: root.systemPageElementScale("volume", 3)
                    transform: Translate { y: root.systemPageElementOffset("volume", 3, 8) }
                    onTriggered: root.cycleAudioDevice("source")
                }

                Text {
                    visible: root.audioDeviceError.length > 0
                    Layout.fillWidth: true
                    text: root.audioDeviceError
                    color: root.accent2
                    font.family: root.uiFont
                    font.pixelSize: 10
                }
            }
        }
    }

    Component {
        id: wifiView

        Item {
            anchors.fill: parent

            ColumnLayout {
                anchors { fill: parent; leftMargin: 18; rightMargin: 18; topMargin: 18; bottomMargin: 30 }
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text { text: "Wi‑Fi"; color: root.ink; font.family: root.uiFont; font.pixelSize: 20; font.weight: Font.DemiBold }
                        Text { text: root.wifiPendingAction.length > 0 ? root.wifiPendingAction : (root.wifiEnabled ? "Redes e internet" : "Desativado"); color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 10 }
                    }
                    MiniButton {
                        Layout.preferredWidth: 78
                        Layout.preferredHeight: 34
                        label: root.wifiEnabled ? "Ligado" : "Desligado"
                        active: root.wifiEnabled
                        onTriggered: root.toggleWifi()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 74
                    radius: 22
                    color: root.wifiSsid.length > 0 ? root.primaryContainer : root.surfaceContainer
                    border.width: 1
                    border.color: root.wifiSsid.length > 0 ? root.alpha(root.accent, 0.52) : root.outlineVariant
                    RowLayout {
                        anchors { fill: parent; margins: 12 }
                        spacing: 10
                        Rectangle {
                            Layout.preferredWidth: 42
                            Layout.preferredHeight: 42
                            radius: 21
                            color: root.alpha(root.accent, 0.20)
                            VeloraMaterialIcon { anchors.centerIn: parent; width: 25; height: 25; iconName: "wifi"; iconColor: root.accent; filled: root.wifiSsid.length > 0 }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { Layout.fillWidth: true; text: root.wifiSsid.length > 0 ? root.wifiSsid : "Nenhuma rede conectada"; color: root.ink; font.family: root.uiFont; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight }
                            Text { Layout.fillWidth: true; text: root.wifiIp.length > 0 ? root.wifiIp : root.wifiState; color: root.inkSoft; font.family: root.monoFont; font.pixelSize: 9; elide: Text.ElideRight }
                        }
                        MiniButton {
                            visible: root.wifiSsid.length > 0
                            Layout.preferredWidth: 90
                            Layout.preferredHeight: 34
                            label: "Desconectar"
                            onTriggered: root.disconnectWifi()
                        }
                    }
                }

                Rectangle {
                    visible: root.wifiSelectedSecure
                        && !root.wifiSelectedEnterprise
                        && !root.wifiHiddenForm
                        && root.wifiSelectedSsid.length > 0
                        && root.wifiSelectedUuid.length <= 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? 112 : 0
                    radius: 22
                    color: root.surfaceContainerHigh
                    border.width: 1
                    border.color: root.alpha(root.accent, 0.46)
                    ColumnLayout {
                        anchors { fill: parent; margins: 12 }
                        spacing: 7
                        Text { Layout.fillWidth: true; text: "Senha de " + root.wifiSelectedSsid; color: root.ink; font.family: root.uiFont; font.pixelSize: 12; font.weight: Font.DemiBold; elide: Text.ElideRight }
                        RowLayout {
                            Layout.fillWidth: true
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 38
                                radius: 16
                                color: root.alpha(root.inkSoft, 0.10)
                                TextInput {
                                    id: wifiPasswordInput
                                    anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: root.wifiPassword
                                    echoMode: root.wifiPasswordVisible ? TextInput.Normal : TextInput.Password
                                    color: root.ink
                                    font.family: root.uiFont
                                    font.pixelSize: 12
                                    selectByMouse: true
                                    onTextEdited: root.wifiPassword = text
                                    Keys.onReturnPressed: root.submitWifiPassword()
                                }
                            }
                            MiniButton { Layout.preferredWidth: 70; Layout.preferredHeight: 38; label: root.wifiPasswordVisible ? "Ocultar" : "Mostrar"; onTriggered: root.wifiPasswordVisible = !root.wifiPasswordVisible }
                            MiniButton { Layout.preferredWidth: 80; Layout.preferredHeight: 38; label: "Conectar"; active: true; enabledControl: !networkSecretAction.running; onTriggered: root.submitWifiPassword() }
                        }
                    }
                }

                RowLayout {
                    visible: root.wifiError.length > 0
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        text: root.wifiError
                        color: root.accent2
                        font.family: root.uiFont
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                    }
                    MiniButton {
                        visible: root.wifiSelectedEnterprise
                        Layout.preferredWidth: 96
                        Layout.preferredHeight: 34
                        label: "Avançado"
                        active: true
                        onTriggered: root.openAdvancedNetworkSettings()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { Layout.fillWidth: true; text: "Redes disponíveis"; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 11; font.weight: Font.DemiBold }
                    MiniButton {
                        Layout.preferredWidth: 110
                        Layout.preferredHeight: 34
                        label: root.wifiHiddenForm ? "Cancelar" : "Rede oculta"
                        onTriggered: {
                            root.wifiHiddenForm = !root.wifiHiddenForm
                            root.wifiSelectedSsid = ""
                            root.wifiSelectedUuid = ""
                            root.wifiSelectedSecure = true
                            root.wifiSelectedEnterprise = false
                            root.wifiHiddenSsid = ""
                            root.wifiPassword = ""
                            root.wifiError = ""
                        }
                    }
                }

                Rectangle {
                    visible: root.wifiHiddenForm
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? 132 : 0
                    radius: 22
                    color: root.surfaceContainerHigh
                    ColumnLayout {
                        anchors { fill: parent; margins: 14 }
                        spacing: 8
                        Text {
                            Layout.fillWidth: true
                            text: "Conectar a uma rede oculta"
                            color: root.ink
                            font.family: root.uiFont
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: 16
                            color: root.alpha(root.inkSoft, 0.10)
                            TextInput {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                verticalAlignment: TextInput.AlignVCenter
                                text: root.wifiHiddenSsid
                                color: root.ink
                                font.family: root.uiFont
                                font.pixelSize: 11
                                selectByMouse: true
                                onTextEdited: {
                                    root.wifiHiddenSsid = text
                                    root.wifiSelectedSsid = text
                                }
                                Text { anchors.fill: parent; visible: parent.text.length <= 0; text: "Nome da rede"; color: root.alpha(root.inkSoft, 0.58); font: parent.font; verticalAlignment: Text.AlignVCenter }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 38
                                radius: 16
                                color: root.alpha(root.inkSoft, 0.10)
                                TextInput {
                                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: root.wifiPassword
                                    echoMode: root.wifiPasswordVisible ? TextInput.Normal : TextInput.Password
                                    color: root.ink
                                    font.family: root.uiFont
                                    font.pixelSize: 11
                                    selectByMouse: true
                                    onTextEdited: root.wifiPassword = text
                                    Keys.onReturnPressed: root.submitWifiPassword()
                                    Text { anchors.fill: parent; visible: parent.text.length <= 0; text: "Senha"; color: root.alpha(root.inkSoft, 0.58); font: parent.font; verticalAlignment: Text.AlignVCenter }
                                }
                            }
                            MiniButton { Layout.preferredWidth: 72; Layout.preferredHeight: 38; label: root.wifiPasswordVisible ? "Ocultar" : "Mostrar"; onTriggered: root.wifiPasswordVisible = !root.wifiPasswordVisible }
                            MiniButton { Layout.preferredWidth: 82; Layout.preferredHeight: 38; label: "Conectar"; active: true; enabledControl: !networkSecretAction.running; onTriggered: root.submitWifiPassword() }
                        }
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: wifiNetworkColumn.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: wifiNetworkColumn
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: Math.min(6, wifiNetworks.count)

                            Rectangle {
                                id: wifiNetworkRow
                                required property int index
                                readonly property var network: wifiNetworks.get(index)
                                readonly property bool confirmForget: network.saved && root.wifiForgetConfirmUuid === network.uuid
                                width: wifiNetworkColumn.width
                                height: confirmForget ? 86 : 52
                                radius: 18
                                color: network.active ? root.primaryContainer : (wifiMouse.containsMouse ? root.surfaceContainerHigh : root.surfaceContainer)
                                border.width: 1
                                border.color: network.active ? root.alpha(root.accent, 0.50) : root.outlineVariant

                                RowLayout {
                                    z: 1
                                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                                    height: 36
                                    VeloraMaterialIcon {
                                        Layout.preferredWidth: 22
                                        Layout.preferredHeight: 22
                                        iconName: "wifi"
                                        iconColor: wifiNetworkRow.network.active ? root.accent : root.inkSoft
                                        filled: wifiNetworkRow.network.active
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        Text {
                                            Layout.fillWidth: true
                                            text: wifiNetworkRow.network.ssid
                                            color: root.ink
                                            font.family: root.uiFont
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: (wifiNetworkRow.network.saved ? "Salva · " : "")
                                                + (wifiNetworkRow.network.secure
                                                    ? (wifiNetworkRow.network.security.length > 0 ? wifiNetworkRow.network.security : "Protegida")
                                                    : "Aberta")
                                                + " · "
                                                + Math.max(0, Math.min(100, wifiNetworkRow.network.signal))
                                                + "%"
                                            color: root.inkSoft
                                            font.family: root.uiFont
                                            font.pixelSize: 9
                                            elide: Text.ElideRight
                                        }
                                    }
                                    MiniButton {
                                        visible: wifiNetworkRow.network.saved
                                        Layout.preferredWidth: 74
                                        Layout.preferredHeight: 30
                                        label: "Esquecer"
                                        onTriggered: root.wifiForgetConfirmUuid = wifiNetworkRow.network.uuid
                                    }
                                }

                                RowLayout {
                                    z: 3
                                    visible: wifiNetworkRow.confirmForget
                                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 12; rightMargin: 12; bottomMargin: 8 }
                                    Text { Layout.fillWidth: true; text: "Remover esta rede salva?"; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 10 }
                                    MiniButton { Layout.preferredWidth: 72; Layout.preferredHeight: 30; label: "Cancelar"; onTriggered: root.wifiForgetConfirmUuid = "" }
                                    MiniButton { Layout.preferredWidth: 72; Layout.preferredHeight: 30; label: "Remover"; active: true; onTriggered: { root.forgetWifi(wifiNetworkRow.network.uuid); root.wifiForgetConfirmUuid = "" } }
                                }

                                MouseArea {
                                    id: wifiMouse
                                    anchors { left: parent.left; right: parent.right; top: parent.top; rightMargin: wifiNetworkRow.network.saved ? 88 : 0 }
                                    height: 52
                                    z: 2
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectWifiNetwork(wifiNetworkRow.network)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: brightnessView

        Item {
            ColumnLayout {
                anchors {
                    fill: parent
                    leftMargin: 24
                    rightMargin: 24
                    topMargin: 18
                    bottomMargin: 32
                }
                spacing: 14
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 146
                    opacity: root.systemPageElementProgress("display", 0)
                    scale: root.systemPageElementScale("display", 0)
                    transform: Translate { y: root.systemPageElementOffset("display", 0, 10) }
                    radius: 28
                    color: root.primaryContainer
                    border.width: 1
                    border.color: root.alpha(root.accent, 0.42)

                    ColumnLayout {
                        anchors { fill: parent; margins: 18 }
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            Rectangle {
                                Layout.preferredWidth: 46
                                Layout.preferredHeight: 46
                                radius: 23
                                color: root.alpha(root.accent, 0.24)
                                VeloraMaterialIcon { anchors.centerIn: parent; width: 28; height: 28; iconName: "sun"; iconColor: root.onPrimaryContainer; filled: true }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text { text: "Brilho"; color: root.onPrimaryContainer; font.family: root.uiFont; font.pixelSize: 16; font.weight: Font.DemiBold }
                                Text { text: Math.round(root.brightnessPercent * 100) + "%"; color: root.alpha(root.onPrimaryContainer, 0.76); font.family: root.monoFont; font.pixelSize: 12 }
                            }
                        }

                        CompactSlider {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 54
                        label: "Brilho"
                        detail: Math.round(root.brightnessPercent * 100) + "%"
                        value: root.brightnessPercent
                            iconName: "sun"
                            fillColor: root.onPrimaryContainer
                        onMoved: function(value) { root.setBrightness(value) }
                        }
                    }
                }
                ActionCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 86
                    iconName: "moon"
                    title: "Luz noturna"
                    subtitle: root.nightLight ? "Ativada · temperatura quente" : "Desativada"
                    active: root.nightLight
                    opacity: root.systemPageElementProgress("display", 1)
                    transform: Translate { y: root.systemPageElementOffset("display", 1, 10) }
                    onTriggered: root.toggleNightLight()
                }
                MaterialInfoRow {
                    iconName: "display"
                    title: "Configurações da tela"
                    subtitle: "Resolução, escala e monitores"
                    value: "Abrir"
                    opacity: root.systemPageElementProgress("display", 2)
                    scale: root.systemPageElementScale("display", 2)
                    transform: Translate { y: root.systemPageElementOffset("display", 2, 9) }
                    onTriggered: root.runCommand("systemsettings kcm_kscreen >/dev/null 2>&1 || gnome-control-center display >/dev/null 2>&1 || true")
                }
                MaterialInfoRow {
                    iconName: "brightness"
                    title: "Tela ativa"
                    subtitle: root.brightnessDevice
                    value: Math.round(root.brightnessPercent * 100) + "%"
                    clickable: false
                    opacity: root.systemPageElementProgress("display", 3)
                    scale: root.systemPageElementScale("display", 3)
                    transform: Translate { y: root.systemPageElementOffset("display", 3, 8) }
                }
            }
        }
    }

    Component {
        id: notificationsView

        Item {
            ColumnLayout {
                anchors {
                    fill: parent
                    leftMargin: 24
                    rightMargin: 24
                    topMargin: 18
                    bottomMargin: 32
                }
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    opacity: root.systemPageElementProgress("notifications", 0)
                    scale: root.systemPageElementScale("notifications", 0)
                    transform: Translate { y: root.systemPageElementOffset("notifications", 0, 8) }
                    Item { Layout.fillWidth: true }
                    MiniButton { Layout.preferredWidth: 104; Layout.preferredHeight: 36; label: root.doNotDisturb ? "Não perturbe" : "Ativar DND"; active: root.doNotDisturb; onTriggered: root.toggleDnd() }
                    MiniButton { Layout.preferredWidth: 76; Layout.preferredHeight: 36; label: "Limpar"; enabledControl: root.notificationGroups.length > 0; onTriggered: root.clearNotifications() }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.notificationGroups.length <= 0
                    opacity: root.systemPageElementProgress("notifications", 1)
                    scale: root.systemPageElementScale("notifications", 1)
                    transform: Translate { y: root.systemPageElementOffset("notifications", 1, 10) }
                    radius: 28
                    color: root.surfaceContainer
                    border.width: 1
                    border.color: root.line

                    ColumnLayout {
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 40, 320)
                        spacing: 7

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 58
                            Layout.preferredHeight: 58
                            radius: 29
                            color: root.primaryContainer

                            VeloraMaterialIcon {
                                anchors.centerIn: parent
                                width: 30
                                height: 30
                                iconName: "notifications-off"
                                iconColor: root.accent
                                symbolWeight: 500
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Tudo em dia"
                            color: root.ink
                            font.family: root.uiFont
                            font.pixelSize: 17
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Nenhuma notificação recente"
                            color: root.inkSoft
                            font.family: root.uiFont
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Flickable {
                    id: notificationFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.notificationGroups.length > 0
                    clip: true
                    contentWidth: width
                    contentHeight: notificationGroupColumn.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: notificationGroupColumn
                        width: notificationFlick.width
                        spacing: 8

                        Repeater {
                            model: root.notificationGroups

                            Rectangle {
                                required property var modelData
                                required property int index
                                readonly property bool expanded: root.expandedNotificationGroup === modelData.key
                                readonly property color groupAccent: root.notificationAccentColor(modelData.iconKey)
                                width: notificationGroupColumn.width
                                height: groupContents.implicitHeight + 12
                                opacity: root.systemPageElementProgress("notifications", 1 + Math.min(index, 4))
                                scale: root.systemPageElementScale("notifications", 1 + Math.min(index, 4))
                                transform: Translate { y: root.systemPageElementOffset("notifications", 1 + Math.min(index, 4), 9) }
                                radius: 24
                                color: root.surfaceContainer
                                border.width: 1
                                border.color: expanded ? root.alpha(groupAccent, 0.58) : root.outlineVariant
                                clip: true

                                Behavior on height { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
                                Behavior on border.color { ColorAnimation { duration: 160 } }

                                Column {
                                    id: groupContents
                                    x: 6
                                    y: 6
                                    width: parent.width - 12
                                    spacing: 5

                                    Rectangle {
                                        width: parent.width
                                        height: 64
                                        radius: 19
                                        color: groupHeaderMouse.containsMouse ? root.surfaceContainerHigh : "transparent"

                                        RowLayout {
                                            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                            spacing: 11

                                            Rectangle {
                                                Layout.preferredWidth: 44
                                                Layout.preferredHeight: 44
                                                radius: 16
                                                color: root.alpha(groupAccent, 0.20)
                                                VeloraMaterialIcon {
                                                    anchors.centerIn: parent
                                                    width: 25
                                                    height: 25
                                                    iconName: root.notificationIconName(modelData.iconKey)
                                                    iconColor: groupAccent
                                                    filled: true
                                                    symbolWeight: 560
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1
                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 7
                                                    Text { Layout.fillWidth: true; text: modelData.app; color: root.ink; font.family: root.uiFont; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                                    Rectangle {
                                                        visible: modelData.items.length > 1
                                                        Layout.preferredWidth: countText.implicitWidth + 12
                                                        Layout.preferredHeight: 20
                                                        radius: 10
                                                        color: root.alpha(groupAccent, 0.17)
                                                        Text { id: countText; anchors.centerIn: parent; text: modelData.items.length; color: groupAccent; font.family: root.monoFont; font.pixelSize: 9; font.weight: Font.Bold }
                                                    }
                                                }
                                                Text { Layout.fillWidth: true; text: modelData.latestSummary; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 10; elide: Text.ElideRight }
                                            }

                                            Text { text: modelData.latestTime; color: root.inkSoft; font.family: root.monoFont; font.pixelSize: 8 }
                                            VeloraMaterialIcon { Layout.preferredWidth: 22; Layout.preferredHeight: 22; iconName: expanded ? "expand_less" : "expand_more"; iconColor: groupAccent }
                                        }

                                        MouseArea {
                                            id: groupHeaderMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.expandedNotificationGroup = parent.parent.parent.expanded ? "" : parent.parent.parent.modelData.key
                                        }
                                    }

                                    Column {
                                        width: parent.width
                                        spacing: 5
                                        visible: parent.parent.expanded

                                        Repeater {
                                            model: parent.parent.parent.modelData.items.slice(0, 4)

                                            Rectangle {
                                                required property var modelData
                                                readonly property var actions: root.notificationActions(modelData)
                                                width: parent.width
                                                height: actions.length > 0 ? 94 : 76
                                                radius: 18
                                                color: notificationMouse.containsMouse ? root.surfaceContainerHigh : root.alpha(root.surfaceContainerHigh, 0.58)

                                                ColumnLayout {
                                                    z: 1
                                                    anchors { fill: parent; leftMargin: 13; rightMargin: 10; topMargin: 9; bottomMargin: 8 }
                                                    spacing: 4

                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 8
                                                        ColumnLayout {
                                                            Layout.fillWidth: true
                                                            spacing: 1
                                                            Text { Layout.fillWidth: true; text: modelData.summary; color: root.ink; font.family: root.uiFont; font.pixelSize: 11; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                                            Text { Layout.fillWidth: true; text: modelData.body.length > 0 ? modelData.body : "Clique para abrir"; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 9; elide: Text.ElideRight }
                                                        }
                                                        Text { text: modelData.timeText; color: root.inkSoft; font.family: root.monoFont; font.pixelSize: 8 }
                                                        Rectangle {
                                                            Layout.preferredWidth: 30
                                                            Layout.preferredHeight: 30
                                                            radius: 15
                                                            color: closeNotificationMouse.containsMouse ? root.alpha(root.inkSoft, 0.16) : "transparent"
                                                            VeloraMaterialIcon { anchors.centerIn: parent; width: 18; height: 18; iconName: "close"; iconColor: root.inkSoft }
                                                            MouseArea {
                                                                id: closeNotificationMouse
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: root.notificationDismissRequested(modelData.id)
                                                            }
                                                        }
                                                    }

                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        visible: actions.length > 0
                                                        spacing: 6
                                                        Repeater {
                                                            model: actions
                                                            Rectangle {
                                                                required property var modelData
                                                                Layout.preferredWidth: actionText.implicitWidth + 22
                                                                Layout.preferredHeight: 26
                                                                radius: 13
                                                                color: actionMouse.containsMouse ? root.alpha(groupAccent, 0.22) : root.alpha(groupAccent, 0.12)
                                                                border.width: 1
                                                                border.color: root.alpha(groupAccent, 0.40)
                                                                Text { id: actionText; anchors.centerIn: parent; text: modelData.text; color: groupAccent; font.family: root.uiFont; font.pixelSize: 9; font.weight: Font.DemiBold }
                                                                MouseArea {
                                                                    id: actionMouse
                                                                    anchors.fill: parent
                                                                    hoverEnabled: true
                                                                    cursorShape: Qt.PointingHandCursor
                                                                    onClicked: root.notificationActionRequested(parent.parent.parent.parent.modelData.id, modelData.identifier)
                                                                }
                                                            }
                                                        }
                                                        Item { Layout.fillWidth: true }
                                                    }
                                                }

                                                MouseArea {
                                                    id: notificationMouse
                                                    anchors { fill: parent; rightMargin: 42; bottomMargin: actions.length > 0 ? 34 : 0 }
                                                    z: 0
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.notificationActivated(parent.modelData.id)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: bluetoothView

        Item {
            ColumnLayout {
                anchors {
                    fill: parent
                    leftMargin: 24
                    rightMargin: 24
                    topMargin: 18
                    bottomMargin: 32
                }
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    spacing: 11
                    opacity: root.systemPageElementProgress("bluetooth", 0)
                    scale: root.systemPageElementScale("bluetooth", 0)
                    transform: Translate { y: root.systemPageElementOffset("bluetooth", 0, 8) }

                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 20
                        color: root.primaryContainer
                        VeloraMaterialIcon { anchors.centerIn: parent; width: 24; height: 24; iconName: "bluetooth"; iconColor: root.accent; filled: root.bluetoothPowered }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text { text: "Bluetooth"; color: root.ink; font.family: root.uiFont; font.pixelSize: 14; font.weight: Font.DemiBold }
                        Text {
                            text: root.bluetoothPendingAction.length > 0
                                ? root.bluetoothPendingAction
                                : (root.bluetoothScanning
                                    ? "Procurando dispositivos…"
                                    : (root.bluetoothPowered ? (bluetoothDevices.count + (bluetoothDevices.count === 1 ? " dispositivo" : " dispositivos")) : "Desativado"))
                            color: root.inkSoft
                            font.family: root.uiFont
                            font.pixelSize: 10
                        }
                    }

                    MiniButton {
                        visible: root.bluetoothPowered
                        Layout.preferredWidth: 92
                        Layout.preferredHeight: 34
                        label: root.bluetoothScanning ? "Buscando…" : "Procurar"
                        enabledControl: !root.bluetoothScanning
                        onTriggered: root.scanBluetooth()
                    }

                    Rectangle {
                        Layout.preferredWidth: 52
                        Layout.preferredHeight: 30
                        radius: 15
                        color: root.bluetoothPowered ? root.accent : root.alpha(root.inkSoft, 0.20)
                        opacity: root.bluetoothAvailable ? 1 : 0.42

                        Rectangle {
                            width: 22
                            height: 22
                            radius: 11
                            x: root.bluetoothPowered ? parent.width - width - 4 : 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.bluetoothPowered ? root.onPrimaryContainer : root.inkSoft
                            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }

                        MouseArea { anchors.fill: parent; enabled: root.bluetoothAvailable; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleBluetooth() }
                    }
                }

                Flickable {
                    id: bluetoothFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: bluetoothContent.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    visible: bluetoothDevices.count > 0

                    Column {
                        id: bluetoothContent
                        width: bluetoothFlick.width
                        spacing: 6

                        Repeater {
                            model: Math.min(5, bluetoothDevices.count)

                            Rectangle {
                                id: btDeviceRow
                                required property int index
                                readonly property var device: bluetoothDevices.get(index)
                                readonly property bool editorOpen: root.bluetoothExpandedAddress === device.address
                                width: bluetoothContent.width
                                height: 62
                                opacity: root.systemPageElementProgress("bluetooth", 1 + Math.min(index, 4))
                                scale: root.systemPageElementScale("bluetooth", 1 + Math.min(index, 4))
                                transform: Translate { y: root.systemPageElementOffset("bluetooth", 1 + Math.min(index, 4), 9) }
                                radius: 20
                                color: btMouse.containsMouse || editorOpen || device.connected ? root.surfaceContainerHigh : root.surfaceContainer
                                border.width: 1
                                border.color: editorOpen || device.connected ? root.alpha(root.accent, 0.56) : root.outlineVariant

                                RowLayout {
                                    anchors { fill: parent; leftMargin: 11; rightMargin: 8 }
                                    spacing: 10

                                    Rectangle {
                                        Layout.preferredWidth: 40
                                        Layout.preferredHeight: 40
                                        radius: 20
                                        color: root.alpha(root.accent, device.connected ? 0.24 : 0.12)
                                        VeloraMaterialIcon { anchors.centerIn: parent; width: 23; height: 23; iconName: root.bluetoothTypeIcon(device.type); iconColor: root.accent; filled: device.connected; symbolWeight: 520 }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text { Layout.fillWidth: true; text: device.name; color: root.ink; font.family: root.uiFont; font.pixelSize: 12; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                        Text {
                                            Layout.fillWidth: true
                                            text: (device.connected ? "Conectado" : (device.paired ? "Salvo" : "Disponível"))
                                                + " · " + root.bluetoothTypeLabel(device.type)
                                                + (device.battery >= 0 ? " · " + device.battery + "%" : "")
                                            color: root.inkSoft
                                            font.family: root.uiFont
                                            font.pixelSize: 10
                                        }
                                    }

                                    Rectangle {
                                        visible: device.connected
                                        Layout.preferredWidth: 24
                                        Layout.preferredHeight: 24
                                        radius: 12
                                        color: root.alpha(root.accent, 0.18)
                                        VeloraMaterialIcon { anchors.centerIn: parent; width: 17; height: 17; iconName: "check"; iconColor: root.accent; filled: true }
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 38
                                        Layout.preferredHeight: 38
                                        radius: 19
                                        color: btEditorMouse.containsMouse ? root.alpha(root.accent, 0.16) : "transparent"
                                        VeloraMaterialIcon { anchors.centerIn: parent; width: 22; height: 22; iconName: btDeviceRow.editorOpen ? "expand_less" : "chevron_right"; iconColor: root.inkSoft }
                                        MouseArea {
                                            id: btEditorMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.bluetoothExpandedAddress = btDeviceRow.editorOpen ? "" : btDeviceRow.device.address
                                        }
                                    }
                                }

                                MouseArea {
                                    id: btMouse
                                    anchors { fill: parent; rightMargin: 48 }
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (!btDeviceRow.device.connected && !btDeviceRow.device.paired)
                                            root.pairBluetoothDevice(btDeviceRow.device.address)
                                        else
                                            root.setBluetoothConnection(btDeviceRow.device.address, btDeviceRow.device.connected)
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: bluetoothDeviceEditor
                            readonly property var device: root.bluetoothDeviceByAddress(root.bluetoothExpandedAddress)
                            width: bluetoothContent.width
                            readonly property bool confirmForget: device && root.bluetoothForgetConfirmAddress === device.address
                            height: visible ? (confirmForget || root.bluetoothPairPrompt.length > 0 || root.bluetoothError.length > 0 ? 292 : 236) : 0
                            visible: device !== null
                            opacity: root.systemPageElementProgress("bluetooth", 3)
                            scale: root.systemPageElementScale("bluetooth", 3)
                            transform: Translate { y: root.systemPageElementOffset("bluetooth", 3, 8) }
                            radius: 24
                            color: root.surfaceContainer
                            border.width: 1
                            border.color: root.alpha(root.accent, 0.52)
                            clip: true

                            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                            ColumnLayout {
                                anchors { fill: parent; margins: 14 }
                                spacing: 9

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: "Ícone do dispositivo"; color: root.ink; font.family: root.uiFont; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    Text { text: bluetoothDeviceEditor.device ? root.bluetoothTypeLabel(bluetoothDeviceEditor.device.type) : ""; color: root.accent; font.family: root.uiFont; font.pixelSize: 10; font.weight: Font.DemiBold }
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 4
                                    columnSpacing: 6
                                    rowSpacing: 6

                                    Repeater {
                                        model: [
                                            { type: "auto", icon: "tune" },
                                            { type: "headphones", icon: "headphones" },
                                            { type: "speaker", icon: "speaker" },
                                            { type: "controller", icon: "sports_esports" },
                                            { type: "phone", icon: "phone" },
                                            { type: "laptop", icon: "laptop" },
                                            { type: "keyboard", icon: "keyboard" },
                                            { type: "mouse", icon: "mouse" }
                                        ]

                                        Rectangle {
                                            id: btTypeTile
                                            required property var modelData
                                            readonly property bool selected: bluetoothDeviceEditor.device && ((modelData.type === "auto" && bluetoothDeviceEditor.device.type === "bluetooth") || modelData.type === bluetoothDeviceEditor.device.type)
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 58
                                            radius: 16
                                            color: selected ? root.primaryContainer : (btTypeMouse.containsMouse ? root.surfaceContainerHigh : root.alpha(root.inkSoft, 0.06))
                                            border.width: 1
                                            border.color: selected ? root.alpha(root.accent, 0.52) : root.outlineVariant

                                            ColumnLayout {
                                                anchors.centerIn: parent
                                                spacing: 2
                                                VeloraMaterialIcon { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 23; Layout.preferredHeight: 23; iconName: btTypeTile.modelData.icon; iconColor: btTypeTile.selected ? root.accent : root.inkSoft; filled: btTypeTile.selected }
                                                Text { text: root.bluetoothTypeLabel(btTypeTile.modelData.type); color: btTypeTile.selected ? root.accent : root.inkSoft; font.family: root.uiFont; font.pixelSize: 8; font.weight: Font.DemiBold }
                                            }

                                            MouseArea {
                                                id: btTypeMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.setBluetoothDeviceIcon(bluetoothDeviceEditor.device.address, btTypeTile.modelData.type)
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    MiniButton {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 38
                                        label: bluetoothDeviceEditor.device && bluetoothDeviceEditor.device.connected
                                            ? "Desconectar"
                                            : (bluetoothDeviceEditor.device && bluetoothDeviceEditor.device.paired ? "Conectar" : "Parear")
                                        active: bluetoothDeviceEditor.device && bluetoothDeviceEditor.device.connected
                                        onTriggered: {
                                            if (!bluetoothDeviceEditor.device)
                                                return
                                            if (!bluetoothDeviceEditor.device.connected && !bluetoothDeviceEditor.device.paired)
                                                root.pairBluetoothDevice(bluetoothDeviceEditor.device.address)
                                            else
                                                root.setBluetoothConnection(bluetoothDeviceEditor.device.address, bluetoothDeviceEditor.device.connected)
                                        }
                                    }
                                    MiniButton {
                                        Layout.preferredWidth: 108
                                        Layout.preferredHeight: 38
                                        label: "Esquecer"
                                        enabledControl: bluetoothDeviceEditor.device && bluetoothDeviceEditor.device.paired
                                        onTriggered: if (bluetoothDeviceEditor.device) root.bluetoothForgetConfirmAddress = bluetoothDeviceEditor.device.address
                                    }
                                }

                                RowLayout {
                                    visible: bluetoothDeviceEditor.confirmForget
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: "Remover pareamento e confiança?"; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 10 }
                                    MiniButton { Layout.preferredWidth: 76; Layout.preferredHeight: 32; label: "Cancelar"; onTriggered: root.bluetoothForgetConfirmAddress = "" }
                                    MiniButton {
                                        Layout.preferredWidth: 76
                                        Layout.preferredHeight: 32
                                        label: "Remover"
                                        active: true
                                        onTriggered: {
                                            if (bluetoothDeviceEditor.device)
                                                root.removeBluetoothDevice(bluetoothDeviceEditor.device.address)
                                            root.bluetoothForgetConfirmAddress = ""
                                        }
                                    }
                                }

                                RowLayout {
                                    visible: root.bluetoothPairPrompt.length > 0
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: root.bluetoothPairPrompt; color: root.ink; font.family: root.uiFont; font.pixelSize: 10; elide: Text.ElideRight }
                                    Rectangle {
                                        visible: root.bluetoothPairPrompt.toLowerCase().indexOf("enter") >= 0
                                        Layout.preferredWidth: 90
                                        Layout.preferredHeight: 34
                                        radius: 14
                                        color: root.alpha(root.inkSoft, 0.10)
                                        TextInput {
                                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                            verticalAlignment: TextInput.AlignVCenter
                                            text: root.bluetoothPairResponse
                                            color: root.ink
                                            font.family: root.monoFont
                                            font.pixelSize: 11
                                            inputMethodHints: Qt.ImhDigitsOnly
                                            onTextEdited: root.bluetoothPairResponse = text
                                            Keys.onReturnPressed: root.answerBluetoothPairing(text)
                                        }
                                    }
                                    MiniButton { Layout.preferredWidth: 70; Layout.preferredHeight: 34; label: "Recusar"; onTriggered: root.answerBluetoothPairing("no") }
                                    MiniButton { Layout.preferredWidth: 70; Layout.preferredHeight: 34; label: "Aceitar"; active: true; onTriggered: root.answerBluetoothPairing(root.bluetoothPairResponse.length > 0 ? root.bluetoothPairResponse : "yes") }
                                }

                                Text {
                                    visible: root.bluetoothError.length > 0
                                    Layout.fillWidth: true
                                    text: root.bluetoothError
                                    color: root.accent2
                                    font.family: root.uiFont
                                    font.pixelSize: 10
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: bluetoothDevices.count <= 0
                    opacity: root.systemPageElementProgress("bluetooth", 1)
                    scale: root.systemPageElementScale("bluetooth", 1)
                    transform: Translate { y: root.systemPageElementOffset("bluetooth", 1, 10) }
                    radius: 28
                    color: root.surfaceContainer
                    border.width: 1
                    border.color: root.line

                    ColumnLayout {
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 48, 340)
                        spacing: 8

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 62
                            Layout.preferredHeight: 62
                            radius: 31
                            color: root.primaryContainer
                            VeloraMaterialIcon { anchors.centerIn: parent; width: 32; height: 32; iconName: "bluetooth"; iconColor: root.accent; filled: root.bluetoothPowered; symbolWeight: 500 }
                        }

                        Text { Layout.fillWidth: true; text: root.bluetoothPowered ? "Nenhum dispositivo por perto" : "Bluetooth desativado"; color: root.ink; font.family: root.uiFont; font.pixelSize: 16; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap }
                        Text { Layout.fillWidth: true; text: root.bluetoothPowered ? "Deixe o acessório visível e procure novamente." : "Ative para encontrar fones, controles e outros acessórios."; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap }
                        MiniButton {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 5
                            Layout.preferredWidth: root.bluetoothPowered ? 154 : 138
                            Layout.preferredHeight: 40
                            label: root.bluetoothPowered ? "Procurar novamente" : "Ativar Bluetooth"
                            active: true
                            enabledControl: root.bluetoothAvailable
                            onTriggered: {
                                if (root.bluetoothPowered)
                                    root.scanBluetooth()
                                else
                                    root.toggleBluetooth()
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: bluetoothViewLegacy

        Item {
            ColumnLayout {
                anchors { fill: parent; margins: 24 }
                spacing: 12
                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    MiniButton { Layout.preferredWidth: 82; Layout.preferredHeight: 36; label: root.bluetoothPowered ? "Ligado" : "Desligado"; active: root.bluetoothPowered; enabledControl: root.bluetoothAvailable; onTriggered: root.toggleBluetooth() }
                }

                Text { Layout.fillWidth: true; text: "Dispositivos"; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 9 }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 292
                    radius: 28
                    color: root.surfaceContainer
                    border.width: 1
                    border.color: root.line

                    ColumnLayout {
                        anchors { fill: parent; margins: 10 }
                        spacing: 6
                        visible: bluetoothDevices.count > 0

                        Repeater {
                            model: Math.min(5, bluetoothDevices.count)
                            Rectangle {
                                required property int index
                                readonly property var device: bluetoothDevices.get(index)
                                Layout.fillWidth: true
                                Layout.preferredHeight: 62
                                radius: 20
                                color: btMouse.containsMouse || device.connected
                                       ? root.surfaceContainerHigh
                                       : "transparent"
                                border.width: device.connected ? 1 : 0
                                border.color: root.alpha(root.accent, 0.60)

                                RowLayout {
                                    anchors { fill: parent; leftMargin: 11; rightMargin: 11 }
                                    spacing: 10

                                    Rectangle {
                                        Layout.preferredWidth: 40
                                        Layout.preferredHeight: 40
                                        radius: 20
                                        color: root.alpha(root.accent, device.connected ? 0.24 : 0.12)
                                        VeloraMaterialIcon {
                                            anchors.centerIn: parent
                                            width: 23
                                            height: 23
                                            iconName: "bluetooth"
                                            iconColor: root.accent
                                            filled: device.connected
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text { Layout.fillWidth: true; text: device.name; color: root.ink; font.family: root.uiFont; font.pixelSize: 12; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                        Text { Layout.fillWidth: true; text: device.connected ? "Conectado" : "Disponível"; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 10 }
                                    }

                                    VeloraMaterialIcon {
                                        Layout.preferredWidth: 22
                                        Layout.preferredHeight: 22
                                        iconName: device.connected ? "check" : "chevron_right"
                                        iconColor: device.connected ? root.accent : root.inkSoft
                                        filled: device.connected
                                    }
                                }

                                MouseArea {
                                    id: btMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setBluetoothConnection(parent.device.address, parent.device.connected)
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 48, 340)
                        spacing: 10
                        visible: bluetoothDevices.count <= 0

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 76
                            Layout.preferredHeight: 76
                            radius: 38
                            color: root.primaryContainer

                            VeloraMaterialIcon {
                                anchors.centerIn: parent
                                width: 38
                                height: 38
                                iconName: "bluetooth"
                                iconColor: root.accent
                                filled: root.bluetoothPowered
                                symbolWeight: 500
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.topMargin: 6
                            text: root.bluetoothPowered ? "Nenhum dispositivo por perto" : "Bluetooth desativado"
                            color: root.ink
                            font.family: root.uiFont
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.bluetoothPowered
                                  ? "Verifique se o dispositivo está visível e procure novamente."
                                  : "Ative para encontrar fones, controles e outros dispositivos próximos."
                            color: root.inkSoft
                            font.family: root.uiFont
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            lineHeight: 1.25
                        }

                        MiniButton {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 10
                            Layout.preferredWidth: root.bluetoothPowered ? 164 : 138
                            Layout.preferredHeight: 44
                            label: root.bluetoothPowered ? "Procurar novamente" : "Ativar Bluetooth"
                            active: true
                            enabledControl: root.bluetoothAvailable
                            onTriggered: {
                                if (root.bluetoothPowered) {
                                    if (!bluetoothQuery.running)
                                        bluetoothQuery.running = true
                                } else {
                                    root.toggleBluetooth()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: batteryView

        Item {
            ColumnLayout {
                anchors {
                    fill: parent
                    leftMargin: 24
                    rightMargin: 24
                    topMargin: 14
                    bottomMargin: 26
                }
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 84
                    opacity: root.systemPageElementProgress("battery", 0)
                    scale: root.systemPageElementScale("battery", 0)
                    transform: Translate { y: root.systemPageElementOffset("battery", 0, 10) }
                    radius: 26
                    color: root.primaryContainer
                    border.width: 1
                    border.color: root.alpha(root.accent, 0.42)

                    ColumnLayout {
                        anchors { fill: parent; margins: 12 }
                        spacing: 5

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 14

                            Rectangle {
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48
                                radius: 24
                                color: root.alpha(root.accent, 0.24)
                                VeloraMaterialIcon {
                                    anchors.centerIn: parent
                                    width: 29
                                    height: 29
                                    iconName: root.batteryAcOnline ? "battery_charging_full" : "battery_full"
                                    iconColor: root.onPrimaryContainer
                                    filled: true
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text { text: Math.round(root.batteryPercent * 100) + "%"; color: root.onPrimaryContainer; font.family: root.monoFont; font.pixelSize: 30; font.weight: Font.Bold }
                                Text { text: root.batteryStateLabel(); color: root.alpha(root.onPrimaryContainer, 0.78); font.family: root.uiFont; font.pixelSize: 10; font.weight: Font.Medium }
                            }

                            Rectangle {
                                Layout.preferredWidth: statusText.implicitWidth + 22
                                Layout.preferredHeight: 28
                                radius: 14
                                color: root.alpha(root.onPrimaryContainer, 0.10)
                                Text {
                                    id: statusText
                                    anchors.centerIn: parent
                                    text: root.batteryIsFull ? "Carga completa" : (root.batteryTime.length > 0 ? root.batteryTime : "Calculando")
                                    color: root.onPrimaryContainer
                                    font.family: root.uiFont
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 6
                            radius: 3
                            color: root.alpha(root.onPrimaryContainer, 0.13)

                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1, root.batteryPercent))
                                height: parent.height
                                radius: parent.radius
                                color: root.onPrimaryContainer
                                opacity: 0.82

                                Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                }

                Rectangle {
                    id: powerProfileCard
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.batteryProfileExpanded ? 174 : 56
                    opacity: root.systemPageElementProgress("battery", 1)
                    scale: root.systemPageElementScale("battery", 1)
                    transform: Translate { y: root.systemPageElementOffset("battery", 1, 9) }
                    radius: 20
                    color: root.surfaceContainer
                    border.width: 1
                    border.color: root.batteryProfileExpanded ? root.alpha(root.accent, 0.54) : root.outlineVariant
                    clip: true

                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    ColumnLayout {
                        anchors { fill: parent; margins: 4 }
                        spacing: 6

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            radius: 17
                            color: profileHeaderMouse.containsMouse ? root.surfaceContainerHigh : "transparent"

                            RowLayout {
                                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                spacing: 11

                                Rectangle {
                                    Layout.preferredWidth: 34
                                    Layout.preferredHeight: 34
                                    radius: 17
                                    color: root.primaryContainer
                                    VeloraMaterialIcon { anchors.centerIn: parent; width: 21; height: 21; iconName: "bolt"; iconColor: root.accent; filled: true }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text { Layout.fillWidth: true; text: "Modo de energia"; color: root.ink; font.family: root.uiFont; font.pixelSize: 12; font.weight: Font.DemiBold }
                                    Text { Layout.fillWidth: true; text: root.powerProfileDescription(root.powerProfile); color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 8; elide: Text.ElideRight }
                                }

                                Text { text: root.powerProfileLabel(root.powerProfile); color: root.accent; font.family: root.uiFont; font.pixelSize: 11; font.weight: Font.DemiBold }
                                VeloraMaterialIcon { Layout.preferredWidth: 20; Layout.preferredHeight: 20; iconName: root.batteryProfileExpanded ? "expand_less" : "expand_more"; iconColor: root.inkSoft }
                            }

                            MouseArea {
                                id: profileHeaderMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.batteryProfileExpanded = !root.batteryProfileExpanded
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: root.batteryProfileExpanded
                            spacing: 3

                            Repeater {
                                model: [
                                    { key: "power-saver", label: "Economia", detail: "Prioriza autonomia" },
                                    { key: "balanced", label: "Equilibrado", detail: "Uso diário" },
                                    { key: "performance", label: "Desempenho", detail: "Prioriza velocidade" }
                                ]

                                Rectangle {
                                    required property var modelData
                                    readonly property bool selected: root.powerProfile === modelData.key
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 35
                                    radius: 12
                                    color: selected ? root.primaryContainer : (profileOptionMouse.containsMouse ? root.surfaceContainerHigh : "transparent")

                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 13; rightMargin: 13 }
                                        spacing: 10
                                        VeloraMaterialIcon { Layout.preferredWidth: 18; Layout.preferredHeight: 18; iconName: modelData.key === "power-saver" ? "eco" : (modelData.key === "performance" ? "bolt" : "tune"); iconColor: selected ? root.accent : root.inkSoft; filled: selected }
                                        Text { text: modelData.label; color: root.ink; font.family: root.uiFont; font.pixelSize: 11; font.weight: Font.DemiBold }
                                        Text { Layout.fillWidth: true; text: modelData.detail; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 8 }
                                        VeloraMaterialIcon { Layout.preferredWidth: 18; Layout.preferredHeight: 18; visible: selected; iconName: "check"; iconColor: root.accent; filled: true }
                                    }

                                    MouseArea {
                                        id: profileOptionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.setPowerProfile(parent.modelData.key)
                                            root.batteryProfileExpanded = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                MaterialInfoRow {
                    Layout.preferredHeight: 48
                    iconName: "battery_full"
                    title: "Saúde da bateria"
                    subtitle: "Capacidade estimada"
                    value: root.batteryHealth >= 0 ? Math.round(root.batteryHealth * 100) + "%" : "Calculando"
                    clickable: false
                    opacity: root.systemPageElementProgress("battery", 2)
                    scale: root.systemPageElementScale("battery", 2)
                    transform: Translate { y: root.systemPageElementOffset("battery", 2, 8) }
                }

                MaterialInfoRow {
                    Layout.preferredHeight: 48
                    iconName: "schedule"
                    title: "Ciclos de carga"
                    subtitle: root.batteryAcOnline ? "Carregando agora" : "Na bateria"
                    value: root.batteryCycles >= 0 ? String(root.batteryCycles) : "—"
                    clickable: false
                    opacity: root.systemPageElementProgress("battery", 3)
                    scale: root.systemPageElementScale("battery", 3)
                    transform: Translate { y: root.systemPageElementOffset("battery", 3, 8) }
                }
            }
        }
    }

    component BottomReferenceToggle: Item {
        id: referenceToggle

        property string iconName: "wifi"
        property string label: "Atalho"
        property bool active: false
        property bool enabledControl: true
        property color accentColor: root.accent
        property color secondaryAccentColor: root.accent3
        signal triggered()

        implicitWidth: 76
        implicitHeight: 104
        opacity: enabledControl ? 1 : 0.44
        scale: referenceToggleMouse.pressed ? 0.96 : 1

        Behavior on scale {
            NumberAnimation {
                duration: root.systemMotionEnabled ? 90 : 1
                easing.type: Easing.OutCubic
            }
        }

        DropShadow {
            anchors.fill: referenceToggleSurface
            source: referenceToggleSurface
            horizontalOffset: 0
            verticalOffset: 4
            radius: 12
            samples: 25
            color: Qt.rgba(0, 0, 0, referenceToggleMouse.containsMouse ? 0.28 : 0.20)
            transparentBorder: true
        }

        Rectangle {
            id: referenceToggleSurface

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: 76
            radius: 22
            color: "transparent"
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0
                    color: referenceToggle.active
                        ? root.pastelTone(referenceToggle.accentColor, 0.48, 0.88)
                        : root.systemTone(
                            referenceToggle.accentColor,
                            referenceToggleMouse.containsMouse ? 0.16 : 0.08,
                            0.48
                        )
                }
                GradientStop {
                    position: 1
                    color: referenceToggle.active
                        ? root.pastelTone(referenceToggle.secondaryAccentColor, 0.56, 0.84)
                        : root.systemTone(
                            referenceToggle.secondaryAccentColor,
                            referenceToggleMouse.containsMouse ? 0.12 : 0.055,
                            0.44
                        )
                }
            }
            border.width: 1
            border.color: root.alpha(
                referenceToggle.active ? referenceToggle.accentColor : root.inkSoft,
                referenceToggle.active ? 0.54 : 0.24
            )

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 1
                }
                height: Math.round(parent.height * 0.46)
                radius: Math.max(0, parent.radius - 1)
                color: root.alpha(root.ink, referenceToggleMouse.containsMouse ? 0.05 : 0.028)
            }

            VeloraMaterialIcon {
                anchors.centerIn: parent
                width: 32
                height: 32
                iconName: referenceToggle.iconName
                iconColor: referenceToggle.active
                    ? root.deepTone(referenceToggle.accentColor, 0.92)
                    : root.ink
                filled: referenceToggle.active
            }
        }

        Text {
            anchors {
                left: parent.left
                right: parent.right
                top: referenceToggleSurface.bottom
                topMargin: 7
            }
            text: referenceToggle.enabledControl
                ? referenceToggle.label
                : referenceToggle.label + " indisponível"
            color: referenceToggle.enabledControl ? root.inkSoft : root.alpha(root.inkSoft, 0.72)
            font.family: root.uiFont
            font.pixelSize: referenceToggle.enabledControl ? 9 : 8
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        MouseArea {
            id: referenceToggleMouse

            anchors.fill: parent
            enabled: referenceToggle.enabledControl
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: referenceToggle.triggered()
        }
    }

    Component {
        id: bottomSettingsView

        Item {
            anchors.fill: parent

            ColumnLayout {
                anchors {
                    fill: parent
                    leftMargin: 18
                    rightMargin: 18
                    topMargin: 18
                    bottomMargin: 30
                }
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    spacing: 8

                    RightConnectionPill {
                        Layout.fillWidth: true
                        iconName: root.wifiEnabled ? "wifi" : "wifi-off"
                        accentColor: root.accent
                        secondaryAccentColor: root.accent3
                        title: root.wifiSsid.length > 0 ? root.wifiSsid : "Wi‑Fi"
                        subtitle: root.wifiSsid.length > 0 ? "Conectado" : (root.wifiEnabled ? "Disponível" : "Desativado")
                        active: root.wifiEnabled && root.wifiSsid.length > 0
                        onTriggered: root.systemPageRequested("wifi")
                    }
                    RightConnectionPill {
                        Layout.fillWidth: true
                        iconName: "bluetooth"
                        accentColor: root.accent
                        secondaryAccentColor: root.accent3
                        title: root.connectedBluetoothName()
                        subtitle: root.bluetoothPowered
                            ? (root.connectedBluetoothName() === "Bluetooth" ? "Ativado" : "Conectado")
                            : "Desativado"
                        active: root.bluetoothPowered
                        onTriggered: root.systemPageRequested("bluetooth")
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 140
                    spacing: 8

                    Rectangle {
                        id: settingsMediaCard

                        property real mediaGradientPhase: 0
                        readonly property bool lyricsRevealed: settingsVinylHover.hovered

                        function gradientTone(offset) {
                            const revealBoost = lyricsRevealed ? 0.08 : 0
                            const first = root.systemTone(
                                root.accent,
                                (root.mediaPlaying ? 0.50 : 0.34) + revealBoost,
                                root.mediaPlaying ? 0.70 : 0.60
                            )
                            const middle = root.systemTone(
                                root.accent3,
                                (root.mediaPlaying ? 0.43 : 0.28) + revealBoost,
                                root.mediaPlaying ? 0.66 : 0.56
                            )
                            const last = root.systemTone(
                                root.accent2,
                                (root.mediaPlaying ? 0.48 : 0.31) + revealBoost,
                                root.mediaPlaying ? 0.68 : 0.58
                            )
                            const wrapped = mediaGradientPhase + Number(offset || 0)
                            const segment = (wrapped - Math.floor(wrapped)) * 3

                            if (segment < 1)
                                return root.mixTone(first, middle, segment, first.a + (middle.a - first.a) * segment)
                            if (segment < 2) {
                                const amount = segment - 1
                                return root.mixTone(middle, last, amount, middle.a + (last.a - middle.a) * amount)
                            }
                            const amount = segment - 2
                            return root.mixTone(last, first, amount, last.a + (first.a - last.a) * amount)
                        }

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 24
                        color: "transparent"
                        clip: true
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop {
                                position: 0
                                color: settingsMediaCard.gradientTone(0)
                            }
                            GradientStop {
                                position: 0.34
                                color: settingsMediaCard.gradientTone(0.34)
                            }
                            GradientStop {
                                position: 0.68
                                color: settingsMediaCard.gradientTone(0.68)
                            }
                            GradientStop {
                                position: 1
                                color: settingsMediaCard.gradientTone(1)
                            }
                        }
                        border.width: 1
                        border.color: root.mediaPlaying
                            ? root.alpha(root.accent, settingsMediaCard.lyricsRevealed ? 0.52 : 0.38)
                            : root.outlineVariant

                        Behavior on border.color {
                            ColorAnimation {
                                duration: root.systemMotionEnabled ? 220 : 1
                                easing.type: Easing.OutCubic
                            }
                        }

                        NumberAnimation on mediaGradientPhase {
                            from: 0
                            to: 1
                            duration: 9000
                            loops: Animation.Infinite
                            easing.type: Easing.Linear
                            running: root.open
                                && root.popupType === "system"
                                && root.systemPage === "settings"
                                && root.systemMotionEnabled
                        }

                        Image {
                            id: settingsMediaImage
                            x: 1
                            y: 1
                            width: Math.round(settingsMediaCard.width * 0.66)
                            height: settingsMediaCard.height - 2
                            source: root.mediaArt
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            visible: false
                        }

                        Rectangle {
                            id: settingsMediaMask
                            x: settingsMediaImage.x
                            y: settingsMediaImage.y
                            width: settingsMediaImage.width
                            height: settingsMediaImage.height
                            radius: Math.max(0, settingsMediaCard.radius - 1)
                            visible: false
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: "white" }
                                GradientStop { position: 0.70; color: "white" }
                                GradientStop { position: 1; color: "transparent" }
                            }
                        }

                        OpacityMask {
                            x: settingsMediaImage.x
                            y: settingsMediaImage.y
                            width: settingsMediaImage.width
                            height: settingsMediaImage.height
                            source: settingsMediaImage
                            maskSource: settingsMediaMask
                            opacity: 0.82
                            visible: settingsMediaImage.status === Image.Ready
                                && settingsMediaImage.source.toString().length > 0
                        }

                        Rectangle {
                            x: 1
                            y: 1
                            width: Math.round(settingsMediaCard.width * 0.66)
                            height: settingsMediaCard.height - 2
                            radius: Math.max(0, settingsMediaCard.radius - 1)
                            color: "transparent"
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop {
                                    position: 0
                                    color: root.deepTone(root.accent, 0.20)
                                }
                                GradientStop {
                                    position: 0.62
                                    color: root.systemTone(root.accent3, 0.10, 0.28)
                                }
                                GradientStop {
                                    position: 1
                                    color: root.systemTone(root.accent2, 0.02, 0)
                                }
                            }
                        }

                        VeloraMaterialIcon {
                            x: Math.round(settingsMediaImage.width * 0.31 - width / 2)
                            anchors.verticalCenter: parent.verticalCenter
                            width: 42
                            height: 42
                            opacity: 0.54
                            visible: settingsMediaImage.status !== Image.Ready
                                || settingsMediaImage.source.toString().length <= 0
                            iconName: "music"
                            iconColor: root.inkSoft
                            filled: true
                        }

                        Item {
                            id: settingsMediaGlavaColorField

                            x: 0
                            y: 0
                            width: settingsMediaCard.width
                            height: settingsMediaCard.height
                            z: 2

                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop {
                                        position: 0
                                        color: root.pastelTone(root.accent2, 0.18, 1)
                                    }
                                    GradientStop {
                                        position: 0.48
                                        color: root.pastelTone(root.accent3, 0.10, 1)
                                    }
                                    GradientStop {
                                        position: 1
                                        color: root.pastelTone(root.accent, 0.16, 1)
                                    }
                                }
                            }

                            Image {
                                id: settingsMediaGlavaArtField

                                anchors.fill: parent
                                source: root.mediaArt
                                sourceSize.width: 18
                                sourceSize.height: 18
                                fillMode: Image.Stretch
                                asynchronous: true
                                cache: false
                                smooth: true
                                mipmap: true
                                opacity: status === Image.Ready
                                    && source.toString().length > 0
                                    ? 0.96
                                    : 0
                            }

                            Rectangle {
                                anchors.fill: parent
                                opacity: settingsMediaGlavaArtField.status === Image.Ready
                                    ? 0.22
                                    : 0.10
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop {
                                        position: 0
                                        color: Qt.rgba(1, 1, 1, 0.42)
                                    }
                                    GradientStop {
                                        position: 0.42
                                        color: Qt.rgba(1, 1, 1, 0)
                                    }
                                    GradientStop {
                                        position: 1
                                        color: Qt.rgba(0.02, 0.025, 0.04, 0.24)
                                    }
                                }
                            }
                        }

                        ShaderEffectSource {
                            id: settingsMediaGlavaColorProxy

                            x: settingsMediaGlavaColorField.x
                            y: settingsMediaGlavaColorField.y
                            width: settingsMediaGlavaColorField.width
                            height: settingsMediaGlavaColorField.height
                            sourceItem: settingsMediaGlavaColorField
                            hideSource: true
                            live: false
                            recursive: true
                            visible: false
                        }

                        Canvas {
                            id: settingsMediaGlava

                            readonly property bool hasSignal: {
                                const values = root.cavaValues || []
                                for (let i = 0; i < values.length; ++i) {
                                    if (Number(values[i]) > 0.018)
                                        return true
                                }
                                return false
                            }
                            readonly property int sampleCount: 64
                            property var smoothedValues: []
                            readonly property color crestColor: root.pastelTone(
                                root.accent3,
                                root.theme && root.theme.themeMode === "light" ? 0.08 : 0.30,
                                1
                            )

                            x: 0
                            y: 0
                            width: settingsMediaCard.width
                            height: settingsMediaCard.height
                            z: 3
                            antialiasing: true
                            visible: false

                            function contourPoint(unit) {
                                const t = Math.max(0, Math.min(1, Number(unit) || 0))
                                // The outer GLava stroke is five pixels wide.
                                // Keeping its center 2.5 px from the edge makes
                                // it touch the card boundary without escaping it.
                                const inset = 2.5
                                const radius = Math.min(
                                    Math.max(1, settingsMediaCard.radius - inset),
                                    Math.max(14, height * 0.17)
                                )
                                const verticalLength = Math.max(
                                    1,
                                    height - inset * 2 - radius
                                )
                                const arcLength = radius * Math.PI / 2
                                const horizontalLength = Math.max(
                                    1,
                                    width - inset * 2 - radius
                                )
                                const totalLength = verticalLength
                                    + arcLength
                                    + horizontalLength
                                const distance = t * totalLength

                                if (distance <= verticalLength) {
                                    return {
                                        x: inset,
                                        y: inset + distance,
                                        nx: 1,
                                        ny: 0
                                    }
                                }

                                if (distance <= verticalLength + arcLength) {
                                    const arcUnit = (distance - verticalLength)
                                        / Math.max(1, arcLength)
                                    const angle = Math.PI - arcUnit * Math.PI / 2
                                    const centerX = inset + radius
                                    const centerY = height - inset - radius
                                    return {
                                        x: centerX + Math.cos(angle) * radius,
                                        y: centerY + Math.sin(angle) * radius,
                                        nx: -Math.cos(angle),
                                        ny: -Math.sin(angle)
                                    }
                                }

                                const horizontalDistance = distance
                                    - verticalLength
                                    - arcLength
                                return {
                                    x: inset + radius + horizontalDistance,
                                    y: height - inset,
                                    nx: 0,
                                    ny: -1
                                }
                            }

                            function waveformValue(index) {
                                if (smoothedValues
                                    && index >= 0
                                    && index < smoothedValues.length) {
                                    const smoothed = Number(smoothedValues[index])
                                    if (!isNaN(smoothed))
                                        return Math.max(0, Math.min(1, smoothed))
                                }

                                return rawSpectrumValue(index)
                            }

                            function rawSpectrumValue(index) {
                                const values = root.cavaValues || []
                                if (values.length <= 0)
                                    return 0

                                const unit = Math.max(
                                    0,
                                    Math.min(
                                        1,
                                        Number(index)
                                            / Math.max(1, sampleCount - 1)
                                    )
                                )
                                const position = unit * Math.max(0, values.length - 1)
                                const lowerIndex = Math.floor(position)
                                const upperIndex = Math.min(
                                    values.length - 1,
                                    lowerIndex + 1
                                )
                                const blend = position - lowerIndex
                                const lowerValue = Number(values[lowerIndex])
                                const upperValue = Number(values[upperIndex])
                                const safeLower = isNaN(lowerValue) ? 0 : lowerValue
                                const safeUpper = isNaN(upperValue)
                                    ? safeLower
                                    : upperValue
                                return Math.max(
                                    0,
                                    Math.min(
                                        1,
                                        safeLower
                                            + (safeUpper - safeLower) * blend
                                    )
                                )
                            }

                            function spectrumTone(unit) {
                                const t = Math.max(0, Math.min(1, Number(unit) || 0))
                                if (t < 0.5)
                                    return root.mixTone(root.accent2, root.accent3, t * 2, 1)
                                return root.mixTone(root.accent3, root.accent, (t - 0.5) * 2, 1)
                            }

                            function refreshSpectrum() {
                                const rawValues = []
                                const nextValues = []
                                const previousValues = smoothedValues || []

                                for (let i = 0; i < sampleCount; ++i) {
                                    rawValues.push(rawSpectrumValue(i))
                                }

                                for (let sampleIndex = 0;
                                        sampleIndex < sampleCount;
                                        ++sampleIndex) {
                                    const before = rawValues[Math.max(0, sampleIndex - 1)]
                                    const current = rawValues[sampleIndex]
                                    const after = rawValues[Math.min(
                                        sampleCount - 1,
                                        sampleIndex + 1
                                    )]
                                    const target = before * 0.16
                                        + current * 0.68
                                        + after * 0.16
                                    const oldValue = sampleIndex < previousValues.length
                                        ? Number(previousValues[sampleIndex])
                                        : target
                                    const safeOld = isNaN(oldValue) ? target : oldValue
                                    if (target >= safeOld) {
                                        nextValues.push(
                                            safeOld + (target - safeOld) * 0.64
                                        )
                                    } else {
                                        nextValues.push(Math.max(
                                            target,
                                            safeOld - 4.2 / 60
                                        ))
                                    }
                                }

                                smoothedValues = nextValues
                                requestPaint()
                            }

                            function traceLine(ctx, points) {
                                if (!points || points.length <= 0)
                                    return

                                ctx.beginPath()
                                ctx.moveTo(points[0].x, points[0].y)
                                for (let i = 1; i < points.length; ++i)
                                    ctx.lineTo(points[i].x, points[i].y)
                            }

                            onPaint: {
                                const ctx = getContext("2d")
                                const crest = []
                                const baseline = []
                                const count = Math.max(8, sampleCount)

                                ctx.reset()
                                ctx.clearRect(0, 0, width, height)

                                for (let i = 0; i < count; ++i) {
                                    const unit = i / Math.max(1, count - 1)
                                    const pathPoint = contourPoint(unit)
                                    const signal = waveformValue(i)
                                    const amplitude = height * 0.008
                                        + Math.pow(signal, 0.72) * height * 0.285

                                    baseline.push({
                                        x: pathPoint.x,
                                        y: pathPoint.y
                                    })
                                    crest.push({
                                        x: pathPoint.x + pathPoint.nx * amplitude,
                                        y: pathPoint.y + pathPoint.ny * amplitude
                                    })
                                }

                                ctx.save()
                                ctx.lineCap = "butt"
                                ctx.lineJoin = "round"
                                for (let barIndex = 0;
                                        barIndex < crest.length;
                                        ++barIndex) {
                                    const basePoint = baseline[barIndex]
                                    const crestPoint = crest[barIndex]
                                    const unit = barIndex
                                        / Math.max(1, crest.length - 1)
                                    const normalX = crestPoint.x - basePoint.x
                                    const normalY = crestPoint.y - basePoint.y
                                    const normalLength = Math.max(
                                        0.001,
                                        Math.sqrt(
                                            normalX * normalX
                                                + normalY * normalY
                                        )
                                    )

                                    ctx.beginPath()
                                    ctx.moveTo(basePoint.x, basePoint.y)
                                    ctx.lineTo(crestPoint.x, crestPoint.y)
                                    ctx.lineWidth = 5
                                    ctx.strokeStyle = hasSignal
                                        ? "rgba(255,255,255,0.72)"
                                        : "rgba(255,255,255,0.34)"
                                    ctx.stroke()

                                    ctx.beginPath()
                                    ctx.moveTo(basePoint.x, basePoint.y)
                                    ctx.lineTo(crestPoint.x, crestPoint.y)
                                    ctx.lineWidth = 3
                                    ctx.strokeStyle = hasSignal
                                        ? "rgba(255,255,255,1)"
                                        : "rgba(255,255,255,0.52)"
                                    ctx.stroke()
                                }

                                traceLine(ctx, baseline)
                                ctx.lineWidth = 1
                                ctx.strokeStyle = hasSignal
                                    ? "rgba(255,255,255,0.84)"
                                    : "rgba(255,255,255,0.38)"
                                ctx.stroke()
                                ctx.restore()
                            }

                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                            onCrestColorChanged: requestPaint()
                            Component.onCompleted: refreshSpectrum()

                            Connections {
                                target: root
                                enabled: false

                                function onCavaValuesChanged() {
                                    settingsMediaGlava.refreshSpectrum()
                                }
                            }
                        }

                        OpacityMask {
                            x: settingsMediaGlava.x
                            y: settingsMediaGlava.y
                            width: settingsMediaGlava.width
                            height: settingsMediaGlava.height
                            source: settingsMediaGlavaColorProxy
                            maskSource: settingsMediaGlava
                            cached: false
                            z: 3
                            visible: false
                            opacity: settingsMediaCard.lyricsRevealed
                                ? 0.12
                                : (settingsMediaGlava.hasSignal ? 0.98 : 0.52)

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: root.systemMotionEnabled ? 220 : 1
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        VeloraGlavaTopSpectrum {
                            id: settingsMediaTopSpectrum

                            x: 13
                            y: settingsMediaCard.height - height - 6
                            width: Math.max(1, settingsMediaCard.width - 26)
                            height: 54
                            z: 3
                            theme: root.theme
                            values: root.cavaValues
                            active: root.open
                                && root.popupType === "system"
                                && root.systemPage === "settings"
                            growUpward: true
                            referenceHeight: height
                            strength: root.theme
                                ? Math.max(
                                    0.42,
                                    Math.min(
                                        0.88,
                                        Number(root.theme.visualizerStrength) * 0.84
                                    )
                                )
                                : 0.78
                            opacity: settingsMediaCard.lyricsRevealed ? 0.10 : 0.90

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: root.systemMotionEnabled ? 180 : 1
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Item {
                            id: settingsMediaLyrics

                            readonly property string activeWord: {
                                const words = root.lyricsWords || []
                                if (!root.lyricsAvailable || words.length <= 0)
                                    return ""

                                const index = Math.max(
                                    0,
                                    Math.min(words.length - 1, Number(root.lyricsActiveIndex) || 0)
                                )
                                return String(words[index] || "").trim()
                            }

                            x: Math.round(settingsMediaCard.width * 0.66) + 8
                            y: 10
                            width: Math.max(76, settingsMediaCard.width - x - 10)
                            height: 86
                            z: 4
                            opacity: settingsMediaCard.lyricsRevealed ? 1 : 0
                            clip: true

                            transform: Translate {
                                x: settingsMediaCard.lyricsRevealed ? 0 : 12

                                Behavior on x {
                                    NumberAnimation {
                                        duration: root.systemMotionEnabled ? 300 : 1
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: root.systemMotionEnabled ? 260 : 1
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Row {
                                x: 2
                                y: 3
                                spacing: 5

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: root.pastelTone(root.accent, 0.18, 1)
                                }
                                Text {
                                    text: "VELYRICS"
                                    color: root.alpha(root.inkSoft, 0.74)
                                    font.family: root.monoFont
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.7
                                }
                            }

                            Text {
                                id: settingsLyricsActiveWord
                                x: 2
                                y: 20
                                width: parent.width - 4
                                height: 62
                                visible: settingsMediaLyrics.activeWord.length > 0
                                text: settingsMediaLyrics.activeWord
                                color: root.pastelTone(root.accent, 0.10, 1)
                                font.family: root.uiFont
                                font.pixelSize: 28
                                font.weight: Font.Bold
                                fontSizeMode: Text.Fit
                                minimumPixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.NoWrap
                                style: Text.Outline
                                styleColor: Qt.rgba(0.01, 0.015, 0.02, 0.72)
                                transformOrigin: Item.Center

                                onTextChanged: {
                                    if (root.systemMotionEnabled
                                            && settingsMediaCard.lyricsRevealed) {
                                        settingsLyricsWordArrival.restart()
                                    } else {
                                        opacity = 1
                                        scale = 1
                                    }
                                }
                            }

                            ParallelAnimation {
                                id: settingsLyricsWordArrival

                                NumberAnimation {
                                    target: settingsLyricsActiveWord
                                    property: "opacity"
                                    from: 0.28
                                    to: 1
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                                NumberAnimation {
                                    target: settingsLyricsActiveWord
                                    property: "scale"
                                    from: 1.08
                                    to: 1
                                    duration: 190
                                    easing.type: Easing.OutBack
                                }
                            }

                            Text {
                                x: 2
                                y: 21
                                width: parent.width - 4
                                height: 60
                                visible: settingsMediaLyrics.activeWord.length <= 0
                                text: root.controlCenterLyricsFallback()
                                color: root.ink
                                font.family: root.uiFont
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                style: Text.Outline
                                styleColor: Qt.rgba(0.01, 0.015, 0.02, 0.64)
                            }
                        }

                        ControlCenterVinyl {
                            id: settingsMediaVinyl

                            width: 200
                            height: 200
                            x: settingsMediaCard.lyricsRevealed
                                ? -30
                                : settingsMediaCard.width - width + 30
                            y: Math.round((settingsMediaCard.height - height) / 2)
                            z: 6
                            playing: root.mediaPlaying
                            emphasized: settingsMediaCard.lyricsRevealed
                            opacity: root.mediaAvailable ? 1 : 0.46

                            Behavior on x {
                                NumberAnimation {
                                    duration: root.systemMotionEnabled ? 380 : 1
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: root.systemMotionEnabled ? 220 : 1
                                }
                            }
                        }

                        Item {
                            id: settingsVinylHoverZone

                            x: settingsMediaCard.lyricsRevealed
                                ? 0
                                : Math.max(0, settingsMediaCard.width - 214)
                            y: 0
                            width: settingsMediaCard.width - x
                            height: settingsMediaCard.height
                            z: 9

                            HoverHandler {
                                id: settingsVinylHover
                                cursorShape: Qt.PointingHandCursor
                            }
                        }

                        ColumnLayout {
                            z: 10
                            anchors { fill: parent; margins: 12 }
                            spacing: 4

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 38

                                Column {
                                    id: settingsMediaMeta

                                    anchors {
                                        left: parent.left
                                        leftMargin: 80
                                        right: parent.right
                                        rightMargin: Math.round(settingsMediaCard.width * 0.48)
                                        verticalCenter: parent.verticalCenter
                                    }
                                    spacing: 1
                                    opacity: settingsMediaCard.lyricsRevealed ? 0 : 1

                                    transform: Translate {
                                        x: settingsMediaCard.lyricsRevealed ? -8 : 0

                                        Behavior on x {
                                            NumberAnimation {
                                                duration: root.systemMotionEnabled ? 220 : 1
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: root.systemMotionEnabled ? 160 : 1
                                        }
                                    }

                                    Text {
                                        width: parent.width
                                        text: root.mediaTitle
                                        color: root.ink
                                        font.family: root.uiFont
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                        style: Text.Outline
                                        styleColor: Qt.rgba(0.01, 0.015, 0.02, 0.76)
                                    }
                                    Text {
                                        width: parent.width
                                        text: root.mediaArtist
                                        color: root.inkSoft
                                        font.family: root.uiFont
                                        font.pixelSize: 9
                                        elide: Text.ElideRight
                                        style: Text.Outline
                                        styleColor: Qt.rgba(0.01, 0.015, 0.02, 0.72)
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }

                            RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    TransportButton { action: "previous"; enabledControl: root.mediaAvailable; onTriggered: root.previousMedia() }
                                    Item { Layout.fillWidth: true }
                                    TransportButton { action: root.mediaPlaying ? "pause" : "play"; enabledControl: root.mediaAvailable; onTriggered: root.toggleMedia() }
                                    Item { Layout.fillWidth: true }
                                    TransportButton { action: "next"; enabledControl: root.mediaAvailable; onTriggered: root.nextMedia() }
                            }
                        }
                    }

                    VerticalQuickControl {
                        Layout.fillHeight: true
                        iconName: "sun"
                        fillColor: root.accent
                        secondaryFillColor: root.accent3
                        value: root.brightnessPercent
                        onMoved: function(value) { root.setBrightness(value) }
                    }
                    VerticalQuickControl {
                        Layout.fillHeight: true
                        iconName: root.muted ? "volume-muted" : "volume"
                        fillColor: root.accent2
                        secondaryFillColor: root.accent3
                        value: root.volumePercent
                        onMoved: function(value) { root.setVolume(value) }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    spacing: 8

                    RightConnectionPill {
                        Layout.fillWidth: true
                        iconName: root.powerProfile === "power-saver" ? "leaf" : "bolt"
                        accentColor: root.accent2
                        secondaryAccentColor: root.accent
                        title: root.powerProfileLabel(root.powerProfile)
                        subtitle: "Modo de energia"
                        active: root.powerProfile !== "balanced"
                        onTriggered: root.cyclePowerProfile()
                    }
                    RightConnectionPill {
                        Layout.fillWidth: true
                        iconName: "sun"
                        accentColor: root.accent3
                        secondaryAccentColor: root.accent2
                        title: "Luz noturna"
                        subtitle: root.nightLight ? "Ativada" : "Desativada"
                        active: root.nightLight
                        onTriggered: root.toggleNightLight()
                    }
                }

                Item {
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0
                    visible: !root.rightActionsExpanded
                }

                Item {
                    id: bottomActionsCard

                    Layout.fillWidth: true
                    Layout.preferredHeight: root.rightActionsExpanded ? 336 : 84

                    Behavior on Layout.preferredHeight {
                        NumberAnimation {
                            duration: root.systemMotionEnabled ? 260 : 1
                            easing.type: Easing.OutCubic
                        }
                    }

                    DropShadow {
                        anchors.fill: bottomActionsSurface
                        source: bottomActionsSurface
                        horizontalOffset: 0
                        verticalOffset: 5
                        radius: 15
                        samples: 31
                        color: Qt.rgba(0, 0, 0, 0.24)
                        transparentBorder: true
                        z: -1
                    }

                    Rectangle {
                        id: bottomActionsSurface
                        anchors.fill: parent
                        radius: 26
                        color: "transparent"
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop {
                                position: 0
                                color: root.systemTone(root.accent3, 0.12, 0.46)
                            }
                            GradientStop {
                                position: 0.52
                                color: root.systemTone(root.accent, 0.08, 0.38)
                            }
                            GradientStop {
                                position: 1
                                color: root.systemTone(root.accent2, 0.12, 0.46)
                            }
                        }
                        border.width: 1
                        border.color: root.alpha(root.inkSoft, 0.24)
                    }

                    ColumnLayout {
                        anchors {
                            fill: parent
                            leftMargin: 12
                            rightMargin: 12
                            topMargin: 10
                            bottomMargin: 10
                        }
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 62
                            spacing: 8

                            RightPriorityAction {
                                Layout.fillWidth: true
                                iconName: "power"
                                tooltip: "Desligar"
                                onTriggered: root.runCommand("if command -v wlogout >/dev/null 2>&1; then setsid -f wlogout >/dev/null 2>&1; fi")
                            }
                            RightPriorityAction {
                                Layout.fillWidth: true
                                iconName: "lock"
                                tooltip: "Bloquear"
                                onTriggered: root.runCommand("loginctl lock-session >/dev/null 2>&1 || true")
                            }
                            RightPriorityAction {
                                Layout.fillWidth: true
                                iconName: root.micMuted ? "mic-muted" : "mic"
                                tooltip: root.micMuted ? "Ativar microfone" : "Silenciar microfone"
                                active: root.micMuted
                                onTriggered: root.toggleMicMute()
                            }
                            RightPriorityAction {
                                Layout.fillWidth: true
                                iconName: "display"
                                tooltip: "Tela"
                                onTriggered: root.systemPageRequested("display")
                            }
                            RightPriorityAction {
                                Layout.fillWidth: true
                                tooltip: root.rightActionsExpanded ? "Recolher" : "Mais ações"
                                expandControl: true
                                expanded: root.rightActionsExpanded
                                onTriggered: root.setRightActionsExpanded(!root.rightActionsExpanded)
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 4
                            columnSpacing: 8
                            rowSpacing: 2
                            visible: root.rightActionsExpanded
                            opacity: root.rightActionsExpanded ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: root.systemMotionEnabled ? 180 : 1
                                }
                            }

                            RightQuickAction { Layout.fillWidth: true; iconName: "airplane"; label: "Modo avião"; active: root.airplaneMode; onTriggered: root.toggleAirplane() }
                            RightQuickAction { Layout.fillWidth: true; iconName: "moon"; label: "Não perturbe"; active: root.doNotDisturb; onTriggered: root.toggleDnd() }
                            RightQuickAction { Layout.fillWidth: true; iconName: "battery"; label: "Economia"; active: root.powerProfile === "power-saver"; onTriggered: root.setPowerProfile(root.powerProfile === "power-saver" ? "balanced" : "power-saver") }
                            RightQuickAction { Layout.fillWidth: true; iconName: root.muted ? "volume-muted" : "volume"; label: "Som"; active: root.muted; onTriggered: root.systemPageRequested("volume") }

                            RightQuickAction { Layout.fillWidth: true; iconName: "notifications"; label: "Notificações"; active: root.doNotDisturb; onTriggered: root.systemPageRequested("notifications") }
                            RightQuickAction { Layout.fillWidth: true; iconName: "battery"; label: "Bateria"; active: root.batteryAcOnline; onTriggered: root.systemPageRequested("battery") }
                            RightQuickAction { Layout.fillWidth: true; iconName: "screenshot"; label: "Captura"; onTriggered: root.runCommand("if command -v velora-screenshot-select >/dev/null 2>&1; then setsid -f velora-screenshot-select select >/dev/null 2>&1; fi") }
                            RightQuickAction { Layout.fillWidth: true; iconName: "search"; label: "Busca"; onTriggered: root.popupRequested("search") }

                            RightQuickAction { Layout.fillWidth: true; iconName: "palette"; label: "Tema e cores"; onTriggered: root.popupRequested("theme") }
                            RightQuickAction { Layout.fillWidth: true; iconName: "pencil"; label: "Editar"; onTriggered: root.popupRequested("theme") }
                            RightQuickAction { Layout.fillWidth: true; iconName: "settings"; label: "Configurações"; onTriggered: root.advancedSettingsRequested() }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: rightSettingsView

        Item {
            anchors.fill: parent

            ColumnLayout {
                anchors {
                    fill: parent
                    leftMargin: 18
                    rightMargin: 18
                    topMargin: 16
                    bottomMargin: 16
                }
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    spacing: 8

                    RightConnectionPill {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        iconName: root.wifiEnabled ? "wifi" : "wifi-off"
                        accentColor: root.accent
                        secondaryAccentColor: root.accent3
                        title: root.wifiSsid.length > 0 ? root.wifiSsid : "Wi‑Fi"
                        subtitle: root.wifiSsid.length > 0 ? "Conectado" : (root.wifiEnabled ? "Disponível" : "Desativado")
                        active: root.wifiEnabled && root.wifiSsid.length > 0
                        onTriggered: root.systemPageRequested("wifi")
                    }
                    RightConnectionPill {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        iconName: "bluetooth"
                        accentColor: root.accent2
                        secondaryAccentColor: root.accent
                        title: root.connectedBluetoothName()
                        subtitle: root.bluetoothPowered ? (root.connectedBluetoothName() === "Bluetooth" ? "Ativado" : "Conectado") : "Desativado"
                        active: root.bluetoothPowered
                        onTriggered: root.systemPageRequested("bluetooth")
                    }
                }

                Rectangle {
                    id: rightMediaCard
                    property real mediaGradientPhase: 0

                    function gradientTone(offset) {
                        const first = root.systemTone(root.accent, root.mediaPlaying ? 0.50 : 0.34, root.mediaPlaying ? 0.70 : 0.60)
                        const middle = root.systemTone(root.accent3, root.mediaPlaying ? 0.43 : 0.28, root.mediaPlaying ? 0.66 : 0.56)
                        const last = root.systemTone(root.accent2, root.mediaPlaying ? 0.48 : 0.31, root.mediaPlaying ? 0.68 : 0.58)
                        const wrapped = mediaGradientPhase + Number(offset || 0)
                        const segment = (wrapped - Math.floor(wrapped)) * 3
                        if (segment < 1)
                            return root.mixTone(first, middle, segment, first.a + (middle.a - first.a) * segment)
                        if (segment < 2) {
                            const amount = segment - 1
                            return root.mixTone(middle, last, amount, middle.a + (last.a - middle.a) * amount)
                        }
                        const amount = segment - 2
                        return root.mixTone(last, first, amount, last.a + (first.a - last.a) * amount)
                    }

                    Layout.fillWidth: true
                    Layout.preferredHeight: 160
                    radius: 28
                    clip: true
                    color: root.systemTone(root.accent2, 0.26, 0.48)
                    border.width: 1
                    border.color: root.outlineVariant

                    Rectangle {
                        anchors.fill: parent
                        radius: rightMediaCard.radius
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: rightMediaCard.gradientTone(0) }
                            GradientStop { position: 0.34; color: rightMediaCard.gradientTone(0.34) }
                            GradientStop { position: 0.68; color: rightMediaCard.gradientTone(0.68) }
                            GradientStop { position: 1; color: rightMediaCard.gradientTone(1) }
                        }
                    }

                    NumberAnimation on mediaGradientPhase {
                        from: 0
                        to: 1
                        duration: 9000
                        loops: Animation.Infinite
                        easing.type: Easing.Linear
                        running: root.open && root.rightControlCenter && root.systemMotionEnabled
                    }

                    Image {
                        id: rightMediaArt
                        x: 1
                        y: 1
                        width: Math.round(rightMediaCard.width * 0.66)
                        height: rightMediaCard.height - 2
                        source: root.mediaArt
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        visible: false
                    }

                    Rectangle {
                        id: rightMediaArtMask
                        x: rightMediaArt.x
                        y: rightMediaArt.y
                        width: rightMediaArt.width
                        height: rightMediaArt.height
                        radius: Math.max(0, rightMediaCard.radius - 1)
                        visible: false
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: "white" }
                            GradientStop { position: 0.70; color: "white" }
                            GradientStop { position: 1; color: "transparent" }
                        }
                    }

                    OpacityMask {
                        anchors.fill: rightMediaArt
                        source: rightMediaArt
                        maskSource: rightMediaArtMask
                        visible: rightMediaArt.status === Image.Ready && rightMediaArt.source.toString().length > 0
                        opacity: 0.82
                    }

                    Rectangle {
                        x: rightMediaArt.x
                        y: rightMediaArt.y
                        width: rightMediaArt.width
                        height: rightMediaArt.height
                        radius: Math.max(0, rightMediaCard.radius - 1)
                        visible: rightMediaArt.status !== Image.Ready || rightMediaArt.source.toString().length <= 0
                        color: root.alpha(root.surfaceContainerHigh, 0.58)
                        VeloraMaterialIcon { anchors.centerIn: parent; width: 44; height: 44; iconName: "music"; iconColor: root.inkSoft; filled: true }
                    }

                    Column {
                        x: 16
                        y: 17
                        width: 132
                        spacing: 3
                        z: 8

                        Text { width: parent.width; text: root.mediaTitle; color: root.ink; font.family: root.uiFont; font.pixelSize: 14; font.weight: Font.DemiBold; elide: Text.ElideRight }
                        Text { width: parent.width; text: root.mediaArtist; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 11; elide: Text.ElideRight }
                    }

                    VeloraGlavaTopSpectrum {
                        x: 12
                        y: rightMediaCard.height - height - 5
                        width: parent.width - 24
                        height: 48
                        z: 3
                        theme: root.theme
                        values: root.cavaValues
                        active: root.open && root.rightControlCenter
                        growUpward: true
                        referenceHeight: height
                        strength: root.theme ? Math.max(0.42, Math.min(0.88, Number(root.theme.visualizerStrength) * 0.84)) : 0.78
                        opacity: 0.86
                    }

                    Row {
                        x: 14
                        y: 88
                        width: 138
                        height: 18
                        z: 8

                        Text { width: 34; text: root.formatTime(root.mediaPosition); color: root.inkSoft; font.family: root.monoFont; font.pixelSize: 8 }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 68
                            height: 4
                            radius: 2
                            color: root.alpha(root.inkSoft, 0.18)
                            Rectangle { width: parent.width * root.mediaProgress; height: parent.height; radius: parent.radius; color: root.pastelTone(root.accent, 0.18, 1) }
                        }
                        Text { width: 34; text: root.formatTime(root.mediaLength); color: root.inkSoft; font.family: root.monoFont; font.pixelSize: 8; horizontalAlignment: Text.AlignRight }
                    }

                    RowLayout {
                        x: 10
                        y: 108
                        width: 148
                        height: 38
                        spacing: 4
                        z: 9

                        Item { Layout.fillWidth: true }
                        TransportButton { action: "previous"; enabledControl: root.mediaAvailable; onTriggered: root.previousMedia() }
                        TransportButton { action: root.mediaPlaying ? "pause" : "play"; enabledControl: root.mediaAvailable; onTriggered: root.toggleMedia() }
                        TransportButton { action: "next"; enabledControl: root.mediaAvailable; onTriggered: root.nextMedia() }
                        Item { Layout.fillWidth: true }
                    }

                    Item {
                        id: rightVinylSource
                        anchors.fill: parent
                        visible: false

                        ControlCenterVinyl {
                            width: 165
                            height: 165
                            x: rightMediaCard.width - width + 65
                            y: Math.round((rightMediaCard.height - height) / 2)
                            playing: root.mediaPlaying
                            emphasized: false
                            animateAsEffectSource: true
                            opacity: root.mediaAvailable ? 1 : 0.46
                        }
                    }

                    Rectangle {
                        id: rightMediaRoundedMask
                        anchors.fill: parent
                        radius: rightMediaCard.radius
                        color: "white"
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: rightVinylSource
                        maskSource: rightMediaRoundedMask
                        cached: false
                        z: 6
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: rightMediaCard.radius
                        color: "transparent"
                        border.width: 1
                        border.color: root.outlineVariant
                        z: 20
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 164
                    spacing: 8

                    Item {
                        id: rightVerticalControls

                        Layout.preferredWidth: 148
                        Layout.fillHeight: true

                        DropShadow {
                            anchors.fill: rightVerticalControlsSurface
                            source: rightVerticalControlsSurface
                            horizontalOffset: 0
                            verticalOffset: 4
                            radius: 14
                            samples: 29
                            color: Qt.rgba(0, 0, 0, 0.25)
                            transparentBorder: true
                        }

                        Rectangle {
                            id: rightVerticalControlsSurface

                            anchors.fill: parent
                            radius: 28
                            clip: true
                            color: "transparent"
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop {
                                    position: 0
                                    color: root.systemTone(root.accent3, 0.055, 0.39)
                                }
                                GradientStop {
                                    position: 1
                                    color: root.systemTone(root.accent2, 0.045, 0.35)
                                }
                            }
                            border.width: 1
                            border.color: root.alpha(root.inkSoft, 0.28)

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: 1
                                }
                                height: 45
                                radius: Math.max(0, parent.radius - 1)
                                color: root.alpha(root.ink, 0.032)
                            }

                            Rectangle {
                                anchors {
                                    horizontalCenter: parent.horizontalCenter
                                    top: parent.top
                                    bottom: parent.bottom
                                    topMargin: 1
                                    bottomMargin: 1
                                }
                                width: 1
                                color: root.alpha(root.inkSoft, 0.17)
                            }
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 5
                                rightMargin: 5
                            }
                            spacing: 4

                            RightVerticalTrack {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                iconName: "sun"
                                fillColor: root.accent
                                secondaryFillColor: root.accent3
                                value: root.brightnessPercent
                                onMoved: function(value) { root.setBrightness(value) }
                            }
                            RightVerticalTrack {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                iconName: root.muted ? "volume-muted" : "volume"
                                fillColor: root.accent2
                                secondaryFillColor: root.accent3
                                value: root.volumePercent
                                onMoved: function(value) { root.setVolume(value) }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 8

                        RightClockCard {
                            Layout.fillWidth: true
                            onTriggered: root.popupRequested("time")
                        }
                        RightBatteryCard {
                            Layout.fillWidth: true
                            onTriggered: root.systemPageRequested("battery")
                        }
                    }
                }

                Rectangle {
                    id: rightActionsCard

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: root.rightActionsExpanded ? 280 : 84
                    radius: 30
                    color: "transparent"
                    border.width: 1
                    border.color: root.alpha(
                        root.outlineVariant,
                        root.rightActionsExpanded ? 0.24 : 0.32
                    )
                    clip: true

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            leftMargin: 18
                            rightMargin: 18
                            topMargin: 8
                        }
                        height: 1
                        radius: 0.5
                        color: root.alpha(root.inkSoft, 0.22)
                    }

                    RowLayout {
                        id: priorityActionsRow

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            leftMargin: 10
                            rightMargin: 10
                            topMargin: 13
                        }
                        height: 60
                        spacing: 5

                        RightPriorityAction {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            iconName: "power"
                            tooltip: "Desligar"
                            accentColor: root.accent
                            secondaryAccentColor: root.accent2
                            onTriggered: root.runCommand("if command -v wlogout >/dev/null 2>&1; then setsid -f wlogout >/dev/null 2>&1; fi")
                        }
                        RightPriorityAction {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            iconName: "lock"
                            tooltip: "Bloquear"
                            accentColor: root.accent3
                            secondaryAccentColor: root.accent2
                            onTriggered: root.runCommand("loginctl lock-session >/dev/null 2>&1 || true")
                        }
                        RightPriorityAction {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            iconName: root.micMuted ? "mic-muted" : "mic"
                            tooltip: root.micMuted ? "Ativar microfone" : "Bloquear microfone"
                            active: root.micMuted
                            accentColor: root.accent2
                            secondaryAccentColor: root.accent3
                            onTriggered: root.toggleMicMute()
                        }
                        RightPriorityAction {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            iconName: "display"
                            tooltip: "Tela"
                            accentColor: root.accent3
                            secondaryAccentColor: root.accent
                            onTriggered: root.systemPageRequested("display")
                        }
                        RightPriorityAction {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            tooltip: root.rightActionsExpanded ? "Recolher" : "Expandir"
                            expandControl: true
                            expanded: root.rightActionsExpanded
                            accentColor: root.accent
                            secondaryAccentColor: root.accent3
                            onTriggered: root.setRightActionsExpanded(!root.rightActionsExpanded)
                        }
                    }

                    Item {
                        id: expandedActionsPane

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: priorityActionsRow.bottom
                            bottom: parent.bottom
                            leftMargin: 10
                            rightMargin: 10
                            topMargin: 13
                            bottomMargin: 10
                        }
                        enabled: root.rightActionsExpanded
                        opacity: root.rightActionsExpanded ? 1 : 0
                        scale: root.rightActionsExpanded ? 1 : 0.985
                        transformOrigin: Item.Top

                        Behavior on opacity {
                            NumberAnimation {
                                duration: root.systemMotionEnabled ? 190 : 1
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: root.systemMotionEnabled ? 220 : 1
                                easing.type: Easing.OutCubic
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8

                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 4
                            columnSpacing: 6
                            rowSpacing: 4

                            RightQuickAction { Layout.fillWidth: true; Layout.fillHeight: true; iconName: "airplane"; label: "Modo avião"; active: root.airplaneMode; accentColor: root.accent; secondaryAccentColor: root.accent3; onTriggered: root.toggleAirplane() }
                            RightQuickAction { Layout.fillWidth: true; Layout.fillHeight: true; iconName: "moon"; label: "Não perturbe"; active: root.doNotDisturb; accentColor: root.accent2; secondaryAccentColor: root.accent; onTriggered: root.toggleDnd() }
                            RightQuickAction { Layout.fillWidth: true; Layout.fillHeight: true; iconName: "battery"; label: "Economia de\nenergia"; active: root.powerProfile === "power-saver"; accentColor: root.accent; secondaryAccentColor: root.accent2; onTriggered: root.setPowerProfile(root.powerProfile === "power-saver" ? "balanced" : "power-saver") }

                            RightQuickAction { Layout.fillWidth: true; Layout.fillHeight: true; iconName: "volume"; label: "Som"; accentColor: root.accent2; secondaryAccentColor: root.accent3; onTriggered: root.systemPageRequested("volume") }
                            RightQuickAction { Layout.fillWidth: true; Layout.fillHeight: true; iconName: "notifications"; label: "Notificações"; active: root.doNotDisturb; accentColor: root.accent; secondaryAccentColor: root.accent2; onTriggered: root.systemPageRequested("notifications") }
                            RightQuickAction { Layout.fillWidth: true; Layout.fillHeight: true; iconName: "screenshot"; label: "Captura de tela"; accentColor: root.accent2; secondaryAccentColor: root.accent; onTriggered: root.runCommand("if command -v velora-screenshot-select >/dev/null 2>&1; then setsid -f velora-screenshot-select select >/dev/null 2>&1; fi") }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 3
                            columnSpacing: 6
                            rowSpacing: 4

                            RightQuickAction { Layout.fillWidth: true; Layout.fillHeight: true; iconName: "palette"; label: "Tema e cores"; accentColor: root.accent2; secondaryAccentColor: root.accent3; onTriggered: root.popupRequested("theme") }
                            RightQuickAction { Layout.fillWidth: true; Layout.fillHeight: true; iconName: "search"; label: "Buscar"; accentColor: root.accent; secondaryAccentColor: root.accent2; onTriggered: root.popupRequested("search") }

                            RightQuickAction { Layout.fillWidth: true; Layout.fillHeight: true; iconName: "pencil"; label: "Editar"; accentColor: root.accent3; secondaryAccentColor: root.accent; onTriggered: root.popupRequested("theme") }
                            RightQuickAction { Layout.fillWidth: true; Layout.fillHeight: true; iconName: "settings"; label: "Configurações"; accentColor: root.accent2; secondaryAccentColor: root.accent3; onTriggered: root.advancedSettingsRequested() }
                        }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: workspacesView

        Item {
            ColumnLayout {
                anchors { fill: parent; margins: 20 }
                spacing: 14

                PopupTitle {
                    Layout.fillWidth: true
                    title: "Áreas de trabalho"
                    subtitle: "Selecione um workspace do Hyprland"
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 2
                    rowSpacing: 12
                    columnSpacing: 12

                    Repeater {
                        model: 4

                        Rectangle {
                            required property int index
                            readonly property int workspaceNumber: index + 1
                            readonly property bool workspaceActive: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === workspaceNumber
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 14
                            color: workspaceActive ? root.alpha(root.accent, 0.17) : (workspaceMouse.containsMouse ? root.cardHover : root.card)
                            border.width: workspaceActive ? 2 : 1
                            border.color: workspaceActive ? root.accent : root.line

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 7
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: String(parent.parent.workspaceNumber)
                                    color: parent.parent.workspaceActive ? root.accent : root.ink
                                    font.family: root.monoFont
                                    font.pixelSize: 26
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: parent.parent.workspaceActive ? "Ativo" : "Workspace"
                                    color: root.inkSoft
                                    font.family: root.uiFont
                                    font.pixelSize: 10
                                }
                            }

                            MouseArea {
                                id: workspaceMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Hyprland.dispatch("workspace " + parent.workspaceNumber)
                                    root.closeRequested()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: appsView

        Item {
            Connections {
                target: root
                function onAppFocusRequestChanged() {
                    Qt.callLater(function() { appSearch.forceActiveFocus() })
                }
            }

            ColumnLayout {
                anchors { fill: parent; margins: 18 }
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: 11
                    color: root.card
                    border.width: 1
                    border.color: appSearch.activeFocus ? root.alpha(root.accent, 0.60) : root.line

                    RowLayout {
                        anchors { fill: parent; leftMargin: 13; rightMargin: 13 }
                        spacing: 9
                        Text { text: "⌕"; color: root.inkSoft; font.family: root.monoFont; font.pixelSize: 18 }
                        TextInput {
                            id: appSearch
                            Layout.fillWidth: true
                            text: root.appQuery
                            color: root.ink
                            font.family: root.uiFont
                            font.pixelSize: 11
                            selectByMouse: true
                            clip: true
                            onTextEdited: root.appQuery = text
                            Keys.onEscapePressed: root.closeRequested()

                            Text {
                                anchors.fill: parent
                                visible: appSearch.text.length <= 0
                                text: "Buscar aplicativos..."
                                color: root.alpha(root.inkSoft, 0.58)
                                font: appSearch.font
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 4
                    rowSpacing: 8
                    columnSpacing: 8

                    Repeater {
                        model: root.appResults

                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 12
                            color: appMouse.containsMouse ? root.cardHover : "transparent"

                            ColumnLayout {
                                anchors { fill: parent; margins: 7 }
                                spacing: 5
                                Image {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: 36
                                    Layout.preferredHeight: 36
                                    source: Quickshell.iconPath(modelData ? modelData.icon : "", "application-x-executable")
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData ? String(modelData.name || "App") : "App"
                                    color: root.ink
                                    font.family: root.uiFont
                                    font.pixelSize: 9
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }

                            MouseArea {
                                id: appMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.launchApp(parent.modelData)
                            }
                        }
                    }
                }
            }

            Component.onCompleted: Qt.callLater(function() { appSearch.forceActiveFocus() })
        }
    }

    Component {
        id: mediaView

        Item {
            Rectangle {
                anchors.fill: parent
                anchors.margins: 8
                radius: 28
                color: root.surfaceContainer
                border.width: 1
                border.color: root.outlineVariant
            }

            RowLayout {
                anchors { fill: parent; margins: 24 }
                spacing: 20

                Rectangle {
                    id: coverFrame
                    Layout.preferredWidth: 184
                    Layout.preferredHeight: 184
                    Layout.alignment: Qt.AlignVCenter
                    radius: 28
                    color: root.surfaceContainerHigh
                    border.width: 1
                    border.color: root.outlineVariant
                    clip: true

                    Image {
                        id: coverImage
                        anchors.fill: parent
                        source: root.mediaArt
                        visible: false
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                    }
                    Rectangle { id: coverMask; anchors.fill: parent; radius: coverFrame.radius; visible: false }
                    OpacityMask { anchors.fill: parent; source: coverImage; maskSource: coverMask; visible: coverImage.status === Image.Ready && coverImage.source.toString().length > 0 }
                    VeloraMaterialIcon { anchors.centerIn: parent; width: 58; height: 58; visible: coverImage.status !== Image.Ready || coverImage.source.toString().length <= 0; iconName: "play"; iconColor: root.inkSoft; filled: true }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.lyricsAvailable ? 285 : 430
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 10

                    Text { Layout.fillWidth: true; text: root.mediaTitle; color: root.ink; font.family: root.uiFont; font.pixelSize: 20; font.weight: Font.Bold; elide: Text.ElideRight }
                    Text { Layout.fillWidth: true; text: root.mediaArtist; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 13; font.weight: Font.Medium; elide: Text.ElideRight }

                    Rectangle {
                        Layout.preferredWidth: deviceRow.implicitWidth + 24
                        Layout.preferredHeight: 34
                        radius: 17
                        color: root.primaryContainer
                        RowLayout {
                            id: deviceRow
                            anchors.centerIn: parent
                            spacing: 7
                            VeloraMaterialIcon { Layout.preferredWidth: 18; Layout.preferredHeight: 18; iconName: "devices"; iconColor: root.onPrimaryContainer; filled: true }
                            Text { text: "Dispositivo padrão"; color: root.onPrimaryContainer; font.family: root.uiFont; font.pixelSize: 10; font.weight: Font.DemiBold }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: root.formatTime(root.mediaPosition); color: root.inkSoft; font.family: root.monoFont; font.pixelSize: 10 }
                        Item {
                            id: seekTrack
                            Layout.fillWidth: true
                            Layout.preferredHeight: 18
                            Rectangle {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                }
                                height: 10
                                radius: 5
                                color: root.alpha(root.inkSoft, 0.16)

                                Rectangle {
                                    width: parent.width * root.mediaProgress
                                    height: parent.height
                                    radius: parent.radius
                                    color: root.accent
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: Boolean(root.mediaPlayer && root.mediaPlayer.canSeek)
                                cursorShape: Qt.PointingHandCursor
                                onPressed: function(mouse) { root.seekMedia(mouse.x / Math.max(1, width)) }
                                onPositionChanged: function(mouse) { if (pressed) root.seekMedia(mouse.x / Math.max(1, width)) }
                            }
                        }
                        Text { text: root.formatTime(root.mediaLength); color: root.inkSoft; font.family: root.monoFont; font.pixelSize: 10 }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64
                        spacing: 10
                        MediaButton { iconName: "shuffle"; active: root.mediaShuffle; enabledControl: root.mediaShuffleSupported; onTriggered: root.toggleShuffle() }
                        MediaButton { iconName: "skip-previous"; enabledControl: root.mediaAvailable; onTriggered: root.previousMedia() }
                        MediaButton { iconName: root.mediaPlaying ? "pause" : "play"; primary: true; enabledControl: root.mediaAvailable; onTriggered: root.toggleMedia() }
                        MediaButton { iconName: "skip-next"; enabledControl: root.mediaAvailable; onTriggered: root.nextMedia() }
                    }
                }

                Rectangle { visible: root.lyricsAvailable; Layout.preferredWidth: 1; Layout.preferredHeight: 260; color: root.line }

                ColumnLayout {
                    visible: root.lyricsAvailable
                    Layout.preferredWidth: 250
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 10
                    Repeater {
                        model: root.lyricsAvailable ? root.lyricsContextLines.slice(0, 4) : []
                        Text {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            text: (index === 0 ? "♫  " : "") + String(modelData.text || "")
                            color: index === 0 ? root.ink : root.alpha(root.inkSoft, Math.max(0.25, 0.62 - index * 0.11))
                            font.family: root.uiFont
                            font.pixelSize: index === 0 ? 11 : 10
                            font.weight: index === 0 ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    component MediaButton: Rectangle {
        id: mediaButton
        property string label: "▶"
        property string iconName: "play"
        property bool primary: false
        property bool active: false
        property bool enabledControl: true
        signal triggered()
        Layout.preferredWidth: primary ? 64 : 48
        Layout.preferredHeight: primary ? 64 : 48
        Layout.alignment: Qt.AlignVCenter
        radius: Math.round(height / 2)
        opacity: enabledControl ? 1 : 0.34
        color: primary ? root.primaryContainer : (active ? root.primaryContainer : (mediaMouse.containsMouse ? root.surfaceContainerHigh : root.surfaceContainer))
        border.width: 1
        border.color: primary || active ? root.alpha(root.accent, 0.62) : root.line
        VeloraMaterialIcon { anchors.centerIn: parent; width: mediaButton.primary ? 34 : 25; height: width; iconName: mediaButton.iconName; iconColor: mediaButton.primary || mediaButton.active ? root.onPrimaryContainer : root.ink; filled: mediaButton.primary || mediaButton.active }
        MouseArea { id: mediaMouse; anchors.fill: parent; hoverEnabled: true; enabled: mediaButton.enabledControl; cursorShape: Qt.PointingHandCursor; onClicked: mediaButton.triggered() }
    }

    Component {
        id: profileView

        Item {
            ColumnLayout {
                anchors { fill: parent; margins: 20 }
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 78
                    spacing: 14

                    Rectangle {
                        id: profileFrame
                        Layout.preferredWidth: 66
                        Layout.preferredHeight: 66
                        radius: 20
                        color: root.card
                        border.width: 1
                        border.color: root.alpha(root.accent, 0.52)
                        clip: true
                        Image {
                            id: profileImage
                            anchors.fill: parent
                            anchors.margins: 3
                            source: root.profileSource()
                            visible: false
                            fillMode: Image.PreserveAspectCrop
                        }
                        Rectangle { id: profileMask; anchors.fill: profileImage; radius: 17; visible: false }
                        OpacityMask { anchors.fill: profileImage; source: profileImage; maskSource: profileMask }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Text { Layout.fillWidth: true; text: Quickshell.env("USER") || "User"; color: root.ink; font.family: root.uiFont; font.pixelSize: 18; font.weight: Font.DemiBold; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; text: "Sessão local • Online"; color: root.inkSoft; font.family: root.uiFont; font.pixelSize: 10; elide: Text.ElideRight }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.line }

                ActionCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    iconName: "settings"
                    title: "Configurações rápidas"
                    subtitle: "Áudio, rede, tela e sessão"
                    onTriggered: root.popupRequested("settingsQuick")
                }
                ActionCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    iconName: "notifications"
                    title: "Notificações"
                    subtitle: "Histórico e preferências"
                    onTriggered: root.popupRequested("notifications")
                }
                ActionCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    iconName: "apps"
                    title: "Aplicativos"
                    subtitle: "Abrir o grid de aplicativos"
                    onTriggered: root.popupRequested("apps")
                }
            }
        }
    }
}
