import QtQuick
import Quickshell
import "core" as Core
import "services" as Services

ShellRoot {
    Core.ConfigStore { id: configuration }
    Services.WallpaperService { id: wallpaper }
    Core.PywalPalette { id: palette; config: configuration; wallpaperService: wallpaper }
    Core.Theme {
        id: freshTheme
        config: configuration
        palette: palette
    }
    Timer {
        property int attempts: 0
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            attempts += 1
            if (configuration.ready && wallpaper.ready && palette.ready) {
                const color = freshTheme.withAlpha(undefined, 0.5)
                const expected = {clock: ["dots", 653, 740], weather: ["dots", 96.5, 54],
                                  system: ["metrics", 1229.9, 54], battery: ["ring", 748.3, 635.8]}
                const desktop = configuration.sharedWidgets.filter(widget => widget.desktopEnabled)
                const layoutMatches = desktop.length === 4 && desktop.every(widget => {
                    const target = expected[widget.kind]
                    return target && widget.variantId === target[0]
                        && Math.abs(widget.desktop.x - target[1]) < .01 && Math.abs(widget.desktop.y - target[2]) < .01
                })
                const paletteMatches = String(freshTheme.independentBarSurface) === "#131d26"
                    && String(palette.foreground) === "#f6f4f1"
                if (Math.abs(color.a - 0.5) > 0.01 || !configuration.referenceAppearance || !layoutMatches
                        || !wallpaper.appliedPath.endsWith("/assets/wallpapers/velora.png") || !paletteMatches) {
                    console.error("VELORA_FIRST_RUN_FAILED", JSON.stringify({
                        surface: String(freshTheme.independentBarSurface), ink: String(palette.foreground),
                        wallpaper: wallpaper.appliedPath, widgets: desktop.map(widget => widget.kind),
                        layoutMatches: layoutMatches
                    }))
                    Qt.quit()
                    return
                }
                console.info("VELORA_FIRST_RUN_READY")
                Qt.quit()
            } else if (attempts > 80) {
                console.error("VELORA_FIRST_RUN_FAILED", configuration.error)
                Qt.quit()
            }
        }
    }
}
