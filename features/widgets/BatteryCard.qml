import QtQuick

WidgetSurface {
    id: root
    required property var status
    readonly property bool circular: variantId === "ring"
    readonly property real level: status.hasBattery ? Math.max(0, Math.min(1, status.batteryLevel)) : 0
    width: 270; height: 150
    Text {
        x: 20; y: 17; text: "BATERIA"; color: root.mutedColor
        font.family: root.contentFont; font.pixelSize: 10; font.letterSpacing: 2
    }
    Canvas {
        id: ring; visible: root.circular
        anchors.centerIn: parent; anchors.verticalCenterOffset: 3
        width: Math.min(root.width - 56, root.height - 70); height: width
        property real value: root.level
        property color ink: root.contentColor
        onValueChanged: requestPaint()
        onInkChanged: requestPaint()
        onWidthChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0,0,width,height)
            ctx.lineWidth = 6; ctx.lineCap = "round"
            ctx.strokeStyle = root.quietColor
            ctx.beginPath(); ctx.arc(width/2,height/2,width/2-5,0,2*Math.PI); ctx.stroke()
            if (value > 0) {
                ctx.strokeStyle = ink
                ctx.beginPath(); ctx.arc(width/2,height/2,width/2-5,-Math.PI/2,-Math.PI/2+2*Math.PI*value); ctx.stroke()
            }
        }
    }
    DotMatrixText {
        objectName: "battery.value"
        x: root.circular ? (root.width - width) / 2 : 20
        y: root.circular ? (root.height - height) / 2 + 3 : 46
        width: root.circular ? root.width * .42 : root.width * .49; height: 44
        text: root.status.hasBattery ? String(root.status.batteryPercent) : "—"
        color: root.contentColor
    }
    Text {
        visible: !root.circular; x: root.width * .58; y: 69
        text: "%"; color: root.mutedColor; font.family: root.contentFont; font.pixelSize: 12
    }
    Rectangle {
        visible: !root.circular; x: parent.width - 58; y: 40; width: 30; height: 61
        color: "transparent"; radius: 5; border.width: 1.5; border.color: root.contentColor
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: -4; width: 12; height: 3; radius: 1; color: root.contentColor }
        Column {
            x: 4; y: 5; spacing: 2
            Repeater {
                model: 8
                Rectangle {
                    required property int index; width: 22; height: 4.6; radius: 1
                    color: root.contentColor; opacity: index >= 8 - Math.ceil(root.level * 8) ? 1 : .1
                }
            }
        }
    }
    Text {
        x: 20; y: parent.height - 31; width: parent.width - 40
        text: !root.status.hasBattery ? "Sem bateria" : root.status.batteryCharging ? "Carregando" : root.level >= .99 ? "Carga completa" : "Em uso"
        color: root.mutedColor; font.family: root.contentFont; font.pixelSize: 10
        horizontalAlignment: root.circular ? Text.AlignHCenter : Text.AlignLeft
    }
}
