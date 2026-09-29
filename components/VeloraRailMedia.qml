pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import Velora.Visualizer 1.0

Item {
    id: root

    required property var media

    property var visualizer: null
    property color surfaceColor: "#272730"
    property color ink: "white"
    property color accent: "#b8a18d"
    property string fontFamily: "sans-serif"
    property real availableHeight: 176
    property bool selected: false

    readonly property bool hasPlayer:
        !!media && media.hasPlayer

    readonly property bool playing:
        hasPlayer && media.playing

    signal triggerHoverChanged(bool inside)
    signal activated()

    implicitWidth: 44
    implicitHeight: 100
    height: implicitHeight

    Rectangle {
        id: surface

        anchors.fill: parent

        radius: 11

        color: root.surfaceColor

        border.width: root.selected ? 1.4 : 1
        border.color: Qt.rgba(
            root.ink.r,
            root.ink.g,
            root.ink.b,
            root.selected ? 0.40 : 0.23
        )

        Behavior on border.color {
            ColorAnimation {
                duration: 140
            }
        }

        Rectangle {
            id: cover

            anchors {
                top: parent.top
                topMargin: 5
                horizontalCenter: parent.horizontalCenter
            }

            width: parent.width - 10
            height: width

            radius: 8

            color: Qt.rgba(
                root.ink.r,
                root.ink.g,
                root.ink.b,
                0.06
            )

            Image {
                id: artwork

                anchors.fill: parent

                source:
                    root.hasPlayer
                        ? root.media.artUrl
                        : ""

                sourceSize.width: 96
                sourceSize.height: 96

                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                smooth: true

                layer.enabled: true

                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: cover.width
                        height: cover.height
                        radius: cover.radius
                    }
                }
            }

            VeloraMaterialIcon {
                anchors.centerIn: parent

                width: 20
                height: 20

                visible:
                    artwork.status !== Image.Ready

                iconName: "music"
                iconColor: root.ink
                opacity: 0.55
            }
        }

        Text {
            anchors {
                top: cover.bottom
                topMargin: 5
                horizontalCenter: parent.horizontalCenter
            }

            width: parent.width - 6
            height: 12

            text:
                root.hasPlayer
                    ? root.media.title
                    : "Mídia"

            textFormat: Text.PlainText

            color: root.ink

            font.family: root.fontFamily
            font.pixelSize: 9
            font.weight: Font.Medium

            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Text {
            y: 57

            anchors.horizontalCenter:
                parent.horizontalCenter

            width: parent.width - 6

            visible: root.hasPlayer

            text:
                root.hasPlayer
                    ? root.media.artist
                    : ""

            color: root.ink
            opacity: 0.68

            font.family: root.fontFamily
            font.pixelSize: 8

            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Spectrum {
            anchors.horizontalCenter:
                parent.horizontalCenter

            y: 76

            width: 38
            height: 18

            analyzer: root.visualizer

            active:
                visible
                && root.visible
                && root.playing
                && !!root.visualizer
                && root.visualizer.running

            referenceHeight: height
            strength: 0.30

            opacity:
                root.selected ? 1 : 0.82

            accentStart: root.ink
            accentMiddle: root.ink
            accentEnd: root.ink

            outlineColor: "transparent"
        }

        HoverHandler {
            id: hover

            blocking: false

            onHoveredChanged:
                root.triggerHoverChanged(hovered)
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton

            onTapped:
                root.activated()
        }
    }
}
