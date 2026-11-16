import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../core" as Core
import "../../services" as Services
import "../../features/settings" as Settings

ShellRoot {
    id: root
    Core.ConfigStore { id: config }
    Core.Theme { id: theme; config: config; palette: null; kittyMaterial: null }
    Core.Motion { id: motion; config: config }
    Services.SceneEditorService { id: editor; config: config }
    Window {
        id: window
        width: 1200; height: 900; visible: true; color: "#132b2c"
        Rectangle {
            x: overlay.selectedX; y: overlay.selectedY
            width: overlay.selectedWidth; height: overlay.selectedHeight; radius: 18
            color: "#1d222c"
            opacity: Number(overlay.selectedTransform.opacity === undefined ? 1 : overlay.selectedTransform.opacity)
            rotation: Number(overlay.selectedTransform.rotation || 0)
            Text { anchors.centerIn: parent; text: "Galeria"; color: theme.textPrimary; font.family: theme.bodyFont; font.pixelSize: 24 }
        }
        Settings.SceneEditorOverlay {
            id: overlay; anchors.fill: parent; active: true
            config: config; editor: editor; theme: theme; motion: motion
        }
        TestCase { id: pointer; name: "SelectionPointer"; when: false }
    }
    function assert(value,message) { if (!value) throw new Error(message) }
    function find(item,name) {
        if (item.objectName===name) return item
        for (const child of item.children || []) { const result=find(child,name);if(result)return result }
        return null
    }
    property string galleryId: ""
    property int phase: 0
    property bool stepping: false
    Timer {
        interval: 150; running: true; repeat: true
        onTriggered: {
            if (!config.ready || stepping) return
            stepping=true
            try {
                if (phase===0) {
                    config.setValue("appearance.reducedMotion",true)
                    galleryId=config.sharedWidgetByKind("gallery").id
                    if (Quickshell.env("VELORA_SELECTION_RELOAD")==="1") {
                        assert(config.sharedWidgetByKind("gallery").desktopEnabled,"deletion undo did not persist")
                        assert(Math.abs(config.sharedWidgetByKind("gallery").desktop.opacity-.65)<.001,"opacity did not persist")
                        console.info("EDITOR_SELECTION_CONTROLS_OK reload");Qt.quit();return
                    }
                    editor.setBuiltInVisible("gallery",true)
                    editor.updateLayer(galleryId,{transform:{x:400,y:220,scale:1,rotation:0,opacity:1}})
                    editor.select(galleryId)
                } else if (phase===1) {
                    const controls=overlay.selectionControls
                    assert(controls.visible,"selecting a widget does not show its controls")
                    assert(controls.y>=overlay.selectedY+overlay.selectedHeight+13,"controls are not below the widget")
                    const size=find(controls,"editorSelection.scale")
                    const opacity=find(controls,"editorSelection.opacity")
                    assert(size && opacity && find(controls,"editorSelection.delete"),"compact actions are missing")
                    size.forceActiveFocus(); pointer.keyClick(Qt.Key_Right)
                    assert(Math.abs(config.sharedWidgetByKind("gallery").desktop.scale-1.01)<.001,"keyboard resize failed")
                    assert(editor.undo() && Math.abs(config.sharedWidgetByKind("gallery").desktop.scale-1)<.001,"resize undo failed")
                    const before=editor.undoStack.length
                    pointer.mousePress(size,size.width*.45,size.height/2,Qt.LeftButton)
                    pointer.mouseMove(size,size.width*.55,size.height/2,30)
                    assert(editor.gestureActive && controls.interactionHeld,"slider does not preview a gesture")
                    const heldX=controls.x,heldY=controls.y
                    pointer.mouseMove(size,size.width*.62,size.height/2,30)
                    assert(controls.x===heldX && controls.y===heldY,"controls move away while adjusting size")
                    pointer.mouseRelease(size,size.width*.62,size.height/2,Qt.LeftButton)
                    assert(!editor.gestureActive && !controls.interactionHeld,"size gesture did not finish")
                    assert(editor.undoStack.length===before+1,"one drag creates more than one undo entry")
                    opacity.forceActiveFocus();pointer.keyClick(Qt.Key_Home)
                    assert(config.sharedWidgetByKind("gallery").desktop.opacity===0,"zero opacity is lost")
                    assert(controls.visible,"zero opacity hides the editing controls")
                    assert(editor.undo() && config.sharedWidgetByKind("gallery").desktop.opacity===1,"opacity undo failed")
                    editor.setTransform(galleryId,"opacity",.65)
                    editor.updateLayer(galleryId,{transform:{x:400,y:200,scale:1,rotation:35}})
                } else if (phase===2) {
                    const controls=overlay.selectionControls
                    assert(controls.y>=overlay.selectedBounds.y+overlay.selectedBounds.height+13,"controls overlap a rotated widget")
                    editor.updateLayer(galleryId,{transform:{x:900,y:750,rotation:0}})
                    window.width=640;window.height=480;overlay.rightInset=240
                } else if (phase===3) {
                    const controls=overlay.selectionControls
                    assert(controls.x>=0 && controls.x+controls.width<=window.width-overlay.rightInset,"controls overlap the catalog")
                    assert(controls.y>=0 && controls.y+controls.height<=window.height,"controls leave the screen")
                    const button=find(controls,"editorSelection.delete")
                    pointer.mouseClick(button,button.width/2,button.height/2,Qt.LeftButton)
                    assert(!config.sharedWidgetByKind("gallery").desktopEnabled && editor.selectedLayerId==="","delete did not remove the widget")
                    assert(!controls.visible,"controls stay after deleting the widget")
                    assert(editor.undo() && config.sharedWidgetByKind("gallery").desktopEnabled,"deletion cannot be undone")
                    editor.select(galleryId)
                    editor.updateLayer(galleryId,{transform:{x:400,y:220,scale:1,rotation:0}})
                    window.width=1200;window.height=900;overlay.rightInset=0
                } else if (phase===4) {
                    if (config.savePending) return
                    const path=Quickshell.env("VELORA_SELECTION_SCREENSHOT")
                    if(path) {
                        running=false
                        window.contentItem.grabToImage(result=>{
                            assert(result.saveToFile(path),"preview was not saved")
                            console.info("EDITOR_SELECTION_CONTROLS_OK");Qt.quit()
                        });return
                    }
                    console.info("EDITOR_SELECTION_CONTROLS_OK");Qt.quit()
                }
                phase++
            } catch(error) {console.error("EDITOR_SELECTION_CONTROLS_FAILED",error,error.stack);Qt.quit()}
            finally {stepping=false}
        }
    }
    Timer {interval:12000;running:true;onTriggered:{console.error("EDITOR_SELECTION_CONTROLS_FAILED timeout");Qt.quit()}}
}
