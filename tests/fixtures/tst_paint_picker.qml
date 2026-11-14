import QtQuick
import QtTest
import "../../components" as Components
Item {
    width: 400; height: 320
    Item {
        id: canvasHost
        width: 200; height: 100
        visible: false
        Components.VeloraWallpaperColorSampler { id: sampler; source: Qt.resolvedUrl("picker-colors.svg") }
    }
    SignalSpy { id: selection; target: sampler; signalName: "selected" }
    SignalSpy { id: cancel; target: sampler; signalName: "cancelled" }
    TestCase {
        name: "PaintPicker"; when: windowShown
        function test_1_sample_and_cancel() {
            canvasHost.visible = true
            tryCompare(sampler, "imageStatus", Image.Ready)
            tryCompare(sampler, "ready", true)
            wait(100)
            mouseClick(sampler, 32, 64)
            compare(selection.count, 1); compare(selection.signalArguments[0][0], "#ff0000")
            mouseClick(sampler, 170, 80)
            compare(selection.count, 2); compare(selection.signalArguments[1][0], "#0000ff")
            sampler.forceActiveFocus(); keyClick(Qt.Key_Escape); compare(cancel.count, 1)
            mouseClick(sampler, 30, 80, Qt.RightButton); compare(cancel.count, 2)
        }
        function test_2_contain() {
            selection.clear()
            sampler.fit = "contain"; canvasHost.height = 200
            wait(100)
            mouseClick(sampler, 30, 20)
            compare(selection.count, 1); compare(selection.signalArguments[0][0], "#000000")
            mouseClick(sampler, 30, 80)
            compare(selection.count, 2); compare(selection.signalArguments[1][0], "#ff0000")
        }

    }
}
