import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var popup: null
    readonly property color accent: popup ? popup.winAccent : Qt.rgba(0.78, 0.62, 0.30, 1)
    readonly property color accentSoft: popup ? popup.alpha(popup.winAccent, 0.46) : Qt.rgba(0.78, 0.62, 0.30, 0.46)
    readonly property color rowFill: popup ? popup.alpha(popup.winCardHover, 0.34) : Qt.rgba(1, 1, 1, 0.10)
    readonly property color rowFillHover: popup ? popup.alpha(popup.winCardHover, 0.54) : Qt.rgba(1, 1, 1, 0.16)
    readonly property color lineSoft: popup ? popup.alpha(popup.winAccent, 0.16) : Qt.rgba(1, 1, 1, 0.14)
    readonly property string fontFamily: popup ? popup.uiFont : "sans"

    opacity: popup ? popup.popupIntroOpacity(20, 210) : 1
    scale: popup ? popup.popupIntroScale(20, 0.985, 1) : 1
    transformOrigin: Item.TopLeft
    clip: true

    transform: Translate {
        y: root.popup ? root.popup.popupIntroTranslateY(20, 12) : 0
    }

    function queueSearchFocus() {
        if (popup && popup.popupType === "search" && popup.interactiveFocus) {
            searchFocusTimer.attempts = 0
            searchFocusTimer.restart()
        }
    }

    function triggerAction(action) {
        if (!popup)
            return

        if (action === "terminal") {
            popup.runDetached("if command -v alacritty >/dev/null 2>&1; then alacritty; elif command -v kitty >/dev/null 2>&1; then kitty; elif command -v foot >/dev/null 2>&1; then foot; elif command -v konsole >/dev/null 2>&1; then konsole; else x-terminal-emulator; fi")
            return
        }

        if (action === "settings") {
            popup.openSettings("")
            return
        }

        if (action === "screenshot") {
            popup.runDetached("if command -v velora-screenshot-select >/dev/null 2>&1; then velora-screenshot-select select; elif command -v grimblast >/dev/null 2>&1; then grimblast --notify area; elif command -v slurp >/dev/null 2>&1; then mkdir -p " + popup.shellQuote(popup.homeDir + "/Pictures/Screenshots") + "; grim -g \"$(slurp)\" " + popup.shellQuote(popup.homeDir + "/Pictures/Screenshots/velora-selection.png") + "; fi")
            return
        }

        if (action === "audio") {
            popup.runDetached("systemctl --user restart pipewire pipewire-pulse wireplumber")
            return
        }

        if (action === "large-files") {
            popup.runDetached("if command -v baobab >/dev/null 2>&1; then baobab; elif command -v filelight >/dev/null 2>&1; then filelight; else xdg-open " + popup.shellQuote(popup.homeDir) + "; fi")
            return
        }

        if (action === "startup") {
            popup.runDetached("if command -v systemsettings >/dev/null 2>&1; then systemsettings kcm_autostart; elif command -v gnome-session-properties >/dev/null 2>&1; then gnome-session-properties; else xdg-open " + popup.shellQuote(popup.homeDir + "/.config/autostart") + "; fi")
            return
        }

        if (action === "updates") {
            popup.runDetached("if command -v bauh >/dev/null 2>&1; then bauh; elif command -v discover >/dev/null 2>&1; then plasma-discover --mode update; elif command -v pamac-manager >/dev/null 2>&1; then pamac-manager --updates; else alacritty -e sh -lc 'paru -Qua || pacman -Qu'; fi")
            return
        }

        if (action === "documents") {
            popup.runDetached("xdg-open " + popup.shellQuote(popup.homeDir + "/Documents") + " 2>/dev/null || xdg-open " + popup.shellQuote(popup.homeDir + "/Documentos") + " 2>/dev/null || xdg-open " + popup.shellQuote(popup.homeDir))
            return
        }

        if (action === "photos") {
            popup.runDetached("xdg-open " + popup.shellQuote(popup.homeDir + "/Pictures") + " 2>/dev/null || xdg-open " + popup.shellQuote(popup.homeDir + "/Imagens") + " 2>/dev/null || xdg-open " + popup.shellQuote(popup.homeDir))
            return
        }

        if (action === "notes") {
            popup.runDetached("xdg-open " + popup.shellQuote(popup.homeDir + "/Documents") + " 2>/dev/null || xdg-open " + popup.shellQuote(popup.homeDir))
            return
        }

        if (action === "travel-pdf") {
            popup.runDetached("xdg-open " + popup.shellQuote(popup.homeDir + "/Documents") + " 2>/dev/null || true")
        }
    }

    function themedInputFill(popupRef, active, strong) {
        if (!popupRef)
            return strong ? Qt.rgba(0.02, 0.025, 0.035, 0.74) : Qt.rgba(1, 1, 1, 0.10)

        const source = popupRef.theme ? popupRef.theme.surfaceInput : popupRef.winCardHover
        const dark = popupRef.theme && popupRef.theme.themeMode === "dark"
        const baseOpacity = strong
            ? (active ? 0.78 : 0.66)
            : (active ? 0.70 : 0.58)
        return popupRef.alpha(source, dark ? baseOpacity : Math.min(0.86, baseOpacity + 0.06))
    }

    function themedInputBorder(popupRef, active, busy) {
        if (!popupRef)
            return Qt.rgba(1, 1, 1, 0.14)

        if (busy)
            return popupRef.alpha(root.accent, 0.58)
        return active ? popupRef.alpha(root.accent, 0.52) : popupRef.alpha(popupRef.winLine, 0.82)
    }

    function focusSearchInput(selectText) {
        searchBox.forceSearchFocus(selectText)
    }

    Timer {
        id: searchFocusTimer

        property int attempts: 0

        interval: 70
        repeat: false
        onTriggered: {
            if (!(root.popup && root.popup.popupType === "search" && root.popup.interactiveFocus))
                return

            searchBox.forceSearchFocus()
            attempts += 1
            if (attempts < 10 && !searchBox.searchActiveFocus)
                restart()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 13

        SearchBox {
            id: searchBox

            Layout.fillWidth: true
            Layout.preferredHeight: 56
            popup: root.popup
        }

        SectionHeader {
            Layout.fillWidth: true
            visible: root.popup && root.popup.searchQuery.trim().length > 0
            iconText: "◷"
            title: "Resultados"
            actionText: "Limpar"
            entryDelay: 105
            onActionClicked: {
                if (!root.popup)
                    return
                root.popup.searchQuery = ""
                root.popup.searchSelectedIndex = 0
                root.popup.rebuildSearch()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.popup && root.popup.searchQuery.trim().length > 0
            spacing: 2

            Repeater {
                model: root.popup ? root.popup.searchResults : []

                SearchResultRow {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    popup: root.popup
                    entry: modelData
                    selected: root.popup && index === root.popup.searchSelectedIndex
                    entryDelay: 130 + index * 24
                    onClicked: if (root.popup) root.popup.launchSearchEntry(entry)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.popup && root.popup.searchQuery.trim().length <= 0
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Atalhos"
                color: root.popup ? root.popup.ink : "white"
                font.family: root.fontFamily
                font.pixelSize: 12
                font.weight: Font.Bold
            }

            Text {
                text: "Limpar"
                color: root.popup ? root.popup.inkSoft : Qt.rgba(1, 1, 1, 0.62)
                font.family: root.fontFamily
                font.pixelSize: 11
                font.weight: Font.Medium
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.popup && root.popup.searchQuery.trim().length <= 0
            spacing: 0

            ReferenceRecentRow { Layout.fillWidth: true; iconName: "folder"; title: "Documentos"; subtitle: "Pasta de arquivos"; action: "documents" }
            ReferenceRecentRow { Layout.fillWidth: true; iconName: "image"; title: "Fotos"; subtitle: "Aplicativo"; action: "photos" }
            ReferenceRecentRow { Layout.fillWidth: true; iconName: "settings"; title: "Configurações"; subtitle: "Sistema"; action: "settings" }
            ReferenceRecentRow { Layout.fillWidth: true; iconName: "memo"; title: "Arquivos"; subtitle: "Documentos"; action: "travel-pdf" }
            ReferenceRecentRow { Layout.fillWidth: true; iconName: "memo"; title: "Notas"; subtitle: "Notas"; action: "notes" }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            radius: 12
            color: "transparent"
            border.width: 0

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 12

                VeloraPopupIcon {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    popup: root.popup
                    iconName: "search"
                    lineColor: root.popup ? root.popup.inkSoft : "white"
                }

                Text {
                    Layout.fillWidth: true
                    text: "Ver mais resultados para \" \""
                    color: root.popup ? root.popup.ink : "white"
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    Connections {
        target: root.popup

        function onPopupTypeChanged() {
            root.queueSearchFocus()
        }

        function onOpenChanged() {
            if (root.popup && !root.popup.open)
                root.popup.holdOpen = false
        }

        function onInteractiveFocusChanged() {
            root.queueSearchFocus()
        }

        function onSearchFocusRequestChanged() {
            root.queueSearchFocus()
        }
    }

    Component.onCompleted: {
        root.queueSearchFocus()
    }

    component SectionHeader: Item {
        id: header

        property string iconText: ""
        property string title: ""
        property string actionText: ""
        property int entryDelay: 100
        signal actionClicked()

        implicitHeight: 24
        opacity: root.popup ? root.popup.popupIntroOpacity(entryDelay, 170) : 1
        transform: Translate { y: root.popup ? root.popup.popupIntroTranslateY(header.entryDelay, 5) : 0 }

        RowLayout {
            anchors.fill: parent
            spacing: 8

            Text {
                Layout.preferredWidth: 18
                text: header.iconText
                color: root.accent
                font.family: root.fontFamily
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                Layout.fillWidth: true
                text: header.title
                color: root.popup ? root.popup.ink : "white"
                font.family: root.fontFamily
                font.pixelSize: 13
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                visible: header.actionText.length > 0
                text: header.actionText
                color: root.popup ? root.popup.inkSoft : Qt.rgba(1, 1, 1, 0.62)
                font.family: root.fontFamily
                font.pixelSize: 10
                font.weight: Font.Medium
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: header.actionText.length > 0
            cursorShape: Qt.PointingHandCursor
            onClicked: header.actionClicked()
        }
    }

    component ReferenceRecentRow: Rectangle {
        id: row

        property string iconName: "folder"
        property string title: ""
        property string subtitle: ""
        property string timeText: ""
        property string action: ""
        readonly property bool hovered: rowMouse.containsMouse

        Layout.preferredHeight: 56
        radius: 0
        color: hovered ? root.rowFillHover : "transparent"
        border.width: 0

        Behavior on color { ColorAnimation { duration: root.popup ? root.popup.motionHover : 120; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: root.lineSoft
            opacity: 0.55
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 9
                color: root.popup ? root.popup.alpha(root.popup.winCardHover, 0.48) : Qt.rgba(1, 1, 1, 0.12)
                border.width: 1
                border.color: root.lineSoft

                VeloraPopupIcon {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    popup: root.popup
                    iconName: row.iconName
                    lineColor: root.popup ? root.popup.ink : "white"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: row.title
                    color: root.popup ? root.popup.ink : "white"
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: row.subtitle
                    color: root.popup ? root.popup.inkSoft : Qt.rgba(1, 1, 1, 0.62)
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }

            Text {
                text: row.timeText
                color: root.popup ? root.popup.inkSoft : Qt.rgba(1, 1, 1, 0.62)
                font.family: root.fontFamily
                font.pixelSize: 11
                font.weight: Font.Medium
            }

            Text {
                text: "◷"
                color: root.popup ? root.popup.inkSoft : Qt.rgba(1, 1, 1, 0.62)
                font.family: root.fontFamily
                font.pixelSize: 13
            }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.triggerAction(row.action)
        }
    }

    component SearchBox: Rectangle {
        id: box

        property var popup: null
        readonly property bool searchActiveFocus: input.activeFocus
        property bool pendingSelectText: true

        function forceSearchFocus(selectText) {
            if (!popup)
                return

            pendingSelectText = selectText !== false
            popup.forceActiveFocus(Qt.ShortcutFocusReason)
            input.forceActiveFocus(Qt.ShortcutFocusReason)
            if (selectText !== false)
                input.selectAll()
            searchInputRetry.attempts = 0
            searchInputRetry.restart()
        }

        radius: 10
        color: root.themedInputFill(box.popup, input.activeFocus, false)
        border.width: 1
        border.color: root.themedInputBorder(box.popup, input.activeFocus, false)
        opacity: root.popup ? root.popup.popupIntroOpacity(65, 190) : 1
        scale: root.popup ? root.popup.popupIntroScale(65, 0.97, 1) : 1
        transform: Translate { y: root.popup ? root.popup.popupIntroTranslateY(65, 8) : 0 }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 10
            spacing: 10

            VeloraPopupIcon {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                popup: box.popup
                iconName: "search"
                lineColor: box.popup ? box.popup.inkSoft : "white"
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text.length <= 0
                    text: "Pesquisar apps, arquivos, configurações..."
                    color: box.popup ? box.popup.inkSoft : Qt.rgba(1, 1, 1, 0.62)
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                TextInput {
                    id: input

                    anchors.fill: parent
                    activeFocusOnPress: true
                    text: box.popup ? box.popup.searchQuery : ""
                    color: box.popup ? box.popup.ink : "white"
                    selectedTextColor: box.popup && box.popup.theme ? box.popup.theme.activeText : "white"
                    selectionColor: box.popup ? root.accent : Qt.rgba(0.8, 0.4, 0.6, 1)
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    focus: box.popup && box.popup.popupType === "search" && box.popup.interactiveFocus

                    onTextEdited: if (box.popup) box.popup.searchQuery = text

                    Keys.onPressed: function(event) {
                        if (!box.popup)
                            return
                        if (event.key === Qt.Key_Down) {
                            box.popup.stepSearch(1)
                            event.accepted = true
                            return
                        }
                        if (event.key === Qt.Key_Up) {
                            box.popup.stepSearch(-1)
                            event.accepted = true
                            return
                        }
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            box.popup.launchSelectedSearchEntry()
                            event.accepted = true
                            return
                        }
                        if (event.key === Qt.Key_Escape) {
                            box.popup.closeRequested()
                            event.accepted = true
                        }
                    }
                }
            }

        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.IBeamCursor
            preventStealing: true
            onPressed: function(mouse) {
                mouse.accepted = true
                box.forceSearchFocus(false)
            }
            onClicked: function(mouse) {
                mouse.accepted = true
                box.forceSearchFocus()
            }
        }

        Timer {
            id: searchInputRetry

            property int attempts: 0

            interval: 38
            repeat: false
            onTriggered: {
                if (!box.popup)
                    return
                box.popup.forceActiveFocus(Qt.ShortcutFocusReason)
                input.forceActiveFocus(Qt.ShortcutFocusReason)
                if (box.pendingSelectText)
                    input.selectAll()
                attempts += 1
                if (attempts < 8 && !input.activeFocus)
                    restart()
            }
        }
    }

    component ShortcutHint: Rectangle {
        id: hint

        property string text: ""

        Layout.preferredWidth: Math.max(22, hintLabel.implicitWidth + 10)
        Layout.preferredHeight: 24
        radius: 6
        color: root.popup ? root.popup.alpha(root.popup.winCardHover, 0.50) : Qt.rgba(1, 1, 1, 0.12)
        border.width: 1
        border.color: root.lineSoft

        Text {
            id: hintLabel
            anchors.centerIn: parent
            text: hint.text
            color: root.popup ? root.popup.inkSoft : Qt.rgba(1, 1, 1, 0.62)
            font.family: root.fontFamily
            font.pixelSize: 10
            font.weight: Font.Bold
        }
    }

    component RecentFileRow: Item {
        id: row

        property var popup: null
        property string iconName: "folder"
        property string title: ""
        property string subtitle: ""
        property string kind: "file"
        property bool hovered: false
        property int entryDelay: 130
        signal clicked()

        opacity: root.popup ? root.popup.popupIntroOpacity(entryDelay, 180) : 1
        transform: Translate { y: root.popup ? root.popup.popupIntroTranslateY(row.entryDelay, 6) : 0 }

        RowLayout {
            anchors.fill: parent
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 4
                color: {
                    if (row.kind === "pdf")
                        return Qt.rgba(0.78, 0.16, 0.13, 0.92)
                    if (row.kind === "sheet")
                        return Qt.rgba(0.14, 0.54, 0.26, 0.92)
                    if (row.kind === "text")
                        return Qt.rgba(0.60, 0.62, 0.60, 0.86)
                    return root.popup ? root.popup.alpha(root.accent, 0.78) : Qt.rgba(0.78, 0.62, 0.30, 0.78)
                }

                VeloraPopupIcon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    popup: row.popup
                    iconName: row.iconName
                    lineColor: row.kind === "folder" ? (root.popup ? root.popup.winSurfaceDeep : "black") : "white"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: row.title
                    color: root.popup ? root.popup.ink : "white"
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: row.subtitle
                    color: root.popup ? root.popup.inkSoft : Qt.rgba(1, 1, 1, 0.62)
                    font.family: root.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: -8
            anchors.rightMargin: -8
            radius: 8
            z: -1
            color: row.hovered ? root.rowFill : "transparent"
            border.width: row.hovered ? 1 : 0
            border.color: root.lineSoft
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: row.hovered = true
            onExited: row.hovered = false
            onClicked: row.clicked()
        }
    }

    component CommandRow: Rectangle {
        id: row

        property var popup: null
        property string iconName: "box"
        property string title: ""
        property string subtitle: ""
        property string shortcut: ""
        property bool hovered: false
        property int entryDelay: 200
        signal clicked()

        radius: 9
        color: hovered ? root.rowFillHover : root.rowFill
        border.width: 1
        border.color: hovered ? root.accentSoft : root.lineSoft
        opacity: root.popup ? root.popup.popupIntroOpacity(entryDelay, 180) : 1
        scale: root.popup ? root.popup.popupIntroScale(entryDelay, 0.975, 1) : 1
        transform: Translate { y: root.popup ? root.popup.popupIntroTranslateY(row.entryDelay, 6) : 0 }

        Behavior on color { ColorAnimation { duration: root.popup ? root.popup.motionHover : 120 } }
        Behavior on border.color { ColorAnimation { duration: root.popup ? root.popup.motionHover : 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 11

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: 7
                color: root.popup ? root.popup.alpha(root.popup.winCardHover, 0.48) : Qt.rgba(1, 1, 1, 0.12)
                border.width: 1
                border.color: root.lineSoft

                VeloraPopupIcon {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    popup: row.popup
                    iconName: row.iconName
                    lineColor: root.popup ? (row.hovered ? root.accent : root.popup.inkSoft) : "white"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: row.title
                    color: root.popup ? root.popup.ink : "white"
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: row.subtitle.length > 0
                    text: row.subtitle
                    color: root.popup ? root.popup.inkSoft : Qt.rgba(1, 1, 1, 0.62)
                    font.family: root.fontFamily
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }

            ShortcutHint {
                visible: row.shortcut.length > 0
                text: row.shortcut
            }

            Text {
                text: "›"
                color: root.popup ? root.popup.inkSoft : Qt.rgba(1, 1, 1, 0.62)
                font.family: root.fontFamily
                font.pixelSize: 18
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: row.hovered = true
            onExited: row.hovered = false
            onClicked: row.clicked()
        }
    }

    component SuggestionPanel: Rectangle {
        id: panel

        property var popup: null
        property int entryDelay: 410

        radius: 10
        color: root.popup ? root.popup.alpha(root.popup.winCardHover, 0.28) : Qt.rgba(1, 1, 1, 0.10)
        border.width: 1
        border.color: root.lineSoft
        opacity: root.popup ? root.popup.popupIntroOpacity(entryDelay, 190) : 1
        scale: root.popup ? root.popup.popupIntroScale(entryDelay, 0.98, 1) : 1
        transform: Translate { y: root.popup ? root.popup.popupIntroTranslateY(panel.entryDelay, 6) : 0 }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            spacing: 3

            Repeater {
                model: panel.popup ? panel.popup.frequentApps : []

                SuggestionRow {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    popup: panel.popup
                    iconName: panel.popup && panel.popup.searchEntryKind(modelData) === "settings"
                        ? "settings"
                        : (panel.popup && panel.popup.searchEntryKind(modelData) === "files" ? "folder" : "box")
                    title: panel.popup ? panel.popup.textOf(modelData.name) : ""
                    subtitle: panel.popup ? panel.popup.appUsageSubtitle(modelData) : ""
                    onClicked: if (panel.popup) panel.popup.launchSearchEntry(modelData)
                }
            }
        }
    }

    component SuggestionRow: Item {
        id: row

        property var popup: null
        property string iconName: "box"
        property string title: ""
        property string subtitle: ""
        property bool hovered: false
        signal clicked()

        RowLayout {
            anchors.fill: parent
            spacing: 12

            VeloraPopupIcon {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                popup: row.popup
                iconName: row.iconName
                lineColor: root.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: row.title
                    color: root.popup ? root.popup.ink : "white"
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: row.subtitle
                    color: root.popup ? root.popup.inkSoft : Qt.rgba(1, 1, 1, 0.62)
                    font.family: root.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: -6
            anchors.rightMargin: -6
            z: -1
            radius: 8
            color: row.hovered ? root.rowFill : "transparent"
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: row.hovered = true
            onExited: row.hovered = false
            onClicked: row.clicked()
        }
    }

    component Divider: Rectangle {
        height: 1
        color: root.popup ? root.popup.alpha(root.popup.winAccent, 0.12) : Qt.rgba(1, 1, 1, 0.12)
    }

    component SearchResultRow: Rectangle {
        id: row

        property var popup: null
        property var entry: null
        property bool selected: false
        property int entryDelay: 130
        signal clicked()

        radius: 9
        color: selected && popup ? popup.alpha(root.accent, 0.24) : (rowMouse.containsMouse && popup ? root.rowFill : "transparent")
        border.width: selected ? 1 : 0
        border.color: popup ? popup.alpha(root.accent, 0.34) : Qt.rgba(1, 1, 1, 0.16)
        opacity: root.popup ? root.popup.popupIntroOpacity(entryDelay, 180) : 1
        transform: Translate { y: root.popup ? root.popup.popupIntroTranslateY(row.entryDelay, 6) : 0 }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 6
                color: root.popup ? root.popup.alpha(root.accent, row.selected ? 0.36 : 0.22) : Qt.rgba(1, 1, 1, 0.12)

                VeloraPopupIcon {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    popup: row.popup
                    iconName: row.popup && row.popup.searchEntryKind(row.entry) === "settings" ? "settings" : (row.popup && row.popup.searchEntryKind(row.entry) === "files" ? "folder" : "box")
                    lineColor: row.popup ? (row.selected ? root.accent : row.popup.inkSoft) : "white"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: row.popup && row.entry ? row.popup.textOf(row.entry.name) : ""
                    color: row.popup ? (row.selected ? root.accent : row.popup.ink) : "white"
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: row.popup && row.entry ? row.popup.textOf(row.entry.genericName || row.entry.comment || "") : ""
                    color: row.popup ? row.popup.inkSoft : Qt.rgba(1, 1, 1, 0.62)
                    visible: text.length > 0
                    font.family: root.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            id: rowMouse

            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            preventStealing: true
            cursorShape: Qt.PointingHandCursor
            onClicked: function(mouse) {
                mouse.accepted = true
                row.clicked()
            }
        }
    }
}
