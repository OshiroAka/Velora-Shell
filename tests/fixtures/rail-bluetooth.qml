import QtQuick
import Quickshell
import "components" as Components
import "services" as Services

ShellRoot {
    id: test
    property int stage: 0
    property int ticks: 0
    function check(ok, message) { if (!ok) throw new Error(message) }
    function find(item, name) {
        if (item.objectName === name) return item
        for (const child of item.children || []) { const found = find(child, name); if (found) return found }
        return null
    }
    QtObject { id: theme }
    QtObject {
        id: fakeManager
        property bool available: true
        property bool powered: true
        property bool scanning: false
        property bool busy: false
        property bool needsPin: false
        property string pairPrompt: ""
        property string error: ""
        property string action: ""
        property string targetAddress: ""
        property int scans: 0
        property int pairs: 0
        property int removals: 0
        property int connections: 0
        property int disconnections: 0
        property int cancellations: 0
        property var devices: [
            {address: "headset", name: "QCY H3", icon: "audio-headset", paired: true, connected: true},
            {address: "phone", name: "Phone", icon: "phone", paired: false, connected: false}
        ]
        function scan() { scans++; scanning = true }
        function stopScan() { scanning = false }
        function pair(address) { pairs++ }
        function toggleDevice(device) {
            if (busy) return
            if (device.connected) disconnections++
            else if (device.paired || device.bonded) connections++
            else pairs++
        }
        function remove(address) { removals++ }
        function cancel() { cancellations++; busy = false }
    }
    Item {
        width: 800; height: 600
        Components.VeloraRailBluetooth {
            id: menu
            anchors.fill: parent
            theme: theme
            manager: fakeManager
            anchorY: 280
        }
    }
    QtObject { id: adapter; property bool enabled: true; property bool discovering: false }
    Services.RailBluetoothService {
        id: service
        adapter: adapter
        controlScript: Quickshell.shellDir + "/mock-bluetooth"
    }
    Timer {
        interval: 400; running: true; repeat: true
        onTriggered: {
            if (++test.ticks > 45) { console.error("RAIL_BLUETOOTH_FAILED timeout", test.stage); Qt.quit(); return }
            try {
                switch (test.stage) {
                case 0:
                    test.check(fakeManager.scans === 0, "hover must not start discovery")
                    test.check(menu.knownDevices.length === 1, "only paired/connected devices in compact menu")
                    menu.triggerHovered = true
                    break
                case 1:
                    test.check(menu.opened && menu.reveal > 0.98, "hover opens menu")
                    test.check(menu.extension === null, "hover cannot create a name tag")
                    test.check(fakeManager.connections === 0 && fakeManager.disconnections === 0, "hover cannot change a connection")
                    test.find(menu,"bluetoothDeviceheadset").activate()
                    test.check(fakeManager.disconnections === 1,"compact tile disconnects the connected headset")
                    fakeManager.devices=[{address:"headset",name:"QCY H3",icon:"audio-headset",paired:true,connected:false},fakeManager.devices[1]]
                    break
                case 2:
                    test.check(menu.iconFor(fakeManager.devices[0]) === "headphones", "device icon")
                    const tile=test.find(menu,"bluetoothDeviceheadset")
                    tile.activate(); test.check(fakeManager.connections===1,"compact tile connects the paired headset")
                    fakeManager.action="connect";fakeManager.targetAddress="headset";fakeManager.busy=true
                    tile.activate();test.check(fakeManager.connections===1,"busy tile rejects duplicate clicks")
                    test.check(test.find(menu,"bluetoothPendingheadset").visible && !menu.closeOnLeave,"pending connection stays visible")
                    fakeManager.busy=false;fakeManager.action="";fakeManager.targetAddress=""
                    test.find(menu, "bluetoothAdd").clicked()
                    test.check(fakeManager.scans === 1 && menu.managing, "plus starts search")
                    break
                case 3: {
                    test.find(menu,"bluetoothConnectheadset").clicked()
                    test.check(fakeManager.connections===2,"manager offers a connection action for paired devices")
                    const remove = test.find(menu, "bluetoothActionheadset")
                    remove.clicked()
                    test.check(fakeManager.removals === 0 && menu.removeAddress === "headset", "removal requires confirmation")
                    remove.clicked()
                    test.check(fakeManager.removals === 1, "confirmed removal dispatched")
                    test.find(menu, "bluetoothConnectphone").clicked()
                    test.check(fakeManager.pairs === 1, "pair dispatch")
                    fakeManager.busy=true;fakeManager.action="connect";fakeManager.targetAddress="headset"
                    menu.triggerHovered = false; menu.close()
                    test.check(fakeManager.cancellations===0 && fakeManager.busy,"Closing the menu must preserve an in-flight connection")
                    break
                }
                case 4:
                    fakeManager.busy=false;fakeManager.action="";fakeManager.targetAddress=""
                    test.check(!menu.mounted && !menu.managing && !fakeManager.scanning, "close releases discovery and manager")
                    service.scan(); test.check(adapter.discovering, "scan starts")
                    service.stopScan(); test.check(!adapter.discovering, "own scan stops")
                    adapter.discovering = true; service.scan(); service.stopScan()
                    test.check(adapter.discovering, "external scan remains owned by its client")
                    adapter.discovering = false
                    service.pair("success")
                    break
                case 5:
                    if (!service.pairPrompt) return
                    test.check(service.busy && service.pairPrompt.indexOf("123456") >= 0, "pair confirmation without newline")
                    service.answer("yes")
                    break
                case 6:
                    if (service.busy) return
                    test.check(service.error === "" && service.pairPrompt === "", "pair success")
                    service.disconnectDevice("success")
                    break
                case 7:
                    if (service.busy) return
                    test.check(service.error === "","disconnect success")
                    service.remove("failure")
                    break
                case 8:
                    if (service.busy) return
                    test.check(service.error.length > 0, "remove error surfaced")
                    service.pair("failure")
                    break
                case 9:
                    if (service.busy) return
                    test.check(service.error.length > 0, "pair failure with zero exit code surfaced")
                    service.connectDevice("failure")
                    break
                case 10:
                    if (service.busy) return
                    test.check(service.error.indexOf("conectar")>=0,"connection failure has its own error")
                    service.pair("success")
                    break
                case 11:
                    if (!service.pairPrompt) return
                    service.cancel()
                    break
                case 12:
                    test.check(!service.busy && !service.pairPrompt, "pair cancellation clears session")
                    adapter.enabled = false; service.scan()
                    test.check(!adapter.discovering && service.error.length > 0, "disabled adapter reported")
                    console.info("RAIL_BLUETOOTH_OK"); Qt.quit(); return
                }
                test.stage++
            } catch (error) { console.error("RAIL_BLUETOOTH_FAILED", test.stage, error.message); Qt.quit() }
        }
    }
}
