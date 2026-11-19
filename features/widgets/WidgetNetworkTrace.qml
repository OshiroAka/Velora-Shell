import QtQuick

Canvas {
    id: root
    property var samples: []
    property color ink: "white"
    onSamplesChanged: requestPaint()
    onInkChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        if (samples.length < 2 || width < 2 || height < 2)
            return
        ctx.beginPath()
        for (let i = 0; i < samples.length; ++i) {
            const x = 1 + (width - 2) * i / (samples.length - 1)
            const y = height - 1 - (height - 2) * samples[i]
            if (i === 0) ctx.moveTo(x, y)
            else ctx.lineTo(x, y)
        }
        ctx.strokeStyle = ink
        ctx.lineWidth = 1.4
        ctx.lineJoin = "round"
        ctx.stroke()
    }
}
