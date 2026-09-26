import QtQuick

QtObject {
    id: root

    required property var motion
    property real progress: 0
    property bool targetLocked: false
    property bool running: false
    property string phase: "desktop"
    readonly property bool elevated: progress > 0.001 || targetLocked

    signal settled(bool locked)

    function clamp(value) {
        return Math.max(0, Math.min(1, Number(value)))
    }

    function setLocked(locked) {
        const target = locked ? 1 : 0
        targetLocked = Boolean(locked)
        progressAnimation.stop()
        const distance = Math.abs(target - progress)
        if (distance < 0.0005) {
            progress = target
            running = false
            phase = locked ? "lock" : "desktop"
            settled(locked)
            return
        }
        phase = locked ? "opening" : "closing"
        running = true
        progressAnimation.from = progress
        progressAnimation.to = target
        progressAnimation.duration = Math.max(1, Math.round(
            (locked ? motion.widgetOpen : motion.widgetExit) * distance))
        progressAnimation.easing.type = locked ? Easing.OutCubic : Easing.InOutCubic
        progressAnimation.start()
    }

    function staggeredProgress(stagger) {
        if (motion.reduced)
            return clamp(progress)
        const count = 5
        const stepOpen = motion.widgetStagger / Math.max(1, motion.widgetOpen)
        const stepClose = motion.widgetStagger / Math.max(1, motion.widgetExit)
        const order = Math.max(0, Math.min(count, Number(stagger)))
        if (targetLocked || phase === "opening") {
            const delay = order * stepOpen
            return clamp((progress - delay) / Math.max(0.001, 1 - delay))
        }
        const reverseDelay = (count - order) * stepClose
        return clamp(progress / Math.max(0.001, 1 - reverseDelay))
    }

    function outBack(value) {
        const t = clamp(value) - 1
        const overshoot = 0.32
        return 1 + (overshoot + 1) * t * t * t + overshoot * t * t
    }

    function motionProgress(stagger) {
        const local = staggeredProgress(stagger)
        if (motion.reduced)
            return local
        return targetLocked || phase === "opening"
            ? outBack(local) : 1 - outBack(1 - local)
    }

    function activity(stagger) {
        const local = staggeredProgress(stagger)
        return running ? Math.max(0, 4 * local * (1 - local)) : 0
    }

    property PropertyAnimation progressAnimation: PropertyAnimation {
        id: progressAnimation
        target: root
        property: "progress"
        onFinished: {
            root.progress = root.targetLocked ? 1 : 0
            root.running = false
            root.phase = root.targetLocked ? "lock" : "desktop"
            root.settled(root.targetLocked)
        }
    }
}
