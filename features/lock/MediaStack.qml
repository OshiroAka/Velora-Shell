import QtQuick
import QtQuick.Effects

Item {
    id: root

    required property var media
    required property var theme
    required property var motion
    property url fallbackArt

    property var coverHistory: []
    property string currentKey: ""
    property string currentTitle: ""
    property string currentArtist: ""
    property string pendingKey: ""
    property string pendingTitle: ""
    property string pendingArtist: ""
    property url pendingArt: ""
    property real transitionProgress: 0
    property bool transitioning: false
    property bool preparing: false
    property bool settling: false
    property int pendingDirection: 1
    property int handoffElapsed: 0
    readonly property bool hovered: stackHover.hovered
    readonly property real cardWidth: 218
    readonly property real cardHeight: 244
    readonly property real cardX: (width - cardWidth) / 2
    readonly property real frontY: 78
    readonly property real incomingTravel: 58
    readonly property real depthProgress: smoothstep(0.06, 0.86, transitionProgress)
    readonly property real incomingProgress: smoothstep(0.02, 0.94, transitionProgress)

    width: 292
    height: 350

    function clamp01(value) {
        return Math.max(0, Math.min(1, value))
    }

    function smoothstep(from, to, value) {
        const t = clamp01((value - from) / (to - from))
        return t * t * (3 - 2 * t)
    }

    function blurPulse(value) {
        if (value <= 0 || value >= 0.98)
            return 0
        const t = value < 0.40
            ? value / 0.40
            : 1 - (value - 0.40) / 0.58
        const bounded = clamp01(t)
        return bounded * bounded * (3 - 2 * bounded)
    }

    function mediaKey() {
        return String(media.title || "") + "\u0000"
            + String(media.artist || "") + "\u0000" + String(media.artUrl || "")
    }

    function resolvedArt() {
        return String(media.artUrl || "").length ? media.artUrl : fallbackArt
    }

    function inferDirection(nextKey) {
        const requestedAt = Number(media.transportRequestedAt || 0)
        const requestedDirection = Number(media.transportDirection || 0)
        if (requestedDirection !== 0 && Date.now() - requestedAt < 2200) {
            if (typeof media.clearTransportIntent === "function")
                media.clearTransportIntent()
            return requestedDirection < 0 ? -1 : 1
        }

        // Also recognizes a back action issued outside Velora. The entry after
        // the current one is the last previously observed track.
        const entries = media.historyEntries || []
        if (entries.length > 1
                && String((entries[1] || ({})).key || "") === String(nextKey))
            return -1
        return 1
    }

    function rotatedCovers(previous) {
        const next = []
        function append(candidate) {
            const normalized = String(candidate || "")
            if (normalized.length && !next.some(item => String(item) === normalized))
                next.push(candidate)
        }

        append(pendingArt)
        for (let index = 0; index < previous.length && next.length < 3; index += 1)
            append(previous[index])
        const entries = media.historyEntries || []
        for (let index = 0; index < entries.length && next.length < 3; index += 1)
            append((entries[index] || ({})).art)
        while (next.length < 3)
            next.push(next[next.length - 1] || fallbackArt)
        return next.slice(0, 3)
    }

    function restorePersistentHistory(frontKey, frontArt) {
        const restored = [frontArt]
        const entries = media.historyEntries || []
        for (let index = 0; index < entries.length && restored.length < 3; index += 1) {
            const entry = entries[index] || ({})
            const art = String(entry.art || "")
            if (String(entry.key || "") !== frontKey && art.length
                    && !restored.some(candidate => String(candidate) === art))
                restored.push(art)
        }
        while (restored.length < 3)
            restored.push(restored[restored.length - 1] || fallbackArt)
        let changed = coverHistory.length !== restored.length
        for (let index = 0; index < restored.length && !changed; index += 1)
            changed = String(coverHistory[index] || "") !== String(restored[index] || "")
        if (changed)
            coverHistory = restored
    }

    function recordCurrent(key, title, artist, art) {
        if (media.hasPlayer && String(media.artUrl || "").length
                && typeof media.recordHistory === "function")
            media.recordHistory(key, title, artist, String(art || ""))
    }

    function syncTrack() {
        const nextKey = mediaKey()
        const nextArt = resolvedArt()
        if (!currentKey.length) {
            currentKey = nextKey
            currentTitle = media.title
            currentArtist = media.artist
            recordCurrent(nextKey, currentTitle, currentArtist, nextArt)
            restorePersistentHistory(nextKey, nextArt)
            return
        }
        if (nextKey === currentKey)
            return
        if (transitioning || settling) {
            trackDebounce.restart()
            return
        }
        if (preparing && nextKey === pendingKey)
            return
        pendingKey = nextKey
        pendingTitle = media.title
        pendingArtist = media.artist
        pendingArt = nextArt
        pendingDirection = inferDirection(nextKey)
        preparing = true
        preloadTimeout.restart()
        Qt.callLater(startPreparedTransition)
    }

    function startPreparedTransition() {
        if (!preparing)
            return
        if (pendingLoader.status !== Image.Ready
                && pendingLoader.status !== Image.Error)
            return
        preparing = false
        preloadTimeout.stop()
        transitioning = true
        trackMotion.restart()
    }

    function completeTransition() {
        const previous = coverHistory.slice()
        settling = true
        handoffElapsed = 0
        coverHistory = rotatedCovers(previous)
        currentKey = pendingKey
        currentTitle = pendingTitle
        currentArtist = pendingArtist
        recordCurrent(currentKey, currentTitle, currentArtist, pendingArt)
        transitionProgress = 0
        transitioning = false
        handoffTimer.restart()
    }

    HoverHandler { id: stackHover }

    WheelHandler {
        onWheel: function(event) {
            if (event.angleDelta.y > 0)
                root.media.previous()
            else
                root.media.next()
            event.accepted = true
        }
    }

    Repeater {
        id: coverRepeater
        model: 3

        Item {
            id: coverCard
            required property int index
            readonly property real depth: root.depthProgress
            readonly property real fan: root.hovered && !root.transitioning ? 1 : 0
            readonly property bool targetArtReady: coverFace.artReady

            x: root.cardX
            y: index === 0 ? root.frontY - 40 * depth
                : (index === 1 ? 38 - 34 * depth - 8 * fan
                    : 4 - 30 * depth - 14 * fan)
            width: root.cardWidth
            height: root.cardHeight
            z: 20 - index
            visible: !(root.settling && index === 0)
            scale: index === 0 ? 1 - 0.09 * depth
                : (index === 1 ? 0.91 - 0.08 * depth : 0.83 - 0.07 * depth)
            opacity: index === 0 ? 1 - 0.14 * depth
                : (index === 1 ? 0.86 - 0.18 * depth
                    : 0.68 * (1 - root.smoothstep(0.24, 0.82, root.transitionProgress)))
            transformOrigin: Item.Center
            layer.enabled: root.transitioning || index > 0
            layer.smooth: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blurMax: 58
                autoPaddingEnabled: true
                blur: coverCard.index === 0
                    ? 0.18 * coverCard.depth + root.blurPulse(root.transitionProgress) * 0.18
                    : (coverCard.index === 1
                        ? 0.18 + 0.16 * coverCard.depth
                        : 0.34 + 0.12 * coverCard.depth)
            }

            MediaCoverFace {
                id: coverFace
                anchors.fill: parent
                media: root.media
                theme: root.theme
                motion: root.motion
                artSource: root.coverHistory[coverCard.index]
                    || root.coverHistory[0] || root.fallbackArt
                fallbackArt: root.fallbackArt
                title: root.currentTitle
                artist: root.currentArtist
                showUi: coverCard.index === 0
                interactive: coverCard.index === 0 && !root.transitioning
                uiOpacity: coverCard.index === 0
                    ? 1 - root.smoothstep(0.04, 0.38, root.transitionProgress) : 0
                contourStrength: coverCard.index === 0 ? 1
                    : (coverCard.index === 1 ? 0.52 : 0.34)
                shadowStrength: coverCard.index === 0 ? 1 : 0.54
                instantArtSwitch: root.settling
            }

            Behavior on y {
                enabled: !root.transitioning
                NumberAnimation { duration: root.motion.hover; easing.type: Easing.OutCubic }
            }
        }
    }

    Item {
        id: incomingCard
        x: root.cardX
        y: root.settling ? root.frontY
            : root.frontY - root.pendingDirection * root.incomingTravel
                * (1 - root.incomingProgress)
        width: root.cardWidth
        height: root.cardHeight
        z: 50
        visible: root.transitioning || root.settling
        opacity: root.settling ? 1
            : root.smoothstep(0.02, 0.62, root.transitionProgress)
        scale: root.settling ? 1 : 1.14 - 0.14 * root.incomingProgress
        transformOrigin: Item.Center
        layer.enabled: visible
        layer.smooth: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 58
            autoPaddingEnabled: true
            blur: root.settling ? 0
                : 0.14 * (1 - root.incomingProgress)
                    + root.blurPulse(root.transitionProgress) * 0.34
        }

        MediaCoverFace {
            anchors.fill: parent
            media: root.media
            theme: root.theme
            motion: root.motion
            artSource: root.pendingArt
            fallbackArt: root.coverHistory[0] || root.fallbackArt
            title: root.pendingTitle
            artist: root.pendingArtist
            showUi: true
            interactive: false
            uiOpacity: root.settling ? 1
                : root.smoothstep(0.70, 0.98, root.transitionProgress)
            contourStrength: 1
            shadowStrength: 1
        }
    }

    Timer {
        id: trackDebounce
        interval: 140
        repeat: false
        onTriggered: root.syncTrack()
    }

    Image {
        id: pendingLoader
        visible: false
        source: root.pendingArt
        asynchronous: true
        cache: true
        sourceSize.width: Math.round(root.cardWidth * 2)
        sourceSize.height: Math.round(root.cardHeight * 2)
        onStatusChanged: {
            if (status === Image.Ready || status === Image.Error)
                root.startPreparedTransition()
        }
    }

    Timer {
        id: preloadTimeout
        interval: 1200
        repeat: false
        onTriggered: {
            if (root.preparing) {
                root.preparing = false
                root.transitioning = true
                trackMotion.restart()
            }
        }
    }

    Timer {
        id: handoffTimer
        interval: 16
        repeat: true
        onTriggered: {
            root.handoffElapsed += interval
            const front = coverRepeater.itemAt(0)
            if ((front && front.targetArtReady && root.handoffElapsed >= 32)
                    || root.handoffElapsed >= 1200) {
                stop()
                root.settling = false
                if (root.mediaKey() !== root.currentKey)
                    trackDebounce.restart()
            }
        }
    }

    SequentialAnimation {
        id: trackMotion
        NumberAnimation {
            target: root
            property: "transitionProgress"
            from: 0
            to: 1
            duration: root.motion.reduced ? 100 : 400
            easing.type: Easing.Linear
        }
        ScriptAction { script: root.completeTransition() }
    }

    Connections {
        target: root.media
        function onTitleChanged() { trackDebounce.restart() }
        function onArtistChanged() { trackDebounce.restart() }
        function onArtUrlChanged() { trackDebounce.restart() }
        function onHistoryEntriesChanged() {
            if (!root.transitioning && root.currentKey.length)
                root.restorePersistentHistory(root.currentKey, root.resolvedArt())
        }
    }

    Component.onCompleted: Qt.callLater(syncTrack)
}
