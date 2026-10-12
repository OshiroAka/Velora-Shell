import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

Scope {
    id: root
    required property var status
    property var palette: null
    property string activeType: ""
    property bool enabled: true
    property bool reducedMotion: false
    property var network: ({ available: false })
    property var power: ({ available: false, profiles: [] })
    property var usb: ({ available: false, devices: [] })
    property var capabilities: ({})
    property string error: ""
    property var previousTraffic: null
    property real download: -1
    property real upload: -1
    property var previousCpu: null
    property real cpuUsage: -1
    property bool catAnimation: true
    property string oneThing: ""
    property var notes: []
    property string selectedNote: ""
    property bool loaded: false
    property bool saving: false
    property string saveError: ""
    property bool caffeineRequested: false
    property double caffeineUntil: 0
    property double now: Date.now()
    readonly property bool caffeineActive: caffeineRequested && inhibitor.running
    readonly property bool powerBusy: profileWrite.running
    readonly property bool actionBusy: actionProcess.running
    readonly property string helper: Quickshell.shellDir + "/scripts/velora-topbar-system"
    readonly property bool networkChanging: status.wifiDevice && status.wifiDevice.state === ConnectionState.Connecting
    readonly property real wifiStrength: status.activeNetwork ? Number(status.activeNetwork.signalStrength) : 0
    readonly property string statePath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/velora-shell/topbar-tools.json"
    function parse(text) {
        try { return JSON.parse(text) } catch (e) { return { available: false, error: "Resposta indisponível" } }
    }
    function refresh() {
        if (activeType === "wifi" && !networkRead.running) networkRead.running = true
        if (activeType === "battery" && !profileRead.running && !profileWrite.running) profileRead.running = true
        if (activeType === "usb" && !usbRead.running) usbRead.running = true
    }
    function setProfile(profile) {
        if (profileWrite.running || !power.available || power.profiles.indexOf(profile) < 0) return
        profileWrite.command = ["python3", helper, "profiles", profile]; profileWrite.running = true
    }
    function runAction(name) {
        if (actionProcess.running) return
        error = ""; actionProcess.command = ["python3", helper, "action", name]; actionProcess.running = true
    }
    function keepAwake(minutes) {
        if (!capabilities.inhibit) { error = "Inibição de suspensão indisponível"; return }
        now = Date.now(); error = ""
        caffeineUntil = minutes > 0 ? now + minutes * 60000 : 0
        caffeineRequested = true
    }
    function stopAwake() { caffeineRequested = false; caffeineUntil = 0 }
    function save() { if (loaded) { saving = true; saveError = ""; saveDelay.restart() } }
    function writeState() {
        stateFile.setText(JSON.stringify({oneThing: oneThing, notes: notes, catAnimation: catAnimation}) + "\n")
    }
    function newNote(initialText) {
        const id = String(Date.now()) + "-" + Math.random().toString(36).slice(2,6)
        notes = notes.concat([{ id: id, text: typeof initialText === "string" ? initialText : "", pinned: false }]); selectedNote = id; save()
    }
    function editNote(id, text) {
        notes = notes.map(note => note.id === id ? Object.assign({}, note, {text: text}) : note); save()
    }
    function pinNote(id) {
        notes = notes.map(note => note.id === id ? Object.assign({}, note, {pinned: !note.pinned}) : note); save()
    }
    function deleteNote(id) {
        notes = notes.filter(note => note.id !== id); selectedNote = notes.length ? notes[0].id : ""; save()
    }
    function sampleCpu(text) {
        const values = text.split("\n")[0].trim().split(/\s+/).slice(1,9).map(Number)
        if (values.length < 4 || values.some(v => !Number.isFinite(v))) { cpuUsage = -1; return }
        const total = values.reduce((a,b) => a+b, 0), idle = values[3] + (values[4] || 0)
        if (previousCpu && total > previousCpu.total)
            cpuUsage = Math.max(0, Math.min(100, 100 * (1 - (idle - previousCpu.idle) / (total - previousCpu.total))))
        previousCpu = {total: total, idle: idle}
    }
    function sampleTraffic(text) {
        const name = String(network.interface || "")
        const row = text.split("\n").find(line => line.trim().startsWith(name + ":"))
        if (!name || !row) { previousTraffic = null; download = -1; upload = -1; return }
        const values = row.split(":")[1].trim().split(/\s+/).map(Number), now = Date.now()
        if (previousTraffic && previousTraffic.name === name && now > previousTraffic.at) {
            const seconds = (now - previousTraffic.at) / 1000
            download = Math.max(0, (values[0] - previousTraffic.rx) / seconds)
            upload = Math.max(0, (values[8] - previousTraffic.tx) / seconds)
        }
        previousTraffic = { name: name, rx: values[0], tx: values[8], at: now }
    }
    onActiveTypeChanged: { error = ""; refresh(); if (activeType !== "wifi") { previousTraffic=null; download=-1; upload=-1 } }
    onOneThingChanged: save()
    onCatAnimationChanged: save()
    Component.onCompleted: capabilityRead.running = true
    Component.onDestruction: {
        if (loaded && saving) { stateFile.blockWrites = true; writeState() }
    }
    Timer { interval: root.activeType === "usb" ? 3000 : 10000; running: ["battery","wifi","usb"].includes(root.activeType); repeat: true; onTriggered: root.refresh() }
    Timer { interval: 1000; running: root.caffeineRequested; repeat: true; onTriggered: { root.now=Date.now(); if(root.caffeineUntil > 0 && root.now >= root.caffeineUntil) root.stopAwake() } }
    Process {
        id: inhibitor
        command: ["systemd-inhibit", "--what=idle:sleep", "--who=Velora", "--why=Top bar keep awake", "--mode=block", "python3", root.helper, "awake"]
        stdinEnabled: true
        running: root.caffeineRequested
        stderr: StdioCollector { id: inhibitorError }
        onExited: (code, exitStatus) => {
            if (root.caffeineRequested) { root.caffeineRequested=false; root.error=inhibitorError.text.trim() || "Não foi possível manter o sistema acordado" }
        }
    }
    Process { id: networkRead; command: ["python3", root.helper, "network"]; stdout: StdioCollector { id: networkOutput } onExited: root.network=root.parse(networkOutput.text) }
    Process { id: profileRead; command: ["python3", root.helper, "profiles"]; stdout: StdioCollector { id: profileOutput } onExited: root.power=root.parse(profileOutput.text) }
    Process { id: profileWrite; stdout: StdioCollector { id: profileWriteOutput } onExited: root.power=root.parse(profileWriteOutput.text) }
    Process { id: usbRead; command: ["python3", root.helper, "usb"]; stdout: StdioCollector { id: usbOutput } onExited: root.usb=root.parse(usbOutput.text) }
    Process { id: capabilityRead; command: ["python3", root.helper, "capabilities"]; stdout: StdioCollector { id: capabilityOutput } onExited: root.capabilities=root.parse(capabilityOutput.text) }
    Process { id: actionProcess; stdout: StdioCollector { id: actionOutput } onExited: root.error=root.parse(actionOutput.text).error || "" }
    FileView { id: traffic; path: root.activeType === "wifi" ? "/proc/net/dev" : ""; printErrors: false; onLoaded: root.sampleTraffic(text()) }
    Timer { interval: 2000; running: root.activeType === "wifi"; repeat: true; onTriggered: traffic.reload() }
    FileView { id: cpu; path: root.enabled ? "/proc/stat" : ""; printErrors: false; onLoaded: root.sampleCpu(text()) }
    Timer { interval: 2000; running: root.enabled; repeat: true; onTriggered: cpu.reload() }
    FileView {
        id: stateFile; path: root.statePath; atomicWrites: true; printErrors: false
        onLoaded: {
            if(root.loaded) return
            try {
                const state=JSON.parse(text())
                root.oneThing=String(state.oneThing || "")
                root.notes=Array.isArray(state.notes) ? state.notes.filter(n => n && typeof n.id === "string" && typeof n.text === "string").slice(0,500) : []
                root.selectedNote=root.notes.length ? root.notes[0].id : ""
                root.catAnimation=state.catAnimation !== false
            } catch(e) { console.warn("Top bar tools: invalid saved state") }
            root.loaded=true
        }
        onLoadFailed: root.loaded=true
        onSaved: { root.saving = saveDelay.running; root.saveError = "" }
        onSaveFailed: { root.saving = false; root.saveError = "Não foi possível salvar as notas" }
    }
    Timer { id: saveDelay; interval: 300; onTriggered: root.writeState() }
}
