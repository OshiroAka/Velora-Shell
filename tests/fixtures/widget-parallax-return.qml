import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../core" as Core

ShellRoot {
    Core.WidgetParallax { id: parallax; viewportWidth: 1600; viewportHeight: 900 }
    Core.InfiniteDesktopCameraState { id: cameraState }
    Core.WidgetParallax {
        id: workspaceParallax
        viewportWidth: 1600; viewportHeight: 900; active: true
        camera: cameraState.views["DP-1"] || null
    }
    Window {
        width: 1600; height: 900; visible: true
        TestCase {
            id: checks
            name: "WidgetParallaxReturn"
            when: false
            function pose(x, y, zoom) {
                return {active:true, viewport:[1600,900], origin:[0,0],
                    center:[x,y], zoom:zoom}
            }
            function near(value, expected) { verify(Math.abs(value-expected)<.00001) }
            function startAt(value) {
                parallax.snapToRest=true
                parallax.active=true
                parallax.camera=value
                parallax.snapToRest=false
            }
            function test_return_camera_order_reversal_and_navigation() {
                for (const cameraFirst of [false,true]) {
                    startAt(pose(400,650,.5))
                    near(parallax.x,210); near(parallax.y,43.75); near(parallax.scale,.825)
                    // Navigation follows each new camera sample with no trailing animation.
                    parallax.camera=pose(600,550,.5)
                    near(parallax.x,175); near(parallax.y,61.25); near(parallax.scale,.825)
                    verify(!parallax.moving)
                    if (cameraFirst) parallax.camera={active:false}
                    else parallax.active=false
                    verify(parallax.moving)
                    near(parallax.x,175); near(parallax.y,61.25); near(parallax.scale,.825)
                    wait(200)
                    verify(parallax.x>0 && parallax.x<175)
                    verify(parallax.y>0 && parallax.y<61.25)
                    verify(parallax.scale>.825 && parallax.scale<1)
                    const before=parallax.x
                    // The other half of disable must not restart or erase the return.
                    if (cameraFirst) parallax.active=false
                    else parallax.camera={active:false}
                    near(parallax.x,before)
                    wait(220)
                    verify(parallax.x>0 && parallax.x<before)
                    tryCompare(parallax,"moving",false,800)
                    near(parallax.x,0); near(parallax.y,0); near(parallax.scale,1)
                }
                startAt(pose(600,550,1))
                near(parallax.x,70)
                parallax.active=false
                wait(200)
                const reversing=parallax.x
                verify(reversing>0 && reversing<70)
                parallax.active=true
                near(parallax.x,reversing)
                wait(150)
                verify(parallax.x>reversing && parallax.x<70)
                tryCompare(parallax,"moving",false,800)
                near(parallax.x,70)
                parallax.camera=pose(400,450,1)
                near(parallax.x,140) // no smoothing after the mode transition ends
                verify(!parallax.moving)
                parallax.active=false
                wait(100)
                parallax.snapToRest=true
                near(parallax.x,0); near(parallax.scale,1)
                verify(!parallax.moving)
                parallax.snapToRest=false
                parallax.active=true
                near(parallax.x,140)
                parallax.active=false
                tryCompare(parallax,"moving",false,1000)
                near(parallax.x,0)
            }
            function sendWorkspace(workspace, x, y, zoom) {
                const value=pose(x,y,zoom)
                value.monitor="DP-1"; value.workspace=workspace
                verify(cameraState.readEvent("velora-infinite-camera>>"+JSON.stringify(value)))
            }
            function test_workspace_resume_after_settling_and_direct_switch() {
                sendWorkspace(1,400,650,.5)
                near(workspaceParallax.x,210)
                verify(cameraState.applyPose({monitor:"DP-1",active:false}))
                tryCompare(workspaceParallax,"moving",false,1000)
                near(workspaceParallax.x,0); near(workspaceParallax.scale,1)
                // Returning after the entire departure has finished must still animate.
                sendWorkspace(1,400,650,.5)
                verify(workspaceParallax.moving,"workspace resume must animate after settling")
                near(workspaceParallax.x,0); near(workspaceParallax.scale,1)
                wait(200)
                verify(workspaceParallax.x>0 && workspaceParallax.x<210)
                verify(workspaceParallax.scale>.825 && workspaceParallax.scale<1)
                tryCompare(workspaceParallax,"moving",false,1000)
                near(workspaceParallax.x,210); near(workspaceParallax.scale,.825)
                sendWorkspace(1,600,550,.5)
                near(workspaceParallax.x,175)
                verify(!workspaceParallax.moving,"pan within a workspace stays direct")
                // Two nonempty workspaces never publish an inactive pose between them.
                sendWorkspace(2,1200,200,1.5)
                verify(workspaceParallax.moving,"direct workspace switch must animate")
                near(workspaceParallax.x,175); near(workspaceParallax.scale,.825)
                wait(200)
                verify(workspaceParallax.x>-350 && workspaceParallax.x<175)
                verify(workspaceParallax.scale>.825 && workspaceParallax.scale<1.175)
                tryCompare(workspaceParallax,"moving",false,1000)
                near(workspaceParallax.x,-350); near(workspaceParallax.y,52.5)
                near(workspaceParallax.scale,1.175)
                sendWorkspace(1,600,550,.5)
                near(workspaceParallax.x,-350)
                verify(workspaceParallax.moving)
                // Live camera events update the destination without restarting the tween.
                for(let i=0;i<8;i++) {
                    wait(100)
                    sendWorkspace(1,600+i,550,.5)
                }
                verify(!workspaceParallax.moving,"camera samples must not restart workspace entry")
                near(workspaceParallax.x,.35*(800-607*.5))
                near(workspaceParallax.scale,.825)
                workspaceParallax.active=false
                tryCompare(workspaceParallax,"moving",false,1000)
                near(workspaceParallax.x,0)
                workspaceParallax.active=true
                verify(workspaceParallax.moving,"mode resume also animates after settling")
                near(workspaceParallax.x,0)
                tryCompare(workspaceParallax,"moving",false,1000)
                near(workspaceParallax.x,.35*(800-607*.5))
            }
        }
    }
    Timer {
        interval:100; running:true
        onTriggered: {
            try {
                checks.test_return_camera_order_reversal_and_navigation()
                checks.test_workspace_resume_after_settling_and_direct_switch()
                console.info("WIDGET_PARALLAX_RETURN_OK")
            }
            catch(error) { console.error("WIDGET_PARALLAX_FAILED",String(error),error.stack) }
            Qt.quit()
        }
    }
    Timer { interval:12000; running:true; onTriggered: { console.error("WIDGET_PARALLAX_FAILED timeout"); Qt.quit() } }
}
