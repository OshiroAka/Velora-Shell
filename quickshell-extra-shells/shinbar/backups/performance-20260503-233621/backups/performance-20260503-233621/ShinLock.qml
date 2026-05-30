import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import "."

Scope {
    id: root

    property bool authBusy: false
    property bool failed: false
    property int failureTick: 0
    property string pendingPassword: ""
    property string currentWallpaper: ""
    property string activeBackgroundPath: ""
    property string statusText: ""
    property string userName: Quickshell.env("USER") || "shira"
    property bool unlocking: false
    property int lockEnterNonce: 0

    function isImageFile(path) {
        var p = (path || "").toLowerCase()
        return p.endsWith(".jpg") || p.endsWith(".jpeg") || p.endsWith(".png")
            || p.endsWith(".webp") || p.endsWith(".avif") || p.endsWith(".bmp")
    }

    function backgroundPath() {
        if (ShinData.lockWallpaper.length > 0 && isImageFile(ShinData.lockWallpaper))
            return ShinData.lockWallpaper
        if (currentWallpaper.length > 0 && isImageFile(currentWallpaper))
            return currentWallpaper
        if (ShinData.weatherBg.length > 0 && isImageFile(ShinData.weatherBg))
            return ShinData.weatherBg
        if (ShinData.clockBg.length > 0 && isImageFile(ShinData.clockBg))
            return ShinData.clockBg
        return ""
    }

    function fileUrl(path) {
        var p = (path || "").trim()
        if (p.length === 0)
            return ""
        return p.startsWith("file://") ? p : "file://" + p
    }

    function refreshBackgroundPath() {
        activeBackgroundPath = backgroundPath()
        console.log("[shinlock-bg] path", activeBackgroundPath.length > 0 ? activeBackgroundPath : "(empty)")
    }

    function clamp01(v) {
        return Math.max(0, Math.min(1, v))
    }

    function easeOut(t) {
        t = clamp01(t)
        return 1 - Math.pow(1 - t, 3)
    }

    function easeInOut(t) {
        t = clamp01(t)
        return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2
    }

    function lockAnim(ms) {
        if (!ShinData.effectsEnabled)
            return 1

        var strength = Math.max(0.35, Math.min(1.8, ShinData.lockAnimStrength))
        return Math.max(1, Math.round(ShinData.anim(ms) * strength))
    }

    function lockExitMs() {
        return lockAnim(430)
    }

    function fmtTime(date) {
        return Qt.formatTime(date, ShinData.lockClock24h ? "HH:mm" : "hh:mm")
    }

    function fmtDate(date) {
        return Qt.formatDate(date, "dddd, MMMM dd").toUpperCase()
    }

    function lockNow() {
        failed = false
        statusText = ""
        pendingPassword = ""
        authBusy = false
        unlocking = false
        unlockReleaseTimer.stop()
        lockEnterNonce += 1
        refreshBackgroundPath()
        if (!wallpaperProc.running)
            wallpaperProc.running = true
        sessionLock.locked = true
    }

    function finishUnlock() {
        statusText = ""
        pendingPassword = ""
        authBusy = false
        failed = false
        unlocking = true
        unlockReleaseTimer.restart()
    }

    function submitPassword(password) {
        if (authBusy || password.length === 0)
            return

        pendingPassword = password
        authBusy = true
        failed = false
        statusText = "Verificando..."

        if (!pam.start())
            failAuth("PAM indisponivel")
    }

    function failAuth(message) {
        authBusy = false
        pendingPassword = ""
        failed = true
        failureTick += 1
        statusText = message.length > 0 ? message : "Senha incorreta"
        failTimer.restart()
    }

    Timer {
        id: failTimer
        interval: 1400
        onTriggered: root.failed = false
    }

    Timer {
        id: unlockReleaseTimer
        interval: root.lockExitMs() + 40
        repeat: false
        onTriggered: {
            sessionLock.locked = false
            root.unlocking = false
        }
    }

    Process {
        id: wallpaperProc
        running: false
        command: ["bash", "-lc", "swww query 2>/dev/null | sed -n 's/.*image: //p' | head -n1"]
        stdout: SplitParser {
            onRead: function(line) {
                var path = line.trim()
                if (path.length > 0) {
                    root.currentWallpaper = path
                    if (sessionLock.locked && root.activeBackgroundPath.length === 0)
                        root.refreshBackgroundPath()
                }
            }
        }
        onExited: running = false
    }

    PamContext {
        id: pam
        configDirectory: "/home/shira/.config/quickshell/shinbar/pam"
        config: "password.conf"
        user: root.userName

        onPamMessage: function() {
            if (pam.responseRequired)
                pam.respond(root.pendingPassword)
        }

        onCompleted: function(result) {
            if (result === PamResult.Success) {
                root.statusText = ""
                root.pendingPassword = ""
                root.authBusy = false
                root.finishUnlock()
            } else {
                root.failAuth("Senha incorreta")
            }
        }

        onError: function(error) {
            root.failAuth(PamError.toString(error))
        }
    }

    component OutlineRect: Rectangle {
        id: frame
        property color lineColor: "#f6f7ff"
        property real glow: 0.86
        property real reveal: 1.0
        property real shiftX: 0.0
        property real shiftY: 0.0

        color: "transparent"
        radius: 0
        opacity: reveal
        scale: 0.97 + reveal * 0.03
        transformOrigin: Item.Center
        transform: Translate {
            x: frame.shiftX * (1 - frame.reveal)
            y: frame.shiftY * (1 - frame.reveal)
        }
        border.width: 2
        border.color: Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.88)
        layer.enabled: glow > 0 && reveal > 0.01
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(lineColor.r, lineColor.g, lineColor.b, Math.min(0.42, glow * 0.24))
            shadowBlur: 0.72
            shadowScale: 1.006
        }
    }

    component DiamondDrop: Item {
        id: drop
        property color lineColor: "#f6f7ff"
        property real reveal: 1.0
        property real shiftX: 0.0
        property real shiftY: 0.0
        width: 28
        height: 150
        opacity: reveal
        scale: 0.98 + reveal * 0.02
        transform: Translate {
            x: drop.shiftX * (1 - drop.reveal)
            y: drop.shiftY * (1 - drop.reveal)
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: diamond.top
            width: 2
            color: Qt.rgba(drop.lineColor.r, drop.lineColor.g, drop.lineColor.b, 0.88)
        }

        Rectangle {
            id: diamond
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: 20
            height: 20
            rotation: 45
            color: "transparent"
            border.width: 2
            border.color: Qt.rgba(drop.lineColor.r, drop.lineColor.g, drop.lineColor.b, 0.92)
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: false

        onLockedChanged: {
            if (!locked) {
                root.authBusy = false
                root.failed = false
                root.pendingPassword = ""
                root.statusText = ""
                root.unlocking = false
                unlockReleaseTimer.stop()
                if (pam.active)
                    pam.abort()
            }
        }

        WlSessionLockSurface {
            color: "#050506"

            Item {
                id: scene
                anchors.fill: parent

	                property date now: new Date()
	                property real enter: 0.0
	                property real exit: root.unlocking ? 1.0 : 0.0
	                property real enterEase: root.easeOut(enter)
	                property real exitEase: root.easeInOut(exit)
	                property real live: enterEase * (1 - exitEase)
	                property real bgAlpha: root.easeOut(enter / 0.46) * (1 - exitEase * 0.86)
	                property real s: Math.min(width / 1674, height / 941)
	                property real artW: 520 * s
	                property real artH: 760 * s
	                property color whiteLine: "#f7f8ff"

	                function reveal(delay, span) {
	                    return root.easeOut((enter - delay) / span) * (1 - exitEase)
	                }

	                function frameReveal(order) {
	                    if (ShinData.lockAnimStyle === 2)
	                        return reveal(0.05 + order * 0.025, 0.58)
	                    return reveal(0.04 + order * 0.075, 0.42)
	                }

	                function frameShiftX(direction) {
	                    if (ShinData.lockAnimStyle === 0)
	                        return direction * 34 * s
	                    return 0
	                }

	                function frameShiftY(direction) {
	                    if (ShinData.lockAnimStyle === 1)
	                        return direction * 62 * s
	                    if (ShinData.lockAnimStyle === 2)
	                        return 22 * s
	                    return direction * 18 * s
	                }

	                function restartEntrance() {
	                    enterAnim.stop()
	                    enter = 0.0
	                    enterAnim.restart()
	                }

	                Timer {
	                    interval: 1000
                    repeat: true
                    running: true
	                    onTriggered: scene.now = new Date()
	                }

	                NumberAnimation {
	                    id: enterAnim
	                    target: scene
	                    property: "enter"
	                    from: 0
	                    to: 1
	                    duration: root.lockAnim(640)
	                    easing.type: Easing.OutCubic
	                }

	                Behavior on exit {
	                    NumberAnimation {
	                        duration: root.lockExitMs()
	                        easing.type: Easing.InOutCubic
	                    }
	                }

	                Component.onCompleted: restartEntrance()

	                Connections {
	                    target: root
	                    function onLockEnterNonceChanged() {
	                        scene.restartEntrance()
	                    }
	                }

                property string bgSource: root.fileUrl(root.activeBackgroundPath)
                property bool bgReady: bgBase.status === Image.Ready

                Image {
                    id: bgBase
                    anchors.fill: parent
                    source: scene.bgSource
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: false
                    cache: false
	                    sourceSize.width: 2560
	                    sourceSize.height: 1440
	                    visible: status === Image.Ready
	                    opacity: scene.bgAlpha
	                    scale: 1.026 - scene.enterEase * 0.026 + scene.exitEase * 0.018

	                    onStatusChanged: {
                        if (status === Image.Ready)
                            console.log("[shinlock-bg] loaded", source)
                        else if (status === Image.Error)
                            console.log("[shinlock-bg] error", source)
                    }
                }

                Image {
                    id: bgBlur
                    anchors.fill: parent
                    source: scene.bgSource
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: false
                    cache: false
                    sourceSize.width: 1920
	                    sourceSize.height: 1080
	                    visible: bgBase.status === Image.Ready
	                    opacity: 0.84 * scene.bgAlpha
	                    scale: 1.052 - scene.enterEase * 0.017 + scene.exitEase * 0.018
                    layer.enabled: visible
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blur: Math.max(0.38, Math.min(1, ShinData.lockBlur))
                        blurMax: 74
                        blurMultiplier: 1.0
                    }
                }

                Rectangle {
	                    anchors.fill: parent
	                    color: "#000000"
	                    opacity: (scene.bgReady ? Math.max(0.10, Math.min(0.42, ShinData.lockDim)) : 0.34) * Math.max(scene.bgAlpha, scene.live)
	                }

                Item {
	                    id: model
	                    width: scene.artW
	                    height: scene.artH
	                    anchors.centerIn: parent
	                    opacity: scene.live
	                    scale: (0.965 + scene.enterEase * 0.035) * (1 + scene.exitEase * 0.018)
	                    transform: Translate {
	                        y: (ShinData.lockAnimStyle === 1 ? -20 : 18) * scene.s * (1 - scene.enterEase)
	                            + 34 * scene.s * scene.exitEase
	                    }

                    OutlineRect {
                        id: mainFrame
                        x: 196 * scene.s
                        y: 0
	                        width: 236 * scene.s
	                        height: 666 * scene.s
	                        lineColor: scene.whiteLine
	                        glow: ShinData.lockGlow
	                        reveal: scene.frameReveal(0)
	                        shiftY: scene.frameShiftY(-1)
	                    }

                    OutlineRect {
                        x: 76 * scene.s
                        y: 154 * scene.s
                        width: 100 * scene.s
	                        height: 398 * scene.s
	                        lineColor: scene.whiteLine
	                        glow: ShinData.lockGlow
	                        reveal: scene.frameReveal(1)
	                        shiftX: scene.frameShiftX(-1)
	                        shiftY: scene.frameShiftY(1)
	                    }

                    OutlineRect {
                        x: 448 * scene.s
                        y: 42 * scene.s
                        width: 100 * scene.s
	                        height: 404 * scene.s
	                        lineColor: scene.whiteLine
	                        glow: ShinData.lockGlow
	                        reveal: scene.frameReveal(2)
	                        shiftX: scene.frameShiftX(1)
	                        shiftY: scene.frameShiftY(-1)
	                    }

                    OutlineRect {
                        x: 363 * scene.s
                        y: 446 * scene.s
                        width: 112 * scene.s
	                        height: 292 * scene.s
	                        lineColor: scene.whiteLine
	                        glow: ShinData.lockGlow
	                        reveal: scene.frameReveal(3)
	                        shiftX: scene.frameShiftX(1)
	                        shiftY: scene.frameShiftY(1)
	                    }

                    Rectangle {
                        x: 432 * scene.s
                        y: 16 * scene.s
                        width: 38 * scene.s
	                        height: 2 * scene.s
	                        color: scene.whiteLine
	                        opacity: 0.92 * scene.reveal(0.30, 0.34)
	                        transform: Translate { x: 22 * scene.s * (1 - scene.reveal(0.30, 0.34)) }
	                    }

                    Rectangle {
                        x: 432 * scene.s
                        y: 28 * scene.s
                        width: 66 * scene.s
	                        height: 2 * scene.s
	                        color: scene.whiteLine
	                        opacity: 0.82 * scene.reveal(0.36, 0.34)
	                        transform: Translate { x: 34 * scene.s * (1 - scene.reveal(0.36, 0.34)) }
	                    }

                    DiamondDrop {
                        x: 92 * scene.s
                        y: 552 * scene.s
	                        height: 142 * scene.s
	                        lineColor: scene.whiteLine
	                        reveal: scene.reveal(0.34, 0.42)
	                        shiftY: 42 * scene.s
	                    }

                    DiamondDrop {
                        x: 160 * scene.s
                        y: 552 * scene.s
	                        height: 166 * scene.s
	                        lineColor: scene.whiteLine
	                        reveal: scene.reveal(0.42, 0.42)
	                        shiftY: 52 * scene.s
	                    }

                    DiamondDrop {
                        x: 488 * scene.s
                        y: 446 * scene.s
	                        height: 286 * scene.s
	                        lineColor: scene.whiteLine
	                        reveal: scene.reveal(0.50, 0.42)
	                        shiftY: 64 * scene.s
	                    }

	                    Column {
	                        anchors.horizontalCenter: mainFrame.horizontalCenter
	                        y: 214 * scene.s
	                        width: mainFrame.width * 0.82
	                        spacing: 14 * scene.s
	                        opacity: scene.reveal(0.42, 0.38)
	                        transform: Translate { y: 14 * scene.s * (1 - scene.reveal(0.42, 0.38)) }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.fmtTime(scene.now)
                            color: scene.whiteLine
                            font.family: "DejaVu Sans"
                            font.pixelSize: 80 * scene.s
                            font.weight: Font.Light
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: ShinData.lockShowDate ? root.fmtDate(scene.now) : ""
                            color: Qt.rgba(scene.whiteLine.r, scene.whiteLine.g, scene.whiteLine.b, 0.88)
                            font.family: "DejaVu Sans"
                            font.pixelSize: 18 * scene.s
                            font.weight: Font.Normal
                            elide: Text.ElideRight
                        }

	                        Rectangle {
	                            id: passwordPill
	                            property real inputPulse: 0.0
	                            anchors.horizontalCenter: parent.horizontalCenter
	                            width: 180 * scene.s
	                            height: 36 * scene.s
	                            radius: height / 2
	                            color: "transparent"
	                            border.width: root.failed ? 2 : 1
	                            border.color: root.failed ? ShinColors.warn : scene.whiteLine
	                            scale: 1 + inputPulse * 0.018
	                            transform: Translate { id: shakeShift; x: 0 }

                            Connections {
                                target: root
                                function onFailureTickChanged() {
                                    shakeAnim.restart()
	                                }
	                            }

	                            SequentialAnimation {
	                                id: passPulse
	                                NumberAnimation { target: passwordPill; property: "inputPulse"; to: 1; duration: root.lockAnim(70); easing.type: Easing.OutCubic }
	                                NumberAnimation { target: passwordPill; property: "inputPulse"; to: 0; duration: root.lockAnim(150); easing.type: Easing.OutCubic }
	                            }

                            SequentialAnimation {
                                id: shakeAnim
                                NumberAnimation { target: shakeShift; property: "x"; to: -12; duration: 48 }
                                NumberAnimation { target: shakeShift; property: "x"; to: 12; duration: 48 }
                                NumberAnimation { target: shakeShift; property: "x"; to: -7; duration: 48 }
                                NumberAnimation { target: shakeShift; property: "x"; to: 7; duration: 48 }
                                NumberAnimation { target: shakeShift; property: "x"; to: 0; duration: 58 }
                            }

	                            Row {
	                                anchors.centerIn: parent
	                                spacing: 9 * scene.s
	                                visible: !root.authBusy && passwordInput.text.length > 0
	                                Repeater {
	                                    model: Math.min(passwordInput.text.length, 12)
	                                    Text {
	                                        id: passMark
	                                        property real appear: 0.0
	                                        text: "*"
	                                        color: scene.whiteLine
	                                        opacity: appear
	                                        scale: 0.72 + appear * 0.28
	                                        font.family: "DejaVu Sans"
	                                        font.pixelSize: 20 * scene.s
	                                        font.weight: Font.Light
	                                        horizontalAlignment: Text.AlignHCenter
	                                        verticalAlignment: Text.AlignVCenter

	                                        SequentialAnimation {
	                                            running: true
	                                            PauseAnimation { duration: index * root.lockAnim(18) }
	                                            NumberAnimation {
	                                                target: passMark
	                                                property: "appear"
	                                                from: 0
	                                                to: 1
	                                                duration: root.lockAnim(170)
	                                                easing.type: Easing.OutCubic
	                                            }
	                                        }
	                                    }
	                                }
	                            }

                            Text {
                                anchors.centerIn: parent
                                text: "..."
                                visible: root.authBusy
                                color: scene.whiteLine
                                font.family: "DejaVu Sans"
                                font.pixelSize: 16 * scene.s
                            }

	                            TextInput {
	                                id: passwordInput
	                                anchors.fill: parent
	                                anchors.margins: 8 * scene.s
	                                enabled: !root.authBusy
	                                echoMode: TextInput.Password
	                                color: "transparent"
	                                selectionColor: "transparent"
	                                selectedTextColor: "transparent"
	                                cursorVisible: false
	                                cursorDelegate: Component {
	                                    Item {
	                                        width: 0
	                                        height: 0
	                                        visible: false
	                                    }
	                                }
	                                focus: true
	                                selectByMouse: false
	                                activeFocusOnPress: true
	                                onTextChanged: {
	                                    if (text.length > 0)
	                                        passPulse.restart()
	                                }
	                                Keys.onReturnPressed: {
	                                    var secret = text
	                                    text = ""
                                    root.submitPassword(secret)
                                }
                                Keys.onEscapePressed: text = ""
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: passwordInput.forceActiveFocus()
                            }
                        }
                    }
                }

                Text {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 26 * scene.s
                    width: Math.min(420 * scene.s, parent.width - 40)
                    horizontalAlignment: Text.AlignHCenter
                    text: root.statusText
                    color: root.failed ? ShinColors.warn : Qt.rgba(scene.whiteLine.r, scene.whiteLine.g, scene.whiteLine.b, 0.58)
                    font.family: "DejaVu Sans"
	                    font.pixelSize: 12 * scene.s
	                    elide: Text.ElideRight
	                    visible: text.length > 0
	                    opacity: scene.live
	                }
            }
        }
    }
}
