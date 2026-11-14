import QtQuick
import QtQuick.Window
import Quickshell
import "../../components" as Components
import "../../platform" as Platform

ShellRoot {
    id: test
    QtObject {
        id: analyzer
        property bool running: true
        property int ticks: 0
        property var reads: []
        signal bandsChanged()
        function materialFrame() { throw Error("desktop read the shared spectrum") }
        function desktopFrame() { reads.push(ticks); return Array(96).fill((ticks%97)/100).join(" ") }
    }
    QtObject {
        id: composition
        property var audioVisualizer: analyzer
        property bool desktopVisualizerVisible: true
        property color unifiedBarSurface: "#202020"
        property string barMaterial: "solid"
        property bool barBlurEnabled: false
    }
    Window { width: 320; height: 180; visible: true }
    Components.DesktopBarMaterial { id: material; monitorName: "fixture"; composition: composition }
    FrameAnimation {
        id: source
        running: true
        onTriggered: { analyzer.ticks++;analyzer.bandsChanged() }
    }
    property int restCount: 0
    property int phase: 0
    Timer {
        interval: 750;running: true;repeat: true
        onTriggered: {
            try {
                if (phase===0) {
                    if (analyzer.ticks<20) throw Error("insufficient frame samples")
                    let gap=0
                    for(let i=2;i<analyzer.reads.length;i++)gap=Math.max(gap,analyzer.reads[i]-analyzer.reads[i-1])
                    console.info("DESKTOP_PACING",JSON.stringify({ticks:analyzer.ticks,published:analyzer.reads.length,maxGap:gap}))
                    if(analyzer.reads.length<analyzer.ticks-3 || gap>2)throw Error("desktop publisher skips display frames")
                    source.running=false;phase=1
                } else if(phase===1) {
                    restCount=analyzer.reads.length;phase=2
                } else {
                    if(analyzer.reads.length!==restCount)throw Error("publisher keeps reading at rest")
                    console.info("DESKTOP_MATERIAL_PACING_OK");Qt.quit()
                }
            } catch(error) { console.error("DESKTOP_MATERIAL_PACING_FAILED",String(error));Qt.quit() }
        }
    }
    Component.onCompleted: {
        // Keep transport disconnected; no user monitor or audio is touched.
        Platform.NativeBlur.available=true
        Platform.NativeBlur.capabilities=["desktop-bar-material"]
    }
}
