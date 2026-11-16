pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../features/topbar" as Bar

Item {
    id: root
    required property var theme
    required property var media
    required property var status
    required property var tools
    property string avatarSource: ""
    property string profileName: "Seu perfil"
    property bool reducedMotion: false
    property bool outputsOpen: false
    readonly property bool interactionHeld: volume.pressed || progress.pressed
    readonly property color ink: theme.textPrimary
    readonly property color muted: theme.textSecondary
    readonly property string family: theme.bodyFont
    signal toolRequested(string action)
    function alpha(color, amount) { return Qt.rgba(color.r, color.g, color.b, amount) }
    function timeLabel(seconds) {
        const value = Math.max(0, Math.floor(Number(seconds) || 0))
        return Math.floor(value / 60) + ":" + String(value % 60).padStart(2, "0")
    }
    component Label: Text {
        color: root.ink; font.family: root.family; font.pixelSize: 12
        elide: Text.ElideRight; textFormat: Text.PlainText
    }
    component IconButton: Button {
        id: button
        property string iconName: ""
        property bool filled: false
        implicitWidth: 36; implicitHeight: 36
        Accessible.name: text
        hoverEnabled: true
        background: Rectangle {
            radius: width / 2
            color: button.filled ? root.ink : root.alpha(root.ink, button.down ? .17 : button.hovered ? .09 : 0)
            border.width: button.activeFocus ? 1 : 0; border.color: root.ink
            Behavior on color { ColorAnimation { duration: root.reducedMotion ? 0 : 140 } }
        }
        contentItem: Bar.BarIcon {
            name: button.iconName; color: button.filled ? root.theme.barSurface : root.ink
            opacity: button.enabled ? 1 : .3
            width: 18; height: 18
        }
        padding: 9
    }
    component Tile: Button {
        id: tile
        required property string toolKey
        required property string iconName
        readonly property bool stopping: toolKey === "record" && root.tools.recording
        readonly property bool available: stopping || !!root.tools.capabilities[toolKey]?.available
        Layout.fillWidth: true; Layout.fillHeight: true
        objectName: "profile-tool-" + toolKey
        enabled: stopping || (available && !root.tools.busy)
        hoverEnabled: true
        Accessible.name: text
        Accessible.description: available ? "" : "Ferramenta indisponível neste sistema"
        onClicked: stopping ? root.tools.stopRecording() : root.toolRequested(toolKey)
        background: Rectangle {
            radius: 18
            color: root.alpha(root.ink, tile.down ? .16 : tile.hovered ? .115 : .065)
            border.width: tile.activeFocus ? 1 : 0
            border.color: root.alpha(root.ink, .6)
            Behavior on color { ColorAnimation { duration: root.reducedMotion ? 0 : 140 } }
        }
        contentItem: Item {
          Column {
            anchors.centerIn: parent; width: parent.width
            spacing: 5
            opacity: tile.available ? 1 : .38
            Bar.BarIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 21; height: 21
                name: tile.stopping ? "stop" : tile.iconName
                color: tile.stopping ? root.theme.danger : root.ink
            }
            Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: tile.stopping ? "Parar gravação" : tile.text; font.pixelSize: 11 }
            Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "Indisponível"; visible: !tile.available; color: root.muted; font.pixelSize: 9 }
          }
        }
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        RowLayout {
            Layout.fillWidth: true; Layout.fillHeight: false; Layout.minimumHeight: 44; Layout.maximumHeight: 44
            Rectangle {
                Layout.preferredWidth: 100; Layout.fillHeight: true
                radius: 22; color: root.alpha(root.ink, .13)
                Row {
                    anchors.centerIn: parent; spacing: 6
                    Bar.BarIcon { width: 17; height: 17; name: "home"; color: root.ink }
                    Label { text: "Principal"; height: 17; verticalAlignment: Text.AlignVCenter }
                }
            }
            Item { Layout.fillWidth: true }
            Label {
                Layout.maximumWidth: root.width - 120
                text: root.tools.recording ? "●  Gravando" : root.tools.error
                color: root.tools.recording ? root.theme.danger : root.muted
                font.pixelSize: 10
            }
        }
        RowLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            spacing: 10
            Rectangle {
                id: mediaCard
                Layout.fillWidth: true; Layout.preferredWidth: 420; Layout.fillHeight: true
                radius: 22; color: root.alpha(root.ink, .065)
                RowLayout {
                    anchors.fill: parent; anchors.margins: 22
                    spacing: 15
                    ColumnLayout {
                        Layout.preferredWidth: Math.max(70, Math.min(108, mediaCard.width * .25))
                        spacing: 9
                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: Math.min(86, mediaCard.width * .23); Layout.preferredHeight: width
                            Rectangle { anchors.fill: parent; radius: width / 2; color: root.alpha(root.ink, .09); border.width: 1; border.color: root.alpha(root.ink, .18) }
                            Bar.BarIcon {
                                anchors.centerIn: parent; width: 28; height: 28
                                name: "user"; color: root.ink
                                visible: avatar.status !== Image.Ready
                            }
                            Image {
                                id: avatar
                                anchors.fill: parent; anchors.margins: 2
                                source: root.avatarSource
                                sourceSize: Qt.size(172,172); fillMode: Image.PreserveAspectCrop
                                visible: false; asynchronous: true
                            }
                            Rectangle { id: avatarMask; anchors.fill: avatar; radius: width / 2; visible: false }
                            OpacityMask { anchors.fill: avatar; source: avatar; maskSource: avatarMask }
                        }
                        Label { Layout.fillWidth: true; text: root.profileName; color: root.muted; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter }
                    }
                    Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 128; color: root.alpha(root.ink, .16) }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 9
                        RowLayout {
                            Layout.fillWidth: true; spacing: 6
                            Bar.BarIcon { Layout.preferredWidth: 16; Layout.preferredHeight: 16; name: "music"; color: root.ink }
                            Label { Layout.fillWidth: true; text: root.media.playing ? "Reproduzindo agora" : root.media.hasPlayer ? "Em pausa" : "Nada tocando" }
                        }
                        Label { Layout.fillWidth: true; text: [root.media.artist, root.media.title].filter(Boolean).join(" · "); color: root.muted; font.pixelSize: 11 }
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter; spacing: 10
                            IconButton { objectName: "profile-previous"; iconName: "previous"; text: "Faixa anterior"; enabled: root.media.canPrevious; onClicked: root.media.previous() }
                            IconButton { objectName: "profile-play"; iconName: root.media.playing ? "pause" : "play"; text: root.media.playing ? "Pausar" : "Reproduzir"; filled: true; enabled: root.media.canToggle; onClicked: root.media.togglePlaying() }
                            IconButton { objectName: "profile-next"; iconName: "next"; text: "Próxima faixa"; enabled: root.media.canNext; onClicked: root.media.next() }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 0
                            VeloraMotionSlider {
                                id: progress; objectName: "profile-progress"
                                Layout.fillWidth: true; implicitHeight: 18; handleSize: 0
                                ink: root.ink; reducedMotion: root.reducedMotion
                                value: root.media.progress; enabled: root.media.canSeek
                                Accessible.name: "Posição da música"
                                onMoved: root.media.seekTo(value * root.media.length)
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: root.timeLabel(root.media.sampledPosition); color: root.muted; font.pixelSize: 10 }
                                Item { Layout.fillWidth: true }
                                Label { text: root.timeLabel(root.media.length); color: root.muted; font.pixelSize: 10 }
                            }
                        }
                    }
                }
            }
            GridLayout {
                Layout.fillWidth: true; Layout.preferredWidth: 360; Layout.fillHeight: true
                columns: 2; rowSpacing: 10; columnSpacing: 10
                Tile { toolKey: "area"; iconName: "area"; text: "Área" }
                Tile { toolKey: "screen"; iconName: "monitor"; text: "Tela inteira" }
                Tile { toolKey: "text"; iconName: "ocr"; text: "Texto" }
                Tile { toolKey: "eyedropper"; iconName: "eyedropper"; text: "Pipeta" }
                Tile { toolKey: "record"; iconName: "video"; text: "Gravar tela"; Layout.columnSpan: 2 }
            }
        }
        Rectangle {
            id: audioCard
            Layout.fillWidth: true; Layout.preferredHeight: 50
            radius: 17; color: root.alpha(root.ink, .065)
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                spacing: 8
                IconButton { objectName: "profile-mute"; iconName: root.status.muted ? "muted" : "volume"; text: root.status.muted ? "Ativar som" : "Silenciar"; enabled: root.status.hasAudio; onClicked: root.status.toggleMuted() }
                VeloraMotionSlider {
                    id: volume; objectName: "profile-volume"
                    Layout.fillWidth: true; ink: root.ink; reducedMotion: root.reducedMotion
                    handleSize: 0; value: root.status.volume; enabled: root.status.hasAudio
                    Accessible.name: "Volume"
                    onMoved: root.status.audioSink.audio.volume = value
                }
                Label { Layout.preferredWidth: 40; text: root.status.hasAudio ? root.status.volumePercent + "%" : "—"; color: root.muted; horizontalAlignment: Text.AlignRight; font.pixelSize: 11 }
                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 24; color: root.alpha(root.ink, .15) }
                IconButton { objectName: "profile-output"; iconName: "headphones"; text: "Saída de áudio"; enabled: root.tools.outputs.length > 0; onClicked: root.outputsOpen = !root.outputsOpen }
            }
        }
    }
    Rectangle {
        objectName: "profile-output-list"
        visible: root.outputsOpen
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.bottomMargin: 60
        width: Math.min(320, root.width); height: Math.min(180, devices.contentHeight + 16)
        radius: 16; color: root.theme.barSurface
        border.width: 1; border.color: root.alpha(root.ink, .15)
        ListView {
            id: devices
            anchors.fill: parent; anchors.margins: 8; clip: true; spacing: 3
            model: root.tools.outputs
            delegate: Bar.BarAction {
                required property var modelData
                width: devices.width; theme: root.theme
                text: (modelData.selected ? "✓  " : "") + modelData.name
                onClicked: { root.tools.selectOutput(modelData.id); root.outputsOpen = false }
            }
        }
    }
}
