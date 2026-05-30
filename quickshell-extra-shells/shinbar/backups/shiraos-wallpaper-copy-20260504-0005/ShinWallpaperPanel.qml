import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "."

Item {
    id: root

    property bool opened: ShinPopup.active === "wallpapers"
    property bool overlayVisible: false
    property real motion: 0.0
    property real scanPulse: 0.0
    property var entries: []
    property var filtered: []
    property string category: ""
    property int selectedIndex: 0

    readonly property bool horizontal: ShinConfig.wallpaperPanelPosition < 2
    readonly property bool carouselMode: ShinConfig.wallpaperModel === 2
    readonly property var categoryModel: [
        { label: "Todos", kind: "" },
        { label: "Static", kind: "static" },
        { label: "Live", kind: "live" },
        { label: "Engine", kind: "engine" }
    ]

    function clamp(v, mn, mx) {
        return Math.max(mn, Math.min(mx, v))
    }

    function clamp01(v) {
        return clamp(v, 0, 1)
    }

    function ease(t) {
        t = clamp01(t)
        return 1 - Math.pow(1 - t, 3.0)
    }

    function basename(path) {
        var parts = ("" + path).split("/")
        return parts.length > 0 ? parts[parts.length - 1] : path
    }

    function fileUrl(path) {
        return path && path.length > 0 ? "file://" + path : ""
    }

    function kindLabel(kind) {
        if (kind === "live")
            return "LIVE"
        if (kind === "engine")
            return "ENGINE"
        return "STATIC"
    }

    function transitionName() {
        if (ShinConfig.wallpaperTransition === 1)
            return "grow"
        if (ShinConfig.wallpaperTransition === 2)
            return "wipe"
        if (ShinConfig.wallpaperTransition === 3)
            return "outer"
        return "fade"
    }

    function panelMargin() {
        return Math.max(8, ShinConfig.barMarginH)
    }

    function panelSpan() {
        return clamp(ShinConfig.wallpaperPanelSpan, 0.45, 1.0)
    }

    function panelThick() {
        return clamp(ShinConfig.wallpaperPanelThick, 140, 420)
    }

    function panelWidth() {
        var m = panelMargin()
        if (carouselMode)
            return overlay.width - m * 2
        if (horizontal)
            return ShinConfig.wallpaperFillEdges ? overlay.width - m * 2 : Math.min(overlay.width - m * 2, Math.round(overlay.width * panelSpan()))
        return panelThick()
    }

    function panelHeight() {
        var m = panelMargin()
        if (carouselMode)
            return Math.min(clamp(ShinConfig.wallpaperPanelThick, 280, 430), overlay.height - ShinConfig.barH - m * 2)
        if (horizontal)
            return Math.min(panelThick(), overlay.height - ShinConfig.barH - m * 2)
        return ShinConfig.wallpaperFillEdges ? overlay.height - ShinConfig.barH - m * 2 : Math.min(overlay.height - ShinConfig.barH - m * 2, Math.round(overlay.height * panelSpan()))
    }

    function panelX(et) {
        var m = panelMargin()
        var base = 0
        if (carouselMode)
            base = m
        else
        if (ShinConfig.wallpaperPanelPosition === 2)
            base = m
        else if (ShinConfig.wallpaperPanelPosition === 3)
            base = overlay.width - panelWidth() - m
        else
            base = Math.round((overlay.width - panelWidth()) / 2)

        if (carouselMode)
            return base
        if (ShinConfig.wallpaperOpenStyle === 2)
            return base
        if (ShinConfig.wallpaperPanelPosition === 2)
            return Math.round(base - (1 - et) * 48)
        if (ShinConfig.wallpaperPanelPosition === 3)
            return Math.round(base + (1 - et) * 48)
        if (ShinConfig.wallpaperOpenStyle === 3)
            return base
        return Math.round(base + (1 - et) * 18)
    }

    function panelY(et) {
        var m = panelMargin()
        var topBase = ShinConfig.barH + ShinConfig.barMarginT + 8
        var base = 0
        if (carouselMode)
            base = topBase
        else
        if (ShinConfig.wallpaperPanelPosition === 0)
            base = overlay.height - panelHeight() - m
        else if (ShinConfig.wallpaperPanelPosition === 1)
            base = topBase
        else
            base = Math.round(topBase + (overlay.height - topBase - panelHeight() - m) / 2)

        if (carouselMode)
            return Math.round(base - (1 - et) * 34)
        if (ShinConfig.wallpaperOpenStyle === 2)
            return base
        if (ShinConfig.wallpaperPanelPosition === 0)
            return Math.round(base + (1 - et) * 54)
        if (ShinConfig.wallpaperPanelPosition === 1)
            return Math.round(base - (1 - et) * 42)
        if (ShinConfig.wallpaperOpenStyle === 3)
            return base
        return Math.round(base + (1 - et) * 14)
    }

    function tileWidth(current) {
        if (!horizontal)
            return Math.max(122, list.width - 8)
        if (carouselMode)
            return current ? 272 : 238
        if (ShinConfig.wallpaperModel === 0)
            return 142
        if (ShinConfig.wallpaperModel === 1)
            return 178
        if (ShinConfig.wallpaperModel === 3)
            return current ? 236 : 176
        if (ShinConfig.wallpaperModel === 4)
            return 164
        return 196
    }

    function tileHeight(current) {
        if (horizontal) {
            if (carouselMode)
                return Math.max(290, list.height - 18)
            if (ShinConfig.wallpaperModel === 0)
                return Math.max(92, list.height - 28)
            if (ShinConfig.wallpaperModel === 3)
                return current ? Math.max(120, list.height - 6) : Math.max(104, list.height - 28)
            return Math.max(108, list.height - 16)
        }

        if (ShinConfig.wallpaperModel === 0)
            return 92
        if (ShinConfig.wallpaperModel === 3)
            return current ? 158 : 118
        return 128
    }

    function tileAngle(idx, current) {
        if (carouselMode)
            return clamp((idx - selectedIndex) * -4.8, -10, 10)
        if (ShinConfig.wallpaperModel === 2)
            return clamp((idx - selectedIndex) * -5, -9, 9)
        if (ShinConfig.wallpaperModel === 4)
            return current ? 0 : (idx % 2 === 0 ? -3 : 3)
        return 0
    }

    function tileScale(current) {
        if (carouselMode)
            return current ? 1.02 : 0.96
        if (ShinConfig.wallpaperMoveStyle === 1 && current)
            return 1.03
        if (ShinConfig.wallpaperModel === 3)
            return current ? 1.0 : 0.88
        return current ? 1.0 : 0.96
    }

    function tileOpacity(current) {
        if (ShinConfig.wallpaperMoveStyle === 4)
            return current ? 1.0 : 0.70
        return 1.0
    }

    function tileLift(idx, current) {
        if (carouselMode)
            return current ? -14 : Math.min(10, Math.abs(idx - selectedIndex) * 2)
        if (ShinConfig.wallpaperMoveStyle === 1 && current)
            return root.horizontal ? -8 : 0
        if (ShinConfig.wallpaperMoveStyle === 2)
            return root.horizontal ? Math.min(10, Math.abs(idx - selectedIndex) * 2) : 0
        return 0
    }

    function moveDuration() {
        if (ShinConfig.wallpaperMoveStyle === 1)
            return 120
        if (ShinConfig.wallpaperMoveStyle === 2)
            return 260
        if (ShinConfig.wallpaperMoveStyle === 3)
            return 40
        if (ShinConfig.wallpaperMoveStyle === 4)
            return 160
        return 190
    }

    function refreshFiltered() {
        var out = []
        for (var i = 0; i < entries.length; ++i) {
            var item = entries[i]
            if (category.length === 0 || item.kind === category)
                out.push(item)
        }

        filtered = out
        selectedIndex = clamp(selectedIndex, 0, Math.max(0, filtered.length - 1))
    }

    function countKind(kind) {
        if (kind.length === 0)
            return entries.length

        var count = 0
        for (var i = 0; i < entries.length; ++i) {
            if (entries[i].kind === kind)
                count += 1
        }
        return count
    }

    function setCategory(kind) {
        category = kind
        selectedIndex = 0
        refreshFiltered()
    }

    function moveSelection(step) {
        if (filtered.length === 0)
            return
        selectedIndex = clamp(selectedIndex + step, 0, filtered.length - 1)
        list.positionViewAtIndex(selectedIndex, ListView.Center)
    }

    function applyCurrent() {
        if (filtered.length === 0 || applyProc.running)
            return

        var item = filtered[selectedIndex]
        applyProc.command = [
            "/home/shira/.config/quickshell/shinbar/scripts/shinbar-wallpaper-apply",
            item.kind,
            item.path,
            item.preview,
            transitionName(),
            ShinConfig.wallpaperApplyPywal ? "true" : "false"
        ]
        applyProc.running = true
    }

    function reload() {
        if (!scanProc.running)
            scanProc.running = true
    }

    function beginOpen() {
        hideTimer.stop()
        closeAnim.stop()
        overlayVisible = true
        openAnim.from = motion
        openAnim.restart()
        if (entries.length === 0)
            reload()
    }

    function beginClose() {
        openAnim.stop()
        closeAnim.from = motion
        closeAnim.restart()
        hideTimer.restart()
    }

    onEntriesChanged: refreshFiltered()
    onCategoryChanged: refreshFiltered()

    onOpenedChanged: {
        if (opened && !ShinConfig.wallpaperSelectorEnabled) {
            ShinPopup.close("wallpapers")
            return
        }

        if (opened) {
            beginOpen()
        } else {
            beginClose()
        }
    }

    Component.onCompleted: {
        if (opened)
            beginOpen()
    }

    Process {
        id: scanProc
        running: false
        property var tmp: []
        command: ["/home/shira/.config/quickshell/shinbar/scripts/shinbar-wallpaper-scan"]

        onStarted: {
            tmp = []
            scanAnim.restart()
        }

        stdout: SplitParser {
            onRead: function(data) {
                var line = data.trim()
                if (!line || line === "BEGIN")
                    return
                if (line === "END") {
                    root.entries = scanProc.tmp
                    return
                }

                var parts = line.split("|")
                if (parts.length < 3)
                    return

                var kind = parts[0].toLowerCase()
                var path = parts[1]
                var preview = parts.slice(2).join("|")
                var title = kind === "engine" ? "Workshop " + path : root.basename(path)
                scanProc.tmp.push({ kind: kind, path: path, preview: preview, title: title })
            }
        }

        onExited: {
            running = false
            root.entries = tmp
        }
    }

    Process {
        id: applyProc
        running: false
        command: ["/home/shira/.config/quickshell/shinbar/scripts/shinbar-wallpaper-apply"]
        onExited: running = false
    }

    Timer {
        id: hideTimer
        interval: ShinData.popupAnim(220)
        repeat: false
        onTriggered: {
            if (!root.opened) {
                root.overlayVisible = false
                root.motion = 0
            }
        }
    }

    NumberAnimation {
        id: openAnim
        target: root
        property: "motion"
        from: 0
        to: 1
        duration: ShinData.popupAnim(360)
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

    SequentialAnimation {
        id: scanAnim
        loops: Animation.Infinite
        running: scanProc.running
        NumberAnimation { target: root; property: "scanPulse"; from: 0; to: 1; duration: ShinData.anim(620); easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "scanPulse"; from: 1; to: 0; duration: ShinData.anim(620); easing.type: Easing.InOutSine }
    }

    PanelWindow {
        id: overlay
        visible: root.overlayVisible || openAnim.running || closeAnim.running
        color: "transparent"
        focusable: true

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "shinbar-wallpapers"
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore

        Item {
            anchors.fill: parent
            focus: root.opened

            Keys.onEscapePressed: ShinPopup.close("wallpapers")
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Left) {
                    root.moveSelection(root.carouselMode || root.horizontal ? -1 : 0)
                    event.accepted = true
                } else if (event.key === Qt.Key_Right) {
                    root.moveSelection(root.carouselMode || root.horizontal ? 1 : 0)
                    event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                    root.moveSelection(root.carouselMode || root.horizontal ? 0 : -1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Down) {
                    root.moveSelection(root.carouselMode || root.horizontal ? 0 : 1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.applyCurrent()
                    event.accepted = true
                } else if (event.key === Qt.Key_R) {
                    root.reload()
                    event.accepted = true
                }
            }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, (root.carouselMode ? 0.08 : 0.18) * root.ease(root.motion))
            MouseArea {
                anchors.fill: parent
                enabled: root.opened
                onClicked: ShinPopup.close("wallpapers")
            }
        }

        Repeater {
            model: [0.08, 0.16, 0.25]

            Rectangle {
                property real t: root.ease(root.motion - modelData)

                z: 1
                x: card.x + Math.round(16 * (1.0 - t))
                y: card.y + Math.round(12 * (1.0 - t))
                width: card.width
                height: card.height
                radius: card.radius
                visible: !root.carouselMode && ShinConfig.trailEnabled && (openAnim.running || closeAnim.running)
                opacity: (0.14 - index * 0.035) * root.motion
                color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.12)
                border.width: 1
                border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.18)
            }
        }

        Rectangle {
            id: card
            property real et: root.ease(root.motion)

            z: 2
            x: root.panelX(et)
            y: root.panelY(et)
            width: root.panelWidth()
            height: root.panelHeight()
            radius: 18
            scale: ShinConfig.wallpaperOpenStyle === 3 ? 0.88 + et * 0.12 : 1.0
            opacity: root.clamp01(root.motion * 1.35)
            color: root.carouselMode ? "transparent" : Qt.rgba(ShinColors.bg.r, ShinColors.bg.g, ShinColors.bg.b, Math.max(0.58, ShinConfig.popupOpacity))
            border.width: root.carouselMode ? 0 : 1
            border.color: root.carouselMode ? "transparent" : Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.24)
            clip: !root.carouselMode
            antialiasing: true

            Behavior on width { NumberAnimation { duration: ShinData.anim(180); easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: ShinData.anim(180); easing.type: Easing.OutCubic } }

            MouseArea { anchors.fill: parent; onClicked: {} }

            Rectangle {
                visible: !root.carouselMode
                width: parent.width
                height: 2
                y: 0
                color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.40 + root.scanPulse * 0.28)
                opacity: scanProc.running ? 1 : 0.34
            }

            Column {
                anchors.fill: parent
                anchors.margins: root.carouselMode ? 0 : 12
                spacing: root.carouselMode ? 0 : 10

                Row {
                    width: parent.width
                    height: root.carouselMode ? 0 : 34
                    visible: !root.carouselMode
                    spacing: 10

                    Text {
                        id: panelTitle
                        visible: parent.width > 300
                        width: visible ? Math.min(126, parent.width * 0.32) : 0
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Wallpapers"
                        color: ShinColors.fg
                        font.pixelSize: 13
                        font.bold: true
                        font.family: ShinConfig.fontFamily
                        elide: Text.ElideRight
                    }

                    Flickable {
                        width: Math.max(44, parent.width - panelTitle.width - refreshButton.width - applyButton.width - 34)
                        height: parent.height
                        contentWidth: catRow.implicitWidth
                        clip: true
                        interactive: contentWidth > width

                        Row {
                            id: catRow
                            height: parent.height
                            spacing: 6

                            Repeater {
                                model: root.categoryModel

                                Rectangle {
                                    property bool selected: root.category === modelData.kind

                                    width: Math.max(64, catText.implicitWidth + 22)
                                    height: 28
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: 9
                                    color: selected
                                        ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.22)
                                        : catArea.containsMouse
                                            ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.13)
                                            : Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.06)
                                    border.width: selected ? 1 : 0
                                    border.color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.30)

                                    Text {
                                        id: catText
                                        anchors.centerIn: parent
                                        text: modelData.label + " " + root.countKind(modelData.kind)
                                        color: selected ? ShinColors.accent : ShinColors.fg
                                        font.pixelSize: 10
                                        font.family: ShinConfig.fontFamily
                                        font.bold: selected
                                    }

                                    MouseArea {
                                        id: catArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.setCategory(modelData.kind)
                                    }

                                    Behavior on color { ColorAnimation { duration: ShinData.anim(120); easing.type: Easing.OutCubic } }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: refreshButton
                        width: card.width > 300 ? 76 : 34
                        height: 28
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 9
                        color: refreshArea.containsMouse || scanProc.running
                            ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.16)
                            : Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.06)

                        Text {
                            anchors.centerIn: parent
                            text: card.width > 300 ? (scanProc.running ? "Lendo" : "Atualizar") : "R"
                            color: ShinColors.fg
                            font.pixelSize: 10
                            font.family: ShinConfig.fontFamily
                        }

                        MouseArea {
                            id: refreshArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.reload()
                        }
                    }

                    Rectangle {
                        id: applyButton
                        width: card.width > 300 ? 54 : 34
                        height: 28
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 9
                        color: applyArea.containsMouse || applyProc.running
                            ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.20)
                            : Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.06)

                        Text {
                            anchors.centerIn: parent
                            text: card.width > 300 ? (applyProc.running ? "..." : "Aplicar") : ">"
                            color: applyProc.running ? ShinColors.muted : ShinColors.accent
                            font.pixelSize: 10
                            font.bold: !applyProc.running
                            font.family: ShinConfig.fontFamily
                        }

                        MouseArea {
                            id: applyArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.applyCurrent()
                        }
                    }
                }

                ListView {
                    id: list
                    width: parent.width
                    height: parent.height - (root.carouselMode ? 0 : 44)
                    clip: false
                    orientation: root.carouselMode || root.horizontal ? ListView.Horizontal : ListView.Vertical
                    spacing: root.carouselMode ? 52 : root.horizontal ? 14 : 10
                    model: root.filtered
                    currentIndex: root.selectedIndex
                    highlightMoveDuration: ShinData.anim(root.moveDuration())
                    highlightRangeMode: ListView.ApplyRange
                    preferredHighlightBegin: root.carouselMode ? width * 0.42 : root.horizontal ? width * 0.34 : height * 0.30
                    preferredHighlightEnd: root.carouselMode ? width * 0.58 : root.horizontal ? width * 0.66 : height * 0.58
                    cacheBuffer: root.carouselMode ? 360 : 120

                    delegate: Rectangle {
                        id: tile
                        property bool current: index === root.selectedIndex
                        property bool imageReady: modelData.preview && modelData.preview.length > 0

                        width: root.tileWidth(current)
                        height: root.tileHeight(current)
                        radius: root.carouselMode ? 3 : ShinConfig.wallpaperModel === 0 ? 999 : 14
                        scale: root.tileScale(current)
                        rotation: root.tileAngle(index, current)
                        opacity: root.tileOpacity(current)
                        color: root.carouselMode
                            ? Qt.rgba(ShinColors.bg.r, ShinColors.bg.g, ShinColors.bg.b, current ? 0.28 : 0.16)
                            : current
                            ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.18)
                            : tileArea.containsMouse
                                ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.10)
                                : Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.055)
                        border.width: current ? 2 : 1
                        border.color: root.carouselMode
                            ? Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, current ? 0.82 : 0.18)
                            : current
                            ? Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.78)
                            : Qt.rgba(ShinColors.fg.r, ShinColors.fg.g, ShinColors.fg.b, 0.10)
                        clip: true
                        antialiasing: true
                        transform: Translate { y: root.tileLift(index, current) }

                        Behavior on width { NumberAnimation { duration: ShinData.anim(170); easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: ShinData.anim(170); easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: ShinData.anim(170); easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: ShinData.anim(root.moveDuration()); easing.type: Easing.OutCubic } }
                        Behavior on rotation { NumberAnimation { duration: ShinData.anim(180); easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: ShinData.anim(120); easing.type: Easing.OutCubic } }

                        Rectangle {
                            visible: ShinConfig.wallpaperModel === 4
                            width: 1
                            height: 18
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 0
                            color: Qt.rgba(ShinColors.accent.r, ShinColors.accent.g, ShinColors.accent.b, 0.44)
                        }

                        Image {
                            anchors.fill: parent
                            anchors.margins: ShinConfig.wallpaperModel === 0 ? 4 : 0
                            visible: tile.imageReady
                            source: root.fileUrl(modelData.preview)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            sourceSize.width: root.carouselMode ? 360 : 220
                            sourceSize.height: root.carouselMode ? 520 : 140
                        }

                        Rectangle {
                            anchors.fill: parent
                            visible: !tile.imageReady
                            color: Qt.rgba(ShinColors.bg.r, ShinColors.bg.g, ShinColors.bg.b, 0.62)

                            Text {
                                anchors.centerIn: parent
                                text: root.kindLabel(modelData.kind)
                                color: ShinColors.muted
                                font.pixelSize: 10
                                font.bold: true
                                font.family: ShinConfig.fontFamily
                            }
                        }

                        Rectangle {
                            visible: !root.carouselMode
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: ShinConfig.wallpaperModel === 0 ? 30 : 38
                            color: Qt.rgba(ShinColors.bg.r, ShinColors.bg.g, ShinColors.bg.b, current ? 0.74 : 0.68)
                        }

                        Text {
                            visible: !root.carouselMode
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            anchors.bottomMargin: ShinConfig.wallpaperModel === 0 ? 8 : 18
                            text: modelData.title
                            color: current ? ShinColors.accent : ShinColors.fg
                            font.pixelSize: 10
                            font.bold: current
                            font.family: ShinConfig.fontFamily
                            elide: Text.ElideMiddle
                        }

                        Text {
                            visible: !root.carouselMode && ShinConfig.wallpaperModel !== 0
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            anchors.bottomMargin: 6
                            text: root.kindLabel(modelData.kind)
                            color: ShinColors.muted
                            font.pixelSize: 8
                            font.family: ShinConfig.fontFamily
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: tileArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.selectedIndex = index
                                list.positionViewAtIndex(index, ListView.Center)
                            }
                            onDoubleClicked: root.applyCurrent()
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !scanProc.running && root.filtered.length === 0
                        text: "Nenhum wallpaper"
                        color: ShinColors.muted
                        font.pixelSize: 12
                        font.family: ShinConfig.fontFamily
                    }
                }
            }
        }
        }
    }
}
