import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import "../../core" as Core
import "../../components" as Components
import "SettingsCatalog.js" as Catalog

Item {
    id: root
    required property var config
    required property var controller
    required property var editor
    required property var theme
    required property var profileService
    required property var wallpaperStore
    property var motion: defaultMotion
    Core.Motion { id: defaultMotion; config: root.config }
    readonly property bool launcherMode: controller.launcherMode === true
    property bool presented: true
    property bool nativeConnected: false
    property string page: controller.settingsPage || "wallpapers"
    property string section: "main"
    onSectionChanged: if (controller.settingsSection !== undefined) controller.settingsSection = section
    property string searchText: ""
    property var pendingResult: null
    property string searchNotice: ""
    readonly property real wallpaperArtworkEnd: Math.max(0,Math.min(layoutHeight,controls.y+viewport.y))
    property alias contentItem: contentLoader.item
    property var scrollPositions: ({})
    readonly property var searchResults: Catalog.search(searchText)
    // Layout follows the final panel size, independently of the animated contour.
    property real layoutWidth: width
    property real layoutHeight: height
    readonly property real contentJoin: Math.min(42, layoutWidth*.04, layoutHeight*.3)
    readonly property bool compact: layoutWidth < 780
    readonly property real railWidth: compact ? 72 : Math.min(272, layoutWidth * .28)
    readonly property real preferredWidth: launcherMode ? 840 : 1140
    readonly property real preferredHeight: launcherMode ? 500 : 840
    readonly property real reveal: lifecycle.reveal
    readonly property bool animating: lifecycle.animating
    readonly property real join: surface.join
    readonly property real wallInset: controller.shell
        ? (controller.shell.barOnRight ? (controller.shell.sidebarVisualWidth || 48)
            : (controller.shell.oppositeFrameWidth || 4)) : 0
    readonly property color ink: theme.textPrimary
    readonly property color mutedInk: theme.textSecondary
    readonly property color accent: theme.accent
    readonly property var barComposition: controller.shell ? controller.shell.composition : null
    readonly property string barMaterial: barComposition ? barComposition.barMaterial : config.barMaterial
    readonly property color barSurface: barComposition ? barComposition.unifiedBarSurface : theme.barSurface
    readonly property bool liquidMaterial: ["liquid", "liquid-glass"].includes(barMaterial) && !config.reduceTransparency
    readonly property bool blurMaterial: barMaterial !== "solid"
        && (barComposition ? barComposition.barBlurEnabled : config.barBlurEnabled) && !config.reduceTransparency
    readonly property color surfaceTint: config.reduceTransparency
        ? Qt.rgba(barSurface.r, barSurface.g, barSurface.b, 1) : barSurface
    readonly property var currentCategory: Catalog.category(page)
    property alias materialItem: materialBounds
    signal requestClose()
    signal finishedClosing()

    onPageChanged: controller.setSettingsPage(page)
    SettingsMotion {
        id: lifecycle
        motion: root.motion; presented: root.presented; desiredPage: root.page
        sidePanel: !root.launcherMode
        onClosed: root.finishedClosing()
        onPresentedPageChanged: {
            root.section = "main"
            if (root.pendingResult && root.pendingResult.page === presentedPage)
                root.section = root.pendingResult.section
            Qt.callLater(root.restorePosition)
        }
    }
    SettingsSurface {
        id: surface
        anchors.fill: parent
        visible: !root.nativeConnected
        bottomAttached: root.launcherMode
        wallInset: root.wallInset
        tint: root.surfaceTint
        rim: root.launcherMode ? "transparent" : root.theme.borderStrong
    }
    Item {
        anchors.fill: parent
        visible: !root.launcherMode && lifecycle.presentedPage === "wallpapers" && lifecycle.reveal > 0
        opacity: lifecycle.contentReveal
        layer.enabled: true
        layer.effect: OpacityMask { maskSource: wallpaperMask }
        Item {
            // Only the contour mask grows; artwork keeps its final size/position.
            x: contentFrame.x; y: contentFrame.y
            width: root.layoutWidth
            height: root.wallpaperArtworkEnd
            clip: true
            Image {
                id: wallpaperBackdrop
                anchors.fill: parent
                source: !root.launcherMode && root.presented
                    && lifecycle.presentedPage === "wallpapers" && root.controller.wallpaperService
                    ? root.controller.wallpaperService.currentPreviewPath
                        || (/\.(png|jpe?g|bmp|gif)(?:[?#].*)?$/i.test(root.controller.wallpaperService.currentPath || "")
                            ? root.controller.wallpaperService.currentPath : "") : ""
                asynchronous: true
                retainWhileLoading: true
                sourceSize: Qt.size(1600, 1000)
                fillMode: Image.PreserveAspectCrop
                opacity: status === Image.Ready ? .42 : 0
                Behavior on opacity { NumberAnimation { duration: root.motion.reduced ? 0 : 260 } }
                layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
                layer.effect: MultiEffect { blurEnabled: true; blurMax: 16; blur: .18; autoPaddingEnabled: false }
            }
            Rectangle {
                anchors.fill: parent
                visible: wallpaperBackdrop.status === Image.Ready
                gradient: Gradient {
                    GradientStop { position: 0; color: "#00111316" }
                    GradientStop { position: .28; color: "#10111316" }
                    GradientStop { position: .60; color: "#18111316" }
                    GradientStop { position: 1; color: "#00111316" }
                }
                opacity: .25
            }
        }
    }
    SettingsSurface {
        id: wallpaperMask
        width: root.width; height: root.height
        visible: false
        bottomAttached: root.launcherMode
        wallInset: root.wallInset
        tint: "white"; rim: "transparent"
        fadeEnabled: true
        fadeHeight: Math.max(1, root.wallpaperArtworkEnd+contentFrame.y)
    }
    Item {
        id: materialBounds
        x: root.launcherMode ? surface.join : 0
        y: root.launcherMode ? 0 : surface.join
        width: Math.max(0, parent.width-(root.launcherMode ? 2*x : root.wallInset))
        height: Math.max(0, parent.height-(root.launcherMode ? 0 : 2*surface.join))
        // The native lens and fallback receive the same bounded body.
    }
    function requestSearchFocus() {
        if (launcherMode && launcherLoader.item) launcherLoader.item.requestSearchFocus()
        else forceActiveFocus(Qt.ShortcutFocusReason)
    }
    Loader {
        id: launcherLoader
        x: Math.min(42,root.width*.04)+16; y: 12
        width: Math.max(0,root.width-2*x); height: root.height-26
        active: root.launcherMode && root.visible && lifecycle.reveal > 0
        visible: active
        opacity: lifecycle.contentReveal
        sourceComponent: Components.VeloraSearchPanel {
            theme: root.theme
            reducedMotion: root.motion.reduced
            animateEntrance: false
            open: root.presented && root.launcherMode
            onCloseRequested: root.requestClose()
            onSettingsRequested: { root.controller.show("desktop"); root.controller.setSettingsPage("system") }
        }
        onLoaded: Qt.callLater(root.requestSearchFocus)
    }
    function navigate(id) {
        const positions = Object.assign({}, scrollPositions)
        positions[page + "/" + section] = viewport.contentY
        scrollPositions = positions
        pendingResult = null; searchText = ""; search.text = ""
        controller.setSettingsPage(id)
    }
    function restorePosition() {
        if (pendingResult) { focusResult(); return }
        viewport.contentY = Math.max(0, Math.min(scrollPositions[lifecycle.presentedPage+"/"+section] || 0,
            viewport.contentHeight-viewport.height))
    }
    function findTarget(item, result) {
        if (!item || item.visible === false) return null
        if (item.objectName === result.target || (item.settingIds && item.settingIds.includes(result.id))) return item
        const label = item.label !== undefined ? item.label : item.text
        if (result.label && label !== undefined
                && Catalog.normalize(label) === Catalog.normalize(result.label)) return item
        const children = item.children || []
        for (let i=0;i<children.length;i++) { const found=findTarget(children[i],result); if(found) return found }
        return null
    }
    function focusResult() {
        if (!pendingResult || lifecycle.presentedPage !== pendingResult.page || !contentLoader.item) return
        if (contentLoader.item.prepareResult(pendingResult)) { focusRetry.restart(); return }
        let target=findTarget(contentLoader.item,pendingResult)
        searchNotice = ""
        if (!target && pendingResult.fallbackLabel) {
            target=findTarget(contentLoader.item,{label:pendingResult.fallbackLabel})
            searchNotice=pendingResult.conditionHint || ""
        }
        if (!target) {
            searchNotice = "Esta opção depende do estado atual. Verifique os controles desta categoria."
            return
        }
        const point=target.mapToItem(contentLoader,0,0)
        viewport.contentY=Math.max(0,Math.min(point.y-24,viewport.contentHeight-viewport.height))
        target.forceActiveFocus(Qt.TabFocusReason)
        focusRing.targetItem=target
        focusTimeout.restart()
        pendingResult=null
    }
    function selectResult(result) {
        searchText=""; search.text=""
        pendingResult=result
        searchNotice=""
        controller.setSettingsPage(result.page)
        section=result.section
        if (result.action === "editor") { controller.beginEditing(result.page === "lock" ? "lock" : "desktop"); pendingResult=null }
        else if (result.action && contentLoader.item) { contentLoader.item.openTool(result.action); pendingResult=null }
        else Qt.callLater(focusResult)
    }
    // Bounded retry accommodates an asynchronous file/adapter load, not polling.
    Timer { id: focusRetry; interval: 40; repeat: false; onTriggered: root.focusResult() }
    Timer { id: focusTimeout; interval: 1800; onTriggered: focusRing.targetItem=null }
    Keys.onEscapePressed: event => {
        if (root.searchText) { search.text=""; root.searchText="" }
        else root.requestClose()
        event.accepted=true
    }
    Keys.onPressed: event => {
        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_F) {
            if (root.launcherMode) root.requestSearchFocus()
            else search.forceActiveFocus()
            event.accepted=true
        }
    }

    function categoryLabel(id) {
        const labels = {system: "Sistema", appearance: "Aparência", wallpapers: "Wallpaper",
            bar: "Barra e material", desktop: "Desktop e widgets", motion: "Movimento",
            media: "Mídia e áudio", profiles: "Perfis", language: "Acessibilidade", lock: "Prévia visual"}
        return labels[id] || Catalog.category(id).name
    }
    readonly property var sideNavigation: ["system", "appearance", "wallpapers", "media", "motion", "profiles", "language", "lock"].map(id => Catalog.category(id))
    Item {
        anchors.fill: parent
        clip: true
        Item {
            id: contentFrame
            objectName: "settingsContentFrame"
            width: root.layoutWidth; height: root.layoutHeight
            x: root.width-width
            y: (root.height-height)/2
            Item {
                id: sidebar
                objectName: "settingsSidebar"
                visible: !root.launcherMode
                x: 12; y: root.contentJoin+24; width: Math.max(0,root.railWidth-24); height: Math.max(0,root.layoutHeight-2*y)
                opacity: lifecycle.chromeReveal
                enabled: lifecycle.interactive
                clip: true
                Flickable {
                    id: navigationScroll
                    y: 70; width: parent.width; height: Math.max(0,parent.height-y-34)
                    contentWidth: width; contentHeight: navigationList.height
                    clip: true; boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    Column {
                        id: navigationList
                        width: parent.width; spacing: 6
                        Repeater {
                            model: root.sideNavigation
                            Rectangle {
                                id: nav
                                required property var modelData
                                objectName: "settingsNav-" + modelData.id
                                width: navigationList.width; height: 48; radius: 22
                                activeFocusOnTab: enabled
                                Accessible.role: Accessible.Button
                                Accessible.name: root.categoryLabel(modelData.id)
                                Accessible.onPressAction: root.navigate(modelData.id)
                                color: root.page === modelData.id ? Qt.rgba(root.ink.r,root.ink.g,root.ink.b,.14)
                                    : navHover.hovered ? Qt.rgba(root.ink.r,root.ink.g,root.ink.b,.065) : "transparent"
                                border.width: activeFocus ? 1 : 0; border.color: root.accent
                                Behavior on color { ColorAnimation { duration: root.motion.surfaceHover } }
                                Components.VeloraIconMotion {
                                    id: navIconMotion
                                    highlighted: nav.enabled && (navHover.hovered || nav.activeFocus)
                                    reducedMotion: root.motion.reduced
                                }
                                Components.VeloraMaterialIcon {
                                    x: root.compact ? (parent.width-width)/2 : 18
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 24; height: 24
                                    scale: navIconMotion.zoom
                                    transform: Translate { y: navIconMotion.lift }
                                    opacity: navIconMotion.inkOpacity
                                    iconName: nav.modelData.id === "system" ? "display" : nav.modelData.icon
                                    iconColor: root.ink
                                    layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
                                        && navIconMotion.emphasis > .001 && root.visible
                                    layer.effect: MultiEffect {
                                        shadowEnabled: true
                                        shadowColor: root.ink
                                        shadowOpacity: .5 * navIconMotion.emphasis
                                        shadowBlur: .5; blurMax: 12
                                        shadowHorizontalOffset: 0; shadowVerticalOffset: 0
                                        autoPaddingEnabled: true
                                    }
                                }
                                Text {
                                    visible: !root.compact
                                    x: 66; width: Math.max(0,parent.width-x-12); anchors.verticalCenter: parent.verticalCenter
                                    text: root.categoryLabel(nav.modelData.id); color: root.ink
                                    font.family: root.theme.bodyFont; font.pixelSize: 16; elide: Text.ElideRight
                                }
                                HoverHandler { id: navHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: root.navigate(nav.modelData.id) }
                                Keys.onReturnPressed: root.navigate(modelData.id)
                                Keys.onSpacePressed: root.navigate(modelData.id)
                            }
                        }
                    }
                }
                Text {
                    visible: !root.compact
                    x: 18; anchors.bottom: parent.bottom
                    text: "Velora"; color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 12
                }
            }
            Rectangle {
                visible: !root.launcherMode
                x: root.railWidth; y: root.contentJoin+24; width: 1; height: Math.max(0,root.layoutHeight-2*y)
                color: root.theme.borderSubtle; opacity: lifecycle.chromeReveal
            }
            TextField {
                id: search
                objectName: "settingsSearch"
                visible: !root.launcherMode
                x: root.compact ? root.railWidth+20 : 20; y: root.contentJoin+30
                width: root.compact ? Math.max(0,root.layoutWidth-x-64) : Math.max(0,root.railWidth-40)
                height: 44; leftPadding: 44; rightPadding: 12
                opacity: lifecycle.chromeReveal; enabled: lifecycle.interactive
                color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 12
                placeholderText: "Buscar configurações…"; placeholderTextColor: root.mutedInk
                selectByMouse: true
                onTextChanged: root.searchText=text
                onAccepted: if (root.searchResults.length) root.selectResult(root.searchResults[0])
                background: Rectangle {
                    radius: 22; color: Qt.rgba(0,0,0,.07)
                    border.color: search.activeFocus ? root.accent : root.theme.borderSubtle
                }
                Components.VeloraMaterialIcon {
                    x: 15; anchors.verticalCenter: parent.verticalCenter
                    width: 19; height: 19; iconName: "search"; iconColor: root.ink
                }
            }
            Rectangle {
                objectName: "settingsClose"
                z: 10
                visible: !root.launcherMode
                x: root.layoutWidth-root.wallInset-52; y: root.contentJoin+24; width: 32; height: 32; radius: 16
                opacity: lifecycle.chromeReveal; enabled: lifecycle.interactive
                color: closeHover.hovered ? Qt.rgba(root.ink.r,root.ink.g,root.ink.b,.1) : "transparent"
                activeFocusOnTab: true
                Accessible.role: Accessible.Button; Accessible.name: "Fechar configurações"
                Accessible.onPressAction: root.requestClose()
                Components.VeloraMaterialIcon { anchors.centerIn: parent; width: 18; height: 18; iconName: "close"; iconColor: root.mutedInk }
                HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.requestClose() }
                Keys.onReturnPressed: root.requestClose()
                Keys.onSpacePressed: root.requestClose()
            }
            Item {
                id: controls
                visible: !root.launcherMode
                x: root.railWidth+24; y: root.contentJoin+(root.compact ? 94 : 24)
                width: Math.max(0,root.layoutWidth-x-root.wallInset-24); height: Math.max(0,root.layoutHeight-y-root.contentJoin-20)
                enabled: lifecycle.interactive
                clip: true
                Item {
                    id: titleRow
                    opacity: lifecycle.chromeReveal
                    width: Math.max(0,parent.width-34)
                    height: root.page === "system" && !root.searchText ? 0 : root.page === "wallpapers" && !root.searchText ? 36 : 58
                    Text {
                        visible: root.page !== "system" || !!root.searchText
                        text: root.searchText ? "Resultados da busca" : root.categoryLabel(root.page)
                        color: root.ink; font.family: root.theme.bodyFont; font.pixelSize: 22; font.weight: Font.Medium
                        width: parent.width; elide: Text.ElideRight
                    }
                    Text {
                        y: 31; width: parent.width; visible: root.page !== "wallpapers" && root.page !== "system" && !root.searchText
                        text: root.currentCategory.detail; color: root.mutedInk; font.family: root.theme.bodyFont; font.pixelSize: 11; elide: Text.ElideRight
                    }
                }
                Flickable {
                    id: viewport
                    objectName: "settingsViewport"
                    y: titleRow.height+(titleRow.height ? 16 : 0)
                    width: parent.width; height: Math.max(0,parent.height-y-22)
                    contentWidth: Math.max(width,380)
                    contentHeight: contentLoader.height
                    clip: true; boundsBehavior: Flickable.StopAtBounds
                    visible: !root.searchText
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }
                    Loader {
                        id: contentLoader
                        width: viewport.contentWidth
                        opacity: lifecycle.contentReveal
                        y: (1-lifecycle.contentReveal)*8
                        active: !root.launcherMode && lifecycle.reveal > 0 && root.visible
                        asynchronous: !root.motion.reduced
                        sourceComponent: SettingsContent {
                            animatePageEntrance: false
                            config: root.config; controller: root.controller; editor: root.editor
                            theme: root.theme; motion: root.motion; profileService: root.profileService
                            wallpaperStore: root.wallpaperStore; page: lifecycle.presentedPage
                            section: root.section; mediaSection: root.section === "main" ? "playback" : root.section
                            onInlineToolOpened: item => {
                                if (!item || !root.presented) return
                                const point=item.mapToItem(contentLoader,0,0)
                                viewport.contentY=Math.max(0,Math.min(point.y-12,viewport.contentHeight-viewport.height))
                            }
                            onRevealSetting: id => {
                                const result = Catalog.entries.find(entry => entry.id === id)
                                if (result) root.selectResult(result)
                            }
                            onImplicitHeightChanged: if (root.pendingResult) focusRetry.restart()
                        }
                        onLoaded: { root.restorePosition(); if (root.pendingResult) focusRetry.restart() }
                    }
                    Rectangle {
                        id: focusRing
                        property var targetItem: null
                        visible: !!targetItem
                        x: targetItem ? targetItem.mapToItem(contentLoader,0,0).x-3 : 0
                        y: targetItem ? targetItem.mapToItem(contentLoader,0,0).y-3 : 0
                        width: targetItem ? targetItem.width+6 : 0; height: targetItem ? targetItem.height+6 : 0
                        color: "transparent"; border.color: root.accent; border.width: 1; radius: 10
                    }
                }
                ListView {
                    id: results
                    opacity: lifecycle.chromeReveal
                    y: titleRow.height+16; width: parent.width; height: Math.max(0,parent.height-y-26)
                    visible: !!root.searchText
                    clip: true; spacing: 8
                    model: root.searchResults
                    delegate: Rectangle {
                        required property var modelData
                        width: results.width; height: 64; radius: 20
                        color: resultHover.hovered ? Qt.rgba(root.ink.r,root.ink.g,root.ink.b,.11) : Qt.rgba(root.ink.r,root.ink.g,root.ink.b,.045)
                        activeFocusOnTab: true
                        function activate() { root.selectResult(modelData) }
                        Accessible.role: Accessible.Button; Accessible.name: modelData.name
                        Text { x: 18; y: 12; width: parent.width-36; text: modelData.name; color: root.ink; font.pixelSize: 13; elide: Text.ElideRight; font.family: root.theme.bodyFont }
                        Text { x: 18; y: 37; width: parent.width-36; text: Catalog.category(modelData.page).name; color: root.mutedInk; font.pixelSize: 11; elide: Text.ElideRight; font.family: root.theme.bodyFont }
                        HoverHandler { id: resultHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: parent.activate() }
                        Keys.onReturnPressed: activate()
                        Keys.onSpacePressed: activate()
                    }
                    Text { anchors.centerIn: parent; visible: root.searchText && results.count === 0; text: "Nenhuma configuração encontrada"; color: root.mutedInk; font.pixelSize: 12 }
                }
                Text {
                    anchors.left: parent.left; anchors.bottom: parent.bottom; width: parent.width
                    opacity: lifecycle.chromeReveal
                    text: root.config.saveError || root.controller.integrationError || root.searchNotice
                        || (root.config.savePending || (root.controller.integrations && root.controller.integrations.busy) ? "Salvando…" : "")
                    color: root.config.saveError || root.controller.integrationError ? root.theme.danger : root.mutedInk
                    font.family: root.theme.bodyFont; font.pixelSize: 10; elide: Text.ElideRight
                }
            }
        }
    }
}
