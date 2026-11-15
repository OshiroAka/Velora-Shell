import QtQuick
import QtTest
import QtQuick.Window
import Quickshell
import "../../core" as Core
import "../../components" as Components
import "../../features/topbar" as TopBar

ShellRoot {
  Window {
    visible: true
    width: 600; height: 420
    Core.InfiniteDesktopTransition { id: transition }
    Rectangle {
        id: frameStage
        width: 600; height: 380
        color: "black"
        Components.InfiniteDesktopFrame {
            id: frame
            anchors.fill: parent
            surface: "#ffffffff"
        }
    }
    QtObject {
        id: theme
        property color textPrimary: "white"
        property color accent: "#777777"
        property color accentSoft: "#aaaaaa"
        function withAlpha(color, alpha) { return Qt.rgba(color.r, color.g, color.b, alpha) }
    }
    QtObject { id: config; property bool reducedMotion: true }
    QtObject {
        id: sidebar
        property color desktopIconInk: "white"
        property real desktopIconSize: 22
        property real desktopIconOpacity: .8
        property string desktopAvatarSource: ""
    }
    QtObject {
        id: shell
        property var infiniteDesktopPanels: ({ fixture: sidebar })
        property bool infiniteDesktopMorphing: false
        function railMediaRequested() {}
        function railWhatsAppRequested() {}
    }
    QtObject {
        id: host
        property var screen: ({ name: "fixture" })
    }
    QtObject {
        id: status
        property bool muted: true
        property real volume: .5
        function adjustVolume(delta) {}
        function adjustBrightness(delta) {}
    }
    QtObject {
        id: actions
        function openSettings() {}
    }
    QtObject {
        id: controller
        property var owner: null
        property string activeType: ""
        property var registered: ({})
        function registerItem(type, item, host) { registered[type] = item }
        function unregisterItem(item) {}
        function enter(type, item, host) {}
        function leave(item) {}
        function toggle(type, item, host) { owner = host; activeType = type }
        function close() { activeType = ""; owner = null }
    }
    Rectangle {
        id: toolsStage
        y: 380
        width: 228; height: 40
        color: "black"
        TopBar.InfiniteDesktopTools {
            id: tools
            shell: shell; theme: theme; config: config; host: host
            status: status; actions: actions; controller: controller
            progress: 1
        }
    }
    TestCase {
        id: checks
        name: "InfiniteDesktopTransition"
        when: false
        function init() {
            transition.reducedMotion = true
            transition.active = false
            transition.transformBars = true
            transition.reducedMotion = false
            frame.progress = 0
            tools.reveal = 0
            controller.close()
            compare(transition.sourceReveal, 1)
            compare(transition.targetReveal, 0)
            compare(transition.progress, 0)
            compare(transition.frameFold, 0)
        }
        function test_canvas_without_special_topbar_preserves_bars_and_frame() {
            transition.transformBars = false
            transition.active = true
            wait(60)
            verify(transition.active, "The canvas must remain enabled")
            compare(transition.progress, 0)
            compare(transition.frameFold, 0)
            compare(transition.remaining, 1)
            compare(transition.railRemaining, 1)
            compare(transition.sourceReveal, 1)
            compare(transition.targetReveal, 0)
            verify(!transition.moving)
            transition.reducedMotion = true
            transition.transformBars = true
            compare(transition.frameFold, 1)
            transition.transformBars = false
            compare(transition.frameFold, 0)
            compare(transition.sourceReveal, 1)
            verify(transition.active)
        }
        function test_continuous_geometry_with_hidden_model_handoff() {
            transition.active = true
            let previous = 0, frames = 0
            while (transition.moving && frames < 100) {
                wait(16)
                const p = transition.progress
                verify(p >= previous, "Opening must move monotonically")
                verify(p-previous < .2, "Geometry must not jump between frames")
                compare(transition.frameFold,p)
                compare(transition.railRemaining,1-p)
                if (p >= .28 && p <= .68) {
                    compare(transition.sourceReveal,0)
                    compare(transition.targetReveal,0)
                }
                verify(transition.sourceReveal === 0 || transition.targetReveal === 0,
                       "Different item models must never overlap")
                previous=p; frames++
            }
            verify(frames > 8)
            compare(transition.progress,1)
            compare(transition.targetReveal,1)
            transition.active=false
            tryVerify(function() { return !transition.moving }, 1200)
            compare(transition.progress,0)
            compare(transition.sourceReveal,1)
            compare(transition.targetReveal,0)
        }
        function test_frame_morph_stays_anchored_and_restores() {
            for (const p of [0,.1,.25,.5,.75,.9,1,.75,.5,.25,0]) {
                frame.progress=p
                wait(25)
                const image=grabImage(frameStage)
                verify(image.red(0,200)>0,"Side border must never break into travelling blocks")
                verify(image.red(300,379)>0,"The bottom rim must stay anchored")
                compare(image.red(300,160),0,"Morph must leave the desktop interior free")
            }
            frame.progress=1
            wait(25)
            const dock=grabImage(frameStage)
            compare(dock.red(30,200),0,"Destination must release the old wide rail")
            verify(dock.red(2,365)>0,"Destination must retain its curved shelf")
            frame.progress=0
            wait(25)
            verify(grabImage(frameStage).red(30,200)>250,"Source rail must restore")
        }
        function test_live_icons_blur_fade_and_control_registration() {
            if (toolsStage.GraphicsInfo.api === GraphicsInfo.Software)
                skip("The software scene graph cannot draw MultiEffect shaders")
            wait(50)
            const volume = findChild(tools, "infiniteDesktopTool-volume")
            const wifi = findChild(tools, "infiniteDesktopTool-wifi")
            verify(volume && wifi)
            compare(volume.width, 34)
            compare(volume.height, 40)
            const hidden = grabImage(toolsStage)
            compare(hidden.red(29, 20), 0)
            tools.reveal = .4
            wait(60)
            verify(tools.layer.enabled)
            compare(volume.width, 34)
            compare(volume.height, 40)
            verify(!volume.interactive)
            const blurred = grabImage(toolsStage)
            tools.reveal = 1
            wait(60)
            verify(!tools.layer.enabled)
            verify(volume.interactive)
            const sharp = grabImage(toolsStage)
            let blurredPeak = 0, sharpPeak = 0, halo = false
            for (let y = 0; y < 40; ++y)
                for (let x = 12; x < 46; ++x) {
                    blurredPeak = Math.max(blurredPeak, blurred.red(x, y))
                    sharpPeak = Math.max(sharpPeak, sharp.red(x, y))
                    if (sharp.red(x, y) === 0 && blurred.red(x, y) > 2) halo = true
                }
            verify(blurredPeak > 0, "Intermediate blur fade must draw the icon")
            verify(halo, "Blur must spread the ink around the original silhouette")
            verify(sharpPeak > blurredPeak, "Fully revealed icon must regain its sharp ink")
            compare(controller.registered.volume, volume)
            mouseClick(volume)
            compare(controller.activeType, "volume")
            controller.close()
        }
        function test_reverse_without_jump() {
            transition.active = true
            wait(280)
            const before = transition.progress, foldBefore = transition.frameFold
            transition.active = false
            compare(transition.progress, before)
            compare(transition.frameFold, foldBefore)
            tryVerify(function() { return transition.progress < before }, 500)
            transition.active = true
            tryVerify(function() { return !transition.moving }, 1500)
            compare(transition.progress, 1)
            compare(transition.frameFold, 1)
            compare(transition.targetReveal, 1)
            compare(transition.sourceReveal, 0)
        }
        function test_reduced_motion_and_midflight_change() {
            transition.reducedMotion = true
            transition.active = true
            compare(transition.progress, 1)
            compare(transition.frameFold, 1)
            compare(transition.sourceReveal, 0)
            compare(transition.targetReveal, 1)
            verify(!transition.moving)
            transition.active = false
            compare(transition.progress, 0)
            compare(transition.frameFold, 0)
            compare(transition.sourceReveal, 1)
            compare(transition.targetReveal, 0)
            transition.reducedMotion = false
            transition.active = true
            wait(300)
            transition.reducedMotion = true
            compare(transition.progress, 1)
            compare(transition.frameFold, 1)
            compare(transition.targetReveal, 1)
            verify(!transition.moving)
        }
    }
  }
  Timer {
    interval: 100; running: true
    onTriggered: {
        try {
            for (const name of ["test_canvas_without_special_topbar_preserves_bars_and_frame",
                "test_continuous_geometry_with_hidden_model_handoff",
                "test_frame_morph_stays_anchored_and_restores", "test_reverse_without_jump",
                "test_reduced_motion_and_midflight_change"]) {
                checks.init(); checks[name]()
            }
            console.info("INFINITE_MORPH_OK")
        } catch (error) { console.error("INFINITE_MORPH_FAILED",String(error)) }
        Qt.quit()
    }
  }
}
