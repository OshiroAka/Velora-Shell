import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects
import "."

PanelWindow {
    id: win

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: ShinConfig.namespace + "-expanded-host"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 650
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: ShinPopup.expandedOpen || motion > 0.02 || openAnim.running || closeAnim.running || switchAnim.running

    property string page: ShinPopup.expandedPage

    property real motion: 0.0
    property int motionDir: 1

    property real stageX: 0.0
    property real stageY: 0.0
    property real stageOpacity: 1.0
    property real stageScale: 1.0
    property real trailGlow: 0.0
    property real sweepX: -240

    property var now: new Date()

    // Weather data.
    property string temp: "--"
    property string feels: "--"
    property string desc: "Carregando"
    property string location: "..."
    property string humidity: "--"
    property string wind: "--"
    property string windDir: ""
    property string precip: "0"
    property string cloudcover: "--"
    property var days: []

    property string fxMode: "auto"
    readonly property var fxModes: ["auto", "rain", "sun", "cloud", "wind"]

    property string visualMode: fxMode === "auto"
        ? (isRainy() ? "rain" : isSunny() ? "sun" : isWindy() ? "wind" : "cloud")
        : fxMode

    readonly property int closedW: 110
    readonly property int closedH: 34

    readonly property int clockW: 570
    readonly property int clockH: 470

    readonly property int weatherW: 1320
    readonly property int weatherH: 520

    readonly property int targetW: page === "weather" ? weatherW : clockW
    readonly property int targetH: page === "weather" ? weatherH : clockH

    readonly property int leftW: visualMode === "sun" ? 390
                                : visualMode === "rain" ? 320
                                : visualMode === "wind" ? 330
                                : 350

    readonly property int topH: visualMode === "wind" ? 154
                               : visualMode === "rain" ? 108
                               : visualMode === "sun" ? 122
                               : 132

    function clamp01(v) {
        return Math.max(0, Math.min(1, v))
    }

    function lerp(a, b, t) {
        return a + (b - a) * t
    }

    function easeOut(t) {
        t = clamp01(t)
        return 1 - Math.pow(1 - t, 3.15)
    }

    function cardW(t) {
        return lerp(closedW, targetW, easeOut(t))
    }

    function cardH(t) {
        return lerp(closedH, targetH, easeOut(t))
    }

    function cardY(t) {
        return lerp(-18, 0, easeOut(t))
    }

    function trailT(offset) {
        if (motionDir >= 0)
            return clamp01(motion - offset)

        return clamp01(motion + offset)
    }

    function seasonName() {
        var mo = now.getMonth() + 1
        if (mo >= 12 || mo <= 2) return "Verão"
        if (mo >= 3 && mo <= 5) return "Outono"
        if (mo >= 6 && mo <= 8) return "Inverno"
        return "Primavera"
    }

    function weatherIcon() {
        var d = desc.toLowerCase()

        if (d.indexOf("storm") >= 0 || d.indexOf("thunder") >= 0 || d.indexOf("trovo") >= 0)
            return "⚡︎"

        if (d.indexOf("rain") >= 0 || d.indexOf("chuva") >= 0 || d.indexOf("garoa") >= 0 || d.indexOf("drizzle") >= 0)
            return "☔︎"

        if (d.indexOf("cloud") >= 0 || d.indexOf("nublado") >= 0 || d.indexOf("overcast") >= 0)
            return "☁︎"

        if (d.indexOf("mist") >= 0 || d.indexOf("fog") >= 0 || d.indexOf("neblina") >= 0)
            return "≋"

        if (d.indexOf("clear") >= 0 || d.indexOf("sun") >= 0 || d.indexOf("sol") >= 0)
            return "☀︎"

        return "◌"
    }

    function isRainy() {
        var d = desc.toLowerCase()
        return d.indexOf("rain") >= 0 || d.indexOf("chuva") >= 0 || d.indexOf("garoa") >= 0 || d.indexOf("drizzle") >= 0
    }

    function isSunny() {
        var d = desc.toLowerCase()
        return d.indexOf("clear") >= 0 || d.indexOf("sun") >= 0 || d.indexOf("sol") >= 0
    }

    function isWindy() {
        var n = parseInt(wind)
        if (isNaN(n))
            n = 0

        return n >= 14
    }

    function fxRain() {
        return visualMode === "rain"
    }

    function fxSun() {
        return visualMode === "sun"
    }

    function fxCloud() {
        return visualMode === "cloud" || visualMode === "rain"
    }

    function fxWind() {
        return visualMode === "wind"
    }

    function fxName(v) {
        if (v === "auto") return "Auto"
        if (v === "rain") return "Chuva"
        if (v === "sun") return "Sol"
        if (v === "cloud") return "Nuvem"
        if (v === "wind") return "Vento"
        return v
    }

    function advanceWeatherMode() {
        var idx = fxModes.indexOf(fxMode)
        if (idx < 0)
            idx = 0

        fxMode = fxModes[(idx + 1) % fxModes.length]
    }

    function dayIcon(dayDesc, rainChance) {
        var d = (dayDesc || "").toLowerCase()

        if (parseInt(rainChance) >= 60)
            return "☔︎"

        if (d.indexOf("storm") >= 0 || d.indexOf("thunder") >= 0)
            return "⚡︎"

        if (d.indexOf("rain") >= 0 || d.indexOf("chuva") >= 0 || d.indexOf("garoa") >= 0)
            return "☔︎"

        if (d.indexOf("cloud") >= 0 || d.indexOf("nublado") >= 0 || d.indexOf("overcast") >= 0)
            return "☁︎"

        if (d.indexOf("clear") >= 0 || d.indexOf("sun") >= 0 || d.indexOf("sol") >= 0)
            return "☀︎"

        return "◌"
    }

    function rainLabel(v) {
        var n = parseInt(v)
        if (isNaN(n))
            return "0%"

        return n + "%"
    }

    function percentWidth(v, total) {
        var n = parseInt(v)
        if (isNaN(n))
            n = 0

        n = Math.max(0, Math.min(100, n))
        return total * n / 100.0
    }

    function refreshWeather() {
        if (!weatherProc.running)
            weatherProc.running = true
    }

    Connections {
        target: ShinPopup

        function onExpandedOpenChanged() {
            if (ShinPopup.expandedOpen) {
                closeAnim.stop()
                motionDir = 1
                openAnim.from = motion
                openAnim.restart()
                if (ShinPopup.expandedPage === "weather")
                    refreshWeather()
            } else {
                openAnim.stop()
                motionDir = -1
                closeAnim.from = motion
                closeAnim.restart()
            }
        }

        function onSwitchNonceChanged() {
            if (ShinPopup.switchingTo.length > 0)
                switchAnim.restart()
        }

        function onWeatherFxCycleNonceChanged() {
            if (ShinPopup.expandedPage === "weather")
                weatherModeAnim.restart()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: now = new Date()
    }

    Timer {
        interval: 600000
        running: true
        repeat: true
        onTriggered: refreshWeather()
    }

    Component.onCompleted: refreshWeather()

    Process {
        id: weatherProc
        running: false
        command: ["bash", "-lc", "~/.config/quickshell/shinbar/scripts/shinbar-temperature"]

        stdout: SplitParser {
            onRead: function(lineRaw) {
                var line = lineRaw.trim()
                if (!line) return

                if (line.startsWith("LOCATION="))
                    location = line.substring(9)
                else if (line.startsWith("TEMP="))
                    temp = line.substring(5)
                else if (line.startsWith("FEELS="))
                    feels = line.substring(6)
                else if (line.startsWith("DESC="))
                    desc = line.substring(5)
                else if (line.startsWith("HUMIDITY="))
                    humidity = line.substring(9)
                else if (line.startsWith("WIND="))
                    wind = line.substring(5)
                else if (line.startsWith("WIND_DIR="))
                    windDir = line.substring(9)
                else if (line.startsWith("PRECIP="))
                    precip = line.substring(7)
                else if (line.startsWith("CLOUDCOVER="))
                    cloudcover = line.substring(11)
                else if (line.startsWith("DAYS=")) {
                    try {
                        days = JSON.parse(line.substring(5))
                    } catch(e) {
                        days = []
                    }
                }
            }
        }

        onExited: running = false
    }

    NumberAnimation {
        id: openAnim
        target: win
        property: "motion"
        from: 0
        to: 1
        duration: ShinData.popupAnim(420)
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: closeAnim
        target: win
        property: "motion"
        from: 1
        to: 0
        duration: ShinData.popupAnim(310)
        easing.type: Easing.InCubic
    }

    SequentialAnimation {
        id: switchAnim

        ScriptAction {
            script: {
                trailGlow = 0
                sweepX = ShinPopup.switchDir >= 0 ? -240 : card.width + 120
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: win
                property: "stageX"
                from: 0
                to: ShinPopup.switchDir >= 0 ? -110 : 110
                duration: ShinData.popupAnim(190)
                easing.type: Easing.InCubic
            }

            NumberAnimation {
                target: win
                property: "stageY"
                from: 0
                to: 12
                duration: ShinData.popupAnim(190)
                easing.type: Easing.InCubic
            }

            NumberAnimation {
                target: win
                property: "stageOpacity"
                from: 1
                to: 0
                duration: ShinData.popupAnim(190)
                easing.type: Easing.InCubic
            }

            NumberAnimation {
                target: win
                property: "stageScale"
                from: 1
                to: 0.965
                duration: ShinData.popupAnim(190)
                easing.type: Easing.InCubic
            }

            NumberAnimation {
                target: win
                property: "trailGlow"
                from: 0
                to: 1
                duration: ShinData.popupAnim(190)
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: win
                property: "sweepX"
                from: ShinPopup.switchDir >= 0 ? -240 : card.width + 120
                to: ShinPopup.switchDir >= 0 ? card.width * 0.45 : card.width * 0.45
                duration: ShinData.popupAnim(210)
                easing.type: Easing.OutCubic
            }
        }

        ScriptAction {
            script: {
                ShinPopup.finishSwitch()
                stageX = ShinPopup.switchDir >= 0 ? 130 : -130
                stageY = -18
                stageOpacity = 0
                stageScale = 0.965
                sweepX = ShinPopup.switchDir >= 0 ? -160 : card.width + 160
                if (ShinPopup.expandedPage === "weather")
                    refreshWeather()
            }
        }

        PauseAnimation { duration: ShinData.popupAnim(55) }

        ParallelAnimation {
            NumberAnimation {
                target: win
                property: "stageX"
                from: ShinPopup.switchDir >= 0 ? 130 : -130
                to: 0
                duration: ShinData.popupAnim(430)
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: win
                property: "stageY"
                from: -18
                to: 0
                duration: ShinData.popupAnim(430)
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: win
                property: "stageOpacity"
                from: 0
                to: 1
                duration: ShinData.popupAnim(430)
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: win
                property: "stageScale"
                from: 0.965
                to: 1
                duration: ShinData.popupAnim(430)
                easing.type: Easing.OutBack
            }

            NumberAnimation {
                target: win
                property: "trailGlow"
                from: 1
                to: 0
                duration: ShinData.popupAnim(520)
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: win
                property: "sweepX"
                from: ShinPopup.switchDir >= 0 ? -160 : card.width + 160
                to: ShinPopup.switchDir >= 0 ? card.width + 160 : -260
                duration: ShinData.popupAnim(520)
                easing.type: Easing.OutCubic
            }
        }
    }

    SequentialAnimation {
        id: weatherModeAnim

        ParallelAnimation {
            NumberAnimation {
                target: win
                property: "stageX"
                from: 0
                to: -80
                duration: ShinData.popupAnim(170)
                easing.type: Easing.InCubic
            }

            NumberAnimation {
                target: win
                property: "stageOpacity"
                from: 1
                to: 0
                duration: ShinData.popupAnim(170)
                easing.type: Easing.InCubic
            }

            NumberAnimation {
                target: win
                property: "trailGlow"
                from: 0
                to: 1
                duration: ShinData.popupAnim(170)
                easing.type: Easing.OutCubic
            }
        }

        ScriptAction {
            script: {
                advanceWeatherMode()
                stageX = 95
                stageOpacity = 0
            }
        }

        PauseAnimation { duration: ShinData.popupAnim(40) }

        ParallelAnimation {
            NumberAnimation {
                target: win
                property: "stageX"
                from: 95
                to: 0
                duration: ShinData.popupAnim(340)
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: win
                property: "stageOpacity"
                from: 0
                to: 1
                duration: ShinData.popupAnim(340)
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: win
                property: "trailGlow"
                from: 1
                to: 0
                duration: ShinData.popupAnim(420)
                easing.type: Easing.OutCubic
            }
        }
    }

    Item {
        id: rootLayer

        anchors {
            fill: parent
            topMargin: ShinConfig.barH + ShinConfig.barMarginT + 10
        }

        Repeater {
            model: [0.10, 0.18, 0.27]

            Rectangle {
                property real t: win.trailT(modelData)

                z: 0
                anchors.horizontalCenter: parent.horizontalCenter
                y: win.cardY(t)

                width: win.cardW(t)
                height: win.cardH(t)
                radius: Math.min(34, height / 2)
                antialiasing: true
                clip: true

                visible: ShinConfig.trailEnabled && win.visible && (openAnim.running || closeAnim.running)
                opacity: (0.20 - index * 0.045) * (ShinPopup.expandedOpen ? win.motion : Math.max(win.motion, 0.25))

                color: Qt.rgba(
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                    0.16
                )

                border.width: 1
                border.color: Qt.rgba(
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                    0.26
                )
            }
        }

        Rectangle {
            id: card

            z: 1
            width: win.cardW(win.motion)
            height: win.cardH(win.motion)
            anchors.horizontalCenter: parent.horizontalCenter
            y: win.cardY(win.motion)

            radius: 32
            antialiasing: true
            clip: true
            opacity: win.clamp01(win.motion * 1.25)
            scale: 0.965 + win.easeOut(win.motion) * 0.035

            color: Qt.rgba((ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").r, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").g, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").b, ShinConfig.popupOpacity)
            border.color: Qt.rgba(
                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                0.18 + 0.12 * win.motion
            )
            border.width: 1

            Behavior on width {
                NumberAnimation { duration: ShinData.popupAnim(420); easing.type: Easing.OutCubic }
            }

            Behavior on height {
                NumberAnimation { duration: ShinData.popupAnim(420); easing.type: Easing.OutCubic }
            }

            Rectangle {
                anchors.fill: parent
                opacity: 0.30 + win.trailGlow * 0.18
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: win.page === "weather" && win.fxSun()
                            ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.32)
                            : win.page === "weather" && win.fxRain()
                                ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.20)
                                : Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.16)
                    }

                    GradientStop {
                        position: 0.55
                        color: Qt.rgba((ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").r, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").g, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").b, 0.03)
                    }

                    GradientStop {
                        position: 1.0
                        color: Qt.rgba((ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").r, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").g, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").b, 0.07)
                    }
                }
            }

            Item {
                id: fxLayer
                z: 0
                anchors.fill: parent
                clip: true

                Text {
                    visible: win.page === "weather"
                    anchors.right: parent.right
                    anchors.rightMargin: 54
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.fxRain() ? "☔︎" : win.fxSun() ? "☀︎" : win.fxWind() ? "≋" : "☁︎"
                    color: Qt.rgba(
                        (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                        (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                        (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                        0.13 + win.trailGlow * 0.10
                    )
                    font.pixelSize: 280
                    font.family: ShinConfig.fontFamily
                }

                Rectangle {
                    visible: win.page === "weather" && win.fxSun()
                    width: 360
                    height: 360
                    radius: 180
                    x: card.width - 290
                    y: -110
                    color: Qt.rgba(
                        (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                        (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                        (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                        0.22 + win.trailGlow * 0.10
                    )

                    SequentialAnimation on opacity {
                        running: ShinPopup.expandedOpen && win.page === "weather" && win.fxSun()
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.12; to: 0.32; duration: 1800; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 0.32; to: 0.12; duration: 1800; easing.type: Easing.InOutSine }
                    }
                }

                Repeater {
                    model: 8

                    Text {
                        visible: win.page === "weather" && win.fxCloud()
                        text: "☁︎"
                        color: index % 2 === 0
                            ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.16)
                            : Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.10)
                        font.pixelSize: index < 2 ? 62 : index < 5 ? 46 : 32
                        x: index * 155 - 80
                        y: index === 0 ? 20 : index === 1 ? 82 : index === 2 ? 142 : index === 3 ? 210 : index === 4 ? 305 : index === 5 ? 390 : index === 6 ? 455 : 120

                        SequentialAnimation on x {
                            running: ShinPopup.expandedOpen && win.page === "weather" && win.fxCloud()
                            loops: Animation.Infinite
                            NumberAnimation { from: index * 155 - 80; to: index * 155 + 60; duration: 8800 + index * 650; easing.type: Easing.Linear }
                            NumberAnimation { from: index * 155 + 60; to: index * 155 - 80; duration: 8800 + index * 650; easing.type: Easing.Linear }
                        }
                    }
                }

                Repeater {
                    model: 70

                    Rectangle {
                        visible: win.page === "weather" && win.fxRain()
                        width: 3
                        height: 28 + (index % 4) * 4
                        radius: 2
                        rotation: -18
                        x: (index * 23) % 1320
                        y: -100
                        color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.22)

                        SequentialAnimation on y {
                            running: ShinPopup.expandedOpen && win.page === "weather" && win.fxRain()
                            loops: Animation.Infinite
                            PauseAnimation { duration: (index % 8) * 90 }
                            NumberAnimation { from: -100; to: card.height + 40; duration: 1150 + (index % 5) * 95; easing.type: Easing.InQuad }
                        }
                    }
                }

                Repeater {
                    model: 18

                    Rectangle {
                        visible: win.page === "weather" && win.fxWind()
                        width: 90 + (index % 4) * 24
                        height: 3
                        radius: 2
                        x: -180
                        y: 54 + index * 23
                        color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.25)

                        SequentialAnimation on x {
                            running: ShinPopup.expandedOpen && win.page === "weather" && win.fxWind()
                            loops: Animation.Infinite
                            PauseAnimation { duration: index * 80 }
                            NumberAnimation { from: -180; to: card.width + 40; duration: 1250 + index * 60; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }

            Rectangle {
                z: 12
                x: win.sweepX
                y: 22
                width: 210
                height: card.height - 44
                radius: 22
                opacity: win.trailGlow
                color: Qt.rgba(
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                    0.10
                )
                border.width: 1
                border.color: Qt.rgba(
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                    0.22
                )
            }

            Text {
                z: 13
                anchors.horizontalCenter: parent.horizontalCenter
                y: 28
                text: win.page === "weather" ? win.fxName(win.visualMode) : "Clock"
                color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                font.pixelSize: 18 + win.trailGlow * 7
                font.bold: true
                font.family: ShinConfig.fontFamily
                opacity: win.trailGlow
            }

            Item {
                id: stage
                z: 20
                anchors.fill: parent
                anchors.margins: 20
                opacity: card.opacity * win.stageOpacity
                x: win.stageX
                y: win.stageY
                scale: win.stageScale
                transformOrigin: Item.Center

                Item {
                    id: clockPage
                    anchors.fill: parent
                    visible: win.page === "clock"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 2
                        spacing: 14

                        Rectangle {
                            width: parent.width
                            height: 126
                            radius: 22
                            clip: true
                            color: Qt.rgba((ShinColors && ShinColors.surface ? ShinColors.surface : "#ffffff").r, (ShinColors && ShinColors.surface ? ShinColors.surface : "#ffffff").g, (ShinColors && ShinColors.surface ? ShinColors.surface : "#ffffff").b, 0.42)
                            border.width: 1
                            border.color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.08)

                            Image {
                                anchors.fill: parent
                                visible: ShinData.clockBg.length > 0
                                source: ShinData.clockBg.length > 0 ? "file://" + ShinData.clockBg : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                                opacity: ShinData.clockBgOpacity
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: Qt.rgba((ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").r, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").g, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").b, ShinData.clockBg.length > 0 ? 0.42 : 0.0)
                            }

                            Text {
                                id: bigClock
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: -8

                                text: Qt.formatDateTime(win.now, "hh:mm:ss AP")
                                color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                                font.pixelSize: 42
                                font.bold: true
                                font.family: ShinConfig.fontFamily
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: bigClock.bottom
                                anchors.topMargin: 5
                                text: Qt.formatDateTime(win.now, "dddd, dd 'de' MMMM 'de' yyyy")
                                color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                                font.pixelSize: 13
                                font.family: ShinConfig.fontFamily
                            }
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 10

                            Rectangle {
                                width: 112
                                height: 28
                                radius: 14
                                color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.15)

                                Text {
                                    anchors.centerIn: parent
                                    text: win.seasonName()
                                    color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.family: ShinConfig.fontFamily
                                }
                            }

                            Rectangle {
                                width: 142
                                height: 28
                                radius: 14
                                color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.07)

                                Text {
                                    anchors.centerIn: parent
                                    text: "Shared Host"
                                    color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                                    font.pixelSize: 11
                                    font.family: ShinConfig.fontFamily
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.17)
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(win.now, "MMMM yyyy")
                            color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                            font.pixelSize: 13
                            font.bold: true
                            font.family: ShinConfig.fontFamily
                        }

                        Column {
                            width: parent.width
                            spacing: 4

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 0

                                Repeater {
                                    model: ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sab"]

                                    Text {
                                        width: 68
                                        height: 19
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        text: modelData
                                        font.pixelSize: 10
                                        font.family: ShinConfig.fontFamily
                                        color: Qt.rgba((ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff").r, (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff").g, (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff").b, 0.80)
                                    }
                                }
                            }

                            Grid {
                                id: calGrid
                                anchors.horizontalCenter: parent.horizontalCenter
                                columns: 7
                                spacing: 0

                                property int year: win.now.getFullYear()
                                property int month: win.now.getMonth()
                                property int today: win.now.getDate()
                                property int firstDow: new Date(year, month, 1).getDay()
                                property int daysInMonth: new Date(year, month + 1, 0).getDate()
                                property int totalCells: firstDow + daysInMonth

                                Repeater {
                                    model: calGrid.totalCells

                                    Item {
                                        width: 68
                                        height: 26

                                        property int day: index - calGrid.firstDow + 1
                                        property bool valid: day >= 1 && day <= calGrid.daysInMonth
                                        property bool isToday: valid && day === calGrid.today

                                        Rectangle {
                                            visible: isToday
                                            anchors.centerIn: parent
                                            width: 34
                                            height: 23
                                            radius: 10
                                            color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.30)
                                        }

                                        Text {
                                            visible: valid
                                            anchors.centerIn: parent
                                            text: day.toString()
                                            color: isToday ? (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff") : (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                                            font.pixelSize: 11
                                            font.family: ShinConfig.fontFamily
                                            font.bold: isToday
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    id: weatherPage
                    anchors.fill: parent
                    visible: win.page === "weather"

                    Row {
                        id: mainRow
                        anchors.fill: parent
                        spacing: 16

                        Rectangle {
                            id: todayCard
                            width: win.leftW
                            height: parent.height
                            radius: 26
                            clip: true
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: todayCard.width
                                    height: todayCard.height
                                    radius: todayCard.radius
                                }
                            }
                            color: Qt.rgba(
                                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                                win.fxSun() ? 0.10 : 0.075
                            )
                            border.width: 1
                            border.color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.15)

                            Image {
                                anchors.fill: parent
                                visible: ShinData.weatherBg.length > 0
                                source: ShinData.weatherBg.length > 0 ? "file://" + ShinData.weatherBg : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                                sourceSize.width: Math.max(1, parent.width)
                                sourceSize.height: Math.max(1, parent.height)
                                opacity: ShinData.weatherBgOpacity
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: ShinData.weatherBg.length > 0
                                radius: parent.radius
                                color: Qt.rgba(
                                    (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").r,
                                    (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").g,
                                    (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").b,
                                    0.46
                                )
                            }

                            Behavior on width {
                                NumberAnimation { duration: 420; easing.type: Easing.OutCubic }
                            }

                            Rectangle {
                                width: 250
                                height: 150
                                radius: 90
                                x: -110
                                y: -44
                                color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, win.fxSun() ? 0.08 : 0.05)
                            }

                            Column {
                                anchors.fill: parent
                                anchors.margins: 24
                                spacing: 14

                                Row {
                                    spacing: 10

                                    Text {
                                        text: win.weatherIcon()
                                        color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                                        font.pixelSize: 62
                                        font.family: ShinConfig.fontFamily

                                        SequentialAnimation on y {
                                            running: ShinPopup.expandedOpen && win.page === "weather"
                                            loops: Animation.Infinite
                                            NumberAnimation { from: 0; to: -4; duration: 1500; easing.type: Easing.InOutSine }
                                            NumberAnimation { from: -4; to: 0; duration: 1500; easing.type: Easing.InOutSine }
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 3

                                        Text {
                                            text: win.fxName(win.visualMode)
                                            color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                                            font.pixelSize: 12
                                            font.family: ShinConfig.fontFamily
                                        }

                                        Text {
                                            text: win.desc
                                            color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                                            font.pixelSize: 18
                                            font.family: ShinConfig.fontFamily
                                        }
                                    }
                                }

                                Item { width: 1; height: 8 }

                                Text {
                                    text: win.temp + "°C"
                                    color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                                    font.pixelSize: 72
                                    font.bold: true
                                    font.family: ShinConfig.fontFamily
                                }

                                Text {
                                    text: "agora • sensação " + win.feels + "°C"
                                    color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                                    font.pixelSize: 14
                                    font.family: ShinConfig.fontFamily
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 76
                                    radius: 18
                                    color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.05)

                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 18

                                        Column {
                                            spacing: 4
                                            Text { text: "vento"; color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff"); font.pixelSize: 11; font.family: ShinConfig.fontFamily }
                                            Text { text: win.wind + " km/h"; color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff"); font.pixelSize: 14; font.bold: true; font.family: ShinConfig.fontFamily }
                                        }

                                        Column {
                                            spacing: 4
                                            Text { text: "umidade"; color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff"); font.pixelSize: 11; font.family: ShinConfig.fontFamily }
                                            Text { text: win.humidity + "%"; color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff"); font.pixelSize: 14; font.bold: true; font.family: ShinConfig.fontFamily }
                                        }
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 84
                                    radius: 18
                                    color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.045)

                                    Text {
                                        anchors.centerIn: parent
                                        width: parent.width - 24
                                        text: win.location
                                        color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                                        font.pixelSize: 13
                                        font.family: ShinConfig.fontFamily
                                        wrapMode: Text.WordWrap
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 92
                                    radius: 18
                                    color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.09)
                                    border.width: 1
                                    border.color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.10)

                                    Text {
                                        anchors.centerIn: parent
                                        width: parent.width - 24
                                        text: win.desc + " • precipitação " + win.precip + " mm • cobertura " + win.cloudcover + "%"
                                        color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                                        font.pixelSize: 13
                                        font.family: ShinConfig.fontFamily
                                        wrapMode: Text.WordWrap
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }
                        }

                        Column {
                            id: rightColumn
                            width: parent.width - todayCard.width - mainRow.spacing
                            height: parent.height
                            spacing: 14

                            Behavior on width {
                                NumberAnimation { duration: 420; easing.type: Easing.OutCubic }
                            }

                            Rectangle {
                                id: modeBar
                                width: parent.width
                                height: 38
                                radius: 19
                                color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.045)
                                border.width: 1
                                border.color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.07)

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 8

                                    Repeater {
                                        model: win.fxModes

                                        Rectangle {
                                            width: modelData === "auto" ? 54 : 68
                                            height: 22
                                            radius: 11
                                            color: win.fxMode === modelData
                                                ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.20)
                                                : "transparent"
                                            border.width: win.fxMode === modelData ? 1 : 0
                                            border.color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.30)

                                            Text {
                                                anchors.centerIn: parent
                                                text: win.fxName(modelData)
                                                color: win.fxMode === modelData ? (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff") : (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                                                font.pixelSize: 10
                                                font.bold: win.fxMode === modelData
                                                font.family: ShinConfig.fontFamily
                                            }
                                        }
                                    }
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "↓ troca modo"
                                    color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                                    font.pixelSize: 10
                                    font.family: ShinConfig.fontFamily
                                }
                            }

                            Rectangle {
                                id: topInfo
                                width: parent.width
                                height: win.topH
                                radius: 22
                                color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.045)
                                border.width: 1
                                border.color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.07)

                                Behavior on height {
                                    NumberAnimation { duration: 420; easing.type: Easing.OutCubic }
                                }

                                Grid {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    columns: 4
                                    rowSpacing: 10
                                    columnSpacing: 10

                                    Repeater {
                                        model: [
                                            { label: "Umidade", value: win.humidity + "%" },
                                            { label: "Vento", value: win.wind + " km/h " + win.windDir },
                                            { label: "Precipitação", value: win.precip + " mm" },
                                            { label: "Cobertura", value: win.cloudcover + "%" },
                                            { label: "Modo", value: win.fxName(win.visualMode) },
                                            { label: "Sensação", value: win.feels + "°C" },
                                            { label: "Agora", value: win.temp + "°C" },
                                            { label: "Cena", value: win.fxName(win.fxMode) }
                                        ]

                                        Rectangle {
                                            width: (topInfo.width - 28 - 30) / 4
                                            height: 42
                                            radius: 14
                                            color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.055)

                                            Column {
                                                anchors.fill: parent
                                                anchors.margins: 9
                                                spacing: 2

                                                Text {
                                                    text: modelData.label
                                                    color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                                                    font.pixelSize: 10
                                                    font.family: ShinConfig.fontFamily
                                                }

                                                Text {
                                                    text: modelData.value
                                                    color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    font.family: ShinConfig.fontFamily
                                                    elide: Text.ElideRight
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: forecastCard
                                width: parent.width
                                height: parent.height - modeBar.height - topInfo.height - rightColumn.spacing * 2
                                radius: 24
                                color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.06)
                                border.width: 1
                                border.color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.09)

                                Behavior on height {
                                    NumberAnimation { duration: 420; easing.type: Easing.OutCubic }
                                }

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 4

                                    Row {
                                        width: parent.width
                                        height: 24

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "Próximos 7 dias"
                                            color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                                            font.pixelSize: 15
                                            font.bold: true
                                            font.family: ShinConfig.fontFamily
                                        }

                                        Text {
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "agora: " + win.temp + "°C • " + win.desc
                                            color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                                            font.pixelSize: 9
                                            font.family: ShinConfig.fontFamily
                                        }
                                    }

                                    Repeater {
                                        model: win.days

                                        Rectangle {
                                            width: forecastCard.width - 24
                                            height: 22
                                            radius: 10
                                            color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.045)
                                            border.width: 1
                                            border.color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.05)

                                            Text {
                                                anchors.left: parent.left
                                                anchors.leftMargin: 12
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 42
                                                text: modelData.label
                                                color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                                                font.pixelSize: 9
                                                font.bold: true
                                                font.family: ShinConfig.fontFamily
                                            }

                                            Text {
                                                anchors.left: parent.left
                                                anchors.leftMargin: 58
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: win.dayIcon(modelData.desc, modelData.rain)
                                                color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                                                font.pixelSize: 12
                                                font.family: ShinConfig.fontFamily
                                            }

                                            Text {
                                                anchors.left: parent.left
                                                anchors.leftMargin: 84
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 64
                                                text: modelData.short
                                                color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                                                font.pixelSize: 9
                                                font.family: ShinConfig.fontFamily
                                            }

                                            Text {
                                                anchors.left: parent.left
                                                anchors.leftMargin: 152
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 76
                                                text: modelData.min + "° / " + modelData.max + "°"
                                                color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                                                font.pixelSize: 9
                                                font.family: ShinConfig.fontFamily
                                            }

                                            Rectangle {
                                                id: barTrack
                                                anchors.left: parent.left
                                                anchors.leftMargin: 250
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: parent.width - 370
                                                height: 6
                                                radius: 3
                                                color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.08)

                                                Rectangle {
                                                    height: parent.height
                                                    radius: parent.radius
                                                    width: win.percentWidth(modelData.rain, barTrack.width)
                                                    color: Qt.rgba(
                                                        (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                                                        (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                                                        (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                                                        0.82
                                                    )

                                                    SequentialAnimation on opacity {
                                                        running: ShinPopup.expandedOpen && win.page === "weather"
                                                        loops: Animation.Infinite
                                                        NumberAnimation { from: 0.66; to: 1.0; duration: 1400; easing.type: Easing.InOutSine }
                                                        NumberAnimation { from: 1.0; to: 0.66; duration: 1400; easing.type: Easing.InOutSine }
                                                    }
                                                }
                                            }

                                            Text {
                                                anchors.right: parent.right
                                                anchors.rightMargin: 14
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: win.rainLabel(modelData.rain)
                                                color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                                                font.pixelSize: 9
                                                font.bold: true
                                                font.family: ShinConfig.fontFamily
                                            }
                                        }
                                    }

                                    Rectangle {
                                        visible: win.days.length === 0
                                        width: parent.width
                                        height: 60
                                        radius: 16
                                        color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.04)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Sem previsão disponível."
                                            color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                                            font.pixelSize: 12
                                            font.family: ShinConfig.fontFamily
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
