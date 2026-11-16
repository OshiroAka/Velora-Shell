import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "components" as Components
import "features/topbar" as Topbar
import "core" as Core

ShellRoot {
    id: fixture
    QtObject {
        id: theme
        property color textPrimary: "#d8dfd6"
        property color textSecondary: "#a5aba3"
        property color barSurface: "#111311"
        property color danger: "#ef7c7c"
        property color accent: textPrimary
        property color accentSoft: textPrimary
        property string bodyFont: "DejaVu Sans"
        function withAlpha(color, amount) { return Qt.rgba(color.r,color.g,color.b,amount) }
    }
    QtObject {
        id: media
        property bool playing: true
        property bool hasPlayer: true
        property bool canToggle: true
        property bool canPrevious: true
        property bool canNext: true
        property bool canSeek: true
        property string title: "Música"
        property string artist: "Artista"
        property real length: 220
        property real sampledPosition: 84
        property real progress: sampledPosition / length
        property int previousCount: 0
        property int nextCount: 0
        function previous() { previousCount++ }
        function next() { nextCount++ }
        function togglePlaying() { playing = !playing }
        function seekTo(value) { sampledPosition = value }
    }
    QtObject {
        id: audio
        property bool hasAudio: true
        property bool muted: false
        property real volume: .61
        property int volumePercent: Math.round(volume*100)
        property var audioSink: ({audio: audio})
        function toggleMuted() { muted = !muted }
    }
    QtObject {
        id: tools
        property var capabilities: ({area:{available:true},screen:{available:true},text:{available:true},eyedropper:{available:true},record:{available:true}})
        property var outputs: [{id:"12", name:"Fones de ouvido", selected:true}, {id:"20", name:"Monitor", selected:false}]
        property bool busy: false
        property bool recording: false
        property string error: ""
        property string called: ""
        property int refreshCount: 0
        property string output: ""
        property bool visibleAtCapture: true
        function refresh() { refreshCount++ }
        function run(value) { called = value; visibleAtCapture = menu.mounted || topMenu.mounted }
        function stopRecording() { recording = false }
        function selectOutput(id) { output = id }
    }
    QtObject { id: settings; property bool reducedMotion: false }
    Core.Motion { id: motion; config: settings }
    Topbar.TopBarController { id: controller; motion: motion }
    QtObject { id: host; property var screen: ({name:"Fixture"}) }
    QtObject {
        id: shell
        property var composition: ({profileToolsService:tools, configStore:{profileName:"Seu perfil"}})
        property var infiniteDesktopPanels: ({Fixture:{desktopAvatarSource:""}})
    }
    Window {
        id: window
        width: 1000; height: 650; visible: true; color: "#090b09"
        Rectangle { x:0; y:0; width:64; height:parent.height; color:theme.barSurface }
        Rectangle {
            x:64; y:menu.bodyY; width:menu.bodyWidth; height:menu.bodyHeight
            color:theme.barSurface; radius:18; visible:menu.mounted
        }
        Components.VeloraRailProfile {
            id: menu
            anchors.fill: parent
            theme: theme; system: tools; media: media; status: audio; tools: tools
            anchorY: 550
        }
        Components.VeloraRailPopover {
            id: other
            anchors.fill: parent
            theme:theme; system:tools
            preferredWidth:300; preferredHeight:200
            handoffSource:menu
            customContent: Component { Item {} }
        }
        Item { id: topAnchor; x:550; width:32; height:40 }
        Topbar.ConnectedPopover {
            id: topMenu
            anchors.fill: parent
            host:host; controller:controller; motionTokens:motion
            config:settings; theme:theme; status:audio; system:tools; fanPlus:tools
            timerService:tools; clock:tools; calendar:tools; media:media; actions:tools
            weather:tools; shell:shell
        }
    }
    TestCase {
        id: tests
        name: "ProfileMenu"
        when: true
        windowShown: true
        function find(item, name) {
            if (item.objectName === name) return item
            for (const child of item.children || []) {
                const result = find(child, name)
                if (result) return result
            }
            return null
        }
        function button(name) { const result=find(menu,name);verify(!!result,name);return result }
        function click(name) { const item=button(name);mouseClick(item,item.width/2,item.height/2) }
        function init() {
            controller.close();tryCompare(topMenu,"mounted",false,2000)
            other.closeInstant();menu.closeInstant();menu.motion.reduced=false
            window.width=1000;window.height=650;menu.rightSide=false
            menu.pendingAction="";tools.called="";tools.busy=false;tools.recording=false
            menu.open();tryCompare(menu,"contentReveal",1,2000)
        }
        function cleanup() {
            if (qtest_results.failed) console.error("PROFILE_CASE_FAILED", qtest_results.functionName)
        }
        function cleanupTestCase() {
            console.info("PROFILE_MENU_RESULTS", qtest_results.passCount, qtest_results.failCount)
            if (qtest_results.failCount === 0 && qtest_results.passCount >= 6) console.info("PROFILE_MENU_OK")
            else console.error("PROFILE_MENU_FAILED", qtest_results.failCount)
        }
        function test_controls() {
            click("profile-play");verify(!media.playing)
            click("profile-next");compare(media.nextCount,1)
            click("profile-previous");compare(media.previousCount,1)
            click("profile-mute");verify(audio.muted)
            const volume=button("profile-volume")
            mouseClick(volume,volume.width*.3,volume.height/2);verify(audio.volume>.2 && audio.volume<.4)
            const progress=button("profile-progress")
            mouseClick(progress,progress.width*.7,progress.height/2);verify(media.sampledPosition>130)
            click("profile-output");verify(button("profile-output-list").visible)
            // Closing via Escape keeps the services intact.
            menu.forceActiveFocus();keyClick(Qt.Key_Escape);tryCompare(menu,"mounted",false,1500)
        }
        function test_capture_waits_for_morph() {
            click("profile-tool-area")
            compare(tools.called,"");verify(menu.mounted)
            tryCompare(menu,"mounted",false,1500)
            compare(tools.called,"area");verify(!tools.visibleAtCapture)
        }
        function test_reverse_handoff_bounds_and_reduced_motion() {
            menu.close();wait(45)
            const width=menu.bodyWidth;menu.open();verify(Math.abs(menu.bodyWidth-width)<.01)
            tryCompare(menu,"reveal",1,1500)
            other.open();verify(!menu.mounted);verify(other.bodyWidth>700)
            menu.handoffSource=other;menu.open();verify(!other.mounted)
            tryCompare(menu,"handoffActive",false,1500)
            window.width=700;window.height=480;menu.rightSide=true;wait(80)
            verify(menu.bodyWidth<=window.width-80)
            verify(menu.bodyY>=menu.verticalMargin)
            verify(menu.bodyY+menu.bodyHeight<=window.height-menu.verticalMargin+.1)
            menu.motion.reduced=true;menu.close();verify(!menu.mounted)
            menu.open();compare(menu.reveal,1);compare(menu.contentReveal,1);verify(!menu.animating)
        }
        function test_recording_and_no_player() {
            tools.recording=true;tools.busy=true
            click("profile-tool-record");verify(!tools.recording)
            media.hasPlayer=false;media.canToggle=false;media.canPrevious=false;media.canNext=false;media.canSeek=false
            wait(20);verify(!button("profile-play").enabled)
            verify(!button("profile-progress").enabled)
        }
        function test_topbar_uses_same_content_and_waits_for_close() {
            menu.closeInstant()
            controller.show("profile",topAnchor,host,false)
            tryCompare(topMenu,"mounted",true,1500);wait(450)
            const capture=find(topMenu,"profile-tool-screen")
            verify(!!capture);verify(capture.enabled)
            verify(topMenu.panelRect.width>790)
            mouseClick(capture,capture.width/2,capture.height/2)
            compare(tools.called,"");verify(topMenu.mounted)
            tryCompare(topMenu,"mounted",false,2000)
            compare(tools.called,"screen");verify(!tools.visibleAtCapture)
        }
        function test_visual() {
            media.hasPlayer=true;media.playing=true;media.canToggle=true;media.canNext=true;media.canPrevious=true
            audio.muted=false;audio.volume=.61;media.sampledPosition=84
            wait(250)
            if (Quickshell.env("PROFILE_PREVIEW")) {
                let saved=false
                window.contentItem.grabToImage(result => { result.saveToFile(Quickshell.env("PROFILE_PREVIEW"));saved=true })
                tryVerify(() => saved,2000)
            }
        }
    }
}
