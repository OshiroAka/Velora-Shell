import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../core" as Core
import "../../features/editor" as Editor
ShellRoot {
    id: test
    Core.ConfigStore { id: config }
    Core.Motion { id: motion; config: config }
    QtObject {
        id: theme
        property color textPrimary: "#f4f4f6"
        property color textSecondary: "#bdbdc5"
        property color accent: "#c8788f"
        property color borderSubtle: "#40404a"
        property string bodyFont: "Sans Serif"
        function withAlpha(c,a) { return Qt.rgba(c.r,c.g,c.b,a) }
    }
    property int stage: 0
    function check(ok,message) { if(!ok) throw Error(message) }
    Window {
        id: win; width: Quickshell.env("VELORA_DESK_RELOAD")==="1" ? 400 : 800
        height: 850; visible: true; color: "#202027"
        Flickable {
            anchors.fill: parent; anchors.margins: 16
            contentHeight: page.implicitHeight
            Editor.SettingsInfiniteDesk { id: page; width: parent.width; config: config; theme: theme; motion: motion }
        }
        TestCase { id: input; when: false }
    }
    function typeNumber(spin, digits) {
        spin.contentItem.forceActiveFocus()
        input.keyClick(Qt.Key_A,Qt.ControlModifier)
        for (let i=0;i<digits.length;i++) input.keyClick(Qt.Key_0+Number(digits[i]))
        input.keyClick(Qt.Key_Return)
    }
    Timer {
        interval: 60; running: true; repeat: true
        onTriggered: {
            if (!config.ready) return
            try {
                if (test.stage===0) {
                    test.stage=-1
                    if (Quickshell.env("VELORA_DESK_RELOAD")==="1") {
                        check(config.infiniteDeskSizes.length===1 && config.infiniteDeskSizes[0].width===960
                            && config.infiniteDeskSizes[0].height===640,"dimensions lost after restart")
                        check(config.infiniteDeskDragSensitivity===4,"sensitivity lost after restart")
                        check(config.infiniteDeskWindowSpacing===3,"window spacing lost after restart")
                        test.stage=1;return
                    }
                    check(config.infiniteDeskSizes.length===3,"three initial sizes")
                    config.setValue("appearance.reducedMotion",true)
                    const add=input.findChild(page,"infiniteDesk.addSize")
                    input.mouseClick(add,20,16);input.mouseClick(add,20,16)
                    check(config.infiniteDeskSizes.length===5,"plus must allow more than three sizes")
                    for (let i=4;i>0;i--) {
                        const remove=input.findChild(page,"infiniteDesk.removeSize"+i)
                        remove.forceActiveFocus();input.keyClick(Qt.Key_Space)
                    }
                    check(config.infiniteDeskSizes.length===1,"delete must allow one size")
                    check(!input.findChild(page,"infiniteDesk.removeSize0").enabled,"last size must be retained")
                    test.typeNumber(input.findChild(page,"infiniteDesk.width0"),"960")
                    test.typeNumber(input.findChild(page,"infiniteDesk.height0"),"640")
                    check(config.infiniteDeskSizes[0].width===960 && config.infiniteDeskSizes[0].height===640,"typing dimensions did not save")
                    const slider=input.findChild(page,"infiniteDesk.sensitivity")
                    input.mouseClick(slider.controlItem,slider.controlItem.width-1,16)
                    check(config.infiniteDeskDragSensitivity===4,"sensitivity slider disconnected")
                    slider.controlItem.forceActiveFocus();input.keyClick(Qt.Key_Left)
                    check(config.infiniteDeskDragSensitivity<4,"sensitivity keyboard disconnected")
                    const reset=input.findChild(slider,"infiniteDesk.sensitivity.reset")
                    reset.forceActiveFocus();input.keyClick(Qt.Key_Space)
                    check(config.infiniteDeskDragSensitivity===1.15,"sensitivity reset disconnected")
                    input.mouseClick(slider.controlItem,slider.controlItem.width-1,16)
                    const spacing=input.findChild(page,"infiniteDesk.spacing")
                    input.mouseClick(spacing.controlItem,spacing.controlItem.width-1,16)
                    check(config.infiniteDeskWindowSpacing===3,"window spacing slider disconnected")
                    input.mouseClick(spacing.controlItem,0,16)
                    check(config.infiniteDeskWindowSpacing===0,"windows cannot be brought closer")
                    const resetSpacing=input.findChild(spacing,"infiniteDesk.spacing.reset")
                    resetSpacing.forceActiveFocus();input.keyClick(Qt.Key_Space)
                    check(config.infiniteDeskWindowSpacing===1,"window spacing reset disconnected")
                    input.mouseClick(spacing.controlItem,spacing.controlItem.width-1,16)
                    test.stage=1
                } else if (test.stage===1 && !config.savePending) {
                    check(!config.saveError,"save failed")
                    const screenshot=Quickshell.env("VELORA_DESK_SCREENSHOT")
                    if (screenshot) win.contentItem.grabToImage(result=>{result.saveToFile(screenshot);console.info("INFINITE_SETTINGS_OK");Qt.quit()})
                    else { console.info("INFINITE_SETTINGS_OK");Qt.quit() }
                    test.stage=2
                }
            } catch(error) {console.error("INFINITE_SETTINGS_FAILED",String(error));Qt.quit()}
        }
    }
    Timer { interval:8000;running:true;onTriggered:{console.error("INFINITE_SETTINGS_FAILED timeout");Qt.quit()} }
}
