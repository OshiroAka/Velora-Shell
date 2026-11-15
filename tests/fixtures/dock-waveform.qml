import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../components" as Components
import "../../services" as Services

ShellRoot {
    id: test
    QtObject {
        id: config
        property var infiniteDeskPinnedItems: []
        property bool reducedMotion: false
        property bool barBackgroundEnabled: true
        property bool infiniteDeskOutlineIcons: false
    }
    QtObject {
        id: theme
        property color barSurface: "#080b12"
        property color textPrimary: "white"
        property color accent: "#c8788f"
        property string bodyFont: "Sans Serif"
        function withAlpha(color,alpha) { return Qt.rgba(color.r,color.g,color.b,alpha) }
    }
    QtObject { id: shell; function openUnifiedSettings() {} function toggleTopSearch() {} }
    QtObject {
        id: audio
        property bool running: true
        property var frame: Array(96).fill(0)
        property int reads: 0
        signal bandsChanged()
        function materialFrame() { reads++; return frame.join(" ") }
        function publish(value) { frame=Array(96).fill(value); bandsChanged() }
    }
    Services.VisualizerDemand { id: demand }
    Window {
        id: win
        width: 1280; height: 720; visible: true; color: "white"
        Components.InfiniteDesktopDock {
            id: dock
            anchors.fill: parent
            config: config; theme: theme; shell: shell; screen: Quickshell.screens[0]
            visualizer: audio
            progress: 1; reveal: 1
        }
        TestCase {
            id: input
            when: false
            function check(value,message) { if (!value) throw Error(message) }
            function run() {
                const wave=dock.waveform
                check(!wave.visible,"Empty dock must not gain a waveform")
                demand.dockVisible=true
                check(demand.active,"Dock does not request audio")
                demand.editingDesktop=true; check(!demand.active,"Editor must stop dock audio")
                demand.editingDesktop=false; demand.dockVisible=false
                check(!demand.active,"Hidden consumers must release audio")
                config.infiniteDeskPinnedItems=["shell:settings","shell:search"]
                wait(100)
                check(wave.active,"Pinned dock waveform is missing")
                check(Math.abs(wave.x+wave.width/2-dock.width/2)<.1,"Wave must follow the dock centre")
                check(Math.abs(wave.y+wave.height-dock.dockInput.y)<.1,"Wave must touch the dock top and stay entirely above it")
                check(wave.ink===dock.surface,"Wave must use the bar colour")
                check(dock.dockInput.z>wave.z,"App icons must stay above the trace")
                check(wave.width === dock.dockWidth,"Wave does not follow the app list width")
                const flat=grabImage(wave)
                check(flat.red(Math.floor(wave.width/2),Math.floor(wave.height)-1)<150,"Silent waveform lost its baseline")
                check(wave.level===0,"Silence must settle flat")
                audio.publish(.8); wait(250)
                check(wave.level>.5,"Wave does not react to the audio snapshot")
                const playing=grabImage(wave)
                let peaks=0
                for (let x=0;x<wave.width;x++) for (let y=0;y<wave.height;y++)
                    if (y<wave.height-5 && playing.red(x,y)<100) peaks++
                check(peaks>20,"Audio must draw a real oscillating trace")
                check(playing.red(2,4)===flat.red(2,4),"Waveform acquired a rectangular background")
                const preview=Quickshell.env("VELORA_WAVEFORM_PREVIEW")
                if (preview) playing.save(preview)
                audio.running=false; wait(1000)
                check(wave.level===0,"Stopped playback must return to a flat line")
                const reads=audio.reads
                dock.progress=0; dock.reveal=0; wait(80)
                audio.publish(.9); wait(120)
                check(audio.reads===reads,"Standard mode must not keep sampling the dock")
                dock.progress=1; dock.reveal=1; audio.running=true; wait(100)
                dock.waveformEnabled=false; wait(80)
                const disabledReads=audio.reads
                audio.publish(.8); wait(100)
                check(audio.reads===disabledReads,"Disabled visualizer keeps sampling")
                console.info("DOCK_WAVEFORM_OK"); Qt.quit()
            }
        }
    }
    Timer { interval: 100; running: true; onTriggered: { try { input.run() } catch(error) { console.error("DOCK_WAVEFORM_FAILED",String(error)); Qt.quit() } } }
    Timer { interval: 6000; running: true; onTriggered: { console.error("DOCK_WAVEFORM_FAILED timeout"); Qt.quit() } }
}
