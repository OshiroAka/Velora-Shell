import QtQuick

Item {
    id: root
    required property var theme
    property var workspaceIds: [1, 2, 3, 4, 5]
    property int activeWorkspaceId: 1
    property int pendingId: 0
    property bool ready: false
    signal workspaceRequested(int workspaceId)
    readonly property int selectedIndex: workspaceIds.indexOf(activeWorkspaceId)
    // Match the existing row: 32 px items, 4 px gaps, in its original 208 px slot.
    readonly property real gap: 4
    readonly property real cellWidth: (width - gap * Math.max(0, workspaceIds.length - 1)) / Math.max(1, workspaceIds.length)
    readonly property real step: cellWidth + gap
    readonly property real targetCenter: Math.max(0, selectedIndex) * step + cellWidth / 2
    property real selectedCenter: targetCenter
    property real travel: 0
    implicitWidth: workspaceIds.length * 32 + Math.max(0, workspaceIds.length - 1) * gap
    implicitHeight: 32

    function activate(workspaceId) {
        if (workspaceId === activeWorkspaceId || workspaceId === pendingId) return
        pendingId = workspaceId
        acknowledgement.restart()
        workspaceRequested(workspaceId)
    }
    onActiveWorkspaceIdChanged: {
        if (activeWorkspaceId === pendingId) { pendingId = 0; acknowledgement.stop() }
        if (ready) transition.restart()
    }
    Component.onCompleted: ready = true
    Behavior on selectedCenter { enabled: root.ready; NumberAnimation { duration: 220; easing.type: Easing.InOutCubic } }
    Timer { id: acknowledgement; interval: 1200; onTriggered: root.pendingId = 0 }
    SequentialAnimation {
        id: transition
        NumberAnimation { target: root; property: "travel"; to: 1; duration: 90; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "travel"; to: 0; duration: 150; easing.type: Easing.InOutCubic }
    }
    Rectangle {
        objectName: "workspaceActiveIndicator"
        x: root.selectedCenter - width / 2; y: root.travel
        width: Math.min(32, root.cellWidth) + root.travel * 4
        height: 32 - root.travel * 2; radius: height / 2
        visible: root.selectedIndex >= 0
        color: root.theme.accent
        border.width: 1
        border.color: root.theme.withAlpha(root.theme.accentSoft, 0.32)
    }
    Row {
        spacing: root.gap
        Repeater {
            model: root.workspaceIds
            FocusScope {
                id: workspace
                required property int modelData
                objectName: "workspaceButton" + modelData
                readonly property bool selected: modelData === root.activeWorkspaceId
                width: root.cellWidth; height: 32
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: "Área de trabalho " + modelData
                Accessible.onPressAction: root.activate(modelData)
                Keys.onReturnPressed: root.activate(modelData)
                Keys.onSpacePressed: root.activate(modelData)
                Rectangle {
                    objectName: "workspaceHover"
                    anchors.centerIn: parent
                    width: Math.min(32, parent.width); height: 32; radius: 16
                    color: root.theme.withAlpha(root.theme.textPrimary, workspace.selected ? 0.045 : 0.08)
                    opacity: pointer.containsMouse || workspace.activeFocus ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    border.width: workspace.activeFocus ? 1 : 0
                    border.color: root.theme.accentSoft
                }
                Text {
                    anchors.centerIn: parent
                    text: workspace.modelData
                    color: root.theme.textPrimary
                    font.family: root.theme.bodyFont; font.pixelSize: 13
                    font.weight: workspace.selected ? Font.Medium : Font.Normal
                    scale: pointer.pressed ? 0.94 : 1
                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                }
                MouseArea {
                    id: pointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activate(workspace.modelData)
                }
            }
        }
    }
}
