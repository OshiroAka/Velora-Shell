import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../core" as Core
import "../../features/topbar" as TopBar
import "../../features/topbar/TopBarGeometry.js" as Geometry

ShellRoot {
    Core.ConfigStore { id: config }
    Core.Theme { id: theme; config: config; palette: null }
    QtObject { id: palette; property bool generating: false; function shuffle() {} }
    QtObject { id: system; property var palette: palette }
    Window {
        width: 300; height: 220; visible: true; color: "#122229"
        TopBar.BarPanelContent {
            id: panel
            x: 20; y: 20
            width: Geometry.size("paint")[0]-32; height: Geometry.size("paint")[1]-32
            type: "paint"; theme: theme; system: system
            systemStatus: null; fanPlus: null; timerService: null; clock: null; calendar: null
            media: null; weather: null; controller: null; actions: null
        }
    }
    TestCase { id: input; name: "PaintTone"; when: false }
    function find(item,name) {
        if(item.objectName===name)return item
        for(const child of item.children||[]) {const result=find(child,name);if(result)return result}
        return null
    }
    property int phase: 0
    property int ticks: 0
    Timer {
        interval: 50; repeat: true; running: true
        onTriggered: {
            if (!config.ready || !panel.item) return
            try {
                ticks++
                if (phase===0) {
                    const mode=Quickshell.env("VELORA_PAINT_MODE")
                    for(const id of ["light","dark","auto"]) {
                        const button=find(panel,"paletteTone-"+id)
                        const p=button.mapToItem(panel,0,0)
                        if(p.x<0 || p.y<0 || p.x+button.width>panel.width+.1 || p.y+button.height>panel.height+.1)
                            throw Error("tone button is clipped: "+id)
                    }
                    input.mouseClick(find(panel,"paletteTone-"+mode),18,16)
                    if(config.pywalTone!==mode || !find(panel,"paletteTone-"+mode).highlighted)throw Error("tone did not change: "+mode)
                    if(theme.effectivePywalTone!==(mode==="auto" ? config.colorScheme : mode))throw Error("theme ignores selected tone")
                    phase=1
                } else if(!config.savePending) {console.info("PAINT_TONE_OK",config.pywalTone);Qt.quit()}
                if(ticks>40)throw Error("palette did not persist")
            } catch(error) {console.error("PAINT_TONE_FAILED",String(error));Qt.quit()}
        }
    }
    Timer { interval: 4000;running:true;onTriggered:{console.error("PAINT_TONE_FAILED timeout");Qt.quit()} }
}
