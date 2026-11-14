import QtQuick
import QtQuick.Window
import QtQuick.Effects
import "../../components" as Components

FocusScope {
    id: root
    property bool presented: false
    property bool reducedMotion: false
    property url wallpaperSource: ""
    property string timeText: ""
    property string dateText: ""
    property string dayText: ""
    property string title: "Nenhuma mídia"
    property string artist: ""
    property url artworkSource: ""
    property bool mediaAvailable: false
    property bool playing: false
    property real mediaProgress: 0
    property real batteryProgress: 0
    property bool batteryAvailable: false
    // A reviewed host must supply the backend. The component stores no password.
    property bool authenticationAvailable: false
    property bool busy: false
    property string authenticationError: ""
    property string notice: ""
    readonly property bool compact: width < 1050 || width / Math.max(1, height) < 1.25
    readonly property real designWidth: compact ? 600 : 1586
    readonly property real designHeight: compact ? 840 : 992
    readonly property real designScale: Math.min(width / designWidth, height / designHeight)
    readonly property real reveal: entrance
    property real entrance: 0
    property bool ready: false
    readonly property bool interactive: presented && entrance > .98
    readonly property bool motionRunning: entranceAnimation.running || shake.running
    readonly property color ink: "#ffeadb"
    readonly property color blush: "#e7b5a6"
    readonly property string bodyFont: regularFont.name
    signal closeRequested
    signal exitFinished
    signal authenticationRequested(string secret)
    signal mediaRequested(string action)
    signal powerRequested
    signal settingsRequested
    FontLoader { id: regularFont; source: "../../assets/fonts/Poppins-Regular.ttf" }
    opacity: entrance; visible: entrance > .001; focus: presented; clip: true
    NumberAnimation {
        id: entranceAnimation; target: root; property: "entrance"
        easing.type: Easing.InOutCubic
    }
    function animatePresentation() {
        entranceAnimation.stop()
        const target = presented ? 1 : 0
        if (reducedMotion) { entrance = target; return }
        entranceAnimation.from = entrance
        entranceAnimation.to = target
        entranceAnimation.duration = Math.max(1, Math.round((presented ? 620 : 280) * Math.abs(target - entrance)))
        entranceAnimation.start()
    }
    onEntranceChanged: if (!presented && entrance < .001) exitFinished()
    Component.onCompleted: { ready = true; Qt.callLater(animatePresentation) }
    onPresentedChanged: {
        if (ready) animatePresentation()
        password.clear(); notice = ""; authenticationError = ""
        if (presented) Qt.callLater(claimFocus)
    }
    onReducedMotionChanged: if (reducedMotion) {
        entranceAnimation.stop(); entrance = presented ? 1 : 0
        shake.stop(); passwordRow.shakeX = 0
    }
    onAuthenticationErrorChanged: {
        password.clear()
        if (authenticationError && !reducedMotion && presented) shake.restart()
    }
    function claimFocus() { if (presented) password.forceActiveFocus(Qt.OtherFocusReason) }
    function clearSecret() { password.clear() }
    function submit() {
        if (!interactive || busy) return
        if (!authenticationAvailable) { notice = "Autenticação pendente de revisão."; return }
        if (!password.text.length) return
        const secret = password.text
        password.clear()
        authenticationRequested(secret)
    }
    Keys.onEscapePressed: { clearSecret(); closeRequested() }
    Rectangle { anchors.fill: parent; color: "#3a282c" }
    Image {
        anchors.fill: parent; source: root.wallpaperSource
        asynchronous: true; fillMode: Image.PreserveAspectCrop
        sourceSize.width: Math.ceil(root.width * Math.max(1, Screen.devicePixelRatio))
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#143a242b" }
            GradientStop { position: 1; color: "#80201b20" }
        }
    }
    // A single curved veil, with a soft halo following its edge.
    Canvas {
        id: veil; anchors.fill: parent
        property real morph: root.entrance
        property bool compactLayout: root.compact
        onMorphChanged: requestPaint()
        onCompactLayoutChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const c = getContext("2d"); c.reset()
            const w = width, h = height, shift = (1 - morph) * w * .18
            function edge() {
                c.beginPath()
                if (compactLayout) {
                    c.moveTo(w + shift, h * .18)
                    c.bezierCurveTo(w * .15 + shift, h * .12, w * 1.05 + shift, h * .65, -shift, h * .85)
                } else {
                    c.moveTo(w * .63 + shift, 0)
                    c.bezierCurveTo(w * .29 + shift, h * .015, w * .365 + shift, h * .51, w * .245 + shift, h * .72)
                    c.bezierCurveTo(w * .16 + shift, h * .89, w * .05 + shift, h * .88, -shift, h * .945)
                }
            }
            edge(); c.lineTo(0, h); c.lineTo(w, h); c.lineTo(w, 0); c.closePath()
            const g = c.createLinearGradient(w * .3, 0, w, h)
            g.addColorStop(0, "rgba(59,40,43,.89)"); g.addColorStop(1, "rgba(40,29,32,.96)")
            c.fillStyle = g; c.fill()
            for (let i = 6; i > 0; --i) {
                edge(); c.lineWidth = i * 12; c.strokeStyle = "rgba(231,165,155,.009)"; c.stroke()
            }
            edge(); c.lineWidth = 1; c.strokeStyle = "rgba(233,176,164,.44)"; c.stroke()
        }
    }
    Item {
        id: design; width: root.designWidth; height: root.designHeight
        anchors.centerIn: parent; scale: root.designScale; transformOrigin: Item.Center
        Rectangle {
            x: 38; y: 56; width: 70; height: 44; radius: 22; color: "#408f7771"
            Text { anchors.centerIn: parent; text: root.dayText; color: root.ink; font.family: root.bodyFont; font.pixelSize: 24 }
        }
        Item {
            objectName: "lockClock"
            x: root.compact ? 48 : 584; y: (root.compact ? 170 : 351) + (1 - root.entrance) * 28
            width: root.compact ? 504 : 350; height: 250
            Text {
                width: parent.width; text: root.timeText; color: root.blush
                font.family: root.bodyFont; font.pixelSize: root.compact ? 104 : 112
                font.weight: Font.Light; font.letterSpacing: -3
            }
            Text {
                y: 142; width: parent.width; text: root.dateText; color: root.blush
                font.family: root.bodyFont; font.pixelSize: root.compact ? 23 : 25
                font.letterSpacing: .7; elide: Text.ElideRight
            }
            Rectangle {
                x: 10; y: 209; width: 164; height: 8; radius: 4; color: "#75605a"; visible: root.batteryAvailable
                Rectangle { width: parent.width * Math.max(0, Math.min(1, root.batteryProgress)); height: parent.height; radius: 4; color: "#f49da9" }
            }
        }
        Rectangle { x: 934; y: 350; width: 1; height: 249 * root.entrance; visible: !root.compact; color: "#88635d" }
        Item {
            objectName: "lockMedia"
            x: root.compact ? 48 : 982; y: (root.compact ? 407 : 350) + (1 - root.entrance) * 40
            width: root.compact ? 504 : 444; height: 132
            Rectangle {
                width: 104; height: 104; radius: 20; color: "#68504e"; clip: true
                Image { id: art; anchors.fill: parent; source: root.artworkSource; fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: false }
                MultiEffect { anchors.fill: parent; source: art; maskEnabled: true; maskSource: artMask; visible: art.status === Image.Ready && GraphicsInfo.api !== GraphicsInfo.Software }
                Rectangle { id: artMask; anchors.fill: parent; color: "white"; radius: 20; layer.enabled: true; visible: false }
                Image { anchors.fill: parent; source: root.artworkSource; fillMode: Image.PreserveAspectCrop; visible: GraphicsInfo.api === GraphicsInfo.Software }
                Components.VeloraMaterialIcon { anchors.centerIn: parent; width: 36; height: 36; iconName: "music"; iconColor: root.blush; visible: art.status !== Image.Ready }
            }
            Text { x: 126; y: 8; width: parent.width - 126; text: root.title; color: root.ink; font.family: root.bodyFont; font.pixelSize: 23; elide: Text.ElideRight }
            Text { x: 126; y: 45; width: root.compact ? 180 : 165; text: root.artist; color: root.blush; font.family: root.bodyFont; font.pixelSize: 17; elide: Text.ElideRight }
            Row {
                x: parent.width - 156; y: 36; spacing: 5
                LockAction { objectName: "lockPrevious"; width: 45; height: 55; filled: false; iconName: "skip-previous"; label: "Faixa anterior"; enabled: root.interactive && root.mediaAvailable; reducedMotion: root.reducedMotion; onTriggered: root.mediaRequested("previous") }
                LockAction { objectName: "lockPlay"; width: 56; height: 56; iconName: root.playing ? "pause" : "play"; label: root.playing ? "Pausar" : "Reproduzir"; enabled: root.interactive && root.mediaAvailable; reducedMotion: root.reducedMotion; onTriggered: root.mediaRequested("toggle") }
                LockAction { objectName: "lockNext"; width: 45; height: 55; filled: false; iconName: "skip-next"; label: "Próxima faixa"; enabled: root.interactive && root.mediaAvailable; reducedMotion: root.reducedMotion; onTriggered: root.mediaRequested("next") }
            }
            Rectangle {
                x: 126; y: 96; width: parent.width - 126; height: 7; radius: 4; color: "#735b52"
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.mediaProgress)); height: parent.height; radius: 4; color: "#ffc08c"
                    Behavior on width { enabled: !root.reducedMotion && root.presented; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }
            }
        }
        Rectangle {
            id: passwordRow; objectName: "lockPasswordMorph"
            property real shakeX: 0
            property real emphasis: password.activeFocus || passwordHover.hovered ? 1 : 0
            x: (root.compact ? 48 : 982) + shakeX
            y: (root.compact ? 590 : 518) + (1 - root.entrance) * 50
            width: root.compact ? 504 : 444; height: root.authenticationError ? 92 : 68
            radius: 34 - 10 * emphasis
            color: Qt.rgba(.72, .57, .53, .20 + .10 * emphasis)
            border.width: 1; border.color: root.authenticationError ? "#f69ba8" : Qt.rgba(.88, .72, .66, .12 + emphasis * .15)
            Behavior on emphasis { enabled: !root.reducedMotion; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on height { enabled: !root.reducedMotion; NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            HoverHandler { id: passwordHover }
            Components.VeloraMaterialIcon { x: 24; y: 19; width: 30; height: 30; iconName: "lock"; iconColor: root.ink }
            TextInput {
                id: password; objectName: "lockPassword"
                x: 78; y: 10; width: parent.width - 146; height: 48
                color: root.ink; font.family: root.bodyFont; font.pixelSize: 22
                echoMode: TextInput.Password; passwordCharacter: "●"; maximumLength: 256
                selectByMouse: false; persistentSelection: false
                readOnly: !root.interactive || !root.authenticationAvailable || root.busy
                activeFocusOnTab: true
                inputMethodHints: Qt.ImhSensitiveData | Qt.ImhHiddenText | Qt.ImhNoPredictiveText
                verticalAlignment: TextInput.AlignVCenter; Accessible.name: "Senha"
                onAccepted: root.submit()
                onTextEdited: { root.authenticationError = ""; root.notice = "" }
                Text {
                    anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                    text: root.busy ? "Verificando…" : "Digite sua senha"
                    color: root.ink; opacity: .9; visible: !password.text.length; font: password.font
                }
            }
            LockAction {
                objectName: "lockSubmit"; x: parent.width - 62; y: 7; width: 54; height: 54
                iconName: "arrow_forward"; label: "Entrar"; filled: false
                enabled: root.interactive && !root.busy; reducedMotion: root.reducedMotion; onTriggered: root.submit()
            }
            Text {
                x: 78; y: 62; width: parent.width - 96; text: root.authenticationError
                visible: root.authenticationError.length > 0; color: "#ffb3be"; elide: Text.ElideRight
                font.family: root.bodyFont; font.pixelSize: 13
            }
        }
        SequentialAnimation {
            id: shake
            NumberAnimation { target: passwordRow; property: "shakeX"; to: -7; duration: 55 }
            NumberAnimation { target: passwordRow; property: "shakeX"; to: 5; duration: 75 }
            NumberAnimation { target: passwordRow; property: "shakeX"; to: 0; duration: 100; easing.type: Easing.OutCubic }
        }
        LockAction {
            objectName: "lockPower"; x: root.compact ? 392 : 1492; y: root.compact ? 724 : 411
            iconName: "power"; label: "Opções de energia"; reducedMotion: root.reducedMotion; enabled: root.interactive
            onTriggered: { root.notice = "Ações de energia pendentes de revisão."; root.powerRequested() }
        }
        LockAction {
            objectName: "lockSettings"; x: root.compact ? 480 : 1492; y: root.compact ? 724 : 496
            iconName: "settings"; label: "Configurações da tela"; reducedMotion: root.reducedMotion; enabled: root.interactive
            onTriggered: { root.notice = "Configurações da lockscreen pendentes de revisão."; root.settingsRequested() }
        }
        Text {
            objectName: "lockNotice"; x: root.compact ? 48 : 982; y: passwordRow.y + passwordRow.height + 16
            width: passwordRow.width; text: root.notice; color: root.blush
            font.family: root.bodyFont; font.pixelSize: 14; wrapMode: Text.WordWrap
        }
    }
}
