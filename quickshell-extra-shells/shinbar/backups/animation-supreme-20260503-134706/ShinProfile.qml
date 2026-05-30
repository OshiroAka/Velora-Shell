import Quickshell
import QtQuick
import Qt5Compat.GraphicalEffects
import "."

Item {
    id: root

    implicitWidth: 42
    implicitHeight: ShinConfig.barH

    property bool opened: ShinPopup.active === "profile"
    property bool popupVisible: false
    property bool hoverRoot: false
    property bool hoverPopup: false
    property real reveal: opened ? 1.0 : 0.0
    property real pulse: 0.0

    readonly property int popupW: 720
    readonly property int popupH: 190

    function profileSource() {
        return ShinData.profileImage && ShinData.profileImage.length > 0 ? "file://" + ShinData.profileImage : ""
    }

    function displayName() {
        var name = ShinData.profileName || "shira"
        return name === "User" ? "shira" : name
    }

    function canvasColor(c, alpha) {
        var a = alpha === undefined ? 1 : alpha
        return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + a + ")"
    }

    function openPopup() {
        closeTimer.stop()
        hideTimer.stop()
        popupVisible = true
        ShinPopup.open("profile")
    }

    function closePopup() {
        ShinPopup.close("profile")
    }

    function scheduleClose() {
        closeTimer.restart()
    }

    onOpenedChanged: {
        if (opened) {
            hideTimer.stop()
            popupVisible = true
            pulseAnim.restart()
        } else {
            hideTimer.restart()
        }
    }

    Behavior on reveal {
        NumberAnimation { duration: ShinData.popupAnim(300); easing.type: Easing.OutBack }
    }

    SequentialAnimation {
        id: pulseAnim
        NumberAnimation { target: root; property: "pulse"; from: 0.0; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "pulse"; from: 1.0; to: 0.0; duration: 420; easing.type: Easing.OutCubic }
    }

    Timer {
        id: closeTimer
        interval: 240
        repeat: false
        onTriggered: {
            if (!root.hoverRoot && !root.hoverPopup)
                root.closePopup()
        }
    }

    Timer {
        id: hideTimer
        interval: 290
        repeat: false
        onTriggered: {
            if (!root.opened)
                root.popupVisible = false
        }
    }

    ShinPill {
        anchors.fill: parent
        anchors.topMargin: (parent.height - ShinConfig.pillH) / 2
        anchors.bottomMargin: (parent.height - ShinConfig.pillH) / 2
        active: root.opened
        hovered: root.hoverRoot
        clickable: false
    }

    Canvas {
        id: profilePillIcon
        anchors.centerIn: parent
        width: 18
        height: 18
        scale: root.opened ? 1.10 : root.hoverRoot ? 1.06 : 1.0

        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        onPaint: {
            var ctx = getContext("2d")
            var w = width
            var h = height
            ctx.clearRect(0, 0, w, h)
            ctx.lineWidth = 1.8
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.strokeStyle = root.opened ? root.canvasColor(ShinColors.accent, 1) : root.canvasColor(ShinColors.fg, 0.88)
            ctx.fillStyle = root.canvasColor(ShinColors.accent, root.opened ? 0.18 : 0.08)

            ctx.beginPath()
            ctx.arc(w * 0.50, h * 0.34, w * 0.20, 0, Math.PI * 2)
            ctx.fill()
            ctx.stroke()

            ctx.beginPath()
            ctx.moveTo(w * 0.22, h * 0.82)
            ctx.quadraticCurveTo(w * 0.50, h * 0.55, w * 0.78, h * 0.82)
            ctx.stroke()
        }

        Connections {
            target: ShinColors
            function onAccentChanged() { profilePillIcon.requestPaint() }
            function onFgChanged() { profilePillIcon.requestPaint() }
            function onWalSignatureChanged() { profilePillIcon.requestPaint() }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            root.hoverRoot = true
            root.openPopup()
        }
        onExited: {
            root.hoverRoot = false
            root.scheduleClose()
        }
        onClicked: ShinPopup.toggle("profile")
    }

    PopupWindow {
        id: profilePopup
        visible: root.popupVisible
        color: "transparent"
        implicitWidth: root.popupW
        implicitHeight: root.popupH

        anchor.item: root
        anchor.rect.x: Math.round(root.implicitWidth / 2 - profilePopup.implicitWidth / 2)
        anchor.rect.y: root.implicitHeight + 26
        anchor.rect.width: 1
        anchor.rect.height: 1

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            z: 20
            onEntered: {
                root.hoverPopup = true
                root.openPopup()
            }
            onExited: {
                root.hoverPopup = false
                root.scheduleClose()
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: root.popupW * (0.94 + root.reveal * 0.06)
            height: root.popupH * (0.94 + root.reveal * 0.06)
            radius: 24
            antialiasing: true
            clip: true
            opacity: root.reveal
            color: Qt.rgba(ShinColors.bg.r, ShinColors.bg.g, ShinColors.bg.b, Math.max(0.62, ShinConfig.popupOpacity))
            border.width: 2
            border.color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.14 + root.reveal * 0.10)
            transform: Translate {
                x: 0
                y: -18 * (1.0 - root.reveal)
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 18 + root.pulse * 28
                height: parent.height + 18 + root.pulse * 28
                radius: parent.radius + 12
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.28 * root.pulse)
                z: -1
            }

            Rectangle {
                width: parent.width
                height: parent.height * 0.58
                anchors.bottom: parent.bottom
                color: Qt.rgba(ShinColors.surface.r, ShinColors.surface.g, ShinColors.surface.b, 0.16)
            }

            Row {
                id: profileContent
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                Item {
                    width: 120
                    height: parent.height

                    Rectangle {
                        id: avatarFrame
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        width: 112
                        height: 112
                        radius: 56
                        color: Qt.rgba(ShinColors.surface.r, ShinColors.surface.g, ShinColors.surface.b, 0.46)
                        border.width: 1
                        border.color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.18)

                        Image {
                            id: profileAvatarImage
                            anchors.fill: parent
                            anchors.margins: 6
                            visible: false
                            source: root.profileSource()
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                        }

                        Rectangle {
                            id: profileAvatarMask
                            anchors.fill: profileAvatarImage
                            radius: width / 2
                            visible: false
                        }

                        OpacityMask {
                            anchors.fill: profileAvatarImage
                            source: profileAvatarImage
                            maskSource: profileAvatarMask
                            visible: root.profileSource().length > 0
                        }

                        Canvas {
                            anchors.fill: parent
                            anchors.margins: 14
                            visible: root.profileSource().length === 0
                            onPaint: {
                                var ctx = getContext("2d")
                                var w = width
                                var h = height
                                ctx.clearRect(0, 0, w, h)
                                ctx.fillStyle = Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.18)
                                ctx.beginPath()
                                ctx.arc(w * 0.5, h * 0.36, w * 0.18, 0, Math.PI * 2)
                                ctx.fill()
                                ctx.beginPath()
                                ctx.moveTo(w * 0.20, h * 0.84)
                                ctx.quadraticCurveTo(w * 0.50, h * 0.54, w * 0.80, h * 0.84)
                                ctx.closePath()
                                ctx.fill()
                            }
                        }

                        Rectangle {
                            width: 30
                            height: 30
                            radius: 15
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.rightMargin: 7
                            anchors.bottomMargin: 7
                            color: Qt.rgba(ShinColors.bg.r, ShinColors.bg.g, ShinColors.bg.b, 0.82)
                            border.width: 1
                            border.color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.14)

                            Rectangle {
                                anchors.centerIn: parent
                                width: 18
                                height: 18
                                radius: 9
                                color: ShinColors.accent
                                opacity: 0.86
                            }
                        }
                    }
                }

                Column {
                    width: 260
                    height: parent.height
                    spacing: 8

                    Item {
                        width: parent.width
                        height: 110

                        Text {
                            x: 0
                            y: 18
                            text: root.displayName()
                            color: ShinColors.fg
                            font.pixelSize: 30
                            font.bold: true
                            font.family: ShinConfig.fontFamily
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            x: 0
                            y: 66
                            text: ShinData.profileBio.length > 0 ? ShinData.profileBio : "Foco, disciplina e constancia."
                            color: ShinColors.muted
                            font.pixelSize: 13
                            font.family: ShinConfig.fontFamily
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Row {
                            x: 2
                            y: 96
                            spacing: 10

                            Rectangle {
                                width: 10
                                height: 10
                                radius: 6
                                color: ShinColors.accent
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "ONLINE"
                                color: ShinColors.accent
                                font.pixelSize: 13
                                font.family: ShinConfig.fontFamily
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                Rectangle {
                    width: 1
                    height: 110
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.12)
                }

                Column {
                    width: parent.width - 120 - 260 - 1 - profileContent.spacing * 3
                    height: 116
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    ProfileInfoCard {
                        width: parent.width
                        title: "TikTok"
                        value: ShinData.profileTikTok.length > 0 ? ShinData.profileTikTok : "@____________"
                        mode: "tiktok"
                    }

                    ProfileInfoCard {
                        width: parent.width
                        title: "Sistema"
                        value: ShinData.profileSystem.length > 0 ? ShinData.profileSystem : "CachyOS"
                        mode: "system"
                    }
                }
            }
        }
    }

    component ProfileInfoCard: Rectangle {
        id: infoCard
        property string title: ""
        property string value: ""
        property string mode: "system"

        height: 54
        radius: 13
        color: Qt.rgba(ShinColors.surface.r, ShinColors.surface.g, ShinColors.surface.b, 0.44)
        border.width: 1
        border.color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.12)

        Row {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Canvas {
                id: infoIcon
                width: 24
                height: 24
                anchors.verticalCenter: parent.verticalCenter
                onPaint: {
                    var ctx = getContext("2d")
                    var w = width
                    var h = height
                    ctx.clearRect(0, 0, w, h)
                    ctx.strokeStyle = ShinColors.fg
                    ctx.fillStyle = Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.18)
                    ctx.lineWidth = 2.2
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"

                    if (infoCard.mode === "tiktok") {
                        ctx.beginPath()
                        ctx.moveTo(w * 0.58, h * 0.18)
                        ctx.lineTo(w * 0.58, h * 0.66)
                        ctx.bezierCurveTo(w * 0.58, h * 0.86, w * 0.24, h * 0.86, w * 0.24, h * 0.66)
                        ctx.bezierCurveTo(w * 0.24, h * 0.48, w * 0.48, h * 0.48, w * 0.52, h * 0.58)
                        ctx.moveTo(w * 0.58, h * 0.22)
                        ctx.bezierCurveTo(w * 0.66, h * 0.36, w * 0.78, h * 0.42, w * 0.88, h * 0.42)
                        ctx.stroke()
                    } else {
                        ctx.beginPath()
                        ctx.moveTo(w * 0.50, h * 0.14)
                        ctx.lineTo(w * 0.82, h * 0.32)
                        ctx.lineTo(w * 0.82, h * 0.68)
                        ctx.lineTo(w * 0.50, h * 0.86)
                        ctx.lineTo(w * 0.18, h * 0.68)
                        ctx.lineTo(w * 0.18, h * 0.32)
                        ctx.closePath()
                        ctx.fill()
                        ctx.stroke()
                        ctx.beginPath()
                        ctx.moveTo(w * 0.18, h * 0.32)
                        ctx.lineTo(w * 0.50, h * 0.50)
                        ctx.lineTo(w * 0.82, h * 0.32)
                        ctx.moveTo(w * 0.50, h * 0.50)
                        ctx.lineTo(w * 0.50, h * 0.86)
                        ctx.stroke()
                    }
                }

                Connections {
                    target: ShinColors
                    function onAccentChanged() { infoIcon.requestPaint() }
                    function onFgChanged() { infoIcon.requestPaint() }
                    function onWalSignatureChanged() { infoIcon.requestPaint() }
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 34
                spacing: 3

                Text {
                    text: infoCard.title
                    color: ShinColors.muted
                    font.pixelSize: 10
                    font.family: ShinConfig.fontFamily
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: infoCard.value
                    color: ShinColors.fg
                    font.pixelSize: 12
                    font.bold: true
                    font.family: ShinConfig.fontFamily
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
        }
    }
}
