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
    Core.Theme { id: theme; config: config; palette: null; kittyMaterial: terminalMaterial }
    Core.Motion { id: motion; config: config }
    Core.PreviewController { id: preview; motion: motion; keepWarm: false }
    Components.VeloraTheme { id: historical }
    Services.SceneEditorService { id: scene; config: config }
    QtObject {
        id: wallpaper
        property string currentPath: ""
        property string currentPreviewPath: ""
        property string error: ""
        function applyWallpaper(path) { currentPath=path; return true }
    }
    QtObject {
        id: shell
        property bool barOnRight: false
        property int bottomBarHeight: 18
        property var unifiedTheme: historical
        property var composition: null
        property int pickerCalls: 0
        function openLyricsMaskEditor() { }
        function toggleTopWallpaperPopup(open, keyboard) {
            test.assert(open && keyboard, "main picker must open with keyboard focus")
            pickerCalls++
        }
    }
    Core.SettingsController { id: controller; config: config; editor: scene; motion: motion; preview: preview; wallpaperService: wallpaper; shell: shell }
    Window {
        id: window
        width: 1440; height: 900; visible: true; color: "#1b424b"
        Editor.EditorChrome {
            id: chrome; anchors.fill: parent; config: config; controller: controller; editor: scene
            theme: theme; motion: motion
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
    TestCase { id: input; name: "WallpaperSettingsInput"; when: windowShown }
    property int step: 0
    function capture(name) {
        const directory=Quickshell.env("VELORA_WALLPAPER_EVIDENCE")
        if (directory) { window.contentItem.grabToImage(result=>result.saveToFile(directory+"/"+name+".png"));input.wait(75) }
    }
    Timer {
        interval: 400; running: true; repeat: true
        onTriggered: {
            if (!config.ready) return
            try {
                const home=chrome.settingsItem
                if (test.step===0) {
                    config.setValue("appearance.reducedMotion",true)
                    controller.show("desktop");controller.setSettingsPage("wallpapers")
                } else if (test.step===1) {
                    assert(!find(home,"wallpaperBackdrop"),"decorative wallpaper remains in the menu")
                    for (const name of ["image","effects","transitions","animated"]) {
                        const group=find(home,"wallpaperGroup-"+name)
                        assert(!!group && !group.expanded && !group.contentItem,"closed wallpaper group keeps content alive")
                    }
                    capture("collapsed")
                    const image=find(home,"wallpaperGroup-image")
                    input.mouseClick(image,20,27);input.wait(35)
                    assert(image.expanded && !!find(home,"wallpaper.fit"),"mouse must open image controls")
                    const whole=find(home,"Imagem inteira")
                    input.mouseClick(whole,whole.width/2,whole.height/2)
                    assert(config.wallpaperFit==="contain","framing mouse control failed")
                    const effects=find(home,"wallpaperGroup-effects")
                    effects.children[0].children[0].forceActiveFocus()
                    input.keyClick(Qt.Key_Return);input.wait(35)
                    assert(effects.expanded,"keyboard must expand effects")
                    const blur=find(home,"wallpaperBlurToggle")
                    blur.triggered()
                    find(home,"wallpaper.blur-strength").edited(.63)
                    find(home,"wallpaper.dimming").edited(.27)
                    assert(config.wallpaperBlurEnabled && Math.abs(config.wallpaperBlurStrength-.63)<.001 && Math.abs(config.wallpaperDimming-.27)<.001,"effects failed to save")
                    input.keyClick(Qt.Key_Space)
                    assert(!effects.expanded && !effects.contentItem,"collapsed effects keep previews mounted")
                    home.contentItem.revealSetting("wallpaper.duration")
                } else if (test.step===2) {
                    const group=find(home,"wallpaperGroup-transitions")
                    assert(group.expanded && !!find(home,"wallpaper.duration"),"search must reveal the transition group")
                    find(home,"wallpaper.duration").edited(.85)
                    assert(Math.abs(controller.integrations.wallpaperTransitionDuration-.85)<.001,"duration setter lost")
                    capture("transitions")
                    home.contentItem.revealSetting("motion.reduced")
                } else if (test.step===3) {
                    const group=find(home,"systemGroup-accessibility")
                    assert(home.page==="system" && group.expanded,"search must reveal accessibility within System")
                    assert(!find(home,"settingsNav-motion") && !find(home,"settingsNav-language"),"deleted categories remain in sidebar")
                    const reduced=find(home,"motion.reduced")
                    const viewport=find(home,"settingsViewport")
                    const point=reduced.mapToItem(viewport,0,0)
                    assert(point.y>=0 && point.y+reduced.height<=viewport.height,"accessibility search leaves the focused control outside the viewport")
                    const locale=find(home,"system.locale")
                    locale.chosen("ja_JP")
                    assert(config.localeName==="ja_JP","locale setting lost")
                    capture("accessibility")
                    window.width=800;window.height=600
                    controller.setSettingsPage("wallpapers")
                } else if (test.step===4) {
                    assert(home.compact,"compact layout not active")
                    const group=find(home,"wallpaperGroup-effects")
                    input.mouseClick(group,20,27);input.wait(35)
                    const slider=find(home,"wallpaper.dimming")
                    const position=slider.mapToItem(home,0,0)
                    assert(position.x>=0 && position.x+slider.width<=home.width,"effects overflow the compact menu")
                    capture("compact")
                    group.expanded=false
                    assert(!group.contentItem,"compact closed effects retained content")
                    find(home,"wallpaper.choose").triggered()
                } else if (test.step===5) {
                    assert(shell.pickerCalls===1 && !controller.shown,"wallpaper action must open the main picker and close Settings")
                    console.info("WALLPAPER_SETTINGS_OK mouse keyboard search collapse compact effects main-picker")
                    Qt.quit();running=false
                }
                test.step++
            } catch(error) { console.error("WALLPAPER_SETTINGS_FAILED",String(error),error.stack);Qt.quit();running=false }
        }
    }
}
