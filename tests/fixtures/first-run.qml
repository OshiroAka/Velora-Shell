import QtQuick
import Quickshell
import "core" as Core
import "services" as Services

ShellRoot {
    Core.ConfigStore { id: configuration }
    QtObject {
        id: wallpaper
        property bool ready: true
        property string currentPath: ""
        function fileUrl(path) { return path ? "file://" + path : "" }
        function applyWallpaper(path) { return false }
    }
    Services.CompositionProfileService {
        id: profiles
        config: configuration
        wallpaperService: wallpaper
    }
    Timer {
        property int attempts: 0
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            attempts += 1
            if (configuration.ready && profiles.ready) {
                console.info("VELORA_FIRST_RUN_READY")
                Qt.quit()
            } else if (attempts > 80) {
                console.error("VELORA_FIRST_RUN_FAILED", configuration.error, profiles.error)
                Qt.quit()
            }
        }
    }
}
