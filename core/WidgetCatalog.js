.pragma library

// Stable IDs are persisted. Labels and suggested sizes belong to the catalog,
// so Settings, previews and the scene resolve exactly the same design.
function variants(kind) {
    const entries = {
        clock: [
            {id: "editorial", name: "Digital", detail: "Hora e data em destaque", width: 350, height: 140},
            {id: "dots", name: "Pontilhado", detail: "Matriz de pontos e data", width: 350, height: 170},
            {id: "analog", name: "Analógico", detail: "Mostrador circular", width: 240, height: 260},
            {id: "minimal", name: "Essencial", detail: "Tipografia leve e compacta", width: 300, height: 112}
        ],
        weather: [
            {id: "editorial", name: "Resumo", detail: "Condição e temperatura", width: 282, height: 160},
            {id: "dots", name: "Pontilhado", detail: "Temperatura em pontos", width: 282, height: 180},
            {id: "forecast", name: "Previsão", detail: "Próximos quatro dias", width: 340, height: 244}
        ],
        media: [
            {id: "editorial", name: "Compacto", detail: "Capa e controles", width: 330, height: 112},
            {id: "poster", name: "Capa", detail: "Álbum em destaque", width: 270, height: 354},
            {id: "vinyl", name: "Disco", detail: "Capa circular e faixa", width: 330, height: 160}
        ],
        system: [
            {id: "editorial", name: "Painel", detail: "CPU, memória e disco", width: 302, height: 210},
            {id: "metrics", name: "Métricas", detail: "Indicadores em pontos", width: 340, height: 236},
            {id: "minimal", name: "Essencial", detail: "Três indicadores compactos", width: 320, height: 120}
        ],
        battery: [
            {id: "editorial", name: "Segmentos", detail: "Carga e alimentação", width: 270, height: 150},
            {id: "ring", name: "Circular", detail: "Anel de carga", width: 220, height: 220}
        ],
        gallery: [
            {id: "editorial", name: "Tríptico", detail: "Três fotos lado a lado", width: 360, height: 210},
            {id: "classic", name: "Mosaico", detail: "Uma foto e dois detalhes", width: 302, height: 294}
        ]
    }
    return entries[kind] || []
}

function resolve(kind, id) {
    const choices = variants(kind)
    const requested = String(id || "inherit")
    // Earlier widgets had an inherited editorial desktop design.
    return choices.find(entry => entry.id === requested) || choices[0] || null
}

function description(kind) {
    return ({clock: "Hora e data", weather: "Tempo e previsão", media: "Seu player",
        system: "Desempenho do computador", battery: "Energia do dispositivo", gallery: "Suas fotografias"})[kind] || ""
}
