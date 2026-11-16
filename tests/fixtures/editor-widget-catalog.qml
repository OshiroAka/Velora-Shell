import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../core" as Core
import "../../core/WidgetCatalog.js" as Catalog
import "../../services" as Services
import "../../features/editor" as Editor

ShellRoot {
    id: root
    Core.ConfigStore { id: config }
    Core.Theme { id: theme; config: config; palette: null; kittyMaterial: null }
    Core.Motion { id: motion; config: config }
    Services.SceneEditorService { id: editor; config: config }
    QtObject {
        id: legacy
        property string visualizerMode: "wave"
        function setVisualizerMode(mode) { visualizerMode = mode }
    }
    QtObject {
        id: shell
        property bool barOnRight: false
        property real sidebarVisualWidth: 64
        property var unifiedTheme: legacy
    }
    QtObject {
        id: controller
        property var shell: shell
        property int imageRequests: 0
        function chooseCustomImage() { imageRequests++ }
    }
    Window {
        id: window
        width: 1200; height: 900; visible: true; color: "#132b2c"
        Rectangle { y: 0; width: parent.width; height: 40; color: theme.barSurface }
        Rectangle { y: parent.height-16; width: parent.width; height: 16; color: theme.barSurface }
        Editor.EditorWidgetCatalog {
            id: catalog
            config: config; editor: editor; controller: controller; theme: theme; motion: motion
            onCloseRequested: presented=false
        }
        TestCase { id: pointer; name: "WidgetCatalogPointer"; when: false }
    }
    function assert(value, message) { if (!value) throw new Error(message) }
    function clickEntry(kind, variant) {
        const index=catalog.entries.findIndex(entry=>entry.kind===kind && entry.id===variant)
        assert(index>=0,"missing entry: "+kind+"/"+variant)
        catalog.listItem.positionViewAtIndex(index,ListView.Center)
        catalog.listItem.forceLayout()
        pointer.wait(35)
        const card=catalog.listItem.itemAtIndex(index)
        assert(!!card,"entry did not mount: "+kind+"/"+variant)
        pointer.mouseClick(card,card.width/2,card.height-26,Qt.LeftButton)
        return card
    }
    property bool stepping: false
    property int phase: 0
    property var initialClock: null
    Timer {
        interval: 120; running: true; repeat: true
        onTriggered: {
            if (!config.ready || stepping) return
            stepping=true
            try {
                if (phase===0) {
                    config.setValue("appearance.reducedMotion",true)
                    catalog.presented=true
                    if (Quickshell.env("VELORA_CATALOG_RELOAD")==="1") {
                        const clock=config.sharedWidgetByKind("clock")
                        assert(clock.variantId==="analog" && clock.desktopEnabled,"variant did not persist")
                        assert(clock.desktopSize.width===240 && clock.desktopSize.height===260,"variant size did not persist")
                        console.info("EDITOR_WIDGET_CATALOG_OK reload"); Qt.quit(); return
                    }
                } else if (phase===1) {
                    assert(catalog.visible && catalog.x+catalog.bodyWidth===window.width,"catalog has a right margin")
                    assert(catalog.y===40 && catalog.height===window.height-40,"catalog does not span the right edge")
                    const families=["clock","weather","media","system","gallery","battery"]
                    for (const kind of families)
                        assert(catalog.entries.filter(entry=>entry.kind===kind).length===Catalog.variants(kind).length,
                            "missing widget appearances: "+kind)
                    initialClock=editor.clone(config.sharedWidgetByKind("clock"))
                    clickEntry("clock","dots")
                    const clock=config.sharedWidgetByKind("clock")
                    assert(clock.variantId==="dots" && clock.desktopEnabled,"click did not add the chosen widget")
                    assert(editor.selectedLayerId===clock.id,"added widget was not selected for editing")
                    assert(catalog.presented,"adding a widget closes the catalog")
                    assert(editor.undo(),"widget addition is not undoable")
                    assert(JSON.stringify(config.sharedWidgetByKind("clock"))===JSON.stringify(initialClock),"undo did not restore the widget")
                    assert(editor.redo() && config.sharedWidgetByKind("clock").variantId==="dots","redo failed")
                    const count=config.sharedWidgets.length
                    clickEntry("clock","analog")
                    assert(config.sharedWidgets.length===count,"choosing a variation duplicates a singleton")
                    const history=editor.undoStack.length
                    editor.clearSelection()
                    clickEntry("clock","analog")
                    assert(editor.selectedLayerId===clock.id && editor.undoStack.length===history,
                        "choosing the current appearance must select it without changing history")
                    const before=editor.undoStack.length
                    assert(!editor.addWidgetVariant("clock","invalid") && editor.undoStack.length===before,"invalid choice changed history")
                    // Mount every preview, including the final rows after scrolling.
                    for (let index=0;index<catalog.entries.length;index++) {
                        catalog.listItem.positionViewAtIndex(index,ListView.Center)
                        catalog.listItem.forceLayout(); pointer.wait(15)
                        assert(!!catalog.listItem.itemAtIndex(index),"preview missing at "+index)
                    }
                    clickEntry("visualizer","pixels")
                    assert(config.desktopVisualizerEnabled && legacy.visualizerMode==="pixels","visualizer choice failed")
                    const prior=editor.editableLayers.length
                    clickEntry("text","text")
                    assert(editor.editableLayers.length===prior+1,"text creation failed")
                    shell.barOnRight=true; window.width=640; window.height=480
                } else if (phase===2) {
                    assert(catalog.width<=window.width-80 && catalog.x+catalog.bodyWidth===window.width,"small screen overflows")
                    assert(catalog.listItem.width>0 && catalog.listItem.height>0,"small screen has no scrollable content")
                    clickEntry("image","image")
                    assert(controller.imageRequests===1 && !catalog.presented,"image picker was not opened")
                    catalog.presented=true
                    pointer.wait(20)
                    catalog.forceActiveFocus()
                    pointer.keyClick(Qt.Key_Escape)
                    assert(!catalog.presented,"Escape does not close the catalog")
                    catalog.presented=true
                    window.width=1200;window.height=900;shell.barOnRight=false
                    catalog.listItem.positionViewAtBeginning()
                } else if (phase===3) {
                    const path=Quickshell.env("VELORA_CATALOG_SCREENSHOT")
                    if (path) {
                        running=false
                        window.contentItem.grabToImage(result=>{
                            assert(result.saveToFile(path),"preview was not saved")
                            console.info("EDITOR_WIDGET_CATALOG_OK");Qt.quit()
                        })
                        return
                    }
                    console.info("EDITOR_WIDGET_CATALOG_OK");Qt.quit()
                }
                phase++
            } catch(error) { console.error("EDITOR_WIDGET_CATALOG_FAILED",error,error.stack);Qt.quit() }
            finally { stepping=false }
        }
    }
    Timer { interval: 12000; running: true; onTriggered: { console.error("EDITOR_WIDGET_CATALOG_FAILED timeout");Qt.quit() } }
}
