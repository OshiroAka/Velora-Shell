import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../core" as Core
import "../../components" as Components
import "../../features/topbar" as Topbar

ShellRoot {
    id: test
    property int stage: 0
    property int clicks: 0
    property real topPeak: 0
    property real sidePeak: 0
    function check(value, message) { if (!value) throw Error(message) }
    function find(item,name) { if(item.objectName===name)return item;for(const child of item.children||[]){const result=find(child,name);if(result)return result}return null }
    QtObject { id: config; property bool reducedMotion: false; property string motionPreset: "balanced" }
    Core.Motion { id: tokens; config: config }
    QtObject { id: palette; property var config: config; property color accent: "#8ac"; property color accentSoft: "#abc"
        property color borderSubtle: "#444";property color textPrimary: "white";property color textSecondary: "gray";property string bodyFont: "Sans"
        function withAlpha(color,alpha){return Qt.rgba(color.r,color.g,color.b,alpha)} }
    QtObject { id: system }
    QtObject { id: controller; property var anchorItem: trigger; function close(){popup.desiredType=""} }
    TestCase { id: input; name: "DepthMotionInput"; when: false }
    Window {
        width: 900; height: 700; visible: true
        Item { id: trigger; x: 420; width: 64; height: 40 }
        Topbar.MorphPopover { id: popup; anchors.fill: parent; controller: controller; motion: tokens }
        Components.VeloraRailPopover {
            id: rail; anchors.fill: parent; theme: palette; system: system; motion: tokens
            closeOnLeave: false; anchorY: 340
            customContent: Component {
                Item {
                    Item { objectName: "railAction"; width: 80; height: 40
                        MouseArea { anchors.fill: parent; onClicked: test.clicks++ }
                    }
                }
            }
        }
        Components.VeloraSettingsTabs { id: tabs; x: 390; y: 400; width: 300; theme: palette; motion: tokens
            options: [{id:"a",label:"A"},{id:"b",label:"B"},{id:"c",label:"C"}];selected: "a" }
        Topbar.WorkspaceSwitcher { id: workspaces; x: 390;y: 500;width: 176;height: 32;theme: palette;reducedMotion: config.reducedMotion }
        Item {
            id: iconButton; x: 50; y: 600; width: 80; height: 60
            Components.VeloraIconMotion { id: icon; highlighted: true; reducedMotion: config.reducedMotion }
            Rectangle { width: 20; height: 20; anchors.centerIn: parent; color: "white"
                transform: Translate { x: icon.drift; y: icon.lift } }
            MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: test.clicks++ }
        }
    }
    FrameAnimation {
        running: test.stage<=1
        onTriggered: { test.topPeak=Math.max(test.topPeak,popup.reveal);test.sidePeak=Math.max(test.sidePeak,rail.reveal) }
    }
    Timer {
        id: drive
        interval: 30;running: true;repeat: true
        onTriggered: {
            try {
                switch(test.stage) {
                case 0:
                    popup.desiredType="timer";rail.open();test.stage=1;interval=380;break
                case 1:
                    test.check(test.topPeak>1.003 && test.sidePeak>1.003,"Connected openings must overshoot subtly")
                    test.check(popup.reveal===1 && rail.reveal===1,"Open surfaces must settle exactly")
                    test.check(popup.panelRect.x>=8 && popup.panelRect.x+popup.panelRect.width<=892,"Connected geometry exceeded the viewport")
                    input.mouseClick(test.find(rail,"railAction"),20,20)
                    input.mouseMove(iconButton,75,50)
                    test.stage=2;interval=160;break
                case 2:
                    test.check(icon.drift>.8 && icon.drift<=1.25,"Glyph must follow the pointer within a small bound")
                    input.mouseClick(iconButton,40,30)
                    test.check(test.clicks===2,"Decorative motion stole a control click")
                    tabs.selected="b";workspaces.activeWorkspaceId=4
                    popup.desiredType="";rail.close();test.stage=3;interval=25;break
                case 3:
                    const pose=popup.reveal
                    popup.desiredType="notes";rail.open()
                    test.check(popup.mounted && popup.reveal===pose,"Reversing an opening must retain its current pose")
                    config.reducedMotion=true
                    test.check(tabs.indicatorX===102,"Reduced motion must finish an in-flight selection")
                    test.check(workspaces.selectedCenter===workspaces.targetCenter && workspaces.travel===0,"Reduced motion must stop workspace settling immediately")
                    tabs.selected="c"
                    test.check(popup.reveal===1 && rail.reveal===1,"Reduced motion must settle connected surfaces immediately")
                    test.check(icon.drift===0 && icon.lift===0 && icon.zoom===1,"Reduced motion must remove decorative parallax")
                    test.check(tabs.indicatorX===202,"Reduced motion must keep selection direct")
                    popup.desiredType="";rail.close()
                    test.check(!popup.mounted && !rail.mounted,"Reduced close must unmount immediately")
                    console.info("DEPTH_MOTION_OK",JSON.stringify({topPeak:test.topPeak,sidePeak:test.sidePeak,clicks:test.clicks}))
                    Qt.quit();break
                }
            } catch(error) {console.error("DEPTH_MOTION_FAILED",String(error));Qt.quit()}
        }
    }
}
