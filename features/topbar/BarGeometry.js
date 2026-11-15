.pragma library

// The standard bar keeps its left, centred and right sections. Infinite Desk
// packs those sections into a strip centred by its host.
function sections(width, left, center, right, leftInset, rightInset, packed) {
    const start = Math.min(width, Math.max(0, leftInset))
    const end = Math.max(start, width - Math.max(0, rightInset))
    const available = Math.max(0, end - start)
    const total = left + center + right
    const gap = !packed && left > 0 && center > 0 ? 8 : 0
    const gapRight = !packed && right > 0 && (center > 0 || left > 0) ? 8 : 0
    const factor = total > 0 ? Math.min(1, Math.max(0, available - gap - gapRight) / total) : 1
    const l = left * factor, c = center * factor, r = right * factor
    const cx = packed ? start + l : Math.max(start + l + gap, Math.min(end - r - gapRight - c, (width - c) / 2))
    return { left: {x: start, width: l}, center: {x: cx, width: c}, right: {x: packed ? start + l + c : end - r, width: r} }
}
