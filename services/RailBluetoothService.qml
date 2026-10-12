import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

Scope {
    id: root
    property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: Bluetooth.devices.values
    readonly property bool available: !!adapter
    readonly property bool powered: available && adapter.enabled
    readonly property bool scanning: available && adapter.discovering
    property var scanAdapter: null
    property string error: ""
    property string action: ""
    property string targetAddress: ""
    property string pairPrompt: ""
    property string lastPrompt: ""
    readonly property bool busy: actionProcess.running
    readonly property bool needsPin: /enter.*(pin|passkey)/i.test(pairPrompt)
    property string controlScript: Quickshell.shellDir + "/scripts/velora-bluetooth-control"

    function scan() {
        error = ""
        if (!powered) { error = available ? "Ative o Bluetooth para buscar dispositivos." : "Bluetooth indisponível."; return }
        if (!adapter.discovering) { scanAdapter = adapter; adapter.discovering = true }
        scanDeadline.restart(); scanCheck.restart()
    }
    function stopScan() {
        scanDeadline.stop(); scanCheck.stop()
        if (scanAdapter) scanAdapter.discovering = false
        scanAdapter = null
    }
    function run(actionName, address) {
        if (busy || !available || !address) return
        stopScan(); error = ""; pairPrompt = ""; lastPrompt = ""
        action = actionName; targetAddress = address
        actionProcess.command = [controlScript, actionName === "pair" ? "pair-session" : actionName, address]
        actionProcess.running = true
    }
    function pair(address) { run("pair", address) }
    function remove(address) { run("remove", address) }
    function powerOn() {
        if (available && !busy) { error = ""; adapter.enabled = true; powerCheck.restart() }
    }
    function answer(value) {
        if (busy && action === "pair" && String(value).trim()) {
            actionProcess.write(String(value).trim() + "\n")
            pairPrompt = ""
        }
    }
    function cancel() {
        if (busy) { actionProcess.running = false; error = "Pareamento cancelado." }
        pairPrompt = ""
    }
    Component.onDestruction: stopScan()
    Timer { id: scanDeadline; interval: 15000; onTriggered: root.stopScan() }
    Timer { id: scanCheck; interval: 1600; onTriggered: if (!root.scanning) root.error = "Não foi possível iniciar a busca." }
    Timer { id: powerCheck; interval: 1600; onTriggered: { if (root.powered) root.scan(); else root.error = "Não foi possível ativar o Bluetooth." } }
    Process {
        id: actionProcess
        stdinEnabled: true
        stdout: StdioCollector {
            id: actionOutput
            waitForEnd: false
            onTextChanged: {
                const clean = text.replace(/\x1b\[[0-9;]*[A-Za-z]/g, "").replace(/\r/g, "\n")
                const lines = clean.split("\n").filter(s => /confirm passkey|request confirmation|enter.*(pin|passkey)|authorize service|display.*(pin|passkey)/i.test(s))
                if (lines.length) {
                    const prompt = lines[lines.length - 1].trim()
                    if (prompt !== root.lastPrompt) { root.lastPrompt = prompt; root.pairPrompt = prompt }
                }
            }
        }
        stderr: StdioCollector { id: actionErrors }
        onExited: code => {
            const output = actionOutput.text + "\n" + actionErrors.text
            if (code !== 0 || /failed|not available|ERR\|/i.test(output) || (root.action === "pair" && !/pairing successful/i.test(output)))
                root.error = root.action === "pair" ? "Não foi possível parear. Deixe o dispositivo visível e tente novamente." : "Não foi possível remover o dispositivo."
            root.pairPrompt = ""; root.action = ""; root.targetAddress = ""
        }
    }
}
