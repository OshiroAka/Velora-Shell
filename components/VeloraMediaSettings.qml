pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Pipewire
import "../core" as Core

Item {
    id: ui
    required property var theme
    required property var controller
    required property var styleTheme
    property var motion: defaultMotion
    Core.Motion { id: defaultMotion; config: ui.styleTheme ? ui.styleTheme.config : null }
    property string mediaSection: "playback"
    readonly property real fieldWidth: width>=560 ? (width-16)/2 : width
    property var audioSink: mediaSection==="audio" ? Pipewire.defaultAudioSink : null
    readonly property bool hasAudio: !!(audioSink && audioSink.ready && audioSink.audio)
    PwObjectTracker { objects: ui.audioSink ? [ui.audioSink] : [] }
    property var blockState: null
    readonly property int selectedLyricsBlock: blockState ? blockState.index : 0
    readonly property color accent: styleTheme.accent
    readonly property color primaryText: styleTheme.textPrimary
    readonly property color secondaryText: styleTheme.textSecondary
    readonly property color inputColor: styleTheme.withAlpha(styleTheme.textPrimary,.045)
    readonly property color lineColor: styleTheme.borderSubtle
    readonly property string uiFont: styleTheme.bodyFont
    implicitHeight: pageLoader.item ? (pageLoader.item as Item).implicitHeight : 0
    function selectBlock(index) { if (blockState) blockState.index=index }
    function overrideValue(map, key, fallback) {
        return map && map[key] !== undefined ? map[key] : fallback
    }

    function updateLyrics(overrides) {
        if (!theme)
            return
        if (controller && controller.visible === false)
            return

        theme.applyLyricsSettings(
            overrideValue(overrides, "enabled", theme.lyricsEnabled),
            overrideValue(overrides, "posX", theme.lyricsPositionX),
            overrideValue(overrides, "posY", theme.lyricsPositionY),
            overrideValue(overrides, "colorMode", theme.lyricsColorMode),
            overrideValue(overrides, "manualColor", theme.lyricsManualColor),
            overrideValue(overrides, "fontSize", theme.lyricsFontSize),
            overrideValue(overrides, "opacity", theme.lyricsOpacity),
            overrideValue(overrides, "spacing", theme.lyricsWordSpacing),
            overrideValue(overrides, "shadow", theme.lyricsShadowEnabled),
            overrideValue(overrides, "uppercase", theme.lyricsUppercase),
            overrideValue(overrides, "layout", theme.lyricsLayoutMode),
            overrideValue(overrides, "animation", theme.lyricsAnimationMode),
            overrideValue(overrides, "activeWord", theme.lyricsActiveWordEnabled),
            overrideValue(overrides, "revealMode", theme.lyricsRevealMode),
            overrideValue(overrides, "pos2X", theme.lyricsSecondPositionX),
            overrideValue(overrides, "pos2Y", theme.lyricsSecondPositionY),
            overrideValue(overrides, "syncOffsetMs", theme.lyricsSyncOffsetMs),
            overrideValue(overrides, "floatEnabled", theme.lyricsFloatEnabled),
            overrideValue(overrides, "floatIntensity", theme.lyricsFloatIntensity),
            overrideValue(overrides, "glowEnabled", theme.lyricsGlowEnabled),
            overrideValue(overrides, "glowIntensity", theme.lyricsGlowIntensity),
            true
        )
    }

    function updateLyricsTransform(overrides) {
        if (!theme)
            return
        theme.applyLyricsTransformSettings(
            overrideValue(overrides, "scale", theme.lyricsScale),
            overrideValue(overrides, "rotation", theme.lyricsRotation),
            overrideValue(overrides, "tiltX", theme.lyricsTiltX),
            overrideValue(overrides, "tiltY", theme.lyricsTiltY),
            true
        )
    }

    function updateLyricsMaterial(overrides) {
        if (!theme)
            return
        theme.applyLyricsMaterialSettings(
            overrideValue(overrides, "mode", theme.lyricsMaterialMode),
            overrideValue(overrides, "intensity", theme.lyricsMaterialIntensity),
            overrideValue(overrides, "depthEnabled", theme.lyricsDepthEnabled),
            overrideValue(overrides, "depthIntensity", theme.lyricsDepthIntensity),
            overrideValue(overrides, "fogEnabled", theme.lyricsFogEnabled),
            overrideValue(overrides, "fogIntensity", theme.lyricsFogIntensity),
            overrideValue(overrides, "maskFeather", theme.lyricsMaskFeather),
            true
        )
    }

    function lyricsPreviewWords() {
        const words = ["A", "MÚSICA", "MOVE", "O", "DESKTOP"]
        const mode = theme ? theme.lyricsRevealMode : "progressive"
        if (mode === "current")
            return ["MÚSICA"]
        if (mode === "line")
            return words
        return words.slice(0, 2)
    }

    function lyricsPreviewSourceIndex(index) {
        return theme && theme.lyricsRevealMode === "current" ? 1 : index
    }

    function lyricsPreviewColor(index) {
        if (!theme)
            return primaryText
        if (theme.lyricsColorMode === "manual")
            return theme.lyricsManualColor
        if (theme.lyricsColorMode === "palette" && theme.lyricsPalette && theme.lyricsPalette.length > 0)
            return theme.lyricsPalette[index % theme.lyricsPalette.length]
        return theme.lyricsPywalColor
    }

    function selectLyricsLayout(layoutId) {
        if (layoutId === "two" && theme && theme.lyricsLayoutMode !== "two") {
            updateLyrics({ layout: "two", posX: 8, posY: 11, pos2X: 72, pos2Y: 10, revealMode: "progressive" })
            return
        }
        if (layoutId === "four" && theme && theme.lyricsLayoutMode !== "four") {
            ui.selectBlock(0)
            updateLyrics({ layout: "four", posX: 8, posY: 11, pos2X: 72, pos2Y: 10, revealMode: "progressive" })
            theme.applyLyricsBlocksSettings(8, 58, 72, 58, theme.lyricsBlockStyleData, true)
            return
        }
        updateLyrics({ layout: layoutId })
    }

    function lyricsBlockCount() {
        if (!theme)
            return 1
        return theme.lyricsLayoutMode === "four" ? 4 : (theme.lyricsLayoutMode === "two" ? 2 : 1)
    }

    function clampSelectedLyricsBlock() {
        return Math.max(0, Math.min(lyricsBlockCount() - 1, selectedLyricsBlock))
    }

    function selectedLyricsBlockX() {
        const block = clampSelectedLyricsBlock()
        if (block === 1)
            return theme ? theme.lyricsSecondPositionX : 72
        if (block === 2)
            return theme ? theme.lyricsThirdPositionX : 8
        if (block === 3)
            return theme ? theme.lyricsFourthPositionX : 72
        return theme ? theme.lyricsPositionX : 8
    }

    function selectedLyricsBlockY() {
        const block = clampSelectedLyricsBlock()
        if (block === 1)
            return theme ? theme.lyricsSecondPositionY : 10
        if (block === 2)
            return theme ? theme.lyricsThirdPositionY : 58
        if (block === 3)
            return theme ? theme.lyricsFourthPositionY : 58
        return theme ? theme.lyricsPositionY : 11
    }

    function updateSelectedLyricsBlockPosition(axis, value) {
        if (!theme)
            return
        const block = clampSelectedLyricsBlock()
        if (block === 0)
            updateLyrics(axis === "x" ? { posX: value } : { posY: value })
        else if (block === 1)
            updateLyrics(axis === "x" ? { pos2X: value } : { pos2Y: value })
        else {
            const pos3X = block === 2 && axis === "x" ? value : theme.lyricsThirdPositionX
            const pos3Y = block === 2 && axis === "y" ? value : theme.lyricsThirdPositionY
            const pos4X = block === 3 && axis === "x" ? value : theme.lyricsFourthPositionX
            const pos4Y = block === 3 && axis === "y" ? value : theme.lyricsFourthPositionY
            theme.applyLyricsBlocksSettings(pos3X, pos3Y, pos4X, pos4Y, theme.lyricsBlockStyleData, true)
        }
    }

    function updateSelectedLyricsBlockStyle(overrides) {
        if (!theme)
            return
        const block = clampSelectedLyricsBlock()
        theme.applyLyricsBlockStyle(
            block,
            overrideValue(overrides, "colorMode", theme.lyricsBlockColorMode(block)),
            overrideValue(overrides, "manualColor", theme.lyricsBlockManualColor(block)),
            overrideValue(overrides, "glowMode", theme.lyricsBlockGlowMode(block)),
            overrideValue(overrides, "glowIntensity", theme.lyricsBlockGlowIntensity(block)),
            true
        )
    }






    component SectionTitle: Text {
        width: parent ? parent.width : implicitWidth
        required property string label
        text: label; color: ui.secondaryText
        font.family: ui.uiFont; font.pixelSize: 10; font.weight: Font.DemiBold; font.letterSpacing: .7
    }
    component Divider: Rectangle { implicitHeight: 1; color: ui.lineColor; opacity: .5 }
    component ChoiceButton: VeloraSettingsChoice {
        theme: ui.styleTheme; motion: ui.motion
        property bool compact: false
    }
    component ToggleRow: Item {
        id: row
        property string label: ""
        property string hint: ""
        property bool checked: false
        signal toggled()
        implicitHeight: Math.max(54, caption.implicitHeight+20)
        Column {
            id: caption
            anchors.left: parent.left; anchors.right: toggle.left; anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter; spacing: 5
            Text { width: parent.width; text: row.label; color: ui.primaryText; font.family: ui.uiFont; font.pixelSize: 12; wrapMode: Text.WordWrap }
            Text { width: parent.width; text: row.hint; visible: text.length>0; color: ui.secondaryText; font.family: ui.uiFont; font.pixelSize: 10; wrapMode: Text.WordWrap }
        }
        VeloraSettingsSwitch {
            id: toggle; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            width: 42; theme: ui.styleTheme; motion: ui.motion; label: row.label; hint: row.hint; checked: row.checked
            onTriggered: row.toggled()
        }
    }
    component SettingSlider: Rectangle {
        id: field
        property string label: ""
        property var settingIds: []
        property string hint: ""
        property real minimum: 0
        property real maximum: 1
        property real value: 0
        property string valueText: Math.round(slider.value*100)+"%"
        signal valueRequested(real newValue)
        implicitHeight: 96
        radius: 14; color: ui.styleTheme.withAlpha(ui.primaryText,.025)
        opacity: enabled ? 1 : .45
        Text {
            x: 14; y: 12; width: Math.max(0,parent.width-90)
            text: field.label; color: ui.primaryText; font.family: ui.uiFont; font.pixelSize: 12
            elide: Text.ElideRight
        }
        Text {
            x: parent.width-width-14; y: 13
            text: field.valueText; color: ui.accent; font.family: ui.uiFont; font.pixelSize: 11
        }
        Text {
            x: 14; y: 34; width: parent.width-28
            text: field.hint; color: ui.secondaryText; font.family: ui.uiFont; font.pixelSize: 10
            elide: Text.ElideRight
        }
        VeloraMotionSlider {
            id: slider; objectName: "settingsSlider"
            x: 10; y: 59; width: Math.min(184,parent.width-20); height: 28
            from: field.minimum; to: field.maximum; value: field.value
            ink: ui.primaryText; accent: ui.accent; reducedMotion: ui.motion.reduced
            handleSize: 11; trackHeight: 3
            Accessible.name: field.label; Accessible.description: field.hint
            onMoved: field.valueRequested(value)
        }
    }
    component TextInputRow: Item {
        id: inputRow

        property string label: ""
        property string hint: ""
        property string value: ""
        signal valueSubmitted(string newValue)

        implicitHeight: hint.length > 0 ? 76 : 62

        Column {
            anchors.left: parent.left
            anchors.right: inputBox.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                width: parent.width
                text: inputRow.label
                color: ui.primaryText
                font.family: ui.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                visible: inputRow.hint.length > 0
                text: inputRow.hint
                color: ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        Rectangle {
            id: inputBox
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 126
            height: 38
            radius: 9
            color: ui.inputColor
            border.width: 1
            border.color: colorInput.activeFocus ? ui.accent : ui.lineColor

            TextInput {
                id: colorInput
                Accessible.name: inputRow.label
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                text: inputRow.value
                color: ui.primaryText
                selectionColor: ui.theme.withAlpha(ui.accent, 0.45)
                selectedTextColor: ui.primaryText
                font.family: ui.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                clip: true

                onEditingFinished: inputRow.valueSubmitted(text)
                Keys.onReturnPressed: {
                    inputRow.valueSubmitted(text)
                    focus = false
                }
                Keys.onEnterPressed: {
                    inputRow.valueSubmitted(text)
                    focus = false
                }
            }
        }
    }

    Component { id: audioPage; Column {
        width: parent ? parent.width : 500; spacing: 12
        Text {
            width: parent.width; visible: !ui.hasAudio
            text: "Nenhuma saída de áudio disponível."
            color: ui.secondaryText; font.family: ui.uiFont; font.pixelSize: 11
        }
        Flow {
            width: parent.width; spacing: 16
            SettingSlider {
                objectName: "settingsInlineVolume"; width: ui.fieldWidth
                label: "Volume de saída"; hint: "Ajuste o volume desta saída."
                enabled: ui.hasAudio
                value: ui.hasAudio ? Math.min(1,ui.audioSink.audio.volume) : 0
                onValueRequested: value => {
                    if (!ui.hasAudio) return
                    ui.audioSink.audio.volume=value
                    if (value>0) ui.audioSink.audio.muted=false
                }
            }
            ToggleRow {
                objectName: "settingsInlineMute"; width: ui.fieldWidth; implicitHeight: 96
                label: "Silenciar saída"; hint: "Interrompe o som sem perder o volume escolhido."
                enabled: ui.hasAudio; checked: ui.hasAudio && ui.audioSink.audio.muted
                onToggled: if (ui.hasAudio) ui.audioSink.audio.muted=!ui.audioSink.audio.muted
            }
        }
    } }

    Component { id: lyricsPlayback; Column { width: parent ? parent.width : 400; spacing: 12

            ToggleRow {
                width: parent.width
                objectName: "lyrics.enabled"; label: "Ativar lyrics"
                hint: "Mostra a letra atual integrada ao wallpaper"
                checked: ui.theme ? ui.theme.lyricsEnabled : false
                onToggled: ui.updateLyrics({ enabled: !(ui.theme && ui.theme.lyricsEnabled) })
            }



            Rectangle {
                width: parent.width; height: 96; radius: 18
                color: ui.styleTheme.withAlpha(ui.styleTheme.textPrimary,.035)
                border.color: ui.styleTheme.borderSubtle
                Column {
                    anchors.fill: parent; anchors.margins: 16; spacing: 10
                    Text { text: "Prévia das letras"; color: ui.secondaryText; font.family: ui.uiFont; font.pixelSize: 10 }
                    Text {
                        width: parent.width
                        text: ui.lyricsPreviewWords().join(" · ")
                        color: ui.lyricsPreviewColor(1)
                        opacity: ui.theme ? ui.theme.lyricsOpacity : .86
                        font.family: ui.uiFont; font.pixelSize: 22; font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                }
            }

            Divider { width: parent.width }
            SectionTitle { label: "REVELAÇÃO DAS PALAVRAS" }

            Flow {
                width: parent.width
                spacing: 8

                Repeater {
                    model: [
                        { id: "progressive", icon: "article", label: "Progressivo" },
                        { id: "line", icon: "article", label: "Linha" },
                        { id: "current", icon: "music_note", label: "Atual" }
                    ]

                    ChoiceButton {
                        required property var modelData
                        width: Math.min(164,(parent.width - 16) / 3)
                        compact: true
                        label: modelData.label
                        iconName: modelData.icon
                        active: ui.theme && ui.theme.lyricsRevealMode === modelData.id
                        onClicked: ui.updateLyrics({ revealMode: modelData.id })
                    }
                }
            }

            SettingSlider {
                width: ui.fieldWidth
                objectName: "lyrics.sync"; label: "Sincronia"
                hint: "Use negativo para atrasar, positivo para adiantar"
                minimum: -3000
                maximum: 3000
                value: ui.theme ? ui.theme.lyricsSyncOffsetMs : 460
                valueText: (value > 0 ? "+" : "") + Math.round(value) + "ms"
                onValueRequested: function(newValue) { ui.updateLyrics({ syncOffsetMs: newValue }) }
            }

            ToggleRow {
                width: parent.width
                objectName: "lyrics.active-word"; label: "Palavra ativa"
                hint: "Destaca a palavra sincronizada atual"
                checked: ui.theme ? ui.theme.lyricsActiveWordEnabled : true
                onToggled: ui.updateLyrics({ activeWord: !(ui.theme && ui.theme.lyricsActiveWordEnabled) })
            }

    } }

    Component { id: lyricsLayout; Column { width: parent ? parent.width : 400; spacing: 12
            SectionTitle { label: "LAYOUT" }

            Flow {
                width: parent.width
                spacing: 8

                Repeater {
                    model: [
                        { id: "simple", icon: "music_note", label: "Simples" },
                        { id: "vertical", icon: "workspaces", label: "Vertical" },
                        { id: "cascade", icon: "apps", label: "Cascata" },
                        { id: "centered", icon: "grid", label: "Centro" },
                        { id: "two", icon: "workspaces", label: "Dois lados" },
                        { id: "four", icon: "grid", label: "4 lyrics" }
                    ]

                    ChoiceButton {
                        required property var modelData
                        width: Math.min(196,(parent.width - 8) / 2)
                        compact: true
                        label: modelData.label
                        iconName: modelData.icon
                        active: ui.theme && ui.theme.lyricsLayoutMode === modelData.id
                        onClicked: ui.selectLyricsLayout(modelData.id)
                    }
                }
            }

    } }

    Component { id: lyricsMovement; Column { width: parent ? parent.width : 400; spacing: 12
            SectionTitle { label: "FLUTUAÇÃO" }

            ToggleRow {
                width: parent.width
                objectName: "lyrics.float"; label: "Flutuação"
                hint: "Movimento suave nas palavras"
                checked: ui.theme ? ui.theme.lyricsFloatEnabled : true
                onToggled: ui.updateLyrics({ floatEnabled: !(ui.theme && ui.theme.lyricsFloatEnabled) })
            }

            SettingSlider {
                width: ui.fieldWidth
                visible: ui.theme ? ui.theme.lyricsFloatEnabled : true
                height: visible ? implicitHeight : 0
                objectName: "lyrics.float-strength"; label: "Força da flutuação"
                hint: "Deslocamento suave em pixels"
                minimum: 0
                maximum: 24
                value: ui.theme ? ui.theme.lyricsFloatIntensity : 5
                valueText: Math.round(value) + "px"
                onValueRequested: function(newValue) { ui.updateLyrics({ floatIntensity: newValue }) }
            }

    } }

    Component { id: lyricsPosition; Flow { width: parent ? parent.width : 400; spacing: 16
            SectionTitle { label: "POSIÇÃO" }

            Column {
                width: parent.width; spacing: 8
                visible: ui.lyricsBlockCount()>1
                height: visible ? implicitHeight : 0
                Flow {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: ui.lyricsBlockCount()

                        ChoiceButton {
                            required property int index
                            width: Math.min(196,(parent.width - 8) / 2)
                            compact: true
                            label: "Bloco " + (index + 1)
                            iconName: "grid"
                            active: ui.selectedLyricsBlock === index
                            onClicked: ui.selectBlock(index)
                        }
                    }
                }

            }
                SettingSlider {
                    width: ui.fieldWidth
                    objectName: "lyrics.x"
                    settingIds: ["lyrics.block-x"].concat(ui.lyricsBlockCount()>1 && ui.selectedLyricsBlock===1 ? ["lyrics.x2"] : [])
                    label: ui.lyricsBlockCount()>1 ? "Bloco X" : "Posição X"
                    hint: "Posição horizontal do bloco selecionado"
                    minimum: 0
                    maximum: 100
                    value: ui.selectedLyricsBlockX()
                    valueText: Math.round(value) + "%"
                    onValueRequested: function(newValue) { ui.updateSelectedLyricsBlockPosition("x", newValue) }
                }

                SettingSlider {
                    width: ui.fieldWidth
                    objectName: "lyrics.y"
                    settingIds: ["lyrics.block-y"].concat(ui.lyricsBlockCount()>1 && ui.selectedLyricsBlock===1 ? ["lyrics.y2"] : [])
                    label: ui.lyricsBlockCount()>1 ? "Bloco Y" : "Posição Y"
                    hint: "Posição vertical do bloco selecionado"
                    minimum: 0
                    maximum: 100
                    value: ui.selectedLyricsBlockY()
                    valueText: Math.round(value) + "%"
                    onValueRequested: function(newValue) { ui.updateSelectedLyricsBlockPosition("y", newValue) }
                }

            Divider { width: parent.width }
            SectionTitle { label: "TRANSFORMAR" }

            SettingSlider {
                width: ui.fieldWidth
                objectName: "lyrics.scale"; label: "Escala"
                hint: "Redimensiona o bloco de lyrics"
                minimum: 0.35
                maximum: 2.50
                value: ui.theme ? ui.theme.lyricsScale : 1
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) { ui.updateLyricsTransform({ scale: newValue }) }
            }

            SettingSlider {
                width: ui.fieldWidth
                objectName: "lyrics.rotation"; label: "Rotação"
                hint: "Inclinação plana da lyrics"
                minimum: -60
                maximum: 60
                value: ui.theme ? ui.theme.lyricsRotation : 0
                valueText: Math.round(value) + "°"
                onValueRequested: function(newValue) { ui.updateLyricsTransform({ rotation: newValue }) }
            }

            SettingSlider {
                width: ui.fieldWidth
                objectName: "lyrics.tilt-x"; label: "Perspectiva X"
                hint: "Dobra a lyrics para cima ou para baixo"
                minimum: -70
                maximum: 70
                value: ui.theme ? ui.theme.lyricsTiltX : 0
                valueText: Math.round(value) + "°"
                onValueRequested: function(newValue) { ui.updateLyricsTransform({ tiltX: newValue }) }
            }

            SettingSlider {
                width: ui.fieldWidth
                objectName: "lyrics.tilt-y"; label: "Perspectiva Y"
                hint: "Dobra a lyrics para esquerda ou direita"
                minimum: -70
                maximum: 70
                value: ui.theme ? ui.theme.lyricsTiltY : 0
                valueText: Math.round(value) + "°"
                onValueRequested: function(newValue) { ui.updateLyricsTransform({ tiltY: newValue }) }
            }

            ChoiceButton {
                width: Math.min(parent.width,234)
                objectName: "lyrics.transform-reset"
                checkable: false; label: "Resetar transformação"; iconName: "refresh"
                active: false
                onClicked: if (ui.theme) ui.theme.resetLyricsTransformSettings()
            }

            Divider { width: parent.width }

    } }

    Component { id: lyricsStyle; Flow { width: parent ? parent.width : 400; spacing: 16
            SectionTitle { label: "COR" }

            Flow {
                width: parent.width
                spacing: 8

                ChoiceButton {
                    width: Math.min(164,(parent.width - 16) / 3)
                    label: "Pywal"; iconName: "wallpaper"
                    active: ui.theme && ui.theme.lyricsColorMode === "pywal"
                    onClicked: ui.updateLyrics({ colorMode: "pywal" })
                }

                ChoiceButton {
                    width: Math.min(164,(parent.width - 16) / 3)
                    label: "Paleta"; iconName: "palette"
                    active: ui.theme && ui.theme.lyricsColorMode === "palette"
                    onClicked: ui.updateLyrics({ colorMode: "palette" })
                }

                ChoiceButton {
                    width: Math.min(164,(parent.width - 16) / 3)
                    label: "Manual"; iconName: "paint"
                    active: ui.theme && ui.theme.lyricsColorMode === "manual"
                    onClicked: ui.updateLyrics({ colorMode: "manual" })
                }
            }

            TextInputRow {
                width: parent.width
                visible: ui.theme && ui.theme.lyricsColorMode === "manual"
                height: visible ? implicitHeight : 0
                objectName: "lyrics.manual-color"; label: "Cor manual"
                hint: "Hexadecimal, ex: #f5f7ff"
                value: ui.theme ? ui.theme.lyricsManualColor : "#f5f7ff"
                onValueSubmitted: function(newValue) { ui.updateLyrics({ manualColor: newValue, colorMode: "manual" }) }
            }

            Divider { width: parent.width }
            SectionTitle { label: "TIPOGRAFIA" }

            SettingSlider {
                width: ui.fieldWidth
                objectName: "lyrics.font-size"; label: "Tamanho"
                hint: "Tamanho da palavra no wallpaper"
                minimum: 24
                maximum: 180
                value: ui.theme ? ui.theme.lyricsFontSize : 86
                valueText: Math.round(value) + "px"
                onValueRequested: function(newValue) { ui.updateLyrics({ fontSize: newValue }) }
            }

            SettingSlider {
                width: ui.fieldWidth
                objectName: "lyrics.spacing"; label: "Espaçamento"
                hint: "Distância entre palavras"
                minimum: 0
                maximum: 48
                value: ui.theme ? ui.theme.lyricsWordSpacing : 8
                valueText: Math.round(value) + "px"
                onValueRequested: function(newValue) { ui.updateLyrics({ spacing: newValue }) }
            }

            SettingSlider {
                width: ui.fieldWidth
                objectName: "lyrics.opacity"; label: "Opacidade"
                hint: "Transparência das lyrics"
                minimum: 0.15
                maximum: 1.0
                value: ui.theme ? ui.theme.lyricsOpacity : 0.86
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) { ui.updateLyrics({ opacity: newValue }) }
            }

            ToggleRow {
                width: parent.width
                objectName: "lyrics.uppercase"; label: "Caixa alta"
                hint: "Transforma a linha em palavras maiúsculas"
                checked: ui.theme ? ui.theme.lyricsUppercase : true
                onToggled: ui.updateLyrics({ uppercase: !(ui.theme && ui.theme.lyricsUppercase) })
            }

            ToggleRow {
                width: parent.width
                objectName: "lyrics.shadow"; label: "Sombra"
                hint: "Melhora leitura sobre wallpapers claros"
                checked: ui.theme ? ui.theme.lyricsShadowEnabled : true
                onToggled: ui.updateLyrics({ shadow: !(ui.theme && ui.theme.lyricsShadowEnabled) })
            }

            ToggleRow {
                width: parent.width
                objectName: "lyrics.glow"; label: "Glow"
                hint: "Brilho suave para wallpapers escuros"
                checked: ui.theme ? ui.theme.lyricsGlowEnabled : true
                onToggled: ui.updateLyrics({ glowEnabled: !(ui.theme && ui.theme.lyricsGlowEnabled) })
            }

            SettingSlider {
                width: ui.fieldWidth
                visible: ui.theme ? ui.theme.lyricsGlowEnabled : true
                height: visible ? implicitHeight : 0
                objectName: "lyrics.glow-strength"; label: "Força do glow"
                hint: "Intensidade do brilho ao redor da letra"
                minimum: 0
                maximum: 1
                value: ui.theme ? ui.theme.lyricsGlowIntensity : 0.45
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) { ui.updateLyrics({ glowIntensity: newValue }) }
            }

            Divider { width: parent.width }

            Column {
                width: parent.width; spacing: 10
                visible: ui.lyricsBlockCount()>1
                height: visible ? implicitHeight : 0
                SectionTitle { label: "ESTILO POR BLOCO" }
                Flow {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: ui.lyricsBlockCount()

                        ChoiceButton {
                            required property int index
                            width: Math.min(196,(parent.width - 8) / 2)
                            compact: true
                            label: "Bloco " + (index + 1)
                            iconName: "grid"
                            active: ui.selectedLyricsBlock === index
                            onClicked: ui.selectBlock(index)
                        }
                    }
                }

                Flow {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: [
                            { id: "inherit", icon: "refresh", label: "Cor geral" },
                            { id: "pywal", icon: "wallpaper", label: "Pywal" },
                            { id: "palette", icon: "palette", label: "Paleta" },
                            { id: "manual", icon: "paint", label: "Manual" }
                        ]

                        ChoiceButton {
                            required property var modelData
                            width: Math.min(196,(parent.width - 8) / 2)
                            compact: true
                            label: modelData.label
                        iconName: modelData.icon
                            active: ui.theme && ui.theme.lyricsBlockColorMode(ui.selectedLyricsBlock) === modelData.id
                            onClicked: ui.updateSelectedLyricsBlockStyle({ colorMode: modelData.id })
                        }
                    }
                }

                TextInputRow {
                    width: parent.width
                    visible: ui.theme && ui.theme.lyricsBlockColorMode(ui.selectedLyricsBlock) === "manual"
                    height: visible ? implicitHeight : 0
                    objectName: "lyrics.block-color"; label: "Cor do bloco"
                    hint: "Hexadecimal do bloco selecionado"
                    value: ui.theme ? ui.theme.lyricsBlockManualColor(ui.selectedLyricsBlock) : "#f5f7ff"
                    onValueSubmitted: function(newValue) { ui.updateSelectedLyricsBlockStyle({ colorMode: "manual", manualColor: newValue }) }
                }

                Flow {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: [
                            { id: "inherit", icon: "refresh", label: "Glow geral" },
                            { id: "on", icon: "spark", label: "Glow ON" },
                            { id: "off", icon: "close", label: "Glow OFF" }
                        ]

                        ChoiceButton {
                            required property var modelData
                            width: Math.min(164,(parent.width - 16) / 3)
                            compact: true
                            label: modelData.label
                        iconName: modelData.icon
                            active: ui.theme && ui.theme.lyricsBlockGlowMode(ui.selectedLyricsBlock) === modelData.id
                            onClicked: ui.updateSelectedLyricsBlockStyle({ glowMode: modelData.id })
                        }
                    }
                }

                SettingSlider {
                    width: ui.fieldWidth
                    objectName: "lyrics.block-glow"; label: "Glow do bloco"
                    hint: "Intensidade individual do brilho"
                    minimum: 0
                    maximum: 1
                    value: ui.theme ? ui.theme.lyricsBlockGlowIntensity(ui.selectedLyricsBlock) : 0.45
                    valueText: Math.round(value * 100) + "%"
                    onValueRequested: function(newValue) { ui.updateSelectedLyricsBlockStyle({ glowIntensity: newValue }) }
                }
            }

    } }

    Component { id: lyricsMaterial; Column { width: parent ? parent.width : 400; spacing: 12
            SectionTitle { label: "MATERIAL" }

            Flow {
                width: parent.width
                spacing: 8

                Repeater {
                    model: [
                        { id: "off", icon: "close", label: "Sem material" },
                        { id: "cloud", icon: "cloud", label: "Nuvem" },
                        { id: "glass", icon: "water_drop", label: "Vidro" },
                        { id: "metal", icon: "apps", label: "Metal" },
                        { id: "sky", icon: "suncloud", label: "Céu" }
                    ]

                    ChoiceButton {
                        required property var modelData
                        width: Math.min(164,(parent.width - 16) / 3)
                        compact: true
                        label: modelData.label
                        iconName: modelData.icon
                        active: ui.theme && ui.theme.lyricsMaterialMode === modelData.id
                        onClicked: ui.updateLyricsMaterial({ mode: modelData.id })
                    }
                }
            }

            SettingSlider {
                width: ui.fieldWidth
                visible: ui.theme ? ui.theme.lyricsMaterialMode !== "off" : false
                height: visible ? implicitHeight : 0
                objectName: "lyrics.texture"; label: "Textura"
                hint: "Mistura a cor da letra com o material escolhido"
                minimum: 0
                maximum: 1
                value: ui.theme ? ui.theme.lyricsMaterialIntensity : 0.55
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) { ui.updateLyricsMaterial({ intensity: newValue }) }
            }

            ToggleRow {
                width: parent.width
                objectName: "lyrics.depth"; label: "Profundidade"
                hint: "Borda e sombra ambiental para integrar no wallpaper"
                checked: ui.theme ? ui.theme.lyricsDepthEnabled : false
                onToggled: ui.updateLyricsMaterial({ depthEnabled: !(ui.theme && ui.theme.lyricsDepthEnabled) })
            }

            SettingSlider {
                width: ui.fieldWidth
                visible: ui.theme ? ui.theme.lyricsDepthEnabled : false
                height: visible ? implicitHeight : 0
                objectName: "lyrics.depth-strength"; label: "Força da profundidade"
                hint: "Intensidade do relevo e sombra direcional"
                minimum: 0
                maximum: 1
                value: ui.theme ? ui.theme.lyricsDepthIntensity : 0.45
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) { ui.updateLyricsMaterial({ depthIntensity: newValue }) }
            }

            ToggleRow {
                width: parent.width
                objectName: "lyrics.fog"; label: "Névoa"
                hint: "Reduz contraste para parecer mais distante"
                checked: ui.theme ? ui.theme.lyricsFogEnabled : false
                onToggled: ui.updateLyricsMaterial({ fogEnabled: !(ui.theme && ui.theme.lyricsFogEnabled) })
            }

            SettingSlider {
                width: ui.fieldWidth
                visible: ui.theme ? ui.theme.lyricsFogEnabled : false
                height: visible ? implicitHeight : 0
                objectName: "lyrics.fog-strength"; label: "Força da névoa"
                hint: "Quanto a letra se mistura com o ar do wallpaper"
                minimum: 0
                maximum: 1
                value: ui.theme ? ui.theme.lyricsFogIntensity : 0.35
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) { ui.updateLyricsMaterial({ fogIntensity: newValue }) }
            }

            ToggleRow {
                width: parent.width
                objectName: "lyrics.mask"; label: "Máscara manual"
                hint: "Recorta a letra nas áreas desenhadas"
                checked: ui.theme ? ui.theme.lyricsMaskEnabled : false
                onToggled: if (ui.theme) ui.theme.applyLyricsMaskSettings(!ui.theme.lyricsMaskEnabled, ui.theme.lyricsMaskBrushSize, ui.theme.lyricsMaskData, true)
            }

            SettingSlider {
                width: ui.fieldWidth
                visible: ui.theme ? ui.theme.lyricsMaskEnabled : false
                height: visible ? implicitHeight : 0
                objectName: "lyrics.brush"; label: "Tamanho do pincel"
                hint: "Largura usada para pintar a área de recorte"
                minimum: 6
                maximum: 180
                value: ui.theme ? ui.theme.lyricsMaskBrushSize : 56
                valueText: Math.round(value) + "px"
                onValueRequested: function(newValue) {
                    if (ui.theme)
                        ui.theme.applyLyricsMaskSettings(ui.theme.lyricsMaskEnabled, newValue, ui.theme.lyricsMaskData, true)
                }
            }

            SettingSlider {
                width: ui.fieldWidth
                visible: ui.theme ? ui.theme.lyricsMaskEnabled : false
                height: visible ? implicitHeight : 0
                objectName: "lyrics.feather"; label: "Suavização da máscara"
                hint: "Feather na borda do recorte manual"
                minimum: 0
                maximum: 80
                value: ui.theme ? ui.theme.lyricsMaskFeather : 0
                valueText: Math.round(value) + "px"
                onValueRequested: function(newValue) { ui.updateLyricsMaterial({ maskFeather: newValue }) }
            }

            Flow {
                width: parent.width
                visible: ui.theme ? ui.theme.lyricsMaskEnabled : false
                height: visible ? implicitHeight : 0
                spacing: 8

                ChoiceButton {
                    width: Math.min(196,(parent.width - 8) / 2)
                    objectName: "lyrics.mask-edit"; label: "Editar máscara"; iconName: "edit"
                    active: ui.theme && ui.theme.lyricsMaskHasStrokes
                    onClicked: if (ui.controller) ui.controller.lyricsMaskEditorRequested()
                }

                ChoiceButton {
                    width: Math.min(196,(parent.width - 8) / 2)
                    objectName: "lyrics.mask-clear"; label: "Limpar"; iconName: "close"
                    active: false
                    onClicked: if (ui.theme) ui.theme.clearLyricsMask(true)
                }
            }

            Divider { width: parent.width }

    } }


    Component {
        id: velyricsPage

        Column {
            spacing: 10

            SectionTitle { label: "VELYRICS" }

            Text {
                width: parent.width
                text: "Letras em terminais, separadas das letras no wallpaper. Com a Infinite Desk ativa, a câmera pode acompanhar os terminais flutuantes."
                color: ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }

            ToggleRow {
                width: parent.width
                objectName: "velyrics.group"; label: "Agrupar por palavras"
                hint: "Desligado usa uma linha completa por terminal"
                checked: ui.controller ? ui.controller.velyricsMode === "words" : false
                onToggled: if (ui.controller) ui.controller.setVelyricsMode(ui.controller.velyricsMode === "words" ? "line" : "words")
            }

            SettingSlider {
                width: ui.fieldWidth
                visible: ui.controller ? ui.controller.velyricsMode === "words" : false
                height: visible ? implicitHeight : 0
                objectName: "velyrics.words"; label: "Palavras por terminal"
                hint: "Troca o texto quando começa o próximo grupo"
                minimum: 1
                maximum: 12
                value: ui.controller ? ui.controller.velyricsWordsPerTerminal : 4
                valueText: Math.round(value) + (Math.round(value) === 1 ? " palavra" : " palavras")
                onValueRequested: function(newValue) { if (ui.controller) ui.controller.setVelyricsWordsPerTerminal(newValue) }
            }

            Divider { width: parent.width }
            SectionTitle { label: "SINCRONISMO" }

            SettingSlider {
                width: ui.fieldWidth
                objectName: "velyrics.sync"; label: "Sincronismo do terminal"
                hint: "Antecipa a troca das linhas em relação ao Spotify"
                minimum: 0
                maximum: 1500
                value: ui.controller ? ui.controller.velyricsSyncOffsetMs : 500
                valueText: Math.round(value) + " ms"
                onValueRequested: function(newValue) { if (ui.controller) ui.controller.setVelyricsSyncOffset(newValue) }
            }

            Divider { width: parent.width }
            SectionTitle { label: "TIPOGRAFIA" }

            SettingSlider {
                width: ui.fieldWidth
                objectName: "velyrics.font-scale"; label: "Tamanho da fonte"
                hint: "Escala a fonte escolhida dentro de cada terminal"
                minimum: 0.5
                maximum: 3.0
                value: ui.controller ? ui.controller.velyricsFontScale : 1.0
                valueText: Math.round(value * 100) + "%"
                onValueRequested: function(newValue) { if (ui.controller) ui.controller.setVelyricsFontScale(newValue) }
            }

            Text {
                width: parent.width
                text: "Fonte · " + (ui.controller ? ui.controller.velyricsFontFamily : "Pixelon")
                color: ui.primaryText
                font.family: ui.uiFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Rectangle {
                width: parent.width
                height: 38
                radius: 9
                color: ui.theme.withAlpha(ui.theme.surfaceButton, 0.76)
                border.width: 1
                border.color: fontSearch.activeFocus ? ui.theme.withAlpha(ui.accent, 0.68) : ui.theme.withAlpha(ui.theme.borderSoft, 0.32)

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    visible: fontSearch.text.length <= 0
                    text: "Buscar entre as fontes do sistema…"
                    color: ui.secondaryText
                    font.family: ui.uiFont
                    font.pixelSize: 10
                }

                TextInput {
                    id: fontSearch
                    objectName: "velyrics.font-search"
                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 12
                    }
                    verticalAlignment: TextInput.AlignVCenter
                    text: ui.controller ? ui.controller.velyricsFontSearch : ""
                    color: ui.primaryText
                    selectionColor: ui.theme.withAlpha(ui.accent, 0.42)
                    selectedTextColor: ui.primaryText
                    font.family: ui.uiFont
                    font.pixelSize: 11
                    clip: true
                    onTextEdited: if (ui.controller) ui.controller.setVelyricsFontSearch(text)
                }
            }

            Rectangle {
                width: parent.width
                height: 158
                radius: 10
                color: ui.theme.withAlpha(ui.theme.surfaceButton, 0.44)
                border.width: 1
                border.color: ui.theme.withAlpha(ui.theme.borderSoft, 0.26)
                clip: true

                ListView {
                    id: fontList
                    objectName: "velyrics.font"
                    anchors {
                        fill: parent
                        margins: 4
                    }
                    spacing: 2
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: ui.controller ? ui.controller.filteredVelyricsFonts() : ["Pixelon"]

                    delegate: Rectangle {
                        id: fontOption
                        required property var modelData
                        readonly property string familyName: String(modelData)
                        width: fontList.width
                        height: 31
                        radius: 7
                        color: ui.controller && ui.controller.velyricsFontFamily === familyName
                            ? ui.theme.withAlpha(ui.accent, 0.22)
                            : (fontMouse.containsMouse ? ui.theme.withAlpha(ui.theme.surfaceCard, 0.42) : "transparent")

                        Text {
                            anchors {
                                left: parent.left
                                right: parent.right
                                leftMargin: 9
                                rightMargin: 9
                                verticalCenter: parent.verticalCenter
                            }
                            text: fontOption.familyName
                            color: ui.primaryText
                            font.family: fontOption.familyName
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: fontMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (ui.controller) ui.controller.setVelyricsFontFamily(fontOption.familyName)
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 128
                radius: 12
                color: ui.theme.withAlpha(ui.accent, 0.10)
                border.width: 1
                border.color: ui.theme.withAlpha(ui.accent, 0.28)
                clip: true

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 28
                    text: ui.controller && ui.controller.velyricsMode === "words" ? "VELORA LYRICS FLOW" : "THE MUSIC MOVES THROUGH THE DESKTOP"
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    color: ui.theme ? ui.theme.lyricsPywalColor : ui.primaryText
                    font.family: ui.controller ? ui.controller.velyricsFontFamily : "Pixelon"
                    font.pixelSize: Math.max(18, Math.min(52, 25 * (ui.controller ? ui.controller.velyricsFontScale : 1.0)))
                }
            }

            Text {
                width: parent.width
                text: "As alterações são aplicadas à sessão ativa sem reiniciar o Spotify."
                color: ui.secondaryText
                font.family: ui.uiFont
                font.pixelSize: 10
                wrapMode: Text.WordWrap
            }
        }
    }


    Loader {
        id: pageLoader; width: parent.width
        sourceComponent: ui.mediaSection === "audio" ? audioPage
            : ui.mediaSection === "position" ? lyricsPosition
            : ui.mediaSection === "style" ? lyricsStyle
            : ui.mediaSection === "layout" ? lyricsLayout
            : ui.mediaSection === "movement" ? lyricsMovement
            : ui.mediaSection === "material" ? lyricsMaterial
            : ui.mediaSection === "velyrics" ? velyricsPage : lyricsPlayback
    }
}
