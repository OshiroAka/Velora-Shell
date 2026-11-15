import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "../../core" as Core
import "../../components" as Components
import "../../features/editor" as Editor

ShellRoot {
    id: test
    function equal(actual, expected, message) { if (actual !== expected) throw Error((message || "compare") + ": " + actual + " !== " + expected) }
    function check(value, message) { if (!value) throw Error(message || "verify") }
    Core.ConfigStore { id: config }
    Components.VeloraDockAppIcon { id: glyphProbe; visible: false }
    QtObject {
        id: theme
        property color textPrimary: "#f4f4f6"
        property color textSecondary: "#bdbdc5"
        property color accent: "#c8788f"
        property color accentSoft: accent
        property color warning: "#e7bd76"
        property color danger: "#e07282"
        property color profileDark: "#171a22"
        property color barBubbleTint: accent
        property bool manualPalette: false
        property color borderSubtle: "#40404a"
        property color barSurface: "#e8171a22"
        property string bodyFont: "Sans Serif"
        function withAlpha(c,a) { return Qt.rgba(c.r,c.g,c.b,a) }
    }
    QtObject { id: shell; property int settingsRequests: 0; function openUnifiedSettings() { settingsRequests++ } function toggleTopSearch() {} }
    QtObject {
        id: status
        property bool hasBattery: true
        property real batteryLevel: .72
        property bool batteryCharging: false
    }
    QtObject {
        id: timer
        property string barText: "25:00"
        property string timerText: barText
        property var countdown: ({running:false})
        property bool finished: false
        property int duration: 1500000
        property bool engaged: false
    }
    property string activatedControl: ""
    QtObject {
        id: edge
        property bool mounted: false
        property real bodyWidth: 180
        property real bodyY: 100
        property real bodyHeight: 140
        property real contour: 0
        property var extension: ({y: 100, width: 0, height: 0})
        signal shapeChanged()
        onMountedChanged: shapeChanged()
    }
    Window {
        id: win
        width: 1280; height: 720; visible: true; color: "#73818d"
        Components.InfiniteDesktopDock {
            id: dock
            anchors.fill: parent
            config: config; theme: theme; shell: shell; screen: Quickshell.screens[0]
            edgePanel: edge
            controlStatus: status; controlTimer: timer
            onControlActivated: (type, item) => test.activatedControl=type
            progress: 1; reveal: 1
        }
    }
    Window {
        id: settings
        width: 600; height: 500; visible: true; color: "#202027"
        Editor.SettingsInfiniteDock { id: page; width: parent.width - 32; x: 16; y: 16; config: config; theme: theme }
    TestCase {
        id: input
        when: false
        function run() {
            if (Quickshell.env("VELORA_DOCK_RELOAD") === "1") {
                test.equal(config.infiniteDeskPinnedItems.join(","), "shell:settings,dock-test")
                test.equal(config.infiniteDeskOutlineIcons, false, "Icon preference must persist")
                console.info("INFINITE_DOCK_OK persisted")
                Qt.quit()
                return
            }
            for (const pair of [["com.spotify.Client", "Spotify"], ["com.discordapp.Discord", "Discord"], ["io.github.mimbrero.WhatsAppDesktop", "WhatsApp"], ["steam", "Steam"], ["zen", "Zen"], ["brave-browser", "Brave"], ["Wallpaper Engine", "WallpaperEngine"], ["steam-game-123", ""]]) {
                glyphProbe.identifier=pair[0]
                test.equal(glyphProbe.sharedGlyph,pair[1],"Desktop ID must select the shared glyph automatically")
            }
            test.equal(config.infiniteDeskPinnedItems.length, 0)
            test.equal(dock.dockWidth, 0, "Empty dock must have no central elevation")
            const search = findChild(page, "infiniteDesk.pinSearch")
            settings.requestActivate()
            search.forceActiveFocus()
            for (const character of "Dock Test") keyClick(character)
            wait(50)
            test.equal(page.choices.length, 1)
            const add = findChild(page, "infiniteDesk.addPin")
            mouseClick(add)
            test.equal(config.infiniteDeskPinnedItems[0], "dock-test")
            page.pin("shell:settings")
            page.pin("shell:search")
            page.pin("dock-test")
            test.equal(config.infiniteDeskPinnedItems.length, 3, "Duplicates cannot be pinned")
            const earlier = findChild(page, "infiniteDesk.pinEarlier1")
            earlier.forceActiveFocus(); keyClick(Qt.Key_Space)
            test.equal(config.infiniteDeskPinnedItems[0], "shell:settings")
            const remove = findChild(page, "infiniteDesk.removePin2")
            remove.forceActiveFocus(); keyClick(Qt.Key_Space)
            test.equal(config.infiniteDeskPinnedItems.join(","), "shell:settings,dock-test")
            wait(80)
            test.equal(dock.entries.length, 2)
            const icon = findChild(dock, "infiniteDeskAppIcon-dock-test")
            const outlineSwitch = findChild(page, "infiniteDesk.outlineIcons")
            test.equal(icon.outline, true, "Outline icons are enabled by default")
            outlineSwitch.forceActiveFocus(); keyClick(Qt.Key_Space)
            test.equal(icon.outline, false, "Keyboard switch restores original icons immediately")
            mouseClick(outlineSwitch)
            test.equal(icon.outline, true, "Mouse switch enables contours immediately")
            config.setValue("infiniteDesk.outlineIcons", "invalid")
            test.equal(config.infiniteDeskOutlineIcons, true, "Invalid preference falls back")
            config.setValue("infiniteDesk.outlineIcons", false)
            const controls=dock.controls
            test.check(!!controls,"Right-hand controls are missing")
            test.equal(controls.focusedType,"battery")
            test.equal(controls.tools.join(","),"battery,paint,monitor,controls,timer")
            const focused=controls.itemForType("battery")
            const idleScale=findChild(focused,"infiniteDeskControlFace").scale
            test.check(idleScale < dock.unit,"Controls should stay small at rest")
            test.check(controls.itemForType("timer").opacity < focused.opacity,"Outer roulette items need a fade")
            win.requestActivate()
            mouseClick(focused,focused.width/2,focused.height/2)
            test.equal(test.activatedControl,"battery","Original battery action was lost")
            const preview=controls.itemForType("paint")
            mouseMove(preview,preview.width/2,preview.height/2)
            mouseClick(preview,preview.width/2,preview.height/2)
            test.equal(controls.focusedType,"battery","Preview hover stole the roulette focus")
            test.equal(test.activatedControl,"battery","Only the centre item may open a menu")
            mouseWheel(controls,controls.width-38,controls.height-38,0,-120)
            wait(80)
            test.check(controls.displayStart > -1 && controls.displayStart < 0,"Scroll must animate along the curve")
            wait(320)
            test.equal(controls.focusedType,"paint")
            test.check(findChild(controls.itemForType("paint"),"infiniteDeskControlFace").scale > idleScale,"Scrolling should enlarge the focused icon")
            config.setValue("appearance.reducedMotion",true)
            controls.turn(3)
            test.equal(controls.focusedType,"timer")
            test.equal(controls.displayStart,controls.targetStart,"Reduced motion does not settle the controls")
            const timerSlot=controls.itemForType("timer")
            test.check(!!findChild(timerSlot,"barExistingBubble-timer"),"Timer must reuse its original badge")
            mouseClick(timerSlot,timerSlot.width/2,timerSlot.height/2)
            test.equal(test.activatedControl,"timer","Timer action was lost")
            controls.turn(5)
            test.equal(controls.focusedType,"timer","Roulette must wrap without losing tools")
            controls.turn(-4)
            test.equal(controls.focusedType,"battery")
            wait(300)
            config.setValue("appearance.reducedMotion",false)
            // The software renderer cannot capture the live GPU mask.
            dock.controlStatus=null
            wait(10)
            const numbers = [1,2,3,4,5].map(id => findChild(dock,"infiniteDeskWorkspace"+id))
            test.check(!findChild(dock,"infiniteDeskWorkspaceGroupBubble"), "Workspace bubbles must be removed")
            test.equal(findChild(dock,"infiniteDeskWorkspaces").height, 128, "Workspace corner must stay compact")
            test.check(-numbers[4].position.y < 15, "Last number must stay close to the bottom")
            test.check(numbers[0].position.y > -90, "Workspace group must be shorter")
            const emptyPanelImage = grabImage(dock)
            edge.extension = ({y: 124, width: 104, height: 44})
            edge.mounted = true
            wait(100)
            const panelImage = grabImage(dock)
            test.check(panelImage.red(1210, 170) !== emptyPanelImage.red(1210, 170), "Right menu must retain its background in Infinite Desk")
            test.equal(panelImage.red(900, 170), emptyPanelImage.red(900, 170), "Right menu background must remain bounded")
            test.check(panelImage.red(1010, 146) !== emptyPanelImage.red(1010, 146), "Lyrics balloon must have a continuous background")
            test.check(panelImage.red(1278, 400) !== panelImage.red(1000, 400), "Existing border must remain visible above the bottom curve")
            edge.mounted = false
            for (let i=0; i<5; i++) {
                test.check(numbers[i])
                test.check(numbers[i].x >= 0)
                if (i) { test.check(numbers[i].x > numbers[i-1].x); test.check(numbers[i].y > numbers[i-1].y) }
            }
            const before = numbers[1].x
            dock.activeWorkspace=2
            wait(70)
            test.check(dock.displayStart > 1 && dock.displayStart < 2, "Roulette must animate")
            wait(350)
            test.equal(dock.displayStart, 2)
            test.check(!findChild(dock,"infiniteDeskWorkspace1").visible, "Previous workspace must leave the curve")
            test.check(findChild(dock,"infiniteDeskWorkspace6").visible, "Next workspace must appear")
            test.check(findChild(dock,"infiniteDeskWorkspace2").x < before, "Numbers must travel along the curve")
            dock.activeWorkspace=9
            wait(350)
            test.check(findChild(dock,"infiniteDeskWorkspace13").visible, "Workspaces without windows must be reachable")
            dock.activeWorkspace=3
            wait(40)
            config.setValue("appearance.reducedMotion", true)
            test.equal(dock.displayStart, 3, "Reduced motion must settle an active roulette")
            dock.activeWorkspace=1
            test.equal(dock.displayStart, 1)
            wait(300)
            config.setValue("appearance.reducedMotion", false)
            dock.activeWorkspace=1
            wait(350)
            const dockViewport = findChild(dock, "infiniteDeskPinnedDock")
            test.equal(Math.round(dockViewport.x + dockViewport.width/2), win.width/2)
            test.equal(dockViewport.y + dockViewport.height, win.height)
            test.check(dockViewport.width < 200, "Small app lists must not have a fixed-width dock")
            mouseClick(dockViewport, dockViewport.width/2 - 25, dockViewport.height/2)
            test.equal(shell.settingsRequests, 1)
            for (const size of [[800,600],[1920,1080],[1280,720]]) {
                win.width=size[0];win.height=size[1];wait(30)
                test.equal(Math.round(dockViewport.x + dockViewport.width/2), win.width/2)
                test.check(dockViewport.width <= win.width*.43 + 1)
                test.check(dockViewport.height > 0)
                const last=findChild(dock,"infiniteDeskWorkspace5")
                test.check(last.x+last.width < dockViewport.x, "Workspaces cannot overlap the central dock")
            }
            const image = Quickshell.env("VELORA_DOCK_SCREENSHOT")
            if (image) win.contentItem.grabToImage(result => result.saveToFile(image))
            finish.running=true
        }
    }
    }
    Timer { interval: 120; running: true; onTriggered: { if (!config.ready) { restart(); return } try { input.run() } catch (error) { console.error("INFINITE_DOCK_FAILED", String(error)); Qt.quit() } } }
    Timer {
        id: finish
        interval: 100; repeat: true
        onTriggered: if (!config.savePending) { console.info("INFINITE_DOCK_OK saved"); Qt.quit() }
    }
    Timer { interval: 10000; running: true; onTriggered: { console.error("INFINITE_DOCK_FAILED timeout"); Qt.quit() } }
}
