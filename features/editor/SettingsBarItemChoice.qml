import QtQuick
import "../../components" as Components

Item {
    id: root
    required property var theme
    required property var motion
    property alias label: toggle.label
    property alias checked: toggle.checked
    signal triggered()
    height: 36
    Components.VeloraSettingsSwitch {
        id: toggle
        theme: root.theme; motion: root.motion
        width: Math.min(parent.width, implicitWidth)
        onTriggered: root.triggered()
    }
}
