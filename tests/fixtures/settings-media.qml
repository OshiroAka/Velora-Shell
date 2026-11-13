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

    TestCase { id: input; name: "MediaSettings"; when: false }
    property int phase: 0
    property int waitTicks: 0
    property real partialReveal: 0
    property int searchIndex: 0
    property var mediaResults: Catalog.entries.filter(entry=>entry.page==="media")
    property var missing: []
    function capture(name) {
        const directory=Quickshell.env("VELORA_MEDIA_PREVIEW_DIR")
        if (directory) window.contentItem.grabToImage(result=>result.saveToFile(directory+"/"+name+".png"))
    }
    function group(name) { return find(chrome.settingsItem,"mediaGroup-"+name) }
    function target(name) { return find(chrome.settingsItem,name) }
    function scrollTo(item) {
        const home=chrome.settingsItem, viewport=target("settingsViewport")
        const point=item.mapToItem(home.contentItem,0,0)
        viewport.contentY=Math.max(0,Math.min(point.y-12,viewport.contentHeight-viewport.height))
    }
    Timer {
        id: advance
        interval: phase>=11 ? 25 : 100; repeat: true; running: true
        onTriggered: {
            if (!config.ready) return
            try {
                const home=chrome.settingsItem
                if (phase===0) {
                    config.setValue("appearance.reducedMotion",true)
                    controller.show("desktop");controller.setSettingsPage("media")
                    phase++;return
                }
                if (phase===13) {
                    if (controller.integrations) return
                    console.info("MEDIA_SETTINGS_OK",JSON.stringify({search:mediaResults.length,missing:missing}))
                    Qt.quit()
                }
                if (!home || !home.contentItem || !group("audio")) return
                if (phase===1) {
                    assert(group("audio").expanded && !group("lyrics").expanded && !group("velyrics").expanded,"initial hierarchy")
                    assert(!!target("settingsInlineVolume") && !!target("settingsInlineMute"),"inline audio missing")
                    group("audio").contentItem.audioSink=null
                    assert(!target("settingsInlineVolume").enabled,"audio unavailable must disable controls")
                    assert(!target("legacy.reset"),"global reset exposed")
                    capture("overview")
                    group("audio").expanded=false;group("lyrics").expanded=true
                    phase++;return
                }
                if (phase===2) {
                    assert(group("playback").contentItem && !group("position").contentItem,"groups are not lazy")
                    const toggle=target("lyrics.enabled")
                    toggle.toggled();assert(historical.lyricsEnabled,"wallpaper enable lost")
                    target("Linha").forceActiveFocus();input.keyClick(Qt.Key_Space)
                    assert(historical.lyricsRevealMode==="line","keyboard selection lost")
                    assert(!target("Fade") && !target("Slide"),"unimplemented animation choices exposed")
                    const slider=target("lyrics.sync")
                    slider.valueRequested(125)
                    assert(historical.lyricsSyncOffsetMs===125,"sync setter lost")
                    assert(find(slider,"settingsSlider").width<=184,"slider is too wide")
                    capture("lyrics")
                    group("playback").expanded=false;group("layout").expanded=true
                    phase++;return
                }
                if (phase===3) {
                    target("4 lyrics").clicked();assert(historical.lyricsLayoutMode==="four","layout setter lost")
                    capture("layout")
                    group("layout").expanded=false;group("position").expanded=true
                    phase++;return
                }
                if (phase===4) {
                    target("Bloco 4").forceActiveFocus();input.keyClick(Qt.Key_Return)
                    target("lyrics.x").valueRequested(57)
                    assert(historical.lyricsFourthPositionX===57,"wrong block updated")
                    target("lyrics.rotation").valueRequested(23)
                    target("lyrics.transform-reset").clicked()
                    assert(historical.lyricsRotation===0 && historical.lyricsFourthPositionX===57 && historical.lyricsSyncOffsetMs===125,"transform reset spilled into other settings")
                    const x=target("lyrics.x"),y=target("lyrics.y")
                    assert(x.y===y.y && x.x!==y.x,"position fields did not compose in two columns")
                    scrollTo(group("position"));capture("position")
                    group("position").expanded=false;group("style").expanded=true
                    phase++;return
                }
                if (phase===5) {
                    assert(target("Bloco 4").active,"block selection lost on section change")
                    target("lyrics.font-size").valueRequested(92)
                    target("lyrics.opacity").valueRequested(.63)
                    const glowBefore=historical.lyricsGlowEnabled
                    target("lyrics.glow").toggled()
                    assert(historical.lyricsGlowEnabled!==glowBefore && historical.lyricsFontSize===92 && historical.lyricsOpacity===.63,"text setters lost")
                    scrollTo(group("style"));capture("style")
                    group("style").expanded=false;group("material").expanded=true
                    phase++;return
                }
                if (phase===6) {
                    target("Nuvem").clicked();target("lyrics.texture").valueRequested(.7)
                    assert(historical.lyricsMaterialMode==="cloud" && historical.lyricsMaterialIntensity===.7,"material setters lost")
                    scrollTo(group("material"));capture("material")
                    group("material").expanded=false;group("movement").expanded=true
                    phase++;return
                }
                if (phase===7) {
                    const before=historical.lyricsFloatEnabled
                    target("lyrics.float").toggled();assert(historical.lyricsFloatEnabled!==before,"movement setter lost")
                    group("lyrics").expanded=false;group("velyrics").expanded=true
                    phase++;return
                }
                if (phase===8) {
                    assert(controller.integrations.loadedDomains.velyrics,"terminal domain was not loaded on expansion")
                    target("velyrics.group").toggled()
                    assert(controller.integrations.velyricsMode==="words" && target("velyrics.words").visible,"terminal grouping lost")
                    target("velyrics.words").valueRequested(6)
                    assert(controller.integrations.velyricsWordsPerTerminal===6,"terminal word count lost")
                    scrollTo(group("velyrics"));capture("terminal")
                    window.width=800;window.height=600
                    phase++;return
                }
                if (phase===9) {
                    assert(home.compact,"small screen navigation")
                    const viewport=target("settingsViewport")
                    assert(viewport.contentWidth>=viewport.width && home.width<=window.width,"small screen bounds")
                    for(const item of [target("velyrics.sync"),target("velyrics.font-scale")])
                        assert(item.width>0 && find(item,"settingsSlider").width<=184,"small-screen slider bounds")
                    capture("compact")
                    window.width=1440;window.height=900
                    group("velyrics").expanded=false
                    config.setValue("appearance.reducedMotion",false)
                    group("lyrics").expanded=true
                    phase++;return
                }
                if (phase===10) {
                    assert(group("lyrics").reveal>0 && group("lyrics").reveal<1,"accordion expansion not animated")
                    partialReveal=group("lyrics").reveal
                    group("lyrics").expanded=false
                    assert(Math.abs(group("lyrics").reveal-partialReveal)<.01,"reversal jumps")
                    config.setValue("appearance.reducedMotion",true)
                    assert(group("lyrics").reveal===0,"reduced motion does not settle")
                    phase++;return
                }
                if (phase===11) {
                    if (searchIndex>=mediaResults.length) {
                        assert(!missing.length,"missing media search targets: "+missing.join(","))
                        controller.hide(true);phase=13;return
                    }
                    const result=mediaResults[searchIndex]
                    home.selectResult(result)
                    phase++;return
                }
                if (phase===12) {
                    if (home.pendingResult) {
                        if (++waitTicks<15) return
                        missing.push(mediaResults[searchIndex].id)
                    } else if (home.searchNotice.indexOf("depende do estado")>=0) missing.push(mediaResults[searchIndex].id)
                    waitTicks=0;searchIndex++;phase=11;return
                }

            } catch(error) { console.error("MEDIA_SETTINGS_FAILED",String(error),error.stack);Qt.quit() }
        }
    }
    Timer { interval: 23000; running: true; onTriggered: {console.error("MEDIA_SETTINGS_FAILED timeout",phase,searchIndex);Qt.quit()} }
}
