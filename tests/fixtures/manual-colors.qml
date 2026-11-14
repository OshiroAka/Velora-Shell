import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../core" as Core
import "../../services" as Services
import "../../components" as Components
import "../../features/editor" as Editor
import "../../features/editor/SettingsCatalog.js" as Catalog

ShellRoot {
    id: test
    Core.ConfigStore { id: config }
    Core.KittyMaterial { id: terminalMaterial; config: config }
    QtObject { id: palette; property bool ready: true; property bool exactSurface: true
        property color background: "#223344"; property color foreground: "#f4f4ff"; property color muted: "#b0bccd"
        property color accent: "#aabbcc"; property color accentAlt: "#667788"; property color accentSoft: "#ccddee" }
    Core.Theme { id: theme; config: config; palette: palette; kittyMaterial: terminalMaterial }
    Core.PywalPalette { id: extractor; config: config; wallpaperService: wallpaper }
    Core.Motion { id: motion; config: config }
    Core.PreviewController { id: preview; motion: motion; keepWarm: false }
    Components.VeloraTheme { id: historical }
    Services.SceneEditorService { id: scene; config: config }
    QtObject {
        id: wallpaper
        property string currentPath: ""
        property string currentPreviewPath: ""
        property string error: ""
        property string appliedPath: currentPath
        signal wallpaperApplied(string path)
        function applyWallpaper(path) { currentPath=path; return true }
    }
    QtObject {
        id: profiles
        signal profileApplied()
        signal operationFinished(string operation, bool ok, string message)
        property var wallpaperService: wallpaper
        property string activeProfileId: ""
        property var profiles: []
        property string error: ""
    }
    QtObject {
        id: shell
        property bool barOnRight: false
        property int bottomBarHeight: 18
        property var unifiedTheme: historical
        property var composition: null
        function openLyricsMaskEditor() { }
    }
    QtObject { id: wallpaperStore; property string activeKey: "fixture" }
    Core.SettingsController { id: controller; config: config; editor: scene; motion: motion; preview: preview; profileService: profiles; shell: shell }
    Window {
        id: window
        TestCase { id: pointer; name: "ManualColorPointer"; when: false }
        Components.VeloraBarItemBubble {
            id: manualBubble; width: 50; height: 100; shown: true
            tint: theme.barBubbleTint; surfaceTint: theme.barSurface; exactColor: theme.manualPalette
        }
        width: 1440; height: 900; visible: true; color: "#1b424b"
        Editor.EditorChrome {
            id: chrome; anchors.fill: parent; config: config; controller: controller; editor: scene
            theme: theme; motion: motion; profileService: profiles; wallpaperStore: wallpaperStore
            presented: controller.shown
        }
    }
    function assert(value, message) { if (!value) throw new Error(message) }
    function find(item, name) {
        if (!item) return null
        if (item.objectName === name || item.label === name) return item
        const list=item.children||[]
        for(let i=0;i<list.length;i++) { const result=find(list[i],name); if(result) return result }
        return null
    }
    property int phase: 0
    property string originalBubble: ""
    Timer {
        interval: 140; repeat: true; running: true
        onTriggered: {
            if (!config.ready) return
            try {
                const home=chrome.settingsItem
                if (phase===0) {
                    if (Quickshell.env("VELORA_MANUAL_RELOAD")==="1") {
                        assert(config.customColor("bubbles")==="#12ab34","manual bubble colour lost across processes")
                        assert(!config.wallpaperColorsEnabled && config.accentMode==="custom","automatic colour preference lost")
                        console.info("MANUAL_COLORS_OK reload"); Qt.quit(); return
                    }
                    config.setValue("appearance.reducedMotion",true)
                    controller.show("desktop")
                    controller.setSettingsPage("appearance")
                } else if (phase===1) {
                    const toggle=find(home,"appearance.automatic-colors")
                    assert(toggle && toggle.checked,"automatic colours toggle missing")
                    toggle.forceActiveFocus(); pointer.keyClick(Qt.Key_Space)
                    assert(!config.wallpaperColorsEnabled && config.accentMode==="custom","automatic colours do not disable")
                    originalBubble=config.customColor("bubbles")
                } else if (phase===2) {
                    const choice=find(home,"appearance.color.bubbles")
                    assert(!!choice,"manual bubble colour missing")
                    choice.forceActiveFocus(); pointer.keyClick(Qt.Key_Space)
                } else if (phase===3) {
                    const picker=find(home,"manualColorPicker")
                    assert(picker && picker.parent,"picker did not open inside Settings")
                    const square=find(picker,"manualColorPicker.square")
                    pointer.mouseClick(square,square.width*.7,square.height*.25,Qt.LeftButton)
                    assert(Math.abs(picker.saturation-.7)<.03 && Math.abs(picker.level-.75)<.03,"native colour square ignores mouse: "+square.width+"x"+square.height+" at "+JSON.stringify(square.mapToItem(window.contentItem,0,0))+" HSV="+picker.saturation+","+picker.level+" viewport="+find(home,"settingsViewport").contentY+","+find(home,"settingsViewport").contentHeight+","+find(home,"settingsViewport").height+" pickerHeight="+picker.height+" presented="+home.presented)
                    const hue=find(picker,"manualColorPicker.hue")
                    hue.forceActiveFocus(); pointer.keyClick(Qt.Key_Right)
                    assert(config.customColor("bubbles")===originalBubble,"draft colour applied before confirmation")
                    const hex=find(picker,"manualColorPicker.hex")
                    hex.text="invalid"; hex.textEdited()
                    assert(!find(picker,"manualColorPicker.apply").enabled,"invalid hex can be saved")
                    hex.text="#12ab34"; hex.textEdited()
                    assert(picker.hexColor==="#12ab34","hexadecimal edit does not update picker")
                    const image=Quickshell.env("VELORA_MANUAL_SCREENSHOT")
                    if(image) window.contentItem.grabToImage(result=>result.saveToFile(image))
                    find(picker,"manualColorPicker.apply").clicked()
                } else if (phase===4) {
                    assert(!find(home,"manualColorPicker"),"confirmed picker stays mounted")
                    assert(config.customColor("bubbles")==="#12ab34","manual colour was not saved")
                    assert(Math.abs(theme.barBubbleTint.g-171/255)<.005,"manual colour does not reach bar bubbles")
                    wallpaper.currentPath="/fixture/first.png"
                    wallpaper.currentPath="/fixture/second.png"
                    assert(!config.wallpaperColorsEnabled && config.accentMode==="custom" && !extractor.paletteEnabled,"wallpaper re-enables automatic colours")
                    find(home,"appearance.color.bubbles").triggered()
                } else if (phase===5) {
                    const picker=find(home,"manualColorPicker")
                    assert(picker.hexColor==="#12ab34","reopened picker lost saved colour")
                    const hex=find(picker,"manualColorPicker.hex"); hex.text="#ff0000"; hex.textEdited()
                    find(picker,"manualColorPicker.cancel").clicked()
                } else if (phase===6) {
                    assert(config.customColor("bubbles")==="#12ab34" && !find(home,"manualColorPicker"),"cancel changes persisted colour")
                    wallpaper.currentPath=""
                    find(home,"appearance.automatic-colors").triggered()
                    assert(config.wallpaperColorsEnabled && config.accentMode==="wallpaper","automatic colours do not re-enable")
                } else if (phase===7) {
                    find(home,"appearance.automatic-colors").triggered()
                    assert(config.customColor("bubbles")==="#aabbcc","disabling automatic colours does not freeze current palette")
                    config.setCustomColor("bubbles","#ffffff")
                    config.setValue("appearance.colorScheme","dark")
                } else if (phase===8) {
                    assert(manualBubble.bubbleColor.r===1 && manualBubble.bubbleColor.g===1 && manualBubble.bubbleColor.b===1 && manualBubble.bubbleColor.a===1,"manual white is tinted in dark mode")
                    manualBubble.grabToImage(result=>result.saveToFile(Quickshell.env("VELORA_MANUAL_WHITE_SCREENSHOT")+"dark.png"))
                    config.setValue("appearance.colorScheme","light")
                } else if (phase===9) {
                    assert(manualBubble.bubbleColor.r===1 && manualBubble.bubbleColor.g===1 && manualBubble.bubbleColor.b===1 && manualBubble.bubbleColor.a===1,"manual white is tinted in light mode")
                    manualBubble.grabToImage(result=>result.saveToFile(Quickshell.env("VELORA_MANUAL_WHITE_SCREENSHOT")+"light.png"))
                } else if (phase===10) {
                    config.setCustomColor("bubbles","#12ab34")
                } else if (phase===11) {
                    if (config.savePending) return
                    console.info("MANUAL_COLORS_OK"); Qt.quit(); return
                }
                phase++
            } catch(error) { console.error("MANUAL_COLORS_FAILED",String(error),error.stack);Qt.quit() }
        }
    }
    Timer { interval: 10000; running: true; onTriggered: { console.error("MANUAL_COLORS_FAILED timeout");Qt.quit() } }
}
