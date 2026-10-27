import QtQuick

Canvas {
    id: root
    property string iconName: "person"
    property color ink: "#f1f3f4"
    implicitWidth: 22; implicitHeight: 22
    antialiasing: true
    onIconNameChanged: requestPaint()
    onInkChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const c = getContext("2d")
        c.reset(); c.scale(width / 24, height / 24)
        c.strokeStyle = root.ink; c.fillStyle = root.ink
        c.lineWidth = 1.65; c.lineCap = "round"; c.lineJoin = "round"
        function line(x,y,x2,y2) { c.beginPath(); c.moveTo(x,y); c.lineTo(x2,y2); c.stroke() }
        function dot(x,y,r) { c.beginPath(); c.arc(x,y,r,0,Math.PI*2); c.fill() }
        if (iconName === "person" || iconName === "group") {
            dot(12,8,3.2)
            c.beginPath(); c.moveTo(5.5,20); c.quadraticCurveTo(5.5,13,12,13)
            c.quadraticCurveTo(18.5,13,18.5,20); c.closePath(); c.fill()
            if (iconName === "group") {
                dot(4.5,9,2.2); dot(19.5,9,2.2)
                c.beginPath(); c.moveTo(1,18); c.quadraticCurveTo(1,13,5,13); c.stroke()
                c.beginPath(); c.moveTo(23,18); c.quadraticCurveTo(23,13,19,13); c.stroke()
            }
        } else if (iconName === "video") {
            c.beginPath(); c.roundedRect(2,5.5,13,13,2,2); c.stroke()
            c.beginPath(); c.moveTo(15,10); c.lineTo(22,6); c.lineTo(22,18); c.lineTo(15,14); c.stroke()
        } else if (iconName === "phone") {
            c.beginPath(); c.moveTo(6,3); c.lineTo(9,7); c.lineTo(7,10)
            c.quadraticCurveTo(9,15,14,17); c.lineTo(17,15); c.lineTo(21,18)
            c.quadraticCurveTo(20,23,15,21); c.bezierCurveTo(7,18,2,11,3,6)
            c.quadraticCurveTo(3,3,6,3); c.closePath(); c.stroke()
        } else if (iconName === "more") {
            dot(12,5,1.4); dot(12,12,1.4); dot(12,19,1.4)
        } else if (iconName === "emoji") {
            c.beginPath(); c.arc(12,12,9.5,0,Math.PI*2); c.stroke()
            dot(8.5,9.5,1); dot(15.5,9.5,1)
            c.beginPath(); c.arc(12,12,5,.2,Math.PI-.2); c.stroke()
        } else if (iconName === "attach") {
            c.beginPath(); c.moveTo(9,13); c.lineTo(15,7)
            c.bezierCurveTo(19,3,23,7,19,11); c.lineTo(10,20)
            c.bezierCurveTo(4,26,-1,19,5,13); c.lineTo(14,4)
            c.bezierCurveTo(21,-3,29,6,22,13); c.lineTo(14,21); c.stroke()
        } else if (iconName === "send") {
            c.beginPath(); c.moveTo(3,11); c.lineTo(21,3); c.lineTo(16,21)
            c.lineTo(11,15); c.lineTo(3,11); c.closePath(); c.stroke()
            line(11,15,21,3)
        } else if (iconName === "add") {
            line(5,12,19,12); line(12,5,12,19)
        } else if (iconName === "back") {
            line(14,6,8,12); line(8,12,14,18)
        } else if (iconName === "down") {
            line(6,9,12,15); line(12,15,18,9)
        } else if (iconName === "play") {
            c.beginPath(); c.moveTo(8,5); c.lineTo(19,12); c.lineTo(8,19); c.closePath(); c.stroke()
        } else if (iconName === "pause") {
            c.beginPath(); c.roundedRect(6,5,3.5,14,1,1); c.roundedRect(14.5,5,3.5,14,1,1); c.stroke()
        } else if (iconName === "close") {
            line(6,6,18,18); line(18,6,6,18)
        } else if (iconName === "read") {
            line(1,13,5,17); line(5,17,13,7)
            line(10,13,14,17); line(14,17,22,7)
        }
    }
}
