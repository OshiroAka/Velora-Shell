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
    QtObject {
        id: theme
        property color textPrimary: "#f4f4f6"
        property color textSecondary: "#bdbdc5"
        property color accent: "#c8788f"
        property color borderSubtle: "#40404a"
        property color barSurface: "#e8171a22"
        property string bodyFont: "Sans Serif"
        function withAlpha(c,a) { return Qt.rgba(c.r,c.g,c.b,a) }
    }
    QtObject { id: shell; property int settingsRequests: 0; function openUnifiedSettings() { settingsRequests++ } function toggleTopSearch() {} }
    Window {
        id: win
        width: 1280; height: 720; visible: true; color: "#73818d"
        Components.InfiniteDesktopDock {
            id: dock
            anchors.fill: parent
            config: config; theme: theme; shell: shell; screen: Quickshell.screens[0]
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
                console.info("INFINITE_DOCK_OK persisted")
                Qt.quit()
                return
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
            const numbers = [1,2,3,4,5].map(id => findChild(dock,"infiniteDeskWorkspace"+id))
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
    Timer { interval: 7000; running: true; onTriggered: { console.error("INFINITE_DOCK_FAILED timeout"); Qt.quit() } }
}
