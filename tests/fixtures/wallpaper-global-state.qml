import QtQuick
import Quickshell
import Quickshell.Io
import "../../core" as Core
import "../../services" as Services
import "../../features/editor/SettingsCatalog.js" as Catalog

ShellRoot {
    id: test
    Core.ConfigStore { id: configuration }
    Core.Motion { id: motion; config: configuration }
    Core.PreviewController { id: preview; motion: motion; keepWarm: false }
    Services.SceneEditorService { id: editor; config: configuration }
    Services.WallpaperService { id: wallpaper }
    Core.SettingsController {
        id: settings
        config: configuration; motion: motion; preview: preview
        wallpaperService: wallpaper; editor: editor
    }
    property int step: 0
    property int ticks: 0
    property string baseline: ""
    function check(ok, message) { if (!ok) throw new Error(message) }
    Timer {
        interval: 200; running: true; repeat: true
        onTriggered: {
            if (!configuration.ready || !wallpaper.ready || configuration.savePending || wallpaper.running) return
            try {
                if (++test.ticks > 60) throw new Error("timeout step=" + test.step + " current=" + wallpaper.currentPath + " applied=" + wallpaper.appliedPath + " pending=" + wallpaper.pendingPath + " error=" + wallpaper.error)
                if (test.step === 0) {
                    check(!configuration.error.length, "config remains valid")
                    check(configuration.sharedWidgetByKind("clock").desktop.x === 321, "saved global clock position")
                    check(configuration.sharedWidgetByKind("clock").variantId === "dots", "saved global variant")
                    check(configuration.profileName === "Global", "old profile not applied at startup")
                    check(!Catalog.categories.some(item => item.id === "profiles"), "retired navigation absent")
                    check(!Catalog.entries.some(item => item.id === "wallpaper.autosave" || item.page === "profiles"), "retired search absent")
                    test.baseline = JSON.stringify(configuration.userData)
                    if (Quickshell.env("VELORA_GLOBAL_RELOAD") === "1") {
                        check(configuration.sharedWidgetByKind("clock").desktop.y === 234, "global edit survives restart")
                        console.info("WALLPAPER_GLOBAL_RELOAD_OK"); Qt.quit(); return
                    }
                    wallpaper.applyWallpaper("file:///tmp/global-b.png")
                } else if (test.step === 1) {
                    check(wallpaper.appliedPath === "/tmp/global-b.png", "wallpaper B applied")
                    check(JSON.stringify(configuration.userData) === test.baseline, "new wallpaper keeps every preference")
                    editor.setTransform("shared-clock", "y", 234)
                } else if (test.step === 2) {
                    test.baseline = JSON.stringify(configuration.userData)
                    wallpaper.applyWallpaper("file:///tmp/global-a.png")
                } else if (test.step === 3) {
                    check(wallpaper.appliedPath === "/tmp/global-a.png", "wallpaper A applied again")
                    check(JSON.stringify(configuration.userData) === test.baseline, "returning wallpaper keeps edited scene and all preferences")
                    wallpaper.applyWallpaper("file:///tmp/global-b.png")
                    wallpaper.applyWallpaper("file:///tmp/global-c.png")
                } else if (test.step === 4) {
                    if (wallpaper.appliedPath !== "/tmp/global-c.png") return
                    check(JSON.stringify(configuration.userData) === test.baseline, "queued changes keep settings")
                    settings.pendingKind = "wallpaper"
                    settings.pendingImagePath = "/tmp/global-a.png"
                    settings.restoreAfterPicker(0)
                } else if (test.step === 5) {
                    check(wallpaper.appliedPath === "/tmp/global-a.png", "file picker applies wallpaper directly")
                    check(JSON.stringify(configuration.userData) === test.baseline, "file picker has no composition draft")
                    // Simulate an external backend updating the watched state file.
                    externalWriter.running = true
                } else if (test.step === 6) {
                    if (wallpaper.currentPath !== "/tmp/global-external.png") return
                    check(JSON.stringify(configuration.userData) === test.baseline, "external wallpaper preserves global state")
                    console.info("WALLPAPER_GLOBAL_OK roundtrip queued picker external all-preferences")
                    Qt.quit()
                }
                test.step++
            } catch (error) { console.error("WALLPAPER_GLOBAL_FAILED", String(error), error.stack); Qt.quit() }
        }
    }
    Process {
        id: externalWriter
        command: [Quickshell.shellDir + "/scripts/velora-composition-wallpaper-apply", "/tmp/global-external.png"]
    }
    Timer { interval: 18000; running: true; onTriggered: { console.error("WALLPAPER_GLOBAL_FAILED timeout"); Qt.quit() } }
}
