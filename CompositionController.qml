import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "core" as Core
import "platform" as Platform
import "services" as Services
import "features/topbar" as TopBarFeature
import "surfaces" as Surfaces

Scope {
    id: root

    required property var shell
    readonly property bool lockOccluding: preview.occluding
    readonly property bool referenceAppearance: config.referenceAppearance
    readonly property bool connectedNotifications: config.topbarEnabled && config.referenceAppearance
    readonly property var clockTimerService: topbarTimer
    readonly property real barHeight: 40
    readonly property bool reducedMotion: config.reducedMotion
    readonly property var motionTokens: motion
    readonly property string barMaterial: config.barMaterial
    readonly property bool barBlurEnabled: config.barBlurEnabled
    readonly property bool infiniteDesktopTopbarEnabled: config.infiniteDesktopTopbarEnabled
    readonly property bool wallpaperSelectorGlassEnabled: config.wallpaperSelectorGlassEnabled
    function setWallpaperSelectorGlass(enabled) { config.setValue("desktop.wallpaperSelectorGlassEnabled", enabled) }
    readonly property real barWaveStrength: config.barWaveStrength
    readonly property color unifiedBarSurface: theme.barSurface
    readonly property color unifiedBarBorder: theme.borderSubtle
    readonly property color unifiedBarTextPrimary: theme.textPrimary
    readonly property color unifiedBarTextSecondary: theme.textSecondary
    readonly property color unifiedBarAccent: theme.accent
    readonly property color unifiedBarAccentAlt: theme.accentAlt
    readonly property var forecastService: weather
    readonly property var mediaService: media
    readonly property var whatsappService: whatsapp
    readonly property var audioVisualizer: visualizer
    readonly property bool desktopVisualizerEnabled: config.desktopVisualizerEnabled
    readonly property bool desktopVisualizerSuppressed: !!root.shell && root.shell.edgeMediaOpen
    readonly property real visualizerDockProgress: root.shell ? root.shell.visualizerDockProgress : 0
    readonly property bool desktopVisualizerVisible: config.desktopVisualizerEnabled
        && (!desktopVisualizerSuppressed || visualizerDockProgress < .999)
        && visualizer.running && !preview.shown
        && !(editorController.shown && editorController.mode === "editing")
    readonly property bool nativeBarMaterial: Platform.NativeBlur.supportsBarMaterial(visualizer)
    readonly property string nativeBarMaterialDiagnostic: Platform.NativeBlur.supports("desktop-bar-material") && !nativeBarMaterial
        ? "Visualizador sem materialFrame; material compartilhado usa fallback. Reconstrua e reinicie o Velora para carregar o módulo atualizado." : ""
    onNativeBarMaterialDiagnosticChanged: {
        if (nativeBarMaterialDiagnostic) console.warn("Velora blur: " + nativeBarMaterialDiagnostic)
    }
    readonly property var topbarTools: topbarSystem
    readonly property var networkStatus: systemStatus
    property bool sidebarNetworkActive: false
    readonly property var fanPlusService: fanPlus
    readonly property var topbarTheme: theme
    readonly property string activeTopbarType: topbarController.activeType
    function closeTopbarTool() { topbarController.close() }
    function toggleTopbarWeather() { return topbarController.openByType("weather", compositor.focusedMonitorName) }
    function showTopbarWeather() {
        const entry = topbarController.items.find(entry => entry.type === "weather"
            && entry.host.screen.name === compositor.focusedMonitorName)
        if (!entry) return false
        topbarController.show("weather", entry.item, entry.host, false)
        return true
    }
    function toggleTopbarNotifications() {
        return topbarController.openByType("notifications", compositor.focusedMonitorName)
    }
    // No QML waves are painted on the bar. The compositor plugin moves only
    // the refracted wallpaper underneath this otherwise quiet surface.
    readonly property real unifiedBarWavePhase: 0
    function openEditor(space) { editorController.show(space) }
    function openSystemSettings() {
        editorController.show("desktop")
        editorController.setSettingsPage("system")
    }
    function showLock() { return preview.show() }
    function hideLock() { return preview.hide() }
    function toggleLock() {
        if (editorController.mounted)
            return editorController.hide()
        return preview.toggle()
    }

    readonly property string version: "velora-shell-0.1"
    property int opticsGeneration: 0
    Connections {
        target: Platform.NativeBlur
        function onRevisionChanged() {
            root.opticsGeneration += 1
            root.syncNativeAppearance()
        }
    }

    function syncNativeAppearance() {
        syncBarBlur()
        syncTerminalLiquid()
        Platform.NativeBlur.dispatch("velora-blur:lock-layout "
            + (theme.editorial ? "editorial" : "panel"))
        Platform.NativeBlur.dispatch("velora-blur:appearance commit "
            + Number(config.blurStrength).toFixed(4) + " "
            + Number(config.appearanceContrast).toFixed(4) + " "
            + Number(config.reflectionStrength).toFixed(4))
    }

    function syncTerminalLiquid() {
        if (!config.ready) return
        syncKittyBarMaterial()
        Platform.NativeBlur.dispatch("velora-blur:terminal-glass-control "
            + (config.terminalLiquidEnabled ? "1 " : "0 ") + Number(config.terminalRefraction).toFixed(4))
    }
    function syncKittyBarMaterial() {
        if (!config.ready) return
        Platform.NativeBlur.dispatch("velora-blur:terminal-bar-match " + (config.barMatchKittyMaterial ? "1" : "0"))
        Platform.NativeBlur.dispatch("velora-blur:terminal-follow-bar " + (config.terminalFollowBar ? "1" : "0"))
        Platform.NativeBlur.dispatch("velora-blur:terminal-brightness " + Number(config.terminalBarBrightness).toFixed(4))
    }
    function controlTerminalLiquid(action, value) {
        if (!config.ready) return JSON.stringify({error: "As configurações ainda estão carregando."})
        if (action === "on" || action === "off" || action === "toggle")
            config.setValue("appearance.terminalLiquidEnabled", action === "toggle"
                ? !config.terminalLiquidEnabled : action === "on")
        else if (action === "strength") {
            if (!Number.isFinite(value) || value < 0 || value > 3)
                return JSON.stringify({error: "A intensidade deve estar entre 0 e 3."})
            config.setValue("appearance.terminalRefraction", value)
        } else if (action !== "status")
            return JSON.stringify({error: "Use on, off, toggle, strength ou status."})
        return JSON.stringify({enabled: config.terminalLiquidEnabled, strength: config.terminalRefraction,
            available: Platform.NativeBlur.supports("terminal-glass-control")})
    }

    function syncWallpaperEffects() {
        Platform.NativeBlur.dispatch("velora-blur:wallpaper " + Number(
            config.wallpaperBlurEnabled ? config.wallpaperBlurStrength : 0).toFixed(4))
    }
    function syncLiquidStyle() {
        Platform.NativeBlur.dispatch("velora-blur:liquid-style " + config.liquidGlassStyle + " " + (theme.light ? "1" : "0"))
    }
    function syncBarRefraction() {
        if (!config.ready) return
        Platform.NativeBlur.dispatch("velora-blur:bar-refraction " + Number(config.barRefractionStrength).toFixed(4))
    }
    function syncBarBrightness() {
        if (!config.ready) return
        Platform.NativeBlur.dispatch("velora-blur:bar-brightness " + Number(config.barBrightness).toFixed(4))
    }
    function syncBarBlur() {
        syncLiquidStyle()
        syncBarRefraction()
        syncBarBrightness()
        syncWallpaperEffects()
        Platform.NativeBlur.dispatch("velora-blur:bar-blur " + (config.barBlurEnabled ? "1" : "0"))
        Platform.NativeBlur.dispatch("velora-blur:widget-blur " + (config.widgetBlurEnabled ? "1" : "0"))
    }

    Core.ConfigStore { id: config }
    Core.PywalPalette {
        id: pywalPalette
        config: config
        wallpaperService: wallpaper
    }
    Core.Theme {
        id: theme
        config: config
        palette: pywalPalette
        kittyMaterial: terminalMaterial
    }
    Core.KittyMaterial { id: terminalMaterial; config: config }
    Core.KittyBarSync {
        config: config; theme: theme
        available: Platform.NativeBlur.supports("terminal-follow-bar")
    }
    Core.Motion { id: motion; config: config }
    Core.PreviewController { id: preview; motion: motion }
    Core.WidgetTransitionController { id: widgetTransition; motion: motion }
    Core.CausticsClock {
        id: causticsClock
        active: preview.shown && config.waterCausticsEnabled
            && config.waterCausticsLines && config.waterCausticsModules
        reduced: motion.reduced
    }
    Platform.CompositorService { id: compositor }
    Services.ClockService { id: clock; localeName: config.localeName }
    TopBarFeature.TopBarController { id: topbarController; motion: motion }
    Services.TopBarTimerService {
        id: topbarTimer
        reducedMotion: config.reducedMotion
        onCloseNotificationRequested: id => { if (root.shell) root.shell.dismissNotificationHistory(id) }
    }
    Services.FanPlusService { id: fanPlus }
    Connections {
        target: topbarController
        function onActiveTypeChanged() {
            if (topbarController.activeType === "battery") fanPlus.refresh()
        }
    }
    Services.ExecutionStatusService { id: executionStatus }
    Services.TopBarSystemService {
        id: topbarSystem
        enabled: config.topbarEnabled && !compositor.activeToplevelFullscreen && !root.lockOccluding
        reducedMotion: config.reducedMotion
        status: systemStatus
        activeType: root.sidebarNetworkActive ? "wifi" : topbarController.activeType
        palette: pywalPalette
    }
    Services.CalendarService {
        id: calendarService
        config: config
        active: config.widgetVisibleAtProgress("calendar", widgetTransition.progress)
            || editorController.mounted
    }
    Services.MediaService {
        id: media
        active: preview.mounted || config.topbarEnabled
            || config.widgetVisibleAtProgress("media", widgetTransition.progress)
    }
    Services.WhatsAppService { id: whatsapp }
    Services.WeatherService {
        id: weather
        active: config.topbarEnabled || config.widgetVisibleAtProgress(
            "weather", widgetTransition.progress)
            || (root.shell && root.shell.weatherTopOpen
                && root.shell.weatherTopMode !== "search")
    }
    Services.VisualizerDemand {
        id: visualizerDemand
        desktopEnabled: config.desktopVisualizerEnabled && (!root.desktopVisualizerSuppressed || root.visualizerDockProgress < .999)
        editingDesktop: editorController.shown && editorController.mode === "editing"
        lockOccluding: preview.occluding
        railVisible: !!root.shell && root.shell.sideBarLayoutEnabled && root.shell.sidebarMediaEnabled
        edgeMediaVisible: !!root.shell && root.shell.edgeSpectrumOpen
        mediaPlaying: media.playing
    }
    Services.VisualizerService { id: visualizer; active: visualizerDemand.active }
    Services.WallpaperService { id: wallpaper }
    Services.CompositionProfileService {
        id: compositionProfiles
        config: config
        wallpaperService: wallpaper
    }
    Services.WallpaperCompositionService {
        id: wallpaperCompositions
        config: config
        wallpaperService: wallpaper
        profileService: compositionProfiles
    }
    Services.SceneEditorService { id: sceneEditor; config: config }
    Core.SettingsController {
        id: editorController
        shell: root.shell
        motion: motion
        preview: preview
        config: config
        profileService: compositionProfiles
        editor: sceneEditor
    }
    Services.SystemStatusService {
        id: systemStatus
        performanceActive: config.widgetVisibleAtProgress(
            "system", widgetTransition.progress)
            || editorController.mounted
    }
    Services.ActionService {
        id: actions
        shell: root.shell
        editorController: editorController
        controller: preview
        config: config
        settings: editorController
    }

    Surfaces.TopBarHost {
        edgeMediaPanels: root.shell ? root.shell.edgeMediaPanels : ({})
        edgeFullHeightPanels: root.shell ? root.shell.edgeFullHeightPanels : ({})
        nativeBarMaterial: root.nativeBarMaterial
        notificationSource: root.shell
        executionStatus: executionStatus
        controller: topbarController
        timerService: topbarTimer
        system: topbarSystem
        fanPlus: fanPlus
        calendar: calendarService
        barOnRight: root.shell ? root.shell.barOnRight : false
        lockOccluding: preview.occluding
        barWavePhase: root.unifiedBarWavePhase
        opticsGeneration: root.opticsGeneration
        compositor: compositor
        config: config
        theme: theme
        motion: motion
        clock: clock
        media: media
        weather: weather
        status: systemStatus
        actions: actions
        settings: editorController
        editorController: editorController
    }

    Surfaces.LockPreviewHost {
        opticsGeneration: root.opticsGeneration
        controller: preview
        compositor: compositor
        config: config
        theme: theme
        motion: motion
        clock: clock
        calendarService: calendarService
        media: media
        weather: weather
        visualizer: visualizer
        profileService: compositionProfiles
        editor: sceneEditor
        transition: widgetTransition
        causticsClock: causticsClock
        settingsVisible: editorController.mounted
    }

    Surfaces.WallpaperEffectsHost {
        compositor: compositor
        config: config
        wallpaper: wallpaper
    }

    Surfaces.SharedWidgetsHost {
        visualizerSuppressed: root.desktopVisualizerSuppressed
        visualizerDockProgress: root.visualizerDockProgress
        nativeBarMaterial: root.nativeBarMaterial
        opticsGeneration: root.opticsGeneration
        barOnRight: root.shell ? root.shell.barOnRight : false
        visualizerRailInset: root.shell && root.shell.sideBarLayoutEnabled
            ? root.shell.sidebarVisualWidth : 0
        visualizerCornerRadius: root.shell && root.shell.sideBarLayoutEnabled
            ? root.shell.sidebarCornerRadius : 0
        visualizerBottomInset: root.shell && root.shell.sideBarLayoutEnabled
            ? root.shell.bottomBarHeight : 0
        compositor: compositor
        preview: preview
        settings: editorController
        config: config
        theme: theme
        motion: motion
        clock: clock
        calendarService: calendarService
        media: media
        weather: weather
        visualizer: visualizer
        status: systemStatus
        transition: widgetTransition
        editor: sceneEditor
        profileService: compositionProfiles
        causticsClock: causticsClock
    }

    Surfaces.EditorHost {
        opticsGeneration: root.opticsGeneration
        controller: editorController
        compositor: compositor
        config: config
        theme: theme
        motion: motion
        profileService: compositionProfiles
        wallpaperStore: wallpaperCompositions
        editor: sceneEditor
    }

    Timer {
        id: nativeAppearanceDebounce
        interval: 32; repeat: false
        onTriggered: root.syncNativeAppearance()
    }
    function openMonitorSettings() {
        const anchors = topbarController.items.filter(entry => entry.host.screen.name === compositor.focusedMonitorName)
        const entry = anchors.find(entry => entry.type === "monitor")
            || anchors.find(entry => entry.type === "controls") || anchors.find(entry => entry.type === "clock") || anchors[0]
        if (!entry) return false
        topbarController.show("monitor", entry.item, entry.host, false)
        return true
    }

    Connections {
        target: compositionProfiles
        function onProfileApplied() {
            sceneEditor.resetHistory()
            root.syncNativeAppearance()
        }
    }

    Connections {
        target: config
        function onLiquidGlassStyleChanged() { root.syncLiquidStyle() }
        function onBarRefractionStrengthChanged() { root.syncBarRefraction() }
        function onBarBrightnessChanged() { root.syncBarBrightness() }
        function onTerminalLiquidEnabledChanged() { root.syncTerminalLiquid() }
        function onTerminalFollowBarChanged() { root.syncTerminalLiquid() }
        function onTerminalBarBrightnessChanged() { root.syncTerminalLiquid() }
        function onTerminalRefractionChanged() { root.syncTerminalLiquid() }
        function onBarMatchKittyMaterialChanged() { root.syncBarBlur(); root.syncKittyBarMaterial() }
        function onColorSchemeChanged() { root.syncLiquidStyle() }
        function onWallpaperBlurEnabledChanged() { root.syncWallpaperEffects() }
        function onWallpaperBlurStrengthChanged() { root.syncWallpaperEffects() }
        function onBarBlurEnabledChanged() { root.syncBarBlur() }
        function onWidgetBlurEnabledChanged() { root.syncBarBlur() }
        function onReadyChanged() {
            if (config.ready) root.syncBarRefraction()
            if (config.ready) root.syncBarBrightness()
            if (config.ready) root.syncTerminalLiquid()
            if (config.ready && Number(config.valueAt(config.userData, "appearance.referenceVersion", 0)) < 3)
                config.applyReferenceAppearance()
        }
        function onBlurStrengthChanged() { nativeAppearanceDebounce.restart() }
        function onAppearanceContrastChanged() { nativeAppearanceDebounce.restart() }
        function onReflectionStrengthChanged() { nativeAppearanceDebounce.restart() }
        function onVisualStyleChanged() { nativeAppearanceDebounce.restart() }
    }

    Connections {
        target: preview
        function onShownChanged() { topbarController.close(); widgetTransition.setLocked(preview.shown) }
    }

    Connections {
        target: editorController
        function onMountedChanged() { if (editorController.mounted) topbarController.close() }
    }

    Connections {
        target: widgetTransition
        function onSettled(locked) {
            if (!locked && !preview.shown)
                preview.finishClose()
        }
    }

    function statusSnapshot() {
        return {
            apiVersion: 2,
            version: version,
            ready: config.ready,
            configurationError: config.error,
            nativeBlur: Platform.NativeBlur.state,
            nativeBarMaterial: { available: root.nativeBarMaterial, diagnostic: root.nativeBarMaterialDiagnostic },
            infiniteDesktop: {enabled: !!root.shell && root.shell.infiniteDesktopCanvasEnabled,
                progress: root.shell ? root.shell.infiniteDesktopMorphProgress : 0,
                moving: !!root.shell && root.shell.infiniteDesktopMorphing},
            preview: preview.status(),
            settings: editorController.status(),
            editor: editorController.status(),
            compositor: {
                backend: compositor.backend,
                focusedMonitor: compositor.focusedMonitorName,
                surfaceNamespace: compositor.surfaceNamespace
            },
            assets: config.assetStatus(),
            media: {
                available: media.hasPlayer,
                identity: media.identity,
                playing: media.playing
            },
            visualizer: {
                active: visualizer.active,
                edgeMediaOpen: root.desktopVisualizerSuppressed,
                dockProgress: root.visualizerDockProgress,
                running: visualizer.running,
                desktopMaterial: root.nativeBarMaterial,
                desktopVisible: root.desktopVisualizerVisible,
                bands: visualizer.bandCount,
                native: true
            },
            sharedWidgets: {
                progress: widgetTransition.progress,
                running: widgetTransition.running,
                phase: widgetTransition.phase,
                count: config.sharedWidgets.length,
                desktopTemplate: config.desktopLayoutTemplate,
                desktopSeed: config.desktopLayoutSeed,
                visibility: config.sharedWidgetVisibilitySnapshot(
                    widgetTransition.progress)
            },
            topbar: {
                enabled: config.topbarEnabled,
                brightness: config.barBrightness,
                layoutCount: config.topbarLayout.length,
                leftCount: config.topbarItemsForSection("left", false).length,
                centerCount: config.topbarItemsForSection("center", false).length,
                rightCount: config.topbarItemsForSection("right", false).length,
                hiddenForFullscreen: compositor.activeToplevelFullscreen,
                systemName: config.systemName,
                wifi: systemStatus.wifiName,
                battery: systemStatus.hasBattery ? systemStatus.batteryPercent : -1,
                volume: systemStatus.volumePercent,
                muted: systemStatus.muted,
                performanceActive: systemStatus.performanceActive,
                cpu: systemStatus.performanceAvailable
                    ? systemStatus.cpuPercent : -1,
                ram: systemStatus.performanceAvailable
                    ? systemStatus.ramPercent : -1
            },
            appearance: {
                visualStyle: config.visualStyle,
                colorScheme: config.colorScheme,
                material: config.materialMode,
                motionPreset: config.motionPreset,
                characterPywal: config.characterPywal,
                pywalReady: pywalPalette.ready,
                pywalSource: pywalPalette.sourcePath,
                pywalGenerating: pywalPalette.generating,
                pywalError: pywalPalette.error,
                accentMode: config.accentMode,
                accent: String(theme.accent),
                barSurface: String(theme.barSurface),
                textPrimary: String(theme.textPrimary),
                wallpaper: wallpaper.currentPath
            },
            compositionProfiles: compositionProfiles.status()
        }
    }

    IpcHandler {
        function paletteState(): string {
            return JSON.stringify({ready: pywalPalette.ready, generating: pywalPalette.generating,
                error: pywalPalette.error, wallpaper: pywalPalette.sourcePath,
                tone: pywalPalette.requestedTone, background: String(pywalPalette.background),
                // Keep terminal theme generation independent of the surface
                // following that terminal, avoiding repeated tint/opacity feedback.
                bar: String(theme.independentBarSurface), foreground: String(theme.textPrimary),
                terminalFollowBar: config.terminalFollowBar && config.terminalLiquidEnabled
                    && Platform.NativeBlur.supports("terminal-follow-bar"),
                barColor: Qt.rgba(theme.independentBarSurface.r, theme.independentBarSurface.g,
                    theme.independentBarSurface.b, 1).toString(),
                barOpacity: theme.independentBarSurface.a,
                exactSurface: pywalPalette.exactSurface})
        }
        function paletteShuffle(): void { pywalPalette.shuffle() }
        function topbarState(): string {
            return JSON.stringify(Object.assign(topbarController.snapshot(), {
                oneThingEnabled: config.topbarOneThingEnabled,
                notesEnabled: config.topbarNotesEnabled,
                blurEnabled: config.barBlurEnabled,
                widgetBlurEnabled: config.widgetBlurEnabled,
                toolsOrder: config.topbarToolsOrder,
                editing: editorController.shown && editorController.mode === "editing"
            }))
        }
        function topbarOption(name: string, enabled: bool): bool {
            if (!["oneThingEnabled", "notesEnabled"].includes(name)) return false
            config.setValue("topbar." + name, enabled)
            return true
        }
        function barBlur(enabled: bool): void { config.setValue("bar.blurEnabled", enabled) }
        function widgetBlur(enabled: bool): void { config.setValue("lockPreview.sharedWidgets.blurEnabled", enabled) }
        function topbarMove(type: string, target: string): bool { return config.moveTopbarTool(type, target) }
        function topbarToggle(type: string): bool { return topbarController.openByType(type, compositor.focusedMonitorName) }
        function topbarClose(): void { topbarController.close() }
        function timerState(): string {
            return JSON.stringify({running: topbarTimer.countdown.running, finished: topbarTimer.finished,
                duration: topbarTimer.duration, remaining: topbarTimer.remaining,
                alertPhase: topbarTimer.alertPhase, alertStrength: topbarTimer.alertStrength})
        }
        function timerStart(seconds: int): bool { return topbarTimer.startDuration(seconds) }
        function timerDismiss(): bool { return topbarTimer.dismissAlert() }
        function timerSnooze(): bool { return topbarTimer.snoozeAlert() }
        target: "composition"

        function lockToggle(): void {
            if (editorController.mounted)
                editorController.hide()
            else
                preview.toggle()
        }
        function nativeBlurSuspend(): void { Platform.NativeBlur.suspend() }
        function nativeBlurResume(): void { Platform.NativeBlur.resume() }
        function opticsResync(): void {
            Platform.NativeBlur.refresh()
            root.opticsGeneration += 1
            root.syncNativeAppearance()
        }
        function terminalLiquid(action: string, strength: real): string {
            return root.controlTerminalLiquid(action, strength)
        }
        function terminalBrightness(value: real): bool {
            if (!config.ready || !Number.isFinite(value) || value < .8 || value > 1.2) return false
            config.setValue("appearance.terminalBarBrightness", value)
            return true
        }
        function barBrightness(value: real): bool {
            if (!config.ready || !Number.isFinite(value) || value < .2 || value > 1.2) return false
            config.setValue("bar.brightness", value)
            return true
        }
        function referenceAppearanceApply(): void { config.applyReferenceAppearance() }
        function barAppearance(material: string, waveStrength: real): bool {
            return config.setBarAppearance(material, waveStrength)
        }
        function barOpacity(value: real): bool {
            return config.setBarOpacity(value)
        }
        function widgetSurface(mode: string): bool {
            return config.setWidgetSurfaceMode(mode)
        }
        function lockPreviewShow(): void { preview.show() }
        function lockPreviewHide(): void { preview.hide() }
        function lockPreviewToggle(): void { preview.toggle() }
        function settingsShow(): void { editorController.show("desktop") }
        function settingsHide(): void { editorController.hide() }
        function settingsToggle(): void {
            if (editorController.mounted) editorController.hide(); else editorController.show("desktop")
        }
        function settingsPage(page: string): bool {
            editorController.show(page === "lock" ? "lock" : "desktop")
            editorController.setSettingsPage(page)
            return true
        }
        function settingsEditSpace(space: string): bool {
            return editorController.beginEditing(space)
        }
        function settingsChooseImage(target: int): bool {
            return editorController.chooseImage(target)
        }
        function settingsChooseBarAvatar(): bool {
            return editorController.chooseBarAvatar()
        }
        function editorShow(space: string): bool {
            editorController.show(space)
            return editorController.beginEditing(space)
        }
        function editorHide(): bool { return editorController.hide() }
        function editorToggle(space: string): bool {
            return editorController.mounted
                ? editorController.hide() : editorController.show(space)
        }
        function editorEditSpace(space: string): bool {
            if (!editorController.mounted)
                return editorController.show(space)
            return editorController.setEditSpace(space)
        }
        function editorSelect(layerId: string): bool {
            sceneEditor.select(layerId)
            return sceneEditor.selectedLayerId === layerId
        }
        function sharedWidgetsPersist(): bool {
            return config.setSharedWidgets(config.sharedWidgets, true)
        }
        function sharedWidgetVisibility(kind: string, desktopEnabled: bool,
                                        lockEnabled: bool): bool {
            return config.setSharedWidgetVisibility(
                kind, desktopEnabled, lockEnabled)
        }
        function profileApply(profileId: string): bool {
            return compositionProfiles.applyProfile(profileId, true)
        }
        function profileUpdate(profileId: string): bool {
            return compositionProfiles.updateProfile(profileId)
        }
        function status(): string { return JSON.stringify(root.statusSnapshot()) }
    }

    Component.onCompleted: {
        Qt.callLater(root.syncNativeAppearance)
        console.info("Velora Shell Configuration Loaded")
        console.info("Lock preview is inactive; open it through the composition IPC target")
    }
}
