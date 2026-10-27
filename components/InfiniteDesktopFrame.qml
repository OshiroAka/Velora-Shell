import QtQuick

Canvas {
    id: root
    property real progress: 0
    property real railWidth: 63
    property real oppositeWidth: 4
    property real bottomHeight: 16
    property real cornerRadius: 24
    property bool rightSide: false
    property color surface: "#a0202029"
    antialiasing: true
    onProgressChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onSurfaceChanged: requestPaint()
    onRightSideChanged: requestPaint()
    onVisibleChanged: if (visible) requestPaint()
    onPaint: {
        const c = getContext("2d")
        c.clearRect(0, 0, width, height)
        const remain = 1 - progress
        const railRemain = Math.min(1, remain / .22)
        const gather = Math.min(1, progress / .35)
        const rise = Math.max(0, (progress - .35) / .65)
        const extent = height * (1 - rise)
        if (extent < .01) return
        const left = railWidth * railRemain
        const right = width - oppositeWidth * railRemain
        const bottom = extent - Math.min(extent / 2, bottomHeight * railRemain)
        const r = Math.min(cornerRadius * (1 - rise), bottom / 2)
        c.save()
        if (rightSide) { c.translate(width, 0); c.scale(-1, 1) }
        const leftEnd = width / 2 + (left + r - width / 2) * gather
        const rightStart = width / 2 + (right - r - width / 2) * gather
        c.beginPath()
        c.rect(0, 0, leftEnd, extent)
        c.rect(rightStart, 0, width - rightStart, extent)
        c.clip()
        c.fillStyle = surface
        c.beginPath()
        c.moveTo(0, 0)
        c.lineTo(left + r, 0)
        c.arcTo(left, 0, left, r, r)
        c.lineTo(left, bottom - r)
        c.arcTo(left, bottom, left + r, bottom, r)
        c.lineTo(right - r, bottom)
        c.arcTo(right, bottom, right, bottom - r, r)
        c.lineTo(right, r)
        c.arcTo(right, 0, right - r, 0, r)
        c.lineTo(width, 0)
        c.lineTo(width, extent)
        c.lineTo(0, extent)
        c.closePath()
        c.fill()
        c.restore()
    }
}
