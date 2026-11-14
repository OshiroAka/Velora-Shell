import QtQuick
import Quickshell
import Quickshell.Io

// Event-driven ingress for a real task producer. No process-name heuristics,
// filesystem polling, synthetic progress or automatic Codex status inference.
Scope {
    id: root
    property var current: ({ id: "", phase: "idle", agent: "", label: "", detail: "", progress: -1 })
    readonly property bool shown: current.phase !== "idle"
    readonly property bool busy: current.phase === "running"

    function update(document) {
        let event
        try { event = JSON.parse(document) } catch (error) { return false }
        if (!event || typeof event.id !== "string" || !event.id.trim() || event.id.length > 128) return false
        if (!["running", "waiting", "completed", "failed", "cancelled"].includes(event.phase)) return false
        const terminal = !["running", "waiting"].includes(event.phase)
        // A late completion from a previous producer cannot hide the current task.
        if (terminal && event.id !== current.id) return false
        if (typeof event.agent !== "string" || !event.agent.trim() || event.agent.length > 48) return false
        if (event.label !== undefined && (typeof event.label !== "string" || event.label.length > 96)) return false
        if (event.detail !== undefined && (typeof event.detail !== "string" || event.detail.length > 160)) return false
        const progress = event.progress === undefined || event.progress === null ? -1 : event.progress
        if (progress !== -1 && (typeof progress !== "number" || !Number.isFinite(progress) || progress < 0 || progress > 1)) return false
        const ttl = event.ttlMs === undefined ? 30000 : event.ttlMs
        if (typeof ttl !== "number" || !Number.isFinite(ttl) || ttl < 1000 || ttl > 120000) return false
        const labels = { running: "Em execução", waiting: "Aguardando", completed: "Concluído", failed: "Falhou", cancelled: "Cancelado" }
        expiry.stop()
        current = { id: event.id, phase: event.phase, agent: event.agent.trim(),
            label: (event.label || labels[event.phase]).trim(), detail: (event.detail || "").trim(), progress: progress }
        expiry.interval = terminal ? 1600 : ttl
        expiry.start()
        return true
    }
    function clear(id) {
        if (id !== current.id) return false
        expiry.stop()
        current = { id: "", phase: "idle", agent: "", label: "", detail: "", progress: -1 }
        return true
    }
    Timer { id: expiry; onTriggered: root.clear(root.current.id) }
    IpcHandler {
        target: "execution"
        function update(document: string): bool { return root.update(document) }
        function clear(id: string): bool { return root.clear(id) }
        function status(): string { return JSON.stringify(root.current) }
    }
}
