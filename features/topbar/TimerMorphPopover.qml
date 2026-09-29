import QtQuick

// Compatibility wrapper; the same sequence now serves the approved menus.
MorphPopover {
    id: root
    required property var theme
    required property var timerService
    property bool desiredOpen: false
    property string kind: "timer"
    desiredType: desiredOpen ? "timer" : ""
    onKindChanged: if (desiredOpen) updateAnchor()
    onMountedChanged: if (!mounted) timerPanel.customOpen = false
    TimerPanel {
        id: timerPanel
        anchors.fill: parent
        theme: root.theme
        timerService: root.timerService
        presented: root.mounted
    }
}
