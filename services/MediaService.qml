import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Scope {
    id: root

    property bool active: false
    property int playersRevision: 0
    property real sampledPosition: 0
    // Transport intent lets the visual stack distinguish a forward skip from
    // returning to the previous song. MPRIS metadata itself has no direction.
    property int transportDirection: 0
    property double transportRequestedAt: 0
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME")
        || homeDir + "/.config"
    readonly property string historyPath: configHome
        + "/velora-shell/media-history.json"
    property var historyEntries: []
    readonly property var players: Mpris.players.values
    readonly property var player: choosePlayer(playersRevision, players.length)

    readonly property bool hasPlayer: player !== null
    readonly property string identity: player ? String(player.identity || "") : ""
    readonly property string title: player && String(player.trackTitle || "").length
        ? String(player.trackTitle) : "No active track"
    readonly property string artist: player && String(player.trackArtist || "").length
        ? String(player.trackArtist) : "Velora Shell"
    readonly property string artUrl: player ? String(player.trackArtUrl || "") : ""
    readonly property bool playing: player ? Boolean(player.isPlaying) : false
    readonly property bool canToggle: player ? Boolean(player.canTogglePlaying) : false
    readonly property bool canNext: player ? Boolean(player.canGoNext) : false
    readonly property bool canPrevious: player ? Boolean(player.canGoPrevious) : false
    readonly property real length: player ? Number(player.length || 0) : 0
    readonly property real progress: length > 0
        ? Math.max(0, Math.min(1, sampledPosition / length)) : 0

    function score(candidate) {
        if (!candidate)
            return -1
        let result = candidate.isPlaying ? 100 : 0
        if (String(candidate.trackTitle || "").length)
            result += 20
        if (String(candidate.trackArtist || "").length)
            result += 10
        return result
    }

    function choosePlayer(revision, count) {
        revision
        count
        const available = Mpris.players.values
        if (!available || available.length === 0)
            return null
        let best = available[0]
        let bestScore = score(best)
        for (let index = 1; index < available.length; index += 1) {
            const candidateScore = score(available[index])
            if (candidateScore > bestScore) {
                best = available[index]
                bestScore = candidateScore
            }
        }
        return best
    }

    function togglePlaying() {
        if (!canToggle)
            return false
        player.togglePlaying()
        return true
    }

    function previous() {
        if (!canPrevious)
            return false
        transportDirection = -1
        transportRequestedAt = Date.now()
        player.previous()
        return true
    }

    function next() {
        if (!canNext)
            return false
        transportDirection = 1
        transportRequestedAt = Date.now()
        player.next()
        return true
    }

    function clearTransportIntent() {
        transportDirection = 0
        transportRequestedAt = 0
    }

    function refreshPosition() {
        sampledPosition = player ? Number(player.position || 0) : 0
    }

    function recordHistory(key, title, artist, art) {
        const normalizedKey = String(key || "")
        const normalizedArt = String(art || "")
        if (!normalizedKey.length || !normalizedArt.length)
            return false
        const next = [{
            key: normalizedKey,
            title: String(title || ""),
            artist: String(artist || ""),
            art: normalizedArt
        }]
        for (let index = 0; index < historyEntries.length && next.length < 3; index += 1) {
            const entry = historyEntries[index] || ({})
            if (String(entry.key || "") !== normalizedKey
                    && String(entry.art || "").length)
                next.push(entry)
        }
        historyEntries = next
        historySave.restart()
        return true
    }

    function loadHistory(text) {
        try {
            const document = JSON.parse(text || "{}")
            const entries = Array.isArray(document.entries) ? document.entries : []
            const normalized = entries.filter(entry => entry
                && typeof entry === "object" && String(entry.art || "").length).slice(0, 3)
            if (JSON.stringify(normalized) !== JSON.stringify(historyEntries))
                historyEntries = normalized
        } catch (parseError) {
            console.warn("Ignoring invalid media history:", String(parseError))
            historyEntries = []
        }
    }

    onPlayerChanged: refreshPosition()

    Connections {
        target: Mpris.players
        function onValuesChanged() { root.playersRevision += 1 }
    }

    Timer {
        // The preview does not need a video-rate progress clock. A five-second
        // cadence keeps the card current without waking the render path every
        // second while the glass scene is idle.
        interval: 5000
        repeat: true
        running: root.active && root.playing
        onTriggered: root.refreshPosition()
    }

    FileView {
        id: historyFile
        path: root.historyPath
        atomicWrites: true
        watchChanges: true
        printErrors: false
        onLoaded: root.loadHistory(text())
        onFileChanged: reload()
        onLoadFailed: function(errorCode) {
            if (errorCode === FileViewError.FileNotFound)
                root.historyEntries = []
        }
    }

    Timer {
        id: historySave
        interval: 180
        repeat: false
        onTriggered: historyFile.setText(JSON.stringify({
            version: 1,
            entries: root.historyEntries
        }, null, 2) + "\n")
    }
}
