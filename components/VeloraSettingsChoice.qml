pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import "../core" as Core

Rectangle {
    id: root
    required property var theme
    property var motion: fallbackMotion
    property string label: ""
    property string iconName: "settings"
    property bool active: false
    property bool checkable: true
    signal clicked()
    Core.Motion { id: fallbackMotion; config: root.theme ? root.theme.config : null }
    implicitWidth: Math.max(110, caption.implicitWidth+62)
    implicitHeight: 38
    radius: 13
    color: root.theme.withAlpha(root.theme.textPrimary, active ? .13 : pointer.containsMouse ? .085 : .04)
    border.width: active || activeFocus ? 1 : 0
    border.color: activeFocus ? theme.accent : theme.withAlpha(theme.accent,.55)
    opacity: enabled ? 1 : .45
    Behavior on color { ColorAnimation { duration: root.motion.surfaceHover } }
    activeFocusOnTab: enabled && visible
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.checkable: checkable
    Accessible.checked: active
    Accessible.onPressAction: if (enabled) clicked()
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()
    VeloraIconMotion {
        id: iconMotion
        highlighted: root.enabled && (pointer.containsMouse || root.activeFocus)
        reducedMotion: root.motion.reduced
    }
    Row {
        anchors.centerIn: parent; spacing: 8
        VeloraMaterialIcon {
            width: 18; height: 18; anchors.verticalCenter: parent.verticalCenter
            iconName: root.iconName
            iconColor: root.active ? root.theme.accent : root.theme.textPrimary
            scale: iconMotion.zoom; opacity: iconMotion.inkOpacity
            transform: Translate { y: iconMotion.lift }
            layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software && iconMotion.emphasis>.001 && root.visible
            layer.effect: MultiEffect {
                shadowEnabled: true; shadowColor: root.theme.accent
                shadowOpacity: .4*iconMotion.emphasis; shadowBlur: .5; blurMax: 10
                shadowHorizontalOffset: 0; shadowVerticalOffset: 0
            }
        }
        Text {
            id: caption
            anchors.verticalCenter: parent.verticalCenter
            text: root.label; color: root.theme.textPrimary
            font.family: root.theme.bodyFont; font.pixelSize: 11
            font.weight: root.active ? Font.DemiBold : Font.Normal
        }
    }
    MouseArea {
        id: pointer; anchors.fill: parent; hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
