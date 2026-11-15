pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell

Column {
    id: root
    required property var config
    required property var theme
    width: parent ? parent.width : 600
    spacing: 10
    objectName: "infiniteDesk.pinnedItems"
    readonly property var applications: DesktopEntries.applications.values
    readonly property var catalog: [{id: "shell:search", name: "Aplicativos · busca"},
        {id: "shell:settings", name: "Configurações do Velora"}].concat(
        applications.filter(entry => entry && !entry.noDisplay).map(entry => ({id: entry.id, name: entry.name})))
    readonly property var choices: {
        const query = search.text.toLocaleLowerCase()
        return catalog.filter(entry => !config.infiniteDeskPinnedItems.includes(entry.id)
            && entry.name.toLocaleLowerCase().includes(query)).sort((a, b) => a.name.localeCompare(b.name))
    }
    function label(identifier) { const entry = catalog.find(entry => entry.id === identifier); return entry ? entry.name : identifier }
    function pin(identifier) {
        if (!identifier || config.infiniteDeskPinnedItems.includes(identifier) || config.infiniteDeskPinnedItems.length >= 40) return
        config.setValue("infiniteDesk.pinnedItems", config.infiniteDeskPinnedItems.concat([identifier]))
    }
    function remove(index) {
        const items = config.infiniteDeskPinnedItems.slice()
        items.splice(index, 1)
        config.setValue("infiniteDesk.pinnedItems", items)
    }
    function move(index, direction) {
        const items = config.infiniteDeskPinnedItems.slice(), next = index + direction
        if (next < 0 || next >= items.length) return
        const item = items.splice(index, 1)[0]
        items.splice(next, 0, item)
        config.setValue("infiniteDesk.pinnedItems", items)
    }
    Text {
        text: "Barra inferior · apps fixados"; color: root.theme.textPrimary
        font.family: root.theme.bodyFont; font.pixelSize: 16
    }
    Text {
        width: parent.width; wrapMode: Text.WordWrap
        text: "Escolha os ícones e aplicativos do centro da barra. A ordem abaixo é a ordem na barra."
        color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 12
    }
    TextField {
        id: search
        objectName: "infiniteDesk.pinSearch"
        width: parent.width; placeholderText: "Buscar aplicativo…"
        Accessible.name: "Buscar aplicativo para fixar"
        color: root.theme.textPrimary
        font.family: root.theme.bodyFont; font.pixelSize: 12
        background: Rectangle { radius: 8; color: root.theme.withAlpha(root.theme.accent, .06); border.width: 1; border.color: search.activeFocus ? root.theme.accent : root.theme.borderSubtle }
    }
    Row {
        width: parent.width; spacing: 8
        ComboBox {
            id: choice
            objectName: "infiniteDesk.pinChoice"
            width: parent.width - add.width - 8
            model: root.choices; textRole: "name"
            Accessible.name: "Aplicativo para fixar"
        }
        Button {
            id: add
            objectName: "infiniteDesk.addPin"
            text: "Fixar"
            enabled: choice.currentIndex >= 0 && root.choices.length > 0 && root.config.infiniteDeskPinnedItems.length < 40
            onClicked: root.pin(root.choices[choice.currentIndex].id)
        }
    }
    Text {
        visible: root.config.infiniteDeskPinnedItems.length === 0
        text: "Nenhum app fixado. O centro da barra está livre."
        color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 12
        width: parent.width; wrapMode: Text.WordWrap
    }
    Repeater {
        model: root.config.infiniteDeskPinnedItems
        Row {
            id: pinned
            required property string modelData
            required property int index
            width: root.width; spacing: 6
            Text {
                width: Math.max(20, parent.width - earlier.width - later.width - remove.width - 18)
                height: remove.height; verticalAlignment: Text.AlignVCenter
                text: root.label(pinned.modelData); elide: Text.ElideRight
                color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 12
            }
            Button {
                id: earlier
                objectName: "infiniteDesk.pinEarlier" + pinned.index
                text: "←"; implicitWidth: 36; enabled: pinned.index > 0
                Accessible.name: "Mover " + root.label(pinned.modelData) + " para antes"
                onClicked: root.move(pinned.index, -1)
            }
            Button {
                id: later
                objectName: "infiniteDesk.pinLater" + pinned.index
                text: "→"; implicitWidth: 36; enabled: pinned.index < root.config.infiniteDeskPinnedItems.length - 1
                Accessible.name: "Mover " + root.label(pinned.modelData) + " para depois"
                onClicked: root.move(pinned.index, 1)
            }
            Button {
                id: remove
                objectName: "infiniteDesk.removePin" + pinned.index
                text: "Remover"; onClicked: root.remove(pinned.index)
                Accessible.name: "Remover " + root.label(pinned.modelData) + " da barra"
            }
        }
    }
}
