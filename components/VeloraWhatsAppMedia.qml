pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    required property var media
    property color ink: "#f1f3f4"
    property var audio: null
    property string messageId: ""
    property bool reducedMotion: false
    readonly property bool currentAudio: !!audio && audio.messageId === messageId
    signal openRequested()
    implicitHeight: media.kind === "audio" ? 24 : media.kind === "document" ? 44 : Math.min(200, width * .78)
    Image {
        anchors.fill: parent
        source: root.media.isAnimated && root.media.kind === "sticker" ? "" : root.media.kind === "video" ? root.media.thumbnail || "" : ["image","sticker"].includes(root.media.kind) ? root.media.displaySource || (root.media.mime==="image/webp" || root.media.kind==="sticker" ? "" : root.media.source) || root.media.thumbnail || "" : ""
        asynchronous: true; fillMode: Image.PreserveAspectFit
        sourceSize: Qt.size(640,640)
    }
    AnimatedImage {
        anchors.fill: parent
        source: root.media.kind==="sticker" && root.media.isAnimated ? root.media.displaySource || "" : ""
        playing: visible && !root.reducedMotion; cache: false; fillMode: Image.PreserveAspectFit; sourceSize: Qt.size(256,256)
    }
    AbstractButton {
        id: openButton
        objectName: "whatsappOpenMedia"
        anchors.fill: parent; hoverEnabled: true; activeFocusOnTab: true
        visible: root.media.kind !== "audio"
        scale: pressed ? .985 : 1
        Behavior on scale { NumberAnimation { duration: root.reducedMotion ? 0 : 120; easing.type: Easing.OutCubic } }
        Accessible.name: root.media.kind === "video" ? "Reproduzir vídeo" : root.media.kind === "image" ? "Abrir imagem" : "Abrir arquivo"
        background: Rectangle { radius: 8; color: openButton.hovered || openButton.activeFocus ? "#18ffffff" : "transparent"; Behavior on color { ColorAnimation { duration: root.reducedMotion ? 0 : 140 } } }
        contentItem: Item {
            Text {
                anchors.centerIn: parent; width: parent.width - 20
                visible: root.media.kind === "video" || (!root.media.source && !root.media.thumbnail) || !!root.media.error
                text: root.media.loading ? "Carregando…" : root.media.error ? "Tentar novamente"
                    : root.media.kind === "video" ? "▶" : root.media.filename || (root.media.kind === "image" ? "Abrir imagem" : "Abrir mídia")
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                color: root.ink; font.pixelSize: root.media.kind === "video" && !root.media.loading && !root.media.error ? 30 : 12
                textFormat: Text.PlainText
                style: Text.Outline; styleColor: "#9a101417"
            }
        }
        onClicked: root.openRequested()
    }
    RowLayout {
        visible: root.media.kind === "audio"
        anchors.fill: parent; spacing: 6
        VeloraWhatsAppButton {
            objectName: "whatsappPlayAudio"
            Layout.preferredWidth: 24; Layout.preferredHeight: 24
            hint: root.currentAudio && root.audio.playing ? "Pausar áudio" : "Ouvir áudio"
            iconName: root.currentAudio && root.audio.playing ? "pause" : "play"
            busy: root.media.loading===true; reducedMotion: root.reducedMotion; ink: root.ink
            onClicked: if (root.audio) root.audio.toggle(root.messageId)
        }
        VeloraMotionSlider {
            objectName: "whatsappAudioSeek"
            Layout.fillWidth: true; Layout.minimumWidth: 40; Layout.preferredHeight: 24
            handleSize: 7
            ink: root.ink; accent: root.ink; reducedMotion: root.reducedMotion
            from: 0; to: root.currentAudio ? Math.max(1,root.audio.duration) : 1
            value: root.currentAudio ? root.audio.position : 0
            enabled: root.currentAudio && root.audio.seekable
            onMoved: root.audio.seek(value)
            Accessible.name: "Posição do áudio"
        }
        Text {
            objectName: "whatsappAudioTime"
            Layout.preferredWidth: Math.max(27,implicitWidth)
            text: {
                if (root.media.error || (root.currentAudio && root.audio.failed)) return "Erro"
                const seconds = Math.floor((root.currentAudio ? root.audio.playing ? root.audio.position : root.audio.duration : root.media.seconds * 1000 || 0) / 1000)
                return Math.floor(seconds/60) + ":" + String(seconds%60).padStart(2,"0")
            }
            color: root.ink; font.pixelSize: 10
        }
    }
}
