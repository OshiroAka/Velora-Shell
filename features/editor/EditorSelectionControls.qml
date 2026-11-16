pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../../components" as Components

Rectangle {
    id: root
    required property var editor
    required property var widgetLayer
    required property var theme
    required property var motion
    property real desiredX: 0
    property real desiredY: 0
    property real heldX: 0
    property real heldY: 0
    property bool interactionHeld: false
    readonly property bool editable: !!widgetLayer && !widgetLayer.locked
    x: interactionHeld ? heldX : desiredX
    y: interactionHeld ? heldY : desiredY
    height: controls.height + 16
    radius: 14
    color: theme.surfaceRaised
    border.width: 1
    border.color: theme.borderSubtle
    objectName: "editorSelectionControls"

    function beginAdjustment() {
        if (!widgetLayer || !editor.beginGesture(widgetLayer.id)) return
        heldX = desiredX; heldY = desiredY
        interactionHeld = true
    }
    function finishAdjustment() {
        if (interactionHeld) editor.finishGesture()
        interactionHeld = false
    }
    function remove() {
        if (editor.removeSelected()) editor.clearSelection()
    }
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

    component Adjustment: Column {
        id: adjustment
        required property string label
        required property string field
        required property real maximum
        property real minimum: 0
        readonly property real currentValue: {
            if (!root.widgetLayer) return 100
            const pose = root.editor.gestureActive && root.editor.gestureLayerId === root.widgetLayer.id
                ? Object.assign({}, root.widgetLayer.transform, root.editor.gesturePatch) : root.widgetLayer.transform
            return Number(pose && pose[field] !== undefined ? pose[field] : 1) * 100
        }
        width: controls.width < 256 ? Math.max(0, controls.width - 54) : (controls.width - 66) / 2
        spacing: 0
        Text {
            text: adjustment.label + " · " + Math.round(slider.value) + "%"
            color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 10
        }
        Slider {
            id: slider
            objectName: "editorSelection." + adjustment.field
            width: parent.width; height: 26
            enabled: root.editable
            from: adjustment.minimum; to: adjustment.maximum; stepSize: 1
            value: adjustment.currentValue
            Accessible.name: adjustment.label
            Keys.onPressed: event => {
                if (root.widgetLayer && (event.key === Qt.Key_Home || event.key === Qt.Key_End)) {
                    root.editor.setTransform(root.widgetLayer.id, adjustment.field, (event.key === Qt.Key_Home ? from : to) / 100)
                    event.accepted = true
                }
            }
            onPressedChanged: {
                if (pressed) root.beginAdjustment()
                else root.finishAdjustment()
            }
            onMoved: {
                if (!root.widgetLayer) return
                const patch = ({})
                patch[adjustment.field] = value / 100
                if (pressed && root.interactionHeld) root.editor.previewTransform(root.widgetLayer.id, patch)
                else if (!pressed) root.editor.setTransform(root.widgetLayer.id, adjustment.field, value / 100)
            }
        }
    }
    Flow {
        id: controls
        x: 10; y: 8; width: Math.max(0, parent.width - 20)
        height: childrenRect.height; spacing: 12
        Rectangle {
            id: removeButton
            objectName: "editorSelection.delete"
            width: 42; height: 40; radius: 11
            color: hover.hovered ? "#503a262d" : "#283a262d"
            activeFocusOnTab: true
            Accessible.role: Accessible.Button; Accessible.name: "Apagar widget"
            Accessible.onPressAction: root.remove()
            Keys.onReturnPressed: root.remove()
            Keys.onSpacePressed: root.remove()
            Components.VeloraMaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter; y: 3; width: 18; height: 18
                iconName: "close"; iconColor: "#f09caa"
            }
            Text { anchors.horizontalCenter: parent.horizontalCenter; y: 22; text: "Apagar"; color: "#f09caa"; font.family: root.theme.bodyFont; font.pixelSize: 10 }
            HoverHandler { id: hover }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.remove() }
        }
        Adjustment { label: "Tamanho"; field: "scale"; minimum: 10; maximum: 300 }
        Adjustment { label: "Opacidade"; field: "opacity"; maximum: 100 }
    }
}
