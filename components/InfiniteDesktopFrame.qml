import QtQuick
import "../core/InfiniteDockGeometry.js" as Geometry

Canvas {
    id: root
    property real progress: 0
    property real railWidth: 63
    property real oppositeWidth: 4
    property real bottomHeight: 16
    property real cornerRadius: 24
    property int dockCount: 0
    property bool rightSide: false
    property color surface: "#a0202029"
    antialiasing: true
    onProgressChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onSurfaceChanged: requestPaint()
    onRightSideChanged: requestPaint()
    onRailWidthChanged: requestPaint()
    onOppositeWidthChanged: requestPaint()
    onBottomHeightChanged: requestPaint()
    onCornerRadiusChanged: requestPaint()
    onDockCountChanged: requestPaint()
    onVisibleChanged: if (visible) requestPaint()
    onPaint: {
        const c = getContext("2d")
        c.clearRect(0,0,width,height)
        Geometry.path(c,width,height,dockCount,progress,railWidth,oppositeWidth,
                      bottomHeight,cornerRadius,rightSide)
        c.fillStyle = surface
        c.fill()
    }
}
