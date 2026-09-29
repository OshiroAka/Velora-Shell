pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

VeloraRailPopover {
    id: root

    required property var media

    system: media

    preferredWidth: 446
    preferredHeight: 318

    contentPadding: 14

    readonly property color ink:
        theme
            ? theme.textPrimary
            : "white"

    readonly property color inkSoft:
        theme
            ? theme.textSecondary
            : "#b9b9c4"

    readonly property color accent:
        theme
            ? theme.accentPrimary
            : "#b8a18d"

    readonly property color card:
        theme
            ? theme.withAlpha(
                theme.surfaceCard,
                theme.themeMode === "dark"
                    ? 0.32
                    : 0.50
            )
            : Qt.rgba(
                1,
                1,
                1,
                0.08
            )

    function queueNumber(index) {
        const value = index + 1

        return value < 10
            ? "0" + value
            : String(value)
    }

    customContent: Component {
        Item {
            id: content

            anchors.fill: parent

            property bool interactionHeld:
                queueView.dragging
                || queueView.moving
                || queueView.flicking

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                height: 54
                radius: 14

                color: Qt.rgba(
                    root.ink.r,
                    root.ink.g,
                    root.ink.b,
                    0.025
                )

                border.width: 1
                border.color: Qt.rgba(
                    root.ink.r,
                    root.ink.g,
                    root.ink.b,
                    0.05
                )
            }

            RowLayout {
                anchors.fill: parent

                spacing: 18

                // ───────────────────────
                // CURRENT TRACK
                // ───────────────────────

                ColumnLayout {
                    Layout.preferredWidth: 160
                    Layout.fillHeight: true

                    spacing: 6

                    Rectangle {
                        id: artworkFrame

                        Layout.preferredWidth: 160
                        Layout.preferredHeight: 160

                        radius: 14

                        color: root.card

                        clip: true

                        Image {
                            id: artwork

                            anchors.fill: parent

                            source:
                                root.media
                                && root.media.hasPlayer
                                    ? root.media.artUrl
                                    : ""

                            asynchronous: true
                            smooth: true

                            fillMode:
                                Image.PreserveAspectCrop

                            sourceSize.width: 320
                            sourceSize.height: 320

                            layer.enabled: true

                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width:
                                        artworkFrame.width

                                    height:
                                        artworkFrame.height

                                    radius:
                                        artworkFrame.radius
                                }
                            }
                        }

                        VeloraMaterialIcon {
                            anchors.centerIn:
                                parent

                            width: 36
                            height: 36

                            visible:
                                artwork.status
                                    !== Image.Ready

                            iconName: "music"

                            iconColor:
                                root.ink

                            opacity: 0.42
                        }
                    }

                    Text {
                        Layout.fillWidth: true

                        text:
                            root.media
                            && root.media.hasPlayer
                                ? root.media.title
                                : "Nenhuma faixa"

                        color: root.ink

                        font.family:
                            root.theme
                                ? root.theme.uiFont
                                : "sans-serif"

                        font.pixelSize: 13
                        font.weight: Font.DemiBold

                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true

                        text:
                            root.media
                            && root.media.hasPlayer
                                ? root.media.artist
                                : ""

                        color: root.inkSoft

                        font.family:
                            root.theme
                                ? root.theme.uiFont
                                : "sans-serif"

                        font.pixelSize: 10

                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 2

                        radius: 2

                        color: Qt.rgba(
                            root.ink.r,
                            root.ink.g,
                            root.ink.b,
                            0.12
                        )

                        Rectangle {
                            width:
                                parent.width
                                * (
                                    root.media
                                        ? root.media.progress
                                        : 0
                                )

                            height: parent.height

                            radius: parent.radius

                            color: root.accent

                            Behavior on width {
                                NumberAnimation {
                                    duration: 180
                                    easing.type:
                                        Easing.OutCubic
                                }
                            }
                        }
                    }

                    Item {
                        Layout.preferredHeight: 2
                    }

                    RowLayout {
                        Layout.alignment:
                            Qt.AlignHCenter

                        Layout.topMargin: 4

                        spacing: 7

                        TransportButton {
                            iconName: "skip-previous"

                            enabled:
                                root.media
                                && root.media.canPrevious

                            onTriggered:
                                root.media.previous()
                        }

                        TransportButton {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44

                            primary: true

                            iconName:
                                root.media
                                && root.media.playing
                                    ? "pause"
                                    : "play"

                            enabled:
                                root.media
                                && root.media.canToggle

                            onTriggered:
                                root.media.togglePlaying()
                        }

                        TransportButton {
                            iconName: "skip-next"

                            enabled:
                                root.media
                                && root.media.canNext

                            onTriggered:
                                root.media.next()
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true

                    color: Qt.rgba(
                        root.ink.r,
                        root.ink.g,
                        root.ink.b,
                        0.10
                    )
                }

                // ───────────────────────
                // UPCOMING QUEUE
                // ───────────────────────

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true

                            text: "Próximas músicas"

                            color: root.ink

                            font.family:
                                root.theme
                                    ? root.theme.uiFont
                                    : "sans-serif"

                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text:
                                root.media
                                    ? String(
                                        root.media.spotifyQueueCount
                                    )
                                    : "0"

                            color: root.inkSoft

                            font.family:
                                root.theme
                                    ? root.theme.monoFont
                                    : "monospace"

                            font.pixelSize: 9
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1

                        color: Qt.rgba(
                            root.ink.r,
                            root.ink.g,
                            root.ink.b,
                            0.09
                        )
                    }

                    ListView {
                        id: queueView

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        clip: true

                        boundsBehavior:
                            Flickable.StopAtBounds

                        flickDeceleration: 2400

                        cacheBuffer: 220

                        model:
                            root.media
                                ? root.media.spotifyQueue
                                : []

                        spacing: 1

                        delegate: Item {
                            id: queueEntry

                            required property int index
                            required property var modelData

                            width: queueView.width
                            height: 48

                            readonly property var track:
                                modelData || ({})

                            Rectangle {
                                anchors.fill: parent

                                radius: 8

                                color:
                                    entryHover.hovered
                                        ? Qt.rgba(
                                            root.ink.r,
                                            root.ink.g,
                                            root.ink.b,
                                            0.055
                                        )
                                        : "transparent"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 110
                                    }
                                }
                            }

                            Text {
                                id: queueNumber

                                anchors {
                                    left: parent.left
                                    leftMargin: 3
                                    verticalCenter:
                                        parent.verticalCenter
                                }

                                width: 22

                                text:
                                    root.queueNumber(
                                        queueEntry.index
                                    )

                                color: root.inkSoft
                                opacity: 0.64

                                font.family:
                                    root.theme
                                        ? root.theme.monoFont
                                        : "monospace"

                                font.pixelSize: 9
                            }

                            Rectangle {
                                id: queueArtFrame

                                anchors {
                                    left: queueNumber.right
                                    leftMargin: 4
                                    verticalCenter: parent.verticalCenter
                                }

                                width: 30
                                height: 30
                                radius: 8

                                color: root.card
                                clip: true

                                Image {
                                    anchors.fill: parent

                                    source: String(queueEntry.track.art || "")
                                    asynchronous: true
                                    smooth: true
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize.width: 96
                                    sourceSize.height: 96

                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle {
                                            width: queueArtFrame.width
                                            height: queueArtFrame.height
                                            radius: queueArtFrame.radius
                                        }
                                    }
                                }

                                VeloraMaterialIcon {
                                    anchors.centerIn: parent
                                    width: 12
                                    height: 12
                                    visible: !queueEntry.track.art
                                    iconName: "music"
                                    iconColor: root.ink
                                    opacity: 0.45
                                }
                            }

                            Column {
                                anchors {
                                    left: queueArtFrame.right

                                    leftMargin: 8

                                    right:
                                        parent.right

                                    rightMargin: 9

                                    verticalCenter:
                                        parent.verticalCenter
                                }

                                spacing: 1

                                Text {
                                    width: parent.width

                                    text:
                                        String(
                                            queueEntry
                                                .track
                                                .title
                                            || ""
                                        )

                                    color: root.ink

                                    font.family:
                                        root.theme
                                            ? root.theme.uiFont
                                            : "sans-serif"

                                    font.pixelSize: 10
                                    font.weight:
                                        Font.Medium

                                    maximumLineCount: 1
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width

                                    text:
                                        String(
                                            queueEntry
                                                .track
                                                .artist
                                            || ""
                                        )

                                    color: root.inkSoft

                                    opacity: 0.70

                                    font.family:
                                        root.theme
                                            ? root.theme.uiFont
                                            : "sans-serif"

                                    font.pixelSize: 8

                                    maximumLineCount: 1
                                    elide: Text.ElideRight
                                }
                            }

                            HoverHandler {
                                id: entryHover
                                blocking: false
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded

                            width: 4

                            contentItem: Rectangle {
                                implicitWidth: 3

                                radius: 2

                                color: root.inkSoft

                                opacity:
                                    parent.active
                                        ? 0.55
                                        : 0.20

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 140
                                    }
                                }
                            }

                            background: Item {}
                        }
                    }

                    Text {
                        Layout.fillWidth: true

                        visible:
                            !root.media
                            || !root.media.spotifyQueueAvailable

                        text: "Fila indisponível"

                        color: root.inkSoft

                        opacity: 0.56

                        font.family:
                            root.theme
                                ? root.theme.uiFont
                                : "sans-serif"

                        font.pixelSize: 9

                        horizontalAlignment:
                            Text.AlignHCenter
                    }
                }
            }
        }
    }

    component TransportButton: Rectangle {
        id: button

        property string iconName: ""
        property bool primary: false

        signal triggered()

        Layout.preferredWidth:
            primary ? 44 : 34

        Layout.preferredHeight:
            primary ? 44 : 34

        radius:
            primary ? 14 : 11

        color: Qt.rgba(
            root.ink.r,
            root.ink.g,
            root.ink.b,
            buttonMouse.pressed
                ? 0.15
                : buttonMouse.containsMouse
                    ? 0.09
                    : primary
                        ? 0.055
                        : 0.018
        )

        border.width: 1

        border.color: Qt.rgba(
            root.ink.r,
            root.ink.g,
            root.ink.b,
            primary ? 0.18 : 0.10
        )

        opacity:
            enabled ? 1 : 0.30

        scale:
            buttonMouse.pressed
                ? 0.94
                : 1

        Behavior on color {
            ColorAnimation {
                duration: 110
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 110
                easing.type: Easing.OutCubic
            }
        }

        VeloraMaterialIcon {
            anchors.centerIn: parent

            width:
                button.primary
                    ? 22
                    : 18

            height: width

            iconName:
                button.iconName

            iconColor:
                root.ink

            filled:
                button.primary
        }

        MouseArea {
            id: buttonMouse

            anchors.fill: parent

            enabled: button.enabled
            hoverEnabled: true

            cursorShape:
                Qt.PointingHandCursor

            onClicked:
                button.triggered()
        }
    }
}
