import QtQuick
import QtTest
import "../../components" as Components

Item {
    id: fixture
    width: 1000; height: 1100
    QtObject { id: palette; property string bodyFont: "sans-serif" }
    QtObject {
    id: preview
    property bool hasSession: true
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
    readonly property var contacts: preview.groups ? preview.communities : preview.people
    readonly property var contact: preview.contacts[Math.min(preview.selected, preview.contacts.length - 1)]
    function selectContact(index) { preview.selected = index; preview.draft = "" }
    function selectGroupMode(value) { preview.groups = value; preview.selected = 0; preview.draft = "" }
}

    Components.VeloraEdgeWhatsAppPanel {
        id: panel
        x: 552; width: 448; height: 1100
        preview: preview; theme: palette; reducedMotion: true
    }
    Components.VeloraWhatsAppContacts {
        id: contacts
        x: 468; width: 84; height: 520
        preview: preview; reducedMotion: true
    }
    SignalSpy { id: backSpy; target: panel; signalName: "backRequested" }
    SignalSpy { id: closeSpy; target: panel; signalName: "closeRequested" }
    TestCase {
        name: "EdgeWhatsApp"; when: windowShown
        function init() {
            panel.width=448; panel.height=1100; panel.embeddedContacts=false
            preview.selectGroupMode(false)
            panel.forceActiveFocus(); wait(100)
        }
        function test_contacts_and_groups_are_local() {
            const name=findChild(panel,"whatsappContactName")
            const messages=findChild(panel,"whatsappMessages")
            compare(findChild(contacts,"whatsappContactsScroll").flickableDirection,Flickable.VerticalFlick)
            verify(findChild(contacts,"whatsappGroups").y>findChild(contacts,"whatsappPeople").y)
            compare(name.text,"Kael"); compare(messages.count,9)
            mouseClick(findChild(contacts,"whatsappContact1"))
            compare(name.text,"Lia"); tryCompare(messages,"count",2)
            mouseClick(findChild(contacts,"whatsappGroups"))
            compare(preview.groups,true); compare(name.text,"Entre amigos")
            wait(100)
            mouseClick(findChild(contacts,"whatsappPeople"))
            compare(name.text,"Kael")
        }
        function test_draft_never_sends_a_message() {
            const composer=findChild(panel,"whatsappComposer")
            const send=findChild(panel,"whatsappSend")
            const messages=findChild(panel,"whatsappMessages")
            mouseClick(composer); keyClick(Qt.Key_A); keyClick(Qt.Key_B)
            compare(preview.draft,"ab"); verify(panel.interactionHeld)
            verify(!send.enabled)
            mouseClick(send); compare(messages.count,9)
            preview.selectContact(1); compare(composer.text,"")
        }
        function test_responsive_chat_and_controls() {
            const messages=findChild(panel,"whatsappMessages")
            const composer=findChild(panel,"whatsappComposer")
            const back=findChild(panel,"whatsappBack")
            for (const size of [[320,560],[448,720],[448,1100]]) {
                panel.width=size[0]; panel.height=size[1]
                panel.embeddedContacts=size[0]<380; wait(100)
                const composerPosition=composer.mapToItem(panel,0,0)
                const listPosition=messages.mapToItem(panel,0,messages.height)
                verify(listPosition.y<=composerPosition.y,"Messages must not overlap the composer")
                verify(back.mapToItem(panel,0,back.height).y<=panel.height)
                for (let i=0;i<messages.count;i++) {
                    const row=messages.itemAtIndex(i)
                    if (!row) continue
                    const bubble=findChild(row,"whatsappBubble")
                    verify(bubble.x>=0 && bubble.x+bubble.width<=messages.width)
                    verify(bubble.height>0)
                    compare(bubble.color.a,1,"Messages use an opaque background above the liquid panel")
                }
            }
            back.forceActiveFocus(); keyClick(Qt.Key_Return); compare(backSpy.count,1)
            mouseClick(findChild(panel,"whatsappClose")); compare(closeSpy.count,1)
        }
    }
}
