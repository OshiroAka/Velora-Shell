import Quickshell
import QtQuick
import Qt5Compat.GraphicalEffects
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

    readonly property string clockHeroDefault: "/home/shira/Pictures/Wallpapers/static/fuji-mountain-with-milky-way-night.jpg"
    readonly property int popupW: 930
    readonly property int popupH: 390

    readonly property int cardOpenW: 890
    readonly property int cardOpenH: 350
    readonly property int cardClosedW: 190
    readonly property int cardClosedH: 46
    readonly property int popupLift: 26

    // Animação tipo rastro/corpo elástico.
    property real motion: 0.0
    property int motionDir: 1
    property real introHero: 1.0
    property real introCalendar: 1.0
    property real introFooter: 1.0

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

    function replayPanelEntrance() {
        introHeroAnim.restart()
        introCalendarAnim.restart()
        introFooterAnim.restart()
    }

    function timeFormat(withSeconds) {
        var fmt = ShinConfig.clockUse24h ? "HH:mm" : "hh:mm"
        if (withSeconds && ShinConfig.clockShowSeconds)
            fmt += ":ss"
        if (!ShinConfig.clockUse24h)
            fmt += " AP"
        return fmt
    }

    function pillText() {
        var time = Qt.formatDateTime(root.now, root.timeFormat(true))
        if (ShinConfig.clockStyle === 1)
            return Qt.formatDateTime(root.now, root.timeFormat(false))
        if (ShinConfig.clockStyle === 2)
            return Qt.formatDateTime(root.now, "ddd dd") + "  " + Qt.formatDateTime(root.now, root.timeFormat(false))
        if (ShinConfig.clockStyle === 3)
            return Qt.formatDateTime(root.now, ShinConfig.clockUse24h ? "HH.mm" : "hh.mm AP")
        if (ShinConfig.clockStyle === 4)
            return Qt.formatDateTime(root.now, ShinConfig.clockUse24h ? "HH:mm" : "h:mm AP")
        return time
    }

    onOpenedChanged: {
        if (opened) {
            hideTimer.stop()
            popupVisible = true
            motionDir = 1
            closeAnim.stop()
            openAnim.from = motion
            openAnim.restart()
            replayPanelEntrance()
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
        duration: ShinData.popupAnim(480)
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: closeAnim
        target: root
        property: "motion"
        from: 1
        to: 0
        duration: ShinData.popupAnim(360)
        easing.type: Easing.InCubic
    }

    SequentialAnimation {
        id: introHeroAnim

        ScriptAction { script: root.introHero = 0.0 }
        PauseAnimation { duration: ShinData.popupAnim(80) }
        NumberAnimation {
            target: root
            property: "introHero"
            from: 0.0
            to: 1.0
            duration: ShinData.popupAnim(430)
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: introCalendarAnim

        ScriptAction { script: root.introCalendar = 0.0 }
        PauseAnimation { duration: ShinData.popupAnim(170) }
        NumberAnimation {
            target: root
            property: "introCalendar"
            from: 0.0
            to: 1.0
            duration: ShinData.popupAnim(460)
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: introFooterAnim

        ScriptAction { script: root.introFooter = 0.0 }
        PauseAnimation { duration: ShinData.popupAnim(260) }
        NumberAnimation {
            target: root
            property: "introFooter"
            from: 0.0
            to: 1.0
            duration: ShinData.popupAnim(420)
            easing.type: Easing.OutCubic
        }
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

    function clockHeroSource() {
        var src = ShinData.clockBg && ShinData.clockBg.length > 0 ? ShinData.clockBg : clockHeroDefault
        return src.length > 0 ? "file://" + src : ""
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
        interval: ShinConfig.clockShowSeconds ? 1000 : 5000
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
        text: root.pillText()
        color: (ShinColors && ShinColors.fg ? ShinColors.fg : "#ffffff")
        font.pixelSize: ShinConfig.clockStyle === 2 ? ShinConfig.fontSizeSm : ShinConfig.fontSize
        font.family: ShinConfig.fontFamily
        font.bold: ShinConfig.clockStyle === 3 || ShinConfig.clockStyle === 4
        verticalAlignment: Text.AlignVCenter

        Behavior on color { ColorAnimation { duration: ShinData.anim(120); easing.type: Easing.OutCubic } }
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

                visible: ShinConfig.trailEnabled && root.popupVisible && (openAnim.running || closeAnim.running)
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

            radius: ShinConfig.clockPopupStyle === 1 ? 16 : (ShinConfig.clockPopupStyle === 2 ? 32 : root.cardRadius(root.motion))
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
                    (ShinConfig.clockPopupStyle === 2 ? 0.14 : 0.085) * ShinData.clockAccentBoost
                )
            }

            Row {
                anchors.fill: parent
                anchors.margins: Math.round(root.lerp(0, 20, islandCard.ct))
                spacing: 16
                opacity: islandCard.ct
                visible: opacity > 0.01

                Rectangle {
                    width: 410
                    height: parent.height
                    radius: 20
                    opacity: root.introHero
                    scale: 0.965 + root.introHero * 0.035
                    color: Qt.rgba(ShinColors.surface.r, ShinColors.surface.g, ShinColors.surface.b, 0.52)
                    border.width: 1
                    border.color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.08)
                    clip: true
                    transform: Translate {
                        x: -24 * (1.0 - root.introHero)
                        y: 12 * (1.0 - root.introHero)
                    }

                    Image {
                        id: clockHeroImage
                        anchors.fill: parent
                        visible: false
                        source: root.clockHeroSource()
                        fillMode: Image.PreserveAspectCrop
                        horizontalAlignment: Image.AlignHCenter
                        verticalAlignment: Image.AlignTop
                        asynchronous: true
                        cache: false
                    }

                    Rectangle {
                        id: clockHeroMask
                        anchors.fill: parent
                        radius: parent.radius
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: clockHeroImage
                        maskSource: clockHeroMask
                        opacity: ShinData.clockBg.length > 0 ? ShinData.clockBgOpacity : 0.78
                        visible: root.clockHeroSource().length > 0
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Qt.rgba(ShinColors.bg.r, ShinColors.bg.g, ShinColors.bg.b, 0.42)
                    }

                    Text {
                        x: 28
                        y: 54
                        text: Qt.formatDateTime(root.now, "dddd")
                        color: ShinColors.fg
                        font.pixelSize: 16
                        font.family: ShinConfig.fontFamily
                    }

                    Text {
                        x: 28
                        y: 104
                        text: Qt.formatDateTime(root.now, root.timeFormat(true))
                        color: ShinColors.fg
                        font.pixelSize: 52
                        font.bold: true
                        font.family: ShinConfig.fontFamily
                    }

                    Text {
                        x: 28
                        y: 178
                        text: Qt.formatDateTime(root.now, "dd 'de' MMMM 'de' yyyy")
                        color: ShinColors.muted
                        font.pixelSize: 14
                        font.family: ShinConfig.fontFamily
                    }

                    Rectangle {
                        x: 28
                        y: parent.height - 90
                        width: parent.width - 56
                        height: 1
                        color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.10)
                    }

                    Row {
                        x: 28
                        y: parent.height - 66
                        width: parent.width - 56
                        height: 48
                        spacing: 0
                        opacity: root.introFooter
                        transform: Translate { y: 10 * (1.0 - root.introFooter) }

                        Repeater {
                            model: [
                                { label: "Fuso horário", value: "GMT-3" },
                                { label: "Nascer do sol", value: "06:38" },
                                { label: "Pôr do sol", value: "17:24" }
                            ]

                            Column {
                                width: parent.width / 3
                                spacing: 4

                                Text {
                                    text: modelData.label.toUpperCase()
                                    color: ShinColors.muted
                                    font.pixelSize: 8
                                    font.family: ShinConfig.fontFamily
                                }

                                Text {
                                    text: modelData.value
                                    color: ShinColors.fg
                                    font.pixelSize: 13
                                    font.family: ShinConfig.fontFamily
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: Math.max(0, parent.width - 410 - parent.spacing)
                    height: parent.height
                    radius: 20
                    opacity: root.introCalendar
                    scale: 0.965 + root.introCalendar * 0.035
                    color: Qt.rgba(ShinColors.surface.r, ShinColors.surface.g, ShinColors.surface.b, 0.46)
                    border.width: 1
                    border.color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.08)
                    transform: Translate {
                        x: 26 * (1.0 - root.introCalendar)
                        y: 14 * (1.0 - root.introCalendar)
                    }

                    Text {
                        x: 24
                        y: 26
                        text: Qt.formatDateTime(root.now, "MMMM 'de' yyyy")
                        color: ShinColors.fg
                        font.pixelSize: 18
                        font.family: ShinConfig.fontFamily
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 72
                        y: 25
                        text: "‹"
                        color: ShinColors.fg
                        font.pixelSize: 24
                        font.family: ShinConfig.fontFamily
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 28
                        y: 25
                        text: "›"
                        color: ShinColors.fg
                        font.pixelSize: 24
                        font.family: ShinConfig.fontFamily
                    }

                    Column {
                        x: 24
                        y: 76
                        width: parent.width - 48
                        spacing: 8

                        Row {
                            width: parent.width
                            spacing: 0

                            Repeater {
                                model: ["DOM", "SEG", "TER", "QUA", "QUI", "SEX", "SÁB"]

                                Text {
                                    width: parent.width / 7
                                    height: 22
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: modelData
                                    font.pixelSize: 11
                                    font.family: ShinConfig.fontFamily
                                    color: ShinColors.muted
                                }
                            }
                        }

                        Grid {
                            id: calGrid
                            width: parent.width
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
                                    width: calGrid.width / 7
                                    height: 30

                                    property int day: index - calGrid.firstDow + 1
                                    property bool valid: day >= 1 && day <= calGrid.daysInMonth
                                    property bool isToday: valid && day === calGrid.today

                                    Rectangle {
                                        visible: isToday
                                        anchors.centerIn: parent
                                        width: 34
                                        height: 26
                                        radius: 8
                                        color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.22)
                                    }

                                    Text {
                                        visible: valid
                                        anchors.centerIn: parent
                                        text: day.toString()
                                        color: isToday ? ShinColors.fg : (index % 7 === 0 ? ShinColors.accent : ShinColors.fg)
                                        opacity: isToday ? 1.0 : 0.82
                                        font.pixelSize: 13
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
