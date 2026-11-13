import QtQuick
import QtQuick.Controls
import QtTest
import "../../components" as Components
Item { id: fixture; width: 500; height: 1100
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
        property var spotifyCurrent: null
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

Rectangle { id: renderSurface; anchors.fill: parent; color: "#4d286d" }
Components.VeloraEdgeMediaPanel { id: panel; width: 400; height: 1050; media: media; library: library; theme: palette }
Components.VeloraEdgeApps { id: apps; x: 410; width: 56; height: 164 }
SignalSpy { id: openSpy; target: apps; signalName: "spotifyRequested" }
SignalSpy { id: closeSpy; target: panel; signalName: "closeRequested" }
Rectangle {
 id: fadeFixture; width: 400; height: 1050; color: "#4d286d"; visible: false; z: 5
 Components.VeloraMediaBackdrop {
   id: fadeBackdrop; width: 400; height: 1050; artworkHeight: 690; topInset: 0; animated: false
   source: "data:image/svg+xml," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"><rect width="16" height="16" fill="white"/></svg>')
 }
}
TestCase {
 name: "EdgeMedia"; when: windowShown
 function init() {
   panel.width=400; panel.height=1050; panel.lyrics=false; panel.reducedMotion=false
   media.hasPlayer=true; media.playing=true; media.canNext=true; media.skips=0
   media.spotifyCurrent=null; media.spotifyQueueAvailable=true
   library.page="queue"; library.query=""; library.results=[]; library.searches=0
   findChild(panel,"edgeMediaSearch").text=""
   findChild(panel,"edgeMediaSearchPopup").close()
   panel.forceActiveFocus(); wait(100)
 }
 function test_transport() {
   mouseClick(findChild(panel,"edgeMediaPlay")); compare(media.playing,false)
   mouseClick(findChild(panel,"edgeMediaNext")); compare(media.skips,1)
   mouseClick(findChild(panel,"edgeMediaPrevious")); compare(media.skips,0)
   media.canNext=false; mouseClick(findChild(panel,"edgeMediaNext")); compare(media.skips,0)
 }
 function test_seek_search_lyrics() {
   const seek=findChild(panel,"edgeMediaSeek")
   mousePress(seek,seek.width*.2,seek.height/2)
   mouseMove(seek,seek.width*.7,seek.height/2,20)
   const val=seek.value; media.sampledPosition=2; fuzzyCompare(seek.value,val,.1)
   mouseRelease(seek,seek.width*.7,seek.height/2)
   verify(media.seeked>120)
   const search=findChild(panel,"edgeMediaSearch")
   mouseClick(findChild(panel,"edgeMediaSearchButton"))
   tryCompare(findChild(panel,"edgeMediaSearchPopup"),"opened",true)
   mouseClick(search); keyClick(Qt.Key_A); keyClick(Qt.Key_B); compare(library.query,"ab")
   compare(library.page,"search"); keyClick(Qt.Key_Return); compare(library.searches,1)
   keyClick(Qt.Key_Escape); tryCompare(findChild(panel,"edgeMediaSearchPopup"),"visible",false)
   panel.lyrics=true; library.page="lyrics"; wait(400)
   compare(findChild(panel,"edgeLyrics").count,6)
   const lineView=findChild(panel,"edgeLyrics")
   lineView.positionViewAtIndex(2,ListView.Center); wait(400)
   const words=findChild(panel,"edgeLyricWords2")
   verify(words); const previousX=words.x
   compare(words.font.family,"Liberation Serif")
   tryCompare(words.parent,"glow",1)
   const startY=lineView.contentY
   library.activeLine=3
   const slide=findChild(panel,"edgeLyricsSlide")
   verify(slide.running,"Synced verses must animate instead of jumping")
   wait(100)
   verify(Math.abs(lineView.contentY-startY)<Math.abs(slide.to-startY),"Scroll starts between the old and new verse")
   tryCompare(words.parent,"glow",0)
   tryCompare(findChild(panel,"edgeLyricWords3").parent,"glow",1)
   tryCompare(slide,"running",false)
   fuzzyCompare(lineView.contentY,slide.to,.01)
   library.activeLine=2
   wait(100)
   panel.reducedMotion=true
   compare(slide.running,false)
   panel.following=false; lineView.contentY += 130; wait(60)
   verify(Math.abs(words.x-previousX)>1,"Verse center follows the contour while scrolling")
   panel.reducedMotion=true; library.activeLine=4; wait(50)
   verify(findChild(panel,"edgeLyrics").visible)
   panel.forceActiveFocus(); keyClick(Qt.Key_Escape); compare(closeSpy.count,1)
 }
 function test_header_search_results_and_selection() {
   compare(findChild(panel,"edgeMediaFullQueue"),null)
   compare(findChild(panel,"edgeMediaTracks"),null)
   compare(findChild(panel,"edgeMediaShuffle"),null)
   compare(findChild(panel,"edgeMediaRepeat"),null)
   const button=findChild(panel,"edgeMediaSearchButton")
   button.forceActiveFocus(); keyClick(Qt.Key_Return)
   const popup=findChild(panel,"edgeMediaSearchPopup")
   tryCompare(popup,"opened",true)
   const search=findChild(panel,"edgeMediaSearch")
   tryCompare(search,"activeFocus",true)
   keyClick(Qt.Key_A); keyClick(Qt.Key_B)
   library.results=[
     {title:"One",artist:"Test",uri:"spotify:track:one",art:media.artUrl},
     {title:"Two",artist:"Test",uri:"spotify:track:two",art:media.artUrl}]
   const results=findChild(panel,"edgeMediaSearchResults")
   tryCompare(results,"count",2)
   tryVerify(function(){ return results.itemAtIndex(1)!==null })
   mouseClick(results.itemAtIndex(1)); compare(media.played,"spotify:track:two")
   verify(panel.interactionHeld)
   keyClick(Qt.Key_Escape); tryCompare(popup,"visible",false)
   compare(button.activeFocus,true)
   compare(results.count,0)
 }
 function test_backdrop_reacts_and_neutral_fallback() {
   const backdrop=findChild(panel,"edgeMediaBackdrop")
   const image=findChild(panel,"edgeMediaBackdropImage")
   verify(backdrop); verify(image)
   compare(backdrop.source,media.artUrl)
   tryCompare(backdrop,"ready",true)
   verify(image.width >= panel.width)
   const original=media.artUrl
   media.artUrl=Qt.resolvedUrl("../../assets/profile-avatar.svg").toString()
   tryCompare(backdrop,"source",media.artUrl)
   tryCompare(image,"status",Image.Ready)
   media.artUrl=""
   tryCompare(backdrop,"ready",false)
   media.hasPlayer=false
   compare(backdrop.source,"")
   compare(findChild(panel,"edgeMediaSearchResults").count,0)
   media.artUrl=original
   compare(backdrop.source,"")
   media.hasPlayer=true
   tryCompare(backdrop,"ready",true)
   compare(findChild(panel,"edgeMediaVolume"),null)
   compare(findChild(panel,"edgeMediaPlayer"),null)
 }
 function test_backdrop_preserves_liquid_transparency() {
   if (GraphicsInfo.api === GraphicsInfo.Software) skip("OpacityMask needs the RHI rendering check")
   const backdrop=findChild(panel,"edgeMediaBackdrop")
   panel.reducedMotion=true
   tryCompare(backdrop,"ready",true)
   wait(100)
   const rendered=grabImage(backdrop)
   compare(rendered.pixel(200,1000),renderSurface.color,"Lower panel must expose the native liquid material")
   compare(rendered.pixel(0,200),renderSurface.color,"Artwork must stay inside the organic contour")
   verify(rendered.pixel(200,150)!==renderSurface.color,"Album artwork must remain visible")
   renderSurface.color="#276841"; wait(100)
   verify(grabImage(backdrop).pixel(200,150)!==rendered.pixel(200,150),"Artwork must blend with the underlying material")
   const original=media.artUrl
   media.artUrl=""; tryCompare(backdrop,"ready",false); wait(100)
   compare(grabImage(backdrop).pixel(200,150),renderSurface.color,"Missing artwork must expose the native neutral surface")
   media.artUrl=original
   renderSurface.color="#4d286d"
 }
 function test_backdrop_top_fade_and_alignment() {
   if (GraphicsInfo.api === GraphicsInfo.Software) skip("OpacityMask needs the RHI rendering check")
   fadeFixture.visible=true
   fadeBackdrop.y=0; fadeBackdrop.height=1050; fadeBackdrop.topInset=0
   tryCompare(fadeBackdrop,"ready",true); wait(100)
   const full=grabImage(fadeFixture)
   for (let y=0; y<=145; y+=5)
     compare(full.pixel(200,y),fadeFixture.color,"Header and album top margin must expose the native material")
   verify(full.pixel(200,250)!==fadeFixture.color,"Soft top fade must still reveal the album below the header")
   for (let y=155; y<300; ++y)
     verify(Math.abs(full.red(200,y)-full.red(200,y-1))<=3,"Top artwork fade has a sharp horizontal step")
   fadeBackdrop.y=40; fadeBackdrop.height=1010; fadeBackdrop.topInset=40; wait(100)
   const body=grabImage(fadeFixture)
   for (let y=40; y<740; y+=5)
     for (const channel of ["red","green","blue"])
       verify(Math.abs(body[channel](200,y)-full[channel](200,y))<=3,"Topbar/body artwork coordinates do not align: y=" + y + " " + channel + " " + body[channel](200,y) + " / " + full[channel](200,y))
   fadeFixture.visible=false
 }
 function test_responsive_controls_and_keyboard_states() {
   const play=findChild(panel,"edgeMediaPlay")
   const search=findChild(panel,"edgeMediaSearch")
   const back=findChild(panel,"edgeMediaBack")
   for (const dimensions of [[320,640],[400,720],[400,1050],[560,1440]]) {
     panel.width=dimensions[0]; panel.height=dimensions[1]; wait(100)
     const buttons=["edgeMediaPrevious","edgeMediaPlay","edgeMediaNext"]
     let right=0
     for (const name of buttons) {
       const button=findChild(panel,name), point=button.mapToItem(panel,0,0)
       verify(point.x >= right - .5, name+" overlaps previous button")
       verify(point.x+button.width <= panel.width, name+" overflows panel")
       verify(button.width>=36 && button.height>=36)
       right=point.x+button.width
     }
     const searchButton=findChild(panel,"edgeMediaSearchButton")
     const searchPoint=searchButton.mapToItem(panel,0,0)
     verify(searchPoint.y<80,"Search must be in the header")
     verify(searchPoint.x+searchButton.width<=panel.width)
     verify(!findChild(panel,"edgeMediaSearchPopup").visible)
     verify(back.mapToItem(panel,0,back.height).y <= panel.height)
   }
   panel.width=400; panel.height=1050
   play.forceActiveFocus(); media.playing=true
   keyClick(Qt.Key_Space); compare(media.playing,false)
   const next=findChild(panel,"edgeMediaNext")
   next.forceActiveFocus(); keyClick(Qt.Key_Return); compare(media.skips,1)

 }
 function test_apps() {
   const spotify=findChild(apps,"edgeAppSpotify"), discord=findChild(apps,"edgeAppDiscord")
   mouseMove(spotify,22,22); tryCompare(spotify,"emphasis",1)
   mouseClick(spotify); compare(openSpy.count,1)
   mouseClick(discord); compare(openSpy.count,1)
   mouseMove(fixture,490,1090); tryCompare(spotify,"emphasis",0)
   spotify.forceActiveFocus(); keyClick(Qt.Key_Return); compare(openSpy.count,2)
   keyClick(Qt.Key_Tab); compare(discord.activeFocus,true)
   discord.focus=false; apps.reducedMotion=true; wait(220)
   mouseMove(spotify,22,22); compare(spotify.emphasis,1)
 }
}
}
