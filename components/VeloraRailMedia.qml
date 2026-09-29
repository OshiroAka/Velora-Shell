pragma ComponentBehavior: Bound
import QtQuick
import Qt5Compat.GraphicalEffects
import Velora.Visualizer 1.0

Rectangle {
    id: root
    required property var media
    property var visualizer: null
    property color surfaceColor: "#272730"
    property color ink: "white"
    property color accent: "#b8a18d"
    property string fontFamily: "sans-serif"
    property real availableHeight: 176
    property real expansion: 0
    property real controlsReveal: 0
    readonly property bool hasPlayer: !!media && media.hasPlayer
    readonly property bool playing: hasPlayer && media.playing
    readonly property bool interacting: hover.hovered || pointerHold.active
        || previousButton.activeFocus || playButton.activeFocus || nextButton.activeFocus
    implicitWidth: 44
    implicitHeight: 100 + Math.max(0, Math.min(76, availableHeight - 100)) * expansion
    height: implicitHeight
    radius: 11 + expansion
    clip: true
    color: surfaceColor
    border.width: 1
    border.color: Qt.rgba(ink.r, ink.g, ink.b, 0.23)

    // Same ordering as the top-bar widgets: form first, then controls.
    function updatePresentation() {
        if (interacting) {
            exitDelay.stop()
            if (closing.running) {
                closing.stop(); opening.restart(); contentDelay.restart()
            } else if (!opening.running && !enterDelay.running && expansion < 1) enterDelay.restart()
        } else {
            enterDelay.stop()
            exitDelay.restart()
        }
    }
    onInteractingChanged: updatePresentation()
    onVisibleChanged: if (!visible) {
        enterDelay.stop(); exitDelay.stop(); contentDelay.stop()
        opening.stop(); entering.stop(); closing.stop()
        expansion = 0; controlsReveal = 0
    }
    HoverHandler { id: hover; blocking: false }
    PointHandler { id: pointerHold; acceptedButtons: Qt.LeftButton }
    Timer {
        id: enterDelay; interval: 110
        onTriggered: {
            closing.stop(); opening.restart(); contentDelay.restart()
        }
    }
    Timer {
        id: exitDelay; interval: 180
        onTriggered: {
            opening.stop(); contentDelay.stop(); entering.stop(); closing.restart()
        }
    }
    NumberAnimation { id: opening; target: root; property: "expansion"; to: 1; duration: 210; easing.type: Easing.OutCubic }
    Timer { id: contentDelay; interval: 135; onTriggered: entering.restart() }
    NumberAnimation { id: entering; target: root; property: "controlsReveal"; to: 1; duration: 150; easing.type: Easing.OutCubic }
    SequentialAnimation {
        id: closing
        NumberAnimation { target: root; property: "controlsReveal"; to: 0; duration: 65; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "expansion"; to: 0; duration: 125; easing.type: Easing.InOutCubic }
    }

    Rectangle {
        id: cover
        anchors.horizontalCenter: parent.horizontalCenter
        y: 5
        width: parent.width - 10; height: width
        radius: 8
        color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.06)
        Image {
            id: artwork
            anchors.fill: parent
            source: root.hasPlayer ? root.media.artUrl : ""
            sourceSize.width: 96; sourceSize.height: 96
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            smooth: true
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle { width: cover.width; height: cover.height; radius: cover.radius }
            }
        }
        VeloraMaterialIcon {
            anchors.centerIn: parent
            width: 20; height: 20
            visible: artwork.status !== Image.Ready
            iconName: "music"; iconColor: root.ink
            opacity: 0.55
        }
    }
    Text {
        anchors.top: cover.bottom; anchors.topMargin: 5
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 6; height: 12
        text: root.hasPlayer ? root.media.title : "Mídia"
        textFormat: Text.PlainText
        color: root.ink
        font.family: root.fontFamily; font.pixelSize: 9; font.weight: Font.Medium
        horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
    }
    Text {
        y: 57; width: parent.width - 6
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.hasPlayer
        text: root.hasPlayer ? root.media.artist : ""
        textFormat: Text.PlainText
        color: root.ink; opacity: 0.72
        font.family: root.fontFamily; font.pixelSize: 8
        horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
    }
    Spectrum {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 76; width: 38; height: 18
        analyzer: root.visualizer
        active: visible && root.visible && root.playing && !!root.visualizer && root.visualizer.running
        referenceHeight: height; strength: 0.3
        opacity: 0.85
        accentStart: root.ink; accentMiddle: root.ink; accentEnd: root.ink
        outlineColor: "transparent"
    }
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 100 + (1 - root.controlsReveal) * 4
        opacity: root.controlsReveal
        visible: opacity > 0.001
        enabled: root.controlsReveal > 0.6
        scale: 0.97 + root.controlsReveal * 0.03
        spacing: 1
        Transport {
            id: previousButton
            iconName: "skip-previous"; label: "Faixa anterior"
            enabled: root.hasPlayer && root.media.canPrevious
            onTriggered: root.media.previous()
        }
        Transport {
            id: playButton
            height: 26
            iconName: root.playing ? "pause" : "play"
            label: root.playing ? "Pausar" : "Reproduzir"
            enabled: root.hasPlayer && root.media.canToggle
            emphasized: true
            onTriggered: root.media.togglePlaying()
        }
        Transport {
            id: nextButton
            iconName: "skip-next"; label: "Próxima faixa"
            enabled: root.hasPlayer && root.media.canNext
            onTriggered: root.media.next()
        }
    }
    component Transport: Rectangle {
        id: button
        required property string iconName
        required property string label
        property bool emphasized: false
        signal triggered()
        width: 30; height: 22
        radius: 7
        activeFocusOnTab: enabled && visible
        color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b,
            pointer.pressed ? 0.15 : pointer.containsMouse || activeFocus ? 0.09 : emphasized ? 0.04 : 0)
        opacity: enabled ? 1 : 0.28
        scale: pointer.pressed ? 0.94 : 1
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Accessible.role: Accessible.Button
        Accessible.name: label
        Accessible.onPressAction: if (enabled) triggered()
        Keys.onSpacePressed: if (enabled) triggered()
        Keys.onReturnPressed: if (enabled) triggered()
        VeloraMaterialIcon {
            anchors.centerIn: parent
            width: button.emphasized ? 20 : 17; height: width
            iconName: button.iconName; iconColor: root.ink
            filled: button.emphasized
        }
        MouseArea {
            id: pointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.triggered()
        }
    }
}
