import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../core" as Core
import "../../features/editor" as Editor

ShellRoot {
    id: test
    Core.ConfigStore { id: config }
    Core.Theme { id: theme; config: config; palette: null }
    Core.Motion { id: motion; config: config }
    QtObject { id: wifiDevice; property bool scannerEnabled: false }
    QtObject {
        id: status
        property bool hasBattery: true
        property real batteryLevel: .75
        property int batteryPercent: 75
        property bool batteryCharging: false
        property bool wifiEnabled: false
        property var wifiDevice: wifiDevice
        property var wifiNetworks: []
        function toggleWifi() { wifiEnabled=!wifiEnabled }
    }
    QtObject {
        id: tools
        property var status: status
        property var network: ({interface:"fixture",addresses:[],connection:"",vpn:[]})
        property bool networkChanging: false
        property var power: ({available:true,profiles:["power-saver","balanced","performance"],current:"balanced"})
        property bool powerBusy: false
        property string error: ""
        property int powerReads: 0
        property int networkReads: 0
        function refreshPower() { powerReads++ }
        function refreshNetwork() { networkReads++ }
        function setProfile(value) { power=Object.assign({},power,{current:value}) }
        function runAction(name) { throw Error("unexpected external action "+name) }
    }
    QtObject {
        id: fan
        property bool supported: true
        property bool busy: false
        property bool enabled: false
        property string state: "off"
        property bool lastConfirmedActive: false
        property string error: ""
        function refresh() {}
        function toggle() { enabled=!enabled }
    }
    QtObject { id: composition; property var networkStatus: status; property var topbarTools: tools; property var fanPlusService: fan }
    ListModel { id: history }
    QtObject {
        id: shell
        property var composition: composition
        property var notificationHistory: history
        function dismissNotificationHistory(id) { history.remove(0) }
        function clearTrackedNotificationHistory() { history.clear() }
        function openQuickPopup(kind) { throw Error("Settings opened a popup "+kind) }
    }
    QtObject {
        id: controller
        property bool shown: true
        property var shell: shell
        function hide() { throw Error("Settings closed") }
        function setSettingsPage(page) { throw Error("Card navigated away: "+page) }
    }
    Window {
        id: window
        width: 900; height: 700; visible: true; color: "#10191d"
        Flickable {
            id: viewport
            anchors.fill: parent; clip: true
            contentWidth: width; contentHeight: overview.height+32
            Editor.SettingsOverview {
                id: overview
                x: 16; y: 16; width: viewport.width-32
                theme: theme; motion: motion; controller: controller
                onSectionOpened: item => viewport.contentY=Math.max(0,Math.min(item.y+16,viewport.contentHeight-viewport.height))
            }
        }
    }
    TestCase { id: input; name: "SettingsSystemInline"; when: false }
    function check(value,message) { if (!value) throw Error(message) }
    function find(item,name) {
        if (!item) return null
        if (item.objectName===name || item.text===name) return item
        for(const child of item.children||[]) { const result=find(child,name);if(result)return result }
        return null
    }
    function card(kind) { return find(overview,"settingsSystem-"+kind) }
    property int phase: 0
    property int ticks: 0
    property real pose: 0
    Timer {
        interval: 70; repeat: true; running: true
        onTriggered: {
            if (!config.ready) return
            try {
                ticks++
                if (phase===0) {
                    config.setValue("appearance.reducedMotion",true)
                    history.append({id:"fixture",summary:"Fixture",body:"Body",app:"App",timeText:"Agora"})
                    for(const kind of ["monitor","volume","notifications","battery","wifi"])
                        check(card(kind).height===72 && !find(card(kind),"settingsSystemBody-"+kind).item,"collapsed card mounted controls")
                    input.mouseClick(card("monitor"),50,34)
                    check(card("monitor").expanded,"display header click does not expand")
                    phase++;return
                }
                if (phase===1) {
                    const display=find(overview,"settingsInlineMonitor")
                    if (!display || !display.monitors.length) return
                    check(card("monitor").height>300,"display controls are not inline")
                    check(find(display,"monitorMode") && find(display,"monitorScale"),"resolution and scale missing")
                    input.mouseClick(find(display,"monitorApply"),30,16)
                    phase++;return
                }
                if (phase===2) {
                    const display=find(overview,"settingsInlineMonitor")
                    if (!display.awaitingConfirmation) return
                    input.mouseClick(card("monitor"),50,34)
                    check(!card("monitor").expanded,"header does not collapse")
                    phase++;return
                }
                if (phase===3) {
                    const body=find(card("monitor"),"settingsSystemBody-monitor").item
                    if (body && body.busy) return // Rollback finishes before the loader can be released.
                    check(!body,"collapsed display controls were retained")
                    overview.openTool("volume");phase++;return
                }
                if (phase===4) {
                    check(!!find(overview,"settingsInlineVolume") && !!find(overview,"settingsInlineMute"),"audio controls are not inline")
                    card("volume").expanded=false;overview.openTool("notifications");phase++;return
                }
                if (phase===5) {
                    check(!!find(overview,"settingsInlineNotifications"),"notification history missing")
                    input.mouseClick(find(overview,"notificationClear"),30,15)
                    phase++;return
                }
                if (phase===6) {
                    if (history.count) return
                    card("notifications").expanded=false;overview.openTool("battery");phase++;return
                }
                if (phase===7) {
                    check(tools.powerReads>0 && !!find(overview,"settingsInlinePower"),"power section did not query its shared backend")
                    input.mouseClick(find(overview,"energyChoice-performance"),30,28)
                    check(tools.power.current==="performance","inline power profile has no action")
                    input.mouseClick(find(overview,"topbarFanSwitch"),20,15)
                    check(fan.enabled,"inline Fan+ has no action")
                    card("battery").expanded=false;overview.openTool("wifi");phase++;return
                }
                if (phase===8) {
                    check(tools.networkReads>0 && !!find(overview,"settingsInlineWifi"),"network controls missing")
                    input.mouseClick(find(overview,"Ligar Wi-Fi"),30,15)
                    check(status.wifiEnabled && wifiDevice.scannerEnabled,"inline Wi-Fi did not enable scanning")
                    card("wifi").expanded=false
                    check(!wifiDevice.scannerEnabled,"collapsed network section keeps scanning")
                    config.setValue("appearance.reducedMotion",false)
                    card("monitor").expanded=true;phase++;return
                }
                if (phase===9) {
                    check(card("monitor").reveal>0 && card("monitor").reveal<1,"section did not animate")
                    pose=card("monitor").reveal;card("monitor").expanded=false
                    check(Math.abs(card("monitor").reveal-pose)<.001,"closing jumps the accordion")
                    phase++;return
                }
                if (phase===10) {
                    pose=card("monitor").reveal;card("monitor").expanded=true
                    check(Math.abs(card("monitor").reveal-pose)<.001,"reopening jumps the accordion")
                    config.setValue("appearance.reducedMotion",true)
                    window.width=440;phase++;return
                }
                if (phase===11) {
                    check(card("monitor").reveal===1,"reduced motion does not settle")
                    const display=find(overview,"settingsInlineMonitor")
                    check(display.width<=window.width-80 && find(display,"monitorMode").width===display.width,"compact monitor exceeds the section")
                    check(controller.shown,"inline card closed Settings")
                    const target=Quickshell.env("VELORA_INLINE_SCREENSHOT")
                    window.contentItem.grabToImage(result=>{if(target)result.saveToFile(target);console.info("SETTINGS_INLINE_OK");Qt.quit()})
                    running=false
                }
                if(ticks>100)throw Error("phase "+phase+" did not complete")
            } catch(error) {console.error("SETTINGS_INLINE_FAILED",String(error),error.stack);Qt.quit()}
        }
    }
    Timer { interval: 10000;running:true;onTriggered:{console.error("SETTINGS_INLINE_FAILED timeout");Qt.quit()} }
}
