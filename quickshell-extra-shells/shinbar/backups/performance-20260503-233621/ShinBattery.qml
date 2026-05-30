import Quickshell
import QtQuick
import Quickshell.Io
import "."

Item {
    id: root

    implicitWidth: bRow.implicitWidth + ShinConfig.pillPadH * 2
    implicitHeight: ShinConfig.barH

    property int pct: 100
    property bool charging: false
    property bool low: pct <= 20 && !charging
    property bool pulse: false

    property bool opened: ShinPopup.active === "battery"
    property bool popupVisible: false
    property bool hoverRoot: false
    property bool hoverPopup: false

    property int cpuPct: 0
    property int ramPct: 0
    property int swapPct: 0
    property int diskPct: 0
    property string ramUsed: "0"
    property string ramTotal: "0"
    property string swapUsed: "0"
    property string swapTotal: "0"
    property string diskUsed: "0"
    property string diskTotal: "0"
    property string load1: "0.00"
    property string load5: "0.00"
    property string load15: "0.00"
    property int temp: 0
    property int procs: 0
    property string netRx: "0.0"
    property string netTx: "0.0"
    property int netPct: 0
    property bool settingsButtonHover: false
    property int selectedAction: 0
    readonly property bool settingsButtonSelected: opened && ShinPopup.focusMode && selectedAction === 0

    readonly property int popupW: 520
    readonly property int popupH: 390
    readonly property int cardOpenW: 486
    readonly property int cardOpenH: 350
    readonly property int cardClosedW: 150
    readonly property int cardClosedH: 46

    property real motion: 0.0
    property int motionDir: 1
    property real sweep: -160
    property real meterGlow: 0.0
    property real introHero: 1.0
    property real introTop: 1.0
    property real introCards: 1.0
    property real introFooter: 1.0

    function clamp01(v) {
        return Math.max(0, Math.min(1, v))
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
        return clamp01((motion - 0.24) / 0.76)
    }

    function cardW(t) {
        return lerp(cardClosedW, cardOpenW, emphasizedDecel(t))
    }

    function cardH(t) {
        return lerp(cardClosedH, cardOpenH, emphasizedDecel(t))
    }

    function cardY(t) {
        return lerp(-18, 0, emphasizedDecel(t))
    }

    function cardRadius(t) {
        return lerp(23, 26, emphasizedDecel(t))
    }

    function trailT(offset) {
        if (motionDir >= 0)
            return clamp01(motion - offset)
        return clamp01(motion + offset)
    }

    function replayPanelEntrance() {
        introHeroAnim.restart()
        introTopAnim.restart()
        introCardsAnim.restart()
        introFooterAnim.restart()
    }

    function setStat(key, value) {
        if (key === "CPU") cpuPct = parseInt(value) || 0
        else if (key === "RAM_USED") ramUsed = value
        else if (key === "RAM_TOTAL") ramTotal = value
        else if (key === "RAM_PCT") ramPct = parseInt(value) || 0
        else if (key === "SWAP_USED") swapUsed = value
        else if (key === "SWAP_TOTAL") swapTotal = value
        else if (key === "SWAP_PCT") swapPct = parseInt(value) || 0
        else if (key === "DISK_USED") diskUsed = value
        else if (key === "DISK_TOTAL") diskTotal = value
        else if (key === "DISK_PCT") diskPct = parseInt(value) || 0
        else if (key === "LOAD") load1 = value
        else if (key === "LOAD5") load5 = value
        else if (key === "LOAD15") load15 = value
        else if (key === "TEMP") temp = parseInt(value) || 0
        else if (key === "PROCS") procs = parseInt(value) || 0
        else if (key === "NET_RX") netRx = value
        else if (key === "NET_TX") netTx = value
        else if (key === "NET_PCT") netPct = parseInt(value) || 0
    }

    function refreshStats() {
        if (!statsProc.running)
            statsProc.running = true
    }

    function openPopup() {
        closeTimer.stop()
        hideTimer.stop()
        popupVisible = true
        ShinPopup.open("battery")
        refreshStats()
    }

    function closePopup() {
        ShinPopup.close("battery")
    }

    function togglePopup() {
        if (opened)
            closePopup()
        else
            openPopup()
    }

    function scheduleClose() {
        closeTimer.restart()
    }

    function openSettings() {
        root.hoverPopup = false
        ShinPopup.open("settings")
    }

    onOpenedChanged: {
        if (opened) {
            hideTimer.stop()
            popupVisible = true
            motionDir = 1
            closeAnim.stop()
            openAnim.from = motion
            openAnim.restart()
            sweepAnim.restart()
            meterGlowAnim.restart()
            replayPanelEntrance()
            refreshStats()
        } else {
            motionDir = -1
            openAnim.stop()
            closeAnim.from = motion
            closeAnim.restart()
            hideTimer.restart()
        }
    }

    Process {
        id: bProc
        running: false
        property int ln: 0
        command: [
            "bash",
            "-lc",
            "for b in BAT0 BAT1; do f=/sys/class/power_supply/$b/capacity; s=/sys/class/power_supply/$b/status; [ -f $f ] && cat $f && cat $s && break; done || echo -e '100\\nFull'"
        ]

        stdout: SplitParser {
            onRead: function(data) {
                var s = data.trim()
                if (bProc.ln === 0) {
                    var n = parseInt(s)
                    if (!isNaN(n))
                        root.pct = n
                } else {
                    root.charging = (s === "Charging" || s === "Full")
                }
                bProc.ln++
            }
        }

        onStarted: bProc.ln = 0
        onExited: running = false
    }

    Process {
        id: statsProc
        running: false
        command: ["bash", "-lc", "~/.config/quickshell/shinbar/scripts/shinbar-system-stats"]

        stdout: SplitParser {
            onRead: function(data) {
                var line = data.trim()
                var idx = line.indexOf("=")
                if (idx <= 0)
                    return
                root.setStat(line.slice(0, idx), line.slice(idx + 1))
            }
        }

        onExited: running = false
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: bProc.running = true
    }

    Timer {
        interval: 2500
        running: root.popupVisible
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshStats()
    }

    Timer {
        interval: 700
        running: true
        repeat: true
        onTriggered: root.pulse = !root.pulse
    }

    Connections {
        target: ShinPopup
        function onInsideNonceChanged() {
            if (root.opened)
                root.selectedAction = 0
        }

        function onActivateNonceChanged() {
            if (root.opened)
                root.openSettings()
        }
    }

    Timer {
        id: closeTimer
        interval: 240
        repeat: false
        onTriggered: {
            if (!root.hoverRoot && !root.hoverPopup)
                root.closePopup()
        }
    }

    Timer {
        id: hideTimer
        interval: 420
        repeat: false
        onTriggered: {
            if (!root.opened)
                root.popupVisible = false
        }
    }

    NumberAnimation {
        id: openAnim
        target: root
        property: "motion"
        from: 0
        to: 1
        duration: ShinData.popupAnim(470)
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: closeAnim
        target: root
        property: "motion"
        from: 1
        to: 0
        duration: ShinData.popupAnim(350)
        easing.type: Easing.InCubic
    }

    NumberAnimation {
        id: sweepAnim
        target: root
        property: "sweep"
        from: -170
        to: 520
        duration: ShinData.popupAnim(960)
        easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: introHeroAnim

        ScriptAction { script: root.introHero = 0.0 }
        PauseAnimation { duration: ShinData.popupAnim(70) }
        NumberAnimation {
            target: root
            property: "introHero"
            from: 0.0
            to: 1.0
            duration: ShinData.popupAnim(360)
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: introTopAnim

        ScriptAction { script: root.introTop = 0.0 }
        PauseAnimation { duration: ShinData.popupAnim(120) }
        NumberAnimation {
            target: root
            property: "introTop"
            from: 0.0
            to: 1.0
            duration: ShinData.popupAnim(390)
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: introCardsAnim

        ScriptAction { script: root.introCards = 0.0 }
        PauseAnimation { duration: ShinData.popupAnim(190) }
        NumberAnimation {
            target: root
            property: "introCards"
            from: 0.0
            to: 1.0
            duration: ShinData.popupAnim(430)
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: introFooterAnim

        ScriptAction { script: root.introFooter = 0.0 }
        PauseAnimation { duration: ShinData.popupAnim(270) }
        NumberAnimation {
            target: root
            property: "introFooter"
            from: 0.0
            to: 1.0
            duration: ShinData.popupAnim(360)
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: meterGlowAnim

        ScriptAction { script: root.meterGlow = 0.0 }
        PauseAnimation { duration: ShinData.popupAnim(180) }
        NumberAnimation {
            target: root
            property: "meterGlow"
            from: 0.0
            to: 1.0
            duration: ShinData.popupAnim(520)
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "meterGlow"
            from: 1.0
            to: 0.0
            duration: ShinData.popupAnim(580)
            easing.type: Easing.InOutCubic
        }
    }

    ShinPill {
        anchors.fill: parent
        anchors.topMargin: (parent.height - ShinConfig.pillH) / 2
        anchors.bottomMargin: (parent.height - ShinConfig.pillH) / 2
        active: root.opened || root.low
        clickable: false
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            root.hoverRoot = true
            root.openPopup()
        }
        onExited: {
            root.hoverRoot = false
            root.scheduleClose()
        }
        onClicked: root.togglePopup()
    }

    Row {
        id: bRow
        anchors.centerIn: parent
        spacing: 7
        scale: root.opened ? 1.05 : root.hoverRoot ? ShinConfig.hoverScale : 1.0

        Behavior on scale { NumberAnimation { duration: ShinData.anim(150); easing.type: Easing.OutCubic } }

        Item {
            width: 29
            height: 16
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                id: shell
                x: 0
                y: 2
                width: 25
                height: 12
                radius: 3
                color: "transparent"
                border.width: 1
                border.color: root.low ? ShinColors.warn : Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.70)

                Rectangle {
                    x: 2
                    y: 2
                    height: parent.height - 4
                    width: Math.max(2, (parent.width - 4) * root.clamp01(root.pct / 100))
                    radius: 2
                    color: root.low
                        ? ShinColors.warn
                        : root.charging
                            ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, root.pulse ? 0.95 : 0.55)
                            : ShinColors.accent

                    Behavior on width { NumberAnimation { duration: ShinData.anim(260); easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: ShinData.anim(180); easing.type: Easing.OutCubic } }
                }
            }

            Rectangle {
                x: 26
                y: 6
                width: 3
                height: 4
                radius: 1
                color: root.low ? ShinColors.warn : Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.70)
            }

            Text {
                visible: root.charging
                anchors.centerIn: shell
                text: "+"
                color: ShinColors.bg
                font.pixelSize: 9
                font.bold: true
                font.family: ShinConfig.fontFamily
                opacity: root.pulse ? 1 : 0.55
                Behavior on opacity { NumberAnimation { duration: ShinData.anim(180); easing.type: Easing.OutCubic } }
            }
        }

        Text {
            text: root.pct + "%"
            color: root.low ? ShinColors.warn : ShinColors.fg
            font.pixelSize: ShinConfig.fontSizeSm
            font.family: ShinConfig.fontFamily
            verticalAlignment: Text.AlignVCenter
            Behavior on color { ColorAnimation { duration: ShinData.anim(140); easing.type: Easing.OutCubic } }
        }
    }

    ShinSettings {
        showLauncher: false
    }

    PopupWindow {
        id: batteryPopup
        visible: root.popupVisible
        color: "transparent"
        implicitWidth: root.popupW
        implicitHeight: root.popupH

        anchor.item: root
        anchor.rect.x: Math.round(root.implicitWidth / 2 - batteryPopup.implicitWidth / 2)
        anchor.rect.y: root.implicitHeight + 10
        anchor.rect.width: 1
        anchor.rect.height: 1

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            z: 0
            onEntered: {
                root.hoverPopup = true
                root.openPopup()
            }
            onExited: {
                root.hoverPopup = false
                root.scheduleClose()
            }
        }

        Repeater {
            model: [0.10, 0.20, 0.30]
            Rectangle {
                property real t: root.trailT(modelData)
                z: -3
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.cardY(t)
                width: root.cardW(t)
                height: root.cardH(t)
                radius: root.cardRadius(t)
                antialiasing: true
                visible: ShinConfig.trailEnabled && root.popupVisible && (openAnim.running || closeAnim.running)
                opacity: (0.22 - index * 0.055) * (root.opened ? root.motion : Math.max(root.motion, 0.25))
                color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.18)
                border.width: 1
                border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.26)
            }
        }

        Rectangle {
            id: card
            property real t: root.opened ? root.emphasizedDecel(root.motion) : 1 - root.emphasizedAccel(1 - root.motion)
            property real ct: root.contentT()

            width: root.cardW(root.motion)
            height: root.cardH(root.motion)
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.cardY(root.motion)
            radius: root.cardRadius(root.motion)
            antialiasing: true
            clip: true
            opacity: root.clamp01(root.motion * 1.25)
            scale: 0.965 + root.emphasizedDecel(root.motion) * 0.035
            color: Qt.rgba(ShinColors.bg.r, ShinColors.bg.g, ShinColors.bg.b, ShinConfig.popupOpacity)
            border.width: 1
            border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.18 + 0.14 * root.motion)

            Rectangle {
                width: 180
                height: parent.height + 80
                x: root.sweep
                y: -40
                rotation: 16
                color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.055)
            }

            Column {
                anchors.fill: parent
                anchors.margins: Math.round(root.lerp(0, 18, card.ct))
                spacing: Math.round(root.lerp(0, 14, card.ct))
                opacity: root.clamp01(card.ct * 1.18)
                Behavior on opacity { NumberAnimation { duration: ShinData.anim(180); easing.type: Easing.OutCubic } }

                Row {
                    width: parent.width
                    height: root.lerp(parent.height, 84, card.ct)
                    spacing: Math.round(root.lerp(0, 16, card.ct))

                    Rectangle {
                        id: batteryHero
                        width: root.lerp(58, 84, card.ct)
                        height: width
                        radius: root.lerp(20, 24, card.ct)
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: root.introHero
                        scale: 0.94 + root.introHero * 0.06
                        color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.12)
                        border.width: 1
                        border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.24)
                        transform: Translate {
                            x: -16 * (1.0 - root.introHero)
                            y: 10 * (1.0 - root.introHero)
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width + 18 + root.meterGlow * 16
                            height: width
                            radius: width / 2
                            color: "transparent"
                            border.width: 1
                            border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.26 * root.meterGlow)
                            opacity: root.opened ? 1 : 0
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - 20
                            height: parent.height - 20
                            radius: 18
                            color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.035)
                        }

                        Canvas {
                            id: monitorIcon
                            anchors.centerIn: parent
                            width: Math.round(root.lerp(18, 38, card.ct))
                            height: width

                            onPaint: {
                                var ctx = getContext("2d")
                                var w = width
                                var h = height
                                ctx.clearRect(0, 0, w, h)
                                ctx.lineWidth = Math.max(1.5, w * 0.055)
                                ctx.strokeStyle = root.low ? ShinColors.warn : ShinColors.accent
                                ctx.fillStyle = Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.10)
                                ctx.lineJoin = "round"
                                ctx.lineCap = "round"

                                for (var i = 0; i < 4; ++i) {
                                    var p = w * (0.30 + i * 0.13)
                                    ctx.beginPath()
                                    ctx.moveTo(p, h * 0.12)
                                    ctx.lineTo(p, h * 0.21)
                                    ctx.moveTo(p, h * 0.79)
                                    ctx.lineTo(p, h * 0.88)
                                    ctx.moveTo(w * 0.12, p)
                                    ctx.lineTo(w * 0.21, p)
                                    ctx.moveTo(w * 0.79, p)
                                    ctx.lineTo(w * 0.88, p)
                                    ctx.stroke()
                                }

                                ctx.strokeRect(w * 0.22, h * 0.22, w * 0.56, h * 0.56)
                                ctx.globalAlpha = 0.42
                                ctx.strokeRect(w * 0.34, h * 0.34, w * 0.32, h * 0.32)
                                ctx.globalAlpha = 1
                            }

                            onWidthChanged: requestPaint()

                            Connections {
                                target: ShinColors
                                function onAccentChanged() { monitorIcon.requestPaint() }
                                function onWarnChanged() { monitorIcon.requestPaint() }
                                function onWalSignatureChanged() { monitorIcon.requestPaint() }
                            }
                        }
                    }

                    Column {
                        width: parent.width - batteryHero.width - settingsAction.width - parent.spacing * 2
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: root.lerp(0, 0, card.ct)
                        spacing: Math.round(root.lerp(0, 7, card.ct))
                        opacity: root.introTop
                        transform: Translate { x: 18 * (1.0 - root.introTop) }

                        Text {
                            width: parent.width
                            text: "Desempenho do sistema"
                            color: ShinColors.fg
                            font.pixelSize: Math.round(root.lerp(12, 18, card.ct))
                            font.bold: true
                            font.family: ShinConfig.fontFamily
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: card.ct > 0.18
                            opacity: card.ct
                            y: root.lerp(-8, 0, card.ct)
                            width: parent.width
                            text: "CPU " + root.cpuPct + "%  •  RAM " + root.ramPct + "%  •  Load " + root.load1
                            color: ShinColors.muted
                            font.pixelSize: 11
                            font.family: ShinConfig.fontFamily
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            visible: card.ct > 0.22
                            opacity: card.ct
                            width: parent.width
                            height: Math.round(root.lerp(3, 9, card.ct))
                            radius: 5
                            color: Qt.rgba(1, 1, 1, 0.06)
                            clip: true
                            Rectangle {
                                width: parent.width * root.clamp01(root.cpuPct / 100)
                                height: parent.height
                                radius: parent.radius
                                color: root.low ? ShinColors.warn : ShinColors.accent
                                Behavior on width { NumberAnimation { duration: ShinData.anim(260); easing.type: Easing.OutCubic } }
                            }
                            Rectangle {
                                width: 70
                                height: parent.height
                                x: root.lerp(-70, parent.width + 10, root.meterGlow)
                                color: Qt.rgba(1, 1, 1, 0.18 * root.meterGlow)
                            }
                        }
                    }

                    Rectangle {
                        id: settingsAction
                        width: root.lerp(0, 44, card.ct)
                        height: width
                        radius: 15
                        anchors.verticalCenter: parent.verticalCenter
                        visible: card.ct > 0.34 && root.introTop > 0.04
                        opacity: card.ct * root.introTop
                        color: root.settingsButtonHover
                            || root.settingsButtonSelected
                            ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.18)
                            : Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.085)
                        border.width: 1
                        border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, root.settingsButtonSelected ? 0.72 : root.settingsButtonHover ? 0.44 : 0.22)
                        scale: (0.92 + root.introTop * 0.08) * (root.settingsButtonSelected ? 1.06 : 1.0)

                        Text {
                            anchors.centerIn: parent
                            text: "⟳"
                            color: root.settingsButtonHover || root.settingsButtonSelected ? ShinColors.accent : ShinColors.fg
                            font.pixelSize: 18
                            font.bold: true
                            font.family: ShinConfig.fontFamily
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.settingsButtonHover = true
                            onExited: root.settingsButtonHover = false
                            onClicked: root.refreshStats()
                        }

                        Behavior on color { ColorAnimation { duration: ShinData.anim(120); easing.type: Easing.OutCubic } }
                        Behavior on border.color { ColorAnimation { duration: ShinData.anim(120); easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: ShinData.anim(140); easing.type: Easing.OutCubic } }
                    }
                }

                Rectangle {
                    visible: card.ct > 0.42
                    width: 118
                    height: 32
                    radius: 11
                    anchors.right: parent.right
                    anchors.rightMargin: 2
                    opacity: card.ct * root.introFooter
                    color: settingsMiniArea.containsMouse
                        ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.22)
                        : Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.07)
                    border.width: 1
                    border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, settingsMiniArea.containsMouse ? 0.48 : 0.22)
                    scale: (settingsMiniArea.containsMouse ? 1.025 : 1.0) * (0.94 + root.introFooter * 0.06)

                    Row {
                        anchors.centerIn: parent
                        spacing: 7

                        Text {
                            text: "▥"
                            color: ShinColors.accent
                            font.pixelSize: 14
                            font.family: ShinConfig.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Detalhes"
                            color: ShinColors.fg
                            font.pixelSize: 10
                            font.bold: true
                            font.family: ShinConfig.fontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: settingsMiniArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.openSettings()
                    }

                    Behavior on color { ColorAnimation { duration: ShinData.anim(130); easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: ShinData.anim(130); easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: ShinData.anim(130); easing.type: Easing.OutCubic } }
                }

                Grid {
                    width: parent.width
                    columns: 2
                    rowSpacing: Math.round(root.lerp(0, 10, card.ct))
                    columnSpacing: Math.round(root.lerp(0, 10, card.ct))
                    opacity: card.ct * root.introCards
                    scale: 0.97 + root.introCards * 0.03
                    y: root.lerp(-14, 0, card.ct)
                    visible: opacity > 0.01

                    Repeater {
                        model: [
                            { icon: "cpu", label: "CPU", value: root.cpuPct + "%", pct: root.cpuPct, sub: root.temp > 0 ? root.temp + "°C" : root.procs + " proc" },
                            { icon: "ram", label: "RAM", value: root.ramUsed + " / " + root.ramTotal + " GiB", pct: root.ramPct, sub: root.ramPct + "%" },
                            { icon: "disk", label: "Disco", value: root.diskUsed + " / " + root.diskTotal + " GiB", pct: root.diskPct, sub: root.diskPct + "% em ~" },
                            { icon: "net", label: "Rede", value: "Enviando " + root.netTx + " Mbps", pct: root.netPct, sub: root.netPct + "%", extra: "Recebendo " + root.netRx + " Mbps" }
                        ]

                        Rectangle {
                            width: (card.width - 46) / 2
                            height: root.lerp(22, 86, card.ct)
                            radius: root.lerp(12, 18, card.ct)
                            color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.045 + 0.018 * root.meterGlow)
                            border.width: 1
                            border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.12 + 0.08 * root.meterGlow)
                            clip: true

                            Column {
                                anchors.fill: parent
                                anchors.margins: Math.round(root.lerp(5, 12, card.ct))
                                spacing: Math.round(root.lerp(0, 7, card.ct))

                                Row {
                                    width: parent.width
                                    height: root.lerp(12, 24, card.ct)
                                    spacing: 7

                                    Rectangle {
                                        width: 22
                                        height: 22
                                        radius: 7
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.06)
                                        border.width: 1
                                        border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.14)
                                        opacity: card.ct

                                        Canvas {
                                            id: metricIcon
                                            property string kind: modelData.icon
                                            anchors.centerIn: parent
                                            width: 14
                                            height: 14

                                            onPaint: {
                                                var ctx = getContext("2d")
                                                var w = width
                                                var h = height
                                                ctx.clearRect(0, 0, w, h)
                                                ctx.strokeStyle = ShinColors.accent
                                                ctx.fillStyle = ShinColors.accent
                                                ctx.lineWidth = 1.4
                                                ctx.lineCap = "round"
                                                ctx.lineJoin = "round"

                                                if (kind === "cpu") {
                                                    ctx.strokeRect(w * 0.24, h * 0.24, w * 0.52, h * 0.52)
                                                    ctx.strokeRect(w * 0.39, h * 0.39, w * 0.22, h * 0.22)
                                                    for (var i = 0; i < 3; ++i) {
                                                        var p = w * (0.28 + i * 0.22)
                                                        ctx.beginPath()
                                                        ctx.moveTo(p, h * 0.05); ctx.lineTo(p, h * 0.18)
                                                        ctx.moveTo(p, h * 0.82); ctx.lineTo(p, h * 0.95)
                                                        ctx.moveTo(w * 0.05, p); ctx.lineTo(w * 0.18, p)
                                                        ctx.moveTo(w * 0.82, p); ctx.lineTo(w * 0.95, p)
                                                        ctx.stroke()
                                                    }
                                                } else if (kind === "ram") {
                                                    ctx.strokeRect(w * 0.12, h * 0.28, w * 0.76, h * 0.44)
                                                    for (var r = 0; r < 3; ++r)
                                                        ctx.fillRect(w * (0.24 + r * 0.18), h * 0.40, w * 0.08, h * 0.18)
                                                } else if (kind === "disk") {
                                                    ctx.strokeRect(w * 0.20, h * 0.16, w * 0.60, h * 0.68)
                                                    ctx.beginPath()
                                                    ctx.arc(w * 0.50, h * 0.36, w * 0.12, 0, Math.PI * 2)
                                                    ctx.stroke()
                                                    ctx.beginPath()
                                                    ctx.moveTo(w * 0.34, h * 0.70); ctx.lineTo(w * 0.66, h * 0.70)
                                                    ctx.stroke()
                                                } else {
                                                    ctx.beginPath()
                                                    ctx.arc(w * 0.50, h * 0.78, w * 0.06, 0, Math.PI * 2)
                                                    ctx.fill()
                                                    ctx.beginPath()
                                                    ctx.arc(w * 0.50, h * 0.78, w * 0.26, Math.PI * 1.18, Math.PI * 1.82)
                                                    ctx.arc(w * 0.50, h * 0.78, w * 0.46, Math.PI * 1.15, Math.PI * 1.85)
                                                    ctx.stroke()
                                                }
                                            }

                                            Connections {
                                                target: ShinColors
                                                function onAccentChanged() { metricIcon.requestPaint() }
                                                function onWalSignatureChanged() { metricIcon.requestPaint() }
                                            }
                                        }
                                    }

                                    Text {
                                        width: parent.width - 22 - 58 - parent.spacing * 2
                                        text: modelData.label
                                        color: ShinColors.fg
                                        font.pixelSize: Math.round(root.lerp(9, 12, card.ct))
                                        font.bold: true
                                        font.family: ShinConfig.fontFamily
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        opacity: card.ct
                                        width: 58
                                        text: modelData.sub
                                        color: ShinColors.muted
                                        font.pixelSize: 9
                                        font.family: ShinConfig.fontFamily
                                        horizontalAlignment: Text.AlignRight
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    visible: card.ct > 0.18
                                    opacity: card.ct
                                    y: root.lerp(-6, 0, card.ct)
                                    width: parent.width
                                    text: modelData.value
                                    color: ShinColors.accent
                                    font.pixelSize: 11
                                    font.family: ShinConfig.fontFamily
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: card.ct > 0.18 && modelData.extra !== undefined
                                    opacity: card.ct
                                    width: parent.width
                                    text: modelData.extra || ""
                                    color: ShinColors.muted
                                    font.pixelSize: 9
                                    font.family: ShinConfig.fontFamily
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    visible: card.ct > 0.24
                                    opacity: card.ct
                                    width: parent.width
                                    height: Math.round(root.lerp(3, 8, card.ct))
                                    radius: 4
                                    color: Qt.rgba(1, 1, 1, 0.06)
                                    clip: true
                                    Rectangle {
                                        width: parent.width * root.clamp01(modelData.pct / 100)
                                        height: parent.height
                                        radius: parent.radius
                                        color: modelData.pct >= 85 ? ShinColors.warn : ShinColors.accent
                                        Behavior on width { NumberAnimation { duration: ShinData.anim(320); easing.type: Easing.OutCubic } }
                                    }
                                    Rectangle {
                                        width: 54
                                        height: parent.height
                                        x: root.lerp(-54, parent.width + 8, root.meterGlow)
                                        color: Qt.rgba(1, 1, 1, 0.14 * root.meterGlow)
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: card.ct > 0.35
                    width: parent.width
                    text: "Load 5m " + root.load5 + "  •  Load 15m " + root.load15 + "  •  Processos " + root.procs
                    color: ShinColors.muted
                    font.pixelSize: 10
                    font.family: ShinConfig.fontFamily
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    opacity: card.ct * root.introFooter
                    y: root.lerp(-8, 0, card.ct)
                }
            }
        }
    }
}
