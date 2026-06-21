import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "popups"

Item {
    id: root

    property var theme: null
    property bool open: false
    property bool autoFocus: false
    property bool embeddedInFrame: false
    property color panelGlass: theme ? theme.surfacePopup : Qt.rgba(0.015, 0.09, 0.12, 0.82)
    property color panelLine: theme ? theme.borderSoft : Qt.rgba(1, 1, 1, 0.13)
    property int focusRequest: 0
    property string geminiScript: Quickshell.shellDir + "/scripts/velora-gemini-ask"
    property string geminiPrompt: ""
    property string geminiPendingPrompt: ""
    property string geminiAnswer: ""
    property string geminiError: ""
    property string geminiCleanAnswer: ""
    property string geminiVisibleAnswer: ""
    property int geminiRevealIndex: 0
    property int geminiThinkingFrame: 0
    property bool geminiLoading: false
    readonly property bool conversationActive: geminiLoading || geminiAnswer.trim().length > 0 || geminiError.trim().length > 0
    readonly property bool geminiAnswerTyping: geminiCleanAnswer.length > 0 && geminiVisibleAnswer.length < geminiCleanAnswer.length
    readonly property string uiFont: theme ? theme.uiFont : "Noto Sans"
    readonly property color accent: theme ? theme.accentPrimary : Qt.rgba(0.10, 0.70, 0.94, 1)
    readonly property color accentSoft: theme ? theme.alpha(theme.accentPrimary, 0.42) : Qt.rgba(0.10, 0.70, 0.94, 0.42)
    readonly property color ink: theme ? theme.textPrimary : Qt.rgba(0.95, 0.97, 0.98, 0.94)
    readonly property color inkSoft: theme ? theme.textSecondary : Qt.rgba(0.82, 0.86, 0.90, 0.68)
    readonly property color glass: panelGlass.a > 0.001 ? panelGlass : (theme ? theme.alpha(theme.surfacePopup, theme.themeMode === "dark" ? 0.80 : 0.70) : Qt.rgba(0.015, 0.09, 0.12, 0.82))
    readonly property color inputGlass: theme
        ? theme.withAlpha(theme.surfaceInput, theme.themeMode === "dark" ? Math.max(0.68, Math.min(0.90, theme.surfaceInput.a + 0.14)) : Math.max(0.62, Math.min(0.82, theme.surfaceInput.a + 0.06)))
        : Qt.rgba(0.012, 0.018, 0.026, 0.78)
    readonly property color line: panelLine.a > 0.001 ? panelLine : (theme ? theme.alpha(theme.borderSoft, theme.themeMode === "dark" ? 0.20 : 0.28) : Qt.rgba(1, 1, 1, 0.13))

    signal closeRequested()
    signal activated()
    signal pointerInsideChanged(bool inside)

    clip: true

    function forcePromptFocus(selectText) {
        root.activated()
        root.forceActiveFocus()
        promptInput.forceActiveFocus()
        if (selectText !== false)
            promptInput.selectAll()
    }

    function askGemini() {
        const prompt = geminiPrompt.trim()
        if (prompt.length <= 0)
            return

        if (geminiQuery.running)
            geminiQuery.running = false

        resetGeminiTyping()
        geminiPendingPrompt = prompt
        geminiAnswer = ""
        geminiError = ""
        geminiLoading = true
        geminiQuery.command = [geminiScript, "--plain", prompt]
        geminiQuery.running = true
        geminiPrompt = ""
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

    function clearConversation() {
        if (geminiQuery.running)
            geminiQuery.running = false
        geminiLoading = false
        geminiPendingPrompt = ""
        geminiAnswer = ""
        geminiError = ""
        resetGeminiTyping()
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

    onGeminiAnswerChanged: queueGeminiTyping()
    onOpenChanged: {
        if (open && autoFocus)
            focusTimer.restart()
    }
    onFocusRequestChanged: if (open && autoFocus) focusTimer.restart()

    HoverHandler {
        onHoveredChanged: root.pointerInsideChanged(hovered)
    }

    Process {
        id: geminiQuery

        running: false
        command: [root.geminiScript, "--plain", ""]

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
        id: focusTimer

        interval: 55
        repeat: false
        onTriggered: root.forcePromptFocus(false)
    }

    Keys.onEscapePressed: root.closeRequested()

    Rectangle {
        id: panel

        anchors.fill: parent
        radius: 24
        color: root.embeddedInFrame ? "transparent" : root.glass
        border.width: root.embeddedInFrame ? 0 : 1
        border.color: root.line
        antialiasing: true
        clip: true

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            visible: !root.embeddedInFrame
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.030)
            antialiasing: true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 72
            anchors.rightMargin: 72
            anchors.topMargin: 18
            anchors.bottomMargin: 12
            spacing: 10

            Text {
                Layout.fillWidth: true
                text: "No que você está pensando hoje?"
                color: root.inkSoft
                font.family: root.uiFont
                font.pixelSize: 18
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Rectangle {
                id: promptBar

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(506, parent.width)
                Layout.preferredHeight: 44
                radius: 24
                color: root.inputGlass
                border.width: 1
                border.color: promptInput.activeFocus ? root.accentSoft : Qt.rgba(1, 1, 1, 0.09)
                antialiasing: true

                Behavior on border.color {
                    ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 13
                    spacing: 12

                    VeloraPopupIcon {
                        Layout.preferredWidth: 19
                        Layout.preferredHeight: 19
                        iconName: "search"
                        lineColor: root.inkSoft
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: promptInput.text.length <= 0
                            text: "Pergunte alguma coisa"
                            color: Qt.rgba(root.inkSoft.r, root.inkSoft.g, root.inkSoft.b, 0.70)
                            font.family: root.uiFont
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        TextInput {
                            id: promptInput

                            anchors.fill: parent
                            text: root.geminiPrompt
                            color: root.ink
                            selectedTextColor: root.theme ? root.theme.activeText : "white"
                            selectionColor: root.accent
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            font.family: root.uiFont
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            onTextEdited: root.geminiPrompt = text
                            onActiveFocusChanged: if (activeFocus) root.activated()
                            Keys.onReturnPressed: root.askGemini()
                            Keys.onEnterPressed: root.askGemini()
                            Keys.onEscapePressed: root.closeRequested()
                        }
                    }

                    Text {
                        Layout.preferredWidth: 34
                        text: "Abc"
                        color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.66)
                        font.family: root.uiFont
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        Layout.preferredWidth: 18
                        text: root.geminiLoading ? root.thinkingDots() : "↗"
                        color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.72)
                        font.family: root.uiFont
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    VeloraPopupIcon {
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        iconName: "volume"
                        lineColor: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.68)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.IBeamCursor
                    onClicked: {
                        mouse.accepted = true
                        root.forcePromptFocus()
                    }
                }
            }

            Rectangle {
                id: answerPanel

                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.conversationActive
                radius: 16
                color: Qt.rgba(0.015, 0.025, 0.034, 0.42)
                border.width: 1
                border.color: root.geminiError.length > 0 ? Qt.rgba(1, 0.45, 0.45, 0.36) : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.20)
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 22
                        spacing: 8

                        VeloraPopupIcon {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            iconName: "spark"
                            lineColor: root.geminiError.length > 0 ? Qt.rgba(1, 0.45, 0.45, 0.92) : root.accent
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.geminiPendingPrompt.length > 0 ? root.geminiPendingPrompt : "Gemini"
                            color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.80)
                            font.family: root.uiFont
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "Limpar"
                            color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.56)
                            font.family: root.uiFont
                            font.pixelSize: 11
                            font.weight: Font.Bold

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.clearConversation()
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

                            Text {
                                width: parent.width
                                visible: root.geminiLoading && root.geminiVisibleAnswer.length <= 0
                                text: "Pensando" + root.thinkingDots()
                                color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.72)
                                font.family: root.uiFont
                                font.pixelSize: 13
                                font.weight: Font.Bold
                            }

                            Text {
                                width: parent.width
                                text: {
                                    if (root.geminiAnswer.length > 0)
                                        return root.geminiVisibleAnswer
                                    if (root.geminiLoading)
                                        return ""
                                    return root.geminiError
                                }
                                color: root.geminiError.length > 0 && root.geminiAnswer.length <= 0
                                    ? Qt.rgba(1, 0.55, 0.55, 0.92)
                                    : Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.82)
                                font.family: root.uiFont
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                lineHeightMode: Text.ProportionalHeight
                                lineHeight: 1.18
                                textFormat: Text.PlainText
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            }
                        }
                    }
                }
            }
        }
    }
}
