import QtQuick

// Local presentation data only. This preview has no account or network actions.
QtObject {
    id: root
    property bool groups: false
    property int selected: 0
    property string draft: ""
    readonly property var people: [
        {name: "Kael", style: 0, status: "online", messages: [
            {text: "E aí, tudo bem?", time: "13:20", outgoing: false},
            {text: "Tudo sim! E contigo?", time: "13:22", outgoing: true},
            {text: "Tranquilo também. Conseguiu ver aquele projeto que te mandei?", time: "13:23", outgoing: false},
            {text: "Sim, dei uma olhada agora.", time: "13:24", outgoing: true},
            {text: "Tá ficando muito bom!", time: "13:24", outgoing: true},
            {text: "Que bom! Se tiver alguma sugestão me fala.", time: "13:25", outgoing: false},
            {text: "Claro, vou anotar aqui alguns pontos e te envio ainda hoje.", time: "13:26", outgoing: true},
            {text: "Perfeito! Valeu demais.", time: "13:27", outgoing: false},
            {text: "Disponha! Qualquer coisa me chama.", time: "13:28", outgoing: true}
        ]},
        {name: "Lia", style: 1, status: "online", messages: [
            {text: "Olha como ficou a luz no fim da tarde.", time: "12:42", outgoing: false},
            {text: "Essa combinação de cores ficou linda.", time: "12:44", outgoing: true}
        ]},
        {name: "Noah", style: 2, status: "visto por último às 12:10", messages: [
            {text: "Vamos caminhar no sábado?", time: "11:50", outgoing: false},
            {text: "Vamos! A gente combina o horário depois.", time: "11:52", outgoing: true}
        ]},
        {name: "Maya", style: 3, status: "online", messages: [
            {text: "Separei algumas referências para a gente ver.", time: "10:16", outgoing: false},
            {text: "Boa, vejo com você mais tarde.", time: "10:18", outgoing: true}
        ]},
        {name: "Theo", style: 4, status: "visto por último às 09:32", messages: [
            {text: "Encontrei aquele lugar que você comentou.", time: "09:20", outgoing: false},
            {text: "Depois me conta como foi!", time: "09:23", outgoing: true}
        ]}
    ]
    readonly property var communities: [
        {name: "Entre amigos", style: 2, status: "5 participantes", messages: [
            {text: "Qual é o plano para o fim de semana?", time: "13:10", outgoing: false},
            {text: "Um café e uma boa conversa.", time: "13:12", outgoing: true}
        ]},
        {name: "Ideias", style: 1, status: "4 participantes", messages: [
            {text: "Vamos reunir as referências por aqui.", time: "12:04", outgoing: false}
        ]},
        {name: "Trilhas", style: 4, status: "6 participantes", messages: [
            {text: "A previsão para sábado está ótima.", time: "11:30", outgoing: false}
        ]}
    ]
    readonly property var contacts: groups ? communities : people
    readonly property var contact: contacts[Math.min(selected, contacts.length - 1)]
    function selectContact(index) { selected = index; draft = "" }
    function selectGroupMode(value) { groups = value; selected = 0; draft = "" }
}
