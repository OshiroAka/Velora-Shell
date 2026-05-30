pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property int barH: 38
    property int pillH: 28
    property real pillOpacity: 0.72
    property real popupOpacity: 0.58
    property int pillR: 9
    property int pillPadH: 12
    property int pillSpacing: 6
    property int barMarginT: 8
    property int barMarginH: 10
    property int fontSize: 12
    property int fontSizeSm: 10
    property string fontFamily: "JetBrainsMono Nerd Font"

    property string settingsCategory: "bar"

    property string clockBg: ""
    property real clockBgOpacity: 0.22
    property real clockAccentBoost: 1.0

    property string mediaBg: ""
    property real mediaBgOpacity: 0.22

    property string weatherBg: ""
    property real weatherBgOpacity: 0.58

    property string profileName: "shira"
    property string profileBio: "Foco, disciplina e constancia."
    property string profileImage: ""
    property string profileTikTok: "@____________"
    property string profileSystem: "CachyOS"

    property bool effectsEnabled: true
    property real motionStrength: 1.0
    property bool pywalActive: true
    property int pywalPollMs: 700
    property string weatherCity: "Guarulhos"

    property bool searchEnabled: true
    property int searchPanelWidth: 560
    property int searchMaxResults: 8
    property int searchIconSize: 28
    property real searchOpacity: 0.74
    property bool searchShowIcons: true
    property bool searchCompact: false
    property int searchPosition: 1

    property int clockStyle: 0
    property int clockPopupStyle: 0
    property bool clockShowSeconds: true
    property bool clockUse24h: false
    property bool clockShowDate: true

    property int lockTheme: 0
    property bool lockEnabled: true
    property bool lockShowImage: true
    property bool lockShowDate: true
    property bool lockShowUser: true
    property bool lockClock24h: false
    property string lockWallpaper: ""
    property string lockImage: ""
    property real lockBlur: 0.68
    property real lockDim: 0.22
    property real lockGlow: 0.86
    property real lockPanelOpacity: 0.18
    property int lockLineStyle: 0
    property int lockAnimStyle: 0
    property real lockAnimStrength: 1.0

    property bool mediaAlwaysVisible: false
    property bool mediaShowVisualizer: true
    property int mediaPanelWidth: 246
    property int mediaPanelHeight: 560

    property bool wallpaperSelectorEnabled: true
    property int wallpaperModel: 2
    property int wallpaperPanelPosition: 0
    property int wallpaperOpenStyle: 0
    property int wallpaperMoveStyle: 0
    property int wallpaperTransition: 0
    property int wallpaperPanelThick: 235
    property real wallpaperPanelSpan: 1.0
    property bool wallpaperFillEdges: true
    property bool wallpaperApplyPywal: true

    property int animationSpeed: 100
    property bool trailEnabled: true
    property real glowStrength: 0.70
    property real hoverScale: 1.025

    property bool loaded: false
    property var saveQueue: []
    readonly property var configKeys: [
        "barH", "pillH", "pillR", "pillPadH", "pillSpacing", "barMarginT", "barMarginH",
        "pillOpacity", "popupOpacity", "fontSize", "fontSizeSm", "fontFamily",
        "settingsCategory", "clockBg", "clockBgOpacity", "clockAccentBoost",
        "mediaBg", "mediaBgOpacity", "weatherBg", "weatherBgOpacity",
        "profileName", "profileBio", "profileImage", "profileTikTok", "profileSystem",
        "effectsEnabled", "motionStrength",
        "pywalActive", "pywalPollMs", "weatherCity", "searchEnabled",
        "searchPanelWidth", "searchMaxResults", "searchIconSize", "searchOpacity",
        "searchShowIcons", "searchCompact", "searchPosition", "clockStyle",
        "clockPopupStyle", "clockShowSeconds", "clockUse24h", "clockShowDate",
        "lockTheme", "lockEnabled", "lockShowImage", "lockShowDate",
        "lockShowUser", "lockClock24h", "lockWallpaper", "lockImage",
        "lockBlur", "lockDim", "lockGlow", "lockPanelOpacity", "lockLineStyle", "lockAnimStyle",
        "lockAnimStrength",
        "mediaAlwaysVisible", "mediaShowVisualizer", "mediaPanelWidth",
        "mediaPanelHeight", "wallpaperSelectorEnabled", "wallpaperModel",
        "wallpaperPanelPosition", "wallpaperOpenStyle", "wallpaperMoveStyle",
        "wallpaperTransition", "wallpaperPanelThick", "wallpaperPanelSpan",
        "wallpaperFillEdges", "wallpaperApplyPywal",
        "animationSpeed", "trailEnabled", "glowStrength",
        "hoverScale"
    ]

    function quote(s) {
        return "'" + ("" + s).replace(/'/g, "'\\''") + "'"
    }

    function stringify(value) {
        if (value === true)
            return "true"
        if (value === false)
            return "false"
        return "" + value
    }

    function valueForKey(key) {
        if (key === "barH") return root.barH
        if (key === "pillH") return root.pillH
        if (key === "pillR") return root.pillR
        if (key === "pillPadH") return root.pillPadH
        if (key === "pillSpacing") return root.pillSpacing
        if (key === "barMarginT") return root.barMarginT
        if (key === "barMarginH") return root.barMarginH
        if (key === "pillOpacity") return root.pillOpacity
        if (key === "popupOpacity") return root.popupOpacity
        if (key === "fontSize") return root.fontSize
        if (key === "fontSizeSm") return root.fontSizeSm
        if (key === "fontFamily") return root.fontFamily
        if (key === "settingsCategory") return root.settingsCategory
        if (key === "clockBg") return root.clockBg
        if (key === "clockBgOpacity") return root.clockBgOpacity
        if (key === "clockAccentBoost") return root.clockAccentBoost
        if (key === "mediaBg") return root.mediaBg
        if (key === "mediaBgOpacity") return root.mediaBgOpacity
        if (key === "weatherBg") return root.weatherBg
        if (key === "weatherBgOpacity") return root.weatherBgOpacity
        if (key === "profileName") return root.profileName
        if (key === "profileBio") return root.profileBio
        if (key === "profileImage") return root.profileImage
        if (key === "profileTikTok") return root.profileTikTok
        if (key === "profileSystem") return root.profileSystem
        if (key === "effectsEnabled") return root.effectsEnabled
        if (key === "motionStrength") return root.motionStrength
        if (key === "pywalActive") return root.pywalActive
        if (key === "pywalPollMs") return root.pywalPollMs
        if (key === "weatherCity") return root.weatherCity
        if (key === "searchEnabled") return root.searchEnabled
        if (key === "searchPanelWidth") return root.searchPanelWidth
        if (key === "searchMaxResults") return root.searchMaxResults
        if (key === "searchIconSize") return root.searchIconSize
        if (key === "searchOpacity") return root.searchOpacity
        if (key === "searchShowIcons") return root.searchShowIcons
        if (key === "searchCompact") return root.searchCompact
        if (key === "searchPosition") return root.searchPosition
        if (key === "clockStyle") return root.clockStyle
        if (key === "clockPopupStyle") return root.clockPopupStyle
        if (key === "clockShowSeconds") return root.clockShowSeconds
        if (key === "clockUse24h") return root.clockUse24h
        if (key === "clockShowDate") return root.clockShowDate
        if (key === "lockTheme") return root.lockTheme
        if (key === "lockEnabled") return root.lockEnabled
        if (key === "lockShowImage") return root.lockShowImage
        if (key === "lockShowDate") return root.lockShowDate
        if (key === "lockShowUser") return root.lockShowUser
        if (key === "lockClock24h") return root.lockClock24h
        if (key === "lockWallpaper") return root.lockWallpaper
        if (key === "lockImage") return root.lockImage
        if (key === "lockBlur") return root.lockBlur
        if (key === "lockDim") return root.lockDim
        if (key === "lockGlow") return root.lockGlow
        if (key === "lockPanelOpacity") return root.lockPanelOpacity
        if (key === "lockLineStyle") return root.lockLineStyle
        if (key === "lockAnimStyle") return root.lockAnimStyle
        if (key === "lockAnimStrength") return root.lockAnimStrength
        if (key === "mediaAlwaysVisible") return root.mediaAlwaysVisible
        if (key === "mediaShowVisualizer") return root.mediaShowVisualizer
        if (key === "mediaPanelWidth") return root.mediaPanelWidth
        if (key === "mediaPanelHeight") return root.mediaPanelHeight
        if (key === "wallpaperSelectorEnabled") return root.wallpaperSelectorEnabled
        if (key === "wallpaperModel") return root.wallpaperModel
        if (key === "wallpaperPanelPosition") return root.wallpaperPanelPosition
        if (key === "wallpaperOpenStyle") return root.wallpaperOpenStyle
        if (key === "wallpaperMoveStyle") return root.wallpaperMoveStyle
        if (key === "wallpaperTransition") return root.wallpaperTransition
        if (key === "wallpaperPanelThick") return root.wallpaperPanelThick
        if (key === "wallpaperPanelSpan") return root.wallpaperPanelSpan
        if (key === "wallpaperFillEdges") return root.wallpaperFillEdges
        if (key === "wallpaperApplyPywal") return root.wallpaperApplyPywal
        if (key === "animationSpeed") return root.animationSpeed
        if (key === "trailEnabled") return root.trailEnabled
        if (key === "glowStrength") return root.glowStrength
        if (key === "hoverScale") return root.hoverScale
        return ""
    }

    function toBool(value) {
        if (value === true || value === 1)
            return true
        if (value === false || value === 0)
            return false

        var s = ("" + value).toLowerCase()
        return s === "true" || s === "1" || s === "yes" || s === "on"
    }

    function clamp(v, mn, mx) {
        return Math.max(mn, Math.min(mx, v))
    }

    function motionDuration(ms) {
        var speed = root.animationSpeed > 0 ? root.animationSpeed : 100
        return Math.max(35, Math.round(ms * speed / 100 * root.motionStrength))
    }

    function anim(ms) {
        if (!root.effectsEnabled)
            return 0

        return root.motionDuration(ms)
    }

    function popupAnim(ms) {
        return root.motionDuration(ms)
    }

    function applyConfig() {
        ShinConfig.barH = root.barH
        ShinConfig.pillH = root.pillH
        ShinConfig.pillR = root.pillR
        ShinConfig.pillPadH = root.pillPadH
        ShinConfig.pillSpacing = root.pillSpacing
        ShinConfig.barMarginT = root.barMarginT
        ShinConfig.barMarginH = root.barMarginH
        ShinConfig.pillOpacity = root.pillOpacity
        ShinConfig.popupOpacity = root.popupOpacity
        ShinConfig.fontSize = root.fontSize
        ShinConfig.fontSizeSm = root.fontSizeSm
        ShinConfig.fontFamily = root.fontFamily
        ShinConfig.weatherCity = root.weatherCity
        ShinConfig.searchEnabled = root.searchEnabled
        ShinConfig.searchPanelWidth = root.searchPanelWidth
        ShinConfig.searchMaxResults = root.searchMaxResults
        ShinConfig.searchIconSize = root.searchIconSize
        ShinConfig.searchOpacity = root.searchOpacity
        ShinConfig.searchShowIcons = root.searchShowIcons
        ShinConfig.searchCompact = root.searchCompact
        ShinConfig.searchPosition = root.searchPosition
        ShinConfig.clockStyle = root.clockStyle
        ShinConfig.clockPopupStyle = root.clockPopupStyle
        ShinConfig.clockShowSeconds = root.clockShowSeconds
        ShinConfig.clockUse24h = root.clockUse24h
        ShinConfig.clockShowDate = root.clockShowDate
        ShinConfig.lockTheme = root.lockTheme
        ShinConfig.lockEnabled = root.lockEnabled
        ShinConfig.lockShowImage = root.lockShowImage
        ShinConfig.lockShowDate = root.lockShowDate
        ShinConfig.lockShowUser = root.lockShowUser
        ShinConfig.lockClock24h = root.lockClock24h
        ShinConfig.lockWallpaper = root.lockWallpaper
        ShinConfig.lockImage = root.lockImage
        ShinConfig.lockBlur = root.lockBlur
        ShinConfig.lockDim = root.lockDim
        ShinConfig.lockGlow = root.lockGlow
        ShinConfig.lockPanelOpacity = root.lockPanelOpacity
        ShinConfig.lockLineStyle = root.lockLineStyle
        ShinConfig.lockAnimStyle = root.lockAnimStyle
        ShinConfig.lockAnimStrength = root.lockAnimStrength
        ShinConfig.mediaAlwaysVisible = root.mediaAlwaysVisible
        ShinConfig.mediaShowVisualizer = root.mediaShowVisualizer
        ShinConfig.mediaPanelWidth = root.mediaPanelWidth
        ShinConfig.mediaPanelHeight = root.mediaPanelHeight
        ShinConfig.wallpaperSelectorEnabled = root.wallpaperSelectorEnabled
        ShinConfig.wallpaperModel = root.wallpaperModel
        ShinConfig.wallpaperPanelPosition = root.wallpaperPanelPosition
        ShinConfig.wallpaperOpenStyle = root.wallpaperOpenStyle
        ShinConfig.wallpaperMoveStyle = root.wallpaperMoveStyle
        ShinConfig.wallpaperTransition = root.wallpaperTransition
        ShinConfig.wallpaperPanelThick = root.wallpaperPanelThick
        ShinConfig.wallpaperPanelSpan = root.wallpaperPanelSpan
        ShinConfig.wallpaperFillEdges = root.wallpaperFillEdges
        ShinConfig.wallpaperApplyPywal = root.wallpaperApplyPywal
        ShinConfig.animationSpeed = root.animationSpeed
        ShinConfig.trailEnabled = root.trailEnabled
        ShinConfig.glowStrength = root.glowStrength
        ShinConfig.hoverScale = root.hoverScale
        ShinConfig.pywalPollMs = root.pywalPollMs
        ShinColors.pywalActive = root.pywalActive
    }

    function setValue(key, value) {
        if (key === "barH") root.barH = parseInt(value)
        else if (key === "pillH") root.pillH = parseInt(value)
        else if (key === "pillR") root.pillR = parseInt(value)
        else if (key === "pillPadH") root.pillPadH = parseInt(value)
        else if (key === "pillSpacing") root.pillSpacing = parseInt(value)
        else if (key === "barMarginT") root.barMarginT = parseInt(value)
        else if (key === "barMarginH") root.barMarginH = parseInt(value)
        else if (key === "fontSize") root.fontSize = parseInt(value)
        else if (key === "fontSizeSm") root.fontSizeSm = parseInt(value)
        else if (key === "pillOpacity") root.pillOpacity = Number(value)
        else if (key === "popupOpacity") root.popupOpacity = Number(value)
        else if (key === "fontFamily") root.fontFamily = value
        else if (key === "settingsCategory") root.settingsCategory = value
        else if (key === "clockBg") root.clockBg = value
        else if (key === "clockBgOpacity") root.clockBgOpacity = Number(value)
        else if (key === "clockAccentBoost") root.clockAccentBoost = Number(value)
        else if (key === "mediaBg") root.mediaBg = value
        else if (key === "mediaBgOpacity") root.mediaBgOpacity = Number(value)
        else if (key === "weatherBg") root.weatherBg = value
        else if (key === "weatherBgOpacity") root.weatherBgOpacity = Number(value)
        else if (key === "profileName") root.profileName = value
        else if (key === "profileBio") root.profileBio = value
        else if (key === "profileImage") root.profileImage = value
        else if (key === "profileTikTok") root.profileTikTok = value
        else if (key === "profileSystem") root.profileSystem = value
        else if (key === "effectsEnabled") root.effectsEnabled = root.toBool(value)
        else if (key === "motionStrength") root.motionStrength = Number(value)
        else if (key === "pywalActive") root.pywalActive = root.toBool(value)
        else if (key === "pywalPollMs") root.pywalPollMs = parseInt(value)
        else if (key === "weatherCity") root.weatherCity = value
        else if (key === "searchEnabled") root.searchEnabled = root.toBool(value)
        else if (key === "searchPanelWidth") root.searchPanelWidth = parseInt(value)
        else if (key === "searchMaxResults") root.searchMaxResults = parseInt(value)
        else if (key === "searchIconSize") root.searchIconSize = parseInt(value)
        else if (key === "searchOpacity") root.searchOpacity = Number(value)
        else if (key === "searchShowIcons") root.searchShowIcons = root.toBool(value)
        else if (key === "searchCompact") root.searchCompact = root.toBool(value)
        else if (key === "searchPosition") root.searchPosition = parseInt(value)
        else if (key === "clockStyle") root.clockStyle = parseInt(value)
        else if (key === "clockPopupStyle") root.clockPopupStyle = parseInt(value)
        else if (key === "clockShowSeconds") root.clockShowSeconds = root.toBool(value)
        else if (key === "clockUse24h") root.clockUse24h = root.toBool(value)
        else if (key === "clockShowDate") root.clockShowDate = root.toBool(value)
        else if (key === "lockTheme") root.lockTheme = parseInt(value)
        else if (key === "lockEnabled") root.lockEnabled = root.toBool(value)
        else if (key === "lockShowImage") root.lockShowImage = root.toBool(value)
        else if (key === "lockShowDate") root.lockShowDate = root.toBool(value)
        else if (key === "lockShowUser") root.lockShowUser = root.toBool(value)
        else if (key === "lockClock24h") root.lockClock24h = root.toBool(value)
        else if (key === "lockWallpaper") root.lockWallpaper = value
        else if (key === "lockImage") root.lockImage = value
        else if (key === "lockBlur") root.lockBlur = Number(value)
        else if (key === "lockDim") root.lockDim = Number(value)
        else if (key === "lockGlow") root.lockGlow = Number(value)
        else if (key === "lockPanelOpacity") root.lockPanelOpacity = Number(value)
        else if (key === "lockLineStyle") root.lockLineStyle = parseInt(value)
        else if (key === "lockAnimStyle") root.lockAnimStyle = parseInt(value)
        else if (key === "lockAnimStrength") root.lockAnimStrength = Number(value)
        else if (key === "mediaAlwaysVisible") root.mediaAlwaysVisible = root.toBool(value)
        else if (key === "mediaShowVisualizer") root.mediaShowVisualizer = root.toBool(value)
        else if (key === "mediaPanelWidth") root.mediaPanelWidth = parseInt(value)
        else if (key === "mediaPanelHeight") root.mediaPanelHeight = parseInt(value)
        else if (key === "wallpaperSelectorEnabled") root.wallpaperSelectorEnabled = root.toBool(value)
        else if (key === "wallpaperModel") root.wallpaperModel = parseInt(value)
        else if (key === "wallpaperPanelPosition") root.wallpaperPanelPosition = parseInt(value)
        else if (key === "wallpaperOpenStyle") root.wallpaperOpenStyle = parseInt(value)
        else if (key === "wallpaperMoveStyle") root.wallpaperMoveStyle = parseInt(value)
        else if (key === "wallpaperTransition") root.wallpaperTransition = parseInt(value)
        else if (key === "wallpaperPanelThick") root.wallpaperPanelThick = parseInt(value)
        else if (key === "wallpaperPanelSpan") root.wallpaperPanelSpan = Number(value)
        else if (key === "wallpaperFillEdges") root.wallpaperFillEdges = root.toBool(value)
        else if (key === "wallpaperApplyPywal") root.wallpaperApplyPywal = root.toBool(value)
        else if (key === "animationSpeed") root.animationSpeed = parseInt(value)
        else if (key === "trailEnabled") root.trailEnabled = root.toBool(value)
        else if (key === "glowStrength") root.glowStrength = Number(value)
        else if (key === "hoverScale") root.hoverScale = Number(value)

        root.applyConfig()
    }

    function save(key, value) {
        root.setValue(key, value)

        var q = root.saveQueue.slice()
        q.push({ key: key, value: value })
        root.saveQueue = q
        root.flushSave()
    }

    function saveAll() {
        if (!root.loaded)
            return

        root.applyConfig()

        var q = root.saveQueue.slice()
        for (var i = 0; i < root.configKeys.length; ++i) {
            var key = root.configKeys[i]
            q.push({ key: key, value: root.valueForKey(key) })
        }
        root.saveQueue = q
        root.flushSave()
    }

    function flushSave() {
        if (saveProc.running || root.saveQueue.length === 0)
            return

        var q = root.saveQueue.slice()
        var item = q.shift()
        root.saveQueue = q

        saveProc.command = [
            "/home/shira/.config/quickshell/shinbar/scripts/shinbar-data",
            "set",
            item.key,
            root.stringify(item.value)
        ]

        saveProc.running = true
    }

    function reload() {
        if (!loadProc.running) {
            root.loaded = false
            loadProc.running = true
        }
    }

    property Process loadProc: Process {
        running: false
        command: ["/home/shira/.config/quickshell/shinbar/scripts/shinbar-data", "get"]

        stdout: SplitParser {
            onRead: function(data) {
                var line = data.trim()
                if (!line || line.indexOf("=") < 0)
                    return

                var idx = line.indexOf("=")
                var key = line.slice(0, idx)
                var value = line.slice(idx + 1)

                root.setValue(key, value)
            }
        }

        onExited: {
            running = false
            root.loaded = true
            root.applyConfig()
        }
    }

    property Process saveProc: Process {
        running: false
        command: ["bash", "-lc", "true"]
        onExited: {
            running = false
            root.flushSave()
        }
    }

    Component.onCompleted: root.reload()
}
