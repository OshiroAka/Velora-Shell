import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../core" as Core
import "../../core/WidgetCatalog.js" as Catalog
import "../../services" as Services
import "../../features/editor" as Editor
import "../../features/widgets" as Widgets

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
    Window {
        id: window; width: 1000; height: 1500; visible: true; color: "#18191c"
        Editor.SettingsWidgets {
            id: settings; x: 20; y: 20; width: window.width - 40
            config: testConfig; theme: testTheme; motion: testMotion; editor: testEditor; controller: controller
        }
        Widgets.SharedWidgetsScene {
            id: scene; x: 2000; width: 1600; height: 900
            config: testConfig; theme: testTheme; motion: testMotion; clock: testClock; weather: testWeather
            status: testStatus; media: testMedia; calendarService: null; transition: testTransition
            editor: testEditor; profileService: profile; causticsClock: caustics; lockPresented: false
        }
        TestCase { id: input; when: false }
    }
    function assert(value, message) { if (!value) throw new Error(message) }
    function find(item, name) {
        if (item.objectName === name) return item
        for (const child of item.children || []) { const found = find(child,name); if (found) return found }
        return null
    }
    property int step: 0
    property bool working: false
    property var before: null
    Timer {
        interval: 200; running: true; repeat: true
        onTriggered: {
            if (!testConfig.ready || working) return
            working = true
            try {
                const reload = Quickshell.env("VELORA_WIDGET_RELOAD") === "1"
                if (step === 0) {
                    assert(!testConfig.error.length, "valid old/new config: " + testConfig.error)
                    assert(testConfig.sharedWidgets.length === 7, "optional battery normalized")
                    assert(testConfig.sharedWidgetByKind("clock").desktop.x === 120, "legacy position preserved")
                    assert(testConfig.sharedWidgetByKind("clock").desktop.y === 112, "legacy y preserved")
                    if (!reload) assert(!testConfig.sharedWidgetByKind("battery").desktopEnabled, "new battery is opt in")
                    if (reload) {
                        assert(testConfig.sharedWidgetByKind("clock").variantId === "analog", "clock choice survives restart")
                        assert(testConfig.sharedWidgetByKind("weather").variantId === "forecast", "weather choice survives restart")
                        assert(scene.clockHitItem.currentVariant === "analog", "scene resolves saved design")
                        console.info("WIDGET_VARIANTS_RELOAD_OK")
                        Qt.quit(); return
                    }
                    testConfig.setValue("appearance.reducedMotion", true)
                    before = JSON.parse(JSON.stringify(testConfig.sharedWidgets))
                    assert(!testConfig.setWidgetVariant("clock", "invalid"), "invalid choice rejected")
                    assert(!find(settings,"widgetCard.frame"), "frame removed from widgets")
                    const analog = find(settings,"widgetVariant.clock.analog")
                    input.mouseClick(analog, analog.width / 2, analog.height / 2)
                    assert(testConfig.sharedWidgetByKind("clock").variantId === "analog", "pointer chooses analog")
                } else if (step === 1) {
                    assert(scene.clockHitItem.currentVariant === "analog", "scene uses selected variant")
                    assert(scene.clockHitItem.width === 240 && scene.clockHitItem.height === 260, "variant size reaches scene")
                    assert(testConfig.sharedWidgetByKind("clock").desktopEnabled === before[0].desktopEnabled, "variant keeps visibility")
                    assert(JSON.stringify(testConfig.sharedWidgetByKind("clock").lock) === JSON.stringify(before[0].lock), "lock pose preserved")
                    assert(JSON.stringify(testConfig.sharedWidgetByKind("clock").desktopStyle) === JSON.stringify(before[0].desktopStyle), "custom style preserved")
                    settings.prepareResult({id:"widget.weather.variants"})
                } else if (step === 2) {
                    const forecast = find(settings,"widgetVariant.weather.forecast")
                    forecast.forceActiveFocus(); input.keyClick(Qt.Key_Space)
                    assert(testConfig.sharedWidgetByKind("weather").variantId === "forecast", "keyboard chooses variant")
                    assert(!find(settings,"widgetVariant.clock.analog"), "leaving family unmounts choices")
                    settings.prepareResult({id:"widget.battery.desktop"})
                } else if (step === 3) {
                    assert(!!find(settings,"widgetVariant.battery.ring"), "battery family has designs")
                    assert(testConfig.setWidgetVariant("battery","ring"), "ring saved")
                    for (const kind of ["clock","weather","media","system","battery","gallery"]) {
                        for (const entry of Catalog.variants(kind)) {
                            assert(testConfig.setWidgetVariant(kind,entry.id), "catalog option accepted: " + kind + "/" + entry.id)
                        }
                    }
                    testConfig.setWidgetVariant("clock","analog")
                    testConfig.setWidgetVariant("weather","forecast")
                    testConfig.setSharedWidgetVisibility("battery", true, false)
                    testMedia.canToggle = true
                    window.width = 440
                } else if (step === 4) {
                    const value = find(scene.batteryHitItem,"battery.value")
                    assert(value && value.text === "—", "missing battery is not a full charge")
                    testStatus.hasBattery = true; testStatus.batteryLevel = .41; testStatus.batteryPercent = 41
                    const toggle = find(scene.mediaHitItem,"widgetMedia.toggle")
                    toggle.forceActiveFocus(); input.keyClick(Qt.Key_Space)
                    assert(testMedia.toggleCount === 1, "media keyboard control uses injected player")
                } else if (step === 5) {
                    assert(find(scene.batteryHitItem,"battery.value").text === "41", "live battery value reaches card")
                    assert(settings.variantColumns === 1, "narrow variants stack")
                    assert(!find(settings,"widgetCard.frame") && !find(settings,"legacy.frame-opacity"), "fixed frame has no controls")
                    if (testConfig.savePending) return
                    assert(!testConfig.saveError.length, "settings saved: " + testConfig.saveError)
                    console.info("WIDGET_VARIANTS_OK migration pointer keyboard scene persistence missing-data")
                    Qt.quit()
                }
                step++
            } catch (error) { console.error("WIDGET_VARIANTS_FAILED",String(error),error.stack); Qt.quit() }
            finally { working = false }
        }
    }
    Timer { interval: 10000; running: true; onTriggered: { console.error("WIDGET_VARIANTS_FAILED timeout"); Qt.quit() } }
}
