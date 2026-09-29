import QtQuick
import QtQuick.Controls

FocusScope {
    id: root
    required property var theme
    property string label: ""
    property bool selected: false
    property bool interactive: true
    property bool reducedMotion: false
    property bool scrollable: false
    readonly property bool hovered: pointer.containsMouse
    property bool dragToCreate: false
    signal draggedDown()
    signal activated()
    signal secondaryActivated()
    signal scrolled(real delta)
    activeFocusOnTab: interactive
    scale: pointer.pressed ? 0.98 : 1
    Behavior on scale { NumberAnimation { duration: root.reducedMotion ? 0 : 110; easing.type: Easing.OutCubic } }
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: if (interactive) activated()
    Keys.onReturnPressed: if (interactive) activated()
    Keys.onSpacePressed: if (interactive) activated()

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: 9
        color: root.theme.withAlpha(root.theme.accent,
            root.selected ? 0.18 : root.hovered ? 0.075 : 0)
        border.width: root.activeFocus ? 1 : 0
        border.color: root.theme.accentSoft
        Behavior on color { ColorAnimation { duration: root.reducedMotion ? 0 : 120 } }
    }
    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        property real pressY: 0
        property bool dragged: false
        onPressed: mouse => { pressY = mouse.y; dragged = false }
        onPositionChanged: mouse => {
            if (pressed && root.dragToCreate && !dragged && mouse.y - pressY > 16) {
                dragged = true; root.draggedDown()
            }
        }
        onClicked: mouse => { if (!dragged) mouse.button === Qt.RightButton ? root.secondaryActivated() : root.activated() }
        onWheel: wheel => {
            if (!root.scrollable || wheel.angleDelta.y === 0) { wheel.accepted = false; return }
            root.scrolled(wheel.angleDelta.y > 0 ? 1 : -1)
            wheel.accepted = true
        }
    }
    ToolTip.visible: hovered && label.length > 0 && !selected
    ToolTip.delay: 700
    ToolTip.text: label
}
