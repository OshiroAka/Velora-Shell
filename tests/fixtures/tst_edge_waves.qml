import QtQuick
import QtTest
import "../../components" as Components
import "../../services" as Services
import "../../components/EdgeMediaContours.js" as Contours

Item {
    QtObject {
        id: analyzer
        property bool running: true
        property var frame: Array(64).fill(0)
        property int reads: 0
        signal bandsChanged()
        function materialFrame() { reads++; return frame.join(" ") }
    }
    Components.VeloraEdgeWaves {
        id: waves
        analyzer: analyzer
        synced: true
        lines: [{time: 0}, {time: 10}, {time: 20}]
        duration: 30
    }
    Services.VisualizerDemand { id: demand }
    TestCase {
        name: "EdgeWaves"; when: windowShown
        function init() {
            waves.active = false; waves.reducedMotion = false
            waves.page = "media"; waves.contour = 1; waves.playing = true
            waves.activeLine = 0; waves.position = 0
            analyzer.frame = Array(64).fill(0); analyzer.running = true
        }
        function test_audio_response_silence_and_lifecycle() {
            waves.active = true
            const rest = JSON.stringify(waves.samples)
            analyzer.frame = Array(64).fill(.04); analyzer.bandsChanged()
            tryVerify(() => waves.levels[10] >= .038)
            const base = Contours.samples(1)
            verify(Math.max(...waves.samples.map((v,i) => v-base[i])) > .04,
                "Quiet passages must produce a clearly visible contour displacement")
            analyzer.frame = Array(64).fill(.8); analyzer.bandsChanged()
            tryVerify(() => waves.levels[10] > .6)
            verify(JSON.stringify(waves.samples) !== rest)
            // Joins remain fixed and media never reaches the controls.
            fuzzyCompare(waves.samples[0], Contours.samples(1)[0], .00001)
            fuzzyCompare(waves.samples[20], Contours.samples(1)[20], .00001)
            verify(waves.samples.every(v => v >= 0 && v <= .235))
            analyzer.frame = Array(64).fill(0); analyzer.bandsChanged()
            tryCompare(waves, "settling", false, 3000)
            compare(JSON.stringify(waves.samples), rest)
            const reads = analyzer.reads; wait(150); compare(analyzer.reads, reads)
            waves.playing = false; analyzer.bandsChanged(); wait(80)
            compare(analyzer.reads, reads)
            waves.playing = true; waves.active = false
            const closedReads = analyzer.reads
            analyzer.bandsChanged(); wait(100); compare(analyzer.reads, closedReads)
        }
        function test_default_lobes_survive_loud_audio() {
            const base=Contours.samples(1)
            // Measure the rendered spline, not just its control points.
            const lobes=[[.1,.25],[.35,.25],[.35,.45],[.55,.45],
                         [.55,.7],[.8,.7],[.8,.9]]
            for (const level of [0,.04,.3,.8,1]) {
                const shape=Contours.animatedSamples(1,Array(21).fill(level),0,false)
                for (const pair of lobes) {
                    const original=Contours.offset(base,pair[0])-Contours.offset(base,pair[1])
                    const animated=Contours.offset(shape,pair[0])-Contours.offset(shape,pair[1])
                    verify(animated>=original-.00001,
                        "Audio must preserve every original peak and valley at level "+level)
                }
                verify(shape.every(v=>v>=0 && v<=.235),"Keep waves outside the controls")
                fuzzyCompare(shape[0],base[0],.00001)
                fuzzyCompare(shape[20],base[20],.00001)
            }
        }
        function test_lyrics_follow_timestamps_not_audio() {
            waves.page = "lyrics"; waves.contour = 2; waves.active = true
            wait(300)
            const first = JSON.stringify(waves.samples), reads = analyzer.reads
            analyzer.frame = Array(64).fill(1); analyzer.bandsChanged(); wait(80)
            compare(JSON.stringify(waves.samples), first); compare(analyzer.reads, reads)
            waves.position = 8; wait(1000)
            verify(JSON.stringify(waves.samples) !== first)
            verify(waves.samples.every(v => v >= 0 && v <= .40))
            const beforeVerse=waves.samples.slice()
            waves.activeLine = 1; waves.position = 14; wait(1000)
            verify(Math.max(...waves.samples.map((v,i) => Math.abs(v-beforeVerse[i]))) > .04,
                "A new verse must create a perceptible morph")
            fuzzyCompare(waves.lyricPhase, 2.5442, .001)
            waves.playing = false
            const paused = JSON.stringify(waves.samples); wait(300)
            compare(JSON.stringify(waves.samples), paused)
            waves.activeLine = 0; waves.position = 2
            fuzzyCompare(waves.lyricPhase, .0742, .001)
            waves.reducedMotion = true
            compare(JSON.stringify(waves.samples), JSON.stringify(Contours.samples(2)))
            waves.reducedMotion = false; waves.synced = false
            compare(JSON.stringify(waves.samples), JSON.stringify(Contours.samples(2)))
            waves.synced = true
        }
        function test_demand_for_menu_with_bottom_hidden() {
            demand.desktopEnabled = false; demand.railVisible = false
            demand.mediaPlaying = true; demand.edgeMediaVisible = true
            compare(demand.active, true)
            demand.edgeMediaVisible = false; compare(demand.active, false)
            demand.edgeMediaVisible = true; demand.mediaPlaying = false
            compare(demand.active, false)
            waves.active = true; waves.reducedMotion = true
            compare(waves.spectrumActive, false)
        }
    }
}
