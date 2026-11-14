.pragma library

// Logical pixels, shared by the native surface and the thumbnail viewport.
function layout(width, height, barHeight, left, right, count) {
    const available = Math.max(0, width - left - right - 32)
    const bodyWidth = Math.min(860, available)
    const columns = bodyWidth >= 620 ? 4 : bodyWidth >= 400 ? 3 : 2
    const padding = Math.min(18, bodyWidth / 12)
    const gap = 14
    const cellWidth = Math.max(1, (bodyWidth - padding * 2 + gap) / columns)
    const tileHeight = Math.max(1, (cellWidth - gap) / 1.9)
    const rows = Math.min(4, Math.max(1, Math.ceil(count / columns)))
    const top = 40
    const bodyHeight = Math.min(top + rows * (tileHeight + gap) - gap + padding,
        Math.max(1, height - barHeight - 24))
    const x = Math.max(left + 16, Math.min(width - right - 16 - bodyWidth,
        (width - bodyWidth) / 2))
    const shoulder = Math.max(0, Math.min(144, x - left, width - right - x - bodyWidth))
    return { x: x, width: bodyWidth, height: bodyHeight, columns: columns,
        padding: padding, gap: gap, top: top, cellWidth: cellWidth,
        tileHeight: tileHeight, shoulder: shoulder }
}

function step(index, key, columns, count) {
    if (!count) return -1
    const delta = key === "left" ? -1 : key === "right" ? 1
        : key === "up" ? -columns : columns
    return Math.max(0, Math.min(count - 1, index + delta))
}
