import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

ShellRoot {
    id: root

    readonly property bool testMode: Quickshell.env("VELORA_LOCK_TEST") === "1"
    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string userId: Quickshell.env("USER") || "shira"
    readonly property string userName: userId.length > 0 ? userId.charAt(0).toUpperCase() + userId.slice(1) : "Shira"
    readonly property color ink: Qt.rgba(0.86, 0.91, 0.92, 0.96)
    readonly property color inkSoft: Qt.rgba(0.60, 0.72, 0.72, 0.72)
    readonly property color outline: Qt.rgba(0.28, 0.43, 0.44, 0.72)
    readonly property color field: Qt.rgba(0.86, 0.96, 0.98, 0.22)
    readonly property color fieldLine: Qt.rgba(0.58, 0.76, 0.76, 0.82)
    property string timeText: "00:00"
    property string dateText: ""
    property string buffer: ""
    property string message: ""
    property bool messageError: false
    property bool unlocking: false
    property real flashOffset: 0

    function updateTime() {
        const now = new Date()
        timeText = Qt.formatDateTime(now, "HH:mm")
        dateText = Qt.formatDate(now, "dddd, d MMMM")
    }

    function clearMessageSoon() {
        messageReset.restart()
    }

    function submitPassword() {
        if (unlocking || passwd.active || buffer.length <= 0)
            return

        message = "Verificando..."
        messageError = false
        passwd.start()
    }

    function handleKey(event) {
        if (unlocking || passwd.active)
            return

        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            submitPassword()
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Escape) {
            buffer = ""
            message = ""
            event.accepted = true
            return
        }

        if (event.key === Qt.Key_Backspace) {
            if (event.modifiers & Qt.ControlModifier)
                buffer = ""
            else
                buffer = buffer.slice(0, -1)
            event.accepted = true
            return
        }

        if (event.text && event.text.length > 0 && !/[\x00-\x1f\x7f-\x9f]/.test(event.text)) {
            buffer += event.text
            message = ""
            event.accepted = true
        }
    }

    Component.onCompleted: updateTime()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updateTime()
    }

    Timer {
        id: messageReset

        interval: 3600
        repeat: false
        onTriggered: if (!passwd.active) root.message = ""
    }

    Timer {
        id: quitTimer

        interval: 260
        repeat: false
        onTriggered: Quickshell.execDetached(["kill", String(Quickshell.processId)])
    }

    SequentialAnimation {
        id: flashAnimation

        NumberAnimation { target: root; property: "flashOffset"; from: 0; to: -10; duration: 45; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "flashOffset"; to: 10; duration: 70; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "flashOffset"; to: -5; duration: 60; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "flashOffset"; to: 0; duration: 120; easing.type: Easing.OutCubic }
    }

    PamContext {
        id: passwd

        config: "passwd"
        configDirectory: Quickshell.shellDir + "/assets/pam.d"
        user: root.userId

        onResponseRequiredChanged: {
            if (!responseRequired)
                return

            respond(root.buffer)
            root.buffer = ""
        }

        onCompleted: function(result) {
            if (result === PamResult.Success) {
                root.unlocking = true
                root.message = ""
                sessionLock.unlock()
                quitTimer.restart()
                return
            }

            root.message = result === PamResult.MaxTries ? "Muitas tentativas. Aguarde um pouco." : "Senha incorreta"
            root.messageError = true
            flashAnimation.restart()
            root.clearMessageSoon()
        }

        onError: function(error) {
            root.message = "Erro de autenticação"
            root.messageError = true
            flashAnimation.restart()
            root.clearMessageSoon()
        }
    }

    Loader {
        asynchronous: true
        active: Quickshell.screens.length > 0
        onLoaded: active = false
        sourceComponent: ScreencopyView {
            captureSource: Quickshell.screens[0]
        }
    }

    WlSessionLock {
        id: sessionLock

        locked: !root.testMode

        WlSessionLockSurface {
            id: surface

            color: "transparent"

            ScreencopyView {
                id: background

                anchors.fill: parent
                captureSource: surface.screen
                opacity: root.unlocking ? 0 : 1

                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                layer.enabled: true
                layer.effect: MultiEffect {
                    autoPaddingEnabled: false
                    blurEnabled: true
                    blur: 1
                    blurMax: 56
                    blurMultiplier: 1
                    saturation: 0.82
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0.03, 0.15, 0.17, root.unlocking ? 0 : 0.22)
                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                anchors.fill: parent
                opacity: root.unlocking ? 0 : 1
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0.02, 0.12, 0.16, 0.48) }
                    GradientStop { position: 0.44; color: Qt.rgba(0.80, 0.96, 0.98, 0.10) }
                    GradientStop { position: 1.0; color: Qt.rgba(0.02, 0.10, 0.12, 0.50) }
                }
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }

            Item {
                id: stage

                readonly property real scaleUnit: Math.min(surface.width / 1170, surface.height / 730)
                readonly property int avatarSize: Math.round(Math.max(112, Math.min(154, surface.height * 0.19)))
                readonly property int fieldWidth: Math.round(Math.max(210, Math.min(310, surface.width * 0.19)))
                readonly property int fieldHeight: Math.round(Math.max(26, Math.min(34, surface.height * 0.045)))

                anchors.fill: parent
                focus: true
                opacity: root.unlocking ? 0 : 1
                scale: root.unlocking ? 0.96 : 1
                Keys.onPressed: function(event) { root.handleKey(event) }
                Component.onCompleted: forceActiveFocus()
                onActiveFocusChanged: if (!activeFocus) forceActiveFocus()

                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                Text {
                    id: clockText

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: Math.round(-78 * stage.scaleUnit)
                    text: root.timeText
                    color: Qt.rgba(root.outline.r, root.outline.g, root.outline.b, 0.08)
                    style: Text.Outline
                    styleColor: root.outline
                    font.family: "FantasqueSansM Nerd Font"
                    font.pixelSize: Math.round(Math.max(118, Math.min(190, surface.width * 0.16)))
                    font.weight: Font.Light
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }

                Item {
                    id: avatar

                    width: stage.avatarSize
                    height: width
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: Math.round(-28 * stage.scaleUnit)

                    Image {
                        id: avatarImage

                        anchors.fill: parent
                        source: Qt.resolvedUrl("assets/profile-avatar.png")
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        visible: false
                    }

                    Rectangle {
                        id: avatarMask

                        anchors.fill: avatarImage
                        radius: width / 2
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: avatarImage
                        source: avatarImage
                        maskSource: avatarMask
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        border.width: 3
                        border.color: Qt.rgba(0.08, 0.13, 0.15, 0.78)
                    }
                }

                ColumnLayout {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: avatar.bottom
                    anchors.topMargin: Math.round(24 * stage.scaleUnit)
                    width: stage.fieldWidth
                    spacing: Math.round(12 * stage.scaleUnit)
                    x: root.flashOffset

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: stage.fieldWidth
                        Layout.preferredHeight: stage.fieldHeight
                        radius: height / 2
                        color: root.field
                        border.width: 2
                        border.color: root.messageError ? Qt.rgba(0.95, 0.40, 0.42, 0.88) : root.fieldLine

                        Behavior on border.color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        Canvas {
                            id: lockIcon

                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.round(parent.height * 0.70)
                            height: width
                            onPaint: {
                                const ctx = getContext("2d")
                                const s = width
                                ctx.reset()
                                ctx.clearRect(0, 0, width, height)
                                ctx.strokeStyle = "rgba(83, 112, 115, 0.88)"
                                ctx.lineWidth = Math.max(1.4, s * 0.10)
                                ctx.lineCap = "round"
                                ctx.lineJoin = "round"
                                ctx.beginPath()
                                ctx.arc(s * 0.50, s * 0.38, s * 0.20, Math.PI, Math.PI * 2, false)
                                ctx.lineTo(s * 0.70, s * 0.54)
                                ctx.moveTo(s * 0.30, s * 0.54)
                                ctx.lineTo(s * 0.30, s * 0.38)
                                ctx.stroke()
                                const x = s * 0.22
                                const y = s * 0.48
                                const w = s * 0.56
                                const h = s * 0.34
                                const r = s * 0.08
                                ctx.beginPath()
                                ctx.moveTo(x + r, y)
                                ctx.lineTo(x + w - r, y)
                                ctx.quadraticCurveTo(x + w, y, x + w, y + r)
                                ctx.lineTo(x + w, y + h - r)
                                ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h)
                                ctx.lineTo(x + r, y + h)
                                ctx.quadraticCurveTo(x, y + h, x, y + h - r)
                                ctx.lineTo(x, y + r)
                                ctx.quadraticCurveTo(x, y, x + r, y)
                                ctx.closePath()
                                ctx.stroke()
                            }
                        }

                        Text {
                            anchors.left: lockIcon.right
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 6
                            anchors.rightMargin: 12
                            text: root.buffer.length > 0 ? "•".repeat(root.buffer.length) : (passwd.active ? "..." : "Senha")
                            color: root.buffer.length > 0 ? root.ink : root.inkSoft
                            font.family: "FantasqueSansM Nerd Font"
                            font.pixelSize: Math.round(parent.height * 0.48)
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            horizontalAlignment: root.buffer.length > 0 ? Text.AlignLeft : Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.IBeamCursor
                            onClicked: stage.forceActiveFocus()
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.userName
                        color: root.ink
                        font.family: "FantasqueSansM Nerd Font"
                        font.pixelSize: Math.round(Math.max(22, Math.min(31, surface.height * 0.038)))
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: stage.fieldWidth + 80
                        text: root.message
                        visible: text.length > 0
                        color: root.messageError ? Qt.rgba(1.0, 0.56, 0.58, 0.95) : root.inkSoft
                        font.family: "FantasqueSansM Nerd Font"
                        font.pixelSize: Math.round(Math.max(12, Math.min(15, surface.height * 0.019)))
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
