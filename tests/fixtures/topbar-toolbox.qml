import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../core" as Core
import "../../features/topbar" as Topbar

ShellRoot {
    id: test
    function check(value, message) { if (!value) throw Error(message) }
    function find(item, name) {
        if (item.objectName === name) return item
        for (const child of item.children || []) {
            const found = find(child, name)
            if (found) return found
        }
        return null
    }
    QtObject {
        id: config
        property bool reducedMotion: true
        property var topbarToolsOrder: ["search", "controls"]
        property bool topbarOneThingEnabled: true
        property bool topbarNotesEnabled: false
        function topbarItemsForSection(section, all) {
            return section === "left" ? [{type: "launcher"}] : section === "center" ? [{type:"weather"}] : []
        }
    }
    QtObject {
        id: theme
        property var config: config
        property color accent: "#b5c9d4"
        property color accentSoft: "#e0e9ef"
        property color accentMuted: "#29424c"
        property color textPrimary: "#f0f3f6"
        property color textSecondary: "#bac8d0"
        property color textMuted: "#9cabb5"
        property color warning: "#ddb66b"
        property color danger: "#d67a7a"
        property string bodyFont: "Sans Serif"
        property color borderSubtle: "#40545a"
        function withAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    }
    QtObject {
        id: actions
        property int launched: 0
        property int settingsOpened: 0
        function openLauncher() { launched++ }
        function openSettings() { settingsOpened++ }
    }
    QtObject {
        id: host
        property var screen: Quickshell.screens[0]
    }
    Core.Motion { id: tokens; config: config }
    QtObject { id: clock; property var now: new Date(); function locale() { return Qt.locale("pt_BR") } }
    Topbar.TopBarController { id: controller; motion: tokens }
    Window {
        id: win
        width: 1280; height: 800; visible: true
        Topbar.ConnectedPopover {
            id: popup
            anchors.fill: parent
            leftInset: 72; rightInset: 8
            controller: controller; host: host; config: config; theme: theme; motionTokens: tokens
            status: ({}); system: ({}); fanPlus: ({}); timerService: ({}); clock: ({}); calendar: ({})
            media: ({}); actions: actions
            weather: ({available:true,temperature:"24",location:"Fixture",hourly:[],forecast:[]})
        }
        Topbar.ReferenceBar {
            id: bar
            width: parent.width; height: 40
            config: config; theme: theme; clock: clock; media: ({}); weather: ({available:true,temperature:"24"})
            status: ({hasBattery:false,batteryLevel:0,batteryCharging:false,wifiConnected:false,wifiEnabled:false})
            actions: actions; compositor: ({}); editorController: ({shown: false, mounted: false})
            controller: controller; host: host; system: ({wifiStrength:0,cpuUsage:0,enabled:false,catAnimation:false})
            timerService: ({finished:false,countdown:{running:false},barText:"25:00",duration:1500000,engaged:false}); wavePhase: 0
        }
    }
    TestCase { id: input; name: "Toolbox"; when: false }
    Timer {
        interval: 300; running: true
        onTriggered: {
            try {
                const trigger = test.find(bar, "topbarToolboxTrigger")
                test.check(!!trigger, "Dots trigger is missing")
                test.check(controller.items.some(entry => entry.type === "toolbox" && entry.item === trigger), "Toolbox anchor was not registered")
                input.mouseMove(trigger, 45, 20)
                test.check(!controller.opened, "Toolbox opened on hover")
                input.mouseClick(trigger, 45, 20)
                test.check(controller.activeType === "toolbox" && popup.mounted, "Dots did not open the toolbox")
                test.check(actions.launched === 0, "Dots still launched applications")
                const rect = popup.panelRect
                test.check(rect.x === 52 && rect.y === 40 && rect.width === 224 && rect.height === 172,
                    "Toolbox did not expand into the corner: " + JSON.stringify(rect))
                for (const name of ["eyedropper", "record", "timer", "calendar", "markings", "documents"]) {
                    const tool = test.find(popup, "toolbox-" + name)
                    test.check(!!tool && tool.visible && tool.enabled, "Missing tool: " + name)
                    const point = tool.mapToItem(popup, 0, 0)
                    test.check(point.x >= 64 && point.x + tool.width <= rect.x + rect.width - 15
                        && point.y >= rect.y + 15 && point.y + tool.height <= rect.y + rect.height - 15,
                        "Tool is clipped: " + name)
                    input.mouseClick(tool, tool.width / 2, tool.height / 2)
                    test.check(controller.activeType === "toolbox" && actions.launched === 0, "Placeholder executed an action")
                }
                input.keyClick(Qt.Key_Escape)
                test.check(!controller.opened && !popup.mounted, "Escape did not close the toolbox")
                trigger.forceActiveFocus()
                input.keyClick(Qt.Key_Space)
                test.check(controller.activeType === "toolbox", "Keyboard did not open the toolbox")
                input.mouseClick(trigger, 45, 20)
                test.check(!controller.opened && !popup.mounted, "Second click did not close the toolbox")
                const search = test.find(bar,"topbarTool-search")
                const settings = test.find(bar,"topbarTool-controls")
                test.check(!!search && !!settings,"Direct bar icons are missing")
                test.check(!controller.supportsHover("search") && !controller.supportsHover("controls"),"Removed menus still open on hover")
                test.check(!controller.openByType("search") && !controller.openByType("controls"),"Removed menus still have anchors")
                input.mouseMove(search,18,20); input.wait(160)
                test.check(!controller.opened,"Search opened on hover")
                input.mouseClick(search,18,20)
                test.check(!controller.opened && actions.launched===0,"Search placeholder executed an action")
                input.mouseClick(settings,18,20)
                test.check(actions.settingsOpened===1 && !controller.opened,"Controls did not open settings directly")
                settings.forceActiveFocus(); input.keyClick(Qt.Key_Return)
                test.check(actions.settingsOpened===2,"Settings shortcut lost keyboard activation")
                const weather = test.find(bar,"topbarWeatherTrigger")
                input.mouseClick(weather,40,20)
                test.check(controller.activeType==="weather" && popup.mounted,"Weather did not use the connected host")
                test.check(popup.panelRect.width===368 && popup.panelRect.height===354,"Weather still uses its old large geometry")
                test.check(!!test.find(popup,"weatherChart"),"New weather content was not loaded")
                input.keyClick(Qt.Key_Escape)
                test.check(!controller.opened,"Weather did not close with Escape")
                console.info("TOPBAR_TOOLBOX_OK")
                Qt.quit()
            } catch (error) {
                console.error("TOPBAR_TOOLBOX_FAILED", String(error), error.stack)
                Qt.quit()
            }
        }
    }
    Timer { interval: 5000; running: true; onTriggered: { console.error("TOPBAR_TOOLBOX_FAILED timeout"); Qt.quit() } }
}
