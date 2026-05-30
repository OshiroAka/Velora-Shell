import Quickshell
import QtQuick
import Quickshell.Services.Mpris
import "."

Item {
    id: root

    property var player: pickPlayer()

    implicitWidth: visible ? mRow.implicitWidth + ShinConfig.pillPadH * 2 : 0
    implicitHeight: ShinConfig.barH
    visible: root.player !== null

    property bool opened: ShinPopup.active === "media-tab"
    property bool popupVisible: false
    property bool hoverRoot: false
    property bool hoverPopup: false
    property bool pinnedFromKeyboard: false

    property string title: root.player ? (root.player.trackTitle || "Unknown Title") : "Unknown Title"
    property string artist: root.player ? (root.player.trackArtist || "Unknown Artist") : "Unknown Artist"
    property string album: root.player ? (root.player.trackAlbum || "") : ""
    property string artUrl: root.player ? (root.player.trackArtUrl || "") : ""

    readonly property int popupW: 940
    readonly property int popupH: 620
    readonly property int cardOpenW: 940
    readonly property int cardOpenH: 560
    readonly property int cardClosedW: 190
    readonly property int cardClosedH: 46
    readonly property int popupLift: 22

    readonly property int animFast: 120
    readonly property int animMed: 180
    readonly property int animSlow: 260

    property real motion: 0.0
    property int motionDir: 1
    property string selectedPreset: "Melancholic"
    property real position: 0
    property real progress: root.player && root.player.length > 0 ? clamp01(root.position / root.player.length) : 0.56

    property int fx60: 88
    property int fx150: 58
    property int fx400: 34
    property int fx1k: 58
    property int fx24k: 70
    property int fx6k: 52
    property int fx15k: 36

    property var bars: [
        0.20, 0.28, 0.35, 0.42, 0.55, 0.66, 0.78, 0.92,
        0.70, 0.62, 0.58, 0.74, 0.84, 0.68, 0.52, 0.43,
        0.36, 0.30, 0.24, 0.20, 0.18, 0.22, 0.28, 0.34,
        0.40, 0.32, 0.25, 0.22, 0.20, 0.18, 0.16, 0.14
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

    function visualT() {
        return opened ? emphasizedDecel(motion) : 1 - emphasizedAccel(1 - motion)
    }

    function contentT() {
        return clamp01((motion - 0.28) / 0.72)
    }

    function cardW(t) {
        return lerp(cardClosedW, cardOpenW, emphasizedDecel(t))
    }

    function cardH(t) {
        return lerp(cardClosedH, cardOpenH, emphasizedDecel(t))
    }

    function cardY(t) {
        return lerp(-popupLift, -4, emphasizedDecel(t))
    }

    function cardRadius(t) {
        return lerp(23, 30, emphasizedDecel(t))
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

    function prepareMouseInteraction() {
        if (ShinPopup.focusMode)
            ShinPopup.releaseFocusKeepActive()
        pinnedFromKeyboard = false
        hoverPopup = true
        closeTimer.stop()
    }

    function randomizeBars() {
        var arr = []
        for (var i = 0; i < 32; ++i) {
            var center = 1.0 - Math.min(1.0, Math.abs(i - 13) / 15)
            var base = root.player && root.player.isPlaying ? 0.22 + center * 0.62 : 0.12 + center * 0.22
            arr.push(Math.max(0.10, Math.min(0.96, base + (Math.random() - 0.5) * 0.26)))
        }
        bars = arr
    }

    function applyPreset(name) {
        selectedPreset = name
        if (name === "Atmospheric") {
            fx60 = 62; fx150 = 66; fx400 = 54; fx1k = 58; fx24k = 64; fx6k = 74; fx15k = 82
        } else if (name === "Calm") {
            fx60 = 50; fx150 = 54; fx400 = 48; fx1k = 50; fx24k = 48; fx6k = 44; fx15k = 38
        } else if (name === "Deep") {
            fx60 = 92; fx150 = 80; fx400 = 58; fx1k = 46; fx24k = 42; fx6k = 38; fx15k = 34
        } else {
            fx60 = 88; fx150 = 58; fx400 = 34; fx1k = 58; fx24k = 70; fx6k = 52; fx15k = 36
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
        if (!root.player)
            ShinPopup.active = ""
    }

    NumberAnimation {
        id: openAnim
        target: root
        property: "motion"
        from: 0
        to: 1
        duration: 470
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: closeAnim
        target: root
        property: "motion"
        from: 1
        to: 0
        duration: 350
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
        interval: 440
        repeat: false
        onTriggered: {
            if (!root.opened)
                root.popupVisible = false
        }
    }

    Timer {
        interval: 120
        running: root.popupVisible
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
            color: ShinColors.accent
            font.pixelSize: 13
            font.family: ShinConfig.fontFamily
            verticalAlignment: Text.AlignVCenter
            Behavior on color { ColorAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
        }

        Text {
            property string raw: root.player ? (root.player.trackTitle || "") : ""
            text: raw.length > 26 ? raw.substring(0, 24) + "..." : raw
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
        implicitHeight: root.popupH

        anchor.item: root
        anchor.rect.x: Math.round(root.implicitWidth + 108 - mediaPopup.implicitWidth)
        anchor.rect.y: root.implicitHeight + 10
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
            model: [0.10, 0.18, 0.27]
            Rectangle {
                property real t: root.trailT(modelData)
                z: -3
                anchors.right: parent.right
                y: root.cardY(t)
                width: root.cardW(t)
                height: root.cardH(t)
                radius: root.cardRadius(t)
                antialiasing: true
                clip: true
                visible: root.popupVisible && (openAnim.running || closeAnim.running)
                opacity: (0.22 - index * 0.05) * (root.opened ? root.motion : Math.max(root.motion, 0.25))
                color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.16)
                border.width: 1
                border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.26)
            }
        }

        Rectangle {
            id: card
            property real ct: root.contentT()

            z: 10
            width: root.cardW(root.motion)
            height: root.cardH(root.motion)
            anchors.right: parent.right
            y: root.cardY(root.motion)
            radius: root.cardRadius(root.motion)
            antialiasing: true
            clip: true
            opacity: root.clamp01(root.motion * 1.25)
            scale: 0.965 + root.emphasizedDecel(root.motion) * 0.035
            color: Qt.rgba(ShinColors.bg.r, ShinColors.bg.g, ShinColors.bg.b, Math.max(0.74, ShinConfig.popupOpacity))
            border.width: 1
            border.color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.18)

            Rectangle {
                width: 170
                height: 170
                radius: 85
                x: 520
                y: 128
                color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.045)
            }

            Text {
                x: card.width - 86
                y: 20
                text: "♡"
                color: ShinColors.accent
                font.pixelSize: 24
                font.family: ShinConfig.fontFamily
                opacity: card.ct
            }

            Text {
                x: card.width - 48
                y: 20
                text: "..."
                color: ShinColors.fg
                font.pixelSize: 18
                font.family: ShinConfig.fontFamily
                opacity: card.ct * 0.86
            }

            Rectangle {
                id: cover
                x: 34
                y: 48
                width: 420
                height: 420
                radius: 22
                antialiasing: true
                clip: true
                opacity: card.ct
                scale: 0.965 + card.ct * 0.035
                color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.10)
                border.width: 1
                border.color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.14)

                Image {
                    anchors.fill: parent
                    source: root.artSource()
                    visible: root.artUrl.length > 0
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.artUrl.length === 0
                    text: "♪"
                    color: ShinColors.accent
                    font.pixelSize: 78
                    font.family: ShinConfig.fontFamily
                }
            }

            Item {
                x: 34
                y: 486
                width: 420
                height: 42
                z: 50
                opacity: card.ct

                Rectangle {
                    x: 0
                    y: 16
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.12)
                    clip: true

                    Rectangle {
                        width: parent.width * root.progress
                        height: parent.height
                        radius: parent.radius
                        color: ShinColors.accent
                        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    }
                }

                Rectangle {
                    x: Math.max(0, Math.min(parent.width - width, parent.width * root.progress - width / 2))
                    y: 11
                    width: 14
                    height: 14
                    radius: 7
                    color: ShinColors.accent
                    border.width: 2
                    border.color: ShinColors.fg
                    Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }

                Text {
                    x: 0
                    y: 27
                    text: root.formatTime(root.position)
                    color: ShinColors.muted
                    font.pixelSize: 10
                    font.family: ShinConfig.fontFamily
                }

                Text {
                    x: parent.width - width
                    y: 27
                    text: root.player && root.player.length > 0 ? root.formatTime(root.player.length) : "0:00"
                    color: ShinColors.muted
                    font.pixelSize: 10
                    font.family: ShinConfig.fontFamily
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.topMargin: 4
                    anchors.bottomMargin: 8
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    preventStealing: true
                    z: 30

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

            Item {
                id: playerArea
                x: 500
                y: 72
                width: 380
                height: 392
                opacity: card.ct
                transform: Translate { y: root.lerp(-12, 0, card.ct) }

                Text {
                    x: 0
                    y: 0
                    text: "TOCANDO AGORA"
                    color: ShinColors.accent
                    font.pixelSize: 11
                    font.bold: true
                    font.family: ShinConfig.fontFamily
                }

                Text {
                    x: 0
                    y: 28
                    width: parent.width
                    text: root.title.toUpperCase()
                    color: ShinColors.fg
                    font.pixelSize: 32
                    font.bold: true
                    font.family: ShinConfig.fontFamily
                    elide: Text.ElideRight
                }

                Text {
                    x: 0
                    y: 82
                    width: parent.width
                    text: root.artist.toUpperCase()
                    color: ShinColors.accent
                    font.pixelSize: 12
                    font.family: ShinConfig.fontFamily
                    elide: Text.ElideRight
                }

                Text {
                    x: Math.min(parent.width - 18, artistTextMetrics.width + 8)
                    y: 78
                    text: "●"
                    color: ShinColors.accent
                    font.pixelSize: 10
                    font.family: ShinConfig.fontFamily
                }

                TextMetrics {
                    id: artistTextMetrics
                    font.pixelSize: 12
                    font.family: ShinConfig.fontFamily
                    text: root.artist.toUpperCase()
                }

                Text {
                    x: parent.width - 28
                    y: 48
                    text: "+"
                    color: ShinColors.accent
                    font.pixelSize: 34
                    font.family: ShinConfig.fontFamily
                    opacity: 0.9
                }

                Row {
                    id: visualizer
                    x: 0
                    y: 128
                    width: parent.width
                    height: 38
                    spacing: 2

                    Repeater {
                        model: root.bars
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: 4
                            height: 4 + modelData * 30
                            radius: 2
                            color: Qt.rgba(
                                ShinColors.accent.r,
                                ShinColors.accent.g,
                                ShinColors.accent.b,
                                index > 23 ? 0.42 : 0.88
                            )
                            Behavior on height { NumberAnimation { duration: 95; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                Row {
                    x: 0
                    y: 188
                    width: parent.width
                    height: 42
                    z: 60
                    spacing: 10

                    ControlButton { width: 116; icon: "◀"; label: "Anterior"; onPress: { if (root.player && root.player.canGoPrevious) root.player.previous() } }
                    ControlButton { width: 128; icon: root.player && root.player.isPlaying ? "Ⅱ" : "▶"; label: root.player && root.player.isPlaying ? "Pausar" : "Tocar"; primary: true; onPress: { if (root.player && root.player.canTogglePlaying) root.player.togglePlaying() } }
                    ControlButton { width: 116; icon: "▶"; label: "Próxima"; onPress: { if (root.player && root.player.canGoNext) root.player.next() } }
                }
            }

            Row {
                x: 500
                y: 306
                width: 380
                height: 32
                z: 60
                spacing: 12
                opacity: card.ct

                Repeater {
                    model: ["Atmospheric", "Melancholic", "Calm", "Deep", "+"]
                    Rectangle {
                        id: chip
                        property bool active: root.selectedPreset === modelData
                        property bool hovered: false
                        width: modelData === "Atmospheric" ? 78 : modelData === "Melancholic" ? 86 : 54
                        height: 28
                        radius: 14
                        color: active
                            ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.18)
                            : hovered
                                ? Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.10)
                                : Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.06)
                        border.width: 1
                        border.color: active ? ShinColors.accent : Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.10)

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: chip.active ? ShinColors.accent : ShinColors.fg
                            font.pixelSize: 9
                            font.family: ShinConfig.fontFamily
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton
                            preventStealing: true
                            z: 20
                            onEntered: chip.hovered = true
                            onExited: chip.hovered = false
                            onClicked: {
                                root.prepareMouseInteraction()
                                if (modelData !== "+")
                                    root.applyPreset(modelData)
                            }
                        }

                        Behavior on color { ColorAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
                    }
                }
            }

            Rectangle {
                x: 34
                y: 358
                width: card.width - 68
                height: 1
                color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.10)
                opacity: card.ct
            }

            Rectangle {
                x: 500
                y: 378
                width: 390
                height: 142
                z: 60
                radius: 14
                opacity: card.ct
                color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.035)
                border.width: 1
                border.color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.08)

                Text {
                    x: 16
                    y: 16
                    text: "+12db"
                    color: ShinColors.muted
                    font.pixelSize: 9
                    font.family: ShinConfig.fontFamily
                }

                Text {
                    x: 22
                    y: 66
                    text: "0db"
                    color: ShinColors.muted
                    font.pixelSize: 9
                    font.family: ShinConfig.fontFamily
                }

                Text {
                    x: 15
                    y: 112
                    text: "-12db"
                    color: ShinColors.muted
                    font.pixelSize: 9
                    font.family: ShinConfig.fontFamily
                }

                Row {
                    x: 72
                    y: 12
                    width: 292
                    height: 116
                    spacing: 14

                    EqSlider { label: "60"; value: root.fx60; onSetValue: function(v) { root.fx60 = v } }
                    EqSlider { label: "150"; value: root.fx150; onSetValue: function(v) { root.fx150 = v } }
                    EqSlider { label: "400"; value: root.fx400; onSetValue: function(v) { root.fx400 = v } }
                    EqSlider { label: "1k"; value: root.fx1k; onSetValue: function(v) { root.fx1k = v } }
                    EqSlider { label: "2.4k"; value: root.fx24k; onSetValue: function(v) { root.fx24k = v } }
                    EqSlider { label: "6k"; value: root.fx6k; onSetValue: function(v) { root.fx6k = v } }
                    EqSlider { label: "15k"; value: root.fx15k; onSetValue: function(v) { root.fx15k = v } }
                }
            }

            Item {
                x: 764
                y: 338
                width: 120
                height: 54
                opacity: card.ct

                Text {
                    x: 0
                    y: 0
                    text: "PRESET"
                    color: ShinColors.muted
                    font.pixelSize: 9
                    font.bold: true
                    font.family: ShinConfig.fontFamily
                }

                Rectangle {
                    x: 0
                    y: 18
                    width: 110
                    height: 26
                    radius: 13
                    color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.06)
                    border.width: 1
                    border.color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.10)

                    Text {
                        anchors.centerIn: parent
                        text: "Personalizado"
                        color: ShinColors.fg
                        font.pixelSize: 9
                        font.bold: true
                        font.family: ShinConfig.fontFamily
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                x: 34
                y: card.height - 45
                width: card.width - 68
                height: 1
                color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.10)
                opacity: card.ct
            }

            Text {
                x: 48
                y: card.height - 28
                text: "☷  FILA        ▣  LETRA"
                color: ShinColors.muted
                font.pixelSize: 11
                font.family: ShinConfig.fontFamily
                opacity: card.ct
            }

            Item {
                x: card.width - 260
                y: card.height - 31
                width: 220
                height: 18
                opacity: card.ct

                Text {
                    x: 0
                    y: -1
                    text: "♩"
                    color: ShinColors.muted
                    font.pixelSize: 18
                    font.family: ShinConfig.fontFamily
                }

                Rectangle {
                    x: 32
                    y: 8
                    width: 145
                    height: 3
                    radius: 2
                    color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.16)

                    Rectangle {
                        width: parent.width * root.clamp01(root.playerVolumePercent() / 100)
                        height: parent.height
                        radius: parent.radius
                        color: ShinColors.accent
                    }
                }

                Text {
                    x: 186
                    y: 0
                    text: root.playerVolumePercent() + "%"
                    color: ShinColors.fg
                    font.pixelSize: 10
                    font.family: ShinConfig.fontFamily
                }
            }

            component ControlButton: Rectangle {
                id: cb
                property string icon: "▶"
                property string label: "Tocar"
                property bool primary: false
                property bool hovered: false
                signal press()

                height: 42
                radius: 8
                color: primary
                    ? (hovered ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.86) : Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.70))
                    : (hovered ? Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.11) : Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.065))
                border.width: 1
                border.color: primary
                    ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.32)
                    : Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.07)
                scale: hovered ? 1.025 : 1.0

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: cb.icon
                        color: cb.primary ? ShinColors.fg : ShinColors.fg
                        font.pixelSize: cb.primary ? 18 : 14
                        font.bold: true
                        font.family: ShinConfig.fontFamily
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: cb.label
                        color: ShinColors.fg
                        opacity: cb.primary ? 1 : 0.82
                        font.pixelSize: 10
                        font.bold: cb.primary
                        font.family: ShinConfig.fontFamily
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    preventStealing: true
                    z: 20
                    onEntered: cb.hovered = true
                    onExited: cb.hovered = false
                    onClicked: function(mouse) {
                        root.prepareMouseInteraction()
                        mouse.accepted = true
                        cb.press()
                    }
                }

                Behavior on scale { NumberAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
            }

            component RoundButton: Rectangle {
                id: rb
                property string label: "▶"
                property bool big: false
                property bool hovered: false
                signal press()

                width: big ? 58 : 42
                height: width
                radius: width / 2
                color: big
                    ? (hovered ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.96) : ShinColors.accent)
                    : (hovered ? Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.12) : Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.065))
                scale: hovered ? 1.05 : 1.0

                Text {
                    anchors.centerIn: parent
                    text: rb.label
                    color: rb.big ? ShinColors.bg : ShinColors.fg
                    font.pixelSize: rb.big ? 22 : 17
                    font.bold: rb.big
                    font.family: ShinConfig.fontFamily
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    preventStealing: true
                    z: 20
                    onEntered: rb.hovered = true
                    onExited: rb.hovered = false
                    onClicked: function(mouse) {
                        root.prepareMouseInteraction()
                        mouse.accepted = true
                        rb.press()
                    }
                }

                Behavior on scale { NumberAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
            }

            component EqSlider: Item {
                id: eq
                property string label: "EQ"
                property int value: 50
                property bool hovered: drag.containsMouse || drag.pressed
                signal setValue(int v)

                width: 28
                height: 116

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    width: eq.hovered ? 8 : 7
                    height: 88
                    radius: 4
                    color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.11)

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(8, parent.height * root.clamp01(eq.value / 100))
                        radius: parent.radius
                        color: ShinColors.accent
                        Behavior on height { NumberAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.height - (parent.height * root.clamp01(eq.value / 100)) - height / 2
                        width: eq.hovered ? 15 : 13
                        height: width
                        radius: width / 2
                        color: ShinColors.fg
                        Behavior on y { NumberAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    text: eq.label
                    color: ShinColors.muted
                    font.pixelSize: 9
                    font.family: ShinConfig.fontFamily
                }

                MouseArea {
                    id: drag
                    x: -8
                    y: 0
                    width: parent.width + 16
                    height: parent.height
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    preventStealing: true
                    z: 20
                    onPressed: function(mouse) {
                        root.prepareMouseInteraction()
                        mouse.accepted = true
                        update(mouse.y)
                    }
                    onPositionChanged: function(mouse) {
                        if (pressed)
                            update(mouse.y)
                    }
                    function update(yPos) {
                        var pct = 100 - ((yPos - 2) / 88) * 100
                        eq.setValue(root.clamp100(pct))
                    }
                }
            }
        }
    }
}
