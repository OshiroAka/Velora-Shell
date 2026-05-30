import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Services.UPower

Item {
    id: bar

    focus: wallpaperListOpen || appSearchOpen

    Keys.priority: Keys.BeforeItem
    Keys.onEscapePressed: function(event) {
        if (appSearchOpen) {
            appSearchOpen = false
            event.accepted = true
            return
        }

        if (!wallpaperListOpen)
            return

        wallpaperListOpen = false
        event.accepted = true
    }
    Keys.onUpPressed: function(event) {
        if (appSearchOpen) {
            stepAppSearch(-1)
            event.accepted = true
            return
        }

        if (!wallpaperListOpen)
            return

        stepWallpaperList(-1)
        event.accepted = true
    }
    Keys.onDownPressed: function(event) {
        if (appSearchOpen) {
            stepAppSearch(1)
            event.accepted = true
            return
        }

        if (!wallpaperListOpen)
            return

        stepWallpaperList(1)
        event.accepted = true
    }
    Keys.onLeftPressed: function(event) {
        if (!wallpaperListOpen)
            return

        stepWallpaperCategory(-1)
        event.accepted = true
    }
    Keys.onRightPressed: function(event) {
        if (!wallpaperListOpen)
            return

        stepWallpaperCategory(1)
        event.accepted = true
    }
    Keys.onReturnPressed: function(event) {
        if (appSearchOpen) {
            launchSelectedAppSearchEntry()
            event.accepted = true
            return
        }

        if (!wallpaperListOpen)
            return

        applySelectedWallpaper()
        event.accepted = true
    }
    Keys.onEnterPressed: function(event) {
        if (appSearchOpen) {
            launchSelectedAppSearchEntry()
            event.accepted = true
            return
        }

        if (!wallpaperListOpen)
            return

        applySelectedWallpaper()
        event.accepted = true
    }

    property int cornerRadius: 18
    property string clockText: Qt.formatDateTime(new Date(), "HH:mm")
    property var batteryDevice: null
    property int volume: 70
    property bool muted: false
    property var mediaPlayer: pickMediaPlayer()
    property real mediaPosition: 0
    property bool cavaReady: false
    property bool launcherOpen: false
    property bool launcherMounted: false
    property real launcherReveal: launcherOpen ? 1.0 : 0.0
    property bool themesOpen: false
    property bool themesMounted: false
    property real themeReveal: themesOpen ? 1.0 : 0.0
    property bool themeSettingsOpen: false
    property bool wallpaperListOpen: false
    property bool wallpaperListMounted: false
    property real wallpaperListReveal: wallpaperListOpen ? 1.0 : 0.0
    property bool appSearchOpen: false
    property bool appSearchMounted: false
    property real appSearchReveal: appSearchOpen ? 1.0 : 0.0
    property bool musicOpen: false
    property bool musicMounted: false
    property real musicReveal: musicOpen ? 1.0 : 0.0
    property bool profileOpen: false
    property bool profileMounted: false
    property bool profileHovered: false
    property bool profilePopupHovered: false
    property bool launcherHovering: false
    property bool themesHovering: false
    property bool wallpapersScanning: false
    property bool autoThemeSwitch: false
    property int mediaVersion: 0
    property int wallpaperPage: 0
    property int wallpaperListIndex: 0
    property real wallpaperListSlideOffset: 0.0
    property real wallpaperListSlideOpacity: 1.0
    property real wallpaperPageOffset: 0.0
    property real wallpaperPageOpacity: 1.0
    property real profilePulse: 0.0
    property real profileIntroAvatar: 1.0
    property real profileIntroText: 1.0
    property real profileIntroStats: 1.0
    property real profileIntroActions: 1.0
    property string launcherQuery: ""
    property string appSearchQuery: ""
    property string appSearchMode: "all"
    property string pendingCommand: ""
    property string pendingWallpaperKey: ""
    property string themeMode: "dark"
    property string wallpaperCategory: "static"
    property string wallpaperTransitionType: "fade"
    property string currentWallpaperKey: ""
    property real interfaceOpacity: 0.46
    property real wallpaperTransitionDuration: 1.0
    property real musicOriginX: 188
    property real musicOriginY: 140
    property real musicOriginW: 84
    property real musicOriginH: 80
    property bool pywalAccentEnabled: true
    property color pywalAccentChoice: Qt.rgba(0.61, 0.82, 1.0, 0.96)
    property color manualAccentChoice: Qt.rgba(0.61, 0.82, 1.0, 0.96)
    property color accentChoice: pywalAccentEnabled ? pywalAccentChoice : manualAccentChoice
    property var cavaBars: [0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08]
    property var wallpaperEntries: []
    property var wallpaperFiltered: []
    property var appSearchResults: []
    property int appSearchIndex: 0
    property bool settingsLoaded: false
    property var settingsSaveQueue: []
    readonly property int shellBaseWidth: 70
    readonly property int screenWidth: Screen.width
    readonly property int screenHeight: Screen.height
    readonly property int railWidth: 52
    readonly property int launcherMainWidth: 322
    readonly property int launcherDrawerHeight: 560
    readonly property bool launcherDrawerVisible: launcherOpen || launcherMounted
    readonly property int launcherAnimatedWidth: launcherDrawerVisible ? Math.max(0, Math.round(launcherMainWidth * launcherReveal)) : 0
    readonly property bool launcherSurfaceActive: launcherDrawerVisible && launcherAnimatedWidth > 1
    readonly property int themeMainWidth: 322
    readonly property int themeSettingsWidth: 206
    readonly property int themeDrawerHeight: 486
    readonly property bool themeDrawerVisible: themesOpen || themesMounted
    readonly property int themeDrawerWidth: themeSettingsOpen ? themeMainWidth + themeSettingsWidth : themeMainWidth
    readonly property int themeAnimatedWidth: themeDrawerVisible ? Math.max(0, Math.round(themeDrawerWidth * themeReveal)) : 0
    readonly property bool themeSurfaceActive: themeDrawerVisible && themeAnimatedWidth > 1
    readonly property bool drawerSurfaceActive: themeSurfaceActive || launcherSurfaceActive
    readonly property bool wantsKeyboardFocus: launcherOpen || wallpaperListOpen || appSearchOpen
    readonly property int wallpaperListPanelWidth: 240
    readonly property int wallpaperListEdgeCompensation: 22
    readonly property int wallpaperListCardHeight: 126
    readonly property int wallpaperListCardSpacing: 9
    readonly property int appSearchPanelWidth: Math.min(700, Math.max(520, screenWidth - 220))
    readonly property int appSearchPanelHeight: Math.min(420, Math.max(320, screenHeight - 220))
    readonly property int activeDrawerWidth: themeSurfaceActive ? themeAnimatedWidth : launcherSurfaceActive ? launcherAnimatedWidth : 0
    readonly property int activeDrawerHeight: themeSurfaceActive ? themeDrawerHeight : launcherSurfaceActive ? launcherDrawerHeight : 0
    readonly property int desiredShellWidth: (wallpaperListOpen || wallpaperListMounted) ? screenWidth : shellBaseWidth + themeMainWidth + themeSettingsWidth
    property alias railMaskItem: surface
    property alias drawerMaskItem: themeMaskRegion
    property alias wallpaperListMaskItem: wallpaperListInputRegion
    property alias appSearchMaskItem: appSearchInputRegion
    readonly property int notificationCount: Number(NotificationServer.trackedCount || 0)
    readonly property int batteryPercent: batteryDevice && batteryDevice.ready ? Math.round(batteryDevice.percentage) : 100
    readonly property real batteryFill: Math.max(0.08, Math.min(1, batteryPercent / 100))
    readonly property bool mediaAvailable: mediaPlayer !== null
    readonly property bool mediaPlaying: mediaPlayer ? mediaPlayer.isPlaying : false
    readonly property bool mediaShuffle: Boolean(mediaPlayer && mediaPlayer.shuffleSupported && mediaPlayer.shuffle)
    readonly property bool mediaRepeat: Boolean(mediaPlayer && mediaPlayer.loopSupported && mediaPlayer.loopState !== MprisLoopState.None)
    readonly property real mediaLength: mediaPlayer && mediaPlayer.length > 0 ? mediaPlayer.length : 0
    readonly property real mediaProgress: mediaLength > 0 ? clamp01(mediaPosition / mediaLength) : 0.38
    readonly property string mediaTitle: mediaPlayer && textOf(mediaPlayer.trackTitle).length > 0 ? textOf(mediaPlayer.trackTitle) : "FOCO"
    readonly property string mediaArtist: mediaPlayer && textOf(mediaPlayer.trackArtist).length > 0 ? textOf(mediaPlayer.trackArtist) : (mediaPlayer ? "Player ativo" : "Mente leve")
    readonly property string mediaAlbum: mediaPlayer && textOf(mediaPlayer.trackAlbum).length > 0 ? textOf(mediaPlayer.trackAlbum) : (mediaPlayer ? textOf(mediaPlayer.identity) : "Spotify")
    readonly property string mediaArtUrl: mediaPlayer ? textOf(mediaPlayer.trackArtUrl) : ""
    readonly property var musicQueueEntries: buildMusicQueue(mediaVersion, mediaTitle, mediaArtist, mediaAlbum, mediaArtUrl)
    readonly property int wallpaperPageSize: 3
    readonly property int wallpaperPageCount: Math.max(1, Math.ceil(wallpaperFiltered.length / wallpaperPageSize))
    readonly property var wallpaperPageItems: wallpaperFiltered.slice(
        wallpaperPage * wallpaperPageSize,
        Math.min(wallpaperFiltered.length, (wallpaperPage + 1) * wallpaperPageSize)
    )

    readonly property bool lightTheme: themeMode === "light"
    readonly property bool amoledTheme: themeMode === "amoled"
    readonly property bool blueTheme: themeMode === "blue"
    readonly property color panelBase: lightTheme
        ? Qt.rgba(0.91, 0.94, 0.96, Math.max(0.58, interfaceOpacity + 0.12))
        : amoledTheme
            ? Qt.rgba(0.0, 0.0, 0.0, Math.max(0.60, interfaceOpacity + 0.18))
            : blueTheme
                ? Qt.rgba(0.025, 0.050, 0.085, Math.max(0.42, interfaceOpacity))
                : Qt.rgba(0.025, 0.045, 0.060, interfaceOpacity)
    readonly property color joinedPanelBase: lightTheme
        ? Qt.rgba(0.82, 0.86, 0.89, Math.max(0.70, interfaceOpacity + 0.20))
        : amoledTheme
            ? Qt.rgba(0.0, 0.0, 0.0, Math.max(0.76, interfaceOpacity + 0.28))
            : blueTheme
                ? Qt.rgba(0.010, 0.020, 0.032, Math.max(0.80, interfaceOpacity + 0.34))
                : Qt.rgba(0.010, 0.014, 0.017, Math.max(0.82, interfaceOpacity + 0.36))
    readonly property color activePanelBase: panelBase
    readonly property color panelSoft: lightTheme ? Qt.rgba(0.82, 0.87, 0.92, 0.56) : Qt.rgba(0.055, 0.080, 0.105, 0.38)
    readonly property color panelHover: lightTheme ? Qt.rgba(0.74, 0.82, 0.90, 0.68) : Qt.rgba(0.075, 0.115, 0.150, 0.58)
    readonly property color line: lightTheme ? Qt.rgba(0.22, 0.32, 0.42, 0.24) : Qt.rgba(0.54, 0.69, 0.84, 0.22)
    readonly property color lineStrong: accentChoice
    readonly property color text: lightTheme ? Qt.rgba(0.08, 0.12, 0.17, 0.92) : Qt.rgba(0.86, 0.94, 1.0, 0.92)
    readonly property color dimText: lightTheme ? Qt.rgba(0.18, 0.25, 0.34, 0.58) : Qt.rgba(0.54, 0.64, 0.76, 0.55)
    readonly property color accent: accentChoice
    readonly property color warning: Qt.rgba(1.0, 0.45, 0.43, 0.95)
    property real profileReveal: profileOpen ? 1.0 : 0.0
    readonly property string profileName: "Hatsune Miku"
    readonly property string profileBio: "Living in pixels."
    readonly property string profileEmail: "hatsune@miku.com"
    readonly property string profilePlan: "Pro Plan"
    readonly property string profileSource: "file:///home/shira/.face"

    readonly property string paletteCommand: "if command -v nwg-look >/dev/null 2>&1; then nwg-look; elif command -v qt6ct >/dev/null 2>&1; then qt6ct; elif command -v qt5ct >/dev/null 2>&1; then qt5ct; else pkill wofi 2>/dev/null; wofi --show drun --prompt Tema & fi"
    readonly property string searchCommand: "pkill wofi 2>/dev/null; wofi --show drun --prompt Buscar &"
    readonly property string filesCommand: "if command -v dolphin >/dev/null 2>&1; then dolphin \"$HOME\"; elif command -v thunar >/dev/null 2>&1; then thunar \"$HOME\"; else xdg-open \"$HOME\"; fi"
    readonly property string appsCommand: "pkill wofi 2>/dev/null; wofi --show drun &"
    readonly property string browserCommand: "if command -v zen-browser >/dev/null 2>&1; then zen-browser; elif command -v zen >/dev/null 2>&1; then zen; elif command -v firefox >/dev/null 2>&1; then firefox; elif command -v chromium >/dev/null 2>&1; then chromium; else xdg-open https://www.google.com; fi"
    readonly property string documentsCommand: "xdg-open \"$HOME/Documentos\" 2>/dev/null || xdg-open \"$HOME/Documents\" 2>/dev/null || xdg-open \"$HOME\""
    readonly property string musicCommand: "if command -v spotify >/dev/null 2>&1; then spotify; else xdg-open \"$HOME/Música\" 2>/dev/null || xdg-open \"$HOME/Music\" 2>/dev/null || xdg-open \"$HOME\"; fi"
    readonly property string downloadsCommand: "xdg-open \"$HOME/Downloads\" 2>/dev/null || xdg-open \"$HOME/Transferências\" 2>/dev/null || xdg-open \"$HOME\""
    readonly property string trashCommand: "gio open trash:/// 2>/dev/null || xdg-open trash:/// 2>/dev/null || true"
    readonly property string homeCommand: "xdg-open \"$HOME\""
    readonly property string desktopCommand: "xdg-open \"$HOME/Desktop\" 2>/dev/null || xdg-open \"$HOME/Área de Trabalho\" 2>/dev/null || xdg-open \"$HOME\""
    readonly property string picturesCommand: "xdg-open \"$HOME/Pictures\" 2>/dev/null || xdg-open \"$HOME/Imagens\" 2>/dev/null || xdg-open \"$HOME\""
    readonly property string wallpapersCommand: "xdg-open \"$HOME/Pictures/Wallpapers\" 2>/dev/null || xdg-open \"$HOME/Imagens/Wallpapers\" 2>/dev/null || xdg-open \"$HOME/Pictures\" 2>/dev/null || xdg-open \"$HOME\""
    readonly property string terminalCommand: "if command -v kitty >/dev/null 2>&1; then kitty; elif command -v foot >/dev/null 2>&1; then foot; elif command -v alacritty >/dev/null 2>&1; then alacritty; elif command -v wezterm >/dev/null 2>&1; then wezterm; else xterm; fi"
    readonly property string settingsCommand: "if command -v systemsettings >/dev/null 2>&1; then systemsettings; elif command -v gnome-control-center >/dev/null 2>&1; then gnome-control-center; elif command -v nwg-look >/dev/null 2>&1; then nwg-look; else pkill wofi 2>/dev/null; wofi --show drun --prompt Config & fi"
    readonly property string muteCommand: "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    readonly property string cavaCommand: "/home/shira/.config/quickshell/testebar/scripts/testebar-cava 10"
    readonly property string pywalAccentCommand: "/home/shira/.config/quickshell/testebar/scripts/testebar-pywal-accent"
    readonly property string wallpaperScanCommand: "/home/shira/.config/quickshell/testebar/scripts/testebar-wallpaper-scan"
    readonly property string wallpaperApplyCommand: "/home/shira/.config/quickshell/testebar/scripts/testebar-wallpaper-apply"
    readonly property string settingsDataCommand: "/home/shira/.config/quickshell/testebar/scripts/testebar-data"
    readonly property var settingsKeys: [
        "themeMode",
        "wallpaperCategory",
        "wallpaperTransitionType",
        "wallpaperTransitionDuration",
        "interfaceOpacity",
        "autoThemeSwitch",
        "pywalAccentEnabled",
        "manualAccentChoice",
        "currentWallpaperKey"
    ]
    readonly property var themeModes: [
        { "key": "dark", "label": "Dark", "icon": "moon" },
        { "key": "light", "label": "Light", "icon": "sun" },
        { "key": "blue", "label": "Blue", "icon": "drop" },
        { "key": "amoled", "label": "AMOLED", "icon": "circle" }
    ]
    readonly property var accentChoices: [
        pywalAccentChoice,
        Qt.rgba(0.28, 0.74, 0.68, 0.96),
        Qt.rgba(0.62, 0.38, 0.80, 0.96),
        Qt.rgba(0.82, 0.34, 0.58, 0.96),
        Qt.rgba(0.92, 0.64, 0.04, 0.96),
        Qt.rgba(0.45, 0.52, 0.60, 0.96)
    ]
    readonly property var wallpaperCategories: [
        { "key": "static", "label": "Static" },
        { "key": "live", "label": "MPV" },
        { "key": "engine", "label": "Engine" }
    ]
    readonly property var wallpaperTransitions: [
        { "key": "fade", "label": "Fade" },
        { "key": "wave", "label": "Wave" },
        { "key": "wipe", "label": "Wipe" },
        { "key": "grow", "label": "Grow" },
        { "key": "outer", "label": "Outer" },
        { "key": "random", "label": "Random" }
    ]
    readonly property var appSearchTabs: [
        { "key": "all", "label": "All", "icon": "grid" },
        { "key": "apps", "label": "Apps", "icon": "grid" },
        { "key": "files", "label": "Files", "icon": "folder" },
        { "key": "settings", "label": "Settings", "icon": "settings" },
        { "key": "web", "label": "Web", "icon": "browser" }
    ]
    readonly property real wallpaperTransitionSpeedRatio: clamp01((3.0 - wallpaperTransitionDuration) / 2.75)
    readonly property var launcherTiles: [
        { "icon": "folder", "label": "Files", "command": filesCommand },
        { "icon": "browser", "label": "Browser", "command": browserCommand },
        { "icon": "terminal", "label": "Terminal", "command": terminalCommand },
        { "icon": "document", "label": "Documents", "command": documentsCommand },
        { "icon": "settings", "label": "Settings", "command": settingsCommand },
        { "icon": "music", "label": "Music", "command": musicCommand },
        { "icon": "palette", "label": "Themes", "command": "" },
        { "icon": "download", "label": "Downloads", "command": downloadsCommand },
        { "icon": "trash", "label": "Trash", "command": trashCommand }
    ]
    readonly property var quickLinks: [
        { "icon": "home", "label": "Home", "command": homeCommand },
        { "icon": "desktop", "label": "Desktop", "command": desktopCommand },
        { "icon": "image", "label": "Pictures", "command": picturesCommand },
        { "icon": "image", "label": "Wallpapers", "command": wallpapersCommand }
    ]
    readonly property var profileActions: [
        { "icon": "user", "label": "Account", "sub": "Local session", "command": settingsCommand, "kind": "command" },
        { "icon": "palette", "label": "Personalization", "sub": "Themes and wallpapers", "command": "", "kind": "themes" },
        { "icon": "activity", "label": "Activity", "sub": "Open launcher", "command": "", "kind": "launcher" },
        { "icon": "star", "label": "Favorites", "sub": "Home folder", "command": homeCommand, "kind": "command" },
        { "icon": "download", "label": "Downloads", "sub": "Recent files", "command": downloadsCommand, "kind": "command" },
        { "icon": "logout", "label": "Logout", "sub": "Session action", "command": "", "kind": "logout" }
    ]

    onLauncherOpenChanged: {
        if (launcherOpen) {
            launcherCloseTimer.stop()
            launcherMounted = true
        } else {
            launcherCloseTimer.restart()
        }
    }

    onThemesOpenChanged: {
        if (themesOpen) {
            themesCloseTimer.stop()
            themesMounted = true
        } else {
            themesCloseTimer.restart()
        }
    }

    onWallpaperListOpenChanged: {
        if (wallpaperListOpen) {
            wallpaperListCloseTimer.stop()
            wallpaperListMounted = true
            syncWallpaperListIndexToCurrent()
            clampWallpaperListIndex()
            bar.forceActiveFocus()
            wallpaperKeyboardFocusTimer.restart()
            wallpaperListFocusTimer.restart()
        } else {
            wallpaperListCloseTimer.restart()
        }
    }

    onAppSearchOpenChanged: {
        if (appSearchOpen) {
            appSearchCloseTimer.stop()
            appSearchMounted = true
            rebuildAppSearch()
            appSearchFocusTimer.restart()
        } else {
            appSearchCloseTimer.restart()
        }
    }

    onMusicOpenChanged: {
        if (musicOpen) {
            musicCloseTimer.stop()
            musicMounted = true
        } else {
            musicCloseTimer.restart()
        }
    }

    onProfileOpenChanged: {
        if (profileOpen) {
            profileCloseTimer.stop()
            profileMounted = true
            profilePulseAnim.restart()
            profileAvatarIntroAnim.restart()
            profileTextIntroAnim.restart()
            profileStatsIntroAnim.restart()
            profileActionsIntroAnim.restart()
        } else {
            profileCloseTimer.restart()
        }
    }

    Behavior on profileReveal {
        NumberAnimation { duration: 290; easing.type: Easing.OutBack; easing.overshoot: 1.04 }
    }

    Behavior on launcherReveal {
        NumberAnimation { duration: 300; easing.type: Easing.InOutCubic }
    }

    Behavior on themeReveal {
        NumberAnimation { duration: 300; easing.type: Easing.InOutCubic }
    }

    Behavior on wallpaperListReveal {
        NumberAnimation { duration: 260; easing.type: Easing.InOutCubic }
    }

    Behavior on appSearchReveal {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: wallpaperListCategorySlideAnim

        NumberAnimation {
            target: bar
            property: "wallpaperListSlideOffset"
            to: 0.0
            duration: 250
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: bar
            property: "wallpaperListSlideOpacity"
            to: 1.0
            duration: 210
            easing.type: Easing.OutCubic
        }
    }

    Behavior on musicReveal {
        NumberAnimation { duration: 240; easing.type: Easing.InOutCubic }
    }

    SequentialAnimation {
        id: profilePulseAnim

        NumberAnimation { target: bar; property: "profilePulse"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
        NumberAnimation { target: bar; property: "profilePulse"; from: 1.0; to: 0.0; duration: 420; easing.type: Easing.OutCubic }
    }

    SequentialAnimation {
        id: profileAvatarIntroAnim

        ScriptAction { script: bar.profileIntroAvatar = 0.0 }
        PauseAnimation { duration: 55 }
        NumberAnimation { target: bar; property: "profileIntroAvatar"; from: 0.0; to: 1.0; duration: 340; easing.type: Easing.OutCubic }
    }

    SequentialAnimation {
        id: profileTextIntroAnim

        ScriptAction { script: bar.profileIntroText = 0.0 }
        PauseAnimation { duration: 120 }
        NumberAnimation { target: bar; property: "profileIntroText"; from: 0.0; to: 1.0; duration: 360; easing.type: Easing.OutCubic }
    }

    SequentialAnimation {
        id: profileStatsIntroAnim

        ScriptAction { script: bar.profileIntroStats = 0.0 }
        PauseAnimation { duration: 180 }
        NumberAnimation { target: bar; property: "profileIntroStats"; from: 0.0; to: 1.0; duration: 390; easing.type: Easing.OutCubic }
    }

    SequentialAnimation {
        id: profileActionsIntroAnim

        ScriptAction { script: bar.profileIntroActions = 0.0 }
        PauseAnimation { duration: 240 }
        NumberAnimation { target: bar; property: "profileIntroActions"; from: 0.0; to: 1.0; duration: 430; easing.type: Easing.OutCubic }
    }

    SequentialAnimation {
        id: wallpaperSlideAnim

        ParallelAnimation {
            NumberAnimation { target: bar; property: "wallpaperPageOffset"; to: 0.0; duration: 240; easing.type: Easing.OutCubic }
            NumberAnimation { target: bar; property: "wallpaperPageOpacity"; to: 1.0; duration: 190; easing.type: Easing.OutCubic }
        }
    }

    Timer {
        id: launcherCloseTimer

        interval: 330
        repeat: false
        onTriggered: {
            if (!bar.launcherOpen)
                bar.launcherMounted = false
        }
    }

    Timer {
        id: themesCloseTimer

        interval: 330
        repeat: false
        onTriggered: {
            if (!bar.themesOpen) {
                bar.themesMounted = false
                bar.themeSettingsOpen = false
            }
        }
    }

    Timer {
        id: wallpaperListCloseTimer

        interval: 290
        repeat: false
        onTriggered: {
            if (!bar.wallpaperListOpen)
                bar.wallpaperListMounted = false
        }
    }

    Timer {
        id: wallpaperKeyboardFocusTimer

        interval: 140
        repeat: false
        onTriggered: {
            if (bar.wallpaperListOpen)
                bar.forceActiveFocus()
        }
    }

    Timer {
        id: appSearchCloseTimer

        interval: 260
        repeat: false
        onTriggered: {
            if (!bar.appSearchOpen)
                bar.appSearchMounted = false
        }
    }

    Timer {
        id: appSearchFocusTimer

        interval: 90
        repeat: false
        onTriggered: {
            if (bar.appSearchOpen)
                appSearchField.forceActiveFocus()
        }
    }

    Timer {
        id: musicCloseTimer

        interval: 260
        repeat: false
        onTriggered: {
            if (!bar.musicOpen)
                bar.musicMounted = false
        }
    }

    Timer {
        id: profileCloseTimer

        interval: 290
        repeat: false
        onTriggered: {
            if (!bar.profileOpen)
                bar.profileMounted = false
        }
    }

    Timer {
        id: launcherHoverCloseTimer

        interval: 280
        repeat: false
        onTriggered: {
            if (!bar.launcherHovering && bar.launcherOpen)
                bar.launcherOpen = false
        }
    }

    Timer {
        id: themesHoverCloseTimer

        interval: 280
        repeat: false
        onTriggered: {
            if (!bar.themesHovering && bar.themesOpen && !bar.wallpaperListOpen)
                bar.themesOpen = false
        }
    }

    Timer {
        id: profileHoverCloseTimer

        interval: 260
        repeat: false
        onTriggered: {
            if (!bar.profileHovered && !bar.profilePopupHovered && bar.profileOpen)
                bar.profileOpen = false
        }
    }

    IpcHandler {
        target: "testebar"

        function launcher(): void {
            bar.openLauncher()
        }

        function toggleLauncher(): void {
            if (!bar.launcherOpen) {
                bar.themesOpen = false
                bar.musicOpen = false
                bar.profileOpen = false
            }
            bar.launcherOpen = !bar.launcherOpen
        }

        function closeLauncher(): void {
            bar.launcherOpen = false
        }

        function search(): void {
            bar.openAppSearch()
        }

        function toggleSearch(): void {
            bar.toggleAppSearch()
        }

        function closeSearch(): void {
            bar.appSearchOpen = false
        }

        function themes(): void {
            bar.openThemes()
        }

        function toggleThemes(): void {
            bar.toggleThemes()
        }

        function closeThemes(): void {
            bar.themesOpen = false
            bar.wallpaperListOpen = false
        }

        function wallpapers(): void {
            bar.toggleWallpaperList()
        }

        function closeWallpapers(): void {
            bar.wallpaperListOpen = false
        }

        function music(): void {
            bar.openMusic()
        }

        function closeMusic(): void {
            bar.musicOpen = false
        }

        function profile(): void {
            bar.openProfile()
        }

        function toggleProfile(): void {
            bar.toggleProfile()
        }

        function closeProfile(): void {
            bar.profileOpen = false
        }
    }

    function clamp01(v) {
        return Math.max(0, Math.min(1, Number(v) || 0))
    }

    function textOf(v) {
        return v === undefined || v === null ? "" : String(v)
    }

    function boolOf(v) {
        if (v === true || v === 1)
            return true
        if (v === false || v === 0)
            return false

        var s = textOf(v).toLowerCase()
        return s === "true" || s === "1" || s === "yes" || s === "on"
    }

    function channelHex(v) {
        var n = Math.max(0, Math.min(255, Math.round(Number(v) * 255)))
        var h = n.toString(16)
        return h.length < 2 ? "0" + h : h
    }

    function colorToHex(c) {
        return "#" + channelHex(c.r) + channelHex(c.g) + channelHex(c.b)
    }

    function stringifySetting(value) {
        if (value === true)
            return "true"
        if (value === false)
            return "false"
        return textOf(value)
    }

    function valueForSetting(key) {
        if (key === "themeMode") return themeMode
        if (key === "wallpaperCategory") return wallpaperCategory
        if (key === "wallpaperTransitionType") return wallpaperTransitionType
        if (key === "wallpaperTransitionDuration") return wallpaperTransitionDuration
        if (key === "interfaceOpacity") return interfaceOpacity
        if (key === "autoThemeSwitch") return autoThemeSwitch
        if (key === "pywalAccentEnabled") return pywalAccentEnabled
        if (key === "manualAccentChoice") return colorToHex(manualAccentChoice)
        if (key === "currentWallpaperKey") return currentWallpaperKey
        return ""
    }

    function setPersistedValue(key, value) {
        if (key === "themeMode") {
            themeMode = textOf(value)
        } else if (key === "wallpaperCategory") {
            wallpaperCategory = textOf(value)
            refreshWallpapers()
        } else if (key === "wallpaperTransitionType") {
            wallpaperTransitionType = textOf(value)
        } else if (key === "wallpaperTransitionDuration") {
            wallpaperTransitionDuration = Math.max(0.25, Math.min(3.0, Number(value) || 1.0))
        } else if (key === "interfaceOpacity") {
            interfaceOpacity = Math.max(0.25, Math.min(0.80, Number(value) || 0.46))
        } else if (key === "autoThemeSwitch") {
            autoThemeSwitch = boolOf(value)
        } else if (key === "pywalAccentEnabled") {
            pywalAccentEnabled = boolOf(value)
        } else if (key === "manualAccentChoice") {
            manualAccentChoice = colorFromHex(textOf(value), manualAccentChoice)
        } else if (key === "currentWallpaperKey") {
            currentWallpaperKey = textOf(value)
        }
    }

    function saveSetting(key, value) {
        setPersistedValue(key, value)

        if (!settingsLoaded)
            return

        var q = []
        for (var i = 0; i < settingsSaveQueue.length; i += 1) {
            if (settingsSaveQueue[i].key !== key)
                q.push(settingsSaveQueue[i])
        }
        q.push({ "key": key, "value": stringifySetting(value) })
        settingsSaveQueue = q
        flushSettingsSave()
    }

    function saveAllSettings() {
        if (!settingsLoaded)
            return

        var q = settingsSaveQueue.slice()
        for (var i = 0; i < settingsKeys.length; i += 1) {
            var key = settingsKeys[i]
            q.push({ "key": key, "value": stringifySetting(valueForSetting(key)) })
        }
        settingsSaveQueue = q
        flushSettingsSave()
    }

    function flushSettingsSave() {
        if (settingsSaveProcess.running || settingsSaveQueue.length === 0)
            return

        var q = settingsSaveQueue.slice()
        var item = q.shift()
        settingsSaveQueue = q
        settingsSaveProcess.command = [settingsDataCommand, "set", item.key, item.value]
        settingsSaveProcess.running = true
    }

    function mediaKey(p) {
        if (!p)
            return ""

        return (textOf(p.identity)
            + " " + textOf(p.desktopEntry)
            + " " + textOf(p.busName)
            + " " + textOf(p.service)
            + " " + textOf(p.name)
            + " " + textOf(p.trackTitle)
            + " " + textOf(p.trackArtist)).toLowerCase()
    }

    function mediaScore(p) {
        if (!p)
            return -9999

        var key = mediaKey(p)
        var title = textOf(p.trackTitle).toLowerCase()
        var artist = textOf(p.trackArtist).toLowerCase()
        var art = textOf(p.trackArtUrl)
        var score = 0

        if (p.isPlaying)
            score += 150
        if (art.length > 0)
            score += 80
        if (artist.length > 0)
            score += 45
        if (title.length > 0)
            score += 35
        if (key.indexOf("spotify") >= 0)
            score += 90
        if (key.indexOf("whatsapp") >= 0)
            score -= 300

        return score
    }

    function pickMediaPlayer() {
        var list = Mpris.players.values
        if (!list || list.length === 0)
            return null

        var best = list[0]
        var bestScore = mediaScore(best)

        for (var i = 1; i < list.length; i += 1) {
            var score = mediaScore(list[i])
            if (score > bestScore) {
                best = list[i]
                bestScore = score
            }
        }

        return best
    }

    function mediaArtSource() {
        if (mediaArtUrl.length === 0)
            return ""
        if (mediaArtUrl.indexOf("/") === 0)
            return "file://" + mediaArtUrl
        return mediaArtUrl
    }

    function musicArtSource(url) {
        var art = textOf(url)
        if (art.length === 0)
            return ""
        if (art.indexOf("/") === 0)
            return "file://" + art
        return art
    }

    function buildMusicQueue(version, title, artist, album, art) {
        var out = []
        var seen = {}

        function add(kind, p, fallbackTitle, fallbackArtist, fallbackAlbum, fallbackArt) {
            var itemTitle = p ? textOf(p.trackTitle) : textOf(fallbackTitle)
            var itemArtist = p ? textOf(p.trackArtist) : textOf(fallbackArtist)
            var itemAlbum = p ? textOf(p.trackAlbum || p.identity) : textOf(fallbackAlbum)
            var itemArt = p ? textOf(p.trackArtUrl) : textOf(fallbackArt)
            var itemLength = p && p.length > 0 ? p.length : mediaLength
            var key = itemTitle + "|" + itemArtist + "|" + itemAlbum

            if (itemTitle.length === 0 || seen[key])
                return

            seen[key] = true
            out.push({
                "kind": kind,
                "title": itemTitle,
                "artist": itemArtist.length > 0 ? itemArtist : "Spotify",
                "album": itemAlbum.length > 0 ? itemAlbum : "Player",
                "art": itemArt,
                "length": itemLength
            })
        }

        if (mediaPlayer)
            add("current", mediaPlayer, title, artist, album, art)

        var list = Mpris.players.values || []
        for (var i = 0; i < list.length; i += 1) {
            if (list[i] !== mediaPlayer)
                add("player", list[i], "", "", "", "")
        }

        if (out.length === 0)
            out.push({ "kind": "empty", "title": "Spotify", "artist": "Nenhuma faixa ativa", "album": "Abra uma musica", "art": "", "length": 0 })

        return out
    }

    function formatMediaTime(sec) {
        sec = Math.max(0, Math.floor(Number(sec) || 0))
        var m = Math.floor(sec / 60)
        var s = sec % 60
        return m + ":" + (s < 10 ? "0" + s : s)
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

    function toggleShuffle() {
        if (mediaPlayer && mediaPlayer.shuffleSupported)
            mediaPlayer.shuffle = !mediaPlayer.shuffle
    }

    function toggleRepeat() {
        if (!mediaPlayer || !mediaPlayer.loopSupported)
            return

        mediaPlayer.loopState = mediaPlayer.loopState === MprisLoopState.None
            ? MprisLoopState.Playlist
            : MprisLoopState.None
    }

    function seekMedia(ratio) {
        if (!mediaPlayer || !mediaPlayer.positionSupported || mediaLength <= 0)
            return

        mediaPosition = mediaLength * clamp01(ratio)
        mediaPlayer.position = mediaPosition
    }

    function setVolumeFromRatio(ratio) {
        volume = Math.max(0, Math.min(100, Math.round(clamp01(ratio) * 100)))
        pendingCommand = "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + volume + "% 2>/dev/null"

        if (!launcherProcess.running)
            launcherProcess.running = true
    }

    function runCommand(command) {
        if (command.length === 0)
            return

        pendingCommand = "(" + command + ") >/dev/null 2>&1 &"
        launcherOpen = false
        themesOpen = false
        wallpaperListOpen = false
        appSearchOpen = false
        musicOpen = false
        profileOpen = false

        if (!launcherProcess.running)
            launcherProcess.running = true
    }

    function openAppSearch() {
        appSearchOpen = true
        launcherOpen = false
        themesOpen = false
        wallpaperListOpen = false
        musicOpen = false
        profileOpen = false
        rebuildAppSearch()
    }

    function toggleAppSearch() {
        if (appSearchOpen)
            appSearchOpen = false
        else
            openAppSearch()
    }

    function openLauncher() {
        launcherOpen = true
        themesOpen = false
        wallpaperListOpen = false
        appSearchOpen = false
        musicOpen = false
        profileOpen = false
    }

    function openThemes() {
        themesOpen = true
        launcherOpen = false
        wallpaperListOpen = false
        appSearchOpen = false
        musicOpen = false
        profileOpen = false
        if (wallpaperEntries.length === 0 && !wallpaperScanProcess.running)
            wallpaperScanProcess.running = true
    }

    function toggleThemes() {
        if (themesOpen)
            themesOpen = false
        else
            openThemes()
    }

    function toggleWallpaperList() {
        if (wallpaperListOpen) {
            wallpaperListOpen = false
            return
        }

        wallpaperListOpen = true
        themesOpen = false
        launcherOpen = false
        appSearchOpen = false
        musicOpen = false
        profileOpen = false
        themesHovering = false
        if (wallpaperEntries.length === 0 && !wallpaperScanProcess.running)
            wallpaperScanProcess.running = true
    }

    function appEntryText(entry) {
        if (!entry)
            return ""

        return textOf(entry.name).toLowerCase() + " "
            + textOf(entry.genericName).toLowerCase() + " "
            + textOf(entry.comment).toLowerCase() + " "
            + textOf(entry.execString).toLowerCase() + " "
            + textOf(entry.id).toLowerCase() + " "
            + textOf(entry.categories ? entry.categories.join(" ") : "").toLowerCase()
    }

    function appEntryKind(entry) {
        var data = appEntryText(entry)

        if (data.indexOf("settings") >= 0 || data.indexOf("configuration") >= 0)
            return "settings"
        if (data.indexOf("filemanager") >= 0 || data.indexOf("file manager") >= 0 || data.indexOf("folder") >= 0)
            return "files"
        if (data.indexOf("webbrowser") >= 0 || data.indexOf("browser") >= 0 || data.indexOf("network") >= 0)
            return "web"
        return "apps"
    }

    function appModeMatches(entry) {
        if (appSearchMode === "all")
            return true

        return appEntryKind(entry) === appSearchMode
    }

    function rebuildAppSearch() {
        var list = DesktopEntries.applications.values || []
        var query = textOf(appSearchQuery).toLowerCase().trim()
        var out = []

        for (var i = 0; i < list.length; i += 1) {
            var entry = list[i]
            if (!entry || entry.noDisplay || !appModeMatches(entry))
                continue
            if (query.length > 0 && appEntryText(entry).indexOf(query) < 0)
                continue

            out.push(entry)
        }

        out.sort(function(a, b) {
            return textOf(a.name).localeCompare(textOf(b.name))
        })

        appSearchResults = out.slice(0, 5)
        appSearchIndex = Math.max(0, Math.min(Math.max(0, appSearchResults.length - 1), appSearchIndex))
    }

    function setAppSearchMode(mode) {
        appSearchMode = mode
        appSearchIndex = 0
        rebuildAppSearch()
        appSearchFocusTimer.restart()
    }

    function stepAppSearch(delta) {
        if (!appSearchOpen || appSearchResults.length === 0)
            return

        appSearchIndex = Math.max(0, Math.min(appSearchResults.length - 1, appSearchIndex + delta))
        if (appSearchListView)
            appSearchListView.positionViewAtIndex(appSearchIndex, ListView.Contain)
    }

    function launchAppSearchEntry(entry) {
        if (!entry)
            return

        entry.execute()
        appSearchOpen = false
        appSearchQuery = ""
        appSearchIndex = 0
    }

    function launchSelectedAppSearchEntry() {
        if (appSearchResults.length === 0)
            return

        launchAppSearchEntry(appSearchResults[appSearchIndex])
    }

    function openMusic(px, py, pw, ph) {
        musicOpen = true
        launcherOpen = false
        themesOpen = false
        wallpaperListOpen = false
        appSearchOpen = false
        profileOpen = false
        mediaVersion += 1
    }

    function toggleMusic() {
        if (musicOpen)
            closeMusic()
        else
            openMusic()
    }

    function closeMusic() {
        musicOpen = false
    }

    function openProfile() {
        profileCloseTimer.stop()
        profileMounted = true
        profileOpen = true
        launcherOpen = false
        themesOpen = false
        wallpaperListOpen = false
        appSearchOpen = false
        musicOpen = false
    }

    function toggleProfile() {
        if (profileOpen)
            profileOpen = false
        else
            openProfile()
    }

    function triggerProfileAction(action) {
        var kind = action.kind || "command"

        if (kind === "themes") {
            openThemes()
        } else if (kind === "launcher") {
            profileOpen = false
            themesOpen = false
            wallpaperListOpen = false
            appSearchOpen = false
            musicOpen = false
            openLauncher()
        } else if (kind === "command" && action.command && action.command.length > 0) {
            runCommand(action.command)
        }
    }

    function fileUrl(path) {
        return path && path.length > 0 ? "file://" + path : ""
    }

    function colorFromHex(hex, fallback) {
        var value = textOf(hex).trim()
        if (value.charAt(0) === "#")
            value = value.slice(1)
        if (value.length !== 6)
            return fallback

        var r = parseInt(value.slice(0, 2), 16)
        var g = parseInt(value.slice(2, 4), 16)
        var b = parseInt(value.slice(4, 6), 16)
        if (isNaN(r) || isNaN(g) || isNaN(b))
            return fallback

        return Qt.rgba(r / 255, g / 255, b / 255, 0.96)
    }

    function refreshPywalAccent(forcePywal) {
        if (forcePywal)
            saveSetting("pywalAccentEnabled", true)

        if (!pywalAccentProcess.running)
            pywalAccentProcess.running = true
    }

    function applyPywalAccent(hex) {
        pywalAccentChoice = colorFromHex(hex, pywalAccentChoice)
    }

    function setThemeMode(mode) {
        saveSetting("themeMode", mode)
    }

    function setWallpaperCategory(kind) {
        if (wallpaperCategory !== kind) {
            wallpaperPage = 0
            wallpaperPageOffset = 0
            wallpaperPageOpacity = 1
        }

        saveSetting("wallpaperCategory", kind)
    }

    function wallpaperCategoryIndex(kind) {
        for (var i = 0; i < wallpaperCategories.length; i += 1) {
            if (wallpaperCategories[i].key === kind)
                return i
        }
        return 0
    }

    function setWallpaperCategoryAnimated(kind, direction) {
        if (wallpaperCategory === kind)
            return

        var dir = direction
        if (dir === 0) {
            var from = wallpaperCategoryIndex(wallpaperCategory)
            var to = wallpaperCategoryIndex(kind)
            dir = to >= from ? 1 : -1
        }

        wallpaperListCategorySlideAnim.stop()
        wallpaperListIndex = 0
        wallpaperListSlideOffset = dir >= 0 ? 28 : -28
        wallpaperListSlideOpacity = 0.36
        setWallpaperCategory(kind)

        if (wallpaperListView) {
            wallpaperListScrollAnim.stop()
            wallpaperListView.contentY = 0
        }

        wallpaperListCategorySlideAnim.restart()
    }

    function wallpaperCount(kind) {
        var count = 0
        for (var i = 0; i < wallpaperEntries.length; i += 1) {
            if (wallpaperEntries[i].kind === kind)
                count += 1
        }
        return count
    }

    function refreshWallpapers() {
        var out = []
        for (var i = 0; i < wallpaperEntries.length; i += 1) {
            if (wallpaperEntries[i].kind === wallpaperCategory)
                out.push(wallpaperEntries[i])
        }
        wallpaperFiltered = out
        clampWallpaperPage()
        if (wallpaperListOpen)
            syncWallpaperListIndexToCurrent()
        clampWallpaperListIndex()
        if (wallpaperListOpen)
            Qt.callLater(centerWallpaperListSelection)
    }

    function clampWallpaperPage() {
        var maxPage = Math.max(0, Math.ceil(wallpaperFiltered.length / wallpaperPageSize) - 1)
        wallpaperPage = Math.max(0, Math.min(maxPage, wallpaperPage))
    }

    function clampWallpaperListIndex() {
        wallpaperListIndex = Math.max(0, Math.min(Math.max(0, wallpaperFiltered.length - 1), wallpaperListIndex))
    }

    function syncWallpaperListIndexToCurrent() {
        if (currentWallpaperKey.length === 0 || wallpaperFiltered.length === 0)
            return

        for (var i = 0; i < wallpaperFiltered.length; i += 1) {
            var item = wallpaperFiltered[i]
            if (currentWallpaperKey === item.kind + "|" + item.path) {
                wallpaperListIndex = i
                return
            }
        }
    }

    function wallpaperListContentHeightEstimate() {
        if (wallpaperListView && wallpaperListView.contentHeight > 0)
            return wallpaperListView.contentHeight

        var count = wallpaperFiltered.length
        if (count <= 0)
            return 0

        return count * wallpaperListCardHeight + Math.max(0, count - 1) * wallpaperListCardSpacing
    }

    function wallpaperListTargetY(index) {
        if (!wallpaperListView || wallpaperFiltered.length === 0)
            return 0

        var safeIndex = Math.max(0, Math.min(wallpaperFiltered.length - 1, index))
        var itemTop = safeIndex * (wallpaperListCardHeight + wallpaperListCardSpacing)
        var centeredY = itemTop - Math.max(0, (wallpaperListView.height - wallpaperListCardHeight) / 2)
        var maxY = Math.max(0, wallpaperListContentHeightEstimate() - wallpaperListView.height)
        return Math.max(0, Math.min(maxY, centeredY))
    }

    function centerWallpaperListSelection(animated) {
        if (!wallpaperListView || wallpaperFiltered.length === 0)
            return

        var targetY = wallpaperListTargetY(wallpaperListIndex)
        if (animated) {
            wallpaperListScrollAnim.stop()
            wallpaperListScrollAnim.from = wallpaperListView.contentY
            wallpaperListScrollAnim.to = targetY
            wallpaperListScrollAnim.restart()
        } else {
            wallpaperListScrollAnim.stop()
            wallpaperListView.contentY = targetY
        }
    }

    function stepWallpaperList(delta) {
        if (!wallpaperListOpen || wallpaperFiltered.length === 0)
            return

        wallpaperListSlideOffset = 0
        wallpaperListSlideOpacity = 1
        wallpaperListIndex = Math.max(0, Math.min(wallpaperFiltered.length - 1, wallpaperListIndex + delta))
        centerWallpaperListSelection(true)
    }

    function stepWallpaperCategory(delta) {
        var idx = 0
        for (var i = 0; i < wallpaperCategories.length; i += 1) {
            if (wallpaperCategories[i].key === wallpaperCategory) {
                idx = i
                break
            }
        }

        idx = (idx + delta + wallpaperCategories.length) % wallpaperCategories.length
        setWallpaperCategoryAnimated(wallpaperCategories[idx].key, delta)
    }

    function stepWallpaperPage(delta) {
        if (wallpaperFiltered.length <= wallpaperPageSize)
            return

        var maxPage = Math.max(0, Math.ceil(wallpaperFiltered.length / wallpaperPageSize) - 1)
        wallpaperPage = (wallpaperPage + delta + maxPage + 1) % (maxPage + 1)
        wallpaperPageOffset = delta > 0 ? 28 : -28
        wallpaperPageOpacity = 0.36
        wallpaperSlideAnim.restart()
    }

    function parseWallpaperLine(lineRaw, tmp) {
        var line = textOf(lineRaw).trim()
        if (line.length === 0 || line === "BEGIN")
            return tmp
        if (line === "END") {
            wallpaperEntries = tmp
            refreshWallpapers()
            return tmp
        }

        var parts = line.split("|")
        if (parts.length < 4)
            return tmp

        var kind = parts[0].toLowerCase()
        var path = parts[1]
        var preview = parts[2]
        var title = parts.slice(3).join("|")
        tmp.push({ "kind": kind, "path": path, "preview": preview, "title": title })
        return tmp
    }

    function applyWallpaper(item) {
        if (!item || wallpaperApplyProcess.running)
            return

        pendingWallpaperKey = item.kind + "|" + item.path
        wallpaperApplyProcess.command = [
            wallpaperApplyCommand,
            item.kind,
            item.path,
            item.preview || "",
            wallpaperTransitionType,
            String(wallpaperTransitionDuration)
        ]
        wallpaperApplyProcess.running = true
    }

    function applySelectedWallpaper() {
        if (!wallpaperListOpen || wallpaperFiltered.length === 0)
            return

        applyWallpaper(wallpaperFiltered[wallpaperListIndex])
    }

    function accentMatches(c) {
        return Math.abs(c.r - accentChoice.r) < 0.01
            && Math.abs(c.g - accentChoice.g) < 0.01
            && Math.abs(c.b - accentChoice.b) < 0.01
    }

    onWallpaperCategoryChanged: refreshWallpapers()
    onCurrentWallpaperKeyChanged: {
        if (wallpaperListOpen) {
            syncWallpaperListIndexToCurrent()
            Qt.callLater(centerWallpaperListSelection)
        }
    }
    onAppSearchQueryChanged: {
        appSearchIndex = 0
        rebuildAppSearch()
    }
    onAppSearchModeChanged: rebuildAppSearch()

    function parseCava(data) {
        var raw = textOf(data).trim()
        if (raw.length === 0)
            return

        var lines = raw.split(/\n/)
        var line = lines[lines.length - 1]
        var parts = line.split(/[;,\s]+/)
        var out = []

        for (var i = 0; i < parts.length; i += 1) {
            if (parts[i].length === 0)
                continue

            var n = Number(parts[i])
            if (isNaN(n))
                continue

            var normalized = clamp01(n / 1000)
            out.push(Math.max(0.08, Math.pow(normalized, 0.72)))
        }

        if (out.length > 0) {
            cavaBars = out
            cavaReady = true
        }
    }

    function pickBattery() {
        batteryDevice = null

        for (let i = 0; i < UPower.devices.count; i += 1) {
            let dev = UPower.devices.get(i)

            if (dev && dev.isLaptopBattery) {
                batteryDevice = dev
                return
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: bar.clockText = Qt.formatDateTime(new Date(), "HH:mm")
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            bar.pickBattery()

            if (!volumeQuery.running)
                volumeQuery.running = true
        }
    }

    Timer {
        interval: 1000
        running: bar.mediaAvailable
        repeat: true
        triggeredOnStart: true
        onTriggered: bar.mediaPosition = bar.mediaPlayer ? bar.mediaPlayer.position : 0
    }

    onMediaPlayerChanged: mediaPosition = mediaPlayer ? mediaPlayer.position : 0

    Connections {
        target: Mpris.players

        function onValuesChanged() {
            bar.mediaVersion += 1
        }
    }

    Connections {
        target: DesktopEntries.applications

        function onValuesChanged() {
            bar.rebuildAppSearch()
        }
    }

    onMediaAvailableChanged: {
        if (mediaAvailable && !cavaProcess.running)
            cavaProcess.running = true
        else if (!mediaAvailable && cavaProcess.running)
            cavaProcess.running = false
    }

    Timer {
        id: volumeRefreshDelay

        interval: 220
        repeat: false
        onTriggered: {
            if (!volumeQuery.running)
                volumeQuery.running = true
        }
    }

    Timer {
        id: pywalRefreshDelay

        interval: 700
        repeat: false
        onTriggered: bar.refreshPywalAccent()
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: bar.refreshPywalAccent()
    }

    Process {
        id: pywalAccentProcess

        running: false
        command: [bar.pywalAccentCommand]

        stdout: SplitParser {
            onRead: function(data) {
                bar.applyPywalAccent(data)
            }
        }

        onExited: running = false
    }

    Process {
        id: settingsLoadProcess

        running: false
        command: [bar.settingsDataCommand, "get"]

        stdout: SplitParser {
            onRead: function(data) {
                var line = data.trim()
                if (line.length === 0 || line.indexOf("=") < 0)
                    return

                var idx = line.indexOf("=")
                bar.setPersistedValue(line.slice(0, idx), line.slice(idx + 1))
            }
        }

        onExited: {
            running = false
            bar.settingsLoaded = true
        }
    }

    Process {
        id: settingsSaveProcess

        running: false
        command: ["bash", "-lc", "true"]
        onExited: {
            running = false
            bar.flushSettingsSave()
        }
    }

    Process {
        id: volumeQuery

        running: false
        command: ["bash", "-lc", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo 'Volume: 0.70'"]

        stdout: SplitParser {
            onRead: function(data) {
                var text = data.trim()
                var match = text.match(/[0-9]+\.?[0-9]*/)

                bar.muted = text.indexOf("MUTED") >= 0

                if (match)
                    bar.volume = Math.max(0, Math.min(100, Math.round(parseFloat(match[0]) * 100)))
            }
        }

        onExited: running = false
    }

    Process {
        id: cavaProcess

        running: false
        command: ["bash", "-lc", bar.cavaCommand]

        stdout: SplitParser {
            onRead: function(data) {
                bar.parseCava(data)
            }
        }

        onExited: {
            running = false
            if (bar.mediaAvailable)
                cavaRestart.restart()
        }
    }

    Process {
        id: launcherProcess

        running: false
        command: ["bash", "-lc", bar.pendingCommand]
        onExited: running = false
    }

    Process {
        id: wallpaperScanProcess

        property var tmp: []

        running: false
        command: [bar.wallpaperScanCommand]

        onStarted: {
            tmp = []
            bar.wallpapersScanning = true
        }

        stdout: SplitParser {
            onRead: function(data) {
                wallpaperScanProcess.tmp = bar.parseWallpaperLine(data, wallpaperScanProcess.tmp)
            }
        }

        onExited: {
            running = false
            bar.wallpapersScanning = false
            if (tmp.length > 0) {
                bar.wallpaperEntries = tmp
                bar.refreshWallpapers()
            }
        }
    }

    Process {
        id: wallpaperApplyProcess

        running: false
        command: [bar.wallpaperApplyCommand]
        onExited: {
            running = false
            if (bar.pendingWallpaperKey.length > 0) {
                bar.saveSetting("currentWallpaperKey", bar.pendingWallpaperKey)
                bar.pendingWallpaperKey = ""
            }
            bar.saveSetting("pywalAccentEnabled", true)
            pywalRefreshDelay.restart()
        }
    }

    Timer {
        id: cavaRestart

        interval: 1400
        repeat: false
        onTriggered: {
            if (bar.mediaAvailable && !cavaProcess.running)
                cavaProcess.running = true
        }
    }

    Component.onCompleted: {
        if (!settingsLoadProcess.running)
            settingsLoadProcess.running = true

        if (mediaAvailable && !cavaProcess.running)
            cavaProcess.running = true
    }

    Item {
        id: themeMaskRegion

        x: 0
        y: 0
        width: bar.drawerSurfaceActive ? bar.railWidth + bar.activeDrawerWidth : 0
        height: bar.activeDrawerHeight
    }

    Rectangle {
        visible: !bar.drawerSurfaceActive
        x: 2
        y: 4
        width: bar.railWidth
        height: Math.max(0, parent.height - 3)
        radius: bar.cornerRadius
        color: Qt.rgba(0.0, 0.0, 0.0, 0.14)
    }

    Rectangle {
        visible: bar.drawerSurfaceActive
        x: 2
        y: 4
        width: bar.railWidth - 2
        height: bar.activeDrawerHeight - 3
        radius: bar.cornerRadius
        topRightRadius: 0
        bottomLeftRadius: 0
        bottomRightRadius: 0
        color: Qt.rgba(0.0, 0.0, 0.0, 0.14)
    }

    Rectangle {
        visible: bar.drawerSurfaceActive
        x: bar.railWidth
        y: 4
        width: bar.activeDrawerWidth
        height: bar.activeDrawerHeight - 3
        radius: bar.cornerRadius
        topLeftRadius: 0
        color: Qt.rgba(0.0, 0.0, 0.0, 0.14)
    }

    Rectangle {
        visible: bar.drawerSurfaceActive
        x: 2
        y: bar.activeDrawerHeight + 4
        width: bar.railWidth
        height: Math.max(0, parent.height - y - 3)
        radius: bar.cornerRadius
        topLeftRadius: 0
        topRightRadius: 0
        color: Qt.rgba(0.0, 0.0, 0.0, 0.14)
    }

    Rectangle {
        visible: !bar.drawerSurfaceActive

        x: 0
        y: 0
        width: bar.railWidth
        height: parent.height
        radius: bar.cornerRadius
        color: bar.panelBase
        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        visible: bar.drawerSurfaceActive
        x: 0
        y: 0
        width: bar.railWidth
        height: bar.activeDrawerHeight
        radius: bar.cornerRadius
        topRightRadius: 0
        bottomLeftRadius: 0
        bottomRightRadius: 0
        color: bar.activePanelBase
        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        visible: bar.drawerSurfaceActive
        x: bar.railWidth
        y: 0
        width: bar.activeDrawerWidth
        height: bar.activeDrawerHeight
        radius: bar.cornerRadius
        topLeftRadius: 0
        color: bar.activePanelBase
        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        visible: bar.drawerSurfaceActive
        x: 0
        y: bar.activeDrawerHeight
        width: bar.railWidth
        height: Math.max(0, parent.height - bar.activeDrawerHeight)
        radius: bar.cornerRadius
        topLeftRadius: 0
        topRightRadius: 0
        color: bar.activePanelBase
        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    Item {
        id: surface

        x: 0
        y: 0
        width: bar.railWidth
        height: parent.height
    }

    Item {
        id: themeSurface

        visible: bar.themeSurfaceActive
        opacity: bar.themeReveal
        x: bar.railWidth
        y: 0
        width: bar.themeAnimatedWidth
        height: bar.themeDrawerHeight
        clip: true

        Rectangle {
            x: 0
            y: 0
            width: Math.max(0, parent.width - bar.cornerRadius)
            height: 1
            color: Qt.rgba(0.58, 0.72, 0.86, 0.20)
        }

        Rectangle {
            x: bar.cornerRadius
            y: parent.height - 1
            width: Math.max(0, parent.width - bar.cornerRadius * 2)
            height: 1
            color: Qt.rgba(0.58, 0.72, 0.86, 0.16)
        }

        Rectangle {
            visible: parent.width > bar.cornerRadius
            x: parent.width - 1
            y: bar.cornerRadius
            width: 1
            height: parent.height - bar.cornerRadius * 2
            color: Qt.rgba(0.58, 0.72, 0.86, 0.20)
        }
    }

    Rectangle {
        anchors {
            left: surface.left
            right: surface.right
            top: surface.top
            leftMargin: 6
            rightMargin: 6
            topMargin: 3
        }

        height: 1
        color: Qt.rgba(1.0, 1.0, 1.0, 0.12)
    }

    Rectangle {
        x: bar.cornerRadius
        y: 0
        width: bar.drawerSurfaceActive ? bar.railWidth - bar.cornerRadius : bar.railWidth - bar.cornerRadius * 2
        height: 1
        color: Qt.rgba(0.58, 0.72, 0.86, 0.20)
    }

    Rectangle {
        x: bar.cornerRadius
        y: surface.height - 1
        width: bar.railWidth - bar.cornerRadius * 2
        height: 1
        color: Qt.rgba(0.58, 0.72, 0.86, 0.16)
    }

    Rectangle {
        x: 0
        y: bar.cornerRadius
        width: 1
        height: surface.height - bar.cornerRadius * 2
        color: Qt.rgba(0.58, 0.72, 0.86, 0.20)
    }

    Rectangle {
        visible: !bar.drawerSurfaceActive
        x: surface.width - 1
        y: bar.cornerRadius
        width: 1
        height: surface.height - bar.cornerRadius * 2
        color: Qt.rgba(0.58, 0.72, 0.86, 0.20)
    }

    Rectangle {
        anchors {
            left: surface.left
            top: surface.top
            bottom: surface.bottom
            leftMargin: 3
            topMargin: 14
            bottomMargin: 14
        }

        width: 1
        color: Qt.rgba(0.80, 0.90, 1.0, 0.08)
    }

    Rectangle {
        x: surface.width - 4
        y: bar.drawerSurfaceActive ? Math.min(surface.height - 14, bar.activeDrawerHeight + bar.cornerRadius) : 14
        width: 1
        height: Math.max(0, surface.height - y - 14)
        color: Qt.rgba(0.0, 0.0, 0.0, 0.24)
    }

    Column {
        id: rail

        x: 7
        y: 7
        width: bar.railWidth - 14
        height: surface.height - 14
        spacing: 8

        readonly property int fixedBase: clockButton.height
            + topGroup.height
            + workspaceGroup.height
            + separatorA.height
            + toolsGroup.height
            + separatorB.height
            + mediaCard.height
            + statusGroup.height
            + settingsButton.height
            + profileFrame.height
            + spacing * 11
        readonly property int flexibleSpace: Math.max(0, height - fixedBase)
        readonly property int topGapHeight: flexibleSpace <= 0 ? 0 : Math.max(26, Math.min(118, Math.round(flexibleSpace * 0.30)))
        readonly property int mediaGapHeight: Math.max(0, flexibleSpace - topGapHeight)

        ClockButton {
            id: clockButton
            anchors.horizontalCenter: parent.horizontalCenter
        }

        SegmentedGroup {
            id: topGroup
            anchors.horizontalCenter: parent.horizontalCenter
            items: [
                { "icon": "palette", "command": "", "active": bar.themesOpen },
                { "icon": "search", "command": "", "active": bar.appSearchOpen }
            ]

            onItemClicked: function(index) {
                if (index === 0) {
                    bar.musicOpen = false
                    bar.profileOpen = false
                    bar.openThemes()
                } else if (index === 1) {
                    bar.toggleAppSearch()
                }
            }

            onItemHovered: function(index) {
                if (index === 0) {
                    bar.themesHovering = true
                    themesHoverCloseTimer.stop()
                    bar.openThemes()
                }
            }

            onItemExited: function(index) {
                if (index === 0) {
                    bar.themesHovering = false
                    themesHoverCloseTimer.restart()
                }
            }
        }

        Item {
            width: 1
            height: rail.topGapHeight
        }

        WorkspaceGroup {
            id: workspaceGroup
            anchors.horizontalCenter: parent.horizontalCenter
        }

        RailSeparator {
            id: separatorA
            anchors.horizontalCenter: parent.horizontalCenter
        }

        SegmentedGroup {
            id: toolsGroup
            anchors.horizontalCenter: parent.horizontalCenter
            items: [
                { "icon": "folder", "command": bar.filesCommand },
                { "icon": "grid", "command": "", "active": bar.launcherOpen },
                { "icon": "terminal", "command": bar.terminalCommand }
            ]

            onItemClicked: function(index) {
                if (index === 1) {
                    bar.themesOpen = false
                    bar.musicOpen = false
                    bar.profileOpen = false
                    bar.openLauncher()
                }
            }

            onItemHovered: function(index) {
                if (index === 1) {
                    bar.launcherHovering = true
                    launcherHoverCloseTimer.stop()
                    bar.openLauncher()
                }
            }

            onItemExited: function(index) {
                if (index === 1) {
                    bar.launcherHovering = false
                    launcherHoverCloseTimer.restart()
                }
            }
        }

        RailSeparator {
            id: separatorB
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Item {
            width: 1
            height: rail.mediaGapHeight
        }

        MediaCard {
            id: mediaCard
            anchors.horizontalCenter: parent.horizontalCenter
        }

        SegmentedGroup {
            id: statusGroup
            anchors.horizontalCenter: parent.horizontalCenter
            items: [
                {
                    "icon": "bell",
                    "command": "",
                    "active": bar.notificationCount > 0,
                    "badge": bar.notificationCount > 0 ? String(Math.min(bar.notificationCount, 9)) : ""
                },
                {
                    "icon": bar.muted ? "volume-muted" : "volume",
                    "command": bar.muteCommand,
                    "warning": bar.muted
                },
                {
                    "icon": "battery",
                    "command": "",
                    "warning": bar.batteryPercent <= 20,
                    "value": bar.batteryFill
                }
            ]

            onItemClicked: function(index) {
                if (index === 1)
                    volumeRefreshDelay.restart()
            }
        }

        IconButton {
            id: settingsButton
            anchors.horizontalCenter: parent.horizontalCenter
            iconName: "settings"
            command: bar.settingsCommand
        }

        Rectangle {
            id: profileFrame

            anchors.horizontalCenter: parent.horizontalCenter
            width: 38
            height: 38
            radius: width / 2
            scale: bar.profileOpen ? 1.07 : bar.profileHovered ? 1.04 : 1.0
            color: bar.profileOpen ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.18) : Qt.rgba(0.10, 0.16, 0.20, 0.42)
            border.width: 1
            border.color: bar.profileOpen || bar.profileHovered ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.72) : Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.38)
            clip: true

            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

            Image {
                id: profileImage

                anchors.fill: parent
                anchors.margins: 3
                source: "file:///home/shira/.face"
                visible: false
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
            }

            Rectangle {
                id: profileMask

                anchors.fill: profileImage
                radius: width / 2
                visible: false
            }

            OpacityMask {
                anchors.fill: profileImage
                source: profileImage
                maskSource: profileMask
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                    bar.profileHovered = true
                    profileHoverCloseTimer.stop()
                    bar.openProfile()
                }
                onExited: {
                    bar.profileHovered = false
                    profileHoverCloseTimer.restart()
                }
                onClicked: bar.openProfile()
            }
        }
    }

    PopupWindow {
        id: profilePopup

        visible: bar.profileOpen || bar.profileMounted
        color: "transparent"
        implicitWidth: 382
        implicitHeight: 588

        anchor.item: profileFrame
        anchor.rect.x: profileFrame.width + 18
        anchor.rect.y: Math.round(profileFrame.height / 2 + 48 - implicitHeight)
        anchor.rect.width: 1
        anchor.rect.height: 1

        Item {
            id: profileMotion

            readonly property real iconOriginX: profileFrame.width / 2 - profilePopup.anchor.rect.x
            readonly property real iconOriginY: profileFrame.height / 2 - profilePopup.anchor.rect.y

            width: parent.width
            height: parent.height
            opacity: bar.profileOpen ? 1 : 0
            enabled: bar.profileOpen
            transform: Scale {
                id: profileOpenScale

                origin.x: profileMotion.iconOriginX
                origin.y: profileMotion.iconOriginY
                xScale: bar.profileOpen ? 1.0 : 0.10
                yScale: bar.profileOpen ? 1.0 : 0.10

                Behavior on xScale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.04 } }
                Behavior on yScale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.04 } }
            }

            Behavior on opacity { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }

            HoverHandler {
                onHoveredChanged: {
                    bar.profilePopupHovered = hovered
                    if (hovered)
                        profileHoverCloseTimer.stop()
                    else
                        profileHoverCloseTimer.restart()
                }
            }

            Rectangle {
                x: 16
                y: 12
                width: parent.width - 20
                height: parent.height - 16
                radius: 24
                color: Qt.rgba(0.0, 0.0, 0.0, 0.32)
            }

            Rectangle {
                x: 4
                y: Math.round(profileMotion.iconOriginY - height / 2)
                width: 18
                height: 18
                radius: 2
                rotation: 45
                color: Qt.rgba(0.052, 0.066, 0.078, 0.94)
                border.width: 1
                border.color: Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.34)
            }

            Rectangle {
                x: 10 - bar.profilePulse * 10
                y: -bar.profilePulse * 10
                width: parent.width - 10 + bar.profilePulse * 20
                height: parent.height + bar.profilePulse * 20
                radius: 26 + bar.profilePulse * 10
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.28 * bar.profilePulse)
            }

            Rectangle {
                id: profilePanel

                anchors {
                    fill: parent
                    leftMargin: 10
                }

                radius: 22
                color: Qt.rgba(0.052, 0.066, 0.078, 0.94)
                border.width: 1
                border.color: Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.20 + bar.profileReveal * 0.12)
                clip: true

                Rectangle {
                    width: parent.width
                    height: parent.height * 0.46
                    anchors.bottom: parent.bottom
                    color: Qt.rgba(0.80, 0.88, 0.94, 0.035)
                }

                Column {
                    anchors {
                        fill: parent
                        margins: 14
                    }

                    spacing: 10

                    Rectangle {
                        width: parent.width
                        height: 118
                        radius: 16
                        color: Qt.rgba(0.060, 0.078, 0.092, 0.54)
                        border.width: 1
                        border.color: Qt.rgba(0.82, 0.90, 0.96, 0.13)
                        opacity: bar.profileIntroAvatar
                        scale: 0.96 + bar.profileIntroAvatar * 0.04
                        transform: Translate { x: -18 * (1.0 - bar.profileIntroAvatar) }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 14

                            Rectangle {
                                id: profilePopupAvatar

                                width: 78
                                height: 78
                                radius: width / 2
                                anchors.verticalCenter: parent.verticalCenter
                                color: Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.16)
                                border.width: 1
                                border.color: Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.54)
                                clip: true

                                Image {
                                    id: profilePopupImage

                                    anchors.fill: parent
                                    anchors.margins: 5
                                    source: bar.profileSource
                                    visible: false
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                }

                                Rectangle {
                                    id: profilePopupMask

                                    anchors.fill: profilePopupImage
                                    radius: width / 2
                                    visible: false
                                }

                                OpacityMask {
                                    anchors.fill: profilePopupImage
                                    source: profilePopupImage
                                    maskSource: profilePopupMask
                                }

                                Rectangle {
                                    width: 15
                                    height: 15
                                    radius: 8
                                    anchors {
                                        right: parent.right
                                        bottom: parent.bottom
                                        rightMargin: 6
                                        bottomMargin: 6
                                    }
                                    color: Qt.rgba(0.40, 0.86, 0.58, 0.96)
                                    border.width: 2
                                    border.color: Qt.rgba(0.052, 0.066, 0.078, 0.95)
                                }
                            }

                            Column {
                                width: parent.width - profilePopupAvatar.width - editButton.width - parent.spacing * 2
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 7
                                opacity: bar.profileIntroText
                                transform: Translate { x: 16 * (1.0 - bar.profileIntroText) }

                                Text {
                                    width: parent.width
                                    text: bar.profileName
                                    color: bar.text
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 17
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: bar.profileBio
                                    color: Qt.rgba(0.80, 0.87, 0.96, 0.74)
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }

                                Row {
                                    width: parent.width
                                    height: 24
                                    spacing: 7

                                    ProfileTag {
                                        label: bar.profileEmail
                                    }

                                    ProfileTag {
                                        label: bar.profilePlan
                                        accentTag: true
                                    }
                                }
                            }

                            MusicSquareButton {
                                id: editButton

                                width: 34
                                height: 34
                                anchors.top: parent.top
                                iconName: "edit"
                                subtle: true
                                onPressed: bar.runCommand(bar.settingsCommand)
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 82
                        spacing: 10
                        opacity: bar.profileIntroStats
                        transform: Translate { y: 14 * (1.0 - bar.profileIntroStats) }

                        ProfileStatCard {
                            width: Math.floor((parent.width - parent.spacing * 2) / 3)
                            title: "Online"
                            subtitle: "Active now"
                            iconName: "circle"
                            highlight: true
                        }

                        ProfileStatCard {
                            width: Math.floor((parent.width - parent.spacing * 2) / 3)
                            title: "42.6 GB"
                            subtitle: "of 100 GB used"
                            iconName: "folder"
                            progress: 0.426
                        }

                        ProfileStatCard {
                            width: Math.floor((parent.width - parent.spacing * 2) / 3)
                            title: "12"
                            subtitle: "Projects"
                            iconName: "activity"
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 284
                        radius: 16
                        color: Qt.rgba(0.060, 0.078, 0.092, 0.42)
                        border.width: 1
                        border.color: Qt.rgba(0.82, 0.90, 0.96, 0.12)
                        opacity: bar.profileIntroActions
                        transform: Translate { y: 22 * (1.0 - bar.profileIntroActions) }

                        Column {
                            anchors {
                                fill: parent
                                margins: 10
                            }

                            Repeater {
                                model: bar.profileActions

                                ProfileActionRow {
                                    width: parent.width
                                    height: 42
                                    actionData: modelData
                                    rowIndex: index
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: launcherPopup

        x: bar.railWidth
        y: 0
        width: Math.max(1, bar.launcherAnimatedWidth)
        height: bar.launcherDrawerHeight
        visible: bar.launcherDrawerVisible
        enabled: bar.launcherOpen && bar.launcherReveal > 0.14
        opacity: bar.launcherReveal
        clip: true

        onVisibleChanged: {
            if (visible) {
                bar.launcherQuery = ""
                launcherFocusTimer.restart()
            }
        }

        HoverHandler {
            onHoveredChanged: {
                bar.launcherHovering = hovered
                if (hovered)
                    launcherHoverCloseTimer.stop()
                else
                    launcherHoverCloseTimer.restart()
            }
        }

        Timer {
            id: launcherFocusTimer

            interval: 80
            repeat: false
            onTriggered: searchField.forceActiveFocus()
        }

        Rectangle {
            x: 0
            y: 0
            width: Math.max(0, parent.width - bar.cornerRadius)
            height: 1
            color: Qt.rgba(0.58, 0.72, 0.86, 0.20)
        }

        Rectangle {
            x: bar.cornerRadius
            y: parent.height - 1
            width: Math.max(0, parent.width - bar.cornerRadius * 2)
            height: 1
            color: Qt.rgba(0.58, 0.72, 0.86, 0.16)
        }

        Rectangle {
            visible: parent.width > bar.cornerRadius
            x: parent.width - 1
            y: bar.cornerRadius
            width: 1
            height: parent.height - bar.cornerRadius * 2
            color: Qt.rgba(0.58, 0.72, 0.86, 0.20)
        }

        Item {
            id: launcherMotion

            width: bar.launcherMainWidth
            height: parent.height
            x: -Math.round(22 * (1.0 - bar.launcherReveal))
            y: 0

            Rectangle {
                visible: false
                x: 14
                y: 6
                width: parent.width - 18
                height: parent.height - 8
                radius: 20
                color: Qt.rgba(0.0, 0.0, 0.0, 0.14)
            }

            Rectangle {
                visible: false
                x: 4
                y: 0
                width: 18
                height: 18
                radius: 2
                rotation: 45
                color: Qt.rgba(0.055, 0.070, 0.082, 0.92)
                border.width: 1
                border.color: Qt.rgba(0.74, 0.82, 0.90, 0.15)
            }

            Rectangle {
                id: launcherPanel

                anchors {
                    fill: parent
                    leftMargin: 0
                }

                radius: 0
                color: "transparent"
                border.width: 0
                border.color: "transparent"
                clip: true

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        leftMargin: 16
                        rightMargin: 16
                        topMargin: 2
                    }

                    height: 1
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.09)
                }

                Column {
                    anchors {
                        fill: parent
                        margins: 20
                    }

                    spacing: 12

                    Rectangle {
                        width: parent.width
                        height: 42
                        radius: 12
                        color: Qt.rgba(0.045, 0.056, 0.066, 0.74)
                        border.width: 1
                        border.color: Qt.rgba(0.74, 0.82, 0.90, 0.13)

                        IconCanvas {
                            anchors {
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                                leftMargin: 14
                            }

                            width: 18
                            height: 18
                            iconName: "search"
                            lineColor: bar.dimText
                        }

                        TextInput {
                            id: searchField

                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 42
                                rightMargin: 14
                            }

                            text: bar.launcherQuery
                            color: bar.text
                            selectionColor: Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.28)
                            selectedTextColor: bar.text
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            clip: true

                            onTextChanged: bar.launcherQuery = text
                            onAccepted: bar.runCommand(bar.appsCommand)
                            Keys.onEscapePressed: bar.launcherOpen = false
                        }

                        Text {
                            anchors {
                                left: searchField.left
                                verticalCenter: parent.verticalCenter
                            }

                            visible: searchField.text.length === 0
                            text: "Search apps..."
                            color: bar.dimText
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                        }
                    }

                    Grid {
                        id: launcherGrid

                        width: parent.width
                        columns: 3
                        columnSpacing: 8
                        rowSpacing: 8

                        Repeater {
                            model: bar.launcherTiles

                            LauncherTile {
                                width: Math.floor((launcherGrid.width - launcherGrid.columnSpacing * 2) / 3)
                                height: 80
                                iconName: modelData.icon
                                label: modelData.label
                                command: modelData.command
                                visible: bar.launcherQuery.length === 0
                                    || modelData.label.toLowerCase().indexOf(bar.launcherQuery.toLowerCase()) >= 0
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Qt.rgba(0.74, 0.82, 0.90, 0.13)
                    }

                    Text {
                        width: parent.width
                        text: "Quick Access"
                        color: bar.text
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }

                    Column {
                        width: parent.width
                        spacing: 2

                        Repeater {
                            model: bar.quickLinks

                            QuickLink {
                                iconName: modelData.icon
                                label: modelData.label
                                command: modelData.command
                            }
                        }
                    }
                }
            }
        }
    }

    PopupWindow {
        id: musicPopup

        visible: bar.musicOpen || bar.musicMounted
        color: "transparent"
        implicitWidth: 226
        implicitHeight: 454

        anchor.item: surface
        anchor.rect.x: Math.max(bar.railWidth + 18, bar.screenWidth - implicitWidth - 34)
        anchor.rect.y: -12
        anchor.rect.width: 1
        anchor.rect.height: 1

        onVisibleChanged: {
            if (visible)
                bar.mediaVersion += 1
        }

        Item {
            id: musicMotion

            width: parent.width
            height: parent.height
            x: Math.round((1.0 - bar.musicReveal) * 36)
            opacity: bar.musicReveal
            scale: 0.97 + bar.musicReveal * 0.03
            enabled: bar.musicOpen
            transformOrigin: Item.TopRight

            Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.InOutCubic } }
            Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.InOutCubic } }

            Rectangle {
                x: 5
                y: 7
                width: parent.width - 3
                height: parent.height - 4
                radius: 9
                color: Qt.rgba(0.0, 0.0, 0.0, 0.26)
            }

            Rectangle {
                id: musicPanel

                anchors.fill: parent
                radius: 8
                color: bar.panelBase
                border.width: 1
                border.color: Qt.rgba(0.74, 0.82, 0.90, 0.22)
                clip: true

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        leftMargin: 8
                        rightMargin: 8
                        topMargin: 1
                    }

                    height: 1
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.11)
                }

                Column {
                    anchors {
                        fill: parent
                        margins: 17
                    }

                    spacing: 12

                    Item {
                        width: parent.width
                        height: 124

                        Rectangle {
                            id: compactMusicArtFrame

                            x: 0
                            y: 0
                            width: 124
                            height: 124
                            radius: 12
                            color: Qt.rgba(0.08, 0.10, 0.12, 0.82)
                            border.width: 1
                            border.color: Qt.rgba(0.82, 0.90, 0.96, 0.13)
                            clip: true

                            Image {
                                id: compactMusicArt

                                anchors.fill: parent
                                source: bar.mediaArtSource()
                                visible: false
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                            }

                            Rectangle {
                                id: compactMusicArtMask

                                anchors.fill: compactMusicArt
                                radius: compactMusicArtFrame.radius
                                visible: false
                            }

                            OpacityMask {
                                anchors.fill: compactMusicArt
                                source: compactMusicArt
                                maskSource: compactMusicArtMask
                                visible: compactMusicArt.source.toString().length > 0 && compactMusicArt.status === Image.Ready
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: compactMusicArt.source.toString().length === 0 || compactMusicArt.status !== Image.Ready
                                color: Qt.rgba(0.075, 0.088, 0.100, 0.95)

                                IconCanvas {
                                    anchors.centerIn: parent
                                    width: 44
                                    height: 44
                                    iconName: "music"
                                    lineColor: bar.dimText
                                }
                            }
                        }

                        Row {
                            anchors {
                                right: parent.right
                                top: parent.top
                            }
                            spacing: 4

                            MusicSquareButton {
                                width: 28
                                height: 28
                                iconName: "heart"
                                subtle: true
                                onPressed: bar.mediaVersion += 1
                            }

                            MusicSquareButton {
                                width: 28
                                height: 28
                                iconName: "more"
                                subtle: true
                                onPressed: bar.mediaVersion += 1
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        height: 60
                        spacing: 3

                        Text {
                            width: parent.width
                            height: 19
                            text: bar.mediaTitle
                            color: bar.text
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Text {
                            width: parent.width
                            height: 16
                            text: bar.mediaArtist
                            color: Qt.rgba(0.80, 0.87, 0.96, 0.70)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Text {
                            width: parent.width
                            height: 15
                            text: bar.mediaAlbum
                            color: bar.dimText
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }

                    Column {
                        width: parent.width
                        height: 42
                        spacing: 5

                        MusicProgressBar {
                            width: parent.width
                            height: 17
                        }

                        Row {
                            width: parent.width
                            height: 15

                            Text {
                                width: parent.width / 2
                                text: bar.mediaAvailable ? bar.formatMediaTime(bar.mediaPosition) : "0:00"
                                color: bar.dimText
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                            }

                            Text {
                                width: parent.width / 2
                                text: bar.mediaAvailable && bar.mediaLength > 0 ? "-" + bar.formatMediaTime(Math.max(0, bar.mediaLength - bar.mediaPosition)) : "-0:00"
                                color: bar.dimText
                                horizontalAlignment: Text.AlignRight
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                            }
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 180
                        height: 42
                        spacing: 8

                        CompactMusicButton {
                            iconName: "shuffle"
                            active: bar.mediaShuffle
                            controlEnabled: Boolean(bar.mediaPlayer && bar.mediaPlayer.shuffleSupported)
                            onPressed: bar.toggleShuffle()
                        }

                        CompactMusicButton {
                            iconName: "previous"
                            controlEnabled: Boolean(bar.mediaPlayer && bar.mediaPlayer.canGoPrevious)
                            onPressed: bar.previousMedia()
                        }

                        CompactMusicButton {
                            iconName: bar.mediaPlaying ? "pause" : "play"
                            primary: true
                            controlEnabled: Boolean(bar.mediaAvailable)
                            onPressed: bar.toggleMedia()
                        }

                        CompactMusicButton {
                            iconName: "next"
                            controlEnabled: Boolean(bar.mediaPlayer && bar.mediaPlayer.canGoNext)
                            onPressed: bar.nextMedia()
                        }

                        CompactMusicButton {
                            iconName: "repeat"
                            active: bar.mediaRepeat
                            controlEnabled: Boolean(bar.mediaPlayer && bar.mediaPlayer.loopSupported)
                            onPressed: bar.toggleRepeat()
                        }
                    }

                    Item {
                        id: compactWaveform

                        width: parent.width
                        height: 27

                        Repeater {
                            model: 28

                            Rectangle {
                                readonly property real v: bar.cavaBars[index % Math.max(1, bar.cavaBars.length)]

                                width: 2
                                height: Math.max(3, compactWaveform.height * (bar.cavaReady ? v : 0.18))
                                x: index * (compactWaveform.width / 28) + (compactWaveform.width / 28 - width) / 2
                                y: Math.round((compactWaveform.height - height) / 2)
                                radius: 1
                                color: bar.mediaPlaying ? Qt.rgba(0.78, 0.82, 0.84, 0.62) : Qt.rgba(0.58, 0.62, 0.64, 0.26)

                                Behavior on height { NumberAnimation { duration: 75; easing.type: Easing.OutCubic } }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Qt.rgba(0.74, 0.82, 0.90, 0.13)
                    }

                    Row {
                        width: parent.width
                        height: 26
                        spacing: 10

                        IconCanvas {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18
                            iconName: bar.muted ? "volume-muted" : "volume"
                            lineColor: bar.text
                        }

                        MusicVolumeSlider {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 54
                            height: 22
                        }

                        IconCanvas {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 17
                            height: 17
                            iconName: "settings"
                            lineColor: bar.dimText
                        }
                    }
                }
            }
        }
    }

    Item {
        id: appSearchInputRegion

        x: appSearchPopup.x
        y: appSearchPopup.y
        width: (bar.appSearchOpen || bar.appSearchMounted) ? appSearchPopup.width : 0
        height: (bar.appSearchOpen || bar.appSearchMounted) ? appSearchPopup.height : 0
    }

    Item {
        id: appSearchPopup

        visible: bar.appSearchOpen || bar.appSearchMounted
        enabled: visible
        z: 86
        x: Math.round((bar.width - width) / 2)
        y: Math.round((bar.height - height) / 2)
        width: bar.appSearchPanelWidth
        height: bar.appSearchPanelHeight

        Item {
            id: appSearchMotion

            width: parent.width
            height: parent.height
            y: Math.round((1.0 - bar.appSearchReveal) * 26)
            opacity: bar.appSearchReveal
            scale: 0.96 + bar.appSearchReveal * 0.04
            enabled: bar.appSearchOpen
            transformOrigin: Item.Center

            Behavior on y { NumberAnimation { duration: 230; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 230; easing.type: Easing.OutCubic } }

            Keys.onEscapePressed: function(event) {
                bar.appSearchOpen = false
                event.accepted = true
            }

            Keys.onUpPressed: function(event) {
                bar.stepAppSearch(-1)
                event.accepted = true
            }

            Keys.onDownPressed: function(event) {
                bar.stepAppSearch(1)
                event.accepted = true
            }

            Keys.onReturnPressed: function(event) {
                bar.launchSelectedAppSearchEntry()
                event.accepted = true
            }

            Keys.onEnterPressed: function(event) {
                bar.launchSelectedAppSearchEntry()
                event.accepted = true
            }

            Rectangle {
                x: 7
                y: 9
                width: parent.width
                height: parent.height
                radius: 18
                color: Qt.rgba(0.0, 0.0, 0.0, 0.24)
            }

            Rectangle {
                anchors.fill: parent
                radius: 18
                color: Qt.rgba(bar.panelBase.r, bar.panelBase.g, bar.panelBase.b, Math.max(0.78, bar.panelBase.a))
                border.width: 1
                border.color: Qt.rgba(0.74, 0.82, 0.90, 0.22)
                clip: true

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        leftMargin: 18
                        rightMargin: 18
                        topMargin: 1
                    }

                    height: 1
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.11)
                }

                Column {
                    anchors {
                        fill: parent
                        margins: 24
                    }
                    spacing: 16

                    Rectangle {
                        width: parent.width
                        height: 44
                        radius: 13
                        color: Qt.rgba(0.045, 0.056, 0.066, 0.72)
                        border.width: 1
                        border.color: Qt.rgba(0.74, 0.82, 0.90, 0.16)

                        IconCanvas {
                            anchors {
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                                leftMargin: 16
                            }
                            width: 19
                            height: 19
                            iconName: "search"
                            lineColor: bar.text
                        }

                        TextInput {
                            id: appSearchField

                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 48
                                rightMargin: 16
                            }

                            text: bar.appSearchQuery
                            color: bar.text
                            selectionColor: Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.28)
                            selectedTextColor: bar.text
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            clip: true

                            onTextChanged: bar.appSearchQuery = text
                            onAccepted: bar.launchSelectedAppSearchEntry()
                            Keys.onEscapePressed: bar.appSearchOpen = false
                            Keys.onUpPressed: function(event) {
                                bar.stepAppSearch(-1)
                                event.accepted = true
                            }
                            Keys.onDownPressed: function(event) {
                                bar.stepAppSearch(1)
                                event.accepted = true
                            }
                        }

                        Text {
                            anchors {
                                left: appSearchField.left
                                verticalCenter: parent.verticalCenter
                            }

                            visible: appSearchField.text.length === 0
                            text: "Search apps, files, settings..."
                            color: bar.dimText
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                        }
                    }

                    Row {
                        width: parent.width
                        height: 32
                        spacing: 13

                        Repeater {
                            model: bar.appSearchTabs

                            AppSearchTab {
                                modeKey: modelData.key
                                label: modelData.label
                                iconName: modelData.icon
                            }
                        }
                    }

                    ListView {
                        id: appSearchListView

                        width: parent.width
                        height: parent.height - 44 - 32 - 32
                        clip: true
                        spacing: 7
                        model: bar.appSearchResults
                        currentIndex: bar.appSearchIndex
                        boundsBehavior: Flickable.StopAtBounds

                        Behavior on contentY {
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }

                        delegate: AppSearchRow {
                            width: appSearchListView.width
                            entry: modelData
                            rowIndex: index
                        }
                    }

                    Text {
                        visible: bar.appSearchResults.length === 0
                        width: parent.width
                        height: 32
                        text: "No apps found"
                        color: bar.dimText
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                    }
                }
            }
        }
    }

    Item {
        id: wallpaperListInputRegion

        x: wallpaperListPopup.x
        y: wallpaperListPopup.y
        width: (bar.wallpaperListOpen || bar.wallpaperListMounted) ? wallpaperListPopup.width : 0
        height: (bar.wallpaperListOpen || bar.wallpaperListMounted) ? wallpaperListPopup.height : 0
    }

    Item {
        id: wallpaperListPopup

        visible: bar.wallpaperListOpen || bar.wallpaperListMounted
        enabled: visible
        z: 90
        x: Math.round(bar.width - width)
        y: -bar.wallpaperListEdgeCompensation
        width: bar.wallpaperListPanelWidth
        height: bar.height + bar.wallpaperListEdgeCompensation * 2

        Timer {
            id: wallpaperListFocusTimer

        interval: 80
        repeat: false
        onTriggered: {
            wallpaperListMotion.forceActiveFocus()
            bar.centerWallpaperListSelection()
        }
    }

        Item {
            id: wallpaperListMotion

            width: parent.width
            height: parent.height
            x: Math.round((1.0 - bar.wallpaperListReveal) * 42)
            opacity: bar.wallpaperListReveal
            enabled: bar.wallpaperListOpen
            focus: bar.wallpaperListOpen

            Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.InOutCubic } }

            Keys.onEscapePressed: function(event) {
                bar.wallpaperListOpen = false
                event.accepted = true
            }

            Keys.onUpPressed: function(event) {
                bar.stepWallpaperList(-1)
                event.accepted = true
            }

            Keys.onDownPressed: function(event) {
                bar.stepWallpaperList(1)
                event.accepted = true
            }

            Keys.onLeftPressed: function(event) {
                bar.stepWallpaperCategory(-1)
                event.accepted = true
            }

            Keys.onRightPressed: function(event) {
                bar.stepWallpaperCategory(1)
                event.accepted = true
            }

            Keys.onReturnPressed: function(event) {
                if (bar.wallpaperFiltered.length > 0)
                    bar.applyWallpaper(bar.wallpaperFiltered[bar.wallpaperListIndex])
                event.accepted = true
            }

            Keys.onEnterPressed: function(event) {
                if (bar.wallpaperFiltered.length > 0)
                    bar.applyWallpaper(bar.wallpaperFiltered[bar.wallpaperListIndex])
                event.accepted = true
            }

            HoverHandler {
                onHoveredChanged: {
                    bar.themesHovering = hovered
                    if (hovered)
                        themesHoverCloseTimer.stop()
                    else
                        themesHoverCloseTimer.restart()
                }
            }

            Rectangle {
                x: 5
                y: 7
                width: parent.width - 3
                height: parent.height - 4
                radius: 10
                color: Qt.rgba(0.0, 0.0, 0.0, 0.22)
            }

            Rectangle {
                id: wallpaperListPanel

                anchors.fill: parent
                radius: 8
                color: bar.panelBase
                border.width: 1
                border.color: Qt.rgba(0.74, 0.82, 0.90, 0.22)
                clip: true

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        leftMargin: 10
                        rightMargin: 10
                        topMargin: 1
                    }

                    height: 1
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.11)
                }

                Column {
                    anchors {
                        fill: parent
                        margins: 10
                    }
                    spacing: 0

                    Item {
                        width: parent.width
                        height: parent.height

                        ListView {
                            id: wallpaperListView

                            x: bar.wallpaperListSlideOffset
                            y: 0
                            width: parent.width - 8
                            height: parent.height
                            opacity: bar.wallpaperListSlideOpacity
                            clip: true
                            spacing: bar.wallpaperListCardSpacing
                            model: bar.wallpaperFiltered
                            currentIndex: bar.wallpaperListIndex
                            boundsBehavior: Flickable.StopAtBounds
                            interactive: true

                            NumberAnimation {
                                id: wallpaperListScrollAnim

                                target: wallpaperListView
                                property: "contentY"
                                duration: 260
                                easing.type: Easing.InOutCubic
                            }

                            delegate: Rectangle {
                                id: wallpaperRowCard

                                required property var modelData
                                required property int index
                                readonly property var entry: modelData || ({})
                                readonly property bool selected: bar.currentWallpaperKey === (entry.kind + "|" + entry.path)
                                readonly property bool keySelected: bar.wallpaperListOpen && bar.wallpaperListIndex === index
                                property bool hovered: false

                                width: wallpaperListView.width
                                height: bar.wallpaperListCardHeight
                                radius: 10
                                color: hovered || keySelected ? Qt.rgba(0.09, 0.11, 0.13, 0.62) : Qt.rgba(0.055, 0.070, 0.082, 0.34)
                                border.width: selected || keySelected ? 2 : 1
                                border.color: selected ? bar.accent : keySelected ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.54) : hovered ? Qt.rgba(0.78, 0.86, 0.94, 0.24) : Qt.rgba(0.74, 0.82, 0.90, 0.14)
                                clip: true

                                Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                Behavior on border.color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }

                                Image {
                                    id: wallpaperRowImage

                                    anchors {
                                        fill: parent
                                        margins: 7
                                    }
                                    source: bar.fileUrl(wallpaperRowCard.entry.preview || wallpaperRowCard.entry.path || "")
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                }

                                Rectangle {
                                    anchors {
                                        fill: parent
                                        margins: 7
                                    }
                                    radius: 8
                                    color: Qt.rgba(0, 0, 0, 0.05)
                                    border.width: 1
                                    border.color: Qt.rgba(0.88, 0.94, 1.0, 0.10)
                                }

                                IconCanvas {
                                    anchors {
                                        right: parent.right
                                        top: parent.top
                                        rightMargin: 14
                                        topMargin: 14
                                    }
                                    width: 20
                                    height: 20
                                    visible: wallpaperRowCard.selected
                                    iconName: "check"
                                    lineColor: bar.accent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    z: 4
                                    hoverEnabled: true
                                    preventStealing: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: {
                                        wallpaperRowCard.hovered = true
                                        bar.wallpaperListIndex = wallpaperRowCard.index
                                    }
                                    onExited: wallpaperRowCard.hovered = false
                                    onClicked: {
                                        bar.wallpaperListIndex = wallpaperRowCard.index
                                        bar.centerWallpaperListSelection(true)
                                        bar.applyWallpaper(wallpaperRowCard.entry)
                                    }
                                }
                            }

                            WheelHandler {
                                target: null
                                onWheel: function(wheel) {
                                    wallpaperListScrollAnim.stop()
                                    var maxY = Math.max(0, wallpaperListView.contentHeight - wallpaperListView.height)
                                    wallpaperListView.contentY = Math.max(0, Math.min(maxY, wallpaperListView.contentY - wheel.angleDelta.y))
                                    wheel.accepted = true
                                }
                            }
                        }

                        Text {
                            visible: bar.wallpaperFiltered.length === 0
                            anchors.centerIn: parent
                            text: bar.wallpapersScanning ? "Scanning..." : "No wallpapers"
                            color: bar.dimText
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }

                        Rectangle {
                            visible: wallpaperListView.contentHeight > wallpaperListView.height
                            anchors.right: parent.right
                            width: 3
                            height: Math.max(34, wallpaperListView.height * wallpaperListView.height / Math.max(1, wallpaperListView.contentHeight))
                            y: wallpaperListView.y + (wallpaperListView.height - height) * bar.clamp01(wallpaperListView.contentY / Math.max(1, wallpaperListView.contentHeight - wallpaperListView.height))
                            radius: 2
                            color: Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.48)
                        }
                    }
                }
            }
        }
    }

    Item {
        id: themesDrawer

        x: bar.railWidth
        y: 0
        width: Math.max(1, bar.themeAnimatedWidth)
        height: bar.themeDrawerHeight
        visible: bar.themeDrawerVisible
        enabled: bar.themesOpen && bar.themeReveal > 0.14
        opacity: bar.themeReveal
        clip: true

        onVisibleChanged: {
            if (visible && bar.wallpaperEntries.length === 0 && !wallpaperScanProcess.running)
                wallpaperScanProcess.running = true
        }

        HoverHandler {
            onHoveredChanged: {
                bar.themesHovering = hovered
                if (hovered)
                    themesHoverCloseTimer.stop()
                else
                    themesHoverCloseTimer.restart()
            }
        }

        Item {
            id: themesMotion

            width: bar.themeDrawerWidth
            height: parent.height
            x: -Math.round(22 * (1.0 - bar.themeReveal))
            y: 0
            transform: Scale {
                id: themesOpenScale

                origin.x: 0
                origin.y: themesMotion.height / 2
                xScale: 0.94 + 0.06 * bar.themeReveal
                yScale: 1.0
            }

            Item {
                id: themesPanel

                x: 0
                y: 0
                width: bar.themeMainWidth
                height: parent.height
                clip: true

                Column {
                    anchors {
                        fill: parent
                        margins: 20
                    }

                    spacing: 13

                    Row {
                        width: parent.width
                        height: 24
                        spacing: 4

                        IconCanvas {
                            width: 18
                            height: 18
                            anchors.verticalCenter: parent.verticalCenter
                            iconName: "arrow-left"
                            lineColor: bar.dimText
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Themes"
                            color: bar.text
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }

                    }

                    Grid {
                        id: themeGrid
                        width: parent.width
                        columns: 2
                        columnSpacing: 10
                        rowSpacing: 10

                        Repeater {
                            model: bar.themeModes

                            ThemeModeCard {
                                width: Math.floor((themeGrid.width - themeGrid.columnSpacing) / 2)
                                height: 86
                                modeKey: modelData.key
                                label: modelData.label
                                iconName: modelData.icon
                            }
                        }
                    }

                    ThinLine { width: parent.width }

                    Row {
                        width: parent.width
                        height: 24

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 34
                            text: "Accent color"
                            color: bar.text
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                        }

                        Item {
                            width: 28
                            height: 24

                            Rectangle {
                                anchors.centerIn: parent
                                width: 24
                                height: 24
                                radius: 8
                                color: bar.themeSettingsOpen ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.22) : Qt.rgba(0.82, 0.88, 0.94, 0.07)
                                border.width: 1
                                border.color: bar.themeSettingsOpen ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.46) : Qt.rgba(0.82, 0.88, 0.94, 0.16)

                                IconCanvas {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    iconName: "settings"
                                    lineColor: bar.themeSettingsOpen ? bar.accent : bar.dimText
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: bar.themeSettingsOpen = !bar.themeSettingsOpen
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 34
                        spacing: 14

                        Repeater {
                            model: bar.accentChoices

                            AccentSwatch {
                                swatchColor: modelData
                                usesPywal: index === 0
                            }
                        }
                    }

                    ThinLine { width: parent.width }

                    Row {
                        width: parent.width
                        height: 28

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Wallpaper"
                            color: bar.text
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                        }

                        Item { width: 10; height: 1 }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            Repeater {
                                model: bar.wallpaperCategories

                                WallpaperCategoryChip {
                                    categoryKey: modelData.key
                                    label: modelData.label
                                }
                            }
                        }
                    }

                    Item {
                        id: wallpaperRow
                        width: parent.width
                        height: 66

                        Row {
                            anchors.fill: parent
                            spacing: 8
                            visible: bar.wallpaperFiltered.length > 0

                            WallpaperPagerButton {
                                width: 22
                                height: parent.height
                                iconName: "arrow-left"
                                controlEnabled: bar.wallpaperFiltered.length > bar.wallpaperPageSize
                                onPressed: bar.stepWallpaperPage(-1)
                            }

                            Item {
                                id: wallpaperStrip

                                width: parent.width - 60
                                height: parent.height
                                clip: true

                                Row {
                                    id: wallpaperStripContent

                                    x: bar.wallpaperPageOffset
                                    width: parent.width
                                    height: parent.height
                                    spacing: 7
                                    opacity: bar.wallpaperPageOpacity

                                    Repeater {
                                        model: bar.wallpaperPageItems

                                        WallpaperThumb {
                                            width: Math.floor((wallpaperStrip.width - wallpaperStripContent.spacing * 2) / 3)
                                            height: wallpaperStrip.height
                                            entry: modelData
                                        }
                                    }
                                }
                            }

                            WallpaperPagerButton {
                                width: 22
                                height: parent.height
                                iconName: "arrow-right"
                                controlEnabled: bar.wallpaperFiltered.length > bar.wallpaperPageSize
                                onPressed: bar.stepWallpaperPage(1)
                            }
                        }

                        Text {
                            visible: bar.wallpaperFiltered.length === 0
                            anchors.centerIn: parent
                            text: bar.wallpapersScanning ? "Scanning..." : "No wallpapers"
                            color: bar.dimText
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }
                    }
                }

                Item {
                    id: wallpaperMoreButton

                    x: bar.themeMainWidth - 48
                    y: 296
                    width: 28
                    height: 24
                    visible: bar.themesOpen
                    opacity: bar.themesOpen ? 1.0 : 0.0

                    Rectangle {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        radius: 8
                        color: bar.wallpaperListOpen ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.22) : Qt.rgba(0.82, 0.88, 0.94, 0.07)
                        border.width: 1
                        border.color: bar.wallpaperListOpen ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.46) : Qt.rgba(0.82, 0.88, 0.94, 0.16)

                        Behavior on color { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
                        Behavior on border.color { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }

                        IconCanvas {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            iconName: "more"
                            lineColor: bar.wallpaperListOpen ? bar.accent : bar.dimText
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bar.toggleWallpaperList()
                    }
                }
            }

            Rectangle {
                id: themeSettingsPanel

                x: bar.themeMainWidth
                y: 0
                width: bar.themeSettingsWidth
                height: parent.height
                radius: 0
                visible: bar.themeSettingsOpen
                opacity: bar.themeSettingsOpen ? 1.0 : 0.0
                scale: 1.0
                color: "transparent"
                border.width: 0
                clip: true

                Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

                Rectangle {
                    x: 0
                    y: 18
                    width: 1
                    height: parent.height - 36
                    color: Qt.rgba(0.58, 0.72, 0.86, 0.14)
                }

                Column {
                    anchors {
                        fill: parent
                        leftMargin: 16
                        rightMargin: 16
                        topMargin: 22
                        bottomMargin: 16
                    }
                    spacing: 12

                    Row {
                        width: parent.width
                        height: 20

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 24
                            text: "Settings"
                            color: bar.text
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }

                        IconCanvas {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16
                            iconName: "settings"
                            lineColor: bar.dimText
                        }
                    }

                    ThinLine { width: parent.width }

                    Row {
                        width: parent.width
                        height: 36

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 50
                            spacing: 2

                            Text {
                                text: "Auto switch"
                                color: bar.text
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                            }

                            Text {
                                text: "Light / dark"
                                color: bar.dimText
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                            }
                        }

                        TogglePill {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: bar.autoThemeSwitch
                            onPressed: bar.saveSetting("autoThemeSwitch", !bar.autoThemeSwitch)
                        }
                    }

                    Column {
                        width: parent.width
                        height: 75
                        spacing: 7

                        Row {
                            width: parent.width
                            height: 16

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 54
                                text: "Transition"
                                color: bar.text
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 54
                                text: bar.wallpaperTransitionType
                                color: bar.dimText
                                horizontalAlignment: Text.AlignRight
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                            }
                        }

                        Flow {
                            width: parent.width
                            height: 52
                            spacing: 6

                            Repeater {
                                model: bar.wallpaperTransitions

                                WallpaperTransitionChip {
                                    transitionKey: modelData.key
                                    label: modelData.label
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        height: 49
                        spacing: 6

                        Row {
                            width: parent.width
                            height: 16

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 54
                                text: "Speed"
                                color: bar.text
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 54
                                text: bar.wallpaperTransitionDuration.toFixed(2) + "s"
                                color: bar.dimText
                                horizontalAlignment: Text.AlignRight
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                            }
                        }

                        TransitionSpeedSlider { width: parent.width }
                    }

                    Column {
                        width: parent.width
                        height: 49
                        spacing: 6

                        Row {
                            width: parent.width
                            height: 16

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 54
                                text: "Transparency"
                                color: bar.text
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 54
                                text: Math.round(bar.interfaceOpacity * 100) + "%"
                                color: bar.dimText
                                horizontalAlignment: Text.AlignRight
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                            }
                        }

                        OpacitySlider { width: parent.width }
                    }

                    Rectangle {
                        width: parent.width
                        height: 32
                        radius: 10
                        color: saveArea.containsMouse ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.18) : Qt.rgba(0.82, 0.88, 0.94, 0.07)
                        border.width: 1
                        border.color: saveArea.containsMouse ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.42) : Qt.rgba(0.82, 0.88, 0.94, 0.15)

                        Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        Behavior on border.color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            IconCanvas {
                                width: 15
                                height: 15
                                iconName: "check"
                                lineColor: saveArea.containsMouse ? bar.accent : bar.dimText
                            }

                            Text {
                                text: "Save"
                                color: saveArea.containsMouse ? bar.text : bar.dimText
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                            }
                        }

                        MouseArea {
                            id: saveArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bar.saveAllSettings()
                        }
                    }
                }
            }
        }
    }

    component ThinLine: Rectangle {
        height: 1
        radius: 1
        color: Qt.rgba(0.74, 0.82, 0.90, 0.13)
    }

    component ProfileTag: Rectangle {
        id: tag

        property string label: ""
        property bool accentTag: false

        width: Math.min(118, labelText.implicitWidth + 16)
        height: 24
        radius: 7
        color: accentTag ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.10) : Qt.rgba(0.72, 0.82, 0.92, 0.08)
        border.width: 1
        border.color: accentTag ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.28) : Qt.rgba(0.72, 0.82, 0.92, 0.13)
        clip: true

        Text {
            id: labelText

            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 8
                rightMargin: 8
            }

            text: tag.label
            color: tag.accentTag ? bar.accent : Qt.rgba(0.80, 0.87, 0.96, 0.80)
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 9
            elide: Text.ElideRight
        }
    }

    component ProfileStatCard: Rectangle {
        id: stat

        property string title: ""
        property string subtitle: ""
        property string iconName: "activity"
        property real progress: 0.0
        property bool highlight: false
        property bool hovered: false

        height: parent ? parent.height : 82
        radius: 13
        color: hovered ? Qt.rgba(0.090, 0.112, 0.128, 0.74) : Qt.rgba(0.060, 0.078, 0.092, 0.50)
        border.width: 1
        border.color: hovered || highlight ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, highlight ? 0.34 : 0.24) : Qt.rgba(0.82, 0.90, 0.96, 0.12)
        clip: true

        Behavior on color { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }

        IconCanvas {
            x: 14
            y: 14
            width: 18
            height: 18
            iconName: stat.iconName
            lineColor: stat.highlight ? bar.accent : Qt.rgba(0.78, 0.86, 0.94, 0.90)
        }

        Text {
            x: 38
            y: 13
            width: parent.width - 48
            text: stat.title
            color: stat.highlight ? bar.accent : bar.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            x: 14
            y: 42
            width: parent.width - 28
            text: stat.subtitle
            color: bar.dimText
            horizontalAlignment: Text.AlignHCenter
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 9
            elide: Text.ElideRight
        }

        Rectangle {
            visible: stat.progress > 0
            x: 18
            y: parent.height - 17
            width: parent.width - 36
            height: 4
            radius: 2
            color: Qt.rgba(0.72, 0.82, 0.92, 0.18)

            Rectangle {
                width: parent.width * bar.clamp01(stat.progress)
                height: parent.height
                radius: parent.radius
                color: bar.accent
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: stat.hovered = true
            onExited: stat.hovered = false
        }
    }

    component ProfileActionRow: Rectangle {
        id: row

        property var actionData: ({})
        property int rowIndex: 0
        property bool hovered: false
        readonly property bool warning: actionData.kind === "logout"

        radius: 9
        color: hovered ? Qt.rgba(0.72, 0.82, 0.92, 0.08) : "transparent"

        Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }

        IconCanvas {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: 9
            }

            width: 21
            height: 21
            iconName: row.actionData.icon || "settings"
            lineColor: row.warning ? bar.warning : row.hovered ? bar.text : Qt.rgba(0.78, 0.86, 0.94, 0.88)
        }

        Column {
            anchors {
                left: parent.left
                right: arrow.left
                verticalCenter: parent.verticalCenter
                leftMargin: 42
                rightMargin: 8
            }

            spacing: 2

            Text {
                width: parent.width
                text: row.actionData.label || ""
                color: row.warning ? bar.warning : row.hovered ? bar.text : Qt.rgba(0.84, 0.90, 0.97, 0.92)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                font.weight: row.hovered ? Font.DemiBold : Font.Medium
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: row.actionData.sub || ""
                visible: text.length > 0
                color: bar.dimText
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 8
                elide: Text.ElideRight
            }
        }

        IconCanvas {
            id: arrow

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: 8
            }

            width: 17
            height: 17
            iconName: "arrow-right"
            lineColor: row.hovered ? bar.text : bar.dimText
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 10
                rightMargin: 10
            }

            visible: row.rowIndex < bar.profileActions.length - 1
            height: 1
            color: Qt.rgba(0.72, 0.82, 0.92, 0.10)
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: row.hovered = true
            onExited: row.hovered = false
            onClicked: bar.triggerProfileAction(row.actionData)
        }
    }

    component ThemeModeCard: Rectangle {
        id: card

        property string modeKey: "dark"
        property string label: "Dark"
        property string iconName: "moon"
        property bool selected: bar.themeMode === modeKey
        property bool hovered: false

        radius: 14
        opacity: bar.themesOpen ? 1.0 : 0.0
        scale: bar.themesOpen ? 1.0 : 0.90
        color: hovered ? Qt.rgba(0.090, 0.110, 0.125, 0.82) : Qt.rgba(0.047, 0.058, 0.068, 0.62)
        border.width: selected ? 2 : 1
        border.color: selected ? bar.accent : Qt.rgba(0.74, 0.82, 0.90, 0.16)
        clip: true

        Behavior on opacity { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.04 } }
        Behavior on color { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }

        Column {
            anchors.centerIn: parent
            spacing: 8

            IconCanvas {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 30
                height: 30
                iconName: card.iconName
                lineColor: card.selected ? bar.text : Qt.rgba(0.78, 0.86, 0.94, 0.86)
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: card.label
                color: bar.text
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
            }
        }

        Rectangle {
            visible: card.selected
            width: 18
            height: 18
            radius: 9
            anchors {
                right: parent.right
                top: parent.top
                rightMargin: 8
                topMargin: 8
            }
            color: bar.accent

            IconCanvas {
                anchors.centerIn: parent
                width: 12
                height: 12
                iconName: "check"
                lineColor: Qt.rgba(0.02, 0.05, 0.08, 0.95)
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: card.hovered = true
            onExited: card.hovered = false
            onClicked: bar.setThemeMode(card.modeKey)
        }
    }

    component AccentSwatch: Item {
        id: root

        property color swatchColor: bar.accent
        property bool usesPywal: false
        property bool selected: bar.accentMatches(swatchColor)

        width: 24
        height: 28
        opacity: bar.themesOpen ? 1.0 : 0.0
        scale: bar.themesOpen ? 1.0 : 0.78

        Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 210; easing.type: Easing.OutBack; easing.overshoot: 1.08 } }

        Rectangle {
            anchors.centerIn: parent
            width: root.selected ? 24 : 20
            height: width
            radius: width / 2
            color: Qt.rgba(root.swatchColor.r, root.swatchColor.g, root.swatchColor.b, 0.86)
            border.width: root.selected ? 3 : 1
            border.color: root.selected ? bar.accent : Qt.rgba(0.92, 0.96, 1.0, 0.24)
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.usesPywal) {
                    bar.saveSetting("pywalAccentEnabled", true)
                    bar.refreshPywalAccent(true)
                } else {
                    bar.saveSetting("pywalAccentEnabled", false)
                    bar.saveSetting("manualAccentChoice", bar.colorToHex(root.swatchColor))
                }
            }
        }
    }

    component WallpaperCategoryChip: Rectangle {
        id: chip

        property string categoryKey: "static"
        property string label: "Static"
        property bool selected: bar.wallpaperCategory === categoryKey

        width: Math.max(48, labelText.implicitWidth + 16)
        height: 22
        radius: 8
        opacity: (bar.themesOpen || bar.wallpaperListOpen) ? 1.0 : 0.0
        scale: (bar.themesOpen || bar.wallpaperListOpen) ? 1.0 : 0.88
        color: selected ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.20) : Qt.rgba(0.82, 0.88, 0.94, 0.06)
        border.width: selected ? 1 : 0
        border.color: Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.42)

        Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }

        Text {
            id: labelText
            anchors.centerIn: parent
            text: chip.label + " " + bar.wallpaperCount(chip.categoryKey)
            color: chip.selected ? bar.accent : bar.dimText
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 9
            font.weight: chip.selected ? Font.DemiBold : Font.Medium
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: bar.setWallpaperCategoryAnimated(chip.categoryKey, 0)
        }
    }

    component WallpaperTransitionChip: Rectangle {
        id: chip

        property string transitionKey: "fade"
        property string label: "Fade"
        property bool selected: bar.wallpaperTransitionType === transitionKey

        width: Math.max(42, labelText.implicitWidth + 14)
        height: 22
        radius: 8
        opacity: bar.themesOpen ? 1.0 : 0.0
        scale: bar.themesOpen ? 1.0 : 0.88
        color: selected ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.20) : Qt.rgba(0.82, 0.88, 0.94, 0.06)
        border.width: selected ? 1 : 0
        border.color: Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.42)

        Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }

        Text {
            id: labelText
            anchors.centerIn: parent
            text: chip.label
            color: chip.selected ? bar.accent : bar.dimText
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 9
            font.weight: chip.selected ? Font.DemiBold : Font.Medium
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: bar.saveSetting("wallpaperTransitionType", chip.transitionKey)
        }
    }

    component WallpaperPagerButton: Item {
        id: root

        property string iconName: "arrow-right"
        property bool controlEnabled: true
        property bool hovered: false
        signal pressed()

        opacity: (controlEnabled ? 1.0 : 0.30) * (bar.themesOpen ? 1.0 : 0.0)
        scale: bar.themesOpen ? 1.0 : 0.82

        Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.centerIn: parent
            width: 22
            height: 44
            radius: 9
            color: root.hovered ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.18) : Qt.rgba(0.82, 0.88, 0.94, 0.07)
            border.width: 1
            border.color: root.hovered ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.42) : Qt.rgba(0.82, 0.88, 0.94, 0.15)

            Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }

        IconCanvas {
            anchors.centerIn: parent
            width: 15
            height: 15
            iconName: root.iconName
            lineColor: root.hovered ? bar.accent : bar.dimText
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            enabled: root.controlEnabled
            cursorShape: Qt.PointingHandCursor
            onEntered: root.hovered = true
            onExited: root.hovered = false
            onClicked: root.pressed()
        }
    }

    component WallpaperThumb: Rectangle {
        id: thumb

        property var entry: ({})
        property bool selected: bar.currentWallpaperKey === (entry.kind + "|" + entry.path)
        property bool hovered: false

        radius: 10
        opacity: bar.themesOpen ? 1.0 : 0.0
        scale: bar.themesOpen ? 1.0 : 0.88
        color: Qt.rgba(0.047, 0.058, 0.068, 0.70)
        border.width: selected ? 2 : 1
        border.color: selected ? bar.accent : hovered ? Qt.rgba(0.78, 0.86, 0.94, 0.26) : Qt.rgba(0.74, 0.82, 0.90, 0.14)
        clip: true

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.02 } }
        Behavior on border.color { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }

        Image {
            anchors.fill: parent
            source: bar.fileUrl(thumb.entry.preview || thumb.entry.path || "")
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            opacity: 0.86
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.16)
        }

        Text {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 6
                rightMargin: 6
                bottomMargin: 5
            }

            text: thumb.entry.kind === "engine" ? "ENGINE" : thumb.entry.kind === "live" ? "MPV" : "STATIC"
            color: bar.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 8
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Rectangle {
            visible: thumb.selected
            width: 16
            height: 16
            radius: 8
            anchors {
                top: parent.top
                right: parent.right
                topMargin: 5
                rightMargin: 5
            }
            color: bar.accent

            IconCanvas {
                anchors.centerIn: parent
                width: 11
                height: 11
                iconName: "check"
                lineColor: Qt.rgba(0.02, 0.05, 0.08, 0.95)
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: thumb.hovered = true
            onExited: thumb.hovered = false
            onClicked: bar.applyWallpaper(thumb.entry)
        }
    }

    component TogglePill: Item {
        id: root

        property bool checked: false
        signal pressed()

        width: 42
        height: 24

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: root.checked ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.28) : Qt.rgba(0.82, 0.88, 0.94, 0.10)
            border.width: 1
            border.color: root.checked ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.54) : Qt.rgba(0.82, 0.88, 0.94, 0.20)
        }

        Rectangle {
            width: 14
            height: 14
            radius: 7
            x: root.checked ? parent.width - width - 5 : 5
            anchors.verticalCenter: parent.verticalCenter
            color: root.checked ? bar.accent : Qt.rgba(0.78, 0.86, 0.94, 0.86)
            Behavior on x { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.pressed()
        }
    }

    component OpacitySlider: Item {
        id: slider

        property real value: 0.46

        height: 24

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            height: 2
            radius: 1
            color: Qt.rgba(0.82, 0.88, 0.94, 0.22)

            Rectangle {
                width: parent.width * bar.clamp01((bar.interfaceOpacity - 0.25) / 0.55)
                height: parent.height
                radius: parent.radius
                color: bar.accent
            }
        }

        Rectangle {
            width: 12
            height: 12
            radius: 6
            x: Math.max(0, Math.min(parent.width - width, parent.width * bar.clamp01((bar.interfaceOpacity - 0.25) / 0.55) - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            color: bar.text
            border.width: 1
            border.color: bar.accent
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            function setFromX(px) {
                bar.saveSetting("interfaceOpacity", 0.25 + bar.clamp01(px / Math.max(1, width)) * 0.55)
            }

            onClicked: function(mouse) { setFromX(mouse.x) }
            onPositionChanged: function(mouse) {
                if (pressed)
                    setFromX(mouse.x)
            }
        }
    }

    component TransitionSpeedSlider: Item {
        id: slider

        height: 24

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            height: 2
            radius: 1
            color: Qt.rgba(0.82, 0.88, 0.94, 0.22)

            Rectangle {
                width: parent.width * bar.wallpaperTransitionSpeedRatio
                height: parent.height
                radius: parent.radius
                color: bar.accent
            }
        }

        Rectangle {
            width: 12
            height: 12
            radius: 6
            x: Math.max(0, Math.min(parent.width - width, parent.width * bar.wallpaperTransitionSpeedRatio - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            color: bar.text
            border.width: 1
            border.color: bar.accent
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            function setFromX(px) {
                bar.saveSetting("wallpaperTransitionDuration", 3.0 - bar.clamp01(px / Math.max(1, width)) * 2.75)
            }

            onClicked: function(mouse) { setFromX(mouse.x) }
            onPositionChanged: function(mouse) {
                if (pressed)
                    setFromX(mouse.x)
            }
        }
    }

    component MusicSquareButton: Item {
        id: root

        property string iconName: "arrow-left"
        property bool subtle: false
        property bool hovered: false
        signal pressed()

        Rectangle {
            anchors.centerIn: parent
            width: root.subtle ? 32 : parent.width
            height: root.subtle ? 32 : parent.height
            radius: root.subtle ? 10 : 13
            color: root.hovered ? Qt.rgba(0.72, 0.82, 0.92, 0.12) : Qt.rgba(0.72, 0.82, 0.92, root.subtle ? 0.00 : 0.06)
            border.width: root.subtle ? 0 : 1
            border.color: Qt.rgba(0.72, 0.82, 0.92, 0.13)

            Behavior on color { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
        }

        IconCanvas {
            anchors.centerIn: parent
            width: root.subtle ? 25 : 26
            height: root.subtle ? 25 : 26
            iconName: root.iconName
            lineColor: root.hovered ? bar.text : Qt.rgba(0.80, 0.87, 0.96, 0.86)
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.hovered = true
            onExited: root.hovered = false
            onClicked: root.pressed()
        }
    }

    component MusicControlButton: Item {
        id: root

        property string iconName: "play"
        property bool primary: false
        property bool active: false
        property bool controlEnabled: true
        property bool hovered: false
        signal pressed()

        width: primary ? 58 : 42
        height: primary ? 58 : 42
        opacity: controlEnabled ? 1.0 : 0.32

        Rectangle {
            anchors.centerIn: parent
            width: root.primary ? 58 : 42
            height: width
            radius: width / 2
            color: root.primary
                ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, root.hovered ? 0.34 : 0.24)
                : root.active ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, root.hovered ? 0.24 : 0.16)
                    : root.hovered ? Qt.rgba(0.72, 0.82, 0.92, 0.11) : "transparent"
            border.width: root.primary || root.active ? 2 : 0
            border.color: root.primary || root.active ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.94) : "transparent"

            Behavior on color { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
        }

        IconCanvas {
            anchors.centerIn: parent
            width: root.primary ? 34 : 26
            height: root.primary ? 34 : 26
            iconName: root.iconName
            lineColor: root.primary || root.active ? bar.text : Qt.rgba(0.80, 0.87, 0.96, 0.88)
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            enabled: root.controlEnabled
            cursorShape: Qt.PointingHandCursor
            onEntered: root.hovered = true
            onExited: root.hovered = false
            onClicked: root.pressed()
        }
    }

    component CompactMusicButton: Item {
        id: root

        property string iconName: "play"
        property bool primary: false
        property bool active: false
        property bool controlEnabled: true
        property bool hovered: false
        signal pressed()

        width: primary ? 42 : 28
        height: primary ? 42 : 28
        opacity: controlEnabled ? 1.0 : 0.32

        Rectangle {
            anchors.centerIn: parent
            width: root.primary ? 42 : 28
            height: width
            radius: width / 2
            color: root.primary
                ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, root.hovered ? 0.28 : 0.18)
                : root.active ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, root.hovered ? 0.20 : 0.13)
                    : root.hovered ? Qt.rgba(0.72, 0.82, 0.92, 0.10) : "transparent"
            border.width: root.primary || root.active ? 1 : 0
            border.color: root.primary || root.active ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.58) : "transparent"

            Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }

        IconCanvas {
            anchors.centerIn: parent
            width: root.primary ? 25 : 18
            height: root.primary ? 25 : 18
            iconName: root.iconName
            lineColor: root.primary || root.active || root.hovered ? bar.text : bar.dimText
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            enabled: root.controlEnabled
            cursorShape: Qt.PointingHandCursor
            onEntered: root.hovered = true
            onExited: root.hovered = false
            onClicked: root.pressed()
        }
    }

    component MiniBars: Item {
        id: root

        property bool active: false

        Repeater {
            model: 4

            Rectangle {
                width: 2
                height: root.active ? 5 + bar.cavaBars[Math.min(index, bar.cavaBars.length - 1)] * 10 : 5 + index * 2
                x: index * 4
                anchors.bottom: parent.bottom
                radius: 1
                color: root.active ? bar.accent : Qt.rgba(0.78, 0.86, 0.94, 0.50)

                Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
            }
        }
    }

    component MusicProgressBar: Item {
        id: root

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }

            height: 4
            radius: 2
            color: Qt.rgba(0.72, 0.82, 0.92, 0.16)

            Rectangle {
                width: parent.width * bar.mediaProgress
                height: parent.height
                radius: parent.radius
                color: bar.accent

                Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }
        }

        Rectangle {
            width: 14
            height: 14
            radius: 7
            x: Math.max(0, Math.min(parent.width - width, parent.width * bar.mediaProgress - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            color: bar.accent
            border.width: 1
            border.color: Qt.rgba(0.95, 0.98, 1.0, 0.72)

            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            enabled: bar.mediaAvailable && bar.mediaLength > 0
            cursorShape: Qt.PointingHandCursor
            onClicked: function(mouse) { bar.seekMedia(mouse.x / Math.max(1, width)) }
            onPositionChanged: function(mouse) {
                if (pressed)
                    bar.seekMedia(mouse.x / Math.max(1, width))
            }
        }
    }

    component MusicVolumeSlider: Item {
        id: root

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }

            height: 4
            radius: 2
            color: Qt.rgba(0.72, 0.82, 0.92, 0.16)

            Rectangle {
                width: parent.width * bar.clamp01(bar.volume / 100)
                height: parent.height
                radius: parent.radius
                color: bar.accent

                Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
            }
        }

        Rectangle {
            width: 14
            height: 14
            radius: 7
            x: Math.max(0, Math.min(parent.width - width, parent.width * bar.clamp01(bar.volume / 100) - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            color: bar.text
            border.width: 1
            border.color: bar.accent

            Behavior on x { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            function setFromX(px) {
                bar.setVolumeFromRatio(px / Math.max(1, width))
            }

            onClicked: function(mouse) { setFromX(mouse.x) }
            onPositionChanged: function(mouse) {
                if (pressed)
                    setFromX(mouse.x)
            }
        }
    }

    component QueueTrack: Rectangle {
        id: row

        property var entry: ({})
        property int rowIndex: 0
        property bool hovered: false
        readonly property bool current: rowIndex === 0 && entry.kind !== "empty"

        color: hovered ? Qt.rgba(0.72, 0.82, 0.92, 0.08) : "transparent"

        Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            height: 1
            color: Qt.rgba(0.72, 0.82, 0.92, 0.10)
        }

        Item {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: 18
            }

            width: 40

            MiniBars {
                visible: row.current
                anchors.centerIn: parent
                width: 18
                height: 18
                active: bar.mediaPlaying
            }

            Rectangle {
                visible: !row.current
                anchors.centerIn: parent
                width: 36
                height: 36
                radius: 8
                color: Qt.rgba(0.10, 0.14, 0.18, 0.75)
                border.width: 1
                border.color: Qt.rgba(0.72, 0.82, 0.92, 0.10)
                clip: true

                Image {
                    anchors.fill: parent
                    source: bar.musicArtSource(row.entry.art || "")
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: source.toString().length > 0
                }
            }
        }

        Column {
            anchors {
                left: parent.left
                right: timeText.left
                verticalCenter: parent.verticalCenter
                leftMargin: 82
                rightMargin: 10
            }

            spacing: 3

            Text {
                width: parent.width
                text: row.entry.title || "Spotify"
                color: row.current ? bar.accent : bar.text
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.weight: row.current ? Font.DemiBold : Font.Medium
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                width: parent.width
                text: row.entry.artist || ""
                color: bar.dimText
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        Text {
            id: timeText

            anchors {
                right: moreIcon.left
                verticalCenter: parent.verticalCenter
                rightMargin: 16
            }

            width: 44
            text: row.entry.length > 0 ? bar.formatMediaTime(row.entry.length) : "--"
            color: bar.dimText
            horizontalAlignment: Text.AlignRight
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
        }

        IconCanvas {
            id: moreIcon

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: 18
            }

            width: 22
            height: 22
            iconName: "more"
            lineColor: row.hovered ? bar.text : bar.dimText
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: row.hovered = true
            onExited: row.hovered = false
            onClicked: {
                if (row.current)
                    bar.toggleMedia()
            }
        }
    }

    component AppSearchTab: Item {
        id: tab

        property string modeKey: "all"
        property string label: "All"
        property string iconName: "grid"
        readonly property bool selected: bar.appSearchMode === modeKey
        property bool hovered: false

        width: Math.max(62, labelText.implicitWidth + 42)
        height: 32

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: tab.selected
                ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.17)
                : tab.hovered ? Qt.rgba(0.82, 0.88, 0.94, 0.09) : "transparent"
            border.width: tab.selected || tab.hovered ? 1 : 0
            border.color: tab.selected
                ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.82)
                : Qt.rgba(0.74, 0.82, 0.90, 0.16)

            Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }

        IconCanvas {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: 12
            }
            width: 15
            height: 15
            iconName: tab.iconName
            lineColor: tab.selected ? bar.accent : tab.hovered ? bar.text : bar.dimText
        }

        Text {
            id: labelText

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: 34
            }
            text: tab.label
            color: tab.selected ? bar.text : tab.hovered ? bar.text : Qt.rgba(0.80, 0.87, 0.94, 0.84)
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            font.weight: tab.selected ? Font.DemiBold : Font.Medium
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: tab.hovered = true
            onExited: tab.hovered = false
            onClicked: bar.setAppSearchMode(tab.modeKey)
        }
    }

    component AppSearchRow: Rectangle {
        id: row

        property var entry: ({})
        property int rowIndex: 0
        property bool hovered: false
        readonly property bool selected: bar.appSearchIndex === rowIndex
        readonly property string entryName: bar.textOf(entry ? entry.name : "")
        readonly property string entrySub: bar.textOf(entry ? (entry.genericName || entry.comment || "Application") : "Application")
        readonly property string entryKind: bar.appEntryKind(entry)

        height: 45
        radius: 11
        color: row.selected || row.hovered ? Qt.rgba(0.090, 0.110, 0.125, 0.72) : Qt.rgba(0.040, 0.052, 0.062, 0.44)
        border.width: row.selected || row.hovered ? 1 : 1
        border.color: row.selected
            ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.56)
            : row.hovered ? Qt.rgba(0.78, 0.86, 0.94, 0.24) : Qt.rgba(0.74, 0.82, 0.90, 0.12)
        clip: true

        Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }

        IconImage {
            id: appIcon

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: 16
            }
            implicitSize: 26
            asynchronous: true
            source: Quickshell.iconPath(row.entry ? row.entry.icon : "", "application-x-executable")
        }

        Column {
            anchors {
                left: appIcon.right
                right: kindText.left
                verticalCenter: parent.verticalCenter
                leftMargin: 14
                rightMargin: 14
            }
            spacing: 2

            Text {
                width: parent.width
                text: row.entryName
                color: bar.text
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                width: parent.width
                text: row.entrySub
                color: bar.dimText
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        Text {
            id: kindText

            anchors {
                right: arrow.left
                verticalCenter: parent.verticalCenter
                rightMargin: 18
            }
            width: 72
            text: row.entryKind === "settings" ? "Settings" : row.entryKind === "files" ? "Folder" : row.entryKind === "web" ? "Web" : "App"
            color: row.selected ? bar.text : Qt.rgba(0.80, 0.87, 0.94, 0.78)
            horizontalAlignment: Text.AlignRight
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        IconCanvas {
            id: arrow

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: 16
            }
            width: 16
            height: 16
            iconName: "arrow-right"
            lineColor: row.selected || row.hovered ? bar.text : bar.dimText
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                row.hovered = true
                bar.appSearchIndex = row.rowIndex
            }
            onExited: row.hovered = false
            onClicked: {
                bar.appSearchIndex = row.rowIndex
                bar.launchAppSearchEntry(row.entry)
            }
        }
    }

    component LauncherTile: Rectangle {
        id: tile

        property string iconName: "folder"
        property string label: "Files"
        property string command: ""
        property bool hovered: false

        radius: 14
        color: hovered ? Qt.rgba(0.090, 0.110, 0.125, 0.88) : Qt.rgba(0.047, 0.058, 0.068, 0.66)
        border.width: 1
        border.color: hovered ? Qt.rgba(0.78, 0.86, 0.94, 0.28) : Qt.rgba(0.74, 0.82, 0.90, 0.16)
        clip: true

        Behavior on color {
            ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        Column {
            anchors.centerIn: parent
            width: parent.width - 10
            spacing: 8

            IconCanvas {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 29
                height: 29
                iconName: tile.iconName
                lineColor: tile.hovered ? bar.text : Qt.rgba(0.78, 0.86, 0.94, 0.88)
            }

            Text {
                width: parent.width
                text: tile.label
                color: tile.hovered ? bar.text : Qt.rgba(0.80, 0.87, 0.94, 0.92)
                horizontalAlignment: Text.AlignHCenter
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onEntered: tile.hovered = true
            onExited: tile.hovered = false
            onClicked: {
                if (tile.label === "Music") {
                    var origin = tile.mapToItem(launcherMotion, 0, 0)
                    bar.openMusic(origin.x, origin.y, tile.width, tile.height)
                } else if (tile.command.length > 0) {
                    bar.runCommand(tile.command)
                } else if (tile.label === "Themes") {
                    bar.openThemes()
                }
            }
        }
    }

    component QuickLink: Rectangle {
        id: link

        property string iconName: "home"
        property string label: "Home"
        property string command: ""
        property bool hovered: false

        width: parent ? parent.width : 240
        height: 34
        radius: 10
        color: hovered ? Qt.rgba(0.090, 0.110, 0.125, 0.68) : "transparent"
        border.width: hovered ? 1 : 0
        border.color: Qt.rgba(0.74, 0.82, 0.90, 0.13)

        Behavior on color {
            ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        IconCanvas {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: 10
            }

            width: 21
            height: 21
            iconName: link.iconName
            lineColor: link.hovered ? bar.text : Qt.rgba(0.74, 0.82, 0.90, 0.84)
        }

        Text {
            anchors {
                left: parent.left
                right: arrow.left
                verticalCenter: parent.verticalCenter
                leftMargin: 42
                rightMargin: 8
            }

            text: link.label
            color: link.hovered ? bar.text : Qt.rgba(0.80, 0.87, 0.94, 0.90)
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        IconCanvas {
            id: arrow

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: 8
            }

            width: 17
            height: 17
            iconName: "arrow-right"
            lineColor: link.hovered ? bar.text : bar.dimText
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onEntered: link.hovered = true
            onExited: link.hovered = false
            onClicked: bar.runCommand(link.command)
        }
    }

    component MediaCard: Rectangle {
        id: card

        property bool hovered: false

        width: 44
        height: 148
        radius: 14
        color: bar.musicOpen || card.hovered
            ? Qt.rgba(0.074, 0.086, 0.096, 0.72)
            : bar.mediaAvailable ? Qt.rgba(0.060, 0.068, 0.074, 0.64) : Qt.rgba(0.058, 0.064, 0.070, 0.48)
        border.width: 1
        border.color: bar.musicOpen || card.hovered
            ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.46)
            : bar.mediaAvailable ? Qt.rgba(0.72, 0.80, 0.88, 0.24) : bar.line
        clip: true

        Behavior on color { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 130; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: card.hovered = true
            onExited: card.hovered = false
            onClicked: bar.toggleMusic()
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 6
                rightMargin: 6
                topMargin: 2
            }

            height: 1
            color: Qt.rgba(1.0, 1.0, 1.0, 0.10)
        }

        Column {
            anchors {
                fill: parent
                margins: 5
            }

            spacing: 4

            Rectangle {
                id: artFrame

                anchors.horizontalCenter: parent.horizontalCenter
                width: 32
                height: 32
                radius: 8
                color: Qt.rgba(0.10, 0.11, 0.12, 0.70)
                border.width: 1
                border.color: Qt.rgba(0.85, 0.88, 0.90, 0.13)
                clip: true

                Image {
                    id: mediaArt

                    anchors.fill: parent
                    source: bar.mediaArtSource()
                    visible: false
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                }

                Rectangle {
                    id: mediaArtMask

                    anchors.fill: mediaArt
                    radius: artFrame.radius
                    visible: false
                }

                OpacityMask {
                    anchors.fill: mediaArt
                    source: mediaArt
                    maskSource: mediaArtMask
                    visible: mediaArt.source.toString().length > 0 && mediaArt.status === Image.Ready
                }

                Rectangle {
                    anchors.fill: parent
                    visible: mediaArt.source.toString().length === 0 || mediaArt.status !== Image.Ready
                    color: Qt.rgba(0.075, 0.083, 0.090, 0.95)

                    IconCanvas {
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        iconName: "music"
                        lineColor: bar.mediaAvailable ? bar.text : bar.dimText
                    }
                }
            }

            Text {
                width: parent.width
                height: 10
                text: bar.mediaTitle
                color: bar.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 7
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                width: parent.width
                height: 8
                text: bar.mediaArtist
                color: bar.dimText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 6
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Item {
                id: waveform

                anchors.horizontalCenter: parent.horizontalCenter
                width: 32
                height: 18

                readonly property real barStep: width / Math.max(1, bar.cavaBars.length)

                Repeater {
                    model: bar.cavaBars

                    Rectangle {
                        width: Math.max(1.5, waveform.barStep * 0.48)
                        height: Math.max(3, waveform.height * (bar.cavaReady ? modelData : 0.08))
                        x: index * waveform.barStep + (waveform.barStep - width) / 2
                        y: Math.round((waveform.height - height) / 2)
                        radius: 1
                        color: bar.mediaPlaying ? Qt.rgba(0.78, 0.82, 0.84, 0.66) : Qt.rgba(0.58, 0.62, 0.64, 0.30)

                        Behavior on height {
                            NumberAnimation { duration: 70; easing.type: Easing.OutCubic }
                        }

                        Behavior on color {
                            ColorAnimation { duration: 160; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 32
                height: 12

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }

                    height: 2
                    radius: 1
                    color: Qt.rgba(0.82, 0.86, 0.88, 0.18)

                    Rectangle {
                        width: parent.width * bar.mediaProgress
                        height: parent.height
                        radius: parent.radius
                        color: Qt.rgba(0.84, 0.86, 0.86, 0.72)

                        Behavior on width {
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: bar.mediaAvailable && bar.mediaLength > 0
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        bar.seekMedia(mouse.x / Math.max(1, width))
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 34
                height: 8
                spacing: 2

                Text {
                    width: 16
                    text: bar.mediaAvailable ? bar.formatMediaTime(bar.mediaPosition) : "1:28"
                    color: bar.dimText
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 5
                    horizontalAlignment: Text.AlignLeft
                }

                Text {
                    width: 16
                    text: bar.mediaAvailable && bar.mediaLength > 0 ? bar.formatMediaTime(bar.mediaLength) : "3:45"
                    color: bar.dimText
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 5
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 36
                height: 19
                spacing: 2

                MediaMiniButton {
                    kind: "previous"
                    controlEnabled: Boolean(bar.mediaPlayer && bar.mediaPlayer.canGoPrevious)
                    onPressed: bar.previousMedia()
                }

                MediaMiniButton {
                    width: 14
                    height: 18
                    kind: bar.mediaPlaying ? "pause" : "play"
                    primary: true
                    controlEnabled: Boolean(bar.mediaAvailable)
                    onPressed: bar.toggleMedia()
                }

                MediaMiniButton {
                    kind: "next"
                    controlEnabled: Boolean(bar.mediaPlayer && bar.mediaPlayer.canGoNext)
                    onPressed: bar.nextMedia()
                }
            }
        }

    }

    component MediaMiniButton: Item {
        id: root

        property string kind: "play"
        property bool primary: false
        property bool controlEnabled: true
        property bool hovered: false
        signal pressed()

        width: 10
        height: 18
        opacity: controlEnabled ? 1.0 : 0.34

        Rectangle {
            anchors.centerIn: parent
            width: root.primary ? 14 : 10
            height: root.primary ? 14 : 10
            radius: width / 2
            color: root.primary
                ? Qt.rgba(0.78, 0.80, 0.80, root.hovered ? 0.26 : 0.18)
                : root.hovered ? Qt.rgba(0.78, 0.80, 0.80, 0.13) : "transparent"
            border.width: root.primary ? 1 : 0
            border.color: Qt.rgba(0.88, 0.90, 0.90, 0.18)
        }

        IconCanvas {
            anchors.centerIn: parent
            width: root.primary ? 11 : 9
            height: root.primary ? 11 : 9
            iconName: root.kind
            lineColor: root.primary ? bar.text : bar.dimText
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            enabled: root.controlEnabled
            cursorShape: Qt.PointingHandCursor

            onEntered: root.hovered = true
            onExited: root.hovered = false
            onClicked: root.pressed()
        }
    }

    component ClockButton: Rectangle {
        width: 44
        height: 34
        radius: 11
        color: bar.panelSoft
        border.width: 1
        border.color: bar.line

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 6
                rightMargin: 6
                topMargin: 2
            }

            height: 1
            color: Qt.rgba(1.0, 1.0, 1.0, 0.08)
        }

        Text {
            anchors {
                fill: parent
                leftMargin: 4
                rightMargin: 4
            }

            text: bar.clockText
            color: bar.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            elide: Text.ElideNone
        }
    }

    component SegmentedGroup: Rectangle {
        id: group

        property var items: []
        signal itemClicked(int index)
        signal itemHovered(int index)
        signal itemExited(int index)

        width: 44
        height: 8 + items.length * 38
        radius: 14
        color: Qt.rgba(0.065, 0.095, 0.120, 0.26)
        border.width: 1
        border.color: bar.line
        clip: true

        Repeater {
            model: Math.max(0, group.items.length - 1)

            Rectangle {
                x: 5
                y: 4 + (index + 1) * 38
                width: group.width - 10
                height: 1
                color: Qt.rgba(0.70, 0.82, 0.95, 0.13)
            }
        }

        Repeater {
            model: group.items

            IconButton {
                x: 3
                y: 4 + index * 38
                width: group.width - 6
                height: 38
                iconName: modelData.icon || "search"
                command: modelData.command || ""
                active: Boolean(modelData.active)
                warning: Boolean(modelData.warning)
                badge: modelData.badge || ""
                iconValue: modelData.value === undefined ? 1.0 : modelData.value

                onClicked: group.itemClicked(index)
                onHoverEntered: group.itemHovered(index)
                onHoverExited: group.itemExited(index)
            }
        }
    }

    component WorkspaceGroup: Rectangle {
        id: group

        width: 44
        height: 8 + 4 * 38
        radius: 14
        color: Qt.rgba(0.065, 0.095, 0.120, 0.26)
        border.width: 1
        border.color: bar.line
        clip: true

        Repeater {
            model: 4

            WorkspaceButton {
                x: 4
                y: 4 + index * 38
                number: index + 1
                active: Hyprland.focusedMonitor !== null
                    && Hyprland.focusedMonitor.activeWorkspace !== null
                    && Hyprland.focusedMonitor.activeWorkspace.id === index + 1
            }
        }
    }

    component WorkspaceButton: Item {
        id: root

        property int number: 1
        property bool active: false
        property bool hovered: false

        width: 36
        height: 38

        Rectangle {
            anchors.centerIn: parent
            width: root.active ? 30 : 28
            height: root.active ? 30 : 28
            radius: 9
            color: root.active
                ? Qt.rgba(0.11, 0.18, 0.23, 0.86)
                : root.hovered ? bar.panelHover : Qt.rgba(0.08, 0.12, 0.16, 0.30)
            border.width: root.active ? 2 : 1
            border.color: root.active
                ? bar.lineStrong
                : root.hovered ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.38) : bar.line

            Behavior on color {
                ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
            }

            Behavior on border.color {
                ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
        }

        Text {
            anchors.centerIn: parent
            text: String(root.number)
            color: root.active ? bar.text : bar.dimText
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
            font.weight: root.active ? Font.DemiBold : Font.Medium
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: root.hovered = true
            onExited: root.hovered = false
            onClicked: Hyprland.dispatch("workspace " + root.number)
        }
    }

    component IconButton: Item {
        id: root

        property string iconName: "search"
        property string command: ""
        property bool active: false
        property bool warning: false
        property bool hovered: false
        property string badge: ""
        property real iconValue: 1.0
        readonly property color resolvedColor: warning ? bar.warning : active ? bar.accent : bar.text

        signal clicked()
        signal hoverEntered()
        signal hoverExited()

        width: 38
        height: 38

        Process {
            id: actionProc

            running: false
            command: ["bash", "-lc", root.command]
            onExited: running = false
        }

        Rectangle {
            anchors.centerIn: parent
            width: 32
            height: 32
            radius: 10
            color: root.hovered || root.active ? bar.panelHover : "transparent"
            border.width: root.hovered || root.active ? 1 : 0
            border.color: root.active ? Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.42) : Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.22)

            Behavior on color {
                ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
        }

        IconCanvas {
            anchors.centerIn: parent
            width: 25
            height: 25
            iconName: root.iconName
            lineColor: root.resolvedColor
            value: root.iconValue
        }

        Rectangle {
            visible: root.badge.length > 0
            width: 14
            height: 14
            radius: 7
            x: parent.width - width - 4
            y: 4
            color: Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.24)
            border.width: 1
            border.color: Qt.rgba(bar.accent.r, bar.accent.g, bar.accent.b, 0.56)

            Text {
                anchors.centerIn: parent
                text: root.badge
                color: bar.text
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                root.hovered = true
                root.hoverEntered()
            }
            onExited: {
                root.hovered = false
                root.hoverExited()
            }
            onClicked: {
                if (root.command.length > 0 && !actionProc.running)
                    actionProc.running = true

                root.clicked()
            }
        }
    }

    component RailSeparator: Rectangle {
        width: 38
        height: 1
        radius: 1
        color: Qt.rgba(0.68, 0.82, 0.95, 0.16)
    }

    component IconCanvas: Canvas {
        id: canvas

        property string iconName: "search"
        property color lineColor: bar.text
        property real value: 1.0

        antialiasing: true

        onIconNameChanged: requestPaint()
        onLineColorChanged: requestPaint()
        onValueChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        function css(c, alpha) {
            var a = alpha === undefined ? c.a : alpha
            return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + a + ")"
        }

        function px(v, s, ox) {
            return ox + v * s
        }

        function rounded(ctx, x, y, w, h, r) {
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
        }

        function dot(ctx, x, y, r) {
            ctx.beginPath()
            ctx.arc(x, y, r, 0, Math.PI * 2)
            ctx.fill()
        }

        onPaint: {
            var ctx = getContext("2d")
            var s = Math.min(width, height)
            var ox = (width - s) / 2
            var oy = (height - s) / 2
            function x(v) { return px(v, s, ox) }
            function y(v) { return px(v, s, oy) }

            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = css(lineColor)
            ctx.fillStyle = css(lineColor)
            ctx.lineWidth = Math.max(1.45, s * 0.075)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            if (iconName === "palette") {
                ctx.beginPath()
                ctx.arc(x(0.46), y(0.50), s * 0.29, Math.PI * 0.18, Math.PI * 1.88)
                ctx.stroke()

                dot(ctx, x(0.34), y(0.40), s * 0.035)
                dot(ctx, x(0.46), y(0.32), s * 0.035)
                dot(ctx, x(0.55), y(0.45), s * 0.035)

                ctx.beginPath()
                ctx.moveTo(x(0.58), y(0.66))
                ctx.lineTo(x(0.78), y(0.34))
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.68), y(0.31))
                ctx.quadraticCurveTo(x(0.83), y(0.30), x(0.80), y(0.44))
                ctx.stroke()
            } else if (iconName === "search") {
                ctx.beginPath()
                ctx.arc(x(0.43), y(0.43), s * 0.23, 0, Math.PI * 2)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.61), y(0.61))
                ctx.lineTo(x(0.82), y(0.82))
                ctx.stroke()
            } else if (iconName === "folder") {
                ctx.beginPath()
                ctx.moveTo(x(0.17), y(0.38))
                ctx.lineTo(x(0.39), y(0.38))
                ctx.lineTo(x(0.45), y(0.47))
                ctx.lineTo(x(0.83), y(0.47))
                ctx.lineTo(x(0.83), y(0.78))
                ctx.lineTo(x(0.17), y(0.78))
                ctx.closePath()
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.18), y(0.48))
                ctx.lineTo(x(0.82), y(0.48))
                ctx.stroke()
            } else if (iconName === "grid") {
                rounded(ctx, x(0.20), y(0.18), s * 0.21, s * 0.21, s * 0.035)
                ctx.stroke()
                rounded(ctx, x(0.59), y(0.18), s * 0.21, s * 0.21, s * 0.035)
                ctx.stroke()
                rounded(ctx, x(0.20), y(0.58), s * 0.21, s * 0.21, s * 0.035)
                ctx.stroke()
                rounded(ctx, x(0.59), y(0.58), s * 0.21, s * 0.21, s * 0.035)
                ctx.stroke()
            } else if (iconName === "terminal") {
                ctx.beginPath()
                ctx.moveTo(x(0.25), y(0.29))
                ctx.lineTo(x(0.49), y(0.50))
                ctx.lineTo(x(0.25), y(0.71))
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.55), y(0.73))
                ctx.lineTo(x(0.79), y(0.73))
                ctx.stroke()
            } else if (iconName === "bell") {
                ctx.beginPath()
                ctx.moveTo(x(0.50), y(0.22))
                ctx.quadraticCurveTo(x(0.30), y(0.30), x(0.30), y(0.54))
                ctx.lineTo(x(0.23), y(0.68))
                ctx.lineTo(x(0.77), y(0.68))
                ctx.lineTo(x(0.70), y(0.54))
                ctx.quadraticCurveTo(x(0.70), y(0.30), x(0.50), y(0.22))
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.44), y(0.76))
                ctx.quadraticCurveTo(x(0.50), y(0.82), x(0.56), y(0.76))
                ctx.stroke()
            } else if (iconName === "volume" || iconName === "volume-muted") {
                ctx.beginPath()
                ctx.moveTo(x(0.17), y(0.43))
                ctx.lineTo(x(0.32), y(0.43))
                ctx.lineTo(x(0.50), y(0.28))
                ctx.lineTo(x(0.50), y(0.72))
                ctx.lineTo(x(0.32), y(0.57))
                ctx.lineTo(x(0.17), y(0.57))
                ctx.closePath()
                ctx.stroke()

                if (iconName === "volume-muted") {
                    ctx.beginPath()
                    ctx.moveTo(x(0.66), y(0.34))
                    ctx.lineTo(x(0.83), y(0.66))
                    ctx.moveTo(x(0.83), y(0.34))
                    ctx.lineTo(x(0.66), y(0.66))
                    ctx.stroke()
                } else {
                    ctx.beginPath()
                    ctx.arc(x(0.52), y(0.50), s * 0.16, -0.60, 0.60)
                    ctx.stroke()
                    ctx.beginPath()
                    ctx.arc(x(0.55), y(0.50), s * 0.28, -0.56, 0.56)
                    ctx.stroke()
                }
            } else if (iconName === "battery") {
                rounded(ctx, x(0.16), y(0.36), s * 0.62, s * 0.30, s * 0.045)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.82), y(0.44))
                ctx.lineTo(x(0.87), y(0.44))
                ctx.lineTo(x(0.87), y(0.58))
                ctx.lineTo(x(0.82), y(0.58))
                ctx.stroke()

                var fillW = Math.max(0.08, Math.min(0.48, 0.48 * value))
                ctx.fillStyle = css(lineColor, 0.34)
                rounded(ctx, x(0.24), y(0.43), s * fillW, s * 0.16, s * 0.025)
                ctx.fill()
            } else if (iconName === "browser") {
                ctx.beginPath()
                ctx.arc(x(0.50), y(0.50), s * 0.32, 0, Math.PI * 2)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.19), y(0.50))
                ctx.lineTo(x(0.81), y(0.50))
                ctx.moveTo(x(0.50), y(0.18))
                ctx.quadraticCurveTo(x(0.34), y(0.50), x(0.50), y(0.82))
                ctx.moveTo(x(0.50), y(0.18))
                ctx.quadraticCurveTo(x(0.66), y(0.50), x(0.50), y(0.82))
                ctx.stroke()
            } else if (iconName === "document") {
                ctx.beginPath()
                ctx.moveTo(x(0.27), y(0.15))
                ctx.lineTo(x(0.58), y(0.15))
                ctx.lineTo(x(0.75), y(0.32))
                ctx.lineTo(x(0.75), y(0.84))
                ctx.lineTo(x(0.27), y(0.84))
                ctx.closePath()
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.58), y(0.16))
                ctx.lineTo(x(0.58), y(0.33))
                ctx.lineTo(x(0.74), y(0.33))
                ctx.moveTo(x(0.37), y(0.50))
                ctx.lineTo(x(0.64), y(0.50))
                ctx.moveTo(x(0.37), y(0.63))
                ctx.lineTo(x(0.64), y(0.63))
                ctx.stroke()
            } else if (iconName === "download") {
                ctx.beginPath()
                ctx.moveTo(x(0.50), y(0.17))
                ctx.lineTo(x(0.50), y(0.62))
                ctx.moveTo(x(0.31), y(0.45))
                ctx.lineTo(x(0.50), y(0.64))
                ctx.lineTo(x(0.69), y(0.45))
                ctx.moveTo(x(0.24), y(0.81))
                ctx.lineTo(x(0.76), y(0.81))
                ctx.stroke()
            } else if (iconName === "trash") {
                ctx.beginPath()
                ctx.moveTo(x(0.25), y(0.32))
                ctx.lineTo(x(0.75), y(0.32))
                ctx.moveTo(x(0.40), y(0.22))
                ctx.lineTo(x(0.60), y(0.22))
                ctx.moveTo(x(0.45), y(0.22))
                ctx.lineTo(x(0.42), y(0.32))
                ctx.moveTo(x(0.55), y(0.22))
                ctx.lineTo(x(0.58), y(0.32))
                ctx.stroke()

                rounded(ctx, x(0.32), y(0.34), s * 0.36, s * 0.48, s * 0.035)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.42), y(0.44))
                ctx.lineTo(x(0.42), y(0.72))
                ctx.moveTo(x(0.50), y(0.44))
                ctx.lineTo(x(0.50), y(0.72))
                ctx.moveTo(x(0.58), y(0.44))
                ctx.lineTo(x(0.58), y(0.72))
                ctx.stroke()
            } else if (iconName === "home") {
                ctx.beginPath()
                ctx.moveTo(x(0.18), y(0.51))
                ctx.lineTo(x(0.50), y(0.23))
                ctx.lineTo(x(0.82), y(0.51))
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.27), y(0.47))
                ctx.lineTo(x(0.27), y(0.80))
                ctx.lineTo(x(0.73), y(0.80))
                ctx.lineTo(x(0.73), y(0.47))
                ctx.stroke()
            } else if (iconName === "desktop") {
                rounded(ctx, x(0.17), y(0.24), s * 0.66, s * 0.42, s * 0.035)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.50), y(0.66))
                ctx.lineTo(x(0.50), y(0.78))
                ctx.moveTo(x(0.34), y(0.80))
                ctx.lineTo(x(0.66), y(0.80))
                ctx.stroke()
            } else if (iconName === "image") {
                rounded(ctx, x(0.17), y(0.22), s * 0.66, s * 0.56, s * 0.045)
                ctx.stroke()

                dot(ctx, x(0.66), y(0.36), s * 0.045)

                ctx.beginPath()
                ctx.moveTo(x(0.24), y(0.70))
                ctx.lineTo(x(0.42), y(0.52))
                ctx.lineTo(x(0.55), y(0.65))
                ctx.lineTo(x(0.64), y(0.56))
                ctx.lineTo(x(0.77), y(0.70))
                ctx.stroke()
            } else if (iconName === "user") {
                ctx.beginPath()
                ctx.arc(x(0.50), y(0.34), s * 0.17, 0, Math.PI * 2)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.24), y(0.82))
                ctx.quadraticCurveTo(x(0.50), y(0.56), x(0.76), y(0.82))
                ctx.stroke()
            } else if (iconName === "edit") {
                rounded(ctx, x(0.20), y(0.22), s * 0.48, s * 0.56, s * 0.045)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.43), y(0.62))
                ctx.lineTo(x(0.75), y(0.30))
                ctx.moveTo(x(0.68), y(0.24))
                ctx.lineTo(x(0.81), y(0.37))
                ctx.moveTo(x(0.40), y(0.65))
                ctx.lineTo(x(0.35), y(0.78))
                ctx.lineTo(x(0.49), y(0.73))
                ctx.stroke()
            } else if (iconName === "activity") {
                ctx.beginPath()
                ctx.moveTo(x(0.16), y(0.62))
                ctx.lineTo(x(0.30), y(0.62))
                ctx.lineTo(x(0.40), y(0.34))
                ctx.lineTo(x(0.54), y(0.78))
                ctx.lineTo(x(0.66), y(0.48))
                ctx.lineTo(x(0.84), y(0.48))
                ctx.stroke()
            } else if (iconName === "star") {
                ctx.beginPath()
                ctx.moveTo(x(0.50), y(0.17))
                ctx.lineTo(x(0.60), y(0.39))
                ctx.lineTo(x(0.83), y(0.42))
                ctx.lineTo(x(0.66), y(0.58))
                ctx.lineTo(x(0.70), y(0.81))
                ctx.lineTo(x(0.50), y(0.69))
                ctx.lineTo(x(0.30), y(0.81))
                ctx.lineTo(x(0.34), y(0.58))
                ctx.lineTo(x(0.17), y(0.42))
                ctx.lineTo(x(0.40), y(0.39))
                ctx.closePath()
                ctx.stroke()
            } else if (iconName === "logout") {
                rounded(ctx, x(0.18), y(0.24), s * 0.38, s * 0.52, s * 0.045)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.50), y(0.50))
                ctx.lineTo(x(0.84), y(0.50))
                ctx.moveTo(x(0.70), y(0.36))
                ctx.lineTo(x(0.84), y(0.50))
                ctx.lineTo(x(0.70), y(0.64))
                ctx.stroke()
            } else if (iconName === "arrow-right") {
                ctx.beginPath()
                ctx.moveTo(x(0.38), y(0.25))
                ctx.lineTo(x(0.63), y(0.50))
                ctx.lineTo(x(0.38), y(0.75))
                ctx.stroke()
            } else if (iconName === "arrow-left") {
                ctx.beginPath()
                ctx.moveTo(x(0.62), y(0.25))
                ctx.lineTo(x(0.37), y(0.50))
                ctx.lineTo(x(0.62), y(0.75))
                ctx.stroke()
            } else if (iconName === "check") {
                ctx.beginPath()
                ctx.moveTo(x(0.25), y(0.52))
                ctx.lineTo(x(0.43), y(0.70))
                ctx.lineTo(x(0.76), y(0.30))
                ctx.stroke()
            } else if (iconName === "moon") {
                ctx.beginPath()
                ctx.arc(x(0.55), y(0.46), s * 0.29, Math.PI * 0.35, Math.PI * 1.63)
                ctx.quadraticCurveTo(x(0.38), y(0.61), x(0.54), y(0.78))
                ctx.quadraticCurveTo(x(0.30), y(0.74), x(0.22), y(0.52))
                ctx.quadraticCurveTo(x(0.17), y(0.30), x(0.35), y(0.18))
                ctx.quadraticCurveTo(x(0.30), y(0.40), x(0.55), y(0.46))
                ctx.stroke()
            } else if (iconName === "sun") {
                ctx.beginPath()
                ctx.arc(x(0.50), y(0.50), s * 0.18, 0, Math.PI * 2)
                ctx.stroke()
                for (var si = 0; si < 8; si += 1) {
                    var sa = si * Math.PI / 4
                    ctx.beginPath()
                    ctx.moveTo(x(0.50 + Math.cos(sa) * 0.30), y(0.50 + Math.sin(sa) * 0.30))
                    ctx.lineTo(x(0.50 + Math.cos(sa) * 0.40), y(0.50 + Math.sin(sa) * 0.40))
                    ctx.stroke()
                }
            } else if (iconName === "drop") {
                ctx.beginPath()
                ctx.moveTo(x(0.50), y(0.16))
                ctx.quadraticCurveTo(x(0.28), y(0.43), x(0.28), y(0.60))
                ctx.quadraticCurveTo(x(0.28), y(0.82), x(0.50), y(0.82))
                ctx.quadraticCurveTo(x(0.72), y(0.82), x(0.72), y(0.60))
                ctx.quadraticCurveTo(x(0.72), y(0.43), x(0.50), y(0.16))
                ctx.stroke()
            } else if (iconName === "circle") {
                ctx.beginPath()
                ctx.arc(x(0.50), y(0.50), s * 0.30, 0, Math.PI * 2)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(x(0.43), y(0.44), s * 0.10, Math.PI * 1.15, Math.PI * 2.15)
                ctx.stroke()
            } else if (iconName === "music") {
                ctx.beginPath()
                ctx.moveTo(x(0.36), y(0.27))
                ctx.lineTo(x(0.36), y(0.68))
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.36), y(0.27))
                ctx.lineTo(x(0.70), y(0.20))
                ctx.lineTo(x(0.70), y(0.60))
                ctx.stroke()

                dot(ctx, x(0.29), y(0.71), s * 0.105)
                dot(ctx, x(0.63), y(0.63), s * 0.105)
            } else if (iconName === "previous") {
                ctx.beginPath()
                ctx.moveTo(x(0.28), y(0.25))
                ctx.lineTo(x(0.28), y(0.75))
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.74), y(0.25))
                ctx.lineTo(x(0.36), y(0.50))
                ctx.lineTo(x(0.74), y(0.75))
                ctx.closePath()
                ctx.fill()
            } else if (iconName === "next") {
                ctx.beginPath()
                ctx.moveTo(x(0.72), y(0.25))
                ctx.lineTo(x(0.72), y(0.75))
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.26), y(0.25))
                ctx.lineTo(x(0.64), y(0.50))
                ctx.lineTo(x(0.26), y(0.75))
                ctx.closePath()
                ctx.fill()
            } else if (iconName === "play") {
                ctx.beginPath()
                ctx.moveTo(x(0.34), y(0.23))
                ctx.lineTo(x(0.76), y(0.50))
                ctx.lineTo(x(0.34), y(0.77))
                ctx.closePath()
                ctx.fill()
            } else if (iconName === "pause") {
                ctx.lineWidth = Math.max(1.55, s * 0.14)
                ctx.beginPath()
                ctx.moveTo(x(0.38), y(0.25))
                ctx.lineTo(x(0.38), y(0.75))
                ctx.moveTo(x(0.62), y(0.25))
                ctx.lineTo(x(0.62), y(0.75))
                ctx.stroke()
            } else if (iconName === "more") {
                dot(ctx, x(0.50), y(0.26), s * 0.045)
                dot(ctx, x(0.50), y(0.50), s * 0.045)
                dot(ctx, x(0.50), y(0.74), s * 0.045)
            } else if (iconName === "heart") {
                ctx.beginPath()
                ctx.moveTo(x(0.50), y(0.78))
                ctx.quadraticCurveTo(x(0.18), y(0.58), x(0.22), y(0.35))
                ctx.quadraticCurveTo(x(0.26), y(0.18), x(0.43), y(0.26))
                ctx.quadraticCurveTo(x(0.49), y(0.29), x(0.50), y(0.38))
                ctx.quadraticCurveTo(x(0.51), y(0.29), x(0.57), y(0.26))
                ctx.quadraticCurveTo(x(0.74), y(0.18), x(0.78), y(0.35))
                ctx.quadraticCurveTo(x(0.82), y(0.58), x(0.50), y(0.78))
                ctx.stroke()
            } else if (iconName === "shuffle") {
                ctx.beginPath()
                ctx.moveTo(x(0.18), y(0.32))
                ctx.quadraticCurveTo(x(0.38), y(0.32), x(0.50), y(0.50))
                ctx.quadraticCurveTo(x(0.62), y(0.68), x(0.82), y(0.68))
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.18), y(0.68))
                ctx.quadraticCurveTo(x(0.38), y(0.68), x(0.50), y(0.50))
                ctx.quadraticCurveTo(x(0.62), y(0.32), x(0.82), y(0.32))
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.73), y(0.24))
                ctx.lineTo(x(0.84), y(0.32))
                ctx.lineTo(x(0.73), y(0.40))
                ctx.moveTo(x(0.73), y(0.60))
                ctx.lineTo(x(0.84), y(0.68))
                ctx.lineTo(x(0.73), y(0.76))
                ctx.stroke()
            } else if (iconName === "repeat") {
                ctx.beginPath()
                ctx.moveTo(x(0.28), y(0.30))
                ctx.lineTo(x(0.70), y(0.30))
                ctx.quadraticCurveTo(x(0.82), y(0.30), x(0.82), y(0.42))
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.72), y(0.22))
                ctx.lineTo(x(0.84), y(0.30))
                ctx.lineTo(x(0.72), y(0.38))
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.72), y(0.70))
                ctx.lineTo(x(0.30), y(0.70))
                ctx.quadraticCurveTo(x(0.18), y(0.70), x(0.18), y(0.58))
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.28), y(0.78))
                ctx.lineTo(x(0.16), y(0.70))
                ctx.lineTo(x(0.28), y(0.62))
                ctx.stroke()
            } else if (iconName === "settings") {
                for (var i = 0; i < 8; i += 1) {
                    var a = i * Math.PI / 4
                    ctx.beginPath()
                    ctx.moveTo(x(0.50 + Math.cos(a) * 0.27), y(0.50 + Math.sin(a) * 0.27))
                    ctx.lineTo(x(0.50 + Math.cos(a) * 0.36), y(0.50 + Math.sin(a) * 0.36))
                    ctx.stroke()
                }

                ctx.beginPath()
                ctx.arc(x(0.50), y(0.50), s * 0.22, 0, Math.PI * 2)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(x(0.50), y(0.50), s * 0.075, 0, Math.PI * 2)
                ctx.stroke()
            }
        }
    }
}
