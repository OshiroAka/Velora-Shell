import QtQuick
import QtQuick.Controls

AbstractButton {
    id: root
    property string iconName: "person"
    property string hint: ""
    property color ink: "#f1f3f4"
    property bool selected: false
    property bool reducedMotion: false
    property bool tooltipEnabled: false
    property bool busy: false
    property real busyPhase: 0
    implicitWidth: 36; implicitHeight: 36
    hoverEnabled: true; activeFocusOnTab: enabled
    scale: pressed ? .94 : 1
    Behavior on scale { NumberAnimation { duration: root.reducedMotion ? 0 : 120; easing.type: Easing.OutCubic } }
    NumberAnimation { target: root; property: "busyPhase"; from: 0; to: 1; duration: 1100; loops: Animation.Infinite; running: root.busy && !root.reducedMotion }
    Accessible.name: hint
    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()
    background: Rectangle {
        radius: width / 2
        color: Qt.rgba(root.ink.r,root.ink.g,root.ink.b,
            root.selected ? .1 : root.hovered || root.activeFocus ? .06 : 0)
        Behavior on color { ColorAnimation { duration: root.reducedMotion ? 0 : 140 } }
    }
    contentItem: Item {
        VeloraIconMotion { id: motion; highlighted: root.hovered || root.activeFocus || root.selected; reducedMotion: root.reducedMotion }
        VeloraWhatsAppIcon {
            anchors.centerIn: parent; anchors.verticalCenterOffset: motion.lift
            width: 21; height: width; iconName: root.iconName; ink: root.ink
            scale: motion.zoom; opacity: root.busy ? .16 : root.enabled ? motion.inkOpacity : .45
        }
        Canvas {
            id: spinner
            anchors.centerIn: parent; width: 24; height: 24; visible: root.busy; antialiasing: true
            Connections { target: root; function onBusyPhaseChanged() { spinner.requestPaint() } }
            onVisibleChanged: requestPaint()
            onPaint: {
                const c=getContext("2d");c.reset();c.strokeStyle=root.ink;c.lineWidth=1.6;c.lineCap="round"
                c.beginPath();c.arc(12,12,9,root.busyPhase*Math.PI*2,root.busyPhase*Math.PI*2+Math.PI*1.4);c.stroke()
            }
        }
    }
}
