import Quickshell
import QtQuick
import Quickshell.Io
import "."

Item {
    id: root

    implicitWidth: tempTxt.implicitWidth + ShinConfig.pillPadH * 2
    implicitHeight: ShinConfig.barH

    property bool opened: ShinPopup.active === "weather"
    property bool popupVisible: false
    property bool hoverRoot: false
    property bool hoverPopup: false

    property string location: "..."
    property string temp: "--"
    property string feels: "--"
    property string desc: "Carregando"
    property string humidity: "--"
    property string wind: "--"
    property string windDir: ""
    property string precip: "0"
    property string uv: "--"
    property string pressure: "--"
    property string visibility: "--"
    property string cloudcover: "--"
    property var days: []

    property string fxMode: "auto"
    readonly property var fxModes: ["auto", "rain", "sun", "cloud", "wind"]

    property string visualMode: fxMode === "auto"
        ? (isRainy() ? "rain" : isSunny() ? "sun" : isWindy() ? "wind" : "cloud")
        : fxMode

    // Entrada/saída do popup.
    property real motion: 0.0
    property int motionDir: 1

    // Troca de modo interna.
    property real sceneX: 0.0
    property real sceneOpacity: 1.0
    property real sceneScale: 1.0
    property real sceneGlow: 0.0

    // Entrada interna dos elementos, para ficar mais parecido com o Clock.
    property real introHero: 1.0
    property real introMetrics: 1.0
    property real introDays: 1.0
    property real introDetails: 1.0
    property real sweepX: -220

    // Tamanho reduzido e mais equilibrado.
    readonly property int popupW: 980
    readonly property int popupH: 590
    readonly property int cardOpenW: 940
    readonly property int cardOpenH: 550
    readonly property int cardClosedW: 190
    readonly property int cardClosedH: 46

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
        return clamp01((motion - 0.28) / 0.72)
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

    function trailT(offset) {
        if (motionDir >= 0)
            return clamp01(motion - offset)

        return clamp01(motion + offset)
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

    function dayIcon(dayDesc, rainChance) {
        var d = (dayDesc || "").toLowerCase()
        if (parseInt(rainChance) >= 60) return "☔︎"
        if (d.indexOf("storm") >= 0 || d.indexOf("thunder") >= 0) return "⚡︎"
        if (d.indexOf("rain") >= 0 || d.indexOf("chuva") >= 0 || d.indexOf("garoa") >= 0) return "☔︎"
        if (d.indexOf("cloud") >= 0 || d.indexOf("nublado") >= 0 || d.indexOf("overcast") >= 0) return "☁︎"
        if (d.indexOf("clear") >= 0 || d.indexOf("sun") >= 0 || d.indexOf("sol") >= 0) return "☀︎"
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

    function advanceMode() {
        var idx = fxModes.indexOf(fxMode)
        if (idx < 0)
            idx = 0
        fxMode = fxModes[(idx + 1) % fxModes.length]
    }

    function nextFxMode() {
        if (modeSwitchAnim.running)
            return
        modeSwitchAnim.restart()
    }

    function refreshWeather() {
        if (!weatherProc.running)
            weatherProc.running = true
    }

    function openPopup() {
        closeTimer.stop()
        hideTimer.stop()
        popupVisible = true
        refreshWeather()
        ShinPopup.open("weather")
    }

    function replayTemperatureEntrance() {
        introHeroAnim.restart()
        introMetricsAnim.restart()
        introDaysAnim.restart()
        introDetailsAnim.restart()
    }

    function scheduleClose() {
        closeTimer.restart()
    }

    onOpenedChanged: {
        if (opened) {
            hideTimer.stop()
            popupVisible = true
            motionDir = 1
            closeAnim.stop()
            openAnim.from = motion
            openAnim.restart()
            refreshWeather()
            replayTemperatureEntrance()
        } else {
            motionDir = -1
            openAnim.stop()
            closeAnim.from = motion
            closeAnim.restart()
            hideTimer.restart()
        }
    }

    Connections {
        target: ShinPopup

        function onWeatherFxCycleNonceChanged() {
            if (root.opened)
                root.nextFxMode()
        }
    }

    SequentialAnimation {
        id: introHeroAnim
        ScriptAction { script: root.introHero = 0.0 }
        PauseAnimation { duration: 80 }
        NumberAnimation {
            target: root
            property: "introHero"
            from: 0.0
            to: 1.0
            duration: 430
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: introMetricsAnim
        ScriptAction { script: root.introMetrics = 0.0 }
        PauseAnimation { duration: 160 }
        NumberAnimation {
            target: root
            property: "introMetrics"
            from: 0.0
            to: 1.0
            duration: 430
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: introDaysAnim
        ScriptAction { script: root.introDays = 0.0 }
        PauseAnimation { duration: 230 }
        NumberAnimation {
            target: root
            property: "introDays"
            from: 0.0
            to: 1.0
            duration: 560
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: introDetailsAnim
        ScriptAction { script: root.introDetails = 0.0 }
        PauseAnimation { duration: 310 }
        NumberAnimation {
            target: root
            property: "introDetails"
            from: 0.0
            to: 1.0
            duration: 480
            easing.type: Easing.OutCubic
        }
    }

    NumberAnimation {
        id: openAnim
        target: root
        property: "motion"
        from: 0
        to: 1
        duration: 480
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: closeAnim
        target: root
        property: "motion"
        from: 1
        to: 0
        duration: 360
        easing.type: Easing.InCubic
    }

    SequentialAnimation {
        id: modeSwitchAnim

        ScriptAction {
            script: {
                root.sceneGlow = 0
                root.sweepX = -220
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "sceneX"
                from: 0
                to: -58
                duration: 230
                easing.type: Easing.InCubic
            }

            NumberAnimation {
                target: root
                property: "sceneOpacity"
                from: 1
                to: 0
                duration: 230
                easing.type: Easing.InCubic
            }

            NumberAnimation {
                target: root
                property: "sceneScale"
                from: 1
                to: 0.975
                duration: 230
                easing.type: Easing.InCubic
            }

            NumberAnimation {
                target: root
                property: "sceneGlow"
                from: 0
                to: 1
                duration: 230
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: root
                property: "sweepX"
                from: -220
                to: 280
                duration: 260
                easing.type: Easing.OutCubic
            }
        }

        ScriptAction {
            script: {
                root.advanceMode()
                root.replayTemperatureEntrance()
                root.sceneX = 72
                root.sceneOpacity = 0
                root.sceneScale = 0.975
                root.sweepX = -160
            }
        }

        PauseAnimation { duration: 70 }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "sceneX"
                from: 72
                to: 0
                duration: 460
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: root
                property: "sceneOpacity"
                from: 0
                to: 1
                duration: 460
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: root
                property: "sceneScale"
                from: 0.975
                to: 1
                duration: 460
                easing.type: Easing.OutBack
            }

            NumberAnimation {
                target: root
                property: "sceneGlow"
                from: 1
                to: 0
                duration: 540
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: root
                property: "sweepX"
                from: -160
                to: root.cardOpenW + 160
                duration: 560
                easing.type: Easing.OutCubic
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 260
        repeat: false
        onTriggered: {
            if (!root.hoverRoot && !root.hoverPopup)
                ShinPopup.close("weather")
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
        interval: 600000
        running: true
        repeat: true
        onTriggered: root.refreshWeather()
    }

    Component.onCompleted: root.refreshWeather()

    Process {
        id: weatherProc
        running: false
        command: ["bash", "-lc", "~/.config/quickshell/shinbar/scripts/shinbar-temperature"]

        stdout: SplitParser {
            onRead: function(lineRaw) {
                var line = lineRaw.trim()
                if (!line) return

                if (line.startsWith("LOCATION="))
                    root.location = line.substring(9)
                else if (line.startsWith("TEMP="))
                    root.temp = line.substring(5)
                else if (line.startsWith("FEELS="))
                    root.feels = line.substring(6)
                else if (line.startsWith("DESC="))
                    root.desc = line.substring(5)
                else if (line.startsWith("HUMIDITY="))
                    root.humidity = line.substring(9)
                else if (line.startsWith("WIND="))
                    root.wind = line.substring(5)
                else if (line.startsWith("WIND_DIR="))
                    root.windDir = line.substring(9)
                else if (line.startsWith("PRECIP="))
                    root.precip = line.substring(7)
                else if (line.startsWith("UV="))
                    root.uv = line.substring(3)
                else if (line.startsWith("PRESSURE="))
                    root.pressure = line.substring(9)
                else if (line.startsWith("VISIBILITY="))
                    root.visibility = line.substring(11)
                else if (line.startsWith("CLOUDCOVER="))
                    root.cloudcover = line.substring(11)
                else if (line.startsWith("DAYS=")) {
                    try {
                        root.days = JSON.parse(line.substring(5))
                    } catch(e) {
                        root.days = []
                    }
                }
            }
        }

        onExited: running = false
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
        acceptedButtons: Qt.NoButton

        onEntered: {
            root.hoverRoot = true
            root.openPopup()
        }

        onExited: {
            root.hoverRoot = false
            root.scheduleClose()
        }
    }

    Text {
        id: tempTxt
        anchors.centerIn: parent
        text: root.temp + "°C"
        color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
        font.pixelSize: ShinConfig.fontSize
        font.family: ShinConfig.fontFamily
        verticalAlignment: Text.AlignVCenter
    }

    PopupWindow {
        id: weatherPopup
        visible: root.popupVisible
        color: "transparent"

        implicitWidth: root.popupW
        implicitHeight: root.popupH

        anchor.item: root
        anchor.rect.x: Math.round(root.implicitWidth / 2 - root.popupW / 2)
        anchor.rect.y: root.implicitHeight + 10
        anchor.rect.width: 1
        anchor.rect.height: 1

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            z: 99

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
            model: [0.10, 0.18, 0.27]

            Rectangle {
                property real t: root.trailT(modelData)

                z: -3
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.cardY(t)

                width: root.cardW(t)
                height: root.cardH(t)
                radius: Math.min(34, height / 2)
                antialiasing: true
                clip: true

                visible: root.popupVisible && (openAnim.running || closeAnim.running)
                opacity: (0.24 - index * 0.055) * (root.opened ? root.motion : Math.max(root.motion, 0.25))

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

            property real ct: root.contentT()

            width: root.cardW(root.motion)
            height: root.cardH(root.motion)
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.cardY(root.motion)

            radius: 32
            antialiasing: true
            clip: true
            opacity: root.clamp01(root.motion * 1.25)
            scale: 0.965 + root.emphasizedDecel(root.motion) * 0.035

            color: Qt.rgba((ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").r, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").g, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").b, ShinConfig.popupOpacity)
            border.color: Qt.rgba(
                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                0.18 + 0.12 * root.motion
            )
            border.width: 1

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
                color: Qt.rgba(
                    (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").r,
                    (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").g,
                    (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").b,
                    ShinData.clockBg.length > 0 ? 0.38 : 0.0
                )
            }

            Rectangle {
                anchors.fill: parent
                opacity: 0.26 + root.sceneGlow * 0.12
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: root.fxSun()
                            ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.28)
                            : root.fxRain()
                                ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.18)
                                : Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.15)
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
                    anchors.right: parent.right
                    anchors.rightMargin: 38
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.fxRain() ? "☔︎" : root.fxSun() ? "☀︎" : root.fxWind() ? "≋" : "☁︎"
                    color: Qt.rgba(
                        (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                        (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                        (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                        0.10 + root.sceneGlow * 0.08
                    )
                    font.pixelSize: 220
                    font.family: ShinConfig.fontFamily
                }

                Repeater {
                    model: 6

                    Text {
                        visible: root.fxCloud()
                        text: "☁︎"
                        color: index % 2 === 0
                            ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.13)
                            : Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.08)
                        font.pixelSize: index < 2 ? 48 : 34
                        x: index * 145 - 80
                        y: index === 0 ? 24 : index === 1 ? 95 : index === 2 ? 180 : index === 3 ? 300 : index === 4 ? 405 : 140

                        SequentialAnimation on x {
                            running: root.opened && root.fxCloud()
                            loops: Animation.Infinite
                            NumberAnimation { from: index * 145 - 80; to: index * 145 + 60; duration: 9200 + index * 700; easing.type: Easing.Linear }
                            NumberAnimation { from: index * 145 + 60; to: index * 145 - 80; duration: 9200 + index * 700; easing.type: Easing.Linear }
                        }
                    }
                }

                Repeater {
                    model: 45

                    Rectangle {
                        visible: root.fxRain()
                        width: 2
                        height: 24 + (index % 4) * 4
                        radius: 2
                        rotation: -18
                        x: (index * 23) % root.cardOpenW
                        y: -80
                        color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.18)

                        SequentialAnimation on y {
                            running: root.opened && root.fxRain()
                            loops: Animation.Infinite
                            PauseAnimation { duration: (index % 8) * 90 }
                            NumberAnimation { from: -80; to: card.height + 40; duration: 1300 + (index % 5) * 95; easing.type: Easing.InQuad }
                        }
                    }
                }

                Repeater {
                    model: 12

                    Rectangle {
                        visible: root.fxWind()
                        width: 75 + (index % 4) * 22
                        height: 2
                        radius: 2
                        x: -160
                        y: 56 + index * 26
                        color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.20)

                        SequentialAnimation on x {
                            running: root.opened && root.fxWind()
                            loops: Animation.Infinite
                            PauseAnimation { duration: index * 90 }
                            NumberAnimation { from: -160; to: card.width + 40; duration: 1450 + index * 65; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }

            Rectangle {
                z: 12
                x: root.sweepX
                y: 20
                width: 170
                height: card.height - 40
                radius: 22
                opacity: root.sceneGlow
                color: Qt.rgba(
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                    0.08
                )
                border.width: 1
                border.color: Qt.rgba(
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                    0.18
                )
            }

            Text {
                z: 13
                anchors.horizontalCenter: parent.horizontalCenter
                y: 26
                text: root.fxName(root.visualMode)
                color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                font.pixelSize: 16 + root.sceneGlow * 6
                font.bold: true
                font.family: ShinConfig.fontFamily
                opacity: root.sceneGlow
            }

            Item {
                id: contentLayer
                z: 20
                anchors.fill: parent
                anchors.margins: 22
                opacity: card.ct * root.sceneOpacity

                Item {
                    id: stage
                    width: parent.width
                    height: parent.height
                    x: root.sceneX
                    scale: root.sceneScale
                    transformOrigin: Item.Center

                    Column {
                        anchors.fill: parent
                        spacing: 14

                        Row {
                            width: parent.width
                            height: 158
                            spacing: 16

                            Rectangle {
                                id: hero
                                opacity: root.introHero
                                scale: 0.94 + root.introHero * 0.06
                                transformOrigin: Item.Center
                                transform: Translate {
                                    x: -26 * (1.0 - root.introHero)
                                    y: 22 * (1.0 - root.introHero)
                                }

                                width: 330
                                height: parent.height
                                radius: 24
                                color: Qt.rgba(
                                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                                    root.fxSun() ? 0.10 : 0.075
                                )
                                border.width: 1
                                border.color: Qt.rgba(
                                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                                    0.15
                                )
                                clip: true

                                Rectangle {
                                    width: 210
                                    height: 126
                                    radius: 70
                                    x: -92
                                    y: -38
                                    color: Qt.rgba(
                                        (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r,
                                        (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g,
                                        (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b,
                                        0.055
                                    )
                                }

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 18
                                    anchors.top: parent.top
                                    anchors.topMargin: 18
                                    spacing: 10

                                    Text {
                                        text: root.weatherIcon()
                                        color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                                        font.pixelSize: 52
                                        font.family: ShinConfig.fontFamily

                                        SequentialAnimation on y {
                                            running: root.opened
                                            loops: Animation.Infinite
                                            NumberAnimation { from: 0; to: -3; duration: 1700; easing.type: Easing.InOutSine }
                                            NumberAnimation { from: -3; to: 0; duration: 1700; easing.type: Easing.InOutSine }
                                        }
                                    }

                                    Column {
                                        spacing: 2
                                        anchors.verticalCenter: parent.verticalCenter

                                        Text {
                                            text: root.temp + "°C"
                                            color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                                            font.pixelSize: 48
                                            font.bold: true
                                            font.family: ShinConfig.fontFamily
                                        }

                                        Text {
                                            text: "sensação "
                                            color: (ShinColors && ShinColors.text ? ShinColors.text : "#ffffff")
                                            font.pixelSize: 11
                                            font.family: ShinConfig.fontFamily
                                        }
                                    }
                                }

                                Column {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 20
                                    anchors.right: parent.right
                                    anchors.rightMargin: 18
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 16
                                    spacing: 5

                                    Text {
                                        width: parent.width
                                        text: root.desc
                                        color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                                        font.pixelSize: 14
                                        font.family: ShinConfig.fontFamily
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: root.location
                                        color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                                        font.pixelSize: 10
                                        font.family: ShinConfig.fontFamily
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Grid {
                                id: metrics
                                opacity: root.introMetrics
                                scale: 0.96 + root.introMetrics * 0.04
                                transformOrigin: Item.Center
                                transform: Translate {
                                    x: 32 * (1.0 - root.introMetrics)
                                    y: 12 * (1.0 - root.introMetrics)
                                }

                                width: parent.width - hero.width - 16
                                height: parent.height
                                columns: 2
                                rowSpacing: 10
                                columnSpacing: 10

                                Repeater {
                                    model: [
                                        { label: "Umidade", value: root.humidity + "%" },
                                        { label: "Vento", value: root.wind + " km/h " + root.windDir },
                                        { label: "Precipitação", value: root.precip + " mm" },
                                        { label: "Cobertura", value: root.cloudcover + "%" },
                                        { label: "Modo", value: root.fxName(root.visualMode) },
                                        { label: "Cena", value: root.fxName(root.fxMode) }
                                    ]

                                    Rectangle {
                                        property real metricIntro: root.clamp01((root.introMetrics - index * 0.055) / 0.65)

                                        opacity: metricIntro
                                        scale: 0.955 + metricIntro * 0.045
                                        transformOrigin: Item.Center
                                        transform: Translate {
                                            x: 18 * (1.0 - metricIntro)
                                            y: 10 * (1.0 - metricIntro)
                                        }

                                        width: (metrics.width - metrics.columnSpacing) / 2
                                        height: 46
                                        radius: 16
                                        color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.055)
                                        border.width: 1
                                        border.color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.07)

                                        Column {
                                            anchors.fill: parent
                                            anchors.margins: 10
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
                            width: parent.width
                            height: 1
                            color: Qt.rgba(
                                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                                0.15
                            )
                        }

                        Row {
                            width: parent.width
                            height: parent.height - 158 - 1 - 28
                            spacing: 16

                            Column {
                                id: daysColumn
                                opacity: root.introDays
                                scale: 0.965 + root.introDays * 0.035
                                transformOrigin: Item.Center
                                transform: Translate {
                                    x: -18 * (1.0 - root.introDays)
                                    y: 28 * (1.0 - root.introDays)
                                }

                                width: 560
                                height: parent.height
                                spacing: 8

                                Text {
                                    text: "☔︎ Próximos 7 dias"
                                    color: (ShinColors && ShinColors.text ? ShinColors.text : "#ffffff")
                                    font.pixelSize: 15
                                    font.bold: true
                                    font.family: ShinConfig.fontFamily
                                }

                                Repeater {
                                    model: root.days

                                    Rectangle {
                                        property real rowIntro: root.clamp01((root.introDays - index * 0.055) / 0.62)

                                        opacity: rowIntro
                                        scale: 0.965 + rowIntro * 0.035
                                        transformOrigin: Item.Center
                                        transform: Translate {
                                            x: 24 * (1.0 - rowIntro)
                                            y: 10 * (1.0 - rowIntro)
                                        }

                                        width: daysColumn.width
                                        height: 31
                                        radius: 12
                                        color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.045)
                                        border.width: 1
                                        border.color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.05)

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 38
                                            text: modelData.label
                                            color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                                            font.pixelSize: 10
                                            font.bold: true
                                            font.family: ShinConfig.fontFamily
                                        }

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 50
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: root.dayIcon(modelData.desc, modelData.rain)
                                            color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                                            font.pixelSize: 13
                                            font.family: ShinConfig.fontFamily
                                        }

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 76
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 56
                                            text: modelData.short
                                            color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                                            font.pixelSize: 9
                                            font.family: ShinConfig.fontFamily
                                        }

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 136
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 70
                                            text: modelData.min + "° / " + modelData.max + "°"
                                            color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                                            font.pixelSize: 10
                                            font.family: ShinConfig.fontFamily
                                        }

                                        Rectangle {
                                            id: rainTrack
                                            anchors.left: parent.left
                                            anchors.leftMargin: 220
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 235
                                            height: 7
                                            radius: 4
                                            color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.08)

                                            Rectangle {
                                                height: parent.height
                                                radius: parent.radius
                                                width: root.percentWidth(modelData.rain, rainTrack.width)
                                                color: Qt.rgba(
                                                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                                                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                                                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                                                    0.78
                                                )

                                                SequentialAnimation on opacity {
                                                    running: root.opened
                                                    loops: Animation.Infinite
                                                    NumberAnimation { from: 0.68; to: 1.0; duration: 1600; easing.type: Easing.InOutSine }
                                                    NumberAnimation { from: 1.0; to: 0.68; duration: 1600; easing.type: Easing.InOutSine }
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.right: parent.right
                                            anchors.rightMargin: 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: root.rainLabel(modelData.rain)
                                            color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                                            font.pixelSize: 10
                                            font.bold: true
                                            font.family: ShinConfig.fontFamily
                                        }
                                    }
                                }

                                Text {
                                    visible: root.days.length === 0
                                    text: "Sem previsão disponível."
                                    color: (ShinColors && ShinColors.text ? ShinColors.text : "#ffffff")
                                    font.pixelSize: 11
                                    font.family: ShinConfig.fontFamily
                                }
                            }

                            Column {
                                id: details
                                opacity: root.introDetails
                                scale: 0.965 + root.introDetails * 0.035
                                transformOrigin: Item.Center
                                transform: Translate {
                                    x: 28 * (1.0 - root.introDetails)
                                    y: 24 * (1.0 - root.introDetails)
                                }

                                width: parent.width - daysColumn.width - 16
                                height: parent.height
                                spacing: 10

                                Text {
                                    text: "☀︎ Detalhes"
                                    color: (ShinColors && ShinColors.text ? ShinColors.text : "#ffffff")
                                    font.pixelSize: 15
                                    font.bold: true
                                    font.family: ShinConfig.fontFamily
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 76
                                    radius: 18
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
                                        0.12
                                    )

                                    Text {
                                        anchors.centerIn: parent
                                        width: parent.width - 24
                                        text: root.desc + "\nAgora: " + root.temp + "°C • sensação " + root.feels + "°C"
                                        color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                                        font.pixelSize: 11
                                        font.family: ShinConfig.fontFamily
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 68
                                    radius: 18
                                    color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.045)

                                    Text {
                                        anchors.centerIn: parent
                                        width: parent.width - 24
                                        text: "Vento "
                                        color: (ShinColors && ShinColors.text ? ShinColors.text : "#ffffff")
                                        font.pixelSize: 11
                                        font.family: ShinConfig.fontFamily
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 68
                                    radius: 18
                                    color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.045)

                                    Text {
                                        anchors.centerIn: parent
                                        width: parent.width - 24
                                        text: "Umidade "
                                        color: (ShinColors && ShinColors.text ? ShinColors.text : "#ffffff")
                                        font.pixelSize: 11
                                        font.family: ShinConfig.fontFamily
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 68
                                    radius: 18
                                    color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.045)

                                    Text {
                                        anchors.centerIn: parent
                                        width: parent.width - 24
                                        text: "Cobertura de nuvens "
                                        color: (ShinColors && ShinColors.text ? ShinColors.text : "#ffffff")
                                        font.pixelSize: 11
                                        font.family: ShinConfig.fontFamily
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.WordWrap
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
