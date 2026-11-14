import QtQuick
import QtTest
import "../../core" as Core
import "../../features/lock" as Lock

Item {
    id: stage
    width: 1586; height: 992
    Lock.LockScene {
        id: scene; anchors.fill: parent
        timeText: "04:30"; dateText: "Sex, 13 de Novembro"; dayText: "07"
        title: "Lofi Nature"; artist: "Chill Study"; playing: true
        wallpaperSource: Qt.resolvedUrl("fixture-landscape.svg"); artworkSource: wallpaperSource
        batteryAvailable: true; batteryProgress: .68; mediaProgress: .36
        onAuthenticationRequested: secret => {
            fake.accepted = secret === "demo-only"
            scene.busy = true; fakeReply.restart()
        }
    }
    QtObject { id: fake; property bool accepted: false; property int replies: 0 }
    Timer {
        id: fakeReply; interval: 80
        onTriggered: {
            scene.busy = false; fake.replies++
            if (!fake.accepted) scene.authenticationError = "Senha fictícia incorreta"
        }
    }
    QtObject { id: motion; property int widgetExit: 80 }
    Core.PreviewController { id: previewController; motion: motion; exitDuration: 80 }
    SignalSpy { id: mediaSpy; target: scene; signalName: "mediaRequested" }
    SignalSpy { id: powerSpy; target: scene; signalName: "powerRequested" }
    SignalSpy { id: closeSpy; target: scene; signalName: "closeRequested" }
    TestCase {
        name: "NewLockscreen"; when: windowShown
        function item(name) { const found = findChild(scene, name); verify(!!found, name); return found }
        function init() {
            fakeReply.stop(); scene.busy = false
            scene.reducedMotion = true; scene.presented = true
            scene.authenticationAvailable = false; scene.authenticationError = ""
            scene.notice = ""; scene.mediaAvailable = false
            stage.width = 1586; stage.height = 992
            mediaSpy.clear(); powerSpy.clear(); closeSpy.clear()
            scene.clearSecret(); wait(30)
        }
        function test_preview_controller_rapid_close_reopen_and_release() {
            verify(!previewController.mounted)
            previewController.show(); previewController.hide()
            compare(previewController.shown, false); verify(previewController.occluding)
            wait(40); previewController.show(); wait(200)
            verify(previewController.shown && previewController.occluding)
            previewController.hide(); tryCompare(previewController, "occluding", false)
            compare(previewController.mounted, false)
        }
        function test_pending_integrations_do_not_authenticate_or_operate_system() {
            const field = item("lockPassword")
            verify(field.readOnly)
            item("lockSubmit").activate()
            verify(scene.notice.indexOf("pendente") >= 0)
            item("lockPlay").activate(); compare(mediaSpy.count, 0)
            const power = item("lockPower")
            mouseClick(power, power.width/2, power.height/2); compare(powerSpy.count, 1)
            verify(scene.notice.indexOf("pendentes") >= 0)
            field.forceActiveFocus(); keyClick(Qt.Key_Escape); compare(closeSpy.count, 1)
        }
        function test_fake_password_wrong_correct_busy_and_clear() {
            scene.authenticationAvailable = true
            const field = item("lockPassword"), morph = item("lockPasswordMorph")
            field.forceActiveFocus(); keyClick(Qt.Key_X)
            compare(field.echoMode, TextInput.Password)
            keyClick(Qt.Key_Return)
            verify(scene.busy); compare(field.text, "")
            verify(field.readOnly); verify(!item("lockSubmit").enabled)
            tryCompare(scene, "busy", false)
            verify(scene.authenticationError.length > 0); compare(morph.height, 92)
            field.forceActiveFocus(); keyClick(Qt.Key_D)
            compare(scene.authenticationError, "")
            field.text = "demo-only"; keyClick(Qt.Key_Return)
            tryCompare(scene, "busy", false)
            verify(fake.accepted); compare(field.text, "")
            field.text = "discard-me"; scene.presented = false
            compare(field.text, "")
        }
        function test_reversal_glow_focus_and_reduced_motion() {
            scene.presented = false; wait(20)
            scene.reducedMotion = false; scene.presented = true
            wait(140); verify(scene.reveal > 0 && scene.reveal < 1)
            const pose = scene.reveal
            scene.presented = false; wait(40); verify(scene.reveal <= pose)
            scene.presented = true; tryCompare(scene, "entrance", 1, 1200)
            const button = item("lockSettings")
            button.forceActiveFocus(); wait(70)
            verify(button.emphasis > 0 && button.emphasis < 1)
            tryCompare(button, "emphasis", 1)
            scene.claimFocus(); mouseMove(scene, 20, 20); tryCompare(button, "emphasis", 0)
            mouseMove(button, button.width/2, button.height/2); tryCompare(button, "emphasis", 1)
            scene.presented = false; tryCompare(scene, "entrance", 0); scene.presented = true; wait(65)
            verify(scene.reveal > 0 && scene.reveal < 1)
            scene.reducedMotion = true; compare(scene.reveal, 1)
            scene.presented = false
            compare(scene.reveal, 0); compare(scene.motionRunning, false)
            scene.presented = true; compare(scene.reveal, 1)
            verify(!scene.motionRunning)
        }
        function test_keyboard_media_and_geometry_data() {
            return [
                {tag:"reference",w:1586,h:992}, {tag:"fullhd",w:1920,h:1080},
                {tag:"ultrawide",w:3440,h:1440}, {tag:"small",w:800,h:600},
                {tag:"portrait",w:600,h:950}, {tag:"phone",w:390,h:844}
            ]
        }
        function test_keyboard_media_and_geometry(data) {
            stage.width=data.w;stage.height=data.h; wait(20)
            scene.mediaAvailable = true
            const button = item("lockPlay"); button.forceActiveFocus(); keyClick(Qt.Key_Return)
            compare(mediaSpy.count, 1); compare(mediaSpy.signalArguments[0][0], "toggle")
            for (const name of ["lockClock","lockMedia","lockPasswordMorph","lockPower","lockSettings"]) {
                const control=item(name), point=control.mapToItem(scene,0,0)
                verify(point.x >= 0 && point.y >= 0, name+" origin "+data.tag)
                verify(point.x + control.width*scene.designScale <= scene.width+.1, name+" width "+data.tag)
                verify(point.y + control.height*scene.designScale <= scene.height+.1, name+" height "+data.tag)
            }
            scene.mediaAvailable = false; button.activate(); compare(mediaSpy.count, 1)
        }
        function test_visual_preview() {
            console.info("LOCK_GRAPHICS_API", scene.GraphicsInfo.api)
            scene.mediaAvailable = true; scene.claimFocus(); wait(100)
            const shot = grabImage(stage)
            verify(shot.width > 0); verify(shot.height > 0)
            shot.save("@PREVIEW@")
        }
    }
}
