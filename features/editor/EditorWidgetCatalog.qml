pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../../core/WidgetCatalog.js" as Catalog

Item {
    id: root
    required property var config
    required property var editor
    required property var controller
    required property var theme
    required property var motion
    property bool presented: false
    property bool nativeConnected: false
    property color surfaceTint: theme.barSurface
    property real topInset: config.topbarEnabled ? 40 : 0
    property real railInset: controller.shell && controller.shell.barOnRight
        ? controller.shell.sidebarVisualWidth : 4
    readonly property real join: 24
    readonly property real radius: 20
    readonly property real reveal: entrance.value
    readonly property real bodyWidth: width * reveal
    property alias materialItem: materialBounds
    property alias listItem: choices
    signal closeRequested()
    width: Math.min(448, Math.max(0, parent.width - 80))
    height: Math.max(0, parent.height - topInset)
    x: parent.width - bodyWidth
    y: topInset
    visible: reveal > .001
    enabled: presented
    clip: true
    z: 35

    QtObject {
        id: entrance
        property real value: root.presented ? 1 : 0
        Behavior on value {
            enabled: !root.motion.reduced
            NumberAnimation { duration: root.motion.geometryDuration; easing.type: Easing.InOutCubic }
        }
    }
    Item { id: materialBounds; width: root.bodyWidth; height: root.height }
    // The native editor pass owns the frame and both attached editor bodies.
    // Without it, extend the same tint through the right edge without a rim.
    Rectangle {
        visible: !root.nativeConnected
        width: parent.width + root.radius
        height: parent.height + 2 * root.radius
        y: -root.radius
        radius: root.radius
        color: root.surfaceTint
    }
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

    readonly property var entries: {
        const result = []
        for (const widget of config.sharedWidgets) {
            if (widget.kind === "calendar") continue
            for (const variant of Catalog.variants(widget.kind))
                result.push(Object.assign({kind: widget.kind, family: widget.name}, variant))
        }
        result.push({kind: "visualizer", family: "Visualizador", id: "wave", name: "Wave", detail: "Onda na moldura do desktop", width: 330, height: 110})
        result.push({kind: "visualizer", family: "Visualizador", id: "pixels", name: "Pixels", detail: "Espectro em barras", width: 330, height: 110})
        result.push({kind: "image", family: "Conteúdo livre", id: "image", name: "Imagem", detail: "Escolher uma imagem", width: 330, height: 170})
        result.push({kind: "text", family: "Conteúdo livre", id: "text", name: "Texto", detail: "Escreva no seu desktop", width: 330, height: 100})
        return result
    }
    function chosen(entry) {
        if (entry.kind === "visualizer") {
            const legacy = controller.shell ? controller.shell.unifiedTheme : null
            return config.desktopVisualizerEnabled && !!legacy && legacy.visualizerMode === entry.id
        }
        const widget = config.sharedWidgetByKind(entry.kind)
        return !!widget && widget.desktopEnabled && Catalog.resolve(entry.kind, widget.variantId).id === entry.id
    }
    function choose(entry) {
        if (entry.kind === "image") { closeRequested(); controller.chooseCustomImage(); return }
        if (entry.kind === "text") { editor.addText("Novo texto"); return }
        if (entry.kind === "visualizer") {
            const legacy = controller.shell ? controller.shell.unifiedTheme : null
            if (legacy) legacy.setVisualizerMode(entry.id)
            config.setValue("desktop.visualizerEnabled", true)
            return
        }
        editor.addWidgetVariant(entry.kind, entry.id)
    }

    Row {
        id: heading
        x: 24; y: 20; width: parent.width - 48 - root.railInset
        spacing: 12
        Column {
            width: Math.max(0, parent.width - 48); spacing: 5
            Text { text: "Widgets"; color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 22; font.weight: Font.DemiBold }
            Text { text: "Escolha uma aparência para o desktop."; color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 11 }
        }
        Rectangle {
            objectName: "widgetCatalogClose"
            width: 36; height: 36; radius: 18
            color: closeHover.hovered ? Qt.rgba(1,1,1,.12) : "transparent"
            activeFocusOnTab: true
            Accessible.role: Accessible.Button; Accessible.name: "Fechar catálogo de widgets"
            Accessible.onPressAction: root.closeRequested()
            Keys.onReturnPressed: root.closeRequested()
            Keys.onSpacePressed: root.closeRequested()
            Text { anchors.centerIn: parent; text: "×"; color: root.theme.textPrimary; font.pixelSize: 24 }
            HoverHandler { id: closeHover }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.closeRequested() }
        }
    }
    ListView {
        id: choices
        objectName: "editorWidgetChoices"
        x: 20; y: heading.y + heading.height + 24
        width: Math.max(0, parent.width - 40 - root.railInset)
        height: Math.max(0, parent.height - y - 20)
        clip: true
        spacing: 16
        reuseItems: true
        cacheBuffer: 180
        model: root.visible ? root.entries : []
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { }
        section.property: "family"
        section.delegate: Text {
            required property string section
            width: choices.width; height: 38
            text: section; color: root.theme.textPrimary
            font.family: root.theme.bodyFont; font.pixelSize: 14; font.weight: Font.DemiBold
            verticalAlignment: Text.AlignVCenter
        }
        delegate: Rectangle {
            id: card
            required property var modelData
            required property int index
            readonly property bool chosen: root.chosen(modelData)
            readonly property real previewHeight: Math.min(216, modelData.height)
            objectName: "editorWidgetVariant." + modelData.kind + "." + modelData.id
            width: choices.width
            height: previewHeight + 66
            radius: 18
            color: Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, hover.hovered ? .09 : .025)
            border.width: 1
            border.color: chosen || activeFocus ? root.theme.accent : root.theme.borderSubtle
            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: modelData.family + ": " + modelData.name + (chosen ? ", no desktop" : ", adicionar")
            Accessible.onPressAction: root.choose(modelData)
            Keys.onReturnPressed: root.choose(modelData)
            Keys.onSpacePressed: root.choose(modelData)
            HoverHandler { id: hover }
            SettingsWidgetPreview {
                x: 14; y: 12; width: parent.width - 28; height: card.previewHeight
                theme: root.theme; kind: card.modelData.kind; variantId: card.modelData.id
                visualizerMode: card.modelData.kind === "visualizer" ? card.modelData.id : "wave"
                visible: card.modelData.kind !== "image" && card.modelData.kind !== "text"
                Accessible.ignored: true
            }
            Text {
                visible: card.modelData.kind === "text" || card.modelData.kind === "image"
                x: 18; y: 12; width: parent.width - 36; height: card.previewHeight
                text: card.modelData.kind === "text" ? "Seu texto aqui" : "▧"
                color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 30
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
            Column {
                x: 16; y: card.previewHeight + 23; width: parent.width - 62; spacing: 4
                Text { text: card.modelData.name; color: root.theme.textPrimary; font.family: root.theme.bodyFont; font.pixelSize: 12; font.weight: Font.DemiBold }
                Text { text: card.modelData.detail; color: root.theme.textSecondary; font.family: root.theme.bodyFont; font.pixelSize: 10; width: parent.width; elide: Text.ElideRight }
            }
            Text {
                anchors.right: parent.right; anchors.rightMargin: 18; y: card.previewHeight + 24
                text: card.chosen ? "✓" : "+"; color: root.theme.accent; font.pixelSize: 22
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.choose(card.modelData) }
        }
    }
    Keys.onEscapePressed: closeRequested()
}
