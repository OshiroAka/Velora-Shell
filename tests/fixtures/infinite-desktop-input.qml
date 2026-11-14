import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../components" as Components
ShellRoot {
    id: test
    property int stage: 0
    Window {
        visible: true; width: 400; height: 300
        Components.VeloraInfiniteDesktopGesture {
            id: gesture; anchors.fill: parent
            bridgePath: Quickshell.env("VELORA_TEST_BRIDGE")
        }
        TestCase { id: input; when: false }
    }
    Timer {
        interval: 20; running: true; repeat: true
        onTriggered: {
            try {
                const area=input.findChild(gesture,"infiniteDesktopPanInput")
                if (area.cursorShape!==Qt.ArrowCursor) throw Error("Canvas changed the pointer")
                if (test.stage===0) {
                    gesture.scrollBy(12,-8);gesture.scrollBy(3,6)
                    if (!gesture.scrolling || !gesture.dragging) throw Error("Scroll did not begin")
                    test.stage=1
                } else if (test.stage===1 && gesture.releasePending) {
                    if (gesture.bridgeReady) throw Error("Fixture must exercise release before READY")
                    test.stage=2
                } else if (test.stage===2 && !gesture.releasePending && !gesture.bridgeReady) {
                    input.mousePress(area,20,20,Qt.RightButton)
                    input.mouseMove(area,50,40)
                    input.mouseRelease(area,50,40,Qt.RightButton)
                    test.stage=3
                } else if (test.stage===3 && !gesture.releasePending && !gesture.bridgeReady) {
                    input.mouseClick(area,20,20,Qt.LeftButton)
                    if (gesture.dragging) throw Error("Left click started a drag")
                    console.info("INFINITE_INPUT_OK");Qt.quit()
                }
            } catch(error) { console.error("INFINITE_INPUT_FAILED",String(error));Qt.quit() }
        }
    }
    Timer { interval:5000;running:true;onTriggered:{ console.error("INFINITE_INPUT_FAILED timeout");Qt.quit() } }
}
