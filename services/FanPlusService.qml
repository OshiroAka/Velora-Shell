import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    property string state: "unsupported"
    property string error: "Verificando Fan+…"
    readonly property bool supported: state !== "unsupported"
    readonly property bool enabled: state === "active"
    readonly property bool busy: state === "starting" || state === "stopping"
    property bool lastConfirmedActive: false
    readonly property int targetRpm: 6300
    property string helper: Quickshell.shellDir + "/scripts/velora-fanplus"
    property string pending: ""
    property double lastTick: Date.now()

    function parse(output) {
        try { return JSON.parse(output) }
        catch (e) { return {state: "error", error: "Resposta inválida do Fan+"} }
    }
    function refresh() {
        if (operation.running) return
        pending = "status"
        operation.command = ["python3", helper, "status"]
        operation.running = true
    }
    function enable() {
        if (busy || operation.running || state === "unsupported" || enabled) return
        error = ""; state = "starting"; pending = "on"
        operation.command = ["python3", helper, "on"]
        operation.running = true
    }
    function disable() {
        if (busy || operation.running || !(enabled || state === "error" && lastConfirmedActive)) return
        error = ""; state = "stopping"; pending = "off"
        operation.command = ["python3", helper, "off"]
        operation.running = true
    }
    function toggle() { if (enabled || state === "error" && lastConfirmedActive) disable(); else enable() }
    function checkResume(now) {
        const resumed = now - lastTick > 45000
        lastTick = now
        if (resumed && enabled && !operation.running) {
            state = "starting"
            pending = "on"
            operation.command = ["python3", helper, "on"]
            operation.running = true
        }
    }

    Component.onCompleted: refresh()
    // A wall-clock gap reveals suspend/resume without polling the EC. Only a
    // session that explicitly enabled Fan+ reapplies the validated ON command.
    Timer {
        interval: 15000; repeat: true; running: true
        onTriggered: root.checkResume(Date.now())
    }
    Process {
        id: operation
        stdout: StdioCollector { id: output }
        stderr: StdioCollector { id: diagnostics }
        onExited: (code, exitStatus) => {
            const data = root.parse(output.text)
            root.error = String(data.error || (code === 0 ? "" : diagnostics.text.trim()) || "")
            root.state = code === 0 && ["active", "off"].includes(data.state)
                ? data.state : data.state === "unsupported" ? "unsupported" : "error"
            if (root.state === "active") root.lastConfirmedActive = true
            else if (root.state === "off" || root.state === "unsupported") root.lastConfirmedActive = false
            root.pending = ""
        }
    }
}
