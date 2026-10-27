pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: root
    required property var preview
    required property var theme
    property bool reducedMotion: false
    property bool embeddedContacts: false
    property real contactsProgress: 1
    property real contactsOpacity: 1
    property real contactsFold: 1
    readonly property color ink: "#f1f3f4"
    readonly property color muted: "#a6aeb3"
    readonly property string family: theme ? theme.bodyFont : "sans-serif"
    readonly property color messageTone: theme && theme.wallpaperSurfaceTone ? theme.wallpaperSurfaceTone : "#28343b"
    readonly property color receivedBubble: Qt.rgba(.08+.16*messageTone.r,.10+.16*messageTone.g,.12+.16*messageTone.b,1)
    readonly property color sentBubble: Qt.rgba(.07+.12*messageTone.r,.20+.16*messageTone.g,.17+.14*messageTone.b,1)
    readonly property bool compact: width < 380
    readonly property bool live: preview.networkMode === true
    readonly property bool showConversations: !live || preview.hasSession
    readonly property var incomingMessages: preview.contact.messages
    readonly property bool interactionHeld: composer.activeFocus || messages.dragging || messages.flicking
        || (embeddedContacts && inlineContacts.interactionHeld) || accountMenu.visible || pairing.interactionHeld || mediaViewer.visible || files.visible || audioPlayback.playing
        || attachmentsStrip.dragging || attachmentsStrip.flicking || emojiPicker.visible || stickerFiles.visible
    signal backRequested()
    signal closeRequested()
    Keys.onEscapePressed: closeRequested()
    onVisibleChanged: if (!visible) { accountMenu.close(); emojiPicker.close() }
    FontLoader { id: emojiFont; objectName: "whatsappEmojiFont"; source: "../assets/fonts/NotoColorEmoji.ttf" }
    property real sendPulse: 0
    SequentialAnimation {
        id: sendFeedback
        NumberAnimation { target: root; property: "sendPulse"; from: 0; to: 1; duration: root.reducedMotion ? 0 : 130; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "sendPulse"; to: 0; duration: root.reducedMotion ? 0 : 320; easing.type: Easing.OutCubic }
    }
    FileDialog {
        id: stickerFiles
        title: "Importar figurinhas"; fileMode: FileDialog.OpenFiles
        nameFilters: ["Imagens (*.webp *.png *.jpg *.jpeg *.gif)"]
        onAccepted: root.preview.importStickers(selectedFiles)
    }
    VeloraWhatsAppEmojiPicker {
        id: emojiPicker
        client: root.preview; reducedMotion: root.reducedMotion
        emojiFamily: emojiFont.name || "sans-serif"
        x: root.width-width-16; y: Math.max(8,mainColumn.y+composerSurface.y-height-12)
        width: Math.min(340,root.width-32); height: Math.min(340,root.height-140)
        onEmojiSelected: emoji => { composer.insert(composer.cursorPosition,emoji); close() }
        onStickerSelected: (chat,id) => { root.preview.attachSticker(chat,id); close() }
        onImportRequested: { close(); stickerFiles.open() }
        onClosed: if (root.visible) composer.forceActiveFocus()
    }
    onIncomingMessagesChanged: syncTimer.restart()
    Component.onCompleted: syncTimer.restart()
    Timer { id: syncTimer; interval: 0; onTriggered: root.syncMessages() }
    Timer {
        id: settleTimer
        property bool switched: false
        property bool jump: false
        interval: 0
        onTriggered: {
            if (!root.live) messages.positionViewAtBeginning()
            else if (switched || (jump && messages.followEnd && !messages.dragging && !messages.flicking)) root.scrollToBottom()
            messages.restoring = false
        }
    }
    Timer {
        id: tailTimer; interval: 0
        onTriggered: {
            if (!messages.followEnd) return
            messages.forceLayout(); messages.positionViewAtEnd()
            const tail = messages.itemAtIndex(messages.count - 1)
            if (tail) messages.contentY = Math.max(messages.originY - messages.topMargin,tail.y + tail.height - messages.height + messages.bottomMargin)
        }
    }
    Timer { id: sentScroll; interval: 0; onTriggered: root.scrollToBottom() }
    Timer {
        id: followScroll; interval: 0
        onTriggered: if (messages.followEnd && !messages.dragging && !messages.flicking) root.scrollToBottom()
    }
    function syncMessages() {
        const items = root.incomingMessages || []
        const chat = String(root.preview.contact.id || root.preview.contact.name || "")
        const last = items.length ? String(items[items.length - 1].id || items.length) : ""
        const switched = chat !== messages.lastChat
        const jump = switched || (last !== messages.lastMessage && messages.followEnd)
        messages.restoring = true
        if (switched) messageRows.clear()
        for (let i = 0; i < items.length; i++) {
            const entry = items[i]
            const key = String(entry.id || i)
            if (i < messageRows.count && messageRows.get(i).key !== key) {
                let match = -1
                for (let j = i + 1; j < messageRows.count; j++) if (messageRows.get(j).key === key) { match = j; break }
                if (match >= 0) messageRows.remove(i,match - i)
                else messageRows.insert(i,{key: key,payload: entry,arrival:root.live && !switched})
            }
            if (i >= messageRows.count) messageRows.append({key:key,payload:entry,arrival:root.live && !switched})
            else if (JSON.stringify(messageRows.get(i).payload) !== JSON.stringify(entry)) messageRows.setProperty(i,"payload",entry)
        }
        if (messageRows.count > items.length) messageRows.remove(items.length,messageRows.count - items.length)
        messages.lastChat = chat; messages.lastMessage = last
        settleTimer.switched = switched; settleTimer.jump = jump; settleTimer.restart()
    }
    function scrollToBottom() {
        messages.followEnd = true
        messages.forceLayout()
        messages.positionViewAtEnd()
        const last = messages.itemAtIndex(messages.count - 1)
        if (last) messages.contentY = Math.max(messages.originY - messages.topMargin,last.y + last.height - messages.height + messages.bottomMargin)
        tailTimer.restart()
    }
    ListModel { id: messageRows; dynamicRoles: true }
    function openMedia(id, media) {
        if (!root.live) return
        if (["image","video","sticker"].includes(media.kind)) { audioPlayback.stop(); mediaViewer.view(root.preview.selectedId,id) }
        else if (media.source) Qt.openUrlExternally(media.source)
        else root.preview.loadMedia(root.preview.selectedId,id)
    }
    Connections {
        target: root.preview
        ignoreUnknownSignals: true
        function onPasteText(text) { composer.insert(composer.cursorPosition,text) }
        function onMessageSent(chat) {
            if (chat !== root.preview.selectedId) return
            sentScroll.restart()
            if (!root.reducedMotion) sendFeedback.restart()
        }
    }
    FileDialog {
        id: files
        title: "Anexar arquivos ao WhatsApp"; fileMode: FileDialog.OpenFiles
        onAccepted: root.preview.attachFiles(selectedFiles)
    }
    VeloraWhatsAppMediaViewer {
        id: mediaViewer
        client: root.preview; reducedMotion: root.reducedMotion
        x: 8; y: 80; width: root.width - 16; height: root.height - 112
    }
    VeloraWhatsAppAudio { id: audioPlayback; client: root.preview }
    Loader {
        id: inlineContacts
        objectName: "whatsappInlineContacts"
        visible: root.embeddedContacts && root.showConversations
        active: root.embeddedContacts && root.showConversations && root.contactsProgress > 0
        x: 0; y: 0
        width: 64 * root.contactsProgress * Math.min(1,root.contactsFold * Math.min(448,root.height-92) / 64)
        height: Math.min(448,root.height-92) * root.contactsProgress * root.contactsFold
        opacity: root.contactsOpacity * Math.min(1,root.contactsFold * 3)
        enabled: root.contactsOpacity > .9 && root.contactsFold > .98
        clip: true
        readonly property bool interactionHeld: (item as VeloraWhatsAppContacts)?.interactionHeld === true
        sourceComponent: Component {
            VeloraWhatsAppContacts { preview: root.preview; reducedMotion: root.reducedMotion; vertical: true }
        }
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.leftMargin: inlineContacts.visible ? inlineContacts.width : 0
        spacing: 0
        RowLayout {
            Layout.fillWidth: true; Layout.preferredHeight: 90
            Layout.leftMargin: 18; Layout.rightMargin: 12; spacing: 10
            VeloraWhatsAppAvatar {
                Layout.preferredWidth: root.compact ? 40 : 50; Layout.preferredHeight: width
                style: root.preview.contact.style; imageSource: root.preview.contact.avatar || ""
                initials: Array.from(String(root.preview.contact.name || ""))[0] || ""
                scale: !root.reducedMotion && headerHover.hovered ? 1.04 : 1
                Behavior on scale { NumberAnimation { duration: root.reducedMotion ? 0 : 180; easing.type: Easing.OutCubic } }
                HoverHandler { id: headerHover; blocking: false }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 3
                Text {
                    objectName: "whatsappContactName"
                    Layout.fillWidth: true; text: root.preview.contact.name
                    color: root.ink; font.family: root.family; font.pixelSize: 17; elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
                Text {
                    Layout.fillWidth: true
                    text: root.live ? root.preview.statusText : root.preview.contact.status + " · prévia"
                    color: "#55c6a5"; font.family: root.family; font.pixelSize: 10; elide: Text.ElideRight
                }
            }
            VeloraWhatsAppButton {
                objectName: "whatsappAccount"
                iconName: "more"; hint: "Conta"; enabled: root.live && root.preview.hasSession
                reducedMotion: root.reducedMotion; onClicked: accountMenu.open()
            }
            VeloraWhatsAppButton { objectName: "whatsappClose"; iconName: "close"; hint: "Fechar"; reducedMotion: root.reducedMotion; onClicked: root.closeRequested() }
        }
        Loader {
            id: pairing
            objectName: "whatsappPairing"
            active: root.live && !root.showConversations
            visible: active
            Layout.fillWidth: true; Layout.fillHeight: true
            readonly property bool interactionHeld: (item as VeloraWhatsAppPairing)?.interactionHeld === true
            sourceComponent: Component {
                VeloraWhatsAppPairing { client: root.preview; family: root.family; reducedMotion: root.reducedMotion }
            }
        }
        ListView {
            id: messages
            objectName: "whatsappMessages"
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: root.showConversations
            clip: true; spacing: 10
            topMargin: 16; bottomMargin: 20
            boundsBehavior: Flickable.StopAtBounds
            model: messageRows
            maximumFlickVelocity: 5000; flickDeceleration: 2400
            property string lastChat: ""
            property string lastMessage: ""
            property bool restoring: false
            property bool followEnd: true
            readonly property bool atLatest: {
                const viewportBottom = contentY + height
                if (count === 0 || contentHeight <= height || atYEnd) return true
                const last = itemAtIndex(count - 1)
                return !!last && last.y + last.height <= viewportBottom + 1
            }
            onMovementStarted: followEnd = false
            onMovementEnded: followEnd = atLatest
            onContentHeightChanged: if (followEnd && !restoring && !dragging && !flicking) followScroll.restart()
            Text {
                anchors.centerIn: parent; width: parent.width - 48
                visible: messages.count === 0 && root.showConversations
                text: "Aguardando mensagens\nAs conversas recebidas aparecerão aqui."
                color: root.muted; font.family: root.family; font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
            }
            delegate: Item {
                id: message
                required property var payload
                required property int index
                required property bool arrival
                readonly property var modelData: payload
                readonly property bool compactAudio: !!modelData.media && modelData.media.kind === "audio" && !modelData.media.caption
                width: messages.width
                height: bubble.height
                Component.onCompleted: if (arrival) { messageRows.setProperty(index,"arrival",false); motion.arrive() }
                VeloraWhatsAppMessageMotion {
                    id: motion
                    objectName: "whatsappMessageMotion"
                    reducedMotion: root.reducedMotion; outgoing: message.modelData.outgoing
                    highlighted: bubbleHover.hovered || avatarHover.hovered
                    scrollVelocity: messages.verticalVelocity
                }
                Rectangle {
                    id: bubble
                    objectName: "whatsappBubble"
                    x: (message.modelData.outgoing ? message.width - width - 20 : root.live ? 54 : 20) + motion.slide
                    y: motion.lift + motion.rise
                    opacity: motion.presence; scale: motion.zoom
                    transform: Scale { origin.x: bubble.width/2; origin.y: bubble.height/2; xScale: 1-.006*motion.scrollEnergy; yScale: 1+.012*motion.scrollEnergy }
                    width: message.compactAudio ? Math.min(176,message.width - (root.live ? 74 : 64)) : Math.min(message.width - (root.live ? 74 : 64),
                        Math.max(stamp.implicitWidth + 20, sender.visible ? sender.implicitWidth + 20 : 0,
                            media.visible ? 230 : 0, body.implicitWidth + 20))
                    height: stamp.y + stamp.height + (message.compactAudio ? 6 : 7)
                    radius: 11
                    color: Qt.lighter(message.modelData.outgoing ? root.sentBubble : root.receivedBubble,
                        1 + .10*motion.hoverAmount + .06*motion.arrivalLight)
                    HoverHandler { id: bubbleHover; blocking: false }
                    Text {
                        id: sender
                        objectName: "whatsappSenderName"
                        x: 10; y: message.compactAudio ? 6 : 8; width: parent.width - 20
                        visible: root.live && !message.modelData.outgoing && String(message.modelData.sender || "").length > 0
                        text: String(message.modelData.sender || "")
                        color: "#72c0aa"; font.family: root.family; font.pixelSize: message.compactAudio ? 10 : 11
                        textFormat: Text.PlainText; elide: Text.ElideRight
                    }
                    VeloraWhatsAppMedia {
                        id: media
                        visible: !!message.modelData.media
                        media: message.modelData.media || ({kind:"",source:""})
                        audio: audioPlayback; messageId: String(message.modelData.id || "")
                        reducedMotion: root.reducedMotion
                        x: 8; y: sender.visible ? sender.y + sender.height + (message.compactAudio ? 2 : 5) : message.compactAudio ? 6 : 8
                        width: parent.width - 16; height: visible ? implicitHeight : 0
                        onOpenRequested: root.openMedia(message.modelData.id, message.modelData.media)
                    }
                    Text {
                        id: body
                        objectName: "whatsappMessageText"
                        x: 10; y: media.visible ? media.y + media.height + (visible ? 5 : 0) : sender.visible ? sender.y + sender.height + 4 : 8
                        width: parent.width - 20
                        text: message.modelData.text; wrapMode: Text.Wrap
                        visible: !message.modelData.media || !!message.modelData.media.caption
                        height: visible ? implicitHeight : 0
                        color: root.ink; font.family: root.family; font.pixelSize: 14
                        lineHeight: 1.15
                        textFormat: Text.PlainText
                    }
                    Row {
                        id: stamp
                        anchors.right: parent.right; anchors.rightMargin: 10
                        y: body.y + body.height + (message.compactAudio ? 1 : 3); spacing: 5
                        Text { text: message.modelData.time; color: root.muted; font.family: root.family; font.pixelSize: message.compactAudio ? 9 : 10 }
                        VeloraWhatsAppIcon {
                            visible: message.modelData.outgoing && (!root.live || message.modelData.read===true)
                            width: 17; height: 14; iconName: "read"; ink: "#55c6ce"
                        }
                    }
                }
                VeloraWhatsAppAvatar {
                    objectName: "whatsappSenderAvatar"
                    visible: root.live && !message.modelData.outgoing
                    x: 12; y: 2; width: 30; height: 30; style: -1
                    opacity: motion.presence
                    transform: Translate { y: motion.lift + motion.rise }
                    HoverHandler { id: avatarHover; blocking: false }
                    imageSource: message.modelData.senderAvatar || (!root.preview.groups ? root.preview.contact.avatar || "" : "")
                    initials: Array.from(String(message.modelData.sender || (!root.preview.groups ? root.preview.contact.name : "") || ""))[0] || ""
                }
            }
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        }
        Text {
            visible: root.live && !!root.preview.operationError
            Layout.fillWidth: true; Layout.leftMargin: 18; Layout.rightMargin: 18
            text: root.live ? root.preview.operationError || "" : ""
            color: "#e4b6a5"; font.family: root.family; font.pixelSize: 11; wrapMode: Text.WordWrap
            textFormat: Text.PlainText
        }
        Flickable {
            id: attachmentsStrip
            visible: root.live && root.preview.attachments && root.preview.attachments.length > 0
            Layout.fillWidth: true; Layout.leftMargin: 16; Layout.rightMargin: 16
            Layout.preferredHeight: 64
            clip: true; contentWidth: attachmentEntries.width; contentHeight: 64
            flickableDirection: Flickable.HorizontalFlick; boundsBehavior: Flickable.StopAtBounds
            Row {
                id: attachmentEntries; spacing: 8
            Repeater {
                model: root.live ? root.preview.attachments || [] : []
                delegate: Rectangle {
                    id: attachment
                    required property var modelData
                    property real reveal: 1
                    opacity: reveal
                    transform: Translate { y: 6*(1-attachment.reveal) }
                    Component.onCompleted: attachmentEntrance.start()
                    NumberAnimation { id: attachmentEntrance; target: attachment; property: "reveal"; from: 0; to: 1; duration: root.reducedMotion ? 0 : 220; easing.type: Easing.OutCubic }
                    width: 136; height: 64
                    radius: 10; color: "#18ffffff"
                    Image {
                        x: 5; y: 5; width: 48; height: 54
                        source: attachment.modelData.isAnimated ? "" : attachment.modelData.kind==="sticker" ? attachment.modelData.displaySource || "" : attachment.modelData.mime.startsWith("image/") ? attachment.modelData.source : ""
                        fillMode: Image.PreserveAspectFit; asynchronous: true; sourceSize: Qt.size(96,96)
                    }
                    AnimatedImage {
                        x: 5; y: 5; width: 48; height: 54
                        source: attachment.modelData.isAnimated ? attachment.modelData.displaySource || "" : ""
                        playing: visible && !root.reducedMotion; cache: false
                        fillMode: Image.PreserveAspectFit; sourceSize: Qt.size(96,96)
                    }
                    Text {
                        x: attachment.modelData.mime.startsWith("image/") ? 58 : 8; y: 24
                        width: parent.width - x - 30
                        text: attachment.modelData.name; color: root.ink; elide: Text.ElideRight
                        textFormat: Text.PlainText; font.pixelSize: 11
                    }
                    VeloraWhatsAppButton {
                        anchors.right: parent.right; width: 30; height: 30; iconName: "close"; hint: "Remover arquivo"
                        onClicked: root.preview.removeAttachment(attachment.modelData.id)
                        reducedMotion: root.reducedMotion
                    }
                }
            }
            }
        }
        Rectangle {
            id: composerSurface
            visible: root.showConversations
            Layout.fillWidth: true; Layout.leftMargin: 16; Layout.rightMargin: 16
            Layout.preferredHeight: 68; Layout.bottomMargin: 12
            radius: 22; color: composer.activeFocus ? "#15f1f3f4" : "#0df1f3f4"
            Behavior on color { ColorAnimation { duration: root.reducedMotion ? 0 : 180 } }
            RowLayout {
                anchors.fill: parent; anchors.margins: 8; spacing: 6
                VeloraWhatsAppButton {
                    objectName: "whatsappEmoji"
                    iconName: "emoji"; hint: "Emoji e figurinhas"; tooltipEnabled: false
                    enabled: root.live && root.preview.connected && !root.preview.sending
                    reducedMotion: root.reducedMotion
                    onClicked: emojiPicker.visible ? emojiPicker.close() : emojiPicker.open()
                }
                TextArea {
                    id: composer
                    objectName: "whatsappComposer"
                    Layout.fillWidth: true; Layout.fillHeight: true
                    placeholderText: "Escreva uma mensagem…"
                    placeholderTextColor: root.muted
                    color: root.ink; font.family: root.family; font.pixelSize: 13
                    wrapMode: TextEdit.Wrap; selectByMouse: true
                    clip: true
                    readOnly: root.live && (!root.preview.connected || root.preview.sending)
                    topPadding: 15; bottomPadding: 8; leftPadding: 0; rightPadding: 0
                    background: Item {}
                    text: root.preview.draft
                    onTextChanged: if (root.preview.draft !== text) root.preview.draft = text
                    Accessible.name: "Mensagem do WhatsApp"
                    Keys.onPressed: event => {
                        if (!root.live) return
                        if (event.matches(StandardKey.Paste)) { root.preview.pasteClipboard(); event.accepted = true }
                        else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
                            root.preview.sendDraft(); event.accepted = true
                        }
                    }
                }
                VeloraWhatsAppButton {
                    objectName: "whatsappAttach"
                    iconName: "attach"; hint: "Anexar"; enabled: root.live && root.preview.connected && !root.preview.sending
                    reducedMotion: root.reducedMotion; onClicked: files.open()
                }
                VeloraWhatsAppButton {
                    objectName: "whatsappSend"
                    implicitWidth: 42; implicitHeight: 42; iconName: "send"; hint: "Enviar"
                    enabled: root.live && root.preview.connected && !root.preview.sending
                        && (composer.text.trim().length > 0 || root.preview.attachments.length > 0)
                    busy: root.live && root.preview.sending
                    scale: (pressed ? .94 : 1) + .07 * root.sendPulse
                    background: Rectangle { radius: width / 2; color: "#348f75" }
                    onClicked: root.preview.sendDraft()
                    reducedMotion: root.reducedMotion
                }
            }
        }
        VeloraWhatsAppButton {
            objectName: "whatsappBack"
            Layout.alignment: Qt.AlignHCenter; Layout.bottomMargin: 8
            implicitHeight: 26; iconName: "back"; hint: "Voltar aos apps"
            reducedMotion: root.reducedMotion; onClicked: root.backRequested()
        }
    }
    VeloraWhatsAppButton {
        id: jumpToLatest
        objectName: "whatsappScrollBottom"
        readonly property bool needed: root.showConversations && messages.count>0 && !messages.atLatest
        property real reveal: needed ? 1 : 0
        Behavior on reveal { NumberAnimation { duration: root.reducedMotion ? 0 : 180; easing.type: Easing.OutCubic } }
        x: root.width - width - 22
        y: messages.y + messages.height - height - 12
        width: 42; height: 42; z: 10
        iconName: "down"; hint: "Ir às mensagens mais recentes"
        visible: needed || reveal>0; enabled: needed
        opacity: reveal; scale: (.93+.07*reveal)*(pressed ? .94 : 1)
        transform: Translate { y: 10*(1-jumpToLatest.reveal) }
        reducedMotion: root.reducedMotion
        background: Rectangle { radius: width / 2; color: "#e32a3033" }
        onClicked: root.scrollToBottom()
    }
    Popup {
        id: accountMenu
        property real reveal: 1
        parent: root
        x: root.width - width - 16; y: 76
        width: Math.min(280, root.width - 32)
        padding: 14; focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        enter: Transition { NumberAnimation { target: accountMenu; property: "reveal"; from: 0; to: 1; duration: root.reducedMotion ? 0 : 220; easing.type: Easing.OutCubic } }
        exit: Transition { NumberAnimation { target: accountMenu; property: "reveal"; to: 0; duration: root.reducedMotion ? 0 : 140; easing.type: Easing.InCubic } }
        background: Rectangle { radius: 14; color: "#f51c2528"; opacity: accountMenu.reveal; scale: .97+.03*accountMenu.reveal }
        contentItem: ColumnLayout {
            opacity: accountMenu.reveal
            spacing: 12
            Text {
                Layout.fillWidth: true
                text: root.live ? root.preview.accountName || "WhatsApp" : "WhatsApp"
                color: root.ink; font.family: root.family; font.pixelSize: 14
                textFormat: Text.PlainText; elide: Text.ElideRight
            }
            Button {
                visible: root.live && !root.preview.connected
                text: "Reconectar"
                onClicked: { root.preview.reconnect(); accountMenu.close() }
            }
            Button {
                objectName: "whatsappLogout"
                text: "Sair da conta"
                onClicked: { root.preview.logout(); accountMenu.close() }
            }
        }
    }
}
