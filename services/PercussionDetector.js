.pragma library

// These are the existing analyzer's logarithmic bands (35–7600 Hz).
// Detect positive spectral flux, not loudness: steady bass must not pulse.
function create() {
    return {previous: [], flux: 0, energy: 0, started: -1, time: -1, lastBeat: -10000}
}

function update(state, frame, now) {
    if (!frame || frame.length < 8 || !Number.isFinite(now)) return 0
    if (state.time < 0 || now - state.time > 400 || now < state.time) {
        Object.assign(state, create(), {started: now, time: now})
    }
    const dt = Math.max(1, Math.min(100, now - state.time))
    let energy = 0, flux = 0, weight = 0
    const next = frame.map(value => Number.isFinite(Number(value))
        ? Math.max(0, Math.min(1, Number(value))) : 0)
    for (let i = 0; i < next.length; ++i) {
        const hz = 35 * Math.pow(7600 / 35, i / (next.length - 1))
        // Bumbo, toms and the low body of a snare. Upper voice/harmonic
        // bands do not drive this effect; instruments sharing this band can.
        const w = hz >= 40 && hz <= 180 ? 1 : hz > 180 && hz <= 320 ? .35 : 0
        energy += next[i] * next[i] * w
        const rise = next[i] - (state.previous[i] || 0)
        flux += Math.max(0, rise) * w
        weight += w
    }
    energy = Math.sqrt(energy / Math.max(1, weight))
    flux /= Math.max(1, weight)
    const threshold = Math.max(.018, state.flux * 2.2)
    const onset = now - state.started >= 300 && now - state.lastBeat >= 200
        && energy > .065 && flux > threshold
        && energy > state.energy * 1.12
    const adapt = 1 - Math.exp(-dt / 700)
    state.flux += (flux - state.flux) * adapt
    state.energy += (energy - state.energy) * adapt
    state.previous = next
    state.time = now
    if (!onset) return 0
    state.lastBeat = now
    return Math.max(.3, Math.min(1, (flux - threshold) * 7 + energy * .55))
}
