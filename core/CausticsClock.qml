import QtQuick

QtObject {
    id: root

    required property bool active
    required property bool reduced
    property real phase: 0

    onActiveChanged: {
        if (active)
            phase = (Date.now() / 1000) % 4096
    }

    property FrameAnimation frameClock: FrameAnimation {
        running: root.active && !root.reduced
        onTriggered: root.phase = (root.phase
            + Math.min(0.05, Math.max(0, frameTime))) % 4096
    }
}
