import Quickshell
import Quickshell.Wayland
import QtQuick
import Quickshell.Io
import "."

Item {
    id: root

    property bool showLauncher: true
    implicitWidth: showLauncher ? gearTxt.implicitWidth + ShinConfig.pillPadH * 2 : 0
    implicitHeight: showLauncher ? ShinConfig.barH : 0
    property bool opened: ShinPopup.active === "settings"
    property var wallpapers: []
    property var fonts: []

    function shellQuote(s) {
        return "'" + ("" + s).replace(/'/g, "'\\''") + "'"
    }

    function setCat(c) {
        ShinData.save("settingsCategory", c)
    }

    function clamp(v, mn, mx) {
        return Math.max(mn, Math.min(mx, v))
    }

    function setInt(key, val) {
        ShinData.save(key, clamp(val, 20, 90))
    }

    function setReal(key, val) {
        ShinData.save(key, Math.max(0.05, Math.min(1, val)).toFixed(2))
    }

    function basename(path) {
        var p = ("" + path).split("/")
        return p[p.length - 1]
    }

    Component.onCompleted: {
        wallProc.running = true
        fontProc.running = true
        applyTimer.restart()
    }

    Timer {
        id: applyTimer
        interval: 250
        repeat: false
        onTriggered: ShinData.applyConfig()
    }

    Process {
        id: wallProc
        running: false
        property var tmp: []
        command: ["bash", "-lc", "~/.config/quickshell/shinbar/scripts/shinbar-list-wallpapers"]

        onStarted: tmp = []

        stdout: SplitParser {
            onRead: function(data) {
                var s = data.trim()
                if (!s) return
                var a = wallProc.tmp.slice()
                a.push(s)
                wallProc.tmp = a
            }
        }

        onExited: {
            root.wallpapers = tmp
            running = false
        }
    }

    Process {
        id: fontProc
        running: false
        property var tmp: []
        command: ["bash", "-lc", "~/.config/quickshell/shinbar/scripts/shinbar-fonts"]

        onStarted: tmp = []

        stdout: SplitParser {
            onRead: function(data) {
                var s = data.trim()
                if (!s) return
                var a = fontProc.tmp.slice()
                a.push(s)
                fontProc.tmp = a
            }
        }

        onExited: {
            root.fonts = tmp
            running = false
        }
    }

    ShinPill {
        visible: root.showLauncher
        anchors.fill: parent
        anchors.topMargin: (parent.height - ShinConfig.pillH) / 2
        anchors.bottomMargin: (parent.height - ShinConfig.pillH) / 2
        clickable: true
        active: root.opened
        onClicked: ShinPopup.toggle("settings")
    }

    Text {
        id: gearTxt
        visible: root.showLauncher
        anchors.centerIn: parent
        text: "S"
        color: root.opened ? (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff") : (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
        font.pixelSize: 13
        font.family: ShinConfig.fontFamily
        font.bold: true

        Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    PanelWindow {
        id: overlay
        visible: root.opened
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "shinbar-settings"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.25)
            MouseArea {
                anchors.fill: parent
                onClicked: ShinPopup.close("settings")
            }
        }

        Rectangle {
            id: card
            width: 720
            height: 500
            anchors.centerIn: parent
            radius: 22
            antialiasing: true
            color: Qt.rgba((ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").r, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").g, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").b, Math.max(0.64, ShinConfig.popupOpacity))
            border.color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.30)
            border.width: 1

            opacity: root.opened ? 1 : 0
            scale: root.opened ? 1 : 0.92
            y: root.opened ? 0 : 24

            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

            MouseArea { anchors.fill: parent; onClicked: {} }

            Row {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 16

                Column {
                    width: 150
                    height: parent.height
                    spacing: 8

                    Text {
                        text: "Shinbar"
                        color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                        font.pixelSize: 18
                        font.bold: true
                        font.family: ShinConfig.fontFamily
                    }

                    Text {
                        text: "savedata ativo"
                        color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                        font.pixelSize: 10
                        font.family: ShinConfig.fontFamily
                    }

                    Item { height: 8 }

                    CatButton { label: "Barra"; cat: "bar" }
                    CatButton { label: "Clock"; cat: "clock" }
                    CatButton { label: "Mídia"; cat: "media" }
                    CatButton { label: "Fontes"; cat: "fonts" }
                    CatButton { label: "Efeitos"; cat: "effects" }

                    Item { height: 1; width: 1 }

                    Rectangle {
                        width: parent.width
                        height: 34
                        radius: 10
                        color: closeArea.containsMouse
                            ? Qt.rgba((ShinColors && ShinColors.warn ? ShinColors.warn : "#ffffff").r, (ShinColors && ShinColors.warn ? ShinColors.warn : "#ffffff").g, (ShinColors && ShinColors.warn ? ShinColors.warn : "#ffffff").b, 0.18)
                            : Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.07)

                        Text {
                            anchors.centerIn: parent
                            text: "Fechar"
                            color: closeArea.containsMouse ? (ShinColors && ShinColors.warn ? ShinColors.warn : "#ffffff") : (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                            font.pixelSize: 10
                            font.family: ShinConfig.fontFamily
                        }

                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: ShinPopup.close("settings")
                        }
                    }
                }

                Rectangle {
                    width: 1
                    height: parent.height
                    color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.16)
                }

                Item {
                    width: parent.width - 167
                    height: parent.height

                    Column {
                        anchors.fill: parent
                        spacing: 12
                        visible: ShinData.settingsCategory === "bar"

                        Text {
                            text: "Barra"
                            color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                            font.pixelSize: 16
                            font.bold: true
                            font.family: ShinConfig.fontFamily
                        }

                        SettingRow { title: "Altura total"; valueText: ShinConfig.barH + "px"; onMinus: root.setInt("barH", ShinConfig.barH - 2); onPlus: root.setInt("barH", ShinConfig.barH + 2) }
                        SettingRow { title: "Altura dos pills"; valueText: ShinConfig.pillH + "px"; onMinus: root.setInt("pillH", ShinConfig.pillH - 2); onPlus: root.setInt("pillH", ShinConfig.pillH + 2) }
                        SettingRow { title: "Opacidade dos pills"; valueText: Math.round(ShinConfig.pillOpacity * 100) + "%"; onMinus: root.setReal("pillOpacity", ShinConfig.pillOpacity - 0.05); onPlus: root.setReal("pillOpacity", ShinConfig.pillOpacity + 0.05) }
                        SettingRow { title: "Opacidade dos popups"; valueText: Math.round(ShinConfig.popupOpacity * 100) + "%"; onMinus: root.setReal("popupOpacity", ShinConfig.popupOpacity - 0.05); onPlus: root.setReal("popupOpacity", ShinConfig.popupOpacity + 0.05) }

                        Text {
                            width: parent.width
                            text: "Os valores são salvos em ~/.config/quickshell/shinbar/savedata.json sem reescrever QML."
                            color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                            font.pixelSize: 10
                            font.family: ShinConfig.fontFamily
                            wrapMode: Text.WordWrap
                        }
                    }

                    Column {
                        anchors.fill: parent
                        spacing: 12
                        visible: ShinData.settingsCategory === "clock"

                        Text {
                            text: "Clock"
                            color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                            font.pixelSize: 16
                            font.bold: true
                            font.family: ShinConfig.fontFamily
                        }

                        SettingRow { title: "Opacidade do fundo personalizado"; valueText: Math.round(ShinData.clockBgOpacity * 100) + "%"; onMinus: root.setReal("clockBgOpacity", ShinData.clockBgOpacity - 0.05); onPlus: root.setReal("clockBgOpacity", ShinData.clockBgOpacity + 0.05) }
                        SettingRow { title: "Força do accent"; valueText: Math.round(ShinData.clockAccentBoost * 100) + "%"; onMinus: root.setReal("clockAccentBoost", ShinData.clockAccentBoost - 0.05); onPlus: root.setReal("clockAccentBoost", ShinData.clockAccentBoost + 0.05) }

                        WallpaperPicker {
                            title: "Fundo do popup/calendário"
                            targetKey: "clockBg"
                            currentPath: ShinData.clockBg
                            wallpapers: root.wallpapers
                        }
                    }

                    Column {
                        anchors.fill: parent
                        spacing: 12
                        visible: ShinData.settingsCategory === "media"

                        Text {
                            text: "Mídia"
                            color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                            font.pixelSize: 16
                            font.bold: true
                            font.family: ShinConfig.fontFamily
                        }

                        SettingRow { title: "Opacidade do fundo personalizado"; valueText: Math.round(ShinData.mediaBgOpacity * 100) + "%"; onMinus: root.setReal("mediaBgOpacity", ShinData.mediaBgOpacity - 0.05); onPlus: root.setReal("mediaBgOpacity", ShinData.mediaBgOpacity + 0.05) }

                        WallpaperPicker {
                            title: "Fundo do popup da mídia"
                            targetKey: "mediaBg"
                            currentPath: ShinData.mediaBg
                            wallpapers: root.wallpapers
                        }
                    }

                    Column {
                        anchors.fill: parent
                        spacing: 12
                        visible: ShinData.settingsCategory === "effects"

                        Text {
                            text: "Efeitos"
                            color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                            font.pixelSize: 16
                            font.bold: true
                            font.family: ShinConfig.fontFamily
                        }

                        ToggleRow {
                            title: "Visualizer / efeitos ativos"
                            active: ShinData.effectsEnabled
                            onToggle: ShinData.save("effectsEnabled", !ShinData.effectsEnabled)
                        }

                        SettingRow { title: "Força do motion"; valueText: Math.round(ShinData.motionStrength * 100) + "%"; onMinus: root.setReal("motionStrength", ShinData.motionStrength - 0.05); onPlus: root.setReal("motionStrength", ShinData.motionStrength + 0.05) }

                        Text {
                            width: parent.width
                            text: "Área reservada para efeitos futuros: partículas, blur dinâmico, glow, visualizer real com CAVA/PipeWire, etc."
                            color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                            font.pixelSize: 10
                            font.family: ShinConfig.fontFamily
                            wrapMode: Text.WordWrap
                        }
                    }

                    Column {
                        anchors.fill: parent
                        spacing: 12
                        visible: ShinData.settingsCategory === "fonts"

                        Text {
                            text: "Fontes"
                            color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                            font.pixelSize: 16
                            font.bold: true
                            font.family: ShinConfig.fontFamily
                        }

                        Text {
                            width: parent.width
                            text: "Fonte atual: " + ShinConfig.fontFamily
                            color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                            font.pixelSize: 10
                            font.family: ShinConfig.fontFamily
                            elide: Text.ElideRight
                        }

                        FontPicker {
                            fonts: root.fonts
                            currentFont: ShinConfig.fontFamily
                        }
                    }
                }
            }

            component CatButton: Rectangle {
                id: cb
                property string label: "Cat"
                property string cat: "bar"

                width: 150
                height: 36
                radius: 11
                color: ShinData.settingsCategory === cb.cat
                    ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.24)
                    : area.containsMouse
                        ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.13)
                        : Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.06)

                Text {
                    anchors.centerIn: parent
                    text: cb.label
                    color: ShinData.settingsCategory === cb.cat ? (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff") : (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                    font.pixelSize: 11
                    font.bold: ShinData.settingsCategory === cb.cat
                    font.family: ShinConfig.fontFamily
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.setCat(cb.cat)
                }

                Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }

            component SettingRow: Rectangle {
                id: sr
                property string title: "Setting"
                property string valueText: ""
                signal minus()
                signal plus()

                width: 500
                height: 42
                radius: 12
                color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.055)
                border.color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.10)
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        width: parent.width - 142
                        anchors.verticalCenter: parent.verticalCenter
                        text: sr.title
                        color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                        font.pixelSize: 10
                        font.family: ShinConfig.fontFamily
                        elide: Text.ElideRight
                    }

                    Text {
                        width: 64
                        anchors.verticalCenter: parent.verticalCenter
                        text: sr.valueText
                        color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                        font.pixelSize: 10
                        font.family: ShinConfig.fontFamily
                        horizontalAlignment: Text.AlignHCenter
                    }

                    SmallButton { label: "-"; onPress: sr.minus() }
                    SmallButton { label: "+"; onPress: sr.plus() }
                }
            }

            component ToggleRow: Rectangle {
                id: tr
                property string title: "Toggle"
                property bool active: false
                signal toggle()

                width: 500
                height: 42
                radius: 12
                color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.055)

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: tr.title
                    color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                    font.pixelSize: 10
                    font.family: ShinConfig.fontFamily
                }

                Rectangle {
                    width: 52
                    height: 24
                    radius: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: tr.active
                        ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.28)
                        : Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.10)

                    Rectangle {
                        width: 18
                        height: 18
                        radius: 9
                        anchors.verticalCenter: parent.verticalCenter
                        x: tr.active ? 30 : 4
                        color: tr.active ? (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff") : (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")

                        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: tr.toggle()
                    }
                }
            }

            component SmallButton: Rectangle {
                id: sb
                property string label: "+"
                signal press()

                width: 28
                height: 24
                radius: 8
                anchors.verticalCenter: parent.verticalCenter
                color: sbArea.containsMouse
                    ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.22)
                    : Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.08)

                Text {
                    anchors.centerIn: parent
                    text: sb.label
                    color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                    font.pixelSize: 12
                    font.family: ShinConfig.fontFamily
                }

                MouseArea {
                    id: sbArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: sb.press()
                }
            }

            component WallpaperPicker: Column {
                id: wp
                property string title: "Fundo"
                property string targetKey: "clockBg"
                property string currentPath: ""
                property var wallpapers: []

                width: 500
                spacing: 8

                Text {
                    text: wp.title
                    color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                    font.pixelSize: 12
                    font.bold: true
                    font.family: ShinConfig.fontFamily
                }

                Text {
                    width: parent.width
                    text: wp.currentPath.length > 0 ? root.basename(wp.currentPath) : "Nenhum fundo selecionado"
                    color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                    font.pixelSize: 10
                    font.family: ShinConfig.fontFamily
                    elide: Text.ElideRight
                }

                Row {
                    spacing: 8

                    Rectangle {
                        width: 90
                        height: 30
                        radius: 10
                        color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.07)

                        Text {
                            anchors.centerIn: parent
                            text: "Atualizar"
                            color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                            font.pixelSize: 10
                            font.family: ShinConfig.fontFamily
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: wallProc.running = true
                        }
                    }

                    Rectangle {
                        width: 90
                        height: 30
                        radius: 10
                        color: Qt.rgba((ShinColors && ShinColors.warn ? ShinColors.warn : "#ffffff").r, (ShinColors && ShinColors.warn ? ShinColors.warn : "#ffffff").g, (ShinColors && ShinColors.warn ? ShinColors.warn : "#ffffff").b, 0.12)

                        Text {
                            anchors.centerIn: parent
                            text: "Limpar"
                            color: (ShinColors && ShinColors.warn ? ShinColors.warn : "#ffffff")
                            font.pixelSize: 10
                            font.family: ShinConfig.fontFamily
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: ShinData.save(wp.targetKey, "")
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 180
                    radius: 14
                    color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.05)
                    border.color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.14)
                    border.width: 1
                    clip: true

                    ListView {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6
                        model: wp.wallpapers

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 32
                            radius: 10
                            color: modelData === wp.currentPath
                                ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.20)
                                : pickArea.containsMouse
                                    ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.12)
                                    : "transparent"

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 20
                                text: root.basename(modelData)
                                color: modelData === wp.currentPath ? (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff") : (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                                font.pixelSize: 10
                                font.family: ShinConfig.fontFamily
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                id: pickArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: ShinData.save(wp.targetKey, modelData)
                            }

                            Behavior on color { ColorAnimation { duration: 100; easing.type: Easing.OutCubic } }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: wp.wallpapers.length === 0
                        text: "Coloque imagens em\n~/Pictures/Wallpapers/static"
                        color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                        font.pixelSize: 10
                        font.family: ShinConfig.fontFamily
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            component FontPicker: Rectangle {
                id: fp
                property var fonts: []
                property string currentFont: ""

                width: 500
                height: 360
                radius: 14
                color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.05)
                border.color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.14)
                border.width: 1
                clip: true

                ListView {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6
                    model: fp.fonts

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 34
                        radius: 10
                        color: modelData === fp.currentFont
                            ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.20)
                            : fontArea.containsMouse
                                ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.12)
                                : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 20
                            text: modelData
                            color: modelData === fp.currentFont ? (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff") : (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                            font.pixelSize: 11
                            font.family: modelData
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: fontArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: ShinData.save("fontFamily", modelData)
                        }

                        Behavior on color { ColorAnimation { duration: 100; easing.type: Easing.OutCubic } }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: fp.fonts.length === 0
                    text: "Nenhuma fonte encontrada"
                    color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                    font.pixelSize: 10
                    font.family: ShinConfig.fontFamily
                }
            }
        }
    }
}
