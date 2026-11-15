import QtQuick

// A retargetable decorative value; input geometry never depends on this item.
QtObject {
    id: root
    property real target: 0
    property real value: target
    property bool reducedMotion: false
    property bool enabled: true
    property int duration: 300
    property real overshoot: .55
    property bool ready: false
    function retarget() {
        animation.stop()
        if (!ready || reducedMotion || !enabled || Math.abs(value-target)<.00001) value=target
        else { animation.to=target;animation.restart() }
    }
    onTargetChanged: retarget()
    onReducedMotionChanged: retarget()
    onEnabledChanged: retarget()
    Component.onCompleted: { ready=true;value=target }
    property NumberAnimation animation: NumberAnimation {
        target: root;property: "value"
        duration: root.duration;easing.type: Easing.OutBack;easing.overshoot: root.overshoot
    }
}
