import QtQuick
import QtQuick.Window
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
    property var destinations: Catalog.categories.map(entry=>entry.id)
    property int step: -1
    property bool beforeGlass: false
    property int launcherProbe: 0
    property int searchIndex: -1
    property var searchable: Catalog.entries.filter(entry => !entry.action)
    property var missingTargets: []
    Timer {
        interval: test.step > test.destinations.length+13 ? 30 : 500; running: true; repeat: true
        onTriggered: {
            if (!config.ready) return
            try {
                test.step++
                const home=chrome.settingsItem
                if (test.step === 0) {
                    if (Quickshell.env("VELORA_SETTINGS_RELOAD") === "1") {
                        assert(config.customColors.text === "#c0ffee", "manual palette survives restart")
                        assert(config.wallpaperFit === "contain", "wallpaper framing survives restart")
                        assert(config.reflectionStrength === 0 && config.blurStrength === 0, "zero endpoints survive restart")
                        assert(!config.terminalLiquidEnabled && config.terminalRefraction===2.4,"terminal liquid preference survives restart")
                        assert(config.barRefractionStrength===7.5,"independent bar refraction survives restart")
                        assert(config.barBrightness===.65,"bar brightness survives restart")
                        assert(config.terminalBarBrightness===.96,"Kitty brightness survives restart")
                        assert(!config.infiniteDesktopTopbarEnabled,"Infinite Desk preference lost on restart")
                        assert(config.barMatchKittyMaterial && config.barMaterial==="liquid","Kitty/bar matching preference lost on restart")
                        assert(config.barIndependentMaterial==="liquid-glass","new optical material does not survive restart")
                        config.setValue("bar.matchKittyMaterial",false)
                        assert(config.barMaterial==="liquid-glass","disabling matching does not restore the new glass")
                        assert(config.barRefractionStrength===2.25,"new glass refraction does not survive restart")
                        assert(!controller.integrations, "closed session does not construct helpers")
                        console.info("SETTINGS_REBUILD_OK reload"); Qt.quit(); return
                    }
                    assert(!Catalog.search("reflexos").some(entry=>entry.id==="appearance.reflection"),"removed reflection control remains searchable")
                    assert(Catalog.search("aparencia").length>0,"accent insensitive search")
                    assert(Catalog.search("blur").length>=4,"blur options search")
                    config.setValue("appearance.reducedMotion",true)
                    controller.show("desktop")
                } else if (test.step <= destinations.length) {
                    if (home.page === "wallpapers") {
                        assert(!find(home,"wallpaperLibrary"),"removed library is still mounted")
                        find(home,"Imagem inteira").clicked()
                        assert(config.wallpaperFit === "contain", "whole-image setting does not update the persisted value")
                        assert(!!find(home,"wallpaper.blur-strength") && !!find(home,"wallpaper.transition") && !!find(home,"openAlternativeWallpaperSelector"),"wallpaper controls are split into tabs")
                    }
                    if (home.page === "appearance") {
                        assert(home.sideNavigation.length===8,"navigation did not lose the two merged categories")
                        assert(find(home,"appearanceGroup-bar").icon==="tune" && find(home,"appearanceGroup-widgets").icon==="grid","merged groups lost their icons")
                        assert(!find(home,"Tom do Pywal"),"tone controls remain in Appearance")
                        find(home,"appearanceGroup-bar").expanded=true
                        assert(!find(home,"settingsNav-bar") && !find(home,"settingsNav-desktop"),"merged categories remain in navigation")
                        const slider=find(home,"settingsSlider")
                        assert(!!slider && slider.height >= 28,"slider has a usable hit area")
                    }
                    if (home.page === "appearance") {
                        const terminal=find(home,"bar.terminal-liquid")
                        const refraction=find(home,"bar.terminal-refraction")
                        assert(!!terminal && !!refraction,"terminal liquid controls mounted")
                        const previous=config.terminalLiquidEnabled
                        terminal.triggered()
                        assert(config.terminalLiquidEnabled!==previous,"terminal toggle does not update configuration")
                        terminal.triggered()
                        refraction.committed(2.4)
                        assert(config.terminalRefraction===2.4,"terminal refraction does not persist")
                        terminal.triggered()
                        assert(!config.terminalLiquidEnabled && !refraction.enabled,"disabled terminal keeps an active slider")
                        const match=find(home,"bar.kitty-match"), infinite=find(home,"bar.infinite-desktop-topbar")
                        const barRefraction=find(home,"bar.refraction")
                        const barBrightness=find(home,"bar.brightness")
                        assert(!!barBrightness && barBrightness.minimum===.2 && barBrightness.maximum===1.2,"bar brightness range missing")
                        const originalOpacity=config.barOpacity, originalKittyBrightness=config.terminalBarBrightness
                        barBrightness.committed(.65)
                        assert(config.barBrightness===.65 && config.barOpacity===originalOpacity
                            && config.terminalBarBrightness===originalKittyBrightness,"bar brightness changes opacity or Kitty's fine adjustment")
                        const brightnessReset=find(home,"bar.brightness.reset")
                        assert(!!brightnessReset,"bar brightness reset missing")
                        brightnessReset.clicked()
                        assert(config.barBrightness===1,"bar brightness reset failed")
                        barBrightness.committed(.65)
                        assert(Catalog.search("brilho da barra").some(entry=>entry.id==="bar.brightness"),"bar brightness search missing")
                        assert(!!barRefraction && barRefraction.maximum===10,"independent bar refraction range missing")
                        config.setBarAppearance("liquid")
                        barRefraction.committed(7.5)
                        assert(config.barRefractionStrength===7.5 && config.terminalRefraction===2.4,"bar refraction changes Kitty strength")
                        const reset=find(home,"bar.refraction.reset")
                        assert(!!reset && reset.enabled,"bar refraction reset missing")
                        reset.clicked()
                        assert(config.barRefractionStrength===1 && config.terminalRefraction===2.4,"reset does not restore only bar refraction")
                        barRefraction.committed(0)
                        assert(config.barRefractionStrength===0,"zero refraction cannot be saved")
                        barRefraction.committed(7.5)
                        assert(!!match && !!infinite,"new bar controls missing")
                        const originalMaterial=config.barMaterial, originalTint=String(theme.barSurface), originalIndependentTint=String(theme.independentBarSurface)
                        const follow=find(home,"bar.terminal-follow-bar")
                        assert(!!follow,"Kitty follows bar control missing")
                        follow.triggered()
                        assert(config.terminalFollowBar && !config.barMatchKittyMaterial && !refraction.enabled,"Kitty does not follow the bar")
                        const terminalBrightness=find(home,"bar.terminal-brightness")
                        assert(!!terminalBrightness,"Kitty brightness control missing")
                        terminalBrightness.committed(.96)
                        assert(config.terminalBarBrightness===.96,"Kitty brightness not saved")
                        const terminalBrightnessReset=find(home,"bar.terminal-brightness.reset")
                        assert(!!terminalBrightnessReset,"Kitty brightness reset missing")
                        terminalBrightnessReset.clicked()
                        assert(config.terminalBarBrightness===1,"Kitty brightness reset failed")
                        terminalBrightness.committed(.96)
                        assert(String(theme.barSurface)===originalTint && config.barRefractionStrength===7.5,"following Kitty changes the liked bar")
                        assert(Catalog.search("Kitty acompanha").some(entry=>entry.id==="bar.terminal-follow-bar"),"follow bar search missing")
                        assert(terminalMaterial.ready && Math.abs(terminalMaterial.opacity-.47)<.0001,"Kitty material file not read")
                        match.triggered()
                        assert(!config.terminalFollowBar,"two inheritance directions enabled at once")
                        assert(config.barMatchKittyMaterial && config.barMaterial==="liquid" && config.barBlurEnabled,"matching mode does not enable the common material")
                        assert(!barRefraction.enabled,"independent refraction must explain the shared Kitty control")
                        assert(Math.abs(theme.barSurface.r-37/255)<.001 && Math.abs(theme.barSurface.a-.47)<.001,"bars do not follow actual Kitty colour and opacity")
                        assert(String(theme.independentBarSurface)===originalIndependentTint,"Kitty theme input feeds back into the matching bars")
                        assert(refraction.enabled,"matching bars must allow strength edits while Kitty is off")
                        terminalMaterial.apply("background #ff0000\nbackground_opacity nan\n")
                        assert(Math.abs(terminalMaterial.opacity-.47)<.0001,"invalid material replaced valid Kitty colours")
                        match.triggered()
                        assert(config.barMaterial===originalMaterial && String(theme.barSurface)===originalTint,"independent bar material not restored")
                        assert(barRefraction.enabled && config.barRefractionStrength===7.5,"own bar strength lost on leaving shared mode")
                        follow.triggered()
                        assert(config.terminalFollowBar && config.terminalRefraction===2.4,"independent Kitty strength lost")
                        follow.triggered()
                        assert(!config.terminalFollowBar && config.terminalRefraction===2.4,"leaving follow mode loses Kitty strength")
                        assert(Catalog.search("refração da barra").some(entry=>entry.id==="bar.refraction"),"bar refraction search missing")
                        infinite.triggered()
                        assert(!config.infiniteDesktopTopbarEnabled,"Infinite Desk option not saved")
                        assert(Catalog.search("kitty").some(entry=>entry.id==="bar.kitty-match"),"matching search missing")
                        assert(Catalog.search("molduras").some(entry=>entry.id==="bar.infinite-desktop-topbar"),"Infinite Desk search missing")
                    }
                    controller.setSettingsPage(destinations[test.step-1])
                } else if (test.step === destinations.length+1) {
                    for (const material of ["solid", "glass", "liquid", "liquid-glass"]) {
                        config.setValue("bar.material",material)
                        assert(home.liquidMaterial === (["liquid","liquid-glass"].includes(material)),"refraction follows bar material")
                        assert(home.blurMaterial === (material !== "solid"),"blur follows bar material")
                        assert(home.surfaceTint === theme.barSurface,"settings inherit bar tint and opacity")
                        if(material==="liquid-glass") {
                            assert(config.barRefractionStrength===1,"new glass inherits an excessive legacy refraction")
                            config.setValue(config.barRefractionKey,2.25)
                        }
                    }
                    config.setValue("appearance.reduceTransparency",true)
                    assert(!home.liquidMaterial && !home.blurMaterial && home.surfaceTint.a === 1,"reduced transparency suppresses optics")
                    config.setValue("appearance.reduceTransparency",false)
                    controller.setSettingsPage("wallpapers")
                    home.section="selector"
                } else if (test.step === destinations.length+2) {
                    assert(home.height === Math.min(840,window.height*.80),"right Settings keeps a stable height across categories")
                    assert(home.x > window.width*.25,"Settings is not docked on the right")
                    assert(Math.abs(home.x+home.width-window.width)<.01,"Settings leaves a margin at the right wall")
                    assert(home.y > 40 && home.y+home.height < window.height-18,"Settings is still attached to the bottom")
                    assert(home.y+home.height<=window.height,"adapted surface leaves the output")
                    const glass=find(home,"wallpaperSelectorGlassToggle")
                    assert(!!glass,"canonical glass toggle mounted")
                    beforeGlass=config.wallpaperSelectorGlassEnabled
                    glass.triggered()
                    assert(config.wallpaperSelectorGlassEnabled !== beforeGlass,"glass updates ConfigStore")
                    assert(controller.integrations.wallpaperSelectorGlassEnabled===config.wallpaperSelectorGlassEnabled,"adapter shares the same state")
                    controller.integrations.setWallpaperSelectorGlass(beforeGlass)
                    assert(config.wallpaperSelectorGlassEnabled===beforeGlass,"legacy operation updates same state")
                    config.setValue("appearance.reflection",0)
                    config.setValue("appearance.blurStrength",0)
                    controller.setSettingsPage("appearance")
                } else if (test.step === destinations.length+3) {
                    const manual=find(home,"Cor manual")
                    assert(!!manual,"manual palette preserved")
                    manual.triggered()
                    config.setCustomColor("text","#c0ffee")
                    controller.setSettingsPage("media"); home.section="velyrics"
                } else if (test.step === destinations.length+4) {
                    home.section="style"
                } else if (test.step === destinations.length+5) {
                    home.section="position"
                } else if (test.step === destinations.length+6) {
                    home.section="material"
                } else if (test.step === destinations.length+7) {
                    controller.setSettingsPage("appearance"); find(home,"appearanceGroup-sidebar").expanded=true
                } else if (test.step === destinations.length+8) {
                    controller.setSettingsPage("motion")
                    config.setValue("appearance.reducedMotion",false)
                } else if (test.step === destinations.length+9) {
                    assert(!home.animating,"animations settle")
                    home.contentItem.revealSetting("wallpaper.transition")
                } else if (test.step === destinations.length+10) {
                    assert(home.page === "wallpapers" && home.section === "main", "context link opens the unified wallpaper page")
                    controller.hide()
                } else if (test.step === destinations.length+11) {
                    assert(!controller.mounted,"close unmounts")
                    assert(!controller.integrations,"settings-only backend released")
                    controller.showLauncher()
                } else if (test.step === destinations.length+12) {
                    assert(home.launcherMode && !controller.integrations, "cold launcher constructs settings backend")
                    assert(!!find(home, "launcherQuery"), "cold launcher field missing")
                    controller.show("desktop")
                    controller.setSettingsPage("motion")
                    controller.setSettingsPage("wallpapers")
                } else if (test.step === destinations.length+13) {
                    assert(home.page==="wallpapers","rapid retarget final page")
                    assert(!home.animating,"retarget settles")
                    config.setValue("appearance.reducedMotion",true)
                } else if (test.step > destinations.length+13) {
                    if (searchIndex >= 0 && searchIndex < searchable.length) {
                        const result=searchable[searchIndex]
                        const target=home.findTarget(home.contentItem,result)
                            || (result.fallbackLabel && home.findTarget(home.contentItem,{label:result.fallbackLabel}))
                        if (!target) missingTargets.push(result.id)
                    }
                    searchIndex++
                    if (searchIndex < searchable.length) {
                        home.selectResult(searchable[searchIndex])
                        return
                    }
                    assert(missingTargets.length===0,"missing search targets: "+missingTargets.join(", "))
                    if (!config.barMatchKittyMaterial) {
                        config.setValue("bar.matchKittyMaterial",true)
                        return
                    }
                    if (config.savePending) return
                    if (home.page !== "appearance") {
                        controller.setSettingsPage("appearance")
                        return
                    }
                    if (launcherProbe === 0) {
                        launcherProbe = 1
                        assert(controller.showLauncher(), "launcher cannot open")
                        return
                    }
                    if (launcherProbe === 1) {
                        const query = find(home, "launcherQuery")
                        assert(home.launcherMode && !!query && query.activeFocus, "launcher field missing keyboard focus")
                        assert(!home.contentItem, "settings content remains active behind launcher")
                        assert(home.preferredWidth === 840 && home.preferredHeight === 500, "launcher loses settings-sized panel")
                        assert(home.y + home.height <= window.height, "bottom launcher leaves screen")
                        query.text = "velora-fixture-no-such-application-1234"
                        window.contentItem.grabToImage(result => {
                            const path = Quickshell.env("VELORA_LAUNCHER_SCREENSHOT")
                            if (path) result.saveToFile(path)
                        })
                        launcherProbe = 2
                        return
                    }
                    if (launcherProbe < 5) { launcherProbe++; return }
                    if (launcherProbe === 5) {
                        assert(find(home, "launcherResults").count === 0, "launcher search does not filter")
                        controller.show("desktop")
                        controller.setSettingsPage("appearance")
                        launcherProbe = 6
                        return
                    }
                    assert(!home.launcherMode && !!home.contentItem, "returning to settings leaves launcher active")
                    window.contentItem.grabToImage(result=> {
                        const path=Quickshell.env("VELORA_SETTINGS_SCREENSHOT")
                        if(path)result.saveToFile(path)
                        console.info("SETTINGS_REBUILD_OK",JSON.stringify({pages:destinations.length,reflection:config.reflectionStrength,blur:config.blurStrength,pending:config.savePending}))
                        Qt.quit()
                    })
                    running=false
                }
            } catch(error) { console.error("SETTINGS_REBUILD_FAILED",String(error),error.stack); Qt.quit() }
        }
    }
    Timer { interval: 23000; running: true; onTriggered: {console.error("SETTINGS_REBUILD_FAILED timeout");Qt.quit()} }
}
