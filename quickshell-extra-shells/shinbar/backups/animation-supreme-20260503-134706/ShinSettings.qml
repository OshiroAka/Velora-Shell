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
    property bool overlayVisible: false
    property real motion: 0.0
    property var wallpapers: []
    property var fonts: []
    property int keyboardRow: 0
    property var categories: ["bar", "clock", "weather", "profile", "media", "search", "fonts", "colors", "effects"]

    function clamp01(v) {
        return Math.max(0, Math.min(1, v))
    }

    function ease(t) {
        t = clamp01(t)
        return 1 - Math.pow(1 - t, 3.0)
    }

    function lerp(a, b, t) {
        return a + (b - a) * t
    }

    function shellQuote(s) {
        return "'" + ("" + s).replace(/'/g, "'\\''") + "'"
    }

    function clamp(v, mn, mx) {
        return Math.max(mn, Math.min(mx, v))
    }

    function setInt(key, val, mn, mx) {
        ShinData.save(key, clamp(val, mn === undefined ? 0 : mn, mx === undefined ? 9999 : mx))
    }

    function setReal(key, val, mn, mx) {
        ShinData.save(key, Math.max(mn === undefined ? 0.05 : mn, Math.min(mx === undefined ? 1 : mx, val)).toFixed(2))
    }

    function setBool(key, val) {
        ShinData.save(key, val)
    }

    function cycleInt(key, current, count) {
        ShinData.save(key, (current + 1) % count)
    }

    function cycleStep(key, current, count, dir) {
        ShinData.save(key, (current + dir + count) % count)
    }

    function rowCount() {
        if (ShinData.settingsCategory === "bar") return 12
        if (ShinData.settingsCategory === "clock") return 7
        if (ShinData.settingsCategory === "weather") return 2
        if (ShinData.settingsCategory === "profile") return 4
        if (ShinData.settingsCategory === "media") return 5
        if (ShinData.settingsCategory === "effects") return 6
        if (ShinData.settingsCategory === "search") return 8
        if (ShinData.settingsCategory === "colors") return 3
        return 1
    }

    function clampKeyboardRow() {
        keyboardRow = Math.max(0, Math.min(keyboardRow, rowCount() - 1))
    }

    function setCat(c) {
        ShinData.save("settingsCategory", c)
        keyboardRow = 0
    }

    function categoryIndex() {
        var idx = categories.indexOf(ShinData.settingsCategory)
        return idx >= 0 ? idx : 0
    }

    function moveCategory(dir) {
        var idx = (categoryIndex() + dir + categories.length) % categories.length
        setCat(categories[idx])
    }

    function moveKeyboard(dx, dy) {
        if (!opened)
            return
        if (dy !== 0) {
            keyboardRow = Math.max(0, Math.min(keyboardRow + dy, rowCount() - 1))
            return
        }
        if (dx !== 0)
            adjustKeyboard(dx)
    }

    function activateKeyboard() {
        if (!opened)
            return
        adjustKeyboard(0)
    }

    function setBoolKey(key, current, dir) {
        if (dir === 0)
            setBool(key, !current)
        else
            setBool(key, dir > 0)
    }

    function adjustKeyboard(dir) {
        var cat = ShinData.settingsCategory
        var r = keyboardRow
        var step = dir === 0 ? 1 : dir

        if (cat === "bar") {
            if (r === 0) setInt("barH", ShinConfig.barH + step * 2, 24, 72)
            else if (r === 1) setInt("pillH", ShinConfig.pillH + step * 2, 18, 54)
            else if (r === 2) setInt("pillR", ShinConfig.pillR + step, 2, 28)
            else if (r === 3) setInt("pillPadH", ShinConfig.pillPadH + step, 4, 28)
            else if (r === 4) setInt("pillSpacing", ShinConfig.pillSpacing + step, 0, 18)
            else if (r === 5) setInt("barMarginT", ShinConfig.barMarginT + step, 0, 24)
            else if (r === 6) setInt("barMarginH", ShinConfig.barMarginH + step, 0, 34)
            else if (r === 7) setInt("fontSize", ShinConfig.fontSize + step, 8, 22)
            else if (r === 8) setInt("fontSizeSm", ShinConfig.fontSizeSm + step, 7, 18)
            else if (r === 9) setReal("pillOpacity", ShinConfig.pillOpacity + step * 0.05, 0.05, 1)
            else if (r === 10) setReal("popupOpacity", ShinConfig.popupOpacity + step * 0.05, 0.05, 1)
            else if (r === 11 && dir >= 0) ShinData.saveAll()
        } else if (cat === "clock") {
            if (r === 0) cycleStep("clockStyle", ShinConfig.clockStyle, 5, step)
            else if (r === 1) cycleStep("clockPopupStyle", ShinConfig.clockPopupStyle, 3, step)
            else if (r === 2) setBoolKey("clockShowSeconds", ShinConfig.clockShowSeconds, dir)
            else if (r === 3) setBoolKey("clockUse24h", ShinConfig.clockUse24h, dir)
            else if (r === 4) setBoolKey("clockShowDate", ShinConfig.clockShowDate, dir)
            else if (r === 5) setReal("clockBgOpacity", ShinData.clockBgOpacity + step * 0.05, 0, 1)
            else if (r === 6) setReal("clockAccentBoost", ShinData.clockAccentBoost + step * 0.05, 0.2, 2)
        } else if (cat === "weather") {
            if (r === 0) setReal("weatherBgOpacity", ShinData.weatherBgOpacity + step * 0.05, 0, 1)
            else if (r === 1 && dir >= 0) wallProc.running = true
        } else if (cat === "profile") {
            if (r === 0 && dir === 0) ShinData.save("profileName", ShinData.profileName)
            else if (r === 1 && dir === 0) ShinData.save("profileBio", ShinData.profileBio)
            else if (r === 2 && dir === 0) ShinData.save("profileTikTok", ShinData.profileTikTok)
            else if (r === 3 && dir === 0) ShinData.save("profileSystem", ShinData.profileSystem)
        } else if (cat === "media") {
            if (r === 0) setBoolKey("mediaAlwaysVisible", ShinConfig.mediaAlwaysVisible, dir)
            else if (r === 1) setBoolKey("mediaShowVisualizer", ShinConfig.mediaShowVisualizer, dir)
            else if (r === 2) setInt("mediaPanelWidth", ShinConfig.mediaPanelWidth + step * 10, 220, 340)
            else if (r === 3) setInt("mediaPanelHeight", ShinConfig.mediaPanelHeight + step * 10, 460, 680)
            else if (r === 4) setReal("mediaBgOpacity", ShinData.mediaBgOpacity + step * 0.05, 0, 1)
        } else if (cat === "effects") {
            if (r === 0) setBoolKey("effectsEnabled", ShinData.effectsEnabled, dir)
            else if (r === 1) setBoolKey("trailEnabled", ShinData.trailEnabled, dir)
            else if (r === 2) setReal("motionStrength", ShinData.motionStrength + step * 0.05, 0.35, 1.8)
            else if (r === 3) setInt("animationSpeed", ShinConfig.animationSpeed + step * 10, 40, 180)
            else if (r === 4) setReal("glowStrength", ShinConfig.glowStrength + step * 0.05, 0, 1.6)
            else if (r === 5) setReal("hoverScale", ShinConfig.hoverScale + step * 0.005, 1, 1.12)
        } else if (cat === "search") {
            if (r === 0) setBoolKey("searchEnabled", ShinData.searchEnabled, dir)
            else if (r === 1) setBoolKey("searchShowIcons", ShinData.searchShowIcons, dir)
            else if (r === 2) setBoolKey("searchCompact", ShinData.searchCompact, dir)
            else if (r === 3) cycleStep("searchPosition", ShinConfig.searchPosition, 3, step)
            else if (r === 4) setInt("searchPanelWidth", ShinConfig.searchPanelWidth + step * 20, 380, 920)
            else if (r === 5) setInt("searchMaxResults", ShinConfig.searchMaxResults + step, 3, 18)
            else if (r === 6) setInt("searchIconSize", ShinConfig.searchIconSize + step * 2, 16, 48)
            else if (r === 7) setReal("searchOpacity", ShinConfig.searchOpacity + step * 0.05, 0.35, 1)
        } else if (cat === "colors") {
            if (r === 0) setBoolKey("pywalActive", ShinData.pywalActive, dir)
            else if (r === 1) setInt("pywalPollMs", ShinConfig.pywalPollMs + step * 100, 250, 3000)
            else if (r === 2 && dir >= 0) ShinColors.refreshWalColors()
        }
    }

    function positionName(v) {
        if (v === 0) return "Esquerda"
        if (v === 2) return "Direita"
        return "Centro"
    }

    function clockStyleName(v) {
        if (v === 1) return "Compacto"
        if (v === 2) return "Data + hora"
        if (v === 3) return "Hypr dots"
        if (v === 4) return "Minimal"
        return "Digital"
    }

    function popupStyleName(v) {
        if (v === 1) return "HyprOS wide"
        if (v === 2) return "Soft glow"
        return "Island"
    }

    function basename(path) {
        var p = ("" + path).split("/")
        return p[p.length - 1]
    }

    Component.onCompleted: {
        if (ShinData.settingsCategory === "apps")
            ShinData.save("settingsCategory", "bar")
        wallProc.running = true
        fontProc.running = true
        applyTimer.restart()
    }

    onOpenedChanged: {
        if (opened) {
            clampKeyboardRow()
            hideTimer.stop()
            closeAnim.stop()
            root.overlayVisible = true
            openAnim.from = root.motion
            openAnim.restart()
        } else {
            openAnim.stop()
            closeAnim.from = root.motion
            closeAnim.restart()
            hideTimer.restart()
        }
    }

    Connections {
        target: ShinPopup
        function onInsideNonceChanged() {
            if (root.opened)
                root.moveKeyboard(ShinPopup.insideX, ShinPopup.insideY)
        }

        function onActivateNonceChanged() {
            if (root.opened)
                root.activateKeyboard()
        }
    }

    Timer {
        id: applyTimer
        interval: 250
        repeat: false
        onTriggered: ShinData.applyConfig()
    }

    NumberAnimation {
        id: openAnim
        target: root
        property: "motion"
        from: 0
        to: 1
        duration: ShinData.popupAnim(260)
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: closeAnim
        target: root
        property: "motion"
        from: 1
        to: 0
        duration: ShinData.popupAnim(190)
        easing.type: Easing.InCubic
    }

    Timer {
        id: hideTimer
        interval: ShinData.popupAnim(205)
        repeat: false
        onTriggered: {
            if (!root.opened) {
                root.overlayVisible = false
                root.motion = 0
            }
        }
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
        visible: root.overlayVisible || openAnim.running || closeAnim.running
        color: "transparent"
        focusable: true

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "shinbar-settings"
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore

        Keys.onEscapePressed: ShinPopup.close("settings")
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Up) {
                root.moveKeyboard(0, -1)
                event.accepted = true
            } else if (event.key === Qt.Key_Down) {
                root.moveKeyboard(0, 1)
                event.accepted = true
            } else if (event.key === Qt.Key_Left) {
                root.moveKeyboard(-1, 0)
                event.accepted = true
            } else if (event.key === Qt.Key_Right) {
                root.moveKeyboard(1, 0)
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.activateKeyboard()
                event.accepted = true
            } else if (event.key === Qt.Key_A) {
                root.moveCategory(-1)
                event.accepted = true
            } else if (event.key === Qt.Key_D) {
                root.moveCategory(1)
                event.accepted = true
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.25 * root.ease(root.motion))
            MouseArea {
                anchors.fill: parent
                enabled: root.opened
                onClicked: ShinPopup.close("settings")
            }
        }

        Rectangle {
            id: card
            property real et: root.ease(root.motion)
            width: Math.min(820, overlay.width - 20)
            height: Math.min(640, overlay.height - ShinConfig.barH - ShinConfig.barMarginT - 28)
            x: overlay.width - width - Math.max(6, ShinConfig.barMarginH) + Math.round(root.lerp(28, 0, card.et))
            y: ShinConfig.barH + ShinConfig.barMarginT + 10 + Math.round(root.lerp(-10, 0, card.et))
            radius: 22
            antialiasing: true
            color: Qt.rgba((ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").r, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").g, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").b, Math.max(0.64, ShinConfig.popupOpacity))
            border.color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.30)
            border.width: 1

            opacity: root.clamp01(root.motion * 1.25)
            scale: 0.92 + card.et * 0.08

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
                    CatButton { label: "Clima"; cat: "weather" }
                    CatButton { label: "Perfil"; cat: "profile" }
                    CatButton { label: "Mídia"; cat: "media" }
                    CatButton { label: "Pesquisa"; cat: "search" }
                    CatButton { label: "Fontes"; cat: "fonts" }
                    CatButton { label: "Cores"; cat: "colors" }
                    CatButton { label: "Efeitos"; cat: "effects" }

                    Item { height: 1; width: 1 }

                    Rectangle {
                        width: parent.width
                        height: 34
                        radius: 10
                        color: saveArea.containsMouse
                            ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.18)
                            : Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.07)

                        Text {
                            anchors.centerIn: parent
                            text: ShinData.saveQueue.length > 0 ? "Salvando..." : "Salvar"
                            color: saveArea.containsMouse ? (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff") : (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                            font.pixelSize: 10
                            font.bold: true
                            font.family: ShinConfig.fontFamily
                        }

                        MouseArea {
                            id: saveArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: ShinData.saveAll()
                        }
                    }

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

                        SettingRow { keyIndex: 0; title: "Altura total"; valueText: ShinConfig.barH + "px"; onMinus: root.setInt("barH", ShinConfig.barH - 2, 24, 72); onPlus: root.setInt("barH", ShinConfig.barH + 2, 24, 72) }
                        SettingRow { keyIndex: 1; title: "Altura dos pills"; valueText: ShinConfig.pillH + "px"; onMinus: root.setInt("pillH", ShinConfig.pillH - 2, 18, 54); onPlus: root.setInt("pillH", ShinConfig.pillH + 2, 18, 54) }
                        SettingRow { keyIndex: 2; title: "Raio dos pills"; valueText: ShinConfig.pillR + "px"; onMinus: root.setInt("pillR", ShinConfig.pillR - 1, 2, 28); onPlus: root.setInt("pillR", ShinConfig.pillR + 1, 2, 28) }
                        SettingRow { keyIndex: 3; title: "Padding horizontal"; valueText: ShinConfig.pillPadH + "px"; onMinus: root.setInt("pillPadH", ShinConfig.pillPadH - 1, 4, 28); onPlus: root.setInt("pillPadH", ShinConfig.pillPadH + 1, 4, 28) }
                        SettingRow { keyIndex: 4; title: "Espaço entre módulos"; valueText: ShinConfig.pillSpacing + "px"; onMinus: root.setInt("pillSpacing", ShinConfig.pillSpacing - 1, 0, 18); onPlus: root.setInt("pillSpacing", ShinConfig.pillSpacing + 1, 0, 18) }
                        SettingRow { keyIndex: 5; title: "Margem superior"; valueText: ShinConfig.barMarginT + "px"; onMinus: root.setInt("barMarginT", ShinConfig.barMarginT - 1, 0, 24); onPlus: root.setInt("barMarginT", ShinConfig.barMarginT + 1, 0, 24) }
                        SettingRow { keyIndex: 6; title: "Margem lateral"; valueText: ShinConfig.barMarginH + "px"; onMinus: root.setInt("barMarginH", ShinConfig.barMarginH - 1, 0, 34); onPlus: root.setInt("barMarginH", ShinConfig.barMarginH + 1, 0, 34) }
                        SettingRow { keyIndex: 7; title: "Fonte principal"; valueText: ShinConfig.fontSize + "px"; onMinus: root.setInt("fontSize", ShinConfig.fontSize - 1, 8, 22); onPlus: root.setInt("fontSize", ShinConfig.fontSize + 1, 8, 22) }
                        SettingRow { keyIndex: 8; title: "Fonte pequena"; valueText: ShinConfig.fontSizeSm + "px"; onMinus: root.setInt("fontSizeSm", ShinConfig.fontSizeSm - 1, 7, 18); onPlus: root.setInt("fontSizeSm", ShinConfig.fontSizeSm + 1, 7, 18) }
                        SettingRow { keyIndex: 9; title: "Opacidade dos pills"; valueText: Math.round(ShinConfig.pillOpacity * 100) + "%"; onMinus: root.setReal("pillOpacity", ShinConfig.pillOpacity - 0.05, 0.05, 1); onPlus: root.setReal("pillOpacity", ShinConfig.pillOpacity + 0.05, 0.05, 1) }
                        SettingRow { keyIndex: 10; title: "Opacidade dos popups"; valueText: Math.round(ShinConfig.popupOpacity * 100) + "%"; onMinus: root.setReal("popupOpacity", ShinConfig.popupOpacity - 0.05, 0.05, 1); onPlus: root.setReal("popupOpacity", ShinConfig.popupOpacity + 0.05, 0.05, 1) }
                        ActionRow { keyIndex: 11; title: "Salvar configurações"; valueText: "savedata.json"; onAction: ShinData.saveAll() }

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

                        CycleRow { keyIndex: 0; title: "Estilo da pill"; valueText: root.clockStyleName(ShinConfig.clockStyle); onNext: root.cycleInt("clockStyle", ShinConfig.clockStyle, 5) }
                        CycleRow { keyIndex: 1; title: "Estilo do popup"; valueText: root.popupStyleName(ShinConfig.clockPopupStyle); onNext: root.cycleInt("clockPopupStyle", ShinConfig.clockPopupStyle, 3) }
                        ToggleRow { keyIndex: 2; title: "Mostrar segundos"; active: ShinConfig.clockShowSeconds; onToggle: root.setBool("clockShowSeconds", !ShinConfig.clockShowSeconds) }
                        ToggleRow { keyIndex: 3; title: "Formato 24h"; active: ShinConfig.clockUse24h; onToggle: root.setBool("clockUse24h", !ShinConfig.clockUse24h) }
                        ToggleRow { keyIndex: 4; title: "Data no popup"; active: ShinConfig.clockShowDate; onToggle: root.setBool("clockShowDate", !ShinConfig.clockShowDate) }
                        SettingRow { keyIndex: 5; title: "Opacidade do fundo personalizado"; valueText: Math.round(ShinData.clockBgOpacity * 100) + "%"; onMinus: root.setReal("clockBgOpacity", ShinData.clockBgOpacity - 0.05, 0, 1); onPlus: root.setReal("clockBgOpacity", ShinData.clockBgOpacity + 0.05, 0, 1) }
                        SettingRow { keyIndex: 6; title: "Força do accent"; valueText: Math.round(ShinData.clockAccentBoost * 100) + "%"; onMinus: root.setReal("clockAccentBoost", ShinData.clockAccentBoost - 0.05, 0.2, 2); onPlus: root.setReal("clockAccentBoost", ShinData.clockAccentBoost + 0.05, 0.2, 2) }

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
                        visible: ShinData.settingsCategory === "weather"

                        Text {
                            text: "Clima"
                            color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                            font.pixelSize: 16
                            font.bold: true
                            font.family: ShinConfig.fontFamily
                        }

                        Text {
                            width: parent.width
                            text: "Cidade atual: " + ShinConfig.weatherCity
                            color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                            font.pixelSize: 10
                            font.family: ShinConfig.fontFamily
                            elide: Text.ElideRight
                        }

                        SettingRow { keyIndex: 0; title: "Opacidade da foto do clima"; valueText: Math.round(ShinData.weatherBgOpacity * 100) + "%"; onMinus: root.setReal("weatherBgOpacity", ShinData.weatherBgOpacity - 0.05, 0, 1); onPlus: root.setReal("weatherBgOpacity", ShinData.weatherBgOpacity + 0.05, 0, 1) }
                        ActionRow { keyIndex: 1; title: "Atualizar lista de fotos"; valueText: "~/Pictures/Wallpapers/static"; onAction: wallProc.running = true }

                        WallpaperPicker {
                            title: "Fundo do painel de clima"
                            targetKey: "weatherBg"
                            currentPath: ShinData.weatherBg
                            wallpapers: root.wallpapers
                        }
                    }

                    Column {
                        anchors.fill: parent
                        spacing: 12
                        visible: ShinData.settingsCategory === "profile"

                        Text {
                            text: "Perfil"
                            color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                            font.pixelSize: 16
                            font.bold: true
                            font.family: ShinConfig.fontFamily
                        }

                        TextFieldRow { keyIndex: 0; title: "Nome"; targetKey: "profileName"; currentValue: ShinData.profileName; placeholder: "User" }
                        TextFieldRow { keyIndex: 1; title: "Bio"; targetKey: "profileBio"; currentValue: ShinData.profileBio; placeholder: "Foco, disciplina e constancia." }
                        TextFieldRow { keyIndex: 2; title: "TikTok"; targetKey: "profileTikTok"; currentValue: ShinData.profileTikTok; placeholder: "@____________" }
                        TextFieldRow { keyIndex: 3; title: "Sistema"; targetKey: "profileSystem"; currentValue: ShinData.profileSystem; placeholder: "CachyOS" }

                        WallpaperPicker {
                            title: "Foto de perfil"
                            targetKey: "profileImage"
                            currentPath: ShinData.profileImage
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

                        ToggleRow { keyIndex: 0; title: "Mostrar sem player"; active: ShinConfig.mediaAlwaysVisible; onToggle: root.setBool("mediaAlwaysVisible", !ShinConfig.mediaAlwaysVisible) }
                        ToggleRow { keyIndex: 1; title: "Visualizer animado"; active: ShinConfig.mediaShowVisualizer; onToggle: root.setBool("mediaShowVisualizer", !ShinConfig.mediaShowVisualizer) }
                        SettingRow { keyIndex: 2; title: "Largura do popup"; valueText: ShinConfig.mediaPanelWidth + "px"; onMinus: root.setInt("mediaPanelWidth", ShinConfig.mediaPanelWidth - 10, 220, 340); onPlus: root.setInt("mediaPanelWidth", ShinConfig.mediaPanelWidth + 10, 220, 340) }
                        SettingRow { keyIndex: 3; title: "Altura do popup"; valueText: ShinConfig.mediaPanelHeight + "px"; onMinus: root.setInt("mediaPanelHeight", ShinConfig.mediaPanelHeight - 10, 460, 680); onPlus: root.setInt("mediaPanelHeight", ShinConfig.mediaPanelHeight + 10, 460, 680) }
                        SettingRow { keyIndex: 4; title: "Opacidade do fundo personalizado"; valueText: Math.round(ShinData.mediaBgOpacity * 100) + "%"; onMinus: root.setReal("mediaBgOpacity", ShinData.mediaBgOpacity - 0.05, 0, 1); onPlus: root.setReal("mediaBgOpacity", ShinData.mediaBgOpacity + 0.05, 0, 1) }

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
                            keyIndex: 0
                            title: "Visualizer / efeitos ativos"
                            active: ShinData.effectsEnabled
                            onToggle: ShinData.save("effectsEnabled", !ShinData.effectsEnabled)
                        }

                        ToggleRow { keyIndex: 1; title: "Rastro de foco"; active: ShinData.trailEnabled; onToggle: root.setBool("trailEnabled", !ShinData.trailEnabled) }
                        SettingRow { keyIndex: 2; title: "Força do motion"; valueText: Math.round(ShinData.motionStrength * 100) + "%"; onMinus: root.setReal("motionStrength", ShinData.motionStrength - 0.05, 0.35, 1.8); onPlus: root.setReal("motionStrength", ShinData.motionStrength + 0.05, 0.35, 1.8) }
                        SettingRow { keyIndex: 3; title: "Velocidade das animações"; valueText: ShinConfig.animationSpeed + "%"; onMinus: root.setInt("animationSpeed", ShinConfig.animationSpeed - 10, 40, 180); onPlus: root.setInt("animationSpeed", ShinConfig.animationSpeed + 10, 40, 180) }
                        SettingRow { keyIndex: 4; title: "Força do glow"; valueText: Math.round(ShinConfig.glowStrength * 100) + "%"; onMinus: root.setReal("glowStrength", ShinConfig.glowStrength - 0.05, 0, 1.6); onPlus: root.setReal("glowStrength", ShinConfig.glowStrength + 0.05, 0, 1.6) }
                        SettingRow { keyIndex: 5; title: "Escala no hover"; valueText: Math.round(ShinConfig.hoverScale * 100) + "%"; onMinus: root.setReal("hoverScale", ShinConfig.hoverScale - 0.005, 1, 1.12); onPlus: root.setReal("hoverScale", ShinConfig.hoverScale + 0.005, 1, 1.12) }

                        Text {
                            width: parent.width
                            text: "Esses controles afetam pills, popups, busca, rastro de foco e transições."
                            color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                            font.pixelSize: 10
                            font.family: ShinConfig.fontFamily
                            wrapMode: Text.WordWrap
                        }
                    }

                    Column {
                        anchors.fill: parent
                        spacing: 12
                        visible: ShinData.settingsCategory === "search"

                        Text {
                            text: "Pesquisa"
                            color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                            font.pixelSize: 16
                            font.bold: true
                            font.family: ShinConfig.fontFamily
                        }

                        ToggleRow { keyIndex: 0; title: "Mostrar menu de pesquisa"; active: ShinData.searchEnabled; onToggle: root.setBool("searchEnabled", !ShinData.searchEnabled) }
                        ToggleRow { keyIndex: 1; title: "Mostrar ícones"; active: ShinData.searchShowIcons; onToggle: root.setBool("searchShowIcons", !ShinData.searchShowIcons) }
                        ToggleRow { keyIndex: 2; title: "Modo compacto"; active: ShinData.searchCompact; onToggle: root.setBool("searchCompact", !ShinData.searchCompact) }
                        CycleRow { keyIndex: 3; title: "Posição"; valueText: root.positionName(ShinConfig.searchPosition); onNext: root.cycleInt("searchPosition", ShinConfig.searchPosition, 3) }
                        SettingRow { keyIndex: 4; title: "Largura do menu"; valueText: ShinConfig.searchPanelWidth + "px"; onMinus: root.setInt("searchPanelWidth", ShinConfig.searchPanelWidth - 20, 380, 920); onPlus: root.setInt("searchPanelWidth", ShinConfig.searchPanelWidth + 20, 380, 920) }
                        SettingRow { keyIndex: 5; title: "Resultados máximos"; valueText: ShinConfig.searchMaxResults; onMinus: root.setInt("searchMaxResults", ShinConfig.searchMaxResults - 1, 3, 18); onPlus: root.setInt("searchMaxResults", ShinConfig.searchMaxResults + 1, 3, 18) }
                        SettingRow { keyIndex: 6; title: "Tamanho dos ícones"; valueText: ShinConfig.searchIconSize + "px"; onMinus: root.setInt("searchIconSize", ShinConfig.searchIconSize - 2, 16, 48); onPlus: root.setInt("searchIconSize", ShinConfig.searchIconSize + 2, 16, 48) }
                        SettingRow { keyIndex: 7; title: "Opacidade do menu"; valueText: Math.round(ShinConfig.searchOpacity * 100) + "%"; onMinus: root.setReal("searchOpacity", ShinConfig.searchOpacity - 0.05, 0.35, 1); onPlus: root.setReal("searchOpacity", ShinConfig.searchOpacity + 0.05, 0.35, 1) }
                    }

                    Column {
                        anchors.fill: parent
                        spacing: 12
                        visible: ShinData.settingsCategory === "colors"

                        Text {
                            text: "Cores e pywal16"
                            color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                            font.pixelSize: 16
                            font.bold: true
                            font.family: ShinConfig.fontFamily
                        }

                        ToggleRow { keyIndex: 0; title: "Pywal16 ao vivo"; active: ShinData.pywalActive; onToggle: root.setBool("pywalActive", !ShinData.pywalActive) }
                        SettingRow { keyIndex: 1; title: "Intervalo de leitura"; valueText: ShinConfig.pywalPollMs + "ms"; onMinus: root.setInt("pywalPollMs", ShinConfig.pywalPollMs - 100, 250, 3000); onPlus: root.setInt("pywalPollMs", ShinConfig.pywalPollMs + 100, 250, 3000) }
                        ActionRow { keyIndex: 2; title: "Recarregar pywal agora"; valueText: "~/.cache/wal/colors.json"; onAction: ShinColors.refreshWalColors() }

                        Rectangle {
                            width: 500
                            height: 58
                            radius: 14
                            color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.055)
                            border.width: 1
                            border.color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.12)

                            Row {
                                anchors.centerIn: parent
                                spacing: 8
                                Repeater {
                                    model: [ShinColors.bg, ShinColors.surface, ShinColors.accent, ShinColors.fg, ShinColors.warn]
                                    Rectangle {
                                        width: 34
                                        height: 34
                                        radius: 10
                                        color: modelData
                                        border.width: 1
                                        border.color: Qt.rgba(1, 1, 1, 0.18)
                                    }
                                }
                            }
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

            component TextFieldRow: Rectangle {
                id: tr
                property string title: "Texto"
                property string targetKey: ""
                property string currentValue: ""
                property string placeholder: ""
                property int keyIndex: -1
                property bool keySelected: root.opened && root.keyboardRow === keyIndex

                width: 500
                height: 46
                radius: 12
                color: field.activeFocus || keySelected
                    ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.14)
                    : Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.055)
                border.color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, field.activeFocus || keySelected ? 0.58 : 0.10)
                border.width: field.activeFocus || keySelected ? 2 : 1
                clip: true

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 92
                    text: tr.title
                    color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                    font.pixelSize: 10
                    font.family: ShinConfig.fontFamily
                    elide: Text.ElideRight
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 112
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    height: 30
                    radius: 9
                    color: Qt.rgba((ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").r, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").g, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").b, 0.38)
                    border.width: 1
                    border.color: Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.08)
                    clip: true

                    TextInput {
                        id: field
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        text: tr.currentValue
                        color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                        selectionColor: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.36)
                        selectedTextColor: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                        font.pixelSize: 10
                        font.family: ShinConfig.fontFamily
                        clip: true
                        selectByMouse: true

                        onEditingFinished: {
                            if (tr.targetKey.length > 0)
                                ShinData.save(tr.targetKey, text)
                        }

                        Keys.onReturnPressed: {
                            if (tr.targetKey.length > 0)
                                ShinData.save(tr.targetKey, text)
                            field.focus = false
                        }
                    }

                    Text {
                        anchors.left: field.left
                        anchors.verticalCenter: parent.verticalCenter
                        visible: field.text.length === 0 && !field.activeFocus
                        text: tr.placeholder
                        color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                        opacity: 0.62
                        font.pixelSize: 10
                        font.family: ShinConfig.fontFamily
                    }
                }
            }

            component SettingRow: Rectangle {
                id: sr
                property string title: "Setting"
                property string valueText: ""
                property int keyIndex: -1
                property bool keySelected: root.opened && ShinData.settingsCategory.length > 0 && root.keyboardRow === keyIndex
                signal minus()
                signal plus()

                width: 500
                height: 42
                radius: 12
                color: keySelected
                    ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.16)
                    : Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.055)
                border.color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, keySelected ? 0.58 : 0.10)
                border.width: keySelected ? 2 : 1

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

            component CycleRow: Rectangle {
                id: cr
                property string title: "Setting"
                property string valueText: ""
                property int keyIndex: -1
                property bool keySelected: root.opened && root.keyboardRow === keyIndex
                signal next()

                width: 500
                height: 42
                radius: 12
                color: keySelected
                    ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.16)
                    : Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.055)
                border.color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, keySelected ? 0.58 : 0.10)
                border.width: keySelected ? 2 : 1

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 176
                    text: cr.title
                    color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                    font.pixelSize: 10
                    font.family: ShinConfig.fontFamily
                    elide: Text.ElideRight
                }

                Text {
                    anchors.right: nextBtn.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 112
                    text: cr.valueText
                    color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                    font.pixelSize: 10
                    font.family: ShinConfig.fontFamily
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                }

                SmallButton {
                    id: nextBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    label: ">"
                    onPress: cr.next()
                }
            }

            component ActionRow: Rectangle {
                id: ar
                property string title: "Ação"
                property string valueText: ""
                property int keyIndex: -1
                property bool keySelected: root.opened && root.keyboardRow === keyIndex
                signal action()

                width: 500
                height: 42
                radius: 12
                color: arArea.containsMouse || keySelected
                    ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.13)
                    : Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.055)
                border.color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, keySelected ? 0.58 : 0.10)
                border.width: keySelected ? 2 : 1

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 150
                    text: ar.title
                    color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                    font.pixelSize: 10
                    font.family: ShinConfig.fontFamily
                    elide: Text.ElideRight
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 126
                    text: ar.valueText
                    color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                    font.pixelSize: 9
                    font.family: ShinConfig.fontFamily
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: arArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: ar.action()
                }

                Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }

            component ToggleRow: Rectangle {
                id: tr
                property string title: "Toggle"
                property bool active: false
                property int keyIndex: -1
                property bool keySelected: root.opened && root.keyboardRow === keyIndex
                signal toggle()

                width: 500
                height: 42
                radius: 12
                color: keySelected
                    ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.16)
                    : Qt.rgba((ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g, (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b, 0.055)
                border.width: keySelected ? 2 : 1
                border.color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, keySelected ? 0.58 : 0.08)

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
