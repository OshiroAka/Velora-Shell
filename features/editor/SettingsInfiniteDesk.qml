pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../../components" as Components

Column {
    id: root
    required property var config
    required property var theme
    required property var motion
    width: parent ? parent.width : 600
    spacing: 16
    objectName: "infiniteDeskSettingsPage"

    function addSize() {
        config.setValue("infiniteDesk.scatterSizes", config.infiniteDeskSizes.concat([{width: 1040, height: 500}]))
    }
    function removeSize(index) {
        if (config.infiniteDeskSizes.length <= 1) return
        const sizes = config.clone(config.infiniteDeskSizes)
        sizes.splice(index, 1)
        config.setValue("infiniteDesk.scatterSizes", sizes)
        addButton.forceActiveFocus()
    }
    function resizeSize(index, field, value) {
        const sizes = config.clone(config.infiniteDeskSizes)
        sizes[index][field] = value
        config.setValue("infiniteDesk.scatterSizes", sizes)
    }

    Text {
        text: "Infinite Desk"; color: root.theme.textPrimary
        font.family: root.theme.bodyFont; font.pixelSize: 22
    }
    Components.VeloraSettingsSlider {
        objectName: "infiniteDesk.sensitivity"
        width: parent.width; theme: root.theme
        reducedMotion: root.motion.reduced
        label: "Sensibilidade do arraste"
        hint: "Mouse e deslizamento de dois dedos no touchpad."
        minimum: .1; maximum: 4; value: root.config.infiniteDeskDragSensitivity
        valueText: controlItem.value.toFixed(2) + "×"
        resettable: true; defaultValue: 1.15
        onEdited: value => root.config.setValue("infiniteDesk.dragSensitivity", Math.round(value * 100) / 100)
    }
    Text {
        text: "Misturar janelas"; color: root.theme.textPrimary
        font.family: root.theme.bodyFont; font.pixelSize: 16
    }
    Components.VeloraSettingsSlider {
        objectName: "infiniteDesk.spacing"
        width: parent.width; theme: root.theme
        reducedMotion: root.motion.reduced
        label: "Afastamento das janelas"
        hint: "Menor: mais próximas. Maior: mais distantes. Aplicado ao misturar."
        minimum: 0; maximum: 3; value: root.config.infiniteDeskWindowSpacing
        resettable: true; defaultValue: 1
        onEdited: value => root.config.setValue("infiniteDesk.windowSpacing", Math.round(value * 100) / 100)
    }
    Text {
        width: parent.width
        text: "Escolha os tamanhos usados ao misturar as janelas. Cada janela recebe um deles, com posições sorteadas e sem sobreposição. Mantenha um tamanho ou adicione mais opções."
        wrapMode: Text.WordWrap; color: root.theme.textSecondary
        font.family: root.theme.bodyFont; font.pixelSize: 12
    }
    Column {
        objectName: "infiniteDesk.sizes"
        width: parent.width; spacing: 12
        Repeater {
            model: root.config.infiniteDeskSizes.length
            Rectangle {
                id: card
                required property int index
                readonly property var preset: root.config.infiniteDeskSizes[index]
                width: parent.width; height: fields.implicitHeight + 24; radius: 14
                color: root.theme.withAlpha(root.theme.accent, .05)
                border.width: 1; border.color: root.theme.borderSubtle
                Column {
                    id: fields
                    x: 12; y: 12; width: parent.width - 24; spacing: 10
                    Row {
                        width: parent.width; spacing: 12
                        Text {
                            width: parent.width - remove.implicitWidth - 12; height: remove.height
                            text: "Tamanho " + (card.index + 1); verticalAlignment: Text.AlignVCenter
                            color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 12
                        }
                        Button {
                            id: remove
                            objectName: "infiniteDesk.removeSize" + card.index
                            text: "Apagar"; enabled: root.config.infiniteDeskSizes.length > 1
                            Accessible.name: "Apagar tamanho " + (card.index + 1)
                            opacity: enabled ? 1 : .4
                            onClicked: root.removeSize(card.index)
                            contentItem: Text { text: remove.text; color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter }
                            background: Rectangle { radius: 8; color: root.theme.withAlpha(root.theme.accent, remove.hovered || remove.activeFocus ? .18 : .07) }
                        }
                    }
                    Row {
                        width: parent.width; spacing: 16
                        Repeater {
                            model: ["width", "height"]
                            Column {
                                id: dimension
                                required property string modelData
                                width: Math.min(180, (fields.width - 16) / 2); spacing: 6
                                Text {
                                    text: dimension.modelData === "width" ? "Largura (px)" : "Altura (px)"
                                    color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 11
                                }
                                SpinBox {
                                    id: input
                                    objectName: "infiniteDesk." + dimension.modelData + card.index
                                    width: parent.width; implicitHeight: 36
                                    from: dimension.modelData === "width" ? 320 : 200
                                    to: dimension.modelData === "width" ? 7680 : 4320
                                    stepSize: 40; editable: true
                                    value: card.preset ? card.preset[dimension.modelData] : from
                                    Accessible.name: (dimension.modelData === "width" ? "Largura" : "Altura") + " do tamanho " + (card.index + 1)
                                    textFromValue: value => String(value)
                                    valueFromText: text => Number(text)
                                    onValueModified: root.resizeSize(card.index, dimension.modelData, value)
                                    contentItem: TextInput {
                                        text: input.textFromValue(input.value, input.locale)
                                        color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 12
                                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                        readOnly: !input.editable; selectByMouse: true
                                        validator: input.validator; inputMethodHints: Qt.ImhDigitsOnly
                                    }
                                    up.indicator: Rectangle {
                                        x: input.width - width; width: 26; height: input.height; radius: 8
                                        color: root.theme.withAlpha(root.theme.accent, input.up.pressed ? .24 : .08)
                                        Text { anchors.centerIn: parent; text: "+"; color: root.theme.textPrimary }
                                    }
                                    down.indicator: Rectangle {
                                        width: 26; height: input.height; radius: 8
                                        color: root.theme.withAlpha(root.theme.accent, input.down.pressed ? .24 : .08)
                                        Text { anchors.centerIn: parent; text: "−"; color: root.theme.textPrimary }
                                    }
                                    background: Rectangle { radius: 8; color: "transparent"; border.width: 1; border.color: input.activeFocus ? root.theme.accent : root.theme.borderSubtle }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Button {
        id: addButton
        objectName: "infiniteDesk.addSize"
        text: "+  Adicionar tamanho"; Accessible.name: "Adicionar tamanho"
        implicitHeight: 36
        onClicked: root.addSize()
        contentItem: Text { text: addButton.text; color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        background: Rectangle { radius: 10; color: root.theme.withAlpha(root.theme.accent, addButton.hovered || addButton.activeFocus ? .22 : .12); border.width: 1; border.color: root.theme.borderSubtle }
    }
}
