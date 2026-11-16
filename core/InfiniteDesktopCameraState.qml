import QtQuick

QtObject {
    id: root
    property var views: ({})

    function clear() { views = ({}) }
    function validPair(value, positive) {
        return Array.isArray(value) && value.length === 2
            && value.every(n => typeof n === "number" && Number.isFinite(n)
                && (!positive || n > 0))
    }
    function validPose(value) {
        return value && typeof value.monitor === "string" && value.monitor.length > 0
            && typeof value.active === "boolean"
            && (!value.active || (typeof value.zoom === "number"
                && Number.isFinite(value.zoom) && value.zoom >= .2 && value.zoom <= 3
                && validPair(value.center, false) && validPair(value.origin, false)
                && validPair(value.viewport, true)))
    }
    function applyPose(value) {
        if (!validPose(value)) return false
        views = Object.assign({}, views, {[value.monitor]: value})
        return true
    }
    function applySnapshot(value, observedViews) {
        if (!value || !Array.isArray(value.widgetViews)
                || !value.widgetViews.every(pose => validPose(pose))) return false
        const next = {}
        for (const pose of value.widgetViews) next[pose.monitor] = pose
        // Keep frame events received while the initial query was in flight,
        // while still seeding the other outputs that have stayed idle.
        if (observedViews) for (const name of Object.keys(views)) {
            if (views[name] !== observedViews[name]) next[name] = views[name]
        }
        views = next
        return true
    }
    function readEvent(line) {
        const prefix = "velora-infinite-camera>>"
        if (!line.startsWith(prefix)) return false
        try { return applyPose(JSON.parse(line.slice(prefix.length))) }
        catch (error) { return false }
    }
}
