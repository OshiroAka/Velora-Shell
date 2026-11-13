import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    property bool active: false
    property string source: ""
    property var colors: []
    property string requestedSource: ""
    property var cached: ({})
    readonly property bool ready: colors.length === 6
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("../scripts/velora-album-palette").toString().replace("file://", ""))

    function fetch() {
        if (!active || !source || cached[source] || extraction.running) return
        requestedSource = source
        extraction.command = ["python3", helper, source]
        extraction.running = true
    }
    function accept(text) {
        try {
            const result = JSON.parse(text).colors
            if (!Array.isArray(result) || result.length !== 6
                || !result.every(c => Number.isFinite(c) && c >= 0 && c <= 1)) return
            const next = Object.assign({}, cached)
            next[requestedSource] = result
            if (Object.keys(next).length > 12) delete next[Object.keys(next)[0]]
            cached = next
            if (requestedSource === source) colors = result
        } catch (_) {}
    }
    onSourceChanged: { colors = cached[source] || []; Qt.callLater(fetch) }
    onActiveChanged: {
        if (active) Qt.callLater(fetch)
        else extraction.running = false
    }
    Process {
        id: extraction
        stdout: StdioCollector { onStreamFinished: root.accept(text) }
        onExited: if (root.active && root.source !== root.requestedSource) Qt.callLater(root.fetch)
    }
}
