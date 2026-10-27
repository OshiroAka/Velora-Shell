pragma ComponentBehavior: Bound
import QtQuick
import Qt5Compat.GraphicalEffects

Canvas {
    id: root
    property int style: 0
    property string imageSource: ""
    property string initials: ""
    implicitWidth: 44; implicitHeight: 44
    antialiasing: true
    onStyleChanged: requestPaint()
    onInitialsChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const c = getContext("2d")
        c.reset(); c.scale(width / 48, height / 48)
        c.beginPath(); c.arc(24, 24, 24, 0, Math.PI * 2); c.clip()
        if (root.style < 0) {
            c.fillStyle = "#293237"; c.fillRect(0,0,48,48)
            c.fillStyle = "#d7e2df"; c.font = "600 17px sans-serif"
            c.textAlign = "center"; c.textBaseline = "middle"
            c.fillText(root.initials,24,25)
            return
        }
        const skies = [["#465c71", "#11171e"], ["#75618d", "#2d384b"],
                       ["#da9a86", "#775671"], ["#5d666b", "#23292e"],
                       ["#9eb2a5", "#374d4a"]]
        const palette = skies[root.style % skies.length]
        const gradient = c.createLinearGradient(0, 0, 0, 48)
        gradient.addColorStop(0, palette[0]); gradient.addColorStop(1, palette[1])
        c.fillStyle = gradient; c.fillRect(0, 0, 48, 48)
        c.fillStyle = root.style === 2 ? "#efc3a0" : "#c3c9cd"
        c.globalAlpha = .6; c.beginPath(); c.arc(33, 14, root.style === 2 ? 8 : 4, 0, Math.PI * 2); c.fill()
        c.globalAlpha = 1
        c.fillStyle = root.style === 4 ? "#29453c" : "#1b2633"
        c.beginPath(); c.moveTo(-4, 43); c.lineTo(17, 18 + root.style * 2)
        c.lineTo(31, 31); c.lineTo(41, 24); c.lineTo(53, 45); c.closePath(); c.fill()
        c.fillStyle = "#10181e"
        c.beginPath(); c.moveTo(-3, 50); c.lineTo(9, 32); c.lineTo(26, 39)
        c.lineTo(41, 30); c.lineTo(53, 47); c.closePath(); c.fill()
    }
    Image {
        anchors.fill: parent
        source: root.imageSource
        sourceSize: Qt.size(128,128)
        asynchronous: true; fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
        layer.enabled: visible
        layer.effect: OpacityMask {
            maskSource: Rectangle { width: root.width; height: root.height; radius: width / 2; color: "white" }
        }
    }
}
