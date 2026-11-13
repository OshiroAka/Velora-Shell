import QtQuick
import QtTest
import "../../core" as Core
import "../../features/topbar" as Topbar

Item {
    width: 1366; height: 768
    Core.Motion { id: tokens }
    Topbar.WallpaperPicker {
        id: picker
        anchors.fill: parent
        motion: tokens
        onCloseRequested: open = false
    }
    SignalSpy { id: applied; target: picker; signalName: "applyRequested" }
    SignalSpy { id: refreshed; target: picker; signalName: "refreshRequested" }
    TestCase {
        name: "WallpaperPicker"
        when: windowShown
        function library(count) {
            const entries = []
            for (let i = 0; i < count; ++i)
                entries.push({ key: "static:" + i, path: "", preview: "", title: "Wallpaper " + i })
            return entries
        }
        function init() {
            picker.reducedMotion = true; picker.open = false
            picker.width = 1366; picker.height = 768
            picker.entries = library(500); picker.activeKey = "static:5"
            picker.applying = false; picker.errorMessage = ""
            applied.clear(); refreshed.clear()
            picker.reducedMotion = false
        }
        function settle() {
            picker.open = true
            tryCompare(picker, "interactive", true, 1500)
            picker.forceActiveFocus()
        }
        function test_morph_and_reversal() {
            picker.open = true
            wait(65)
            verify(picker.mounted && picker.reveal > 0 && picker.reveal < 1)
            const pose = picker.panelRect
            picker.open = false
            fuzzyCompare(picker.panelRect.width, pose.width, .01)
            wait(90)
            const duringClose = picker.reveal
            picker.open = true
            fuzzyCompare(picker.reveal, duringClose, .001)
            tryCompare(picker, "interactive", true, 1500)
            compare(picker.panelRect.y, 40)
            compare(picker.metrics.columns, 4)
            verify(picker.joinRadius > 100, "Wide shoulders must connect the grid to the topbar")
            picker.open = false
            verify(picker.mounted)
            tryCompare(picker, "mounted", false, 1000)
            verify(!picker.animating)
            compare(picker.reveal, 0)
        }
        function test_pictures_keep_their_own_slow_entrance() {
            picker.open = true
            wait(tokens.geometryDuration + 40)
            verify(picker.reveal > .98, "The surface may finish before the pictures")
            verify(picker.contentReveal > 0 && picker.contentReveal < .2,
                "Pictures must begin gradually, instead of flashing with the surface")
            wait(400)
            verify(picker.contentReveal > .2 && picker.contentReveal < .9,
                "The diagonal gradient must still be crossing the grid")
            tryCompare(picker, "contentReveal", 1, 1500)
            tryCompare(picker, "animating", false)
            picker.reducedMotion = true
            picker.open = false; picker.open = true
            compare(picker.contentReveal, 1)
            verify(!picker.animating)
        }
        function test_click_keyboard_and_busy() {
            settle()
            compare(picker.selectedIndex, 5)
            const first = findChild(picker, "primaryWallpaperTile0")
            const fourth = findChild(picker, "primaryWallpaperTile3")
            const fifth = findChild(picker, "primaryWallpaperTile4")
            verify(first !== null && fourth !== null && fifth !== null)
            compare(fourth.y, first.y, "The fourth card must remain in the first row")
            verify(fifth.y > first.y)
            keyClick(Qt.Key_Right); compare(picker.selectedIndex, 6)
            keyClick(Qt.Key_Down); compare(picker.selectedIndex, 10)
            compare(applied.count, 0, "Navigation must not apply wallpapers")
            keyClick(Qt.Key_Return)
            compare(applied.count, 1)
            compare(applied.signalArguments[0][0].key, "static:10")
            picker.applying = true
            keyClick(Qt.Key_Return); compare(applied.count, 1)
            picker.applying = false
            keyClick(Qt.Key_Home); compare(picker.selectedIndex, 0)
            wait(30)
            const card = findChild(picker, "primaryWallpaperTile2")
            verify(card !== null)
            mouseClick(card, card.width / 2, card.height / 2)
            compare(applied.count, 2)
            compare(applied.signalArguments[1][0].key, "static:2")
            picker.forceActiveFocus()
            keyClick(Qt.Key_End); compare(picker.selectedIndex, 499)
            keyClick(Qt.Key_Right); compare(picker.selectedIndex, 499)
            keyClick(Qt.Key_F5); compare(refreshed.count, 1)
            keyClick(Qt.Key_Escape)
            verify(!picker.open)
        }
        function test_reduced_motion_empty_and_resize() {
            picker.reducedMotion = true
            picker.open = true
            verify(picker.interactive && !picker.animating)
            for (const size of [[1920,1080], [800,600], [480,320], [320,240]]) {
                picker.width = size[0]; picker.height = size[1]
                verify(picker.panelRect.x >= picker.leftInset)
                verify(picker.panelRect.x + picker.panelRect.width <= picker.width - picker.rightInset)
                verify(picker.panelRect.y + picker.panelRect.height <= picker.height)
            }
            picker.entries = []
            compare(picker.selectedIndex, -1)
            keyClick(Qt.Key_Return); compare(applied.count, 0)
            picker.entries = library(2)
            picker.activeKey = "static:1"
            compare(picker.selectedIndex, 1)
            picker.open = false
            verify(!picker.mounted && !picker.animating)
        }
        function test_large_library_recycles_thumbnails() {
            settle()
            const grid = findChild(picker, "primaryWallpaperGrid")
            wait(100)
            function liveTiles() {
                return grid.contentItem.children.filter(child =>
                    String(child.objectName).startsWith("primaryWallpaperTile")).length
            }
            verify(liveTiles() <= 32, "Only visible rows and a small cache may decode thumbnails")
            picker.navigate("down")
            keyClick(Qt.Key_End); wait(100)
            verify(liveTiles() <= 36)
            picker.open = false
            tryCompare(picker, "mounted", false, 1000)
            tryCompare(grid, "count", 0)
        }
        function test_loading_uses_the_complete_stable_surface() {
            picker.entries=[];picker.loading=true
            picker.open=true
            wait(65)
            const grid=findChild(picker,"primaryWallpaperGrid")
            const finalWidth=picker.metrics.width-picker.metrics.padding*2+picker.metrics.gap
            fuzzyCompare(grid.width,finalWidth,.01,"Grid must not reflow with the opening morph")
            const completeHeight=picker.metrics.height
            picker.entries=library(59)
            fuzzyCompare(picker.metrics.height,completeHeight,.01,"Cold inventory resized the surface")
            picker.loading=false
            fuzzyCompare(picker.metrics.height,completeHeight,.01)
            tryCompare(picker,"interactive",true,1500)
            verify(grid.height<=picker.panelRect.height-picker.metrics.top-picker.metrics.padding+.01)
        }
        function test_incremental_insert_and_preview_keep_existing_tiles_and_scroll() {
            picker.reducedMotion=true;picker.entries=library(60);picker.open=true
            picker.navigate("down");picker.navigate("down");picker.navigate("down")
            const grid=findChild(picker,"primaryWallpaperGrid")
            const selected=picker.selectedIndex
            const original=findChild(picker,"primaryWallpaperTile"+selected)
            verify(original!==null)
            const scroll=grid.contentY
            const next=picker.entries.slice()
            next.push({key:"static:new",path:"",preview:"",title:"Novo",addedAt:Date.now()/1000})
            picker.entries=next
            compare(picker.selectedIndex,selected)
            compare(findChild(picker,"primaryWallpaperTile"+selected),original)
            fuzzyCompare(grid.contentY,scroll,.01)
            compare(picker.contentReveal,1)
            next[selected]=Object.assign({},next[selected],{title:"Prévia pronta"})
            picker.entries=next.slice()
            compare(findChild(picker,"primaryWallpaperTile"+selected),original)
            compare(original.modelData.title,"Prévia pronta")
            picker.navigate("down");picker.forceActiveFocus();keyClick(Qt.Key_End)
            wait(30)
            const added=findChild(picker,"primaryWallpaperTile60")
            verify(added!==null && added.recent,"New discovery must have a glow")
            const expired=next.slice()
            expired[60]=Object.assign({},expired[60],{addedAt:Date.now()/1000-1801})
            picker.entries=expired
            verify(!added.recent,"Recent highlight does not expire")
        }
        function test_insert_during_the_diagonal_entrance_does_not_restart_it() {
            picker.entries=library(20);picker.open=true
            wait(450)
            const progress=picker.contentReveal,pose=picker.reveal
            picker.entries=picker.entries.concat([{key:"static:new",path:"",preview:"",title:"Novo",addedAt:Date.now()/1000}])
            fuzzyCompare(picker.reveal,pose,.001)
            fuzzyCompare(picker.contentReveal,progress,.001)
            wait(100)
            verify(picker.contentReveal>progress)
        }
    }
}
