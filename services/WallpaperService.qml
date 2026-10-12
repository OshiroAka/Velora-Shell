import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string statePath: homeDir + "/.cache/velora-shell/current_wallpaper"
    readonly property string helperPath: Quickshell.shellDir + "/scripts/velora-composition-wallpaper-apply"

    property bool ready: false
    property bool running: false
    property string error: ""
    property string currentPath: ""
    property string currentPreviewPath: ""
    property string currentKind: ""
    property string appliedPath: ""
    property string inFlightPath: ""
    property string pendingPath: ""

    signal wallpaperApplied(string path)

    function localPath(value) {
        const text = String(value || "")
        if (text.startsWith("file://"))
            return decodeURIComponent(text.slice(7))
        return text
    }

    function fileUrl(value) {
        const path = localPath(value)
        return path.length > 0 ? encodeURI("file://" + path) : ""
    }

    function parseState(text) {
        const fields = String(text || "").trim().split("|")
        currentKind = fields[0] || ""
        appliedPath = fields.length >= 2 ? fields[1] : ""
        currentPreviewPath = fields.length >= 3 ? fields[2] : appliedPath
        if (!running)
            currentPath = appliedPath
        ready = true
    }

    function applyWallpaper(value) {
        const path = localPath(value)
        if (!path)
            return false
        if (path === currentPath
                && (wallpaperProcess.running || path === appliedPath)) {
            pendingPath = ""
            return true
        }
        if (wallpaperProcess.running) {
            pendingPath = path
            currentPath = path
            return true
        }
        pendingPath = ""
        currentPath = path
        inFlightPath = path
        error = ""
        wallpaperProcess.command = [helperPath, path]
        wallpaperProcess.running = true
        running = true
        wallpaperApplied(fileUrl(path))
        return true
    }

    FileView {
        id: wallpaperState
        path: root.statePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.parseState(text())
        onLoadFailed: root.ready = true
    }

    Process {
        id: wallpaperProcess
        running: false
        onExited: function(exitCode) {
            root.running = false
            if (exitCode !== 0) {
                root.error = "Não foi possível aplicar o wallpaper deste perfil."
                root.currentPath = root.appliedPath
            } else {
                root.appliedPath = root.inFlightPath
            }
            root.inFlightPath = ""
            const next = root.pendingPath
            root.pendingPath = ""
            if (next.length > 0 && next !== root.appliedPath)
                Qt.callLater(function() { root.applyWallpaper(next) })
        }
    }
}
