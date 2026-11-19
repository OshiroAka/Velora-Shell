import QtQuick

WidgetSurface {
    id: root
    required property var status
    readonly property bool circular: variantId === "ring"
    readonly property real level: status.hasBattery ? Math.max(0, Math.min(1, status.batteryLevel)) : 0
    readonly property bool chargingMotion: animateContent && status.hasBattery && status.batteryCharging && level < .995
    width: 270; height: 150
    Text {
        x: 20; y: 17; text: "BATERIA"; color: root.mutedColor
        font.family: root.contentFont; font.pixelSize: 10; font.letterSpacing: 2
    }
    Canvas {
        id: ring
        objectName: "battery.ring"
        visible: root.circular
        anchors.centerIn: parent; anchors.verticalCenterOffset: 3
        width: Math.max(0, Math.min(root.width - 56, root.height - 70)); height: width
        property real value: root.level
        property color ink: root.contentColor
        property real breathingOpacity: 1
        opacity: breathing.running ? breathingOpacity : 1
        SequentialAnimation on breathingOpacity {
            id: breathing
            running: root.animateContent && ring.visible && root.status.hasBattery && !root.status.batteryCharging
            loops: Animation.Infinite
            NumberAnimation { from: 1; to: .78; duration: root.motionDuration * 7; easing.type: Easing.InOutSine }
            NumberAnimation { from: .78; to: 1; duration: root.motionDuration * 7; easing.type: Easing.InOutSine }
        }
        onValueChanged: requestPaint()
        onInkChanged: requestPaint()
        onWidthChanged: requestPaint()
        Behavior on value {
            NumberAnimation { duration: root.motionDuration; easing.type: Easing.OutCubic }
        }
        onPaint: {
            if (width <= 10)
                return
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
    Item {
        id: chargeOrbit
        objectName: "battery.chargeOrbit"
        anchors.fill: ring
        visible: root.circular && root.chargingMotion && ring.width > 10
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: -2; width: 14; height: 14; radius: 7
            color: root.theme.accentSoft; opacity: .25
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 1; width: 8; height: 8; radius: 4
            color: root.theme.accentSoft
        }
        NumberAnimation on rotation {
            running: chargeOrbit.visible
            from: 0; to: 360; duration: root.motionDuration * 12
            loops: Animation.Infinite
        }
    }
    DotMatrixText {
        objectName: "battery.value"
        x: root.circular ? (root.width - width) / 2 : 20
        y: root.circular ? (root.height - height) / 2 + 3 : 46
        width: root.circular ? root.width * .42 : root.width * .49; height: 44
        text: root.status.hasBattery ? String(root.status.batteryPercent) : "—"
        color: root.contentColor
        duration: root.motionDuration
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
                    Behavior on opacity {
                        NumberAnimation { duration: root.motionDuration; easing.type: Easing.OutCubic }
                    }
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
