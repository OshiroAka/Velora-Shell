import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Scope {
    id: root

    property int networkRevision: 0
    property int deviceRevision: 0
    property int batteryRevision: 0
    property bool performanceActive: false
    property bool performanceAvailable: false
    property real cpuPercent: 0
    property real ramPercent: 0
    property real storagePercent: 0
    property real networkDownKbps: 0
    property real networkUpKbps: 0
    property var networkHistory: []
    property double previousCpuTotal: -1
    property double previousCpuIdle: -1
    property double previousNetworkRx: -1
    property double previousNetworkTx: -1
    property double previousNetworkAt: 0
    property int performanceTick: 0

    readonly property var wifiDevice: selectWifiDevice(
        deviceRevision, Networking.devices.values.length)
    readonly property var wifiNetworks: wifiDevice ? wifiDevice.networks.values : []
    readonly property var activeNetwork: selectActiveNetwork(
        networkRevision, wifiNetworks.length)
    readonly property bool wifiEnabled: Boolean(Networking.wifiEnabled)
    readonly property bool wifiConnected: Boolean(activeNetwork && activeNetwork.connected)
    readonly property string wifiName: wifiConnected
        ? String(activeNetwork.name || "Wi-Fi") : (wifiEnabled ? "Wi-Fi" : "Wi-Fi off")

    readonly property var battery: selectBattery(
        batteryRevision, UPower.devices.values.length)
    readonly property bool hasBattery: Boolean(battery && battery.ready)
    readonly property real batteryLevel: hasBattery
        ? normalizePercentage(battery.percentage) : 1
    readonly property int batteryPercent: Math.round(batteryLevel * 100)
    readonly property bool batteryCharging: Boolean(hasBattery
        && battery.state === UPowerDeviceState.Charging)

    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property bool hasAudio: Boolean(audioSink && audioSink.ready && audioSink.audio)
    readonly property real volume: hasAudio
        ? Math.max(0, Math.min(1.5, Number(audioSink.audio.volume || 0))) : 0
    readonly property bool muted: Boolean(hasAudio && audioSink.audio.muted)
    readonly property int volumePercent: Math.round(volume * 100)

    function selectWifiDevice(revision, count) {
        revision
        count
        const devices = Networking.devices.values
        for (let index = 0; index < devices.length; index += 1) {
            const device = devices[index]
            if (device && device.type === DeviceType.Wifi)
                return device
        }
        return null
    }

    function selectActiveNetwork(revision, count) {
        revision
        count
        const networks = wifiNetworks
        for (let index = 0; index < networks.length; index += 1) {
            if (networks[index] && networks[index].connected)
                return networks[index]
        }
        return null
    }

    function selectBattery(revision, count) {
        revision
        count
        const devices = UPower.devices.values
        for (let index = 0; index < devices.length; index += 1) {
            if (devices[index] && devices[index].isLaptopBattery)
                return devices[index]
        }
        return UPower.displayDevice || null
    }

    function normalizePercentage(value) {
        const number = Number(value || 0)
        return Math.max(0, Math.min(1, number > 1 ? number / 100 : number))
    }

    function toggleMuted() {
        if (!hasAudio)
            return false
        audioSink.audio.muted = !audioSink.audio.muted
        return true
    }

    function adjustVolume(direction) {
        if (!hasAudio)
            return false
        const step = Number(direction) >= 0 ? 0.05 : -0.05
        audioSink.audio.volume = Math.max(0, Math.min(1.5, volume + step))
        return true
    }

    function adjustBrightness(direction) {
        const amount = Number(direction) >= 0 ? "5%+" : "5%-"
        Quickshell.execDetached(["brightnessctl", "set", amount])
        return true
    }

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled
        return true
    }

    function parseCpu(text) {
        const firstLine = String(text || "").split("\n")[0].trim()
        const fields = firstLine.split(/\s+/)
        if (fields.length < 5 || fields[0] !== "cpu")
            return false
        let total = 0
        for (let index = 1; index < fields.length; index += 1)
            total += Number(fields[index] || 0)
        const idle = Number(fields[4] || 0) + Number(fields[5] || 0)
        if (previousCpuTotal >= 0 && total > previousCpuTotal) {
            const deltaTotal = total - previousCpuTotal
            const deltaIdle = idle - previousCpuIdle
            cpuPercent = Math.max(0, Math.min(100,
                100 * (deltaTotal - deltaIdle) / deltaTotal))
            performanceAvailable = true
        }
        previousCpuTotal = total
        previousCpuIdle = idle
        return true
    }

    function parseMemory(text) {
        const lines = String(text || "").split("\n")
        let total = 0
        let available = 0
        for (let index = 0; index < lines.length; index += 1) {
            const fields = lines[index].trim().split(/\s+/)
            if (fields[0] === "MemTotal:")
                total = Number(fields[1] || 0)
            else if (fields[0] === "MemAvailable:")
                available = Number(fields[1] || 0)
        }
        if (total <= 0)
            return false
        ramPercent = Math.max(0, Math.min(100, 100 * (total - available) / total))
        performanceAvailable = true
        return true
    }

    function parseNetwork(text) {
        const lines = String(text || "").split("\n")
        let rx = 0
        let tx = 0
        for (let index = 2; index < lines.length; index += 1) {
            const parts = lines[index].trim().split(/[:\s]+/)
            if (parts.length < 10 || parts[0] === "lo")
                continue
            rx += Number(parts[1] || 0)
            tx += Number(parts[9] || 0)
        }
        const now = Date.now()
        if (previousNetworkRx >= 0 && now > previousNetworkAt) {
            const seconds = (now - previousNetworkAt) / 1000
            networkDownKbps = Math.max(0, (rx - previousNetworkRx) / 1024 / seconds)
            networkUpKbps = Math.max(0, (tx - previousNetworkTx) / 1024 / seconds)
            const next = networkHistory.slice(-29)
            next.push(Math.min(1, Math.log10(1 + networkDownKbps) / 4))
            networkHistory = next
        }
        previousNetworkRx = rx
        previousNetworkTx = tx
        previousNetworkAt = now
        return true
    }

    function parseStorage(text) {
        const lines = String(text || "").trim().split("\n")
        if (lines.length < 2)
            return false
        const fields = lines[lines.length - 1].trim().split(/\s+/)
        const value = fields.length >= 5
            ? Number(String(fields[4]).replace("%", "")) : NaN
        if (!isFinite(value))
            return false
        storagePercent = Math.max(0, Math.min(100, value))
        return true
    }

    function refreshPerformance() {
        if (!performanceActive)
            return false
        cpuFile.reload()
        memoryFile.reload()
        networkFile.reload()
        performanceTick += 1
        if ((performanceTick % 5) === 1 && !storageProcess.running)
            storageProcess.running = true
        return true
    }

    onPerformanceActiveChanged: {
        if (performanceActive) {
            previousCpuTotal = -1
            previousCpuIdle = -1
            previousNetworkRx = -1
            previousNetworkTx = -1
            previousNetworkAt = 0
            networkHistory = []
            performanceTick = 0
            refreshPerformance()
        } else {
            performanceAvailable = false
            previousCpuTotal = -1
            previousCpuIdle = -1
            previousNetworkRx = -1
            previousNetworkTx = -1
            previousNetworkAt = 0
            networkHistory = []
        }
    }

    FileView {
        id: cpuFile
        path: root.performanceActive ? "/proc/stat" : ""
        printErrors: false
        onLoaded: root.parseCpu(text())
    }

    FileView {
        id: networkFile
        path: root.performanceActive ? "/proc/net/dev" : ""
        printErrors: false
        onLoaded: root.parseNetwork(text())
    }

    Process {
        id: storageProcess
        command: ["df", "-P", "/"]
        running: false
        stdout: StdioCollector { id: storageOutput }
        onExited: function(exitCode) {
            if (exitCode === 0)
                root.parseStorage(storageOutput.text)
        }
    }

    FileView {
        id: memoryFile
        path: root.performanceActive ? "/proc/meminfo" : ""
        printErrors: false
        onLoaded: root.parseMemory(text())
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.performanceActive
        onTriggered: root.refreshPerformance()
    }

    Connections {
        target: Networking.devices
        function onValuesChanged() { root.deviceRevision += 1 }
    }

    Connections {
        target: root.wifiDevice ? root.wifiDevice.networks : null
        function onValuesChanged() { root.networkRevision += 1 }
    }

    Connections {
        target: UPower.devices
        function onValuesChanged() { root.batteryRevision += 1 }
    }

    PwObjectTracker {
        objects: root.audioSink ? [root.audioSink] : []
    }
}
