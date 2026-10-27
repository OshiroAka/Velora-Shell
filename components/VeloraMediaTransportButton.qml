import QtQuick

VeloraMediaButton {
    id: root
    implicitWidth: primary ? 52 : 44
    implicitHeight: implicitWidth
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()
    background: Item {}
    contentItem: Item {
        VeloraIconMotion {
            id: motion
            highlighted: root.hovered || root.activeFocus || root.down
            reducedMotion: !root.animated
        }
        VeloraSidebarIcon {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: motion.lift
            width: root.primary ? 26 : 22; height: width
            iconName: root.iconName; ink: root.ink
            opacity: root.enabled ? motion.inkOpacity : .25
            scale: motion.zoom
        }
        Rectangle {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 2
            anchors.horizontalCenter: parent.horizontalCenter
            width: 14; height: 1; radius: .5
            color: root.ink; visible: root.activeFocus
        }
    }
}
