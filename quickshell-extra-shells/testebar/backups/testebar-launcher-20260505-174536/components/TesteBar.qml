import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Services.UPower

Item {
    id: bar

    property int cornerRadius: 18
    property string clockText: Qt.formatDateTime(new Date(), "HH:mm")
    property var batteryDevice: null
    property int volume: 70
    property bool muted: false
    property var mediaPlayer: pickMediaPlayer()
    property real mediaPosition: 0
    property bool cavaReady: false
    property var cavaBars: [0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08, 0.08]
    readonly property int notificationCount: Number(NotificationServer.trackedCount || 0)
    readonly property int batteryPercent: batteryDevice && batteryDevice.ready ? Math.round(batteryDevice.percentage) : 100
    readonly property real batteryFill: Math.max(0.08, Math.min(1, batteryPercent / 100))
    readonly property bool mediaAvailable: mediaPlayer !== null
    readonly property bool mediaPlaying: mediaPlayer ? mediaPlayer.isPlaying : false
    readonly property real mediaLength: mediaPlayer && mediaPlayer.length > 0 ? mediaPlayer.length : 0
    readonly property real mediaProgress: mediaLength > 0 ? clamp01(mediaPosition / mediaLength) : 0.38
    readonly property string mediaTitle: mediaPlayer && textOf(mediaPlayer.trackTitle).length > 0 ? textOf(mediaPlayer.trackTitle) : "FOCO"
    readonly property string mediaArtist: mediaPlayer && textOf(mediaPlayer.trackArtist).length > 0 ? textOf(mediaPlayer.trackArtist) : (mediaPlayer ? "Player ativo" : "Mente leve")
    readonly property string mediaArtUrl: mediaPlayer ? textOf(mediaPlayer.trackArtUrl) : ""

    readonly property color panelBase: Qt.rgba(0.025, 0.045, 0.060, 0.46)
    readonly property color panelSoft: Qt.rgba(0.055, 0.080, 0.105, 0.38)
    readonly property color panelHover: Qt.rgba(0.075, 0.115, 0.150, 0.58)
    readonly property color line: Qt.rgba(0.54, 0.69, 0.84, 0.22)
    readonly property color lineStrong: Qt.rgba(0.70, 0.88, 1.0, 0.78)
    readonly property color text: Qt.rgba(0.86, 0.94, 1.0, 0.92)
    readonly property color dimText: Qt.rgba(0.54, 0.64, 0.76, 0.55)
    readonly property color accent: Qt.rgba(0.61, 0.82, 1.0, 0.96)
    readonly property color warning: Qt.rgba(1.0, 0.45, 0.43, 0.95)

    readonly property string paletteCommand: "if command -v nwg-look >/dev/null 2>&1; then nwg-look; elif command -v qt6ct >/dev/null 2>&1; then qt6ct; elif command -v qt5ct >/dev/null 2>&1; then qt5ct; else pkill wofi 2>/dev/null; wofi --show drun --prompt Tema & fi"
    readonly property string searchCommand: "pkill wofi 2>/dev/null; wofi --show drun --prompt Buscar &"
    readonly property string filesCommand: "if command -v dolphin >/dev/null 2>&1; then dolphin \"$HOME\"; elif command -v thunar >/dev/null 2>&1; then thunar \"$HOME\"; else xdg-open \"$HOME\"; fi"
    readonly property string appsCommand: "pkill wofi 2>/dev/null; wofi --show drun &"
    readonly property string terminalCommand: "if command -v kitty >/dev/null 2>&1; then kitty; elif command -v foot >/dev/null 2>&1; then foot; elif command -v alacritty >/dev/null 2>&1; then alacritty; elif command -v wezterm >/dev/null 2>&1; then wezterm; else xterm; fi"
    readonly property string settingsCommand: "if command -v systemsettings >/dev/null 2>&1; then systemsettings; elif command -v gnome-control-center >/dev/null 2>&1; then gnome-control-center; elif command -v nwg-look >/dev/null 2>&1; then nwg-look; else pkill wofi 2>/dev/null; wofi --show drun --prompt Config & fi"
    readonly property string muteCommand: "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    readonly property string cavaCommand: "/home/shira/.config/quickshell/testebar/scripts/testebar-cava 10"

    function clamp01(v) {
        return Math.max(0, Math.min(1, Number(v) || 0))
    }

    function textOf(v) {
        return v === undefined || v === null ? "" : String(v)
    }

    function mediaKey(p) {
        if (!p)
            return ""

        return (textOf(p.identity)
            + " " + textOf(p.desktopEntry)
            + " " + textOf(p.busName)
            + " " + textOf(p.service)
            + " " + textOf(p.name)
            + " " + textOf(p.trackTitle)
            + " " + textOf(p.trackArtist)).toLowerCase()
    }

    function mediaScore(p) {
        if (!p)
            return -9999

        var key = mediaKey(p)
        var title = textOf(p.trackTitle).toLowerCase()
        var artist = textOf(p.trackArtist).toLowerCase()
        var art = textOf(p.trackArtUrl)
        var score = 0

        if (p.isPlaying)
            score += 150
        if (art.length > 0)
            score += 80
        if (artist.length > 0)
            score += 45
        if (title.length > 0)
            score += 35
        if (key.indexOf("spotify") >= 0)
            score += 90
        if (key.indexOf("whatsapp") >= 0)
            score -= 300

        return score
    }

    function pickMediaPlayer() {
        var list = Mpris.players.values
        if (!list || list.length === 0)
            return null

        var best = list[0]
        var bestScore = mediaScore(best)

        for (var i = 1; i < list.length; i += 1) {
            var score = mediaScore(list[i])
            if (score > bestScore) {
                best = list[i]
                bestScore = score
            }
        }

        return best
    }

    function mediaArtSource() {
        if (mediaArtUrl.length === 0)
            return ""
        if (mediaArtUrl.indexOf("/") === 0)
            return "file://" + mediaArtUrl
        return mediaArtUrl
    }

    function formatMediaTime(sec) {
        sec = Math.max(0, Math.floor(Number(sec) || 0))
        var m = Math.floor(sec / 60)
        var s = sec % 60
        return m + ":" + (s < 10 ? "0" + s : s)
    }

    function toggleMedia() {
        if (mediaPlayer)
            mediaPlayer.togglePlaying()
    }

    function previousMedia() {
        if (mediaPlayer && mediaPlayer.canGoPrevious)
            mediaPlayer.previous()
    }

    function nextMedia() {
        if (mediaPlayer && mediaPlayer.canGoNext)
            mediaPlayer.next()
    }

    function seekMedia(ratio) {
        if (!mediaPlayer || !mediaPlayer.positionSupported || mediaLength <= 0)
            return

        mediaPosition = mediaLength * clamp01(ratio)
        mediaPlayer.position = mediaPosition
    }

    function parseCava(data) {
        var raw = textOf(data).trim()
        if (raw.length === 0)
            return

        var lines = raw.split(/\n/)
        var line = lines[lines.length - 1]
        var parts = line.split(/[;,\s]+/)
        var out = []

        for (var i = 0; i < parts.length; i += 1) {
            if (parts[i].length === 0)
                continue

            var n = Number(parts[i])
            if (isNaN(n))
                continue

            var normalized = clamp01(n / 1000)
            out.push(Math.max(0.08, Math.pow(normalized, 0.72)))
        }

        if (out.length > 0) {
            cavaBars = out
            cavaReady = true
        }
    }

    function pickBattery() {
        batteryDevice = null

        for (let i = 0; i < UPower.devices.count; i += 1) {
            let dev = UPower.devices.get(i)

            if (dev && dev.isLaptopBattery) {
                batteryDevice = dev
                return
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: bar.clockText = Qt.formatDateTime(new Date(), "HH:mm")
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            bar.pickBattery()

            if (!volumeQuery.running)
                volumeQuery.running = true
        }
    }

    Timer {
        interval: 1000
        running: bar.mediaAvailable
        repeat: true
        triggeredOnStart: true
        onTriggered: bar.mediaPosition = bar.mediaPlayer ? bar.mediaPlayer.position : 0
    }

    onMediaPlayerChanged: mediaPosition = mediaPlayer ? mediaPlayer.position : 0

    onMediaAvailableChanged: {
        if (mediaAvailable && !cavaProcess.running)
            cavaProcess.running = true
        else if (!mediaAvailable && cavaProcess.running)
            cavaProcess.running = false
    }

    Timer {
        id: volumeRefreshDelay

        interval: 220
        repeat: false
        onTriggered: {
            if (!volumeQuery.running)
                volumeQuery.running = true
        }
    }

    Process {
        id: volumeQuery

        running: false
        command: ["bash", "-lc", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo 'Volume: 0.70'"]

        stdout: SplitParser {
            onRead: function(data) {
                var text = data.trim()
                var match = text.match(/[0-9]+\.?[0-9]*/)

                bar.muted = text.indexOf("MUTED") >= 0

                if (match)
                    bar.volume = Math.max(0, Math.min(100, Math.round(parseFloat(match[0]) * 100)))
            }
        }

        onExited: running = false
    }

    Process {
        id: cavaProcess

        running: false
        command: ["bash", "-lc", bar.cavaCommand]

        stdout: SplitParser {
            onRead: function(data) {
                bar.parseCava(data)
            }
        }

        onExited: {
            running = false
            if (bar.mediaAvailable)
                cavaRestart.restart()
        }
    }

    Timer {
        id: cavaRestart

        interval: 1400
        repeat: false
        onTriggered: {
            if (bar.mediaAvailable && !cavaProcess.running)
                cavaProcess.running = true
        }
    }

    Component.onCompleted: {
        if (mediaAvailable && !cavaProcess.running)
            cavaProcess.running = true
    }

    Rectangle {
        x: 2
        y: 4
        width: Math.max(0, parent.width - 1)
        height: Math.max(0, parent.height - 3)
        radius: bar.cornerRadius
        color: Qt.rgba(0.0, 0.0, 0.0, 0.14)
    }

    Rectangle {
        id: surface

        anchors.fill: parent
        radius: bar.cornerRadius
        color: bar.panelBase
        border.width: 1
        border.color: Qt.rgba(0.58, 0.72, 0.86, 0.20)
        clip: true
    }

    Rectangle {
        anchors {
            left: surface.left
            right: surface.right
            top: surface.top
            leftMargin: 6
            rightMargin: 6
            topMargin: 3
        }

        height: 1
        color: Qt.rgba(1.0, 1.0, 1.0, 0.12)
    }

    Rectangle {
        anchors {
            left: surface.left
            top: surface.top
            bottom: surface.bottom
            leftMargin: 3
            topMargin: 14
            bottomMargin: 14
        }

        width: 1
        color: Qt.rgba(0.80, 0.90, 1.0, 0.08)
    }

    Rectangle {
        anchors {
            right: surface.right
            top: surface.top
            bottom: surface.bottom
            rightMargin: 3
            topMargin: 14
            bottomMargin: 14
        }

        width: 1
        color: Qt.rgba(0.0, 0.0, 0.0, 0.24)
    }

    Column {
        id: rail

        anchors.fill: surface
        anchors.margins: 7
        spacing: 8

        readonly property int fixedBase: clockButton.height
            + topGroup.height
            + workspaceGroup.height
            + separatorA.height
            + toolsGroup.height
            + separatorB.height
            + mediaCard.height
            + statusGroup.height
            + settingsButton.height
            + profileFrame.height
            + spacing * 11
        readonly property int flexibleSpace: Math.max(0, height - fixedBase)
        readonly property int topGapHeight: flexibleSpace <= 0 ? 0 : Math.max(26, Math.min(118, Math.round(flexibleSpace * 0.30)))
        readonly property int mediaGapHeight: Math.max(0, flexibleSpace - topGapHeight)

        ClockButton {
            id: clockButton
            anchors.horizontalCenter: parent.horizontalCenter
        }

        SegmentedGroup {
            id: topGroup
            anchors.horizontalCenter: parent.horizontalCenter
            items: [
                { "icon": "palette", "command": bar.paletteCommand },
                { "icon": "search", "command": bar.searchCommand }
            ]
        }

        Item {
            width: 1
            height: rail.topGapHeight
        }

        WorkspaceGroup {
            id: workspaceGroup
            anchors.horizontalCenter: parent.horizontalCenter
        }

        RailSeparator {
            id: separatorA
            anchors.horizontalCenter: parent.horizontalCenter
        }

        SegmentedGroup {
            id: toolsGroup
            anchors.horizontalCenter: parent.horizontalCenter
            items: [
                { "icon": "folder", "command": bar.filesCommand },
                { "icon": "grid", "command": bar.appsCommand },
                { "icon": "terminal", "command": bar.terminalCommand }
            ]
        }

        RailSeparator {
            id: separatorB
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Item {
            width: 1
            height: rail.mediaGapHeight
        }

        MediaCard {
            id: mediaCard
            anchors.horizontalCenter: parent.horizontalCenter
        }

        SegmentedGroup {
            id: statusGroup
            anchors.horizontalCenter: parent.horizontalCenter
            items: [
                {
                    "icon": "bell",
                    "command": "",
                    "active": bar.notificationCount > 0,
                    "badge": bar.notificationCount > 0 ? String(Math.min(bar.notificationCount, 9)) : ""
                },
                {
                    "icon": bar.muted ? "volume-muted" : "volume",
                    "command": bar.muteCommand,
                    "warning": bar.muted
                },
                {
                    "icon": "battery",
                    "command": "",
                    "warning": bar.batteryPercent <= 20,
                    "value": bar.batteryFill
                }
            ]

            onItemClicked: function(index) {
                if (index === 1)
                    volumeRefreshDelay.restart()
            }
        }

        IconButton {
            id: settingsButton
            anchors.horizontalCenter: parent.horizontalCenter
            iconName: "settings"
            command: bar.settingsCommand
        }

        Rectangle {
            id: profileFrame

            anchors.horizontalCenter: parent.horizontalCenter
            width: 38
            height: 38
            radius: width / 2
            color: Qt.rgba(0.10, 0.16, 0.20, 0.42)
            border.width: 1
            border.color: Qt.rgba(0.60, 0.86, 1.0, 0.48)
            clip: true

            Image {
                id: profileImage

                anchors.fill: parent
                anchors.margins: 3
                source: "file:///home/shira/.face"
                visible: false
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
            }

            Rectangle {
                id: profileMask

                anchors.fill: profileImage
                radius: width / 2
                visible: false
            }

            OpacityMask {
                anchors.fill: profileImage
                source: profileImage
                maskSource: profileMask
            }
        }
    }

    component MediaCard: Rectangle {
        id: card

        width: 44
        height: 148
        radius: 14
        color: bar.mediaAvailable ? Qt.rgba(0.060, 0.068, 0.074, 0.64) : Qt.rgba(0.058, 0.064, 0.070, 0.48)
        border.width: 1
        border.color: bar.mediaAvailable ? Qt.rgba(0.72, 0.80, 0.88, 0.24) : bar.line
        clip: true

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 6
                rightMargin: 6
                topMargin: 2
            }

            height: 1
            color: Qt.rgba(1.0, 1.0, 1.0, 0.10)
        }

        Column {
            anchors {
                fill: parent
                margins: 5
            }

            spacing: 4

            Rectangle {
                id: artFrame

                anchors.horizontalCenter: parent.horizontalCenter
                width: 32
                height: 32
                radius: 8
                color: Qt.rgba(0.10, 0.11, 0.12, 0.70)
                border.width: 1
                border.color: Qt.rgba(0.85, 0.88, 0.90, 0.13)
                clip: true

                Image {
                    id: mediaArt

                    anchors.fill: parent
                    source: bar.mediaArtSource()
                    visible: false
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                }

                Rectangle {
                    id: mediaArtMask

                    anchors.fill: mediaArt
                    radius: artFrame.radius
                    visible: false
                }

                OpacityMask {
                    anchors.fill: mediaArt
                    source: mediaArt
                    maskSource: mediaArtMask
                    visible: mediaArt.source.toString().length > 0 && mediaArt.status === Image.Ready
                }

                Rectangle {
                    anchors.fill: parent
                    visible: mediaArt.source.toString().length === 0 || mediaArt.status !== Image.Ready
                    color: Qt.rgba(0.075, 0.083, 0.090, 0.95)

                    IconCanvas {
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        iconName: "music"
                        lineColor: bar.mediaAvailable ? bar.text : bar.dimText
                    }
                }
            }

            Text {
                width: parent.width
                height: 10
                text: bar.mediaTitle
                color: bar.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 7
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                width: parent.width
                height: 8
                text: bar.mediaArtist
                color: bar.dimText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 6
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Item {
                id: waveform

                anchors.horizontalCenter: parent.horizontalCenter
                width: 32
                height: 18

                readonly property real barStep: width / Math.max(1, bar.cavaBars.length)

                Repeater {
                    model: bar.cavaBars

                    Rectangle {
                        width: Math.max(1.5, waveform.barStep * 0.48)
                        height: Math.max(3, waveform.height * (bar.cavaReady ? modelData : 0.08))
                        x: index * waveform.barStep + (waveform.barStep - width) / 2
                        y: Math.round((waveform.height - height) / 2)
                        radius: 1
                        color: bar.mediaPlaying ? Qt.rgba(0.78, 0.82, 0.84, 0.66) : Qt.rgba(0.58, 0.62, 0.64, 0.30)

                        Behavior on height {
                            NumberAnimation { duration: 70; easing.type: Easing.OutCubic }
                        }

                        Behavior on color {
                            ColorAnimation { duration: 160; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 32
                height: 12

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }

                    height: 2
                    radius: 1
                    color: Qt.rgba(0.82, 0.86, 0.88, 0.18)

                    Rectangle {
                        width: parent.width * bar.mediaProgress
                        height: parent.height
                        radius: parent.radius
                        color: Qt.rgba(0.84, 0.86, 0.86, 0.72)

                        Behavior on width {
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: bar.mediaAvailable && bar.mediaLength > 0
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        bar.seekMedia(mouse.x / Math.max(1, width))
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 34
                height: 8
                spacing: 2

                Text {
                    width: 16
                    text: bar.mediaAvailable ? bar.formatMediaTime(bar.mediaPosition) : "1:28"
                    color: bar.dimText
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 5
                    horizontalAlignment: Text.AlignLeft
                }

                Text {
                    width: 16
                    text: bar.mediaAvailable && bar.mediaLength > 0 ? bar.formatMediaTime(bar.mediaLength) : "3:45"
                    color: bar.dimText
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 5
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 36
                height: 19
                spacing: 2

                MediaMiniButton {
                    kind: "previous"
                    controlEnabled: Boolean(bar.mediaPlayer && bar.mediaPlayer.canGoPrevious)
                    onPressed: bar.previousMedia()
                }

                MediaMiniButton {
                    width: 14
                    height: 18
                    kind: bar.mediaPlaying ? "pause" : "play"
                    primary: true
                    controlEnabled: Boolean(bar.mediaAvailable)
                    onPressed: bar.toggleMedia()
                }

                MediaMiniButton {
                    kind: "next"
                    controlEnabled: Boolean(bar.mediaPlayer && bar.mediaPlayer.canGoNext)
                    onPressed: bar.nextMedia()
                }
            }
        }

    }

    component MediaMiniButton: Item {
        id: root

        property string kind: "play"
        property bool primary: false
        property bool controlEnabled: true
        property bool hovered: false
        signal pressed()

        width: 10
        height: 18
        opacity: controlEnabled ? 1.0 : 0.34

        Rectangle {
            anchors.centerIn: parent
            width: root.primary ? 14 : 10
            height: root.primary ? 14 : 10
            radius: width / 2
            color: root.primary
                ? Qt.rgba(0.78, 0.80, 0.80, root.hovered ? 0.26 : 0.18)
                : root.hovered ? Qt.rgba(0.78, 0.80, 0.80, 0.13) : "transparent"
            border.width: root.primary ? 1 : 0
            border.color: Qt.rgba(0.88, 0.90, 0.90, 0.18)
        }

        IconCanvas {
            anchors.centerIn: parent
            width: root.primary ? 11 : 9
            height: root.primary ? 11 : 9
            iconName: root.kind
            lineColor: root.primary ? bar.text : bar.dimText
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            enabled: root.controlEnabled
            cursorShape: Qt.PointingHandCursor

            onEntered: root.hovered = true
            onExited: root.hovered = false
            onClicked: root.pressed()
        }
    }

    component ClockButton: Rectangle {
        width: 44
        height: 34
        radius: 11
        color: bar.panelSoft
        border.width: 1
        border.color: bar.line

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 6
                rightMargin: 6
                topMargin: 2
            }

            height: 1
            color: Qt.rgba(1.0, 1.0, 1.0, 0.08)
        }

        Text {
            anchors {
                fill: parent
                leftMargin: 4
                rightMargin: 4
            }

            text: bar.clockText
            color: bar.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            elide: Text.ElideNone
        }
    }

    component SegmentedGroup: Rectangle {
        id: group

        property var items: []
        signal itemClicked(int index)

        width: 44
        height: 8 + items.length * 38
        radius: 14
        color: Qt.rgba(0.065, 0.095, 0.120, 0.26)
        border.width: 1
        border.color: bar.line
        clip: true

        Repeater {
            model: Math.max(0, group.items.length - 1)

            Rectangle {
                x: 5
                y: 4 + (index + 1) * 38
                width: group.width - 10
                height: 1
                color: Qt.rgba(0.70, 0.82, 0.95, 0.13)
            }
        }

        Repeater {
            model: group.items

            IconButton {
                x: 3
                y: 4 + index * 38
                width: group.width - 6
                height: 38
                iconName: modelData.icon || "search"
                command: modelData.command || ""
                active: Boolean(modelData.active)
                warning: Boolean(modelData.warning)
                badge: modelData.badge || ""
                iconValue: modelData.value === undefined ? 1.0 : modelData.value

                onClicked: group.itemClicked(index)
            }
        }
    }

    component WorkspaceGroup: Rectangle {
        id: group

        width: 44
        height: 8 + 4 * 38
        radius: 14
        color: Qt.rgba(0.065, 0.095, 0.120, 0.26)
        border.width: 1
        border.color: bar.line
        clip: true

        Repeater {
            model: 4

            WorkspaceButton {
                x: 4
                y: 4 + index * 38
                number: index + 1
                active: Hyprland.focusedMonitor !== null
                    && Hyprland.focusedMonitor.activeWorkspace !== null
                    && Hyprland.focusedMonitor.activeWorkspace.id === index + 1
            }
        }
    }

    component WorkspaceButton: Item {
        id: root

        property int number: 1
        property bool active: false
        property bool hovered: false

        width: 36
        height: 38

        Rectangle {
            anchors.centerIn: parent
            width: root.active ? 30 : 28
            height: root.active ? 30 : 28
            radius: 9
            color: root.active
                ? Qt.rgba(0.11, 0.18, 0.23, 0.86)
                : root.hovered ? bar.panelHover : Qt.rgba(0.08, 0.12, 0.16, 0.30)
            border.width: root.active ? 2 : 1
            border.color: root.active
                ? bar.lineStrong
                : root.hovered ? Qt.rgba(0.70, 0.88, 1.0, 0.38) : bar.line

            Behavior on color {
                ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
            }

            Behavior on border.color {
                ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
        }

        Text {
            anchors.centerIn: parent
            text: String(root.number)
            color: root.active ? bar.text : bar.dimText
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
            font.weight: root.active ? Font.DemiBold : Font.Medium
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: root.hovered = true
            onExited: root.hovered = false
            onClicked: Hyprland.dispatch("workspace " + root.number)
        }
    }

    component IconButton: Item {
        id: root

        property string iconName: "search"
        property string command: ""
        property bool active: false
        property bool warning: false
        property bool hovered: false
        property string badge: ""
        property real iconValue: 1.0
        readonly property color resolvedColor: warning ? bar.warning : active ? bar.accent : bar.text

        signal clicked()

        width: 38
        height: 38

        Process {
            id: actionProc

            running: false
            command: ["bash", "-lc", root.command]
            onExited: running = false
        }

        Rectangle {
            anchors.centerIn: parent
            width: 32
            height: 32
            radius: 10
            color: root.hovered || root.active ? bar.panelHover : "transparent"
            border.width: root.hovered || root.active ? 1 : 0
            border.color: root.active ? Qt.rgba(0.66, 0.86, 1.0, 0.42) : Qt.rgba(0.70, 0.84, 1.0, 0.22)

            Behavior on color {
                ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
        }

        IconCanvas {
            anchors.centerIn: parent
            width: 25
            height: 25
            iconName: root.iconName
            lineColor: root.resolvedColor
            value: root.iconValue
        }

        Rectangle {
            visible: root.badge.length > 0
            width: 14
            height: 14
            radius: 7
            x: parent.width - width - 4
            y: 4
            color: Qt.rgba(0.45, 0.72, 1.0, 0.24)
            border.width: 1
            border.color: Qt.rgba(0.75, 0.90, 1.0, 0.56)

            Text {
                anchors.centerIn: parent
                text: root.badge
                color: bar.text
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: root.hovered = true
            onExited: root.hovered = false
            onClicked: {
                if (root.command.length > 0 && !actionProc.running)
                    actionProc.running = true

                root.clicked()
            }
        }
    }

    component RailSeparator: Rectangle {
        width: 38
        height: 1
        radius: 1
        color: Qt.rgba(0.68, 0.82, 0.95, 0.16)
    }

    component IconCanvas: Canvas {
        id: canvas

        property string iconName: "search"
        property color lineColor: bar.text
        property real value: 1.0

        antialiasing: true

        onIconNameChanged: requestPaint()
        onLineColorChanged: requestPaint()
        onValueChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        function css(c, alpha) {
            var a = alpha === undefined ? c.a : alpha
            return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + a + ")"
        }

        function px(v, s, ox) {
            return ox + v * s
        }

        function rounded(ctx, x, y, w, h, r) {
            ctx.beginPath()
            ctx.moveTo(x + r, y)
            ctx.lineTo(x + w - r, y)
            ctx.quadraticCurveTo(x + w, y, x + w, y + r)
            ctx.lineTo(x + w, y + h - r)
            ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h)
            ctx.lineTo(x + r, y + h)
            ctx.quadraticCurveTo(x, y + h, x, y + h - r)
            ctx.lineTo(x, y + r)
            ctx.quadraticCurveTo(x, y, x + r, y)
        }

        function dot(ctx, x, y, r) {
            ctx.beginPath()
            ctx.arc(x, y, r, 0, Math.PI * 2)
            ctx.fill()
        }

        onPaint: {
            var ctx = getContext("2d")
            var s = Math.min(width, height)
            var ox = (width - s) / 2
            var oy = (height - s) / 2
            function x(v) { return px(v, s, ox) }
            function y(v) { return px(v, s, oy) }

            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = css(lineColor)
            ctx.fillStyle = css(lineColor)
            ctx.lineWidth = Math.max(1.45, s * 0.075)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            if (iconName === "palette") {
                ctx.beginPath()
                ctx.arc(x(0.46), y(0.50), s * 0.29, Math.PI * 0.18, Math.PI * 1.88)
                ctx.stroke()

                dot(ctx, x(0.34), y(0.40), s * 0.035)
                dot(ctx, x(0.46), y(0.32), s * 0.035)
                dot(ctx, x(0.55), y(0.45), s * 0.035)

                ctx.beginPath()
                ctx.moveTo(x(0.58), y(0.66))
                ctx.lineTo(x(0.78), y(0.34))
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.68), y(0.31))
                ctx.quadraticCurveTo(x(0.83), y(0.30), x(0.80), y(0.44))
                ctx.stroke()
            } else if (iconName === "search") {
                ctx.beginPath()
                ctx.arc(x(0.43), y(0.43), s * 0.23, 0, Math.PI * 2)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.61), y(0.61))
                ctx.lineTo(x(0.82), y(0.82))
                ctx.stroke()
            } else if (iconName === "folder") {
                ctx.beginPath()
                ctx.moveTo(x(0.17), y(0.38))
                ctx.lineTo(x(0.39), y(0.38))
                ctx.lineTo(x(0.45), y(0.47))
                ctx.lineTo(x(0.83), y(0.47))
                ctx.lineTo(x(0.83), y(0.78))
                ctx.lineTo(x(0.17), y(0.78))
                ctx.closePath()
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.18), y(0.48))
                ctx.lineTo(x(0.82), y(0.48))
                ctx.stroke()
            } else if (iconName === "grid") {
                rounded(ctx, x(0.20), y(0.18), s * 0.21, s * 0.21, s * 0.035)
                ctx.stroke()
                rounded(ctx, x(0.59), y(0.18), s * 0.21, s * 0.21, s * 0.035)
                ctx.stroke()
                rounded(ctx, x(0.20), y(0.58), s * 0.21, s * 0.21, s * 0.035)
                ctx.stroke()
                rounded(ctx, x(0.59), y(0.58), s * 0.21, s * 0.21, s * 0.035)
                ctx.stroke()
            } else if (iconName === "terminal") {
                ctx.beginPath()
                ctx.moveTo(x(0.25), y(0.29))
                ctx.lineTo(x(0.49), y(0.50))
                ctx.lineTo(x(0.25), y(0.71))
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.55), y(0.73))
                ctx.lineTo(x(0.79), y(0.73))
                ctx.stroke()
            } else if (iconName === "bell") {
                ctx.beginPath()
                ctx.moveTo(x(0.50), y(0.22))
                ctx.quadraticCurveTo(x(0.30), y(0.30), x(0.30), y(0.54))
                ctx.lineTo(x(0.23), y(0.68))
                ctx.lineTo(x(0.77), y(0.68))
                ctx.lineTo(x(0.70), y(0.54))
                ctx.quadraticCurveTo(x(0.70), y(0.30), x(0.50), y(0.22))
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.44), y(0.76))
                ctx.quadraticCurveTo(x(0.50), y(0.82), x(0.56), y(0.76))
                ctx.stroke()
            } else if (iconName === "volume" || iconName === "volume-muted") {
                ctx.beginPath()
                ctx.moveTo(x(0.17), y(0.43))
                ctx.lineTo(x(0.32), y(0.43))
                ctx.lineTo(x(0.50), y(0.28))
                ctx.lineTo(x(0.50), y(0.72))
                ctx.lineTo(x(0.32), y(0.57))
                ctx.lineTo(x(0.17), y(0.57))
                ctx.closePath()
                ctx.stroke()

                if (iconName === "volume-muted") {
                    ctx.beginPath()
                    ctx.moveTo(x(0.66), y(0.34))
                    ctx.lineTo(x(0.83), y(0.66))
                    ctx.moveTo(x(0.83), y(0.34))
                    ctx.lineTo(x(0.66), y(0.66))
                    ctx.stroke()
                } else {
                    ctx.beginPath()
                    ctx.arc(x(0.52), y(0.50), s * 0.16, -0.60, 0.60)
                    ctx.stroke()
                    ctx.beginPath()
                    ctx.arc(x(0.55), y(0.50), s * 0.28, -0.56, 0.56)
                    ctx.stroke()
                }
            } else if (iconName === "battery") {
                rounded(ctx, x(0.16), y(0.36), s * 0.62, s * 0.30, s * 0.045)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.82), y(0.44))
                ctx.lineTo(x(0.87), y(0.44))
                ctx.lineTo(x(0.87), y(0.58))
                ctx.lineTo(x(0.82), y(0.58))
                ctx.stroke()

                var fillW = Math.max(0.08, Math.min(0.48, 0.48 * value))
                ctx.fillStyle = css(lineColor, 0.34)
                rounded(ctx, x(0.24), y(0.43), s * fillW, s * 0.16, s * 0.025)
                ctx.fill()
            } else if (iconName === "music") {
                ctx.beginPath()
                ctx.moveTo(x(0.36), y(0.27))
                ctx.lineTo(x(0.36), y(0.68))
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.36), y(0.27))
                ctx.lineTo(x(0.70), y(0.20))
                ctx.lineTo(x(0.70), y(0.60))
                ctx.stroke()

                dot(ctx, x(0.29), y(0.71), s * 0.105)
                dot(ctx, x(0.63), y(0.63), s * 0.105)
            } else if (iconName === "previous") {
                ctx.beginPath()
                ctx.moveTo(x(0.28), y(0.25))
                ctx.lineTo(x(0.28), y(0.75))
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.74), y(0.25))
                ctx.lineTo(x(0.36), y(0.50))
                ctx.lineTo(x(0.74), y(0.75))
                ctx.closePath()
                ctx.fill()
            } else if (iconName === "next") {
                ctx.beginPath()
                ctx.moveTo(x(0.72), y(0.25))
                ctx.lineTo(x(0.72), y(0.75))
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(x(0.26), y(0.25))
                ctx.lineTo(x(0.64), y(0.50))
                ctx.lineTo(x(0.26), y(0.75))
                ctx.closePath()
                ctx.fill()
            } else if (iconName === "play") {
                ctx.beginPath()
                ctx.moveTo(x(0.34), y(0.23))
                ctx.lineTo(x(0.76), y(0.50))
                ctx.lineTo(x(0.34), y(0.77))
                ctx.closePath()
                ctx.fill()
            } else if (iconName === "pause") {
                ctx.lineWidth = Math.max(1.55, s * 0.14)
                ctx.beginPath()
                ctx.moveTo(x(0.38), y(0.25))
                ctx.lineTo(x(0.38), y(0.75))
                ctx.moveTo(x(0.62), y(0.25))
                ctx.lineTo(x(0.62), y(0.75))
                ctx.stroke()
            } else if (iconName === "settings") {
                for (var i = 0; i < 8; i += 1) {
                    var a = i * Math.PI / 4
                    ctx.beginPath()
                    ctx.moveTo(x(0.50 + Math.cos(a) * 0.27), y(0.50 + Math.sin(a) * 0.27))
                    ctx.lineTo(x(0.50 + Math.cos(a) * 0.36), y(0.50 + Math.sin(a) * 0.36))
                    ctx.stroke()
                }

                ctx.beginPath()
                ctx.arc(x(0.50), y(0.50), s * 0.22, 0, Math.PI * 2)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(x(0.50), y(0.50), s * 0.075, 0, Math.PI * 2)
                ctx.stroke()
            }
        }
    }
}
