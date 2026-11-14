import QtQuick

// A hit target only. The bar owns the material; this handle paints nothing.
FocusScope {
    id: root
    property real progress: 1
    property real travel: 448
    property bool expanded: true
    readonly property bool dragging: pointer.pressed
    signal dragStarted()
    signal dragged(real progress)
    signal released(bool expanded)
    height: 44
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: expanded ? "Ocultar coluna de conversas e grupos" : "Mostrar coluna de conversas e grupos"
    Accessible.onPressAction: released(!expanded)
    Keys.onReturnPressed: released(!expanded)
    Keys.onSpacePressed: released(!expanded)
    MouseArea {
        id: pointer
        anchors.fill: parent
        preventStealing: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.SizeVerCursor
        property real startY: 0
        property real startProgress: 1
        property real displacement: 0
        property bool moved: false
        onPressed: mouse => {
            startY = mapToItem(null,mouse.x,mouse.y).y
            startProgress = root.progress; displacement = 0; moved = false
            root.dragStarted()
        }
        onPositionChanged: mouse => {
            if (!pressed) return
            displacement = mapToItem(null,mouse.x,mouse.y).y - startY
            if (!moved && Math.abs(displacement) < 4) return
            moved = true
            root.dragged(Math.max(0,Math.min(1,startProgress + displacement / Math.max(1,root.travel))))
        }
        onReleased: root.released(moved ? Math.abs(displacement) >= 24 ? displacement > 0 : root.progress >= .5 : root.expanded)
        onCanceled: root.released(root.expanded)
    }
}
