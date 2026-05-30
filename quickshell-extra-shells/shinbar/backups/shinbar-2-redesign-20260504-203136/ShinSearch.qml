import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "."

Item {
    id: root

    visible: ShinConfig.searchEnabled
    implicitWidth: visible ? 42 : 0
    implicitHeight: visible ? ShinConfig.barH : 0

    property bool opened: ShinPopup.active === "search"
    property bool hovered: false
    property bool overlayVisible: false
    property real motion: 0.0
    property real introInput: 1.0
    property real introRecent: 1.0
    property real introResults: 1.0
    property real introFooter: 1.0
    property real sweepX: -160
    property string query: ""
    property int selectedIndex: 0
    property var results: []

    function clamp01(v) {
        return Math.max(0, Math.min(1, v))
    }

    function ease(t) {
        t = clamp01(t)
        return 1 - Math.pow(1 - t, 3.0)
    }

    function lerp(a, b, t) {
        return a + (b - a) * t
    }

    function canvasColor(c, alpha) {
        var a = alpha === undefined ? 1 : alpha
        return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + a + ")"
    }

    function norm(s) {
        return (s === undefined || s === null ? "" : ("" + s)).toLowerCase()
    }

    function entryText(entry) {
        if (!entry)
            return ""

        return root.norm(entry.name) + " " +
            root.norm(entry.genericName) + " " +
            root.norm(entry.comment) + " " +
            root.norm(entry.execString) + " " +
            root.norm(entry.categories ? entry.categories.join(" ") : "") + " " +
            root.norm(entry.keywords ? entry.keywords.join(" ") : "")
    }

    function matches(entry) {
        if (!entry || entry.noDisplay)
            return false

        var q = root.norm(root.query).trim()
        if (q.length === 0)
            return true

        return root.entryText(entry).indexOf(q) >= 0
    }

    function rebuild() {
        var list = DesktopEntries.applications.values || []
        var out = []
        var max = Math.max(1, ShinConfig.searchMaxResults)

        for (var i = 0; i < list.length; i++) {
            if (root.matches(list[i])) {
                out.push(list[i])
                if (out.length >= max)
                    break
            }
        }

        root.results = out
        root.selectedIndex = Math.max(0, Math.min(root.selectedIndex, out.length - 1))
    }

    function launch(entry) {
        if (!entry)
            return

        entry.execute()
        input.text = ""
        root.query = ""
        ShinPopup.close("search")
    }

    function appSub(entry) {
        if (!entry)
            return ""
        return entry.genericName || entry.comment || "Aplicativo"
    }

    function replaySearchEntrance() {
        introInputAnim.restart()
        introRecentAnim.restart()
        introResultsAnim.restart()
        introFooterAnim.restart()
        sweepAnim.restart()
    }

    onOpenedChanged: {
        if (opened) {
            hideTimer.stop()
            closeAnim.stop()
            root.overlayVisible = true
            openAnim.from = root.motion
            openAnim.restart()
            replaySearchEntrance()
            root.rebuild()
            searchCanvas.requestPaint()
            Qt.callLater(function() {
                input.forceActiveFocus()
                input.selectAll()
            })
        } else {
            openAnim.stop()
            closeAnim.from = root.motion
            closeAnim.restart()
            hideTimer.restart()
            filterTimer.stop()
            searchCanvas.requestPaint()
        }
    }

    Component.onCompleted: {
        root.rebuild()
        searchCanvas.requestPaint()
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            root.rebuild()
        }
    }

    Connections {
        target: ShinColors
        function onAccentChanged() {
            searchCanvas.requestPaint()
        }
        function onWalSignatureChanged() {
            searchCanvas.requestPaint()
        }
    }

    Timer {
        id: filterTimer
        interval: 60
        repeat: false
        onTriggered: root.rebuild()
    }

    NumberAnimation {
        id: openAnim
        target: root
        property: "motion"
        from: 0
        to: 1
        duration: ShinData.popupAnim(300)
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: closeAnim
        target: root
        property: "motion"
        from: 1
        to: 0
        duration: ShinData.popupAnim(220)
        easing.type: Easing.InCubic
    }

    NumberAnimation {
        id: sweepAnim
        target: root
        property: "sweepX"
        from: -170
        to: Math.max(620, ShinConfig.searchPanelWidth + 180)
        duration: ShinData.popupAnim(720)
        easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: introInputAnim

        ScriptAction { script: root.introInput = 0.0 }
        PauseAnimation { duration: ShinData.popupAnim(45) }
        NumberAnimation {
            target: root
            property: "introInput"
            from: 0.0
            to: 1.0
            duration: ShinData.popupAnim(300)
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: introRecentAnim

        ScriptAction { script: root.introRecent = 0.0 }
        PauseAnimation { duration: ShinData.popupAnim(120) }
        NumberAnimation {
            target: root
            property: "introRecent"
            from: 0.0
            to: 1.0
            duration: ShinData.popupAnim(360)
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: introResultsAnim

        ScriptAction { script: root.introResults = 0.0 }
        PauseAnimation { duration: ShinData.popupAnim(190) }
        NumberAnimation {
            target: root
            property: "introResults"
            from: 0.0
            to: 1.0
            duration: ShinData.popupAnim(400)
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: introFooterAnim

        ScriptAction { script: root.introFooter = 0.0 }
        PauseAnimation { duration: ShinData.popupAnim(280) }
        NumberAnimation {
            target: root
            property: "introFooter"
            from: 0.0
            to: 1.0
            duration: ShinData.popupAnim(320)
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: hideTimer
        interval: ShinData.popupAnim(185)
        repeat: false
        onTriggered: {
            if (!root.opened) {
                input.text = ""
                root.query = ""
                root.results = []
                root.overlayVisible = false
                root.motion = 0
            }
        }
    }

    ShinPill {
        anchors.fill: parent
        anchors.topMargin: (parent.height - ShinConfig.pillH) / 2
        anchors.bottomMargin: (parent.height - ShinConfig.pillH) / 2
        clickable: false
        active: root.opened || root.hovered
    }

    Item {
        id: searchIcon
        z: 4
        anchors.centerIn: parent
        width: 20
        height: 20
        scale: root.opened || root.hovered ? 1.10 : 1.0
        rotation: root.opened ? -8 : 0

        Canvas {
            id: searchCanvas
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d")
                var w = width
                var h = height
                ctx.clearRect(0, 0, w, h)
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                ctx.lineWidth = 2.4
                ctx.strokeStyle = root.canvasColor(ShinColors.accent, 1)

                ctx.beginPath()
                ctx.arc(w * 0.43, h * 0.42, w * 0.24, 0, Math.PI * 2)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(w * 0.62, h * 0.62)
                ctx.lineTo(w * 0.82, h * 0.82)
                ctx.stroke()
            }
        }

        Behavior on scale { NumberAnimation { duration: ShinData.anim(150); easing.type: Easing.OutCubic } }
        Behavior on rotation { NumberAnimation { duration: ShinData.anim(170); easing.type: Easing.OutCubic } }
    }

    onHoveredChanged: searchCanvas.requestPaint()

    onVisibleChanged: {
        if (!visible && root.opened)
            ShinPopup.close("search")
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: ShinPopup.toggle("search")
    }

    PanelWindow {
        id: overlay
        visible: root.overlayVisible || openAnim.running || closeAnim.running
        color: "transparent"
        focusable: true

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "shinbar-search"
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.26 * root.ease(root.motion))

            MouseArea {
                anchors.fill: parent
                enabled: root.opened
                onClicked: ShinPopup.close("search")
            }
        }

        Repeater {
            model: [0.08, 0.16, 0.25]

            Rectangle {
                property real t: root.clamp01(root.motion - modelData)
                property real et: root.ease(t)

                z: 1
                x: card.x
                y: card.y + Math.round(root.lerp(-14, 0, et))
                width: card.width
                height: card.height
                radius: card.radius
                antialiasing: true
                visible: ShinConfig.trailEnabled && (openAnim.running || closeAnim.running)
                opacity: (0.18 - index * 0.045) * (root.opened ? root.motion : Math.max(root.motion, 0.25))
                color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.13)
                border.width: 1
                border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.22)
            }
        }

        Rectangle {
            id: card
            property real et: root.ease(root.motion)
            z: 2
            width: Math.min(overlay.width - 32, ShinConfig.searchPanelWidth)
            height: inputBox.height + recentTitle.height + recentRow.height + resultsTitle.height + resultList.height + footerHints.height + 74
            x: ShinConfig.searchPosition === 0
                ? 24
                : ShinConfig.searchPosition === 2
                    ? overlay.width - width - 24
                    : Math.round((overlay.width - width) / 2)
            y: ShinConfig.barH + ShinConfig.barMarginT + 18 + Math.round(root.lerp(-14, 0, card.et))
            radius: 28
            antialiasing: true
            clip: true
            opacity: root.clamp01(root.motion * 1.25)
            scale: 0.94 + card.et * 0.06
            color: Qt.rgba(ShinColors.bg.r, ShinColors.bg.g, ShinColors.bg.b, Math.max(0.84, ShinConfig.searchOpacity))
            border.width: 1
            border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.26)

            Behavior on color { ColorAnimation { duration: ShinData.anim(130); easing.type: Easing.OutCubic } }

            MouseArea { anchors.fill: parent; onClicked: {} }

            Rectangle {
                width: 130
                height: parent.height + 70
                x: root.sweepX
                y: -35
                rotation: 14
                color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.055)
            }

            Rectangle {
                id: inputBox
                x: 24
                y: 24
                width: parent.width - 48
                height: ShinConfig.searchCompact ? 40 : 48
                radius: 16
                opacity: root.introInput
                scale: 0.965 + root.introInput * 0.035
                color: Qt.rgba(ShinColors.surface.r, ShinColors.surface.g, ShinColors.surface.b, 0.62)
                border.width: 1
                border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, input.activeFocus ? 0.54 : 0.16)
                transform: Translate {
                    y: 12 * (1.0 - root.introInput)
                }

                Item {
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                    height: 16

                    Rectangle {
                        x: 1
                        y: 1
                        width: 9
                        height: 9
                        radius: 5
                        color: "transparent"
                        border.width: 2
                        border.color: ShinColors.accent
                    }

                    Rectangle {
                        x: 10
                        y: 11
                        width: 7
                        height: 2
                        radius: 1
                        rotation: 45
                        transformOrigin: Item.Left
                        color: ShinColors.accent
                    }
                }

                TextInput {
                    id: input
                    anchors.left: parent.left
                    anchors.leftMargin: 36
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: ShinColors.fg
                    selectionColor: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.35)
                    selectedTextColor: ShinColors.fg
                    font.pixelSize: ShinConfig.searchCompact ? 13 : 15
                    font.family: ShinConfig.fontFamily
                    clip: true

                    onTextChanged: {
                        root.query = text
                        filterTimer.restart()
                    }

                    Keys.onEscapePressed: ShinPopup.close("search")
                    Keys.onDownPressed: root.selectedIndex = Math.min(root.results.length - 1, root.selectedIndex + 1)
                    Keys.onUpPressed: root.selectedIndex = Math.max(0, root.selectedIndex - 1)
                    Keys.onReturnPressed: root.launch(root.results[root.selectedIndex])
                    Keys.onEnterPressed: root.launch(root.results[root.selectedIndex])
                }

                Text {
                    anchors.left: input.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text.length === 0
                    text: "Pesquisar apps"
                    color: Qt.rgba(ShinColors.muted.r, ShinColors.muted.g, ShinColors.muted.b, 0.76)
                    font.pixelSize: ShinConfig.searchCompact ? 13 : 15
                    font.family: ShinConfig.fontFamily
                }
            }

            Text {
                id: recentTitle
                x: 24
                y: inputBox.y + inputBox.height + 28
                width: parent.width - 48
                height: 22
                text: "Apps recentes"
                color: ShinColors.fg
                opacity: root.introRecent
                font.pixelSize: 13
                font.family: ShinConfig.fontFamily
                transform: Translate { y: 10 * (1.0 - root.introRecent) }
            }

            Row {
                id: recentRow
                x: 24
                y: recentTitle.y + recentTitle.height + 10
                width: parent.width - 48
                height: 86
                spacing: 14
                opacity: root.introRecent
                scale: 0.97 + root.introRecent * 0.03
                transform: Translate { y: 12 * (1.0 - root.introRecent) }

                Repeater {
                    model: root.results.slice(0, Math.min(5, root.results.length))

                    Rectangle {
                        width: (recentRow.width - 56) / 5
                        height: recentRow.height
                        radius: 16
                        color: recentArea.containsMouse
                            ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.14)
                            : Qt.rgba(ShinColors.surface.r, ShinColors.surface.g, ShinColors.surface.b, 0.56)
                        border.width: 1
                        border.color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, recentArea.containsMouse ? 0.14 : 0.06)
                        clip: true

                        IconImage {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 20
                            width: 30
                            height: 30
                            source: Quickshell.iconPath(modelData.icon, true)
                            asynchronous: true
                        }

                        Text {
                            x: 8
                            y: 58
                            width: parent.width - 16
                            text: modelData.name || "App"
                            color: ShinColors.fg
                            font.pixelSize: 10
                            font.family: ShinConfig.fontFamily
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: recentArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.launch(modelData)
                        }

                        Behavior on color { ColorAnimation { duration: ShinData.anim(110); easing.type: Easing.OutCubic } }
                    }
                }
            }

            Text {
                id: resultsTitle
                x: 24
                y: recentRow.y + recentRow.height + 28
                width: parent.width - 48
                height: 22
                text: "Resultados"
                color: ShinColors.fg
                opacity: root.introResults
                font.pixelSize: 13
                font.family: ShinConfig.fontFamily
                transform: Translate { y: 10 * (1.0 - root.introResults) }
            }

            ListView {
                id: resultList
                x: 24
                y: resultsTitle.y + resultsTitle.height + 8
                width: parent.width - 48
                height: Math.min(contentHeight, ShinConfig.searchCompact ? 250 : 320)
                clip: true
                spacing: 8
                model: root.results
                currentIndex: root.selectedIndex
                opacity: root.introResults
                scale: 0.975 + root.introResults * 0.025
                transform: Translate { y: 14 * (1.0 - root.introResults) }

                delegate: Rectangle {
                    id: row
                    property var itemData: modelData

                    width: ListView.view.width
                    height: ShinConfig.searchCompact ? 42 : 56
                    radius: 16
                    color: row.index === root.selectedIndex
                        ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.20)
                            : rowArea.containsMouse
                            ? Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.10)
                            : Qt.rgba(ShinColors.surface.r, ShinColors.surface.g, ShinColors.surface.b, 0.22)

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        IconImage {
                            visible: ShinConfig.searchShowIcons
                            width: Math.max(24, ShinConfig.searchIconSize)
                            height: width
                            anchors.verticalCenter: parent.verticalCenter
                            source: Quickshell.iconPath(row.itemData.icon, true)
                            asynchronous: true
                        }

                        Column {
                            width: parent.width - (ShinConfig.searchShowIcons ? ShinConfig.searchIconSize + 120 : 92)
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                width: parent.width
                                text: row.itemData.name || "App"
                                color: row.index === root.selectedIndex ? ShinColors.accent : ShinColors.fg
                                font.pixelSize: ShinConfig.searchCompact ? 11 : 12
                                font.bold: row.index === root.selectedIndex
                                font.family: ShinConfig.fontFamily
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: !ShinConfig.searchCompact
                                width: parent.width
                                text: root.appSub(row.itemData)
                                color: ShinColors.muted
                                font.pixelSize: 9
                                font.family: ShinConfig.fontFamily
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            width: 70
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Abrir  ↵"
                            color: row.index === root.selectedIndex ? ShinColors.fg : ShinColors.muted
                            font.pixelSize: 10
                            font.family: ShinConfig.fontFamily
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.selectedIndex = row.index
                        onClicked: root.launch(row.itemData)
                    }

                    Behavior on color { ColorAnimation { duration: ShinData.anim(110); easing.type: Easing.OutCubic } }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: resultsTitle.y + 38
                visible: root.results.length === 0
                text: "Nenhum app encontrado"
                color: ShinColors.muted
                opacity: root.introResults
                font.pixelSize: 11
                font.family: ShinConfig.fontFamily
            }

            Row {
                id: footerHints
                x: 24
                y: resultList.y + resultList.height + 18
                width: parent.width - 48
                height: 18
                opacity: root.introFooter
                transform: Translate { y: 8 * (1.0 - root.introFooter) }

                Text {
                    width: parent.width / 2
                    text: "◷  Use ↑↓ para navegar"
                    color: ShinColors.muted
                    font.pixelSize: 10
                    font.family: ShinConfig.fontFamily
                }

                Text {
                    width: parent.width / 2
                    text: "Enter para abrir"
                    color: ShinColors.muted
                    font.pixelSize: 10
                    font.family: ShinConfig.fontFamily
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
