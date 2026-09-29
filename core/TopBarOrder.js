.pragma library

function defaults() {
    return ["caffeine", "timer", "thing", "notes", "battery", "paint", "monitor", "search", "controls", "clock"]
}

function normalize(value) {
    const allowed = defaults()
    const result = []
    for (const original of Array.isArray(value) ? value : []) {
        const type = original === "wifi" ? "monitor" : original
        if (type === "monitor" && !result.includes("paint") && !(value || []).includes("paint")) result.push("paint")
        if (allowed.includes(type) && !result.includes(type)) result.push(type)
    }
    return result.concat(allowed.filter(type => !result.includes(type)))
}

function move(value, type, target) {
    const result = normalize(value)
    const from = result.indexOf(type), to = result.indexOf(target)
    if (from < 0 || to < 0 || from === to) return result
    result.splice(from, 1)
    result.splice(to, 0, type)
    return result
}

function label(type) {
    return ({ caffeine: "Café", timer: "Timer", thing: "Mensagem", notes: "Notas",
        battery: "Bateria", monitor: "Monitores", paint: "Cores do wallpaper", search: "Busca", controls: "Controles",
        clock: "Data e hora" })[type] || type
}
