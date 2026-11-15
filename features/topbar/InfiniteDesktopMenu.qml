pragma ComponentBehavior: Bound
import QtQuick
import "../../components" as Components
import "TopBarGeometry.js" as Geometry

Components.VeloraRailPopover {
    id: root
    required property var composition
    property var shell: null
    property string screenName: ""
    property real contour: 0
    readonly property var contourSamples: Array(21).fill(0)
    readonly property real sidebarWaveScale: 0
    readonly property real dockProgress: 0
    readonly property real sidebarWaveWidth: 0
    readonly property var sidebarSamples: contourSamples
    theme: composition.topbarTheme
    system: composition.topbarTools
    motion: composition.motionTokens
    rightSide: true
    railWidth: 4
    extension: ({y:0,width:0,height:0})
    preferredWidth: Geometry.size(toolType)[0]
    preferredHeight: Geometry.size(toolType)[1]
    closeOnLeave: false
    function activate(type, item) {
        if (type === "controls") { close(); composition.topbarActions.openSettings(); return }
        const same = toolType === type && opened
        toolType = type
        anchorY = item.mapToItem(root, item.width/2, item.height/2).y
        if (same) close()
        else open()
    }
    customContent: Component {
        BarPanelContent {
            active: root.mounted
            type: root.toolType; presented: root.opened
            theme: root.theme; system: root.system
            systemStatus: root.composition.networkStatus
            fanPlus: root.composition.fanPlusService
            timerService: root.composition.clockTimerService
            clock: root.composition.topbarClock
            calendar: root.composition.topbarCalendar
            media: root.composition.mediaService
            weather: root.composition.forecastService
            controller: root; actions: root.composition.topbarActions
            shell: root.shell; screenName: root.screenName
            motionTokens: root.motion
        }
    }
}
