import QtQuick
import QtQuick.Window
import Quickshell
import "../../services" as Services
import "../../features/topbar" as Topbar

ShellRoot {
    id: test
    property int completed: 0
    property int applied: 0
    property string lastKey: ""
    property string failure: ""
    Services.WallpaperLibraryService {
        id: library
        active: true
        onImported: (entries, message) => {
            test.completed++
            if (entries.length) {
                test.lastKey = entries[0].key
                picker.selectEntry(test.lastKey)
                if (message) test.failure = message
            } else if (test.completed !== 3 || !message) test.failure = "Missing import failure"
        }
    }
    Window {
        width: 1366; height: 768; visible: true
        Topbar.WallpaperPicker {
            id: picker
            anchors.fill: parent
            reducedMotion: true
            entries: library.entries
            importing: library.importing
            onApplyRequested: test.applied++
        }
    }
    Component.onCompleted: {
        picker.open = true
        const urls = JSON.parse(Quickshell.env("VELORA_IMPORT_URLS"))
        library.importUrls([urls[0]])
        library.importUrls([urls[1]])
        library.importUrls(["file:///missing-download.png"])
    }
    Timer {
        interval: 20; repeat: true; running: true
        onTriggered: {
            if (test.completed !== 3 || library.importing || library.entries.length !== 2 || library.running) return
            if (test.failure || test.applied || picker.entries[picker.selectedIndex].key !== test.lastKey)
                console.error("WALLPAPER_IMPORT_FAILED", test.failure, test.applied, picker.selectedIndex)
            else console.info("WALLPAPER_IMPORT_SERVICE_OK")
            Qt.quit()
        }
    }
    Timer { interval: 10000; running: true; onTriggered: { console.error("WALLPAPER_IMPORT_FAILED timeout", test.completed, library.entries.length); Qt.quit() } }
}
