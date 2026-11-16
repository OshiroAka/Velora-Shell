import QtQuick

QtObject {
    id: root
    property int workspaceId: 1
    property var state: ({independent: true, global: false, workspaces: {}})
    readonly property bool independent: state.independent
    readonly property var workspaces: state.workspaces
    readonly property bool globalEnabled: state.global
    readonly property bool active: independent ? workspaces[String(workspaceId)] === true : globalEnabled
    function apply(data) {
        // Preserve the running global UI until the upgraded native bridge has
        // published its first registry. Old files do not invent workspace modes.
        const line = String(data).trim()
        if (line === "enabled=1" || line === "enabled=0") {
            state = {independent: false, global: line === "enabled=1", workspaces: {}}
            return true
        }
        try {
            const state = JSON.parse(String(data))
            if (state.version !== 1 || typeof state.independent !== "boolean" || typeof state.global !== "boolean" || !state.workspaces
                    || typeof state.workspaces !== "object" || Array.isArray(state.workspaces)) return false
            const next = {}
            for (const key of Object.keys(state.workspaces))
                if (/^[1-9][0-9]*$/.test(key) && state.workspaces[key] === true) next[key] = true
            root.state = {independent: state.independent, global: state.global, workspaces: next}
            return true
        } catch (error) { return false }
    }
}
