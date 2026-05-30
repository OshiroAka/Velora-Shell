import Quickshell
import QtQuick
import "."

Item {
    id: root

    implicitWidth:  clockTxt.implicitWidth + ShinConfig.pillPadH * 2
    implicitHeight: ShinConfig.barH

    property bool opened: ShinPopup.active === "clock"
    property bool popupVisible: false
    property bool hoverRoot: false
    property bool hoverPopup: false
    property var now: new Date()

    // Popup maior, mantendo o mesmo design.
    readonly property int popupW: 570
    readonly property int popupH: 470

    readonly property int cardOpenW: 540
    readonly property int cardOpenH: 430
    readonly property int cardClosedW: 190
    readonly property int cardClosedH: 46
    readonly property int popupLift: 26

    // Animação tipo rastro/corpo elástico.
    property real motion: 0.0
    property int motionDir: 1

    function clamp01(v) {
        return Math.max(0, Math.min(1, v))
    }

    function lerp(a, b, t) {
        return a + (b - a) * t
    }

    // Parecido com emphasizedDecel: começa rápido e desacelera.
    function emphasizedDecel(t) {
        t = clamp01(t)
        return 1 - Math.pow(1 - t, 3.15)
    }

    // Fechamento um pouco mais agressivo.
    function emphasizedAccel(t) {
        t = clamp01(t)
        return Math.pow(t, 2.35)
    }

    function visualT() {
        return opened ? emphasizedDecel(motion) : 1 - emphasizedAccel(1 - motion)
    }

    function contentT() {
        return clamp01((motion - 0.28) / 0.72)
    }

    function cardW(t) {
        return lerp(cardClosedW, cardOpenW, emphasizedDecel(t))
    }

    function cardH(t) {
        return lerp(cardClosedH, cardOpenH, emphasizedDecel(t))
    }

    function cardY(t) {
        return lerp(-18, 0, emphasizedDecel(t))
    }

    function cardRadius(t) {
        return lerp(23, 24, emphasizedDecel(t))
    }

    function trailT(offset) {
        if (motionDir >= 0)
            return clamp01(motion - offset)

        return clamp01(motion + offset)
    }

    onOpenedChanged: {
        if (opened) {
            hideTimer.stop()
            popupVisible = true
            motionDir = 1
            closeAnim.stop()
            openAnim.from = motion
            openAnim.restart()
        } else {
            motionDir = -1
            openAnim.stop()
            closeAnim.from = motion
            closeAnim.restart()
            hideTimer.restart()
        }
    }

    NumberAnimation {
        id: openAnim
        target: root
        property: "motion"
        from: 0
        to: 1
        duration: 480
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: closeAnim
        target: root
        property: "motion"
        from: 1
        to: 0
        duration: 360
        easing.type: Easing.InCubic
    }

    function openPopup() {
        closeTimer.stop()
        hideTimer.stop()
        popupVisible = true
        ShinPopup.open("clock")
    }

    function scheduleClose() {
        closeTimer.restart()
    }

    function seasonName() {
        var mo = root.now.getMonth() + 1
        if (mo >= 12 || mo <= 2) return "Verão"
        if (mo >= 3 && mo <= 5) return "Outono"
        if (mo >= 6 && mo <= 8) return "Inverno"
        return "Primavera"
    }

    Timer {
        id: closeTimer
        interval: 240
        repeat: false
        onTriggered: {
            if (!root.hoverRoot && !root.hoverPopup)
                ShinPopup.close("clock")
        }
    }

    Timer {
        id: hideTimer
        interval: 450
        repeat: false
        onTriggered: {
            if (!root.opened)
                root.popupVisible = false
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    ShinPill {
        anchors.fill: parent
        anchors.topMargin:    (parent.height - ShinConfig.pillH) / 2
        anchors.bottomMargin: (parent.height - ShinConfig.pillH) / 2
        active: root.opened
        clickable: false
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        onEntered: {
            root.hoverRoot = true
            root.openPopup()
        }

        onExited: {
            root.hoverRoot = false
            root.scheduleClose()
        }
    }

    Text {
        id: clockTxt
        anchors.centerIn: parent
        text: Qt.formatDateTime(root.now, "hh:mm:ss AP")
        color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
        font.pixelSize: ShinConfig.fontSize
        font.family: ShinConfig.fontFamily
        verticalAlignment: Text.AlignVCenter

        Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }

    PopupWindow {
        id: clockPopup
        visible: root.popupVisible
        color: "transparent"

        implicitWidth: root.popupW
        implicitHeight: root.popupH

        anchor.item: root
        anchor.rect.x: Math.round(root.implicitWidth / 2 - clockPopup.implicitWidth / 2)
        anchor.rect.y: root.implicitHeight + 10
        anchor.rect.width: 1
        anchor.rect.height: 1

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            z: 99

            onEntered: {
                root.hoverPopup = true
                root.openPopup()
            }

            onExited: {
                root.hoverPopup = false
                root.scheduleClose()
            }
        }

        // Rastros preenchidos atrás do calendário.
        Repeater {
            model: [0.10, 0.18, 0.27]

            Rectangle {
                property real t: root.trailT(modelData)
                property real e: root.emphasizedDecel(t)

                z: -3
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.cardY(t)

                width: root.cardW(t)
                height: root.cardH(t)
                radius: root.cardRadius(t)
                antialiasing: true
                clip: true

                visible: root.popupVisible && (openAnim.running || closeAnim.running)
                opacity: (0.24 - index * 0.055) * (root.opened ? root.motion : Math.max(root.motion, 0.25))

                color: Qt.rgba(
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                    0.18
                )

                border.width: 1
                border.color: Qt.rgba(
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                    0.28
                )
            }
        }

        Rectangle {
            id: islandCard

            property real t: root.visualT()
            property real ct: root.contentT()

            width: root.cardW(root.motion)
            height: root.cardH(root.motion)
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.cardY(root.motion)

            radius: root.cardRadius(root.motion)
            antialiasing: true
            clip: true
            opacity: root.clamp01(root.motion * 1.25)
            scale: 0.965 + root.emphasizedDecel(root.motion) * 0.035

            color: Qt.rgba((ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").r, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").g, (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").b, ShinConfig.popupOpacity)
            border.color: Qt.rgba(
                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                0.18 + 0.13 * root.motion
            )
            border.width: 1

            Image {
                anchors.fill: parent
                visible: ShinData.clockBg.length > 0
                source: ShinData.clockBg.length > 0 ? "file://" + ShinData.clockBg : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                opacity: ShinData.clockBgOpacity
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(
                    (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").r,
                    (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").g,
                    (ShinColors && ShinColors.bg ? ShinColors.bg : "#ffffff").b,
                    ShinData.clockBg.length > 0 ? 0.38 : 0.0
                )
            }

            Rectangle {
                width: 180
                height: 132
                radius: 66
                x: root.lerp(-82, -52, islandCard.ct)
                y: root.lerp(-66, -44, islandCard.ct)
                color: Qt.rgba(
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                    (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                    0.085 * ShinData.clockAccentBoost
                )
            }

            Column {
                anchors.fill: parent
                anchors.margins: Math.round(root.lerp(0, 22, islandCard.ct))
                spacing: Math.round(root.lerp(0, 12, islandCard.ct))

                Item {
                    width: parent.width
                    height: root.lerp(parent.height, 100, islandCard.ct)

                    Text {
                        id: bigClock
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: root.lerp(0, -10, islandCard.ct)

                        text: Qt.formatDateTime(root.now, "hh:mm:ss AP")
                        color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                        font.pixelSize: Math.round(root.lerp(13, 42, islandCard.ct))
                        font.family: ShinConfig.fontFamily
                        font.bold: true
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: bigClock.bottom
                        anchors.topMargin: 5
                        opacity: islandCard.ct
                        y: root.lerp(-8, 0, islandCard.ct)
                        text: Qt.formatDateTime(root.now, "dddd, dd 'de' MMMM 'de' yyyy")
                        color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                        font.pixelSize: 13
                        font.family: ShinConfig.fontFamily
                    }
                }

                Column {
                    width: parent.width
                    spacing: 10
                    opacity: islandCard.ct
                    y: root.lerp(-14, 0, islandCard.ct)
                    visible: opacity > 0.01

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10

                        Rectangle {
                            width: 112
                            height: 28
                            radius: 14
                            color: Qt.rgba(
                                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                                (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                                0.15
                            )

                            Text {
                                anchors.centerIn: parent
                                text: root.seasonName()
                                color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                                font.pixelSize: 11
                                font.bold: true
                                font.family: ShinConfig.fontFamily
                            }
                        }

                        Rectangle {
                            width: 142
                            height: 28
                            radius: 14
                            color: Qt.rgba(
                                (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").r,
                                (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").g,
                                (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff").b,
                                0.07
                            )

                            Text {
                                anchors.centerIn: parent
                                text: "Island motion"
                                color: (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff")
                                font.pixelSize: 11
                                font.family: ShinConfig.fontFamily
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Qt.rgba(
                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                            0.17
                        )
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(root.now, "MMMM yyyy")
                        color: (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                        font.pixelSize: 13
                        font.bold: true
                        font.family: ShinConfig.fontFamily
                    }

                    Column {
                        width: parent.width
                        spacing: 4

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 0

                            Repeater {
                                model: ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sab"]

                                Text {
                                    width: 68
                                    height: 19
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: modelData
                                    font.pixelSize: 10
                                    font.family: ShinConfig.fontFamily
                                    color: Qt.rgba(
                                        (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff").r,
                                        (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff").g,
                                        (ShinColors && ShinColors.muted ? ShinColors.muted : "#ffffff").b,
                                        0.80
                                    )
                                }
                            }
                        }

                        Grid {
                            id: calGrid
                            anchors.horizontalCenter: parent.horizontalCenter
                            columns: 7
                            spacing: 0

                            property int year: root.now.getFullYear()
                            property int month: root.now.getMonth()
                            property int today: root.now.getDate()
                            property int firstDow: new Date(year, month, 1).getDay()
                            property int daysInMonth: new Date(year, month + 1, 0).getDate()
                            property int totalCells: firstDow + daysInMonth

                            Repeater {
                                model: calGrid.totalCells

                                delegate: Item {
                                    width: 68
                                    height: 26

                                    property int day: index - calGrid.firstDow + 1
                                    property bool valid: day >= 1 && day <= calGrid.daysInMonth
                                    property bool isToday: valid && day === calGrid.today

                                    Rectangle {
                                        visible: isToday
                                        anchors.centerIn: parent
                                        width: 34
                                        height: 23
                                        radius: 10
                                        color: Qt.rgba(
                                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").r,
                                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").g,
                                            (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff").b,
                                            0.30
                                        )
                                    }

                                    Text {
                                        visible: valid
                                        anchors.centerIn: parent
                                        text: day.toString()
                                        color: isToday
                                            ? (ShinColors && ShinColors.accent ? ShinColors.accent : "#ffffff")
                                            : index % 7 === 0
                                                ? Qt.rgba(
                                                    (ShinColors && ShinColors.warn ? ShinColors.warn : "#ffffff").r,
                                                    (ShinColors && ShinColors.warn ? ShinColors.warn : "#ffffff").g,
                                                    (ShinColors && ShinColors.warn ? ShinColors.warn : "#ffffff").b,
                                                    0.80
                                                )
                                                : (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
                                        font.pixelSize: 11
                                        font.family: ShinConfig.fontFamily
                                        font.bold: isToday
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
