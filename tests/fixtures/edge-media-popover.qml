import QtQuick
import QtQuick.Controls
import QtTest
import QtQuick.Window
import Quickshell
import "../../components" as Components
import "../../features/topbar" as Topbar
ShellRoot { id: fixture
    property bool visualizerEnabled: true
    property string activeRailControl: ""
    property string quickPopupType: ""
    Component { id: policyContent; Item {} }
    QtObject { id: otherPopover; property bool mounted: false; function close() { mounted=false } }
    // SHELL_CONTROL_HANDLERS
    QtObject {
        id: palette
        property color textPrimary: "#f5f0f7"
        property color textSecondary: "#bcb2c4"
        property color accent: "#d9c0f3"
        property color accentSoft: "#d9c0f3"
        property color danger: "#ff9999"
        property string bodyFont: "Poppins"
        function withAlpha(c, a) { return Qt.rgba(c.r,c.g,c.b,a) }
    }
    QtObject {
        id: media
        property bool hasPlayer: true
        property bool spotifyPlaying: true
        property bool detailActive: false
        property string trackKey: ""
        property int selections: 0
        function selectSpotify() { selections++ }
        property bool canVolume: true
        property real volume: .6
        property var players: []
        property var player: null
        function setVolume(v) { volume = v }
        property string title: "Luz de outubro"
        property string artist: "Velora Sessions"
        property string album: "October Sessions · 2026"
        property string identity: "Spotify"
        property string artUrl: Qt.resolvedUrl("../../assets/dashboard-cover.svg").toString()
        property bool playing: true
        property bool canSeek: true
        property bool canToggle: true
        property bool canPrevious: true
        property bool canNext: true
        property bool canShuffle: true
        property bool shuffled: false
        property bool canRepeat: true
        property int repeatMode: 0
        property real length: 215
        property real sampledPosition: 74
        property int skips: 0
        property real seeked: -1
        property string launched: ""
        property string played: ""
        property bool spotifyQueueAvailable: true
        property var spotifyQueue: [{title:"Depois da chuva",artist:"Velora Sessions",uri:"spotify:track:test123",art:artUrl},{title:"Cidade devagar",artist:"Velora Sessions",uri:"spotify:track:test456",art:artUrl}]
        function togglePlaying() { playing = !playing }
        function next() { skips++ }
        function previous() { skips-- }
        function seekTo(value) { seeked = value; sampledPosition = value }
        function toggleShuffle() { shuffled = !shuffled }
        function cycleRepeat() { repeatMode = (repeatMode + 1) % 3 }
        function openSpotify(query) { launched = query || "spotify:" }
        function playTrack(uri) { played = uri }
    }
    QtObject {
        id: library
        property string page: "lyrics"
        property string query: ""
        property int searches: 0
        property string lyricsState: "ready"
        property bool synced: true
        property int activeLine: 2
        property string searchState: "idle"
        property var results: []
        // Original fixture text, not song lyrics.
        property var lines: [ {time:0,text:"A cidade acorda devagar"},{time:30,text:"O céu muda de cor"},{time:60,text:"Deixa o mundo lá fora"},{time:90,text:"Hoje o tempo é nosso"},{time:120,text:"E a música fica"},{time:150,text:"Até o último raio de sol"} ]
        function search() { searches++ }
        function retryLyrics() {}
    }


Window { id: win; width: 500; height: 1100; visible: true
MouseArea {
    id: outsideApp
    x: 10; y: 800; width: 160; height: 80
    property int clicks: 0
    property int wheels: 0
    onClicked: clicks++
    onWheel: wheels++
}
// SHELL_OUTSIDE_INPUT
Components.VeloraEdgePopover { id: edge; z: 12; width: win.width; height: 1100; railWidth: 4; anchorY: 550; media: media; theme: palette; visualizerDockEnabled: fixture.visualizerEnabled }
Topbar.ChargingMorph {
    id: charging
    theme: palette; anchorX: 250
    suppressed: edge.fullHeightPanelActive
}
TestCase {
 id: test; name: "EdgePopover"; when: false
 function dragContacts(delta) {
    const handle=edge.contactsDragMask
    verify(handle.visible)
    const start=handle.mapToItem(win.contentItem,handle.width/2,handle.height/2)
    mousePress(handle,handle.width/2,handle.height/2)
    mouseMove(win.contentItem,start.x,start.y+delta,30)
    verify(edge.contactsDragging)
    mouseRelease(win.contentItem,start.x,start.y+delta)
    compare(edge.contactsDragging,false)
 }
 function test_whatsapp_outside_input_and_contacts_drag() {
    win.width=1400
    edge.motion.reduced=true
    edge.open(); edge.showPage("whatsapp")
    wait(100)
    edge.whatsappState.selectGroupMode(true)
    edge.whatsappState.selectContact(1)
    edge.whatsappState.draft="rascunho preservado"
    compare(edge.embeddedContacts,false)
    compare(edge.extension.width,84); compare(edge.extension.height,448)
    compare(railToolOutsideInput.height,0)
    mouseClick(outsideApp)
    mouseWheel(outsideApp,40,40,0,-120)
    compare(outsideApp.clicks,1,"Outside clicks reach the other application")
    compare(outsideApp.wheels,1,"Outside scrolling reaches the other application")
    compare(edge.opened,true)
    otherPopover.mounted=true
    compare(railToolOutsideInput.height,win.height)
    mouseClick(outsideApp)
    compare(otherPopover.mounted,false,"An outside click still dismisses another menu")
    compare(outsideApp.clicks,1)
    compare(edge.opened,true,"Dismissing another menu preserves WhatsApp")
    for (const control of ["volume","brightness","battery","wifi","bluetooth"]) {
        fixture.activeRailControl=control; fixture.onActiveRailControlChanged()
        fixture.quickPopupType=control; fixture.onQuickPopupTypeChanged()
        compare(edge.opened,true,control+" must preserve WhatsApp")
    }
    fixture.activeRailControl=""; fixture.quickPopupType=""
    dragContacts(-160)
    compare(edge.contactsExpanded,false); compare(edge.contactsFold,0)
    compare(edge.extension.width,0); compare(edge.extension.height,0)
    compare(edge.contactsDragMask.y,edge.bodyY,"Collapsed handle remains below the topbar")
    compare(edge.opened,true)
    compare(edge.whatsappState.groups,true); compare(edge.whatsappState.selected,1)
    compare(edge.whatsappState.draft,"rascunho preservado")
    dragContacts(160)
    compare(edge.contactsExpanded,true); compare(edge.contactsFold,1)
    compare(edge.extension.width,84); compare(edge.extension.height,448)
    dragContacts(-8)
    compare(edge.contactsExpanded,true,"A small accidental gesture does not collapse the column")
    edge.motion.reduced=false
    dragContacts(-80)
    compare(edge.contactsExpanded,false)
    wait(60)
    verify(edge.contactsFold>0 && edge.contactsFold<1,"Release animates the remaining contour")
    tryCompare(edge,"contactsFold",0)
    dragContacts(80)
    tryCompare(edge,"contactsFold",1)
    edge.motion.reduced=true
    dragContacts(-160)
    edge.close(); edge.open(); edge.showPage("whatsapp")
    compare(edge.contactsExpanded,false); compare(edge.contactsFold,0)
    compare(edge.contactsDragMask.visible,true,"Reopening keeps the hidden column available to pull down")
    dragContacts(160)
    win.width=500
    wait(100)
    compare(edge.embeddedContacts,true)
    const inlineContacts=findChild(edge,"whatsappInlineContacts")
    verify(inlineContacts)
    compare(inlineContacts.width,64)
    dragContacts(-160)
    compare(inlineContacts.width,0); compare(inlineContacts.height,0)
    dragContacts(160)
    compare(inlineContacts.width,64)
    edge.forceActiveFocus(); keyClick(Qt.Key_Escape)
    compare(edge.opened,false,"Escape remains an explicit dismissal")
    edge.open()
    compare(edge.page,"apps")
    compare(railToolOutsideInput.height,win.height,"The app launcher still dismisses on an outside click")
    mouseClick(outsideApp)
    compare(edge.opened,false)
 }
 function test_charging_side_panel_policy() {
    // Exercise the real panel lifecycle without loading unrelated audio/UI
    // services; payload widgets have separate content tests in this fixture.
    edge.customContent=policyContent
    edge.motion.reduced=true
    edge.open()
    compare(edge.page,"apps")
    compare(edge.fullHeightPanelActive,false,"The compact app launcher must not block charging")
    for (const page of ["media","lyrics","whatsapp"]) {
        edge.showPage(page)
        compare(edge.fullHeightPanelActive,true,page+" must block the battery morph")
        compare(edge.mediaPanelActive,page!=="whatsapp","WhatsApp must not change spectrum policy")
        charging.charging=true
        wait(80)
        compare(charging.visible,false,page+" must show only the topbar color wave")
        compare(charging.surfaceRect.height,0)
        verify(charging.gradientStrength>0)
        edge.close()
        compare(edge.fullHeightPanelActive,false)
        compare(charging.visible,false,"Closing the panel cannot reopen the battery")
        charging.charging=false
        edge.open()
    }
    charging.charging=true
    tryCompare(charging,"reveal",1,700)
    verify(charging.visible)
    edge.motion.reduced=false
    edge.showPage("whatsapp")
    compare(edge.page,"apps","This check must precede the animated page handoff")
    compare(edge.fullHeightPanelActive,true,"The pending page must suppress the morph immediately")
    compare(charging.visible,false)
    compare(charging.surfaceRect.height,0)
    edge.motion.reduced=true
    compare(edge.page,"whatsapp")
    edge.motion.reduced=false
    edge.close()
    verify(edge.mounted && edge.fullHeightPanelActive,"Suppression must cover the panel's exit animation")
    tryCompare(edge,"mounted",false,1800)
    compare(edge.fullHeightPanelActive,false)
    verify(!charging.visible)
    verify(charging.gradientProgress>0 && charging.gradientProgress<1,"Panel exit cannot restart the charging deadline")
    charging.charging=false
 }
 function test_morph_lyrics_lifecycle() {
    fixture.visualizerEnabled=false
    edge.triggerHovered=true; tryCompare(edge,"opened",true)
    tryCompare(edge,"contentReveal",1)
    compare(edge.bodyWidth,56)
    win.width=1400; edge.width=1400
    mouseClick(findChild(edge,"edgeAppWhatsApp"))
    tryCompare(edge,"page","whatsapp")
    wait(300)
    compare(edge.contactsReveal,0,"Contacts wait for the main panel")
    compare(edge.extension.width,0);compare(edge.extension.height,0)
    compare(findChild(edge,"edgeWhatsAppContacts").active,false,"Contacts UI mounts last")
    verify(edge.bodyWidth>56 && edge.bodyWidth<448)
    tryCompare(edge,"contentReveal",1)
    compare(edge.bodyWidth,448); compare(edge.bodyHeight,1100); compare(edge.bodyY,0)
    compare(edge.mediaPanelActive,false); compare(edge.spectrumActive,false)
    compare(media.selections,0); compare(media.detailActive,false)
    compare(edge.embeddedContacts,false); compare(edge.contour,0)
    verify(edge.contactsReveal<1,"The contacts morph begins after the main entrance")
    wait(250)
    verify(edge.contactsReveal>0 && edge.contactsReveal<1)
    verify(edge.extension.height>0 && edge.extension.height<448,"Contacts grow downward from the topbar")
    compare(edge.extension.y,0);compare(edge.contactsContentReveal,0)
    tryCompare(edge,"contactsReveal",1,1500)
    tryCompare(edge,"contactsContentReveal",1,1000)
    compare(edge.extension.width,84);compare(edge.extension.height,448)
    compare(findChild(edge,"edgeWhatsAppContacts").active,true)
    compare(findChild(edge,"whatsappMessages").count,9)
    mouseClick(findChild(edge,"whatsappBack"))
    wait(100)
    verify(edge.contentReveal>0 && edge.contentReveal<1,"WhatsApp content slides and fades on exit")
    verify(findChild(edge,"railContentViewport").x>0)
    tryCompare(edge,"page","apps"); tryCompare(edge,"contentReveal",1)
    compare(edge.contactsReveal,0);compare(edge.contactsContentReveal,0)
    win.width=500;edge.width=500
    edge.showPage("media"); tryCompare(edge,"page","media")
    wait(450)
    compare(edge.dockProgress,0,"Disabled desktop visualizer cannot migrate while Spotify opens")
    compare(edge.sidebarWaveScale,0)
    verify(edge.bodyWidth>56 && edge.bodyWidth<200,"Spotify opens through a slow intermediate shape")
    verify(edge.bodyHeight>164 && edge.bodyHeight<1100,"Height morphs together with width")
    compare(edge.contentReveal,0,"Content waits for the surface morph")
    wait(600)
    verify(edge.bodyWidth>200 && edge.bodyWidth<400,"Morph remains visible after one second")
    tryCompare(edge,"contentReveal",1,3000)
    compare(edge.dockProgress,0,"Disabled desktop visualizer stays off after Spotify settles")
    edge.showPage("apps"); tryCompare(edge,"page","apps"); tryCompare(edge,"contentReveal",1)
    const spotify=findChild(edge,"edgeAppSpotify")
    verify(spotify)
    mouseMove(spotify,22,22)
    tryCompare(edge,"labelReveal",1)
    tryCompare(edge,"labelContent",1)
    const label=findChild(edge,"edgeLyricsButton")
    mouseMove(label,40,22); wait(300); compare(edge.labelReveal,1)
    mouseClick(label,40,22)
    tryCompare(edge,"page","lyrics")
    tryCompare(edge,"bodyHeight",1100)
    tryCompare(edge,"contentReveal",1)
    compare(edge.bodyY,0); compare(edge.bodyWidth,400); compare(edge.closeOnLeave,false)
    compare(edge.dockProgress,0,"Lyrics cannot revive the disabled desktop visualizer")
    compare(edge.sidebarWaveScale,0)
    verify(media.selections>0); compare(media.detailActive,true); compare(edge.mediaPanelActive,true)
    compare(edge.beatActive,true,"Only the Lyrics page requests percussion capture")
    edge.beatEnabled=false; compare(edge.beatActive,false)
    edge.beatEnabled=true
    media.spotifyPlaying=false; compare(edge.beatActive,false)
    media.spotifyPlaying=true; compare(edge.beatActive,true)
    const lyricWaves=findChild(edge,"edgeWaves")
    lyricWaves.synced=true; lyricWaves.lines=[{time:0},{time:10},{time:20}]
    lyricWaves.activeLine=0; lyricWaves.position=0; wait(1000)
    const oldRight=edge.contourSamples.slice(), oldLeft=edge.sidebarSamples.slice()
    lyricWaves.activeLine=1; lyricWaves.position=10; wait(1000)
    verify(Math.max(...edge.contourSamples.map((v,i)=>Math.abs(v-oldRight[i])))>.04,"Right Lyrics contour follows the verse")
    verify(Math.max(...edge.sidebarSamples.map((v,i)=>Math.abs(v-oldLeft[i])))>.04,"Left Lyrics contour follows the same verse")
    compare(JSON.stringify(edge.sidebarSamples),JSON.stringify(edge.contourSamples))
    fixture.visualizerEnabled=true
    edge.showPage("media"); tryCompare(edge,"page","media"); tryCompare(edge,"contentReveal",1)
    compare(edge.bodyY,0); compare(edge.bodyHeight,1100)
    compare(edge.beatActive,false,"Spotify music page cannot emit Lyrics pulses")
    verify(edge.dockProgress > 0,"Dock follows the media opening")
    tryCompare(edge,"dockProgress",1,3000)
    fixture.visualizerEnabled=false
    compare(edge.dockProgress,0,"Disabling the visualizer removes its left wave immediately")
    compare(edge.sidebarWaveScale,0)
    fixture.visualizerEnabled=true
    verify(edge.dockProgress<1,"Enabling preserves the dock animation")
    tryCompare(edge,"dockProgress",1,3000)
    const retainedCurve=JSON.stringify(edge.sidebarSamples)
    const exitingContour=JSON.stringify(edge.contourSamples)
    edge.close()
    compare(edge.bodyHeight,1100); compare(edge.bodyY,0)
    wait(100)
    compare(edge.bodyWidth,400)
    verify(edge.contentReveal < 1 && edge.contentReveal > 0,"Content fades before surface retracts")
    compare(JSON.stringify(edge.contourSamples),exitingContour)
    wait(200)
    verify(edge.mounted && edge.bodyWidth > 300 && edge.bodyWidth < 400,"Slow surface exit retains its intermediate pose")
    verify(edge.dockProgress > .8 && edge.dockProgress < 1,"Undocking starts with panel exit")
    compare(JSON.stringify(edge.sidebarSamples),retainedCurve)
    edge.open(); edge.showPage("media"); tryCompare(edge,"contentReveal",1)
    verify(edge.sidebarWaveScale > 0)
    fixture.activeRailControl="volume"; fixture.onActiveRailControlChanged()
    compare(edge.opened,true)
    fixture.activeRailControl="brightness"; fixture.onActiveRailControlChanged()
    compare(edge.opened,true)
    fixture.quickPopupType="volume"; fixture.onQuickPopupTypeChanged()
    compare(edge.opened,true)
    fixture.quickPopupType="brightness"; fixture.onQuickPopupTypeChanged()
    compare(edge.opened,true)
    verify(!edge.keepOpenForControl("battery"))
    edge.triggerHovered=false
    mouseMove(win.contentItem,10,1000)
    edge.close()
    wait(250)
    const intermediateWidth=edge.bodyWidth
    edge.close() // Repeated requests must not restart the content delay.
    wait(250)
    verify(edge.bodyWidth < intermediateWidth,"Repeated close continues retracting")
    tryCompare(edge,"mounted",false,1200)
    tryCompare(edge,"dockProgress",0,3000)
    edge.open(); edge.showPage("lyrics"); tryCompare(edge,"contentReveal",1)
    edge.motion.reduced=true
    edge.close(); compare(edge.mounted,false); compare(media.detailActive,false)
    compare(edge.page,"apps"); compare(edge.mediaPanelActive,false)
    compare(edge.sidebarWaveScale,0)
    edge.open(); edge.triggerHovered=false
    media.spotifyPlaying=false; edge.spotifyHovered=true; wait(400)
    compare(edge.labelReveal,0)
    edge.close(); compare(edge.mounted,false)
    edge.open(); edge.showPage("whatsapp")
    compare(edge.page,"whatsapp");compare(edge.contentReveal,1)
    compare(edge.contactsReveal,1);compare(edge.contactsContentReveal,1)
    compare(edge.contactsAnimating,false,"Reduced motion skips the staged contacts entrance")
    edge.close();compare(edge.mounted,false)
    compare(edge.contactsReveal,0);compare(edge.contactsContentReveal,0)
 }
}
}

 Timer { interval: 250; running: true; onTriggered: {
   const policy=Quickshell.env("VELORA_CHARGING_POLICY_CHECK")==="1"
   const drawer=Quickshell.env("VELORA_WHATSAPP_DRAWER_CHECK")==="1"
   try {
       if (policy) test.test_charging_side_panel_policy()
       else if (drawer) test.test_whatsapp_outside_input_and_contacts_drag()
       else test.test_morph_lyrics_lifecycle()
       console.info(policy ? "CHARGING_EDGE_POLICY_OK" : drawer ? "WHATSAPP_DRAWER_OK" : "EDGE_POPOVER_OK")
   }
   catch(e) { console.error(policy ? "CHARGING_EDGE_POLICY_FAILED" : drawer ? "WHATSAPP_DRAWER_FAILED" : "EDGE_POPOVER_FAILED", String(e), e.stack) }
   Qt.quit()
 } }
}
