import QtQuick
import QtQuick.Window
import Quickshell
import "../../core" as Core
import "../../features/topbar" as Topbar

ShellRoot {
    id: test
    property int stage: 0
    property int destination: 1
    property int usableSamples: 0
    property bool retained: true
    readonly property var types: ["timer", "caffeine", "notes", "paint", "battery", "toolbox", "clock"]
    function check(value, message) { if (!value) throw Error(message) }
    Core.Motion { id: tokens }
    QtObject { id: host; property var screen: ({name: "fixture"}) }
    Topbar.TopBarController { id: controller; motion: tokens }
    Window {
        width: 1280; height: 800; visible: true
        Repeater {
            id: triggers
            model: test.types.length
            delegate: Item { required property int index; x: 180 + index * 160; width: 64; height: 40 }
        }
        Topbar.MorphPopover {
            id: popup
            anchors.fill: parent
            controller: controller; motion: tokens
            desiredType: controller.owner === host ? controller.activeType : ""
            onMountedChanged: if (test.stage === 2 && !mounted) test.retained = false
        }
    }
    Timer {
        id: drive
        interval: 40; running: true; repeat: true
        onTriggered: {
            try {
                switch (test.stage) {
                case 0:
                    controller.enter("timer", triggers.itemAt(0), host)
                    test.check(!controller.opened, "First hover must retain its intent delay")
                    test.stage = 1; interval = 450
                    break
                case 1:
                    test.check(popup.interactive && controller.activeType === "timer", "Initial opening did not settle")
                    test.stage = 2; interval = 70
                    break
                case 2:
                    if (popup.interactive) test.usableSamples++
                    if (test.destination < test.types.length) {
                        const i = test.destination++
                        const pose = popup.currentPose()
                        controller.leave(triggers.itemAt(i - 1))
                        if (controller.supportsHover(test.types[i])) controller.enter(test.types[i], triggers.itemAt(i), host)
                        else controller.toggle(test.types[i], triggers.itemAt(i), host)
                        test.check(controller.activeType === test.types[i], "Hot handoff delayed the destination")
                        popup.currentPose().forEach((value, axis) => test.check(Math.abs(value - pose[axis]) < .01,
                            "Handoff jumped instead of starting at the current pose"))
                    } else {
                        test.check(test.retained, "Handoff unmounted the shared surface")
                        test.check(test.usableSamples >= 2, "Rapid retargeting repeatedly hid the content")
                        test.stage = 3; interval = 350
                    }
                    break
                case 3:
                    test.check(popup.interactive && popup.presentedType === "clock", "Last hover destination is stale")
                    test.check(Math.abs(popup.handoffProgress - 1) < .001, "Shared geometry handoff did not settle")
                    controller.close()
                    test.check(popup.mounted, "Close must animate before unmounting")
                    test.stage = 4; interval = 30
                    break
                case 4:
                    controller.show("notes", triggers.itemAt(2), host, false)
                    test.check(popup.mounted, "Reopening during close lost the surface")
                    test.stage = 5; interval = 350
                    break
                case 5:
                    test.check(popup.interactive && popup.presentedType === "notes", "Reopening did not recover")
                    controller.hoveredItem = triggers.itemAt(2)
                    controller.close(true)
                    controller.enter("notes", triggers.itemAt(2), host)
                    test.check(!controller.opened, "Explicit close reopened under the same pointer")
                    test.stage = 6; interval = 250
                    break
                case 6:
                    test.check(!popup.mounted, "Closed surface stayed mounted")
                    tokens.reduced = true
                    controller.leave(triggers.itemAt(2))
                    controller.show("paint", triggers.itemAt(3), host, false)
                    test.check(popup.interactive && popup.handoffProgress === 1, "Reduced motion did not settle synchronously")
                    controller.close()
                    test.check(!popup.mounted, "Reduced-motion close stayed mounted")
                    console.info("TOPBAR_HANDOFF_OK", JSON.stringify({hotDestinations: test.types.length - 1, usableSamples: test.usableSamples}))
                    Qt.quit()
                    break
                }
            } catch (error) {
                console.error("TOPBAR_HANDOFF_FAILED", String(error), error.stack)
                Qt.quit()
            }
        }
    }
    Timer { interval: 8000; running: true; onTriggered: { console.error("TOPBAR_HANDOFF_FAILED timeout"); Qt.quit() } }
}
