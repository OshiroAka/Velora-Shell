import QtQuick
import QtQuick.Window
import Quickshell
import "../../components" as Components
ShellRoot {
    id: test
    property int stage: 0
    function check(value, message) { if (!value) throw Error(message) }
    function event(phase, monitor, screen) {
        return "velora-terminal-rectangle>>" + JSON.stringify({phase: phase,
            monitor: monitor || "DP-1", workspace: 4,
            screen: screen || [300, 200, 1200, 600], world: [-3200, 20, 2400, 1200]})
    }
    Window {
        visible: true; width: 1920; height: 1080
        Components.VeloraInfiniteDesktopGesture {
            id: gesture; anchors.fill: parent
            monitorName: "DP-1"
            bridgePath: Quickshell.env("RECT_BRIDGE")
        }
    }
    Timer {
        interval: 50; running: true; repeat: true
        onTriggered: {
            try {
                if (test.stage === 0) {
                    const preview = gesture.children.find(child => child.objectName === "terminalRectanglePreview")
                    gesture.selectionAccent = "#de4924"
                    test.check(Math.abs(preview.border.color.r - 222/255) < .01, "Border ignored accent")
                    test.check(Math.abs(preview.color.r - 222/255) < .01 && preview.color.a > .05 && preview.color.a < .2, "Fill ignored accent/alpha")
                    gesture.selectionAccent = "#428fde"
                    test.check(Math.abs(preview.border.color.b - 222/255) < .01 && Math.abs(preview.border.color.r - 66/255) < .01, "Preview did not follow palette change")
                    test.check(!gesture.readTerminalEvent("velora-terminal-rectangle>>{"), "Malformed event accepted")
                    test.check(!gesture.readTerminalEvent(test.event("begin", "DP-2")), "Other output accepted")
                    test.check(gesture.readTerminalEvent(test.event("begin")), "Begin rejected")
                    test.check(gesture.terminalSelection.screen[0] === 300, "Preview misplaced")
                    gesture.readTerminalEvent(test.event("cancel"))
                    test.check(gesture.terminalSelection === null, "Cancel left preview")
                    gesture.readTerminalEvent(test.event("end", "DP-1", [0,0,10,10]))
                    test.check(gesture.terminalQueue.length === 0, "Tiny click launched terminal")
                    gesture.readTerminalEvent(test.event("begin"))
                    gesture.readTerminalEvent(test.event("update"))
                    gesture.readTerminalEvent(test.event("end"))
                    gesture.readTerminalEvent(test.event("begin"))
                    gesture.readTerminalEvent(test.event("end"))
                    test.check(gesture.terminalSelection === null, "Release left preview")
                    test.stage = 1
                } else if (++test.stage > 14) {
                    test.check(gesture.terminalQueue.length === 0, "Launch queue stuck")
                    console.info("TERMINAL_QML_OK"); Qt.quit()
                }
            } catch (error) { console.error("TERMINAL_QML_FAILED", String(error)); Qt.quit() }
        }
    }
}
