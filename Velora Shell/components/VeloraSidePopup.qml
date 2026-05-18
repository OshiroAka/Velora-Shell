import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Item {
    id: root

    property var theme: null
    property alias surfaceItem: panelSurface
    property string popupType: "search"
    property bool open: visible
    property bool externalSurface: false
    property bool interactiveFocus: false
    property string attachSide: "left"
    property real volumePercent: 0.60
    property real brightnessPercent: 0.86
    property bool muted: false
    property bool wifiEnabled: true
    property bool nightLightEnabled: true
    property string pendingCommand: ""
    property string activeCommand: ""
    property string searchQuery: ""
    property string searchMode: "apps"
    property int searchSelectedIndex: 0
    property var searchResults: []
    property bool searchReady: false
    readonly property int cornerRadius: 13
    readonly property int arrowCenterY: {
        if (popupType === "volume")
            return 78
        if (popupType === "wifi")
            return 288
        if (popupType === "brightness")
            return 248
        if (popupType === "notifications")
            return 414
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
    readonly property color card: theme ? theme.surfaceCard : Qt.rgba(1, 1, 1, 0.70)
    readonly property color line: theme ? theme.alpha(theme.borderActive, 0.18) : Qt.rgba(0.70, 0.52, 0.64, 0.18)
    readonly property color borderSoft: theme ? theme.borderSoft : Qt.rgba(1, 1, 1, 0.78)
    readonly property string uiFont: "Noto Sans CJK JP"
    readonly property string monoFont: "JetBrainsMono Nerd Font"
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string wallpaperDir: homeDir + "/Pictures/Wallpapers"
    readonly property string scanScript: Quickshell.shellDir + "/scripts/velora-wallpaper-scan"
    readonly property string visibilityScript: Quickshell.shellDir + "/scripts/velora-wallpaper-visibility"
    readonly property var fallbackWallpapers: [
        { kind: "static", label: "wp15708544", title: "wp15708544", category: "Static", path: wallpaperDir + "/static/wp15708544.jpg", preview: wallpaperDir + "/static/wp15708544.jpg" }
    ]
    property var wallpaperItems: []
    property var hiddenWallpapers: []
    property bool wallpaperVisibilityLoaded: false
    property bool wallpaperVisibilitySaveQueued: false
    property real revealProgress: 0
    property real entryProgress: 0
    property real arrowVisualCenterY: arrowCenterY
    readonly property bool backgroundPollingActive: open && visible
    readonly property int motionFast: theme ? theme.motionFast : 120
    readonly property int motionNormal: theme ? theme.motionNormal : 200
    readonly property int motionSlow: theme ? theme.motionSlow : 320
    readonly property int motionPanelIn: theme ? theme.motionPanelIn : 220
    readonly property int motionPanelOut: theme ? theme.motionPanelOut : 140
    readonly property int motionPanelGeometry: theme ? theme.motionPanelGeometry : 220
    readonly property int motionHover: theme ? theme.motionHover : 120
    readonly property int motionPanelOffset: theme ? Math.max(theme.motionPanelOffset, 46) : 46
    readonly property int motionEaseEnter: theme ? theme.motionEaseEnter : Easing.OutCubic
    readonly property int motionEaseExit: theme ? theme.motionEaseExit : Easing.InCubic
    readonly property int motionEaseHover: theme ? theme.motionEaseHover : Easing.OutCubic
    readonly property int motionEaseEmphasized: theme ? theme.motionEaseEmphasized : Easing.BezierSpline
    readonly property var motionEmphasizedCurve: theme ? theme.motionEmphasizedCurve : [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]

    signal closeRequested()
    signal pointerInsideChanged(bool inside)

    function alpha(colorValue, opacity) {
        return root.theme ? root.theme.alpha(colorValue, opacity) : Qt.rgba(colorValue.r, colorValue.g, colorValue.b, opacity)
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

    function restartEntryAnimation() {
        entryAnimation.stop()
        entryProgress = 0
        entryAnimation.from = 0
        entryAnimation.to = 1
        entryAnimation.duration = motionSlow
        entryAnimation.restart()
    }

    function exitEntryAnimation() {
        entryAnimation.stop()
        entryAnimation.from = entryProgress
        entryAnimation.to = 0
        entryAnimation.duration = motionPanelOut
        entryAnimation.restart()
    }

    function animateReveal() {
        revealAnimation.stop()
        revealAnimation.from = revealProgress
        revealAnimation.to = open ? 1 : 0
        revealAnimation.duration = open ? motionPanelIn : motionPanelOut
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
    }

    HoverHandler {
        onHoveredChanged: root.pointerInsideChanged(hovered)
    }

    onOpenChanged: {
        animateReveal()
        if (open) {
            restartEntryAnimation()
            if (popupType === "search")
                ensureSearchReady()
            refreshStatusQueries()
            if (popupType === "wallpaperVisibility")
                ensureWallpaperVisibilityLoaded()
        } else {
            exitEntryAnimation()
        }
    }

    onVisibleChanged: {
        if (visible && open) {
            if (revealProgress <= 0.001)
                animateReveal()
            restartEntryAnimation()
            refreshStatusQueries()
        }
    }

    onPopupTypeChanged: {
        if (visible)
            restartEntryAnimation()
        if (open)
            refreshStatusQueries()
        if (popupType === "search" && open)
            ensureSearchReady()
        if (popupType === "wallpaperVisibility" && open)
            ensureWallpaperVisibilityLoaded()
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

    function setVolume(value) {
        root.volumePercent = Math.max(0, Math.min(1, value))
        runCommand("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + Math.round(root.volumePercent * 100) + "%")
    }

    function toggleMute() {
        root.muted = !root.muted
        runCommand("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
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
        syncTrackedNotifications()
        if (open && popupType === "search")
            ensureSearchReady()
        refreshStatusQueries()
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
            }
        }
    }

    Process {
        id: volumeQuery

        running: false
        command: ["bash", "-lc", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo 'Volume: 0.60'"]

        stdout: SplitParser {
            onRead: function(data) {
                var text = data.trim()
                var match = text.match(/[0-9]+\\.?[0-9]*/)

                root.muted = text.indexOf("MUTED") >= 0
                if (match)
                    root.volumePercent = Math.max(0, Math.min(1, parseFloat(match[0])))
            }
        }

        onExited: running = false
    }

    Process {
        id: brightnessQuery

        running: false
        command: ["bash", "-lc", "brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/,\"\",$4); print $4/100}' || echo 0.86"]

        stdout: SplitParser {
            onRead: function(data) {
                var value = parseFloat(data.trim())
                if (!isNaN(value))
                    root.brightnessPercent = Math.max(0.05, Math.min(1, value))
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

    Process {
        id: wifiQuery

        running: false
        command: ["bash", "-lc", "printf 'RADIO|'; nmcli -t -f WIFI radio 2>/dev/null; nmcli -t -f ACTIVE,SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null | awk -F: 'NF>=3 && $2!=\"\" {print $1 \"|\" $2 \"|\" $3 \"|\" $4}'"]

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
        command: ["bash", "-lc", "if command -v makoctl >/dev/null 2>&1; then makoctl list -j 2>/dev/null | python3 -c 'import sys,json; raw=sys.stdin.read().strip() or \"[]\"; print(json.dumps(json.loads(raw)))' 2>/dev/null || printf '[]\\n'; else printf '[]\\n'; fi"]

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

    opacity: revealProgress
    scale: 0.972 + revealProgress * 0.028
    transformOrigin: attachedRight ? Item.Right : Item.Left
    activeFocusOnTab: true

    transform: Translate {
        x: Math.round((1 - root.revealProgress) * (root.attachedRight ? root.motionPanelOffset : -root.motionPanelOffset))
        y: 0
    }

    NumberAnimation {
        id: revealAnimation

        target: root
        property: "revealProgress"
        from: root.revealProgress
        to: root.open ? 1 : 0
        duration: root.open ? root.motionPanelIn : root.motionPanelOut
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
        color: root.externalSurface ? "transparent" : root.glass
        border.width: root.externalSurface ? 0 : 1
        border.color: root.neon && root.theme ? root.theme.popupBorderGlow : root.borderSoft
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
                GradientStop { position: 0.0; color: root.alpha(root.card, root.neon ? 0.28 : 0.48) }
                GradientStop { position: 0.55; color: root.alpha(root.card, root.neon ? 0.16 : 0.24) }
                GradientStop { position: 1.0; color: root.alpha(root.pink, root.neon ? 0.10 : 0.16) }
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

        SearchView {
            anchors.fill: parent
            anchors.margins: 18
            visible: root.popupType === "search"
        }

        VolumeView {
            anchors.fill: parent
            anchors.margins: 22
            visible: root.popupType === "volume"
        }

        WifiView {
            anchors.fill: parent
            anchors.margins: 16
            visible: root.popupType === "wifi"
        }

        BrightnessView {
            anchors.fill: parent
            anchors.margins: 22
            visible: root.popupType === "brightness"
        }

        NotificationsView {
            anchors.fill: parent
            anchors.margins: 16
            visible: root.popupType === "notifications"
        }

        WallpaperVisibilityView {
            anchors.fill: parent
            anchors.margins: 15
            visible: root.popupType === "wallpaperVisibility"
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

    component SearchView: Item {
        id: searchView

        opacity: root.stageOpacity(35, 220)
        scale: root.stageScale(35, 0.985, 1)
        transformOrigin: Item.TopLeft

        transform: Translate {
            y: root.stageTranslateY(35, 12)
        }

        function queueSearchFocus() {
            if (root.popupType === "search" && root.interactiveFocus)
                searchFocusTimer.restart()
        }

        Timer {
            id: searchFocusTimer

            interval: 130
            repeat: false
            onTriggered: {
                if (root.popupType === "search" && root.interactiveFocus)
                    searchBox.forceSearchFocus()
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 11

            SearchBox {
                id: searchBox

                Layout.fillWidth: true
                Layout.preferredHeight: 42
            }

            HeaderText {
                Layout.fillWidth: true
                text: root.searchQuery.length > 0 ? "アプリ" : "最近のアプリ"
            }

            Repeater {
                model: root.searchResults

                SearchResultRow {
                    Layout.fillWidth: true
                    entry: modelData
                    selected: index === root.searchSelectedIndex
                    onClicked: root.launchSearchEntry(entry)
                }
            }

            Text {
                visible: root.searchResults.length <= 0
                Layout.fillWidth: true
                Layout.preferredHeight: 78
                text: "見つかりません"
                color: root.inkSoft
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: root.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            DividerLine {
                Layout.fillWidth: true
                Layout.topMargin: 2
                Layout.bottomMargin: 2
            }

            HeaderText {
                Layout.fillWidth: true
                text: "カテゴリ"
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                PopupChip {
                    text: "アプリ"
                    active: root.searchMode === "apps"
                    onClicked: root.setSearchMode("apps")
                }

                PopupChip {
                    text: "設定"
                    active: root.searchMode === "settings"
                    onClicked: root.setSearchMode("settings")
                }

                PopupChip {
                    text: "ファイル"
                    active: root.searchMode === "files"
                    onClicked: root.setSearchMode("files")
                }
            }
        }

        Connections {
            target: root

            function onPopupTypeChanged() {
                searchView.queueSearchFocus()
            }

            function onInteractiveFocusChanged() {
                searchView.queueSearchFocus()
            }
        }

        Component.onCompleted: {
            searchView.queueSearchFocus()
        }
    }

    component VolumeView: Item {
        ColumnLayout {
            anchors.fill: parent
            spacing: 18

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                PopupIcon {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    iconName: "volume"
                    entryDelay: 40
                }

                TitleText {
                    Layout.fillWidth: true
                    text: "ボリューム"
                    entryDelay: 45
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

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

            HeaderText {
                Layout.fillWidth: true
                text: "出力デバイス"
            }

            SelectRow {
                Layout.fillWidth: true
                text: "スピーカー (Realtek(R) Audio)"
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                HeaderText {
                    Layout.fillWidth: true
                    text: "ミュート"
                }

                SoftToggle {
                    checked: root.muted
                    entryDelay: 180
                    onClicked: root.toggleMute()
                }
            }
        }
    }

    component WifiView: Item {
        ColumnLayout {
            anchors.fill: parent
            spacing: 13

            RowLayout {
                Layout.fillWidth: true

                TitleText {
                    Layout.fillWidth: true
                    text: "インターネット"
                    entryDelay: 40
                }

                SoftToggle {
                    checked: root.wifiEnabled
                    entryDelay: 85
                    onClicked: root.toggleWifi()
                }
            }

            HeaderText {
                Layout.fillWidth: true
                text: "接続中のネットワーク"
            }

            ConnectedWifiCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 66
                ssid: root.activeWifi() ? root.activeWifi().ssid : "ネットワークなし"
                signal: root.activeWifi() ? root.activeWifi().signal : 0
                secure: root.activeWifi() ? root.activeWifi().secure : false
            }

            HeaderText {
                Layout.fillWidth: true
                Layout.topMargin: 4
                text: "利用可能なネットワーク"
            }

            ColumnLayout {
                Layout.fillWidth: true
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

            Item {
                Layout.fillHeight: true
            }

            DividerLine {
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                radius: 9
                color: settingsMouse.containsMouse ? root.alpha(root.pink, 0.10) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 6
                    spacing: 12

                    Text {
                        Layout.fillWidth: true
                        text: "ネットワーク設定"
                        color: root.ink
                        font.family: root.uiFont
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "›"
                        color: root.lilac
                        font.pixelSize: 24
                        font.family: root.uiFont
                    }
                }

                MouseArea {
                    id: settingsMouse

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    preventStealing: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        mouse.accepted = true
                        root.runCommand("if command -v nm-connection-editor >/dev/null 2>&1; then nm-connection-editor >/dev/null 2>&1 & elif command -v systemsettings >/dev/null 2>&1; then systemsettings kcm_networkmanagement >/dev/null 2>&1 & fi")
                    }
                }
            }
        }
    }

    component BrightnessView: Item {
        ColumnLayout {
            anchors.fill: parent
            spacing: 16

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
                    text: "明るさ"
                    entryDelay: 50
                }
            }

            SliderBar {
                Layout.fillWidth: true
                value: root.brightnessPercent
                entryDelay: 80
                onMoved: function(value) {
                    root.setBrightness(value)
                }
            }

            DividerLine {
                Layout.fillWidth: true
                Layout.topMargin: 4
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                PopupIcon {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    iconName: "sun"
                    entryDelay: 110
                    entryRotate: -12
                    entryStartScale: 0.85
                    entryPeakScale: 1.025
                }

                TitleText {
                    Layout.fillWidth: true
                    text: "ナイトライト"
                    entryDelay: 120
                }

                SoftToggle {
                    checked: root.nightLightEnabled
                    entryDelay: 125
                    onClicked: root.toggleNightLight()
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
                    text: "暖色"
                }

                SmallText {
                    text: "寒色"
                }
            }

            DividerLine {
                Layout.fillWidth: true
                Layout.topMargin: 4
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                PopupIcon {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    iconName: "display"
                    entryDelay: 210
                }

                TitleText {
                    Layout.fillWidth: true
                    text: "ディスプレイモード"
                    entryDelay: 215
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 7

                ModeButton {
                    Layout.fillWidth: true
                    label: "明るさ優先"
                    active: true
                    entryDelay: 240
                }

                ModeButton {
                    Layout.fillWidth: true
                    label: "バランス"
                    entryDelay: 280
                }

                ModeButton {
                    Layout.fillWidth: true
                    label: "省エネ"
                    entryDelay: 320
                }
            }
        }
    }

    component NotificationsView: Item {
        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            RowLayout {
                Layout.fillWidth: true

                TitleText {
                    Layout.fillWidth: true
                    text: "通知"
                    entryDelay: 40
                }

                Text {
                    text: "すべて既読"
                    color: root.inkSoft
                    font.family: root.uiFont
                    font.pixelSize: 11
                    font.weight: Font.DemiBold

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clearNotifications()
                    }
                }

                PopupIcon {
                    Layout.leftMargin: 9
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    iconName: "settings"
                }
            }

            Repeater {
                model: Math.min(notificationModel.count, 3)

                NotificationCard {
                    Layout.fillWidth: true
                    notificationId: notificationModel.get(index).id
                    iconName: index === 0 ? "box" : (index === 1 ? "download" : "image")
                    title: notificationModel.get(index).summary
                    appName: notificationModel.get(index).app
                    timeText: notificationModel.get(index).timeText
                    body: notificationModel.get(index).body
                    entryDelay: 120 + index * 42
                    onDismissRequested: root.dismissNotification(notificationId)
                }
            }

            Rectangle {
                visible: notificationModel.count <= 0
                Layout.fillWidth: true
                Layout.preferredHeight: 96
                radius: 10
                color: root.card
                border.width: 1
                border.color: root.line

                Text {
                    anchors.centerIn: parent
                    text: "通知はありません"
                    color: root.inkSoft
                    font.family: root.uiFont
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }

            Item {
                Layout.fillHeight: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 118
                radius: 10
                color: root.alpha(root.card, 0.34)
                border.width: 1
                border.color: root.line

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    ToggleRow {
                        Layout.fillWidth: true
                        iconName: "moon"
                        label: "集中モード"
                    }

                    DividerLine {
                        Layout.fillWidth: true
                    }

                    ToggleRow {
                        Layout.fillWidth: true
                        iconName: "bell"
                        label: "通知をミュート"
                    }
                }
            }
        }
    }

    component SearchBox: Rectangle {
        id: box

        function forceSearchFocus() {
            if (!root.interactiveFocus)
                return
            input.forceActiveFocus()
            input.selectAll()
        }

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
                    focus: root.popupType === "search" && root.interactiveFocus

                    onTextEdited: root.searchQuery = text

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Down) {
                            root.stepSearch(1)
                            event.accepted = true
                            return
                        }

                        if (event.key === Qt.Key_Up) {
                            root.stepSearch(-1)
                            event.accepted = true
                            return
                        }

                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.launchSelectedSearchEntry()
                            event.accepted = true
                            return
                        }

                        if (event.key === Qt.Key_Escape) {
                            root.closeRequested()
                            event.accepted = true
                        }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.IBeamCursor
            onClicked: function(mouse) {
                mouse.accepted = true
                box.forceSearchFocus()
            }
        }
    }

    component SearchResultRow: Rectangle {
        id: row

        property var entry: null
        property bool selected: false
        signal clicked()

        Layout.preferredHeight: 30
        radius: 8
        color: selected ? root.alpha(root.pink, 0.22) : (rowMouse.containsMouse ? root.alpha(root.card, 0.42) : "transparent")
        border.width: selected ? 1 : 0
        border.color: root.alpha(root.pink, 0.26)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 10

            PopupIcon {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                iconName: root.searchEntryKind(row.entry) === "settings" ? "settings" : (root.searchEntryKind(row.entry) === "files" ? "folder" : "box")
                lineColor: row.selected ? root.pink : root.lilac
            }

            Text {
                Layout.fillWidth: true
                text: row.entry ? root.textOf(row.entry.name) : ""
                color: row.selected ? root.pink : root.ink
                font.family: root.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                text: row.entry ? root.textOf(row.entry.genericName || row.entry.comment || "") : ""
                color: root.inkSoft
                visible: text.length > 0
                font.family: root.uiFont
                font.pixelSize: 10
                font.weight: Font.Medium
                elide: Text.ElideRight
                Layout.maximumWidth: 82
            }
        }

        MouseArea {
            id: rowMouse

            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            preventStealing: true
            cursorShape: Qt.PointingHandCursor
            onClicked: function(mouse) {
                mouse.accepted = true
                row.clicked()
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

        Layout.preferredHeight: 42
        radius: 8
        opacity: root.stageOpacity(entryDelay, 170)
        transform: Translate {
            y: root.stageTranslateY(row.entryDelay, 7)
        }
        color: root.alpha(root.card, 0.38)
        border.width: 1
        border.color: root.line

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

        Layout.preferredHeight: 46
        radius: 7
        opacity: root.stageOpacity(entryDelay, 180)
        scale: root.stageScale(entryDelay, 0.96, 1.0)
        transform: Translate {
            y: root.stageTranslateY(modeButton.entryDelay, 8)
        }
        color: active ? root.alpha(root.pink, 0.25) : root.alpha(root.card, 0.36)
        border.width: 1
        border.color: active ? root.alpha(root.pink, 0.30) : root.line

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
            } else if (iconName === "volume" || iconName === "headphones") {
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
            } else if (iconName === "memo") {
                roundRect(ctx, s * 0.24, s * 0.20, s * 0.52, s * 0.60, s * 0.05)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(s * 0.35, s * 0.42)
                ctx.lineTo(s * 0.64, s * 0.42)
                ctx.moveTo(s * 0.35, s * 0.55)
                ctx.lineTo(s * 0.58, s * 0.55)
                ctx.stroke()
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
