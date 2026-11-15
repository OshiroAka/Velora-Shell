.pragma library

// Pack sections in their saved order. The host centres the resulting strip;
// small outputs retain disjoint, scrollable viewports and full-size controls.
function sections(width, left, center, right, leftInset, rightInset) {
    const start = Math.min(width, Math.max(0, leftInset))
    const end = Math.max(start, width - Math.max(0, rightInset))
    const available = Math.max(0, end - start)
    const total = left + center + right
    const factor = total > 0 ? Math.min(1, available / total) : 1
    const l = left * factor, c = center * factor, r = right * factor
    return { left: {x: start, width: l}, center: {x: start + l, width: c}, right: {x: start + l + c, width: r} }
}
