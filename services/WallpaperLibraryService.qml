pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

// Quick inventory and thumbnail enrichment share identities, not a model reset.
Scope {
    id: root
    property bool active: false
    property string scanScript: Quickshell.shellDir + "/scripts/velora-wallpaper-scan"
    property string watchScript: Quickshell.shellDir + "/scripts/velora-wallpaper-index"
    property var entries: []
    property bool ready: false
    readonly property bool running: quick.running || enrich.running
    property string error: ""
    property bool quickQueued: false
    property bool enrichQueued: false
    property bool forceEnrichment: false
    property var available: ({})
    property var updates: ({})

    function refresh(force) {
        forceEnrichment = forceEnrichment || force === true
        if (quick.running) { quickQueued=true; return }
        quick.running=true
    }
    function replaceInventory(inventory) {
        const previous = new Map(entries.map(entry=>[entry.key,entry]))
        const keys = ({})
        const next = inventory.map(entry=> {
            keys[entry.key]=true
            const old=previous.get(entry.key)
            return old && JSON.stringify(old)===JSON.stringify(entry) ? old : entry
        })
        available=keys
        if (JSON.stringify(next)!==JSON.stringify(entries)) entries=next
        ready=true
    }
    function queueUpdate(entry) {
        if (!entry.key || !available[entry.key]) return
        updates[entry.key]=entry
        if (!flush.running) flush.start()
    }
    function flushUpdates() {
        const pending=updates
        updates=({})
        let changed=false
        const next=entries.map(old=> {
            if (!pending[old.key]) return old
            const entry=Object.assign({},pending[old.key],{addedAt:old.addedAt || 0})
            if (JSON.stringify(entry)===JSON.stringify(old)) return old
            changed=true
            return entry
        })
        if (changed) entries=next
    }
    function requestEnrichment() {
        if (enrich.running) { enrichQueued=true; return }
        enrich.command=[scanScript,"--json"].concat(forceEnrichment ? ["--refresh"] : [])
        forceEnrichment=false
        enrich.running=true
    }
    Timer { id: flush; interval: 24; onTriggered: root.flushUpdates() }
    Timer { id: changed; interval: 160; onTriggered: root.refresh(false) }
    Process {
        id: watcher
        running: root.active
        command: ["python3",root.watchScript,"--watch"]
        stdout: SplitParser {
            onRead: line => {
                if (line==="READY") root.refresh(false)
                else if (line==="CHANGED") changed.restart()
            }
        }
    }
    Process {
        id: quick
        property var inventory: []
        property bool complete: false
        command: [root.scanScript,"--json","--quick"]
        onStarted: { quick.inventory=[];quick.complete=false;root.error="" }
        stdout: SplitParser {
            onRead: line => {
                if (line==="BEGIN" || !line) return
                if (line==="END") {
                    quick.complete=true
                    root.replaceInventory(quick.inventory)
                } else {
                    try { quick.inventory.push(JSON.parse(line)) }
                    catch(error) { console.warn("Wallpaper inventory record: "+error) }
                }
            }
        }
        onExited: code => {
            if (code!==0 || !quick.complete) root.error="Não foi possível atualizar a biblioteca de wallpapers."
            else root.requestEnrichment()
            if (root.quickQueued) { root.quickQueued=false;Qt.callLater(function(){quick.running=true}) }
        }
    }
    Process {
        id: enrich
        command: [root.scanScript,"--json"]
        stdout: SplitParser {
            onRead: line => {
                if (!line || line==="BEGIN") return
                if (line==="END") { root.flushUpdates();return }
                try { root.queueUpdate(JSON.parse(line)) }
                catch(error) { console.warn("Wallpaper preview record: "+error) }
            }
        }
        onExited: {
            root.flushUpdates()
            if (root.enrichQueued) { root.enrichQueued=false;Qt.callLater(root.requestEnrichment) }
        }
    }
}
