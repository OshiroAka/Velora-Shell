import QtQuick
import QtTest
import "../../core" as Core
import "../../components" as Components
import "../../features/topbar" as TopBar

Item {
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
        name: "InfiniteDesktopTransition"
        when: windowShown
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
        function test_fade_out_before_slide_and_blur_reveal_after_arrival() {
            transition.active = true
            wait(80)
            verify(transition.sourceReveal > 0 && transition.sourceReveal < 1)
            compare(transition.progress, 0, "Workspaces cannot slide before source icons disappear")
            compare(transition.frameFold, 0)
            compare(transition.targetReveal, 0)
            tryCompare(transition, "sourceReveal", 0, 500)
            wait(80)
            verify(transition.progress > 0 && transition.progress < 1)
            verify(transition.frameFold > 0 && transition.frameFold < 1)
            compare(transition.targetReveal, 0, "Topbar icons must stay hidden during the slide")
            tryCompare(transition, "progress", 1, 500)
            compare(transition.targetReveal, 0)
            tryCompare(transition, "frameFold", 1, 500)
            wait(30)
            verify(transition.targetReveal > 0 && transition.targetReveal < 1, "Reveal must animate instead of appearing suddenly")
            tryVerify(function() { return !transition.moving }, 500)
            compare(transition.targetReveal, 1)
            transition.active = false
            wait(70)
            verify(transition.targetReveal > 0 && transition.targetReveal < 1)
            compare(transition.progress, 1)
            compare(transition.sourceReveal, 0)
            tryCompare(transition, "targetReveal", 0, 500)
            wait(80)
            verify(transition.progress > 0 && transition.progress < 1)
            compare(transition.sourceReveal, 0)
            tryCompare(transition, "frameFold", 0, 500)
            wait(30)
            verify(transition.sourceReveal > 0 && transition.sourceReveal < 1)
            tryVerify(function() { return !transition.moving }, 500)
            compare(transition.sourceReveal, 1)
            compare(transition.progress, 0)
        }
        function test_frame_folds_through_corners_and_restores() {
            frame.progress = .5
            wait(60)
            const partial = grabImage(frameStage)
            compare(partial.red(2, 378), 0)
            compare(partial.red(300, 280), 0, "Bottom frame must leave the centre free")
            verify(partial.red(2, 289) > 0, "Corner must fold along its own edge")
            frame.progress = 1
            wait(40)
            const folded = grabImage(frameStage)
            compare(folded.red(2, 200), 0)
            compare(folded.red(300, 378), 0)
            frame.progress = 0
            tools.reveal = 0
            controller.close()
            wait(40)
            const restored = grabImage(frameStage)
            compare(restored.red(2, 200), 255)
            compare(restored.red(300, 378), 255)
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
