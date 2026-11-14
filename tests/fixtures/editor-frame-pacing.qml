import QtQuick
import QtQuick.Window
import Quickshell
import "../../core" as Core

ShellRoot {
    id: test
    QtObject { id: chrome; property var settingsItem: editorWindow }
    Window {
        id: editorWindow
        width: 320; height: 180; visible: true
        property alias shapeDirty: shapePump.dirty
        property bool animating: morph.running
        property real pose: 0
        property int poseTicks: 0
        property var sentTicks: []
        property var sentPoses: []
        property int restingFrames: 0
        property int restingSends: 0
        property bool requeueOnce: false
        property int phase: 0
        onPoseChanged: { poseTicks++; shapeDirty = true }
        function syncShape() {
            sentTicks.push(poseTicks)
            sentPoses.push(pose)
            if (requeueOnce) { requeueOnce=false;shapeDirty=true }
        }
        Core.FramePublisher {
            id: shapePump
            onPublish: editorWindow.syncShape()
        }
        NumberAnimation {
            id: morph; target: editorWindow; property: "pose"
            to: 1; duration: 480; easing.type: Easing.OutCubic
            onFinished: verify.restart()
        }
        Timer { interval: 80; running: true; onTriggered: morph.start() }
        Timer {
            id: verify; interval: 90
            onTriggered: {
                try {
                    if (editorWindow.phase === 0) {
                        const ticks=editorWindow.sentTicks
                        if (editorWindow.poseTicks < 8) throw new Error("insufficient animation samples")
                        let largestGap=0
                        // Startup can precede the first animated pose; compare the steady burst.
                        for(let i=2;i<ticks.length;i++) largestGap=Math.max(largestGap,ticks[i]-ticks[i-1])
                        console.info("EDITOR_FRAME_COUNTS",JSON.stringify({poses:editorWindow.poseTicks,sends:ticks.length,largestGap:largestGap}))
                        if (ticks.length < editorWindow.poseTicks-1 || largestGap > 1)
                            throw new Error("native geometry skips intermediate animation poses")
                        if (Math.abs(editorWindow.sentPoses[ticks.length-1]-1) > .0001)
                            throw new Error("native geometry never receives the final pose")
                        if (shapePump.running) throw new Error("shape publisher keeps running at rest")
                        editorWindow.restingFrames=shapePump.currentFrame
                        editorWindow.restingSends=ticks.length
                        editorWindow.phase=1; restart()
                    } else if (editorWindow.phase === 1) {
                        if (shapePump.currentFrame !== editorWindow.restingFrames || editorWindow.sentTicks.length !== editorWindow.restingSends)
                            throw new Error("settled geometry schedules more frames")
                        editorWindow.phase=2
                        editorWindow.requeueOnce=true;editorWindow.shapeDirty=true
                        restart()
                    } else {
                        if (editorWindow.sentTicks.length !== editorWindow.restingSends+2)
                            throw new Error("invalidation during publication was lost")
                        if (shapePump.running) throw new Error("requeued publication never returns to rest")
                        console.info("EDITOR_FRAME_PACING_OK"); Qt.quit()
                    }
                } catch(error) { console.error("EDITOR_FRAME_PACING_FAILED",String(error)); Qt.quit() }
            }
        }
    }
    Timer { interval: 4000;running: true;onTriggered: {console.error("EDITOR_FRAME_PACING_FAILED timeout");Qt.quit()} }
}
