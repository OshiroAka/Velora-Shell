import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Services.Mpris
import "."

Item {
    id: root

    property int playersVersion: 0
    property var player: selectedPlayer(playersVersion, Mpris.players.values.length)

    implicitWidth: visible ? mRow.implicitWidth + ShinConfig.pillPadH * 2 : 0
    implicitHeight: ShinConfig.barH
    visible: ShinConfig.mediaAlwaysVisible || root.player !== null

    property bool opened: ShinPopup.active === "media-tab"
    property bool popupVisible: false
    property bool hoverRoot: false
    property bool hoverPopup: false
    property bool pinnedFromKeyboard: false

    property string title: root.player ? (root.player.trackTitle || "Sem titulo") : "Sem player"
    property string artist: root.player ? (root.player.trackArtist || "Artista") : "Aguardando midia"
    property string artUrl: root.player ? (root.player.trackArtUrl || "") : ""

    readonly property int popupW: Math.max(220, Math.min(340, ShinConfig.mediaPanelWidth))
    readonly property int popupH: Math.max(460, Math.min(680, ShinConfig.mediaPanelHeight))
    readonly property int cardOpenW: popupW
    readonly property int cardOpenH: popupH
    readonly property int cardClosedW: Math.max(54, root.implicitWidth)
    readonly property int cardClosedH: 44

    readonly property int animFast: ShinData.anim(120)
    readonly property int animMed: ShinData.popupAnim(190)

    property real motion: 0.0
    property int motionDir: 1
    property real position: 0
    property real progress: root.player && root.player.length > 0 ? clamp01(root.position / root.player.length) : 0
    property int selectedControl: 1
    property bool favorited: false
    property bool repeatHint: false
    property bool lyricsLoading: false
    property bool lyricsSynced: false
    property int lyricsCurrentIndex: 0
    property var lyricsLines: []
    readonly property string trackSignature: root.title + "|" + root.artist + "|" + (root.player ? Math.round(root.player.length || 0) : 0)

    property var bars: [
        0.26, 0.44, 0.62, 0.38, 0.70, 0.52, 0.84, 0.48,
        0.32, 0.58, 0.76, 0.66, 0.44, 0.36, 0.68, 0.82,
        0.52, 0.40, 0.74, 0.58, 0.46, 0.64, 0.34, 0.50,
        0.72, 0.42, 0.60, 0.36, 0.54, 0.30, 0.46, 0.26
    ]

    function clamp01(v) {
        return Math.max(0, Math.min(1, v))
    }

    function clamp100(v) {
        return Math.max(0, Math.min(100, Math.round(v)))
    }

    function lerp(a, b, t) {
        return a + (b - a) * t
    }

    function emphasizedDecel(t) {
        t = clamp01(t)
        return 1 - Math.pow(1 - t, 3.15)
    }

    function emphasizedAccel(t) {
        t = clamp01(t)
        return Math.pow(t, 2.35)
    }

    function contentT() {
        return clamp01((motion - 0.20) / 0.80)
    }

    function cardW(t) {
        return lerp(cardClosedW, cardOpenW, emphasizedDecel(t))
    }

    function cardH(t) {
        return lerp(cardClosedH, cardOpenH, emphasizedDecel(t))
    }

    function cardY(t) {
        return lerp(-14, 0, emphasizedDecel(t))
    }

    function cardRadius(t) {
        return lerp(22, 18, emphasizedDecel(t))
    }

    function trailT(offset) {
        if (motionDir >= 0)
            return clamp01(motion - offset)
        return clamp01(motion + offset)
    }

    function textOf(v) {
        return v === undefined || v === null ? "" : ("" + v)
    }

    function playerKey(p) {
        if (!p)
            return ""
        return (
            textOf(p.identity) + " " +
            textOf(p.desktopEntry) + " " +
            textOf(p.busName) + " " +
            textOf(p.service) + " " +
            textOf(p.name) + " " +
            textOf(p.trackTitle) + " " +
            textOf(p.trackArtist)
        ).toLowerCase()
    }

    function playerScore(p) {
        if (!p)
            return -9999

        var key = playerKey(p)
        var title = textOf(p.trackTitle).toLowerCase()
        var artist = textOf(p.trackArtist).toLowerCase()
        var art = textOf(p.trackArtUrl)
        var score = 0

        if (key.indexOf("spotify") >= 0)
            score += 600
        if (p.isPlaying)
            score += 130
        if (art.length > 0)
            score += 120
        if (artist.length > 0 && artist !== "unknown artist")
            score += 160
        if (title.length > 0 && title !== "unknown title")
            score += 50
        if (key.indexOf("whatsapp") >= 0 || title.indexOf("whatsapp") >= 0)
            score -= 450

        return score
    }

    function pickPlayer() {
        var list = Mpris.players.values
        if (!list || list.length === 0)
            return null

        var best = list[0]
        var bestScore = playerScore(best)
        for (var i = 1; i < list.length; ++i) {
            var score = playerScore(list[i])
            if (score > bestScore) {
                best = list[i]
                bestScore = score
            }
        }

        return best
    }

    function selectedPlayer(version, count) {
        version
        count
        return pickPlayer()
    }

    function artSource() {
        var src = root.artUrl
        if (!src || src.length === 0)
            return ""
        if (src.indexOf("/") === 0)
            return "file://" + src
        return src
    }

    function formatTime(sec) {
        sec = Math.max(0, Math.floor(sec || 0))
        var m = Math.floor(sec / 60)
        var s = sec % 60
        return m + ":" + (s < 10 ? "0" + s : s)
    }

    function canSetPlayerVolume() {
        return !!(root.player && root.player.canControl && root.player.volumeSupported)
    }

    function playerVolumePercent() {
        if (!root.player)
            return 75
        if (canSetPlayerVolume())
            return clamp100(root.player.volume * 100)
        return 75
    }

    function setPlayerVolumePercent(v) {
        if (!canSetPlayerVolume())
            return
        root.player.volume = clamp100(v) / 100.0
    }

    function setPlayerPositionFromRatio(v) {
        if (!root.player || !root.player.positionSupported || root.player.length <= 0)
            return

        var nextPos = root.player.length * clamp01(v)
        root.position = nextPos
        root.player.position = nextPos
    }

    function randomizeBars() {
        var arr = []
        for (var i = 0; i < 32; ++i) {
            var center = 1.0 - Math.min(1.0, Math.abs(i - 15) / 16)
            var base = root.player && root.player.isPlaying ? 0.22 + center * 0.58 : 0.12 + center * 0.26
            arr.push(Math.max(0.10, Math.min(0.96, base + (Math.random() - 0.5) * 0.30)))
        }
        bars = arr
    }

    function isSpotifyPlayer() {
        return playerKey(root.player).indexOf("spotify") >= 0
    }

    function setFallbackLyric(text) {
        lyricsLoading = false
        lyricsSynced = false
        lyricsCurrentIndex = 0
        lyricsLines = [{ ms: 0, text: text }]
    }

    function fetchLyrics() {
        if (!root.opened && !root.popupVisible)
            return

        if (!root.player || !isSpotifyPlayer()) {
            setFallbackLyric("Spotify nao detectado")
            return
        }

        if (!root.title || root.title.length === 0) {
            setFallbackLyric("Lyrics indisponivel")
            return
        }

        lyricsLoading = true
        lyricsCurrentIndex = 0
        lyricsProc.tmp = []
        lyricsProc.mode = "PLAIN"
        lyricsProc.command = [
            "/home/shira/.config/quickshell/shinbar/scripts/shinbar-lyrics",
            "--title", root.title,
            "--artist", root.artist,
            "--duration", "" + Math.round(root.player ? (root.player.length || 0) : 0)
        ]
        lyricsProc.running = true
    }

    function ingestLyricLine(raw) {
        var line = (raw || "").trim()
        if (line.length === 0)
            return

        if (line.indexOf("MODE:") === 0) {
            lyricsProc.mode = line.slice(5)
            return
        }

        if (line.indexOf("LINE:") !== 0)
            return

        var body = line.slice(5)
        var sep = body.indexOf("|")
        if (sep < 0)
            return

        var ms = parseInt(body.slice(0, sep))
        var text = body.slice(sep + 1)
        if (text.length === 0)
            return

        var next = lyricsProc.tmp.slice()
        next.push({ ms: isNaN(ms) ? 0 : ms, text: text })
        lyricsProc.tmp = next
    }

    function updateLyricsIndex() {
        if (!lyricsSynced || lyricsLines.length === 0)
            return

        var posMs = Math.max(0, Math.floor((root.position || 0) * 1000))
        var idx = 0
        for (var i = 0; i < lyricsLines.length; ++i) {
            if (lyricsLines[i].ms <= posMs)
                idx = i
            else
                break
        }
        lyricsCurrentIndex = idx
    }

    function lyricAt(offset) {
        if (lyricsLoading)
            return "Carregando lyrics"
        if (lyricsLines.length === 0)
            return isSpotifyPlayer() ? "Lyrics indisponivel" : "Spotify nao detectado"

        var idx = Math.max(0, Math.min(lyricsLines.length - 1, lyricsCurrentIndex + offset))
        return lyricsLines[idx].text
    }

    function prepareMouseInteraction() {
        if (ShinPopup.focusMode)
            ShinPopup.releaseFocusKeepActive()
        pinnedFromKeyboard = false
        hoverPopup = true
        closeTimer.stop()
    }

    function controlCount() {
        return 7
    }

    function moveInternal(delta) {
        if (!opened)
            return
        selectedControl = (selectedControl + delta + controlCount()) % controlCount()
    }

    function moveVertical(delta) {
        if (!opened)
            return

        if (delta > 0)
            selectedControl = selectedControl <= 2 ? 5 : Math.min(6, selectedControl + 1)
        else if (delta < 0)
            selectedControl = selectedControl >= 5 ? 1 : Math.max(0, selectedControl - 1)
    }

    function activateSelected() {
        if (!opened)
            return

        if (selectedControl === 0 && root.player && root.player.canGoPrevious)
            root.player.previous()
        else if (selectedControl === 1 && root.player && root.player.canTogglePlaying)
            root.player.togglePlaying()
        else if (selectedControl === 2 && root.player && root.player.canGoNext)
            root.player.next()
        else if (selectedControl === 3)
            root.setPlayerPositionFromRatio(Math.max(0, root.progress - 0.08))
        else if (selectedControl === 4)
            root.setPlayerPositionFromRatio(Math.min(1, root.progress + 0.08))
        else if (selectedControl === 5)
            root.setPlayerVolumePercent(root.playerVolumePercent() + 8)
        else if (selectedControl === 6)
            favorited = !favorited
    }

    function openPopup() {
        closeTimer.stop()
        hideTimer.stop()
        pinnedFromKeyboard = false
        popupVisible = true
        ShinPopup.active = "media-tab"
        randomizeBars()
    }

    function closePopup() {
        pinnedFromKeyboard = false
        ShinPopup.active = ""
    }

    function togglePopup() {
        if (opened)
            closePopup()
        else
            openPopup()
    }

    function scheduleClose() {
        if (pinnedFromKeyboard)
            return
        closeTimer.restart()
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() {
            root.playersVersion += 1
        }
    }

    Connections {
        target: ShinPopup
        function onInsideNonceChanged() {
            if (!root.opened)
                return

            if (ShinPopup.insideX !== 0)
                root.moveInternal(ShinPopup.insideX)
            else if (ShinPopup.insideY !== 0)
                root.moveVertical(ShinPopup.insideY)
        }

        function onActivateNonceChanged() {
            if (root.opened)
                root.activateSelected()
        }
    }

    onOpenedChanged: {
        if (opened) {
            hideTimer.stop()
            popupVisible = true
            pinnedFromKeyboard = ShinPopup.focusMode || ShinPopup.keepActiveOnFocusExit
            motionDir = 1
            closeAnim.stop()
            openAnim.from = motion
            openAnim.restart()
            randomizeBars()
            lyricsFetchTimer.restart()
        } else {
            pinnedFromKeyboard = false
            motionDir = -1
            openAnim.stop()
            closeAnim.from = motion
            closeAnim.restart()
            hideTimer.restart()
        }
    }

    onPlayerChanged: {
        root.position = root.player ? root.player.position : 0
        if (!root.player && !ShinConfig.mediaAlwaysVisible)
            ShinPopup.active = ""
        lyricsFetchTimer.restart()
    }

    onTrackSignatureChanged: lyricsFetchTimer.restart()

    NumberAnimation {
        id: openAnim
        target: root
        property: "motion"
        from: 0
        to: 1
        duration: ShinData.popupAnim(360)
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: closeAnim
        target: root
        property: "motion"
        from: 1
        to: 0
        duration: ShinData.popupAnim(250)
        easing.type: Easing.InCubic
    }

    Timer {
        id: closeTimer
        interval: 240
        repeat: false
        onTriggered: {
            if (root.pinnedFromKeyboard)
                return
            if (!root.hoverRoot && !root.hoverPopup)
                root.closePopup()
        }
    }

    Timer {
        id: hideTimer
        interval: 330
        repeat: false
        onTriggered: {
            if (!root.opened)
                root.popupVisible = false
        }
    }

    Timer {
        interval: 120
        running: root.popupVisible && ShinConfig.mediaShowVisualizer
        repeat: true
        onTriggered: root.randomizeBars()
    }

    Timer {
        interval: 1000
        running: root.player !== null
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.player)
                root.position = root.player.position
        }
    }

    Timer {
        id: lyricsFetchTimer
        interval: 260
        repeat: false
        onTriggered: root.fetchLyrics()
    }

    Timer {
        interval: 320
        running: root.popupVisible && root.lyricsSynced
        repeat: true
        onTriggered: root.updateLyricsIndex()
    }

    Process {
        id: lyricsProc
        running: false
        property string mode: "PLAIN"
        property var tmp: []
        command: ["/home/shira/.config/quickshell/shinbar/scripts/shinbar-lyrics"]

        stdout: SplitParser {
            onRead: function(data) {
                root.ingestLyricLine(data)
            }
        }

        onExited: {
            running = false
            root.lyricsLoading = false
            root.lyricsSynced = mode === "SYNCED"
            root.lyricsLines = tmp.length > 0 ? tmp : [{ ms: 0, text: "Lyrics indisponivel" }]
            root.updateLyricsIndex()
        }
    }

    ShinPill {
        anchors.fill: parent
        anchors.topMargin: (parent.height - ShinConfig.pillH) / 2
        anchors.bottomMargin: (parent.height - ShinConfig.pillH) / 2
        active: root.opened
        clickable: false
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton

        onEntered: root.hoverRoot = true
        onExited: {
            root.hoverRoot = false
            root.scheduleClose()
        }

        onClicked: root.togglePopup()

        onWheel: function(w) {
            if (!root.player)
                return
            if (w.angleDelta.y > 0) {
                if (root.player.canGoNext)
                    root.player.next()
            } else {
                if (root.player.canGoPrevious)
                    root.player.previous()
            }
        }
    }

    Row {
        id: mRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            text: root.player && root.player.isPlaying ? "♪" : "♫"
            color: root.opened ? ShinColors.accent : ShinColors.fg
            font.pixelSize: 13
            font.family: ShinConfig.fontFamily
            verticalAlignment: Text.AlignVCenter
            scale: root.opened ? 1.12 : 1.0
            Behavior on color { ColorAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
        }

        Text {
            property string raw: root.player ? (root.player.trackTitle || "") : "Midia"
            text: raw.length > 18 ? raw.substring(0, 16) + "..." : raw
            color: ShinColors.fg
            font.pixelSize: ShinConfig.fontSizeSm
            font.family: ShinConfig.fontFamily
            verticalAlignment: Text.AlignVCenter
            Behavior on color { ColorAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
        }
    }

    PopupWindow {
        id: mediaPopup
        visible: root.popupVisible
        color: "transparent"

        implicitWidth: root.popupW
        implicitHeight: root.popupH + 16

        anchor.item: root
        anchor.rect.x: Math.round(root.implicitWidth + 108 - mediaPopup.implicitWidth)
        anchor.rect.y: root.implicitHeight + 8
        anchor.rect.width: 1
        anchor.rect.height: 1

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            z: -100

            onEntered: {
                root.hoverPopup = true
                closeTimer.stop()
            }

            onExited: {
                root.hoverPopup = false
                root.scheduleClose()
            }
        }

        Repeater {
            model: [0.10, 0.19, 0.28]
            Rectangle {
                property real t: root.trailT(modelData)
                z: -3
                anchors.right: parent.right
                y: root.cardY(t)
                width: root.cardW(t)
                height: root.cardH(t)
                radius: root.cardRadius(t)
                antialiasing: true
                visible: root.popupVisible && (openAnim.running || closeAnim.running)
                opacity: (0.24 - index * 0.055) * (root.opened ? root.motion : Math.max(root.motion, 0.25))
                color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.15)
                border.width: 1
                border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.24)
            }
        }

        Rectangle {
            id: card
            property real ct: root.contentT()

            width: root.cardW(root.motion)
            height: root.cardH(root.motion)
            anchors.right: parent.right
            y: root.cardY(root.motion)
            radius: root.cardRadius(root.motion)
            antialiasing: true
            clip: true
            opacity: root.clamp01(root.motion * 1.25)
            scale: 0.965 + root.emphasizedDecel(root.motion) * 0.035
            color: Qt.rgba(ShinColors.bg.r, ShinColors.bg.g, ShinColors.bg.b, Math.max(0.70, ShinConfig.popupOpacity))
            border.width: 1
            border.color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.16)

            Image {
                anchors.fill: parent
                visible: ShinData.mediaBg.length > 0
                source: ShinData.mediaBg.length > 0 ? "file://" + ShinData.mediaBg : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                opacity: ShinData.mediaBgOpacity
            }

            Rectangle {
                anchors.fill: parent
                visible: ShinData.mediaBg.length > 0
                color: Qt.rgba(ShinColors.bg.r, ShinColors.bg.g, ShinColors.bg.b, 0.52)
            }

            Row {
                x: 16
                y: 14
                width: parent.width - 32
                height: 24
                opacity: card.ct

                Text {
                    width: parent.width / 2
                    text: "⌄"
                    color: ShinColors.fg
                    font.pixelSize: 18
                    font.family: ShinConfig.fontFamily
                }

                Text {
                    width: parent.width / 2
                    text: "☰"
                    color: ShinColors.fg
                    font.pixelSize: 15
                    font.family: ShinConfig.fontFamily
                    horizontalAlignment: Text.AlignRight
                }
            }

            Rectangle {
                id: cover
                x: 14
                y: 58
                width: parent.width - 28
                height: Math.min(width, parent.height * 0.48)
                radius: 16
                antialiasing: true
                clip: true
                opacity: card.ct
                scale: 0.97 + card.ct * 0.03
                color: Qt.rgba(ShinColors.surface.r, ShinColors.surface.g, ShinColors.surface.b, 0.90)
                border.width: 1
                border.color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.13)

                Image {
                    anchors.fill: parent
                    source: root.artSource()
                    visible: root.artUrl.length > 0
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    opacity: 0.82
                }

                Rectangle {
                    anchors.fill: parent
                    visible: root.artUrl.length > 0
                    color: Qt.rgba(ShinColors.bg.r, ShinColors.bg.g, ShinColors.bg.b, 0.28)
                }

                Row {
                    anchors.centerIn: parent
                    width: parent.width - 22
                    height: 72
                    spacing: Math.max(1, Math.floor(width / 116))

                    Repeater {
                        model: root.bars

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(1, Math.floor((visualizerRow.width - 31 * visualizerRow.spacing) / 32))
                            height: 8 + modelData * 58
                            radius: width / 2
                            color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, root.player && root.player.isPlaying ? 0.80 : 0.46)

                            Behavior on height { NumberAnimation { duration: 105; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
                        }
                    }

                    id: visualizerRow
                }
            }

            Text {
                x: 16
                y: cover.y + cover.height + 16
                width: parent.width - 32
                text: root.title
                color: ShinColors.fg
                font.pixelSize: 12
                font.bold: true
                font.family: ShinConfig.fontFamily
                elide: Text.ElideRight
                opacity: card.ct
                transform: Translate { y: root.lerp(-8, 0, card.ct) }
            }

            Text {
                x: 16
                y: cover.y + cover.height + 32
                width: parent.width - 32
                text: root.artist
                color: ShinColors.muted
                font.pixelSize: 10
                font.family: ShinConfig.fontFamily
                elide: Text.ElideRight
                opacity: card.ct
                transform: Translate { y: root.lerp(-6, 0, card.ct) }
            }

            Item {
                id: progressArea
                x: 16
                y: cover.y + cover.height + 62
                width: parent.width - 32
                height: 24
                opacity: card.ct

                Rectangle {
                    y: 10
                    width: parent.width
                    height: 3
                    radius: 2
                    color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.16)
                    clip: true

                    Rectangle {
                        width: parent.width * root.progress
                        height: parent.height
                        radius: parent.radius
                        color: ShinColors.accent
                        Behavior on width { NumberAnimation { duration: root.animMed; easing.type: Easing.OutCubic } }
                    }
                }

                Rectangle {
                    x: Math.max(0, Math.min(parent.width - width, parent.width * root.progress - width / 2))
                    y: 6
                    width: root.selectedControl === 3 || root.selectedControl === 4 ? 12 : 9
                    height: width
                    radius: width / 2
                    color: ShinColors.accent
                    border.width: 1
                    border.color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.70)

                    Behavior on x { NumberAnimation { duration: root.animMed; easing.type: Easing.OutCubic } }
                    Behavior on width { NumberAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    preventStealing: true

                    function seekAt(xPos) {
                        root.setPlayerPositionFromRatio(xPos / parent.width)
                    }

                    onPressed: function(mouse) {
                        root.prepareMouseInteraction()
                        mouse.accepted = true
                        seekAt(mouse.x)
                    }

                    onPositionChanged: function(mouse) {
                        if (pressed)
                            seekAt(mouse.x)
                    }
                }
            }

            Rectangle {
                id: controlsBox
                x: 12
                y: progressArea.y + 34
                width: parent.width - 24
                height: 84
                radius: 18
                opacity: card.ct
                color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.065)
                border.width: 1
                border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.18)

                Behavior on color { ColorAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
            }

            Row {
                id: transport
                x: controlsBox.x + 9
                y: controlsBox.y + 8
                width: controlsBox.width - 18
                height: 38
                spacing: Math.max(5, Math.floor((width - 172) / 4))
                opacity: card.ct

                MediaButton {
                    index: 0
                    kind: "prev"
                    onPress: { if (root.player && root.player.canGoPrevious) root.player.previous() }
                }

                MediaButton {
                    index: 1
                    kind: root.player && root.player.isPlaying ? "pause" : "play"
                    primary: true
                    onPress: { if (root.player && root.player.canTogglePlaying) root.player.togglePlaying() }
                }

                MediaButton {
                    index: 2
                    kind: "next"
                    onPress: { if (root.player && root.player.canGoNext) root.player.next() }
                }

                MediaButton {
                    index: 3
                    kind: "back"
                    onPress: root.setPlayerPositionFromRatio(Math.max(0, root.progress - 0.08))
                }

                MediaButton {
                    index: 4
                    kind: "forward"
                    activeHint: root.repeatHint
                    onPress: {
                        root.repeatHint = !root.repeatHint
                        root.setPlayerPositionFromRatio(Math.min(1, root.progress + 0.08))
                    }
                }
            }

            Row {
                id: bottomTools
                x: controlsBox.x + 22
                y: controlsBox.y + 49
                width: controlsBox.width - 44
                height: 28
                spacing: Math.max(10, width - 74)
                opacity: card.ct

                MediaButton {
                    index: 5
                    kind: "volume"
                    small: true
                    onPress: root.setPlayerVolumePercent(root.playerVolumePercent() + 8)
                }

                MediaButton {
                    index: 6
                    kind: "heart"
                    small: true
                    activeHint: root.favorited
                    onPress: root.favorited = !root.favorited
                }
            }

            Rectangle {
                id: lyricsPanel
                x: 12
                y: controlsBox.y + controlsBox.height + 10
                width: parent.width - 24
                height: Math.max(62, parent.height - y - 12)
                radius: 18
                visible: height > 54
                opacity: card.ct
                clip: true
                color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.075)
                border.width: 1
                border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.20)

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: parent.radius - 1
                    color: Qt.rgba(ShinColors.bg.r, ShinColors.bg.g, ShinColors.bg.b, 0.22)
                }

                Text {
                    anchors.centerIn: lyricMain
                    width: lyricMain.width
                    text: lyricMain.text
                    color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.42 * ShinConfig.glowStrength)
                    font.pixelSize: lyricMain.font.pixelSize + 4
                    font.bold: true
                    font.family: ShinConfig.fontFamily
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    scale: 1.05
                }

                Text {
                    id: lyricMain
                    x: 12
                    y: Math.max(10, Math.round(parent.height * 0.22))
                    width: parent.width - 24
                    text: root.lyricAt(0)
                    color: root.lyricsLoading ? ShinColors.muted : ShinColors.fg
                    font.pixelSize: 13
                    font.bold: true
                    font.family: ShinConfig.fontFamily
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                Text {
                    x: 12
                    y: lyricMain.y + 25
                    width: parent.width - 24
                    text: root.lyricAt(1)
                    color: Qt.rgba(ShinColors.muted.r, ShinColors.muted.g, ShinColors.muted.b, 0.76)
                    font.pixelSize: 10
                    font.family: ShinConfig.fontFamily
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    opacity: root.lyricsSynced && root.lyricsLines.length > 1 ? 1 : 0.55
                }

                Behavior on color { ColorAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
            }
        }
    }

    component MediaButton: Rectangle {
        id: btn
        property int index: 0
        property string kind: "play"
        property bool primary: false
        property bool small: false
        property bool activeHint: false
        property bool selected: root.selectedControl === index && root.opened && ShinPopup.focusMode
        property bool hovered: area.containsMouse
        property color iconColor: btn.primary
            ? ShinColors.bg
            : (btn.activeHint || btn.selected ? ShinColors.accent : ShinColors.fg)
        signal press()

        width: small ? 30 : (primary ? 38 : 32)
        height: width
        radius: width / 2
        color: primary
            ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, hovered || selected ? 0.92 : 0.72)
            : activeHint || selected
                ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, hovered ? 0.30 : 0.20)
                : hovered
                    ? Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.14)
                    : "transparent"
        border.width: selected ? 2 : 1
        border.color: selected
            ? ShinColors.accent
            : Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, hovered ? 0.16 : 0.0)
        scale: hovered || selected ? 1.08 : root.opened ? 1.0 : 0.94

        onKindChanged: iconCanvas.requestPaint()
        onIconColorChanged: iconCanvas.requestPaint()
        onActiveHintChanged: iconCanvas.requestPaint()
        onWidthChanged: iconCanvas.requestPaint()

        Canvas {
            id: iconCanvas
            anchors.centerIn: parent
            width: btn.primary ? 18 : btn.small ? 14 : 16
            height: width
            opacity: btn.enabled ? 1 : 0.55
            scale: btn.hovered || btn.selected ? 1.06 : 1.0

            onPaint: {
                var ctx = getContext("2d")
                var w = width
                var h = height
                ctx.clearRect(0, 0, w, h)
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                ctx.lineWidth = Math.max(1.6, w * 0.12)
                ctx.strokeStyle = btn.iconColor
                ctx.fillStyle = btn.iconColor

                if (btn.kind === "play") {
                    ctx.beginPath()
                    ctx.moveTo(w * 0.34, h * 0.22)
                    ctx.lineTo(w * 0.34, h * 0.78)
                    ctx.lineTo(w * 0.78, h * 0.50)
                    ctx.closePath()
                    ctx.fill()
                } else if (btn.kind === "pause") {
                    ctx.fillRect(w * 0.28, h * 0.22, w * 0.16, h * 0.56)
                    ctx.fillRect(w * 0.58, h * 0.22, w * 0.16, h * 0.56)
                } else if (btn.kind === "prev" || btn.kind === "next") {
                    var flip = btn.kind === "prev" ? -1 : 1
                    ctx.save()
                    if (flip < 0) {
                        ctx.translate(w, 0)
                        ctx.scale(-1, 1)
                    }
                    ctx.fillRect(w * 0.76, h * 0.23, w * 0.10, h * 0.54)
                    ctx.beginPath()
                    ctx.moveTo(w * 0.18, h * 0.50)
                    ctx.lineTo(w * 0.50, h * 0.24)
                    ctx.lineTo(w * 0.50, h * 0.76)
                    ctx.closePath()
                    ctx.fill()
                    ctx.beginPath()
                    ctx.moveTo(w * 0.46, h * 0.50)
                    ctx.lineTo(w * 0.76, h * 0.24)
                    ctx.lineTo(w * 0.76, h * 0.76)
                    ctx.closePath()
                    ctx.fill()
                    ctx.restore()
                } else if (btn.kind === "back" || btn.kind === "forward") {
                    var dir = btn.kind === "back" ? -1 : 1
                    ctx.save()
                    if (dir < 0) {
                        ctx.translate(w, 0)
                        ctx.scale(-1, 1)
                    }
                    ctx.beginPath()
                    ctx.arc(w * 0.50, h * 0.52, w * 0.30, Math.PI * 0.15, Math.PI * 1.45)
                    ctx.stroke()
                    ctx.beginPath()
                    ctx.moveTo(w * 0.78, h * 0.25)
                    ctx.lineTo(w * 0.78, h * 0.52)
                    ctx.lineTo(w * 0.55, h * 0.38)
                    ctx.closePath()
                    ctx.fill()
                    ctx.restore()
                } else if (btn.kind === "volume") {
                    ctx.beginPath()
                    ctx.moveTo(w * 0.18, h * 0.43)
                    ctx.lineTo(w * 0.36, h * 0.43)
                    ctx.lineTo(w * 0.58, h * 0.24)
                    ctx.lineTo(w * 0.58, h * 0.76)
                    ctx.lineTo(w * 0.36, h * 0.57)
                    ctx.lineTo(w * 0.18, h * 0.57)
                    ctx.closePath()
                    ctx.fill()
                    ctx.beginPath()
                    ctx.arc(w * 0.58, h * 0.50, w * 0.20, -0.65, 0.65)
                    ctx.stroke()
                } else if (btn.kind === "heart") {
                    ctx.beginPath()
                    ctx.moveTo(w * 0.50, h * 0.80)
                    ctx.bezierCurveTo(w * 0.18, h * 0.58, w * 0.08, h * 0.40, w * 0.22, h * 0.27)
                    ctx.bezierCurveTo(w * 0.34, h * 0.16, w * 0.47, h * 0.25, w * 0.50, h * 0.36)
                    ctx.bezierCurveTo(w * 0.53, h * 0.25, w * 0.66, h * 0.16, w * 0.78, h * 0.27)
                    ctx.bezierCurveTo(w * 0.92, h * 0.40, w * 0.82, h * 0.58, w * 0.50, h * 0.80)
                    ctx.closePath()
                    if (btn.activeHint)
                        ctx.fill()
                    else
                        ctx.stroke()
                }
            }

            Behavior on scale { NumberAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            onClicked: function(mouse) {
                root.prepareMouseInteraction()
                root.selectedControl = btn.index
                mouse.accepted = true
                btn.press()
            }
        }

        Behavior on color { ColorAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
    }
}
