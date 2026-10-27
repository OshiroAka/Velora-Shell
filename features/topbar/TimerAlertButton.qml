pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects

BarAction {
    id: button
    required property color tint
    property bool reducedMotion: false
    property real glowPhase: 0
    property real hoverReveal: hovered || activeFocus ? 1 : 0
    readonly property real glowStrength: (reducedMotion ? 0.28
        : 0.24 + 0.12 * (0.5 + 0.5 * Math.sin(glowPhase * Math.PI * 2))) + hoverReveal * 0.18
    implicitWidth: 36
    implicitHeight: 36
    padding: 4
    signal confirmed()
    onClicked: confirmed()
    scale: down ? 0.93 : 1 + hoverReveal * 0.05
    Behavior on scale {
        enabled: !button.reducedMotion
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }
    Behavior on hoverReveal {
        enabled: !button.reducedMotion
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }
    NumberAnimation on glowPhase {
        running: button.visible && button.enabled && !button.reducedMotion
        from: 0; to: 1; duration: 2800; loops: Animation.Infinite
    }
    background: Rectangle {
        radius: height / 2
        antialiasing: true
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(button.tint.r, button.tint.g, button.tint.b,
                0.21 + button.hoverReveal * 0.07 + (button.down ? 0.11 : 0)) }
            GradientStop { position: 1; color: Qt.rgba(button.tint.r, button.tint.g, button.tint.b,
                0.12 + button.hoverReveal * 0.06 + (button.down ? 0.13 : 0)) }
        }
        border.width: 1
        border.color: Qt.rgba(button.tint.r, button.tint.g, button.tint.b, button.activeFocus ? 0.85 : 0.35)
        layer.enabled: button.visible && GraphicsInfo.api !== GraphicsInfo.Software
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: button.tint
            shadowOpacity: button.glowStrength
            shadowBlur: 0.8
            blurMax: 8
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
        }
    }
    contentItem: Item {
        opacity: button.enabled ? 1 : 0.5
        Text {
            anchors.fill: parent
            visible: button.iconName !== "stop"
            text: button.text
            color: button.theme.textPrimary
            font.family: button.theme.bodyFont
            font.pixelSize: 11
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        Rectangle {
            anchors.centerIn: parent
            visible: button.iconName === "stop"
            width: 10; height: 10; radius: 1.5
            color: button.theme.textPrimary
        }
    }
}
