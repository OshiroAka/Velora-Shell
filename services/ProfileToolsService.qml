import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    property var capabilities: ({})
    property var outputs: []
    property string error: ""
    property string currentAction: ""
    readonly property bool busy: runner.running || captureSettle.running
    readonly property bool recording: runner.running && currentAction === "record"
    readonly property string helper: Quickshell.shellDir + "/scripts/velora-profile-tools"
    function refresh() {
        if (!probe.running) probe.running = true
        if (!audioQuery.running) audioQuery.running = true
    }
    function run(action) {
        if (busy) return
        error = ""
        currentAction = action
        runner.command = ["python3", helper, action]
        // Give the compositor the hidden-surface commit before starting capture.
        captureSettle.start()
    }
    function stopRecording() { if (recording) runner.signal(2) }
    Timer { id: captureSettle; interval: 50; onTriggered: runner.running = true }
    function selectOutput(id) {
        if (!audioWriter.running) {
            audioWriter.command = ["python3", Quickshell.shellDir + "/scripts/velora-audio-devices", "set-default", String(id)]
            audioWriter.running = true
        }
    }
    Process {
        id: probe
        command: ["python3", root.helper, "status"]
        stdout: StdioCollector { onStreamFinished: {
            try { root.capabilities = JSON.parse(text) } catch (error) { root.capabilities = ({}) }
        } }
    }
    Process {
        id: runner
        stderr: StdioCollector { id: runError }
        onExited: code => {
            root.error = code === 0 ? "" : runError.text.trim() || "A ferramenta não pôde ser executada."
            root.currentAction = ""
        }
    }
    Process {
        id: audioQuery
        command: ["python3", Quickshell.shellDir + "/scripts/velora-audio-devices", "status"]
        stdout: StdioCollector { onStreamFinished: {
            root.outputs = text.split("\n").filter(line => line.startsWith("SINK|")).map(line => {
                const fields = line.split("|")
                return {id: fields[1], selected: fields[2] === "yes", name: fields.slice(3).join("|")}
            })
        } }
    }
    Process {
        id: audioWriter
        stdout: StdioCollector { id: audioResult }
        onExited: code => {
            root.error = code === 0 ? "" : "Não foi possível trocar a saída de áudio."
            root.refresh()
        }
    }
}
