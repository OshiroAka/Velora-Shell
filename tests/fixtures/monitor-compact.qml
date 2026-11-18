import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../features/topbar" as Topbar
import "../../features/topbar/TopBarGeometry.js" as Geometry

ShellRoot {
    id: test
    function check(value,message) { if(!value) throw Error(message) }
    function find(item,name) {
        if(item.objectName===name) return item
        for(const child of item.children || []) { const found=find(child,name); if(found) return found }
        return null
    }
    QtObject { id: config; property bool reducedMotion: false }
    QtObject {
        id: theme
        property var config: config
        property color textPrimary: "#eef2f5"
        property color wallpaperSurfaceTone: "#26343b"
        property string bodyFont: "Sans Serif"
    }
    Window {
        width: 370; height: 320; visible: true
        Topbar.BarPanelContent {
            id: panel
            x: 16; y: 16
            width: Geometry.size("monitor")[0]-32; height: Geometry.size("monitor")[1]-32
            type: "monitor"; theme: theme
            systemStatus: ({}); system: ({}); fanPlus: ({}); timerService: ({}); clock: ({}); calendar: ({})
            media: ({}); weather: ({}); controller: ({}); actions: ({})
        }
    }
    TestCase { id: input; name: "MonitorCompact"; when: false }
    Timer {
        id: drive
        interval: 100; running: true
        onTriggered: {
            if(!panel.item || panel.item.monitors.length<2) { restart(); return }
            try {
                const monitor=panel.item
                for(const width of [288,248]) {
                    panel.width=width; input.wait(20)
                    for(const name of ["monitorChoice-extend","monitorChoice-mirror","monitorChoice-main","monitorOutput","monitorMode","monitorScale","monitorApply","monitorRefresh"]) {
                        const control=test.find(monitor,name)
                        const p=control.mapToItem(panel,0,0)
                        test.check(p.x>=0 && p.x+control.width<=panel.width+.1 && p.y>=0 && p.y+control.height<=panel.height+.1,
                            "Compact monitor control clipped: "+name)
                    }
                }
                monitor.error="Erro de teste"; input.wait(20)
                const apply=test.find(monitor,"monitorApply")
                const point=apply.mapToItem(panel,0,0)
                test.check(point.y+apply.height<=panel.height+.1,"Error status clipped the apply action")
                monitor.error=""
                const mirror=test.find(monitor,"monitorChoice-mirror")
                input.mouseClick(mirror,mirror.width/2,mirror.height/2)
                test.check(monitor.layoutMode==="mirror","Visual monitor choices lost their action")
                monitor.opened=false; input.wait(20)
                monitor.opened=true; input.wait(380)
                const first=mirror.previewProgress
                test.check(mirror.previewLooping && first>0 && first<.9,"Preview did not start without hover")
                input.wait(750)
                const peak=mirror.previewProgress
                test.check(peak>first,"Preview did not reach its destination")
                input.wait(1750)
                const valley=mirror.previewProgress
                test.check(valley<peak-.4,"Preview did not return during its loop")
                input.wait(450)
                test.check(mirror.previewProgress>valley,"Preview did not start the next cycle")
                monitor.opened=false
                const stopped=mirror.previewProgress; input.wait(120)
                test.check(!mirror.previewLooping && mirror.previewProgress===stopped,"Closed preview keeps animating")
                monitor.reducedMotion=true; monitor.opened=true; input.wait(120)
                test.check(!mirror.previewLooping && mirror.previewProgress===1,"Reduced motion does not settle the preview")
                const wireless = test.find(monitor,"monitorWirelessTab")
                input.mouseClick(wireless,wireless.width/2,wireless.height/2)
                input.tryVerify(() => monitor.wireless && monitor.receivers.length === 3)
                test.check(!mirror.visible,"Physical controls remain visible in the wireless tab")
                test.check(test.find(monitor,"monitorWirelessReceivers").count === 3,"Missing receiver rows")
                const scan = test.find(monitor,"monitorWirelessScan")
                input.mouseClick(scan,scan.width/2,scan.height/2)
                input.tryVerify(() => scan.enabled)
                const receivers = test.find(monitor,"monitorWirelessReceivers")
                receivers.forceActiveFocus()
                input.keyClick(Qt.Key_End)
                test.check(!test.find(monitor,"monitorWirelessStart").enabled,"Ordinary LAN devices must not start a cast")
                input.keyClick(Qt.Key_Up)
                test.check(monitor.wirelessReceiver === "01:23:45:67:89:ac","Receiver did not change inside Velora")
                const extend = test.find(monitor,"monitorWirelessMode-extend")
                input.mouseClick(extend,extend.width/2,extend.height/2)
                test.check(monitor.wirelessMode === "extend","Wireless mode did not switch to extend")
                const start = test.find(monitor,"monitorWirelessStart")
                test.check(start.visible && start.enabled,"Wireless start unavailable")
                input.mouseClick(start,start.width/2,start.height/2)
                input.tryVerify(() => monitor.wirelessPhase === "connecting" || monitor.wirelessError.length > 0, 1500)
                test.check(monitor.wirelessDevice === "TV Quarto", monitor.wirelessError)
                input.tryVerify(() => monitor.wirelessPhase === "streaming", 2500)
                monitor.opened=false; input.wait(30)
                monitor.opened=true; input.tryVerify(() => !monitor.checkingWireless && monitor.casting)
                const stop = test.find(monitor,"monitorWirelessStop")
                input.mouseClick(stop,stop.width/2,stop.height/2)
                input.tryVerify(() => monitor.wirelessPhase === "idle")
                console.info("MONITOR_COMPACT_OK")
                Qt.quit()
            } catch(error) {
                console.error("MONITOR_COMPACT_FAILED",String(error),error.stack,
                    panel.item.wirelessError, panel.item.wirelessPhase, panel.item.wirelessDevice)
                Qt.quit()
            }
        }
    }
    Timer { interval: 11000; running: true; onTriggered: { console.error("MONITOR_COMPACT_FAILED timeout"); Qt.quit() } }
}
