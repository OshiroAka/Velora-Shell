import QtQuick

// Shared drawing keeps the edge and topbar app glyphs identical.
Canvas {
    id: root
    property string iconName: "Spotify"
    property color ink: "white"
    implicitWidth: 28; implicitHeight: 28
    antialiasing: true
    onIconNameChanged: requestPaint()
    onInkChanged: requestPaint()
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
        if (root.iconName === "Spotify") {
            c.beginPath(); c.arc(12, 12, 9.5, 0, Math.PI * 2); c.stroke()
            for (let i = 0; i < 3; i++) {
                c.beginPath()
                c.moveTo(6.5 + i * .5, 8.4 + i * 3.3)
                c.quadraticCurveTo(12, 6.5 + i * 3.3, 18 - i * .65, 10 + i * 3)
                c.stroke()
            }
        } else if (root.iconName === "Discord") {
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
        } else if (root.iconName === "Steam") {
            c.beginPath(); c.arc(12, 12, 9.5, 0, Math.PI * 2); c.stroke()
            c.beginPath(); c.arc(15.6, 8.4, 3.2, 0, Math.PI * 2); c.stroke()
            c.beginPath(); c.arc(6.8, 15.8, 2.4, -.6, Math.PI * 1.6); c.stroke()
            c.beginPath(); c.moveTo(8.1, 13.8); c.lineTo(12.8, 9.9)
            c.moveTo(9, 16); c.lineTo(15.2, 11.6)
            c.moveTo(2.6, 13.5); c.lineTo(5.2, 14.2); c.stroke()
        } else if (root.iconName === "Zen") {
            for (const radius of [9.5, 5.1]) {
                c.beginPath(); c.arc(12, 12, radius, 0, Math.PI * 2); c.stroke()
            }
            c.beginPath(); c.arc(12, 12, 0.8, 0, Math.PI * 2); c.fill()
        } else if (root.iconName === "Brave") {
            // Keep the shield and the lion's main features, omitting fur texture.
            c.beginPath(); c.moveTo(7, 3); c.lineTo(17, 3)
            c.lineTo(20, 6); c.lineTo(18.5, 15.5); c.lineTo(12, 21.5)
            c.lineTo(5.5, 15.5); c.lineTo(4, 6); c.closePath(); c.stroke()
            c.beginPath(); c.moveTo(7.5, 8); c.lineTo(9, 6); c.lineTo(12, 7)
            c.lineTo(15, 6); c.lineTo(16.5, 8)
            c.moveTo(7.5, 10); c.lineTo(10, 10.8)
            c.moveTo(16.5, 10); c.lineTo(14, 10.8)
            c.moveTo(10, 13); c.lineTo(12, 14.5); c.lineTo(14, 13)
            c.moveTo(9, 16); c.lineTo(12, 18); c.lineTo(15, 16); c.stroke()
        } else if (root.iconName === "WallpaperEngine") {
            c.beginPath(); c.roundedRect(3, 4.5, 18, 14, 2, 2); c.stroke()
            c.beginPath(); c.arc(12, 11.5, 3.5, 0, Math.PI * 2); c.stroke()
            c.beginPath(); c.moveTo(12, 18.5); c.lineTo(12, 21)
            c.moveTo(8, 21); c.lineTo(16, 21)
            c.moveTo(18, 7.5); c.lineTo(18.1, 7.5); c.stroke()
        } else {
            c.beginPath()
            c.moveTo(4.2, 17)
            c.bezierCurveTo(-1, 9, 6, 1, 13, 2.5)
            c.bezierCurveTo(24, 4, 24, 19, 13, 21)
            c.quadraticCurveTo(8, 22, 6, 19.7)
            c.lineTo(2.5, 21); c.closePath(); c.stroke()
            c.beginPath()
            c.moveTo(8, 7); c.lineTo(9.5, 9.5); c.lineTo(8.5, 10.7)
            c.quadraticCurveTo(10, 13.7, 13, 15)
            c.lineTo(14.5, 13.7); c.lineTo(17, 15)
            c.quadraticCurveTo(17.2, 18, 14, 17)
            c.bezierCurveTo(9, 16, 6, 12, 6.5, 8.5)
            c.quadraticCurveTo(6.5, 7, 8, 7)
            c.closePath(); c.stroke()
        }
    }
}
