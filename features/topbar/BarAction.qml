import QtQuick
import QtQuick.Controls

Button {
    id: root
    required property var theme
    property bool destructive: false
    property string iconName: ""
    implicitHeight: 36
    implicitWidth: Math.max(36, label.implicitWidth + (iconName.length ? 54 : 24))
    padding: 8
    hoverEnabled: true
    Accessible.name: text
    background: Rectangle {
        radius: 9
        color: root.theme.withAlpha(root.destructive ? root.theme.danger : root.theme.accent,
            root.down ? 0.24 : root.highlighted ? 0.16 : root.hovered ? 0.10 : 0.045)
        border.width: root.activeFocus || root.highlighted ? 1 : 0
        border.color: root.theme.withAlpha(root.theme.accentSoft, root.activeFocus ? 0.8 : 0.35)
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    contentItem: Item {
        opacity: root.enabled ? 1 : 0.4
        BarIcon {
            visible: root.iconName.length > 0
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 19; height: 19
            name: root.iconName
            color: root.destructive ? root.theme.danger : root.theme.textPrimary
        }
        Text {
            id: label
            anchors.fill: parent
            anchors.leftMargin: root.iconName.length ? 27 : 0
            text: root.text
            color: root.destructive ? root.theme.danger : root.theme.textPrimary
            font.family: root.theme.bodyFont
            font.pixelSize: 12
            horizontalAlignment: root.iconName.length ? Text.AlignLeft : Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }
}
