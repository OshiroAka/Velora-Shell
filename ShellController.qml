import QtQuick
import "platform" as Platform
import "core/SurfaceGeometry.js" as SurfaceGeometry
import "core/InfiniteDockGeometry.js" as InfiniteDockGeometry
import "core/NotificationMedia.js" as NotificationMedia
import "core" as Core
import "services" as Services
import "surfaces" as Surfaces
import "features/topbar" as TopBarFeature
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import "components"

Scope {
    id: root

    required property var composition
    Surfaces.WhatsAppWindowHost {
        id: whatsappWindowHost
        client: root.composition ? root.composition.whatsappService : null
        theme: root.composition ? root.composition.topbarTheme : null
        reducedMotion: root.composition ? root.composition.reducedMotion : false
    }
    property var edgeMediaPanels: ({})
    property var edgeFullHeightPanels: ({})
    readonly property bool edgeMediaOpen: Object.keys(edgeMediaPanels).length > 0
    property var edgeSpectrumPanels: ({})
    readonly property bool edgeSpectrumOpen: Object.keys(edgeSpectrumPanels).length > 0
    property var edgeDockProgress: ({})
    readonly property real visualizerDockProgress: Math.max(0, ...Object.values(edgeDockProgress))
    function setEdgeDockProgress(screenName, progress) {
        const next = Object.assign({}, edgeDockProgress)
        if (progress > .0001) next[screenName] = progress
        else delete next[screenName]
        edgeDockProgress = next
    }
    function setEdgeSpectrumVisible(screenName, visible) {
        const next = Object.assign({}, edgeSpectrumPanels)
        if (visible) next[screenName] = true
        else delete next[screenName]
        edgeSpectrumPanels = next
    }
    function setEdgeMediaVisible(screenName, visible, owner) {
        const next = Object.assign({}, edgeMediaPanels)
        if (visible) next[screenName] = owner
        else delete next[screenName]
        edgeMediaPanels = next
    }
    function setEdgeFullHeightVisible(screenName, visible) {
        const next = Object.assign({}, edgeFullHeightPanels)
        if (visible) next[screenName] = true
        else delete next[screenName]
        edgeFullHeightPanels = next
    }
    property alias unifiedTheme: veloraTheme
    function openUnifiedSettings() { closeQuickPopup(); composition.openEditor("desktop") }

    VeloraTheme {
        id: veloraTheme
        // The reference defines geometry, not a fixed blue palette. The
        // existing pywal pipeline remains the single color source.
        referencePalette: false
    }

    Component.onCompleted: Qt.callLater(function() {
        root.syncTopBarWindowGaps()
    })


    // Direct qs launches and hot reloads also honor the saved provider choice.
    // The helper only stops a known service with a matching D-Bus owner PID.
    Process {
        id: notificationProviderClaim
        running: true
        command: ["python3", Quickshell.shellDir + "/scripts/velora-notifications", "claim"]
        stdout: StdioCollector {
            onStreamFinished: if (text.trim()) console.info(text.trim())
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) console.warn("Velora notifications: " + text.trim())
        }
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
            root.playNotificationSound()
            root.showNotificationToast(notification)
        }
    }

    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    PwNodePeakMonitor {
        id: audioPeakMonitor

        node: Pipewire.defaultAudioSink
        // Velora.Native owns signal detection. The old peak monitor emitted
        // JavaScript changes continuously even after the text analyzer was
        // removed, keeping the qs main thread awake.
        enabled: false
    }

    Timer {
        id: audioSignalHoldTimer

        interval: 2200
        repeat: false
        onTriggered: {
            if (audioPeakMonitor.peak > 0.003) {
                restart()
                return
            }
            root.audioSignalRecentlyActive = false
        }
    }

    readonly property bool notificationsInTopbar: !!root.composition && root.composition.connectedNotifications
    property bool notificationToastVisible: false
    property bool notificationToastMounted: false
    property string notificationToastTitle: ""
    property string notificationToastBody: ""
    property string notificationToastApp: ""
    property string notificationToastIconKey: "bell"
    property string notificationToastId: ""
    property string notificationToastImage: ""
    property int notificationToastSerial: 0
    property var trackedNotificationObjects: ({})
    property var notificationDismissQueue: []
    readonly property string notificationSoundPath: Quickshell.env("VELORA_NOTIFICATION_SOUND") || "/usr/share/sounds/freedesktop/stereo/message.oga"
    readonly property int notificationHistoryCount: notificationHistoryModel.count
    property bool wallpaperSelectorOpen: false
    property bool settingsPanelOpen: false
    property bool idlePreloadEnabled: false
    property string quickPopupType: ""
    property string hoverPopupType: ""
    property bool quickPopupHoldOpen: false
    property bool sidebarPopupHovering: false
    property bool quickPopupHovering: false
    property bool weatherTopOpen: false
    readonly property bool weatherMenuEnabled: true
    property bool weatherTopWindowOpen: false
    property bool weatherTopKeyboardFocus: false
    property string weatherTopMode: "weather"
    property bool weatherTopTriggerHovering: false
    property bool weatherTopPanelHovering: false
    property int weatherTopFocusRequest: 0
    property bool wallpaperSelectorHovering: false
    property bool settingsPanelHovering: false
    property bool wallpaperSelectorWindowOpen: false
    property bool settingsPanelWindowOpen: false
    property bool wallpaperPreloadEnabled: false
    property bool settingsPanelPreloadEnabled: false
    property bool quickPopupPreloadEnabled: false
    property int quickPopupPreloadCount: 0

    property string appLaunchCommand: ""
    property string appliedWindowGaps: ""
    property string pendingWindowGaps: ""
    property int searchPopupFocusAttempts: 0
    property bool rightDashboardOpen: false
    property real topBarPopupCenterX: 0
    property bool topWallpaperPopupOpen: false
    property var wallpaperSelectorViews: ({})
    property bool topWallpaperKeyboardFocus: false
    property int topWallpaperOffset: 0
    readonly property var topWallpaperAllEntries: topWallpaperScan.entries
    property string topWallpaperMediaFilter: "all"
    property string topWallpaperColorFilter: ""
    property string topWallpaperSearchQuery: ""
    property bool topWallpaperFavoritesOnly: false
    property bool topWallpaperGridMode: false
    property var topWallpaperFavorites: []
    property var topWallpaperHidden: []
    property string topWallpaperActiveKey: ""
    property string topWallpaperErrorMessage: ""
    property var topWallpaperApplyingEntry: null
    property bool topWallpaperLibrarySaveQueued: false
    readonly property bool topWallpaperLibraryReady: topWallpaperScan.ready
    readonly property bool topWallpaperImporting: topWallpaperScan.importing
    property string activeRailControl: ""
    property string railControlHoverTarget: ""
    property bool railControlPanelHovered: false
    property int railFeedbackSerial: 0
    readonly property bool volumeControlOpen: activeRailControl === "volume"
    readonly property bool brightnessControlOpen: activeRailControl === "brightness"
    readonly property bool batteryControlOpen: activeRailControl === "battery"
    property bool leftMenuOpen: false
    property bool leftMenuHovering: false
    property bool leftMenuPinned: false
    property bool leftMenuTriggerHovering: false
    property bool leftMenuHandleHovering: false
    property bool leftMenuHandleRevealHold: false
    property bool leftMenuPanelHovering: false
    property bool leftMediaWindowOpen: false
    property bool leftMediaWindowHovering: false
    property bool leftMediaWindowEntranceHold: false
    property real leftMenuFrameReveal: leftMenuOpen ? 1 : 0
    property real leftMenuHandleSurfaceReveal: (!leftMenuOpen && (leftMenuTriggerHovering || leftMenuHandleHovering || leftMenuHandleRevealHold)) ? 1 : 0
    property real leftMediaWindowCenterY: 300
    property string leftDetailWindowType: "media"
    signal railMediaRequested()
    signal railWhatsAppRequested()
    property real leftDetailSwitchProgress: 1
    property bool leftMenuInteractiveFocus: false
    property bool leftMenuPreloadEnabled: false
    property string rightDashboardSection: "weather"
    property bool focusMode: false
    property int focusIndex: 0
    property real layoutSwitchOpacity: 1
    property string pendingLayoutPosition: ""
    readonly property bool topBarLayout: false
    readonly property bool sideBarLayoutEnabled: !topBarLayout
    // Temporarily hide the rail's media card; retain the shared media service.
    readonly property bool sidebarMediaEnabled: false
    readonly property int focusedWorkspaceId: Hyprland.focusedWorkspace
        ? Number(Hyprland.focusedWorkspace.id)
        : -1
    readonly property bool activeWorkspaceFullscreen: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.hasFullscreen : false
    readonly property bool shellSuppressedByFullscreen: activeWorkspaceFullscreen || (composition && composition.lockOccluding)
    property string infiniteDesktopCommand: ""
    property bool infiniteDesktopCanvasEnabled: false
    property bool infiniteDesktopStateReady: false
    readonly property bool infiniteDesktopBarsActive: infiniteDesktopTransition.effectiveActive
    readonly property real infiniteDesktopMorphProgress: infiniteDesktopTransition.progress
    readonly property real infiniteDesktopFrameFoldProgress: infiniteDesktopTransition.frameFold
    readonly property real infiniteDesktopSourceReveal: infiniteDesktopTransition.sourceReveal
    readonly property real infiniteDesktopTargetReveal: infiniteDesktopTransition.targetReveal
    readonly property real infiniteDesktopFrameRemaining: infiniteDesktopTransition.remaining
    readonly property real infiniteDesktopRailRemaining: infiniteDesktopTransition.railRemaining
    readonly property bool infiniteDesktopMorphing: infiniteDesktopTransition.moving
    property var infiniteDesktopPanels: ({})
    property alias notificationHistory: notificationHistoryModel
    Core.InfiniteDesktopTransition {
        id: infiniteDesktopTransition
        active: root.infiniteDesktopCanvasEnabled
        transformBars: !root.composition || root.composition.infiniteDesktopTopbarEnabled
        reducedMotion: !!root.composition && root.composition.reducedMotion
        pace: root.composition ? root.composition.motionTokens.pace : 1
    }
    readonly property string infiniteDesktopStatePath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/velora-infinite-desktop.state"
    readonly property bool infiniteDesktopGestureMounted: infiniteDesktopCommand.length > 0 && infiniteDesktopCanvasEnabled && !shellSuppressedByFullscreen
    readonly property bool barOnRight: veloraTheme.barPosition === "right"
    readonly property bool topWallpaperLibraryLoading: topWallpaperScan.running
    readonly property bool leftMenuOnLeft: true
    readonly property string leftMenuAttachSide: leftMenuOnLeft ? "left" : "right"
    readonly property bool rightSoftLayout: true
    readonly property real referenceScale: 1
    readonly property bool barBackgroundEnabled: !composition || composition.barBackgroundEnabled !== false
    readonly property int sidebarVisualWidth: 63
    readonly property real unifiedBarWavePhase: root.composition
        ? root.composition.unifiedBarWavePhase : 0
    readonly property int desktopFrameMargin: 0
    readonly property int sidebarOuterMargin: 0
    readonly property int sidebarVerticalMargin: 0
    readonly property int sidebarCornerRadius: 24
    readonly property int bottomBarHeight: 16
    readonly property int oppositeFrameWidth: 4
    readonly property int screenCornerRadius: 24
    readonly property int sideVisualizerWaveWidth: 58
    readonly property real sideVisualizerCapReach: Math.min(38, sideVisualizerWaveWidth * 0.46)
    readonly property int barPanelWidth: sideBarLayoutEnabled ? sidebarVisualWidth + sidebarOuterMargin : 0
    // Layer-shell exclusion is discrete. Animating it forces client layout and
    // Wayland configure roundtrips on every pose of an otherwise visual morph.
    readonly property int barReserveWidth: sideBarLayoutEnabled && !infiniteDesktopBarsActive ? barPanelWidth : 0
    readonly property int desktopFrameRadius: 24
    readonly property bool frameVisualsEnabled: veloraTheme.desktopFrameEnabled && !topBarLayout
    readonly property int frameVisualInset: frameVisualsEnabled ? desktopFrameMargin : 0
    readonly property bool frameVisualsMounted: frameVisualsEnabled || frameVisualsReveal > 0.01
    // The topbar is an independent overlay: the desktop frame must never rise
    // behind it or draw a second outline around the wallpaper.
    readonly property bool topBarFrameVisualsMounted: false
    readonly property bool topBarCenterVisualizerMounted: topBarLayout
        && !shellSuppressedByFullscreen
        && veloraTheme.visualizerStrength > 0.01
    readonly property bool systemControlCenterVisualizerMounted: topBarQuickPopupPanelVisible
        && visibleQuickPopupType === "system"
        && topBarSystemPage === "settings"
        && !shellSuppressedByFullscreen
    // The top-bar visualizer is part of the frame/cutout, not a separate rail.
    readonly property bool topBarFrameVisualizerMounted: false
    property real frameVisualsReveal: frameVisualsEnabled ? 1 : 0
    property bool sideVisualizerWithoutFrame: true
    readonly property bool screenVisualizerWanted: false
    readonly property bool sideVisualizerMounted: false
    readonly property bool screenVisualizerMounted: screenVisualizerWanted
    readonly property bool audioVisualizerMounted: sideVisualizerMounted
        || screenVisualizerMounted
        || topBarCenterVisualizerMounted
    property bool audioSignalRecentlyActive: false
    readonly property bool audioVisualizerProcessWanted: audioVisualizerMounted && audioSignalRecentlyActive
    property var topBarCavaValues: []

    readonly property real sideVisualizerReveal: frameVisualsMounted ? frameVisualsReveal : (sideVisualizerMounted ? 1 : 0)
    property real screenVisualizerReveal: screenVisualizerMounted ? 1 : 0
    readonly property real desktopFrameMatteOpacity: sidebarPanelGlassAlpha()
    readonly property int popupFrameGap: veloraTheme.popupAttachedToBar ? 0 : 14
    readonly property int sideQuickPopupBarClearance: 14
    readonly property string popupAttachSide: barOnRight ? "right" : "left"
    readonly property string topWallpaperHomeDir: Quickshell.env("HOME") || ""
    readonly property string topWallpaperDir: topWallpaperHomeDir + "/Pictures/Wallpapers"
    readonly property string topWallpaperScanScript: Quickshell.shellDir + "/scripts/velora-wallpaper-scan"
    readonly property string topWallpaperApplyScript: Quickshell.shellDir + "/scripts/velora-wallpaper-apply"
    readonly property string topWallpaperLibraryStateScript: Quickshell.shellDir + "/scripts/velora-wallpaper-library-state"
    readonly property string lyricsStateScript: Quickshell.shellDir + "/scripts/velora-lyrics-state"
    readonly property string filesCommand: "if command -v dolphin >/dev/null 2>&1; then dolphin \"$HOME\" >/dev/null 2>&1 & elif command -v thunar >/dev/null 2>&1; then thunar \"$HOME\" >/dev/null 2>&1 & else xdg-open \"$HOME\" >/dev/null 2>&1 & fi"
    readonly property string browserCommand: '"' + Quickshell.shellDir + '/scripts/velora-browser"'
    readonly property var topWallpaperFallbackEntries: []
    property var topWallpaperEntries: topWallpaperFallbackEntries
    readonly property int leftMenuWidth: 820
    readonly property int leftMenuPreferredHeight: 600
    readonly property int leftMenuTriggerWidth: 18
    readonly property int leftMenuHandleWidth: 52
    readonly property int leftMenuHandleHeight: 158
    readonly property int leftMenuFrameInset: frameVisualsEnabled ? desktopFrameMargin + 1 : desktopFrameMargin
    readonly property int leftMediaWindowWidth: 640
    readonly property int leftMediaWindowHeight: 690
    readonly property int leftMediaWindowGap: 12
    property real quickPopupCenterY: 300
    property bool quickPopupWindowOpen: false
    property string renderedQuickPopupType: ""
    property string pendingQuickPopupType: ""
    property real pendingQuickPopupCenterY: 0
    property real pendingTopBarPopupCenterX: 0
    property bool quickPopupSwitching: false
    property bool systemPopupKeyboardFocus: false
    property int systemPopupFocusWorkspaceId: -1
    property string topBarSystemPage: "settings"
    property int topBarSystemSlideDirection: 1
    property string topBarSystemPopupPreferredPage: ""
    property int topBarSystemPopupPreferredWidth: 0
    property int topBarSystemPopupPreferredHeight: 0
    readonly property var topBarSystemPages: ["settings", "wallpaper", "volume", "wifi", "display", "notifications", "bluetooth", "battery"]

    function applyInfiniteDesktopState(data) {
        const line = String(data || "").trim()
        if (line === "enabled=1")
            infiniteDesktopCanvasEnabled = true
        else if (line === "enabled=0")
            infiniteDesktopCanvasEnabled = false
    }

    function updateInfiniteDesktopFeature() {
        // install-session creates an empty marker for the bundled bridge.
        infiniteDesktopCommand = String(infiniteDesktopFeatureFile.text() || "").trim()
            || Quickshell.shellDir + "/scripts/infinite-desktop"
    }
    function registerInfiniteDesktopPanel(name, panel) {
        const next = Object.assign({}, infiniteDesktopPanels)
        if (panel) next[name] = panel
        else delete next[name]
        infiniteDesktopPanels = next
    }
    function infiniteDesktopLevels(name) {
        const panel = infiniteDesktopPanels[name]
        return panel ? panel.levelControls : null
    }
    onInfiniteDesktopCanvasEnabledChanged: {
        dismissTransientSurfaces()
        activeRailControl = ""
        exitFocus()
        if (composition) composition.closeTopbarTool()
    }

    onInfiniteDesktopCommandChanged: {
        infiniteDesktopCanvasEnabled = false
        infiniteDesktopStateReady = false
        if (infiniteDesktopCommand.length <= 0)
            return
        Qt.callLater(function() {
            if (!infiniteDesktopStateSync.running && root.infiniteDesktopCommand.length > 0)
                infiniteDesktopStateSync.running = true
        })
    }
    property bool lyricsAvailable: false
    property string lyricsTitle: ""
    property string lyricsArtist: ""
    property string lyricsLine: ""
    property string lyricsReason: ""
    property string lyricsTimingMode: ""
    property var lyricsContextLines: []
    property bool lyricsMaskEditorOpen: false
    property var lyricsMaskEditorPoints: []
    property var lyricsWords: []
    property int lyricsActiveIndex: -1
    property real lyricsPositionSeconds: 0
    property real lyricsDurationSeconds: 0
    property string lyricsGhostText: ""
    property int lyricsGhostSide: 0
    property real lyricsPhraseProgress: 1
    readonly property bool lyricsOverlayMounted: veloraTheme.lyricsEnabled && !shellSuppressedByFullscreen && (lyricsWords.length > 0 || lyricsReason === "between-lines")
    readonly property bool controlCenterLyricsWanted: topBarLayout
        && topBarQuickPopupPanelVisible
        && activeQuickPopupType === "system"
        && topBarSystemPage === "settings"
    readonly property bool lyricsServiceWanted: !shellSuppressedByFullscreen
        && (veloraTheme.lyricsEnabled
            || (topBarLayout && activeQuickPopupType === "media")
            || controlCenterLyricsWanted)
    readonly property bool wallpaperSelectorHoverPreview: hoverPopupType === "theme" && !wallpaperSelectorOpen
    readonly property bool settingsPanelHoverPreview: hoverPopupType === "settings" && !settingsPanelOpen
    readonly property bool wallpaperSelectorPreview: false
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
    readonly property bool batteryPopupVisualActive: sideQuickPopupPanelVisible && visibleQuickPopupType === "battery" && quickPopupSurfaceReveal > 0.015
    readonly property var cachedQuickPopupTypes: []
    readonly property var topBarCachedQuickPopupTypes: [
        "time",
        "search",
        "apps",
        "workspaces",
        "media",
        "system",
        "profile",
        "quickSettings",
        "settingsQuick"
    ]
    property real quickPopupSurfaceReveal: 0
    property real systemSheetOffsetY: 0
    property bool systemSheetClosing: false
    readonly property int quickPopupLineCloseDuration: veloraTheme.motionEnabled ? Math.max(180, veloraTheme.motionPanelOut) : 1
    readonly property int notificationToastOpenDuration: veloraTheme.motionEnabled ? Math.max(240, veloraTheme.motionPanelIn) : 1
    readonly property int notificationToastCloseDuration: veloraTheme.motionEnabled ? Math.max(300, Math.round(quickPopupLineCloseDuration * 1.35)) : 1
    readonly property bool sideQuickPopupAttachedToBar: quickPopupVisible && sideQuickPopupPanelVisible && quickPopupTypeAttachedToBar(visibleQuickPopupType)
    readonly property int sideQuickPopupBridgeWidth: sideQuickPopupAttachedToBar && sideVisualizerMounted && barOnRight ? Math.max(popupFrameGap, sideQuickPopupBarClearance) : 0
    readonly property bool quickPopupJoinedToBar: sideQuickPopupAttachedToBar && (popupFrameGap <= 0 || sideQuickPopupBridgeWidth > 0)
    readonly property real quickPopupTransitionContrast: (quickPopupVisible && sideQuickPopupPanelVisible) ? (quickPopupSurfaceReveal < 0.98 ? 0.30 : 0.12) : 0

    function shellQuote(value) {
        return "'" + String(value || "").replace(/'/g, "'\"'\"'") + "'"
    }


    function launchApp(command) {
        if (!command || command.length <= 0 || appLaunchProcess.running)
            return

        dismissTransientSurfaces()
        appLaunchCommand = command
        appLaunchProcess.running = true
    }

    function dismissTransientSurfaces() {
        closeQuickPopup()
        wallpaperSelectorOpen = false
        settingsPanelOpen = false
        closeWeatherTop()

        closeLegacyLeftMenu()
        toggleTopWallpaperPopup(false, false)
    }

    function syncTopBarWindowGaps() {
        const target = topBarLayout ? "92,30,25,30" : "25,25,25,25"
        if (target === appliedWindowGaps && pendingWindowGaps.length <= 0)
            return

        pendingWindowGaps = target
        if (typeof windowGapProcess === "undefined" || windowGapProcess.running)
            return

        applyPendingWindowGaps()
    }

    function clearLyricsOverlay(reason) {
        lyricsAvailable = false
        lyricsTitle = ""
        lyricsArtist = ""
        lyricsLine = ""
        lyricsReason = String(reason || "")
        lyricsTimingMode = ""
        lyricsContextLines = []
        lyricsWords = []
        lyricsActiveIndex = -1
        lyricsPositionSeconds = 0
        lyricsDurationSeconds = 0
        lyricsGhostText = ""
        lyricsGhostSide = 0
        lyricsPhraseProgress = 1
    }

    function applyLyricsPayload(payload) {
        if (!payload || payload.ok !== true || !payload.words || payload.words.length <= 0) {
            clearLyricsOverlay(payload && payload.reason ? payload.reason : "no-lyrics")
            return
        }

        const oldPhrase = lyricsPhraseForWords(lyricsWords, lyricsActiveIndex, 0)
        const nextWords = payload.words.slice()
        const nextActiveIndex = Math.max(0, Math.min(nextWords.length - 1, Number(payload.activeIndex) || 0))
        const nextPhrase = lyricsPhraseForWords(nextWords, nextActiveIndex, 0)

        if (lyricsCinematicModeActive() && oldPhrase.text.length > 0 && nextPhrase.text.length > 0 && oldPhrase.text !== nextPhrase.text) {
            lyricsGhostText = oldPhrase.text
            lyricsGhostSide = oldPhrase.side
            lyricsPhraseAnimation.stop()
            lyricsPhraseProgress = 0
            lyricsPhraseAnimation.start()
        } else if (lyricsPhraseProgress < 1 && nextPhrase.text.length <= 0) {
            lyricsPhraseProgress = 1
        }

        lyricsAvailable = true
        lyricsTitle = String(payload.title || "")
        lyricsArtist = String(payload.artist || "")
        lyricsLine = String(payload.line || "")
        lyricsTimingMode = String(payload.timingMode || "")
        lyricsContextLines = Array.isArray(payload.contextLines) ? payload.contextLines.slice(0, 4) : [{ text: lyricsLine, active: true }]
        lyricsWords = nextWords
        lyricsActiveIndex = nextActiveIndex
        lyricsPositionSeconds = Number(payload.position) || 0
        lyricsDurationSeconds = Number(payload.duration) || 0
        lyricsReason = ""
    }

    function lyricsCinematicModeActive() {
        return topBarLayout && veloraTheme.lyricsCinematicEnabled && veloraTheme.lyricsLayoutMode === "two"
    }

    function lyricsWordText(value) {
        return String(value || "").replace(/\s+/g, " ").trim()
    }

    function lyricsPhraseChunksFor(words) {
        const chunks = []
        const source = Array.isArray(words) ? words : []
        var current = []
        var start = 0

        for (let i = 0; i < source.length; i += 1) {
            const word = lyricsWordText(source[i])
            if (word.length <= 0)
                continue

            if (current.length <= 0)
                start = i
            current.push(word)

            const punctuationBreak = /[,;:?!]$/.test(word)
            const longWord = word.length >= 9
            const maxChunk = longWord ? 2 : 3
            if (punctuationBreak || current.length >= maxChunk || i === source.length - 1) {
                chunks.push({
                    text: current.join(" "),
                    start: start,
                    end: i + 1,
                    index: chunks.length,
                    side: chunks.length % 2
                })
                current = []
            }
        }

        return chunks
    }

    function lyricsPhraseForWords(words, activeIndex, offset) {
        const chunks = lyricsPhraseChunksFor(words)
        if (chunks.length <= 0)
            return { text: "", start: 0, end: 0, index: 0, side: 0 }

        const active = Math.max(0, Math.min((Array.isArray(words) ? words.length : 1) - 1, Number(activeIndex) || 0))
        var chunkIndex = 0
        for (let i = 0; i < chunks.length; i += 1) {
            if (active >= chunks[i].start && active < chunks[i].end) {
                chunkIndex = i
                break
            }
        }

        chunkIndex = Math.max(0, Math.min(chunks.length - 1, chunkIndex + (Number(offset) || 0)))
        return chunks[chunkIndex]
    }

    function lyricsCurrentPhrase() {
        return lyricsPhraseForWords(lyricsWords, lyricsActiveIndex, 0)
    }

    function lyricsNextPhrase() {
        return lyricsPhraseForWords(lyricsWords, lyricsActiveIndex, 1)
    }

    function renderedLyricsWords() {
        const words = Array.isArray(lyricsWords) ? lyricsWords : []
        if (words.length <= 0)
            return []

        const active = Math.max(0, Math.min(words.length - 1, lyricsActiveIndex))
        const mode = (veloraTheme.lyricsLayoutMode === "two" || veloraTheme.lyricsLayoutMode === "four")
            ? "progressive"
            : (veloraTheme.lyricsLayoutMode === "simple" ? "current" : veloraTheme.lyricsRevealMode)
        let first = 0
        let last = words.length

        if (mode === "current") {
            first = active
            last = active + 1
        } else if (mode === "progressive") {
            last = active + 1
        }

        const visible = []
        for (let i = first; i < last; i += 1)
            visible.push({ text: words[i], sourceIndex: i })
        return visible
    }

    function lyricsBlockSplitStart(blockIndex, blockCount) {
        const words = Array.isArray(lyricsWords) ? lyricsWords : []
        const count = Math.max(1, Number(blockCount) || 1)
        const index = Math.max(0, Math.min(count - 1, Number(blockIndex) || 0))
        return Math.floor(words.length * index / count)
    }

    function lyricsBlockSplitEnd(blockIndex, blockCount) {
        const words = Array.isArray(lyricsWords) ? lyricsWords : []
        const count = Math.max(1, Number(blockCount) || 1)
        const index = Math.max(0, Math.min(count - 1, Number(blockIndex) || 0))
        return Math.floor(words.length * (index + 1) / count)
    }

    function renderedLyricsBlockWords(blockIndex, blockCount) {
        const visible = renderedLyricsWords()
        const start = lyricsBlockSplitStart(blockIndex, blockCount)
        const end = lyricsBlockSplitEnd(blockIndex, blockCount)
        const blockWords = []
        for (let i = 0; i < visible.length; i += 1) {
            const word = visible[i]
            const sourceIndex = Number(word.sourceIndex)
            if (sourceIndex >= start && sourceIndex < end)
                blockWords.push(word)
        }
        return blockWords
    }

    function renderedLyricsSideWords(side) {
        return renderedLyricsBlockWords(side === "right" ? 1 : 0, 2)
    }

    function lyricsWordColor(sourceIndex, blockIndex) {
        const useBlockStyle = blockIndex !== undefined && Number(blockIndex) >= 0
        const blockMode = useBlockStyle ? veloraTheme.lyricsBlockColorMode(blockIndex) : "inherit"
        const colorMode = blockMode === "inherit" ? veloraTheme.lyricsColorMode : blockMode
        if (colorMode === "manual")
            return useBlockStyle && blockMode !== "inherit" ? veloraTheme.lyricsBlockManualColor(blockIndex) : veloraTheme.lyricsManualColor
        if (colorMode === "palette" && veloraTheme.lyricsPalette && veloraTheme.lyricsPalette.length > 0)
            return veloraTheme.lyricsPalette[Math.abs(Number(sourceIndex) || 0) % veloraTheme.lyricsPalette.length]
        return veloraTheme.lyricsPywalColor
    }

    function lyricsClampUnit(value) {
        const n = Number(value)
        if (isNaN(n))
            return 0
        return Math.max(0, Math.min(1, n))
    }

    function lyricsMixColor(a, b, amount, opacity) {
        const t = lyricsClampUnit(amount)
        const o = opacity === undefined ? (a.a + (b.a - a.a) * t) : lyricsClampUnit(opacity)
        return Qt.rgba(
            lyricsClampUnit(a.r + (b.r - a.r) * t),
            lyricsClampUnit(a.g + (b.g - a.g) * t),
            lyricsClampUnit(a.b + (b.b - a.b) * t),
            o
        )
    }

    function lyricsTextureNoise(sourceIndex) {
        const seed = Math.sin((Number(sourceIndex) + 1) * 12.9898) * 43758.5453
        return seed - Math.floor(seed)
    }

    function lyricsMaterialTarget(red, green, blue, alpha, texture) {
        return Qt.rgba(
            lyricsClampUnit(red + texture),
            lyricsClampUnit(green + texture),
            lyricsClampUnit(blue + texture),
            lyricsClampUnit(alpha)
        )
    }

    function lyricsMaterialColor(baseColor, sourceIndex, active) {
        const mode = veloraTheme.lyricsMaterialMode
        const intensity = lyricsClampUnit(veloraTheme.lyricsMaterialIntensity)
        const noise = lyricsTextureNoise(sourceIndex)
        const texture = (noise - 0.5) * 0.18 * intensity
        let result = baseColor

        if (mode === "cloud") {
            const target = lyricsMaterialTarget(0.72, 0.84, 0.98, baseColor.a, texture)
            result = lyricsMixColor(result, target, 0.34 + intensity * 0.42, baseColor.a)
        } else if (mode === "glass") {
            const target = lyricsMaterialTarget(0.88, 0.95, 1.0, baseColor.a, texture * 0.65)
            result = lyricsMixColor(result, target, 0.28 + intensity * 0.50, baseColor.a)
        } else if (mode === "metal") {
            const highlight = noise > 0.52 ? 0.80 : 0.42
            const target = lyricsMaterialTarget(highlight, highlight + 0.04, highlight + 0.10, baseColor.a, texture * 1.15)
            result = lyricsMixColor(result, target, 0.22 + intensity * 0.48, baseColor.a)
        } else if (mode === "sky") {
            const target = lyricsMaterialTarget(0.50, 0.68, 0.90, baseColor.a, texture * 0.80)
            result = lyricsMixColor(result, target, 0.28 + intensity * 0.44, baseColor.a)
        }

        if (veloraTheme.lyricsFogEnabled) {
            const fog = lyricsClampUnit(veloraTheme.lyricsFogIntensity)
            const target = Qt.rgba(0.68, 0.78, 0.90, result.a)
            result = lyricsMixColor(result, target, fog * (active ? 0.26 : 0.38), result.a)
        }

        return result
    }

    function lyricsRenderedWordOpacity(active) {
        let opacity = active ? 1.0 : 0.46
        const mode = veloraTheme.lyricsMaterialMode
        if (mode === "glass")
            opacity *= 1 - lyricsClampUnit(veloraTheme.lyricsMaterialIntensity) * 0.14
        else if (mode === "cloud" || mode === "sky")
            opacity *= 1 - lyricsClampUnit(veloraTheme.lyricsMaterialIntensity) * 0.07

        if (veloraTheme.lyricsFogEnabled)
            opacity *= 1 - lyricsClampUnit(veloraTheme.lyricsFogIntensity) * (active ? 0.18 : 0.26)

        return Math.max(active ? 0.48 : 0.18, Math.min(1, opacity))
    }

    function lyricsOutlineColor(active) {
        if (veloraTheme.lyricsDepthEnabled) {
            const depth = lyricsClampUnit(veloraTheme.lyricsDepthIntensity)
            const alpha = (active ? 0.18 : 0.12) + depth * (active ? 0.24 : 0.16)
            return Qt.rgba(0.05, 0.12, 0.20, alpha)
        }
        return veloraTheme.themeMode === "dark" ? Qt.rgba(0, 0, 0, 0.55) : Qt.rgba(0, 0, 0, 0.28)
    }

    function normalizedLyricsRepeatWord(value) {
        return String(value || "")
            .toLowerCase()
            .replace(/[^0-9a-zà-öø-ÿ]+/g, "")
            .replace(/(.)\1+/g, "$1")
    }

    function lyricsWordScale(sourceIndex) {
        const words = Array.isArray(lyricsWords) ? lyricsWords : []
        const index = Math.max(0, Math.min(words.length - 1, Number(sourceIndex) || 0))
        const current = normalizedLyricsRepeatWord(words[index])
        if (!current)
            return 1

        let repeat = 0
        for (let i = index - 1; i >= 0; i -= 1) {
            if (normalizedLyricsRepeatWord(words[i]) !== current)
                break
            repeat += 1
        }
        return 1 + Math.min(0.28, repeat * 0.08)
    }

    function lyricsBlockPositionX(panelWidth, blockIndex) {
        if (blockIndex === 1)
            return Math.round(Math.max(0, Math.min(panelWidth - 24, panelWidth * veloraTheme.lyricsSecondPositionX / 100)))
        if (blockIndex === 2)
            return Math.round(Math.max(0, Math.min(panelWidth - 24, panelWidth * veloraTheme.lyricsThirdPositionX / 100)))
        if (blockIndex === 3)
            return Math.round(Math.max(0, Math.min(panelWidth - 24, panelWidth * veloraTheme.lyricsFourthPositionX / 100)))
        return Math.round(Math.max(0, Math.min(panelWidth - 24, panelWidth * veloraTheme.lyricsPositionX / 100)))
    }

    function lyricsBlockPositionY(panelHeight, blockIndex) {
        if (blockIndex === 1)
            return Math.round(Math.max(0, Math.min(panelHeight - 24, panelHeight * veloraTheme.lyricsSecondPositionY / 100)))
        if (blockIndex === 2)
            return Math.round(Math.max(0, Math.min(panelHeight - 24, panelHeight * veloraTheme.lyricsThirdPositionY / 100)))
        if (blockIndex === 3)
            return Math.round(Math.max(0, Math.min(panelHeight - 24, panelHeight * veloraTheme.lyricsFourthPositionY / 100)))
        return Math.round(Math.max(0, Math.min(panelHeight - 24, panelHeight * veloraTheme.lyricsPositionY / 100)))
    }

    function lyricsBlockWidth(panelWidth, blockIndex) {
        const x = lyricsBlockPositionX(panelWidth, blockIndex)
        if (veloraTheme.lyricsLayoutMode === "four")
            return Math.max(140, panelWidth * 0.32)
        if (blockIndex === 0 && veloraTheme.lyricsLayoutMode === "two")
            return Math.max(160, panelWidth * 0.42)
        return Math.max(160, panelWidth - x - 24)
    }

    function lyricsBlockGlowEnabled(blockIndex) {
        if (blockIndex === undefined || Number(blockIndex) < 0)
            return veloraTheme.lyricsGlowEnabled
        return veloraTheme.lyricsBlockGlowEnabled(blockIndex)
    }

    function lyricsBlockGlowIntensity(blockIndex) {
        if (blockIndex === undefined || Number(blockIndex) < 0)
            return veloraTheme.lyricsGlowIntensity
        return veloraTheme.lyricsBlockGlowIntensity(blockIndex)
    }

    function openLyricsMaskEditor() {
        veloraTheme.applyLyricsMaskSettings(true, veloraTheme.lyricsMaskBrushSize, veloraTheme.lyricsMaskData, true)
        lyricsMaskEditorPoints = []
        lyricsMaskEditorOpen = true
        settingsPanelOpen = false
    }

    function closeLyricsMaskEditor() {
        lyricsMaskEditorPoints = []
        lyricsMaskEditorOpen = false
    }

    function normalizedMaskPoint(item, x, y) {
        return {
            x: Math.max(0, Math.min(1, Number(x) / Math.max(1, item.width))),
            y: Math.max(0, Math.min(1, Number(y) / Math.max(1, item.height)))
        }
    }

    function appendLyricsMaskPoint(item, x, y) {
        const next = normalizedMaskPoint(item, x, y)
        const points = Array.isArray(lyricsMaskEditorPoints) ? lyricsMaskEditorPoints.slice() : []
        const last = points.length > 0 ? points[points.length - 1] : null
        if (last) {
            const minDistance = Math.max(0.0025, veloraTheme.lyricsMaskBrushSize / Math.max(1, Math.max(item.width, item.height)) * 0.20)
            const dx = next.x - last.x
            const dy = next.y - last.y
            if (Math.sqrt(dx * dx + dy * dy) < minDistance)
                return
        }
        if (points.length >= 180)
            points[points.length - 1] = next
        else
            points.push(next)
        lyricsMaskEditorPoints = points
    }

    function commitLyricsMaskStroke() {
        const points = Array.isArray(lyricsMaskEditorPoints) ? lyricsMaskEditorPoints.slice() : []
        if (points.length < 2) {
            lyricsMaskEditorPoints = []
            return
        }

        let strokes = []
        try {
            strokes = JSON.parse(veloraTheme.lyricsMaskData || "[]")
        } catch (e) {
            strokes = []
        }
        if (!Array.isArray(strokes))
            strokes = []
        strokes.push({ brush: veloraTheme.lyricsMaskBrushSize, points: points })
        if (strokes.length > 14)
            strokes = strokes.slice(strokes.length - 14)
        veloraTheme.applyLyricsMaskSettings(true, veloraTheme.lyricsMaskBrushSize, JSON.stringify(strokes), true)
        lyricsMaskEditorPoints = []
    }

    function pollLyricsNow() {
        if (!lyricsServiceWanted) {
            clearLyricsOverlay("disabled")
            return
        }

        if (!lyricsQuery.running)
            lyricsQuery.running = true
    }

    function lyricsPollIntervalMs() {
        if (!lyricsAvailable && lyricsReason.length > 0 && lyricsReason !== "between-lines")
            return topBarLayout ? 700 : 360

        return topBarLayout ? 180 : 110
    }

    function applyPendingWindowGaps() {
        if (pendingWindowGaps.length <= 0 || typeof windowGapProcess === "undefined")
            return

        const target = pendingWindowGaps
        pendingWindowGaps = ""
        appliedWindowGaps = target
        windowGapProcess.command = ["hyprctl", "keyword", "general:gaps_out", target]
        windowGapProcess.running = true
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

    function notificationActionsJson(notification) {
        const output = []
        const actions = notification && notification.actions ? notification.actions : []
        for (let i = 0; i < actions.length; ++i) {
            const action = actions[i]
            if (!action)
                continue
            output.push({
                identifier: String(action.identifier || ""),
                text: String(action.text || action.identifier || "Ação")
            })
        }
        return JSON.stringify(output)
    }

    function normalizeNotification(notification) {
        const attachment = NotificationMedia.attachment(notification)
        const summary = notificationField(notification, ["summary", "title"], "")
        const body = notificationField(notification, ["body"], "")
        const appName = notificationField(notification, ["appName", "app", "app_name", "application", "desktopEntry", "desktop_entry", "app-name"], "Sistema")
        const iconName = notificationField(notification, ["appIcon", "app_icon", "icon", "image", "imagePath", "desktopEntry", "desktop_entry"], "")
        const desktopEntry = notificationField(notification, ["desktopEntry", "desktop_entry"], "")
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
            iconKey: notificationIconKey(appName, title, body, iconName),
            appIcon: iconName,
            desktopEntry: desktopEntry,
            imageSource: attachment.imageSource,
            openUrl: attachment.openUrl,
            actionable: attachment.openUrl.length > 0 || (notification && notification.actions
                ? notification.actions.some(action => action.identifier === "default") : false),
            urgency: notification && notification.urgency !== undefined ? Number(notification.urgency) : 1,
            resident: Boolean(notification && notification.resident),
            actionsJson: notificationActionsJson(notification)
        }
    }

    function upsertNotificationHistory(notification) {
        const item = normalizeNotification(notification)
        if (item.summary.length <= 0 && item.body.length <= 0)
            return

        const tracked = Object.assign({}, trackedNotificationObjects)
        tracked[item.id] = notification
        trackedNotificationObjects = tracked

        for (let i = 0; i < notificationHistoryModel.count; ++i) {
            const current = notificationHistoryModel.get(i)
            if ((item.id.length > 0 && current.id === item.id)
                    || (current.app === item.app && current.summary === item.summary && current.body === item.body
                        && current.openUrl === item.openUrl && current.imageSource === item.imageSource)) {
                notificationHistoryModel.set(i, item)
                if (i > 0)
                    notificationHistoryModel.move(i, 0, 1)
                return
            }
        }

        notificationHistoryModel.insert(0, item)
        while (notificationHistoryModel.count > 24) {
            const last = notificationHistoryModel.count - 1
            const discardedId = notificationHistoryModel.get(last).id
            notificationHistoryModel.remove(last)
            delete tracked[discardedId]
        }
        trackedNotificationObjects = tracked
    }

    function removeNotificationHistoryById(notificationId) {
        const id = String(notificationId || "")
        if (id.length <= 0)
            return

        for (let i = notificationHistoryModel.count - 1; i >= 0; --i) {
            if (notificationHistoryModel.get(i).id === id)
                notificationHistoryModel.remove(i)
        }

        const tracked = Object.assign({}, trackedNotificationObjects)
        delete tracked[id]
        trackedNotificationObjects = tracked
    }

    function clearNotificationHistory() {
        notificationHistoryModel.clear()
        trackedNotificationObjects = ({})
    }


    function queueNotificationDismiss(commandArguments) {
        const next = notificationDismissQueue.slice()
        next.push(commandArguments)
        notificationDismissQueue = next
        startNextNotificationDismiss()
    }

    function startNextNotificationDismiss() {
        if (notificationHistoryDismissProcess.running || notificationDismissQueue.length <= 0)
            return
        const next = notificationDismissQueue.slice()
        notificationHistoryDismissProcess.command = next.shift()
        notificationDismissQueue = next
        notificationHistoryDismissProcess.running = true
    }


    function dismissNotificationHistory(notificationId) {
        const id = String(notificationId || "")
        const notification = trackedNotificationObjects[id]
        if (notification) {
            try { notification.dismiss() } catch (error) {}
        } else if (/^[0-9]+$/.test(id)) {
            queueNotificationDismiss(["makoctl", "dismiss", "-n", id])
        }
        removeNotificationHistoryById(id)
    }

    function activateNotificationHistory(notificationId) {
        const id = String(notificationId || "")
        for (let i = 0; i < notificationHistoryModel.count; ++i) {
            const item = notificationHistoryModel.get(i)
            if (item.id === id && item.openUrl)
                return Qt.openUrlExternally(item.openUrl)
        }
        const notification = trackedNotificationObjects[id]
        if (notification) {
            try {
                for (const action of notification.actions) {
                    if (action.identifier === "default") {
                        action.invoke()
                        return true
                    }
                }
            } catch (error) { console.warn("Velora notification action: " + error) }
        }
        return false
    }

    function clickNotificationToast(notificationId, button) {
        if (button === Qt.LeftButton)
            activateNotificationHistory(notificationId)
        if (String(notificationId) === notificationToastId)
            hideNotificationToast()
    }


    function clearTrackedNotificationHistory() {
        const tracked = trackedNotificationObjects
        const ids = Object.keys(tracked)
        for (let i = 0; i < ids.length; ++i) {
            const notification = tracked[ids[i]]
            if (notification) {
                try { notification.dismiss() } catch (error) {}
            }
        }
        clearNotificationHistory()
        queueNotificationDismiss(["makoctl", "dismiss", "--all"])
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

        // The persistent clock alert owns its buttons and attached surface.
        // Keep the actionable notification in history without a second toast.
        if (item.app === "Velora · Temporizador" && composition.connectedNotifications)
            return

        notificationToastTitle = item.summary
        notificationToastBody = item.body
        notificationToastApp = item.app
        notificationToastIconKey = item.iconKey
        notificationToastId = item.id
        notificationToastImage = item.imageSource
        notificationToastSerial += 1
        notificationToastUnmountTimer.stop()
        notificationToastMounted = true
        notificationToastVisible = true
        notificationToastHideTimer.toastSerial = notificationToastSerial
        notificationToastHideTimer.restart()
    }

    function playNotificationSound() {
        if (notificationSoundProcess.running)
            notificationSoundProcess.running = false

        notificationSoundProcess.command = [
            "bash",
            "-lc",
            "sound=" + shellQuote(notificationSoundPath) + "; " +
            "if [ -f \"$sound\" ]; then " +
            "if command -v pw-play >/dev/null 2>&1; then pw-play \"$sound\" >/dev/null 2>&1; " +
            "elif command -v paplay >/dev/null 2>&1; then paplay \"$sound\" >/dev/null 2>&1; " +
            "elif command -v mpv >/dev/null 2>&1; then mpv --no-video --really-quiet \"$sound\" >/dev/null 2>&1; " +
            "fi; fi"
        ]
        notificationSoundProcess.running = true
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
        closeWeatherTop()
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

    SequentialAnimation {
        id: layoutSwitchAnimation

        NumberAnimation {
            target: root
            property: "layoutSwitchOpacity"
            to: 0.18
            duration: veloraTheme.motionEnabled ? 95 : 1
            easing.type: Easing.OutCubic
        }

        ScriptAction {
            script: root.applyPendingLayoutSwitch()
        }

        PauseAnimation {
            duration: veloraTheme.motionEnabled ? 18 : 1
        }

        NumberAnimation {
            target: root
            property: "layoutSwitchOpacity"
            to: 1
            duration: veloraTheme.motionEnabled ? 210 : 1
            easing.type: Easing.OutCubic
        }
    }


    Process {
        id: notificationSoundProcess

        running: false
        command: ["bash", "-lc", "true"]
        onExited: running = false
    }

    Process {
        id: notificationHistoryDismissProcess

        running: false
        command: ["true"]
        onExited: {
            running = false
            Qt.callLater(root.startNextNotificationDismiss)
        }
    }

    Process {
        id: appLaunchProcess

        running: false
        command: ["bash", "-lc", root.appLaunchCommand]
        onExited: running = false
    }

    FileView {
        id: infiniteDesktopFeatureFile

        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/velora-shell/infinite-desktop"
        preload: true
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: root.updateInfiniteDesktopFeature()
        onTextChanged: root.updateInfiniteDesktopFeature()
        onLoadFailed: root.infiniteDesktopCommand = ""
    }

    Process {
        id: infiniteDesktopStateSync

        running: root.infiniteDesktopCommand.length > 0
        command: root.infiniteDesktopCommand.length > 0
            ? [root.infiniteDesktopCommand, "sync-state"]
            : ["true"]

        stdout: SplitParser {
            onRead: function(data) {
                root.applyInfiniteDesktopState(data)
            }
        }

        onExited: {
            running = false
            root.infiniteDesktopStateReady = root.infiniteDesktopCommand.length > 0
            infiniteDesktopStateFile.reload()
        }
    }

    FileView {
        id: infiniteDesktopStateFile

        path: root.infiniteDesktopCommand.length > 0 ? root.infiniteDesktopStatePath : ""
        preload: root.infiniteDesktopCommand.length > 0
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: { root.infiniteDesktopStateReady = true; root.applyInfiniteDesktopState(text()) }
        onTextChanged: root.applyInfiniteDesktopState(text())
    }

    Process {
        id: lyricsQuery

        running: false
        command: [root.lyricsStateScript, "status", "--hide-between-lines", "--lead", (veloraTheme.lyricsSyncOffsetMs / 1000).toFixed(3)]

        stdout: SplitParser {
            onRead: function(data) {
                const line = String(data || "").trim()
                if (line.length <= 0)
                    return

                try {
                    root.applyLyricsPayload(JSON.parse(line))
                } catch (error) {
                    root.clearLyricsOverlay("parse-error")
                }
            }
        }

        onExited: running = false
    }

    NumberAnimation {
        id: lyricsPhraseAnimation

        target: root
        property: "lyricsPhraseProgress"
        from: 0
        to: 1
        duration: veloraTheme.motionEnabled ? 260 : 1
        easing.type: Easing.OutCubic
    }

    Timer {
        id: lyricsPollTimer

        interval: root.lyricsPollIntervalMs()
        repeat: true
        running: root.lyricsServiceWanted
        triggeredOnStart: true
        onTriggered: root.pollLyricsNow()
    }

    Connections {
        target: veloraTheme
        function onLyricsEnabledChanged() {
            if (root.lyricsServiceWanted)
                root.pollLyricsNow()
            else if (!root.lyricsServiceWanted)
                root.clearLyricsOverlay("disabled")
        }
    }

    Process {
        id: windowGapProcess

        running: false
        command: ["hyprctl", "keyword", "general:gaps_out", "25,25,25,25"]
        onExited: {
            running = false
            root.applyPendingWindowGaps()
        }
    }

    Services.WallpaperLibraryService {
        id: topWallpaperScan
        active: root.topWallpaperPopupOpen
        onEntriesChanged: root.recomputeTopWallpaperEntries(root.topWallpaperEntryKey(root.topWallpaperEntry(0)))
        onErrorChanged: root.topWallpaperErrorMessage=error
        onImported: (entries, message) => root.finishTopWallpaperImport(entries, message)
    }

    Process {
        id: topWallpaperLibraryLoad

        running: false
        command: [root.topWallpaperLibraryStateScript, "get"]

        stdout: SplitParser {
            onRead: function(data) {
                try {
                    const payload = JSON.parse(String(data).trim() || "{}")
                    root.topWallpaperFavorites = Array.isArray(payload.favorites) ? payload.favorites : []
                    root.topWallpaperHidden = Array.isArray(payload.hidden) ? payload.hidden : []
                    root.recomputeTopWallpaperEntries(root.topWallpaperActiveKey)
                } catch (error) {
                    root.topWallpaperFavorites = []
                    root.topWallpaperHidden = []
                }
            }
        }

        onExited: running = false
    }

    Process {
        id: topWallpaperActiveLoad

        running: false
        command: [root.topWallpaperLibraryStateScript, "active"]

        stdout: SplitParser {
            onRead: function(data) {
                try {
                    const payload = JSON.parse(String(data).trim() || "{}")
                    root.topWallpaperActiveKey = String(payload.key || "")
                    root.recomputeTopWallpaperEntries(root.topWallpaperActiveKey)
                } catch (error) {
                    root.topWallpaperActiveKey = ""
                }
            }
        }

        onExited: running = false
    }

    Timer {
        id: topWallpaperLibrarySaveTimer

        interval: 160
        repeat: false
        onTriggered: root.flushTopWallpaperLibraryState()
    }

    Process {
        id: topWallpaperLibrarySave

        running: false
        command: [root.topWallpaperLibraryStateScript, "set", "{}"]
        onExited: {
            running = false
            if (root.topWallpaperLibrarySaveQueued)
                topWallpaperLibrarySaveTimer.restart()
        }
    }

    Process {
        id: topWallpaperApply

        running: false
        command: [root.topWallpaperApplyScript, "static", ""]
        onExited: function(exitCode, exitStatus) {
            running = false
            if (exitCode === 0 && root.topWallpaperApplyingEntry) {
                root.topWallpaperActiveKey = root.topWallpaperEntryKey(root.topWallpaperApplyingEntry)
                root.topWallpaperErrorMessage = ""
                root.topWallpaperApplyingEntry = null
                if (root.topWallpaperPopupOpen)
                    root.toggleTopWallpaperPopup(false, false)
            } else if (exitCode !== 0) {
                root.topWallpaperApplyingEntry = null
                root.topWallpaperErrorMessage = "Não foi possível aplicar este wallpaper."
            }
            if (root.topWallpaperPopupOpen && exitCode === 0)
                topWallpaperPreloadRefreshTimer.restart()
        }
    }

    Process {
        id: topWallpaperPreload

        running: false
        command: [root.topWallpaperApplyScript, "__transition-preload-current"]
        onExited: running = false
    }

    Process {
        id: topWallpaperPreloadStop

        running: false
        command: [root.topWallpaperApplyScript, "__transition-preload-stop"]
        onExited: running = false
    }

    Timer {
        id: topWallpaperPreloadRefreshTimer

        interval: 1100
        repeat: false
        onTriggered: {
            if (root.topWallpaperPopupOpen && !topWallpaperPreload.running) {
                topWallpaperPreload.command = [root.topWallpaperApplyScript, "__transition-preload-current"]
                topWallpaperPreload.running = true
            }
        }
    }

    Timer {
        id: topWallpaperPreloadStopTimer

        interval: 1600
        repeat: false
        onTriggered: {
            if (!root.topWallpaperPopupOpen && !topWallpaperPreloadStop.running) {
                topWallpaperPreloadStop.command = [root.topWallpaperApplyScript, "__transition-preload-stop"]
                topWallpaperPreloadStop.running = true
            }
        }
    }

    Timer {
        id: topWallpaperDeferredScanTimer

        interval: 30
        repeat: false
        onTriggered: {
            if (root.topWallpaperPopupOpen) topWallpaperScan.refresh(false)
        }
    }

    readonly property var focusItems: sideBarLayoutEnabled
        ? ["caffeine", "notes", "discord", "volume",
            "brightness", "notifications", "bluetooth", "wifi"] : [
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
        const base = Math.max(veloraTheme.minOpacityForRole("sidebar"), Math.min(veloraTheme.sidebarOpacity, 0.98))
        return base
    }

    function sidebarBarGlassAlpha() {
        const base = Math.max(veloraTheme.minOpacityForRole("sidebar"), Math.min(veloraTheme.barOpacity, 0.98))
        return base
    }


    function batteryNeutralPanelColor() {
        return sidebarBarMaterialColor()
    }


    function quickPopupSurfaceGlass(type) {
        if (type === "battery")
            return batteryNeutralPanelColor()
        return sidebarBarMaterialColor()
    }

    function desktopFrameY(screenHeight) {
        return desktopFrameMargin
    }

    function topBarPanelTopMargin(screenHeight) {
        return 0
    }

    function topBarPanelHeight(screenHeight) {
        return Math.round(Math.min(54, Math.max(50, screenHeight * 0.045)))
    }


    function desktopFrameBottomInset(screenHeight) {
        return desktopFrameMargin
    }

    function desktopFrameHeight(screenHeight) {
        return Math.max(0, screenHeight - desktopFrameY(screenHeight) - desktopFrameBottomInset(screenHeight))
    }


    function normalizeTopWallpaperEntry(entry) {
        const source = entry || {}
        const kind = String(source.kind || "static").toLowerCase()
        const path = String(source.path || "")
        const lowerPath = path.toLowerCase()
        let mediaType = String(source.mediaType || "").toLowerCase()
        if (mediaType.length <= 0) {
            if (lowerPath.endsWith(".gif"))
                mediaType = "gif"
            else if (kind === "engine")
                mediaType = "engine"
            else if (kind === "live")
                mediaType = "vid"
            else
                mediaType = "img"
        }

        return {
            key: String(source.key || (kind + ":" + path)),
            kind: kind,
            mediaType: mediaType,
            path: path,
            preview: String(source.preview || (kind === "static" ? path : "")),
            title: String(source.title || source.label || path.split("/").pop() || "Wallpaper"),
            dominantColor: String(source.dominantColor || "#808080"),
            colorGroup: String(source.colorGroup || "neutral").toLowerCase(),
            addedAt: Number(source.addedAt || 0)
        }
    }

    function topWallpaperEntryKey(entry) {
        if (!entry)
            return ""
        return String(entry.key || (String(entry.kind || "static") + ":" + String(entry.path || "")))
    }

    function topWallpaperMatchesFilters(entry) {
        if (!entry || !entry.path)
            return false

        const key = topWallpaperEntryKey(entry)
        if (topWallpaperHidden.indexOf(String(entry.path)) >= 0 || topWallpaperHidden.indexOf(key) >= 0)
            return false

        const media = String(entry.mediaType || "img")
        if (topWallpaperMediaFilter === "img" && media !== "img")
            return false
        if (topWallpaperMediaFilter === "gif" && media !== "gif")
            return false
        if (topWallpaperMediaFilter === "vid" && media !== "vid" && media !== "engine")
            return false

        if (topWallpaperColorFilter.length > 0 && String(entry.colorGroup || "neutral") !== topWallpaperColorFilter)
            return false
        if (topWallpaperFavoritesOnly && topWallpaperFavorites.indexOf(key) < 0)
            return false

        const query = topWallpaperSearchQuery.trim().toLowerCase()
        if (query.length > 0) {
            const searchable = (String(entry.title || "") + " " + String(entry.path || "")).toLowerCase()
            if (searchable.indexOf(query) < 0)
                return false
        }
        return true
    }

    function topWallpaperControlCenterEntries() {
        const source = topWallpaperAllEntries && topWallpaperAllEntries.length > 0
            ? topWallpaperAllEntries
            : topWallpaperFallbackEntries
        const visible = []

        for (let index = 0; index < source.length; ++index) {
            const entry = normalizeTopWallpaperEntry(source[index])
            const key = topWallpaperEntryKey(entry)
            if (!entry.path)
                continue
            if (topWallpaperHidden.indexOf(String(entry.path)) >= 0
                    || topWallpaperHidden.indexOf(key) >= 0)
                continue
            visible.push(entry)
        }
        return visible
    }


    function recomputeTopWallpaperEntries(preferredKey) {
        const currentKey = String(preferredKey || topWallpaperEntryKey(topWallpaperEntry(0)))
        const source = topWallpaperAllEntries && topWallpaperAllEntries.length > 0
            ? topWallpaperAllEntries
            : topWallpaperFallbackEntries
        const next = []

        for (let i = 0; i < source.length; ++i) {
            const entry = normalizeTopWallpaperEntry(source[i])
            if (topWallpaperMatchesFilters(entry))
                next.push(entry)
        }

        topWallpaperEntries = next
        let targetIndex = 0
        if (currentKey.length > 0) {
            for (let index = 0; index < next.length; ++index) {
                if (topWallpaperEntryKey(next[index]) === currentKey) {
                    targetIndex = index
                    break
                }
            }
        }
        topWallpaperOffset = targetIndex
    }


    function queueTopWallpaperLibrarySave() {
        topWallpaperLibrarySaveQueued = true
        topWallpaperLibrarySaveTimer.restart()
    }

    function flushTopWallpaperLibraryState() {
        if (topWallpaperLibrarySave.running)
            return
        topWallpaperLibrarySaveQueued = false
        topWallpaperLibrarySave.command = [
            topWallpaperLibraryStateScript,
            "set",
            JSON.stringify({ favorites: topWallpaperFavorites, hidden: topWallpaperHidden })
        ]
        topWallpaperLibrarySave.running = true
    }


    function selectTopWallpaperAbsolute(index) {
        if (topWallpaperEntries.length <= 0)
            return
        topWallpaperOffset = ((Math.round(index) % topWallpaperEntries.length) + topWallpaperEntries.length) % topWallpaperEntries.length
    }


    function refreshTopWallpaperLibrary() {
        topWallpaperErrorMessage = ""
        topWallpaperScan.refresh(true)
    }

    function importTopWallpaperUrls(urls) {
        if (!topWallpaperScan.importUrls(urls)) return false
        toggleTopWallpaperPopup(true, true)
        return true
    }

    function finishTopWallpaperImport(entries, message) {
        if (entries.length) {
            const hidden = topWallpaperHidden.filter(value => !entries.some(entry =>
                value === entry.key || value === entry.path))
            if (hidden.length !== topWallpaperHidden.length) {
                topWallpaperHidden = hidden
                queueTopWallpaperLibrarySave()
            }
            for (const name in wallpaperSelectorViews) {
                const view = wallpaperSelectorViews[name]
                if (typeof view.selectEntry === "function") view.selectEntry(entries[0].key)
            }
        }
        topWallpaperErrorMessage = message
    }

    function topWallpaperEntry(index) {
        const entries = Array.isArray(topWallpaperEntries) ? topWallpaperEntries : topWallpaperFallbackEntries
        if (!entries || entries.length <= 0)
            return null
        const normalizedIndex = ((topWallpaperOffset + index) % entries.length + entries.length) % entries.length
        return entries[normalizedIndex]
    }

    function moveTopWallpaper(delta) {
        if (topWallpaperEntries.length <= 1) return
        selectTopWallpaperAbsolute(Math.max(0, Math.min(topWallpaperEntries.length - 1,
            topWallpaperOffset + (delta > 0 ? 1 : -1))))
    }

    function applyTopWallpaperSelection(entryOverride) {
        if (topWallpaperApply.running)
            return

        let item = entryOverride && entryOverride.path ? entryOverride : topWallpaperEntry(0)

        if (!item || !item.path)
            return

        topWallpaperErrorMessage = ""
        topWallpaperApplyingEntry = item
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
        if (nextOpen) {
            if (composition) composition.prepareWallpaperSelector()
        }
        topWallpaperPopupOpen = nextOpen
        topWallpaperKeyboardFocus = nextOpen && withKeyboardFocus === true

        if (topWallpaperPopupOpen) {
            activeRailControl = ""
            topWallpaperErrorMessage = ""
            topWallpaperPreloadStopTimer.stop()
            if (!topWallpaperPreload.running) {
                topWallpaperPreload.command = [root.topWallpaperApplyScript, "__transition-preload-current"]
                topWallpaperPreload.running = true
            }
            wallpaperSelectorOpen = false
            wallpaperSelectorWindowOpen = false
            settingsPanelOpen = false
            settingsPanelWindowOpen = false
            quickPopupType = ""
            rightDashboardOpen = false
            topWallpaperDeferredScanTimer.restart()
            if (!topWallpaperLibraryLoad.running)
                topWallpaperLibraryLoad.running = true
            if (!topWallpaperActiveLoad.running)
                topWallpaperActiveLoad.running = true
            recomputeTopWallpaperEntries(topWallpaperActiveKey)
        } else {
            topWallpaperPreloadRefreshTimer.stop()
            topWallpaperPreloadStopTimer.restart()
            topWallpaperDeferredScanTimer.stop()
        }
    }

    function openWeatherTop(withKeyboardFocus, mode) {
        if (mode !== "search" && composition && composition.referenceAppearance) {
            disableWeatherTopNow()
            if (weatherMenuEnabled) composition.showTopbarWeather()
            return
        }
        if (topBarLayout || (!weatherMenuEnabled && mode !== "search")) {
            disableWeatherTopNow()
            return
        }

        exitFocus()
        closeQuickPopup()
        wallpaperSelectorOpen = false
        wallpaperSelectorWindowOpen = false
        settingsPanelOpen = false
        settingsPanelWindowOpen = false

        closeLegacyLeftMenu()
        toggleTopWallpaperPopup(false, false)
        weatherTopUnmountTimer.stop()
        weatherTopMode = mode === "search" ? "search" : "weather"
        weatherTopKeyboardFocus = withKeyboardFocus === true
        weatherTopWindowOpen = true
        weatherTopOpen = true
        if (weatherTopKeyboardFocus)
            weatherTopFocusRequest += 1
    }

    function openWeatherTopFromMouse() {
        if (composition && composition.referenceAppearance) return
        if (topBarLayout || !weatherMenuEnabled)
            return

        weatherTopHoverCloseTimer.stop()
        if (!weatherTopOpen)
            openWeatherTop(false, "weather")
    }

    function disableWeatherTopNow() {
        weatherTopOpen = false
        weatherTopWindowOpen = false
        weatherTopKeyboardFocus = false
        weatherTopTriggerHovering = false
        weatherTopPanelHovering = false
        if (typeof weatherTopHoverCloseTimer !== "undefined")
            weatherTopHoverCloseTimer.stop()
        if (typeof weatherTopUnmountTimer !== "undefined")
            weatherTopUnmountTimer.stop()
    }

    function closeWeatherTop() {
        if (composition && composition.activeTopbarType === "weather") composition.closeTopbarTool()
        weatherTopOpen = false
        weatherTopKeyboardFocus = false
        weatherTopTriggerHovering = false
        weatherTopPanelHovering = false
        weatherTopHoverCloseTimer.stop()
        weatherTopUnmountTimer.restart()
    }

    function toggleWeatherTop() {
        if (composition && composition.referenceAppearance) {
            disableWeatherTopNow()
            if (weatherMenuEnabled) composition.toggleTopbarWeather()
            return
        }
        if (topBarLayout || !weatherMenuEnabled) {
            disableWeatherTopNow()
            return
        }

        if (weatherTopOpen && weatherTopMode === "weather")
            closeWeatherTop()
        else
            openWeatherTop(false, "weather")
    }

    function toggleTopSearch() {
        disableWeatherTopNow()
        closeQuickPopup()
        if (composition) composition.toggleSearch()
    }

    function switchToSideBarLayout(position) {
        veloraTheme.applyLayout(position, true)
    }

    function applyPendingLayoutSwitch() {
        if (pendingLayoutPosition.length <= 0)
            return

        switchToSideBarLayout(pendingLayoutPosition)
        pendingLayoutPosition = ""
    }

    function switchToSideBarLayoutWithFade(position) {
        pendingLayoutPosition = String(position || "left") === "right" ? "right" : "left"
        layoutSwitchAnimation.stop()
        layoutSwitchOpacity = 1
        layoutSwitchAnimation.restart()
    }

    function cycleBarLayout() {
        closeQuickPopup()
        closeWeatherTop()

        settingsPanelOpen = false
        settingsPanelWindowOpen = false

        switchToSideBarLayoutWithFade((!barOnRight) ? "right" : "left")
    }

    function engageWeatherTop() {
        if (!weatherTopOpen)
            return
        weatherTopKeyboardFocus = true
        weatherTopHoverCloseTimer.stop()
    }

    function setWeatherTopPanelHovering(inside) {
        weatherTopPanelHovering = inside
        if (inside)
            weatherTopHoverCloseTimer.stop()
        else
            scheduleWeatherTopHoverClose()
    }

    function scheduleWeatherTopHoverClose() {
        if (weatherTopKeyboardFocus)
            return
        if (!weatherTopTriggerHovering && !weatherTopPanelHovering)
            weatherTopHoverCloseTimer.restart()
    }

    function sidebarBarMaterialColor() {
        if (root.composition)
            return root.composition.unifiedBarSurface
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


    function desktopFrameBorderColor() {
        if (!frameVisualsMounted)
            return "transparent"
        if (veloraTheme.themeId === "pywal16")
            return veloraTheme.alpha(veloraTheme.sidebarBorderGlow, Math.min(0.18, Math.max(0.08, veloraTheme.sidebarBorderGlow.a * 0.50)))
        return veloraTheme.alpha(veloraTheme.borderSoft, veloraTheme.themeMode === "dark" ? 0.11 : 0.26)
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
        return target === "search" ? "search" : ""
    }


    function topBarSystemPageForType(type) {
        const value = String(type || "")
        if (value === "quickSettings" || value === "settingsQuick" || value === "settings" || value === "system")
            return "settings"
        if (value === "brightness")
            return "display"
        return topBarSystemPages.indexOf(value) >= 0 ? value : ""
    }

    function topBarSystemPageIndex(page) {
        const index = topBarSystemPages.indexOf(String(page || ""))
        return index >= 0 ? index : topBarSystemPages.length - 1
    }


    onActiveQuickPopupTypeChanged: {
        if (activeQuickPopupType.length > 0)
            activeRailControl = ""
        if (quickPopupVisible && activeQuickPopupType.length > 0) {
            renderedQuickPopupType = activeQuickPopupType
        }
        if (lyricsServiceWanted)
            pollLyricsNow()
        else if (!veloraTheme.lyricsEnabled)
            clearLyricsOverlay("disabled")
    }

    onFocusedWorkspaceIdChanged: {
        if (systemPopupKeyboardFocus
                && systemPopupFocusWorkspaceId >= 0
                && focusedWorkspaceId !== systemPopupFocusWorkspaceId) {
            releaseSystemPopupKeyboardFocus()
        }
    }

    onQuickPopupVisibleChanged: {
        if (quickPopupVisible) {
            quickPopupUnmountTimer.stop()
            quickPopupWindowOpen = true
            renderedQuickPopupType = activeQuickPopupType
            if (topBarLayout && activeQuickPopupType === "system") {
                quickPopupSurfaceRevealAnimation.stop()
                quickPopupSurfaceReveal = 1
                Qt.callLater(function() {
                    if (root.quickPopupVisible && root.activeQuickPopupType === "system")
                        root.animateSystemSheetOpen()
                })
            } else {
                systemSheetOpenAnimation.stop()
                systemSheetCloseAnimation.stop()
                systemSheetOffsetY = 0
                systemSheetClosing = false
                animateQuickPopupSurfaceReveal(1)
            }
            if (activeQuickPopupType === "search" || activeQuickPopupType === "apps")
                scheduleSearchPopupFocus()
        } else if (renderedQuickPopupType.length > 0) {
            prepareQuickPopupCloseAnimation()
            if (topBarLayout && renderedQuickPopupType === "system") {
                quickPopupSurfaceRevealAnimation.stop()
                quickPopupSurfaceReveal = 1
                animateSystemSheetClose()
            } else {
                animateQuickPopupSurfaceReveal(0)
            }
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


    function defaultQuickPopupCenterY(type) {
        if (type === "theme")
            return 212
        if (type === "settings")
            return 1018
        if (type === "weatherPanel")
            return 520
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
        if (type === "quickSettings")
            return 760
        if (type === "settingsQuick")
            return 1018
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

    function systemSheetTravelDistance() {
        if (typeof topBarPanel !== "undefined" && topBarPanel.popupHeight > 0)
            return topBarPanel.popupHeight + 28
        return 680
    }

    function currentSystemSheetOffset() {
        return systemSheetOffsetY
    }

    function setCurrentSystemSheetOffset(value) {
        systemSheetOffsetY = value
    }

    function animateSystemSheetOpen() {
        systemSheetCloseAnimation.stop()
        systemSheetOpenAnimation.stop()
        systemSheetClosing = false
        if (!veloraTheme.motionEnabled) {
            systemSheetOffsetY = 0
            return
        }
        const travel = systemSheetTravelDistance()
        const currentOffset = currentSystemSheetOffset()
        if (currentOffset <= 0.5 || currentOffset > travel + 40)
            setCurrentSystemSheetOffset(travel)
        systemSheetRiseAnimation.property = "systemSheetOffsetY"
        systemSheetSettleAnimation.property = systemSheetRiseAnimation.property
        systemSheetRiseAnimation.from = currentSystemSheetOffset()
        systemSheetRiseAnimation.to = -10
        systemSheetOpenAnimation.restart()
    }

    function animateSystemSheetClose() {
        systemSheetOpenAnimation.stop()
        systemSheetCloseAnimation.stop()
        systemSheetClosing = true
        if (!veloraTheme.motionEnabled) {
            setCurrentSystemSheetOffset(systemSheetTravelDistance())
            return
        }
        systemSheetCloseAnimation.property = "systemSheetOffsetY"
        systemSheetCloseAnimation.from = currentSystemSheetOffset()
        systemSheetCloseAnimation.to = systemSheetTravelDistance()
        systemSheetCloseAnimation.restart()
    }

    function queueQuickPopupSwitch(type, centerY, topCenterX) {
        const requestedType = String(type || "")
        if (requestedType.length <= 0)
            return

        quickPopupSwitchTimer.stop()
        pendingQuickPopupType = ""
        pendingQuickPopupCenterY = 0
        pendingTopBarPopupCenterX = 0
        quickPopupSwitching = true
        quickPopupHoldOpen = false
        hoverPopupType = ""
        sidebarPopupHovering = false
        quickPopupHovering = false
        hoverCloseTimer.stop()
        if (Number(topCenterX) > 0)
            setTopBarPopupCenter(topCenterX)
        setQuickPopupCenter(requestedType, centerY)
        renderedQuickPopupType = requestedType
        quickPopupWindowOpen = true
        quickPopupUnmountTimer.stop()
        quickPopupType = requestedType
        if (requestedType === "search" || requestedType === "apps")
            scheduleSearchPopupFocus()
        Qt.callLater(function() {
            root.quickPopupSwitching = false
        })
    }

    function prepareWallpaperSelector(centerY) {
        toggleTopWallpaperPopup(false, false)
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
        toggleTopWallpaperPopup(true, true)
    }

    function toggleWallpaperSelector(centerY, forceOpen) {
        exitFocus()
        toggleTopWallpaperPopup(forceOpen === true ? true : (forceOpen === false ? false : null), true)
    }


    function openQuickPopup(type, centerY, topCenterX) {
        if (["time", "agenda", "weatherPanel", "files", "browser", "wallpaperVisibility"].includes(type)) return

        if (["quickSettings","settingsQuick","settings"].includes(type)) {
            openUnifiedSettings()
            return
        }
        if (type === "search" || type === "apps") {
            toggleTopSearch()
            return
        }
        if (["wifi","bluetooth","brightness"].includes(type)) {
            if (type === "bluetooth" && sideBarLayoutEnabled) {
                for (const surface of sidebarPanels.instances) surface.bluetoothMenu.toggle()
            } else if (type === "wifi" && sideBarLayoutEnabled) {
                for (const surface of sidebarPanels.instances) surface.wifiMenu.toggle()
            } else openAdaptiveBarPopup(type, Number(centerY) || defaultQuickPopupCenterY(type))
            return
        }

        if (type === "volume" || type === "notifications") {
            openAdaptiveBarPopup(type, Number(centerY) || defaultQuickPopupCenterY(type))
            return
        }
        exitFocus()
        toggleTopWallpaperPopup(false, false)
        if (weatherTopOpen)
            closeWeatherTop()
        if (!quickPopupSwitching && activeQuickPopupType.length > 0 && activeQuickPopupType !== type && quickPopupSurfaceReveal > 0.08) {
            queueQuickPopupSwitch(type, centerY, topCenterX)
            return
        }
        if (type !== "search")
            quickPopupHoldOpen = false
        if (Number(topCenterX) > 0)
            setTopBarPopupCenter(topCenterX)
        setQuickPopupCenter(type, centerY)
        renderedQuickPopupType = type
        quickPopupWindowOpen = true
        quickPopupUnmountTimer.stop()
        hoverPopupType = ""
        hoverCloseTimer.stop()
        wallpaperSelectorOpen = false
        settingsPanelOpen = false
        quickPopupType = type
        if (type === "search" || type === "apps")
            scheduleSearchPopupFocus()
    }

    function scheduleSearchPopupFocus() {
        searchPopupFocusAttempts = 0
        searchPopupFocusTimer.restart()
    }

    function focusSearchPopupInput() {
        if (quickPopupType !== "search" && quickPopupType !== "apps")
            return

        if (typeof topBarPanel !== "undefined")
            topBarPanel.requestActivate()

        if (typeof panel !== "undefined")
            panel.forceActiveFocus(Qt.ShortcutFocusReason)

        if (typeof topBarPopupLoader !== "undefined") {
            topBarPopupLoader.forceActiveFocus(Qt.ShortcutFocusReason)
            const popup = topBarPopupLoader.itemForType(quickPopupType === "apps" ? "apps" : "search")
            if (popup) {
                popup.forceActiveFocus(Qt.ShortcutFocusReason)
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
            return 55
        if (type === "apps" || type === "search")
            return 210
        if (type === "workspaces")
            return 395
        if (type === "media")
            return screenWidth / 2
        if (type === "system" || type === "profile")
            return screenWidth - 24
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
        return barX + stageWidth / 2
    }

    function normalizeTopBarPopupCenterX(type, centerX) {
        const value = Number(centerX)
        if (!(value > 0) || Math.abs(value - defaultQuickPopupCenterY(type)) < 0.5)
            return defaultTopBarPopupCenterX(type)
        return value
    }

    function toggleTopBarQuickPopup(type, centerX) {
        const normalizedCenterX = normalizeTopBarPopupCenterX(type, centerX)
        if (quickPopupVisible && activeQuickPopupType !== type && quickPopupSurfaceReveal > 0.08) {
            toggleQuickPopup(type, defaultQuickPopupCenterY(type), normalizedCenterX)
            return
        }
        setTopBarPopupCenter(normalizedCenterX)
        toggleQuickPopup(type, defaultQuickPopupCenterY(type), normalizedCenterX)
    }

    function openTopBarSystemPage(page, centerX) {
        const nextPage = topBarSystemPageForType(page)
        if (nextPage.length <= 0)
            return

        const alreadyOpen = quickPopupType === "system"
        if (alreadyOpen && topBarSystemPage === nextPage) {
            closeQuickPopup()
            return
        }

        topBarSystemSlideDirection = topBarSystemPageIndex(nextPage) >= topBarSystemPageIndex(topBarSystemPage) ? 1 : -1
        topBarSystemPage = nextPage
        const rightCenter = Math.max(Number(centerX) || 0, defaultTopBarPopupCenterX("system"))
        setTopBarPopupCenter(rightCenter)

        if (alreadyOpen) {
            quickPopupWindowOpen = true
            quickPopupUnmountTimer.stop()
            return
        }
        armSystemPopupKeyboardFocus()
        toggleTopBarQuickPopup("system", rightCenter)
    }

    function armSystemPopupKeyboardFocus() {
        systemPopupFocusWorkspaceId = focusedWorkspaceId
        systemPopupKeyboardFocus = true
    }

    function releaseSystemPopupKeyboardFocus() {
        systemPopupKeyboardFocus = false
        systemPopupFocusWorkspaceId = -1
    }

    function moveTopBarSystemPage(direction) {
        if (quickPopupType !== "system" || topBarSystemPages.length <= 0)
            return

        const current = topBarSystemPageIndex(topBarSystemPage)
        const count = topBarSystemPages.length
        const next = (current + (direction < 0 ? -1 : 1) + count) % count
        topBarSystemSlideDirection = direction < 0 ? -1 : 1
        topBarSystemPage = String(topBarSystemPages[next])
    }

    function toggleSystemPanel() {
        if (!topBarLayout)
            return
        if (quickPopupType === "system") {
            closeQuickPopup()
            return
        }
        topBarSystemSlideDirection = topBarSystemPageIndex("settings") >= topBarSystemPageIndex(topBarSystemPage) ? 1 : -1
        topBarSystemPage = "settings"
        openTopBarSystemPage("settings", defaultTopBarPopupCenterX("system"))
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
        activeRailControl = ""
        if (!quickPopupSwitching) {
            quickPopupSwitchTimer.stop()
            pendingQuickPopupType = ""
            pendingQuickPopupCenterY = 0
            pendingTopBarPopupCenterX = 0
        }
        prepareQuickPopupCloseAnimation()
        releaseSystemPopupKeyboardFocus()
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

        if (weatherTopOpen && weatherTopMode === "search")
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

    function toggleQuickPopup(type, centerY, topCenterX) {
        hoverPopupType = ""
        hoverCloseTimer.stop()
        if (quickPopupType === type) {
            prepareQuickPopupCloseAnimation()
            quickPopupHoldOpen = false
            quickPopupType = ""
            return
        }

        openQuickPopup(type, centerY, topCenterX)
    }


    function openAdaptiveBarPopup(type, centerY) {
        if (["time", "agenda", "weatherPanel", "files", "browser", "wallpaperVisibility"].includes(type)) return

        if (type === "notifications" && infiniteDesktopCanvasEnabled && notificationsInTopbar
                && composition.toggleTopbarNotifications())
            return
        if (sideBarLayoutEnabled) {
            if (["volume", "brightness", "battery"].indexOf(type) >= 0) {
                const nextControl = activeRailControl === type ? "" : type
                exitFocus()
                discardQuickPopupAnimation()
                disableWeatherTopNow()
                toggleTopWallpaperPopup(false, false)
                closeLegacyLeftMenu()

                wallpaperSelectorOpen = false
                wallpaperSelectorWindowOpen = false
                settingsPanelOpen = false
                settingsPanelWindowOpen = false
                activeRailControl = nextControl
                return
            }
            if (type === "notifications") {
                for (const surface of sidebarPanels.instances) {
                    surface.notificationMenu.anchorY = centerY
                    surface.notificationMenu.toggle()
                }
                return
            }
            if (["wifi", "bluetooth"].indexOf(type) >= 0)
                return
        }
        if (!sideBarLayoutEnabled) {
            const systemPage = topBarSystemPageForType(type)
            if (systemPage.length > 0) {
                openTopBarSystemPage(systemPage, centerY)
                return
            }
            toggleTopBarQuickPopup(type, centerY)
            return
        }

        closeTopBarPopup()
        closeLegacyLeftMenu()

        toggleQuickPopup(type, centerY)
    }

    function openTopBarPopup(type, centerX) {
        const systemPage = topBarSystemPageForType(type)
        if (systemPage.length > 0)
            openTopBarSystemPage(systemPage, centerX)
        else
            toggleTopBarQuickPopup(type, centerX)
    }

    function closeTopBarPopup() {
        topBarPopupCenterX = 0
    }

    function previewAdaptiveBarPopup(type, centerY) {
        if (["time", "agenda", "weatherPanel", "files", "browser", "wallpaperVisibility"].includes(type)) return

        if (type === "search" || type === "apps" || type === "quickSettings" || type === "settingsQuick") return
        if (sideBarLayoutEnabled && (type === "volume" || type === "brightness")) {
            railControlHoverTarget = type
            railControlCloseTimer.stop()
            if (activeRailControl !== type) railControlOpenTimer.restart()
            return
        }
        if (sideBarLayoutEnabled && ["battery", "wifi", "notifications", "bluetooth"].indexOf(type) >= 0)
            return
        if (weatherTopOpen && weatherTopMode === "search")
            return

        if (!sideBarLayoutEnabled) {
            const systemPage = topBarSystemPageForType(type)
            if (systemPage.length > 0) {
                topBarSystemSlideDirection = topBarSystemPageIndex(systemPage) >= topBarSystemPageIndex(topBarSystemPage) ? 1 : -1
                topBarSystemPage = systemPage
                previewTopBarPopup("system", defaultTopBarPopupCenterX("system"))
            } else {
                previewTopBarPopup(type, centerY)
            }
            return
        }

        closeLegacyLeftMenu()

        previewSidebarPopup(type, centerY)
    }

    function endAdaptiveBarPopupHover(type) {
        if (sideBarLayoutEnabled && (type === "volume" || type === "brightness")) {
            if (railControlHoverTarget === type) railControlHoverTarget = ""
            railControlOpenTimer.stop()
            railControlCloseTimer.restart()
            return
        }
        if (!sideBarLayoutEnabled) {
            const systemPage = topBarSystemPageForType(type)
            endSidebarPopupHover(systemPage.length > 0 ? "system" : type)
            return
        }

        endSidebarPopupHover(type)
    }


    function closeLegacyLeftMenu() {
        leftMenuPinned = false
        leftMenuInteractiveFocus = false
        leftMenuOpen = false
        leftMenuTriggerHovering = false
        leftMenuHandleHovering = false
        leftMenuHandleRevealHold = false
        leftMenuPanelHovering = false
        leftMediaWindowOpen = false
        leftMediaWindowHovering = false
        leftMediaWindowEntranceHold = false
        leftDetailSwitchProgress = 1
        leftMenuCloseTimer.stop()
        leftMenuHandleRevealTimer.stop()
        leftMediaWindowEntranceHoldTimer.stop()
    }

    function openLeftMenu() {
        closeLegacyLeftMenu()
    }

    function updateLeftMenuHovering() {
        leftMenuHovering = leftMenuTriggerHovering || leftMenuHandleHovering || leftMenuPanelHovering || leftMediaWindowHovering || leftMediaWindowEntranceHold
    }


    function scheduleLeftMenuClose() {
        updateLeftMenuHovering()
        if (!leftMenuHovering)
            leftMenuCloseTimer.restart()
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
        const left = mainAreaX(screenWidth)
        const right = screenWidth - mainAreaRightInset(screenWidth)
        return SurfaceGeometry.clamp(Math.round(preferredQuickPopupX(type, screenWidth, popupWidth)), Math.ceil(left), Math.floor(right - popupWidth))
    }

    function preferredQuickPopupX(type, screenWidth, popupWidth) {
        if (quickPopupUsesReferencePlacement(type)) {
            const edge = Math.max(0, frameVisualInset)
            if (type === "settingsQuick")
                return Math.round(Math.max(edge, screenWidth - popupWidth - edge))
            if (type === "wifi")
                return 0

            return Math.round(Math.max(edge, Math.min(screenWidth - popupWidth - edge, (screenWidth - popupWidth) / 2)))
        }

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
        return !quickPopupUsesReferencePlacement(type) && type !== "agenda" && type !== "weatherPanel"
    }

    function quickPopupUsesReferencePlacement(type) {
        // The corner/reference arrangement belongs to the top bar only.
        // Side bars keep their popups attached to the originating control.
        return topBarLayout && (type === "quickSettings"
            || type === "settingsQuick"
            || type === "search"
            || type === "bluetooth"
            || type === "wifi"
            || type === "battery"
            || type === "brightness")
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
        if (type === "time")
            return 470
        if (type === "search")
            return 540
        if (type === "files")
            return 548
        if (type === "browser")
            return 1265
        if (type === "wifi")
            return 410
        if (type === "brightness")
            return 448
        if (type === "quickSettings")
            return 520
        if (type === "settingsQuick")
            return 410
        if (type === "battery")
            return 365
        if (type === "bluetooth")
            return 520
        if (type === "wallpaperVisibility")
            return 372
        if (type === "workspaces")
            return 520
        if (type === "apps")
            return 560
        if (type === "media")
            return 470
        if (type === "profile")
            return 390
        return 286
    }

    function quickPopupWidthForScreen(type, screenWidth) {
        const available = Math.max(0, Math.floor(mainAreaWidth(screenWidth) - 16))
        if (type === "agenda" || type === "weatherPanel") {
            return Math.round(Math.min(available, Math.max(1510, Math.min(1680, mainAreaWidth(screenWidth) - 110))))
        }
        return Math.min(quickPopupWidth(type), available)
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
        if (type === "time")
            return 990
        if (type === "search")
            return 470
        if (type === "files")
            return 720
        if (type === "browser")
            return 795
        if (type === "wifi")
            return 735
        if (type === "brightness")
            return 570
        if (type === "quickSettings")
            return 440
        if (type === "settingsQuick")
            return 605
        if (type === "battery")
            return 450
        if (type === "bluetooth")
            return 450
        if (type === "wallpaperVisibility")
            return 470
        if (type === "workspaces")
            return 390
        if (type === "apps")
            return 440
        if (type === "media")
            return 330
        if (type === "profile")
            return 340
        return 324
    }

    function quickPopupHeightForScreen(type, screenHeight) {
        if (type === "agenda" || type === "weatherPanel") {
            const available = Math.max(0, Math.floor(screenHeight - frameVisualInset * 2 - 64))
            return Math.min(1040, available)
        }
        return Math.min(quickPopupHeight(type), Math.max(0, Math.floor(screenHeight - 64)))
    }

    function quickPopupTopMargin(type) {
        if (type === "time" || type === "search" || type === "battery")
            return Math.max(frameVisualInset + popupFrameGap, 38)
        return frameVisualInset + popupFrameGap
    }

    function quickPopupY(type, panelHeight, screenHeight) {
        const edgeMargin = frameVisualInset + popupFrameGap
        const maxY = Math.floor(screenHeight - panelHeight - edgeMargin)
        function clampY(wanted) {
            if (maxY < edgeMargin)
                return Math.round(Math.max(edgeMargin, maxY))
            return Math.round(Math.max(edgeMargin, Math.min(maxY, wanted)))
        }

        if (quickPopupUsesReferencePlacement(type)) {
            if (type === "settingsQuick")
                return clampY(Math.max(frameVisualInset, Math.round(screenHeight * 0.18)))
            if (type === "quickSettings")
                return clampY(Math.round(screenHeight * 0.32))
            if (type === "search")
                return clampY(Math.round(screenHeight * 0.29))
            if (type === "wifi")
                return clampY(Math.max(frameVisualInset, Math.round(screenHeight * 0.066)))
            if (type === "bluetooth")
                return clampY(Math.round(screenHeight * 0.49))
            if (type === "battery")
                return clampY(screenHeight - panelHeight - frameVisualInset)
            return clampY(screenHeight - panelHeight - frameVisualInset)
        }

        if (type === "agenda" || type === "weatherPanel") {
            const wanted = (screenHeight - panelHeight) / 2
            return clampY(wanted)
        }

        const center = quickPopupCenterY > 0 ? quickPopupCenterY : defaultQuickPopupCenterY(type)
        const topMargin = quickPopupTopMargin(type)
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
        id: leftMenuHandleRevealTimer

        interval: Math.max(460, veloraTheme.motionHover + 260)
        repeat: false
        onTriggered: {
            if (!root.leftMenuTriggerHovering && !root.leftMenuHandleHovering)
                root.leftMenuHandleRevealHold = false
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

    Behavior on leftMenuFrameReveal {
        enabled: veloraTheme.motionEnabled
        NumberAnimation {
            duration: root.leftMenuOpen ? veloraTheme.motionPanelIn : root.quickPopupLineCloseDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.leftMenuOpen ? veloraTheme.motionCurveEmphasizedAccel : veloraTheme.motionCurveStandard
        }
    }

    Behavior on leftMenuHandleSurfaceReveal {
        enabled: veloraTheme.motionEnabled
        NumberAnimation {
            duration: veloraTheme.motionHover
            easing.type: Easing.OutCubic
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
        onTriggered: root.leftMenuPreloadEnabled = false
    }


    Timer {
        id: railControlOpenTimer
        interval: 110
        onTriggered: if (root.railControlHoverTarget && root.sideBarLayoutEnabled) root.activeRailControl = root.railControlHoverTarget
    }
    Timer {
        id: railControlCloseTimer
        interval: 180
        onTriggered: if (!root.railControlHoverTarget && !root.railControlPanelHovered) root.activeRailControl = ""
    }
    Timer {
        id: railControlFeedbackTimer
        interval: 1800
        onTriggered: if (!root.railControlHoverTarget && !root.railControlPanelHovered) root.activeRailControl = ""
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

    SequentialAnimation {
        id: systemSheetOpenAnimation

        NumberAnimation {
            id: systemSheetRiseAnimation
            target: root
            property: "systemSheetOffsetY"
            duration: 260
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            id: systemSheetSettleAnimation
            property: "systemSheetOffsetY"
            from: -10
            to: 0
            duration: 110
            easing.type: Easing.OutBack
        }
    }

    NumberAnimation {
        id: systemSheetCloseAnimation

        target: root
        property: "systemSheetOffsetY"
        duration: 220
        easing.type: Easing.InCubic
        onFinished: root.systemSheetClosing = false
    }

    Timer {
        id: quickPopupUnmountTimer

        interval: Math.max(veloraTheme.motionUnmountDelay, root.quickPopupLineCloseDuration + 160)
        repeat: false
        onTriggered: {
            if (!root.quickPopupVisible) {
                root.quickPopupWindowOpen = false
                root.renderedQuickPopupType = ""
                root.quickPopupSurfaceReveal = 0
                root.systemSheetClosing = false
            }
        }
    }

    Timer {
        id: quickPopupSwitchTimer

        interval: Math.max(220, root.quickPopupLineCloseDuration + 20)
        repeat: false
        onTriggered: {
            const nextType = root.pendingQuickPopupType
            const nextCenterY = root.pendingQuickPopupCenterY
            const nextCenterX = root.pendingTopBarPopupCenterX
            root.pendingQuickPopupType = ""
            root.pendingQuickPopupCenterY = 0
            root.pendingTopBarPopupCenterX = 0
            if (nextType.length <= 0) {
                root.quickPopupSwitching = false
                return
            }
            root.quickPopupSwitching = true
            root.openQuickPopup(nextType, nextCenterY, nextCenterX)
            root.quickPopupSwitching = false
        }
    }

    Timer {
        id: weatherTopUnmountTimer

        interval: Math.max(veloraTheme.motionUnmountDelay, root.quickPopupLineCloseDuration + 180)
        repeat: false
        onTriggered: if (!root.weatherTopOpen) root.weatherTopWindowOpen = false
    }

    Timer {
        id: weatherTopHoverCloseTimer

        interval: 320
        repeat: false
        onTriggered: if (!root.weatherTopKeyboardFocus && !root.weatherTopTriggerHovering && !root.weatherTopPanelHovering) root.closeWeatherTop()
    }

    Timer {
        id: searchPopupFocusTimer

        interval: 80
        repeat: false
        onTriggered: {
            if (root.quickPopupType !== "search"
                    && root.quickPopupType !== "apps") {
                return
            }

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

        function wallpaperNativeTransitionBackend(action: string): string {
            if (!Platform.NativeBlur.supports("wallpaper-transition"))
                return ""
            if (action === "prepare" && (!veloraTheme.motionEnabled || (root.composition && root.composition.reducedMotion)))
                return ""
            return Platform.NativeBlur.supports("lua-dispatch") ? "lua" : "native"
        }

        function topWallpaper(): void {
            root.toggleTopWallpaperPopup(null, true)
        }

        function wallpaperSelectorState(): string {
            const state = {}
            for (const name in root.wallpaperSelectorViews)
                state[name] = root.wallpaperSelectorViews[name].diagnostics()
            return JSON.stringify(state)
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
            root.openUnifiedSettings()
        }

        function systemPanel(): void {
            root.toggleSystemPanel()
        }

        function systemPanelPage(page: string): void {
            const nextPage = root.topBarSystemPageForType(page)
            if (nextPage.length <= 0)
                return
            if (root.quickPopupType !== "system") {
                root.openTopBarSystemPage(nextPage, root.defaultTopBarPopupCenterX("system"))
                return
            }
            root.topBarSystemSlideDirection = root.topBarSystemPageIndex(nextPage)
                >= root.topBarSystemPageIndex(root.topBarSystemPage)
                ? 1
                : -1
            root.topBarSystemPage = nextPage
        }

        function systemPanelState(): string {
            return JSON.stringify({
                "topBarLayout": root.topBarLayout,
                "quickPopupType": root.quickPopupType,
                "quickPopupVisible": root.quickPopupVisible,
                "quickPopupWindowOpen": root.quickPopupWindowOpen,
                "renderedQuickPopupType": root.renderedQuickPopupType,
                "systemPage": root.topBarSystemPage,
                "systemKeyboardFocus": root.systemPopupKeyboardFocus,
                "focusedWorkspaceId": root.focusedWorkspaceId,
                "focusWorkspaceId": root.systemPopupFocusWorkspaceId,
                "sheetOffsetY": root.systemSheetOffsetY
            })
        }

        function preferences(): void {
            root.openUnifiedSettings()
        }


        function editDesktop(): void {
            root.composition.openEditor("desktop")
        }

        function editLock(): void {
            root.composition.openEditor("lock")
        }

        function pywal16(): void {
            veloraTheme.applyTheme("pywal16")
        }

        function reloadPywal16(): void {
            veloraTheme.reloadPywal16()
        }

        function search(): void {
            root.toggleTopSearch()
        }

        function notificationState(): string {
            return JSON.stringify({ count: root.notificationHistoryCount,
                toastVisible: root.notificationToastVisible,
                toastTitle: root.notificationToastTitle, toastBody: root.notificationToastBody,
                toastId: root.notificationToastId, toastImage: root.notificationToastImage })
        }
        function infiniteDesktopState(): string {
            return JSON.stringify({enabled: root.infiniteDesktopCanvasEnabled,
                ready: root.infiniteDesktopStateReady, moving: root.infiniteDesktopMorphing,
                progress: root.infiniteDesktopMorphProgress, frameFold: root.infiniteDesktopFrameFoldProgress,
                sourceReveal: root.infiniteDesktopSourceReveal, targetReveal: root.infiniteDesktopTargetReveal})
        }

        function weatherTop(): void {
            root.toggleWeatherTop()
        }

        function profile(): void {
            root.openAdaptiveBarPopup("quickSettings", root.defaultQuickPopupCenterY("quickSettings"))
        }

        function topbarWorkspaces(): void {
            if (root.topBarLayout)
                root.openTopBarPopup("workspaces", root.defaultTopBarPopupCenterX("workspaces"))
        }

        function topbarApps(): void {
            if (root.topBarLayout)
                root.openTopBarPopup("apps", root.defaultTopBarPopupCenterX("apps"))
        }

        function topbarMedia(): void {
            if (root.topBarLayout)
                root.openTopBarPopup("media", root.defaultTopBarPopupCenterX("media"))
        }

        function topbarProfile(): void {
            if (root.topBarLayout)
                root.openTopBarPopup("profile", root.defaultTopBarPopupCenterX("profile"))
        }

        function time(): void {
            root.openAdaptiveBarPopup("time", root.defaultQuickPopupCenterY("time"))
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

        function railLevel(kind: string): void {
            if (kind !== "volume" && kind !== "brightness") return
            root.railFeedbackSerial += 1
            if (!root.sideBarLayoutEnabled) return
            railControlCloseTimer.stop()
            root.activeRailControl = kind
            railControlFeedbackTimer.restart()
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

        function bluetooth(): void {
            if (root.sideBarLayoutEnabled) {
                for (const surface of sidebarPanels.instances)
                    surface.bluetoothMenu.toggle()
                return
            }
            root.openAdaptiveBarPopup("bluetooth", root.defaultQuickPopupCenterY("bluetooth"))
        }

        function bluetoothState(): string {
            return JSON.stringify(sidebarPanels.instances.map(surface => {
                const menu = surface.bluetoothMenu
                return { monitor: surface.modelData.name, opened: menu.opened,
                    mounted: menu.mounted, managing: menu.managing,
                    available: menu.available, powered: menu.powered,
                    scanning: menu.manager.scanning, devices: menu.devices.length,
                    busy: menu.manager.busy, action: menu.manager.action,
                    target: menu.manager.targetAddress,
                    deviceStates: menu.devices.map(device => ({address: device.address,
                        name: device.name || device.deviceName, paired: device.paired,
                        connected: device.connected})),
                    error: menu.manager.error }
            }))
        }

        function bluetoothConnect(address: string): bool {
            for (const surface of sidebarPanels.instances) {
                const manager = surface.bluetoothMenu.manager
                if (manager.devices.some(device => device.address === address))
                    return manager.connectDevice(address)
            }
            return false
        }

        function battery(): void {
            root.openAdaptiveBarPopup("battery", root.defaultQuickPopupCenterY("battery"))
        }


        function system(): void {
            root.toggleSystemPanel()
        }


        function media(): void {
            if (root.sideBarLayoutEnabled) root.railMediaRequested()
            else root.openTopBarPopup("media", root.defaultTopBarPopupCenterX("media"))
        }
        function whatsapp(): void { root.railWhatsAppRequested() }

        function leftMenu(): void {
            root.leftMenuPinned = false
            root.leftMediaWindowOpen = false
            root.leftMediaWindowEntranceHold = false
            root.leftDetailSwitchProgress = 1
            root.updateLeftMenuHovering()
            root.openLeftMenu()
            root.scheduleLeftMenuClose()
        }

        function closeLeftMenu(): void {
            root.closeLegacyLeftMenu()
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


        function layoutCycle(): void {
            root.cycleBarLayout()
        }
    }

    Variants {
        model: root.infiniteDesktopGestureMounted ? Quickshell.screens : []

        PanelWindow {
            id: infiniteDesktopGesturePanel

            required property var modelData

            screen: modelData
            color: "transparent"
            implicitWidth: modelData.width > 0 ? modelData.width : 1
            implicitHeight: modelData.height > 0 ? modelData.height : 1
            exclusionMode: ExclusionMode.Ignore
            focusable: false

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "velora-infinite-desktop-gesture"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            mask: Region {
                item: infiniteDesktopGesture
                // The pan window shares the desktop layer with the dock.
                // Leave its controls to the dock regardless of map order.
                Region {
                    intersection: Intersection.Subtract
                    width: root.infiniteDesktopTargetReveal > .99 ? 128 * Math.min(1, infiniteDesktopGesturePanel.width/1280, (infiniteDesktopGesturePanel.height-40)/720) : 0
                    height: width
                    y: infiniteDesktopGesturePanel.height-height
                }
                Region {
                    intersection: Intersection.Subtract
                    width: root.infiniteDesktopTargetReveal > .99 ? 128 * Math.min(1, infiniteDesktopGesturePanel.width/1280, (infiniteDesktopGesturePanel.height-40)/720) : 0
                    height: width
                    x: infiniteDesktopGesturePanel.width-width
                    y: infiniteDesktopGesturePanel.height-height
                }
                Region {
                    intersection: Intersection.Subtract
                    readonly property real unit: Math.min(1, infiniteDesktopGesturePanel.width/1280, (infiniteDesktopGesturePanel.height-40)/720)
                    width: root.infiniteDesktopTargetReveal > .99 && root.composition
                        ? InfiniteDockGeometry.dockWidth(infiniteDesktopGesturePanel.width, unit, root.composition.configStore.infiniteDeskPinnedItems.length) : 0
                    height: 54*unit
                    x: (infiniteDesktopGesturePanel.width-width)/2
                    y: infiniteDesktopGesturePanel.height-height
                }
            }

            VeloraInfiniteDesktopGesture {
                id: infiniteDesktopGesture

                anchors.fill: parent
                bridgePath: root.infiniteDesktopCommand
                monitorName: modelData.name
            }
        }
    }

    Variants {
        model: root.lyricsOverlayMounted ? Quickshell.screens : []

        PanelWindow {
            id: lyricsPanel

            required property var modelData
            readonly property int panelWidth: modelData.width > 0 ? modelData.width : 1920
            readonly property int panelHeight: modelData.height > 0 ? modelData.height : 1200
            readonly property color lyricsTextColor: veloraTheme.lyricsColorMode === "manual" ? veloraTheme.lyricsManualColor : veloraTheme.lyricsPywalColor
            property real floatPhase: 0

            function wordFloatX(sourceIndex) {
                return veloraTheme.lyricsFloatEnabled && !root.topBarLayout ? Math.sin(floatPhase + Number(sourceIndex) * 1.37) * veloraTheme.lyricsFloatIntensity : 0
            }

            function wordFloatY(sourceIndex) {
                return veloraTheme.lyricsFloatEnabled && !root.topBarLayout ? Math.cos(floatPhase * 0.82 + Number(sourceIndex) * 1.11) * veloraTheme.lyricsFloatIntensity * 0.45 : 0
            }

            function lyricsGlowRadius(blockIndex) {
                const glowRadius = root.lyricsBlockGlowEnabled(blockIndex) ? Math.round(8 + root.lyricsBlockGlowIntensity(blockIndex) * 30) : 0
                const depthRadius = veloraTheme.lyricsDepthEnabled ? Math.round(4 + veloraTheme.lyricsDepthIntensity * 16) : 0
                return Math.max(1, glowRadius, depthRadius)
            }

            function lyricsGlowSamples(blockIndex) {
                const glowRadius = lyricsGlowRadius(blockIndex)
                return Math.max(17, glowRadius * 2 + 1)
            }

            function lyricsEffectEnabled(blockIndex) {
                return (root.lyricsBlockGlowEnabled(blockIndex) && root.lyricsBlockGlowIntensity(blockIndex) > 0.01) || veloraTheme.lyricsDepthEnabled
            }

            function lyricsEffectHorizontalOffset(blockIndex) {
                if (!veloraTheme.lyricsDepthEnabled)
                    return 0
                return Math.round(1 + veloraTheme.lyricsDepthIntensity * 4)
            }

            function lyricsEffectVerticalOffset(blockIndex) {
                if (!veloraTheme.lyricsDepthEnabled)
                    return 0
                return Math.round(2 + veloraTheme.lyricsDepthIntensity * 6)
            }

            function lyricsGlowColor(colorValue, active, blockIndex) {
                if (root.lyricsBlockGlowEnabled(blockIndex) && root.lyricsBlockGlowIntensity(blockIndex) > 0.01) {
                    const intensity = root.lyricsBlockGlowIntensity(blockIndex)
                    const alpha = Math.min(0.92, (active ? 0.28 : 0.16) + intensity * (active ? 0.50 : 0.34))
                    return veloraTheme.withAlpha(colorValue, alpha)
                }

                const depth = veloraTheme.lyricsDepthEnabled ? veloraTheme.lyricsDepthIntensity : 0
                return Qt.rgba(0.04, 0.10, 0.18, (active ? 0.20 : 0.13) + depth * (active ? 0.28 : 0.20))
            }

            function cinematicPhraseWidth(side) {
                return Math.round(Math.min(panelWidth * 0.36, Math.max(320, panelWidth * 0.26)))
            }

            function cinematicPhraseX(side, role) {
                const widthHint = cinematicPhraseWidth(side)
                const progress = root.lyricsPhraseProgress
                const dir = side === 0 ? -1 : 1
                const pct = side === 0 ? veloraTheme.lyricsPositionX : veloraTheme.lyricsSecondPositionX
                const base = Math.max(18, Math.min(panelWidth - widthHint - 18, panelWidth * pct / 100))

                if (role === "previous")
                    return Math.round(base + dir * (38 + 70 * progress))
                if (role === "next")
                    return Math.round(base - dir * 76)
                return Math.round(base - dir * (56 * (1 - progress)))
            }

            function cinematicPhraseY(side, role) {
                const progress = root.lyricsPhraseProgress
                const pct = side === 0 ? veloraTheme.lyricsPositionY : veloraTheme.lyricsSecondPositionY
                const base = Math.max(root.topBarPanelTopMargin(panelHeight) + root.topBarPanelHeight(panelHeight) + 18, Math.min(panelHeight * 0.62, panelHeight * pct / 100))

                if (role === "previous")
                    return Math.round(base + 20 + progress * 24)
                if (role === "next")
                    return Math.round(base + 16)
                return Math.round(base + (1 - progress) * 10)
            }

            function cinematicTextColor(side, sourceIndex, active) {
                const color = root.lyricsWordColor(sourceIndex, side)
                return root.lyricsMaterialColor(color, sourceIndex, active)
            }

            NumberAnimation on floatPhase {
                from: 0
                to: 6.28318
                duration: 5200
                loops: Animation.Infinite
                running: veloraTheme.lyricsFloatEnabled && root.lyricsOverlayMounted && !root.topBarLayout
            }

            screen: modelData
            color: "transparent"
            implicitWidth: panelWidth
            implicitHeight: panelHeight
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: false

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "velora-shell-lyrics"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            mask: Region {}

            Item {
                id: lyricsContent

                anchors.fill: parent
                layer.enabled: veloraTheme.lyricsMaskEnabled && veloraTheme.lyricsMaskHasStrokes
                layer.smooth: true
                layer.effect: OpacityMask {
                    maskSource: lyricsCutMaskSource
                }

            Item {
                id: lyricsCinematicLayer

                anchors.fill: parent
                visible: root.lyricsCinematicModeActive()
                z: 3

                Text {
                    id: lyricsPreviousPhraseText

                    readonly property int phraseSide: root.lyricsGhostSide
                    readonly property real progress: root.lyricsPhraseProgress

                    visible: root.lyricsGhostText.length > 0 && progress < 0.995
                    text: root.lyricsGhostText
                    x: lyricsPanel.cinematicPhraseX(phraseSide, "previous")
                    y: lyricsPanel.cinematicPhraseY(phraseSide, "previous")
                    width: lyricsPanel.cinematicPhraseWidth(phraseSide)
                    wrapMode: Text.WordWrap
                    lineHeight: 0.92
                    color: lyricsPanel.cinematicTextColor(phraseSide, root.lyricsActiveIndex, false)
                    opacity: Math.max(0, 0.42 * (1 - progress))
                    scale: Math.max(0.78, 0.94 - progress * 0.12)
                    transformOrigin: Item.Center
                    font.family: veloraTheme.uiFont
                    font.pixelSize: Math.round(veloraTheme.lyricsFontSize * 0.92)
                    font.weight: Font.Black
                    font.letterSpacing: 0
                    style: Text.Outline
                    styleColor: root.lyricsOutlineColor(false)
                    renderType: Text.NativeRendering
                    layer.enabled: lyricsPanel.lyricsEffectEnabled(phraseSide)
                    layer.smooth: true
                    layer.effect: DropShadow {
                        horizontalOffset: lyricsPanel.lyricsEffectHorizontalOffset(lyricsPreviousPhraseText.phraseSide)
                        verticalOffset: lyricsPanel.lyricsEffectVerticalOffset(lyricsPreviousPhraseText.phraseSide)
                        radius: lyricsPanel.lyricsGlowRadius(lyricsPreviousPhraseText.phraseSide)
                        samples: lyricsPanel.lyricsGlowSamples(lyricsPreviousPhraseText.phraseSide)
                        spread: 0
                        transparentBorder: true
                        color: lyricsPanel.lyricsGlowColor(lyricsPreviousPhraseText.color, false, lyricsPreviousPhraseText.phraseSide)
                    }
                }

                Text {
                    id: lyricsNextPhraseText

                    readonly property var phrase: root.lyricsNextPhrase()
                    readonly property int phraseSide: Number(phrase.side) || 0
                    readonly property int phraseStart: Number(phrase.start) || 0

                    visible: phrase.text.length > 0 && phrase.text !== root.lyricsCurrentPhrase().text
                    text: phrase.text
                    x: lyricsPanel.cinematicPhraseX(phraseSide, "next")
                    y: lyricsPanel.cinematicPhraseY(phraseSide, "next")
                    width: lyricsPanel.cinematicPhraseWidth(phraseSide)
                    wrapMode: Text.WordWrap
                    lineHeight: 0.92
                    color: lyricsPanel.cinematicTextColor(phraseSide, phraseStart, false)
                    opacity: Math.min(0.20, 0.06 + root.lyricsPhraseProgress * 0.14)
                    scale: 0.82
                    transformOrigin: Item.Center
                    font.family: veloraTheme.uiFont
                    font.pixelSize: Math.round(veloraTheme.lyricsFontSize * 0.86)
                    font.weight: Font.Black
                    font.letterSpacing: 0
                    style: Text.Outline
                    styleColor: root.lyricsOutlineColor(false)
                    renderType: Text.NativeRendering
                }

                Text {
                    id: lyricsCurrentPhraseText

                    readonly property var phrase: root.lyricsCurrentPhrase()
                    readonly property int phraseSide: Number(phrase.side) || 0
                    readonly property int phraseStart: Number(phrase.start) || 0
                    readonly property real progress: root.lyricsPhraseProgress

                    visible: phrase.text.length > 0
                    text: phrase.text
                    x: lyricsPanel.cinematicPhraseX(phraseSide, "current")
                    y: lyricsPanel.cinematicPhraseY(phraseSide, "current")
                    width: lyricsPanel.cinematicPhraseWidth(phraseSide)
                    wrapMode: Text.WordWrap
                    lineHeight: 0.90
                    color: lyricsPanel.cinematicTextColor(phraseSide, phraseStart, true)
                    opacity: Math.max(0.22, 0.18 + progress * 0.82)
                    scale: 0.92 + progress * 0.08
                    transformOrigin: Item.Center
                    font.family: veloraTheme.uiFont
                    font.pixelSize: Math.round(veloraTheme.lyricsFontSize * 1.08)
                    font.weight: Font.Black
                    font.letterSpacing: 0
                    style: Text.Outline
                    styleColor: root.lyricsOutlineColor(true)
                    renderType: Text.NativeRendering
                    layer.enabled: lyricsPanel.lyricsEffectEnabled(phraseSide)
                    layer.smooth: true
                    layer.effect: DropShadow {
                        horizontalOffset: lyricsPanel.lyricsEffectHorizontalOffset(lyricsCurrentPhraseText.phraseSide)
                        verticalOffset: lyricsPanel.lyricsEffectVerticalOffset(lyricsCurrentPhraseText.phraseSide)
                        radius: lyricsPanel.lyricsGlowRadius(lyricsCurrentPhraseText.phraseSide)
                        samples: lyricsPanel.lyricsGlowSamples(lyricsCurrentPhraseText.phraseSide)
                        spread: 0
                        transparentBorder: true
                        color: lyricsPanel.lyricsGlowColor(lyricsCurrentPhraseText.color, true, lyricsCurrentPhraseText.phraseSide)
                    }
                }
            }

            Item {
                id: lyricsBlock

                readonly property real wordStep: Math.round(veloraTheme.lyricsFontSize + veloraTheme.lyricsWordSpacing)
                readonly property bool centered: veloraTheme.lyricsLayoutMode === "centered"
                readonly property bool cascade: veloraTheme.lyricsLayoutMode === "cascade"
                readonly property var visibleWords: root.renderedLyricsWords()

                visible: veloraTheme.lyricsLayoutMode !== "two" && veloraTheme.lyricsLayoutMode !== "four"
                x: Math.round(Math.max(0, Math.min(parent.width - 24, parent.width * veloraTheme.lyricsPositionX / 100)))
                y: Math.round(Math.max(0, Math.min(parent.height - 24, parent.height * veloraTheme.lyricsPositionY / 100)))
                width: Math.max(240, parent.width - x - 24)
                height: Math.max(80, visibleWords.length * wordStep + 20)
                opacity: veloraTheme.lyricsOpacity
                clip: false
                scale: veloraTheme.lyricsScale
                rotation: veloraTheme.lyricsRotation
                transformOrigin: Item.TopLeft
                transform: [
                    Rotation {
                        origin.x: 0
                        origin.y: 0
                        axis.x: 1
                        axis.y: 0
                        axis.z: 0
                        angle: veloraTheme.lyricsTiltX
                    },
                    Rotation {
                        origin.x: 0
                        origin.y: 0
                        axis.x: 0
                        axis.y: 1
                        axis.z: 0
                        angle: veloraTheme.lyricsTiltY
                    }
                ]

                Repeater {
                    model: lyricsBlock.visibleWords

                    Text {
                        id: lyricsMainWordText

                        required property int index
                        required property var modelData

                        readonly property int sourceIndex: Number(modelData.sourceIndex)
                        readonly property bool activeWord: root.lyricsTimingMode === "plain-estimated" || !veloraTheme.lyricsActiveWordEnabled || sourceIndex === root.lyricsActiveIndex
                        readonly property string displayWord: veloraTheme.lyricsUppercase ? String(modelData.text).toUpperCase() : String(modelData.text)
                        readonly property color baseWordColor: root.lyricsWordColor(sourceIndex, -1)

                        text: displayWord
                        x: (lyricsBlock.centered ? -paintedWidth / 2 : (lyricsBlock.cascade ? index * Math.max(8, veloraTheme.lyricsFontSize * 0.18) : 0)) + lyricsPanel.wordFloatX(sourceIndex)
                        y: index * lyricsBlock.wordStep + lyricsPanel.wordFloatY(sourceIndex)
                        color: root.lyricsMaterialColor(baseWordColor, sourceIndex, activeWord)
                        opacity: root.lyricsRenderedWordOpacity(activeWord)
                        scale: root.lyricsWordScale(sourceIndex)
                        transformOrigin: Item.Center
                        font.family: veloraTheme.uiFont
                        font.pixelSize: Math.round(veloraTheme.lyricsFontSize)
                        font.weight: Font.Black
                        font.letterSpacing: 0
                        style: (veloraTheme.lyricsShadowEnabled || veloraTheme.lyricsDepthEnabled) ? Text.Outline : Text.Normal
                        styleColor: root.lyricsOutlineColor(activeWord)
                        renderType: Text.NativeRendering
                        layer.enabled: lyricsPanel.lyricsEffectEnabled(-1)
                        layer.smooth: true
                        layer.effect: DropShadow {
                            horizontalOffset: lyricsPanel.lyricsEffectHorizontalOffset(-1)
                            verticalOffset: lyricsPanel.lyricsEffectVerticalOffset(-1)
                            radius: lyricsPanel.lyricsGlowRadius(-1)
                            samples: lyricsPanel.lyricsGlowSamples(-1)
                            spread: 0
                            transparentBorder: true
                            color: lyricsPanel.lyricsGlowColor(lyricsMainWordText.color, lyricsMainWordText.activeWord, -1)
                        }
                    }
                }
            }

            Item {
                id: lyricsLeftBlock

                readonly property real wordStep: Math.round(veloraTheme.lyricsFontSize + veloraTheme.lyricsWordSpacing)
                readonly property var visibleWords: root.renderedLyricsSideWords("left")

                visible: veloraTheme.lyricsLayoutMode === "two" && !root.lyricsCinematicModeActive()
                x: Math.round(Math.max(0, Math.min(parent.width - 24, parent.width * veloraTheme.lyricsPositionX / 100)))
                y: Math.round(Math.max(0, Math.min(parent.height - 24, parent.height * veloraTheme.lyricsPositionY / 100)))
                width: Math.max(160, parent.width * 0.42)
                height: Math.max(80, visibleWords.length * wordStep + 20)
                opacity: veloraTheme.lyricsOpacity
                clip: false
                scale: veloraTheme.lyricsScale
                rotation: veloraTheme.lyricsRotation
                transformOrigin: Item.TopLeft
                transform: [
                    Rotation {
                        origin.x: 0
                        origin.y: 0
                        axis.x: 1
                        axis.y: 0
                        axis.z: 0
                        angle: veloraTheme.lyricsTiltX
                    },
                    Rotation {
                        origin.x: 0
                        origin.y: 0
                        axis.x: 0
                        axis.y: 1
                        axis.z: 0
                        angle: veloraTheme.lyricsTiltY
                    }
                ]

                Repeater {
                    model: lyricsLeftBlock.visibleWords

                    Text {
                        id: lyricsLeftWordText

                        required property int index
                        required property var modelData

                        readonly property int sourceIndex: Number(modelData.sourceIndex)
                        readonly property bool activeWord: root.lyricsTimingMode === "plain-estimated" || !veloraTheme.lyricsActiveWordEnabled || sourceIndex === root.lyricsActiveIndex
                        readonly property string displayWord: veloraTheme.lyricsUppercase ? String(modelData.text).toUpperCase() : String(modelData.text)
                        readonly property color baseWordColor: root.lyricsWordColor(sourceIndex, 0)

                        text: displayWord
                        x: lyricsPanel.wordFloatX(sourceIndex)
                        y: index * lyricsLeftBlock.wordStep + lyricsPanel.wordFloatY(sourceIndex)
                        color: root.lyricsMaterialColor(baseWordColor, sourceIndex, activeWord)
                        opacity: root.lyricsRenderedWordOpacity(activeWord)
                        scale: root.lyricsWordScale(sourceIndex)
                        transformOrigin: Item.Center
                        font.family: veloraTheme.uiFont
                        font.pixelSize: Math.round(veloraTheme.lyricsFontSize)
                        font.weight: Font.Black
                        font.letterSpacing: 0
                        style: (veloraTheme.lyricsShadowEnabled || veloraTheme.lyricsDepthEnabled) ? Text.Outline : Text.Normal
                        styleColor: root.lyricsOutlineColor(activeWord)
                        renderType: Text.NativeRendering
                        layer.enabled: lyricsPanel.lyricsEffectEnabled(0)
                        layer.smooth: true
                        layer.effect: DropShadow {
                            horizontalOffset: lyricsPanel.lyricsEffectHorizontalOffset(0)
                            verticalOffset: lyricsPanel.lyricsEffectVerticalOffset(0)
                            radius: lyricsPanel.lyricsGlowRadius(0)
                            samples: lyricsPanel.lyricsGlowSamples(0)
                            spread: 0
                            transparentBorder: true
                            color: lyricsPanel.lyricsGlowColor(lyricsLeftWordText.color, lyricsLeftWordText.activeWord, 0)
                        }
                    }
                }
            }

            Item {
                id: lyricsRightBlock

                readonly property real wordStep: Math.round(veloraTheme.lyricsFontSize + veloraTheme.lyricsWordSpacing)
                readonly property var visibleWords: root.renderedLyricsSideWords("right")

                visible: veloraTheme.lyricsLayoutMode === "two" && !root.lyricsCinematicModeActive()
                x: Math.round(Math.max(0, Math.min(parent.width - 24, parent.width * veloraTheme.lyricsSecondPositionX / 100)))
                y: Math.round(Math.max(0, Math.min(parent.height - 24, parent.height * veloraTheme.lyricsSecondPositionY / 100)))
                width: Math.max(160, parent.width - x - 24)
                height: Math.max(80, visibleWords.length * wordStep + 20)
                opacity: veloraTheme.lyricsOpacity
                clip: false
                scale: veloraTheme.lyricsScale
                rotation: veloraTheme.lyricsRotation
                transformOrigin: Item.TopLeft
                transform: [
                    Rotation {
                        origin.x: 0
                        origin.y: 0
                        axis.x: 1
                        axis.y: 0
                        axis.z: 0
                        angle: veloraTheme.lyricsTiltX
                    },
                    Rotation {
                        origin.x: 0
                        origin.y: 0
                        axis.x: 0
                        axis.y: 1
                        axis.z: 0
                        angle: veloraTheme.lyricsTiltY
                    }
                ]

                Repeater {
                    model: lyricsRightBlock.visibleWords

                    Text {
                        id: lyricsRightWordText

                        required property int index
                        required property var modelData

                        readonly property int sourceIndex: Number(modelData.sourceIndex)
                        readonly property bool activeWord: root.lyricsTimingMode === "plain-estimated" || !veloraTheme.lyricsActiveWordEnabled || sourceIndex === root.lyricsActiveIndex
                        readonly property string displayWord: veloraTheme.lyricsUppercase ? String(modelData.text).toUpperCase() : String(modelData.text)
                        readonly property color baseWordColor: root.lyricsWordColor(sourceIndex, 1)

                        text: displayWord
                        x: lyricsPanel.wordFloatX(sourceIndex)
                        y: index * lyricsRightBlock.wordStep + lyricsPanel.wordFloatY(sourceIndex)
                        color: root.lyricsMaterialColor(baseWordColor, sourceIndex, activeWord)
                        opacity: root.lyricsRenderedWordOpacity(activeWord)
                        scale: root.lyricsWordScale(sourceIndex)
                        transformOrigin: Item.Center
                        font.family: veloraTheme.uiFont
                        font.pixelSize: Math.round(veloraTheme.lyricsFontSize)
                        font.weight: Font.Black
                        font.letterSpacing: 0
                        style: (veloraTheme.lyricsShadowEnabled || veloraTheme.lyricsDepthEnabled) ? Text.Outline : Text.Normal
                        styleColor: root.lyricsOutlineColor(activeWord)
                        renderType: Text.NativeRendering
                        layer.enabled: lyricsPanel.lyricsEffectEnabled(1)
                        layer.smooth: true
                        layer.effect: DropShadow {
                            horizontalOffset: lyricsPanel.lyricsEffectHorizontalOffset(1)
                            verticalOffset: lyricsPanel.lyricsEffectVerticalOffset(1)
                            radius: lyricsPanel.lyricsGlowRadius(1)
                            samples: lyricsPanel.lyricsGlowSamples(1)
                            spread: 0
                            transparentBorder: true
                            color: lyricsPanel.lyricsGlowColor(lyricsRightWordText.color, lyricsRightWordText.activeWord, 1)
                        }
                    }
                }
            }

            Repeater {
                model: veloraTheme.lyricsLayoutMode === "four" ? [0, 1, 2, 3] : []

                Item {
                    id: lyricsFourBlock

                    required property int index
                    required property int modelData

                    readonly property int blockIndex: Number(modelData)
                    readonly property real wordStep: Math.round(veloraTheme.lyricsFontSize + veloraTheme.lyricsWordSpacing)
                    readonly property var visibleWords: root.renderedLyricsBlockWords(blockIndex, 4)

                    x: root.lyricsBlockPositionX(parent.width, blockIndex)
                    y: root.lyricsBlockPositionY(parent.height, blockIndex)
                    width: root.lyricsBlockWidth(parent.width, blockIndex)
                    height: Math.max(80, visibleWords.length * wordStep + 20)
                    opacity: veloraTheme.lyricsOpacity
                    clip: false
                    scale: veloraTheme.lyricsScale
                    rotation: veloraTheme.lyricsRotation
                    transformOrigin: Item.TopLeft
                    transform: [
                        Rotation {
                            origin.x: 0
                            origin.y: 0
                            axis.x: 1
                            axis.y: 0
                            axis.z: 0
                            angle: veloraTheme.lyricsTiltX
                        },
                        Rotation {
                            origin.x: 0
                            origin.y: 0
                            axis.x: 0
                            axis.y: 1
                            axis.z: 0
                            angle: veloraTheme.lyricsTiltY
                        }
                    ]

                    Repeater {
                        model: lyricsFourBlock.visibleWords

                        Text {
                            id: lyricsFourWordText

                            required property int index
                            required property var modelData

                            readonly property int sourceIndex: Number(modelData.sourceIndex)
                            readonly property bool activeWord: root.lyricsTimingMode === "plain-estimated" || !veloraTheme.lyricsActiveWordEnabled || sourceIndex === root.lyricsActiveIndex
                            readonly property string displayWord: veloraTheme.lyricsUppercase ? String(modelData.text).toUpperCase() : String(modelData.text)
                            readonly property color baseWordColor: root.lyricsWordColor(sourceIndex, lyricsFourBlock.blockIndex)

                            text: displayWord
                            x: lyricsPanel.wordFloatX(sourceIndex)
                            y: index * lyricsFourBlock.wordStep + lyricsPanel.wordFloatY(sourceIndex)
                            color: root.lyricsMaterialColor(baseWordColor, sourceIndex, activeWord)
                            opacity: root.lyricsRenderedWordOpacity(activeWord)
                            scale: root.lyricsWordScale(sourceIndex)
                            transformOrigin: Item.Center
                            font.family: veloraTheme.uiFont
                            font.pixelSize: Math.round(veloraTheme.lyricsFontSize)
                            font.weight: Font.Black
                            font.letterSpacing: 0
                            style: (veloraTheme.lyricsShadowEnabled || veloraTheme.lyricsDepthEnabled) ? Text.Outline : Text.Normal
                            styleColor: root.lyricsOutlineColor(activeWord)
                            renderType: Text.NativeRendering
                            layer.enabled: lyricsPanel.lyricsEffectEnabled(lyricsFourBlock.blockIndex)
                            layer.smooth: true
                            layer.effect: DropShadow {
                                horizontalOffset: lyricsPanel.lyricsEffectHorizontalOffset(lyricsFourBlock.blockIndex)
                                verticalOffset: lyricsPanel.lyricsEffectVerticalOffset(lyricsFourBlock.blockIndex)
                                radius: lyricsPanel.lyricsGlowRadius(lyricsFourBlock.blockIndex)
                                samples: lyricsPanel.lyricsGlowSamples(lyricsFourBlock.blockIndex)
                                spread: 0
                                transparentBorder: true
                                color: lyricsPanel.lyricsGlowColor(lyricsFourWordText.color, lyricsFourWordText.activeWord, lyricsFourBlock.blockIndex)
                            }
                        }
                    }
                }
            }
            }

            Canvas {
                id: lyricsCutMaskCanvas

                anchors.fill: parent
                visible: veloraTheme.lyricsMaskEnabled && veloraTheme.lyricsMaskHasStrokes

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.clearRect(0, 0, width, height)
                    ctx.fillStyle = "rgba(255,255,255,1)"
                    ctx.fillRect(0, 0, width, height)
                    const strokes = veloraTheme.lyricsMaskStrokes || []
                    ctx.globalCompositeOperation = "destination-out"
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    const feather = Math.max(0, Number(veloraTheme.lyricsMaskFeather) || 0)
                    function drawMaskStroke(points, lineWidth, alpha) {
                        ctx.globalAlpha = Math.max(0, Math.min(1, alpha))
                        ctx.lineWidth = Math.max(1, lineWidth)
                        ctx.beginPath()
                        ctx.moveTo(points[0].x * width, points[0].y * height)
                        for (let p = 1; p < points.length; p += 1)
                            ctx.lineTo(points[p].x * width, points[p].y * height)
                        ctx.stroke()
                    }
                    for (let i = 0; i < strokes.length; i += 1) {
                        const stroke = strokes[i] || {}
                        const points = stroke.points || []
                        if (points.length < 2)
                            continue
                        const brush = Math.max(1, Number(stroke.brush) || veloraTheme.lyricsMaskBrushSize)
                        if (feather > 0) {
                            drawMaskStroke(points, brush + feather * 2.0, 0.16)
                            drawMaskStroke(points, brush + feather, 0.34)
                        }
                        drawMaskStroke(points, brush, 1)
                    }
                    ctx.globalAlpha = 1
                    ctx.globalCompositeOperation = "source-over"
                }

                Connections {
                    target: veloraTheme
                    function onLyricsMaskRevisionChanged() { lyricsCutMaskCanvas.requestPaint() }
                    function onLyricsMaskFeatherChanged() { lyricsCutMaskCanvas.requestPaint() }
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onVisibleChanged: if (visible) requestPaint()
            }

            ShaderEffectSource {
                id: lyricsCutMaskSource

                anchors.fill: parent
                visible: false
                sourceItem: lyricsCutMaskCanvas
                hideSource: true
                live: true
                recursive: true
            }
        }
    }

    Variants {
        model: root.lyricsMaskEditorOpen ? Quickshell.screens : []

        PanelWindow {
            id: lyricsMaskEditorPanel

            required property var modelData
            readonly property int panelWidth: modelData.width > 0 ? modelData.width : 1920
            readonly property int panelHeight: modelData.height > 0 ? modelData.height : 1200

            screen: modelData
            color: "transparent"
            implicitWidth: panelWidth
            implicitHeight: panelHeight
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: true

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "velora-shell-lyrics-mask-editor"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            mask: Region {
                item: lyricsMaskEditorInputMask
            }

            Item {
                id: lyricsMaskEditorInputMask
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.closeLyricsMaskEditor()
                Component.onCompleted: forceActiveFocus()
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.12)
            }

            Canvas {
                id: lyricsMaskEditorCanvas

                anchors.fill: parent
                opacity: 0.82

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.clearRect(0, 0, width, height)
                    const strokes = veloraTheme.lyricsMaskStrokes || []
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    for (let i = 0; i < strokes.length; i += 1) {
                        const stroke = strokes[i] || {}
                        const points = stroke.points || []
                        if (points.length < 2)
                            continue
                        ctx.strokeStyle = "rgba(255,80,160,0.56)"
                        ctx.lineWidth = Math.max(1, Number(stroke.brush) || veloraTheme.lyricsMaskBrushSize)
                        ctx.beginPath()
                        ctx.moveTo(points[0].x * width, points[0].y * height)
                        for (let p = 1; p < points.length; p += 1)
                            ctx.lineTo(points[p].x * width, points[p].y * height)
                        ctx.stroke()
                    }

                    const live = root.lyricsMaskEditorPoints || []
                    if (live.length >= 2) {
                        ctx.strokeStyle = "rgba(255,255,255,0.78)"
                        ctx.lineWidth = Math.max(1, veloraTheme.lyricsMaskBrushSize)
                        ctx.beginPath()
                        ctx.moveTo(live[0].x * width, live[0].y * height)
                        for (let j = 1; j < live.length; j += 1)
                            ctx.lineTo(live[j].x * width, live[j].y * height)
                        ctx.stroke()
                    }
                }

                Connections {
                    target: veloraTheme
                    function onLyricsMaskRevisionChanged() { lyricsMaskEditorCanvas.requestPaint() }
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.CrossCursor
                onPressed: function(mouse) {
                    root.lyricsMaskEditorPoints = []
                    root.appendLyricsMaskPoint(lyricsMaskEditorPanel, mouse.x, mouse.y)
                    lyricsMaskEditorCanvas.requestPaint()
                }
                onPositionChanged: function(mouse) {
                    if (!pressed)
                        return
                    root.appendLyricsMaskPoint(lyricsMaskEditorPanel, mouse.x, mouse.y)
                    lyricsMaskEditorCanvas.requestPaint()
                }
                onReleased: {
                    root.commitLyricsMaskStroke()
                    lyricsMaskEditorCanvas.requestPaint()
                }
            }

            Row {
                z: 4
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 18
                anchors.rightMargin: 18
                spacing: 8

                Rectangle {
                    width: 86
                    height: 36
                    radius: 10
                    color: veloraTheme.withAlpha(veloraTheme.surfacePopup, 0.72)
                    border.width: 1
                    border.color: veloraTheme.withAlpha(veloraTheme.borderSoft, 0.38)

                    Text {
                        anchors.centerIn: parent
                        text: "Limpar"
                        color: veloraTheme.textPrimary
                        font.family: veloraTheme.uiFont
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            veloraTheme.clearLyricsMask(true)
                            lyricsMaskEditorCanvas.requestPaint()
                        }
                    }
                }

                Rectangle {
                    width: 86
                    height: 36
                    radius: 10
                    color: veloraTheme.withAlpha(veloraTheme.accentPrimary, 0.76)

                    Text {
                        anchors.centerIn: parent
                        text: "Concluir"
                        color: veloraTheme.buttonPrimaryText
                        font.family: veloraTheme.uiFont
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.closeLyricsMaskEditor()
                    }
                }
            }
        }
    }


    Variants {
        model: root.systemPopupKeyboardFocus
            && root.quickPopupType === "system"
            ? Quickshell.screens
            : []

        PanelWindow {
            id: systemKeyboardWindow

            required property var modelData
            readonly property bool focusedScreen: !Hyprland.focusedMonitor
                || modelData.name === Hyprland.focusedMonitor.name

            screen: modelData
            color: "transparent"
            implicitWidth: 1
            implicitHeight: 1
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            focusable: focusedScreen

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "velora-system-keyboard"
            WlrLayershell.keyboardFocus: focusedScreen
                ? WlrKeyboardFocus.Exclusive
                : WlrKeyboardFocus.None

            anchors {
                top: true
                left: true
            }

            mask: Region {
                item: systemKeyboardInputMask
            }

            Item {
                id: systemKeyboardInputMask

                width: 0
                height: 0
            }

            Item {
                id: systemKeyboardReceiver

                anchors.fill: parent
                focus: systemKeyboardWindow.focusedScreen
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Left) {
                        root.moveTopBarSystemPage(-1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Right) {
                        root.moveTopBarSystemPage(1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Escape) {
                        root.closeQuickPopup()
                        event.accepted = true
                    }
                }

                Component.onCompleted: {
                    if (systemKeyboardWindow.focusedScreen)
                        forceActiveFocus(Qt.ShortcutFocusReason)
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
                    const openSideTrim = root.sideVisualizerMounted ? Math.max(radius, root.sideVisualizerCapReach) : radius
                    const horizontalStart = barSide === "left" ? fx + openSideTrim : fx + radius
                    const horizontalEnd = barSide === "right" ? x2 - openSideTrim : x2

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
                        ctx.moveTo(x2, fy)
                        ctx.lineTo(x2, y2 - radius)
                        ctx.arc(x2 - radius, y2 - radius, radius, 0, Math.PI / 2, false)
                    }

                    if (horizontalEnd > horizontalStart) {
                        ctx.moveTo(horizontalStart, fy)
                        ctx.lineTo(horizontalEnd, fy)
                    }

                    if (horizontalEnd > horizontalStart) {
                        ctx.moveTo(horizontalStart, y2)
                        ctx.lineTo(horizontalEnd, y2)
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
                        paintCorner(ctx, "bottomRight", fx, fy, fw, fh, radius)
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
            }
        }
    }


    Variants {
        id: sidebarPanels
        model: root.shellSuppressedByFullscreen ? [] : Quickshell.screens

        PanelWindow {
            id: panel
            readonly property var bluetoothMenu: bluetoothPopover
            readonly property var notificationMenu: notificationsPopover
            readonly property var wifiMenu: wifiPopover
            readonly property var levelControls: railControls
            readonly property color desktopIconInk: barRoot.ink
            readonly property real desktopIconOpacity: barRoot.configuredIconOpacity
            readonly property string desktopAvatarSource: barRoot.profileImageSource()
            readonly property real desktopIconSize: Math.round(22 * barRoot.uiScale * barRoot.configuredIconScale)

            required property var modelData
            readonly property int panelWidth: width
            readonly property int panelHeight: height
            readonly property bool weatherTopSearchMode: root.weatherTopMode === "search"
            readonly property bool weatherTopConversationExpanded: false
            readonly property bool weatherTopNotificationAttached: root.weatherTopWindowOpen && root.notificationToastMounted
            readonly property int weatherTopOpenY: Math.max(root.desktopFrameMargin + 18, 30)
            readonly property int weatherTopTargetWidth: Math.round(Math.min(panelWidth - 100, weatherTopSearchMode ? 720 : 368))
            readonly property int weatherTopCompactHeight: 354
            readonly property int weatherTopNotificationHeight: weatherTopCompactHeight
            readonly property int weatherTopExpandedHeight: Math.round(Math.min(560, Math.max(420, panelHeight * 0.50)))
            readonly property int weatherTopSearchHeight: Math.round(Math.min(540, panelHeight - weatherTopOpenY - 70))
            readonly property int weatherTopTargetHeight: weatherTopSearchMode
                ? weatherTopSearchHeight
                : (weatherTopConversationExpanded
                    ? weatherTopExpandedHeight
                    : (weatherTopNotificationAttached ? weatherTopNotificationHeight : weatherTopCompactHeight))
            readonly property int weatherTopTargetX: Math.round((panelWidth - weatherTopTargetWidth) / 2)
            readonly property int weatherTopTargetY: root.weatherTopOpen ? weatherTopOpenY : -weatherTopTargetHeight - 18
            readonly property int weatherTopCornerRadius: 24
            property var activeRailSystemPopover: null
            readonly property var desktopEdgePanel: infiniteControlMenu.mounted ? infiniteControlMenu : edgePopover
            readonly property bool wantsDrawerKeyboard: infiniteControlMenu.mounted || railControls.mounted || (edgePopover.mounted && !edgePopover.keepOpenOutside) || coffeePopover.mounted || notesPopover.mounted || bluetoothPopover.mounted || notificationsPopover.mounted || wifiPopover.mounted || root.focusMode || root.quickPopupType === "search" || root.quickPopupType === "agenda" || root.quickPopupType === "weatherPanel" || root.settingsPanelOpen || root.wallpaperSelectorOpen || (!root.topBarLayout && root.weatherTopKeyboardFocus) || root.leftMenuInteractiveFocus
            readonly property bool whatsappKeyboard: edgePopover.mounted && edgePopover.keepOpenOutside

            screen: modelData
            color: "transparent"
            implicitWidth: Math.max(1, modelData.width)
            exclusiveZone: root.barReserveWidth
            exclusionMode: ExclusionMode.Normal
            focusable: wantsDrawerKeyboard || whatsappKeyboard

            // Reservation and layer must switch in the same commit. Keeping
            // Bottom until progress reaches zero lets the reserving sidebar
            // arrange before the Top workspace strip, then jump down at rest.
            WlrLayershell.layer: root.infiniteDesktopBarsActive
                && !wantsDrawerKeyboard && !whatsappKeyboard ? WlrLayer.Bottom : WlrLayer.Overlay
            WlrLayershell.namespace: "velora-shell-unified-bar"
            WlrLayershell.keyboardFocus: root.weatherTopKeyboardFocus
                ? WlrKeyboardFocus.OnDemand
                : (wantsDrawerKeyboard ? WlrKeyboardFocus.Exclusive : whatsappKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None)

            // ExclusionMode.Normal places this window below the 40 px topbar.
            // Its local origin already is the join: adding barHeight here
            // would leave an unpainted band behind the analog clock.
            BackgroundEffect.blurRegion: Region {
                item: root.composition && root.composition.barBlurEnabled
                    && (root.composition.barMaterial === "glass" || !Platform.NativeBlur.supports("unified-bar-shape")) ? unifiedFrameCanvas : null
            }

            Core.FramePublisher {
                id: unifiedShapePublisher
                onPublish: panel.syncUnifiedBarNativeShape()
            }
            function syncUnifiedBarNativeShape() {
                const active = root.composition
                    && (["liquid", "liquid-glass"].includes(root.composition.barMaterial) || root.composition.nativeBarMaterial)
                    && !(root.infiniteDesktopFrameFoldProgress > .999
                        && (!Platform.NativeBlur.supports("infinite-desktop-dock-compact")
                            || !Platform.NativeBlur.supports("infinite-top-frame-continuous")))
                    && width > 0 && height > 0
                if (!active) {
                    Platform.NativeBlur.dispatch("velora-blur:unified-bar-shape " + modelData.name + " 0")
                    return
                }
                // Extend the vertical lens above this LayerShell surface.
                // Its own rounded top edge stays off-screen; the visible
                // L-shaped corner is drawn separately by the unified frame.
                const opticalTopOverlap = root.infiniteDesktopMorphProgress <= .0001 || Platform.NativeBlur.supports("infinite-top-frame-continuous")
                    ? Math.max(64, root.sidebarCornerRadius * 3) : 0
                const top = -opticalTopOverlap / height
                const rail = root.sidebarVisualWidth / width
                // Move the vertical lens' medial axis outside the visible
                // rail, mirroring the clipped horizontal lens above.
                const left = root.barOnRight
                    ? (width - root.sidebarVisualWidth) / width : -rail
                Platform.NativeBlur.dispatch("velora-blur:unified-bar-shape " + modelData.name + " 1 "
                    + Number(left).toFixed(6) + " "
                    + Number(top).toFixed(6) + " "
                    + Number(rail * 2).toFixed(6) + " "
                    + Number(1 - top).toFixed(6) + " "
                    + Number(root.sidebarCornerRadius / width).toFixed(6) + " "
                    + Number(railControls.nativePanel ? railControls.nativePanel.y / height : 0).toFixed(6) + " "
                    + Number(railControls.nativePanel ? railControls.nativePanel.width / width : 0).toFixed(6) + " "
                    + Number(railControls.nativePanel ? railControls.nativePanel.height / height : 0).toFixed(6) + " "
                    + Number(root.bottomBarHeight / height).toFixed(6) + " "
                    + Number(railControls.nativePanel && railControls.nativePanel.extension ? railControls.nativePanel.extension.y / height : 0).toFixed(6) + " "
                    + Number(railControls.nativePanel && railControls.nativePanel.extension ? railControls.nativePanel.extension.width / width : 0).toFixed(6) + " "
                    + Number(railControls.nativePanel && railControls.nativePanel.extension ? railControls.nativePanel.extension.height / height : 0).toFixed(6) + " "
                    + Number(root.oppositeFrameWidth / width).toFixed(6) + " "
                    + Number(panel.desktopEdgePanel.bodyY / height).toFixed(6) + " "
                    + Number(panel.desktopEdgePanel.mounted ? panel.desktopEdgePanel.bodyWidth / width : 0).toFixed(6) + " "
                    + Number(panel.desktopEdgePanel.bodyHeight / height).toFixed(6) + " "
                    + Number(panel.desktopEdgePanel.contour).toFixed(6) + " "
                    + Number(panel.desktopEdgePanel.extension.y / height).toFixed(6) + " "
                    + Number(panel.desktopEdgePanel.extension.width / width).toFixed(6) + " "
                    + Number(panel.desktopEdgePanel.extension.height / height).toFixed(6) + " "
                    + panel.desktopEdgePanel.contourSamples.map(value => Number(value).toFixed(6)).join(" ") + " "
                    + Number(panel.desktopEdgePanel.sidebarWaveScale).toFixed(6) + " "
                    + Number(panel.desktopEdgePanel.dockProgress).toFixed(6) + " "
                    + Number(panel.desktopEdgePanel.sidebarWaveWidth / width).toFixed(6) + " "
                    + panel.desktopEdgePanel.sidebarSamples.map(value => Number(value).toFixed(6)).join(" ") + " "
                    + Number(root.infiniteDesktopFrameFoldProgress).toFixed(6) + " "
                    + Number(infiniteBottomDock.dockWidth / width).toFixed(6))
            }

            DesktopBarMaterial {
                monitorName: panel.modelData.name
                composition: root.composition
                enabled: root.sideBarLayoutEnabled
            }

            Component.onCompleted: {
                root.registerInfiniteDesktopPanel(modelData.name, panel)
                Qt.callLater(syncUnifiedBarNativeShape)
            }
            Component.onDestruction: {
                root.registerInfiniteDesktopPanel(modelData.name, null)
                Platform.NativeBlur.dispatch("velora-blur:unified-bar-shape " + modelData.name + " 0")
            }
            onWidthChanged: Qt.callLater(syncUnifiedBarNativeShape)
            onHeightChanged: Qt.callLater(syncUnifiedBarNativeShape)

            HyprlandFocusGrab {
                id: weatherTopFocusGrab

                active: !root.topBarLayout && root.weatherTopOpen && root.weatherTopKeyboardFocus
                windows: [panel]
                onCleared: {
                    if (root.weatherTopOpen && root.weatherTopKeyboardFocus)
                        root.closeWeatherTop()
                }
            }

            mask: Region {
                intersection: Intersection.Combine

                Region { item: infiniteBottomDock.visible && root.infiniteDesktopTargetReveal > .99 && infiniteBottomDock.entries.length ? infiniteBottomDock.dockInput : null }
                Region { item: root.infiniteDesktopTargetReveal > .99 && infiniteBottomDock.controlsInput.visible ? infiniteBottomDock.controlsInput : null }
                Region { item: infiniteControlMenu.maskItem }
                Region { item: root.infiniteDesktopTargetReveal > .99 ? infiniteBottomDock.workspaceItem(0) : null; radius: 18 * infiniteBottomDock.unit }
                Region { item: root.infiniteDesktopTargetReveal > .99 ? infiniteBottomDock.workspaceItem(1) : null; radius: 18 * infiniteBottomDock.unit }
                Region { item: root.infiniteDesktopTargetReveal > .99 ? infiniteBottomDock.workspaceItem(2) : null; radius: 18 * infiniteBottomDock.unit }
                Region { item: root.infiniteDesktopTargetReveal > .99 ? infiniteBottomDock.workspaceItem(3) : null; radius: 18 * infiniteBottomDock.unit }
                Region { item: root.infiniteDesktopTargetReveal > .99 ? infiniteBottomDock.workspaceItem(4) : null; radius: 18 * infiniteBottomDock.unit }
                Region { item: root.infiniteDesktopTargetReveal > .99 ? infiniteBottomDock.workspaceItem(5) : null; radius: 14 * infiniteBottomDock.unit }
                Region { item: root.infiniteDesktopTargetReveal > .99 ? infiniteBottomDock.workspaceItem(6) : null; radius: 14 * infiniteBottomDock.unit }

                Region {
                    item: root.infiniteDesktopSourceReveal > .99 ? barRoot.panelMaskItem : null
                    radius: barRoot.cornerRadius
                }

                // Allow the 24 px concave join to extend beyond the
                // 66 px sidebar instead of clipping it at x=66.
                Region {
                    item: sidebarTopJoinMask
                    radius: 0
                }

                Region {
                    item: inlineWeatherTopTriggerMask
                    radius: 0
                }

                Region {
                    item: inlineWeatherTopInputMask
                    radius: panel.weatherTopCornerRadius
                }

                Region {
                    item: inlineTopSearchOutsideInputMask
                    radius: 0
                }

                Region { item: edgeTrigger }
                Region { item: edgePopover.maskItem }
                Region { item: edgePopover.labelMask }
                Region { item: edgePopover.contactsDragMask.visible ? edgePopover.contactsDragMask : null }
                Region { item: railControls.volumeMask }
                Region { item: railControls.brightnessMask }
                Region { item: railControls.batteryMask }
                Region { item: coffeePopover.maskItem }
                Region { item: notesPopover.maskItem }
                Region { item: bluetoothPopover.maskItem }
                Region { item: notificationsPopover.maskItem }
                Region { item: wifiPopover.maskItem }
                Region { item: railToolOutsideInput }

                Region {
                    item: inlineNotificationToastInputMask
                    radius: inlineNotificationToastStage.bubbleRadius
                }


                Region {
                    y: 0
                    width: 0
                    height: 0
                    radius: 0
                }
            }

            Item {
                id: sidebarTopJoinMask

                x: root.barOnRight
                    ? Math.max(0, panel.width - root.sidebarVisualWidth
                        - root.sidebarCornerRadius)
                    : 0
                y: 0
                width: root.sideBarLayoutEnabled
                    ? (root.sidebarVisualWidth + root.sidebarCornerRadius) * root.infiniteDesktopRailRemaining : 0
                height: root.sideBarLayoutEnabled
                    ? root.sidebarCornerRadius * root.infiniteDesktopRailRemaining : 0
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
                visible: (root.frameVisualsMounted || root.sideBarLayoutEnabled) && root.infiniteDesktopFrameFoldProgress < .0001
                opacity: root.layoutSwitchOpacity
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
                    const openSideTrim = root.sideVisualizerMounted ? Math.max(radius, root.sideVisualizerCapReach) : radius
                    const horizontalStart = barSide === "left" ? fx + openSideTrim : fx + radius
                    const horizontalEnd = barSide === "right" ? x2 - openSideTrim : x2 - radius

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

                    if (horizontalEnd > horizontalStart) {
                        ctx.moveTo(horizontalStart, y2)
                        ctx.lineTo(horizontalEnd, y2)
                    }

                    ctx.stroke()
                    ctx.restore()
                }

                function paintSidebarGutterFill(ctx) {
                    if (!root.sideBarLayoutEnabled)
                        return
                    ctx.save()
                    if (root.barOnRight) {
                        ctx.translate(width, 0)
                        ctx.scale(-1, 1)
                    }
                    if (!root.barBackgroundEnabled) {
                        // Keep the attached bodies, without filling the rail or frame.
                        ctx.beginPath()
                        const control = railControls.nativePanel
                        if (control) {
                            ctx.rect(root.sidebarVisualWidth, control.y, control.width, control.height)
                            if (control.extension) ctx.rect(root.sidebarVisualWidth, control.extension.y,
                                control.extension.width, control.extension.height)
                        }
                        if (edgePopover.mounted) {
                            const reach = edgePopover.bodyWidth + edgePopover.extension.width
                            ctx.rect(width - root.oppositeFrameWidth - reach, edgePopover.bodyY,
                                reach, edgePopover.bodyHeight)
                        }
                        ctx.clip()
                    }
                    const w = root.sidebarVisualWidth
                    const r = root.sidebarCornerRadius
                    // The compositor already accounts for the topbar's
                    // exclusive zone. Paint from this window's local origin.
                    const top = 0
                    const bottomStrip = Math.min(height, root.bottomBarHeight)
                    const innerRadius = Math.min(r, Math.max(0, width - w),
                        Math.max(0, (height - bottomStrip - top) / 2))
                    // A concave corner joins the two bars into one L-shaped
                    // surface. Keep the old sidebar controls inside this rail.
                    ctx.beginPath()
                    ctx.moveTo(0, top)

                    // Smooth L-shaped join with the topbar:
                    // extend along the top, then curve back into the
                    // straight right edge of the sidebar.
                    ctx.lineTo(w + r, top)
                    ctx.arcTo(w, top, w, top + r, r)

                    railControls.appendOutline(ctx, w)
                    ctx.lineTo(w, height - bottomStrip - innerRadius)
                    ctx.arcTo(w, height - bottomStrip,
                        w + innerRadius, height - bottomStrip, innerRadius)
                    const edge = width - root.oppositeFrameWidth
                    ctx.lineTo(edge - innerRadius, height - bottomStrip)
                    ctx.arcTo(edge, height - bottomStrip, edge, height - bottomStrip - innerRadius, innerRadius)
                    if (edgePopover.mounted && !root.barOnRight) {
                        const reach = edgePopover.bodyWidth
                        const by = edgePopover.bodyY
                        const bh = edgePopover.bodyHeight
                        const join = Math.min(24, reach * .5)
                        const nose = edge - reach
                        ctx.lineTo(edge, by + bh + join)
                        ctx.bezierCurveTo(edge, by + bh - join, nose, by + bh + join, nose, by + bh - join)
                        if (edgePopover.contour > .01) {
                            for (let i = 160; i >= 0; --i) {
                                const t = i / 160
                                const wave = edgePopover.contourOffset(t)
                                ctx.lineTo(nose + wave, by + bh * t)
                            }
                        } else if (edgePopover.extension.width > .01) {
                            const ey = edgePopover.extension.y
                            const ew = edgePopover.extension.width
                            const eh = edgePopover.extension.height
                            ctx.lineTo(nose, ey + eh + 8)
                            ctx.bezierCurveTo(nose, ey + eh - 4, nose - ew, ey + eh + 12, nose - ew, ey + eh - 10)
                            ctx.lineTo(nose - ew, ey + 10)
                            ctx.bezierCurveTo(nose - ew, ey - 12, nose, ey + 4, nose, ey - 8)
                        }
                        ctx.lineTo(nose, by + join)
                        ctx.bezierCurveTo(nose, by - join, edge, by + join, edge, by - join)
                    }
                    ctx.lineTo(edge, top + innerRadius)
                    ctx.arcTo(edge, top, edge - innerRadius, top, innerRadius)
                    ctx.lineTo(width, top)
                    ctx.lineTo(width, height)
                    ctx.lineTo(0, height)
                    ctx.closePath()
                    if (edgePopover.sidebarWaveScale > 0 && !root.barOnRight) {
                        // Same samples and one fill as the right menu: no overlay tint.
                        ctx.moveTo(0, top)
                        for (let i = 0; i <= 160; ++i) {
                            const t = i / 160
                            ctx.lineTo(w + edgePopover.sidebarOffset(t), height * t)
                        }
                        ctx.lineTo(0, height)
                        ctx.closePath()
                    }
                    // Only this outline is supplied by the native material.
                    // Other attached QML panels still need their own tint.
                    ctx.fillStyle = root.composition && root.composition.nativeBarMaterial
                        ? "transparent" : root.sidebarBarMaterialColor()
                    ctx.fill()
                    ctx.restore()
                }

                function paintSidebarSurface(ctx) {
                    if (!root.sideBarLayoutEnabled)
                        return
                    // The unified bar has no internal border between its two
                    // legs. The wallpaper contrast defines the inner edge.
                    if (root.composition)
                        return

                    ctx.save()
                    if (root.barOnRight) {
                        ctx.translate(width, 0)
                        ctx.scale(-1, 1)
                    }
                    const w = root.sidebarVisualWidth
                    const r = root.sidebarCornerRadius
                    const bottom = height - root.bottomBarHeight
                    ctx.strokeStyle = "#303e4b66"
                    ctx.lineWidth = 1
                    ctx.beginPath()
                    ctx.moveTo(w + r, 0.5)
                    ctx.arcTo(w - 0.5, 0.5, w - 0.5, r, r)
                    railControls.appendOutline(ctx, w - 0.5)
                    ctx.lineTo(w - 0.5, bottom - r - 0.5)
                    ctx.arcTo(w - 0.5, bottom - 0.5,
                        w + r, bottom - 0.5, r)
                    ctx.lineTo(width, bottom - 0.5)
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
                    ctx.fillStyle = root.composition
                        ? root.composition.unifiedBarSurface
                        : root.desktopFrameMatteColor()
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

                function paintWeatherTopSurface(ctx) {
                    if (panel.weatherTopSearchMode) return
                    if (root.topBarLayout)
                        return
                    if (!root.weatherTopWindowOpen && inlineWeatherTopFrame.opacity <= 0.001)
                        return
                    if (inlineWeatherTopFrame.width <= 0 || inlineWeatherTopFrame.height <= 0 || inlineWeatherTopFrame.opacity <= 0.001)
                        return

                    const gx = Math.round(inlineWeatherTopFrame.x)
                    const gw = Math.round(inlineWeatherTopFrame.width)
                    const gy = Math.round(inlineWeatherTopFrame.surfaceY)
                    const gh = Math.round(inlineWeatherTopFrame.surfaceHeight)
                    const radius = Math.min(panel.weatherTopCornerRadius, Math.max(0, gw / 2), Math.max(0, gh / 2))
                    if (gh <= 0)
                        return

                    ctx.save()
                    ctx.globalAlpha = root.frameVisualsReveal * inlineWeatherTopFrame.opacity
                    ctx.fillStyle = root.composition
                        ? root.composition.unifiedBarSurface
                        : root.desktopFrameMatteColor()
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

                function attachedSidePath(ctx, x, y, w, h, radius, side) {
                    const r = Math.min(radius, Math.max(0, w / 2), Math.max(0, h / 2))
                    const x2 = x + w
                    const y2 = y + h

                    ctx.beginPath()
                    if (side === "right") {
                        ctx.moveTo(x + r, y)
                        ctx.lineTo(x2, y)
                        ctx.lineTo(x2, y2)
                        ctx.lineTo(x + r, y2)
                        ctx.arcTo(x, y2, x, y2 - r, r)
                        ctx.lineTo(x, y + r)
                        ctx.arcTo(x, y, x + r, y, r)
                    } else {
                        ctx.moveTo(x, y)
                        ctx.lineTo(x2 - r, y)
                        ctx.arcTo(x2, y, x2, y + r, r)
                        ctx.lineTo(x2, y2 - r)
                        ctx.arcTo(x2, y2, x2 - r, y2, r)
                        ctx.lineTo(x, y2)
                        ctx.lineTo(x, y)
                    }
                    ctx.closePath()
                }

                function strokeAttachedSide(ctx, x, y, w, h, radius, side) {
                    const r = Math.min(radius, Math.max(0, w / 2), Math.max(0, h / 2))
                    const x2 = x + w
                    const y2 = y + h

                    ctx.beginPath()
                    if (side === "right") {
                        ctx.moveTo(x + r, y + 0.5)
                        ctx.arcTo(x + 0.5, y + 0.5, x + 0.5, y + r, r)
                        ctx.lineTo(x + 0.5, y2 - r)
                        ctx.arcTo(x + 0.5, y2 - 0.5, x + r, y2 - 0.5, r)
                        ctx.lineTo(x2, y2 - 0.5)
                    } else {
                        ctx.moveTo(x, y + 0.5)
                        ctx.lineTo(x2 - r, y + 0.5)
                        ctx.arcTo(x2 - 0.5, y + 0.5, x2 - 0.5, y + r, r)
                        ctx.lineTo(x2 - 0.5, y2 - r)
                        ctx.arcTo(x2 - 0.5, y2 - 0.5, x2 - r, y2 - 0.5, r)
                        ctx.lineTo(x, y2 - 0.5)
                    }
                    ctx.stroke()
                }

                function paintFrameAttachedSurface(ctx, x, y, w, h, radius, side, alpha) {
                    if (w <= 1 || h <= 1 || alpha <= 0.001)
                        return

                    ctx.save()
                    ctx.globalAlpha = root.frameVisualsReveal * alpha
                    ctx.fillStyle = root.desktopFrameMatteColor()
                    attachedSidePath(ctx, x, y, w, h, radius, side)
                    ctx.fill()

                    ctx.strokeStyle = root.desktopFrameBorderColor()
                    ctx.lineWidth = 1
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    strokeAttachedSide(ctx, x, y, w, h, radius, side)
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

                    ctx.clearRect(0, 0, width, height)
                    if (!root.frameVisualsMounted || fw <= 0 || fh <= 0) {
                        paintSidebarGutterFill(ctx)
                        return
                    }

                    ctx.save()
                    ctx.globalAlpha = root.frameVisualsReveal
                    ctx.fillStyle = root.desktopFrameMatteColor()
                    // The native frame already owns these strips and rounded
                    // corners. Its interior starts at the topbar seam, while
                    // the legacy frame uses desktopFrameMargin; painting both
                    // produces a second, displaced corner on bright wallpaper.
                    if (root.barBackgroundEnabled && (!root.composition || !root.composition.nativeBarMaterial)) {
                        // Split the canvas at the main-area edge.  The frame owns the
                        // content side; paintSidebarGutterFill owns the sidebar side.
                        // Previously these strips crossed behind the translucent bar,
                        // which made the overlap reappear whenever opacity was lowered.
                        const matteLeft = barSide === "left" ? fx : 0
                        const matteRight = barSide === "right" ? fx + fw : width
                        const matteWidth = Math.max(0, matteRight - matteLeft)
                        ctx.fillRect(matteLeft, 0, matteWidth, fy)
                        ctx.fillRect(matteLeft, fy + fh, matteWidth, Math.max(0, height - fy - fh))

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
                        // When the wallpaper strip is open, the visualizer's molded
                        // cap is the bottom corner on the bar side.  Painting another
                        // frame corner here produced the small translucent overlap.

                        paintFrameOutline(ctx, fx, fy, fw, fh, radius)
                    }
                    paintWeatherTopSurface(ctx)

                    ctx.restore()

                    paintSidebarGutterFill(ctx)
                    paintSidebarSurface(ctx)
                    paintInlineNotificationToast(ctx)
                }

                Component.onCompleted: if (visible) requestPaint()
                onWidthChanged: if (visible) requestPaint()
                onHeightChanged: if (visible) requestPaint()
                onVisibleChanged: if (visible) requestPaint()
            }

            // Physical screen corner cutouts. They suggest a rounded display
            InfiniteDesktopFrame {
                anchors.fill: parent
                progress: root.infiniteDesktopFrameFoldProgress
                rightSide: root.barOnRight
                dockCount: infiniteBottomDock.entries.length
                surface: root.sidebarBarMaterialColor()
                visible: root.barBackgroundEnabled && progress > 0 && progress < 1 && (!root.composition || !root.composition.nativeBarMaterial)
                z: 0
            }
            InfiniteDesktopDock {
                id: infiniteBottomDock
                anchors.fill: parent
                config: root.composition.configStore
                theme: root.composition.topbarTheme
                screen: panel.modelData
                shell: root
                edgePanel: panel.desktopEdgePanel
                controlStatus: root.composition.networkStatus
                controlTimer: root.composition.clockTimerService
                controlsParent: panel
                visualizer: root.composition.audioVisualizer
                waveformEnabled: root.composition.dockWaveformEnabled
                onControlActivated: (type, item) => infiniteControlMenu.activate(type, item)
                progress: root.infiniteDesktopFrameFoldProgress
                reveal: root.infiniteDesktopTargetReveal
                nativeMaterial: root.composition.nativeBarMaterial && Platform.NativeBlur.supports("infinite-desktop-dock-compact")
                    && Platform.NativeBlur.supports("infinite-top-frame-continuous")
                surface: root.sidebarBarMaterialColor()
                onDockWidthChanged: Qt.callLater(panel.syncUnifiedBarNativeShape)
                z: 2
            }
            TopBarFeature.InfiniteDesktopMenu {
                id: infiniteControlMenu
                anchors.fill: parent
                z: 12
                composition: root.composition
                shell: root
                screenName: panel.modelData.name
                enabled: root.infiniteDesktopTargetReveal > .99
                railWidth: 4 * infiniteBottomDock.unit
                onOpening: {
                    edgePopover.closeInstant()
                    root.composition.closeTopbarTool()
                    if (toolType === "battery") root.composition.fanPlusService.refresh()
                }
                onShapeChanged: Qt.callLater(panel.syncUnifiedBarNativeShape)
            }
            Connections {
                target: panel.desktopEdgePanel
                function onShapeChanged() { Qt.callLater(panel.syncUnifiedBarNativeShape) }
            }
            Rectangle {
                x: 0; y: 0; width: 1; height: 1
                color: "#01000000"
                visible: !!root.composition && root.composition.nativeBarMaterial
            }

            // Physical screen corner cutouts. They suggest a rounded display
            // without painting black strips along any straight edge.
            // Keep each fading cutout bounded to its own corner. A transparent
            // full-screen Canvas still damages the whole output when faded.
            Repeater {
                model: 2
                Canvas {
                    required property int index
                    z: 100
                    width: Math.min(root.screenCornerRadius, panel.width / 2, panel.height)
                    height: width
                    x: index === 0 ? 0 : panel.width - width
                    y: panel.height - height
                    visible: root.barBackgroundEnabled && root.sideBarLayoutEnabled
                    opacity: root.infiniteDesktopFrameRemaining
                    antialiasing: true
                    onPaint: {
                        const c = getContext("2d")
                        c.clearRect(0,0,width,height)
                        c.save()
                        if (index === 1) { c.translate(width,0); c.scale(-1,1) }
                        c.fillStyle = "#000000"
                        c.beginPath()
                        c.moveTo(0,height)
                        c.lineTo(0,0)
                        c.arc(width,0,width,Math.PI,Math.PI/2,true)
                        c.closePath(); c.fill(); c.restore()
                    }
                    Component.onCompleted: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    onVisibleChanged: if (visible) requestPaint()
                }
            }

            Connections {
                target: veloraTheme
                function onSurfaceBaseChanged() { if (unifiedFrameCanvas.visible) unifiedFrameCanvas.requestPaint() }
                function onSurfaceSidebarChanged() { if (unifiedFrameCanvas.visible) unifiedFrameCanvas.requestPaint() }
                function onSidebarOpacityChanged() { if (unifiedFrameCanvas.visible) unifiedFrameCanvas.requestPaint() }
                function onBarOpacityChanged() { if (unifiedFrameCanvas.visible) unifiedFrameCanvas.requestPaint() }
                function onThemeModeChanged() { if (unifiedFrameCanvas.visible) unifiedFrameCanvas.requestPaint() }
                function onThemeIdChanged() { if (unifiedFrameCanvas.visible) unifiedFrameCanvas.requestPaint() }
                function onPopupBorderGlowChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onSidebarBorderGlowChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onBorderSoftChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
            }

            Connections {
                target: root.composition
                function onUnifiedBarSurfaceChanged() {
                    unifiedFrameCanvas.requestPaint()
                }
                function onUnifiedBarBorderChanged() {
                    unifiedFrameCanvas.requestPaint()
                }
                function onUnifiedBarTextPrimaryChanged() {
                    unifiedFrameCanvas.requestPaint()
                }
                function onUnifiedBarAccentChanged() {
                    unifiedFrameCanvas.requestPaint()
                }
                function onBarBackgroundEnabledChanged() { unifiedFrameCanvas.requestPaint() }
                function onBarMaterialChanged() {
                    panel.syncUnifiedBarNativeShape()
                    unifiedFrameCanvas.requestPaint()
                }
                function onOpticsGenerationChanged() {
                    panel.syncUnifiedBarNativeShape()
                    unifiedFrameCanvas.requestPaint()
                }
                function onNativeBarMaterialChanged() {
                    panel.syncUnifiedBarNativeShape()
                    unifiedFrameCanvas.requestPaint()
                }
                function onBarWaveStrengthChanged() {
                    unifiedFrameCanvas.requestPaint()
                }
            }

            Connections {
                target: root
                function onSettingsPanelOpenChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onSettingsPanelWindowOpenChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onNotificationToastMountedChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onNotificationToastVisibleChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onNotificationToastSerialChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
            }

            Connections {
                target: root
                function onBarOnRightChanged() { if (unifiedFrameCanvas.visible) unifiedFrameCanvas.requestPaint() }
                function onSideBarLayoutEnabledChanged() { if (unifiedFrameCanvas.visible) unifiedFrameCanvas.requestPaint() }
                function onUnifiedBarWavePhaseChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onDesktopFrameMarginChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onDesktopFrameRadiusChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onFrameVisualsMountedChanged() { unifiedFrameCanvas.requestPaint() }
                function onFrameVisualsRevealChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onWeatherTopOpenChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onWeatherTopWindowOpenChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onLeftMenuFrameRevealChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onLeftMenuHandleSurfaceRevealChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
                function onQuickPopupJoinedToBarChanged() { if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint() }
            }

            Rectangle {
                id: inlineTopSearchBackdrop

                anchors.fill: parent
                visible: !root.topBarLayout && root.weatherTopWindowOpen && panel.weatherTopSearchMode
                color: "#28000000"
                opacity: !root.topBarLayout && root.weatherTopOpen && panel.weatherTopSearchMode ? 1 : 0
                z: 24

                Behavior on opacity {
                    enabled: true
                    NumberAnimation {
                        duration: root.weatherTopOpen ? 420 : 240
                        easing.type: root.weatherTopOpen && panel.weatherTopSearchMode ? Easing.InOutSine : veloraTheme.motionEaseExit
                    }
                }
            }

            Item {
                id: inlineWeatherTopTriggerMask

                x: Math.round(root.mainAreaX(panel.panelWidth)
                    + (root.mainAreaWidth(panel.panelWidth) - width) / 2)
                y: 0
                width: root.topBarLayout || !root.weatherMenuEnabled || (root.composition && root.composition.referenceAppearance) ? 0
                    : Math.round(Math.min(420, root.mainAreaWidth(panel.panelWidth) * .28))
                height: root.topBarLayout ? 0 : (root.weatherTopWindowOpen ? Math.max(12, panel.weatherTopOpenY + 2) : Math.max(12, root.desktopFrameMargin + 2))
                z: 35

                MouseArea {
                    anchors.fill: parent
                    enabled: !root.topBarLayout && root.weatherMenuEnabled && !(root.composition && root.composition.referenceAppearance)
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    onEntered: {
                        root.weatherTopTriggerHovering = true
                        root.openWeatherTopFromMouse()
                    }
                    onExited: {
                        root.weatherTopTriggerHovering = false
                        root.scheduleWeatherTopHoverClose()
                    }
                }
            }

            Item {
                id: inlineTopSearchOutsideInputMask

                width: !root.topBarLayout && root.weatherTopOpen && panel.weatherTopSearchMode ? parent.width : 0
                height: !root.topBarLayout && root.weatherTopOpen && panel.weatherTopSearchMode ? parent.height : 0
                z: 25

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: root.closeWeatherTop()
                }
            }

            Item {
                id: inlineWeatherTopFrame

                readonly property bool mounted: !root.topBarLayout && root.weatherTopWindowOpen
                readonly property int surfaceY: root.weatherTopWindowOpen && y >= root.desktopFrameMargin
                    ? root.desktopFrameMargin
                    : Math.round(y)
                readonly property int surfaceHeight: Math.max(0, Math.round(y + height - surfaceY))

                property real searchReveal: root.weatherTopOpen ? 1 : 0
                Behavior on searchReveal {
                    NumberAnimation { duration: root.weatherTopOpen ? 480 : 280; easing.type: root.weatherTopOpen ? Easing.OutExpo : Easing.InOutCubic }
                }
                width: panel.weatherTopSearchMode ? 440 + (panel.weatherTopTargetWidth - 440) * searchReveal : panel.weatherTopTargetWidth
                height: panel.weatherTopSearchMode ? 56 + (panel.weatherTopTargetHeight - 56) * searchReveal : panel.weatherTopTargetHeight
                x: Math.round((panel.panelWidth - width) / 2)
                y: panel.weatherTopSearchMode ? -80 + (panel.weatherTopOpenY + 80) * searchReveal : panel.weatherTopTargetY
                opacity: 1
                visible: mounted
                z: 26

                Rectangle {
                    anchors.fill: parent
                    visible: panel.weatherTopSearchMode
                    radius: 24
                    color: root.composition ? root.composition.topbarTheme.wallpaperSurfaceTone : veloraTheme.surfaceBase
                    opacity: inlineWeatherTopFrame.searchReveal
                    border.width: 1
                    border.color: root.composition ? root.composition.topbarTheme.borderStrong : veloraTheme.borderSoft
                }

                onXChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onYChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onWidthChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onHeightChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onSurfaceYChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onSurfaceHeightChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                Behavior on y {
                    enabled: !panel.weatherTopSearchMode && veloraTheme.motionEnabled
                    NumberAnimation {
                        duration: root.weatherTopOpen ? veloraTheme.motionPanelIn : root.quickPopupLineCloseDuration
                        easing.type: root.weatherTopOpen ? Easing.BezierSpline : Easing.InOutCubic
                        easing.bezierCurve: root.weatherTopOpen ? veloraTheme.motionCurveEmphasizedAccel : veloraTheme.motionCurveStandard
                    }
                }

                Behavior on height {
                    enabled: !panel.weatherTopSearchMode && veloraTheme.motionEnabled
                    NumberAnimation {
                        duration: veloraTheme.motionPanelGeometry
                        easing.type: veloraTheme.motionEaseEnter
                    }
                }
            }

            Item {
                id: inlineWeatherTopInputMask

                x: inlineWeatherTopFrame.x
                y: inlineWeatherTopFrame.surfaceY
                width: !root.topBarLayout && root.weatherTopWindowOpen ? inlineWeatherTopFrame.width : 0
                height: !root.topBarLayout && root.weatherTopWindowOpen ? inlineWeatherTopFrame.surfaceHeight : 0
                z: 27
            }

            Loader {
                id: inlineWeatherTopPanel

                x: inlineWeatherTopFrame.x
                y: inlineWeatherTopFrame.y
                width: inlineWeatherTopFrame.width
                height: inlineWeatherTopFrame.height
                active: !root.topBarLayout && root.weatherTopWindowOpen
                visible: active
                clip: panel.weatherTopSearchMode
                opacity: inlineWeatherTopFrame.opacity
                z: 32

                sourceComponent: panel.weatherTopSearchMode ? inlineTopSearchComponent : inlineTopWeatherComponent

                onLoaded: {
                    if (panel.weatherTopSearchMode && item && item.requestSearchFocus)
                        item.requestSearchFocus()
                }
            }

            Component {
                id: inlineTopWeatherComponent

                VeloraWeatherTopPanel {
                    theme: veloraTheme
                    motionTokens: root.composition ? root.composition.motionTokens : null
                    weather: root.composition ? root.composition.forecastService : null
                    open: root.weatherTopOpen
                    onActivated: root.engageWeatherTop()
                    onCloseRequested: root.closeWeatherTop()
                    onPointerInsideChanged: function(inside) {
                        root.setWeatherTopPanelHovering(inside)
                    }
                }
            }

            Component {
                id: inlineTopSearchComponent

                VeloraSearchPanel {
                    theme: root.composition ? root.composition.topbarTheme : null
                    open: root.weatherTopOpen
                    onCloseRequested: root.closeWeatherTop()
                    onSettingsRequested: root.openUnifiedSettings()
                    onPointerInsideChanged: inside => root.setWeatherTopPanelHovering(inside)
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
                readonly property int railOverlap: 0
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
                readonly property bool popupCutActive: root.quickPopupVisible && root.sideQuickPopupPanelVisible && root.quickPopupSurfaceReveal > 0.12 && popupCutBottom > popupCutTop && popupCutRight > popupCutLeft
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
                    ? (root.barOnRight ? barEdgeX - waveWidth : barEdgeX)
                    : (root.barOnRight ? frameEdgeX - waveWidth : barEdgeX)
                y: standalone ? root.sidebarVerticalMargin : root.desktopFrameY(parent.height)
                width: root.sideBarLayoutEnabled && root.sideVisualizerMounted ? railWidth : 0
                height: root.sideBarLayoutEnabled && root.sideVisualizerMounted
                    ? (standalone ? Math.max(0, parent.height - root.sidebarVerticalMargin * 2) : Math.max(0, root.desktopFrameHeight(parent.height)))
                    : 0
                visible: root.sideBarLayoutEnabled && root.sideVisualizerMounted
                opacity: root.sideVisualizerReveal * root.layoutSwitchOpacity
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
                onCenterXChanged: requestWaveformPaint(true)
                onWaveDirectionChanged: requestWaveformPaint(true)
                onStandaloneChanged: requestWaveformPaint(true)
                onLocalFrameEdgeXChanged: requestWaveformPaint(true)
                onLocalBarEdgeXChanged: requestWaveformPaint(true)

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
                        const capReach = sideVisualizerRail.standalone ? Math.min(16, width * 0.40) : root.sideVisualizerCapReach
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

                        const waveAlpha = peak >= 0.045 ? Math.min(0.22, 0.08 + peak * 0.24) : 0.055
                        ctx.strokeStyle = veloraTheme.alpha(root.sidebarPanelBorderColor(), veloraTheme.themeId === "pywal16" ? waveAlpha : Math.min(0.42, waveAlpha + 0.08))
                        ctx.lineWidth = 0.75
                        ctx.beginPath()
                        moldedFramePath(ctx, wave)
                        ctx.stroke()

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
                    target: root

                    function onBarOnRightChanged() {
                        waveformPaintTimer.stop()
                        waveformCanvas.requestPaint()
                        sideVisualizerRelayoutTimer.restart()
                    }
                }

                Timer {
                    id: sideVisualizerRelayoutTimer

                    interval: 1
                    repeat: false
                    onTriggered: sideVisualizerRail.requestWaveformPaint(true)
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
                    function onSidebarOpacityChanged() { if (root.sideVisualizerMounted) sideVisualizerRail.requestWaveformPaint(true) }
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
            // Keep only this zero-sized marker so the shared drawers mask can
            // retain the same shape without instantiating a second carousel.

            Item {
                id: inlineNotificationToastInputMask

                x: inlineNotificationToastStage.x
                y: inlineNotificationToastStage.y
                width: inlineNotificationToastStage.visible ? inlineNotificationToastStage.width : 0
                height: inlineNotificationToastStage.visible ? inlineNotificationToastStage.height : 0
                z: 139
            }

            Item {
                id: inlineNotificationToastStage

                readonly property bool mounted: root.notificationToastMounted || opacity > 0.001
                readonly property bool attachedToWeather: root.weatherTopWindowOpen && inlineWeatherTopFrame.mounted
                readonly property int panelWidth: Math.max(parent.width, panel.modelData.width)
                readonly property int safeWidth: Math.max(320, panelWidth - 96)
                readonly property int bubbleRadius: attachedToWeather ? panel.weatherTopCornerRadius : Math.min(17, height / 2)
                readonly property int weatherToastGap: 12
                readonly property int openY: attachedToWeather
                    ? Math.min(Math.round(parent.height - root.desktopFrameMargin - height), Math.round(inlineWeatherTopFrame.y + inlineWeatherTopFrame.height + weatherToastGap))
                    : root.desktopFrameMargin

                width: attachedToWeather ? inlineWeatherTopFrame.width : Math.round(Math.min(safeWidth, Math.max(330, panelWidth * 0.18)))
                readonly property real headerHeight: attachedToWeather ? 76 : 48
                height: headerHeight + (inlineNotificationPreview.visible ? inlineNotificationPreview.height + 12 : 0)
                x: attachedToWeather ? inlineWeatherTopFrame.x : Math.round((panelWidth - width) / 2)
                y: root.notificationToastVisible || attachedToWeather ? openY : -height - 18
                z: 140
                visible: mounted && !root.notificationsInTopbar
                opacity: root.notificationToastVisible ? 1 : 0
                scale: 1
                transformOrigin: Item.Top

                onYChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onOpacityChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onWidthChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()
                onHeightChanged: if (root.frameVisualsMounted) unifiedFrameCanvas.requestPaint()

                Behavior on y {
                    enabled: veloraTheme.motionEnabled && !inlineNotificationToastStage.attachedToWeather
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

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }
                    height: 1
                    visible: inlineNotificationToastStage.attachedToWeather
                    color: root.desktopFrameBorderColor()
                    opacity: 0.52
                }

                Item {
                    id: inlineNotificationToastIcon

                    width: 32
                    height: 32
                    x: inlineNotificationToastStage.attachedToWeather ? 24 : 10
                    y: Math.round((inlineNotificationToastStage.headerHeight - height) / 2)

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
                    y: Math.round((inlineNotificationToastStage.headerHeight - height) / 2) - 1
                    width: parent.width - x - (inlineNotificationToastStage.attachedToWeather ? 28 : 16)
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

                NotificationImage {
                    id: inlineNotificationPreview
                    x: 12; y: inlineNotificationToastStage.headerHeight
                    width: parent.width - 24
                    source: root.notificationToastImage
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => root.clickNotificationToast(root.notificationToastId, mouse.button)
                }
            }

            VeloraBarV2 {
                id: barRoot
                monitorName: panel.modelData.name
                bubbleTint: root.composition ? root.composition.unifiedBarBubbleTint : unifiedAccent
                bubbleColorExact: !!root.composition && root.composition.manualBarBubbleColor
                itemBubblesEnabled: !!root.composition && root.composition.barItemBubblesEnabled
                itemBubblesSolid: !!root.composition && root.composition.barItemBubblesSolid
                itemBubblesLiquid: !!root.composition && root.composition.barItemBubblesLiquid
                desktopSourceReveal: root.infiniteDesktopSourceReveal

                theme: veloraTheme
                mediaService: root.composition ? root.composition.mediaService : null
                mediaEnabled: root.sidebarMediaEnabled
                audioVisualizer: root.composition ? root.composition.audioVisualizer : null
                toolsService: root.composition ? root.composition.topbarTools : null
                fanPlusService: root.composition ? root.composition.fanPlusService : null
                bluetoothMenuOpen: bluetoothPopover.opened
                notificationMenuOpen: notificationsPopover.opened
                wifiMenuOpen: wifiPopover.opened
                mediaMenuOpen: edgePopover.opened && edgePopover.mediaPanelActive
                onMediaMenuRequested: centerY => {
                    if (!edgePopover.enabled) return
                    if (edgePopover.opened && edgePopover.mediaPanelActive) edgePopover.close()
                    else { edgePopover.open(); edgePopover.showPage("media") }
                }
                onBluetoothMenuRequested: centerY => {
                    bluetoothPopover.anchorY = barRoot.y + centerY
                    bluetoothPopover.toggle()
                }
                onBluetoothHoverChanged: (inside, centerY) => {
                    bluetoothPopover.anchorY = barRoot.y + centerY
                    bluetoothPopover.triggerHovered = inside
                }
                onNotificationMenuRequested: centerY => {
                    notificationsPopover.anchorY = barRoot.y + centerY
                    notificationsPopover.toggle()
                }
                onNotificationHoverChanged: (inside, centerY) => {
                    notificationsPopover.anchorY = barRoot.y + centerY
                    notificationsPopover.triggerHovered = inside
                }
                onWifiMenuRequested: centerY => {
                    wifiPopover.anchorY = barRoot.y + centerY
                    wifiPopover.toggle()
                }
                onWifiHoverChanged: (inside, centerY) => {
                    wifiPopover.anchorY = barRoot.y + centerY
                    wifiPopover.triggerHovered = inside
                }
                caffeineMenuOpen: coffeePopover.opened
                onCaffeineMenuRequested: centerY => {
                    coffeePopover.anchorY = barRoot.y + centerY
                    coffeePopover.toggle()
                }
                onCaffeineHoverChanged: (inside, centerY) => {
                    coffeePopover.anchorY = barRoot.y + centerY
                    coffeePopover.triggerHovered = inside
                }
                notesMenuOpen: notesPopover.opened
                onNotesMenuRequested: centerY => {
                    notesPopover.anchorY = barRoot.y + centerY
                    notesPopover.toggle()
                }
                unifiedSurface: root.composition ? root.composition.topbarTheme.wallpaperSurfaceTone : veloraTheme.surfaceSidebar
                unifiedPaletteEnabled: Boolean(root.composition)
                unifiedTextPrimary: root.composition
                    ? root.composition.unifiedBarTextPrimary : "white"
                unifiedTextSecondary: root.composition
                    ? root.composition.unifiedBarTextSecondary : "#c4cede"
                unifiedAccent: root.composition
                    ? root.composition.unifiedBarAccent : "#8db8ff"
                unifiedAccentAlt: root.composition
                    ? root.composition.unifiedBarAccentAlt : "#b99cff"
                z: 10
                visible: root.sideBarLayoutEnabled
                opacity: root.layoutSwitchOpacity
                width: root.sideBarLayoutEnabled ? root.sidebarVisualWidth : 0
                x: root.barX(parent.width)
                focusMode: root.focusMode
                focusIndex: root.focusIndex
                focusTarget: root.focusTarget
                visualizerActive: (root.sideVisualizerMounted || root.screenVisualizerMounted)
                    && root.audioVisualizerProcessWanted
                cavaForceActive: false
                shellDrawsPanelSurface: root.sideBarLayoutEnabled
                reducedIconMotion: !!root.composition && root.composition.motionTokens.reduced
                volumeControlOpen: root.volumeControlOpen
                brightnessControlOpen: root.brightnessControlOpen
                batteryControlOpen: root.batteryControlOpen
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
                    root.openUnifiedSettings()
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

            VeloraRailControls {
                id: railControls
                externalBrightnessActive: root.infiniteDesktopCanvasEnabled && root.composition.activeTopbarType === "brightness"
                motion: root.composition.motionTokens
                handoffSource: panel.activeRailSystemPopover
                onLevelOpening: popover => panel.activeRailSystemPopover = popover
                onLevelClosed: type => { if (root.activeRailControl === type) root.activeRailControl = "" }
                anchors.fill: parent
                z: 11
                theme: veloraTheme
                accent: barRoot.pink
                rightSide: root.barOnRight
                railWidth: root.sidebarVisualWidth
                volumeCenter: barRoot.y + barRoot.volumeControlCenter
                brightnessCenter: barRoot.y + barRoot.brightnessControlCenter
                batteryCenter: barRoot.y + barRoot.batteryControlCenter
                volumeOpen: root.volumeControlOpen
                brightnessOpen: root.brightnessControlOpen
                refreshSerial: root.railFeedbackSerial
                batteryOpen: root.batteryControlOpen
                extraPanel: wifiPopover.opened ? wifiPopover.outline : notificationsPopover.opened ? notificationsPopover.outline : bluetoothPopover.opened ? bluetoothPopover.outline : notesPopover.opened ? notesPopover.outline : coffeePopover.opened ? coffeePopover.outline : wifiPopover.mounted ? wifiPopover.outline : notificationsPopover.mounted ? notificationsPopover.outline : bluetoothPopover.mounted ? bluetoothPopover.outline : notesPopover.mounted ? notesPopover.outline : coffeePopover.outline
                onPanelHoverChanged: hovered => {
                    root.railControlPanelHovered = hovered
                    if (hovered) railControlCloseTimer.stop()
                    else if (!root.railControlHoverTarget) railControlCloseTimer.restart()
                }
                onShapeChanged: {
                    Qt.callLater(unifiedFrameCanvas.requestPaint)
                    Qt.callLater(panel.syncUnifiedBarNativeShape)
                }
            }

            Item {
                id: edgeTrigger
                x: parent.width - width; y: edgePopover.anchorY - height / 2
                width: root.sideBarLayoutEnabled && !root.barOnRight
                    && (root.infiniteDesktopSourceReveal > .99 || root.infiniteDesktopTargetReveal > .99)
                    ? root.oppositeFrameWidth + 4 : 0
                height: 200
                HoverHandler { id: edgeHover; blocking: false }
            }
            VeloraEdgePopover {
                id: edgePopover
                onMediaPanelActiveChanged: root.setEdgeMediaVisible(panel.modelData.name, mediaPanelActive, edgePopover)
                onFullHeightPanelActiveChanged: root.setEdgeFullHeightVisible(panel.modelData.name, fullHeightPanelActive)
                onSpectrumActiveChanged: root.setEdgeSpectrumVisible(panel.modelData.name, spectrumActive)
                Component.onDestruction: {
                    root.setEdgeMediaVisible(panel.modelData.name, false)
                    root.setEdgeFullHeightVisible(panel.modelData.name, false)
                    root.setEdgeSpectrumVisible(panel.modelData.name, false)
                    root.setEdgeDockProgress(panel.modelData.name, 0)
                }
                anchors.fill: parent
                z: 12
                motion: root.composition.motionTokens
                enabled: root.sideBarLayoutEnabled && !root.barOnRight && !!root.composition
                theme: root.composition ? root.composition.topbarTheme : null
                media: root.composition ? root.composition.mediaService : null
                analyzer: root.composition ? root.composition.audioVisualizer : null
                beatEnabled: Platform.NativeBlur.supports("lyrics-beat-palette") && !root.shellSuppressedByFullscreen
                onPercussionBeat: (strength, colors) => {
                    // One origin inside the Lyrics body, in full-monitor
                    // coordinates, shared by all native material passes.
                    const x = (panel.width - edgePopover.railWidth - edgePopover.bodyWidth * .5) / panel.width
                    const y = (40 + edgePopover.bodyY + edgePopover.bodyHeight * .44) / (panel.height + 40)
                    Platform.NativeBlur.dispatch("velora-blur:lyrics-beat " + panel.modelData.name + " "
                        + [x, y, strength].concat(colors).map(v => Number(v).toFixed(6)).join(" "))
                }
                onReducedMotionChanged: if (reducedMotion)
                    Platform.NativeBlur.dispatch("velora-blur:lyrics-beat " + panel.modelData.name + " reset")
                visualizerDockEnabled: !!root.composition && root.composition.desktopVisualizerEnabled
                whatsapp: root.composition ? root.composition.whatsappService : null
                whatsappWindow: whatsappWindowHost
                onWhatsappWindowRequested: whatsappWindowHost.open(panel.modelData.name, edgePopover)
                railWidth: root.oppositeFrameWidth
                // The local origin starts below the reserved topbar.
                anchorY: height - panel.modelData.height / 2
                triggerHovered: edgeHover.hovered
                onOpening: {
                    infiniteControlMenu.close(); coffeePopover.close(); notesPopover.close(); bluetoothPopover.close()
                    notificationsPopover.close(); wifiPopover.close()
                    root.activeRailControl = ""
                    root.closeQuickPopup()
                    if (root.composition) root.composition.closeTopbarTool()
                }
                onShapeChanged: {
                    Qt.callLater(unifiedFrameCanvas.requestPaint)
                    Qt.callLater(panel.syncUnifiedBarNativeShape)
                }
                onContourSamplesChanged: {
                    Qt.callLater(unifiedFrameCanvas.requestPaint)
                    Qt.callLater(panel.syncUnifiedBarNativeShape)
                }
                onSidebarWaveScaleChanged: {
                    root.setEdgeDockProgress(panel.modelData.name, dockProgress)
                    Qt.callLater(unifiedFrameCanvas.requestPaint)
                    Qt.callLater(panel.syncUnifiedBarNativeShape)
                }
                onSidebarSamplesChanged: {
                    Qt.callLater(unifiedFrameCanvas.requestPaint)
                    Qt.callLater(panel.syncUnifiedBarNativeShape)
                }
            }

            VeloraRailCoffee {
                id: coffeePopover
                motion: root.composition.motionTokens
                anchors.fill: parent
                z: 12
                enabled: root.sideBarLayoutEnabled && !!root.composition
                theme: root.composition ? root.composition.topbarTheme : null
                system: root.composition ? root.composition.topbarTools : null
                rightSide: root.barOnRight
                railWidth: root.sidebarVisualWidth
                handoffSource: panel.activeRailSystemPopover
                onOpening: { panel.activeRailSystemPopover = coffeePopover; bluetoothPopover.close(); notesPopover.close(); notificationsPopover.close(); wifiPopover.close(); root.activeRailControl = ""; root.closeQuickPopup(); if (root.composition) root.composition.closeTopbarTool() }
                onShapeChanged: Qt.callLater(unifiedFrameCanvas.requestPaint)
            }
            VeloraRailNotes {
                id: notesPopover
                motion: root.composition.motionTokens
                anchors.fill: parent
                z: 12
                enabled: root.sideBarLayoutEnabled && !!root.composition
                theme: root.composition ? root.composition.topbarTheme : null
                system: root.composition ? root.composition.topbarTools : null
                rightSide: root.barOnRight
                railWidth: root.sidebarVisualWidth
                handoffSource: panel.activeRailSystemPopover
                onOpening: { panel.activeRailSystemPopover = notesPopover; bluetoothPopover.close(); coffeePopover.close(); notificationsPopover.close(); wifiPopover.close(); root.activeRailControl = ""; root.closeQuickPopup(); if (root.composition) root.composition.closeTopbarTool() }
                onShapeChanged: Qt.callLater(unifiedFrameCanvas.requestPaint)
            }
            VeloraRailBluetooth {
                id: bluetoothPopover
                motion: root.composition.motionTokens
                anchors.fill: parent
                z: 12
                enabled: root.sideBarLayoutEnabled && !!root.composition
                theme: root.composition ? root.composition.topbarTheme : null
                rightSide: root.barOnRight
                railWidth: root.sidebarVisualWidth
                ink: barRoot.ink
                accent: barRoot.pink
                uiFont: barRoot.uiFont
                handoffSource: panel.activeRailSystemPopover
                onOpening: { panel.activeRailSystemPopover = bluetoothPopover; coffeePopover.close(); notesPopover.close(); notificationsPopover.close(); wifiPopover.close(); root.activeRailControl = ""; root.closeQuickPopup(); if (root.composition) root.composition.closeTopbarTool() }
                onShapeChanged: Qt.callLater(unifiedFrameCanvas.requestPaint)
            }
            VeloraRailNotifications {
                id: notificationsPopover
                motion: root.composition.motionTokens
                anchors.fill: parent
                z: 12
                enabled: root.sideBarLayoutEnabled && !!root.composition
                theme: root.composition ? root.composition.topbarTheme : null
                system: root.composition ? root.composition.topbarTools : null
                rightSide: root.barOnRight
                railWidth: root.sidebarVisualWidth
                notificationsModel: notificationHistoryModel
                ink: barRoot.ink
                accent: barRoot.pink
                uiFont: barRoot.uiFont
                handoffSource: panel.activeRailSystemPopover
                onDismissRequested: id => root.dismissNotificationHistory(id)
                onActivateRequested: id => { if (root.activateNotificationHistory(id)) notificationsPopover.close() }
                onClearRequested: root.clearTrackedNotificationHistory()
                onOpening: { panel.activeRailSystemPopover = notificationsPopover; coffeePopover.close(); notesPopover.close(); bluetoothPopover.close(); wifiPopover.close(); root.activeRailControl = ""; root.closeQuickPopup() }
                onShapeChanged: Qt.callLater(unifiedFrameCanvas.requestPaint)
            }
            VeloraRailWifi {
                id: wifiPopover
                motion: root.composition.motionTokens
                onOpenedChanged: if (root.composition) root.composition.sidebarNetworkActive = opened
                anchors.fill: parent
                z: 12
                enabled: root.sideBarLayoutEnabled && !!root.composition
                theme: root.composition ? root.composition.topbarTheme : null
                system: root.composition ? root.composition.topbarTools : null
                rightSide: root.barOnRight
                railWidth: root.sidebarVisualWidth
                ink: barRoot.ink
                uiFont: barRoot.uiFont
                handoffSource: panel.activeRailSystemPopover
                onOpening: { panel.activeRailSystemPopover = wifiPopover; coffeePopover.close(); notesPopover.close(); bluetoothPopover.close(); notificationsPopover.close(); root.activeRailControl = ""; root.closeQuickPopup() }
                onShapeChanged: Qt.callLater(unifiedFrameCanvas.requestPaint)
            }
            Connections {
                target: whatsappWindowHost
                function onOpening() {
                    if (edgePopover.whatsappPage || edgePopover.pendingPage === "whatsapp") {
                        edgePopover.blocked = edgePopover.triggerHovered
                        edgePopover.close()
                    }
                }
                function onDockRequested(monitor) {
                    const destination = Quickshell.screens.some(screen => screen.name === monitor)
                        ? monitor : Quickshell.screens[0]?.name
                    if (panel.modelData.name !== destination) return
                    edgePopover.open(); edgePopover.showPage("whatsapp")
                }
            }
            Connections {
                target: root
                function onRailMediaRequested() {
                    if (!edgePopover.enabled) return
                    if (edgePopover.opened && edgePopover.mediaPanelActive) edgePopover.close()
                    else { edgePopover.open(); edgePopover.showPage("media") }
                }
                function onRailWhatsAppRequested() {
                    if (whatsappWindowHost.active) { whatsappWindowHost.raise(); return }
                    if (!edgePopover.enabled) return
                    if (edgePopover.opened && edgePopover.whatsappPage) edgePopover.close()
                    else { edgePopover.open(); edgePopover.showPage("whatsapp") }
                }
            }
            MouseArea {
                id: railToolOutsideInput
                z: 9
                width: panel.width
                height: infiniteControlMenu.mounted || railControls.mounted || (edgePopover.mounted && !edgePopover.keepOpenOutside) || coffeePopover.mounted || notesPopover.mounted || bluetoothPopover.mounted || notificationsPopover.mounted || wifiPopover.mounted ? panel.height : 0
                acceptedButtons: Qt.AllButtons
                onPressed: { infiniteControlMenu.close(); root.activeRailControl = ""; if (!edgePopover.keepOpenOutside) edgePopover.close(); coffeePopover.close(); notesPopover.close(); bluetoothPopover.close(); notificationsPopover.close(); wifiPopover.close() }
            }
            Connections {
                target: root
                function onActiveRailControlChanged() {
                    if (!root.activeRailControl) return
                    if (!edgePopover.keepOpenForControl(root.activeRailControl)) edgePopover.close()
                    coffeePopover.close(); notesPopover.close(); bluetoothPopover.close()
                    notificationsPopover.close(); wifiPopover.close()
                }
                function onInfiniteDesktopFrameFoldProgressChanged() { unifiedShapePublisher.dirty = true }
                function onInfiniteDesktopCanvasEnabledChanged() {
                    infiniteControlMenu.closeInstant(); edgePopover.close(); coffeePopover.closeInstant(); notesPopover.closeInstant()
                    bluetoothPopover.closeInstant(); notificationsPopover.closeInstant(); wifiPopover.closeInstant()
                }
                function onQuickPopupTypeChanged() {
                    if (!root.quickPopupType) return
                    if (!edgePopover.keepOpenForControl(root.quickPopupType)) edgePopover.close()
                    coffeePopover.close(); notesPopover.close(); bluetoothPopover.close()
                    notificationsPopover.close(); wifiPopover.close()
                }
            }


        }
    }


}
