import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root

    property var popup: null
    readonly property color accent: popup ? popup.winAccent : Qt.rgba(0.78, 0.62, 0.30, 1)
    readonly property color accentSoft: popup ? popup.alpha(popup.winAccent, 0.46) : Qt.rgba(0.78, 0.62, 0.30, 0.46)
    readonly property color rowFill: popup ? popup.alpha(popup.winCardHover, 0.34) : Qt.rgba(1, 1, 1, 0.10)
    readonly property color rowFillHover: popup ? popup.alpha(popup.winCardHover, 0.54) : Qt.rgba(1, 1, 1, 0.16)
    readonly property color lineSoft: popup ? popup.alpha(popup.winAccent, 0.16) : Qt.rgba(1, 1, 1, 0.14)
    readonly property string fontFamily: popup ? popup.uiFont : "sans"
    property string geminiPrompt: ""
    property string geminiPendingPrompt: ""
    property string geminiAnswer: ""
    property string geminiError: ""
    property string geminiCleanAnswer: ""
    property string geminiVisibleAnswer: ""
    property var geminiHistory: []
    property int geminiRevealIndex: 0
    property int geminiThinkingFrame: 0
    property bool geminiLoading: false
    readonly property bool geminiConversationActive: geminiLoading || geminiAnswer.trim().length > 0 || geminiError.trim().length > 0
    readonly property bool geminiAnswerTyping: geminiCleanAnswer.length > 0 && geminiVisibleAnswer.length < geminiCleanAnswer.length

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

    function askGemini() {
        if (!popup)
            return

        const prompt = geminiPrompt.trim().length > 0 ? geminiPrompt.trim() : popup.searchQuery.trim()
        if (prompt.length <= 0)
            return

        if (geminiQuery.running)
            geminiQuery.running = false

        resetGeminiTyping()
        geminiPendingPrompt = prompt
        geminiAnswer = ""
        geminiError = ""
        geminiLoading = true
        geminiQuery.command = [popup.geminiScript, "--plain", prompt]
        geminiQuery.running = true
        geminiPrompt = ""
        syncGeminiHoldOpen()
    }

    function syncGeminiHoldOpen() {
        if (popup && popup.popupType === "search")
            popup.holdOpen = geminiConversationActive
    }

    function focusSearchInput(selectText) {
        searchBox.forceSearchFocus(selectText)
    }

    function focusGeminiInput(selectText) {
        if (typeof geminiAskBoxLoader !== "undefined" && geminiAskBoxLoader.item && geminiAskBoxLoader.item.forceGeminiFocus)
            geminiAskBoxLoader.item.forceGeminiFocus(selectText)
    }

    function appendGeminiOutput(data) {
        const line = String(data || "").trim()
        if (line.length <= 0)
            return

        geminiAnswer = geminiAnswer.length > 0 ? geminiAnswer + "\n" + line : line
    }

    function resetGeminiTyping() {
        geminiTypingTimer.stop()
        geminiCleanAnswer = ""
        geminiVisibleAnswer = ""
        geminiRevealIndex = 0
    }

    function cleanGeminiText(text) {
        let output = String(text || "")
        output = output.replace(/\r/g, "")
        output = output.replace(/```[A-Za-z0-9_-]*\n/g, "")
        output = output.replace(/```/g, "")
        output = output.replace(/^\s*#{1,6}\s*/gm, "")
        output = output.replace(/^\s*[-*_]{3,}\s*$/gm, "")
        output = output.replace(/^\s*>\s?/gm, "")
        output = output.replace(/^\s*[-*+]\s+/gm, "")
        output = output.replace(/\*\*([^*]+)\*\*/g, "$1")
        output = output.replace(/__([^_]+)__/g, "$1")
        output = output.replace(/\*([^*\n]+)\*/g, "$1")
        output = output.replace(/_([^_\n]+)_/g, "$1")
        output = output.replace(/`([^`]+)`/g, "$1")
        output = output.replace(/\[([^\]]+)\]\([^)]+\)/g, "$1")
        output = output.replace(/[ \t]+\n/g, "\n")
        output = output.replace(/\n{3,}/g, "\n\n")
        return output.trim()
    }

    function queueGeminiTyping() {
        const nextAnswer = cleanGeminiText(geminiAnswer)
        geminiCleanAnswer = nextAnswer

        if (nextAnswer.length <= 0) {
            resetGeminiTyping()
            return
        }

        if (geminiRevealIndex > nextAnswer.length)
            geminiRevealIndex = 0

        geminiVisibleAnswer = nextAnswer.substring(0, geminiRevealIndex)
        if (geminiRevealIndex < nextAnswer.length && !geminiTypingTimer.running)
            geminiTypingTimer.start()
    }

    function revealGeminiChunk() {
        if (geminiRevealIndex >= geminiCleanAnswer.length) {
            geminiVisibleAnswer = geminiCleanAnswer
            geminiTypingTimer.stop()
            return
        }

        const remaining = geminiCleanAnswer.length - geminiRevealIndex
        const total = geminiCleanAnswer.length
        let chunk = 5
        if (total > 6000 || remaining > 1800)
            chunk = 56
        else if (total > 3200 || remaining > 900)
            chunk = 34
        else if (remaining > 420)
            chunk = 18
        else if (remaining > 180)
            chunk = 10
        geminiRevealIndex = Math.min(geminiCleanAnswer.length, geminiRevealIndex + chunk)
        geminiVisibleAnswer = geminiCleanAnswer.substring(0, geminiRevealIndex)
    }

    function thinkingDots() {
        const dots = geminiThinkingFrame % 4
        if (dots === 1)
            return "."
        if (dots === 2)
            return ".."
        if (dots === 3)
            return "..."
        return ""
    }

    function loadGeminiHistory() {
        if (!popup || historyQuery.running)
            return

        geminiHistory = []
        historyQuery.command = [popup.geminiScript, "--history-list", "6"]
        historyQuery.running = true
    }

    function appendHistoryRecord(data) {
        const line = String(data || "").trim()
        if (line.length <= 0)
            return

        try {
            const record = JSON.parse(line)
            if (!record.question || !record.answer)
                return

            const next = geminiHistory.slice()
            next.push(record)
            geminiHistory = next
        } catch (error) {
        }
    }

    function showHistoryRecord(record) {
        if (!record)
            return

        resetGeminiTyping()
        geminiPendingPrompt = String(record.question || "")
        geminiAnswer = String(record.answer || "")
        geminiError = ""
        geminiLoading = false
        syncGeminiHoldOpen()
    }

    onGeminiConversationActiveChanged: syncGeminiHoldOpen()
    onGeminiAnswerChanged: queueGeminiTyping()

    Process {
        id: geminiQuery

        running: false
        command: [root.popup ? root.popup.geminiScript : "", "--plain", ""]

        stdout: SplitParser {
            onRead: function(data) {
                root.appendGeminiOutput(data)
            }
        }

        onExited: {
            running = false
            root.geminiLoading = false
            if (root.geminiAnswer.trim().length <= 0 && root.geminiError.trim().length <= 0)
                root.geminiError = "Gemini nao retornou resposta. Verifique ~/.config/velora-shell/gemini.env."
            root.loadGeminiHistory()
        }
    }

    Process {
        id: historyQuery

        running: false
        command: [root.popup ? root.popup.geminiScript : "", "--history-list", "6"]

        stdout: SplitParser {
            onRead: function(data) {
                root.appendHistoryRecord(data)
            }
        }

        onExited: {
            running = false
        }
    }

    Timer {
        id: geminiTypingTimer

        interval: 24
        repeat: true
        onTriggered: root.revealGeminiChunk()
    }

    Timer {
        interval: 230
        repeat: true
        running: root.geminiLoading
        onTriggered: root.geminiThinkingFrame = (root.geminiThinkingFrame + 1) % 24
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
        spacing: 14

        Text {
            Layout.fillWidth: true
            text: "Busca"
            color: root.popup ? root.popup.ink : "white"
            font.family: root.fontFamily
            font.pixelSize: 17
            font.weight: Font.Bold
            opacity: root.popup ? root.popup.popupIntroOpacity(25, 180) : 1
            transform: Translate { y: root.popup ? root.popup.popupIntroTranslateY(25, 5) : 0 }
        }

        SearchBox {
            id: searchBox

            Layout.fillWidth: true
            Layout.preferredHeight: 48
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

        SectionHeader {
            Layout.fillWidth: true
            Layout.topMargin: 2
            visible: root.popup && root.popup.searchQuery.trim().length <= 0
            iconText: "☼"
            title: "Mais usados"
            entryDelay: 245
        }

        SuggestionPanel {
            Layout.fillWidth: true
            Layout.preferredHeight: 154
            visible: root.popup && root.popup.searchQuery.trim().length <= 0
            popup: root.popup
            entryDelay: 410
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

    component SearchBox: Rectangle {
        id: box

        property var popup: null
        readonly property bool searchActiveFocus: input.activeFocus
        property bool pendingSelectText: true

        function forceSearchFocus(selectText) {
            if (!popup)
                return

            pendingSelectText = selectText !== false
            popup.forceActiveFocus(Qt.MouseFocusReason)
            input.forceActiveFocus(Qt.MouseFocusReason)
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
                    text: "Pesquisar apps, arquivos e comandos"
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

            ShortcutHint {
                text: "⌘"
            }

            ShortcutHint {
                text: "K"
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
                box.popup.forceActiveFocus(Qt.MouseFocusReason)
                input.forceActiveFocus(Qt.MouseFocusReason)
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

    component GeminiAskBox: Rectangle {
        id: box

        property var popup: null

        function forceGeminiFocus(selectText) {
            if (!popup)
                return

            popup.forceActiveFocus()
            input.forceActiveFocus()
            if (selectText !== false)
                input.selectAll()
        }

        radius: 22
        color: root.themedInputFill(popup, input.activeFocus || root.geminiLoading, true)
        border.width: 1
        border.color: root.themedInputBorder(popup, input.activeFocus, root.geminiLoading)
        opacity: root.popup ? root.popup.popupIntroOpacity(118, 190) : 1
        scale: root.popup ? root.popup.popupIntroScale(118, 0.98, 1) : 1
        transform: Translate { y: root.popup ? root.popup.popupIntroTranslateY(118, 8) : 0 }

        Behavior on border.color { ColorAnimation { duration: root.popup ? root.popup.motionHover : 120 } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: root.accent
            opacity: root.geminiLoading ? (0.12 + (root.geminiThinkingFrame % 3) * 0.08) : 0

            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 10
            spacing: 10

            VeloraPopupIcon {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                popup: box.popup
                iconName: "spark"
                lineColor: root.accent
                scale: root.geminiLoading ? (root.geminiThinkingFrame % 2 === 0 ? 1.08 : 0.94) : 1

                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text.length <= 0
                    text: "Pergunte alguma coisa ao Gemini"
                    color: root.popup ? root.popup.alpha(root.popup.ink, 0.58) : Qt.rgba(1, 1, 1, 0.58)
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                TextInput {
                    id: input

                    anchors.fill: parent
                    text: root.geminiPrompt
                    color: root.popup ? root.popup.ink : "white"
                    selectedTextColor: root.popup && root.popup.theme ? root.popup.theme.activeText : "white"
                    selectionColor: root.accent
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    onTextEdited: root.geminiPrompt = text
                    Keys.onReturnPressed: root.askGemini()
                    Keys.onEnterPressed: root.askGemini()
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                            root.focusSearchInput(false)
                            event.accepted = true
                            return
                        }
                        if (event.key === Qt.Key_Escape && root.popup) {
                            root.popup.closeRequested()
                            event.accepted = true
                        }
                    }
                }
            }

            ShortcutHint { text: "Abc" }

            Text {
                Layout.preferredWidth: 24
                Layout.fillHeight: true
                text: root.geminiLoading ? root.thinkingDots() : "↵"
                color: root.popup ? root.popup.alpha(root.popup.ink, 0.72) : Qt.rgba(1, 1, 1, 0.72)
                font.family: root.fontFamily
                font.pixelSize: 16
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: root.geminiLoading ? 0.62 + (root.geminiThinkingFrame % 3) * 0.12 : 1
                scale: root.geminiLoading ? 0.92 + (root.geminiThinkingFrame % 3) * 0.05 : 1

                Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            VeloraPopupIcon {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                popup: box.popup
                iconName: "volume"
                lineColor: root.popup ? root.popup.alpha(root.popup.ink, 0.70) : "white"
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.IBeamCursor
            onClicked: {
                if (root.popup)
                    root.popup.forceActiveFocus()
                input.forceActiveFocus()
            }
        }
    }

    component GeminiHistoryPanel: Rectangle {
        id: panel

        property var popup: null

        radius: 14
        color: popup ? popup.alpha(popup.winCardHover, 0.22) : Qt.rgba(1, 1, 1, 0.08)
        border.width: 1
        border.color: popup ? popup.alpha(root.accent, 0.16) : Qt.rgba(1, 1, 1, 0.10)
        clip: true
        opacity: root.popup ? root.popup.popupIntroOpacity(132, 180) : 1
        scale: root.popup ? root.popup.popupIntroScale(132, 0.985, 1) : 1
        transform: Translate { y: root.popup ? root.popup.popupIntroTranslateY(132, 7) : 0 }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                spacing: 8

                VeloraPopupIcon {
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    popup: panel.popup
                    iconName: "memo"
                    lineColor: root.accent
                }

                Text {
                    Layout.fillWidth: true
                    text: "Histórico Gemini"
                    color: root.popup ? root.popup.alpha(root.popup.ink, 0.70) : Qt.rgba(1, 1, 1, 0.70)
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: historyRows.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: historyRows

                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root.geminiHistory

                        Item {
                            id: historyRow

                            property bool hovered: false
                            property var record: modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: 58

                            Rectangle {
                                anchors.fill: parent
                                radius: 9
                                color: historyRow.hovered ? root.rowFillHover : "transparent"
                                border.width: historyRow.hovered ? 1 : 0
                                border.color: root.lineSoft
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                anchors.topMargin: 4
                                anchors.bottomMargin: 4
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: historyRow.record ? String(historyRow.record.question || "") : ""
                                    color: root.popup ? root.popup.alpha(root.popup.ink, 0.78) : Qt.rgba(1, 1, 1, 0.78)
                                    font.family: root.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    text: historyRow.record ? root.cleanGeminiText(String(historyRow.record.answer || "")).replace(/\n/g, " ") : ""
                                    color: root.popup ? root.popup.alpha(root.popup.ink, 0.52) : Qt.rgba(1, 1, 1, 0.52)
                                    font.family: root.fontFamily
                                    font.pixelSize: 9
                                    font.weight: Font.Medium
                                    wrapMode: Text.Wrap
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: historyRow.hovered = true
                                onExited: historyRow.hovered = false
                                onClicked: root.showHistoryRecord(historyRow.record)
                            }
                        }
                    }
                }
            }
        }
    }

    component GeminiAnswerPanel: Rectangle {
        id: panel

        property var popup: null

        radius: 14
        color: "transparent"
        border.width: 0
        border.color: "transparent"
        clip: true
        opacity: root.popup ? root.popup.popupIntroOpacity(128, 180) : 1
        scale: root.popup ? root.popup.popupIntroScale(128, 0.985, 1) : 1
        transform: Translate { y: root.popup ? root.popup.popupIntroTranslateY(128, 8) : 0 }

        Behavior on border.color { ColorAnimation { duration: 170; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 0
            border.color: root.accent
            opacity: 0

            Behavior on opacity { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                spacing: 8

                VeloraPopupIcon {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    popup: panel.popup
                    iconName: "spark"
                    lineColor: root.geminiError.length > 0 ? Qt.rgba(1, 0.45, 0.45, 0.92) : root.accent
                    scale: root.geminiLoading ? (root.geminiThinkingFrame % 2 === 0 ? 1.10 : 0.95) : 1

                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.geminiPendingPrompt.length > 0 ? root.geminiPendingPrompt : "Gemini"
                    color: root.popup ? root.popup.alpha(root.popup.ink, 0.74) : Qt.rgba(1, 1, 1, 0.74)
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Row {
                    visible: root.geminiLoading
                    spacing: 4

                    Repeater {
                        model: 3

                        Rectangle {
                            width: 5
                            height: 5
                            radius: 3
                            color: root.accent
                            opacity: (root.geminiThinkingFrame + index) % 3 === 0 ? 0.95 : 0.30
                            scale: (root.geminiThinkingFrame + index) % 3 === 0 ? 1.25 : 0.72
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            Flickable {
                id: answerFlick

                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: answerContent.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                onContentHeightChanged: {
                    if (root.geminiLoading || root.geminiAnswerTyping)
                        answerScrollTimer.restart()
                }

                Timer {
                    id: answerScrollTimer

                    interval: 42
                    repeat: false
                    onTriggered: answerFlick.contentY = Math.max(0, answerFlick.contentHeight - answerFlick.height)
                }

                Column {
                    id: answerContent
                    width: parent.width
                    spacing: 10

                    Item {
                        width: parent.width
                        height: visible ? 42 : 0
                        visible: root.geminiLoading && root.geminiVisibleAnswer.length <= 0

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 2
                            anchors.rightMargin: 2
                            spacing: 10

                            Row {
                                Layout.preferredWidth: 30
                                Layout.preferredHeight: 18
                                spacing: 4

                                Repeater {
                                    model: 3

                                    Rectangle {
                                        width: 6
                                        height: 6
                                        radius: 3
                                        color: root.accent
                                        opacity: (root.geminiThinkingFrame + index) % 3 === 0 ? 1 : 0.28
                                        scale: (root.geminiThinkingFrame + index) % 3 === 0 ? 1.24 : 0.72
                                        anchors.verticalCenter: parent.verticalCenter

                                        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Pensando" + root.thinkingDots()
                                color: root.popup ? root.popup.alpha(root.popup.ink, 0.72) : Qt.rgba(1, 1, 1, 0.72)
                                font.family: root.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }
                        }
                    }

                    GeminiMagicText {
                        id: answerText

                        width: parent.width
                        text: {
                            if (root.geminiAnswer.length > 0)
                                return root.geminiVisibleAnswer
                            if (root.geminiLoading)
                                return ""
                            return root.geminiError
                        }
                        textColor: root.geminiError.length > 0 && root.geminiAnswer.length <= 0
                            ? Qt.rgba(1, 0.55, 0.55, 0.92)
                            : (root.popup ? root.popup.alpha(root.popup.ink, 0.82) : Qt.rgba(1, 1, 1, 0.82))
                        glowColor: root.accent
                        fontFamilyName: root.fontFamily
                        fontPixelSize: 12
                        fontWeight: "500"
                        lineHeight: 1.18
                        animated: root.geminiAnswerTyping
                        fade: 1
                    }
                }
            }
        }
    }

    component GeminiMagicText: Text {
        id: magicText

        property color textColor: Qt.rgba(1, 1, 1, 0.82)
        property color glowColor: root.accent
        property string fontFamilyName: root.fontFamily
        property string fontWeight: "500"
        property int fontPixelSize: 12
        property bool animated: false
        property real fade: 1
        property int letterFrame: 0

        height: Math.max(1, implicitHeight)
        color: textColor
        opacity: fade
        font.family: fontFamilyName
        font.pixelSize: fontPixelSize
        font.weight: fontWeight === "700" ? Font.Bold : Font.Medium
        lineHeightMode: Text.ProportionalHeight
        renderType: Text.NativeRendering
        textFormat: Text.PlainText
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
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
