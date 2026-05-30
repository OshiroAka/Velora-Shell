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

    onOpenedChanged: {
        if (opened) {
            hideTimer.stop()
            closeAnim.stop()
            root.overlayVisible = true
            openAnim.from = root.motion
            openAnim.restart()
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
        duration: ShinData.popupAnim(230)
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: closeAnim
        target: root
        property: "motion"
        from: 1
        to: 0
        duration: ShinData.popupAnim(170)
        easing.type: Easing.InCubic
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
            color: Qt.rgba(0, 0, 0, 0.18 * root.ease(root.motion))

            MouseArea {
                anchors.fill: parent
                enabled: root.opened
                onClicked: ShinPopup.close("search")
            }
        }

        Rectangle {
            id: card
            property real et: root.ease(root.motion)
            width: Math.min(overlay.width - 32, ShinConfig.searchPanelWidth)
            height: inputBox.height + resultList.height + 28
            x: ShinConfig.searchPosition === 0
                ? 24
                : ShinConfig.searchPosition === 2
                    ? overlay.width - width - 24
                    : Math.round((overlay.width - width) / 2)
            y: ShinConfig.barH + ShinConfig.barMarginT + 18 + Math.round(root.lerp(-14, 0, card.et))
            radius: 18
            antialiasing: true
            clip: true
            opacity: root.clamp01(root.motion * 1.25)
            scale: 0.94 + card.et * 0.06
            color: Qt.rgba(ShinColors.bg.r, ShinColors.bg.g, ShinColors.bg.b, ShinConfig.searchOpacity)
            border.width: 1
            border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.26)

            Behavior on color { ColorAnimation { duration: ShinData.anim(130); easing.type: Easing.OutCubic } }

            MouseArea { anchors.fill: parent; onClicked: {} }

            Rectangle {
                id: inputBox
                x: 12
                y: 12
                width: parent.width - 24
                height: ShinConfig.searchCompact ? 40 : 48
                radius: 14
                color: Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.075)
                border.width: 1
                border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, input.activeFocus ? 0.54 : 0.16)

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

            ListView {
                id: resultList
                x: 8
                y: inputBox.y + inputBox.height + 8
                width: parent.width - 16
                height: Math.min(contentHeight, ShinConfig.searchCompact ? 300 : 380)
                clip: true
                spacing: 5
                model: root.results
                currentIndex: root.selectedIndex

                delegate: Rectangle {
                    id: row
                    property var itemData: modelData

                    width: ListView.view.width
                    height: ShinConfig.searchCompact ? 38 : 48
                    radius: 12
                    color: row.index === root.selectedIndex
                        ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.20)
                        : rowArea.containsMouse
                            ? Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.08)
                            : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        IconImage {
                            visible: ShinConfig.searchShowIcons
                            width: ShinConfig.searchIconSize
                            height: ShinConfig.searchIconSize
                            anchors.verticalCenter: parent.verticalCenter
                            source: Quickshell.iconPath(row.itemData.icon, true)
                            asynchronous: true
                        }

                        Column {
                            width: parent.width - (ShinConfig.searchShowIcons ? ShinConfig.searchIconSize + 20 : 10)
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
                                text: row.itemData.comment || row.itemData.genericName || row.itemData.execString || ""
                                color: ShinColors.muted
                                font.pixelSize: 9
                                font.family: ShinConfig.fontFamily
                                elide: Text.ElideRight
                            }
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
                y: inputBox.y + inputBox.height + 36
                visible: root.results.length === 0
                text: "Nenhum app encontrado"
                color: ShinColors.muted
                font.pixelSize: 11
                font.family: ShinConfig.fontFamily
            }
        }
    }
}
