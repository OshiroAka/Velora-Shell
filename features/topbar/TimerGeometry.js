.pragma library

// Diminishing displacement, capped at ten pixels even for a very long drag.
function resistance(distance) {
    return 10 * distance / (Math.abs(distance) + 56)
}

// Timer-only geometry. The native material and QML fill consume this same rect.
function panel(width, height, barHeight, anchor, anchorWidth, wantedWidth, wantedHeight, progress) {
    const p = Math.max(0, Math.min(1, progress))
    const available = Math.max(1, width - 16)
    const targetWidth = Math.min(wantedWidth, available)
    const targetHeight = Math.min(wantedHeight, Math.max(1, height - barHeight - 30))
    const seed = Math.min(targetWidth, Math.max(40, anchorWidth - 8))
    const w = seed + (targetWidth - seed) * p
    const origin = Math.max(8, Math.min(width - 8, anchor))
    const x = Math.max(8, Math.min(width - w - 8, origin - w / 2))
    return { x: x, y: barHeight + 14 * p, width: w, height: targetHeight * p,
        targetWidth: targetWidth, targetHeight: targetHeight,
        // Keep the neck under its trigger, including when the body hits an edge.
        neck: Math.max(0, Math.min(120, w / 2 - 18,
            origin - 8, width - 8 - origin)) * p }
}
