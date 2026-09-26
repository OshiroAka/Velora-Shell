import QtQuick

Item {
    id: root

    required property var media
    required property var theme
    required property var motion
    property url artSource
    property url fallbackArt
    property string title: ""
    property string artist: ""
    property bool showUi: false
    property bool interactive: false
    property real uiOpacity: 1
    property real contourStrength: 1
    property real shadowStrength: 1
    property bool instantArtSwitch: false
    property url bufferA: ""
    property url bufferB: ""
    property bool showingA: true
    property bool imageInitialized: false
    readonly property bool artReady: imageInitialized
        && ((showingA && imageA.status === Image.Ready
                && String(bufferA) === String(artSource))
            || (!showingA && imageB.status === Image.Ready
                && String(bufferB) === String(artSource)))

    function queueArt() {
        const target = String(artSource || "")
        if (!target.length)
            return
        if (!imageInitialized) {
            bufferA = target
            showingA = true
            imageInitialized = true
            return
        }
        const displayed = String(showingA ? bufferA : bufferB)
        if (displayed === target)
            return
        if (showingA) {
            bufferB = target
            if (imageB.status === Image.Ready)
                showingA = false
        } else {
            bufferA = target
            if (imageA.status === Image.Ready)
                showingA = true
        }
    }

    onArtSourceChanged: Qt.callLater(queueArt)

    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: 30
        color: Qt.rgba(0.01, 0.015, 0.03, 0.30)
        opacity: 0.52 * root.shadowStrength
    }

    RoundedImage {
        anchors.fill: parent
        source: root.fallbackArt
        radius: 26
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
    }

    RoundedImage {
        id: imageA
        anchors.fill: parent
        source: root.bufferA
        radius: 26
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        visible: status === Image.Ready
        opacity: root.showingA ? 1 : 0

        onStatusChanged: {
            if (status === Image.Ready && String(root.bufferA) === String(root.artSource))
                root.showingA = true
        }

        Behavior on opacity {
            enabled: !root.instantArtSwitch
            NumberAnimation { duration: root.motion.micro; easing.type: Easing.OutCubic }
        }
    }

    RoundedImage {
        id: imageB
        anchors.fill: parent
        source: root.bufferB
        radius: 26
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        visible: status === Image.Ready
        opacity: root.showingA ? 0 : 1

        onStatusChanged: {
            if (status === Image.Ready && String(root.bufferB) === String(root.artSource))
                root.showingA = false
        }

        Behavior on opacity {
            enabled: !root.instantArtSwitch
            NumberAnimation { duration: root.motion.micro; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 26
        color: "transparent"
        border.width: 2
        border.color: Qt.rgba(1, 1, 1, 0.70 * root.contourStrength)
    }

    Rectangle {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 2
        width: parent.width - 44
        height: 1
        radius: 0.5
        color: Qt.rgba(1, 1, 1, 0.54 * root.contourStrength)
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 114
        radius: 28
        visible: root.showUi
        opacity: root.uiOpacity
        gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.82) }
        }
    }

    Text {
        x: 14
        y: 158
        width: 190
        text: root.title
        visible: root.showUi
        opacity: root.uiOpacity
        color: "white"
        elide: Text.ElideRight
        font.family: root.theme.bodyFont
        font.pixelSize: 11
        font.weight: Font.DemiBold
    }

    Text {
        x: 14
        y: 177
        width: 190
        text: root.artist
        visible: root.showUi
        opacity: root.uiOpacity
        color: Qt.rgba(1, 1, 1, 0.76)
        elide: Text.ElideRight
        font.family: root.theme.bodyFont
        font.pixelSize: 8
    }

    Row {
        x: 52
        y: 198
        spacing: 12
        visible: root.showUi
        opacity: root.uiOpacity

        Repeater {
            model: [
                { id: "previous", symbol: "◀", enabled: root.media.canPrevious },
                { id: "toggle", symbol: root.media.playing ? "Ⅱ" : "▶", enabled: root.media.canToggle },
                { id: "next", symbol: "▶", enabled: root.media.canNext }
            ]

            Item {
                id: mediaControl
                required property var modelData
                width: 30
                height: 28
                opacity: modelData.enabled ? 1 : 0.38
                scale: controlMouse.pressed ? 0.88
                    : (controlMouse.containsMouse ? 1.10 : 1)

                Behavior on scale {
                    NumberAnimation { duration: root.motion.micro; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: controlMouse.containsMouse
                        ? Qt.rgba(1, 1, 1, 0.28) : Qt.rgba(0, 0, 0, 0.30)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.30)

                    Behavior on color {
                        ColorAnimation { duration: root.motion.micro }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: mediaControl.modelData.symbol
                    color: "white"
                    font.family: root.theme.bodyFont
                    font.pixelSize: mediaControl.modelData.id === "toggle" ? 13 : 11
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: controlMouse
                    anchors.fill: parent
                    enabled: root.interactive && mediaControl.modelData.enabled
                    hoverEnabled: enabled
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (mediaControl.modelData.id === "previous")
                            root.media.previous()
                        else if (mediaControl.modelData.id === "toggle")
                            root.media.togglePlaying()
                        else if (mediaControl.modelData.id === "next")
                            root.media.next()
                    }
                }
            }
        }
    }

    Rectangle {
        x: 14
        y: 232
        width: 190
        height: 2
        radius: 1
        visible: root.showUi
        opacity: root.uiOpacity
        color: Qt.rgba(1, 1, 1, 0.32)

        Rectangle {
            width: parent.width * root.media.progress
            height: parent.height
            radius: 1
            color: "white"

            Behavior on width {
                NumberAnimation { duration: 180; easing.type: Easing.Linear }
            }
        }
    }

    Component.onCompleted: Qt.callLater(queueArt)
}
