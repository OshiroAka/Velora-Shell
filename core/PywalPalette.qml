import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    required property var config
    required property var wallpaperService

    readonly property string cachePath: config.configHome
        ? (Quickshell.env("XDG_CACHE_HOME") || config.homeDir + "/.cache")
            + "/velora-shell/pywal/colors.json"
        : ""

    property bool ready: false
    property bool generating: false
    property bool regeneratePending: false
    property string sourcePath: ""
    property color background: "#111216"
    property color foreground: "#f5f7fb"
    property color muted: "#8793a8"
    property color accent: "#b99cff"
    property color accentAlt: "#8db8ff"
    property color accentSoft: "#d9ceff"
    property string generatorSourcePath: ""
    property string generatorTone: ""
    property string error: ""
    readonly property string requestedPreviewPath:
        String(config.accentMode || "wallpaper") === "wallpaper"
        && localPath(wallpaperService.currentPath) === wallpaperService.appliedPath
            ? localPath(wallpaperService.currentPreviewPath) : ""
    readonly property bool paletteEnabled:
        String(config.accentMode || "wallpaper") === "wallpaper"
    readonly property string requestedSourcePath: {
        const wallpaperPath = localPath(wallpaperService.currentPath)
        return wallpaperPath
    }
    readonly property string requestedTone: {
        const requested = String(config.pywalTone || "auto")
        if (requested === "dark" || requested === "light")
            return requested
        return String(config.colorScheme || "dark") === "light"
            ? "light" : "dark"
    }

    function localPath(value) {
        const text = String(value || "")
        if (text.startsWith("file://"))
            return decodeURIComponent(text.slice(7))
        return text
    }

    function requestGeneration() {
        if (!paletteEnabled || requestedSourcePath.length === 0) {
            ready = false
            return
        }
        generationDelay.restart()
    }

    function startGeneration() {
        if (!paletteEnabled || requestedSourcePath.length === 0)
            return
        if (generator.running) {
            regeneratePending = true
            return
        }
        generating = true
        error = ""
        generatorSourcePath = requestedSourcePath
        generatorTone = requestedTone
        generator.command = [
            Quickshell.shellDir + "/scripts/generate-pywal-palette",
            generatorSourcePath,
            generatorTone,
            requestedPreviewPath
        ]
        generator.running = true
    }

    function loadDocument(text) {
        try {
            const document = JSON.parse(text || "{}")
            const special = document.special || ({})
            const colors = document.colors || ({})
            const velora = document.velora || ({})
            const generatedFor = String(document.wallpaper || "")
            const generatedTone = String(document.tone || "")
            const requestedFor = requestedSourcePath
            // A generator that was already running may finish after another
            // preset was selected. Keep the previous complete palette on
            // screen; never publish stale colors or fall back for one frame.
            if (paletteEnabled && (generatedFor !== requestedFor
                    || generatedTone !== requestedTone)) {
                if (!generating)
                    requestGeneration()
                return
            }
            if (!paletteEnabled) {
                ready = false
                return
            }
            sourcePath = generatedFor
            background = String(special.background || colors.color0 || "#111216")
            foreground = String(special.foreground || colors.color15 || "#f5f7fb")
            muted = String(colors.color8 || colors.color7 || "#8793a8")
            accent = String(velora.primary || colors.color12
                || colors.color4 || "#b99cff")
            accentAlt = String(velora.secondary || colors.color11
                || colors.color13 || "#8db8ff")
            accentSoft = String(velora.soft || colors.color14
                || colors.color13 || "#d9ceff")
            ready = true
        } catch (parseError) {
            ready = false
            console.warn("Velora Shell pywal palette error:", parseError)
        }
    }

    onPaletteEnabledChanged: requestGeneration()
    onRequestedSourcePathChanged: requestGeneration()
    onRequestedPreviewPathChanged: requestGeneration()
    onRequestedToneChanged: requestGeneration()

    Connections {
        target: root.wallpaperService
        function onCurrentPathChanged() { root.requestGeneration() }
        function onWallpaperApplied() { root.requestGeneration() }
    }

    Timer {
        id: generationDelay
        interval: 320
        repeat: false
        onTriggered: root.startGeneration()
    }

    Process {
        id: generator
        running: false
        onExited: function(exitCode) {
            root.generating = false
            if (exitCode === 0)
                paletteFile.reload()
            else {
                root.error = "Não foi possível extrair as cores do wallpaper."
                console.warn("Velora Shell pywal exited with code", exitCode)
            }

            if (root.regeneratePending) {
                root.regeneratePending = false
                root.requestGeneration()
            }
            if (exitCode === 0)
                reloadDelay.restart()
        }
    }

    // FileView can observe the atomic rename a few milliseconds before the
    // replacement inode is readable. A second load makes wallpaper changes
    // deterministic without flashing a fallback palette.
    Timer {
        id: reloadDelay
        interval: 90
        repeat: false
        onTriggered: paletteFile.reload()
    }

    FileView {
        id: paletteFile
        path: root.cachePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.loadDocument(text())
        onLoadFailed: function(errorCode) {
            root.ready = false
            if (root.paletteEnabled)
                root.requestGeneration()
        }
    }

    Component.onCompleted: requestGeneration()
}
