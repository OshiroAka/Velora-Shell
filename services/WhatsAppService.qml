import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    property bool enabled: Quickshell.env("VELORA_VALIDATE") !== "1"
    readonly property bool networkMode: true
    property bool ready: false
    property bool hasSession: false
    property string state: "starting"
    property string method: "qr"
    property string error: ""
    property string errorCode: ""
    property int retryCount: 0
    property string pairingCode: ""
    property string qrImage: ""
    property string accountName: ""
    property bool groups: false
    property string selectedId: ""
    property var contacts: []
    property string draft: ""
    property var attachments: []
    property var stickers: []
    property bool sending: false
    property string operationError: ""
    signal pasteText(string text)
    signal messageSent(string chat)
    readonly property bool connected: state === "connected"
    readonly property bool busy: state === "connecting" || state === "reconnecting"
    readonly property int selected: Math.max(0, contacts.findIndex(value => value.id === selectedId))
    readonly property var contact: contacts.find(value => value.id === selectedId)
        || ({id: "", name: "WhatsApp", style: -1, avatar: "", status: statusText, messages: []})
    readonly property string statusText: connected ? "Conectado"
        : state === "reconnecting" ? "Reconectando…"
        : state === "connecting" ? "Conectando…"
        : state === "awaiting_qr" ? "Aguardando leitura do QR Code"
        : state === "awaiting_code" ? "Aguardando confirmação no celular"
        : hasSession ? "Desconectado" : "Conecte sua conta"
    signal commandRequested(var command)
    function send(value) {
        commandRequested(value)
        if (enabled && bridge.running) bridge.write(JSON.stringify(value) + "\n")
    }
    function pair(phone) { send({action: "pair", method: method, phone: phone || ""}) }
    function setPairMethod(value) { send({action: "method", method: value}) }
    function cancelPairing() { send({action: "cancel"}) }
    function reconnect() {
        if (!bridge.running && enabled) bridge.running = true
        else send({action: "connect"})
    }
    function logout() { send({action: "logout"}) }
    function sendDraft() {
        if (!connected || sending || (!draft.trim() && attachments.length === 0)) return
        operationError = ""
        send({action: "send", chat: selectedId, text: draft, attachments: attachments.map(value => value.id)})
    }
    function attachFiles(urls) { operationError = ""; send({action: "attach", urls: urls.map(value => String(value))}) }
    function pasteClipboard() { operationError = ""; send({action: "paste"}) }
    function removeAttachment(id) { send({action: "removeAttachment", id: id}) }
    function loadMedia(chat, id) { send({action: "media", chat: chat, id: id}) }
    function requestStickers(visible) { send({action: "stickers", visible: visible}) }
    function attachSticker(chat,id) { operationError = ""; send({action: "attachSticker", chat: chat, id: id}) }
    function importStickers(urls) { operationError = ""; send({action: "importStickers", urls: urls.map(value => String(value))}) }
    function selectContact(index) {
        const entry = contacts[index]
        if (!entry) return
        draft = ""; send({action: "select", id: entry.id})
    }
    function selectGroupMode(value) { draft = ""; send({action: "groups", groups: value}) }
    function acceptState(value) {
        if (!value) return
        if (value.type === "operation") { operationError = value.error || ""; return }
        if (value.type === "paste") { if (value.chat === selectedId) pasteText(value.text || ""); return }
        if (value.type === "sent") {
            if (value.chat === selectedId && draft === value.text) draft = ""
            messageSent(value.chat); return
        }
        if (value.type !== "state") return
        ready = value.ready === true; hasSession = value.hasSession === true
        state = value.state || "error"; method = value.method || method
        error = value.error || ""; errorCode = value.code || ""
        pairingCode = value.pairingCode || ""
        qrImage = value.qrImage || ""; accountName = value.accountName || ""
        groups = value.groups === true
        sending = value.sending === true
        if (Array.isArray(value.attachments) && JSON.stringify(attachments) !== JSON.stringify(value.attachments)) attachments = value.attachments
        if (Array.isArray(value.stickers) && JSON.stringify(stickers) !== JSON.stringify(value.stickers)) stickers = value.stickers
        if (Array.isArray(value.contacts)) {
            if (JSON.stringify(contacts) !== JSON.stringify(value.contacts)) contacts = value.contacts
            selectedId = value.selectedId || ""
        }
    }
    Component.onCompleted: if (enabled) bridge.running = true
    Timer {
        id: retry
        interval: 600
        onTriggered: if (root.enabled) bridge.running = true
    }
    Process {
        id: bridge
        command: [Quickshell.shellDir + "/scripts/velora-whatsapp"]
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => {
                try { root.acceptState(JSON.parse(line)) } catch (_) {}
            }
        }
        onExited: code => {
            root.ready = false
            if (root.enabled && root.errorCode === "client_running" && root.retryCount++ < 5) retry.restart()
            if (root.enabled && code !== 0) {
                root.state = "error"
                if (!root.error) root.error = "A conexão do WhatsApp foi interrompida."
            }
        }
    }
}
