import QtQuick
import "."

Item {
    id: root

    implicitWidth: 42
    implicitHeight: ShinConfig.barH

    property bool hoverRoot: false

    function canvasColor(c, alpha) {
        var a = alpha === undefined ? 1 : alpha
        return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + a + ")"
    }

    ShinPill {
        anchors.fill: parent
        anchors.topMargin: (parent.height - ShinConfig.pillH) / 2
        anchors.bottomMargin: (parent.height - ShinConfig.pillH) / 2
        hovered: root.hoverRoot
        clickable: true
        active: ShinPopup.active === "wallpapers"
        onClicked: {
            if (ShinConfig.wallpaperSelectorEnabled)
                ShinPopup.toggle("wallpapers")
            else {
                ShinData.save("settingsCategory", "wallpapers")
                ShinPopup.open("settings")
            }
        }
    }

    Canvas {
        id: wallpaperIcon
        anchors.centerIn: parent
        width: 18
        height: 18
        scale: root.hoverRoot ? 1.06 : 1.0

        Behavior on scale { NumberAnimation { duration: ShinData.anim(140); easing.type: Easing.OutCubic } }

        onPaint: {
            var ctx = getContext("2d")
            var w = width
            var h = height
            ctx.clearRect(0, 0, w, h)
            ctx.lineWidth = 1.7
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.strokeStyle = root.canvasColor(ShinColors.fg, 0.86)
            ctx.fillStyle = root.canvasColor(ShinColors.accent, 0.10)

            ctx.beginPath()
            ctx.rect(w * 0.12, h * 0.18, w * 0.76, h * 0.64)
            ctx.fill()
            ctx.stroke()

            ctx.beginPath()
            ctx.arc(w * 0.68, h * 0.34, w * 0.07, 0, Math.PI * 2)
            ctx.fillStyle = root.canvasColor(ShinColors.accent, 0.80)
            ctx.fill()

            ctx.beginPath()
            ctx.moveTo(w * 0.18, h * 0.74)
            ctx.lineTo(w * 0.38, h * 0.52)
            ctx.lineTo(w * 0.50, h * 0.64)
            ctx.lineTo(w * 0.62, h * 0.48)
            ctx.lineTo(w * 0.84, h * 0.74)
            ctx.stroke()
        }

        Connections {
            target: ShinColors
            function onAccentChanged() { wallpaperIcon.requestPaint() }
            function onFgChanged() { wallpaperIcon.requestPaint() }
            function onWalSignatureChanged() { wallpaperIcon.requestPaint() }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onEntered: root.hoverRoot = true
        onExited: root.hoverRoot = false
        onClicked: {
            if (ShinConfig.wallpaperSelectorEnabled)
                ShinPopup.toggle("wallpapers")
            else {
                ShinData.save("settingsCategory", "wallpapers")
                ShinPopup.open("settings")
            }
        }
    }
}
