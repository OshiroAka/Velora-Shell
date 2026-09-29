import QtQuick
import QtQuick.Controls

Slider {
    id: root
    required property var theme
    property string label: ""
    from: 0
    to: 100
    stepSize: 1
    implicitHeight: 36
    Accessible.name: label
    Accessible.description: Math.round(value) + "%"
    opacity: enabled ? 1 : 0.38
    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: 6
        radius: 3
        color: root.theme.withAlpha(root.theme.textSecondary, 0.14)
        Rectangle {
            width: parent.width * root.visualPosition
            height: parent.height
            radius: parent.radius
            color: root.theme.accentSoft
        }
    }
    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: 17; height: 17; radius: 8.5
        color: root.pressed ? root.theme.accent : root.theme.accentSoft
        border.width: root.activeFocus ? 2 : 1
        border.color: root.theme.withAlpha(root.theme.textPrimary, root.activeFocus ? 0.9 : 0.25)
    }
}
