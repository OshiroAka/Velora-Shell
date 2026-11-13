.pragma library

function remaining(state, now) {
    return Math.max(0, state.running ? state.deadline - now : state.remaining)
}
function elapsed(state, now) {
    return Math.max(0, state.elapsed + (state.running ? Math.max(0, now - state.startedAt) : 0))
}
function format(milliseconds) {
    const seconds = Math.max(0, Math.ceil(milliseconds / 1000))
    const h = Math.floor(seconds / 3600)
    const m = Math.floor(seconds / 60) % 60
    const s = seconds % 60
    return (h > 0 ? h + ":" + String(m).padStart(2, "0") : String(m).padStart(2, "0"))
        + ":" + String(s).padStart(2, "0")
}
function normalize(document, now) {
    const source = document && typeof document === "object" ? document : {}
    const duration = Number.isFinite(source.duration)
        ? Math.min(86400000, Math.max(1000, source.duration)) : 1500000
    const timer = source.timer || {}
    const stopwatch = source.stopwatch || {}
    return { duration: duration,
        timer: { running: timer.running === true && Number.isFinite(timer.deadline),
            deadline: Number(timer.deadline) || now,
            remaining: Number.isFinite(timer.remaining)
                ? Math.max(0, Math.min(86400000, timer.remaining)) : duration },
        stopwatch: { running: stopwatch.running === true && Number.isFinite(stopwatch.startedAt),
            startedAt: Number(stopwatch.startedAt) || now,
            elapsed: Number.isFinite(stopwatch.elapsed) ? Math.max(0, stopwatch.elapsed) : 0 },
        finished: source.finished === true,
        engaged: source.engaged === true || source.finished === true || timer.running === true
            || (Number.isFinite(timer.remaining) && timer.remaining < duration) }
}
