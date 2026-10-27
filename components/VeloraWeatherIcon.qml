import QtQuick

// Weather conditions use the same outlined vocabulary as the bar.
Canvas {
    id: root
    property string name: "partly"
    property color ink: "white"
    implicitWidth: 24; implicitHeight: 24
    onNameChanged: requestPaint()
    onInkChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const c = getContext("2d"); c.reset()
        c.scale(width / 32,height / 32)
        c.strokeStyle = ink; c.fillStyle = ink
        c.lineWidth = 1.55; c.lineCap = "round"; c.lineJoin = "round"
        function line(x,y,xx,yy) { c.beginPath(); c.moveTo(x,y); c.lineTo(xx,yy); c.stroke() }
        function circle(x,y,r) { c.beginPath(); c.arc(x,y,r,0,Math.PI*2); c.stroke() }
        function sun(x,y,r) {
            circle(x,y,r)
            for(let i=0;i<8;i++) {
                const a=i*Math.PI/4
                line(x+Math.cos(a)*(r+3),y+Math.sin(a)*(r+3),x+Math.cos(a)*(r+5),y+Math.sin(a)*(r+5))
            }
        }
        function cloud(bottom) {
            c.beginPath(); c.moveTo(9,bottom); c.bezierCurveTo(1,bottom,2,bottom-11,9,bottom-10)
            c.bezierCurveTo(11,bottom-21,25,bottom-19,25,bottom-9)
            c.bezierCurveTo(34,bottom-8,31,bottom,25,bottom); c.closePath(); c.stroke()
        }
        if (name === "sun") sun(16,16,6)
        else if (name === "partly") { sun(10,10,4); cloud(27) }
        else if (name === "cloud") cloud(25)
        else if (["rain","storm","snow"].includes(name)) {
            cloud(21)
            if(name === "storm") {
                c.beginPath(); c.moveTo(18,23); c.lineTo(13,28); c.lineTo(17,28); c.lineTo(15,31); c.stroke()
            } else if(name === "snow") {
                for(const x of [10,22]) { line(x-2,27,x+2,27); line(x,25,x,29); line(x-1.5,25.5,x+1.5,28.5) }
            } else { line(10,25,8,29); line(17,25,15,29); line(24,25,22,29) }
        } else if (name === "wind") {
            line(3,12,22,12); c.beginPath(); c.moveTo(22,12); c.bezierCurveTo(30,12,28,2,22,6); c.stroke()
            line(3,17,28,17); line(7,22,20,22)
            c.beginPath(); c.moveTo(20,22); c.bezierCurveTo(28,22,27,31,21,28); c.stroke()
        } else if (name === "humidity") {
            c.beginPath(); c.moveTo(16,3); c.bezierCurveTo(12,10,6,15,6,21)
            c.bezierCurveTo(6,33,26,33,26,21); c.bezierCurveTo(26,15,20,10,16,3); c.closePath(); c.stroke()
            line(12,24,20,16); circle(12,17,1.3); circle(20,23,1.3)
        } else if (name === "temperature") {
            c.beginPath(); c.moveTo(12,20); c.lineTo(12,7); c.bezierCurveTo(12,1,20,1,20,7)
            c.lineTo(20,20); c.bezierCurveTo(29,29,3,34,10,22); c.lineTo(12,20); c.stroke()
            line(16,11,16,23); circle(16,25,2)
        }
    }
}
