import QtQuick
import "."

Item {
    visible: true
    id: root

    implicitWidth: 42
    implicitHeight: ShinConfig.barH

    property bool active: ShinPopup.notificationsOpen
    property bool hovered: false
    property color iconColor: root.active
        ? (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
        : Qt.rgba((ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g, (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b, root.hovered ? 0.95 : 0.72)

    ShinPill {
        anchors.fill: parent
        anchors.topMargin: (parent.height - ShinConfig.pillH) / 2
        anchors.bottomMargin: (parent.height - ShinConfig.pillH) / 2
        active: root.active || root.hovered
        clickable: false
    }

    Canvas {
        id: bellCanvas
        anchors.centerIn: parent
        width: 18
        height: 18
        scale: root.active || root.hovered ? 1.10 : 1.0
        rotation: root.active ? -7 : 0

        onPaint: {
            var ctx = getContext("2d")
            var w = width
            var h = height
            ctx.clearRect(0, 0, w, h)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.lineWidth = 2
            ctx.strokeStyle = root.iconColor
            ctx.fillStyle = root.iconColor

            ctx.beginPath()
            ctx.moveTo(w * 0.30, h * 0.70)
            ctx.lineTo(w * 0.70, h * 0.70)
            ctx.quadraticCurveTo(w * 0.62, h * 0.58, w * 0.62, h * 0.42)
            ctx.quadraticCurveTo(w * 0.62, h * 0.25, w * 0.50, h * 0.23)
            ctx.quadraticCurveTo(w * 0.38, h * 0.25, w * 0.38, h * 0.42)
            ctx.quadraticCurveTo(w * 0.38, h * 0.58, w * 0.30, h * 0.70)
            ctx.closePath()
            ctx.stroke()

            ctx.beginPath()
            ctx.moveTo(w * 0.25, h * 0.72)
            ctx.lineTo(w * 0.75, h * 0.72)
            ctx.stroke()

            ctx.beginPath()
            ctx.arc(w * 0.50, h * 0.82, w * 0.08, 0, Math.PI * 2)
            ctx.fill()
        }

        Behavior on scale { NumberAnimation { duration: ShinData.anim(140); easing.type: Easing.OutCubic } }
        Behavior on rotation { NumberAnimation { duration: ShinData.anim(160); easing.type: Easing.OutCubic } }
    }

    onIconColorChanged: bellCanvas.requestPaint()
    onActiveChanged: bellCanvas.requestPaint()
    onHoveredChanged: bellCanvas.requestPaint()

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: ShinPopup.toggleNotifications()
    }
}
