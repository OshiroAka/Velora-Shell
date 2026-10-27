pragma ComponentBehavior: Bound
import QtQuick
import QtMultimedia

Item {
    id: root
    required property var client
    property string messageId: ""
    property bool requested: false
    readonly property var entry: client.contact.messages.find(value => value.id === messageId)
    readonly property string source: entry && entry.media ? entry.media.source || "" : ""
    readonly property bool playing: player.playbackState === MediaPlayer.PlayingState
    readonly property int position: player.position
    readonly property int duration: player.duration
    readonly property bool seekable: player.seekable
    readonly property bool failed: player.error !== MediaPlayer.NoError
    function toggle(id) {
        if (messageId !== id) { player.stop(); requested = true; messageId = id }
        else if (playing) { requested = false; player.pause(); return }
        else requested = true
        if (source) player.play()
        else client.loadMedia(client.selectedId,id)
    }
    function seek(value) { if (player.seekable) player.position = value }
    function stop() { requested = false; player.stop(); messageId = "" }
    Connections {
        target: root.client; ignoreUnknownSignals: true
        function onSelectedIdChanged() { root.stop() }
    }
    MediaPlayer {
        id: player
        objectName: "whatsappAudioPlayer"
        source: root.source
        audioOutput: AudioOutput {}
        onSourceChanged: if (root.source && root.requested) play()
    }
}
