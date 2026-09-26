import QtQuick

ShaderEffect {
    id: root

    property bool active: false
    property real phase: 0
    property real strength: 0.32
    property size itemSize: Qt.size(width, height)
    property point designOrigin: Qt.point(0, 0)
    property real designScale: 1
    property real designRotation: 0
    property real cornerRadius: 24

    visible: active && strength > 0.001 && width > 0 && height > 0
    blending: true
    vertexShader: "../../assets/shaders/pool-caustics.vert.qsb"
    fragmentShader: "../../assets/shaders/pool-caustics.frag.qsb"
}
