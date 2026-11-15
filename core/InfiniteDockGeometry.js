.pragma library

function unit(width, height) { return Math.min(1, width / 1280, height / 720) }
function dockWidth(width, scale, count) {
    if (!count) return 0
    return Math.min(820 * scale, width * .43, (count * 44 + Math.max(0, count - 1) * 6 + 24) * scale)
}
function shoulder(width, scale) { return Math.min(28 * scale, width * .04) }
function makeWorkspaceTrack() {
    const points = [], start = Math.acos(166 / 188), end = Math.acos(92 / 188)
    let length = 0
    for (let sample = 0; sample <= 64; sample++) {
        const angle = start + (end - start) * sample / 64
        const dx = 188 * Math.sin(angle), dy = 124 * Math.cos(angle), normal = Math.hypot(dx, dy)
        const point = {x: 192 - 188*Math.cos(angle) - 10*dy/normal,
            y: -128 + 124*Math.sin(angle) + 10*dx/normal,
            angle: Math.atan2(dy, dx) * 180 / Math.PI}
        if (sample) length += Math.hypot(point.x - points[sample-1].x, point.y - points[sample-1].y)
        point.length = length
        points.push(point)
    }
    return points
}
var workspaceTrack = makeWorkspaceTrack()
function workspacePosition(index, count, scale) {
    const points = workspaceTrack, total = points[points.length-1].length
    const target = Math.max(0, Math.min(1, index / 4)) * total
    let upper = 1
    while (upper < points.length-1 && points[upper].length < target) upper++
    const a = points[upper-1], b = points[upper]
    const t = (target - a.length) / (b.length - a.length)
    const angle = a.angle + (b.angle - a.angle) * t
    const outside = (index < 0 ? index : index > 4 ? index - 4 : 0) * total / 4
    return {x: (a.x + (b.x-a.x)*t + outside*Math.cos(angle*Math.PI/180)) * scale,
        y: (a.y + (b.y-a.y)*t + outside*Math.sin(angle*Math.PI/180)) * scale,
        angle: angle}
}
function controlPosition(index, scale, visualWidth, visualHeight) {
    const p = workspacePosition(index * 1.8, 5, 1)
    const hw = visualWidth/2, hh = visualHeight/2, padding = 2
    // Fit an upright glyph's whole rectangle into the curved shelf. Larger
    // timer digits move down the curve instead of crossing its inner edge.
    const needed = Math.min(187, visualWidth + padding*2)
    const minimumY = -128 + 124*Math.sqrt(1-Math.pow((192-needed)/188,2)) + hh + padding
    const y = Math.min(-hh-4, Math.max(p.y + 18*Math.cos(p.angle*Math.PI/180), minimumY))
    const top = y-hh-padding
    const inside = 192-188*Math.sqrt(Math.max(0,1-Math.pow((top+128)/124,2)))
    const x = Math.max(hw+padding, Math.min(p.x-18*Math.sin(p.angle*Math.PI/180), inside-hw-padding))
    return {x:x*scale,y:y*scale}
}
function path(c, width, height, count) {
    const s = unit(width, height), half = dockWidth(width, s, count) / 2
    const left = width / 2 - half, right = width / 2 + half
    const reach = shoulder(width, s)
    c.beginPath()
    c.moveTo(0, 0)
    c.lineTo(4*s, 0)
    c.lineTo(4*s, height - 128*s)
    c.bezierCurveTo(4*s, height - 59.51665*s, 88.17047*s, height - 4*s, 192*s, height - 4*s)
    if (half > 0) {
        c.lineTo(left - reach, height - 4 * s)
        c.bezierCurveTo(left - reach*2/3, height - 4 * s, left - reach/3, height - 54 * s, left, height - 54 * s)
        c.lineTo(right, height - 54 * s)
        c.bezierCurveTo(right + reach/3, height - 54 * s, right + reach*2/3, height - 4 * s, right + reach, height - 4 * s)
    }
    c.lineTo(width - 192 * s, height - 4 * s)
    c.bezierCurveTo(width - 88.17047*s, height - 4*s, width - 4*s, height - 59.51665*s, width - 4*s, height - 128*s)
    c.lineTo(width - 4*s, 0)
    c.lineTo(width, 0)
    c.lineTo(width, height)
    c.lineTo(0, height)
    c.closePath()
}
