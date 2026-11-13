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
        property string currentPath: Quickshell.env("VELORA_SIDE_WALLPAPER") || ""
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
        property int oppositeFrameWidth: 4
        property var unifiedTheme: historical
        property var composition: null
        function openLyricsMaskEditor() { }
    }
    QtObject { id: wallpaperStore; property string activeKey: "fixture" }
    Core.SettingsController { id: controller; config: config; editor: scene; motion: motion; preview: preview; profileService: profiles; shell: shell }
    Window {
        id: window
        width: 1440; height: 900; visible: true; color: "#101113"
        Editor.EditorChrome {
            id: chrome; anchors.fill: parent; config: config; controller: controller; editor: scene
            theme: theme; motion: motion; profileService: profiles; wallpaperStore: wallpaperStore
            presented: controller.shown
        }
    }
    property int phase: 0
    property real poseWidth: 0
    property real poseHeight: 0
    property real rightEdge: 0
    property real poseReveal: 0
    property real stableWidth: 0
    property real stableHeight: 0
    property real stableViewportWidth: 0
    property real stableViewportHeight: 0
    property real stableX: 0
    property real stableY: 0
    property bool contentOverlapped: false
    property var firstContent: null
    property int ticks: 0
    property int screenshotWait: 0
    function assert(value, message) { if (!value) throw new Error(message) }
    function find(item, name) {
        if (!item) return null
        if (item.objectName === name || item.label === name) return item
        const list=item.children||[]
        for(let i=0;i<list.length;i++) { const result=find(list[i],name); if(result) return result }
        return null
    }
    Timer {
        id: advance
        interval: 30; running: true; repeat: true
        onTriggered: {
            if (!config.ready) return
            try {
                const home=chrome.settingsItem
                ticks++
                if (phase === 0) {
                    config.setValue("bar.material", "glass")
                    config.setValue("appearance.reducedMotion",false)
                    controller.show("desktop"); controller.setSettingsPage("system")
                    phase=1; return
                }
                if (phase === 1 && home.contentItem && home.reveal > .15 && home.reveal < .9) {
                    const sidebar=find(home,"settingsSidebar")
                    assert(sidebar && !sidebar.enabled,"opening accepts interaction before the morph settles")
                    const frame=find(home,"settingsContentFrame")
                    const viewport=find(home,"settingsViewport")
                    assert(frame.width>780 && !home.compact && home.width<780,"layout follows the growing surface instead of its final width")
                    stableWidth=frame.width;stableHeight=frame.height
                    stableViewportWidth=viewport.width;stableViewportHeight=viewport.height
                    const origin=frame.mapToItem(chrome,0,0);stableX=origin.x;stableY=origin.y
                    firstContent=home.contentItem
                    poseWidth=home.width; poseHeight=home.height
                    rightEdge=home.x+home.width
                    controller.hide()
                    assert(Math.abs(home.width-poseWidth)<.01,"closing jumps width")
                    poseReveal=home.reveal; phase=2; return
                }
                if (phase >= 2 && phase <= 3) {
                    const frame=find(home,"settingsContentFrame")
                    const viewport=find(home,"settingsViewport")
                    const origin=frame.mapToItem(chrome,0,0)
                    assert(Math.abs(frame.width-stableWidth)<.01 && Math.abs(frame.height-stableHeight)<.01,"content frame resizes during opening/reversal")
                    assert(Math.abs(viewport.width-stableViewportWidth)<.01 && Math.abs(viewport.height-stableViewportHeight)<.01,"scroll viewport reflows during the morph")
                    assert(Math.abs(origin.x-stableX)<.01 && Math.abs(origin.y-stableY)<.01,"content drifts while the surface expands")
                    assert(home.contentItem===firstContent,"reversal recreates the current page")
                    if (phase===3 && home.reveal<.999 && find(home,"settingsSidebar").opacity>.05) {
                        contentOverlapped=true
                        const loader=home.contentItem.parent
                        assert(Math.abs(loader.opacity-find(home,"settingsSidebar").opacity)<.01,"page content has a second entrance fade")
                        assert(loader.parent.opacity===1 && loader.parent.parent.opacity===1,"content opacity is multiplied by its ancestors")
                        let alpha=1
                        for(let item=find(home,"settingsWallpaperPreview"); item && item!==frame; item=item.parent) alpha*=item.opacity
                        assert(Math.abs(alpha-find(home,"settingsSidebar").opacity)<.01,"preview is hidden behind another page fade")
                    }
                }
                if (phase === 2 && home.reveal < poseReveal-.03) {
                    poseWidth=home.width
                    controller.show("desktop")
                    assert(Math.abs(home.width-poseWidth)<.01,"reopening jumps width")
                    phase=3; return
                }
                if (phase === 3 && !home.animating && home.reveal === 1) {
                    assert(contentOverlapped,"content waits for the entire expansion")
                    assert(find(home,"settingsSidebar").enabled,"settled panel does not accept interaction")
                    assert(home.x>window.width*.25,"Settings is not on the right")
                    assert(Math.abs(home.x+home.width-window.width)<.01,"Settings has a margin at the right wall")
                    assert(Math.abs(home.x+home.width-rightEdge)<1,"morph drifts from its right anchor")
                    assert(home.y>40 && home.y+home.height<window.height-18,"Settings remains attached to the bottom")
                    assert(!!find(home,"settingsWallpaperPreview"),"System preview missing")
                    assert(!!find(home,"settingsNav-system") && !!find(home,"settingsNav-language"),"vertical navigation incomplete")
                    poseWidth=home.width;poseHeight=home.height
                    home.navigate("language"); phase=4; return
                }
                if (phase === 4 && home.page === "language" && !home.animating) {
                    assert(Math.abs(home.width-poseWidth)<1 && Math.abs(home.height-poseHeight)<1,"category switch resizes the side panel")
                    home.searchText="resolução"
                    assert(home.searchResults.some(result=>result.page==="system"),"global settings search missing")
                    home.selectResult(home.searchResults[0]);phase=5;return
                }
                if (phase === 5 && home.page === "system" && !home.animating) {
                    config.setValue("appearance.reducedMotion",true)
                    controller.hide()
                    assert(home.reveal===0 && !home.animating,"reduced motion retains animation")
                    window.width=800;window.height=600
                    controller.show("desktop");phase=6;return
                }
                if (phase === 6 && controller.shown) {
                    assert(home.compact,"narrow layout lacks icon rail")
                    assert(home.x>=0 && home.x+home.width<=window.width,"narrow Settings exceeds screen width")
                    assert(home.y>=40 && home.y+home.height<=window.height,"narrow Settings exceeds screen height")
                    assert(find(home,"settingsViewport").width>350,"narrow content is unusable")
                    window.width=1586;window.height=992
                    controller.showLauncher(); phase=7;return
                }
                if (phase === 7 && home.launcherMode) {
                    assert(home.preferredWidth===840 && home.preferredHeight===500,"launcher size changed")
                    assert(home.y+home.height>=window.height-20,"launcher left the bottom")
                    assert(!home.contentItem,"launcher retains Settings content")
                    controller.show("desktop");controller.setSettingsPage("system");phase=8;return
                }
                if (phase === 8 && !home.launcherMode && !home.animating && home.contentItem) {
                    const artwork=find(home,"settingsOverviewArtwork")
                    if (wallpaper.currentPath && artwork && artwork.status!==Image.Ready && screenshotWait++<40) return
                    if (wallpaper.currentPath) assert(artwork && artwork.status===Image.Ready,"wallpaper preview did not decode")
                    const target=Quickshell.env("VELORA_SIDE_SCREENSHOT")
                    window.contentItem.grabToImage(result=> {
                        if (target) result.saveToFile(target)
                        console.info("SETTINGS_SIDE_OK");Qt.quit()
                    })
                    running=false
                }
                if (ticks>160) throw new Error("phase "+phase+" did not complete")
            } catch(error) { console.error("SETTINGS_SIDE_FAILED",String(error),error.stack);Qt.quit() }
        }
    }
    Timer { interval: 12000;running:true;onTriggered:{console.error("SETTINGS_SIDE_FAILED timeout");Qt.quit()} }
}
