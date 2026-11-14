import QtQuick
import QtTest
import "../../features/topbar" as Topbar

Item {
    width: 720; height: 220
    QtObject {
        id: theme
        property color barSurface: "#292b30"
        property color accent: "#a0c4b6"
        property color accentSoft: "#bfd9d0"
        property color accentAlt: "#b99cff"
        property color surfaceSidebar: "#202029"
        property color textPrimary: "white"
        property color textSecondary: "gray"
        property color borderSubtle: "#40434a"
        property color success: "#a0c4b6"
        property color danger: "#dd7777"
        property string bodyFont: "Sans Serif"
        property string displayFont: "Sans Serif"
        function withAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    }
    Topbar.WorkspaceSwitcher { id: workspaces; x: 40; y: 10; width: implicitWidth; height: implicitHeight; theme: theme }
    Topbar.RunCatIcon { id: cat; x: 320; y: 30; cpuUsage: 5 }
    Topbar.CoffeeIcon { id: coffee; x: 400; y: 30 }
    QtObject {
        id: execution
        property var current: ({ phase: "idle", agent: "", label: "", detail: "", progress: -1 })
        readonly property bool shown: current.phase !== "idle"
    }
    Topbar.ExecutionIndicator { id: indicator; x: 450; y: 0; theme: theme; service: execution }
    Topbar.ChargingMorph { id: chargingMorph; anchorX: 615; theme: theme; percentage: 86 }
    Item {
        id: chargingStage
        anchors.fill: parent
        z: -1
        Topbar.ConnectedSurface {
            anchors.fill: parent
            barHeight: chargingMorph.barHeight
            panelRect: Qt.rect(110, 54, 140, 80)
            anchorX: 180; neckHalfWidth: 34
            executionRect: Qt.rect(310, 54, 160, 52)
            executionAnchor: 390; executionNeck: 34
            chargingRect: chargingMorph.surfaceRect
            chargingAnchor: chargingMorph.anchorX
            chargingNeck: chargingMorph.neckHalfWidth
            chargingRadius: chargingMorph.cornerRadius
            chargingJoin: chargingMorph.joinRadius
            fillColor: theme.barSurface
        }
    }
    SignalSpy { id: requests; target: workspaces; signalName: "workspaceRequested" }
    TestCase {
        name: "TopbarDetails"
        when: windowShown
        function init() {
            workspaces.workspaceIds = [1, 2, 3, 4, 5]
            workspaces.activeWorkspaceId = 1
            workspaces.pendingId = 0
            requests.clear()
            cat.visible = true; cat.animate = true; cat.cpuUsage = 5
            coffee.active = false
            chargingMorph.reducedMotion = true
            chargingMorph.charging = false
            chargingMorph.suppressed = false
            chargingMorph.reducedMotion = false
            chargingMorph.displayDuration = 6000
            chargingMorph.percentage = 86
            chargingMorph.anchorX = 615
            theme.barSurface = "#292b30"
            execution.current = { phase: "idle", agent: "", label: "", detail: "", progress: -1 }
            wait(270)
        }
        function test_workspace_real_acknowledgement_contract() {
            const button = findChild(workspaces, "workspaceButton4")
            mouseClick(button, button.width / 2, 15)
            compare(requests.count, 1)
            compare(requests.signalArguments[0][0], 4)
            compare(workspaces.activeWorkspaceId, 1, "Wait for backend acknowledgement")
            mouseClick(button, button.width / 2, 15)
            compare(requests.count, 1, "No duplicate dispatch while pending")
            const previous = workspaces.selectedCenter
            workspaces.activeWorkspaceId = 4
            compare(workspaces.pendingId, 0)
            wait(70)
            verify(workspaces.selectedCenter > previous && workspaces.selectedCenter < workspaces.targetCenter,
                "Indicator must pass through intermediate positions")
            wait(220)
            fuzzyCompare(workspaces.selectedCenter, workspaces.targetCenter, 0.1)
        }
        function test_workspace_hover_keyboard_and_external_changes() {
            const button = findChild(workspaces, "workspaceButton3")
            const hover = findChild(button, "workspaceHover")
            mouseMove(button, button.width / 2, 15)
            wait(180)
            fuzzyCompare(hover.opacity, 1, 0.01)
            button.forceActiveFocus()
            keyClick(Qt.Key_Return)
            compare(requests.count, 1)
            compare(requests.signalArguments[0][0], 3)
            workspaces.workspaceIds = [1, 2, 3, 4, 5, 8]
            workspaces.activeWorkspaceId = 8
            wait(260)
            compare(workspaces.selectedIndex, 5)
            fuzzyCompare(workspaces.selectedCenter, workspaces.targetCenter, 0.1)
        }
        function test_cat_continuity_cadence_and_stop() {
            const first = cat.phase
            wait(100)
            verify(cat.phase !== first)
            const cadence = cat.cadence
            cat.cpuUsage = 100
            wait(100)
            verify(cat.cadence > cadence && cat.cadence < cat.targetCadence,
                "Speed must interpolate without resetting the cycle")
            cat.animate = false
            const paused = cat.phase
            wait(100)
            compare(cat.phase, paused)
            cat.animate = true; cat.visible = false
            const hidden = cat.phase
            wait(100)
            compare(cat.phase, hidden, "Hidden icon must not animate")
        }
        function test_coffee_reveal_loop_and_idle() {
            const smoke = findChild(coffee, "coffeeSmoke")
            const strand = findChild(coffee, "coffeeSmokeStrand0")
            verify(!smoke.visible)
            coffee.active = true
            wait(90)
            verify(coffee.smokeReveal > 0 && coffee.smokeReveal < 1)
            wait(180)
            fuzzyCompare(coffee.smokeReveal, 1, 0.01)
            const phase = strand.progress
            wait(100)
            verify(strand.progress !== phase)
            coffee.active = false
            wait(90)
            verify(coffee.smokeReveal > 0 && coffee.smokeReveal < 1)
            wait(200)
            verify(!smoke.visible)
            const idle = strand.progress
            wait(100)
            compare(strand.progress, idle, "Inactive smoke must stop")
        }
        function test_execution_structure_before_content_and_reverse() {
            verify(!indicator.mounted)
            execution.current = { phase: "running", agent: "Fixture", label: "Teste de motion", detail: "", progress: -1 }
            wait(70)
            verify(indicator.reveal > 0 && indicator.reveal < 1)
            compare(indicator.contentReveal, 0, "Shape must precede content")
            wait(270)
            fuzzyCompare(indicator.contentReveal, 1, 0.01)
            execution.current = { phase: "running", agent: "Fixture", label: "Próxima etapa do teste", detail: "Etapa 2", progress: 0.5 }
            verify(indicator.mounted, "A state change must reuse the surface")
            wait(370)
            compare(indicator.presented.progress, 0.5)
            execution.current = { phase: "idle", agent: "", label: "", detail: "", progress: -1 }
            wait(30)
            verify(indicator.mounted, "Closing must preserve the surface until contraction ends")
            wait(230)
            verify(!indicator.mounted)
        }
        function test_charging_morph_expands_with_live_battery_percentage() {
            verify(!chargingMorph.visible)
            chargingMorph.charging = true
            verify(chargingMorph.visible)
            wait(80)
            verify(chargingMorph.reveal > 0 && chargingMorph.reveal < 1)
            compare(chargingMorph.contentReveal, 0, "The bar must expand before the text appears")
            wait(520)
            fuzzyCompare(chargingMorph.reveal, 1, 0.01)
            verify(chargingMorph.surfaceRect.height > 0)
            verify(chargingMorph.surfaceRect.x >= chargingMorph.leftInset)
            verify(chargingMorph.surfaceRect.x + chargingMorph.surfaceRect.width <= 720 - chargingMorph.rightInset)
            const battery = findChild(chargingMorph, "chargingBattery")
            verify(battery.width > battery.height)
            verify(chargingMorph.height <= 42)
            const center = battery.mapToItem(chargingMorph, battery.width / 2, battery.height / 2)
            fuzzyCompare(center.x, chargingMorph.width / 2, 0.1)
            fuzzyCompare(center.y, chargingMorph.height / 2, 0.1)
            compare(findChild(chargingMorph, "chargingPercentage"), null)
            const segment = findChild(chargingMorph, "chargingSegment5")
            const previousFill = segment.width
            chargingMorph.percentage = 87
            verify(segment.width > previousFill, "Battery segments must follow the real charge")
            chargingMorph.charging = false
            wait(90)
            const reversing = chargingMorph.reveal
            chargingMorph.charging = true
            compare(chargingMorph.reveal, reversing, "Reconnecting must preserve the current shape")
            tryCompare(chargingMorph, "reveal", 1, 600)
            chargingMorph.charging = false
            tryCompare(chargingMorph, "visible", false, 600)
            compare(chargingMorph.surfaceRect.height, 0)
            chargingMorph.reducedMotion = true
            chargingMorph.charging = true
            compare(chargingMorph.reveal, 1)
            chargingMorph.charging = false
            compare(chargingMorph.surfaceRect.height, 0)
        }
        function test_charging_event_expires_without_reopening_on_battery_updates() {
            compare(chargingMorph.displayDuration, 6000)
            chargingMorph.displayDuration = 700
            chargingMorph.charging = true
            wait(180)
            verify(chargingMorph.presenting)
            verify(chargingMorph.gradientProgress > 0 && chargingMorph.gradientProgress < 1)
            verify(chargingMorph.gradientStrength > 0)
            const segment = findChild(chargingMorph, "chargingSegment0")
            const opacity = segment.opacity
            wait(100)
            verify(segment.opacity !== opacity, "The segment glow must breathe slowly")
            tryCompare(chargingMorph, "presenting", false, 1000)
            verify(chargingMorph.charging, "The charger is still connected after dismissal")
            tryCompare(chargingMorph, "visible", false, 600)
            compare(chargingMorph.gradientStrength, 0)
            const phase = chargingMorph.pulsePhase
            chargingMorph.percentage = 90
            wait(120)
            verify(!chargingMorph.visible && !chargingMorph.presenting)
            compare(chargingMorph.pulsePhase, phase, "Hidden charging must stop the glow animation")
            chargingMorph.charging = false
            chargingMorph.charging = true
            verify(chargingMorph.presenting, "Reconnecting must open a new transient morph")
        }
        function test_charging_suppression_preserves_the_color_wave_and_deadline() {
            chargingMorph.suppressed = true
            chargingMorph.charging = true
            wait(180)
            verify(chargingMorph.presenting)
            verify(!chargingMorph.visible)
            compare(chargingMorph.surfaceRect.height, 0)
            verify(chargingMorph.gradientStrength > 0, "Side panels must preserve the charging color wave")
            const before = chargingMorph.gradientProgress
            chargingMorph.suppressed = false
            wait(80)
            verify(!chargingMorph.visible, "Closing a side panel cannot reopen this event's battery morph")
            verify(chargingMorph.gradientProgress > before, "Panel changes cannot restart the color wave")
            chargingMorph.charging = false
            chargingMorph.charging = true
            tryCompare(chargingMorph, "reveal", 1, 600)
            verify(chargingMorph.visible, "A new connection outside side panels allows the morph")
            chargingMorph.suppressed = true
            verify(!chargingMorph.visible)
            compare(chargingMorph.surfaceRect.height, 0, "Opening a side panel removes the native contour immediately")
            verify(chargingMorph.gradientStrength > 0)
        }
        function test_charging_shares_rendered_bar_material_and_continuous_neck() {
            if (chargingStage.GraphicsInfo.api === GraphicsInfo.Software)
                skip("The software scene graph cannot draw ShaderEffect")
            chargingMorph.reducedMotion = true
            chargingMorph.charging = true
            for (const color of [Qt.rgba(0.16, 0.32, 0.44, 0.35), Qt.rgba(0.42, 0.20, 0.12, 0.7)]) {
                theme.barSurface = color
                wait(50)
                const image = grabImage(chargingStage)
                const x = Math.round(chargingMorph.anchorX)
                verify(image.alpha(x, 20) > 0, "Shader must render the shared tint")
                for (let y = 24; y < 81; ++y) {
                    compare(image.alpha(x, y), image.alpha(x, 20), "Neck cannot have a gap or double opacity")
                    compare(image.red(x, y), image.red(x, 20), "Neck cannot change the material tint")
                    compare(image.green(x, y), image.green(x, 20))
                    compare(image.blue(x, y), image.blue(x, 20))
                }
                compare(image.alpha(180, 74), image.alpha(x, 74), "Menus and charging must share one fill")
                compare(image.alpha(390, 74), image.alpha(x, 74), "Notification and charging must share one fill")
                compare(image.alpha(x, 155), 0, "Material must stop at the charging contour")
            }
        }
    }
}
