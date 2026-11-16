import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../core" as Core
import "../../core/WidgetCatalog.js" as Catalog
import "../../services" as Services
import "../../features/editor" as Editor
import "../../features/widgets" as Widgets
import "../../platform" as Platform

ShellRoot {
    id: test
    Core.ConfigStore { id: testConfig }
    Core.Theme { id: testTheme; config: testConfig; palette: null }
    Core.Motion { id: testMotion; config: testConfig }
    Services.SceneEditorService { id: testEditor; config: testConfig }
    QtObject {
        id: controller
        function beginEditing(space) { testEditor.setEditSpace(space) }
        function chooseImage(index) { }
        function setSettingsPage(page) { }
    }
    QtObject {
        id: testTransition
        property real progress: 0
        property bool running: false
        function motionProgress(stagger) { return 0 }
        function staggeredProgress(stagger) { return 0 }
        function activity(stagger) { return 0 }
    }
    QtObject { id: profile; property bool transitioning: false; property int transitionDuration: 0 }
    QtObject { id: caustics; property real phase: 0 }
    QtObject {
        id: testClock
        property date now: new Date(2026,10,16,9,35)
        property string timeText: "09:35"
        property string dateText: "segunda-feira, 16 de novembro"
        function locale() { return Qt.locale("pt_BR") }
    }
    QtObject {
        id: testWeather
        property string temperature: "28"
        property string maximum: "30"
        property string minimum: "21"
        property string description: "Nublado"
        property string location: "São Paulo"
        property string iconName: "cloud"
        property var forecast: []
    }
    QtObject {
        id: testStatus
        property bool performanceAvailable: false
        property real cpuPercent: 0
        property real ramPercent: 0
        property real storagePercent: 0
        property real networkDownKbps: 0
        property real networkUpKbps: 0
        property bool hasBattery: false
        property real batteryLevel: 1
        property int batteryPercent: 100
        property bool batteryCharging: false
        property bool hasAudio: false
        property real volume: 0
        property int volumePercent: 0
    }
    QtObject {
        id: testMedia
        property bool hasPlayer: false
        property string title: ""
        property string artist: ""
        property string artUrl: ""
        property bool playing: false
        property bool canToggle: false
        property bool canPrevious: false
        property bool canNext: false
        property real progress: 0
        property int toggleCount: 0
        function togglePlaying() { toggleCount++; playing = !playing }
        function previous() { }
        function next() { }
    }
    Core.InfiniteDesktopCameraState { id: cameraState }
    Core.InfiniteDesktopCameraState { id: otherState }
    Platform.InfiniteDesktopCamera { id: cameraBridge }
    Window {
        id: window; width: 1600; height: 900; visible: true; color: "#18191c"
        Widgets.SharedWidgetsScene {
            id: scene; anchors.fill: parent
            infiniteDesktopEnabled: true
            camera: cameraState.views["DP-1"] || null
            config: testConfig; theme: testTheme; motion: testMotion; clock: testClock; weather: testWeather
            status: testStatus; media: testMedia; calendarService: null; transition: testTransition
            editor: testEditor; causticsClock: caustics; lockPresented: false
        }
        TestCase { id: input; when: false }
        // NATIVE_SHAPE_FIXTURE
    }
    function assert(value, message) { if (!value) throw new Error(message) }
    function near(a, b, message) { assert(Math.abs(a-b)<.001, message+": "+a+" != "+b) }
    function find(item, name) {
        if (item.objectName === name) return item
        for (const child of item.children || []) { const found=find(child,name); if (found) return found }
        return null
    }
    function pose(cx, cy, zoom, monitor) {
        return {monitor:monitor || "DP-1", active:true, workspace:1,
            zoom:zoom || 1, center:[cx,cy], origin:[0,0], viewport:[1600,900]}
    }
    function send(value) { assert(cameraState.readEvent("velora-infinite-camera>>"+JSON.stringify(value)), "event parsed") }
    property int step: 0
    property var basePos: []
    property var saved: null
    property string customId: ""
    property var customBase: null
    property double returnStarted: 0
    property bool returnChecked: false
    readonly property var cards: [scene.clockHitItem,scene.weatherHitItem,scene.mediaHitItem,
        scene.galleryHitItem,scene.systemHitItem,scene.batteryHitItem]
    Timer {
        interval: 130; running: true; repeat: true
        onTriggered: {
            if (!testConfig.ready) return
            try {
                if (step === 0) {
                    testConfig.setValue("appearance.reducedMotion", false)
                    testConfig.setValue("desktop.widgetsEnabled", true)
                    testConfig.setValue("lockPreview.sharedWidgets.surfaceMode", "bar")
                    testConfig.setValue("bar.material", "liquid")
                    for (const kind of ["clock","weather","media","gallery","system","battery"])
                        testConfig.setSharedWidgetVisibility(kind,true,false)
                    testConfig.setSceneLayers([], false)
                    testEditor.addText("Parallax")
                    customId = testEditor.selectedLayerId
                    testMedia.hasPlayer=true; testMedia.canToggle=true
                    send(pose(800,450))
                } else if (step === 1) {
                    basePos = cards.map(item => ({x:item.x,y:item.y,scale:item.scale}))
                    const custom=scene.dynamicHitItem(0)
                    customBase={x:custom.mapToItem(scene,0,0).x,y:custom.mapToItem(scene,0,0).y}
                    saved=JSON.stringify([testConfig.sharedWidgets,testConfig.sceneLayers])
                    assert(!cameraState.readEvent("other>>{}"),"unrelated ignored")
                    assert(!cameraState.readEvent("velora-infinite-camera>>invalid"),"malformed ignored")
                    assert(!cameraState.applyPose(pose(NaN,0)),"nonfinite ignored")
                    assert(!cameraState.applyPose(pose(0,0,10)),"zoom outside bounds ignored")
                    const wrong=pose(0,0); wrong.viewport=[0,900]
                    assert(!cameraState.applyPose(wrong),"invalid viewport ignored")
                    send(pose(600,550))
                } else if (step === 2) {
                    for(let i=0;i<cards.length;i++) {
                        near(cards[i].x-basePos[i].x,70,"all cards pan x")
                        near(cards[i].y-basePos[i].y,-35,"all cards pan y")
                        near(cards[i].scale,basePos[i].scale,"pan preserves size")
                    }
                    const point=scene.dynamicHitItem(0).mapToItem(scene,0,0)
                    near(point.x-customBase.x,70,"text layer pans x")
                    near(point.y-customBase.y,-35,"text layer pans y")
                    // Click the actual media control through its transformed parent.
                    const toggle=find(scene.mediaHitItem,"widgetMedia.toggle")
                    input.mouseClick(toggle,toggle.width/2,toggle.height/2)
                    assert(testMedia.toggleCount===1,"media click follows transformed widget")
                    send(pose(800,450,.5))
                } else if (step === 3) {
                    for(let i=0;i<cards.length;i++) {
                        near(cards[i].x,140+basePos[i].x*.825,"zoom x")
                        near(cards[i].y,78.75+basePos[i].y*.825,"zoom y")
                        near(cards[i].scale,basePos[i].scale*.825,"zoom depth")
                        const mapped=cards[i].mapToItem(scene,0,0)
                        near(mapped.x,cards[i].x,"native shape origin uses actual x")
                        near(mapped.y,cards[i].y,"native shape origin uses actual y")
                        const shape=window.nativeShape(cards[i],cards[i].currentRadius).split(" ").map(Number)
                        assert(shape[0]===1,"native liquid shape visible")
                        near(shape[1]*window.width,cards[i].x,"native glass x follows camera")
                        near(shape[2]*window.height,cards[i].y,"native glass y follows camera")
                        near(shape[3]*window.width,cards[i].width*cards[i].scale,"native glass scales once")
                    }
                    scene.infiniteDesktopEnabled=false
                    returnStarted=Date.now()
                    near(scene.parallaxX,140,"exit keeps the presented pose")
                } else if (step === 4) {
                    if (Date.now()-returnStarted<180) return
                    if (!returnChecked) {
                        assert(scene.parallaxX>0 && scene.parallaxX<140,"scene returns through intermediate positions")
                        assert(scene.parallaxScale>.825 && scene.parallaxScale<1,"scene returns through intermediate scales")
                        for (let i=0;i<cards.length;i++) {
                            near(cards[i].x,scene.parallaxX+basePos[i].x*scene.parallaxScale,"cards share return progress")
                            const shape=window.nativeShape(cards[i],cards[i].currentRadius).split(" ").map(Number)
                            near(shape[1]*window.width,cards[i].x,"glass follows return frame")
                        }
                        const point=scene.dynamicHitItem(0).mapToItem(scene,0,0)
                        near(point.x,scene.parallaxX+customBase.x*scene.parallaxScale,"text shares return progress")
                        returnChecked=true
                    }
                    if (Date.now()-returnStarted<800) return
                    near(scene.parallaxX,0,"return finishes at normal desktop")
                    near(scene.parallaxScale,1,"return restores original scale")
                    scene.editing=true
                    for(let i=0;i<cards.length;i++) near(cards[i].x,basePos[i].x,"editor uses saved position")
                    scene.editing=false
                    send(pose(600,550))
                    testConfig.setValue("appearance.reducedMotion",true)
                } else if (step === 5) {
                    near(scene.parallaxX,0,"reduced motion neutral")
                    scene.infiniteDesktopEnabled=false
                    testConfig.setValue("appearance.reducedMotion",false)
                } else if (step === 6) {
                    near(scene.parallaxX,0,"normal desktop neutral")
                    scene.infiniteDesktopEnabled=true
                    scene.lockPresented=true
                } else if (step === 7) {
                    near(scene.parallaxX,0,"lock neutral")
                    scene.lockPresented=false
                    testTransition.running=true
                } else if (step === 8) {
                    near(scene.parallaxX,0,"lock transition neutral")
                    testTransition.running=false
                    send(pose(-800,900,1,"DP-2"))
                } else if (step === 9) {
                    near(scene.parallaxX,70,"other monitor isolated")
                    send({monitor:"DP-1", active:false})
                    returnStarted=Date.now()
                } else if (step === 10) {
                    if (Date.now()-returnStarted<800) return
                    near(scene.parallaxX,0,"suspended workspace neutral")
                    send(pose(600,550))
                    scene.barOnRight=true
                } else if (step === 11) {
                    near(scene.parallaxX,70,"right rail keeps camera")
                    send(pose(-1120,450,1)); const changed=pose(-1120,450,1)
                    changed.origin=[-1920,0]; changed.viewport=[1600,900]; send(changed)
                } else if (step === 12) {
                    near(scene.parallaxX,0,"negative monitor origin gives identity")
                    scene.barOnRight=false
                    window.width=1200; window.height=1000
                    const identity=pose(600,500); identity.viewport=[1200,1000]; send(identity)
                } else if (step === 13) {
                    near(scene.parallaxX,0,"resized viewport identity")
                    near(scene.parallaxScale,1,"resized viewport neutral scale")
                    const p=pose(400,600); p.viewport=[1200,1000]; send(p)
                } else if (step === 14) {
                    near(scene.parallaxX,70,"fractional logical screen x")
                    near(scene.parallaxY,-35,"fractional logical screen y")
                    assert(saved===JSON.stringify([testConfig.sharedWidgets,testConfig.sceneLayers]),"parallax never saves camera into layout")
                    scene.editing=true
                    assert(cameraState.applySnapshot({widgetViews:[{monitor:"DP-2",active:false}]}),"snapshot accepted")
                    assert(!cameraState.views["DP-1"],"snapshot clears removed outputs")
                    near(scene.parallaxX,0,"missing camera fallback")
                    cameraState.clear()
                    assert(Object.keys(cameraState.views).length===0,"unload clears camera")
                    const baseline=otherState.views
                    otherState.applyPose(pose(600,450))
                    otherState.applySnapshot({widgetViews:[pose(800,450),pose(1600,450,1,"DP-2")]},baseline)
                    assert(otherState.views["DP-1"].center[0]===600,"late bootstrap preserves new events")
                    assert(otherState.views["DP-2"].center[0]===1600,"late bootstrap seeds idle outputs")
                    assert(Object.keys(cameraBridge.views).length===0,"missing plugin fallback loads without IPC")
                    console.info("WIDGET_PARALLAX_OK pan zoom click layers editor reduced-motion lock outputs persistence")
                    Qt.quit()
                }
                step++
            } catch(error) { console.error("WIDGET_PARALLAX_FAILED",String(error),error.stack); Qt.quit() }
        }
    }
    Timer { interval:12000; running:true; onTriggered:{ console.error("WIDGET_PARALLAX_FAILED timeout"); Qt.quit() } }
}
