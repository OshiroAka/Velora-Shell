import QtQuick
import "../lock" as Lock

Item {
    id: root

    required property bool presented
    required property var controller
    required property var config
    required property var theme
    required property var motion
    required property var profileService
    required property var editor

    property int page: 0
    property string selectedProfileId: ""
    readonly property var selectedLayer: editor.layerById(editor.selectedLayerId)
    readonly property var selectedTransform: selectedLayer ? selectedLayer.transform : ({})
    property real morphOffset: presented ? 0 : 42

    width: 530
    height: Math.min(860, parent ? parent.height - 30 : 860)
    opacity: presented ? 1 : 0
    scale: presented ? 1 : 0.985
    transformOrigin: Item.Right
    transform: Translate {
        x: root.morphOffset
        Behavior on x { NumberAnimation { duration: root.motion.morph; easing.type: Easing.OutCubic } }
    }
    Behavior on opacity { NumberAnimation { duration: root.motion.selection; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: root.motion.morph; easing.type: Easing.OutCubic } }

    function profileById(identifier) { return profileService.profileById(identifier) }
    function beginTransformGesture() {
        return editor.beginGesture(editor.selectedLayerId)
    }
    function previewTransform(field, value) {
        if (editor.gestureActive) {
            const patch = ({})
            patch[field] = value
            editor.previewTransform(editor.selectedLayerId, patch)
        } else {
            editor.setTransform(editor.selectedLayerId, field, value)
        }
    }
    function finishTransformGesture() { editor.finishGesture() }
    function chooseWallpaperForActiveProfile() {
        selectedProfileId = String(profileService.activeProfileId || "")
        if (selectedProfileId.length > 0)
            profileService.selectProfileForEditing(selectedProfileId, true)
        return controller.chooseWallpaper()
    }
    function syncProfileSelection() {
        let identifier = selectedProfileId
        if (!profileById(identifier))
            identifier = profileService.editingProfileId || profileService.activeProfileId
        if (!profileById(identifier) && profileService.profiles.length > 0)
            identifier = String(profileService.profiles[0].id)
        selectedProfileId = String(identifier || "")
        // SettingsHost is intentionally removed while Zenity owns focus. On
        // return this panel is a new QML instance, but the service still owns
        // the unsaved wallpaper draft. Re-selecting the same profile here
        // used to replace that draft with the old saved wallpaper.
        if (selectedProfileId.length > 0
                && String(profileService.editingProfileId) !== selectedProfileId)
            profileService.selectProfileForEditing(selectedProfileId)
        profileNameInput.text = profileService.draftProfileName
    }

    component ActionButton: Rectangle {
        id: button
        property string label: ""
        property bool emphasized: false
        property bool destructive: false
        signal triggered
        implicitWidth: 142; implicitHeight: 40; radius: 16
        opacity: enabled ? 1 : 0.42
        color: destructive ? Qt.rgba(0.55, 0.10, 0.16, mouse.containsMouse ? 0.66 : 0.44)
            : (emphasized ? Qt.rgba(0.50, 0.66, 1.0, mouse.containsMouse ? 0.48 : 0.34)
                : Qt.rgba(1, 1, 1, mouse.containsMouse ? 0.16 : 0.075))
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, mouse.containsMouse ? 0.44 : 0.18)
        scale: mouse.pressed ? 0.975 : 1
        Behavior on color { ColorAnimation { duration: root.motion.micro } }
        Behavior on scale { NumberAnimation { duration: root.motion.micro; easing.type: Easing.OutCubic } }
        Text { anchors.centerIn: parent; text: button.label; color: "white"; font.family: root.theme.bodyFont; font.pixelSize: 11; font.weight: Font.DemiBold }
        MouseArea { id: mouse; anchors.fill: parent; enabled: button.enabled; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: button.triggered() }
    }

    component Field: Rectangle {
        id: field
        property alias text: input.text
        property string placeholder: ""
        signal accepted(string text)
        implicitHeight: 44; radius: 15
        color: Qt.rgba(0.015, 0.035, 0.09, 0.28)
        border.width: 1
        border.color: input.activeFocus ? Qt.rgba(1, 1, 1, 0.52) : Qt.rgba(1, 1, 1, 0.16)
        Text { anchors.fill: parent; anchors.leftMargin: 14; verticalAlignment: Text.AlignVCenter; visible: input.text.length === 0 && !input.activeFocus; text: field.placeholder; color: Qt.rgba(1, 1, 1, 0.42); font.family: root.theme.bodyFont; font.pixelSize: 12 }
        TextInput { id: input; anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; verticalAlignment: TextInput.AlignVCenter; color: "white"; selectionColor: root.theme.accent; selectedTextColor: "white"; font.family: root.theme.bodyFont; font.pixelSize: 12; maximumLength: 120; onEditingFinished: field.accepted(text) }
    }

    component CompactSlider: Item {
        id: control
        property string label: ""; property string suffix: ""
        property real from: 0; property real to: 100; property real stepSize: 1; property real value: 0
        signal edited(real value)
        signal interactionStarted
        signal interactionFinished
        readonly property real ratio: Math.max(0, Math.min(1, (value - from) / Math.max(0.0001, to - from)))
        implicitHeight: 47
        function quantized(position) {
            const raw = from + Math.max(0, Math.min(1, position)) * (to - from)
            return Math.max(from, Math.min(to, Math.round(raw / stepSize) * stepSize))
        }
        Text { x: 1; text: control.label; color: Qt.rgba(1, 1, 1, 0.78); font.family: root.theme.bodyFont; font.pixelSize: 10; font.weight: Font.Medium }
        Text { anchors.right: parent.right; text: Number(control.value).toFixed(control.stepSize < 1 ? 2 : 0) + control.suffix; color: "white"; font.family: root.theme.bodyFont; font.pixelSize: 10; font.weight: Font.DemiBold }
        Rectangle {
            id: track; x: 1; y: 28; width: parent.width - 2; height: 6; radius: 3
            color: Qt.rgba(0.01, 0.03, 0.08, 0.34)
            Rectangle { width: Math.max(6, parent.width * control.ratio); height: parent.height; radius: 3; color: root.theme.accentSoft }
            Rectangle { x: Math.max(-6, Math.min(parent.width - 7, parent.width * control.ratio - 7)); anchors.verticalCenter: parent.verticalCenter; width: sliderMouse.pressed ? 16 : 14; height: width; radius: width / 2; color: "white"; border.width: 2; border.color: root.theme.accent }
            MouseArea {
                id: sliderMouse; x: -5; y: -12; width: parent.width + 10; height: 30
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor; preventStealing: true
                function update(mouseX) { control.edited(control.quantized((mouseX - 5) / track.width)) }
                onPressed: function(mouse) { control.interactionStarted(); update(mouse.x) }
                onPositionChanged: function(mouse) { if (pressed) update(mouse.x) }
                onReleased: control.interactionFinished()
                onCanceled: control.interactionFinished()
                onWheel: function(wheel) {
                    const direction = wheel.angleDelta.y >= 0 ? 1 : -1
                    control.edited(control.quantized(control.ratio + direction * control.stepSize / (control.to - control.from)))
                    wheel.accepted = true
                }
            }
        }
    }

    MouseArea { anchors.fill: parent; hoverEnabled: true }
    Rectangle { anchors.fill: parent; radius: 34; color: "transparent"; border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.30) }
    Rectangle { anchors.fill: parent; anchors.margins: 2; radius: 32; color: "transparent"; border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.09) }

    Text { x: 24; y: 18; text: "Velora Composer"; color: "white"; font.family: root.theme.bodyFont; font.pixelSize: 22; font.weight: Font.Bold }
    Text { x: 24; y: 48; text: root.editor.editSpace === "desktop" ? "Posicione os widgets no desktop vivo" : "Componha a lockscreen diretamente no canvas"; color: Qt.rgba(1, 1, 1, 0.62); font.family: root.theme.bodyFont; font.pixelSize: 10 }
    Row {
        x: 367; y: 17; spacing: 7
        ActionButton { width: 42; label: "↶"; enabled: root.editor.canUndo; onTriggered: root.editor.undo() }
        ActionButton { width: 42; label: "↷"; enabled: root.editor.canRedo; onTriggered: root.editor.redo() }
        ActionButton { width: 42; label: "×"; onTriggered: root.controller.hide() }
    }
    Row {
        x: 18; y: 82; spacing: 7
        Repeater {
            model: ["Camadas", "Conteúdo", "Perfis"]
            Rectangle {
                required property int index; required property string modelData
                width: 160; height: 39; radius: 16
                color: root.page === index ? Qt.rgba(0.62, 0.72, 1, 0.30) : Qt.rgba(1, 1, 1, tabMouse.containsMouse ? 0.12 : 0.045)
                border.width: 1; border.color: root.page === index ? Qt.rgba(1, 1, 1, 0.46) : Qt.rgba(1, 1, 1, 0.11)
                Text { anchors.centerIn: parent; text: modelData; color: "white"; font.family: root.theme.bodyFont; font.pixelSize: 11; font.weight: Font.DemiBold }
                MouseArea { id: tabMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.page = index }
            }
        }
    }

    Item {
        id: layersPage; x: 18; y: 135; width: parent.width - 36; height: parent.height - 154; visible: root.page === 0
        Row {
            width: parent.width; spacing: 8
            Text { width: parent.width - 150; anchors.verticalCenter: parent.verticalCenter; text: "Camadas da composição"; color: "white"; font.family: root.theme.bodyFont; font.pixelSize: 15; font.weight: Font.Bold }
            ActionButton { width: 142; label: "+ Adicionar imagem"; emphasized: true; enabled: root.editor.editSpace === "lock"; onTriggered: root.controller.chooseCustomImage() }
        }
        Row {
            y: 40; spacing: 8
            ActionButton { width: 241; label: "Editar Desktop"; emphasized: root.editor.editSpace === "desktop"; onTriggered: root.controller.setEditSpace("desktop") }
            ActionButton { width: 241; label: "Editar Lock"; emphasized: root.editor.editSpace === "lock"; onTriggered: root.controller.setEditSpace("lock") }
        }
        ActionButton {
            x: 0; y: 88; width: parent.width; height: 40
            label: "Trocar organização dos widgets do Desktop"
            emphasized: true
            onTriggered: {
                root.controller.setEditSpace("desktop")
                root.editor.advanceDesktopTemplate()
            }
        }
        Text {
            x: 1; y: 140
            visible: root.editor.editSpace === "desktop"
            text: "Template: " + root.config.desktopTemplateLabel(
                root.config.desktopLayoutTemplate)
            color: Qt.rgba(1, 1, 1, 0.68)
            font.family: root.theme.bodyFont
            font.pixelSize: 10
            font.weight: Font.DemiBold
        }
        Grid {
            x: 0; y: 161; columns: 2; columnSpacing: 8; rowSpacing: 7
            visible: root.editor.editSpace === "desktop"
            Repeater {
                model: [
                    { label: "Coluna", value: "side-column" },
                    { label: "Cantos", value: "split-corners" },
                    { label: "Esparso", value: "scattered" },
                    { label: "Galeria direita", value: "gallery-top-right" }
                ]
                ActionButton {
                    required property var modelData
                    width: 241; height: 34
                    label: String(modelData.label)
                    emphasized: root.config.desktopLayoutTemplate
                        === String(modelData.value)
                    onTriggered: root.editor.applyDesktopTemplate(
                        String(modelData.value))
                }
            }
        }
        Rectangle {
            id: layersCard; x: 0
            y: root.editor.editSpace === "desktop" ? 242 : 140
            width: parent.width
            height: root.editor.editSpace === "desktop"
                ? Math.min(174, parent.height * 0.25)
                : Math.min(220, parent.height * 0.31)
            radius: 22
            color: Qt.rgba(0.01, 0.03, 0.08, 0.23); border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.14); clip: true
            ListView {
                id: layersList; anchors.fill: parent; anchors.margins: 8; spacing: 5; model: root.editor.editableLayers
                boundsBehavior: Flickable.StopAtBounds; clip: true
                delegate: Rectangle {
                    id: layerRow; required property var modelData
                    width: layersList.width; height: 47; radius: 15
                    readonly property bool selected: String(modelData.id) === root.editor.selectedLayerId
                    color: selected ? Qt.rgba(0.61, 0.70, 1, 0.26) : Qt.rgba(1, 1, 1, rowMouse.containsMouse ? 0.11 : 0.04)
                    border.width: 1; border.color: selected ? Qt.rgba(1, 1, 1, 0.42) : Qt.rgba(1, 1, 1, 0.08)
                    Text { x: 14; y: 9; width: parent.width - 130; text: String(layerRow.modelData.name || layerRow.modelData.type); elide: Text.ElideRight; color: layerRow.modelData.visible ? "white" : Qt.rgba(1, 1, 1, 0.42); font.family: root.theme.bodyFont; font.pixelSize: 11; font.weight: Font.DemiBold }
                    Text { x: 14; y: 27; text: layerRow.modelData.sharedWidget ? (root.editor.editSpace === "desktop" ? "Widget do desktop" : "Widget compartilhado da lock") : (layerRow.modelData.plane === "belowPanel" ? "Atrás do painel" : "À frente do painel"); color: Qt.rgba(1, 1, 1, 0.46); font.family: root.theme.bodyFont; font.pixelSize: 8 }
                    ActionButton { x: parent.width - 91; y: 5; width: 38; height: 37; label: layerRow.modelData.visible ? "◉" : "○"; onTriggered: root.editor.updateLayer(layerRow.modelData.id, { visible: !layerRow.modelData.visible }) }
                    ActionButton { x: parent.width - 47; y: 5; width: 38; height: 37; label: layerRow.modelData.locked ? "◆" : "◇"; onTriggered: root.editor.updateLayer(layerRow.modelData.id, { locked: !layerRow.modelData.locked }) }
                    MouseArea { id: rowMouse; x: 0; y: 0; width: parent.width - 102; height: parent.height; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.editor.select(layerRow.modelData.id) }
                }
            }
        }
        Item {
            x: 0; y: layersCard.y + layersCard.height + 12; width: parent.width; height: parent.height - y; visible: Boolean(root.selectedLayer)
            Text { text: root.selectedLayer ? String(root.selectedLayer.name) : ""; color: "white"; font.family: root.theme.bodyFont; font.pixelSize: 14; font.weight: Font.Bold }
            Row {
                anchors.right: parent.right; y: -8; spacing: 6
                ActionButton { width: 39; label: "↓"; enabled: root.selectedLayer && !root.selectedLayer.sharedWidget; onTriggered: root.editor.moveSelected(-1) }
                ActionButton { width: 39; label: "↑"; enabled: root.selectedLayer && !root.selectedLayer.sharedWidget; onTriggered: root.editor.moveSelected(1) }
                ActionButton { width: 39; label: "⌫"; destructive: true; enabled: root.selectedLayer && root.selectedLayer.type === "image"; onTriggered: root.editor.removeSelected() }
            }
            Row {
                y: 34; spacing: 8; visible: root.selectedLayer && !root.selectedLayer.sharedWidget
                ActionButton { width: 241; label: "Atrás do painel"; emphasized: root.selectedLayer && root.selectedLayer.plane === "belowPanel"; onTriggered: root.editor.setPlane(root.editor.selectedLayerId, "belowPanel") }
                ActionButton { width: 241; label: "À frente do painel"; emphasized: root.selectedLayer && root.selectedLayer.plane === "abovePanel"; onTriggered: root.editor.setPlane(root.editor.selectedLayerId, "abovePanel") }
            }
            Row {
                y: 34; spacing: 8; visible: root.editor.editSpace === "desktop"
                ActionButton { width: 241; label: "Restaurar layout do perfil"; onTriggered: root.editor.restoreDesktopLayout() }
                ActionButton { width: 241; label: "Próximo template"; onTriggered: root.editor.advanceDesktopTemplate() }
            }
            Grid {
                y: 86; columns: 2; columnSpacing: 14; rowSpacing: 1
                CompactSlider { width: 241; label: "Posição X"; suffix: " px"; from: -1600; to: 3200; stepSize: 1; value: Number(root.selectedTransform.x || 0); onInteractionStarted: root.beginTransformGesture(); onEdited: function(value) { root.previewTransform("x", value) }; onInteractionFinished: root.finishTransformGesture() }
                CompactSlider { width: 241; label: "Posição Y"; suffix: " px"; from: -900; to: 1800; stepSize: 1; value: Number(root.selectedTransform.y || 0); onInteractionStarted: root.beginTransformGesture(); onEdited: function(value) { root.previewTransform("y", value) }; onInteractionFinished: root.finishTransformGesture() }
                CompactSlider { width: 241; label: "Escala"; suffix: "×"; from: 0.05; to: 4; stepSize: 0.01; value: Number(root.selectedTransform.scale || 1); onInteractionStarted: root.beginTransformGesture(); onEdited: function(value) { root.previewTransform("scale", value) }; onInteractionFinished: root.finishTransformGesture() }
                CompactSlider { width: 241; label: "Rotação"; suffix: "°"; from: -180; to: 180; stepSize: 1; value: Number(root.selectedTransform.rotation || 0); onInteractionStarted: root.beginTransformGesture(); onEdited: function(value) { root.previewTransform("rotation", value) }; onInteractionFinished: root.finishTransformGesture() }
                CompactSlider { width: 241; label: "Opacidade"; suffix: "%"; from: 0; to: 100; stepSize: 1; value: Number(root.selectedTransform.opacity === undefined ? 1 : root.selectedTransform.opacity) * 100; onInteractionStarted: root.beginTransformGesture(); onEdited: function(value) { root.previewTransform("opacity", value / 100) }; onInteractionFinished: root.finishTransformGesture() }
                ActionButton { width: 241; height: 40; label: root.selectedTransform.flipX ? "Espelhado horizontalmente" : "Espelhar horizontalmente"; emphasized: Boolean(root.selectedTransform.flipX); onTriggered: root.editor.setTransform(root.editor.selectedLayerId, "flipX", !root.selectedTransform.flipX) }
            }
        }
        Text { anchors.centerIn: parent; anchors.verticalCenterOffset: 168; visible: !root.selectedLayer; text: "Selecione uma camada no painel ou diretamente na composição"; color: Qt.rgba(1, 1, 1, 0.50); font.family: root.theme.bodyFont; font.pixelSize: 10 }
    }

    Item {
        id: contentPage; x: 18; y: 135; width: parent.width - 36; height: parent.height - 154; visible: root.page === 1
        Flickable {
            anchors.fill: parent; contentHeight: contentColumn.height + 8; clip: true; boundsBehavior: Flickable.StopAtBounds
            Column {
                id: contentColumn; width: parent.width; spacing: 11
                Text { text: "Identidade"; color: "white"; font.family: root.theme.bodyFont; font.pixelSize: 15; font.weight: Font.Bold }
                Field { width: parent.width; text: root.config.profileName; placeholder: "Nome exibido"; onAccepted: function(value) { root.config.setValue("profile.displayName", value) } }
                Field { width: parent.width; text: root.config.greeting; placeholder: "Saudação"; onAccepted: function(value) { root.config.setProfileValue("greeting", value) } }
                Field { width: parent.width; text: root.config.verticalLabel; placeholder: "Texto vertical"; onAccepted: function(value) { root.config.setProfileValue("verticalLabel", value) } }
                Row {
                    spacing: 8
                    ActionButton { width: 241; label: "Trocar foto de perfil"; onTriggered: root.controller.chooseAvatar() }
                    ActionButton { width: 241; label: "Trocar wallpaper do perfil ativo"; onTriggered: root.chooseWallpaperForActiveProfile() }
                }
                Text { topPadding: 7; text: "Escurecimento da lock"; color: "white"; font.family: root.theme.bodyFont; font.pixelSize: 15; font.weight: Font.Bold }
                Grid {
                    columns: 2; columnSpacing: 8; rowSpacing: 8
                    Repeater {
                        model: [
                            { label: "Desligado", value: "off" },
                            { label: "Somente fundo", value: "background" },
                            { label: "Somente painel", value: "panel" },
                            { label: "Fundo + painel", value: "both" }
                        ]
                        ActionButton {
                            required property var modelData
                            width: 241
                            label: String(modelData.label)
                            emphasized: root.config.lockDimmingMode === String(modelData.value)
                            onTriggered: root.config.setValue(
                                "lockPreview.dimming.mode", String(modelData.value))
                        }
                    }
                }
                CompactSlider {
                    width: parent.width
                    label: "Intensidade"
                    suffix: "%"
                    from: 0
                    to: 72
                    stepSize: 1
                    value: root.config.lockDimmingAmount * 100
                    opacity: root.config.lockDimmingMode === "off" ? 0.52 : 1
                    onEdited: function(value) {
                        root.config.setValue("lockPreview.dimming.amount", value / 100)
                    }
                }
                Text {
                    topPadding: 7
                    text: "Cáusticas de água"
                    color: "white"
                    font.family: root.theme.bodyFont
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }
                Row {
                    spacing: 8
                    ActionButton {
                        width: 241
                        label: root.config.waterCausticsEnabled
                            ? "Efeito ligado" : "Efeito desligado"
                        emphasized: root.config.waterCausticsEnabled
                        onTriggered: root.config.setValue(
                            "lockPreview.caustics.enabled",
                            !root.config.waterCausticsEnabled)
                    }
                    ActionButton {
                        width: 241
                        label: root.config.waterCausticsLines
                            ? "Linhas de luz visíveis" : "Linhas de luz ocultas"
                        enabled: root.config.waterCausticsEnabled
                        emphasized: root.config.waterCausticsEnabled
                            && root.config.waterCausticsLines
                        onTriggered: root.config.setValue(
                            "lockPreview.caustics.lines",
                            !root.config.waterCausticsLines)
                    }
                }
                ActionButton {
                    width: parent.width
                    label: root.config.waterCausticsModules
                        ? "Cáusticas também nos módulos"
                        : "Aplicar também nos módulos"
                    enabled: root.config.waterCausticsEnabled
                        && root.config.waterCausticsLines
                    emphasized: enabled && root.config.waterCausticsModules
                    onTriggered: root.config.setValue(
                        "lockPreview.caustics.modules",
                        !root.config.waterCausticsModules)
                }
                CompactSlider {
                    width: parent.width
                    label: "Intensidade da água"
                    suffix: "%"
                    from: 0
                    to: 100
                    stepSize: 1
                    value: root.config.waterCausticsIntensity * 100
                    opacity: root.config.waterCausticsEnabled ? 1 : 0.52
                    onEdited: function(value) {
                        root.config.setValue(
                            "lockPreview.caustics.intensity", value / 100)
                    }
                }
                Text { topPadding: 7; text: "Imagens principais"; color: "white"; font.family: root.theme.bodyFont; font.pixelSize: 15; font.weight: Font.Bold }
                ActionButton { width: parent.width; height: 46; label: "Trocar personagem principal"; emphasized: true; onTriggered: root.controller.chooseImage(0) }
                Row {
                    spacing: 8
                    Repeater { model: 3; ActionButton { required property int index; width: 158; label: "Imagem " + (index + 1); onTriggered: root.controller.chooseImage(index + 1) } }
                }
                Rectangle {
                    width: parent.width; height: 55; radius: 18
                    color: Qt.rgba(1, 1, 1, pywalMouse.containsMouse ? 0.12 : 0.055); border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.14)
                    Text { x: 15; anchors.verticalCenter: parent.verticalCenter; text: "Harmonizar personagem com o Pywal"; color: "white"; font.family: root.theme.bodyFont; font.pixelSize: 11; font.weight: Font.DemiBold }
                    Rectangle {
                        anchors.right: parent.right; anchors.rightMargin: 13; anchors.verticalCenter: parent.verticalCenter
                        width: 42; height: 24; radius: 12; color: root.config.characterPywal ? root.theme.accent : Qt.rgba(1, 1, 1, 0.15)
                        Rectangle { x: root.config.characterPywal ? 20 : 3; anchors.verticalCenter: parent.verticalCenter; width: 19; height: 19; radius: 9.5; color: "white"; Behavior on x { NumberAnimation { duration: root.motion.micro } } }
                    }
                    MouseArea { id: pywalMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.config.setCharacterPywal(!root.config.characterPywal) }
                }
                Text { width: parent.width; wrapMode: Text.WordWrap; text: "Dica: em Camadas você pode arrastar, girar, redimensionar e definir se cada elemento fica atrás ou à frente do painel. Alt desativa o encaixe temporariamente."; color: Qt.rgba(1, 1, 1, 0.52); font.family: root.theme.bodyFont; font.pixelSize: 10; lineHeight: 1.25 }
            }
        }
    }

    Item {
        id: profilesPage; x: 18; y: 135; width: parent.width - 36; height: parent.height - 154; visible: root.page === 2
        Text { text: "Perfis e pacotes"; color: "white"; font.family: root.theme.bodyFont; font.pixelSize: 15; font.weight: Font.Bold }
        Text { y: 24; text: "Cada perfil preserva composição, imagens e wallpaper"; color: Qt.rgba(1, 1, 1, 0.52); font.family: root.theme.bodyFont; font.pixelSize: 9 }
        Rectangle {
            id: profilesCard; y: 47; width: parent.width; height: Math.min(285, parent.height * 0.43); radius: 22
            color: Qt.rgba(0.01, 0.03, 0.08, 0.23); border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.14); clip: true
            ListView {
                id: profilesList; anchors.fill: parent; anchors.margins: 8; spacing: 6; model: root.profileService.profiles
                boundsBehavior: Flickable.StopAtBounds; clip: true
                delegate: Rectangle {
                    id: profileRow; required property var modelData
                    width: profilesList.width; height: 60; radius: 17
                    readonly property bool selected: String(modelData.id) === root.selectedProfileId
                    readonly property bool activeProfile: String(modelData.id) === root.profileService.activeProfileId
                    color: selected ? Qt.rgba(0.61, 0.70, 1, 0.26) : Qt.rgba(1, 1, 1, profileMouse.containsMouse ? 0.11 : 0.04)
                    border.width: 1; border.color: selected ? Qt.rgba(1, 1, 1, 0.42) : Qt.rgba(1, 1, 1, 0.08)
                    Lock.RoundedImage { x: 7; anchors.verticalCenter: parent.verticalCenter; width: 46; height: 46; radius: 14; source: String(profileRow.modelData.preview || ""); fillMode: Image.PreserveAspectFit }
                    Text { x: 64; y: 11; width: parent.width - 110; text: String(profileRow.modelData.name || "Perfil"); elide: Text.ElideRight; color: "white"; font.family: root.theme.bodyFont; font.pixelSize: 11; font.weight: Font.DemiBold }
                    Text { x: 64; y: 34; text: profileRow.activeProfile ? (root.profileService.dirty ? "Ativo • alterado" : "Ativo") : "Salvo"; color: profileRow.activeProfile && root.profileService.dirty ? "#ffd591" : Qt.rgba(1, 1, 1, 0.48); font.family: root.theme.bodyFont; font.pixelSize: 8 }
                    Rectangle { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; width: 9; height: 9; radius: 4.5; visible: profileRow.activeProfile; color: root.theme.success }
                    MouseArea {
                        id: profileMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { root.selectedProfileId = String(profileRow.modelData.id); root.profileService.selectProfileForEditing(root.selectedProfileId); profileNameInput.text = root.profileService.draftProfileName }
                        onDoubleClicked: root.profileService.applyProfile(String(profileRow.modelData.id), true)
                    }
                }
            }
        }
        Field { id: profileNameInput; y: profilesCard.y + profilesCard.height + 11; width: parent.width; placeholder: "Nome do perfil"; onAccepted: function(value) { root.profileService.setDraftProfileName(value) } }
        Grid {
            id: profileActions; y: profileNameInput.y + profileNameInput.height + 9; columns: 2; columnSpacing: 8; rowSpacing: 8
            ActionButton { width: 241; label: "Salvar como novo"; emphasized: true; enabled: !root.profileService.busy; onTriggered: root.profileService.createProfile(profileNameInput.text) }
            ActionButton { width: 241; label: "Atualizar perfil ativo"; enabled: !root.profileService.busy && root.selectedProfileId === root.profileService.activeProfileId; onTriggered: root.profileService.updateProfile(root.selectedProfileId) }
            ActionButton { width: 241; label: "Aplicar"; enabled: !root.profileService.busy && root.selectedProfileId.length > 0; onTriggered: root.profileService.applyProfile(root.selectedProfileId, true) }
            ActionButton { width: 241; label: "Renomear"; enabled: !root.profileService.busy && root.selectedProfileId.length > 0; onTriggered: root.profileService.renameProfile(root.selectedProfileId, profileNameInput.text) }
            ActionButton { width: 241; label: "Exportar .helixpack"; enabled: !root.profileService.busy && root.selectedProfileId.length > 0; onTriggered: root.controller.exportPackage(root.selectedProfileId) }
            ActionButton { width: 241; label: "Importar .helixpack"; enabled: !root.profileService.busy; onTriggered: root.controller.importPackage() }
        }
        ActionButton { anchors.left: parent.left; anchors.right: parent.right; y: profileActions.y + profileActions.height + 9; label: "Excluir perfil selecionado"; destructive: true; enabled: !root.profileService.busy && root.profileService.profiles.length > 1 && root.selectedProfileId.length > 0; onTriggered: root.profileService.deleteProfile(root.selectedProfileId) }
        Text { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; visible: root.profileService.busy || root.profileService.error.length > 0; text: root.profileService.busy ? "Processando…" : root.profileService.error; wrapMode: Text.WordWrap; color: root.profileService.error.length > 0 ? "#ffd0d6" : Qt.rgba(1, 1, 1, 0.58); font.family: root.theme.bodyFont; font.pixelSize: 9 }
    }

    Connections {
        target: root.profileService
        function onProfilesChangedExternally() { root.syncProfileSelection() }
        function onProfileApplied(profileId) {
            root.selectedProfileId = String(profileId)
            root.syncProfileSelection()
        }
        function onOperationFinished(operation, ok, message) { if (ok && operation === "import") root.page = 2 }
    }
    Component.onCompleted: Qt.callLater(syncProfileSelection)
}
