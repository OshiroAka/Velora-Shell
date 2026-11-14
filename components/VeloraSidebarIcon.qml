import QtQuick

// Same 24-unit grid, rounded 1.65-unit stroke and single ink as VeloraEdgeApps.
Canvas {
    id: root
    property string iconName: "volume"
    property color ink: "white"
    property real level: 1
    implicitWidth: 22
    implicitHeight: 22
    antialiasing: true
    onIconNameChanged: requestPaint()
    onInkChanged: requestPaint()
    onLevelChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const c = getContext("2d")
        c.reset()
        c.scale(width / 24, height / 24)
        c.strokeStyle = root.ink
        c.fillStyle = root.ink
        c.lineWidth = 1.65
        c.lineCap = "round"
        c.lineJoin = "round"
        function line(x, y, x2, y2) {
            c.beginPath(); c.moveTo(x, y); c.lineTo(x2, y2); c.stroke()
        }
        function dot(x, y, radius) {
            c.beginPath(); c.arc(x, y, radius, 0, Math.PI * 2); c.fill()
        }
        if (iconName === "play") {
            c.beginPath(); c.moveTo(8, 5); c.lineTo(19, 12); c.lineTo(8, 19)
            c.closePath(); c.stroke()
        } else if (iconName === "pause") {
            c.beginPath(); c.roundedRect(6, 5, 4, 14, 1, 1)
            c.roundedRect(14, 5, 4, 14, 1, 1); c.stroke()
        } else if (iconName === "skip-previous" || iconName === "skip-next") {
            if (iconName === "skip-previous") { c.translate(24, 0); c.scale(-1, 1) }
            c.beginPath(); c.moveTo(5, 6); c.lineTo(14, 12); c.lineTo(5, 18)
            c.closePath(); c.stroke(); line(18, 6, 18, 18)
        } else if (iconName === "notes") {
            c.beginPath()
            c.moveTo(6, 3); c.lineTo(14, 3); c.lineTo(19, 8); c.lineTo(19, 20)
            c.quadraticCurveTo(19, 21, 18, 21); c.lineTo(6, 21)
            c.quadraticCurveTo(5, 21, 5, 20); c.lineTo(5, 4)
            c.quadraticCurveTo(5, 3, 6, 3); c.closePath(); c.stroke()
            c.beginPath(); c.moveTo(14, 3); c.lineTo(14, 8); c.lineTo(19, 8); c.stroke()
            line(8, 12, 16, 12); line(8, 16, 14, 16)
        } else if (iconName === "discord") {
            // Identical silhouette to the Discord icon on the right edge.
            c.beginPath()
            c.moveTo(7, 5.2); c.lineTo(9, 4.6); c.lineTo(9.8, 6)
            c.quadraticCurveTo(12, 5.5, 14.2, 6)
            c.lineTo(15, 4.6); c.lineTo(17, 5.2)
            c.quadraticCurveTo(20.5, 9.5, 21, 16)
            c.quadraticCurveTo(18.5, 18, 16.4, 18.5)
            c.lineTo(15.3, 16.8)
            c.quadraticCurveTo(12, 17.8, 8.7, 16.8)
            c.lineTo(7.6, 18.5)
            c.quadraticCurveTo(5.5, 18, 3, 16)
            c.quadraticCurveTo(3.5, 9.5, 7, 5.2)
            c.closePath(); c.stroke()
            c.beginPath(); c.ellipse(7.5, 10, 3, 4); c.fill()
            c.beginPath(); c.ellipse(13.5, 10, 3, 4); c.fill()
        } else if (iconName === "volume" || iconName === "volume-muted") {
            c.beginPath(); c.moveTo(3, 9); c.lineTo(7, 9); c.lineTo(12, 5)
            c.lineTo(12, 19); c.lineTo(7, 15); c.lineTo(3, 15)
            c.closePath(); c.stroke()
            if (iconName === "volume-muted") {
                line(16, 9, 21, 15); line(21, 9, 16, 15)
            } else {
                for (let i = 0; i < 2; ++i) {
                    c.globalAlpha = root.level > i * 0.5 ? 1 : 0.25
                    c.beginPath(); c.arc(12, 12, 5 + i * 4, -0.75, 0.75); c.stroke()
                }
            }
        } else if (iconName === "sun") {
            c.beginPath(); c.arc(12, 12, 4, 0, Math.PI * 2); c.stroke()
            for (let i = 0; i < 8; ++i) {
                const angle = i * Math.PI / 4
                line(12 + Math.cos(angle) * 7, 12 + Math.sin(angle) * 7,
                     12 + Math.cos(angle) * 9.5, 12 + Math.sin(angle) * 9.5)
            }
        } else if (iconName === "bell") {
            c.beginPath(); c.moveTo(5, 17)
            c.quadraticCurveTo(7, 15, 7, 10)
            c.bezierCurveTo(7, 3, 17, 3, 17, 10)
            c.quadraticCurveTo(17, 15, 19, 17)
            c.closePath(); c.stroke()
            line(12, 3, 12, 4.5)
            c.beginPath(); c.arc(12, 18.5, 2, 0.25, Math.PI - 0.25); c.stroke()
        } else if (iconName === "bluetooth") {
            c.beginPath(); c.moveTo(7, 7); c.lineTo(17, 17)
            c.lineTo(12, 21); c.lineTo(12, 3); c.lineTo(17, 7)
            c.lineTo(7, 17); c.stroke()
        } else if (iconName === "wifi") {
            for (let i = 0; i < 3; ++i) {
                c.beginPath(); c.arc(12, 20, 5 + i * 4, -2.35, -0.79); c.stroke()
            }
            dot(12, 20, 1)
        } else if (iconName === "battery") {
            c.beginPath(); c.roundedRect(2, 6.5, 18, 11, 2, 2); c.stroke()
            line(22, 10, 22, 14)
            const fill = Math.max(0, Math.min(1, root.level)) * 13
            if (fill > 0) c.fillRect(4.5, 9, fill, 6)
        } else if (iconName === "settings") {
            for (let i = 0; i < 3; ++i) {
                const y = 6 + i * 6
                const x = i === 1 ? 15 : 9
                line(3, y, x - 2, y); line(x + 2, y, 21, y)
                c.beginPath(); c.arc(x, y, 2, 0, Math.PI * 2); c.stroke()
            }
        }
    }
}
