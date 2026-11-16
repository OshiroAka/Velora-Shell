import QtQuick

Canvas {
    id: root
    property string text: ""
    property color color: "white"
    property real dotSize: 3
    readonly property real advance: dotSize * 7
    implicitWidth: Math.max(0, text.length * advance - dotSize * 2)
    implicitHeight: dotSize * 9
    onTextChanged: requestPaint()
    onColorChanged: requestPaint()
    onDotSizeChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    // Paint only when the displayed value changes; no timer or frame callback.
    onPaint: {
        const glyphs = {
            "0":[14,17,19,21,25,17,14], "1":[4,12,4,4,4,4,14],
            "2":[14,17,1,2,4,8,31], "3":[30,1,1,14,1,1,30],
            "4":[2,6,10,18,31,2,2], "5":[31,16,16,30,1,1,30],
            "6":[14,16,16,30,17,17,14], "7":[31,1,2,4,8,8,8],
            "8":[14,17,17,14,17,17,14], "9":[14,17,17,15,1,1,14],
            ":":[0,4,4,0,4,4,0], ".":[0,0,0,0,0,4,4],
            "—":[0,0,0,31,0,0,0], "-":[0,0,0,31,0,0,0],
            "%":[25,26,2,4,8,11,19], "°":[6,9,9,6,0,0,0]
        }
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        ctx.fillStyle = color
        const unit = Math.min(width / Math.max(1, text.length * 7 - 2), height / 9)
        const offsetY = (height - 7 * unit) / 2
        for (let i = 0; i < text.length; ++i) {
            const rows = glyphs[text[i]] || [0,0,0,0,0,0,0]
            for (let row = 0; row < 7; ++row) {
                for (let column = 0; column < 5; ++column) {
                    if (rows[row] & (1 << (4 - column))) {
                        ctx.beginPath()
                        ctx.arc(i * 7 * unit + (column + .5) * unit,
                            offsetY + (row + .5) * unit, unit * .38, 0, Math.PI * 2)
                        ctx.fill()
                    }
                }
            }
        }
    }
}
