import QtQuick
import Quickshell
import "../../services" as Services

ShellRoot {
    id: fixture
    function check(ok, message) { if (!ok) throw new Error(message) }
    Services.AlbumPaletteService { id: palette }
    Services.AlbumPaletteService {
        id: pipeline
        source: Quickshell.env("VELORA_TEST_ALBUM")
        active: true
    }
    Component.onCompleted: {
        try {
            palette.requestedSource="old-cover"
            palette.source="new-cover"
            palette.accept('{"colors":[1,0,0,0,1,0]}')
            check(!palette.ready,"Stale results cannot color the next album")
            palette.requestedSource="new-cover"
            palette.accept('{"colors":[0,0,1,1,0,1]}')
            check(palette.ready && palette.colors[2]===1,"Current album colors were not accepted")
            palette.source="old-cover"
            check(palette.colors[0]===1,"Earlier album may be reused from cache")
            palette.source="missing-cover"
            check(!palette.ready,"Missing cover reused previous album colors")
            palette.requestedSource="missing-cover"
            palette.accept('{"colors":[1,0,0,0,2,0]}')
            check(!palette.ready,"Invalid palette accepted")
        } catch (error) { console.error(error); Qt.exit(1) }
    }
    Timer {
        interval: 30; running: true; repeat: true
        onTriggered: if (pipeline.ready) {
            fixture.check(pipeline.colors[0]>.7 && pipeline.colors[1]<.2,"Helper returned the wrong dominant color")
            console.info("ALBUM_PALETTE_OK")
            Qt.quit()
        }
    }
    Timer { interval: 5000; running: true; onTriggered: { console.error("Palette helper did not finish"); Qt.exit(1) } }
}
