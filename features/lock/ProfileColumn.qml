import QtQuick

Item {
    id: root

    required property var config
    required property var theme
    required property var motion
    required property var media

    width: 324
    height: 570

    GlassPanel {
        id: profileHeader
        x: 174
        y: 0
        width: 169
        height: 58
        radius: 29
        surfaceColor: root.theme.moduleSurface
        borderColor: root.theme.moduleBorder
        shadowColor: Qt.rgba(root.theme.shadow.r, root.theme.shadow.g,
                             root.theme.shadow.b, 0.12)
        transformOrigin: Item.Center
        scale: profileHover.hovered ? 1.022 : 1

        transform: Translate {
            y: profileHover.hovered ? -2 : 0
            Behavior on y {
                NumberAnimation { duration: root.motion.hover; easing.type: Easing.OutCubic }
            }
        }

        Behavior on scale {
            NumberAnimation { duration: root.motion.hover; easing.type: Easing.OutCubic }
        }

        HoverHandler { id: profileHover }

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 21
            anchors.right: profileAvatar.left
            anchors.rightMargin: 8
            text: root.config.profileName
            color: root.theme.ink
            font.family: root.theme.bodyFont
            font.pixelSize: 18
            font.weight: Font.Bold
            elide: Text.ElideRight
        }

        Item {
            id: profileAvatar
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 3
            width: 52
            height: 52
            scale: avatarMouse.pressed ? 0.92
                : (avatarMouse.containsMouse ? 1.045 : 1)

            Behavior on scale {
                NumberAnimation {
                    duration: root.motion.hover
                    easing.type: Easing.OutCubic
                }
            }

            RoundedImage {
                anchors.fill: parent
                source: root.config.avatarPath
                radius: 26
                asynchronous: false
                verticalAlignment: Image.AlignTop
            }

            Rectangle {
                anchors.fill: parent
                radius: 26
                color: "transparent"
                border.width: 2
                border.color: Qt.rgba(root.theme.ink.r,
                                      root.theme.ink.g,
                                      root.theme.ink.b,
                                      avatarMouse.containsMouse ? 0.90 : 0.62)

                Behavior on border.color {
                    ColorAnimation { duration: root.motion.hover }
                }
            }

            MouseArea {
                id: avatarMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
            }
        }
    }

    Text {
        anchors.top: parent.top
        x: 168 + root.config.greetingOffsetX
        width: 145
        anchors.topMargin: 118 + root.config.greetingOffsetY
        text: root.config.greeting
        horizontalAlignment: Text.AlignHCenter
        color: root.theme.heroInk
        font.family: root.theme.bodyFont
        font.pixelSize: root.config.greetingFontSize
        font.weight: Font.Bold
    }

    GalleryPanel {
        x: 11
        y: 172
        config: root.config
        theme: root.theme
        motion: root.motion
    }

    MediaCard {
        x: 15
        y: 481
        media: root.media
        theme: root.theme
        motion: root.motion
        fallbackArt: root.config.avatarPath
    }
}
