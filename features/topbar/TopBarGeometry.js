.pragma library

function panel(width, height, barHeight, anchor, wantedWidth, wantedHeight, progress, leftInset, rightInset) {
    const p = Math.max(0, Math.min(1, Number(progress)))
    const left = Math.max(8, Number(leftInset) || 0)
    const right = Math.max(8, Number(rightInset) || 0)
    const availableWidth = Math.max(0, width - left - right)
    const targetWidth = Math.min(wantedWidth, availableWidth)
    const targetHeight = Math.min(wantedHeight, Math.max(1, height - barHeight - 38))
    const w = Math.min(availableWidth, 48 + (targetWidth - 48) * p)
    const h = targetHeight * p
    const origin = Math.max(left, Math.min(width - right, anchor))
    return { x: Math.max(left, Math.min(width - w - right, origin - w / 2)),
        y: barHeight + 14 * p, width: w, height: h,
        anchor: origin, targetWidth: targetWidth, targetHeight: targetHeight }
}

function size(type) {
    const sizes = { toolbox: [224, 172], battery: [300, 164], clock: [344, 368], timer: [300, 154],
        monitor: [320, 272], weather: [368, 354], paint: [202, 66], wifi: [344, 330], caffeine: [300, 290], cat: [280, 164], usb: [416, 330],
        thing: [300, 68], notes: [352, 368] }
    Object.assign(sizes, {volume: [300, 114], brightness: [300, 114], bluetooth: [360, 380], notifications: [350, 410]})
    return sizes[type] || [304, 180]
}
