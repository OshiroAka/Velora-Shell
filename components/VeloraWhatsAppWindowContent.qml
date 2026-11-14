pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    required property var client
    required property var theme
    property var viewState: null
    property bool reducedMotion: false
    property bool maximized: false
    property bool conversationVisible: true
    property bool unreadOnly: false
    readonly property bool split: width >= 760
    readonly property bool signedIn: client.networkMode !== true || client.hasSession
    readonly property string family: theme ? theme.bodyFont : "sans-serif"
    readonly property color ink: "#f1f3f4"
    readonly property color muted: "#9ba9ae"
    readonly property var rows: {
        const needle = normalize(search.text.trim())
        return client.contacts.map((entry, index) => ({entry: entry, sourceIndex: index}))
            .filter(row => (!needle || normalize(row.entry.name).includes(needle))
                && (!unreadOnly || row.entry.unread > 0))
    }
    signal closeRequested()
    signal dockRequested()
    signal minimizeRequested()
    signal maximizeRequested()
    signal moveRequested()
    function normalize(value) { return String(value || "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLocaleLowerCase() }
    function focusSearch() { conversationVisible = false; search.forceActiveFocus(); search.selectAll() }
    function rememberView() { chat.rememberView() }
    Shortcut { sequence: "Ctrl+F"; onActivated: root.focusSearch() }
    Shortcut { sequence: "Ctrl+W"; onActivated: root.closeRequested() }

    Rectangle { anchors.fill: parent; color: "#10191d" }
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 44
            color: "#1b272c"
            MouseArea {
                anchors.fill: parent
                onPressed: root.moveRequested()
                onDoubleClicked: root.maximizeRequested()
            }
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 6; spacing: 6
                VeloraWhatsAppButton {
                    objectName: "whatsappWindowBack"
                    visible: !root.split && root.conversationVisible && root.signedIn
                    implicitWidth: 30; implicitHeight: 30
                    iconName: "back"; hint: "Mostrar conversas"; reducedMotion: root.reducedMotion
                    onClicked: root.conversationVisible = false
                }
                VeloraEdgeAppIcon { Layout.preferredWidth: 20; Layout.preferredHeight: 20; iconName: "WhatsApp"; ink: "#55c6a5" }
                Text { text: "WhatsApp"; color: root.ink; font.family: root.family; font.pixelSize: 13 }
                Item { Layout.fillWidth: true }
                VeloraWhatsAppButton {
                    objectName: "whatsappWindowMinimize"; implicitWidth: 32; implicitHeight: 30
                    iconName: "minimize"; hint: "Minimizar"; reducedMotion: root.reducedMotion
                    onClicked: root.minimizeRequested()
                }
                VeloraWhatsAppButton {
                    objectName: "whatsappWindowMaximize"; implicitWidth: 32; implicitHeight: 30
                    iconName: root.maximized ? "restore" : "window"; hint: root.maximized ? "Restaurar" : "Maximizar"
                    reducedMotion: root.reducedMotion; onClicked: root.maximizeRequested()
                }
                VeloraWhatsAppButton {
                    objectName: "whatsappWindowClose"; implicitWidth: 32; implicitHeight: 30
                    iconName: "close"; hint: "Fechar janela"; reducedMotion: root.reducedMotion
                    onClicked: root.closeRequested()
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 0
            Rectangle {
                id: sidebar
                objectName: "whatsappConversationSidebar"
                visible: root.signedIn && (root.split || !root.conversationVisible)
                Layout.preferredWidth: root.split ? Math.min(320, root.width * .32) : root.width
                Layout.fillWidth: !root.split; Layout.fillHeight: true
                color: "#182329"
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 12
                    Text {
                        text: "Conversas"; color: root.ink; font.family: root.family; font.pixelSize: 22
                        Layout.topMargin: 12; Layout.bottomMargin: 4
                    }
                    TextField {
                        id: search
                        objectName: "whatsappConversationSearch"
                        Layout.fillWidth: true; implicitHeight: 40
                        placeholderText: "Buscar conversa"; Accessible.name: "Buscar conversa"
                        color: root.ink; placeholderTextColor: root.muted
                        font.family: root.family; font.pixelSize: 13
                        selectByMouse: true; leftPadding: 14; rightPadding: 14
                        background: Rectangle { radius: 14; color: "#25343b"; border.width: search.activeFocus ? 1 : 0; border.color: "#55c6a5" }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 6
                        Repeater {
                            model: ["Conversas", "Grupos"]
                            delegate: Button {
                                id: mode
                                required property string modelData
                                required property int index
                                objectName: "whatsappWindowGroup" + index
                                text: modelData; checkable: true
                                checked: root.client.groups === (index === 1)
                                onClicked: root.client.selectGroupMode(index === 1)
                                contentItem: Text { text: mode.text; color: mode.checked ? "#8fe5bf" : root.muted; font.family: root.family; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter }
                                background: Rectangle { radius: 14; color: mode.checked ? "#26483d" : mode.hovered || mode.activeFocus ? "#2d3b42" : "#223037" }
                            }
                        }
                        VeloraWhatsAppButton {
                            objectName: "whatsappUnreadFilter"
                            iconName: "unread"; hint: "Somente conversas não lidas"; selected: root.unreadOnly
                            reducedMotion: root.reducedMotion; onClicked: root.unreadOnly = !root.unreadOnly
                        }
                    }
                    ListView {
                        id: conversations
                        objectName: "whatsappConversationList"
                        Layout.fillWidth: true; Layout.fillHeight: true
                        clip: true; spacing: 4; model: root.rows
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar {}
                        delegate: AbstractButton {
                            id: entryButton
                            required property var modelData
                            required property int index
                            readonly property var entry: modelData.entry
                            readonly property bool current: root.client.selected === modelData.sourceIndex
                            readonly property var lastMessage: entry.messages && entry.messages.length ? entry.messages[entry.messages.length - 1] : null
                            objectName: "whatsappWindowContact" + index
                            width: ListView.view.width; height: 78
                            hoverEnabled: true; activeFocusOnTab: true
                            Accessible.name: String(entry.name || "") + (entry.unread > 0 ? ", " + entry.unread + " não lidas" : "")
                            Keys.onReturnPressed: clicked()
                            background: Rectangle {
                                radius: 16
                                color: entryButton.current ? "#2a3c43" : entryButton.hovered || entryButton.activeFocus ? "#213239" : "transparent"
                                Behavior on color { ColorAnimation { duration: root.reducedMotion ? 0 : 140 } }
                            }
                            contentItem: RowLayout {
                                spacing: 12
                                VeloraWhatsAppAvatar {
                                    Layout.leftMargin: 10; Layout.preferredWidth: 44; Layout.preferredHeight: 44
                                    style: entryButton.entry.style; imageSource: entryButton.entry.avatar || ""
                                    initials: Array.from(String(entryButton.entry.name || ""))[0] || ""
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 6
                                    Text { Layout.fillWidth: true; text: entryButton.entry.name || ""; textFormat: Text.PlainText; elide: Text.ElideRight; color: root.ink; font.family: root.family; font.pixelSize: 14 }
                                    Text {
                                        Layout.fillWidth: true; elide: Text.ElideRight; textFormat: Text.PlainText
                                        text: entryButton.lastMessage ? entryButton.lastMessage.text || "Mídia" : entryButton.entry.status || ""
                                        color: root.muted; font.family: root.family; font.pixelSize: 11
                                    }
                                }
                                Rectangle {
                                    Layout.rightMargin: 8; visible: entryButton.entry.unread > 0
                                    implicitWidth: Math.max(22, unreadLabel.implicitWidth + 10); implicitHeight: 22; radius: 11; color: "#55c6a5"
                                    Text { id: unreadLabel; anchors.centerIn: parent; text: String(entryButton.entry.unread || 0); color: "#10271e"; font.pixelSize: 11 }
                                }
                            }
                            onClicked: { root.client.selectContact(modelData.sourceIndex); root.conversationVisible = true }
                        }
                        Text {
                            anchors.centerIn: parent; width: parent.width - 20
                            visible: conversations.count === 0
                            text: search.text.trim() || root.unreadOnly ? "Nenhuma conversa encontrada" : "Suas conversas aparecerão aqui"
                            wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
                            color: root.muted; font.family: root.family; font.pixelSize: 13
                        }
                    }
                }
            }
            VeloraEdgeWhatsAppPanel {
                id: chat
                objectName: "whatsappWindowChat"
                Layout.fillWidth: true; Layout.fillHeight: true
                visible: !root.signedIn || root.split || root.conversationVisible
                preview: root.client; theme: root.theme; reducedMotion: root.reducedMotion
                windowMode: true; viewState: root.viewState
                onCloseRequested: root.closeRequested()
                onWindowModeRequested: root.dockRequested()
            }
        }
    }
}
