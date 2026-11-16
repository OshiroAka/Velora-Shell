import QtQuick
import QtQuick.Window
import QtTest
import "../../features/topbar" as Topbar
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
        property var infiniteDesktopPanels: ({})
        property bool infiniteDesktopMorphing: false
        property var importedUrls: []
        function importTopWallpaperUrls(urls) { importedUrls = urls; return true }
        function openLyricsMaskEditor() { }
    }
    QtObject { id: wallpaperStore; property string activeKey: "fixture" }
    Core.SettingsController { id: controller; config: config; editor: scene; motion: motion; preview: preview; profileService: profiles; shell: shell }
    QtObject { id: environment; property var screen: Quickshell.screens[0]; property real width: window.width; property var activeToplevel: null }
    Services.ClockService { id: clock }
    QtObject {
        id: status
        property bool hasBattery: true
        property real batteryLevel: .64
        property int batteryPercent: 64
        property bool batteryCharging: false
        property bool muted: false
        property real volume: .5
        property bool wifiConnected: false
        property bool wifiEnabled: false
        function toggleMuted() { }
        function adjustVolume(delta) { }
    }
    QtObject {
        id: system
        property string oneThing: "Fixture"
        property int wifiStrength: 0
        function newNote() { throw new Error("note created during editing") }
    }
    QtObject {
        id: weather
        property bool available: false
        property string iconName: "partly"
        property int temperature: 20
    }
    QtObject {
        id: media
        property bool playing: false
        property bool hasPlayer: false
        property string title: ""
        function togglePlaying() { }
    }
    QtObject {
        id: timerService
        property bool finished: false
        property var countdown: ({running:false})
        property int duration: 1500000
        property bool engaged: false
        property string barText: "25:00"
        property string timerText: "25:00"
    }
    QtObject {
        id: panels
        property var owner: null
        property string activeType: ""
        property var blockedItem: null
        property int hoverEntries: 0
        function close() { }
        function enter(type,item,host) { hoverEntries++ }
        function leave(item) { }
        function registerItem(type,item,host) { }
        function unregisterItem(item) { }
        function toggle(type,item,host) { throw new Error("popup opened during editing") }
    }
    QtObject {
        id: actions
        function openSettings() { throw new Error("settings opened during drag") }
        function openNetworkSettings() { }
        function openMusic() { }
    }
    Window {
        id: window
        width: 1440; height: 900; visible: true; color: "#101113"
        TestCase { id: pointer; name: "DesktopEditorPointer"; when: false }
        Topbar.ReferenceBar {
            id: bar; width: morphWidth
            x: (parent.width-width)/2; height: 40; z: 100
            config: config; theme: theme; clock: clock; media: media; weather: weather
            status: status; system: system; timerService: timerService
            actions: actions; controller: panels; editorController: controller
            compositor: environment; host: environment; wavePhase: 0
            shell: shell
        }
        Components.VeloraBarV2 {
            id: verticalBar
            property bool fixtureAppsVisible: false
            function collectRunningApps() {
                return fixtureAppsVisible ? ["Spotify", "Terminal", "Música"].map((name,index)=>({
                    key: name, appClass: name, entry: null, count: index===1 ? 2 : 1,
                    target: {title:name}, windows: [], active:false
                })) : []
            }
            x: 0; y: 40; width: 63; height: parent.height - 40
            theme: historical; reducedIconMotion: true; shellDrawsPanelSurface: true
            itemBubblesEnabled: config.barItemBubblesEnabled
            itemBubblesSolid: config.barItemBubblesSolid
            itemBubblesLiquid: config.barItemBubblesLiquid
            visualizerActive: false
        }
        Editor.EditorChrome {
            id: chrome; anchors.fill: parent; config: config; controller: controller; editor: scene
            theme: theme; motion: motion; profileService: profiles; wallpaperStore: wallpaperStore
            presented: controller.shown
        }
    }
    property int editorEntryWaits: 0
    property bool resized: false
    property int phase: 0
    property bool stepping: false
    Component { id: opticsType; Components.BarBubbleOptics {} }
    property var opticsProbe: null
    property string opticsBefore: ""
    property real originalX: 0
    property real targetX: 0
    property double weatherDropAt: 0
    function assert(value, message) { if (!value) throw new Error(message) }
    function find(item, name) {
        if (!item) return null
        if (item.objectName === name) return item
        for (const child of item.children||[]) { const result=find(child,name);if(result)return result }
        return null
    }
    function center(item) { return item.mapToItem(bar,item.width/2,0).x }
    function textLabel(item) {
        if (item.currentText !== undefined && item.visible) return item
        for (const child of item.children||[]) { const found=textLabel(child); if (found) return found }
        return null
    }
    function bubbles(item, result) {
        result = result || []
        if (item.objectName === "barItemBubble" || item.objectName.startsWith("barGroupBubble-")) result.push(item)
        for (const child of item.children || []) bubbles(child, result)
        return result
    }
    Timer {
        interval: 180; running: true; repeat: true
        onTriggered: {
            if (!config.ready || stepping) return
            stepping=true
            try {
                const home=chrome.settingsItem
                if (phase===0) {
                    if (Quickshell.env("VELORA_EDITOR_RELOAD")==="1") {
                        assert(config.topbarToolsOrder[0]==="timer","tool order lost on restart")
                        assert(config.topbarLayout.find(item=>item.type==="weather").section==="left","section lost on restart")
                        assert(config.infiniteTopbarToolsOrder[config.infiniteTopbarToolsOrder.length-1]==="thing","Infinite Desk order lost on restart")
                        assert(config.infiniteTopbarLayout.find(item=>item.type==="weather").section==="left","Infinite Desk section lost on restart")
                        assert(config.barItemBubblesEnabled,"bubble choice lost on restart")
                        assert(!config.barBackgroundEnabled,"background choice lost on restart")
                        assert(config.barItemBubblesSolid,"solid bubble choice lost on restart")
                        console.info("DESKTOP_EDITOR_OK reload");Qt.quit();return
                    }
                    config.setValue("appearance.reducedMotion",true)
                    assert(!bar.packed && bar.width===window.width && bar.x===0,"standard topbar lost its full-width layout")
                    assert(bar.legacyItemWidth("workspaces")===208*bar.unit && bar.rightInset===20,"standard topbar spacing changed")
                    const standardBounds=JSON.stringify(bar.sectionBounds)
                    const standardLayout=JSON.stringify(config.topbarLayout)
                    const standardOrder=JSON.stringify(config.topbarToolsOrder)
                    const packedWidth=bar.packedWidth
                    for (const progress of [.1,.25,.49,.5,.51,.75]) {
                        bar.desktopMorphProgress=progress
                        pointer.wait(16)
                        assert(Math.abs(bar.packedWidth-packedWidth)<.1,"destination width changed while switching item models")
                        const expected=window.width+(Math.min(window.width,packedWidth)-window.width)*progress
                        assert(Math.abs(bar.width-expected)<.1,"topbar geometry jumped during the morph")
                    }
                    bar.desktopMorphProgress=1
                    pointer.wait(25)
                    assert(bar.width < window.width && bar.x > 0,"topbar must detach from both screen edges")
                    assert(Math.abs(bar.x+bar.width/2-window.width/2)<1,"the entire topbar must stay centred")
                    assert(bar.sectionBounds.center.x===bar.sectionBounds.left.x+bar.sectionBounds.left.width,"sections must stay adjacent")
                    assert(bar.sectionBounds.right.x===bar.sectionBounds.center.x+bar.sectionBounds.center.width,"right tools must follow the other items")
                    for (const type of ["clock"]) {
                        const slot=find(bar,"topbarTool-"+type)
                        const label=textLabel(slot)
                        assert(label && slot.width>=label.implicitWidth+20,"text lost the minimum internal padding: "+type)
                    }
                    assert(!bar.visibleTools.some(type=>["battery","paint","monitor","controls","timer"].includes(type)),"Infinite Desk duplicates bottom controls in the topbar")
                    bar.beginDrag("thing",find(bar,"topbarTool-thing"),0)
                    bar.dragTo=bar.visibleTools.indexOf("clock")
                    bar.finishDrag()
                    const weatherId=config.infiniteTopbarLayout.find(item=>item.type==="weather").id
                    bar.layoutDragId=weatherId;bar.layoutDropSection="left";bar.layoutBeforeId=""
                    bar.finishLayoutDrag()
                    assert(config.infiniteTopbarToolsOrder[config.infiniteTopbarToolsOrder.length-1]==="thing","Infinite Desk reorder failed")
                    assert(JSON.stringify(config.topbarLayout)===standardLayout && JSON.stringify(config.topbarToolsOrder)===standardOrder,"Infinite Desk editing changed the standard bar")
                    bar.desktopMorphProgress=0
                    pointer.wait(25)
                    assert(JSON.stringify(bar.sectionBounds)===standardBounds && bar.width===window.width,"leaving Infinite Desk did not restore the standard bar")
                    const weatherTrigger=find(bar,"topbarWeatherTrigger")
                    const drop=find(weatherTrigger,"weatherWallpaperDropArea")
                    assert(drop.enabled,"weather must accept downloaded wallpapers outside editing")
                    drop.filesDropped(["file:///Downloads/wallpaper.jpg"])
                    assert(shell.importedUrls[0]==="file:///Downloads/wallpaper.jpg","weather drop lost its import route")
                    assert(panels.blockedItem===weatherTrigger,"weather hover must not replace the imported-file picker")
                    assert(!config.barItemBubblesEnabled,"bubbles must be optional by default")
                    assert(bubbles(bar).every(item=>!item.shown) && bubbles(verticalBar).every(item=>!item.shown),"bubbles visible while disabled")
                    const broken=config.clone(config.topbarLayout)
                    broken.find(item=>item.type==="weather").section="right"
                    config.setTopbarLayout(broken)
                    assert(config.topbarLayout.find(item=>item.type==="weather").section==="center","lost weather was not recovered")
                    controller.show("desktop");controller.setSettingsPage("desktop")
                } else if (phase===1) {
                    assert(home.page==="appearance" && !find(home,"settingsNav-desktop"),"editor must live in Appearance")
                    const entry=find(home,"scene.enter-desktop")
                    if (!entry && editorEntryWaits++ < 12) return
                    assert(!!entry,"editor entry missing")
                    pointer.mouseClick(entry,20,20,Qt.LeftButton)
                } else if (phase===2) {
                    assert(controller.mode==="editing" && bar.editing,"editor entry does not activate actual bar editing")
                    const toolbar=chrome.toolBarItem
                    const surface=find(toolbar,"editorToolbarSurface")
                    assert(toolbar.y+toolbar.height===window.height-shell.bottomBarHeight,
                        "editor toolbar is detached from the bottom frame")
                    assert(surface && surface.visible && surface.tint.toString()===home.surfaceTint.toString(),
                        "editor fallback does not share the bar material")
                    assert(surface.rim.toString()==="#00000000","editor adds a rim across the frame join")
                    for (const side of [true,false]) {
                        shell.barOnRight=side
                        for (const inset of [4,16,32]) {
                            shell.bottomBarHeight=inset
                            assert(toolbar.y+toolbar.height===window.height-inset,
                                "editor join gained a margin after frame geometry changed")
                        }
                    }
                    shell.bottomBarHeight=18
                    toolbar.nativeConnected=true
                    assert(!surface.visible,"editor draws a second surface over the shared native material")
                    toolbar.nativeConnected=false
                    assert(!find(find(bar,"topbarWeatherTrigger"),"weatherWallpaperDropArea").enabled,
                        "reordering the bar must not import a file")
                    originalX=center(find(bar,"topbarTool-timer"))
                    targetX=center(find(bar,"topbarTool-notes"))+2
                    pointer.mousePress(bar,originalX,20,Qt.LeftButton)
                    pointer.mouseMove(bar,targetX,20,20)
                    assert(bar.dragTo===2,"right drag compares different coordinate spaces")
                    assert(bar.displacement(1,"thing")<0 && bar.displacement(2,"notes")<0,"neighbors do not make room")
                    assert(bar.displacement(3,"battery")===0,"unrelated neighbor moved")
                    pointer.mouseMove(bar,originalX,20,20)
                    assert(bar.dragTo===bar.dragFrom && bar.displacement(1,"thing")===0,"cannot return a held item to its original position")
                    pointer.mouseMove(bar,targetX,20,20)
                    pointer.mouseRelease(bar,targetX,20,Qt.LeftButton)
                    assert(config.topbarToolsOrder.indexOf("timer")===2,"right drop did not persist")
                } else if (phase===3) {
                    const timer=find(bar,"topbarTool-timer"), last=find(bar,"topbarTool-clock")
                    originalX=center(timer);targetX=center(last)+2
                    pointer.mouseDrag(bar,originalX,20,targetX-originalX,0,Qt.LeftButton,Qt.NoModifier,20)
                    assert(config.topbarToolsOrder[config.topbarToolsOrder.length-1]==="timer","drop at last slot failed")
                } else if (phase===4) {
                    const timer=find(bar,"topbarTool-timer"), first=find(bar,"topbarTool-thing")
                    originalX=center(timer);targetX=center(first)-2
                    pointer.mouseDrag(bar,originalX,20,targetX-originalX,0,Qt.LeftButton,Qt.NoModifier,20)
                    assert(config.topbarToolsOrder[0]==="timer","cannot move right tool back from the end")
                } else if (phase===5) {
                    originalX=center(find(bar,"topbarItem-bar-context"))
                    targetX=center(find(bar,"topbarItem-bar-workspaces"))-2
                    pointer.mousePress(bar,originalX,20,Qt.LeftButton)
                    pointer.mouseMove(bar,targetX,20,20)
                    assert(bar.layoutDisplacement("bar-workspaces","left")>0,"left neighbors do not open a slot")
                    pointer.mouseMove(bar,originalX,20,20)
                    assert(bar.layoutDisplacement("bar-workspaces","left")===0,"left drag cannot reverse before release")
                    pointer.mouseMove(bar,targetX,20,20)
                    pointer.mouseRelease(bar,targetX,20,Qt.LeftButton)
                    assert(config.topbarItemsForSection("left",false)[0].id==="bar-context","left drag did not persist")
                } else if (phase===6) {
                    originalX=center(find(bar,"topbarWeatherTrigger"))
                    targetX=center(find(bar,"topbarItem-bar-context"))-2
                    pointer.mouseDrag(bar,originalX,20,targetX-originalX,0,Qt.LeftButton,Qt.NoModifier,20)
                    assert(config.topbarLayout.find(item=>item.type==="weather").section==="left","cross-section drag failed")
                } else if (phase===7) {
                    const view=find(bar,"topbarRightToolsViewport")
                    if (!resized) { window.width=800;resized=true;return }
                    view.contentX=30
                    originalX=center(find(bar,"topbarTool-notes"))
                    pointer.mousePress(bar,originalX,20,Qt.LeftButton)
                    pointer.mouseMove(bar,originalX-2,20,20)
                    assert(bar.dragTo===bar.dragFrom,"scrolled viewport changes the drag destination")
                    pointer.keyClick(Qt.Key_Escape)
                    pointer.mouseRelease(bar,originalX-2,20,Qt.LeftButton)
                    assert(bar.dragType==="","escape leaves a grabbed tool")
                    view.contentX=0
                    originalX=center(find(bar,"topbarTool-timer"))
                    const edgeX=view.x+view.width-4
                    pointer.mousePress(bar,originalX,20,Qt.LeftButton)
                    pointer.mouseMove(bar,edgeX,20,20)
                    const beforeScroll=view.contentX
                    pointer.wait(70)
                    assert(view.contentX>beforeScroll,"dragging to an overflowing edge does not scroll")
                    assert(Math.abs(center(find(bar,"topbarTool-timer"))-edgeX)<1,"scrolling pulls the grabbed icon away from the pointer")
                    pointer.keyClick(Qt.Key_Escape)
                    pointer.mouseRelease(bar,edgeX,20,Qt.LeftButton)
                    controller.returnToSettings();controller.setSettingsPage("appearance")
                } else if (phase===8) {
                    const group=find(home,"appearanceGroup-bar")
                    group.expanded=true
                    for (const name of ["material","icons","items","behavior","image","terminal"]) {
                        const child=find(home,"barGroup-"+name)
                        assert(!!child && !child.expanded && !child.contentItem,"bar subgroup mounts content while collapsed")
                    }
                    find(home,"barGroup-icons").expanded=true
                } else if (phase===9) {
                    const opacity=find(home,"bar.icon-opacity")
                    assert(!!opacity && !find(home,"legacy.menu-position"),"retired menu still mounted")
                    opacity.edited(.3)
                    assert(Math.abs(historical.barIconOpacity-.3)<.001,"sidebar opacity control failed")
                    find(home,"bar.icon-opacity.reset").clicked()
                    assert(Math.abs(historical.barIconOpacity-.8)<.001,"individual reset failed")
                    const toggle=find(home,"bar.item-bubbles")
                    assert(!!toggle && !find(home,"appearanceGroup-sidebar"),"bar options remain separated")
                    home.selectResult(Catalog.search("balões")[0])
                } else if (phase===10) {
                    window.width=1440;window.height=900
                    const toggle=find(home,"bar.item-bubbles")
                    if (!config.barItemBubblesEnabled) { toggle.forceActiveFocus(); pointer.keyClick(Qt.Key_Space) }
                    assert(config.barItemBubblesEnabled,"unified bubble switch failed")
                    const solid = find(home,"bar.item-bubbles-solid")
                    assert(solid && solid.enabled,"solid bubble switch unavailable")
                    solid.forceActiveFocus(); pointer.keyClick(Qt.Key_Space)
                    assert(config.barItemBubblesSolid,"solid bubble switch failed")
                    const liquid=find(home,"bar.item-bubbles-liquid")
                    assert(liquid && liquid.enabled,"Liquid Ass bubble switch unavailable")
                    liquid.forceActiveFocus(); pointer.keyClick(Qt.Key_Space)
                    assert(config.barItemBubblesLiquid && !config.barItemBubblesSolid,"Liquid Ass does not disable solid bubbles")
                    solid.forceActiveFocus(); pointer.keyClick(Qt.Key_Space)
                    assert(config.barItemBubblesSolid && !config.barItemBubblesLiquid,"Solid bubbles do not disable Liquid Ass")
                    const controls = find(bar,"barGroupBubble-controls")
                    const apps = find(verticalBar,"barGroupBubble-appToolsColumn")
                    const utilities = find(verticalBar,"barGroupBubble-utilitiesColumn")
                    assert(controls && controls.shown && controls.width>130,"horizontal controls do not share one bubble")
                    assert(apps && apps.shown && apps.height>100 && utilities && utilities.shown && utilities.height>160,"vertical tools do not share group bubbles")
                    for (const type of ["timer","thing","battery","paint","monitor","controls"]) {
                        assert(!find(find(bar,"topbarTool-"+type),"barItemBubble").shown,"double bubble behind existing surface or grouped icon: "+type)
                    }
                    assert(find(bar,"barExistingBubble-timer").height===28 && find(bar,"barExistingBubble-message").height===28,"existing surfaces are not enhanced")
                    const verticalIndividual=bubbles(verticalBar).filter(item=>item.objectName==="barItemBubble")
                    assert(verticalIndividual.length===1,"individual bubbles remain on grouped icons or profile")
                    assert(!find(verticalBar,"barGroupBubble-openApplications").shown,"empty app group shows a balloon")
                    verticalBar.fixtureAppsVisible = true
                    const before=config.clone(config.topbarToolsOrder)
                    config.moveTopbarTool("timer","monitor")
                    assert(bar.controlBubbleRuns().length===2,"separate icon runs were merged across an unrelated tool")
                    config.setValue("topbar.toolsOrder",before)
                    historical.applyBarAppearance(56,.6,24,false,16,false)
                    assert(Math.abs(bar.unit-56/48)<.001 && Math.abs(bar.iconOpacity-.6)<.001 && bar.itemGap===6,"standard icon settings do not reach horizontal items")
                    assert(config.infiniteTopbarToolsOrder[config.infiniteTopbarToolsOrder.length-1]==="thing","standard editing changed the Infinite Desk order")
                    assert(Math.abs(verticalBar.configuredIconOpacity-.6)<.001,"icon settings do not reach vertical items")
                    historical.applyBarAppearance(48,.8,16,false,16,false)
                } else if (phase===11) {
                    const applications=find(verticalBar,"barGroupBubble-openApplications")
                    assert(applications.shown && applications.height>110,"running apps do not share one group balloon")
                    const path=Quickshell.env("VELORA_EDITOR_SCREENSHOT")
                    if(path) window.contentItem.grabToImage(result=>result.saveToFile(path))
                    find(bar,"barGroupBubble-controls").monitorName="fixture-screen"
                    opticsProbe=opticsType.createObject(window.contentItem,{bubble:find(bar,"barGroupBubble-controls")})
                    assert(!!opticsProbe,"bubble optics tracker cannot be instantiated")
                } else if (phase===12) {
                    assert(opticsProbe.lastMessage.startsWith("velora-blur:bar-bubble-liquid fixture-screen topbar "),"bubble optics did not publish its explicit monitor and layer")
                    opticsBefore=opticsProbe.lastMessage
                    find(bar,"barGroupBubble-controls").opacity=.6
                    const icons = find(home,"barGroup-icons")
                    icons.expanded = false
                    assert(!icons.contentItem,"collapsed group retains its controls")
                    home.selectResult(Catalog.search("balões")[0])
                } else if (phase===13) {
                    assert(opticsProbe.lastMessage!==opticsBefore,"bubble optics ignores foreground opacity changes")
                    opticsProbe.destroy(); opticsProbe=null
                    const icons = find(home,"barGroup-icons")
                    assert(icons.expanded && !!find(home,"bar.item-bubbles"),"search does not expand the compact group")
                    const sample=find(bar,"barGroupBubble-controls")
                    const oldTint=theme.accent
                    for (const material of ["solid","glass","liquid","liquid-glass"]) {
                        config.setValue("bar.material",material)
                        for (const tint of ["#ee7744","#44aadd"]) {
                            theme.accent=tint
                            const expected=Qt.tint(Qt.rgba(theme.barSurface.r,theme.barSurface.g,theme.barSurface.b,1),
                                Qt.rgba(theme.accent.r,theme.accent.g,theme.accent.b,.16))
                            assert(sample.solid && sample.bubbleColor.a===1,"bar material affects solid bubble opacity")
                            assert(Math.abs(sample.bubbleColor.r-expected.r)<.005 && Math.abs(sample.bubbleColor.b-expected.b)<.005,
                                "solid bubble ignores the theme palette")
                        }
                    }
                    theme.accent=oldTint
                    for (const bubble of bubbles(bar).concat(bubbles(verticalBar)).filter(item=>item.visible)) {
                        assert(bubble.radius <= 7, "bubble corners remain pill-shaped")
                        assert(bubble.solid && bubble.bubbleColor.a===1,"solid choice does not reach both bar legs")
                    }
                    find(home,"barGroup-material").expanded=true
                    icons.expanded = false
                    find(home,"settingsViewport").contentY = 0
                } else if (phase===14) {
                    const background=find(home,"bar.background")
                    assert(background && config.barBackgroundEnabled,"background switch unavailable")
                    background.forceActiveFocus(); pointer.keyClick(Qt.Key_Space)
                    assert(!config.barBackgroundEnabled,"background switch failed")
                    const path=Quickshell.env("VELORA_EDITOR_SCREENSHOT")
                    if(path) window.contentItem.grabToImage(result=>result.saveToFile(path+".compact.png"))
                } else if (phase===15) {
                    find(home,"barGroup-items").expanded = true
                    home.selectResult(Catalog.entries.find(entry=>entry.id==="bar.message-visible"))
                } else if (phase===16) {
                    const grid=find(home,"barItemsGrid")
                    assert(!!grid && grid.columns>=2,"bar items retain a full-width vertical list")
                    const message=find(home,"topbarMessageToggle")
                    const toggle=message.children.find(item=>item.label==="Mensagem")
                    assert(toggle && toggle.width<230,"toggle remains distant from its label")
                    const before=config.topbarOneThingEnabled
                    pointer.mouseClick(toggle,toggle.width-18,18,Qt.LeftButton)
                    assert(config.topbarOneThingEnabled!==before,"compact toggle cannot be clicked")
                    toggle.triggered()
                    const path=Quickshell.env("VELORA_EDITOR_SCREENSHOT")
                    if(path) window.contentItem.grabToImage(result=>result.saveToFile(path+".items.png"))
                } else if (phase===17) {
                    if(config.savePending)return
                    controller.hide(true)
                    const weatherTrigger=find(bar,"topbarWeatherTrigger")
                    const drop=find(weatherTrigger,"weatherWallpaperDropArea")
                    drop.filesDropped(["file:///Downloads/another-wallpaper.mp4"])
                    const cooldown=pointer.findChild(weatherTrigger,"weatherWallpaperDropCooldown")
                    assert(cooldown.running && cooldown.interval===5000,"weather needs a five-second wait after a drop")
                    panels.hoverEntries=0
                    weatherDropAt=Date.now()
                    pointer.mouseMove(bar,center(weatherTrigger),20)
                    assert(panels.hoverEntries===0,"weather reopened immediately after dropping")
                } else if (phase===18) {
                    const elapsed=Date.now()-weatherDropAt
                    const cooldown=pointer.findChild(find(bar,"topbarWeatherTrigger"),"weatherWallpaperDropCooldown")
                    if (elapsed<4900) {
                        assert(cooldown.running && panels.hoverEntries===0,"weather ignored the five-second wait")
                        return
                    }
                    if (cooldown.running) return
                    assert(panels.hoverEntries===1,"weather must resume hover after five seconds")
                    console.info("DESKTOP_EDITOR_OK");Qt.quit()
                }
                phase++
            } catch(error) {console.error("DESKTOP_EDITOR_FAILED",String(error),error.stack);Qt.quit()}
            finally { stepping=false }
        }
    }
    Timer {interval:12000;running:true;onTriggered:{console.error("DESKTOP_EDITOR_FAILED timeout");Qt.quit()}}
}
