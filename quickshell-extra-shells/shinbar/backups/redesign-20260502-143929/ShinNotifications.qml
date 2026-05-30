import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "."

PanelWindow {
    id: win

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "shinbar-notifications"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 760
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    visible: panelOpen || panelReveal > 0.01 || toastModel.count > 0

    property bool panelOpen: ShinPopup.notificationsOpen
    property real panelReveal: panelOpen ? 1.0 : 0.0
    property real morphEase: 1.0 - Math.pow(1.0 - panelReveal, 3.0)
    property real contentReveal: Math.max(0.0, Math.min(1.0, (panelReveal - 0.42) / 0.58))
    property int openNonce: 0
    property real trailBurst: 0.0

    property int cardW: 335
    property int panelW: 430
    property int panelH: 560

    property int maxToasts: 4
    property int maxHistory: 80
    property int toastLifetimeMs: 9500

    // Toast perto do sininho.
    property int bellX: Math.round(ShinConfig.barMarginH + ShinPopup.notificationsX)
    property int bellY: Math.round(ShinConfig.barMarginT + (ShinConfig.barH - ShinConfig.pillH) / 2)

    property int toastX: ShinConfig.barMarginH + ShinPopup.notificationsX
    property int toastY: ShinConfig.barH + ShinConfig.barMarginT + 54

    // Histórico quase no canto esquerdo.
    property int panelX: 8
    property bool notificationsMuted: false


    property int panelY: ShinConfig.barH + ShinConfig.barMarginT + 54

    property string storePath: "/home/shira/.cache/shinbar/notifications.json"

    onPanelOpenChanged: {
        trailAnim.restart()

        if (panelOpen) {
            openNonce += 1
            loadHistory()
        }
    }

    Behavior on panelReveal {
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: trailAnim

        ScriptAction {
            script: win.trailBurst = 1.0
        }

        PauseAnimation {
            duration: 80
        }

        NumberAnimation {
            target: win
            property: "trailBurst"
            from: 1.0
            to: 0.0
            duration: 760
            easing.type: Easing.OutCubic
        }
    }

    function nowClock() {
        var d = new Date()
        var h = d.getHours().toString().padStart(2, "0")
        var m = d.getMinutes().toString().padStart(2, "0")
        return h + ":" + m
    }

    function todayDate() {
        var d = new Date()
        var day = d.getDate().toString().padStart(2, "0")
        var mo = (d.getMonth() + 1).toString().padStart(2, "0")
        return day + "/" + mo
    }

    function makeItem(app, summary, body) {
        return {
            app: app || "App",
            summary: summary || "Notificação",
            body: body || "",
            clock: nowClock(),
            date: todayDate(),
            created: Date.now()
        }
    }

    function saveHistory() {
        var arr = []

        for (var i = 0; i < historyModel.count; ++i) {
            var n = historyModel.get(i)

            arr.push({
                app: n.app || "App",
                summary: n.summary || "Notificação",
                body: n.body || "",
                clock: n.clock || "",
                date: n.date || "",
                created: n.created || Date.now()
            })
        }

        var json = JSON.stringify(arr)

        saveProc.command = [
            "python3",
            "-c",
            "import sys, pathlib; p=pathlib.Path(sys.argv[1]); p.parent.mkdir(parents=True, exist_ok=True); p.write_text(sys.argv[2], encoding='utf-8')",
            storePath,
            json
        ]

        saveProc.running = true
    }

    function loadHistory() {
        if (!loadProc.running)
            loadProc.running = true
    }

    function pushHistory(item) {
        historyModel.insert(0, item)

        while (historyModel.count > maxHistory)
            historyModel.remove(historyModel.count - 1)

        saveHistory()
    }

    function clearHistory() {
        historyModel.clear()
        toastModel.clear()
        saveHistory()
        openNonce += 1
    }

    function pushNotification(app, summary, body) {
        var item = makeItem(app, summary, body)

        toastModel.insert(0, item)
        pushHistory(item)

        while (toastModel.count > maxToasts)
            toastModel.remove(toastModel.count - 1)
    }

    Component.onCompleted: loadHistory()

    ListModel {
        id: toastModel
    }

    ListModel {
        id: historyModel
    }

    Process {
        id: loadProc
        running: false
        command: ["bash", "-lc", "cat '" + win.storePath + "' 2>/dev/null || printf '[]'"]

        stdout: SplitParser {
            onRead: function(lineRaw) {
                var line = lineRaw.trim()

                if (!line)
                    line = "[]"

                try {
                    var arr = JSON.parse(line)

                    historyModel.clear()

                    for (var i = 0; i < arr.length; ++i) {
                        historyModel.append({
                            app: arr[i].app || "App",
                            summary: arr[i].summary || "Notificação",
                            body: arr[i].body || "",
                            clock: arr[i].clock || "",
                            date: arr[i].date || "",
                            created: arr[i].created || Date.now()
                        })
                    }
                } catch(e) {
                    console.log("ShinNotifications: erro ao carregar histórico:", e)
                }
            }
        }

        onExited: running = false
    }

    Process {
        id: saveProc
        running: false
        command: ["true"]
        onExited: running = false
    }

    Process {
        id: notifyWatcher
        running: true
        command: ["bash", "-lc", "~/.config/quickshell/shinbar/scripts/shinbar-notify-watch"]

        stdout: SplitParser {
            onRead: function(lineRaw) {
                var line = lineRaw.trim()

                if (!line)
                    return

                try {
                    var n = JSON.parse(line)
                    win.pushNotification(n.app, n.summary, n.body)
                } catch(e) {
                    win.pushNotification("Shinbar", "Erro ao ler notificação", line)
                }
            }
        }

        onExited: restartWatcher.restart()
    }

    Timer {
        id: restartWatcher
        interval: 1400
        repeat: false
        onTriggered: notifyWatcher.running = true
    }

    Timer {
        interval: 700
        repeat: true
        running: true

        onTriggered: {
            var now = Date.now()

            for (var i = toastModel.count - 1; i >= 0; --i) {
                var n = toastModel.get(i)

                if (now - n.created > win.toastLifetimeMs)
                    toastModel.remove(i)
            }
        }
    }

    Item {
        anchors.fill: parent

        // =========================
        // TOASTS TEMPORÁRIOS
        // =========================
        Column {
            id: toastRail

            visible: !win.panelOpen

            x: win.toastX
            y: win.toastY

            width: win.cardW
            spacing: 10

            Repeater {
                model: toastModel

                Rectangle {
                    id: toastCard

                    property real reveal: 0.0
                    property string initial: model.app.length > 0 ? model.app.charAt(0).toUpperCase() : "N"

                    width: win.cardW
                    height: model.body.length > 0 ? 92 : 74
                    radius: 24
                    antialiasing: true
                    clip: true

                    opacity: reveal
                    scale: 0.955 + reveal * 0.045

                    transform: Translate {
                        x: -34 * (1.0 - toastCard.reveal)
                        y: 12 * (1.0 - toastCard.reveal)
                    }

                    color: Qt.rgba((ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").r, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").g, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").b, 0.58)

                    border.width: 1
                    border.color: Qt.rgba(
                        (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                        (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                        (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                        0.18 + 0.10 * reveal
                    )

                    Component.onCompleted: reveal = 1.0

                    Behavior on reveal {
                        NumberAnimation {
                            duration: 430
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        width: 130
                        height: 100
                        radius: 50
                        x: -72
                        y: -48
                        color: Qt.rgba(
                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                            0.085
                        )
                    }

                    Rectangle {
                        width: 4
                        height: parent.height - 24
                        radius: 2
                        anchors.left: parent.left
                        anchors.leftMargin: 11
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.rgba(
                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                            0.65
                        )
                    }

                    Rectangle {
                        id: toastBubble

                        width: 34
                        height: 34
                        radius: 17

                        anchors.left: parent.left
                        anchors.leftMargin: 24
                        anchors.top: parent.top
                        anchors.topMargin: 18

                        color: Qt.rgba(
                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                            0.17
                        )

                        border.width: 1
                        border.color: Qt.rgba(
                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                            0.22
                        )

                        Text {
                            anchors.centerIn: parent
                            text: toastCard.initial
                            color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                            font.pixelSize: 13
                            font.bold: true
                            font.family: ShinConfig.fontFamily
                        }
                    }

                    Item {
                        anchors.left: toastBubble.right
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 18
                        anchors.top: parent.top
                        anchors.topMargin: 15
                        height: parent.height - 22

                        Text {
                            id: toastApp
                            x: 0
                            y: 0
                            width: parent.width - 56
                            text: model.app
                            color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                            font.pixelSize: 10
                            font.bold: true
                            font.family: ShinConfig.fontFamily
                            elide: Text.ElideRight
                        }

                        Text {
                            x: parent.width - 48
                            y: 0
                            width: 48
                            text: "agora"
                            color: (ShinColors && ShinColors.text ? ShinColors.text : "#ffffff")
                            font.pixelSize: 9
                            font.family: ShinConfig.fontFamily
                            horizontalAlignment: Text.AlignRight
                        }

                        Text {
                            x: 0
                            y: 21
                            width: parent.width
                            text: model.summary
                            color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                            font.pixelSize: 12
                            font.bold: true
                            font.family: ShinConfig.fontFamily
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: model.body.length > 0
                            x: 0
                            y: 42
                            width: parent.width
                            text: model.body
                            color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                            font.pixelSize: 10
                            font.family: ShinConfig.fontFamily
                            maximumLineCount: 2
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: toastModel.remove(index)
                    }
                }
            }
        }


        // =========================
        // RASTRO DA EXPANSÃO
        // =========================


        // =========================
        // MORPH: PILL -> HISTÓRICO
        // =========================
        Repeater {
            id: morphAfterImages

            model: [0.12, 0.22]

            Rectangle {
                property real t: Math.max(0.0, Math.min(1.0, (win.panelReveal - modelData) / (1.0 - modelData)))
                property real e: 1.0 - Math.pow(1.0 - t, 3.0)

                z: 1
                visible: win.panelReveal > 0.01 && win.contentReveal < 0.95

                readonly property int startW: 42
                readonly property int startH: ShinConfig.pillH
                readonly property int startX: win.bellX
                readonly property int startY: win.bellY

                x: Math.round(startX + (win.panelX - startX) * e)
                y: Math.round(startY + (win.panelY - startY) * e)
                width: Math.round(startW + (win.panelW - startW) * e)
                height: Math.round(startH + (win.panelH - startH) * e)

                radius: Math.round((startH / 2) + (30 - startH / 2) * e)
                antialiasing: true
                clip: true

                opacity: (0.18 - index * 0.055) * (1.0 - win.contentReveal)

                color: Qt.rgba(
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                    0.18
                )

                border.width: 1
                border.color: Qt.rgba(
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                    0.20
                )
            }
        }

        Rectangle {
            id: morphTrailPanel

            z: 2
            visible: win.panelReveal > 0.01 && win.contentReveal < 0.98

            readonly property int startW: 42
            readonly property int startH: ShinConfig.pillH
            readonly property int startX: win.bellX
            readonly property int startY: win.bellY

            property real t: win.morphEase

            x: Math.round(startX + (win.panelX - startX) * t)
            y: Math.round(startY + (win.panelY - startY) * t)
            width: Math.round(startW + (win.panelW - startW) * t)
            height: Math.round(startH + (win.panelH - startH) * t)

            radius: Math.round((startH / 2) + (30 - startH / 2) * t)
            antialiasing: true
            clip: true

            opacity: Math.max(0.0, 0.72 * (1.0 - win.contentReveal))
            scale: 0.995 + 0.005 * t

            color: Qt.rgba(
                (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").r,
                (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").g,
                (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").b,
                0.52
            )

            border.width: 1
            border.color: Qt.rgba(
                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                0.26
            )

            Rectangle {
                width: 150
                height: 110
                radius: 60
                x: -70
                y: -46
                color: Qt.rgba(
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                    0.12
                )
            }

            Text {
                anchors.centerIn: parent
                visible: morphTrailPanel.t < 0.35
                text: "󰂚"
                color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                font.pixelSize: ShinConfig.fontSize + 1
                font.bold: true
                font.family: ShinConfig.fontFamily
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 18
                visible: morphTrailPanel.t >= 0.35
                opacity: Math.min(1.0, (morphTrailPanel.t - 0.35) / 0.35)
                text: "󰂚  Histórico"
                color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                font.pixelSize: 14
                font.bold: true
                font.family: ShinConfig.fontFamily
            }
        }

        // =========================
        // HISTÓRICO FIXO
        // =========================
        Rectangle {
            id: historyPanel

            visible: win.panelReveal > 0.01

            x: win.panelX
            y: win.panelY - Math.round((1.0 - win.panelReveal) * 18)

            width: win.panelW
            height: win.panelH
            radius: 30
            antialiasing: true
            clip: true

            opacity: win.contentReveal
            scale: 0.985 + win.contentReveal * 0.015
            transformOrigin: Item.TopLeft

            color: Qt.rgba((ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").r, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").g, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").b, 0.54)

            border.width: 1
            border.color: Qt.rgba(
                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                0.24
            )

            Rectangle {
                width: 160
                height: 130
                radius: 70
                x: -76
                y: -58
                color: Qt.rgba(
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                    0.10
                )
            }

            Item {
                id: header

                x: 16
                y: 14
                width: parent.width - 32
                height: 34

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰂚  Histórico"
                color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                    font.pixelSize: 14
                    font.bold: true
                    font.family: ShinConfig.fontFamily
                }

                Rectangle {
                    width: 72
                    height: 24
                    radius: 12
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.07)

                    border.width: 1
                    border.color: Qt.rgba(
                        (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                        (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                        (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                        0.12
                    )

                    Text {
                        anchors.centerIn: parent
                        text: "limpar"
                        color: (ShinColors && ShinColors.text ? ShinColors.text : "#ffffff")
                        font.pixelSize: 10
                        font.family: ShinConfig.fontFamily
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: win.clearHistory()
                    }
                }
            }

            Rectangle {
                x: 16
                y: 56
                width: parent.width - 32
                height: 1
                color: Qt.rgba(
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                    0.15
                )
            }

            Item {
                visible: historyModel.count === 0
                x: 16
                y: 58
                width: parent.width - 32
                height: parent.height - 74

                Text {
                    anchors.centerIn: parent
                    text: "Nenhuma notificação"
                    color: (ShinColors && ShinColors.text ? ShinColors.text : "#ffffff")
                    font.pixelSize: 11
                    font.family: ShinConfig.fontFamily
                }
            }

            ListView {
                id: historyView

                visible: historyModel.count > 0

                x: 14
                y: 72
                width: parent.width - 28
                height: parent.height - 86

                clip: true
                spacing: 9
                model: historyModel

                delegate: Rectangle {
                    id: historyCard

                    property real cardReveal: 0.0
                    property string initial: model.app.length > 0 ? model.app.charAt(0).toUpperCase() : "N"

                    width: historyView.width
                    height: model.body.length > 0 ? 86 : 68
                    radius: 20
                    antialiasing: true
                    clip: true

                    opacity: win.panelReveal * cardReveal
                    scale: 0.965 + cardReveal * 0.035

                    transform: Translate {
                        x: -26 * (1.0 - historyCard.cardReveal)
                        y: 8 * (1.0 - historyCard.cardReveal)
                    }

                    color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.055)

                    border.width: 1
                    border.color: Qt.rgba(
                        (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                        (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                        (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                        0.09
                    )

                    function replay() {
                        cardReveal = 0.0
                        revealAnim.restart()
                    }

                    Component.onCompleted: replay()

                    Connections {
                        target: win

                        function onOpenNonceChanged() {
                            if (win.panelOpen)
                                historyCard.replay()
                        }
                    }

                    SequentialAnimation {
                        id: revealAnim

                        PauseAnimation {
                            duration: Math.max(0, Math.min(index * 65, 520))
                        }

                        NumberAnimation {
                            target: historyCard
                            property: "cardReveal"
                            from: 0.0
                            to: 1.0
                            duration: 360
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        id: histBubble

                        width: 32
                        height: 32
                        radius: 16

                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.top: parent.top
                        anchors.topMargin: 14

                        color: Qt.rgba(
                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                            0.17
                        )

                        border.width: 1
                        border.color: Qt.rgba(
                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                            0.18
                        )

                        Text {
                            anchors.centerIn: parent
                            text: historyCard.initial
                            color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                            font.pixelSize: 11
                            font.bold: true
                            font.family: ShinConfig.fontFamily
                        }
                    }

                    Item {
                        anchors.left: histBubble.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        height: parent.height - 20

                        Text {
                            x: 0
                            y: 0
                            width: parent.width - 62
                            text: model.app
                            color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                            font.pixelSize: 9
                            font.bold: true
                            font.family: ShinConfig.fontFamily
                            elide: Text.ElideRight
                        }

                        Text {
                            x: parent.width - 58
                            y: 0
                            width: 58
                            text: model.clock
                            color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                            font.pixelSize: 9
                            font.family: ShinConfig.fontFamily
                            horizontalAlignment: Text.AlignRight
                        }

                        Text {
                            x: 0
                            y: 19
                            width: parent.width
                            text: model.summary
                            color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                            font.pixelSize: 11
                            font.bold: true
                            font.family: ShinConfig.fontFamily
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: model.body.length > 0
                            x: 0
                            y: 39
                            width: parent.width
                            text: model.body
                            color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                            font.pixelSize: 9
                            maximumLineCount: 2
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
                            font.family: ShinConfig.fontFamily
                        }
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            historyModel.remove(index)
                            win.saveHistory()
                        }
                    }
                }
            }
        }
    }
}
