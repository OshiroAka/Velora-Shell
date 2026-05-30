import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.UPower

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
    readonly property color card: theme ? theme.surfaceCard : Qt.rgba(1, 1, 1, 0.70)
    readonly property color line: theme ? theme.alpha(theme.borderActive, 0.18) : Qt.rgba(0.70, 0.52, 0.64, 0.18)
    readonly property color borderSoft: theme ? theme.borderSoft : Qt.rgba(1, 1, 1, 0.78)
    readonly property color winSurface: theme ? alpha(theme.surfacePopup, theme.themeMode === "dark" ? 0.88 : 0.78) : Qt.rgba(0.035, 0.075, 0.12, 0.88)
    readonly property color winSurfaceDeep: theme ? alpha(theme.surfaceBase, theme.themeMode === "dark" ? 0.76 : 0.62) : Qt.rgba(0.015, 0.045, 0.075, 0.76)
    readonly property color winCard: theme ? alpha(theme.surfaceCard, theme.themeMode === "dark" ? 0.42 : 0.54) : Qt.rgba(0.12, 0.20, 0.29, 0.48)
    readonly property color winCardHover: theme ? alpha(theme.surfaceCard, theme.themeMode === "dark" ? 0.58 : 0.72) : Qt.rgba(0.16, 0.26, 0.36, 0.62)
    readonly property color winLine: theme ? alpha(theme.borderSoft, theme.themeMode === "dark" ? 0.24 : 0.34) : Qt.rgba(1, 1, 1, 0.14)
    readonly property color winAccent: theme ? (pywalStyle ? theme.accentPrimary : theme.accentSecondary) : Qt.rgba(0.10, 0.70, 0.94, 1)
    readonly property color winAccent2: theme ? (pywalStyle ? theme.accentSecondary : theme.accentPrimary) : Qt.rgba(0.17, 0.86, 0.92, 1)
    readonly property string uiFont: "Noto Sans CJK JP"
    readonly property string monoFont: "JetBrainsMono Nerd Font"
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string wallpaperDir: homeDir + "/Pictures/Wallpapers"
    readonly property string scanScript: Quickshell.shellDir + "/scripts/velora-wallpaper-scan"
    readonly property string visibilityScript: Quickshell.shellDir + "/scripts/velora-wallpaper-visibility"
    readonly property string popupStatusScript: Quickshell.shellDir + "/scripts/velora-popup-status"
    readonly property string bluetoothCommand: "if ! command -v bluetoothctl >/dev/null 2>&1; then printf 'POWER|unavailable\\n'; exit 0; fi; power=$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered/ {print $2; exit}'); [ -z \"$power\" ] && power=unknown; printf 'POWER|%s\\n' \"$power\"; bluetoothctl devices Connected 2>/dev/null | sed -n 's/^Device \\([^ ]*\\) \\(.*\\)$/CONNECTED|\\1|\\2/p'; bluetoothctl devices Paired 2>/dev/null | sed -n 's/^Device \\([^ ]*\\) \\(.*\\)$/PAIRED|\\1|\\2/p'; bluetoothctl devices 2>/dev/null | sed -n 's/^Device \\([^ ]*\\) \\(.*\\)$/KNOWN|\\1|\\2/p'"
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
        { kind: "static", label: "wp15708544", title: "wp15708544", category: "Static", path: wallpaperDir + "/static/wp15708544.jpg", preview: wallpaperDir + "/static/wp15708544.jpg" }
    ]
    property var wallpaperItems: []
    property var hiddenWallpapers: []
    property bool wallpaperVisibilityLoaded: false
    property bool wallpaperVisibilitySaveQueued: false
    property var batteryDevice: null
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
            if (revealProgress <= 0.001 && !revealAnimation.running)
                animateReveal()
            if (!entryAnimation.running && entryProgress <= 0.001)
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
        setPowerProfile(powerProfile === "power-saver" ? "balanced" : "power-saver")
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
        command: ["bash", "-lc", "brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/,\"\",$4); printf \"BRIGHTNESS|%s|%s\\n\", $4/100, $1}' || printf 'BRIGHTNESS|0.86|\\n'"]

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
        id: bluetoothQuery

        running: false
        property var stagedDevices: []
        command: ["bash", "-lc", root.bluetoothCommand]

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

        ProfileView {
            anchors.fill: parent
            anchors.margins: 18
            visible: root.popupType === "profile"
        }

        TimeView {
            anchors.fill: parent
            anchors.margins: 18
            visible: root.popupType === "time"
        }

        SearchView {
            anchors.fill: parent
            anchors.margins: 18
            visible: root.popupType === "search"
        }

        FilesView {
            anchors.fill: parent
            anchors.margins: 18
            visible: root.popupType === "files"
        }

        BrowserView {
            anchors.fill: parent
            anchors.margins: 22
            visible: root.popupType === "browser"
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

        BatteryView {
            anchors.fill: parent
            anchors.margins: 18
            visible: root.popupType === "battery"
        }

        BluetoothView {
            anchors.fill: parent
            anchors.margins: 16
            visible: root.popupType === "bluetooth"
        }

        WallpaperVisibilityView {
            anchors.fill: parent
            anchors.margins: 15
            visible: root.popupType === "wallpaperVisibility"
        }
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
        property int currentDay: Number(Qt.formatDateTime(now, "d"))
        readonly property var weekdays: ["日", "月", "火", "水", "木", "金", "土"]

        function localTime(offsetHours) {
            const utc = now.getTime() + now.getTimezoneOffset() * 60000
            return Qt.formatTime(new Date(utc + offsetHours * 3600000), "HH:mm")
        }

        function calendarCells() {
            const year = now.getFullYear()
            const month = now.getMonth()
            const first = new Date(year, month, 1)
            const start = new Date(year, month, 1 - first.getDay())
            var cells = []

            for (var i = 0; i < 49; ++i) {
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

        Timer {
            interval: 1000
            running: timeView.visible
            repeat: true
            onTriggered: timeView.now = new Date()
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                PopupIcon {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    iconName: "clock"
                    lineColor: root.winAccent2
                }

                WinLabel {
                    Layout.fillWidth: true
                    text: "時刻と予定"
                    color: root.winAccent2
                    font.pixelSize: 13
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                columnSpacing: 12
                rowSpacing: 12

            ColumnLayout {
                Layout.preferredWidth: 292
                Layout.fillHeight: true
                spacing: 12

                WinCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 270

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 22
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: Qt.formatDateTime(timeView.now, "HH:mm")
                                color: root.ink
                                font.family: root.monoFont
                                font.pixelSize: 56
                                font.weight: Font.Light
                            }

                            Text {
                                text: ":" + Qt.formatDateTime(timeView.now, "ss")
                                color: root.winAccent2
                                font.family: root.monoFont
                                font.pixelSize: 38
                                font.weight: Font.Light
                                Layout.alignment: Qt.AlignBottom
                                Layout.bottomMargin: 8
                            }
                        }

                        WinLabel {
                            Layout.fillWidth: true
                            text: Qt.formatDateTime(timeView.now, "yyyy年M月d日 ddd")
                            font.pixelSize: 16
                        }

                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: root.winLine }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14
                            WinSubLabel { text: "日の出\n04:42"; color: root.ink; lineHeight: 1.45 }
                            Item { Layout.fillWidth: true }
                            PopupIcon { Layout.preferredWidth: 76; Layout.preferredHeight: 46; iconName: "sun"; lineColor: root.winAccent2 }
                            Item { Layout.fillWidth: true }
                            WinSubLabel { text: "日の入り\n19:03"; color: root.ink; horizontalAlignment: Text.AlignRight; lineHeight: 1.45 }
                        }
                    }
                }

                WinCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        WinSubLabel { text: "世界時計"; color: root.winAccent2; font.pixelSize: 12; font.weight: Font.Bold }
                        Repeater {
                            model: [
                                ["東京", "日本", timeView.localTime(9)],
                                ["ニューヨーク", "アメリカ", timeView.localTime(-4)],
                                ["ロンドン", "イギリス", timeView.localTime(1)],
                                ["パリ", "フランス", timeView.localTime(2)]
                            ]
                            WinActionRow {
                                Layout.fillWidth: true
                                iconName: "clock"
                                title: modelData[0]
                                subtitle: modelData[1]
                                Text {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData[2]
                                    color: root.ink
                                    font.family: root.monoFont
                                    font.pixelSize: 16
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                WinCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 420

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 14

                        RowLayout {
                            Layout.fillWidth: true
                            WinLabel { Layout.fillWidth: true; text: Qt.formatDateTime(timeView.now, "yyyy年M月"); font.pixelSize: 17 }
                            WinLabel { text: "‹"; font.pixelSize: 24 }
                            WinLabel { text: "›"; font.pixelSize: 24 }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 7
                            columnSpacing: 4
                            rowSpacing: 6
                            Repeater {
                                model: timeView.calendarCells()
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 10
                                    color: modelData.today ? root.alpha(root.winAccent, 0.70) : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: modelData.header ? root.inkSoft : (modelData.currentMonth ? root.ink : root.alpha(root.inkSoft, 0.48))
                                        font.family: root.uiFont
                                        font.pixelSize: modelData.header ? 12 : 13
                                        font.weight: modelData.today ? Font.Bold : Font.Medium
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    WinCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 10
                            WinSubLabel { text: "タイマー"; color: root.winAccent2; font.weight: Font.Bold }
                            Repeater {
                                model: [["06:30", "平日", true], ["07:00", "土・日", false], ["08:00", "毎日", true]]
                                WinActionRow { Layout.fillWidth: true; title: modelData[0]; subtitle: modelData[1]; iconName: "clock"; accent: modelData[2]; onClicked: root.openClockApp() }
                            }
                        }
                    }

                    WinCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 10
                            WinSubLabel { text: "今日の予定"; color: root.winAccent2; font.weight: Font.Bold }
                            Repeater {
                                model: [["09:00", "チームミーティング"], ["11:00", "プロジェクトレビュー"], ["13:00", "ランチ"], ["15:30", "デザインチェック"], ["17:00", "ジム"]]
                                WinActionRow { Layout.fillWidth: true; title: modelData[0]; subtitle: modelData[1]; iconName: "calendar"; accent: index === 0; onClicked: root.openCalendarApp() }
                            }
                        }
                    }
                }
            }

            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 9
                color: root.alpha(root.winCardHover, 0.30)
                border.width: 1
                border.color: root.alpha(root.winAccent, 0.12)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    PopupIcon {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        iconName: "clock"
                        lineColor: root.winAccent2
                    }

                    WinSubLabel {
                        Layout.fillWidth: true
                        text: "ヒント: 予定をカレンダーに追加して、効率的な一日を計画しましょう。"
                    }

                    Text {
                        text: "↗"
                        color: root.inkSoft
                        font.family: root.uiFont
                        font.pixelSize: 15
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openCalendarApp()
                }
            }
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

    component BatteryView: Item {
        ColumnLayout {
            anchors.fill: parent
            spacing: 13

            RowLayout {
                Layout.fillWidth: true

                WinLabel {
                    Layout.fillWidth: true
                    text: "通知センター"
                    font.pixelSize: 16
                }

                Rectangle {
                    Layout.preferredWidth: clearLabel.implicitWidth + 18
                    Layout.preferredHeight: 28
                    radius: 14
                    color: clearMouse.containsMouse ? root.alpha(root.winAccent, 0.16) : "transparent"

                    WinSubLabel {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "すべてクリア"
                        color: root.winAccent2
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clearNotifications()
                    }
                }
            }

            WinCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 214

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Repeater {
                        model: Math.min(notificationModel.count, 3)
                        WinActionRow {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 58
                            iconName: "bell"
                            title: notificationModel.get(index).summary
                            subtitle: notificationModel.get(index).body.length > 0 ? notificationModel.get(index).body : notificationModel.get(index).app
                            accent: index === 0
                            showArrow: false
                            onClicked: root.dismissNotification(notificationModel.get(index).id)
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 34
                                anchors.top: parent.top
                                anchors.topMargin: 12
                                text: notificationModel.get(index).timeText
                                color: root.winAccent2
                                font.family: root.monoFont
                                font.pixelSize: 11
                            }
                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                width: 7
                                height: 7
                                radius: 4
                                color: root.winAccent2
                            }
                        }
                    }

                    WinActionRow {
                        visible: notificationModel.count <= 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: 58
                        iconName: "bell"
                        title: "通知なし"
                        subtitle: "新しい通知はありません"
                        showArrow: false
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4

                WinLabel {
                    Layout.fillWidth: true
                    text: "Bluetooth デバイス"
                    font.pixelSize: 16
                }

                WinSubLabel {
                    text: "ペアリング済みデバイス"
                    color: root.winAccent2
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }
            }

            WinCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 204

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 7

                    Repeater {
                        model: Math.min(root.bluetoothDeviceCount(), 3)
                        WinActionRow {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            iconName: root.bluetoothDeviceAt(index).iconName
                            title: root.bluetoothDeviceAt(index).name
                            subtitle: root.bluetoothDeviceAt(index).detail
                            accent: root.bluetoothDeviceAt(index).active
                            showArrow: false
                            onClicked: {
                                const item = root.bluetoothDeviceAt(index)
                                root.setBluetoothDeviceConnection(item.address, item.active)
                            }
                            Text {
                                anchors.right: batteryGlyph.left
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.bluetoothDeviceAt(index).active ? "ON" : ""
                                color: root.ink
                                font.family: root.monoFont
                                font.pixelSize: 12
                            }
                            PopupIcon {
                                id: batteryGlyph
                                anchors.right: menuDots.left
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: 24
                                height: 16
                                iconName: "battery"
                                lineColor: root.inkSoft
                            }
                            Text {
                                id: menuDots
                                anchors.right: parent.right
                                anchors.rightMargin: 13
                                anchors.verticalCenter: parent.verticalCenter
                                text: "⋮"
                                color: root.inkSoft
                                font.pixelSize: 18
                            }
                        }
                    }

                    WinActionRow {
                        visible: root.bluetoothDeviceCount() <= 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        iconName: "bluetooth"
                        title: root.bluetoothIsAvailable ? "デバイスなし" : "Bluetooth unavailable"
                        subtitle: root.bluetoothIsPowered ? "pair a device" : "powered off"
                        showArrow: false
                        onClicked: root.toggleBluetoothPower()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4

                WinLabel {
                    Layout.fillWidth: true
                    text: "電源とバッテリー"
                    font.pixelSize: 16
                }

                WinSubLabel {
                    text: "電源モード: " + root.powerProfile
                    color: root.winAccent2
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }
            }

            WinCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 150

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 18

                    PopupIcon {
                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 86
                        iconName: "battery"
                        lineColor: root.winAccent2
                    }

                    ColumnLayout {
                        Layout.preferredWidth: 114
                        spacing: 2

                        Text {
                            text: root.batteryText()
                            color: root.ink
                            font.family: root.monoFont
                            font.pixelSize: 42
                            font.weight: Font.Light
                        }

                        WinSubLabel {
                            text: root.batteryAvailable()
                                ? (root.batteryStateText + (root.batteryTimeText.length > 0 ? " · " + root.batteryTimeText : ""))
                                : (root.acOnline ? "AC connected" : "battery unavailable")
                            color: root.winAccent2
                        }
                    }

                    WinCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: root.alpha(root.winCardHover, 0.30)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4

                            WinSubLabel {
                                Layout.fillWidth: true
                                text: "バッテリー使用量（過去 24 時間）"
                                color: root.winAccent2
                                font.weight: Font.Bold
                            }

                            BatteryChart {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                        }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: 10
                rowSpacing: 10
                Repeater {
                    model: [["battery", "省電力モード"], ["moon", "夜間モード"], ["sun", "画面の明るさ"], ["settings", "設定"]]
                    WinIconTile {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 96
                        iconName: modelData[0]
                        label: modelData[1]
                        active: index === 0 ? root.powerProfile === "power-saver" : (index === 1 ? root.nightLightEnabled : false)
                        onClicked: {
                            if (index === 0)
                                root.togglePowerSaver()
                            else if (index === 1)
                                root.toggleNightLight()
                            else if (index === 2)
                                root.openDisplaySettings()
                            else
                                root.openSettings("powerdevilprofilesconfig")
                        }
                    }
                }
            }
        }
    }

    component BatteryChart: Canvas {
        id: batteryChart

        Connections {
            target: root
            function onBatteryDeviceChanged() { batteryChart.requestPaint() }
            function onBatteryStateTextChanged() { batteryChart.requestPaint() }
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = root.alpha(root.winAccent2, 0.88)
            ctx.lineWidth = 2
            ctx.beginPath()
            const current = root.batteryAvailable() ? root.batteryPercent() : 0.0
            const charging = root.batteryStateText.toLowerCase().indexOf("charg") >= 0
            var pts = []
            for (let i = 0; i < 11; i += 1) {
                const t = i / 10
                const slope = charging ? (t - 1) * 0.18 : (1 - t) * 0.18
                pts.push(Math.max(0.04, Math.min(1, current + slope)))
            }
            for (let i = 0; i < pts.length; i += 1) {
                const x = i * width / Math.max(1, pts.length - 1)
                const y = height - pts[i] * height
                if (i === 0) ctx.moveTo(x, y)
                else ctx.lineTo(x, y)
            }
            ctx.stroke()
        }
    }

    component AudioBars: Canvas {
        id: audioBars

        Timer {
            interval: 140
            running: audioBars.visible
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
            spacing: 18

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Repeater {
                    model: [["すべて", "apps"], ["アプリ", "apps"], ["ファイル", "files"], ["設定", "settings"], ["Web", "apps"], ["ドキュメント", "files"], ["画像", "files"], ["フォルダー", "files"]]
                    Rectangle {
                        Layout.preferredWidth: Math.max(66, tabLabel.implicitWidth + 26)
                        Layout.preferredHeight: 32
                        radius: 16
                        color: index === 0 || root.searchMode === modelData[1] ? root.alpha(root.winAccent, 0.72) : "transparent"
                        border.width: index === 0 || root.searchMode === modelData[1] ? 0 : 1
                        border.color: root.winLine
                        Text {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: modelData[0]
                            color: index === 0 || root.searchMode === modelData[1] ? "white" : root.inkSoft
                            font.family: root.uiFont
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setSearchMode(modelData[1])
                        }
                    }
                }
            }

            SearchBox {
                id: searchBox

                Layout.fillWidth: true
                Layout.preferredHeight: 56
            }

            WinSubLabel {
                Layout.fillWidth: true
                text: "最近の検索"
                font.pixelSize: 12
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Repeater {
                    model: ["コントロールパネル", "システム情報", "壁紙", "ネットワーク設定", "電源オプション"]
                    Rectangle {
                        Layout.preferredWidth: chipText.implicitWidth + 24
                        Layout.preferredHeight: 30
                        radius: 15
                        color: root.alpha(root.winCard, 0.42)
                        border.width: 1
                        border.color: root.winLine
                        Text { id: chipText; anchors.centerIn: parent; text: modelData; color: root.ink; font.family: root.uiFont; font.pixelSize: 11; font.weight: Font.DemiBold }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.searchQuery = modelData
                                root.rebuildSearch()
                            }
                        }
                    }
                }
            }

            WinSubLabel {
                Layout.fillWidth: true
                text: "クイック結果"
                font.pixelSize: 12
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: 10
                rowSpacing: 10
                Repeater {
                    model: [
                        ["display", "コントロールパネル", "システム"],
                        ["folder", "エクスプローラー", "ファイル エクスプローラー"],
                        ["box", "デバイス マネージャー", "コントロール パネル"],
                        ["settings", "設定", "システム設定"],
                        ["display", "タスク マネージャー", "システム"],
                        ["drive", "ディスクのクリーンアップ", "システム"]
                    ]
                    WinActionRow {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 62
                        iconName: modelData[0]
                        title: modelData[1]
                        subtitle: modelData[2]
                        accent: index === 0
                        onClicked: {
                            if (modelData[0] === "settings" || modelData[0] === "display")
                                root.openSettings("")
                            else if (modelData[0] === "folder")
                                root.openPath(root.homeDir)
                            else
                                root.openFileSearch()
                        }
                    }
                }
            }

            WinSubLabel {
                Layout.fillWidth: true
                text: "アプリ・ファイルの候補"
                font.pixelSize: 12
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                    model: root.searchResults.length > 0 ? root.searchResults : []

                    SearchResultRow {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        entry: modelData
                        selected: index === root.searchSelectedIndex
                        onClicked: root.launchSearchEntry(entry)
                    }
                }

                Repeater {
                    model: root.searchResults.length > 0 ? [] : [["browser", "Microsoft Edge", "アプリ"], ["settings", "設定", "アプリ"], ["memo", "企画書_最終版.pptx", "ドキュメント"], ["memo", "週次レポート.xlsx", "ドキュメント"]]
                    WinActionRow {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        iconName: modelData[0]
                        title: modelData[1]
                        subtitle: modelData[2]
                        onClicked: {
                            if (modelData[0] === "browser")
                                root.browserCommand("new-window")
                            else if (modelData[0] === "settings")
                                root.openSettings("")
                            else
                                root.openFileSearch()
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                WinSubLabel { Layout.fillWidth: true; text: "ヒント:「設定を開く」と入力して設定をすばやく開けます。" }
                WinSubLabel { text: "詳細検索を開く ›"; color: root.winAccent2; font.weight: Font.Bold }
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
                        root.wallpaperDir + "/static/WPP_blue.png",
                        root.wallpaperDir + "/static/wp15708544.jpg",
                        root.wallpaperDir + "/static/wp12419427-tokyo-night-4k-wallpapers.jpg"
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

    component NotificationsView: Item {
        BatteryView {
            anchors.fill: parent
        }
    }

    component BluetoothView: Item {
        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                PopupIcon {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    iconName: "bluetooth"
                    entryDelay: 40
                }

                TitleText {
                    Layout.fillWidth: true
                    text: root.bluetoothIsPowered ? "Bluetooth" : root.tr("bluetoothOff")
                    entryDelay: 48
                }

                SoftToggle {
                    visible: root.bluetoothIsAvailable
                    checked: root.bluetoothIsPowered
                    entryDelay: 58
                    onClicked: root.toggleBluetoothPower()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                radius: 12
                color: root.alpha(root.card, 0.38)
                border.width: 1
                border.color: root.line

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    PopupIcon {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        iconName: "bluetooth"
                        lineColor: root.bluetoothIsPowered ? root.pink : root.inkSoft
                        entryDelay: 86
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: root.bluetoothIsAvailable ? (root.bluetoothIsPowered ? root.tr("btReady") : root.tr("btDisabled")) : root.tr("btMissing")
                            color: root.ink
                            font.family: root.uiFont
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }

                        SmallText {
                            Layout.fillWidth: true
                            text: root.bluetoothIsAvailable ? String(root.bluetoothDeviceCount()) + " " + root.tr("btDevices") : root.tr("btInstall")
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Repeater {
                model: Math.min(root.bluetoothDeviceCount(), 4)

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 11
                    color: deviceMouse.containsMouse ? root.alpha(root.card, 0.48) : root.alpha(root.card, 0.30)
                    border.width: 1
                    border.color: {
                        const item = root.bluetoothDeviceAt(index)
                        return root.alpha(item.active ? root.pink : root.borderSoft, item.active ? 0.34 : 0.20)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            radius: 9
                            color: {
                                const item = root.bluetoothDeviceAt(index)
                                return root.alpha(item.active ? root.pink : root.card, item.active ? 0.20 : 0.42)
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: String(root.bluetoothDeviceAt(index).iconLabel || "").length > 0
                                text: root.bluetoothDeviceAt(index).iconLabel
                                color: root.ink
                                font.family: root.uiFont
                                font.pixelSize: 13
                                font.weight: Font.Bold
                            }

                            PopupIcon {
                                anchors.centerIn: parent
                                visible: String(root.bluetoothDeviceAt(index).iconLabel || "").length <= 0
                                width: 18
                                height: 18
                                iconName: root.bluetoothDeviceAt(index).iconName
                                lineColor: root.bluetoothDeviceAt(index).active ? root.pink : root.inkSoft
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: root.bluetoothDeviceAt(index).name
                                color: root.ink
                                font.family: root.uiFont
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }

                            SmallText {
                                Layout.fillWidth: true
                                text: root.bluetoothDeviceAt(index).detail
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            text: root.bluetoothDeviceAt(index).loading ? "..." : (root.bluetoothDeviceAt(index).active ? root.tr("disconnect") : root.tr("connect"))
                            color: root.pink
                            font.family: root.uiFont
                            font.pixelSize: 11
                            font.weight: Font.Bold
                        }
                    }

                    MouseArea {
                        id: deviceMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const item = root.bluetoothDeviceAt(index)
                            root.setBluetoothDeviceConnection(item.address, item.active)
                        }
                    }
                }
            }

            Rectangle {
                visible: root.bluetoothDeviceCount() <= 0
                Layout.fillWidth: true
                Layout.preferredHeight: 86
                radius: 11
                color: root.alpha(root.card, 0.28)
                border.width: 1
                border.color: root.line

                Text {
                    anchors.centerIn: parent
                    text: root.bluetoothIsAvailable ? root.tr("btNoDevices") : root.tr("btUnavailable")
                    color: root.inkSoft
                    font.family: root.uiFont
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }

            Item {
                Layout.fillHeight: true
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
