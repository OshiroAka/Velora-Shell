import QtQuick

Item {
    id: root

    property real level: 1
    property bool charging: false
    property color color: "white"
    property bool available: true
    property color warningColor: "#e7bd76"
    property color criticalColor: "#e07282"
    readonly property color chargeColor: !available ? Qt.rgba(color.r, color.g, color.b, 0.4)
        : !charging && level <= 0.08 ? criticalColor : !charging && level <= 0.20 ? warningColor : color
    Accessible.role: Accessible.Indicator
    Accessible.name: !available ? "Bateria indisponível" : Math.round(level * 100) + "%" + (charging ? ", carregando" : "")

    width: 30
    height: 18

    Rectangle {
        id: body
        x: 1
        y: 3
        width: 24
        height: 13
        radius: 3
        color: "transparent"
        border.width: 1.4
        border.color: root.chargeColor

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 3
            width: root.available ? (parent.width - 6) * Math.max(0, Math.min(1, root.level)) : 0
            radius: 1.5
            color: root.chargeColor

            Behavior on width {
                NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
            }
        }
    }

    Rectangle {
        x: 26
        y: 7
        width: 3
        height: 6
        radius: 1.5
        color: root.chargeColor
    }

    Canvas {
        id: chargingMark
        visible: root.charging
        anchors.centerIn: body
        width: 9; height: 12
        onPaint: {
            const c = getContext("2d"); c.reset()
            c.beginPath(); c.moveTo(5.5, 0); c.lineTo(1, 7); c.lineTo(4, 7)
            c.lineTo(3.5, 12); c.lineTo(8, 5); c.lineTo(5, 5); c.closePath()
            c.fillStyle = "#25302b"; c.fill(); c.strokeStyle = root.color; c.lineWidth = 0.7; c.stroke()
        }
        Connections { target: root; function onColorChanged() { chargingMark.requestPaint() } }
    }
    Text {
        visible: !root.available
        anchors.centerIn: body
        text: "–"
        color: root.chargeColor
        font.pixelSize: 10
    }
}
