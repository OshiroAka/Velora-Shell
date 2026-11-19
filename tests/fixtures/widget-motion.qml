import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../core" as Core
import "../../services" as Services
import "../../features/widgets" as Widgets

ShellRoot {
    id: test

    Core.ConfigStore { id: config }
    Core.Motion { id: motion; config: config }
    QtObject {
        id: palette
        property bool ready: true
        property bool exactSurface: true
        property color background: "#131d26"
        property color foreground: "#f6f4f1"
        property color muted: "#bbbcbc"
        property color accent: "#626868"
        property color accentAlt: "#696866"
        property color accentSoft: "#838786"
    }
    Core.Theme { id: theme; config: config; palette: palette }
    Services.SceneEditorService { id: editor; config: config }
    QtObject {
        id: transition
        property bool running: false
        property real progress: 0
        function motionProgress() { return 0 }
        function staggeredProgress() { return 0 }
        function activity() { return 0 }
    }
    QtObject {
        id: clock
        property date now: new Date(2026, 10, 19, 4, 9)
        property string timeText: "04:09"
        property string dateText: "quinta-feira, 19 de novembro"
        function locale() { return Qt.locale("pt_BR") }
    }
    QtObject {
        id: weather
        property string location: "Guarulhos, São Paulo"
        property string iconName: "rain"
        property string temperature: "20"
        property string minimum: "18"
        property string maximum: "30"
        property string description: "Chuva fraca"
        property var forecast: [
            {date: "2026-11-20", icon: "rain", max: 27, min: 18},
            {date: "2026-11-21", icon: "cloud", max: 29, min: 19},
            {date: "2026-11-22", icon: "partly", max: 30, min: 18},
            {date: "2026-11-23", icon: "sun", max: 30, min: 19}
        ]
    }
    QtObject {
        id: status
        property bool performanceAvailable: true
        property real cpuPercent: 24
        property real ramPercent: 47
        property real storagePercent: 95
        property real networkDownKbps: 32
        property real networkUpKbps: 8
        property var networkHistory: [.45, .25, .5, .29, .2, .4, .68, .55]
        property bool hasBattery: true
        property bool batteryCharging: true
        property real batteryLevel: .67
        property int batteryPercent: 67
        property var battery: ({timeToFull: 1440, timeToEmpty: 10800})
        property bool hasAudio: false
        property real volume: 0
    }
    QtObject {
        id: media
        property bool hasPlayer: false
        property bool canPrevious: false
        property bool canNext: false
        property bool canToggle: false
        property bool playing: false
        property real progress: 0
    }
    QtObject { id: caustics; property real phase: 0 }
    Window {
        id: window
        width: 1600; height: 1000; visible: true; color: "#131d26"
        Image { anchors.fill: parent; source: Qt.resolvedUrl("../../assets/wallpapers/velora.png"); fillMode: Image.PreserveAspectCrop }
        Widgets.SharedWidgetsScene {
            id: scene
            anchors.fill: parent
            config: config; theme: theme; motion: motion; clock: clock
            calendarService: null; media: media; weather: weather; status: status
            transition: transition; editor: editor; causticsClock: caustics
            lockPresented: false
        }
        TestCase { id: input; when: false }
    }

    function assert(value, message) { if (!value) throw new Error(message) }
    function find(item, name) {
        if (item.objectName === name)
            return item
        for (const child of item.children || []) {
            const found = find(child, name)
            if (found) return found
        }
        return null
    }

    property int step: 0
    property real rainStart: 0
    property real orbitStart: 0
    Timer {
        id: check
        interval: 140; repeat: true; running: true
        onTriggered: {
            if (!config.ready)
                return
            try {
                const dots = find(scene.clockHitItem, "clock.dots")
                const rain = find(scene.weatherHitItem, "weather.rain")
                const orbit = find(scene.batteryHitItem, "battery.chargeOrbit")
                const panel = find(scene, "widgetDetailsPanel")
                if (step === 0) {
                    assert(dots.breathing && rain.visible && orbit.visible, "default widgets start visible animations")
                    rainStart = rain.phase
                    orbitStart = orbit.rotation
                    clock.timeText = "04:10"
                    assert(dots.changeProgress === 0, "changed clock digits begin a fade")
                    input.mouseClick(scene.weatherHitItem, 25, 74)
                    assert(scene.detailsOpen && panel.item.kind === "weather", "weather click opens the forecast")
                } else if (step === 1) {
                    assert(dots.changeProgress > 0 && dots.changeProgress < 1, "digit transition has intermediate frames")
                    assert(rain.phase !== rainStart && orbit.rotation !== orbitStart, "rain and charging orbit keep moving")
                    assert(panel.y > scene.weatherHitItem.y && panel.x >= 64 && panel.height > 56, "forecast attaches below its widget")
                    input.mouseClick(scene.systemHitItem, 30, 50)
                    assert(scene.detailsOpen && panel.item.kind === "system", "system replaces the current details")
                } else if (step === 2) {
                    input.mouseClick(scene.clockHitItem, 40, 65)
                    assert(scene.detailsOpen && panel.item.kind === "clock" && panel.height > 110, "clock opens the current month")
                    assert(panel.x + panel.width <= scene.width && panel.y + panel.height <= scene.height, "calendar stays on screen")
                    const screenshot = Quickshell.env("VELORA_WIDGET_MOTION_SCREENSHOT")
                    if (screenshot)
                        window.contentItem.grabToImage(result => { result.saveToFile(screenshot) })
                } else if (step === 3) {
                    input.mouseClick(scene.batteryHitItem, 30, 60)
                    assert(scene.detailsOpen && panel.item.kind === "battery", "battery opens its estimate")
                    assert(panel.item.batteryEstimate() === "24 min até a carga completa", "estimate comes from the battery service")
                    status.batteryCharging = false
                } else if (step === 4) {
                    const ring = find(scene.batteryHitItem, "battery.ring")
                    assert(!orbit.visible && ring.opacity < 1, "the ring breathes on battery power")
                    motion.reduced = true
                    assert(!rain.visible && !orbit.visible && !dots.breathing && ring.opacity === 1
                        && dots.changeProgress === 1, "reduced motion stops effects")
                    scene.editing = true
                    assert(!scene.detailsOpen && !scene.detailsHitItem, "editor closes the interactive panel")
                    console.info("WIDGET_MOTION_OK")
                    check.stop()
                    Qt.callLater(Qt.quit)
                }
                step++
            } catch (error) {
                console.error("WIDGET_MOTION_FAILED", String(error), error.stack)
                check.stop()
                Qt.quit()
            }
        }
    }
    Timer { interval: 8000; running: true; onTriggered: { console.error("WIDGET_MOTION_FAILED timeout"); Qt.quit() } }
}
