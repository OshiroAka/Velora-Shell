import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "components"

ShellRoot {
    id: root

    VeloraTheme {
        id: veloraTheme
    }

    NotificationServer {
        id: veloraNotificationServer

        keepOnReload: true
        persistenceSupported: true
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: function(notification) {
            if (!notification)
                return

            notification.tracked = true
            root.upsertNotificationHistory(notification)
            root.showNotificationToast(notification)
        }
    }

    property bool notificationToastVisible: false
    property bool notificationToastMounted: false
    property string notificationToastTitle: ""
    property string notificationToastBody: ""
    property string notificationToastApp: ""
    property string notificationToastIconKey: "bell"
    property int notificationToastSerial: 0
    readonly property int notificationHistoryCount: notificationHistoryModel.count
    property bool wallpaperSelectorOpen: false
    property bool settingsPanelOpen: false
    property bool idlePreloadEnabled: false
    property string quickPopupType: ""
    property string hoverPopupType: ""
    property bool quickPopupHoldOpen: false
    property bool sidebarPopupHovering: false
    property bool quickPopupHovering: false
    property bool geminiTopOpen: false
    property bool geminiTopWindowOpen: false
    property bool geminiTopKeyboardFocus: false
    property bool geminiTopTriggerHovering: false
    property bool geminiTopPanelHovering: false
    property int geminiTopFocusRequest: 0
    property bool wallpaperSelectorHovering: false
    property bool settingsPanelHovering: false
    property bool wallpaperSelectorWindowOpen: false
    property bool settingsPanelWindowOpen: false
    property bool wallpaperPreloadEnabled: false
    property bool settingsPanelPreloadEnabled: false
    property bool quickPopupPreloadEnabled: false
    property int quickPopupPreloadCount: 0
    property string appLaunchCommand: ""
    property int searchPopupFocusAttempts: 0
    property bool rightDashboardOpen: false
    property real topBarPopupCenterX: 0
    property bool topWallpaperPopupOpen: false
    property bool topWallpaperKeyboardFocus: false
    property bool topWallpaperCardsMounted: false
    property real topWallpaperFrameReveal: topWallpaperPopupOpen ? 1 : 0
    property bool topWallpaperWithoutFrame: true
    readonly property bool topWallpaperMounted: (topWallpaperPopupOpen || topWallpaperFrameReveal > 0.01) && (frameVisualsMounted || topWallpaperWithoutFrame)
    readonly property real topWallpaperSurfaceReveal: frameVisualsMounted ? frameVisualsReveal : (topWallpaperMounted ? 1 : 0)
    property int topWallpaperOffset: 0
    property int topWallpaperSlideDirection: 0
    property int topWallpaperQueuedDirection: 0
    property real topWallpaperSlideProgress: 0
    property bool leftMenuOpen: false
    property bool leftMenuHovering: false
    property bool leftMenuPinned: false
    property bool leftMenuTriggerHovering: false
    property bool leftMenuPanelHovering: false
    property bool leftMediaWindowOpen: false
    property bool leftMediaWindowHovering: false
    property bool leftMediaWindowEntranceHold: false
    property real leftMediaWindowCenterY: 300
    property string leftDetailWindowType: "media"
    property real leftDetailSwitchProgress: 1
    property bool leftMenuInteractiveFocus: false
    property bool leftMenuPreloadEnabled: false
    property string rightDashboardSection: "weather"
    property bool focusMode: false
    property int focusIndex: 0
    readonly property bool topBarLayout: veloraTheme.topBarEnabled
    readonly property bool sideBarLayoutEnabled: !topBarLayout
    readonly property bool activeWorkspaceFullscreen: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.hasFullscreen : false
    readonly property bool shellSuppressedByFullscreen: activeWorkspaceFullscreen
    readonly property bool barOnRight: veloraTheme.barPosition === "right"
    readonly property bool leftMenuOnLeft: barOnRight
    readonly property string leftMenuAttachSide: leftMenuOnLeft ? "left" : "right"
    readonly property bool rightSoftLayout: true
    readonly property int sidebarVisualWidth: 112
    readonly property int desktopFrameMargin: 14
    readonly property int sidebarOuterMargin: desktopFrameMargin
    readonly property int sidebarVerticalMargin: 20
    readonly property int sidebarCornerRadius: 24
    readonly property int sideVisualizerWaveWidth: 58
    readonly property int barPanelWidth: sideBarLayoutEnabled ? sidebarVisualWidth + sidebarOuterMargin : 0
    readonly property int barReserveWidth: sideBarLayoutEnabled ? barPanelWidth : 0
    readonly property int desktopFrameRadius: 10
    readonly property bool frameVisualsEnabled: veloraTheme.desktopFrameEnabled && !topBarLayout
    readonly property int frameVisualInset: frameVisualsEnabled ? desktopFrameMargin : 0
    readonly property bool frameVisualsMounted: frameVisualsEnabled || frameVisualsReveal > 0.01
    property real frameVisualsReveal: frameVisualsEnabled ? 1 : 0
    property bool sideVisualizerWithoutFrame: true
    readonly property bool screenVisualizerWanted: false
    readonly property bool sideVisualizerMounted: sideBarLayoutEnabled && !screenVisualizerWanted && veloraTheme.visualizerStrength > 0.01 && (frameVisualsMounted || sideVisualizerWithoutFrame)
    readonly property bool screenVisualizerMounted: screenVisualizerWanted
    readonly property bool audioVisualizerMounted: sideVisualizerMounted || screenVisualizerMounted
    readonly property real sideVisualizerReveal: frameVisualsMounted ? frameVisualsReveal : (sideVisualizerMounted ? 1 : 0)
    property real screenVisualizerReveal: screenVisualizerMounted ? 1 : 0
    readonly property real desktopFrameMatteOpacity: sidebarPanelGlassAlpha()
    readonly property int popupFrameGap: veloraTheme.popupAttachedToBar ? 0 : 14
    readonly property int sideQuickPopupBarClearance: 14
    readonly property string popupAttachSide: barOnRight ? "right" : "left"
    readonly property int topWallpaperPopupMargin: 8
    readonly property int topWallpaperPopupRadius: 28
    readonly property int topWallpaperSliceCount: 10
    readonly property int topWallpaperSelectedSlot: Math.floor(topWallpaperSliceCount / 2)
    readonly property string topWallpaperHomeDir: Quickshell.env("HOME") || ""
    readonly property string topWallpaperDir: topWallpaperHomeDir + "/Pictures/Wallpapers"
    readonly property string topWallpaperScanScript: Quickshell.shellDir + "/scripts/velora-wallpaper-scan"
    readonly property string topWallpaperApplyScript: Quickshell.shellDir + "/scripts/velora-wallpaper-apply"
    readonly property string filesCommand: "if command -v dolphin >/dev/null 2>&1; then dolphin \"$HOME\" >/dev/null 2>&1 & elif command -v thunar >/dev/null 2>&1; then thunar \"$HOME\" >/dev/null 2>&1 & else xdg-open \"$HOME\" >/dev/null 2>&1 & fi"
    readonly property string browserCommand: "if command -v zen-browser >/dev/null 2>&1; then zen-browser >/dev/null 2>&1 & elif command -v firefox >/dev/null 2>&1; then firefox >/dev/null 2>&1 & fi"
    readonly property var topWallpaperFallbackEntries: [
        { kind: "static", path: topWallpaperDir + "/static/aerial-view-tokyo-cityscape-with-fuji-mountain-japan.jpg", preview: topWallpaperDir + "/static/aerial-view-tokyo-cityscape-with-fuji-mountain-japan.jpg", title: "Tokyo Fuji" },
        { kind: "static", path: topWallpaperDir + "/static/claudio-guglieri-G6X3OZqIIm8-unsplash.jpg", preview: topWallpaperDir + "/static/claudio-guglieri-G6X3OZqIIm8-unsplash.jpg", title: "city street" },
        { kind: "static", path: topWallpaperDir + "/static/anime-anime-devushki-anime-anime-girls-belye-volosy-golub-zh.jpg", preview: topWallpaperDir + "/static/anime-anime-devushki-anime-anime-girls-belye-volosy-golub-zh.jpg", title: "white girl" },
        { kind: "static", path: topWallpaperDir + "/static/clay-banks-hwLAI5lRhdM-unsplash.jpg", preview: topWallpaperDir + "/static/clay-banks-hwLAI5lRhdM-unsplash.jpg", title: "storefront" },
        { kind: "static", path: topWallpaperDir + "/static/cosmin-georgian-gd3ysFyrsTQ-unsplash.jpg", preview: topWallpaperDir + "/static/cosmin-georgian-gd3ysFyrsTQ-unsplash.jpg", title: "blue pagoda" }
    ]
    property var topWallpaperEntries: topWallpaperFallbackEntries
    readonly property int leftMenuWidth: 348
    readonly property int leftMenuTriggerWidth: 18
    readonly property int leftMenuFrameInset: frameVisualsEnabled ? desktopFrameMargin + 1 : desktopFrameMargin
    readonly property int leftMediaWindowWidth: 640
    readonly property int leftMediaWindowHeight: 690
    readonly property int leftMediaWindowGap: 12
    property real quickPopupCenterY: 300
    property bool quickPopupWindowOpen: false
    property string renderedQuickPopupType: ""
    readonly property bool wallpaperSelectorHoverPreview: hoverPopupType === "theme" && !wallpaperSelectorOpen
    readonly property bool settingsPanelHoverPreview: hoverPopupType === "settings" && !settingsPanelOpen
    readonly property bool wallpaperSelectorPreview: (focusMode && focusTarget === "theme" && !wallpaperSelectorOpen) || wallpaperSelectorHoverPreview
    readonly property bool wallpaperSelectorVisible: wallpaperSelectorOpen || wallpaperSelectorPreview
    readonly property bool settingsPanelVisible: settingsPanelOpen || settingsPanelHoverPreview
    readonly property bool wallpaperSelectorPanelVisible: wallpaperSelectorVisible || wallpaperSelectorWindowOpen
    readonly property bool settingsPanelPanelVisible: settingsPanelVisible || settingsPanelWindowOpen
    readonly property bool quickPopupOpen: quickPopupType.length > 0
    readonly property string quickPopupPreviewType: focusMode ? quickPopupForFocus(focusTarget) : ((hoverPopupType !== "theme" && hoverPopupType !== "settings") ? hoverPopupType : "")
    readonly property string activeQuickPopupType: quickPopupOpen ? quickPopupType : quickPopupPreviewType
    readonly property bool quickPopupVisible: activeQuickPopupType.length > 0
    readonly property bool quickPopupPanelVisible: quickPopupVisible || quickPopupWindowOpen
    readonly property bool sideQuickPopupPanelVisible: sideBarLayoutEnabled && quickPopupPanelVisible
    readonly property bool topBarQuickPopupPanelVisible: topBarLayout && quickPopupPanelVisible
    readonly property string visibleQuickPopupType: quickPopupVisible ? activeQuickPopupType : renderedQuickPopupType
    readonly property var cachedQuickPopupTypes: [
        "profile",
        "time",
        "agenda",
        "weatherPanel",
        "search",
        "volume",
        "wifi",
        "brightness",
        "notifications",
        "battery",
        "bluetooth",
        "wallpaperVisibility"
    ]
    property real quickPopupSurfaceReveal: 0
    readonly property int quickPopupLineCloseDuration: veloraTheme.motionEnabled ? Math.max(700, Math.round(veloraTheme.motionPanelOut * 1.90)) : 1
    readonly property int notificationToastOpenDuration: veloraTheme.motionEnabled ? Math.max(420, veloraTheme.motionPanelIn) : 1
    readonly property int notificationToastCloseDuration: veloraTheme.motionEnabled ? Math.max(640, Math.round(quickPopupLineCloseDuration * 0.82)) : 1
    readonly property bool sideQuickPopupAttachedToBar: sideQuickPopupPanelVisible && quickPopupTypeAttachedToBar(visibleQuickPopupType)
    readonly property int sideQuickPopupBridgeWidth: sideQuickPopupAttachedToBar && sideVisualizerMounted && barOnRight ? Math.max(popupFrameGap, sideQuickPopupBarClearance) : 0
    readonly property bool quickPopupJoinedToBar: sideQuickPopupAttachedToBar && (popupFrameGap <= 0 || sideQuickPopupBridgeWidth > 0)
    readonly property real quickPopupTransitionContrast: sideQuickPopupPanelVisible ? (quickPopupSurfaceReveal < 0.98 ? 0.30 : 0.12) : 0

    function shellQuote(value) {
        return "'" + String(value || "").replace(/'/g, "'\"'\"'") + "'"
    }

    function launchApp(command) {
        if (!command || command.length <= 0 || appLaunchProcess.running)
            return

        appLaunchCommand = command
        appLaunchProcess.running = true
    }

    function notificationCleanText(value) {
        return String(value || "").replace(/<[^>]*>/g, "").replace(/&nbsp;/g, " ").trim()
    }

    function notificationField(notification, keys, fallback) {
        if (!notification)
            return fallback || ""

        for (let i = 0; i < keys.length; ++i) {
            const value = notification[keys[i]]
            if (value !== undefined && value !== null && String(value).trim().length > 0)
                return notificationCleanText(value)
        }

        return fallback || ""
    }

    function notificationIconKey(appName, title, body, iconName) {
        const value = String((appName || "") + " " + (title || "") + " " + (body || "") + " " + (iconName || "")).toLowerCase()
        if (value.indexOf("whatsapp") >= 0 || value.indexOf("whats app") >= 0 || value.indexOf("web.whatsapp") >= 0 || value.indexOf("com.whatsapp") >= 0)
            return "whatsapp"
        if (value.indexOf("discord") >= 0 || value.indexOf("vesktop") >= 0)
            return "discord"
        if (value.indexOf("spotify") >= 0)
            return "spotify"
        if (value.indexOf("telegram") >= 0)
            return "telegram"
        if (value.indexOf("firefox") >= 0 || value.indexOf("zen") >= 0 || value.indexOf("browser") >= 0)
            return "browser"
        if (value.indexOf("velora") >= 0)
            return "velora"
        return "bell"
    }

    function notificationTimeText(notification) {
        const value = notificationField(notification, ["timeText", "time", "timestamp"], "")
        if (value.length > 0) {
            const parsed = new Date(value)
            if (!isNaN(parsed.getTime()))
                return Qt.formatDateTime(parsed, "HH:mm")
            return value
        }

        return Qt.formatTime(new Date(), "HH:mm")
    }

    function normalizeNotification(notification) {
        const summary = notificationField(notification, ["summary", "title"], "")
        const body = notificationField(notification, ["body"], "")
        const appName = notificationField(notification, ["appName", "app", "app_name", "application", "desktopEntry", "desktop_entry", "app-name"], "Sistema")
        const iconName = notificationField(notification, ["appIcon", "app_icon", "icon", "image", "imagePath", "desktopEntry", "desktop_entry"], "")
        const title = summary.length > 0 ? summary : (body.length > 0 ? body : "Notificação")
        let id = notificationField(notification, ["id", "ID", "notificationId", "notification_id"], "")
        if (id.length <= 0)
            id = appName + "|" + title + "|" + body

        return {
            id: String(id),
            app: appName,
            summary: title,
            body: summary.length > 0 ? body : "",
            timeText: notificationTimeText(notification),
            iconKey: notificationIconKey(appName, title, body, iconName)
        }
    }

    function upsertNotificationHistory(notification) {
        const item = normalizeNotification(notification)
        if (item.summary.length <= 0 && item.body.length <= 0)
            return

        for (let i = 0; i < notificationHistoryModel.count; ++i) {
            const current = notificationHistoryModel.get(i)
            if ((item.id.length > 0 && current.id === item.id)
                    || (current.app === item.app && current.summary === item.summary && current.body === item.body)) {
                notificationHistoryModel.set(i, item)
                if (i > 0)
                    notificationHistoryModel.move(i, 0, 1)
                return
            }
        }

        notificationHistoryModel.insert(0, item)
        while (notificationHistoryModel.count > 24)
            notificationHistoryModel.remove(notificationHistoryModel.count - 1)
    }

    function removeNotificationHistoryById(notificationId) {
        const id = String(notificationId || "")
        if (id.length <= 0)
            return

        for (let i = notificationHistoryModel.count - 1; i >= 0; --i) {
            if (notificationHistoryModel.get(i).id === id)
                notificationHistoryModel.remove(i)
        }
    }

    function clearNotificationHistory() {
        notificationHistoryModel.clear()
    }

    function notificationIconSurfaceColor(iconKey) {
        if (iconKey === "whatsapp")
            return Qt.rgba(46 / 255, 168 / 255, 101 / 255, 0.82)
        if (iconKey === "discord")
            return Qt.rgba(112 / 255, 132 / 255, 255 / 255, 0.82)
        if (iconKey === "spotify")
            return Qt.rgba(34 / 255, 197 / 255, 94 / 255, 0.82)
        if (iconKey === "telegram")
            return Qt.rgba(56 / 255, 164 / 255, 220 / 255, 0.82)
        if (iconKey === "browser")
            return Qt.rgba(69 / 255, 160 / 255, 245 / 255, 0.82)
        if (iconKey === "velora")
            return veloraTheme.alpha(veloraTheme.accentPrimary, 0.82)
        return veloraTheme.alpha(veloraTheme.accentTertiary, 0.78)
    }

    function showNotificationToast(notification) {
        if (shellSuppressedByFullscreen)
            return

        const item = normalizeNotification(notification)

        notificationToastTitle = item.summary
        notificationToastBody = item.body
        notificationToastApp = item.app
        notificationToastIconKey = item.iconKey
        notificationToastSerial += 1
        notificationToastUnmountTimer.stop()
        notificationToastMounted = true
        notificationToastVisible = true
        notificationToastHideTimer.toastSerial = notificationToastSerial
        notificationToastHideTimer.restart()
    }

    function hideNotificationToast() {
        notificationToastHideTimer.stop()
        notificationToastVisible = false
        notificationToastUnmountTimer.toastSerial = notificationToastSerial
        notificationToastUnmountTimer.restart()
    }

    onShellSuppressedByFullscreenChanged: {
        if (!shellSuppressedByFullscreen)
            return

        closeQuickPopup()
        closeGeminiTop()
        hideNotificationToast()
        wallpaperSelectorOpen = false
        wallpaperSelectorWindowOpen = false
        settingsPanelOpen = false
        settingsPanelWindowOpen = false
        rightDashboardOpen = false
        leftMenuOpen = false
        leftMediaWindowOpen = false
        toggleTopWallpaperPopup(false, false)
    }

    Timer {
        id: notificationToastHideTimer

        property int toastSerial: -1

        interval: 4300
        repeat: false
        onTriggered: if (toastSerial === root.notificationToastSerial) root.hideNotificationToast()
    }

    Timer {
        id: notificationToastUnmountTimer

        property int toastSerial: -1

        interval: Math.max(veloraTheme.motionUnmountDelay, root.notificationToastCloseDuration + 160)
        repeat: false
        onTriggered: if (toastSerial === root.notificationToastSerial && !root.notificationToastVisible) root.notificationToastMounted = false
    }

    ListModel {
        id: notificationHistoryModel
    }

    function clockAlertCommand(title, message) {
        const sound = "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
        return "title=" + shellQuote(title || "Velora") + "; body=" + shellQuote(message || "Clock alert") + "; sound=" + shellQuote(sound) + "; " +
            "notify-send -a Velora -u critical -t 12000 \"$title\" \"$body\" >/dev/null 2>&1 || true; " +
            "if [ -f \"$sound\" ]; then " +
            "for i in 1 2 3; do " +
            "if command -v pw-play >/dev/null 2>&1; then pw-play \"$sound\" >/dev/null 2>&1; " +
            "elif command -v paplay >/dev/null 2>&1; then paplay \"$sound\" >/dev/null 2>&1; " +
            "elif command -v mpv >/dev/null 2>&1; then mpv --no-video --really-quiet \"$sound\" >/dev/null 2>&1; " +
            "fi; sleep 0.18; done; fi"
    }

    function sendClockNotification(message, title) {
        if (leftClockNotifyProcess.running)
            leftClockNotifyProcess.running = false
        leftClockNotifyProcess.command = ["bash", "-lc", clockAlertCommand(title || "Velora", message)]
        leftClockNotifyProcess.running = true
    }

    QtObject {
        id: leftClockState

        property date currentDate: new Date()
        property var alarms: [
            { time: "07:00", detail: "Weekday", enabled: true },
            { time: "08:30", detail: "Weekend", enabled: true },
            { time: "22:00", detail: "Daily", enabled: true }
        ]
        property string lastAlarmMinute: ""
        property int timerSeconds: 1800
        property int timerRemaining: 1800
        property bool timerRunning: false

        function alarmAt(index) {
            if (index >= 0 && index < alarms.length)
                return alarms[index]
            return { time: "07:00", detail: "", enabled: false }
        }

        function replaceAlarms(next) {
            alarms = next.slice()
            lastAlarmMinute = ""
        }

        function setAlarmEnabled(index, enabled) {
            if (index < 0 || index >= alarms.length)
                return
            var next = alarms.slice()
            var item = Object.assign({}, next[index])
            item.enabled = enabled
            next[index] = item
            replaceAlarms(next)
        }

        function addAlarm() {
            var d = new Date(currentDate.getTime() + 60 * 60 * 1000)
            var next = alarms.slice()
            next.push({
                time: String(d.getHours()).padStart(2, "0") + ":" + String(d.getMinutes()).padStart(2, "0"),
                detail: "Custom",
                enabled: true
            })
            replaceAlarms(next)
        }

        function shiftAlarmMinutes(index, delta) {
            if (index < 0 || index >= alarms.length)
                return
            var item = Object.assign({}, alarms[index])
            var parts = String(item.time || "07:00").split(":")
            var total = ((parseInt(parts[0]) || 0) * 60 + (parseInt(parts[1]) || 0) + delta + 1440) % 1440
            item.time = String(Math.floor(total / 60)).padStart(2, "0") + ":" + String(total % 60).padStart(2, "0")
            var next = alarms.slice()
            next[index] = item
            replaceAlarms(next)
        }

        function removeAlarm(index) {
            if (alarms.length <= 1 || index < 0 || index >= alarms.length)
                return
            var next = alarms.slice()
            next.splice(index, 1)
            replaceAlarms(next)
        }

        function checkAlarms() {
            const hhmm = Qt.formatTime(currentDate, "HH:mm")
            const dayKey = Qt.formatDate(currentDate, "yyyyMMdd") + "-" + hhmm
            for (var i = 0; i < alarms.length; ++i) {
                const alarm = alarmAt(i)
                if (alarm.enabled && hhmm === alarm.time && lastAlarmMinute !== dayKey) {
                    lastAlarmMinute = dayKey
                    root.sendClockNotification("Alarm " + alarm.time, "Velora alarm")
                    break
                }
            }
        }

        function adjustTimerSeconds(delta) {
            const next = Math.max(60, Math.min(24 * 3600, timerSeconds + delta))
            timerSeconds = next
            if (!timerRunning)
                timerRemaining = next
            else
                timerRemaining = Math.max(1, Math.min(24 * 3600, timerRemaining + delta))
        }

        function setTimerPreset(seconds) {
            timerSeconds = seconds
            timerRemaining = seconds
            timerRunning = false
        }

        function toggleTimer() {
            if (timerRemaining <= 0)
                timerRemaining = timerSeconds
            timerRunning = !timerRunning
        }

        function resetTimer() {
            timerRunning = false
            timerRemaining = timerSeconds
        }

        function finishTimer() {
            timerRunning = false
            timerRemaining = 0
            root.sendClockNotification("Timer finished", "Velora timer")
        }

    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            leftClockState.currentDate = new Date()
            leftClockState.checkAlarms()
        }
    }

    Timer {
        interval: 1000
        running: leftClockState.timerRunning
        repeat: true
        onTriggered: {
            if (leftClockState.timerRemaining > 1)
                leftClockState.timerRemaining -= 1
            else
                leftClockState.finishTimer()
        }
    }

    Process {
        id: leftClockNotifyProcess

        running: false
        command: ["bash", "-lc", "true"]
        onExited: running = false
    }

    Process {
        id: appLaunchProcess

        running: false
        command: ["bash", "-lc", root.appLaunchCommand]
        onExited: running = false
    }

    Process {
        id: topWallpaperScan

        running: false
        property var tmp: []
        command: [root.topWallpaperScanScript]

        onStarted: tmp = []

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data).trim()
                if (!line || line === "BEGIN")
                    return

                if (line === "END") {
                    if (topWallpaperScan.tmp.length > 0)
                        root.topWallpaperEntries = topWallpaperScan.tmp.slice()
                    return
                }

                const parts = line.split("|")
                if (parts.length < 3)
                    return

                const kind = parts[0].toLowerCase()
                const path = parts[1]
                const preview = parts[2]
                const title = parts.length > 3 ? parts.slice(3).join("|") : path
                topWallpaperScan.tmp.push({
                    kind: kind,
                    path: path,
                    preview: preview,
                    title: title
                })
            }
        }

        onExited: {
            running = false
            if (tmp.length > 0)
                root.topWallpaperEntries = tmp.slice()
        }
    }

    Process {
        id: topWallpaperApply

        running: false
        command: [root.topWallpaperApplyScript, "static", ""]
        onExited: {
            running = false
        }
    }

    Timer {
        id: topWallpaperCardsMountTimer

        interval: 170
        repeat: false
        onTriggered: root.topWallpaperCardsMounted = root.topWallpaperPopupOpen
    }

    Timer {
        id: topWallpaperDeferredScanTimer

        interval: 420
        repeat: false
        onTriggered: {
            if (root.topWallpaperPopupOpen && !topWallpaperScan.running)
                topWallpaperScan.running = true
        }
    }

    NumberAnimation {
        id: topWallpaperSlideAnimation

        target: root
        property: "topWallpaperSlideProgress"
        from: 0
        to: 1
        duration: veloraTheme.motionEnabled ? 360 : 1
        easing.type: Easing.Linear

        onStopped: {
            if (root.topWallpaperSlideDirection !== 0 && root.topWallpaperSlideProgress >= 1) {
                const entries = root.topWallpaperEntries && root.topWallpaperEntries.length > 0 ? root.topWallpaperEntries : root.topWallpaperFallbackEntries
                if (entries && entries.length > 0)
                    root.topWallpaperOffset = ((root.topWallpaperOffset + root.topWallpaperSlideDirection) % entries.length + entries.length) % entries.length
            }

            const queuedDirection = root.topWallpaperQueuedDirection
            root.topWallpaperQueuedDirection = 0
            root.topWallpaperSlideProgress = 0
            root.topWallpaperSlideDirection = 0

            const entries = root.topWallpaperEntries && root.topWallpaperEntries.length > 0 ? root.topWallpaperEntries : root.topWallpaperFallbackEntries
            if (queuedDirection !== 0 && entries && entries.length > 1 && root.topWallpaperPopupOpen) {
                root.topWallpaperSlideDirection = queuedDirection
                root.topWallpaperSlideProgress = 0
                topWallpaperSlideAnimation.start()
            }
        }
    }

    readonly property var focusItems: [
        "clock",
        "search",
        "workspace1",
        "workspace2",
        "workspace3",
        "workspace4",
        "files",
        "browser",
        "discord",
        "volume",
        "wifi",
        "brightness",
        "notifications",
        "bluetooth",
        "battery",
        "settings",
        "layout",
        "avatar"
    ]
    readonly property string focusTarget: focusItems[Math.max(0, Math.min(focusIndex, focusItems.length - 1))]

    Behavior on frameVisualsReveal {
        enabled: veloraTheme.motionEnabled
        NumberAnimation {
            duration: root.frameVisualsEnabled ? veloraTheme.motionPanelIn : veloraTheme.motionPanelOut
            easing.type: root.frameVisualsEnabled ? veloraTheme.motionEaseEnter : veloraTheme.motionEaseExit
        }
    }

    Behavior on topWallpaperFrameReveal {
        enabled: veloraTheme.motionEnabled
        NumberAnimation {
            duration: root.topWallpaperPopupOpen ? veloraTheme.motionPanelIn : veloraTheme.motionPanelOut
            easing.type: root.topWallpaperPopupOpen ? veloraTheme.motionEaseEnter : veloraTheme.motionEaseExit
        }
    }

    Behavior on screenVisualizerReveal {
        enabled: veloraTheme.motionEnabled
        NumberAnimation {
            duration: root.screenVisualizerMounted ? veloraTheme.motionPanelIn : veloraTheme.motionPanelOut
            easing.type: root.screenVisualizerMounted ? veloraTheme.motionEaseEnter : veloraTheme.motionEaseExit
        }
    }

    function desktopFrameMatteColor() {
        if (!frameVisualsMounted)
            return "transparent"
        return veloraTheme.alpha(veloraTheme.surfaceSidebar, desktopFrameMatteOpacity)
    }

    function sidebarPanelGlassAlpha() {
        return Math.max(0.62, Math.min(veloraTheme.surfaceSidebar.a, 0.78))
    }

    function sidebarBarGlassAlpha() {
        return Math.max(veloraTheme.minOpacityForRole("sidebar"), Math.min(veloraTheme.barOpacity, 0.98))
    }

    function sidebarPanelMaterialColor() {
        if (!frameVisualsMounted)
            return "transparent"
        return veloraTheme.alpha(veloraTheme.surfaceSidebar, sidebarPanelGlassAlpha())
    }

    function topWallpaperPopupWidth(screenWidth) {
        const available = Math.max(760, screenWidth - barReserveWidth - desktopFrameMargin * 4)
        return Math.round(Math.min(1340, Math.max(960, Math.min(available, screenWidth * 0.82))))
    }

    function topWallpaperPopupHeight(screenHeight) {
        return Math.round(Math.min(840, Math.max(640, screenHeight * 0.72)))
    }

    function topWallpaperFrameLiftHeight(screenHeight) {
        const available = Math.max(0, screenHeight - desktopFrameMargin * 2)
        const target = Math.round(Math.min(280, Math.max(210, screenHeight * 0.185)))
        return Math.round(Math.min(target, available * 0.45) * topWallpaperFrameReveal)
    }

    function desktopFrameY(screenHeight) {
        return desktopFrameMargin
    }

    function desktopFrameBottomInset(screenHeight) {
        return desktopFrameMargin + topWallpaperFrameLiftHeight(screenHeight)
    }

    function desktopFrameHeight(screenHeight) {
        return Math.max(0, screenHeight - desktopFrameY(screenHeight) - desktopFrameBottomInset(screenHeight))
    }

    function desktopFrameBottom(screenHeight) {
        return desktopFrameY(screenHeight) + desktopFrameHeight(screenHeight)
    }

    function topWallpaperEntry(index) {
        const entries = topWallpaperEntries && topWallpaperEntries.length > 0 ? topWallpaperEntries : topWallpaperFallbackEntries
        if (!entries || entries.length <= 0)
            return { preview: "", path: "", title: "" }
        const normalizedIndex = ((topWallpaperOffset + index) % entries.length + entries.length) % entries.length
        return entries[normalizedIndex]
    }

    function topWallpaperSlideEase() {
        const t = Math.max(0, Math.min(1, topWallpaperSlideProgress))
        return t * t * (3 - 2 * t)
    }

    function moveTopWallpaper(delta) {
        const entries = topWallpaperEntries && topWallpaperEntries.length > 0 ? topWallpaperEntries : topWallpaperFallbackEntries
        if (!entries || entries.length <= 1)
            return

        const direction = delta > 0 ? 1 : -1

        if (topWallpaperSlideAnimation.running) {
            topWallpaperQueuedDirection = direction
            return
        }

        topWallpaperQueuedDirection = 0
        topWallpaperSlideDirection = direction
        topWallpaperSlideProgress = 0
        topWallpaperSlideAnimation.start()
    }

    function applyTopWallpaperSelection() {
        if (topWallpaperApply.running)
            return

        if (topWallpaperSlideAnimation.running) {
            topWallpaperQueuedDirection = 0
            topWallpaperSlideAnimation.complete()
        }

        const item = topWallpaperEntry(0)
        if (!item || !item.path)
            return

        topWallpaperApply.command = [
            topWallpaperApplyScript,
            item.kind || "static",
            item.path,
            item.preview || item.path
        ]
        topWallpaperApply.running = true
    }

    function toggleTopWallpaperPopup(forceOpen, withKeyboardFocus) {
        const nextOpen = forceOpen === true ? true : (forceOpen === false ? false : !topWallpaperPopupOpen)
        topWallpaperPopupOpen = nextOpen
        topWallpaperKeyboardFocus = nextOpen && withKeyboardFocus === true

        if (topWallpaperPopupOpen) {
            wallpaperSelectorOpen = false
            wallpaperSelectorWindowOpen = false
            settingsPanelOpen = false
            settingsPanelWindowOpen = false
            quickPopupType = ""
            rightDashboardOpen = false

            root.topWallpaperCardsMounted = false
            topWallpaperCardsMountTimer.restart()
            topWallpaperDeferredScanTimer.restart()
        } else {
            topWallpaperCardsMountTimer.stop()
            topWallpaperDeferredScanTimer.stop()
            root.topWallpaperCardsMounted = false
        }
    }

    function openGeminiTop(withKeyboardFocus) {
        exitFocus()
        closeQuickPopup()
        wallpaperSelectorOpen = false
        wallpaperSelectorWindowOpen = false
        settingsPanelOpen = false
        settingsPanelWindowOpen = false
        closeRightDashboard()
        closeLegacyLeftMenu()
        toggleTopWallpaperPopup(false, false)
        geminiTopUnmountTimer.stop()
        geminiTopKeyboardFocus = withKeyboardFocus === true
        geminiTopWindowOpen = true
        geminiTopOpen = true
        if (geminiTopKeyboardFocus)
            geminiTopFocusRequest += 1
    }

    function openGeminiTopFromMouse() {
        geminiTopHoverCloseTimer.stop()
        if (!geminiTopOpen)
            openGeminiTop(false)
    }

    function closeGeminiTop() {
        geminiTopOpen = false
        geminiTopKeyboardFocus = false
        geminiTopTriggerHovering = false
        geminiTopPanelHovering = false
        geminiTopHoverCloseTimer.stop()
        geminiTopUnmountTimer.restart()
    }

    function toggleGeminiTop() {
        if (geminiTopOpen)
            closeGeminiTop()
        else
            openGeminiTop(true)
    }

    function switchToSideBarLayout(position) {
        veloraTheme.setTopBarEnabled(false)
        veloraTheme.applyLayout(position, true)
    }

    function cycleBarLayout() {
        closeQuickPopup()
        closeGeminiTop()
        closeRightDashboard()
        settingsPanelOpen = false
        settingsPanelWindowOpen = false

        if (veloraTheme.topBarEnabled) {
            switchToSideBarLayout("right")
            return
        }

        if (barOnRight) {
            switchToSideBarLayout("left")
            return
        }

        veloraTheme.setTopBarEnabled(true)
    }

    function engageGeminiTop() {
        if (!geminiTopOpen)
            return
        geminiTopKeyboardFocus = true
        geminiTopHoverCloseTimer.stop()
    }

    function setGeminiTopPanelHovering(inside) {
        geminiTopPanelHovering = inside
        if (inside)
            geminiTopHoverCloseTimer.stop()
        else
            scheduleGeminiTopHoverClose()
    }

    function scheduleGeminiTopHoverClose() {
        if (geminiTopKeyboardFocus)
            return
        if (!geminiTopTriggerHovering && !geminiTopPanelHovering)
            geminiTopHoverCloseTimer.restart()
    }

    function sidebarBarMaterialColor() {
        if (!frameVisualsMounted)
            return "transparent"
        return veloraTheme.alpha(veloraTheme.surfaceSidebar, sidebarBarGlassAlpha())
    }

    function sideRailMaterialColor() {
        if (!sideVisualizerMounted)
            return "transparent"
        return veloraTheme.alpha(veloraTheme.surfaceSidebar, sidebarPanelGlassAlpha())
    }

    function sidebarPanelBorderColor() {
        if (!frameVisualsMounted && !sideVisualizerMounted)
            return "transparent"
        if (veloraTheme.themeId === "pywal16")
            return veloraTheme.alpha(veloraTheme.sidebarBorderGlow, Math.min(0.18, Math.max(0.08, veloraTheme.sidebarBorderGlow.a * 0.50)))
        return veloraTheme.alpha(veloraTheme.borderSoft, veloraTheme.themeMode === "dark" ? 0.11 : 0.26)
    }

    function sidebarPanelInnerLineColor() {
        if (!frameVisualsMounted && !sideVisualizerMounted)
            return "transparent"
        if (veloraTheme.themeMode === "dark")
            return Qt.rgba(1, 1, 1, 0.055)
        return veloraTheme.alpha(sidebarPanelBorderColor(), veloraTheme.themeId === "pywal16" ? 0.16 : 0.24)
    }

    function desktopFrameBorderColor() {
        if (!frameVisualsMounted)
            return "transparent"
        if (veloraTheme.themeId === "pywal16")
            return veloraTheme.alpha(veloraTheme.sidebarBorderGlow, Math.min(0.18, Math.max(0.08, veloraTheme.sidebarBorderGlow.a * 0.50)))
        return veloraTheme.alpha(veloraTheme.borderSoft, veloraTheme.themeMode === "dark" ? 0.11 : 0.26)
    }

    function desktopFrameHighlightLineColor() {
        if (!frameVisualsMounted)
            return "transparent"
        return veloraTheme.alpha(veloraTheme.activeText, veloraTheme.themeMode === "dark" ? 0.24 : 0.32)
    }

    function desktopFrameHighlightColor() {
        return "transparent"
    }

    function enterFocus() {
        wallpaperSelectorOpen = false
        settingsPanelOpen = false
        closeQuickPopup()
        focusIndex = Math.max(0, Math.min(focusIndex, focusItems.length - 1))
        focusMode = true
    }

    function exitFocus() {
        focusMode = false
    }

    function toggleFocus() {
        if (focusMode)
            exitFocus()
        else
            enterFocus()
    }

    function moveFocus(dir) {
        focusIndex = Math.max(0, Math.min(focusIndex + dir, focusItems.length - 1))
    }

    function quickPopupForFocus(target) {
        if (target === "search")
            return "search"
        if (target === "volume")
            return "volume"
        if (target === "wifi")
            return "wifi"
        if (target === "brightness")
            return "brightness"
        if (target === "notifications")
            return "notifications"
        if (target === "bluetooth")
            return "bluetooth"
        if (target === "battery")
            return "battery"
        return ""
    }

    function cachedQuickPopupIndex(type) {
        for (let i = 0; i < cachedQuickPopupTypes.length; ++i) {
            if (cachedQuickPopupTypes[i] === type)
                return i
        }
        return -1
    }

    onActiveQuickPopupTypeChanged: {
        if (quickPopupVisible && activeQuickPopupType.length > 0) {
            renderedQuickPopupType = activeQuickPopupType
        }
    }

    onQuickPopupVisibleChanged: {
        if (quickPopupVisible) {
            quickPopupUnmountTimer.stop()
            quickPopupWindowOpen = true
            renderedQuickPopupType = activeQuickPopupType
            animateQuickPopupSurfaceReveal(1)
            if (activeQuickPopupType === "search")
                scheduleSearchPopupFocus()
        } else if (renderedQuickPopupType.length > 0) {
            prepareQuickPopupCloseAnimation()
            animateQuickPopupSurfaceReveal(0)
            quickPopupUnmountTimer.restart()
        }
    }

    onWallpaperSelectorVisibleChanged: {
        if (wallpaperSelectorVisible) {
            wallpaperSelectorUnmountTimer.stop()
            wallpaperSelectorWindowOpen = true
        } else if (wallpaperSelectorWindowOpen) {
            wallpaperSelectorUnmountTimer.restart()
        }
    }

    onSettingsPanelVisibleChanged: {
        if (settingsPanelVisible) {
            settingsPanelUnmountTimer.stop()
            settingsPanelWindowOpen = true
        } else if (settingsPanelWindowOpen) {
            settingsPanelUnmountTimer.restart()
        }
    }

    onLeftMenuOpenChanged: {
        if (!leftMenuOpen) {
            leftMenuPinned = false
            leftMenuInteractiveFocus = false
            leftMediaWindowOpen = false
            leftMediaWindowHovering = false
            leftMediaWindowEntranceHold = false
            leftDetailSwitchProgress = 1
        }
    }

    function quickPopupArrowCenter(type) {
        if (type === "volume")
            return 78
        if (type === "wifi")
            return 288
        if (type === "brightness")
            return 248
        if (type === "notifications")
            return 414
        if (type === "bluetooth")
            return 456
        if (type === "wallpaperVisibility")
            return 132
        return 38
    }

    function defaultQuickPopupCenterY(type) {
        if (type === "theme")
            return 212
        if (type === "settings")
            return 1018
        if (type === "weatherPanel")
            return 520
        if (type === "profile")
            return 1032
        if (type === "time")
            return 84
        if (type === "search")
            return 180
        if (type === "files")
            return 424
        if (type === "browser")
            return 474
        if (type === "volume")
            return 782
        if (type === "wifi")
            return 888
        if (type === "brightness")
            return 938
        if (type === "notifications")
            return 982
        if (type === "battery")
            return 1038
        if (type === "bluetooth")
            return 1028
        if (type === "wallpaperVisibility")
            return defaultQuickPopupCenterY("theme")
        return 290
    }

    function setQuickPopupCenter(type, centerY) {
        const value = Number(centerY)
        quickPopupCenterY = value > 0 ? value : defaultQuickPopupCenterY(type)
    }

    function animateQuickPopupSurfaceReveal(targetValue) {
        const opening = targetValue > quickPopupSurfaceReveal
        quickPopupSurfaceRevealAnimation.stop()
        quickPopupSurfaceRevealAnimation.from = quickPopupSurfaceReveal
        quickPopupSurfaceRevealAnimation.to = targetValue
        quickPopupSurfaceRevealAnimation.duration = opening ? veloraTheme.motionPanelIn : quickPopupLineCloseDuration
        quickPopupSurfaceRevealAnimation.easing.type = opening ? veloraTheme.motionEaseEnter : Easing.InOutCubic
        quickPopupSurfaceRevealAnimation.restart()
    }

    function prepareWallpaperSelector(centerY) {
        topBarPopupCenterX = 0
        setQuickPopupCenter("theme", centerY)
        discardQuickPopupAnimation()
        settingsPanelOpen = false
    }

    function openWallpaperVisibility(centerY) {
        const value = Number(centerY)
        wallpaperSelectorOpen = false
        wallpaperSelectorWindowOpen = false
        wallpaperSelectorHovering = false
        wallpaperSelectorUnmountTimer.stop()
        openQuickPopup("wallpaperVisibility", value > 0 ? value : defaultQuickPopupCenterY("theme"))
    }

    function showWallpaperSelector(centerY) {
        exitFocus()
        prepareWallpaperSelector(centerY)
        wallpaperSelectorOpen = true
    }

    function toggleWallpaperSelector(centerY, forceOpen) {
        exitFocus()
        prepareWallpaperSelector(centerY)
        wallpaperSelectorOpen = forceOpen ? true : !wallpaperSelectorOpen
        focusWallpaperSelectorInput()
    }

    function focusWallpaperSelectorInput() {
        if (!wallpaperSelectorOpen)
            return

        Qt.callLater(function() {
            if (!root.wallpaperSelectorOpen)
                return

            if (typeof inlineModalLayer !== "undefined")
                inlineModalLayer.forceActiveFocus()
            if (typeof inlineWallpaperLoader !== "undefined" && inlineWallpaperLoader.item)
                inlineWallpaperLoader.item.forceActiveFocus()
        })
    }

    function prepareSettingsPanel(centerY) {
        topBarPopupCenterX = 0
        setQuickPopupCenter("settings", centerY)
        discardQuickPopupAnimation()
        wallpaperSelectorOpen = false
    }

    function toggleSettingsPanel(centerY, forceOpen) {
        exitFocus()
        prepareSettingsPanel(centerY)
        settingsPanelOpen = forceOpen ? true : !settingsPanelOpen
    }

    function openQuickPopup(type, centerY) {
        exitFocus()
        if (geminiTopOpen)
            closeGeminiTop()
        if (type !== "search")
            quickPopupHoldOpen = false
        setQuickPopupCenter(type, centerY)
        renderedQuickPopupType = type
        quickPopupWindowOpen = true
        quickPopupUnmountTimer.stop()
        hoverPopupType = ""
        hoverCloseTimer.stop()
        wallpaperSelectorOpen = false
        settingsPanelOpen = false
        quickPopupType = type
        if (type === "search")
            scheduleSearchPopupFocus()
    }

    function scheduleSearchPopupFocus() {
        searchPopupFocusAttempts = 0
        searchPopupFocusTimer.restart()
    }

    function focusSearchPopupInput() {
        if (quickPopupType !== "search")
            return

        if (typeof panel !== "undefined")
            panel.forceActiveFocus()

        if (typeof inlineQuickPopupLoader !== "undefined") {
            const popup = inlineQuickPopupLoader.itemForType("search")
            if (popup) {
                popup.forceActiveFocus()
                if (typeof popup.requestSearchFocus === "function")
                    popup.requestSearchFocus()
            }
        }

        if (typeof topBarPopupLoader !== "undefined") {
            const popup = topBarPopupLoader.itemForType("search")
            if (popup) {
                popup.forceActiveFocus()
                if (typeof popup.requestSearchFocus === "function")
                    popup.requestSearchFocus()
            }
        }
    }

    function setTopBarPopupCenter(centerX) {
        const value = Number(centerX)
        topBarPopupCenterX = value > 0 ? value : Math.round(mainAreaX(1920) + mainAreaWidth(1920) / 2)
    }

    function defaultTopBarPopupCenterX(type) {
        const screenWidth = 1920
        const stageWidth = Math.round(Math.min(1265, Math.max(1043, screenWidth * 0.658)))
        const barX = Math.round((screenWidth - stageWidth) / 2)
        const contentX = barX + 22
        const utilityRight = barX + stageWidth - 18 - 44
        const utilitiesX = utilityRight - 36 - (6 * 18 + 5 * 30)

        if (type === "time")
            return contentX + 73
        if (type === "search")
            return contentX + 224
        if (type === "volume")
            return utilitiesX + 9
        if (type === "wifi")
            return utilitiesX + 57
        if (type === "brightness")
            return utilitiesX + 105
        if (type === "notifications")
            return utilitiesX + 153
        if (type === "bluetooth")
            return utilitiesX + 201
        if (type === "battery")
            return utilitiesX + 249
        if (type === "profile")
            return barX + stageWidth - 40
        return barX + stageWidth / 2
    }

    function normalizeTopBarPopupCenterX(type, centerX) {
        const value = Number(centerX)
        if (!(value > 0) || Math.abs(value - defaultQuickPopupCenterY(type)) < 0.5)
            return defaultTopBarPopupCenterX(type)
        return value
    }

    function toggleTopBarQuickPopup(type, centerX) {
        setTopBarPopupCenter(normalizeTopBarPopupCenterX(type, centerX))
        toggleQuickPopup(type, defaultQuickPopupCenterY(type))
    }

    function previewTopBarPopup(type, centerX) {
        setTopBarPopupCenter(normalizeTopBarPopupCenterX(type, centerX))
        previewSidebarPopup(type, defaultQuickPopupCenterY(type))
    }

    function prepareQuickPopupCloseAnimation() {
        const closingType = activeQuickPopupType.length > 0 ? activeQuickPopupType : visibleQuickPopupType
        if (closingType.length <= 0)
            return

        renderedQuickPopupType = closingType
        quickPopupWindowOpen = true
        quickPopupUnmountTimer.stop()
    }

    function closeQuickPopup() {
        prepareQuickPopupCloseAnimation()
        quickPopupHoldOpen = false
        quickPopupType = ""
        hoverPopupType = ""
        sidebarPopupHovering = false
        quickPopupHovering = false
        hoverCloseTimer.stop()
    }

    function discardQuickPopupAnimation() {
        closeQuickPopup()
        quickPopupSurfaceRevealAnimation.stop()
        quickPopupSurfaceReveal = 0
        quickPopupUnmountTimer.stop()
        quickPopupWindowOpen = false
        renderedQuickPopupType = ""
    }

    function previewSidebarPopup(type, centerY) {
        if (!type || type.length <= 0)
            return

        if (wallpaperSelectorOpen || settingsPanelOpen)
            return

        if (type !== "search")
            quickPopupHoldOpen = false

        exitFocus()
        setQuickPopupCenter(type, centerY)
        renderedQuickPopupType = type
        quickPopupWindowOpen = true
        quickPopupUnmountTimer.stop()
        hoverCloseTimer.stop()
        sidebarPopupHovering = true
        quickPopupType = ""
        hoverPopupType = type
        wallpaperSelectorOpen = false
        settingsPanelOpen = false
    }

    function endSidebarPopupHover(type) {
        if (hoverPopupType !== type)
            return

        sidebarPopupHovering = false
        scheduleHoverClose()
    }

    function scheduleHoverClose() {
        if (quickPopupHoldOpen)
            return
        if (hoverPopupType.length > 0)
            hoverCloseTimer.restart()
    }

    function clearHoveredSidebarPopup() {
        if (quickPopupHoldOpen)
            return
        if (quickPopupType.length > 0 || wallpaperSelectorOpen || settingsPanelOpen)
            return

        if (!quickPopupHovering && !wallpaperSelectorHovering && !settingsPanelHovering) {
            prepareQuickPopupCloseAnimation()
            sidebarPopupHovering = false
            hoverPopupType = ""
        }
    }

    function toggleQuickPopup(type, centerY) {
        hoverPopupType = ""
        hoverCloseTimer.stop()
        if (quickPopupType === type) {
            prepareQuickPopupCloseAnimation()
            quickPopupHoldOpen = false
            quickPopupType = ""
            return
        }

        openQuickPopup(type, centerY)
    }

    function setQuickPopupHoldOpen(type, held) {
        if (type !== "search")
            return

        const nextHeld = held === true && (quickPopupType === "search" || hoverPopupType === "search" || activeQuickPopupType === "search")
        quickPopupHoldOpen = nextHeld
        if (!nextHeld)
            return

        hoverCloseTimer.stop()
        if (hoverPopupType === "search" && quickPopupType.length <= 0) {
            hoverPopupType = ""
            quickPopupType = "search"
        }
    }

    function openAdaptiveBarPopup(type, centerY) {
        if (!sideBarLayoutEnabled) {
            toggleTopBarQuickPopup(type, centerY)
            return
        }

        closeTopBarPopup()
        closeLegacyLeftMenu()
        closeRightDashboard()
        toggleQuickPopup(type, centerY)
    }

    function openTopBarPopup(type, centerX) {
        toggleTopBarQuickPopup(type, centerX)
    }

    function closeTopBarPopup() {
        topBarPopupCenterX = 0
    }

    function previewAdaptiveBarPopup(type, centerY) {
        if (!sideBarLayoutEnabled) {
            previewTopBarPopup(type, centerY)
            return
        }

        closeLegacyLeftMenu()
        closeRightDashboard()
        previewSidebarPopup(type, centerY)
    }

    function endAdaptiveBarPopupHover(type) {
        if (!sideBarLayoutEnabled) {
            endSidebarPopupHover(type)
            return
        }

        endSidebarPopupHover(type)
    }

    function openRightDashboard(section) {
        if (rightSoftLayout) {
            rightDashboardOpen = false
            return
        }

        const value = section && section.length > 0 ? section : "weather"
        rightDashboardSection = value
        rightDashboardOpen = true
    }

    function closeRightDashboard() {
        rightDashboardOpen = false
    }

    function closeLegacyLeftMenu() {
        leftMenuPinned = false
        leftMenuInteractiveFocus = false
        leftMenuOpen = false
        leftMenuTriggerHovering = false
        leftMenuPanelHovering = false
        leftMediaWindowOpen = false
        leftMediaWindowHovering = false
        leftMediaWindowEntranceHold = false
        leftDetailSwitchProgress = 1
        leftMenuCloseTimer.stop()
        leftMediaWindowEntranceHoldTimer.stop()
    }

    function openLeftMenu() {
        closeLegacyLeftMenu()
    }

    function updateLeftMenuHovering() {
        leftMenuHovering = leftMenuPinned || leftMenuTriggerHovering || leftMenuPanelHovering || leftMediaWindowHovering || leftMediaWindowEntranceHold
    }

    function scheduleLeftMenuClose() {
        updateLeftMenuHovering()
        if (!leftMenuHovering)
            leftMenuCloseTimer.restart()
    }

    function openLeftDetailWindow(type, centerY, pinned) {
        const value = Number(centerY)
        const nextType = type && type.length > 0 ? type : "media"
        leftMenuPinned = pinned === true
        leftMenuInteractiveFocus = false
        const switching = leftMediaWindowOpen && leftDetailWindowType !== nextType
        leftDetailWindowType = nextType
        if (switching) {
            leftDetailSwitchProgress = 0
            Qt.callLater(function() {
                if (root.leftMediaWindowOpen)
                    root.leftDetailSwitchProgress = 1
            })
        } else {
            leftDetailSwitchProgress = 1
        }
        leftMediaWindowCenterY = value > 0 ? value : 300
        leftMediaWindowEntranceHold = true
        leftMediaWindowEntranceHoldTimer.restart()
        leftMediaWindowOpen = true
        openLeftMenu()
    }

    function openLeftMediaWindow(centerY) {
        openLeftDetailWindow("media", centerY)
    }

    function leftDetailWindowWidth(type) {
        if (type === "paint")
            return 720
        if (type === "clock")
            return 430
        if (type === "wallpaper")
            return 380
        return leftMediaWindowWidth
    }

    function leftDetailWindowHeight(type, screenHeight) {
        const available = Math.max(360, screenHeight - leftMenuFrameInset * 2)
        if (type === "paint")
            return Math.min(920, available)
        if (type === "clock")
            return Math.min(900, available)
        if (type === "wallpaper")
            return Math.min(1040, available)
        return Math.min(leftMediaWindowHeight, available)
    }

    function leftMediaWindowY(panelHeight, screenHeight) {
        const edgeMargin = leftMenuFrameInset
        const wanted = leftMediaWindowCenterY - panelHeight / 2
        return Math.round(Math.max(edgeMargin, Math.min(screenHeight - panelHeight - edgeMargin, wanted)))
    }

    function barX(screenWidth) {
        return barOnRight ? Math.max(0, screenWidth - sidebarOuterMargin - sidebarVisualWidth) : sidebarOuterMargin
    }

    function mainAreaX(screenWidth) {
        if (!sideBarLayoutEnabled)
            return frameVisualInset
        return barOnRight ? frameVisualInset : barPanelWidth
    }

    function mainAreaRightInset(screenWidth) {
        if (!sideBarLayoutEnabled)
            return frameVisualInset
        return barOnRight ? barPanelWidth : frameVisualInset
    }

    function mainAreaWidth(screenWidth) {
        return Math.max(0, screenWidth - mainAreaX(screenWidth) - mainAreaRightInset(screenWidth))
    }

    function quickPopupX(type, screenWidth, popupWidth) {
        if (type === "agenda" || type === "weatherPanel") {
            const areaLeft = mainAreaX(screenWidth)
            const areaRight = screenWidth - mainAreaRightInset(screenWidth)
            const maxX = Math.max(frameVisualInset, areaRight - popupWidth)
            const wanted = areaLeft + (mainAreaWidth(screenWidth) - popupWidth) / 2
            return Math.round(Math.max(frameVisualInset, Math.min(maxX, wanted)))
        }
        if (barOnRight) {
            const clearance = Math.max(popupFrameGap, sideQuickPopupBarClearance)
            return Math.round(Math.max(frameVisualInset, barX(screenWidth) - clearance - popupWidth))
        }
        return barX(screenWidth) + sidebarVisualWidth + popupFrameGap
    }

    function quickPopupTypeAttachedToBar(type) {
        return type !== "agenda" && type !== "weatherPanel"
    }

    function attachedPopupX(screenWidth, popupWidth) {
        if (barOnRight) {
            const clearance = Math.max(popupFrameGap, sideQuickPopupBarClearance)
            return Math.round(Math.max(frameVisualInset, barX(screenWidth) - clearance - popupWidth))
        }
        return barX(screenWidth) + sidebarVisualWidth + popupFrameGap
    }

    function leftMenuAttachedPopupX(screenWidth, popupWidth) {
        if (leftMenuOnLeft)
            return leftMenuFrameInset + leftMenuWidth + leftMediaWindowGap
        return Math.round(Math.max(frameVisualInset, screenWidth - leftMenuFrameInset - leftMenuWidth - leftMediaWindowGap - popupWidth))
    }

    function quickPopupWidth(type) {
        if (type === "theme")
            return 820
        if (type === "settings")
            return 1510
        if (type === "agenda")
            return 1510
        if (type === "weatherPanel")
            return 1510
        if (type === "profile")
            return 670
        if (type === "time")
            return 470
        if (type === "search")
            return 540
        if (type === "files")
            return 548
        if (type === "browser")
            return 1265
        if (type === "volume")
            return 342
        if (type === "wifi")
            return 410
        if (type === "brightness")
            return 448
        if (type === "notifications")
            return 522
        if (type === "battery")
            return 522
        if (type === "bluetooth")
            return 410
        if (type === "wallpaperVisibility")
            return 372
        return 286
    }

    function quickPopupWidthForScreen(type, screenWidth) {
        if (type === "agenda" || type === "weatherPanel") {
            const available = Math.max(900, mainAreaWidth(screenWidth) - 110)
            return Math.round(Math.max(1510, Math.min(1680, available)))
        }
        return quickPopupWidth(type)
    }

    function quickPopupHeight(type) {
        if (type === "theme")
            return 520
        if (type === "settings")
            return 920
        if (type === "agenda")
            return 900
        if (type === "weatherPanel")
            return 900
        if (type === "profile")
            return 625
        if (type === "time")
            return 990
        if (type === "search")
            return 380
        if (type === "files")
            return 720
        if (type === "browser")
            return 795
        if (type === "volume")
            return 492
        if (type === "wifi")
            return 690
        if (type === "brightness")
            return 735
        if (type === "notifications")
            return 935
        if (type === "battery")
            return 500
        if (type === "bluetooth")
            return 500
        if (type === "wallpaperVisibility")
            return 470
        return 324
    }

    function quickPopupHeightForScreen(type, screenHeight) {
        if (type === "agenda" || type === "weatherPanel") {
            const available = Math.max(900, screenHeight - frameVisualInset * 2 - 110)
            return Math.round(Math.min(1040, available))
        }
        return quickPopupHeight(type)
    }

    function quickPopupTopMargin(type) {
        if (type === "time" || type === "search")
            return Math.max(frameVisualInset + popupFrameGap, 38)
        return frameVisualInset + popupFrameGap
    }

    function quickPopupY(type, panelHeight, screenHeight) {
        const edgeMargin = frameVisualInset + popupFrameGap
        if (type === "agenda" || type === "weatherPanel") {
            const wanted = (screenHeight - panelHeight) / 2
            return Math.round(Math.max(edgeMargin, Math.min(screenHeight - panelHeight - edgeMargin, wanted)))
        }

        const center = quickPopupCenterY > 0 ? quickPopupCenterY : defaultQuickPopupCenterY(type)
        const topMargin = quickPopupTopMargin(type)
        const maxY = screenHeight - panelHeight - edgeMargin
        const wanted = center - panelHeight / 2
        if (maxY < topMargin)
            return Math.round(Math.max(edgeMargin, maxY))
        return Math.round(Math.max(topMargin, Math.min(maxY, wanted)))
    }

    Timer {
        id: hoverCloseTimer

        interval: 360
        repeat: false
        onTriggered: root.clearHoveredSidebarPopup()
    }

    Timer {
        id: leftMenuCloseTimer

        interval: 280
        repeat: false
        onTriggered: {
            root.updateLeftMenuHovering()
            if (!root.leftMenuHovering) {
                root.leftMenuInteractiveFocus = false
                root.leftMenuOpen = false
            }
        }
    }

    Timer {
        id: leftMediaWindowEntranceHoldTimer

        interval: Math.max(520, veloraTheme.motionPanelIn + 180)
        repeat: false
        onTriggered: {
            root.leftMediaWindowEntranceHold = false
            root.scheduleLeftMenuClose()
        }
    }

    Behavior on leftDetailSwitchProgress {
        enabled: veloraTheme.motionEnabled
        NumberAnimation {
            duration: veloraTheme.motionPanelGeometry
            easing.type: veloraTheme.motionEaseEmphasized
            easing.bezierCurve: veloraTheme.motionEmphasizedCurve
        }
    }

    Timer {
        id: leftMenuPreloadTimer

        interval: 700
        running: root.idlePreloadEnabled
        repeat: false
        onTriggered: root.leftMenuPreloadEnabled = true
    }

    Timer {
        id: quickPopupPreloadTimer

        interval: 1000
        running: false
        repeat: false
        onTriggered: {
            root.quickPopupPreloadEnabled = true
            root.quickPopupPreloadCount = Math.max(root.quickPopupPreloadCount, 1)
            quickPopupCacheWarmupTimer.restart()
        }
    }

    Timer {
        id: quickPopupCacheWarmupTimer

        interval: 90
        repeat: true
        onTriggered: {
            if (!root.quickPopupPreloadEnabled) {
                stop()
                return
            }

            if (root.quickPopupPreloadCount >= root.cachedQuickPopupTypes.length) {
                stop()
                return
            }

            root.quickPopupPreloadCount += 1
        }
    }

    NumberAnimation {
        id: quickPopupSurfaceRevealAnimation

        target: root
        property: "quickPopupSurfaceReveal"
        from: root.quickPopupSurfaceReveal
        to: root.quickPopupVisible ? 1 : 0
        duration: veloraTheme.motionPanelIn
        easing.type: veloraTheme.motionEaseEnter
    }

    Timer {
        id: quickPopupUnmountTimer

        interval: Math.max(veloraTheme.motionUnmountDelay, root.quickPopupLineCloseDuration + 160)
        repeat: false
        onTriggered: {
            if (!root.quickPopupVisible) {
                root.quickPopupWindowOpen = false
                root.renderedQuickPopupType = ""
            }
        }
    }

    Timer {
        id: geminiTopUnmountTimer

        interval: Math.max(veloraTheme.motionUnmountDelay, root.quickPopupLineCloseDuration + 180)
        repeat: false
        onTriggered: if (!root.geminiTopOpen) root.geminiTopWindowOpen = false
    }

    Timer {
        id: geminiTopHoverCloseTimer

        interval: 320
        repeat: false
        onTriggered: if (!root.geminiTopKeyboardFocus && !root.geminiTopTriggerHovering && !root.geminiTopPanelHovering) root.closeGeminiTop()
    }

    Timer {
        id: searchPopupFocusTimer

        interval: 80
        repeat: false
        onTriggered: {
            if (root.quickPopupType !== "search")
                return

            root.focusSearchPopupInput()
            root.searchPopupFocusAttempts += 1
            if (root.searchPopupFocusAttempts < 10)
                restart()
        }
    }

    Timer {
        id: wallpaperSelectorUnmountTimer

        interval: veloraTheme.motionUnmountDelay
        repeat: false
        onTriggered: {
            if (!root.wallpaperSelectorVisible)
                root.wallpaperSelectorWindowOpen = false
        }
    }

    Timer {
        id: wallpaperPreloadTimer

        interval: 900
        running: root.idlePreloadEnabled
        repeat: false
        onTriggered: root.wallpaperPreloadEnabled = true
    }

    Timer {
        id: settingsPanelPreloadTimer

        interval: 1300
        running: root.idlePreloadEnabled
        repeat: false
        onTriggered: root.settingsPanelPreloadEnabled = true
    }

    Timer {
        id: settingsPanelUnmountTimer

        interval: veloraTheme.motionUnmountDelay
        repeat: false
        onTriggered: {
            if (!root.settingsPanelVisible)
                root.settingsPanelWindowOpen = false
        }
    }

    IpcHandler {
        target: "velora"

        function focus(): void {
            root.enterFocus()
        }

        function unfocus(): void {
            root.exitFocus()
        }

        function toggleFocus(): void {
            root.toggleFocus()
        }

        function theme(): void {
            root.showWallpaperSelector(root.defaultQuickPopupCenterY("theme"))
        }

        function wallpaper(): void {
            theme()
        }

        function topWallpaper(): void {
            root.toggleTopWallpaperPopup(null, true)
        }

        function topWallpaperNext(): void {
            root.moveTopWallpaper(1)
        }

        function topWallpaperPrevious(): void {
            root.moveTopWallpaper(-1)
        }

        function topWallpaperApply(): void {
            root.applyTopWallpaperSelection()
        }

        function closeTopWallpaper(): void {
            root.toggleTopWallpaperPopup(false, false)
        }

        function wallpaperFilter(): void {
            root.openWallpaperVisibility(root.defaultQuickPopupCenterY("theme"))
        }

        function filter(): void {
            wallpaperFilter()
        }

        function settings(): void {
            root.closeTopBarPopup()
            root.toggleSettingsPanel()
        }

        function pywal16(): void {
            veloraTheme.applyTheme("pywal16")
        }

        function reloadPywal16(): void {
            veloraTheme.reloadPywal16()
        }

        function search(): void {
            root.openAdaptiveBarPopup("search", root.defaultQuickPopupCenterY("search"))
        }

        function gemini(): void {
            root.toggleGeminiTop()
        }

        function profile(): void {
            root.openAdaptiveBarPopup("profile", root.defaultQuickPopupCenterY("profile"))
        }

        function time(): void {
            root.openAdaptiveBarPopup("time", root.defaultQuickPopupCenterY("time"))
        }

        function agenda(): void {
            root.openAdaptiveBarPopup("agenda", root.defaultQuickPopupCenterY("agenda"))
        }

        function weatherPanel(): void {
            root.openAdaptiveBarPopup("weatherPanel", root.defaultQuickPopupCenterY("weatherPanel"))
        }

        function clima(): void {
            weatherPanel()
        }

        function files(): void {
            root.launchApp(root.filesCommand)
        }

        function browser(): void {
            root.launchApp(root.browserCommand)
        }

        function volume(): void {
            root.openAdaptiveBarPopup("volume", root.defaultQuickPopupCenterY("volume"))
        }

        function wifi(): void {
            root.openAdaptiveBarPopup("wifi", root.defaultQuickPopupCenterY("wifi"))
        }

        function brightness(): void {
            root.openAdaptiveBarPopup("brightness", root.defaultQuickPopupCenterY("brightness"))
        }

        function notifications(): void {
            root.openAdaptiveBarPopup("notifications", root.defaultQuickPopupCenterY("notifications"))
        }

        function toastTest(): void {
            root.showNotificationToast({
                "summary": "Hello, tudo bem, so um layout!",
                "body": "",
                "appName": "WhatsApp"
            })
        }

        function bluetooth(): void {
            root.openAdaptiveBarPopup("bluetooth", root.defaultQuickPopupCenterY("bluetooth"))
        }

        function battery(): void {
            root.openAdaptiveBarPopup("battery", root.defaultQuickPopupCenterY("battery"))
        }

        function weather(): void {
            root.openRightDashboard("weather")
        }

        function system(): void {
            root.openRightDashboard("system")
        }

        function calendar(): void {
            root.openRightDashboard("calendar")
        }

        function media(): void {
            root.openRightDashboard("media")
        }

        function leftMedia(): void {
            root.openLeftDetailWindow("media", root.leftMediaWindowCenterY > 0 ? root.leftMediaWindowCenterY : 560, true)
        }

        function leftClock(): void {
            root.openLeftDetailWindow("clock", root.leftMediaWindowCenterY > 0 ? root.leftMediaWindowCenterY : 560, true)
        }

        function leftPaint(): void {
            root.openLeftDetailWindow("paint", root.leftMediaWindowCenterY > 0 ? root.leftMediaWindowCenterY : 560, true)
        }

        function leftWallpaper(): void {
            root.openLeftDetailWindow("wallpaper", root.leftMediaWindowCenterY > 0 ? root.leftMediaWindowCenterY : 560, true)
        }

        function closeLeftMedia(): void {
            root.leftMenuPinned = false
            root.leftMediaWindowOpen = false
            root.leftMediaWindowEntranceHold = false
            root.leftDetailSwitchProgress = 1
        }

        function memo(): void {
            root.openRightDashboard("memo")
        }

        function todo(): void {
            root.openRightDashboard("todo")
        }

        function closeDashboard(): void {
            root.closeRightDashboard()
        }

        function barLeft(): void {
            veloraTheme.setBarPosition("left")
        }

        function barRight(): void {
            veloraTheme.setBarPosition("right")
        }

        function frameOn(): void {
            veloraTheme.setDesktopFrameEnabled(true)
        }

        function frameOff(): void {
            veloraTheme.setDesktopFrameEnabled(false)
        }

        function topBarOn(): void {
            veloraTheme.setTopBarEnabled(true)
        }

        function topBarOff(): void {
            veloraTheme.setTopBarEnabled(false)
        }

        function toggleTopBar(): void {
            veloraTheme.toggleTopBarEnabled()
        }

        function layoutCycle(): void {
            root.cycleBarLayout()
        }
    }

    Variants {
        model: veloraTheme.topBarEnabled && !root.shellSuppressedByFullscreen ? Quickshell.screens : []

        PanelWindow {
            id: topBarPanel

            required property var modelData
            readonly property int panelWidth: modelData.width > 0 ? modelData.width : 1920
            readonly property int panelHeight: modelData.height > 0 ? modelData.height : 1200
            readonly property int topMargin: Math.round(Math.min(24, Math.max(20, panelHeight * 0.020)))
            readonly property int barHeight: Math.round(Math.min(88, Math.max(72, panelHeight * 0.073)))
            readonly property int stageWidth: Math.round(Math.min(1265, Math.max(1043, panelWidth * 0.658)))
            readonly property int popupWidth: root.topBarQuickPopupPanelVisible ? root.quickPopupWidthForScreen(root.visibleQuickPopupType, panelWidth) : 0
            readonly property int popupHeight: root.topBarQuickPopupPanelVisible ? root.quickPopupHeightForScreen(root.visibleQuickPopupType, panelHeight) : 0
            readonly property int popupGap: 12
            readonly property int popupY: topBar.y + topBar.height + popupGap
            readonly property real popupAnchorX: root.topBarPopupCenterX > 0 ? root.topBarPopupCenterX : root.mainAreaX(panelWidth) + root.mainAreaWidth(panelWidth) / 2
            readonly property int popupX: Math.round(Math.max(root.mainAreaX(panelWidth) + 12, Math.min(root.mainAreaX(panelWidth) + root.mainAreaWidth(panelWidth) - popupWidth - 12, popupAnchorX - popupWidth / 2)))

            screen: modelData
            color: "transparent"
            implicitWidth: panelWidth
            implicitHeight: panelHeight
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: root.quickPopupType === "search" || root.quickPopupType === "agenda" || root.quickPopupType === "weatherPanel"

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "velora-topbar"
            WlrLayershell.keyboardFocus: root.quickPopupType === "search" ? WlrKeyboardFocus.Exclusive : ((root.quickPopupType === "agenda" || root.quickPopupType === "weatherPanel") ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None)

            anchors {
                top: true
                left: true
                right: true
            }

            mask: Region {
                Region {
                    item: topBar.maskItem
                    radius: 16
                }

                Region {
                    item: topBarPopupInputMask
                    radius: topBarPopupLoader.cornerRadius
                }

                Region {
                    item: topBarPopupOutsideInputMask
                    radius: 0
                }
            }

            VeloraTopBar {
                id: topBar

                theme: veloraTheme
                activePopupType: root.activeQuickPopupType
                notificationCountOverride: root.notificationHistoryCount
                width: topBarPanel.stageWidth
                height: topBarPanel.barHeight
                x: Math.round((topBarPanel.panelWidth - width) / 2)
                y: topBarPanel.topMargin

                onSearchRequested: function(centerX) {
                    root.openAdaptiveBarPopup("search", topBar.x + centerX)
                }
                onThemeRequested: function(centerX) {
                    root.toggleWallpaperSelector(root.defaultQuickPopupCenterY("theme"))
                }
                onSettingsRequested: function(centerX) {
                    root.closeTopBarPopup()
                    root.toggleSettingsPanel(root.defaultQuickPopupCenterY("settings"))
                }
                onLayoutRequested: function(centerX) {
                    root.closeTopBarPopup()
                    root.cycleBarLayout()
                }
                onQuickPopupRequested: function(type, centerX) {
                    root.openAdaptiveBarPopup(type, topBar.x + centerX)
                }
                onQuickPopupHovered: function(type, centerX) {
                    root.previewAdaptiveBarPopup(type, topBar.x + centerX)
                }
                onQuickPopupHoverEnded: function(type) {
                    root.endAdaptiveBarPopupHover(type)
                }
            }

            Item {
                id: topBarPopupInputMask

                x: topBarPopupLoader.x
                y: topBarPopupLoader.y
                width: root.topBarQuickPopupPanelVisible ? topBarPopupLoader.width : 0
                height: root.topBarQuickPopupPanelVisible ? topBarPopupLoader.height : 0
            }

            Item {
                id: topBarPopupOutsideInputMask

                x: 0
                y: 0
                width: root.quickPopupHoldOpen && root.visibleQuickPopupType === "search" ? topBarPanel.panelWidth : 0
                height: root.quickPopupHoldOpen && root.visibleQuickPopupType === "search" ? topBarPanel.panelHeight : 0
                z: 1

                MouseArea {
                    anchors.fill: parent
                    enabled: root.quickPopupHoldOpen && root.visibleQuickPopupType === "search"
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: root.closeQuickPopup()
                }
            }

            VeloraAttachedSurface {
                id: topBarPopupSurface

                theme: veloraTheme
                attachSide: "left"
                useCustomGlass: true
                customGlass: veloraTheme.surfacePopup
                lineReveal: true
                transitionContrast: root.quickPopupSurfaceReveal < 0.98 ? 0.30 : 0.12
                x: topBarPopupLoader.x
                y: topBarPopupLoader.y
                width: topBarPopupLoader.width
                height: topBarPopupLoader.height
                radius: topBarPopupLoader.cornerRadius
                revealProgress: root.quickPopupSurfaceReveal
                visible: root.topBarQuickPopupPanelVisible && topBarPopupLoader.contentReady
                z: 8
            }

            Item {
                id: topBarPopupLoader

                property int cacheGeneration: 0
                readonly property bool active: root.topBarQuickPopupPanelVisible || (root.topBarLayout && root.quickPopupPreloadEnabled)
                readonly property int targetWidth: topBarPanel.popupWidth
                readonly property int targetHeight: topBarPanel.popupHeight
                readonly property int targetX: topBarPanel.popupX
                readonly property int targetY: topBarPanel.popupY
                readonly property int geometryDuration: Math.max(260, Math.round(veloraTheme.motionPanelGeometry * 0.72))
                readonly property int fadeInDuration: Math.max(150, Math.round(veloraTheme.motionPanelIn * 0.42))
                readonly property int switchFadeOutDuration: Math.max(170, Math.round(veloraTheme.motionPanelOut * 0.52))
                readonly property int closeFadeOutDuration: Math.max(380, Math.round(root.quickPopupLineCloseDuration * 0.74))
                readonly property int cornerRadius: {
                    cacheGeneration
                    const popup = itemForType(root.visibleQuickPopupType)
                    return popup ? popup.cornerRadius : 13
                }
                readonly property real revealProgress: root.quickPopupSurfaceReveal
                readonly property bool contentReady: {
                    cacheGeneration
                    if (!root.topBarQuickPopupPanelVisible || root.visibleQuickPopupType.length <= 0)
                        return false
                    return itemForType(root.visibleQuickPopupType) !== null
                }

                z: 9
                width: targetWidth
                height: targetHeight
                x: targetX
                y: targetY
                visible: root.topBarQuickPopupPanelVisible
                clip: true

                onActiveChanged: if (!active) root.quickPopupHovering = false

                function itemForType(type) {
                    const index = root.cachedQuickPopupIndex(type)
                    if (index < 0 || typeof topBarQuickPopupCache === "undefined")
                        return null

                    const loader = topBarQuickPopupCache.itemAt(index)
                    return loader && loader.item ? loader.item : null
                }

                function opacityTransitionDuration(showing) {
                    if (showing)
                        return fadeInDuration
                    return root.quickPopupVisible ? switchFadeOutDuration : closeFadeOutDuration
                }

                Repeater {
                    id: topBarQuickPopupCache

                    model: root.cachedQuickPopupTypes

                    Loader {
                        id: topBarPopupCacheLoader

                        property string cacheType: String(modelData)
                        readonly property bool showing: root.quickPopupVisible && root.visibleQuickPopupType === cacheType
                        readonly property bool closing: !root.quickPopupVisible && root.quickPopupWindowOpen && root.visibleQuickPopupType === cacheType

                        active: showing
                            || closing
                            || opacity > 0.001
                            || (root.quickPopupPreloadEnabled && root.cachedQuickPopupIndex(cacheType) < root.quickPopupPreloadCount)
                        asynchronous: false
                        visible: root.topBarQuickPopupPanelVisible && (showing || closing || opacity > 0.001)
                        opacity: showing ? 1 : 0
                        x: Math.round((topBarPopupLoader.width - width) / 2)
                        y: Math.round((topBarPopupLoader.height - height) / 2)
                        width: root.quickPopupWidthForScreen(cacheType, topBarPanel.panelWidth)
                        height: root.quickPopupHeightForScreen(cacheType, topBarPanel.panelHeight)
                        z: showing ? 2 : 1

                        Behavior on opacity {
                            enabled: veloraTheme.motionEnabled && topBarPopupLoader.active
                            NumberAnimation {
                                duration: topBarPopupLoader.opacityTransitionDuration(topBarPopupCacheLoader.showing)
                                easing.type: topBarPopupCacheLoader.showing ? veloraTheme.motionEaseEnter : veloraTheme.motionEaseExit
                            }
                        }

                        onLoaded: {
                            topBarPopupLoader.cacheGeneration += 1
                            if (cacheType === "search" && root.quickPopupType === "search")
                                root.scheduleSearchPopupFocus()
                        }

                        sourceComponent: Component {
                            VeloraSidePopup {
                                theme: veloraTheme
                                externalSurface: true
                                lineReveal: true
                                warmSwitch: root.quickPopupSurfaceReveal > 0.35
                                revealProgressOverride: root.quickPopupSurfaceReveal
                                attachSide: "left"
                                popupType: topBarPopupCacheLoader.cacheType
                                notificationsModelOverride: notificationHistoryModel
                                open: topBarPopupCacheLoader.showing
                                interactiveFocus: root.quickPopupType === topBarPopupCacheLoader.cacheType
                                    && (topBarPopupCacheLoader.cacheType === "search" || topBarPopupCacheLoader.cacheType === "agenda" || topBarPopupCacheLoader.cacheType === "weatherPanel")
                                width: topBarPopupCacheLoader.width
                                height: topBarPopupCacheLoader.height
                                visible: topBarPopupCacheLoader.visible
                                onHoldOpenChanged: root.setQuickPopupHoldOpen(topBarPopupCacheLoader.cacheType, holdOpen)
                                onOpenChanged: {
                                    if (!open && topBarPopupCacheLoader.cacheType === "search")
                                        root.setQuickPopupHoldOpen(topBarPopupCacheLoader.cacheType, false)
                                }
                                onCloseRequested: root.closeQuickPopup()
                                onPopupRequested: function(type) {
                                    root.openAdaptiveBarPopup(type, root.defaultTopBarPopupCenterX(type))
                                }
                                onPointerInsideChanged: function(inside) {
                                    root.quickPopupHovering = inside
                                    if (inside)
                                        hoverCloseTimer.stop()
                                    else if (root.hoverPopupType.length > 0)
                                        root.scheduleHoverClose()
                                }
                            }
                        }
                    }
                }

                Keys.onEscapePressed: root.closeQuickPopup()

                Behavior on x {
                    enabled: veloraTheme.motionEnabled && topBarPopupLoader.active
                    NumberAnimation {
                        duration: topBarPopupLoader.geometryDuration
                        easing.type: veloraTheme.motionEaseEnter
                    }
                }

                Behavior on y {
                    enabled: veloraTheme.motionEnabled && topBarPopupLoader.active
                    NumberAnimation {
                        duration: topBarPopupLoader.geometryDuration
                        easing.type: veloraTheme.motionEaseEnter
                    }
                }

                Behavior on width {
                    enabled: veloraTheme.motionEnabled && topBarPopupLoader.active
                    NumberAnimation {
                        duration: topBarPopupLoader.geometryDuration
                        easing.type: veloraTheme.motionEaseEnter
                    }
                }

                Behavior on height {
                    enabled: veloraTheme.motionEnabled && topBarPopupLoader.active
                    NumberAnimation {
                        duration: topBarPopupLoader.geometryDuration
                        easing.type: veloraTheme.motionEaseEnter
                    }
                }
            }
        }
    }

    Variants {
        model: []

        PanelWindow {
            id: geminiTopWindow

            required property var modelData
            readonly property int panelWidth: modelData.width > 0 ? modelData.width : 1920
            readonly property int panelHeight: modelData.height > 0 ? modelData.height : 1200
            readonly property int areaX: root.mainAreaX(panelWidth)
            readonly property int areaWidth: root.mainAreaWidth(panelWidth)
            readonly property bool expanded: geminiTopPanel.item && geminiTopPanel.item.conversationActive
            readonly property int targetWidth: Math.round(Math.min(820, Math.max(760, panelWidth * 0.417)))
            readonly property int compactHeight: Math.round(Math.min(196, Math.max(172, panelHeight * 0.155)))
            readonly property int expandedHeight: Math.round(Math.min(620, Math.max(480, panelHeight * 0.56)))
            readonly property int targetHeight: expanded ? expandedHeight : compactHeight
            readonly property int targetX: Math.round((panelWidth - targetWidth) / 2)
            readonly property int targetY: root.geminiTopOpen ? 0 : -targetHeight - 18

            screen: modelData
            color: "transparent"
            implicitWidth: panelWidth
            implicitHeight: panelHeight
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: true
            visible: true

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "velora-shell-gemini-top"
            WlrLayershell.keyboardFocus: root.geminiTopKeyboardFocus ? WlrKeyboardFocus.Exclusive : (root.geminiTopOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None)

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            mask: Region {
                Region {
                    item: geminiTopTriggerMask
                    radius: 0
                }

                Region {
                    item: geminiTopInputMask
                    radius: 24
                }

            }

            Item {
                id: geminiTopTriggerMask

                x: 0
                y: 0
                width: geminiTopWindow.panelWidth
                height: root.geminiTopOpen ? 0 : 12
                z: 1

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    onEntered: {
                        root.geminiTopTriggerHovering = true
                        root.openGeminiTopFromMouse()
                    }
                    onExited: {
                        root.geminiTopTriggerHovering = false
                        root.scheduleGeminiTopHoverClose()
                    }
                }
            }

            Item {
                id: geminiTopOutsideMask

                x: 0
                y: 0
                width: 0
                height: 0
                z: 1

                MouseArea {
                    anchors.fill: parent
                    enabled: false
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: root.closeGeminiTop()
                }
            }

            Item {
                id: geminiTopInputMask

                x: geminiTopFrame.x
                y: geminiTopFrame.y
                width: root.geminiTopWindowOpen ? geminiTopFrame.width : 0
                height: root.geminiTopWindowOpen ? geminiTopFrame.height : 0
                z: 2
            }

            Loader {
                id: geminiTopPanel

                x: geminiTopFrame.x
                y: geminiTopFrame.y
                width: geminiTopFrame.width
                height: geminiTopFrame.height
                active: root.geminiTopWindowOpen
                visible: active
                z: 4

                sourceComponent: Component {
                    VeloraGeminiTopPanel {
                        theme: veloraTheme
                        open: root.geminiTopOpen
                        autoFocus: root.geminiTopKeyboardFocus
                        panelGlass: root.desktopFrameMatteColor()
                        panelLine: root.desktopFrameBorderColor()
                        focusRequest: root.geminiTopFocusRequest
                        geminiScript: Quickshell.shellDir + "/scripts/velora-gemini-ask"
                        onActivated: root.engageGeminiTop()
                        onCloseRequested: root.closeGeminiTop()
                        onPointerInsideChanged: function(inside) {
                            root.setGeminiTopPanelHovering(inside)
                        }
                    }
                }
            }

            Item {
                id: geminiTopFrame

                width: geminiTopWindow.targetWidth
                height: geminiTopWindow.targetHeight
                x: geminiTopWindow.targetX
                y: geminiTopWindow.targetY
                opacity: 1

                Behavior on y {
                    enabled: veloraTheme.motionEnabled
                    NumberAnimation {
                        duration: root.geminiTopOpen ? veloraTheme.motionPanelIn : root.quickPopupLineCloseDuration
                        easing.type: root.geminiTopOpen ? Easing.BezierSpline : Easing.InOutCubic
                        easing.bezierCurve: root.geminiTopOpen ? veloraTheme.motionCurveEmphasizedAccel : veloraTheme.motionCurveStandard
                    }
                }

                Behavior on height {
                    enabled: veloraTheme.motionEnabled
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEnter
                    }
                }

                Behavior on opacity {
                    enabled: veloraTheme.motionEnabled
                    NumberAnimation {
                        duration: root.geminiTopOpen ? Math.max(180, veloraTheme.motionPanelIn * 0.62) : Math.max(320, root.quickPopupLineCloseDuration * 0.52)
                        easing.type: root.geminiTopOpen ? Easing.BezierSpline : Easing.InOutCubic
                        easing.bezierCurve: root.geminiTopOpen ? veloraTheme.motionCurveEmphasizedAccel : veloraTheme.motionCurveStandard
                    }
                }
            }
        }
    }

    Variants {
        model: []

        PanelWindow {
            id: topWallpaperPopupPanel

            required property var modelData
            readonly property int popupWidth: root.topWallpaperPopupWidth(modelData.width > 0 ? modelData.width : 1920)
            readonly property int popupHeight: root.topWallpaperPopupHeight(modelData.height > 0 ? modelData.height : 1200)

            screen: modelData
            color: "transparent"
            implicitWidth: modelData.width > 0 ? modelData.width : popupWidth
            implicitHeight: root.topWallpaperPopupMargin + popupHeight + 18
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: root.topWallpaperKeyboardFocus

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "velora-shell-wallpaper-top-popup"
            WlrLayershell.keyboardFocus: root.topWallpaperKeyboardFocus ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            anchors {
                top: true
                left: true
                right: true
            }

            mask: Region {
                Region {
                    item: topWallpaperPopupSurface
                    radius: root.topWallpaperPopupRadius
                }
            }

            Item {
                id: topWallpaperPopupStage

                x: Math.round((parent.width - width + (root.barOnRight ? root.barReserveWidth : -root.barReserveWidth)) / 2)
                y: root.topWallpaperPopupMargin
                width: topWallpaperPopupPanel.popupWidth
                height: topWallpaperPopupPanel.popupHeight
                focus: root.topWallpaperKeyboardFocus

                Keys.onEscapePressed: {
                    root.toggleTopWallpaperPopup(false, false)
                }

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Left || event.key === Qt.Key_A) {
                        root.moveTopWallpaper(-1)
                        event.accepted = true
                        return
                    }

                    if (event.key === Qt.Key_Right || event.key === Qt.Key_D) {
                        root.moveTopWallpaper(1)
                        event.accepted = true
                        return
                    }

                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.applyTopWallpaperSelection()
                        event.accepted = true
                        return
                    }
                }

                Component.onCompleted: {
                    if (root.topWallpaperKeyboardFocus)
                        forceActiveFocus()
                }

                Connections {
                    target: root

                    function onTopWallpaperKeyboardFocusChanged() {
                        if (root.topWallpaperKeyboardFocus)
                            topWallpaperPopupStage.forceActiveFocus()
                    }
                }

                DropShadow {
                    anchors.fill: topWallpaperPopupSurface
                    horizontalOffset: 0
                    verticalOffset: 12
                    radius: 34
                    samples: 57
                    color: veloraTheme.alpha(veloraTheme.shadowColor, veloraTheme.themeMode === "dark" ? 0.16 : 0.10)
                    source: topWallpaperPopupSurface
                }

                Rectangle {
                    id: topWallpaperPopupSurface

                    anchors.fill: parent
                    radius: root.topWallpaperPopupRadius
                    color: "transparent"
                    border.width: 0
                    border.color: root.desktopFrameBorderColor()
                    antialiasing: true
                }

                Item {
                    id: topWallpaperImageSlices

                    readonly property int edgeFadeHeight: Math.round(Math.min(46, Math.max(26, height * 0.23)))

                    anchors.fill: topWallpaperPopupSurface
                    visible: root.topWallpaperPopupOpen || root.topWallpaperFrameReveal > 0.01
                    clip: true
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: topWallpaperClipMask
                    }

                    Canvas {
                        id: topWallpaperClipMask

                        anchors.fill: parent
                        visible: false

                        onPaint: {
                            const ctx = getContext("2d")
                            const fadeRatio = Math.max(0.12, Math.min(0.27, topWallpaperImageSlices.edgeFadeHeight / Math.max(1, height)))
                            const r = Math.min(root.topWallpaperPopupRadius, width / 2, height / 2)
                            const gradient = ctx.createLinearGradient(0, 0, 0, height)

                            ctx.clearRect(0, 0, width, height)
                            gradient.addColorStop(0.00, "rgba(255,255,255,0.00)")
                            gradient.addColorStop(fadeRatio * 0.34, "rgba(255,255,255,0.28)")
                            gradient.addColorStop(fadeRatio, "rgba(255,255,255,1.00)")
                            gradient.addColorStop(1.00, "rgba(255,255,255,1.00)")

                            ctx.beginPath()
                            ctx.moveTo(r, 0)
                            ctx.lineTo(width - r, 0)
                            ctx.quadraticCurveTo(width, 0, width, r)
                            ctx.lineTo(width, height - r)
                            ctx.quadraticCurveTo(width, height, width - r, height)
                            ctx.lineTo(r, height)
                            ctx.quadraticCurveTo(0, height, 0, height - r)
                            ctx.lineTo(0, r)
                            ctx.quadraticCurveTo(0, 0, r, 0)
                            ctx.closePath()
                            ctx.fillStyle = gradient
                            ctx.fill()
                        }

                        Component.onCompleted: requestPaint()
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                    }

                    Repeater {
                        model: root.topWallpaperSliceCount + 2

                        delegate: Item {
                            id: wallpaperSlice

                            readonly property int logicalIndex: index - 1 - root.topWallpaperSelectedSlot
                            readonly property real slotWidth: topWallpaperImageSlices.width / Math.max(1, root.topWallpaperSliceCount)
                            readonly property real sliceSkew: Math.max(22, Math.min(36, topWallpaperImageSlices.width * 0.038))
                            readonly property real slideOffset: -root.topWallpaperSlideDirection * root.topWallpaperSlideEase() * slotWidth
                            readonly property var entry: root.topWallpaperEntry(logicalIndex)

                            anchors.fill: parent
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: wallpaperSliceMask
                            }

                            Canvas {
                                id: wallpaperSliceMask

                                anchors.fill: parent
                                visible: false

                                onPaint: {
                                    const ctx = getContext("2d")
                                    const left = wallpaperSlice.logicalIndex * wallpaperSlice.slotWidth + wallpaperSlice.slideOffset
                                    const right = left + wallpaperSlice.slotWidth
                                    const skew = wallpaperSlice.sliceSkew

                                    ctx.clearRect(0, 0, width, height)
                                    ctx.beginPath()
                                    ctx.moveTo(left + skew, -8)
                                    ctx.lineTo(right + skew, -8)
                                    ctx.lineTo(right - skew, height + 8)
                                    ctx.lineTo(left - skew, height + 8)
                                    ctx.closePath()
                                    ctx.fillStyle = "white"
                                    ctx.fill()
                                }

                                Component.onCompleted: requestPaint()
                                onWidthChanged: requestPaint()
                                onHeightChanged: requestPaint()

                                Connections {
                                    target: root

                                    function onTopWallpaperSlideProgressChanged() { wallpaperSliceMask.requestPaint() }
                                    function onTopWallpaperSlideDirectionChanged() { wallpaperSliceMask.requestPaint() }
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: root.desktopFrameMatteColor()
                            }

                            Image {
                                anchors.fill: parent
                                source: wallpaperSlice.entry && wallpaperSlice.entry.preview ? wallpaperSlice.entry.preview : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                smooth: true
                                mipmap: true
                                opacity: 0.90
                                sourceSize.width: 560
                                sourceSize.height: 360
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: root.desktopFrameMatteColor()
                                opacity: veloraTheme.themeMode === "dark" ? 0.22 : 0.14
                            }
                        }
                    }

                    Repeater {
                        model: 2

                        delegate: Item {
                            id: selectedWallpaperLayer

                            readonly property bool incoming: index === 1
                            readonly property real progress: root.topWallpaperSlideDirection === 0 ? 0 : root.topWallpaperSlideEase()
                            readonly property real slotWidth: topWallpaperImageSlices.width / Math.max(1, root.topWallpaperSliceCount)
                            readonly property real activeWidth: Math.min(topWallpaperImageSlices.width * 0.44, slotWidth * 4.35)
                            readonly property real inactiveWidth: slotWidth * 1.04
                            readonly property real currentWidth: incoming
                                ? inactiveWidth + (activeWidth - inactiveWidth) * progress
                                : activeWidth - (activeWidth - inactiveWidth) * progress
                            readonly property real travel: slotWidth * 1.18
                            readonly property real centerX: topWallpaperImageSlices.width / 2
                                + (incoming ? root.topWallpaperSlideDirection * travel * (1 - progress) : -root.topWallpaperSlideDirection * travel * progress)
                            readonly property real sliceSkew: Math.max(26, Math.min(42, topWallpaperImageSlices.width * 0.052))
                            readonly property var entry: root.topWallpaperEntry(incoming ? root.topWallpaperSlideDirection : 0)

                            anchors.fill: parent
                            visible: !incoming || root.topWallpaperSlideDirection !== 0
                            opacity: incoming ? progress : 1 - progress * 0.34
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: selectedWallpaperMask
                            }

                            Canvas {
                                id: selectedWallpaperMask

                                anchors.fill: parent
                                visible: false

                                onPaint: {
                                    const ctx = getContext("2d")
                                    const half = selectedWallpaperLayer.currentWidth / 2
                                    const left = selectedWallpaperLayer.centerX - half
                                    const right = selectedWallpaperLayer.centerX + half
                                    const skew = selectedWallpaperLayer.sliceSkew

                                    ctx.clearRect(0, 0, width, height)
                                    ctx.beginPath()
                                    ctx.moveTo(left + skew, -8)
                                    ctx.lineTo(right + skew, -8)
                                    ctx.lineTo(right - skew, height + 8)
                                    ctx.lineTo(left - skew, height + 8)
                                    ctx.closePath()
                                    ctx.fillStyle = "white"
                                    ctx.fill()
                                }

                                Component.onCompleted: requestPaint()
                                onWidthChanged: requestPaint()
                                onHeightChanged: requestPaint()

                                Connections {
                                    target: root

                                    function onTopWallpaperSlideProgressChanged() { selectedWallpaperMask.requestPaint() }
                                    function onTopWallpaperSlideDirectionChanged() { selectedWallpaperMask.requestPaint() }
                                }
                            }

                            Image {
                                anchors.fill: parent
                                source: selectedWallpaperLayer.entry && selectedWallpaperLayer.entry.preview ? selectedWallpaperLayer.entry.preview : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                smooth: true
                                mipmap: true
                                opacity: 0.98
                                sourceSize.width: 720
                                sourceSize.height: 420
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: root.desktopFrameMatteColor()
                                opacity: veloraTheme.themeMode === "dark" ? 0.10 : 0.06
                            }
                        }
                    }

                    Rectangle {
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }
                        height: topWallpaperImageSlices.edgeFadeHeight
                        color: "transparent"
                        gradient: Gradient {
                            GradientStop { position: 0.00; color: root.desktopFrameMatteColor() }
                            GradientStop { position: 0.32; color: veloraTheme.alpha(veloraTheme.surfaceSidebar, root.desktopFrameMatteOpacity * 0.42) }
                            GradientStop { position: 1.00; color: veloraTheme.alpha(veloraTheme.surfaceSidebar, 0.0) }
                        }
                    }

                }

                Rectangle {
                    anchors.fill: topWallpaperPopupSurface
                    anchors.margins: 1
                    radius: Math.max(0, topWallpaperPopupSurface.radius - 1)
                    color: "transparent"
                    border.width: 1
                    border.color: root.sidebarPanelInnerLineColor()
                    antialiasing: true
                }

                Canvas {
                    id: topWallpaperSliceCanvas

                    anchors.fill: topWallpaperPopupSurface
                    visible: root.topWallpaperPopupOpen || root.topWallpaperFrameReveal > 0.01
                    antialiasing: true

                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        const sliceCount = root.topWallpaperSliceCount
                        const slotWidth = width / Math.max(1, sliceCount)
                        const lean = Math.max(22, Math.min(36, width * 0.038))
                        const slideOffset = -root.topWallpaperSlideDirection * root.topWallpaperSlideEase() * slotWidth
                        const selectedProgress = root.topWallpaperSlideDirection === 0 ? 0 : root.topWallpaperSlideEase()
                        const selectedCenter = width / 2 - root.topWallpaperSlideDirection * slotWidth * 1.18 * selectedProgress
                        const selectedWidth = Math.min(width * 0.44, slotWidth * 4.35) - (Math.min(width * 0.44, slotWidth * 4.35) - slotWidth * 1.04) * selectedProgress
                        const selectedLeft = selectedCenter - selectedWidth / 2
                        const selectedRight = selectedCenter + selectedWidth / 2
                        const incomingCenter = width / 2 + root.topWallpaperSlideDirection * slotWidth * 1.18 * (1 - selectedProgress)
                        const incomingWidth = root.topWallpaperSlideDirection === 0 ? 0 : slotWidth * 1.04 + (Math.min(width * 0.44, slotWidth * 4.35) - slotWidth * 1.04) * selectedProgress
                        const incomingLeft = incomingCenter - incomingWidth / 2
                        const incomingRight = incomingCenter + incomingWidth / 2
                        const lineColor = root.desktopFrameBorderColor()
                        const highlightColor = root.sidebarPanelInnerLineColor()

                        ctx.lineCap = "round"
                        ctx.lineJoin = "round"

                        for (let i = 0; i <= sliceCount; ++i) {
                            const baseX = slotWidth * i + slideOffset
                            if ((baseX > selectedLeft + lean * 0.25 && baseX < selectedRight - lean * 0.25)
                                    || (root.topWallpaperSlideDirection !== 0 && baseX > incomingLeft + lean * 0.25 && baseX < incomingRight - lean * 0.25))
                                continue

                            ctx.beginPath()
                            ctx.moveTo(baseX + lean, -8)
                            ctx.lineTo(baseX - lean, height + 8)
                            ctx.strokeStyle = veloraTheme.alpha(lineColor, veloraTheme.themeMode === "dark" ? 0.34 : 0.42)
                            ctx.lineWidth = 1.45
                            ctx.stroke()

                            ctx.beginPath()
                            ctx.moveTo(baseX + lean + 3, -5)
                            ctx.lineTo(baseX - lean + 3, height + 5)
                            ctx.strokeStyle = veloraTheme.alpha(highlightColor, veloraTheme.themeMode === "dark" ? 0.18 : 0.24)
                            ctx.lineWidth = 0.85
                            ctx.stroke()
                        }

                        function drawSelectedEdge(edgeX, edgeLean, edgeAlpha) {
                            ctx.beginPath()
                            ctx.moveTo(edgeX + edgeLean, -8)
                            ctx.lineTo(edgeX - edgeLean, height + 8)
                            ctx.strokeStyle = veloraTheme.alpha(lineColor, edgeAlpha)
                            ctx.lineWidth = 2.1
                            ctx.stroke()

                            ctx.beginPath()
                            ctx.moveTo(edgeX + edgeLean + 3, -4)
                            ctx.lineTo(edgeX - edgeLean + 3, height + 4)
                            ctx.strokeStyle = veloraTheme.alpha(highlightColor, edgeAlpha * 0.72)
                            ctx.lineWidth = 0.95
                            ctx.stroke()
                        }

                        drawSelectedEdge(selectedLeft, lean, veloraTheme.themeMode === "dark" ? 0.42 : 0.50)
                        drawSelectedEdge(selectedRight, lean, veloraTheme.themeMode === "dark" ? 0.42 : 0.50)

                        if (root.topWallpaperSlideDirection !== 0) {
                            drawSelectedEdge(incomingLeft, lean, (veloraTheme.themeMode === "dark" ? 0.42 : 0.50) * selectedProgress)
                            drawSelectedEdge(incomingRight, lean, (veloraTheme.themeMode === "dark" ? 0.42 : 0.50) * selectedProgress)
                        }
                    }

                    Component.onCompleted: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    Connections {
                        target: veloraTheme
                        function onSurfaceSidebarChanged() { topWallpaperSliceCanvas.requestPaint() }
                        function onBorderSoftChanged() { topWallpaperSliceCanvas.requestPaint() }
                        function onThemeModeChanged() { topWallpaperSliceCanvas.requestPaint() }
                        function onSidebarBorderGlowChanged() { topWallpaperSliceCanvas.requestPaint() }
                    }

                    Connections {
                        target: root

                        function onTopWallpaperSlideProgressChanged() { topWallpaperSliceCanvas.requestPaint() }
                        function onTopWallpaperSlideDirectionChanged() { topWallpaperSliceCanvas.requestPaint() }
                    }
                }

                Item {
                    id: topWallpaperNavLeft

                    visible: root.topWallpaperPopupOpen
                    anchors {
                        top: topWallpaperPopupSurface.top
                        bottom: topWallpaperPopupSurface.bottom
                        left: topWallpaperPopupSurface.left
                    }
                    width: Math.min(74, topWallpaperPopupSurface.width * 0.16)
                    opacity: topWallpaperNavLeftMouse.containsMouse || root.topWallpaperKeyboardFocus ? 0.82 : 0.30

                    Behavior on opacity {
                        enabled: veloraTheme.motionEnabled
                        NumberAnimation { duration: veloraTheme.motionFast; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        width: 30
                        height: 64
                        radius: 15
                        anchors {
                            left: parent.left
                            leftMargin: 8
                            verticalCenter: parent.verticalCenter
                        }
                        color: veloraTheme.alpha(veloraTheme.surfaceSidebar, veloraTheme.themeMode === "dark" ? 0.36 : 0.42)
                        border.width: 1
                        border.color: root.sidebarPanelInnerLineColor()
                    }

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: 16
                            verticalCenter: parent.verticalCenter
                        }
                        text: "‹"
                        color: veloraTheme.alpha(veloraTheme.textPrimary, veloraTheme.themeMode === "dark" ? 0.76 : 0.68)
                        font.pixelSize: 28
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: topWallpaperNavLeftMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.moveTopWallpaper(-1)
                            topWallpaperPopupStage.forceActiveFocus()
                        }
                    }
                }

                Item {
                    id: topWallpaperNavRight

                    visible: root.topWallpaperPopupOpen
                    anchors {
                        top: topWallpaperPopupSurface.top
                        bottom: topWallpaperPopupSurface.bottom
                        right: topWallpaperPopupSurface.right
                    }
                    width: Math.min(74, topWallpaperPopupSurface.width * 0.16)
                    opacity: topWallpaperNavRightMouse.containsMouse || root.topWallpaperKeyboardFocus ? 0.82 : 0.30

                    Behavior on opacity {
                        enabled: veloraTheme.motionEnabled
                        NumberAnimation { duration: veloraTheme.motionFast; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        width: 30
                        height: 64
                        radius: 15
                        anchors {
                            right: parent.right
                            rightMargin: 8
                            verticalCenter: parent.verticalCenter
                        }
                        color: veloraTheme.alpha(veloraTheme.surfaceSidebar, veloraTheme.themeMode === "dark" ? 0.36 : 0.42)
                        border.width: 1
                        border.color: root.sidebarPanelInnerLineColor()
                    }

                    Text {
                        anchors {
                            right: parent.right
                            rightMargin: 16
                            verticalCenter: parent.verticalCenter
                        }
                        text: "›"
                        color: veloraTheme.alpha(veloraTheme.textPrimary, veloraTheme.themeMode === "dark" ? 0.76 : 0.68)
                        font.pixelSize: 28
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: topWallpaperNavRightMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.moveTopWallpaper(1)
                            topWallpaperPopupStage.forceActiveFocus()
                        }
                    }
                }

            }
        }
    }

    Variants {
        model: []

        PanelWindow {
            id: leftMenuPanel

            required property var modelData
            property real reveal: root.leftMenuOpen ? 1 : 0
            property real mediaReveal: root.leftMenuOpen && root.leftMediaWindowOpen ? 1 : 0
            readonly property int slideDistance: root.leftMenuWidth + root.leftMenuFrameInset + root.leftMenuTriggerWidth + 8
            readonly property bool mediaWindowVisible: root.leftMediaWindowOpen || mediaReveal > 0.01
            readonly property bool menuOnLeft: root.leftMenuOnLeft
            readonly property real detailReveal: mediaReveal * root.leftDetailSwitchProgress
            readonly property int detailWindowWidth: root.leftDetailWindowWidth(root.leftDetailWindowType)
            readonly property int detailWindowHeight: root.leftDetailWindowHeight(root.leftDetailWindowType, height)
            readonly property int menuOpenX: menuOnLeft ? root.leftMenuFrameInset : width - root.leftMenuFrameInset - root.leftMenuWidth
            readonly property int menuSlideOffset: Math.round((1 - reveal) * slideDistance)
            readonly property int menuX: menuOpenX + (menuOnLeft ? -menuSlideOffset : menuSlideOffset)
            readonly property int mediaWindowX: menuOnLeft ? menuOpenX + root.leftMenuWidth + root.leftMediaWindowGap : menuOpenX - root.leftMediaWindowGap - detailWindowWidth
            readonly property int mediaWindowSlideDistance: Math.min(118, Math.max(82, Math.round(detailWindowWidth * 0.18)))

            screen: modelData
            color: "transparent"
            implicitWidth: Math.max(root.leftMenuTriggerWidth, root.leftMenuFrameInset + root.leftMenuWidth + 1, mediaWindowVisible ? root.leftMenuFrameInset + root.leftMenuWidth + root.leftMediaWindowGap + detailWindowWidth + root.leftMenuFrameInset : 0)
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: root.leftMenuOpen

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "velora-shell-left-menu"
            WlrLayershell.keyboardFocus: root.leftMenuOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: root.leftMenuOnLeft
                right: !root.leftMenuOnLeft
            }

            mask: Region {
                Region {
                    item: leftMenuTrigger
                    radius: 0
                }

                Region {
                    item: leftMenuInputMask
                    radius: leftMenuLoader.item ? leftMenuLoader.item.cornerRadius : 13
                }

                Region {
                    item: leftMediaWindowInputMask
                    radius: leftMediaWindowLoader.cornerRadius
                }
            }

            Behavior on reveal {
                enabled: veloraTheme.motionEnabled
                NumberAnimation {
                    duration: root.leftMenuOpen ? veloraTheme.motionLayersIn : veloraTheme.motionLayersOut
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.leftMenuOpen ? veloraTheme.motionCurveEmphasizedDecel : veloraTheme.motionCurveEmphasizedAccel
                }
            }

            Behavior on mediaReveal {
                enabled: veloraTheme.motionEnabled
                NumberAnimation {
                    duration: root.leftMediaWindowOpen ? veloraTheme.motionPanelIn : veloraTheme.motionPanelOut
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.leftMediaWindowOpen ? veloraTheme.motionCurveEmphasizedDecel : veloraTheme.motionCurveEmphasizedAccel
                }
            }

            Item {
                id: leftMenuTrigger

                x: leftMenuPanel.menuOnLeft ? 0 : parent.width - width
                y: 0
                width: root.leftMenuTriggerWidth
                height: parent.height

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onEntered: {
                        root.leftMenuTriggerHovering = true
                        root.updateLeftMenuHovering()
                        root.openLeftMenu()
                    }
                    onPositionChanged: {
                        root.leftMenuTriggerHovering = true
                        root.updateLeftMenuHovering()
                        root.openLeftMenu()
                    }
                    onExited: {
                        root.leftMenuTriggerHovering = false
                        root.scheduleLeftMenuClose()
                    }
                }
            }

            Item {
                id: leftMenuInputMask

                x: leftMenuLoader.x
                y: leftMenuLoader.y
                width: (root.leftMenuOpen || leftMenuPanel.reveal > 0.01) ? leftMenuLoader.width : 0
                height: (root.leftMenuOpen || leftMenuPanel.reveal > 0.01) ? leftMenuLoader.height : 0
            }

            Item {
                id: leftMediaWindowInputMask

                x: leftMediaWindowLoader.x
                y: leftMediaWindowLoader.y
                width: leftMediaWindowLoader.active ? leftMediaWindowLoader.width : 0
                height: leftMediaWindowLoader.active ? leftMediaWindowLoader.height : 0
            }

            VeloraAttachedSurface {
                theme: veloraTheme
                sidebarMaterial: true
                attachSide: leftMenuPanel.menuOnLeft ? "left" : "right"
                x: leftMenuLoader.x
                y: leftMenuLoader.y
                width: leftMenuLoader.width
                height: leftMenuLoader.height
                radius: leftMenuLoader.item ? leftMenuLoader.item.cornerRadius : 13
                revealProgress: leftMenuPanel.reveal
                visible: root.leftMenuOpen || leftMenuPanel.reveal > 0.01
            }

            Loader {
                id: leftMenuLoader

                active: root.leftMenuPreloadEnabled || root.leftMenuOpen || leftMenuPanel.reveal > 0.01
                asynchronous: true
                width: root.leftMenuWidth
                height: Math.max(0, parent.height - root.leftMenuFrameInset * 2)
                x: leftMenuPanel.menuX
                y: root.leftMenuFrameInset
                visible: root.leftMenuOpen || leftMenuPanel.reveal > 0.01
                opacity: leftMenuPanel.reveal

                sourceComponent: Component {
                    VeloraLeftMenu {
                        theme: veloraTheme
                        clockState: leftClockState
                        externalSurface: true
                        attachSide: leftMenuPanel.menuOnLeft ? "left" : "right"
                        popupType: "search"
                        open: root.leftMenuOpen
                        preload: root.leftMenuPreloadEnabled
                        interactiveFocus: root.leftMenuInteractiveFocus
                        width: leftMenuLoader.width
                        height: leftMenuLoader.height
                        visible: leftMenuLoader.visible

                        onMediaWindowRequested: function(centerY) {
                            root.openLeftMediaWindow(leftMenuLoader.y + centerY)
                        }

                        onDetailWindowRequested: function(detailType, centerY) {
                            root.openLeftDetailWindow(detailType, leftMenuLoader.y + centerY)
                        }

                        onSettingsRequested: function(centerY) {
                            root.leftMenuPinned = false
                            root.leftMenuInteractiveFocus = false
                            root.leftMediaWindowOpen = false
                            root.leftMediaWindowEntranceHold = false
                            root.leftDetailSwitchProgress = 1
                            root.openLeftMenu()
                            root.toggleSettingsPanel(leftMenuLoader.y + centerY)
                        }

                        onCloseRequested: {
                            root.leftMenuPinned = false
                            root.leftMenuInteractiveFocus = false
                            root.leftMediaWindowOpen = false
                            root.leftMediaWindowEntranceHold = false
                            root.leftDetailSwitchProgress = 1
                            root.leftMenuOpen = false
                            root.leftMenuTriggerHovering = false
                            root.leftMenuPanelHovering = false
                            root.leftMediaWindowHovering = false
                        }

                        HoverHandler {
                            margin: 18
                            onHoveredChanged: {
                                root.leftMenuPanelHovering = hovered
                                root.updateLeftMenuHovering()
                                if (hovered)
                                    root.openLeftMenu()
                                else
                                    root.scheduleLeftMenuClose()
                            }
                        }
                    }
                }
            }

            VeloraAttachedSurface {
                theme: veloraTheme
                sidebarMaterial: true
                attachSide: leftMenuPanel.menuOnLeft ? "left" : "right"
                x: leftMediaWindowLoader.x
                y: leftMediaWindowLoader.y
                width: leftMediaWindowLoader.width
                height: leftMediaWindowLoader.height
                radius: leftMediaWindowLoader.cornerRadius
                revealProgress: leftMenuPanel.mediaReveal
                visible: leftMenuPanel.mediaWindowVisible
            }

            Loader {
                id: leftMediaWindowLoader

                readonly property int cornerRadius: 22

                active: leftMenuPanel.mediaWindowVisible
                asynchronous: false
                width: leftMenuPanel.detailWindowWidth
                height: leftMenuPanel.detailWindowHeight
                x: leftMenuPanel.mediaWindowX + (leftMenuPanel.menuOnLeft ? -1 : 1) * Math.round((1 - leftMenuPanel.mediaReveal) * leftMenuPanel.mediaWindowSlideDistance)
                y: root.leftMediaWindowY(height, parent.height) + Math.round((1 - leftMenuPanel.mediaReveal) * 14)
                visible: active
                opacity: leftMenuPanel.mediaReveal
                scale: 0.94 + leftMenuPanel.mediaReveal * 0.06
                transformOrigin: leftMenuPanel.menuOnLeft ? Item.Left : Item.Right

                onActiveChanged: if (!active) root.leftMediaWindowHovering = false

                sourceComponent: Component {
                    Item {
                        width: leftMediaWindowLoader.width
                        height: leftMediaWindowLoader.height
                        visible: leftMediaWindowLoader.active
                        opacity: leftMenuPanel.detailReveal
                        scale: 0.975 + leftMenuPanel.detailReveal * 0.025
                        x: (leftMenuPanel.menuOnLeft ? -1 : 1) * Math.round((1 - leftMenuPanel.detailReveal) * 28)
                        transformOrigin: leftMenuPanel.menuOnLeft ? Item.Left : Item.Right

                        VeloraDashboard {
                            anchors.fill: parent
                            theme: veloraTheme
                            compact: true
                            externalSurface: true
                            entryProgress: leftMenuPanel.detailReveal
                            activeSection: "media"
                            visible: root.leftDetailWindowType === "media"
                        }

                        VeloraLeftDetailPanel {
                            anchors.fill: parent
                            theme: veloraTheme
                            clockState: leftClockState
                            attachSide: leftMenuPanel.menuOnLeft ? "left" : "right"
                            detailType: root.leftDetailWindowType
                            entryProgress: leftMenuPanel.detailReveal
                            visible: root.leftDetailWindowType !== "media"
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: leftMediaWindowLoader.active
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                            onEntered: {
                                root.leftMediaWindowHovering = true
                                root.updateLeftMenuHovering()
                                root.openLeftMenu()
                            }
                            onExited: {
                                root.leftMediaWindowHovering = false
                                root.scheduleLeftMenuClose()
                            }
                        }
                    }
                }

                Behavior on y {
                    enabled: veloraTheme.motionEnabled && leftMediaWindowLoader.active
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEmphasized
                        easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                    }
                }

                Behavior on scale {
                    enabled: veloraTheme.motionEnabled && leftMediaWindowLoader.active
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEmphasized
                        easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                    }
                }
            }
        }
    }

    Variants {
        model: root.frameVisualsMounted && !root.shellSuppressedByFullscreen ? Quickshell.screens : []

        PanelWindow {
            id: framePanel

            required property var modelData
            readonly property bool compositorReservedBarSpace: root.sideBarLayoutEnabled && modelData.width > 0 && width <= modelData.width - root.barPanelWidth + 2
            readonly property color frameMatteColor: root.desktopFrameMatteColor()
            readonly property color frameBorderColor: root.desktopFrameBorderColor()
            readonly property color frameHighlightColor: root.desktopFrameHighlightColor()

            visible: false
            screen: modelData
            color: "transparent"
            implicitWidth: modelData.width > 0 ? modelData.width : 1
            implicitHeight: modelData.height > 0 ? modelData.height : 1
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: false

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "velora-shell-frame"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            mask: Region {}

            function frameX() {
                if (compositorReservedBarSpace)
                    return root.desktopFrameMargin
                return root.mainAreaX(width)
            }

            function frameY() {
                return root.desktopFrameY(height)
            }

            function frameWidth() {
                if (compositorReservedBarSpace)
                    return Math.max(0, width - root.desktopFrameMargin * 2)
                return Math.max(0, root.mainAreaWidth(width))
            }

            function frameHeight() {
                return root.desktopFrameHeight(height)
            }

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Canvas {
                id: frameMatteCanvas

                anchors.fill: parent
                antialiasing: true
                visible: false
                opacity: root.frameVisualsReveal

                function paintCorner(ctx, corner, fx, fy, fw, fh, radius) {
                    const x2 = fx + fw
                    const y2 = fy + fh
                    ctx.beginPath()

                    if (corner === "topLeft") {
                        ctx.moveTo(fx, fy)
                        ctx.lineTo(fx + radius, fy)
                        ctx.arc(fx + radius, fy + radius, radius, -Math.PI / 2, Math.PI, true)
                        ctx.lineTo(fx, fy)
                    } else if (corner === "topRight") {
                        ctx.moveTo(x2, fy)
                        ctx.lineTo(x2 - radius, fy)
                        ctx.arc(x2 - radius, fy + radius, radius, -Math.PI / 2, 0, false)
                        ctx.lineTo(x2, fy)
                    } else if (corner === "bottomRight") {
                        ctx.moveTo(x2, y2)
                        ctx.lineTo(x2, y2 - radius)
                        ctx.arc(x2 - radius, y2 - radius, radius, 0, Math.PI / 2, false)
                        ctx.lineTo(x2, y2)
                    } else if (corner === "bottomLeft") {
                        ctx.moveTo(fx, y2)
                        ctx.lineTo(fx + radius, y2)
                        ctx.arc(fx + radius, y2 - radius, radius, Math.PI / 2, Math.PI, false)
                        ctx.lineTo(fx, y2)
                    }

                    ctx.closePath()
                    ctx.fill()
                }

                function paintFrameOutline(ctx, fx, fy, fw, fh, radius) {
                    const x2 = fx + fw
                    const y2 = fy + fh
                    const barSide = root.sideBarLayoutEnabled ? (root.barOnRight ? "right" : "left") : ""
                    const openSideTrim = root.sideBarLayoutEnabled ? Math.max(radius, root.sideVisualizerWaveWidth + 4) : radius
                    const bottomOpenCorner = root.sideBarLayoutEnabled && root.topWallpaperFrameReveal > 0.01
                    const openCornerRadius = bottomOpenCorner ? Math.max(radius, Math.min(34, root.sideVisualizerWaveWidth * 0.52)) : radius
                    const horizontalStart = barSide === "left" ? fx + openSideTrim : fx + radius
                    const horizontalEnd = barSide === "right" ? x2 - openSideTrim : x2 - radius
                    const bottomHorizontalStart = barSide === "left" && bottomOpenCorner ? fx + openCornerRadius : horizontalStart
                    const bottomHorizontalEnd = barSide === "right" && bottomOpenCorner ? x2 - openCornerRadius : horizontalEnd

                    ctx.save()
                    ctx.strokeStyle = framePanel.frameBorderColor
                    ctx.lineWidth = 1
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    ctx.beginPath()

                    if (barSide !== "left") {
                        ctx.moveTo(fx + radius, fy)
                        ctx.arc(fx + radius, fy + radius, radius, -Math.PI / 2, Math.PI, true)
                        ctx.lineTo(fx, y2 - radius)
                        ctx.arc(fx + radius, y2 - radius, radius, Math.PI, Math.PI / 2, true)
                    } else {
                        ctx.moveTo(fx + radius, fy)
                    }

                    if (barSide !== "right") {
                        ctx.moveTo(x2 - radius, fy)
                        ctx.arc(x2 - radius, fy + radius, radius, -Math.PI / 2, 0, false)
                        ctx.lineTo(x2, y2 - radius)
                        ctx.arc(x2 - radius, y2 - radius, radius, 0, Math.PI / 2, false)
                    }

                    if (horizontalEnd > horizontalStart) {
                        ctx.moveTo(horizontalStart, fy)
                        ctx.lineTo(horizontalEnd, fy)
                    }

                    if (bottomHorizontalEnd > bottomHorizontalStart) {
                        ctx.moveTo(bottomHorizontalStart, y2)
                        ctx.lineTo(bottomHorizontalEnd, y2)
                    }

                    if (bottomOpenCorner) {
                        if (barSide === "right") {
                            ctx.moveTo(x2, y2 - openCornerRadius)
                            ctx.arc(x2 - openCornerRadius, y2 - openCornerRadius, openCornerRadius, 0, Math.PI / 2, false)
                        } else {
                            ctx.moveTo(fx, y2 - openCornerRadius)
                            ctx.arc(fx + openCornerRadius, y2 - openCornerRadius, openCornerRadius, Math.PI, Math.PI / 2, true)
                        }
                    }

                    ctx.stroke()
                    ctx.restore()
                }

                onPaint: {
                    const ctx = getContext("2d")
                    const fx = Math.round(framePanel.frameX())
                    const fy = Math.round(framePanel.frameY())
                    const fw = Math.round(framePanel.frameWidth())
                    const fh = Math.round(framePanel.frameHeight())
                    const radius = Math.min(root.desktopFrameRadius, Math.max(0, fw / 2), Math.max(0, fh / 2))

                    ctx.clearRect(0, 0, width, height)
                    if (!root.frameVisualsMounted || fw <= 0 || fh <= 0)
                        return

                    const barSide = root.sideBarLayoutEnabled ? (root.barOnRight ? "right" : "left") : ""
                    const openCornerRadius = root.topWallpaperFrameReveal > 0.01
                        ? Math.max(radius, Math.min(34, root.sideVisualizerWaveWidth * 0.52))
                        : radius

                    ctx.fillStyle = framePanel.frameMatteColor
                    ctx.fillRect(0, 0, width, fy)
                    ctx.fillRect(0, fy + fh, width, Math.max(0, height - fy - fh))
                    if (barSide !== "left") {
                        ctx.fillRect(0, fy, fx, fh)
                        paintCorner(ctx, "topLeft", fx, fy, fw, fh, radius)
                        paintCorner(ctx, "bottomLeft", fx, fy, fw, fh, radius)
                    }
                    if (barSide !== "right") {
                        ctx.fillRect(fx + fw, fy, Math.max(0, width - fx - fw), fh)
                        paintCorner(ctx, "topRight", fx, fy, fw, fh, radius)
                        paintCorner(ctx, "bottomRight", fx, fy, fw, fh, radius)
                    }
                    if (root.sideBarLayoutEnabled && root.topWallpaperFrameReveal > 0.01) {
                        paintCorner(ctx, barSide === "right" ? "bottomRight" : "bottomLeft", fx, fy, fw, fh, openCornerRadius)
                    }
                    paintFrameOutline(ctx, fx, fy, fw, fh, radius)
                }

                Component.onCompleted: if (root.frameVisualsMounted) requestPaint()
                onWidthChanged: if (root.frameVisualsMounted) requestPaint()
                onHeightChanged: if (root.frameVisualsMounted) requestPaint()
                onVisibleChanged: if (visible) requestPaint()
            }

            Rectangle {
                id: desktopFrame

                x: framePanel.frameX()
                y: framePanel.frameY()
                width: framePanel.frameWidth()
                height: framePanel.frameHeight()
                radius: root.desktopFrameRadius
                color: "transparent"
                border.width: 0
                border.color: framePanel.frameBorderColor
                opacity: root.frameVisualsReveal
                antialiasing: true
            }

            Rectangle {
                x: desktopFrame.x + 1
                y: desktopFrame.y + 1
                width: Math.max(0, desktopFrame.width - 2)
                height: Math.max(0, desktopFrame.height - 2)
                radius: Math.max(0, desktopFrame.radius - 1)
                color: "transparent"
                visible: false
                border.width: 1
                border.color: framePanel.frameHighlightColor
                antialiasing: true
            }

            Connections {
                target: veloraTheme
                function onSurfaceBaseChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
                function onSidebarOpacityChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
                function onThemeModeChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
                function onPopupBorderGlowChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
                function onBorderSoftChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
            }

            Connections {
                target: root
                function onBarOnRightChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
                function onDesktopFrameMarginChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
                function onDesktopFrameRadiusChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
                function onTopWallpaperFrameRevealChanged() { if (root.frameVisualsMounted) frameMatteCanvas.requestPaint() }
            }
        }
    }

    Variants {
        model: []

        PanelWindow {
            id: notificationToastPanel

            required property var modelData
            readonly property int screenWidth: modelData.width > 0 ? modelData.width : 1920
            readonly property int surfaceWidth: width > 0 ? width : Math.max(320, screenWidth - root.barReserveWidth)
            readonly property int toastWidth: Math.round(Math.min(Math.max(320, surfaceWidth - 96), Math.max(340, surfaceWidth * 0.18)))
            readonly property int toastHeight: 48
            readonly property int toastRadius: 17

            visible: root.notificationToastMounted
            screen: modelData
            color: "transparent"
            implicitWidth: screenWidth
            implicitHeight: toastHeight
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: false

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "velora-notification-frame"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                left: true
                right: true
            }

            mask: Region {
                Region {
                    item: notificationToastInputMask
                    radius: notificationToastPanel.toastRadius
                }
            }

            Item {
                id: notificationToastInputMask

                x: notificationToastStage.x
                y: 0
                width: root.notificationToastMounted ? notificationToastStage.width : 0
                height: root.notificationToastMounted ? notificationToastStage.height : 0
            }

            Item {
                id: notificationToastStage

                width: notificationToastPanel.toastWidth
                height: notificationToastPanel.toastHeight
                x: Math.round((notificationToastPanel.surfaceWidth - width) / 2)
                y: root.notificationToastVisible ? 0 : -height - 14
                opacity: root.notificationToastVisible ? 1 : 0
                scale: root.notificationToastVisible ? 1 : 0.98
                transformOrigin: Item.Top

                Behavior on y {
                    enabled: veloraTheme.motionEnabled
                    NumberAnimation {
                        duration: root.notificationToastVisible ? 300 : 230
                        easing.type: root.notificationToastVisible ? Easing.OutCubic : Easing.InCubic
                    }
                }

                Behavior on opacity {
                    enabled: veloraTheme.motionEnabled
                    NumberAnimation {
                        duration: root.notificationToastVisible ? 170 : 140
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on scale {
                    enabled: veloraTheme.motionEnabled
                    NumberAnimation {
                        duration: 240
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    id: notificationToastBubble

                    anchors.fill: parent
                    radius: notificationToastPanel.toastRadius
                    color: root.frameVisualsMounted
                        ? root.desktopFrameMatteColor()
                        : veloraTheme.alpha(veloraTheme.surfaceSidebar, veloraTheme.themeMode === "dark" ? 0.82 : 0.74)
                    border.width: 0
                    antialiasing: true
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }
                    height: notificationToastPanel.toastRadius
                    color: notificationToastBubble.color
                }

                Item {
                    id: notificationToastIcon

                    width: 32
                    height: 32
                    x: 10
                    y: Math.round((parent.height - height) / 2)

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: root.notificationIconSurfaceColor(root.notificationToastIconKey)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.22)
                        antialiasing: true
                    }

                    Canvas {
                        id: notificationToastIconCanvas

                        anchors.fill: parent
                        antialiasing: true

                        function drawBell(ctx) {
                            ctx.beginPath()
                            ctx.moveTo(27, 15)
                            ctx.bezierCurveTo(19, 16, 17, 24, 17, 31)
                            ctx.lineTo(14, 37)
                            ctx.quadraticCurveTo(27, 42, 40, 37)
                            ctx.lineTo(37, 31)
                            ctx.bezierCurveTo(37, 24, 35, 16, 27, 15)
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.arc(27, 41, 3.1, 0, Math.PI, false)
                            ctx.stroke()
                        }

                        function drawWhatsapp(ctx) {
                            ctx.beginPath()
                            ctx.arc(27, 26, 15, 0.22 * Math.PI, 1.86 * Math.PI, false)
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.moveTo(17, 37)
                            ctx.lineTo(14, 45)
                            ctx.lineTo(23, 41)
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.moveTo(22, 20)
                            ctx.bezierCurveTo(20, 22, 22, 28, 27, 33)
                            ctx.bezierCurveTo(31, 37, 36, 38, 38, 35)
                            ctx.moveTo(23, 20)
                            ctx.lineTo(26, 25)
                            ctx.moveTo(31, 32)
                            ctx.lineTo(37, 35)
                            ctx.stroke()
                        }

                        onPaint: {
                            const ctx = getContext("2d")

                            ctx.clearRect(0, 0, width, height)
                            ctx.save()
                            ctx.scale(width / 54, height / 54)
                            ctx.lineWidth = 3
                            ctx.lineCap = "round"
                            ctx.lineJoin = "round"
                            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.88)
                            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.88)

                            if (root.notificationToastIconKey === "whatsapp")
                                drawWhatsapp(ctx)
                            else
                                drawBell(ctx)

                            ctx.restore()
                        }

                        Component.onCompleted: requestPaint()

                        Connections {
                            target: root
                            function onNotificationToastIconKeyChanged() { notificationToastIconCanvas.requestPaint() }
                            function onNotificationToastSerialChanged() { notificationToastIconCanvas.requestPaint() }
                        }
                    }
                }

                Text {
                    x: notificationToastIcon.x + notificationToastIcon.width + 13
                    y: Math.round((parent.height - height) / 2) - 1
                    width: parent.width - x - 16
                    text: root.notificationToastTitle
                    color: veloraTheme.textPrimary
                    font.family: veloraTheme.uiFont
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: root.hideNotificationToast()
                }
            }
        }
    }

    Variants {
        model: root.shellSuppressedByFullscreen ? [] : Quickshell.screens

        PanelWindow {
            id: panel

            required property var modelData
            readonly property int panelWidth: modelData.width > 0 ? modelData.width : 1920
            readonly property int panelHeight: modelData.height > 0 ? modelData.height : 1200
            readonly property bool geminiTopExpanded: inlineGeminiTopPanel.item && inlineGeminiTopPanel.item.conversationActive
            readonly property int geminiTopOpenY: Math.max(root.desktopFrameMargin + 18, 30)
            readonly property int geminiTopTargetWidth: Math.round(Math.min(780, Math.max(700, panelWidth * 0.385)))
            readonly property int geminiTopCompactHeight: Math.round(Math.min(176, Math.max(150, panelHeight * 0.138)))
            readonly property int geminiTopExpandedHeight: Math.round(Math.min(560, Math.max(420, panelHeight * 0.50)))
            readonly property int geminiTopTargetHeight: geminiTopExpanded ? geminiTopExpandedHeight : geminiTopCompactHeight
            readonly property int geminiTopTargetX: Math.round((panelWidth - geminiTopTargetWidth) / 2)
            readonly property int geminiTopTargetY: root.geminiTopOpen ? geminiTopOpenY : -geminiTopTargetHeight - 18
            readonly property int geminiTopCornerRadius: 24
            readonly property bool wantsDrawerKeyboard: root.focusMode || root.quickPopupType === "search" || root.quickPopupType === "agenda" || root.quickPopupType === "weatherPanel" || root.settingsPanelOpen || root.wallpaperSelectorOpen || root.topWallpaperKeyboardFocus || root.geminiTopKeyboardFocus

            screen: modelData
            color: "transparent"
            implicitWidth: panelWidth
            exclusiveZone: root.barReserveWidth
            exclusionMode: ExclusionMode.Normal
            focusable: wantsDrawerKeyboard

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "velora-shell-drawers"
            WlrLayershell.keyboardFocus: wantsDrawerKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            mask: Region {
                intersection: Intersection.Combine

                Region {
                    item: barRoot.panelMaskItem
                    radius: barRoot.cornerRadius
                }

                Region {
                    item: inlineGeminiTopTriggerMask
                    radius: 0
                }

                Region {
                    item: inlineGeminiTopInputMask
                    radius: panel.geminiTopCornerRadius
                }

                Region {
                    item: inlineNotificationToastInputMask
                    radius: inlineNotificationToastStage.bubbleRadius
                }

                Region {
                    item: inlineQuickPopupInputMask
                    radius: inlineQuickPopupLoader.cornerRadius
                }

                Region {
                    item: inlineQuickPopupOutsideInputMask
                    radius: 0
                }

                Region {
                    item: inlineModalOverlayInputMask
                    radius: 0
                }

                Region {
                    item: inlineWallpaperInputMask
                    radius: inlineWallpaperLoader.cornerRadius
                }

                Region {
                    item: inlineSettingsInputMask
                    radius: inlineSettingsLoader.cornerRadius
                }

                Region {
                    item: topWallpaperStrip
                    radius: 0
                }

                Region {
                    y: 0
                    width: 0
                    height: 0
                    radius: 0
                }
            }

            anchors {
                top: true
                bottom: true
                left: !root.sideBarLayoutEnabled || !root.barOnRight
                right: !root.sideBarLayoutEnabled || root.barOnRight
            }

            Canvas {
                id: unifiedFrameCanvas

                anchors.fill: parent
                antialiasing: true
                visible: root.frameVisualsMounted
                opacity: 1
                z: 0

                function roundedRectPath(ctx, x, y, w, h, radius) {
                    const r = Math.min(radius, Math.max(0, w / 2), Math.max(0, h / 2))
                    const x2 = x + w
                    const y2 = y + h

                    ctx.beginPath()
                    ctx.moveTo(x + r, y)
                    ctx.lineTo(x2 - r, y)
                    ctx.arcTo(x2, y, x2, y + r, r)
                    ctx.lineTo(x2, y2 - r)
                    ctx.arcTo(x2, y2, x2 - r, y2, r)
                    ctx.lineTo(x + r, y2)
                    ctx.arcTo(x, y2, x, y2 - r, r)
                    ctx.lineTo(x, y + r)
                    ctx.arcTo(x, y, x + r, y, r)
                    ctx.closePath()
                }

                function paintCorner(ctx, corner, fx, fy, fw, fh, radius) {
                    const x2 = fx + fw
                    const y2 = fy + fh
                    ctx.beginPath()

                    if (corner === "topLeft") {
                        ctx.moveTo(fx, fy)
                        ctx.lineTo(fx + radius, fy)
                        ctx.arc(fx + radius, fy + radius, radius, -Math.PI / 2, Math.PI, true)
                        ctx.lineTo(fx, fy)
                    } else if (corner === "topRight") {
                        ctx.moveTo(x2, fy)
                        ctx.lineTo(x2 - radius, fy)
                        ctx.arc(x2 - radius, fy + radius, radius, -Math.PI / 2, 0, false)
                        ctx.lineTo(x2, fy)
                    } else if (corner === "bottomRight") {
                        ctx.moveTo(x2, y2)
                        ctx.lineTo(x2, y2 - radius)
                        ctx.arc(x2 - radius, y2 - radius, radius, 0, Math.PI / 2, false)
                        ctx.lineTo(x2, y2)
                    } else if (corner === "bottomLeft") {
                        ctx.moveTo(fx, y2)
                        ctx.lineTo(fx + radius, y2)
                        ctx.arc(fx + radius, y2 - radius, radius, Math.PI / 2, Math.PI, false)
                        ctx.lineTo(fx, y2)
                    }

                    ctx.closePath()
                    ctx.fill()
                }

                function paintFrameOutline(ctx, fx, fy, fw, fh, radius) {
                    const x2 = fx + fw
                    const y2 = fy + fh
                    const barSide = root.sideBarLayoutEnabled ? (root.barOnRight ? "right" : "left") : ""
                    const openSideTrim = root.sideBarLayoutEnabled ? Math.max(radius, root.sideVisualizerWaveWidth + 4) : radius
                    const bottomOpenCorner = root.sideBarLayoutEnabled && root.topWallpaperFrameReveal > 0.01
                    const openCornerRadius = bottomOpenCorner ? Math.max(radius, Math.min(34, root.sideVisualizerWaveWidth * 0.52)) : radius
                    const horizontalStart = barSide === "left" ? fx + openSideTrim : fx + radius
                    const horizontalEnd = barSide === "right" ? x2 - openSideTrim : x2 - radius
                    const bottomHorizontalStart = barSide === "left" && bottomOpenCorner ? fx + openCornerRadius : horizontalStart
                    const bottomHorizontalEnd = barSide === "right" && bottomOpenCorner ? x2 - openCornerRadius : horizontalEnd

                    ctx.save()
                    ctx.strokeStyle = root.desktopFrameBorderColor()
                    ctx.lineWidth = 1
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    ctx.beginPath()

                    if (barSide !== "left") {
                        ctx.moveTo(fx + radius, fy)
                        ctx.arc(fx + radius, fy + radius, radius, -Math.PI / 2, Math.PI, true)
                        ctx.lineTo(fx, y2 - radius)
                        ctx.arc(fx + radius, y2 - radius, radius, Math.PI, Math.PI / 2, true)
                    }

                    if (barSide !== "right") {
                        ctx.moveTo(x2 - radius, fy)
                        ctx.arc(x2 - radius, fy + radius, radius, -Math.PI / 2, 0, false)
                        ctx.lineTo(x2, y2 - radius)
                        ctx.arc(x2 - radius, y2 - radius, radius, 0, Math.PI / 2, false)
                    }

                    if (horizontalEnd > horizontalStart) {
                        ctx.moveTo(horizontalStart, fy)
                        ctx.lineTo(horizontalEnd, fy)
                    }

                    if (bottomHorizontalEnd > bottomHorizontalStart) {
                        ctx.moveTo(bottomHorizontalStart, y2)
                        ctx.lineTo(bottomHorizontalEnd, y2)
                    }

                    if (bottomOpenCorner) {
                        if (barSide === "right") {
                            ctx.moveTo(x2, y2 - openCornerRadius)
                            ctx.arc(x2 - openCornerRadius, y2 - openCornerRadius, openCornerRadius, 0, Math.PI / 2, false)
                        } else {
                            ctx.moveTo(fx, y2 - openCornerRadius)
                            ctx.arc(fx + openCornerRadius, y2 - openCornerRadius, openCornerRadius, Math.PI, Math.PI / 2, true)
                        }
                    }

                    ctx.stroke()
                    ctx.restore()
                }

                function paintSidebarGutterFill(ctx) {
                    if (!root.sideBarLayoutEnabled)
                        return

                    const bx = Math.round(root.barX(width))
                    const by = root.sidebarVerticalMargin
                    const bw = root.sidebarVisualWidth
                    const bh = Math.max(0, height - root.sidebarVerticalMargin * 2)
                    const radius = Math.min(root.sidebarCornerRadius, Math.max(0, bw / 2), Math.max(0, bh / 2))
                    const frameTop = root.desktopFrameMargin
                    const frameBottom = Math.max(frameTop, height - root.desktopFrameMargin)
                    const capX = root.barOnRight ? bx : 0
                    const capW = root.barOnRight ? Math.max(0, width - bx) : Math.max(0, bx + bw)
                    const outerStripX = root.barOnRight ? bx + bw : 0
                    const outerStripW = root.barOnRight ? Math.max(0, width - bx - bw) : Math.max(0, bx)

                    if (bw <= 0 || bh <= 0)
                        return

                    ctx.save()
                    ctx.fillStyle = root.sidebarPanelMaterialColor()
                    ctx.fillRect(capX, frameTop, capW, Math.max(0, by - frameTop))
                    ctx.fillRect(capX, by + bh, capW, Math.max(0, frameBottom - by - bh))
                    ctx.fillRect(outerStripX, by, outerStripW, bh)

                    paintCorner(ctx, "topLeft", bx, by, bw, bh, radius)
                    paintCorner(ctx, "topRight", bx, by, bw, bh, radius)
                    paintCorner(ctx, "bottomRight", bx, by, bw, bh, radius)
                    paintCorner(ctx, "bottomLeft", bx, by, bw, bh, radius)

                    ctx.fillStyle = root.sidebarBarMaterialColor()
                    roundedRectPath(ctx, bx, by, bw, bh, radius)
                    ctx.fill()
                    ctx.restore()
                }

                function paintSidebarSurface(ctx) {
                    if (!root.sideBarLayoutEnabled)
                        return

                    const bx = Math.round(root.barX(width))
                    const by = root.sidebarVerticalMargin
                    const bw = root.sidebarVisualWidth
                    const bh = Math.max(0, height - root.sidebarVerticalMargin * 2)
                    const radius = Math.min(root.sidebarCornerRadius, Math.max(0, bw / 2), Math.max(0, bh / 2))

                    if (bw <= 0 || bh <= 0)
                        return

                    ctx.save()

                    if (root.quickPopupJoinedToBar) {
                        ctx.restore()
                        return
                    }

                    ctx.strokeStyle = root.sidebarPanelBorderColor()
                    ctx.lineWidth = 1
                    roundedRectPath(ctx, bx + 0.5, by + 0.5, Math.max(0, bw - 1), Math.max(0, bh - 1), Math.max(0, radius - 0.5))
                    ctx.stroke()

                    ctx.strokeStyle = root.sidebarPanelInnerLineColor()
                    ctx.lineWidth = 1
                    roundedRectPath(ctx, bx + 1.5, by + 1.5, Math.max(0, bw - 3), Math.max(0, bh - 3), Math.max(0, radius - 1.5))
                    ctx.stroke()
                    ctx.restore()
                }

                function paintInlineNotificationToast(ctx) {
                    if (!inlineNotificationToastStage.visible || !root.notificationToastMounted || inlineNotificationToastStage.width <= 0 || inlineNotificationToastStage.height <= 0 || inlineNotificationToastStage.opacity <= 0.01)
                        return

                    const tx = Math.round(inlineNotificationToastStage.x)
                    const ty = Math.round(inlineNotificationToastStage.y)
                    const tw = Math.round(inlineNotificationToastStage.width)
                    const th = Math.round(inlineNotificationToastStage.height)
                    const attachY = Math.max(ty, root.desktopFrameY(height))
                    const bottomY = ty + th
                    const bodyHeight = Math.max(0, bottomY - attachY)
                    const radius = Math.min(inlineNotificationToastStage.bubbleRadius, Math.max(0, tw / 2), Math.max(0, bodyHeight / 2))

                    if (bodyHeight <= 0)
                        return

                    ctx.save()
                    ctx.globalAlpha = root.frameVisualsReveal * inlineNotificationToastStage.opacity
                    ctx.fillStyle = root.desktopFrameMatteColor()
                    ctx.beginPath()
                    ctx.moveTo(tx, attachY)
                    ctx.lineTo(tx + tw, attachY)
                    ctx.lineTo(tx + tw, bottomY - radius)
                    ctx.arcTo(tx + tw, bottomY, tx + tw - radius, bottomY, radius)
                    ctx.lineTo(tx + radius, bottomY)
                    ctx.arcTo(tx, bottomY, tx, bottomY - radius, radius)
                    ctx.lineTo(tx, attachY)
                    ctx.closePath()
                    ctx.fill()

                    ctx.strokeStyle = root.desktopFrameBorderColor()
                    ctx.lineWidth = 1
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    ctx.beginPath()
                    ctx.moveTo(tx + tw - 0.5, attachY + 0.5)
                    ctx.lineTo(tx + tw - 0.5, bottomY - radius)
                    ctx.arcTo(tx + tw - 0.5, bottomY - 0.5, tx + tw - radius, bottomY - 0.5, radius)
                    ctx.lineTo(tx + radius, bottomY - 0.5)
                    ctx.arcTo(tx + 0.5, bottomY - 0.5, tx + 0.5, bottomY - radius, radius)
                    ctx.lineTo(tx + 0.5, attachY + 0.5)
                    ctx.stroke()
                    ctx.restore()
                }

                function paintGeminiTopSurface(ctx) {
                    if (!root.geminiTopWindowOpen && inlineGeminiTopFrame.opacity <= 0.001)
                        return
                    if (inlineGeminiTopFrame.width <= 0 || inlineGeminiTopFrame.height <= 0 || inlineGeminiTopFrame.opacity <= 0.001)
                        return

                    const gx = Math.round(inlineGeminiTopFrame.x)
                    const gy = Math.round(inlineGeminiTopFrame.y)
                    const gw = Math.round(inlineGeminiTopFrame.width)
                    const gh = Math.round(inlineGeminiTopFrame.height)
                    const radius = Math.min(panel.geminiTopCornerRadius, Math.max(0, gw / 2), Math.max(0, gh / 2))

                    ctx.save()
                    ctx.globalAlpha = root.frameVisualsReveal * inlineGeminiTopFrame.opacity
                    ctx.fillStyle = root.desktopFrameMatteColor()
                    ctx.beginPath()
                    ctx.moveTo(gx, gy)
                    ctx.lineTo(gx + gw, gy)
                    ctx.lineTo(gx + gw, gy + gh - radius)
                    ctx.arcTo(gx + gw, gy + gh, gx + gw - radius, gy + gh, radius)
                    ctx.lineTo(gx + radius, gy + gh)
                    ctx.arcTo(gx, gy + gh, gx, gy + gh - radius, radius)
                    ctx.lineTo(gx, gy)
                    ctx.closePath()
                    ctx.fill()

                    ctx.strokeStyle = root.desktopFrameBorderColor()
                    ctx.lineWidth = 1
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    ctx.beginPath()
                    ctx.moveTo(gx + gw - 0.5, gy + 0.5)
                    ctx.lineTo(gx + gw - 0.5, gy + gh - radius)
                    ctx.arcTo(gx + gw - 0.5, gy + gh - 0.5, gx + gw - radius, gy + gh - 0.5, radius)
                    ctx.lineTo(gx + radius, gy + gh - 0.5)
                    ctx.arcTo(gx + 0.5, gy + gh - 0.5, gx + 0.5, gy + gh - radius, radius)
                    ctx.lineTo(gx + 0.5, gy + 0.5)
                    ctx.stroke()
                    ctx.restore()
                }

                onPaint: {
                    const ctx = getContext("2d")
                    const fx = root.mainAreaX(width)
                    const fy = root.desktopFrameY(height)
                    const fw = root.mainAreaWidth(width)
                    const fh = root.desktopFrameHeight(height)
                    const radius = Math.min(root.desktopFrameRadius, Math.max(0, fw / 2), Math.max(0, fh / 2))
                    const barSide = root.sideBarLayoutEnabled ? (root.barOnRight ? "right" : "left") : ""
                    const openCornerRadius = root.topWallpaperFrameReveal > 0.01
                        ? Math.max(radius, Math.min(34, root.sideVisualizerWaveWidth * 0.52))
                        : radius

                    ctx.clearRect(0, 0, width, height)
                    if (!root.frameVisualsMounted || fw <= 0 || fh <= 0)
                        return

                    ctx.save()
                    ctx.globalAlpha = root.frameVisualsReveal
                    ctx.fillStyle = root.desktopFrameMatteColor()
                    ctx.fillRect(0, 0, width, fy)
                    ctx.fillRect(0, fy + fh, width, Math.max(0, height - fy - fh))

                    if (barSide !== "left") {
                        ctx.fillRect(0, fy, fx, fh)
                        paintCorner(ctx, "topLeft", fx, fy, fw, fh, radius)
                        paintCorner(ctx, "bottomLeft", fx, fy, fw, fh, radius)
                    }

                    if (barSide !== "right") {
                        ctx.fillRect(fx + fw, fy, Math.max(0, width - fx - fw), fh)
                        paintCorner(ctx, "topRight", fx, fy, fw, fh, radius)
                        paintCorner(ctx, "bottomRight", fx, fy, fw, fh, radius)
                    }
                    if (root.sideBarLayoutEnabled && root.topWallpaperFrameReveal > 0.01) {
                        paintCorner(ctx, barSide === "right" ? "bottomRight" : "bottomLeft", fx, fy, fw, fh, openCornerRadius)
                    }

                    paintFrameOutline(ctx, fx, fy, fw, fh, radius)
                    paintGeminiTopSurface(ctx)
                    ctx.restore()

                    paintSidebarGutterFill(ctx)
                    paintSidebarSurface(ctx)
                    paintInlineNotificationToast(ctx)
                }

                Component.onCompleted: if (root.frameVisualsMounted) requestPaint()
                onWidthChanged: if (root.frameVisualsMounted) requestPaint()
                onHeightChanged: if (root.frameVisualsMounted) requestPaint()
                onVisibleChanged: if (visible) requestPaint()
            }

            Connections {
                target: veloraTheme
                function onSurfaceBaseChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onSurfaceSidebarChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onSidebarOpacityChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onBarOpacityChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onThemeModeChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onThemeIdChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onPopupBorderGlowChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onSidebarBorderGlowChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onBorderSoftChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
            }

            Connections {
                target: root
                function onNotificationToastMountedChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onNotificationToastVisibleChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onNotificationToastSerialChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
            }

            Connections {
                target: root
                function onBarOnRightChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onDesktopFrameMarginChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onDesktopFrameRadiusChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onFrameVisualsMountedChanged() { unifiedFrameCanvas.requestPaint() }
                function onFrameVisualsRevealChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onGeminiTopOpenChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onGeminiTopWindowOpenChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onQuickPopupJoinedToBarChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onTopWallpaperFrameRevealChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
            }

            Item {
                id: inlineGeminiTopTriggerMask

                x: Math.round(root.mainAreaX(panel.panelWidth))
                y: 0
                width: Math.round(root.mainAreaWidth(panel.panelWidth))
                height: root.geminiTopWindowOpen ? Math.max(12, root.desktopFrameMargin + 4) : Math.max(12, root.desktopFrameMargin + 2)
                z: 35

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    onEntered: {
                        root.geminiTopTriggerHovering = true
                        root.openGeminiTopFromMouse()
                    }
                    onExited: {
                        root.geminiTopTriggerHovering = false
                        root.scheduleGeminiTopHoverClose()
                    }
                }
            }

            Item {
                id: inlineGeminiTopFrame

                readonly property bool mounted: root.geminiTopWindowOpen

                width: panel.geminiTopTargetWidth
                height: panel.geminiTopTargetHeight
                x: panel.geminiTopTargetX
                y: panel.geminiTopTargetY
                opacity: 1
                visible: mounted
                z: 26

                onXChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onYChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onWidthChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onHeightChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                Behavior on y {
                    enabled: veloraTheme.motionEnabled
                    NumberAnimation {
                        duration: root.geminiTopOpen ? veloraTheme.motionPanelIn : root.quickPopupLineCloseDuration
                        easing.type: root.geminiTopOpen ? Easing.BezierSpline : Easing.InOutCubic
                        easing.bezierCurve: root.geminiTopOpen ? veloraTheme.motionCurveEmphasizedAccel : veloraTheme.motionCurveStandard
                    }
                }

                Behavior on height {
                    enabled: veloraTheme.motionEnabled
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEnter
                    }
                }
            }

            Item {
                id: inlineGeminiTopInputMask

                x: inlineGeminiTopFrame.x
                y: inlineGeminiTopFrame.y
                width: root.geminiTopWindowOpen ? inlineGeminiTopFrame.width : 0
                height: root.geminiTopWindowOpen ? inlineGeminiTopFrame.height : 0
                z: 27
            }

            Loader {
                id: inlineGeminiTopPanel

                x: inlineGeminiTopFrame.x
                y: inlineGeminiTopFrame.y
                width: inlineGeminiTopFrame.width
                height: inlineGeminiTopFrame.height
                active: root.geminiTopWindowOpen
                visible: active
                opacity: inlineGeminiTopFrame.opacity
                z: 32

                sourceComponent: Component {
                    VeloraGeminiTopPanel {
                        theme: veloraTheme
                        open: root.geminiTopOpen
                        autoFocus: root.geminiTopKeyboardFocus
                        embeddedInFrame: true
                        panelGlass: "transparent"
                        panelLine: "transparent"
                        focusRequest: root.geminiTopFocusRequest
                        geminiScript: Quickshell.shellDir + "/scripts/velora-gemini-ask"
                        onActivated: root.engageGeminiTop()
                        onCloseRequested: root.closeGeminiTop()
                        onPointerInsideChanged: function(inside) {
                            root.setGeminiTopPanelHovering(inside)
                        }
                    }
                }
            }

            Item {
                id: screenVisualizerFrame

                readonly property int frameX: Math.round(root.mainAreaX(parent.width))
                readonly property int frameY: Math.round(root.desktopFrameY(parent.height))
                readonly property int frameWidth: Math.round(root.mainAreaWidth(parent.width))
                readonly property int frameHeight: Math.round(root.desktopFrameHeight(parent.height))
                readonly property int band: Math.max(18, Math.min(64, Math.round(16 + veloraTheme.visualizerStrength * 70)))
                readonly property bool activeForPaint: root.screenVisualizerReveal > 0.001 && visible && panel.visible && frameWidth > 0 && frameHeight > 0

                anchors.fill: parent
                visible: root.screenVisualizerReveal > 0.001
                opacity: root.screenVisualizerReveal
                z: 1

                function requestFramePaint(force) {
                    if (!activeForPaint) {
                        screenVisualizerPaintTimer.stop()
                        if (force)
                            screenVisualizerCanvas.requestPaint()
                        return
                    }

                    if (force) {
                        screenVisualizerPaintTimer.stop()
                        screenVisualizerCanvas.requestPaint()
                        return
                    }

                    if (!screenVisualizerPaintTimer.running)
                        screenVisualizerPaintTimer.restart()
                }

                onActiveForPaintChanged: requestFramePaint(true)
                onFrameXChanged: requestFramePaint(true)
                onFrameYChanged: requestFramePaint(true)
                onFrameWidthChanged: requestFramePaint(true)
                onFrameHeightChanged: requestFramePaint(true)
                onBandChanged: requestFramePaint(true)

                Canvas {
                    id: screenVisualizerCanvas

                    readonly property int sampleCount: Math.max(96, Math.min(260, Math.round((width + height) / 12)))
                    readonly property real perimeter: Math.max(1, width * 2 + height * 2)
                    readonly property bool pixelMode: veloraTheme.visualizerMode === "pixels"

                    x: screenVisualizerFrame.frameX
                    y: screenVisualizerFrame.frameY
                    width: screenVisualizerFrame.frameWidth
                    height: screenVisualizerFrame.frameHeight
                    visible: screenVisualizerFrame.visible && width > 0 && height > 0
                    antialiasing: true

                    function rgbaCss(colorValue, opacityValue) {
                        const alphaValue = Math.max(0, Math.min(1, opacityValue))
                        return "rgba(" + Math.round(colorValue.r * 255) + "," + Math.round(colorValue.g * 255) + "," + Math.round(colorValue.b * 255) + "," + alphaValue.toFixed(3) + ")"
                    }

                    function accentColor() {
                        if (veloraTheme.themeId === "pywal16")
                            return veloraTheme.sidebarBorderGlow
                        return veloraTheme.accentPrimary
                    }

                    function rawVisualizerValue(index) {
                        if (!barRoot.cavaValues || barRoot.cavaValues.length <= 0)
                            return 0

                        const value = Number(barRoot.cavaValues[Math.max(0, Math.min(index, barRoot.cavaValues.length - 1))])
                        return Math.max(0, Math.min(1, isNaN(value) ? 0 : value))
                    }

                    function interpolatedVisualizerValue(unit) {
                        const count = Math.max(2, barRoot.cavaBandCount || 28)
                        const normalized = ((unit % 1) + 1) % 1
                        const scaled = normalized * count
                        const left = Math.floor(scaled) % count
                        const right = (left + 1) % count
                        const mix = scaled - left
                        return rawVisualizerValue(left) * (1 - mix) + rawVisualizerValue(right) * mix
                    }

                    function sampleValue(unit) {
                        return interpolatedVisualizerValue(unit)
                    }

                    function sideForDistance(distance) {
                        const w = Math.max(1, width)
                        const h = Math.max(1, height)
                        const d = ((distance % perimeter) + perimeter) % perimeter

                        if (d <= w)
                            return "top"
                        if (d <= w + h)
                            return "right"
                        if (d <= w * 2 + h)
                            return "bottom"
                        return "left"
                    }

                    function sideStrength(side) {
                        if (side === "left")
                            return 1.0
                        if (side === "right")
                            return 0.18
                        return 0.14
                    }

                    function amplitudeFor(unit, sample, side) {
                        const value = sampleValue(unit)
                        const strength = sideStrength(side)
                        const base = side === "left"
                            ? Math.max(5, Math.min(12, screenVisualizerFrame.band * 0.15))
                            : Math.max(2, Math.min(5, screenVisualizerFrame.band * 0.075))
                        const maxAmp = Math.max(base + 1, screenVisualizerFrame.band * Math.min(0.86, 0.30 + veloraTheme.visualizerStrength * 0.62) * strength)
                        const pulse = 0.90 + Math.sin(sample * 0.61) * 0.07
                        return Math.max(3, Math.min(screenVisualizerFrame.band - 1, base + Math.pow(value, 0.76) * maxAmp * pulse))
                    }

                    function pointAtUnit(unit, sample) {
                        const distance = ((unit % 1) + 1) % 1 * perimeter
                        const side = sideForDistance(distance)
                        const amp = amplitudeFor(unit, sample, side)
                        const w = Math.max(1, width)
                        const h = Math.max(1, height)

                        if (distance <= w)
                            return { x: distance, y: amp, side: side }

                        if (distance <= w + h)
                            return { x: w - amp, y: distance - w, side: side }

                        if (distance <= w * 2 + h)
                            return { x: w - (distance - w - h), y: h - amp, side: side }

                        return { x: amp, y: h - (distance - w * 2 - h), side: side }
                    }

                    function pixelPointAtDistance(distance, inward, cell) {
                        const w = Math.max(1, width)
                        const h = Math.max(1, height)
                        const d = ((distance % perimeter) + perimeter) % perimeter

                        if (d <= w)
                            return { x: Math.min(w - cell, Math.max(0, d - cell / 2)), y: inward, side: "top" }

                        if (d <= w + h)
                            return { x: w - cell - inward, y: Math.min(h - cell, Math.max(0, d - w - cell / 2)), side: "right" }

                        if (d <= w * 2 + h)
                            return { x: Math.min(w - cell, Math.max(0, w - (d - w - h) - cell / 2)), y: h - cell - inward, side: "bottom" }

                        return { x: inward, y: Math.min(h - cell, Math.max(0, h - (d - w * 2 - h) - cell / 2)), side: "left" }
                    }

                    function traceClosedPath(ctx, points) {
                        if (points.length <= 0)
                            return

                        ctx.moveTo(points[0].x, points[0].y)
                        for (var i = 1; i <= points.length; i += 1) {
                            const previous = points[(i - 1) % points.length]
                            const current = points[i % points.length]
                            const midX = (previous.x + current.x) / 2
                            const midY = (previous.y + current.y) / 2
                            ctx.quadraticCurveTo(previous.x, previous.y, midX, midY)
                        }
                    }

                    function paintWaveFrame(ctx, points, peak) {
                        const materialAlpha = Math.max(0.035, Math.min(0.08, root.sidebarPanelGlassAlpha() * 0.08))
                        const accentAlpha = Math.min(0.13, 0.035 + peak * 0.12)
                        const accent = accentColor()
                        var fill = rgbaCss(veloraTheme.surfaceSidebar, materialAlpha)

                        if (veloraTheme.visualizerGradientEnabled) {
                            fill = ctx.createLinearGradient(0, 0, width, height)
                            fill.addColorStop(0.0, rgbaCss(veloraTheme.surfaceSidebar, materialAlpha))
                            fill.addColorStop(0.46, rgbaCss(accent, accentAlpha))
                            fill.addColorStop(1.0, rgbaCss(veloraTheme.surfaceSidebar, materialAlpha))
                        }

                        ctx.save()
                        ctx.fillStyle = fill
                        ctx.beginPath()
                        ctx.moveTo(0, 0)
                        ctx.lineTo(width, 0)
                        ctx.lineTo(width, height)
                        ctx.lineTo(0, height)
                        ctx.closePath()
                        ctx.moveTo(points[points.length - 1].x, points[points.length - 1].y)
                        for (var i = points.length - 2; i >= 0; i -= 1)
                            ctx.lineTo(points[i].x, points[i].y)
                        ctx.closePath()
                        ctx.fill()

                        ctx.lineCap = "round"
                        ctx.lineJoin = "round"

                        for (var i = 0; i < points.length; i += 1) {
                            const current = points[i]
                            const next = points[(i + 1) % points.length]
                            const segmentStrength = Math.min(sideStrength(current.side), sideStrength(next.side))
                            const segmentAlpha = Math.min(0.62, (0.16 + peak * 0.46) * (0.30 + segmentStrength * 0.70))
                            ctx.strokeStyle = rgbaCss(accent, segmentAlpha)
                            ctx.lineWidth = current.side === "left" || next.side === "left" ? 1.15 : 0.65
                            ctx.beginPath()
                            ctx.moveTo(current.x, current.y)
                            ctx.quadraticCurveTo(current.x, current.y, next.x, next.y)
                            ctx.stroke()
                        }

                        ctx.restore()
                    }

                    function paintPixelFrame(ctx, peak) {
                        const cell = Math.max(3, Math.min(12, Math.round(veloraTheme.visualizerPixelSize)))
                        const gap = Math.max(1, Math.round(cell * 0.30))
                        const slots = Math.max(24, Math.floor((perimeter + gap) / (cell + gap)))
                        const steps = Math.max(1, Math.floor((screenVisualizerFrame.band + gap) / (cell + gap)))
                        const accent = accentColor()

                        ctx.save()
                        for (var slot = 0; slot < slots; slot += 1) {
                            const unit = slot / Math.max(1, slots)
                            const value = sampleValue(unit)
                            const side = sideForDistance(unit * perimeter)
                            const sideScale = sideStrength(side)
                            const activeSteps = peak >= 0.025
                                ? Math.min(steps, Math.max(1, Math.ceil(Math.pow(value, 0.72) * steps * Math.max(0.16, veloraTheme.visualizerStrength) * sideScale)))
                                : 0
                            const distance = unit * perimeter

                            for (var step = 0; step < activeSteps; step += 1) {
                                const alphaValue = Math.min(0.56, 0.16 + value * 0.42) * (0.35 + sideScale * 0.65) * (1 - step / Math.max(1, steps) * 0.30)
                                const point = pixelPointAtDistance(distance, step * (cell + gap), cell)

                                ctx.fillStyle = rgbaCss(accent, alphaValue)
                                ctx.fillRect(Math.round(point.x), Math.round(point.y), cell, cell)
                            }
                        }
                        ctx.restore()
                    }

                    onPaint: {
                        const ctx = getContext("2d")
                        const points = []
                        var peak = 0

                        ctx.clearRect(0, 0, width, height)
                        if (!screenVisualizerFrame.activeForPaint || width <= 0 || height <= 0)
                            return

                        for (var i = 0; i < sampleCount; i += 1) {
                            const unit = i / Math.max(1, sampleCount)
                            peak = Math.max(peak, sampleValue(unit))
                            points.push(pointAtUnit(unit, i))
                        }

                        if (pixelMode) {
                            paintPixelFrame(ctx, peak)
                            return
                        }

                        paintWaveFrame(ctx, points, peak)
                    }

                    Component.onCompleted: screenVisualizerFrame.requestFramePaint(true)
                    onWidthChanged: screenVisualizerFrame.requestFramePaint(true)
                    onHeightChanged: screenVisualizerFrame.requestFramePaint(true)
                    onVisibleChanged: if (visible) screenVisualizerFrame.requestFramePaint(true)
                }

                Timer {
                    id: screenVisualizerPaintTimer

                    interval: 16
                    repeat: false
                    onTriggered: {
                        if (screenVisualizerFrame.activeForPaint)
                            screenVisualizerCanvas.requestPaint()
                    }
                }

                Connections {
                    target: barRoot
                    function onCavaValuesChanged() {
                        if (root.screenVisualizerReveal > 0.001)
                            screenVisualizerFrame.requestFramePaint(false)
                    }
                }

                Connections {
                    target: veloraTheme
                    function onActiveTextChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onThemeModeChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onThemeIdChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onVisualizerStrengthChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onVisualizerModeChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onVisualizerPixelSizeChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onVisualizerGradientEnabledChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onScreenVisualizerEnabledChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onSurfaceSidebarChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onSidebarBorderGlowChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onBorderSoftChanged() { screenVisualizerFrame.requestFramePaint(true) }
                }

                Connections {
                    target: root
                    function onBarOnRightChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onDesktopFrameMarginChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onScreenVisualizerRevealChanged() { screenVisualizerFrame.requestFramePaint(true) }
                    function onTopWallpaperFrameRevealChanged() { screenVisualizerFrame.requestFramePaint(true) }
                }
            }

            Item {
                id: sideVisualizerRail

                readonly property int frameEdgeX: Math.round(root.barOnRight
                    ? root.mainAreaX(parent.width) + root.mainAreaWidth(parent.width)
                    : root.mainAreaX(parent.width))
                readonly property int barEdgeX: Math.round(root.barOnRight
                    ? root.barX(parent.width)
                    : root.barX(parent.width) + root.sidebarVisualWidth)
                readonly property bool standalone: root.sideVisualizerMounted && !root.frameVisualsMounted
                readonly property int gutterSpan: Math.max(0, root.barOnRight
                    ? barEdgeX - frameEdgeX
                    : frameEdgeX - barEdgeX)
                readonly property int railOverlap: standalone ? root.sidebarCornerRadius : 0
                readonly property int bandCount: barRoot.cavaBandCount || 40
                readonly property int waveWidth: standalone ? Math.max(30, Math.round(root.sideVisualizerWaveWidth * 0.58)) : root.sideVisualizerWaveWidth
                readonly property int railWidth: waveWidth + gutterSpan + railOverlap
                readonly property real waveStrength: veloraTheme.visualizerStrength
                readonly property bool pixelMode: veloraTheme.visualizerMode === "pixels"
                readonly property real centerX: root.barOnRight ? waveWidth - 2 : gutterSpan + railOverlap + 2
                readonly property int waveDirection: root.barOnRight ? -1 : 1
                readonly property real localFrameEdgeX: frameEdgeX - x
                readonly property real localBarEdgeX: barEdgeX - x
                readonly property real bridgeLeftX: Math.max(0, Math.min(localFrameEdgeX, localBarEdgeX) - 1)
                readonly property real bridgeRightX: Math.min(width, Math.max(localFrameEdgeX, localBarEdgeX) + 2)
                readonly property real popupCutLeft: Math.max(0, Math.min(width, inlineQuickPopupSurface.x - x))
                readonly property real popupCutRight: Math.max(0, Math.min(width, inlineQuickPopupSurface.x + inlineQuickPopupSurface.width - x))
                readonly property real popupCutTop: Math.max(0, Math.min(height, inlineQuickPopupSurface.y - y))
                readonly property real popupCutBottom: Math.max(0, Math.min(height, inlineQuickPopupSurface.y + inlineQuickPopupSurface.height - y))
                readonly property bool popupCutActive: root.sideQuickPopupPanelVisible && root.quickPopupSurfaceReveal > 0.001 && popupCutBottom > popupCutTop && popupCutRight > popupCutLeft
                readonly property bool activeForPaint: root.sideBarLayoutEnabled && root.sideVisualizerMounted && visible && panel.visible && width > 0 && height > 0

                function requestWaveformPaint(force) {
                    if (!activeForPaint) {
                        waveformPaintTimer.stop()
                        if (force)
                            waveformCanvas.requestPaint()
                        return
                    }

                    if (force) {
                        waveformPaintTimer.stop()
                        waveformCanvas.requestPaint()
                        return
                    }

                    if (!waveformPaintTimer.running)
                        waveformPaintTimer.restart()
                }

                x: standalone
                    ? (root.barOnRight ? barEdgeX - waveWidth : barEdgeX - railOverlap)
                    : (root.barOnRight ? frameEdgeX - waveWidth + 1 : barEdgeX - 1)
                y: standalone ? root.sidebarVerticalMargin : root.desktopFrameY(parent.height) - 1
                width: root.sideBarLayoutEnabled && root.sideVisualizerMounted ? railWidth : 0
                height: root.sideBarLayoutEnabled && root.sideVisualizerMounted
                    ? (standalone ? Math.max(0, parent.height - root.sidebarVerticalMargin * 2) : Math.max(0, root.desktopFrameHeight(parent.height) + 2))
                    : 0
                visible: root.sideBarLayoutEnabled && root.sideVisualizerMounted
                opacity: root.sideVisualizerReveal
                clip: true
                z: standalone ? 11 : 1

                onActiveForPaintChanged: {
                    if (activeForPaint)
                        requestWaveformPaint(true)
                    else {
                        waveformPaintTimer.stop()
                        waveformCanvas.requestPaint()
                    }
                }

                Canvas {
                    id: waveformCanvas

                    anchors.fill: parent
                    antialiasing: true

                    function rawVisualizerValue(index) {
                        if (!barRoot.cavaValues || barRoot.cavaValues.length <= 0)
                            return 0

                        const value = Number(barRoot.cavaValues[Math.max(0, Math.min(index, barRoot.cavaValues.length - 1))])
                        return Math.max(0, Math.min(1, isNaN(value) ? 0 : value))
                    }

                    function pointAt(index) {
                        const count = Math.max(2, sideVisualizerRail.bandCount)
                        const top = 1
                        const bottom = Math.max(top + 1, height - 1)
                        const step = (bottom - top) / (count - 1)
                        const lifted = rawVisualizerValue(index)
                        const standaloneScale = sideVisualizerRail.standalone ? 0.52 : 1
                        const maxAmp = Math.max(sideVisualizerRail.standalone ? 10 : 16, sideVisualizerRail.waveWidth * sideVisualizerRail.waveStrength * standaloneScale)
                        const edgeFade = Math.min(1, index / 5, (count - 1 - index) / 5)
                        const amp = Math.min(maxAmp, Math.pow(lifted, 0.82) * maxAmp) * edgeFade
                        const pulse = 0.78 + Math.abs(Math.sin(index * 0.70)) * 0.22

                        return {
                            x: sideVisualizerRail.centerX + sideVisualizerRail.waveDirection * amp * pulse,
                            y: top + step * index
                        }
                    }

                    function moldedEdgeX() {
                        if (sideVisualizerRail.standalone)
                            return sideVisualizerRail.localBarEdgeX
                        return root.barOnRight ? width : 0
                    }

                    function continueSmoothLine(ctx, points) {
                        continueSmoothLineRange(ctx, points, 0, points.length - 1)
                    }

                    function continueSmoothLineRange(ctx, points, startIndex, endIndex) {
                        const start = Math.max(0, Math.min(points.length - 1, startIndex))
                        const end = Math.max(start, Math.min(points.length - 1, endIndex))

                        for (let i = start + 1; i <= end; i += 1) {
                            const previous = points[i - 1]
                            const current = points[i]
                            const midX = (previous.x + current.x) / 2
                            const midY = (previous.y + current.y) / 2
                            ctx.quadraticCurveTo(previous.x, previous.y, midX, midY)
                        }

                        const last = points[end]
                        ctx.lineTo(last.x, last.y)
                    }

                    function smoothLine(ctx, points) {
                        if (points.length <= 0)
                            return

                        ctx.moveTo(points[0].x, points[0].y)
                        continueSmoothLine(ctx, points)
                    }

                    function moldedFramePath(ctx, points) {
                        if (points.length <= 0)
                            return

                        const geometry = moldedCapGeometry(points)
                        ctx.moveTo(geometry.capX, 0)
                        ctx.bezierCurveTo(geometry.controlX, 0, geometry.topJoin.x, geometry.topCurveY, geometry.topJoin.x, geometry.topJoin.y)
                        continueSmoothLineRange(ctx, points, geometry.topIndex, geometry.bottomIndex)
                        ctx.bezierCurveTo(geometry.bottomJoin.x, geometry.bottomCurveY, geometry.controlX, height, geometry.capX, height)
                    }

                    function moldedGlassPath(ctx, points) {
                        if (points.length <= 0)
                            return

                        const edgeX = moldedEdgeX()
                        const geometry = moldedCapGeometry(points)

                        ctx.moveTo(geometry.capX, 0)
                        ctx.bezierCurveTo(geometry.controlX, 0, geometry.topJoin.x, geometry.topCurveY, geometry.topJoin.x, geometry.topJoin.y)
                        continueSmoothLineRange(ctx, points, geometry.topIndex, geometry.bottomIndex)
                        ctx.bezierCurveTo(geometry.bottomJoin.x, geometry.bottomCurveY, geometry.controlX, height, geometry.capX, height)

                        if (sideVisualizerRail.standalone) {
                            const side = root.barOnRight ? -1 : 1
                            const innerRadius = Math.min(root.sidebarCornerRadius, height / 2, Math.max(4, sideVisualizerRail.railOverlap))
                            const shoulderX = edgeX + side * innerRadius
                            ctx.lineTo(shoulderX, height)
                            ctx.quadraticCurveTo(edgeX, height, edgeX, height - innerRadius)
                            ctx.lineTo(edgeX, innerRadius)
                            ctx.quadraticCurveTo(edgeX, 0, shoulderX, 0)
                            ctx.lineTo(geometry.capX, 0)
                        } else {
                            ctx.lineTo(edgeX, height)
                            ctx.lineTo(edgeX, 0)
                        }
                        ctx.closePath()
                    }

                    function moldedCapGeometry(points) {
                        const edgeX = moldedEdgeX()
                        const side = root.barOnRight ? -1 : 1
                        const capReach = sideVisualizerRail.standalone ? Math.min(16, width * 0.40) : Math.min(38, width * 0.46)
                        const capControl = capReach * 0.52
                        const topIndex = Math.min(points.length - 1, Math.max(2, Math.round(points.length * 0.055)))
                        const bottomIndex = Math.max(topIndex, points.length - 1 - topIndex)
                        const topJoin = points[topIndex]
                        const bottomJoin = points[bottomIndex]
                        const capX = Math.max(0, Math.min(width, edgeX + side * capReach))
                        const controlX = Math.max(0, Math.min(width, edgeX + side * capControl))
                        const topCurveY = Math.max(6, topJoin.y * 0.34)
                        const bottomCurveY = Math.min(height - 6, height - (height - bottomJoin.y) * 0.34)

                        return {
                            topIndex: topIndex,
                            bottomIndex: bottomIndex,
                            topJoin: topJoin,
                            bottomJoin: bottomJoin,
                            capX: capX,
                            controlX: controlX,
                            topCurveY: topCurveY,
                            bottomCurveY: bottomCurveY
                        }
                    }

                    function interpolatedVisualizerValue(row, rows) {
                        const count = Math.max(2, sideVisualizerRail.bandCount)
                        const scaled = row / Math.max(1, rows - 1) * (count - 1)
                        const left = Math.max(0, Math.min(count - 1, Math.floor(scaled)))
                        const right = Math.max(left, Math.min(count - 1, Math.ceil(scaled)))
                        const mix = scaled - left
                        return rawVisualizerValue(left) * (1 - mix) + rawVisualizerValue(right) * mix
                    }

                    function drawPixelVisualizer(ctx, peak) {
                        const edgeX = moldedEdgeX()
                        const side = root.barOnRight ? -1 : 1
                        const cell = Math.max(3, Math.min(12, Math.round(veloraTheme.visualizerPixelSize)))
                        const gap = Math.max(1, Math.round(cell * 0.30))
                        const maxColumns = Math.max(2, Math.floor(Math.max(14, sideVisualizerRail.waveWidth - 6) / (cell + gap)))
                        const usedWidth = maxColumns * cell + Math.max(0, maxColumns - 1) * gap
                        const availableHeight = Math.max(cell, height - 2)
                        const rows = Math.max(1, Math.floor((availableHeight + gap) / (cell + gap)))
                        const usedHeight = rows * cell + Math.max(0, rows - 1) * gap
                        const y0 = 1
                        const x0 = side > 0 ? edgeX : edgeX - usedWidth
                        const activeBase = veloraTheme.themeId === "pywal16" ? veloraTheme.sidebarBorderGlow : veloraTheme.activeText

                        for (let row = 0; row < rows; row += 1) {
                            const value = interpolatedVisualizerValue(row, rows)
                            const activeColumns = peak >= 0.025
                                ? Math.min(maxColumns, Math.max(1, Math.ceil(Math.pow(value, 0.72) * maxColumns * Math.max(0.25, sideVisualizerRail.waveStrength))))
                                : 0
                            const y = y0 + row * (cell + gap)

                            for (let col = 0; col < maxColumns; col += 1) {
                                const x = side > 0
                                    ? x0 + col * (cell + gap)
                                    : x0 + usedWidth - cell - col * (cell + gap)
                                if (col >= activeColumns)
                                    continue

                                const columnFade = 1 - col / Math.max(1, maxColumns) * 0.36
                                const alpha = Math.min(0.62, 0.18 + value * 0.50) * columnFade
                                ctx.fillStyle = veloraTheme.alpha(activeBase, alpha)
                                ctx.fillRect(Math.round(x), Math.round(y), cell, cell)
                            }
                        }
                    }

                    function popupCutTopPx() {
                        return Math.max(0, Math.min(height, Math.floor(sideVisualizerRail.popupCutTop) - 1))
                    }

                    function popupCutBottomPx() {
                        return Math.max(0, Math.min(height, Math.ceil(sideVisualizerRail.popupCutBottom) + 1))
                    }

                    function popupCutLeftPx() {
                        return Math.max(0, Math.min(width, Math.floor(sideVisualizerRail.popupCutLeft) - 1))
                    }

                    function popupCutRightPx() {
                        return Math.max(0, Math.min(width, Math.ceil(sideVisualizerRail.popupCutRight) + 1))
                    }

                    function popupCutCoversCanvas() {
                        return sideVisualizerRail.popupCutActive
                            && popupCutLeftPx() <= 0
                            && popupCutRightPx() >= width
                            && popupCutTopPx() <= 0
                            && popupCutBottomPx() >= height
                    }

                    function clearPopupCut(ctx) {
                        if (!sideVisualizerRail.popupCutActive)
                            return

                        const top = popupCutTopPx()
                        const bottom = popupCutBottomPx()
                        const left = 0
                        const right = width
                        if (bottom <= top || right <= left)
                            return

                        if (!veloraTheme.visualizerGradientEnabled) {
                            ctx.clearRect(left, top, right - left, bottom - top)
                            return
                        }

                        const cutWidth = right - left
                        const fade = Math.max(42, Math.min(112, Math.round(height * 0.12)))

                        ctx.save()
                        ctx.globalCompositeOperation = "destination-out"
                        ctx.fillStyle = "rgba(0,0,0,1)"
                        ctx.fillRect(left, top, cutWidth, bottom - top)

                        if (top > 0) {
                            const fadeTop = Math.max(0, top - fade)
                            const topGradient = ctx.createLinearGradient(0, fadeTop, 0, top)
                            topGradient.addColorStop(0.0, "rgba(0,0,0,0)")
                            topGradient.addColorStop(1.0, "rgba(0,0,0,1)")
                            ctx.fillStyle = topGradient
                            ctx.fillRect(left, fadeTop, cutWidth, top - fadeTop)
                        }

                        if (bottom < height) {
                            const fadeBottom = Math.min(height, bottom + fade)
                            const bottomGradient = ctx.createLinearGradient(0, bottom, 0, fadeBottom)
                            bottomGradient.addColorStop(0.0, "rgba(0,0,0,1)")
                            bottomGradient.addColorStop(1.0, "rgba(0,0,0,0)")
                            ctx.fillStyle = bottomGradient
                            ctx.fillRect(left, bottom, cutWidth, fadeBottom - bottom)
                        }

                        ctx.restore()
                    }

                    onPaint: {
                        const ctx = getContext("2d")
                        const count = Math.max(2, sideVisualizerRail.bandCount)
                        const wave = []
                        var peak = 0

                        ctx.clearRect(0, 0, width, height)
                        if (!sideVisualizerRail.activeForPaint)
                            return

                        if (popupCutCoversCanvas())
                            return

                        for (let i = 0; i < count; i += 1) {
                            peak = Math.max(peak, rawVisualizerValue(i))
                            wave.push(pointAt(i))
                        }

                        ctx.save()
                        ctx.lineCap = "round"
                        ctx.lineJoin = "round"

                        if (sideVisualizerRail.pixelMode) {
                            drawPixelVisualizer(ctx, peak)
                            clearPopupCut(ctx)
                            ctx.restore()
                            return
                        }

                        ctx.fillStyle = root.sideRailMaterialColor()
                        ctx.beginPath()
                        moldedGlassPath(ctx, wave)
                        ctx.fill()

                        if (peak >= 0.045) {
                            const waveAlpha = Math.min(0.22, 0.08 + peak * 0.24)
                            ctx.strokeStyle = veloraTheme.alpha(root.sidebarPanelBorderColor(), veloraTheme.themeId === "pywal16" ? waveAlpha : Math.min(0.42, waveAlpha + 0.08))
                            ctx.lineWidth = 0.75
                            ctx.beginPath()
                            smoothLine(ctx, wave)
                            ctx.stroke()
                        }

                        clearPopupCut(ctx)
                        ctx.restore()
                    }

                    Component.onCompleted: sideVisualizerRail.requestWaveformPaint(true)
                    onWidthChanged: sideVisualizerRail.requestWaveformPaint(true)
                    onHeightChanged: sideVisualizerRail.requestWaveformPaint(true)
                }

                Timer {
                    id: waveformPaintTimer

                    interval: 16
                    repeat: false
                    onTriggered: {
                        if (sideVisualizerRail.activeForPaint)
                            waveformCanvas.requestPaint()
                    }
                }

                Connections {
                    target: barRoot
                    function onCavaValuesChanged() {
                        if (root.sideVisualizerMounted)
                            sideVisualizerRail.requestWaveformPaint(false)
                    }
                }

                Connections {
                    target: veloraTheme
                    function onActiveTextChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onThemeModeChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onThemeIdChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onVisualizerStrengthChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onVisualizerModeChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onVisualizerPixelSizeChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onVisualizerGradientEnabledChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onSurfaceBaseChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onSurfaceSidebarChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onSidebarBorderGlowChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                    function onBorderSoftChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
                }
            }

            Rectangle {
                id: sideVisualizerFrameVeil

                readonly property int frameEdgeX: Math.round(root.barOnRight
                    ? root.mainAreaX(parent.width) + root.mainAreaWidth(parent.width)
                    : root.mainAreaX(parent.width))

                x: frameEdgeX - 1
                y: root.frameVisualInset
                width: 2
                height: root.frameVisualsMounted ? Math.max(0, parent.height - root.frameVisualInset * 2) : 0
                visible: false && root.frameVisualsMounted
                color: root.desktopFrameBorderColor()
                opacity: root.frameVisualsReveal * (veloraTheme.themeMode === "dark" ? 0.72 : 0.86)
                antialiasing: false
                z: 3
            }

            Rectangle {
                id: rightSoftBackRail

                readonly property int railX: Math.round(root.barX(parent.width) + root.sidebarVisualWidth)

                x: railX
                y: root.frameVisualInset
                width: Math.max(0, parent.width - railX)
                height: root.frameVisualsMounted ? Math.max(0, parent.height - root.frameVisualInset * 2) : 0
                visible: false && root.frameVisualsMounted
                color: "transparent"
                border.width: 1
                border.color: veloraTheme.alpha(veloraTheme.sidebarBorderGlow, 0.20)
                antialiasing: false
            }

            Item {
                id: topWallpaperStrip

                readonly property real reveal: root.topWallpaperFrameReveal
                readonly property int frameBottomY: root.desktopFrameBottom(parent.height)
                readonly property int topGap: Math.max(24, root.desktopFrameMargin + 12)
                readonly property int bottomGap: Math.max(10, root.desktopFrameMargin - 4)
                readonly property int sideGap: Math.max(8, Math.round(parent.width * 0.006))
                readonly property int stripLeftEdge: root.mainAreaX(parent.width)
                readonly property int stripRightEdge: root.mainAreaX(parent.width) + root.mainAreaWidth(parent.width)
                readonly property bool cardsReady: root.topWallpaperCardsMounted && reveal > 0.14
                readonly property int visibleCards: 9
                readonly property int layoutCards: 6
                readonly property int centerSlot: Math.floor(visibleCards / 2)
                readonly property int arrowGutter: Math.max(18, Math.round(width * 0.012))
                readonly property real contentWidth: Math.max(1, width - arrowGutter * 2)
                readonly property real cardGap: -Math.max(14, Math.round(contentWidth * 0.012))

                function entryForSlot(slot) {
                    return root.topWallpaperEntry(slot - centerSlot)
                }

                function cardWidthForDistance(distance) {
                    const available = Math.max(1, contentWidth - cardGap * (layoutCards - 1))
                    const baseWidth = Math.min(326, Math.max(268, contentWidth * 0.174))
                    const scale = Math.min(1, available / (baseWidth * layoutCards))
                    return baseWidth * scale
                }

                function cardCenterForIntegerOffset(offset) {
                    const sign = offset < 0 ? -1 : 1
                    const distance = Math.abs(offset)
                    let x = arrowGutter + contentWidth / 2
                    let previousWidth = cardWidthForDistance(0)

                    for (let i = 1; i <= distance; ++i) {
                        const nextWidth = cardWidthForDistance(i)
                        x += sign * (previousWidth / 2 + cardGap + nextWidth / 2)
                        previousWidth = nextWidth
                    }

                    return x
                }

                function cardCenterForOffset(offset) {
                    if (Math.abs(offset) < 0.001)
                        return cardCenterForIntegerOffset(0)

                    const sign = offset < 0 ? -1 : 1
                    const absolute = Math.abs(offset)
                    const lower = Math.floor(absolute)
                    const upper = Math.ceil(absolute)
                    const t = absolute - lower

                    if (lower === upper)
                        return cardCenterForIntegerOffset(sign * lower)

                    const from = cardCenterForIntegerOffset(sign * lower)
                    const to = cardCenterForIntegerOffset(sign * upper)
                    return from + (to - from) * t
                }

                x: stripLeftEdge + sideGap
                y: frameBottomY + topGap + Math.round((1 - reveal) * 12)
                width: Math.max(0, stripRightEdge - stripLeftEdge - sideGap * 2)
                height: Math.max(0, parent.height - root.desktopFrameMargin - frameBottomY - topGap - bottomGap)
                visible: root.topWallpaperMounted && reveal > 0.01 && width > 420 && height > 78
                opacity: root.topWallpaperSurfaceReveal * Math.min(1, reveal * 1.25)
                z: 60
                clip: true
                focus: root.topWallpaperKeyboardFocus

                Keys.onEscapePressed: root.toggleTopWallpaperPopup(false, false)

                Keys.onPressed: function(event) {
                    if (!root.topWallpaperPopupOpen)
                        return

                    if (event.key === Qt.Key_Left || event.key === Qt.Key_A) {
                        root.moveTopWallpaper(-1)
                        event.accepted = true
                        return
                    }

                    if (event.key === Qt.Key_Right || event.key === Qt.Key_D) {
                        root.moveTopWallpaper(1)
                        event.accepted = true
                        return
                    }

                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.applyTopWallpaperSelection()
                        event.accepted = true
                    }
                }

                onVisibleChanged: {
                    if (visible && root.topWallpaperKeyboardFocus)
                        forceActiveFocus()
                }

                Connections {
                    target: root

                    function onTopWallpaperKeyboardFocusChanged() {
                        if (root.topWallpaperKeyboardFocus && topWallpaperStrip.visible)
                            topWallpaperStrip.forceActiveFocus()
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: 0
                    enabled: root.topWallpaperPopupOpen
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onPressed: function(mouse) {
                        mouse.accepted = true
                        if (root.topWallpaperKeyboardFocus)
                            topWallpaperStrip.forceActiveFocus()
                    }
                }

                Repeater {
                    model: topWallpaperStrip.visible && topWallpaperStrip.cardsReady ? 15 : 0

                    delegate: Image {
                        readonly property int preloadOffset: index - 7
                        readonly property var preloadEntry: root.topWallpaperEntry(preloadOffset)

                        width: 1
                        height: 1
                        visible: false
                        source: preloadEntry && preloadEntry.preview ? preloadEntry.preview : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        retainWhileLoading: true
                        smooth: false
                        mipmap: false
                        sourceSize.width: 600
                        sourceSize.height: 360
                    }
                }

                Repeater {
                    model: topWallpaperStrip.visible && topWallpaperStrip.cardsReady ? topWallpaperStrip.visibleCards : 0

                    delegate: Item {
                        id: wallpaperCard

                        readonly property int slotOffset: index - topWallpaperStrip.centerSlot
                        readonly property real slideOffset: root.topWallpaperSlideDirection === 0 ? 0 : root.topWallpaperSlideDirection * root.topWallpaperSlideEase()
                        readonly property real visualOffset: slotOffset - slideOffset
                        readonly property real layoutDistance: Math.abs(slotOffset)
                        readonly property real distance: Math.abs(visualOffset)
                        readonly property real focusAmount: Math.max(0, 1 - Math.min(1, distance / 3.0))
                        readonly property real cardWidth: topWallpaperStrip.cardWidthForDistance(layoutDistance)
                        readonly property real cardHeight: Math.min(topWallpaperStrip.height - 18, Math.max(104, topWallpaperStrip.height * 0.74))
                        readonly property real cardLean: Math.min(64, Math.max(34, cardWidth * 0.21))
                        readonly property var entry: topWallpaperStrip.entryForSlot(index)

                        function cardPath(ctx, w, h, inset) {
                            const pad = Math.max(0, inset || 0)
                            const left = pad
                            const right = Math.max(left + 1, w - pad)
                            const top = pad
                            const bottom = Math.max(top + 1, h - pad)
                            const lean = Math.min(cardLean, Math.max(8, (right - left) * 0.34))

                            ctx.beginPath()
                            ctx.moveTo(Math.min(right - 1, left + lean), top)
                            ctx.lineTo(right, top)
                            ctx.lineTo(Math.max(left + 1, right - lean), bottom)
                            ctx.lineTo(left, bottom)
                            ctx.closePath()
                        }

                        x: Math.round(topWallpaperStrip.cardCenterForOffset(visualOffset) - width / 2)
                        y: Math.round((topWallpaperStrip.height - height) / 2 + 4)
                        width: Math.round(cardWidth)
                        height: Math.round(cardHeight)
                        z: Math.round(40 + focusAmount * 30 - distance)
                        opacity: Math.min(1, Math.max(0.60, 0.78 + focusAmount * 0.22 - Math.max(0, distance - 3.15) * 0.24))
                        visible: height > 40 && width > 80
                        scale: 1.00 + focusAmount * 0.16
                        rotation: 0
                        transformOrigin: Item.Center

                        Rectangle {
                            id: cardShadow

                            anchors.fill: parent
                            visible: false
                            color: "transparent"
                        }

                        Item {
                            id: cardImageClip

                            anchors.fill: parent
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: cardMask
                            }

                            Image {
                                anchors.fill: parent
                                source: wallpaperCard.entry && wallpaperCard.entry.preview ? wallpaperCard.entry.preview : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                retainWhileLoading: true
                                smooth: false
                                mipmap: false
                                opacity: 0.98
                                sourceSize.width: 600
                                sourceSize.height: 360
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: veloraTheme.themeMode === "dark"
                                    ? Qt.rgba(0, 0, 0, wallpaperCard.distance < 0.5 ? 0.04 : 0.10)
                                    : Qt.rgba(1, 1, 1, wallpaperCard.distance < 0.5 ? 0.02 : 0.10)
                            }
                        }

                        Canvas {
                            id: cardMask

                            anchors.fill: parent
                            visible: false

                            onPaint: {
                                const ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                wallpaperCard.cardPath(ctx, width, height, 2)
                                ctx.fillStyle = "white"
                                ctx.fill()
                            }

                            Component.onCompleted: requestPaint()
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                        }

                        Canvas {
                            id: cardBorder

                            anchors.fill: parent
                            antialiasing: true

                            onPaint: {
                                const ctx = getContext("2d")
                                const selected = wallpaperCard.layoutDistance < 0.5

                                ctx.clearRect(0, 0, width, height)
                                ctx.save()
                                wallpaperCard.cardPath(ctx, width, height, selected ? 2.5 : 3.5)
                                ctx.strokeStyle = selected
                                    ? veloraTheme.alpha(veloraTheme.accentPrimary, veloraTheme.themeMode === "dark" ? 0.56 : 0.44)
                                    : veloraTheme.alpha(veloraTheme.borderSoft, veloraTheme.themeMode === "dark" ? 0.26 : 0.34)
                                ctx.lineWidth = selected ? 1.55 : 1.05
                                ctx.stroke()

                                wallpaperCard.cardPath(ctx, width, height, selected ? 6.5 : 7.5)
                                ctx.strokeStyle = Qt.rgba(1, 1, 1, selected ? 0.52 : 0.34)
                                ctx.lineWidth = 0.8
                                ctx.stroke()
                                ctx.restore()
                            }

                            Component.onCompleted: requestPaint()
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                        }
                    }
                }

                Item {
                    id: topWallpaperLeftArrow

                    width: 48
                    height: Math.min(82, Math.max(62, topWallpaperStrip.height * 0.46))
                    x: Math.max(0, Math.round(topWallpaperStrip.arrowGutter / 2 - width / 2))
                    y: Math.round((topWallpaperStrip.height - height) / 2)
                    z: 90
                    visible: false
                    opacity: topWallpaperArrowLeftMouse.containsMouse ? 0.95 : 0.68

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.min(width, height) / 2
                        color: veloraTheme.alpha(veloraTheme.surfaceSidebar, veloraTheme.themeMode === "dark" ? 0.42 : 0.54)
                        border.width: 1
                        border.color: veloraTheme.alpha(veloraTheme.borderSoft, 0.38)
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "‹"
                        color: veloraTheme.textPrimary
                        font.pixelSize: Math.round(parent.height * 0.54)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        id: topWallpaperArrowLeftMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.moveTopWallpaper(-1)
                    }
                }

                Item {
                    id: topWallpaperRightArrow

                    width: 48
                    height: topWallpaperLeftArrow.height
                    x: Math.min(topWallpaperStrip.width - width, Math.round(topWallpaperStrip.width - topWallpaperStrip.arrowGutter / 2 - width / 2))
                    y: topWallpaperLeftArrow.y
                    z: 90
                    visible: false
                    opacity: topWallpaperArrowRightMouse.containsMouse ? 0.95 : 0.68

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.min(width, height) / 2
                        color: veloraTheme.alpha(veloraTheme.surfaceSidebar, veloraTheme.themeMode === "dark" ? 0.42 : 0.54)
                        border.width: 1
                        border.color: veloraTheme.alpha(veloraTheme.borderSoft, 0.38)
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "›"
                        color: veloraTheme.textPrimary
                        font.pixelSize: Math.round(parent.height * 0.54)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        id: topWallpaperArrowRightMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.moveTopWallpaper(1)
                    }
                }
            }

            Item {
                id: inlineNotificationToastInputMask

                x: inlineNotificationToastStage.x
                y: inlineNotificationToastStage.y
                width: root.notificationToastMounted ? inlineNotificationToastStage.width : 0
                height: root.notificationToastMounted ? inlineNotificationToastStage.height : 0
                z: 139
            }

            Item {
                id: inlineNotificationToastStage

                readonly property bool mounted: root.notificationToastMounted || opacity > 0.001
                readonly property int panelWidth: Math.max(parent.width, panel.modelData.width)
                readonly property int safeWidth: Math.max(320, panelWidth - 96)
                readonly property int bubbleRadius: Math.min(17, height / 2)
                readonly property int openY: root.geminiTopWindowOpen
                    ? Math.max(root.desktopFrameMargin, Math.round(inlineGeminiTopFrame.y + inlineGeminiTopFrame.height + 14))
                    : root.desktopFrameMargin

                width: Math.round(Math.min(safeWidth, Math.max(330, panelWidth * 0.18)))
                height: 48
                x: Math.round((panelWidth - width) / 2)
                y: root.notificationToastVisible ? openY : -height - 18
                z: 140
                visible: mounted
                opacity: root.notificationToastVisible ? 1 : 0
                scale: 1
                transformOrigin: Item.Top

                onYChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onOpacityChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onWidthChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onHeightChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()

                Behavior on y {
                    enabled: veloraTheme.motionEnabled
                    NumberAnimation {
                        duration: root.notificationToastVisible ? root.notificationToastOpenDuration : root.notificationToastCloseDuration
                        easing.type: root.notificationToastVisible ? Easing.BezierSpline : Easing.InOutCubic
                        easing.bezierCurve: root.notificationToastVisible ? veloraTheme.motionCurveEmphasizedAccel : veloraTheme.motionCurveStandard
                    }
                }

                Behavior on opacity {
                    enabled: veloraTheme.motionEnabled
                    NumberAnimation {
                        duration: root.notificationToastVisible ? Math.max(180, Math.round(root.notificationToastOpenDuration * 0.48)) : Math.max(320, Math.round(root.notificationToastCloseDuration * 0.52))
                        easing.type: root.notificationToastVisible ? Easing.BezierSpline : Easing.InOutCubic
                        easing.bezierCurve: root.notificationToastVisible ? veloraTheme.motionCurveEmphasizedAccel : veloraTheme.motionCurveStandard
                    }
                }

                Rectangle {
                    id: inlineNotificationToastBubble

                    anchors.fill: parent
                    radius: inlineNotificationToastStage.bubbleRadius
                    color: "transparent"
                    border.width: 0
                    antialiasing: true
                }

                Item {
                    id: inlineNotificationToastIcon

                    width: 32
                    height: 32
                    x: 10
                    y: Math.round((parent.height - height) / 2)

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: root.notificationIconSurfaceColor(root.notificationToastIconKey)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.22)
                        antialiasing: true
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                        }
                        height: parent.height * 0.42
                        radius: 10
                        visible: false
                        color: Qt.rgba(1, 1, 1, 0.14)
                    }

                    Canvas {
                        id: inlineNotificationToastIconCanvas

                        anchors.fill: parent
                        antialiasing: true

                        function drawBell(ctx) {
                            ctx.beginPath()
                            ctx.moveTo(27, 15)
                            ctx.bezierCurveTo(19, 16, 17, 24, 17, 31)
                            ctx.lineTo(14, 37)
                            ctx.quadraticCurveTo(27, 42, 40, 37)
                            ctx.lineTo(37, 31)
                            ctx.bezierCurveTo(37, 24, 35, 16, 27, 15)
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.arc(27, 41, 3.1, 0, Math.PI, false)
                            ctx.stroke()
                        }

                        function drawWhatsapp(ctx) {
                            ctx.beginPath()
                            ctx.arc(27, 26, 15, 0.22 * Math.PI, 1.86 * Math.PI, false)
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.moveTo(17, 37)
                            ctx.lineTo(14, 45)
                            ctx.lineTo(23, 41)
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.moveTo(22, 20)
                            ctx.bezierCurveTo(20, 22, 22, 28, 27, 33)
                            ctx.bezierCurveTo(31, 37, 36, 38, 38, 35)
                            ctx.moveTo(23, 20)
                            ctx.lineTo(26, 25)
                            ctx.moveTo(31, 32)
                            ctx.lineTo(37, 35)
                            ctx.stroke()
                        }

                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.save()
                            ctx.scale(width / 54, height / 54)
                            ctx.lineWidth = 3
                            ctx.lineCap = "round"
                            ctx.lineJoin = "round"
                            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.88)
                            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.88)
                            if (root.notificationToastIconKey === "whatsapp")
                                drawWhatsapp(ctx)
                            else
                                drawBell(ctx)
                            ctx.restore()
                        }

                        Component.onCompleted: requestPaint()

                        Connections {
                            target: root
                            function onNotificationToastIconKeyChanged() { inlineNotificationToastIconCanvas.requestPaint() }
                            function onNotificationToastSerialChanged() { inlineNotificationToastIconCanvas.requestPaint() }
                        }
                    }
                }

                Text {
                    x: inlineNotificationToastIcon.x + inlineNotificationToastIcon.width + 13
                    y: Math.round((parent.height - height) / 2) - 1
                    width: parent.width - x - 16
                    text: root.notificationToastTitle
                    color: veloraTheme.textPrimary
                    font.family: veloraTheme.uiFont
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: root.hideNotificationToast()
                }
            }

            VeloraBarV2 {
                id: barRoot

                theme: veloraTheme
                z: 10
                visible: root.sideBarLayoutEnabled
                width: root.sideBarLayoutEnabled ? root.sidebarVisualWidth : 0
                x: root.barX(parent.width)
                focusMode: root.focusMode
                focusIndex: root.focusIndex
                focusTarget: root.focusTarget
                visualizerActive: root.audioVisualizerMounted
                shellDrawsPanelSurface: root.sideBarLayoutEnabled && root.frameVisualsMounted
                activePopupType: root.wallpaperSelectorOpen ? "theme" : root.quickPopupType
                notificationCountOverride: root.notificationHistoryCount
                onMoveFocusRequested: function(dir) {
                    root.moveFocus(dir)
                }
                onExitFocusRequested: root.exitFocus()
                onThemeRequested: function(centerY) {
                    const fromFocusedBrush = root.focusMode && root.focusTarget === "theme"
                    const localCenter = Number(centerY)
                    const popupCenter = localCenter > 0 ? barRoot.y + localCenter : root.defaultQuickPopupCenterY("theme")
                    root.toggleWallpaperSelector(popupCenter, fromFocusedBrush)
                }
                onSettingsRequested: function(centerY) {
                    const localCenter = Number(centerY)
                    root.toggleSettingsPanel(localCenter > 0 ? barRoot.y + localCenter : root.defaultQuickPopupCenterY("settings"))
                }
                onLayoutRequested: function(centerY) {
                    root.cycleBarLayout()
                }
                onQuickPopupRequested: function(type, centerY) {
                    root.openAdaptiveBarPopup(type, barRoot.y + centerY)
                }
                onQuickPopupHovered: function(type, centerY) {
                    root.previewAdaptiveBarPopup(type, barRoot.y + centerY)
                }
                onQuickPopupHoverEnded: function(type) {
                    root.endAdaptiveBarPopupHover(type)
                }
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    topMargin: root.sidebarVerticalMargin
                    bottomMargin: root.sidebarVerticalMargin
                }
            }

            Item {
                id: inlineModalOverlayInputMask

                x: 0
                y: 0
                width: root.settingsPanelOpen || root.wallpaperSelectorOpen ? panel.width : 0
                height: root.settingsPanelOpen || root.wallpaperSelectorOpen ? panel.height : 0
            }

            Item {
                id: inlineQuickPopupInputMask

                x: inlineQuickPopupSurface.x
                y: inlineQuickPopupSurface.y
                width: root.sideQuickPopupPanelVisible ? inlineQuickPopupSurface.width : 0
                height: root.sideQuickPopupPanelVisible ? inlineQuickPopupSurface.height : 0
            }

            Item {
                id: inlineQuickPopupOutsideInputMask

                x: 0
                y: 0
                width: root.quickPopupHoldOpen && root.visibleQuickPopupType === "search" ? panel.width : 0
                height: root.quickPopupHoldOpen && root.visibleQuickPopupType === "search" ? panel.height : 0
                z: 1

                MouseArea {
                    anchors.fill: parent
                    enabled: root.quickPopupHoldOpen && root.visibleQuickPopupType === "search"
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: root.closeQuickPopup()
                }
            }

            Rectangle {
                id: inlineQuickPopupJoinStrip

                z: 19
                x: root.barOnRight
                    ? Math.round(root.barX(parent.width) - root.sideQuickPopupBridgeWidth - 1)
                    : Math.round(root.barX(parent.width) + root.sidebarVisualWidth)
                y: inlineQuickPopupSurface.y
                width: root.sideQuickPopupBridgeWidth + 2
	                height: inlineQuickPopupLoader.height
	                visible: false
	                opacity: inlineQuickPopupLoader.revealProgress
	                color: root.sidebarBarMaterialColor()
	            }

                VeloraAttachedSurface {
                    id: inlineQuickPopupSurface

                    z: 20
                    theme: veloraTheme
                    attachSide: root.popupAttachSide
                    useCustomGlass: root.frameVisualsMounted
                    customGlass: root.sidebarBarMaterialColor()
                    flattenAttachedEdge: root.quickPopupJoinedToBar
                    lineReveal: true
                    transitionContrast: root.quickPopupTransitionContrast
                    slideOffsetOverride: root.visibleQuickPopupType === "search" || root.visibleQuickPopupType === "agenda" || root.visibleQuickPopupType === "weatherPanel" ? 76 : -1
                    x: inlineQuickPopupLoader.x - (root.barOnRight ? 0 : root.sideQuickPopupBridgeWidth)
                    y: inlineQuickPopupLoader.y
                width: inlineQuickPopupLoader.width + root.sideQuickPopupBridgeWidth
	                height: inlineQuickPopupLoader.height
	                radius: inlineQuickPopupLoader.cornerRadius
	                revealProgress: root.quickPopupSurfaceReveal
	                visible: root.sideQuickPopupPanelVisible && root.quickPopupSurfaceReveal > 0.015 && inlineQuickPopupLoader.contentReady
	            }

            Item {
                id: inlineQuickPopupLoader

	                property int cacheGeneration: 0
	                readonly property bool active: root.sideQuickPopupPanelVisible || (root.sideBarLayoutEnabled && root.quickPopupPreloadEnabled)
	                readonly property int targetWidth: root.quickPopupWidthForScreen(root.visibleQuickPopupType, parent.width)
	                readonly property int targetHeight: root.quickPopupHeightForScreen(root.visibleQuickPopupType, parent.height)
	                readonly property int targetX: root.quickPopupX(root.visibleQuickPopupType, parent.width, targetWidth)
	                readonly property int targetY: root.quickPopupY(root.visibleQuickPopupType, targetHeight, parent.height)
	                readonly property int geometryDuration: Math.max(260, Math.round(veloraTheme.motionPanelGeometry * 0.72))
	                readonly property int fadeInDuration: Math.max(150, Math.round(veloraTheme.motionPanelIn * 0.42))
	                readonly property int switchFadeOutDuration: Math.max(170, Math.round(veloraTheme.motionPanelOut * 0.52))
	                readonly property int closeFadeOutDuration: Math.max(380, Math.round(root.quickPopupLineCloseDuration * 0.74))
	                readonly property int cornerRadius: {
	                    cacheGeneration
	                    const popup = itemForType(root.visibleQuickPopupType)
                    return popup ? popup.cornerRadius : 13
                }
                readonly property real revealProgress: root.quickPopupSurfaceReveal

	                z: 21
	                width: targetWidth
	                height: targetHeight
	                x: targetX
	                y: targetY
		                visible: root.sideQuickPopupPanelVisible && root.quickPopupSurfaceReveal > 0.015
	                clip: true

                onActiveChanged: if (!active) root.quickPopupHovering = false

                function itemForType(type) {
                    const index = root.cachedQuickPopupIndex(type)
                    if (index < 0 || typeof inlineQuickPopupCache === "undefined")
                        return null

                    const loader = inlineQuickPopupCache.itemAt(index)
                    return loader && loader.item ? loader.item : null
                }

                function opacityTransitionDuration(showing) {
                    if (showing)
                        return fadeInDuration
                    return root.quickPopupVisible ? switchFadeOutDuration : closeFadeOutDuration
                }

                readonly property bool contentReady: {
                    cacheGeneration
                    if (!root.sideQuickPopupPanelVisible || root.visibleQuickPopupType.length <= 0)
                        return false
                    return itemForType(root.visibleQuickPopupType) !== null
                }

                Repeater {
                    id: inlineQuickPopupCache

                    model: root.cachedQuickPopupTypes

                    Loader {
                        id: popupCacheLoader

	                        property string cacheType: String(modelData)
	                        readonly property bool showing: root.quickPopupVisible && root.visibleQuickPopupType === cacheType
	                        readonly property bool closing: !root.quickPopupVisible && root.quickPopupWindowOpen && root.visibleQuickPopupType === cacheType

	                        active: showing
	                            || closing
	                            || opacity > 0.001
	                            || (root.quickPopupPreloadEnabled && root.cachedQuickPopupIndex(cacheType) < root.quickPopupPreloadCount)
	                        asynchronous: false
	                        visible: root.sideQuickPopupPanelVisible && (showing || closing || opacity > 0.001)
	                        opacity: showing ? 1 : 0
	                        x: root.barOnRight ? Math.round(inlineQuickPopupLoader.width - width) : 0
	                        y: Math.round((inlineQuickPopupLoader.height - height) / 2)
	                        width: root.quickPopupWidthForScreen(cacheType, panel.width)
	                        height: root.quickPopupHeightForScreen(cacheType, panel.height)
	                        z: showing ? 2 : 1

	                        Behavior on opacity {
	                            enabled: veloraTheme.motionEnabled && inlineQuickPopupLoader.active
	                            NumberAnimation {
	                                duration: inlineQuickPopupLoader.opacityTransitionDuration(popupCacheLoader.showing)
	                                easing.type: popupCacheLoader.showing ? veloraTheme.motionEaseEnter : veloraTheme.motionEaseExit
	                            }
	                        }

                        onLoaded: {
                            inlineQuickPopupLoader.cacheGeneration += 1
                            if (cacheType === "search" && root.quickPopupType === "search")
                                root.scheduleSearchPopupFocus()
                        }

                        sourceComponent: Component {
                            VeloraSidePopup {
                                theme: veloraTheme
                                externalSurface: true
                                lineReveal: true
                                warmSwitch: root.quickPopupSurfaceReveal > 0.35
	                                revealProgressOverride: root.quickPopupSurfaceReveal
	                                attachSide: root.popupAttachSide
	                                popupType: popupCacheLoader.cacheType
                                notificationsModelOverride: notificationHistoryModel
	                                open: popupCacheLoader.showing
	                                interactiveFocus: root.quickPopupType === popupCacheLoader.cacheType
	                                    && (popupCacheLoader.cacheType === "search" || popupCacheLoader.cacheType === "agenda" || popupCacheLoader.cacheType === "weatherPanel")
                                width: popupCacheLoader.width
                                height: popupCacheLoader.height
                                visible: popupCacheLoader.visible
                                onHoldOpenChanged: root.setQuickPopupHoldOpen(popupCacheLoader.cacheType, holdOpen)
                                onOpenChanged: {
                                    if (!open && popupCacheLoader.cacheType === "search")
                                        root.setQuickPopupHoldOpen(popupCacheLoader.cacheType, false)
                                }
                                onCloseRequested: root.closeQuickPopup()
                                onPopupRequested: function(type) {
                                    root.openAdaptiveBarPopup(type, root.defaultQuickPopupCenterY(type))
                                }
                                onPointerInsideChanged: function(inside) {
                                    root.quickPopupHovering = inside
                                    if (inside)
                                        hoverCloseTimer.stop()
                                    else if (root.hoverPopupType.length > 0)
                                        root.scheduleHoverClose()
                                }
                            }
                        }
                    }
                }

	                Behavior on y {
	                    enabled: veloraTheme.motionEnabled && inlineQuickPopupLoader.active
	                    NumberAnimation {
	                        duration: inlineQuickPopupLoader.geometryDuration
	                        easing.type: veloraTheme.motionEaseEnter
	                    }
	                }

	                Behavior on x {
	                    enabled: veloraTheme.motionEnabled && inlineQuickPopupLoader.active
	                    NumberAnimation {
	                        duration: inlineQuickPopupLoader.geometryDuration
	                        easing.type: veloraTheme.motionEaseEnter
	                    }
	                }

	                Behavior on width {
	                    enabled: veloraTheme.motionEnabled && inlineQuickPopupLoader.active
	                    NumberAnimation {
	                        duration: inlineQuickPopupLoader.geometryDuration
	                        easing.type: veloraTheme.motionEaseEnter
	                    }
	                }

	                Behavior on height {
	                    enabled: veloraTheme.motionEnabled && inlineQuickPopupLoader.active
	                    NumberAnimation {
	                        duration: inlineQuickPopupLoader.geometryDuration
	                        easing.type: veloraTheme.motionEaseEnter
	                    }
	                }
            }

            Item {
                id: inlineModalLayer

                z: 40
                anchors.fill: parent
                visible: root.wallpaperSelectorPanelVisible || root.settingsPanelPanelVisible
                focus: root.wallpaperSelectorOpen || root.settingsPanelOpen

                Keys.onEscapePressed: {
                    root.wallpaperSelectorOpen = false
                    root.settingsPanelOpen = false
                }

                Keys.onPressed: function(event) {
                    if (root.wallpaperSelectorOpen) {
                        const selector = inlineWallpaperLoader.item
                        if (!selector)
                            return

                        if ((event.key === Qt.Key_Left || event.key === Qt.Key_A) && selector.moveSelection) {
                            selector.moveSelection(-1)
                            event.accepted = true
                            return
                        }

                        if ((event.key === Qt.Key_Right || event.key === Qt.Key_D) && selector.moveSelection) {
                            selector.moveSelection(1)
                            event.accepted = true
                            return
                        }

                        if ((event.key === Qt.Key_Down || event.key === Qt.Key_S) && selector.cycleWallpaperMode) {
                            selector.cycleWallpaperMode(1)
                            event.accepted = true
                            return
                        }

                        if ((event.key === Qt.Key_Up || event.key === Qt.Key_W) && selector.cycleWallpaperMode) {
                            selector.cycleWallpaperMode(-1)
                            event.accepted = true
                            return
                        }

                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && selector.applySelected) {
                            selector.applySelected()
                            event.accepted = true
                            return
                        }
                    }

                    if (root.settingsPanelOpen) {
                        const settings = inlineSettingsLoader.item
                        if (!settings)
                            return

                        if (event.key === Qt.Key_Left || event.key === Qt.Key_A) {
                            settings.moveSelection(-1)
                            event.accepted = true
                            return
                        }

                        if (event.key === Qt.Key_Right || event.key === Qt.Key_D) {
                            settings.moveSelection(1)
                            event.accepted = true
                            return
                        }

                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            settings.applySelected()
                            event.accepted = true
                        }
                    }
                }

                MouseArea {
                    z: 0
                    anchors.fill: parent
                    enabled: root.wallpaperSelectorOpen || root.settingsPanelOpen
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        root.wallpaperSelectorOpen = false
                        root.settingsPanelOpen = false
                    }
                }

                Item {
                    id: inlineWallpaperInputMask

                    x: inlineWallpaperLoader.x
                    y: inlineWallpaperLoader.y
                    width: root.wallpaperSelectorPanelVisible ? inlineWallpaperLoader.width : 0
                    height: root.wallpaperSelectorPanelVisible ? inlineWallpaperLoader.height : 0
                }

                VeloraAttachedSurface {
                    z: 2
                    theme: veloraTheme
                    attachSide: root.popupAttachSide
                    x: inlineWallpaperLoader.x
                    y: inlineWallpaperLoader.y
                    width: inlineWallpaperLoader.width
                    height: inlineWallpaperLoader.height
                    radius: inlineWallpaperLoader.cornerRadius
                    revealProgress: inlineWallpaperLoader.revealProgress
                    visible: false
                }

                Loader {
                    id: inlineWallpaperLoader

                    readonly property int cornerRadius: item ? item.cornerRadius : 28
                    readonly property real revealProgress: item ? item.revealProgress : 0
                    readonly property int availableWidth: root.leftMenuWidth
                    readonly property int availableHeight: Math.max(360, parent.height - root.leftMenuFrameInset * 2)

                    active: root.wallpaperSelectorPanelVisible || root.wallpaperPreloadEnabled
                    asynchronous: false
                    z: 3
                    width: availableWidth
                    height: availableHeight
                    x: root.leftMenuOnLeft ? root.leftMenuFrameInset : Math.round(parent.width - root.leftMenuFrameInset - width)
                    y: root.leftMenuFrameInset
                    visible: root.wallpaperSelectorPanelVisible

                    onActiveChanged: if (!active) root.wallpaperSelectorHovering = false
                    onLoaded: root.focusWallpaperSelectorInput()
                    onVisibleChanged: if (visible) root.focusWallpaperSelectorInput()

                    sourceComponent: Component {
                        VeloraWallpaperSelector {
                            theme: veloraTheme
                            externalSurface: true
                            attachSide: root.popupAttachSide
                            width: inlineWallpaperLoader.width
                            height: inlineWallpaperLoader.height
                            open: root.wallpaperSelectorVisible
                            preload: root.wallpaperPreloadEnabled
                            visible: root.wallpaperSelectorPanelVisible
                            focus: root.wallpaperSelectorOpen
                            onCloseRequested: root.wallpaperSelectorOpen = false
                            onVisibilityRequested: root.openWallpaperVisibility(root.defaultQuickPopupCenterY("theme"))

                            HoverHandler {
                                margin: 24
                                onHoveredChanged: {
                                    root.wallpaperSelectorHovering = hovered
                                    if (hovered)
                                        hoverCloseTimer.stop()
                                    else
                                        root.scheduleHoverClose()
                                }
                            }
                        }
                    }

                    Behavior on y {
                        enabled: veloraTheme.motionEnabled && inlineWallpaperLoader.active
                        NumberAnimation {
                            duration: veloraTheme.motionPanelGeometry
                            easing.type: veloraTheme.motionEaseEmphasized
                            easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                        }
                    }

                    Behavior on width {
                        enabled: veloraTheme.motionEnabled && inlineWallpaperLoader.active
                        NumberAnimation {
                            duration: veloraTheme.motionPanelGeometry
                            easing.type: veloraTheme.motionEaseEmphasized
                            easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                        }
                    }

                    Behavior on height {
                        enabled: veloraTheme.motionEnabled && inlineWallpaperLoader.active
                        NumberAnimation {
                            duration: veloraTheme.motionPanelGeometry
                            easing.type: veloraTheme.motionEaseEmphasized
                            easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                        }
                    }
                }

                Item {
                    id: inlineSettingsInputMask

                    x: inlineSettingsLoader.x
                    y: inlineSettingsLoader.y
                    width: root.settingsPanelPanelVisible ? inlineSettingsLoader.width : 0
                    height: root.settingsPanelPanelVisible ? inlineSettingsLoader.height : 0
                }

                VeloraAttachedSurface {
                    z: 4
                    theme: veloraTheme
                    attachSide: root.leftMenuAttachSide
                    x: inlineSettingsLoader.x
                    y: inlineSettingsLoader.y
                    width: inlineSettingsLoader.width
                    height: inlineSettingsLoader.height
                    radius: inlineSettingsLoader.cornerRadius
                    revealProgress: inlineSettingsLoader.revealProgress
                    visible: root.settingsPanelPanelVisible
                }

                Loader {
                    id: inlineSettingsLoader

                    readonly property int cornerRadius: item ? item.cornerRadius : 18
                    readonly property real revealProgress: item ? item.revealProgress : 0

                    active: root.settingsPanelPanelVisible || root.settingsPanelPreloadEnabled
                    asynchronous: true
                    z: 5
                    width: Math.round(Math.min(root.quickPopupWidth("settings"), root.mainAreaWidth(parent.width) - 56))
                    height: Math.round(Math.min(root.quickPopupHeight("settings"), parent.height - root.frameVisualInset * 2 - 72))
                    x: Math.round(root.mainAreaX(parent.width) + (root.mainAreaWidth(parent.width) - width) / 2)
                    y: Math.round(root.frameVisualInset + (parent.height - root.frameVisualInset * 2 - height) / 2)
                    visible: root.settingsPanelPanelVisible

                    onActiveChanged: if (!active) root.settingsPanelHovering = false

                    sourceComponent: Component {
                        VeloraSettingsPanel {
                            theme: veloraTheme
                            externalSurface: true
                            attachSide: root.leftMenuAttachSide
                            width: inlineSettingsLoader.width
                            height: inlineSettingsLoader.height
                            open: root.settingsPanelVisible
                            visible: root.settingsPanelPanelVisible
                            focus: root.settingsPanelOpen
                            onCloseRequested: root.settingsPanelOpen = false

                            HoverHandler {
                                margin: 24
                                onHoveredChanged: {
                                    root.settingsPanelHovering = hovered
                                    if (hovered)
                                        hoverCloseTimer.stop()
                                    else
                                        root.scheduleHoverClose()
                                }
                            }
                        }
                    }

                    Behavior on y {
                        enabled: veloraTheme.motionEnabled && inlineSettingsLoader.active
                        NumberAnimation {
                            duration: veloraTheme.motionPanelGeometry
                            easing.type: veloraTheme.motionEaseEmphasized
                            easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                        }
                    }

                    Behavior on width {
                        enabled: veloraTheme.motionEnabled && inlineSettingsLoader.active
                        NumberAnimation {
                            duration: veloraTheme.motionPanelGeometry
                            easing.type: veloraTheme.motionEaseEmphasized
                            easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                        }
                    }

                    Behavior on height {
                        enabled: veloraTheme.motionEnabled && inlineSettingsLoader.active
                        NumberAnimation {
                            duration: veloraTheme.motionPanelGeometry
                            easing.type: veloraTheme.motionEaseEmphasized
                            easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                        }
                    }
                }

                Connections {
                    target: root

                    function onWallpaperSelectorOpenChanged() {
                        if (root.wallpaperSelectorOpen)
                            root.focusWallpaperSelectorInput()
                    }

                    function onSettingsPanelOpenChanged() {
                        if (root.settingsPanelOpen)
                            Qt.callLater(function() {
                                if (inlineSettingsLoader.item)
                                    inlineSettingsLoader.item.forceActiveFocus()
                            })
                    }
                }
            }
        }
    }

    Variants {
        model: root.shellSuppressedByFullscreen ? [] : Quickshell.screens

        PanelWindow {
            id: dashboardPanel

            required property var modelData
            property real dashboardReveal: !root.rightSoftLayout && root.rightDashboardOpen ? 1 : 0
            property bool dashboardCardHovering: false
            readonly property bool dashboardOnLeft: root.barOnRight
            readonly property int triggerWidth: 34
            readonly property int cardWidth: 372
            readonly property int panelWidth: cardWidth + triggerWidth
            readonly property var sections: [
                { id: "weather", y: 16, height: 206 },
                { id: "system", y: 232, height: 162 },
                { id: "calendar", y: 404, height: 218 },
                { id: "media", y: 632, height: 166 },
                { id: "memo", y: 808, height: 154 },
                { id: "todo", y: 972, height: 180 }
            ]
            readonly property int activeCardY: sectionY(root.rightDashboardSection)
            readonly property int activeCardHeight: sectionHeight(root.rightDashboardSection)

            visible: !root.rightSoftLayout
            screen: modelData
            color: "transparent"
            implicitWidth: panelWidth
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: false

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "velora-shell-drawers"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Behavior on dashboardReveal {
                enabled: veloraTheme.motionEnabled
                NumberAnimation {
                    duration: root.rightDashboardOpen ? veloraTheme.motionPanelIn : veloraTheme.motionPanelOut
                    easing.type: root.rightDashboardOpen ? veloraTheme.motionEaseEnter : veloraTheme.motionEaseExit
                }
            }

            function sectionAtY(localY) {
                for (let i = 0; i < sections.length; i += 1) {
                    const section = sections[i]
                    if (localY >= section.y && localY <= section.y + section.height)
                        return section.id
                }

                return ""
            }

            function sectionData(sectionId) {
                for (let i = 0; i < sections.length; i += 1) {
                    if (sections[i].id === sectionId)
                        return sections[i]
                }

                return sections[0]
            }

            function sectionY(sectionId) {
                return sectionData(sectionId).y
            }

            function sectionHeight(sectionId) {
                return sectionData(sectionId).height
            }

            function requestDashboardOpen(section) {
                if (section && section.length > 0)
                    root.rightDashboardSection = section

                dashboardCloseDelay.stop()
                root.rightDashboardOpen = true
            }

            function dashboardHovering() {
                return dashboardTriggerMouse.containsMouse || dashboardCardHovering
            }

            function requestDashboardClose() {
                if (!dashboardHovering())
                    dashboardCloseDelay.restart()
            }

            mask: Region {
                Region {
                    item: dashboardInteractionArea
                    radius: 0
                }

                Region {
                    item: dashboardCardInputMask
                    radius: dashboardLoader.cornerRadius
                }
            }

            anchors {
                top: true
                bottom: true
                left: dashboardOnLeft
                right: !dashboardOnLeft
            }

            Timer {
                id: dashboardCloseDelay

                interval: 260
                repeat: false
                onTriggered: {
                    if (!dashboardPanel.dashboardHovering())
                        root.rightDashboardOpen = false
                }
            }

            Item {
                id: dashboardInteractionArea

                x: dashboardPanel.dashboardOnLeft ? 0 : dashboardPanel.width - dashboardPanel.triggerWidth
                y: 0
                width: dashboardPanel.triggerWidth
                height: dashboardPanel.height

                MouseArea {
                    id: dashboardTriggerMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onEntered: {
                        const section = dashboardPanel.sectionAtY(mouseY)
                        if (section.length > 0)
                            dashboardPanel.requestDashboardOpen(section)
                    }
                    onPositionChanged: function(mouse) {
                        const section = dashboardPanel.sectionAtY(mouse.y)
                        if (section.length > 0)
                            dashboardPanel.requestDashboardOpen(section)
                        else
                            dashboardPanel.requestDashboardClose()
                    }
                    onExited: dashboardPanel.requestDashboardClose()
                }
            }

            Item {
                id: dashboardCardInputMask

                x: dashboardLoader.x
                y: dashboardLoader.y
                width: dashboardLoader.active ? dashboardLoader.width : 0
                height: dashboardLoader.active ? dashboardLoader.height : 0
            }

            Loader {
                id: dashboardLoader

                readonly property int cornerRadius: item ? item.cornerRadius : 22

                active: dashboardPanel.visible && (root.rightDashboardOpen || dashboardPanel.dashboardReveal > 0.01)
                asynchronous: true
                width: dashboardPanel.cardWidth
                height: dashboardPanel.activeCardHeight
                x: dashboardPanel.dashboardOnLeft ? dashboardPanel.triggerWidth : dashboardPanel.width - dashboardPanel.triggerWidth - width
                y: dashboardPanel.activeCardY
                visible: active
                opacity: dashboardPanel.dashboardReveal
                scale: 0.982 + dashboardPanel.dashboardReveal * 0.018
                transformOrigin: dashboardPanel.dashboardOnLeft ? Item.Left : Item.Right
                transform: Translate {
                    x: Math.round((1 - dashboardPanel.dashboardReveal) * (dashboardPanel.dashboardOnLeft ? -28 : 28))
                    y: Math.round((1 - dashboardPanel.dashboardReveal) * -4)
                }

                sourceComponent: Component {
                    VeloraDashboard {
                        theme: veloraTheme
                        compact: true
                        activeSection: root.rightDashboardSection
                        width: dashboardLoader.width
                        height: dashboardLoader.height
                        visible: dashboardLoader.active
                        onThemeRequested: function(centerY) {
                            root.rightDashboardOpen = false
                            root.showWallpaperSelector(Number(centerY) > 0 ? centerY : root.defaultQuickPopupCenterY("theme"))
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: dashboardLoader.active
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                            onEntered: {
                                dashboardPanel.dashboardCardHovering = true
                                dashboardPanel.requestDashboardOpen(root.rightDashboardSection)
                            }
                            onExited: {
                                dashboardPanel.dashboardCardHovering = false
                                dashboardPanel.requestDashboardClose()
                            }
                        }
                    }
                }

                Behavior on height {
                    enabled: veloraTheme.motionEnabled && dashboardLoader.active
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEmphasized
                        easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                    }
                }

                Behavior on y {
                    enabled: veloraTheme.motionEnabled && dashboardLoader.active
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEmphasized
                        easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                    }
                }

                Behavior on scale {
                    enabled: veloraTheme.motionEnabled && dashboardLoader.active
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEmphasized
                        easing.bezierCurve: veloraTheme.motionEmphasizedCurve
                    }
                }

            }
        }
    }

}
