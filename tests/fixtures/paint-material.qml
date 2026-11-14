import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../core" as Core
import "../../features/topbar" as Topbar
ShellRoot {
    id: test
    property int layoutChanges: 0
    property int orderChanges: 0
    function find(item, name) {
        if (item.objectName === name) return item
        for (const child of item.children || []) { const found = find(child, name); if (found) return found }
        return null
    }
    function check(v, msg) { if (!v) throw Error(msg) }
    Core.ConfigStore { id: config }
    Core.Theme { id: realTheme; config: config; palette: null }
    QtObject {
        id: wallpaper
        property string currentPath: "/fixture/blue.png"
        property string appliedPath: currentPath
        property string currentPreviewPath: ""
        signal wallpaperApplied(string path)
    }
    Component { id: paletteComponent; Core.PywalPalette {} }
    QtObject {
        id: theme
        property var config: config
        property string bodyFont: "Sans"
        property color textPrimary: "white"
        property color textSecondary: "gray"
        property color wallpaperSurfaceTone: "black"
        property color accent: "red"
        property color accentAlt: "blue"
        property color borderStrong: "gray"
        function withAlpha(c,a) { return Qt.rgba(c.r,c.g,c.b,a) }
    }
    Topbar.TopBarController { id: controller }
    Connections {
        target: config
        function onTopbarLayoutChanged() { test.layoutChanges++; controller.close() }
        function onTopbarToolsOrderChanged() { test.orderChanges++ }
    }
    Window {
        id: win
        visible: true; width: 260; height: 192
        Topbar.BarPanelContent {
            id: panel; anchors.fill: parent
            type: "paint"; theme: theme; system: ({palette:null}); systemStatus: ({}); fanPlus: ({})
            timerService: ({}); clock: ({}); calendar: ({}); media: ({}); weather: ({}); controller: controller; actions: ({})
        }
    }
    TestCase { id: input; name: "PaintMaterial"; when: false }
    Timer {
        interval: 350; running: true
        onTriggered: {
            try {
                test.check(config.ready, "Config not loaded")
                config.setBarAppearance("solid", config.barWaveStrength)
                test.layoutChanges = 0; test.orderChanges = 0
                controller.show("paint", panel, win, false)
                const slider = test.find(panel, "paintMaterialSlider")
                test.check(slider && slider.width <= 136, "Slider not compact")
                slider.forceActiveFocus()
                input.keyClick(Qt.Key_Right)
                test.check(config.barMaterial === "glass", "Right did not select glass")
                input.keyClick(Qt.Key_Right)
                test.check(config.barMaterial === "liquid", "Right did not select liquid")
                input.keyClick(Qt.Key_Left); input.keyClick(Qt.Key_Left)
                test.check(config.barMaterial === "solid", "Left did not select solid")
                test.check(controller.activeType === "paint", "Menu closed")
                test.check(test.layoutChanges === 0 && test.orderChanges === 0, "Unrelated models rebuilt")
                config.setValue("appearance.reducedMotion", true)
                test.check(config.setPickedWallpaperColor("#0066ff"), "Picked color rejected")
                test.check(config.customColor("bar").toString() === "#0066ff", "Bar color not updated")
                test.check(realTheme.accent.toString() === "#0066ff", "Workspace accent stayed pink")
                test.check(!config.barMatchKittyMaterial, "Kitty overrides picked color")
                test.check(controller.activeType === "paint", "Color change closed menu")
                test.check(!config.setPickedWallpaperColor("invalid"), "Invalid color accepted")
                test.check(realTheme.accent.toString() === "#0066ff", "Invalid color changed accent")
                const palette = paletteComponent.createObject(test, {config: config, wallpaperService: wallpaper})
                test.check(palette !== null, "Palette unavailable")
                palette.requestGeneration()
                test.check(config.accentMode === "custom", "Manual pick lost on same wallpaper")
                wallpaper.currentPath = "/fixture/green.png"
                test.check(config.accentMode === "wallpaper" && palette.paletteEnabled, "Automatic extraction not restored")
                test.check(config.setPickedWallpaperColor("#009944"), "Second manual pick rejected")
                palette.requestGeneration()
                test.check(config.accentMode === "custom", "Second manual pick lost")
                wallpaper.currentPath = "/fixture/blue.png"
                test.check(config.accentMode === "wallpaper", "Returning wallpaper did not resume extraction")
                palette.destroy()
                const changed = config.topbarLayout.map(x => Object.assign({}, x))
                changed[0].enabled = !changed[0].enabled
                config.setValue("topbar.layout", changed)
                test.check(test.layoutChanges > 0, "Actual layout change ignored")
                console.log("PAINT_MATERIAL_OK"); Qt.quit()
            } catch(e) { console.error("PAINT_MATERIAL_FAILED " + e); Qt.exit(1) }
        }
    }
}
