import QtQuick

Canvas {
    id: icon

    property var popup: null
    property string iconName: "search"
    property color lineColor: popup ? popup.lilac : Qt.rgba(0.58, 0.48, 0.73, 0.78)
    property int entryDelay: 40
    property real entryRotate: 0
    property real entryStartScale: 0.88
    property real entryPeakScale: 1.025

    opacity: popup ? popup.stageOpacity(entryDelay, 180) : 1
    rotation: popup ? popup.stageRotation(entryDelay, entryRotate) : 0
    scale: popup ? popup.stagePopScale(entryDelay, entryStartScale, entryPeakScale, 1.0) : 1

    onIconNameChanged: requestPaint()
    onLineColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        const s = Math.min(width, height)
        const cx = width / 2
        const cy = height / 2

        ctx.reset()
        ctx.clearRect(0, 0, width, height)
        ctx.strokeStyle = lineColor
        ctx.fillStyle = lineColor
        ctx.lineWidth = Math.max(1.4, s * 0.085)
        ctx.lineCap = "round"
        ctx.lineJoin = "round"

        if (iconName === "search") {
            ctx.beginPath()
            ctx.arc(cx - s * 0.08, cy - s * 0.08, s * 0.25, 0, Math.PI * 2)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(cx + s * 0.13, cy + s * 0.13)
            ctx.lineTo(cx + s * 0.32, cy + s * 0.32)
            ctx.stroke()
        } else if (iconName === "volume" || iconName === "volume-muted") {
            ctx.beginPath()
            ctx.moveTo(s * 0.16, s * 0.43)
            ctx.lineTo(s * 0.32, s * 0.43)
            ctx.lineTo(s * 0.52, s * 0.27)
            ctx.lineTo(s * 0.52, s * 0.73)
            ctx.lineTo(s * 0.32, s * 0.57)
            ctx.lineTo(s * 0.16, s * 0.57)
            ctx.closePath()
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(s * 0.56, s * 0.50, s * 0.20, Math.PI * 1.68, Math.PI * 0.32)
            ctx.stroke()
            if (iconName === "volume-muted") {
                ctx.beginPath()
                ctx.moveTo(s * 0.72, s * 0.36)
                ctx.lineTo(s * 0.88, s * 0.64)
                ctx.moveTo(s * 0.88, s * 0.36)
                ctx.lineTo(s * 0.72, s * 0.64)
                ctx.stroke()
            }
        } else if (iconName === "wifi") {
            for (let i = 0; i < 3; i += 1) {
                ctx.globalAlpha = 0.54 + i * 0.15
                ctx.beginPath()
                ctx.arc(cx, cy + s * 0.18, s * (0.16 + i * 0.14), Math.PI * 1.18, Math.PI * 1.82)
                ctx.stroke()
            }
            ctx.globalAlpha = 1
            ctx.beginPath()
            ctx.arc(cx, cy + s * 0.22, s * 0.035, 0, Math.PI * 2)
            ctx.fill()
        } else if (iconName === "sun") {
            ctx.beginPath()
            ctx.arc(cx, cy, s * 0.16, 0, Math.PI * 2)
            ctx.stroke()
            for (let j = 0; j < 8; j += 1) {
                const a = (j / 8) * Math.PI * 2
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(a) * s * 0.29, cy + Math.sin(a) * s * 0.29)
                ctx.lineTo(cx + Math.cos(a) * s * 0.40, cy + Math.sin(a) * s * 0.40)
                ctx.stroke()
            }
        } else if (iconName === "bell") {
            ctx.beginPath()
            ctx.moveTo(s * 0.29, s * 0.64)
            ctx.lineTo(s * 0.71, s * 0.64)
            ctx.quadraticCurveTo(s * 0.65, s * 0.53, s * 0.65, s * 0.42)
            ctx.quadraticCurveTo(s * 0.65, s * 0.24, s * 0.50, s * 0.24)
            ctx.quadraticCurveTo(s * 0.35, s * 0.24, s * 0.35, s * 0.42)
            ctx.quadraticCurveTo(s * 0.35, s * 0.53, s * 0.29, s * 0.64)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(s * 0.44, s * 0.74)
            ctx.quadraticCurveTo(s * 0.50, s * 0.81, s * 0.56, s * 0.74)
            ctx.stroke()
        } else if (iconName === "display") {
            roundRect(ctx, s * 0.18, s * 0.24, s * 0.64, s * 0.42, s * 0.05)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(cx, s * 0.67)
            ctx.lineTo(cx, s * 0.78)
            ctx.moveTo(s * 0.38, s * 0.80)
            ctx.lineTo(s * 0.62, s * 0.80)
            ctx.stroke()
        } else if (iconName === "settings") {
            ctx.beginPath()
            ctx.arc(cx, cy, s * 0.25, 0, Math.PI * 2)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(cx, cy, s * 0.08, 0, Math.PI * 2)
            ctx.stroke()
        } else if (iconName === "lock") {
            roundRect(ctx, s * 0.30, s * 0.44, s * 0.40, s * 0.34, s * 0.05)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(cx, s * 0.45, s * 0.16, Math.PI, 0)
            ctx.stroke()
        } else if (iconName === "moon") {
            ctx.beginPath()
            ctx.arc(cx, cy, s * 0.28, Math.PI * 0.35, Math.PI * 1.70)
            ctx.quadraticCurveTo(s * 0.62, s * 0.56, s * 0.69, s * 0.28)
            ctx.stroke()
        } else if (iconName === "image") {
            roundRect(ctx, s * 0.20, s * 0.24, s * 0.60, s * 0.52, s * 0.05)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(s * 0.62, s * 0.38, s * 0.045, 0, Math.PI * 2)
            ctx.fill()
            ctx.beginPath()
            ctx.moveTo(s * 0.25, s * 0.68)
            ctx.lineTo(s * 0.43, s * 0.50)
            ctx.lineTo(s * 0.56, s * 0.63)
            ctx.lineTo(s * 0.67, s * 0.52)
            ctx.lineTo(s * 0.78, s * 0.68)
            ctx.stroke()
        } else if (iconName === "memo") {
            roundRect(ctx, s * 0.24, s * 0.20, s * 0.52, s * 0.60, s * 0.05)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(s * 0.35, s * 0.42)
            ctx.lineTo(s * 0.64, s * 0.42)
            ctx.moveTo(s * 0.35, s * 0.55)
            ctx.lineTo(s * 0.58, s * 0.55)
            ctx.stroke()
        } else if (iconName === "bluetooth") {
            ctx.beginPath()
            ctx.moveTo(cx, s * 0.18)
            ctx.lineTo(s * 0.68, s * 0.34)
            ctx.lineTo(cx, s * 0.50)
            ctx.lineTo(s * 0.68, s * 0.66)
            ctx.lineTo(cx, s * 0.82)
            ctx.lineTo(cx, s * 0.18)
            ctx.moveTo(cx, s * 0.50)
            ctx.lineTo(s * 0.32, s * 0.34)
            ctx.moveTo(cx, s * 0.50)
            ctx.lineTo(s * 0.32, s * 0.66)
            ctx.stroke()
        } else if (iconName === "battery") {
            roundRect(ctx, s * 0.24, s * 0.25, s * 0.46, s * 0.50, s * 0.06)
            ctx.stroke()
            roundRect(ctx, s * 0.38, s * 0.18, s * 0.18, s * 0.07, s * 0.03)
            ctx.stroke()
            roundRect(ctx, s * 0.31, s * 0.52, s * 0.32, s * 0.16, s * 0.03)
            ctx.fill()
        } else if (iconName === "clock") {
            ctx.beginPath()
            ctx.arc(cx, cy, s * 0.31, 0, Math.PI * 2)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(cx, cy)
            ctx.lineTo(cx, s * 0.32)
            ctx.moveTo(cx, cy)
            ctx.lineTo(s * 0.64, s * 0.58)
            ctx.stroke()
        } else if (iconName === "spark") {
            ctx.beginPath()
            ctx.moveTo(cx, s * 0.16)
            ctx.lineTo(cx + s * 0.09, cy - s * 0.09)
            ctx.lineTo(s * 0.84, cy)
            ctx.lineTo(cx + s * 0.09, cy + s * 0.09)
            ctx.lineTo(cx, s * 0.84)
            ctx.lineTo(cx - s * 0.09, cy + s * 0.09)
            ctx.lineTo(s * 0.16, cy)
            ctx.lineTo(cx - s * 0.09, cy - s * 0.09)
            ctx.closePath()
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(s * 0.74, s * 0.24, s * 0.035, 0, Math.PI * 2)
            ctx.fill()
            ctx.beginPath()
            ctx.arc(s * 0.26, s * 0.76, s * 0.028, 0, Math.PI * 2)
            ctx.fill()
        } else if (iconName === "folder" || iconName === "home") {
            ctx.beginPath()
            ctx.moveTo(s * 0.18, s * 0.34)
            ctx.lineTo(s * 0.38, s * 0.34)
            ctx.lineTo(s * 0.46, s * 0.42)
            ctx.lineTo(s * 0.82, s * 0.42)
            ctx.lineTo(s * 0.82, s * 0.74)
            ctx.lineTo(s * 0.18, s * 0.74)
            ctx.closePath()
            ctx.stroke()
        } else if (iconName === "globe" || iconName === "browser") {
            ctx.beginPath()
            ctx.arc(cx, cy, s * 0.32, 0, Math.PI * 2)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(s * 0.18, cy)
            ctx.lineTo(s * 0.82, cy)
            ctx.moveTo(cx, s * 0.18)
            ctx.bezierCurveTo(s * 0.38, s * 0.34, s * 0.38, s * 0.66, cx, s * 0.82)
            ctx.moveTo(cx, s * 0.18)
            ctx.bezierCurveTo(s * 0.62, s * 0.34, s * 0.62, s * 0.66, cx, s * 0.82)
            ctx.stroke()
        } else {
            roundRect(ctx, s * 0.24, s * 0.28, s * 0.52, s * 0.44, s * 0.05)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(s * 0.34, s * 0.40)
            ctx.lineTo(s * 0.50, s * 0.52)
            ctx.lineTo(s * 0.66, s * 0.40)
            ctx.stroke()
        }
    }

    function roundRect(ctx, x, y, w, h, r) {
        ctx.beginPath()
        ctx.moveTo(x + r, y)
        ctx.lineTo(x + w - r, y)
        ctx.quadraticCurveTo(x + w, y, x + w, y + r)
        ctx.lineTo(x + w, y + h - r)
        ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h)
        ctx.lineTo(x + r, y + h)
        ctx.quadraticCurveTo(x, y + h, x, y + h - r)
        ctx.lineTo(x, y + r)
        ctx.quadraticCurveTo(x, y, x + r, y)
        ctx.closePath()
    }
}
