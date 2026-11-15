.pragma library

function unit(width, height) { return Math.min(1, width / 1280, height / 720) }
function dockWidth(width, scale, count) {
    if (!count) return 0
    return Math.min(820 * scale, width * .43, (count * 44 + Math.max(0, count - 1) * 6 + 24) * scale)
}
function shoulder(width, scale) { return Math.min(140 * scale, width * .09) }
function workspacePosition(index, count, scale) {
    // Place the glyphs at a constant normal offset from the very same
    // parabola as the material, and distribute them by arc length.
    const k = 320 / 246
    function arc(x) {
        const m = k * (1 - x / 246)
        return -246 / (2 * k) * (m * Math.sqrt(1 + m*m) + Math.asinh(m))
    }
    const start = 34, end = 140, a = arc(start), b = arc(end)
    const t = Math.max(0, Math.min(1, index / 4)), target = a + (b - a) * t
    let low = start, high = end
    for (let iteration = 0; iteration < 16; iteration++) {
        const middle = (low + high) / 2
        if (arc(middle) < target) low = middle
        else high = middle
    }
    const x = (low + high) / 2, q = 1 - x / 246, slope = k * q
    const normal = Math.sqrt(1 + slope*slope)
    const outside = index < 0 ? index : index > 4 ? index - 4 : 0
    return {x: (x - 18*slope/normal + outside*(b-a)/4/normal) * scale,
        y: (-4 - 160*q*q + 18/normal + outside*(b-a)/4*slope/normal) * scale,
        angle: Math.atan(slope) * 180 / Math.PI}
}
function path(c, width, height, count) {
    const s = unit(width, height), half = dockWidth(width, s, count) / 2
    const left = width / 2 - half, right = width / 2 + half
    const reach = shoulder(width, s)
    c.beginPath()
    c.moveTo(0, height - 164 * s)
    c.quadraticCurveTo(123 * s, height - 4 * s, 246 * s, height - 4 * s)
    if (half > 0) {
        c.lineTo(left - reach, height - 4 * s)
        c.bezierCurveTo(left - reach*2/3, height - 4 * s, left - reach/3, height - 54 * s, left, height - 54 * s)
        c.lineTo(right, height - 54 * s)
        c.bezierCurveTo(right + reach/3, height - 54 * s, right + reach*2/3, height - 4 * s, right + reach, height - 4 * s)
    }
    c.lineTo(width - 246 * s, height - 4 * s)
    c.quadraticCurveTo(width - 123 * s, height - 4 * s, width, height - 164 * s)
    c.lineTo(width, height)
    c.lineTo(0, height)
    c.closePath()
}
