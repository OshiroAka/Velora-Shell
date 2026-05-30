import QtQuick
import "."

Rectangle {
    id: root

    property bool  clickable: false
    property bool  hovered: false
    property bool  active: false

    signal clicked()

    height: ShinConfig.pillH
    radius: ShinConfig.pillR
    antialiasing: true
    clip: true
    scale: hovered ? ShinConfig.hoverScale : 1.0

    color: active
        ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, Math.min(0.34, ShinConfig.pillOpacity + 0.06))
        : Qt.rgba((ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").r, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").g, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").b, ShinConfig.pillOpacity)

    border.color: hovered || active
        ? Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.48)
        : Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, 0.18)

    border.width: 1

    Behavior on color {
        ColorAnimation { duration: ShinData.anim(135); easing.type: Easing.OutCubic }
    }

    Behavior on border.color {
        ColorAnimation { duration: ShinData.anim(135); easing.type: Easing.OutCubic }
    }

    Behavior on scale {
        NumberAnimation { duration: ShinData.anim(130); easing.type: Easing.OutCubic }
    }

    Rectangle {
        width: parent.width * 0.70
        height: parent.height
        radius: parent.radius
        x: root.hovered || root.active ? parent.width * 0.10 : -parent.width * 0.30
        color: Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, root.active ? 0.12 : 0.055)

        Behavior on x {
            NumberAnimation { duration: ShinData.anim(170); easing.type: Easing.OutCubic }
        }

        Behavior on color {
            ColorAnimation { duration: ShinData.anim(135); easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: root.clickable
        enabled: root.clickable

        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: root.clicked()
    }
}
