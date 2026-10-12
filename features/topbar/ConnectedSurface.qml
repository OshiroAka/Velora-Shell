import QtQuick

ShaderEffect {
    property real barHeight: 40
    property rect panelRect: Qt.rect(0, 0, 0, 0)
    // Optional execution status shares this fill/stroke with the original menu.
    property rect executionRect: Qt.rect(0, 0, 0, 0)
    property real executionAnchor: 0
    property real executionNeck: 0
    property real executionRadius: 18
    property real executionJoin: 8
    readonly property vector4d executionPanel: Qt.vector4d(executionRect.x, executionRect.y, executionRect.width, executionRect.height)
    readonly property vector4d executionMetrics: Qt.vector4d(barHeight, executionAnchor, executionNeck, executionJoin)
    property real anchorX: 0
    property real neckHalfWidth: 120
    property color fillColor: "transparent"
    property color lineColor: "transparent"
    readonly property vector2d surfaceSize: Qt.vector2d(width, height)
    readonly property vector4d panel: Qt.vector4d(panelRect.x, panelRect.y, panelRect.width, panelRect.height)
    readonly property vector4d shapeMetrics: Qt.vector4d(barHeight, anchorX, neckHalfWidth, 8)
    fragmentShader: Qt.resolvedUrl("../../shaders/topbar-connected.frag.qsb")
}
