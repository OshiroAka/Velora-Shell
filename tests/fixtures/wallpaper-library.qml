import QtQuick
import Quickshell
import Quickshell.Io
import "../../services" as Services
ShellRoot {
    id: test
    property int phase: 0
    property double started: 0
    property double discoveredAt: 0
    property bool everReady: false
    property int countChanges: 0
    Services.WallpaperLibraryService {
        id: library; active: true
        onEntriesChanged: {
            test.countChanges++
            if (test.everReady && entries.length<2) {console.error("LIBRARY_FAILED transient empty inventory");Qt.quit()}
        }
    }
    Process {
        id: add
        command: ["python3","-c","from pathlib import Path;import os; p=Path(os.environ['HOME'])/'Pictures/Wallpapers/nested/new.png';p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b'new-image')"]
    }
    Timer {
        interval: 20; running: true; repeat: true
        onTriggered: {
            try {
                if (phase===0 && library.ready) {
                    if (library.entries.length!==2)throw Error("initial inventory")
                    test.everReady=true
                    if (!library.running)throw Error("quick inventory waited for thumbnail enrichment")
                    started=Date.now();add.running=true;phase=1
                } else if (phase===1 && library.entries.length===3) {
                    const elapsed=Date.now()-started
                    if(elapsed>1200)throw Error("discovery delayed "+elapsed)
                    const entry=library.entries.find(entry=>entry.title==="new")
                    discoveredAt=entry.addedAt
                    if(discoveredAt<Date.now()/1000-3)throw Error("new discovery not marked recent")
                    console.info("LIBRARY_DISCOVERY_MS",elapsed)
                    library.refresh(false);phase=2
                } else if (phase===2) {
                    const entry=library.entries.find(entry=>entry.title==="new")
                    if(entry.addedAt!==discoveredAt)throw Error("enrichment lost discovery time")
                    if(entry.preview.indexOf("wallpaper-previews")<0 || library.running) return
                    if(library.entries.length!==3)throw Error("enrichment replaced the inventory")
                    library.active=false;phase=3
                } else if (phase===3) {
                    if(library.error)throw Error(library.error)
                    console.info("WALLPAPER_LIBRARY_OK",countChanges);Qt.quit()
                }
            }catch(error){console.error("LIBRARY_FAILED",String(error),error.stack);Qt.quit()}
        }
    }
    Timer {interval:12000;running:true;onTriggered:{console.error("LIBRARY_FAILED timeout",phase,library.entries.length,library.running,library.error);Qt.quit()}}
}
