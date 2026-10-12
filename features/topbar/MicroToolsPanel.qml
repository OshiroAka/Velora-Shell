import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Loader {
    id: root
    required property string type
    required property var theme
    required property var system
    required property var controller
    required property var actions
    readonly property bool interactionHeld: item ? item.popupOpen === true : false
    sourceComponent: ({cat: catPanel, caffeine: caffeinePanel, usb: usbPanel, thing: thingPanel,
        notes: notesPanel, search: searchPanel, controls: controlsPanel})[type] || null
    component Label: Text {
        color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 12
        elide: Text.ElideRight
    }
    component Detail: Label { color: root.theme.textSecondary; font.pixelSize: 11; wrapMode: Text.WordWrap }
    component Heading: Label { font.pixelSize: 16; font.weight: Font.DemiBold }
    component Field: TextField {
        Layout.fillWidth: true; implicitHeight: 36
        color: root.theme.textPrimary; placeholderTextColor: root.theme.textMuted
        font.family: root.theme.bodyFont; font.pixelSize: 12; selectByMouse: true
        background: Rectangle { radius: 8; color: root.theme.withAlpha(root.theme.textPrimary,0.04); border.width: 1; border.color: parent.activeFocus ? root.theme.accentSoft : root.theme.borderSubtle }
    }
    Component {
        id: catPanel
        ColumnLayout {
            spacing: 10
            RowLayout {
                Layout.fillWidth: true
                RunCatIcon { width: 42; height: 28; color: root.theme.textPrimary; cpuUsage: root.system.cpuUsage; animate: root.system.enabled && root.system.catAnimation }
                Heading { text: "RunCat"; Layout.fillWidth: true }
                Heading { text: root.system.cpuUsage >= 0 ? Math.round(root.system.cpuUsage)+"%" : "—" }
            }
            Detail { Layout.fillWidth: true; text: "O gato acompanha o uso real da CPU." }
            BarAction { Layout.fillWidth: true; theme: root.theme; text: root.system.catAnimation ? "Pausar animação" : "Animar"; onClicked: root.system.catAnimation=!root.system.catAnimation }
            Item { Layout.fillHeight: true }
        }
    }
    Component {
        id: caffeinePanel
        ColumnLayout {
            spacing: 10
            RowLayout {
                Layout.fillWidth: true
                CoffeeIcon { width: 27; height: 25; color: root.theme.textPrimary; active: root.system.caffeineActive; animate: root.system.enabled }
                Heading { text: "Manter acordado"; Layout.fillWidth: true }
            }
            Detail {
                Layout.fillWidth: true
                text: root.system.caffeineActive ? root.system.caffeineUntil > 0
                    ? "Ativo · " + Math.max(0,Math.ceil((root.system.caffeineUntil-root.system.now)/60000)) + " min restantes"
                    : "Ativo por tempo indeterminado" : "Impedir suspensão automática durante o trabalho."
            }
            GridLayout {
                Layout.fillWidth: true; columns: 3
                Repeater {
                    model: [5,15,30,60,120,0]
                    BarAction {
                        required property int modelData
                        Layout.fillWidth: true; theme: root.theme
                        text: modelData === 0 ? "∞" : modelData < 60 ? modelData+" min" : modelData/60+" h"
                        Accessible.name: modelData === 0 ? "Manter acordado sem limite" : "Manter acordado por " + modelData + " minutos"
                        enabled: root.system.capabilities.inhibit === true
                        onClicked: root.system.keepAwake(modelData)
                    }
                }
            }
            BarAction { Layout.fillWidth: true; theme: root.theme; text: "Desativar"; enabled: root.system.caffeineActive; onClicked: root.system.stopAwake() }
            Detail { Layout.fillWidth: true; visible: !root.system.capabilities.inhibit; text: "Inibição de suspensão indisponível." }
            Detail { Layout.fillWidth: true; text: root.system.error; visible: text.length > 0; color: root.theme.warning }
            Item { Layout.fillHeight: true }
        }
    }
    Component {
        id: usbPanel
        ColumnLayout {
            spacing: 10
            RowLayout { Layout.fillWidth: true; Heading { text: "USB Status"; Layout.fillWidth: true } Detail { text: (root.system.usb.devices || []).length + " dispositivos" } }
            Field { id: usbSearch; placeholderText: "Filtrar dispositivos…"; Accessible.name: "Filtrar dispositivos USB" }
            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 8
                model: (root.system.usb.devices || []).filter(d => (d.name+" "+d.vendor).toLowerCase().includes(usbSearch.text.toLowerCase()))
                delegate: ColumnLayout {
                    required property var modelData
                    width: ListView.view.width; spacing: 4
                    RowLayout {
                        Layout.fillWidth: true
                        BarIcon { name: "usb"; width: 18; height: 22; color: root.theme.textPrimary }
                        Label { Layout.fillWidth: true; text: modelData.name; font.weight: Font.DemiBold }
                        Detail { text: modelData.version.startsWith("Thunderbolt") ? modelData.version : "USB " + modelData.version }
                    }
                    Detail { Layout.fillWidth: true; text: [modelData.vendor, modelData.speed ? modelData.speed+" Mb/s" : "", modelData.power].filter(Boolean).join(" · ") }
                    Detail { Layout.fillWidth: true; text: "Porta " + modelData.id + (modelData.serial ? " · SN " + modelData.serial : "") }
                    Rectangle { Layout.fillWidth: true; height: 1; color: root.theme.borderSubtle }
                }
                Detail { anchors.centerIn: parent; visible: parent.count===0; text: root.system.usb.available ? "Nenhum dispositivo encontrado" : "Dados USB indisponíveis" }
                ScrollBar.vertical: ScrollBar {}
            }
        }
    }
    Component {
        id: thingPanel
        ColumnLayout {
            spacing: 10
            Heading { text: "One Thing" }
            Field {
                text: root.system.oneThing; placeholderText: "What is the one thing?"
                maximumLength: 200; Accessible.name: "Texto fixo na barra"
                onTextEdited: root.system.oneThing=text
            }
            Detail { Layout.fillWidth: true; text: root.system.saveError || (root.system.saving ? "Salvando…" : "Seu foco permanece visível na barra. Salvo automaticamente.") }
            Item { Layout.fillHeight: true }
        }
    }
    Component {
        id: notesPanel
        ColumnLayout {
            id: notesPage
            readonly property bool popupOpen: noteSelector.popup.visible
            property bool confirming: false
            readonly property var note: root.system.notes.find(n => n.id === root.system.selectedNote) || null
            onNoteChanged: noteEditor.loadNote()
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                Heading { text: "Notas"; Layout.fillWidth: true }
                BarAction { theme: root.theme; text: "+"; Accessible.name: "Nova nota"; onClicked: { root.system.newNote(); notesPage.confirming=false } }
                BarAction { theme: root.theme; text: "Fixar"; enabled: !!notesPage.note; highlighted: !!notesPage.note && notesPage.note.pinned; onClicked: root.system.pinNote(root.system.selectedNote) }
                BarAction { theme: root.theme; text: "×"; Accessible.name: "Excluir nota"; enabled: !!notesPage.note; onClicked: notesPage.confirming=!notesPage.confirming }
            }
            ComboBox {
                id: noteSelector
                Layout.fillWidth: true; visible: root.system.notes.length > 1
                model: root.system.notes.slice().sort((a,b) => Number(b.pinned)-Number(a.pinned))
                textRole: "text"
                displayText: notesPage.note ? (notesPage.note.pinned ? "● " : "") + (notesPage.note.text.split("\n")[0] || "Nova nota") : "Escolher nota"
                onActivated: index => { root.system.selectedNote=model[index].id; notesPage.confirming=false }
                Accessible.name: "Escolher nota salva"
                contentItem: Label { text: parent.displayText; verticalAlignment: Text.AlignVCenter; leftPadding: 10; rightPadding: 24 }
                background: Rectangle { radius: 8; color: root.theme.surfaceSoft; border.color: root.theme.borderSubtle }
                delegate: ItemDelegate { required property var modelData; width: parent.width; text: (modelData.pinned ? "● " : "") + (modelData.text.split("\n")[0] || "Nova nota") }
            }
            RowLayout {
                visible: notesPage.confirming; Layout.fillWidth: true
                Detail { text: "Excluir esta nota?"; Layout.fillWidth: true }
                BarAction { theme: root.theme; text: "Excluir"; destructive: true; onClicked: { root.system.deleteNote(root.system.selectedNote); notesPage.confirming=false } }
                BarAction { theme: root.theme; text: "Cancelar"; onClicked: notesPage.confirming=false }
            }
            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true
                TextArea {
                    id: noteEditor
                    objectName: "topbarNoteEditor"
                    property bool synchronizing: false
                    function loadNote() {
                        const value = notesPage.note ? notesPage.note.text : ""
                        if (text === value) return
                        synchronizing = true
                        text = value
                        synchronizing = false
                    }
                    Component.onCompleted: loadNote()
                    placeholderText: "Type your note…"; placeholderTextColor: root.theme.textMuted
                    color: root.theme.textPrimary; selectionColor: root.theme.accent
                    font.family: root.theme.bodyFont; font.pixelSize: 13
                    wrapMode: TextEdit.Wrap; selectByMouse: true
                    Accessible.name: "Conteúdo da nota"
                    background: Rectangle { radius: 10; color: root.theme.withAlpha(root.theme.textPrimary,0.025) }
                    onTextChanged: {
                        if (activeFocus && !synchronizing) {
                            const value = text
                            if (!notesPage.note) root.system.newNote(value)
                            else if (value !== notesPage.note.text) root.system.editNote(notesPage.note.id, value)
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                BarAction { theme: root.theme; text: "• Lista"; onClicked: { noteEditor.forceActiveFocus(); noteEditor.insert(noteEditor.cursorPosition, "\n• ") } }
                BarAction { theme: root.theme; text: "☐ To-do"; onClicked: { noteEditor.forceActiveFocus(); noteEditor.insert(noteEditor.cursorPosition, "\n☐ ") } }
                Detail { Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; text: root.system.saveError || (root.system.saving ? "Salvando…" : "Salvo localmente") }
            }
        }
    }
    Component {
        id: searchPanel
        ColumnLayout {
            spacing: 10
            Heading { text: "Buscar" }
            Field {
                id: search; placeholderText: "Aplicativos…"; Accessible.name: "Buscar aplicativos"
                onTextEdited: results.currentIndex=0
                Keys.onDownPressed: results.currentIndex=Math.min(results.count-1,results.currentIndex+1)
                Keys.onUpPressed: results.currentIndex=Math.max(0,results.currentIndex-1)
                onAccepted: if(results.currentItem) results.currentItem.launch()
            }
            ListView {
                id: results
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 4
                model: DesktopEntries.applications.values.filter(app => !app.noDisplay && (app.name+" "+app.genericName).toLowerCase().includes(search.text.toLowerCase())).sort((a,b)=>a.name.localeCompare(b.name)).slice(0,40)
                currentIndex: 0
                delegate: BarAction {
                    required property var modelData
                    required property int index
                    width: ListView.view.width; theme: root.theme; text: modelData.name
                    highlighted: ListView.isCurrentItem
                    function launch() { modelData.execute(); root.controller.close() }
                    onClicked: launch()
                }
                Detail { anchors.centerIn: parent; visible: parent.count===0; text: "Nenhum aplicativo encontrado" }
                ScrollBar.vertical: ScrollBar {}
            }
        }
    }
    Component {
        id: controlsPanel
        ColumnLayout {
            spacing: 10
            Heading { text: "Controles" }
            BarAction { Layout.fillWidth: true; theme: root.theme; text: root.system.caffeineActive ? "Manter acordado · ativo" : "Manter acordado"; highlighted: root.system.caffeineActive; onClicked: root.system.caffeineActive ? root.system.stopAwake() : root.system.keepAwake(0) }
            BarAction { Layout.fillWidth: true; theme: root.theme; text: root.system.catAnimation ? "Animação do gato · ligada" : "Animação do gato · desligada"; onClicked: root.system.catAnimation=!root.system.catAnimation }
            BarAction { Layout.fillWidth: true; theme: root.theme; text: "Configurações do Velora…"; onClicked: { root.controller.close(); root.actions.openSettings() } }
            Item { Layout.fillHeight: true }
        }
    }
}
