.pragma library

// The standard bar keeps its left, centred and right sections. Infinite Desk
// uses the same hierarchy inside a smaller strip centred by its host.
function sections(width, left, center, right, leftInset, rightInset, packed) {
    const start = Math.min(width, Math.max(0, leftInset))
    const end = Math.max(start, width - Math.max(0, rightInset))
    const available = Math.max(0, end - start)
    const total = left + center + right
    const spacing = packed ? 16 : 8
    const gap = left > 0 && center > 0 ? spacing : 0
    const gapRight = right > 0 && (center > 0 || left > 0) ? spacing : 0
    const factor = total > 0 ? Math.min(1, Math.max(0, available - gap - gapRight) / total) : 1
    const l = left * factor, c = center * factor, r = right * factor
    const cx = Math.max(start + l + gap, Math.min(end - r - gapRight - c, (width - c) / 2))
    return { left: {x: start, width: l}, center: {x: cx, width: c}, right: {x: end - r, width: r} }
}
