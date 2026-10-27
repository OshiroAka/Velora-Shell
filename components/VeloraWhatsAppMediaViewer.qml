pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia

Popup {
    id: root
    objectName: "whatsappMediaViewer"
    required property var client
    property bool reducedMotion: false
    property real reveal: 1
    property string chat: ""
    property string messageId: ""
    readonly property var entry: client.contact.messages.find(value => value.id === messageId)
    readonly property var media: entry && entry.media ? entry.media : ({kind:"",source:"",thumbnail:""})
    modal: true; focus: true; padding: 12
    closePolicy: Popup.CloseOnEscape
    background: Rectangle { radius: 16; color: "#f214191b"; opacity: root.reveal; scale: .97+.03*root.reveal }
    enter: Transition { NumberAnimation { target: root; property: "reveal"; from: 0; to: 1; duration: root.reducedMotion ? 0 : 280; easing.type: Easing.OutCubic } }
    exit: Transition { NumberAnimation { target: root; property: "reveal"; to: 0; duration: root.reducedMotion ? 0 : 180; easing.type: Easing.InCubic } }
    onClosed: player.stop()
    function view(chatId, id) {
        chat = chatId; messageId = id
        client.loadMedia(chat, messageId)
        open()
    }
    Connections {
        target: root.client
        ignoreUnknownSignals: true
        function onSelectedIdChanged() { root.close() }
    }
    contentItem: Item {
        opacity: root.reveal
        transform: Translate { y: 10*(1-root.reveal) }
        ColumnLayout {
        anchors.fill: parent
        spacing: 10
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: root.media.filename || (root.media.kind === "video" ? "Vídeo" : "Imagem")
                color: "#f1f3f4"; font.pixelSize: 14; elide: Text.ElideRight; textFormat: Text.PlainText
            }
            VeloraWhatsAppButton { iconName: "close"; hint: "Fechar mídia"; reducedMotion: root.reducedMotion; onClicked: root.close() }
        }
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true
            Image {
                anchors.fill: parent
                visible: root.media.kind !== "video" && !root.media.isAnimated
                source: root.visible && visible ? root.media.displaySource || (root.media.kind==="sticker" || root.media.mime==="image/webp" ? "" : root.media.source) || root.media.thumbnail || "" : ""
                asynchronous: true; fillMode: Image.PreserveAspectFit
            }
            AnimatedImage {
                anchors.fill: parent
                visible: root.media.kind === "sticker" && root.media.isAnimated===true
                source: root.visible && visible ? root.media.displaySource || "" : ""
                cache: false; sourceSize: Qt.size(512,512)
                playing: root.visible && !root.reducedMotion; fillMode: Image.PreserveAspectFit
            }
            VideoOutput { id: output; anchors.fill: parent; visible: root.media.kind === "video"; fillMode: VideoOutput.PreserveAspectFit }
            Text {
                anchors.centerIn: parent; width: parent.width - 20
                visible: !root.media.source || ((root.media.kind==="sticker" || root.media.mime==="image/webp") && !root.media.displaySource) || player.error !== MediaPlayer.NoError
                text: root.media.error || (player.error !== MediaPlayer.NoError ? "Não foi possível reproduzir este vídeo." : "Carregando…")
                color: "#c0c8cc"; font.pixelSize: 13; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
            }
        }
        RowLayout {
            visible: root.media.kind === "video" && !!root.media.source
            Layout.fillWidth: true
            VeloraWhatsAppButton {
                hint: player.playbackState === MediaPlayer.PlayingState ? "Pausar vídeo" : "Reproduzir vídeo"
                iconName: player.playbackState === MediaPlayer.PlayingState ? "pause" : "play"
                reducedMotion: root.reducedMotion
                onClicked: player.playbackState === MediaPlayer.PlayingState ? player.pause() : player.play()
            }
            Slider {
                Layout.fillWidth: true; from: 0; to: Math.max(1,player.duration); value: player.position
                enabled: player.seekable; onMoved: player.position = value
                Accessible.name: "Posição do vídeo"
            }
        }
    }
    }
    MediaPlayer {
        id: player
        objectName: "whatsappVideoPlayer"
        source: root.visible && root.media.kind === "video" ? root.media.source || "" : ""
        videoOutput: output; audioOutput: AudioOutput {}
        onSourceChanged: if (source.toString()) play()
    }
}
