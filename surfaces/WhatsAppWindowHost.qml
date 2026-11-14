pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import Quickshell
import "../components" as Components

Scope {
    id: root
    required property var client
    required property var theme
    property bool reducedMotion: false
    property bool active: false
    property var handoffSource: null
    property string originMonitor: ""
    property var viewState: ({})
    property int savedWidth: 1080
    property int savedHeight: 740
    readonly property bool pending: active && !!handoffSource && handoffSource.mounted
    readonly property var window: loader.item
    signal opening()
    signal dockRequested(string monitor)
    function open(monitor, source) {
        if (active) { raise(); return }
        originMonitor = monitor || ""
        handoffSource = source || null
        active = true
        opening()
    }
    function raise() {
        if (!window) return
        if (window.visibility === Window.Minimized) window.showNormal()
        window.requestActivate()
    }
    function close() {
        if (window) {
            window.rememberView()
            if (window.visibility !== Window.Maximized && window.visibility !== Window.Minimized) {
                savedWidth = window.width; savedHeight = window.height
            }
        }
        active = false
        handoffSource = null
    }
    function dock() {
        const monitor = (window && window.screen ? window.screen.name : "") || originMonitor
        close()
        Qt.callLater(() => root.dockRequested(monitor))
    }
    LazyLoader {
        id: loader
        active: root.active && !root.pending
        Window {
            id: win
            objectName: "veloraWhatsAppWindow"
            title: "WhatsApp — Velora"
            visible: true
            width: Math.min(root.savedWidth, Screen.desktopAvailableWidth || root.savedWidth)
            height: Math.min(root.savedHeight, Screen.desktopAvailableHeight || root.savedHeight)
            minimumWidth: 360; minimumHeight: 480
            flags: Qt.Window | Qt.FramelessWindowHint
            color: "#10191d"
            function rememberView() { content.rememberView() }
            onClosing: event => { event.accepted = false; root.close() }
            Components.VeloraWhatsAppWindowContent {
                id: content
                anchors.fill: parent
                client: root.client; theme: root.theme; viewState: root.viewState
                reducedMotion: root.reducedMotion
                maximized: win.visibility === Window.Maximized
                onMoveRequested: win.startSystemMove()
                onMinimizeRequested: win.showMinimized()
                onMaximizeRequested: win.visibility === Window.Maximized ? win.showNormal() : win.showMaximized()
                onCloseRequested: root.close()
                onDockRequested: root.dock()
            }
            Repeater {
                model: [Qt.TopEdge | Qt.LeftEdge, Qt.TopEdge, Qt.TopEdge | Qt.RightEdge,
                    Qt.LeftEdge, Qt.RightEdge, Qt.BottomEdge | Qt.LeftEdge, Qt.BottomEdge, Qt.BottomEdge | Qt.RightEdge]
                delegate: MouseArea {
                    required property int modelData
                    readonly property bool leftEdge: (modelData & Qt.LeftEdge) !== 0
                    readonly property bool rightEdge: (modelData & Qt.RightEdge) !== 0
                    readonly property bool topEdge: (modelData & Qt.TopEdge) !== 0
                    readonly property bool bottomEdge: (modelData & Qt.BottomEdge) !== 0
                    readonly property bool corner: (leftEdge || rightEdge) && (topEdge || bottomEdge)
                    x: leftEdge ? 0 : rightEdge ? win.width - width : 8
                    y: topEdge ? 0 : bottomEdge ? win.height - height : 8
                    width: leftEdge || rightEdge ? (corner ? 8 : 4) : win.width - 16
                    height: topEdge || bottomEdge ? (corner ? 8 : 4) : win.height - 16
                    enabled: win.visibility !== Window.Maximized
                    cursorShape: corner ? (leftEdge === topEdge ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor)
                        : leftEdge || rightEdge ? Qt.SizeHorCursor : Qt.SizeVerCursor
                    onPressed: win.startSystemResize(modelData)
                }
            }
        }
    }
}
