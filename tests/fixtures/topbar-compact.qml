import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../features/topbar" as Topbar
import "../../features/topbar/TopBarGeometry.js" as Geometry
ShellRoot {
    id: test
    function check(value, message) { if (!value) throw Error(message) }
    function find(item, name) {
        if (item.objectName === name) return item
        for (const child of item.children || []) { const found = find(child, name); if (found) return found }
        return null
    }
    QtObject { id: mockConfig; property bool reducedMotion: true }
    QtObject {
        id: theme
        property var config: mockConfig
        property string bodyFont: "Sans Serif"
        property color textPrimary: "#eef4f2"
        property color textSecondary: "#a4b5b2"
        property color textMuted: "#819693"
        property color accent: "#a3c9bf"
        property color accentSoft: "#a3c9bf"
        property color borderSubtle: "#48615f"
        property color borderStrong: "#718a87"
        property color surfaceSoft: "#20342f"
        property color warning: "#dfb67c"
        property color danger: "#e48b87"
        function withAlpha(c,a) { return Qt.rgba(c.r,c.g,c.b,a) }
    }
    QtObject {
        id: system
        property string oneThing: "Arch!"
        property string error: ""
        property var power: ({available: true, current: "balanced", profiles: ["power-saver", "balanced", "performance"]})
        property bool powerBusy: false
        property string picked: ""
        function setProfile(value) { picked = value; power = Object.assign({}, power, {current: value}) }
    }
    QtObject {
        id: status
        property bool hasBattery: true
        property real batteryLevel: .64
        property int batteryPercent: 64
        property bool batteryCharging: false
        property var battery: ({timeToEmpty: 7200, timeToFull: 3600, healthSupported: true, healthPercentage: 94})
    }
    QtObject {
        id: fan
        property bool enabled: false
        property bool supported: true
        property bool busy: false
        property string state: "off"
        property string error: ""
        property bool lastConfirmedActive: false
        property int toggles: 0
        function toggle() { toggles++; enabled = !enabled }
    }
    Window {
        id: win; width: 660; height: 210; visible: true; color: "#151e23"
        Rectangle {
            x: 20; y: 20; width: Geometry.size("thing")[0]; height: Geometry.size("thing")[1]
            radius: 16; color: "#2c4143"
            Topbar.MicroToolsPanel {
                id: focusPanel
                x: 16; y: 16; width: parent.width - 32; height: parent.height - 32
                type: "thing"; theme: theme; system: system; controller: ({}); actions: ({})
            }
        }
        Rectangle {
            x: 340; y: 20; width: Geometry.size("battery")[0]; height: Geometry.size("battery")[1]
            radius: 16; color: "#2c4143"
            Topbar.BarPanelContent {
                id: batteryPanel
                x: 16; y: 16; width: parent.width - 32; height: parent.height - 32
                type: "battery"; theme: theme; systemStatus: status; system: system; fanPlus: fan
                timerService: ({}); clock: ({}); calendar: ({}); media: ({}); weather: ({})
                controller: ({}); actions: ({})
            }
        }
    }
    TestCase { id: input; name: "CompactMenus"; when: false }
    Timer {
        interval: 400; running: true
        onTriggered: {
            try {
                const field = test.find(focusPanel, "topbarFocusEditor")
                test.check(!!field && field.height >= 34 && field.width > 200, "Focus field is clipped")
                field.text = "Arch!"; field.textEdited()
                test.check(system.oneThing === "Arch!", "Focus editor lost its save binding")
                for (const profile of system.power.profiles) {
                    const button = test.find(batteryPanel, "energyChoice-" + profile)
                    test.check(!!button && button.compact, "Compact energy choice missing")
                    const point = button.mapToItem(batteryPanel, 0, 0)
                    test.check(point.x >= -.1 && point.y >= -.1 && point.x + button.width <= batteryPanel.width + .1
                        && point.y + button.height <= batteryPanel.height + .1, "Energy choice is clipped: " + profile)
                    input.mouseClick(button, button.width/2, button.height/2)
                    test.check(system.picked === profile && button.selected, "Energy choice lost its backend action")
                }
                const switchControl = test.find(batteryPanel, "topbarFanSwitch")
                const position = switchControl.mapToItem(batteryPanel,0,0)
                test.check(position.y + switchControl.height <= batteryPanel.height + .1, "Fan control is clipped")
                input.mouseClick(switchControl,switchControl.width/2,switchControl.height/2)
                test.check(fan.enabled && fan.toggles === 1,"Fan toggle lost its backend action")
                fan.supported = false
                test.check(!switchControl.enabled,"Unsupported fan control is enabled")
                fan.supported = true
                system.setProfile("balanced")
                const path = Quickshell.env("VELORA_TOPBAR_COMPACT_SCREENSHOT")
                if (path) win.contentItem.grabToImage(result => { result.saveToFile(path); console.info("TOPBAR_COMPACT_OK"); Qt.quit() })
                else { console.info("TOPBAR_COMPACT_OK"); Qt.quit() }
            } catch(error) { console.error("TOPBAR_COMPACT_FAILED",String(error),error.stack);Qt.quit() }
        }
    }
}
