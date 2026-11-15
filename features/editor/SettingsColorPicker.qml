import QtQuick
import QtQuick.Controls

Column {
    id: root
    required property var theme
    property string label: "Cor"
    property color initialColor: "#c8788f"
    property real hue: 0
    property real saturation: 0
    property real level: 1
    readonly property color selectedColor: Qt.hsva(hue, saturation, level, 1)
    readonly property string hexColor: rgbHex(selectedColor)
    readonly property bool validHex: /^#?[0-9a-fA-F]{6}$/.test(hexInput.text.trim())
    signal accepted(string color)
    signal canceled
    spacing: 12
    objectName: "manualColorPicker"

    function rgbHex(color) {
        function channel(value) { return Math.round(value * 255).toString(16).padStart(2, "0") }
        return "#" + channel(color.r) + channel(color.g) + channel(color.b)
    }
    function seed(color: color): void {
        hue = color.hsvHue < 0 ? 0 : color.hsvHue
        saturation = color.hsvSaturation
        level = color.hsvValue
    }
    function editSquare(x, y) {
        saturation = Math.max(0, Math.min(1, x / square.width))
        level = 1 - Math.max(0, Math.min(1, y / square.height))
    }
    Component.onCompleted: seed(initialColor)
    onInitialColorChanged: seed(initialColor)
    Keys.onEscapePressed: canceled()


    Text {
        text: "Cor: " + root.label
        color: root.theme.textPrimary
        font.family: root.theme.bodyFont; font.pixelSize: 14; font.weight: Font.DemiBold
    }
    FocusScope {
        id: square
        objectName: "manualColorPicker.square"
        width: parent.width; height: Math.min(210, width * .58)
        activeFocusOnTab: true
        Accessible.role: Accessible.Slider
        Accessible.name: "Saturação e luminosidade de " + root.label
        Keys.onLeftPressed: root.saturation = Math.max(0, root.saturation - .01)
        Keys.onRightPressed: root.saturation = Math.min(1, root.saturation + .01)
        Keys.onUpPressed: root.level = Math.min(1, root.level + .01)
        Keys.onDownPressed: root.level = Math.max(0, root.level - .01)
        Rectangle {
            anchors.fill: parent; radius: 10; clip: true
            color: Qt.hsva(root.hue, 1, 1, 1)
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "white" }
                    GradientStop { position: 1; color: "transparent" }
                }
            }
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: "black" }
                }
            }
        }
        Rectangle {
            x: root.saturation * square.width - width / 2
            y: (1 - root.level) * square.height - height / 2
            width: 14; height: 14; radius: 7; color: root.selectedColor
            border.width: 2; border.color: "white"
            Rectangle { anchors.fill: parent; anchors.margins: -1; radius: 8; color: "transparent"; border.color: "#66000000" }
        }
        MouseArea {
            anchors.fill: parent
            onPressed: mouse => { square.forceActiveFocus(); root.editSquare(mouse.x, mouse.y) }
            onPositionChanged: mouse => { if (pressed) root.editSquare(mouse.x, mouse.y) }
        }
    }
    Slider {
        id: hueSlider
        objectName: "manualColorPicker.hue"
        width: parent.width; implicitHeight: 30; from: 0; to: 1; value: root.hue
        Accessible.name: "Matiz de " + root.label
        onMoved: root.hue = value
        background: Rectangle {
            x: hueSlider.leftPadding; y: (hueSlider.height-height)/2
            width: hueSlider.availableWidth; height: 16; radius: 8
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#ff0000" }
                GradientStop { position: 1/6; color: "#ffff00" }
                GradientStop { position: 2/6; color: "#00ff00" }
                GradientStop { position: 3/6; color: "#00ffff" }
                GradientStop { position: 4/6; color: "#0000ff" }
                GradientStop { position: 5/6; color: "#ff00ff" }
                GradientStop { position: 1; color: "#ff0000" }
            }
        }
        handle: Rectangle {
            x: hueSlider.leftPadding + hueSlider.visualPosition * (hueSlider.availableWidth-width)
            y: (hueSlider.height-height)/2
            width: 22; height: 22; radius: 11; color: Qt.hsva(root.hue,1,1,1)
            border.width: 2; border.color: "white"
        }
    }
    Row {
        spacing: 10; width: parent.width
        Rectangle {
            width: 44; height: 38; radius: 9; color: root.initialColor
            border.color: root.theme.borderSubtle
            Accessible.role: Accessible.StaticText; Accessible.name: "Cor anterior"
        }
        Rectangle {
            width: 44; height: 38; radius: 9; color: root.selectedColor
            border.color: root.theme.borderSubtle
            Accessible.role: Accessible.StaticText; Accessible.name: "Nova cor"
        }
        TextField {
            id: hexInput
            objectName: "manualColorPicker.hex"
            width: Math.max(100, parent.width-108); height: 38
            text: root.hexColor.toUpperCase(); maximumLength: 7
            color: root.theme.textPrimary; selectionColor: root.theme.accentMuted
            font.family: root.theme.bodyFont; font.pixelSize: 13
            Accessible.name: "Cor hexadecimal de " + root.label
            onTextEdited: {
                if (root.validHex) {
                    root.seed(text.startsWith("#") ? text : "#"+text)
                }
            }
            background: Rectangle { radius: 9; color: root.theme.surfaceSoft; border.color: hexInput.activeFocus ? root.theme.accent : root.theme.borderSubtle }
        }
    }
    Text {
        visible: !root.validHex
        text: "Use uma cor no formato #RRGGBB."
        color: root.theme.textSecondary; font.pixelSize: 11
    }
    Row {
        spacing: 10
        SettingsPickerAction {
            theme: root.theme
            objectName: "manualColorPicker.cancel"; text: "Cancelar"
            onClicked: root.canceled()
        }
        SettingsPickerAction {
            theme: root.theme
            primary: true
            objectName: "manualColorPicker.apply"; text: "Aplicar cor"
            enabled: root.validHex
            onClicked: root.accepted(root.hexColor)
        }
    }
}
