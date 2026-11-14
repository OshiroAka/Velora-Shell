pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "EdgeMediaContours.js" as Contours

Item {
    id: root
    required property var media
    required property var library
    required property var theme
    property bool lyrics: false
    property bool reducedMotion: false
    property bool following: true
    property var contourSamples: Contours.samples(lyrics ? 2 : 1)
    readonly property color ink: lyrics && theme ? theme.textPrimary : "#f4f5f7"
    readonly property color muted: lyrics && theme ? theme.textSecondary : "#b8bec7"
    readonly property string family: theme ? theme.bodyFont : "sans-serif"
    readonly property string lyricsFamily: lyricFont.name || "serif"
    FontLoader { id: lyricFont; source: "../assets/fonts/LiberationSerif-Regular.ttf" }
    readonly property bool hasTrack: !!media && media.hasPlayer
    readonly property real position: Math.max(0, Math.min(media.length || 0, media.sampledPosition || 0))
    readonly property bool interactionHeld: seek.pressed || searchPopup.visible
        || lines.dragging || lines.flicking || tracks.dragging || tracks.flicking
    readonly property real contentLeft: lyrics ? 46 : Math.min(104, width * .26)
    readonly property real contentWidth: Math.max(0, width - contentLeft - 24)
    readonly property bool compact: contentWidth < 260
    readonly property bool searching: library.page === "search"
    readonly property real artworkHeight: Math.min(650, Math.max(280, height * .64)) + 40
    QtObject {
        id: panelTheme
        readonly property color textPrimary: root.ink
        readonly property color textSecondary: root.muted
        readonly property string bodyFont: root.family
    }
    function currentTrack(track) {
        const current = media.spotifyCurrent
        return hasTrack && !!current && !!current.uri && String(track.uri || "") === String(current.uri)
    }
    signal backRequested()
    signal lyricsRequested()
    signal mediaRequested()
    signal closeRequested()
    function alpha(c, a) { return Qt.rgba(c.r,c.g,c.b,a) }
    function time(seconds) {
        const s = Math.max(0, Math.floor(seconds || 0))
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }
    function followLine() {
        if (!following || !lyrics || library.activeLine < 0 || lines.dragging || lines.flicking) return
        lyricSlide.stop()
        const start = lines.contentY
        // positionViewAtIndex changes contentY internally and bypasses its
        // Behavior. Measure that destination, then animate the real property.
        lines.positionViewAtIndex(library.activeLine, ListView.Center)
        const destination = lines.contentY
        if (reducedMotion || !visible || Math.abs(destination - start) < .5) return
        lines.contentY = start
        lyricSlide.from = start; lyricSlide.to = destination
        lyricSlide.restart()
    }
    NumberAnimation {
        id: lyricSlide
        objectName: "edgeLyricsSlide"
        target: lines; property: "contentY"
        duration: 900; easing.type: Easing.InOutCubic
    }
    onReducedMotionChanged: if (reducedMotion) lyricSlide.complete()
    onVisibleChanged: if (!visible) { lyricSlide.stop(); searchPopup.close() }
    onLyricsChanged: { if (!lyrics) lyricSlide.stop(); else { searchPopup.close() } }
    Connections {
        target: root.library
        function onActiveLineChanged() { root.followLine() }
        function onLinesChanged() { root.following = true; Qt.callLater(root.followLine) }
    }
    Component.onCompleted: Qt.callLater(followLine)
    Keys.onEscapePressed: closeRequested()
    Keys.onSpacePressed: if (hasTrack && media.canToggle) media.togglePlaying()

    VeloraMediaBackdrop {
        objectName: "edgeMediaBackdrop"
        anchors.fill: parent
        visible: !root.lyrics
        source: root.hasTrack ? root.media.artUrl : ""
        artworkHeight: root.artworkHeight
        contourSamples: root.contourSamples
        animated: !root.reducedMotion
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.leftMargin: root.contentLeft; anchors.rightMargin: 24
        anchors.topMargin: 22; anchors.bottomMargin: 26
        spacing: root.compact ? 10 : 14
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Layout.leftMargin: Math.max(0, Contours.offset(root.contourSamples,
                38 / Math.max(1, root.height)) * root.width + 24 - root.contentLeft)
            VeloraMaterialIcon { implicitWidth: 23; implicitHeight: 23; iconName: "music"; iconColor: root.ink }
            Text {
                Layout.fillWidth: true; Layout.leftMargin: 5
                text: root.lyrics ? "Lyrics" : "Media"
                color: root.ink; font.family: root.lyrics ? root.lyricsFamily : root.family
                font.pixelSize: root.lyrics ? 23 : 17
            }
            IconButton {
                id: searchButton
                objectName: "edgeMediaSearchButton"
                visible: !root.lyrics
                iconName: "search"; hint: "Buscar no Spotify"
                highlighted: searchPopup.visible || root.searching
                onClicked: searchPopup.visible ? searchPopup.close() : searchPopup.open()
            }
            IconButton {
                iconName: root.lyrics ? "music" : "memo"
                hint: root.lyrics ? "Voltar à música" : "Letras da música"
                enabled: root.lyrics || root.media.spotifyPlaying
                onClicked: root.lyrics ? root.mediaRequested() : root.lyricsRequested()
            }
            IconButton { iconName: "close"; hint: "Fechar"; onClicked: root.closeRequested() }
        }
        Rectangle {
            visible: root.lyrics; Layout.fillWidth: true
            Layout.leftMargin: Math.max(0, Contours.offset(root.contourSamples,
                65 / Math.max(1, root.height)) * root.width + 24 - 46)
            implicitHeight: 1; color: root.alpha(root.ink, .12)
        }

        Item {
            visible: !root.lyrics
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(24, Math.min(root.height * .27, root.height - 540))
        }
        ColumnLayout {
            visible: !root.lyrics; Layout.fillWidth: true; spacing: 3
            Text {
                Layout.fillWidth: true
                text: root.hasTrack ? root.media.title : "Seu Spotify, aqui"
                textFormat: Text.PlainText; color: root.ink; font.family: root.family
                font.pixelSize: root.compact ? 21 : 24; font.weight: Font.Medium
                wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true; text: root.hasTrack ? root.media.artist : "Abra o Spotify para começar."
                textFormat: Text.PlainText; color: root.muted; font.family: root.family; font.pixelSize: 13
                elide: Text.ElideRight
            }
        }

        Item {
            visible: root.lyrics; Layout.fillWidth: true; Layout.fillHeight: true
            ListView {
                id: lines
                objectName: "edgeLyrics"
                anchors.top: parent.top; anchors.bottom: parent.bottom
                anchors.bottomMargin: root.following ? 0 : 34
                x: -46; width: root.width
                clip: true; spacing: 30
                cacheBuffer: height * 2
                model: root.library.lines
                boundsBehavior: Flickable.StopAtBounds
                header: Item { height: lines.height * .28 }
                footer: Item { height: lines.height * .38 }
                onDraggingChanged: if (dragging) { lyricSlide.stop(); root.following = false }
                delegate: Item {
                    id: line
                    required property var modelData
                    required property int index
                    readonly property bool current: root.library.synced && index === root.library.activeLine
                    property real glow: current ? 1 : 0
                    Behavior on glow {
                        NumberAnimation { duration: root.reducedMotion ? 0 : 420; easing.type: Easing.InOutCubic }
                    }
                    readonly property real screenY: lines.mapToItem(root, 0, 0).y
                        + y - lines.contentY + height / 2
                    readonly property real boundary: Contours.offset(root.contourSamples,
                        screenY / Math.max(1, root.height)) * root.width
                    width: lines.width; height: words.implicitHeight + 16
                    Text {
                        id: words
                        objectName: "edgeLyricWords" + line.index
                        // A constant wrapping width keeps the row's height stable
                        // while its center follows the actual surface silhouette.
                        width: Math.max(120, root.width * .60 - 52)
                        x: line.boundary + 24 + (root.width - line.boundary - 48 - width) / 2
                        y: 8
                        text: String(line.modelData.text || ""); textFormat: Text.PlainText
                        color: root.ink; font.family: root.lyricsFamily; font.pixelSize: 26
                        wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
                        lineHeight: 1.3; opacity: !root.library.synced || line.current ? 1 : .34
                        scale: line.current ? 1 : .93
                        layer.enabled: root.lyrics && root.visible && line.glow > .001
                            && GraphicsInfo.api !== GraphicsInfo.Software
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: root.ink
                            shadowOpacity: line.glow * .9
                            shadowBlur: .75
                            shadowHorizontalOffset: 0
                            shadowVerticalOffset: 0
                        }
                        Behavior on opacity { NumberAnimation { duration: root.reducedMotion ? 0 : 260 } }
                        Behavior on scale { NumberAnimation { duration: root.reducedMotion ? 0 : 300; easing.type: Easing.OutCubic } }
                    }
                    TapHandler {
                        enabled: root.library.synced && root.media.canSeek
                        onTapped: { root.media.seekTo(Number(line.modelData.time)); root.following = true; root.followLine() }
                    }
                }
            }
            Column {
                anchors.centerIn: parent; width: parent.width; spacing: 14
                visible: root.library.lines.length === 0
                Text {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                    text: root.library.lyricsState === "loading" ? "Buscando a letra…"
                        : root.library.lyricsState === "error" ? "Não foi possível carregar a letra."
                        : "Letra indisponível para esta faixa."
                    color: root.muted; font.family: root.family; font.pixelSize: 14
                }
                VeloraSettingsLink {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.library.lyricsState === "error"
                    label: "Tentar novamente"; theme: root.theme
                    onTriggered: root.library.retryLyrics()
                }
            }
            VeloraSettingsLink {
                anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                visible: root.library.synced && !root.following
                label: "Acompanhar"; theme: root.theme
                onTriggered: { root.following = true; root.followLine() }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; Layout.maximumWidth: root.lyrics ? 250 : Infinity
            Layout.alignment: Qt.AlignRight; spacing: 0
            VeloraMotionSlider {
                id: seek; objectName: "edgeMediaSeek"
                Layout.fillWidth: true; implicitHeight: 24
                handleSize: 6; trackHeight: 2
                from: 0; to: Math.max(1, root.media.length || 0)
                enabled: root.hasTrack && root.media.canSeek
                ink: root.ink; reducedMotion: root.reducedMotion
                Accessible.name: "Posição da música"
                Binding { target: seek; property: "value"; value: root.position; when: !seek.pressed }
                onPressedChanged: if (!pressed && enabled) root.media.seekTo(value)
                Keys.onLeftPressed: root.media.seekTo(root.position - 5)
                Keys.onRightPressed: root.media.seekTo(root.position + 5)
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: root.time(seek.pressed ? seek.value : root.position); color: root.muted; font.family: root.family; font.pixelSize: 10 }
                Item { Layout.fillWidth: true }
                Text { text: root.time(root.media.length); color: root.muted; font.family: root.family; font.pixelSize: 10 }
            }
        }
        RowLayout {
            objectName: "edgeMediaTransport"
            visible: !root.lyrics
            Layout.alignment: Qt.AlignHCenter
            spacing: root.compact ? 20 : 28
            VeloraMediaTransportButton {
                objectName: "edgeMediaPrevious"
                ink: root.ink; animated: !root.reducedMotion
                iconName: "skip-previous"; hint: "Anterior"
                enabled: root.media.canPrevious; onClicked: root.media.previous()
            }
            VeloraMediaTransportButton {
                objectName: "edgeMediaPlay"
                primary: true
                ink: root.ink; animated: !root.reducedMotion
                iconName: root.hasTrack && root.media.playing ? "pause" : "play"
                hint: !root.hasTrack ? "Abrir Spotify" : root.media.playing ? "Pausar" : "Reproduzir"
                enabled: !root.hasTrack || root.media.canToggle
                onClicked: root.hasTrack ? root.media.togglePlaying() : root.media.openSpotify("")
            }
            VeloraMediaTransportButton {
                objectName: "edgeMediaNext"
                ink: root.ink; animated: !root.reducedMotion
                iconName: "skip-next"; hint: "Próxima"
                enabled: root.media.canNext; onClicked: root.media.next()
            }
        }
        Item { visible: !root.lyrics; Layout.fillHeight: true; Layout.minimumHeight: 0 }
        VeloraSettingsLink {
            objectName: "edgeMediaBack"
            Layout.alignment: Qt.AlignHCenter
            label: "Voltar aos apps"; theme: panelTheme
            onTriggered: root.backRequested()
        }
    }
    Popup {
        id: searchPopup
        objectName: "edgeMediaSearchPopup"
        parent: root
        x: root.contentLeft; y: 70
        width: root.contentWidth
        height: root.searching ? Math.min(330, root.height - y - 30) : 40
        padding: 0; focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { radius: 10; color: root.searching ? "#f51b1d22" : "transparent" }
        onOpened: search.forceActiveFocus()
        onClosed: if (root.visible && !root.lyrics) searchButton.forceActiveFocus()
        contentItem: ColumnLayout {
            spacing: 8
            TextField {
                Layout.fillWidth: true
                id: search; objectName: "edgeMediaSearch"
                implicitHeight: 40
                placeholderText: "Buscar no Spotify…"; placeholderTextColor: root.muted
                color: root.ink; font.family: root.family; font.pixelSize: 12
                leftPadding: 12; selectByMouse: true
                Accessible.name: "Buscar no Spotify"
                onTextEdited: { root.library.page = text.trim().length > 1 ? "search" : "queue"; root.library.query = text }
                onAccepted: root.library.search()
                Keys.onEscapePressed: searchPopup.close()
                hoverEnabled: true
                background: Rectangle {
                    radius: 10
                    color: search.activeFocus ? "#d52b2e34" : search.hovered ? "#b52b2e34" : "#9525282e"
                    border.color: root.alpha(root.ink, search.activeFocus ? .28 : search.hovered ? .12 : .06)
                    Behavior on color { ColorAnimation { duration: root.reducedMotion ? 0 : 130 } }
                    Behavior on border.color { ColorAnimation { duration: root.reducedMotion ? 0 : 130 } }
                }
            }
            Item {
                visible: root.searching
                Layout.fillWidth: true; Layout.fillHeight: true
                ListView {
                    id: tracks; objectName: "edgeMediaSearchResults"
                    anchors.fill: parent; anchors.margins: 6
                    clip: true; spacing: 4
                    boundsBehavior: Flickable.StopAtBounds
                    model: searchPopup.visible && root.searching ? root.library.results : []
                    delegate: VeloraMediaTrackRow {
                        width: tracks.width
                        current: root.currentTrack(modelData)
                        ink: root.ink; muted: root.muted; family: root.family
                        reducedMotion: root.reducedMotion
                        onPlayRequested: uri => root.media.playTrack(uri)
                    }
                    ScrollBar.vertical: ScrollBar {}
                }
                Text {
                    anchors.fill: parent; anchors.margins: 12
                    visible: tracks.count === 0; wrapMode: Text.WordWrap
                    text: root.library.searchState === "loading" ? "Buscando…"
                        : root.library.searchState === "offline" ? "Abra o Spotify para buscar."
                        : root.library.searchState === "error" ? "Não foi possível buscar. Pressione Enter para tentar novamente."
                        : "Nenhuma música encontrada."
                    color: root.muted; font.family: root.family; font.pixelSize: 11
                }
            }
        }
    }
    component IconButton: VeloraMediaButton {
        ink: root.ink; accent: root.ink; animated: !root.reducedMotion
        implicitWidth: root.compact ? 36 : 40; implicitHeight: implicitWidth
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Keys.onReturnPressed: clicked()
        Keys.onEnterPressed: clicked()
        Accessible.description: highlighted ? "Ativo" : ""
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom; anchors.bottomMargin: 3
            width: 3; height: 3; radius: 1.5
            color: root.ink; visible: parent.highlighted
        }
        ToolTip.visible: false
    }
}
