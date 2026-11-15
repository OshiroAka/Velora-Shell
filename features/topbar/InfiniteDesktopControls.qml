pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import "../../components" as Components
import "../../core" as Core
import "../../core/InfiniteDockGeometry.js" as Geometry

Item {
    id: root
    required property var config
    required property var theme
    required property var status
    required property var timerService
    property real unit: 1
    property bool interactive: true
    property string monitorName: ""
    readonly property var tools: ["battery", "paint", "monitor", "controls", "timer"]
    property int targetStart: -1
    property real displayStart: -1
    property real wheelRemainder: 0
    property bool scrollActive: false
    readonly property real itemScale: .68 + .20 * enlargement.value
    readonly property string focusedType: tools[wrapped(targetStart + 1)]
    signal activated(string type, var item)
    width: 128 * unit; height: width
    enabled: interactive
    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Canvas {
            width: root.width; height: root.height
            antialiasing: true
            onPaint: {
                const c=getContext("2d"), s=root.unit
                c.reset(); c.beginPath()
                c.moveTo(width,0); c.lineTo(width-4*s,0)
                c.bezierCurveTo(width-4*s,height-59.51665*s,width-88.17047*s,height-4*s,width-192*s,height-4*s)
                c.lineTo(width-192*s,height); c.lineTo(width,height); c.closePath()
                c.fillStyle="white"; c.fill()
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Component.onCompleted: requestPaint()
        }
    }

    function wrapped(index) { return ((index % tools.length) + tools.length) % tools.length }
    function turn(steps) {
        if (!interactive || !steps) return
        scrollActive = true
        compactDelay.restart()
        targetStart += steps
        turning.stop()
        if (config.reducedMotion) displayStart = targetStart
        else { turning.to = targetStart; turning.start() }
    }
    function itemForType(type) {
        for (let i=0;i<slots.count;i++) {
            const item=slots.itemAt(i)
            if (item.type === type && item.visible && item.opacity > .01) return item
        }
        return null
    }
    Core.SettleValue {
        id: enlargement
        target: root.scrollActive ? 1 : 0
        reducedMotion: root.config.reducedMotion
        overshoot: 0; duration: 180
    }
    Timer { id: compactDelay; interval: 1200; onTriggered: root.scrollActive=false }
    HoverHandler {
        id: groupPointer
        blocking: false
        onHoveredChanged: if (!hovered) { root.scrollActive=false; compactDelay.stop() }
    }
    Connections {
        target: root.config
        function onReducedMotionChanged() {
            if (root.config.reducedMotion) { turning.stop(); root.displayStart = root.targetStart }
        }
    }
    NumberAnimation {
        id: turning; target: root; property: "displayStart"
        duration: 300; easing.type: Easing.OutCubic
    }
    Repeater {
        id: slots
        model: 5
        Item {
            id: slot
            required property int index
            readonly property real positionIndex: index - 1 - (root.displayStart - Math.floor(root.displayStart))
            readonly property string type: root.tools[root.wrapped(Math.floor(root.displayStart) + index - 1)]
            readonly property real visualWidth: type === "timer" ? 48 : type === "battery" ? 30 : 20
            readonly property real visualHeight: type === "timer" ? 23 : 26
            readonly property real displayScale: .68 + (root.itemScale-.68)*Math.min(1,Math.max(0,emphasis.emphasis))
            readonly property real fittingScale: displayScale * (1+.18*Math.max(focused ? 1 : 0, emphasis.emphasis))
            readonly property var position: Geometry.controlPosition(positionIndex, root.unit,
                visualWidth*fittingScale, visualHeight*fittingScale)
            readonly property bool focused: type === root.focusedType
            readonly property bool acceptsInput: focused && Math.abs(positionIndex-1) < .15 && root.interactive
            objectName: "infiniteDeskControl-" + type
            x: root.width - position.x - width/2
            y: root.height + position.y - height/2
            width: 26 * root.unit; height: width
            opacity: Math.pow(Math.max(0, 1 - Math.abs(positionIndex-1)/1.5), 1.3)
            visible: opacity > .001
            z: focused ? 2 : 0
            activeFocusOnTab: visible && acceptsInput
            Accessible.role: Accessible.Button
            Accessible.ignored: !acceptsInput
            Accessible.name: ({battery:"Bateria",paint:"Composição",monitor:"Monitores",controls:"Configurações",timer:"Temporizador"})[type]
            Accessible.onPressAction: if (acceptsInput) root.activated(type, slot)
            Keys.onReturnPressed: if (acceptsInput) root.activated(type, slot)
            Keys.onSpacePressed: if (acceptsInput) root.activated(type, slot)
            Keys.onLeftPressed: root.turn(-1)
            Keys.onRightPressed: root.turn(1)
            Components.VeloraIconMotion {
                id: emphasis
                highlighted: slot.focused
                reducedMotion: root.config.reducedMotion
            }
            Item {
                id: face
                objectName: "infiniteDeskControlFace"
                anchors.centerIn: parent
                width: slot.visualWidth
                height: slot.visualHeight
                scale: root.unit * slot.displayScale * (1 + .18 * emphasis.emphasis)
                opacity: .72 + .28 * emphasis.emphasis
                layer.enabled: emphasis.emphasis > .001
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: root.theme.accent
                    shadowBlur: .65
                    shadowOpacity: .8 * emphasis.emphasis
                    shadowHorizontalOffset: 0; shadowVerticalOffset: 0
                }
                BatteryIndicator {
                    anchors.centerIn: parent
                    visible: slot.type === "battery"
                    available: root.status.hasBattery; level: root.status.batteryLevel; charging: root.status.batteryCharging
                    color: root.theme.textPrimary; warningColor: root.theme.warning; criticalColor: root.theme.danger
                }
                BarIcon {
                    anchors.centerIn: parent
                    visible: !["battery", "timer"].includes(slot.type)
                    width: 20; height: 22
                    name: slot.type; color: root.theme.textPrimary
                }
                TimerBadge {
                    anchors.centerIn: parent
                    shown: slot.type === "timer"
                    config: root.config; theme: root.theme; timerService: root.timerService
                    monitor: root.monitorName; compact: true; labelPixelSize: 11
                    width: 48; height: 23
                }
            }
            HoverHandler { id: pointer; enabled: slot.acceptsInput; cursorShape: Qt.PointingHandCursor }
            TapHandler { enabled: slot.acceptsInput; onTapped: root.activated(slot.type, slot) }
        }
    }
    WheelHandler {
        target: null
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const delta = event.angleDelta.y || event.angleDelta.x
            if (delta) {
                root.wheelRemainder += delta
                const steps = root.wheelRemainder > 0 ? Math.floor(root.wheelRemainder/120) : Math.ceil(root.wheelRemainder/120)
                if (steps) { root.wheelRemainder -= steps*120; root.turn(-steps) }
            } else if (event.pixelDelta.y) root.turn(event.pixelDelta.y > 0 ? -1 : 1)
            event.accepted = true
        }
    }
}
