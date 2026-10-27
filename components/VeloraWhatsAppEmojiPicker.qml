pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    objectName: "whatsappEmojiPicker"
    required property var client
    property string emojiFamily: "sans-serif"
    property bool reducedMotion: false
    property int mode: 0
    property int category: 0
    property real reveal: 1
    signal emojiSelected(string emoji)
    signal importRequested()
    signal stickerSelected(string chat, string messageId)
    readonly property var categories: [
        {name:"Rostos",values:["😀","😃","😄","😁","😆","😅","😂","🤣","🥲","😊","😍","🥰","😘","😎","🤩","🥹","😢","😭","😡","🤔","🫠","😴","🤯","🤡","💀","👻","🤖","😇","😋","😏","😐","😬","🙄","😮","🤫","🤭"]},
        {name:"Gestos",values:["👍","👎","👏","🙌","🙏","🤝","✌️","🤞","🤟","🤘","👌","🫶","💪","👋","✋","👀","❤️","🖤","💚","💜","🤍","💕","💔","✨","🔥","💯","🎉","💫","💥","⭐"]},
        {name:"Objetos",values:["🐱","🐶","🐻","🦊","🐼","🐸","🦋","🌸","🌻","🍀","🌙","☀️","🌈","☕","🍕","🍓","🍰","🎂","🎵","🎧","🎮","💻","📱","💡","📚","🎁","🚀","🏠","⚽","🌍"]}
    ]
    padding: 12; focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    background: Rectangle {
        radius: 18; color: "#f51c2528"
        scale: .96 + .04 * root.reveal
        transform: Translate { y: 14 * (1-root.reveal) }
    }
    enter: Transition { NumberAnimation { target: root; property: "reveal"; from: 0; to: 1; duration: root.reducedMotion ? 0 : 320; easing.type: Easing.OutCubic } }
    exit: Transition { NumberAnimation { target: root; property: "reveal"; to: 0; duration: root.reducedMotion ? 0 : 180; easing.type: Easing.InCubic } }
    onOpened: if (mode===1) client.requestStickers(true)
    onModeChanged: if (visible) client.requestStickers(mode===1)
    onClosed: if (mode===1) client.requestStickers(false)
    Connections {
        target: root.client; ignoreUnknownSignals: true
        function onSelectedIdChanged() { root.close() }
    }
    contentItem: Item {
        opacity: root.reveal
        transform: Translate { y: 12 * (1-root.reveal) }
        ColumnLayout {
        anchors.fill: parent; spacing: 8
        RowLayout {
            Layout.fillWidth: true
            Repeater {
                objectName: "whatsappPickerTabs"
                model: ["Emojis","Figurinhas"]
                delegate: AbstractButton {
                    id: tab
                    required property string modelData
                    required property int index
                    objectName: "whatsappPickerTab"+index
                    Layout.fillWidth: true; Layout.preferredHeight: 36
                    hoverEnabled: true; activeFocusOnTab: true
                    scale: pressed ? .98 : 1
                    Behavior on scale { NumberAnimation { duration: root.reducedMotion ? 0 : 120; easing.type: Easing.OutCubic } }
                    background: Rectangle {
                        radius: 9; color: root.mode===tab.index ? "#16ffffff" : tab.hovered ? "#0bffffff" : "transparent"
                        Behavior on color { ColorAnimation { duration: root.reducedMotion ? 0 : 140 } }
                    }
                    contentItem: Text { text: tab.modelData; color: root.mode===tab.index ? "#f1f3f4" : "#a6aeb3"; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    onClicked: { root.mode=index; pages.currentIndex=index }
                }
            }
            VeloraWhatsAppButton { iconName: "close"; hint: "Fechar seletor"; tooltipEnabled: false; reducedMotion: root.reducedMotion; onClicked: root.close() }
        }
        StackLayout {
            id: pages
            Layout.fillWidth: true; Layout.fillHeight: true
            currentIndex: root.mode
            property real pageReveal: 1
            opacity: pageReveal
            onCurrentIndexChanged: pageEntrance.restart()
            NumberAnimation { id: pageEntrance; target: pages; property: "pageReveal"; from: 0; to: 1; duration: root.reducedMotion ? 0 : 180; easing.type: Easing.OutCubic }
            ColumnLayout {
                spacing: 8
                RowLayout {
                    Layout.fillWidth: true
                    Repeater {
                        model: root.categories
                        delegate: AbstractButton {
                            id: categoryButton
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true; Layout.preferredHeight: 28
                            hoverEnabled: true; activeFocusOnTab: true
                            scale: pressed ? .98 : 1
                            Behavior on scale { NumberAnimation { duration: root.reducedMotion ? 0 : 120; easing.type: Easing.OutCubic } }
                            background: Rectangle { radius: 8; color: categoryButton.hovered || root.category===categoryButton.index ? "#0bffffff" : "transparent"; Behavior on color { ColorAnimation { duration: root.reducedMotion ? 0 : 140 } } }
                            contentItem: Text { text: categoryButton.modelData.name; font.pixelSize: 11; color: root.category===categoryButton.index ? "#f1f3f4" : "#a6aeb3"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: root.category=index
                        }
                    }
                }
                GridView {
                    id: emojis
                    objectName: "whatsappEmojiGrid"
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true; cellWidth: Math.floor(width/Math.max(1,Math.floor(width/42))); cellHeight: 42
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.categories[root.category].values
                    property real categoryReveal: 1
                    opacity: categoryReveal
                    onModelChanged: categoryEntrance.restart()
                    NumberAnimation { id: categoryEntrance; target: emojis; property: "categoryReveal"; from: 0; to: 1; duration: root.reducedMotion ? 0 : 180; easing.type: Easing.OutCubic }
                    delegate: AbstractButton {
                        id: emojiButton
                        required property string modelData
                        required property int index
                        objectName: "whatsappEmojiOption"+index
                        width: emojis.cellWidth; height: emojis.cellHeight
                        hoverEnabled: true; activeFocusOnTab: true; Accessible.name: modelData
                        background: Rectangle { anchors.margins: 2; radius: 10; color: emojiButton.hovered || emojiButton.activeFocus ? "#12ffffff" : "transparent"; Behavior on color { ColorAnimation { duration: root.reducedMotion ? 0 : 120 } } }
                        contentItem: Text {
                            text: emojiButton.modelData; font.family: root.emojiFamily; font.pixelSize: 25
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            scale: emojiButton.pressed ? .92 : emojiButton.hovered || emojiButton.activeFocus ? 1.14 : 1
                            Behavior on scale { NumberAnimation { duration: root.reducedMotion ? 0 : 150; easing.type: Easing.OutCubic } }
                        }
                        onClicked: root.emojiSelected(modelData)
                    }
                }
            }
            ColumnLayout {
                spacing: 8
                GridView {
                    id: stickers
                    objectName: "whatsappStickerGrid"
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true; cellWidth: Math.floor(width/Math.max(1,Math.floor(width/78))); cellHeight: 78
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.client.stickers || []
                    delegate: AbstractButton {
                        id: stickerButton
                        required property var modelData
                        required property int index
                        objectName: "whatsappStickerOption"+index
                        width: stickers.cellWidth; height: 78
                        enabled: root.client.connected===true && root.client.sending!==true && !!modelData.source && !!modelData.displaySource
                        hoverEnabled: true; activeFocusOnTab: true; Accessible.name: "Selecionar figurinha"
                        background: Rectangle { anchors.margins: 3; radius: 12; color: stickerButton.hovered || stickerButton.activeFocus ? "#12ffffff" : "transparent" }
                        contentItem: Item {
                            Image { anchors.fill: parent; anchors.margins: 6; source: stickerButton.modelData.isAnimated ? "" : stickerButton.modelData.displaySource || stickerButton.modelData.thumbnail || ""; asynchronous: true; fillMode: Image.PreserveAspectFit; sourceSize: Qt.size(128,128) }
                            AnimatedImage { objectName: "whatsappStickerAnimation"; anchors.fill: parent; anchors.margins: 6; source: stickerButton.modelData.isAnimated ? stickerButton.modelData.displaySource || "" : ""; playing: root.visible && root.mode===1 && !root.reducedMotion; cache: false; fillMode: Image.PreserveAspectFit; sourceSize: Qt.size(128,128) }
                            Text { anchors.centerIn: parent; visible: !stickerButton.modelData.displaySource; text: stickerButton.modelData.loading ? "…" : "Indisponível"; color: "#a6aeb3"; font.pixelSize: 10 }
                            scale: stickerButton.pressed ? .94 : stickerButton.hovered || stickerButton.activeFocus ? 1.06 : 1
                            Behavior on scale { NumberAnimation { duration: root.reducedMotion ? 0 : 160; easing.type: Easing.OutCubic } }
                        }
                        onClicked: root.stickerSelected(modelData.chat,modelData.id)
                    }
                    Text { anchors.centerIn: parent; width: parent.width-20; visible: stickers.count===0; text:"Suas figurinhas recebidas aparecem aqui.\nVocê também pode importar uma imagem."; color:"#a6aeb3"; wrapMode:Text.WordWrap; horizontalAlignment:Text.AlignHCenter; font.pixelSize:12 }
                }
                Button {
                    id: importButton
                    objectName: "whatsappImportSticker"
                    Layout.fillWidth: true; text: "Importar figurinha"
                    hoverEnabled: true; activeFocusOnTab: true
                    scale: pressed ? .98 : 1
                    Behavior on scale { NumberAnimation { duration: root.reducedMotion ? 0 : 120; easing.type: Easing.OutCubic } }
                    background: Rectangle { implicitHeight: 36; radius: 10; color: importButton.hovered || importButton.activeFocus ? "#16ffffff" : "#08ffffff"; Behavior on color { ColorAnimation { duration: root.reducedMotion ? 0 : 140 } } }
                    contentItem: Text { text: importButton.text; color: "#f1f3f4"; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    enabled: root.client.connected===true && root.client.sending!==true
                    onClicked: root.importRequested()
                }
            }
        }
        }
    }
}
