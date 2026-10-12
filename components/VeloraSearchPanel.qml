pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../features/topbar" as TopBar

FocusScope {
    id: root
    required property var theme
    property bool open: false
    property real entrance: 0
    property var results: []
    property var usage: ({})
    readonly property string usageHelper: Quickshell.shellDir + "/scripts/velora-app-usage"
    property string category: "all"
    property int selectedIndex: 0
    signal closeRequested()
    signal pointerInsideChanged(bool inside)
    signal settingsRequested()
    readonly property bool interactionHeld: open
    function requestSearchFocus() { input.forceActiveFocus() }
    function normalized(value) { return String(value || "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase() }
    function record(entry) { return usage[String(entry.id || entry.name)] || {count:0, lastUsed:0} }
    function refresh() {
        const query = normalized(input.text.trim())
        const words = query.split(/\s+/).filter(Boolean)
        const items = (DesktopEntries.applications.values || []).filter(entry => {
            if (!entry || entry.noDisplay) return false
            const categories = String(entry.categories || "")
            if (category !== "all" && !categories.includes(category)) return false
            const text = normalized([entry.name, entry.genericName, entry.comment, entry.keywords, entry.id].join(" "))
            return words.every(word => text.includes(word))
        })
        items.sort((a,b) => {
            const score = entry => normalized(entry.name) === query ? 3 : normalized(entry.name).startsWith(query) ? 2 : 1
            return (query ? score(b) - score(a) : 0) || Number(record(b).count) - Number(record(a).count) || Number(record(b).lastUsed) - Number(record(a).lastUsed) || String(a.name).localeCompare(String(b.name))
        })
        results = items.slice(0, 40)
        selectedIndex = 0
        list.positionViewAtBeginning()
    }
    function step(amount) {
        if (!results.length) return
        selectedIndex = (selectedIndex + amount + results.length) % results.length
        list.positionViewAtIndex(selectedIndex, ListView.Contain)
    }
    function launch(index) {
        if (queryDelay.running) { queryDelay.stop(); refresh(); index = selectedIndex }
        if (index < 0 || index >= results.length) return
        Quickshell.execDetached([usageHelper, "record", String(results[index].id || results[index].name)])
        results[index].execute()
        closeRequested()
    }
    function webSearch() {
        if (!input.text.trim()) return
        Qt.openUrlExternally("https://www.google.com/search?q=" + encodeURIComponent(input.text.trim()))
        closeRequested()
    }
    function updateOpen() {
        entrance = open ? 1 : 0
        if (open) Qt.callLater(requestSearchFocus)
    }
    onOpenChanged: updateOpen()
    onCategoryChanged: refresh()
    Component.onCompleted: { usageRead.running = true; refresh(); Qt.callLater(updateOpen) }
    Behavior on entrance { NumberAnimation { duration: root.open ? 520 : 180; easing.type: root.open ? Easing.OutCubic : Easing.InCubic } }
    HoverHandler { onHoveredChanged: root.pointerInsideChanged(hovered) }
    Connections { target: DesktopEntries.applications; function onValuesChanged() { root.refresh() } }
    Process {
        id: usageRead
        command: [root.usageHelper, "list", "1000"]
        stdout: StdioCollector {
            onStreamFinished: {
                const next = {}
                for (const line of text.trim().split("\n")) {
                    try { const record = JSON.parse(line); next[record.id] = record } catch (e) {}
                }
                root.usage = next
                root.refresh()
            }
        }
    }
    Timer { id: queryDelay; interval: 65; onTriggered: root.refresh() }
    Keys.onEscapePressed: root.closeRequested()
    Keys.onDownPressed: root.step(1)
    Keys.onUpPressed: root.step(-1)
    Keys.onReturnPressed: event => { if (event.modifiers & Qt.ControlModifier) root.webSearch(); else root.launch(root.selectedIndex) }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 24
        spacing: 13
        opacity: Math.min(1, root.entrance * 1.8)
        transform: Translate { y: (1 - root.entrance) * 22 }
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Buscar"; color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 20; font.weight: Font.DemiBold; Layout.fillWidth: true }
            Text { text: "SUPER W"; color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 10; font.letterSpacing: 1 }
            TopBar.BarAction { theme: root.theme; text: "Esc"; onClicked: root.closeRequested() }
        }
        Rectangle {
            Layout.fillWidth: true; implicitHeight: 52; radius: 15
            color: root.theme.withAlpha(root.theme.textPrimary, 0.07)
            border.width: 1; border.color: root.theme.withAlpha(root.theme.accent, 0.55)
            scale: .97 + .03 * root.entrance
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 12; spacing: 12
                TopBar.BarIcon { name: "search"; color: root.theme.textPrimary }
                TextField {
                    id: input
                    objectName: "launcherQuery"
                    Layout.fillWidth: true
                    placeholderText: "Aplicativos, ferramentas, ideias…"
                    color: root.theme.textPrimary; placeholderTextColor: root.theme.textSecondary
                    selectionColor: root.theme.accent; selectedTextColor: root.theme.wallpaperSurfaceTone
                    font.family: root.theme.bodyFont; font.pixelSize: 14
                    background: Item {}
                    selectByMouse: true
                    onTextChanged: queryDelay.restart()
                    Keys.onEscapePressed: root.closeRequested()
                    Keys.onDownPressed: root.step(1)
                    Keys.onUpPressed: root.step(-1)
                    Keys.onReturnPressed: event => { if (event.modifiers & Qt.ControlModifier) root.webSearch(); else root.launch(root.selectedIndex) }
                }
                TopBar.BarAction { theme: root.theme; text: "×"; visible: input.text.length > 0; onClicked: { input.clear(); input.forceActiveFocus() } }
            }
        }
        Row {
            spacing: 6
            opacity: Math.max(0, Math.min(1, (root.entrance - .18) / .6))
            Repeater {
                model: [{key:"all",label:"Tudo"},{key:"Network",label:"Internet"},{key:"AudioVideo",label:"Mídia"},{key:"Utility",label:"Utilitários"}]
                TopBar.BarAction {
                    required property var modelData
                    theme: root.theme; text: modelData.label
                    highlighted: root.category === modelData.key
                    onClicked: { root.category = modelData.key; input.forceActiveFocus() }
                }
            }
        }
        Text {
            text: input.text.trim() ? "RESULTADOS" : "MAIS USADOS"
            color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 9; font.letterSpacing: 1
            opacity: Math.max(0, Math.min(1, (root.entrance - .15) / .65))
        }
        ListView {
            id: list
            objectName: "launcherResults"
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; spacing: 4; model: root.results
            currentIndex: root.selectedIndex
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 170
            highlightResizeDuration: 170
            highlight: Rectangle { radius: 12; color: root.theme.withAlpha(root.theme.textPrimary, .10); border.width: 1; border.color: root.theme.borderSubtle }
            delegate: Item {
                id: row
                required property var modelData
                required property int index
                width: list.width; height: 48
                property real arrival: 0
                opacity: arrival * Math.max(0, Math.min(1, (root.entrance - .2) / .65))
                transform: Translate { x: (1 - row.arrival) * 20; y: (1 - root.entrance) * (8 + row.index * 3) }
                Component.onCompleted: arrivalAnimation.start()
                SequentialAnimation {
                    id: arrivalAnimation
                    PauseAnimation { duration: Math.min(row.index, 7) * 22 }
                    NumberAnimation { target: row; property: "arrival"; to: 1; duration: 250; easing.type: Easing.OutCubic }
                }
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 13; spacing: 12
                    Image { source: Quickshell.iconPath(row.modelData.icon || "application-x-executable", true); sourceSize.width: 28; sourceSize.height: 28; Layout.preferredWidth: 28; Layout.preferredHeight: 28; fillMode: Image.PreserveAspectFit }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        Text { Layout.fillWidth: true; text: row.modelData.name; color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 12; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; text: row.modelData.genericName || row.modelData.comment || "Aplicativo"; color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 10; elide: Text.ElideRight }
                    }
                    Text { text: "↵"; opacity: root.selectedIndex === row.index ? .8 : 0; color: root.theme.textPrimary; font.pixelSize: 17; Behavior on opacity { NumberAnimation { duration: 130 } } }
                }
                MouseArea { anchors.fill: parent; hoverEnabled: true; onPositionChanged: root.selectedIndex = row.index; onClicked: root.launch(row.index) }
            }
            Column {
                anchors.centerIn: parent; spacing: 8; visible: !root.results.length
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Nenhum aplicativo encontrado"; color: root.theme.textPrimary; font.pixelSize: 14 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Ctrl + Enter para pesquisar na web"; color: root.theme.textSecondary; font.pixelSize: 11 }
            }
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: root.theme.borderSubtle }
        RowLayout {
            Layout.fillWidth: true
            TopBar.BarAction { theme: root.theme; text: "Arquivos"; onClicked: { Qt.openUrlExternally("file://" + Quickshell.env("HOME")); root.closeRequested() } }
            TopBar.BarAction { theme: root.theme; text: "Configurações"; onClicked: { root.closeRequested(); root.settingsRequested() } }
            Item { Layout.fillWidth: true }
            Text { text: "↑ ↓  navegar     ↵  abrir"; color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 10 }
        }
    }
}
