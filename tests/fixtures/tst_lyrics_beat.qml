import QtQuick
import QtTest
import "../../services" as Services

Item {
    QtObject {
        id: analyzer
        property bool running: true
        property int reads: 0
        signal bandsChanged()
        function materialFrame() { reads += 1; return Array(96).fill(0).join(" ") }
    }
    Services.LyricsBeatService { id: beats; analyzer: analyzer }
    TestCase {
        name: "LyricsBeat"; when: windowShown
        function test_only_visible_lyrics_consume_the_shared_fft() {
            analyzer.bandsChanged(); compare(analyzer.reads,0)
            beats.active=true
            analyzer.bandsChanged(); compare(analyzer.reads,1)
            beats.detector.lastBeat=1234
            beats.active=false
            compare(beats.detector.lastBeat,-10000)
            analyzer.bandsChanged(); compare(analyzer.reads,1)
            beats.active=true
            analyzer.running=false
            analyzer.bandsChanged(); compare(analyzer.reads,1)
            analyzer.running=true
            analyzer.bandsChanged(); compare(analyzer.reads,2)
            compare(beats.beatCount,0)
            beats.active=false
        }

    }
}
