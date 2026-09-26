import QtQuick
import Quickshell

Scope {
    id: root
    required property var config

    property string editSpace: "desktop"
    property string selectedLayerId: ""
    property var undoStack: []
    property var redoStack: []
    property bool gestureActive: false
    property string gestureLayerId: ""
    property var gestureBefore: ({})
    property var gesturePatch: ({})
    property bool layoutTransitioning: false
    property string toolMode: "select"
    readonly property int historyLimit: 50
    readonly property bool canUndo: undoStack.length > 0
    readonly property bool canRedo: redoStack.length > 0
    readonly property var editableLayers: buildEditableLayers()
    readonly property var builtInCatalog: [
        { kind: "clock", name: "Relógio", singleton: true },
        { kind: "calendar", name: "Calendário", singleton: true },
        { kind: "weather", name: "Previsão", singleton: true },
        { kind: "media", name: "Mídia", singleton: true },
        { kind: "gallery", name: "Galeria principal", singleton: true },
        { kind: "system", name: "Sistema", singleton: true }
    ]

    signal selectionChanged(string layerId)
    signal historyChanged

    function setToolMode(value) {
        const next = String(value) === "crop" ? "crop" : "select"
        if (toolMode === next)
            return false
        cancelGesture()
        toolMode = next
        return true
    }

    function clone(value) {
        return value === undefined ? undefined : JSON.parse(JSON.stringify(value))
    }

    function snapshot() {
        return {
            scene: clone(config.sceneLayers),
            widgets: clone(config.sharedWidgets),
            widgetLayout: {
                template: String(config.desktopLayoutTemplate),
                seed: String(config.desktopLayoutSeed)
            }
        }
    }

    function applySnapshot(value, persist) {
        if (!value || !Array.isArray(value.scene) || !Array.isArray(value.widgets))
            return false
        config.setSceneLayers(value.scene, false)
        const layout = value.widgetLayout || ({})
        config.setSharedWidgetState(value.widgets,
            String(layout.template || config.desktopLayoutTemplate),
            String(layout.seed || config.desktopLayoutSeed), persist)
        return true
    }

    function widgetIndex(identifier, widgets) {
        const source = widgets || config.sharedWidgets
        for (let index = 0; index < source.length; index += 1) {
            if (String(source[index].id) === String(identifier))
                return index
        }
        return -1
    }

    function sceneIndex(identifier, layers) {
        const source = layers || config.sceneLayers
        for (let index = 0; index < source.length; index += 1) {
            if (String(source[index].id) === String(identifier))
                return index
        }
        return -1
    }

    function isShared(identifier) { return widgetIndex(identifier) >= 0 }

    function buildEditableLayers() {
        const widgets = config.sharedWidgetLayers(editSpace)
        const target = editSpace === "desktop" ? "desktop" : "lock"
        const layers = config.sceneLayers.map(function(layer) {
            return Object.assign({}, layer, {
                visible: target === "desktop"
                    ? Boolean(layer.desktopEnabled) : Boolean(layer.lockEnabled),
                transform: clone(layer[target] || layer.transform || ({})),
                style: clone(layer[target + "Style"] || ({}))
            })
        })
        return layers.concat(widgets).sort(function(first, second) {
            return Number(first.order || 0) - Number(second.order || 0)
        })
    }

    function layerIndex(identifier, layers) {
        const source = layers || editableLayers
        for (let index = 0; index < source.length; index += 1) {
            if (String(source[index].id) === String(identifier))
                return index
        }
        return -1
    }

    function layerById(identifier) {
        const index = layerIndex(identifier)
        if (index < 0)
            return null
        const layer = editableLayers[index]
        if (!gestureActive || String(identifier) !== gestureLayerId)
            return layer
        return Object.assign({}, layer, {
            transform: effectiveTransform(identifier, layer.transform)
        })
    }

    function effectiveTransform(identifier, baseTransform) {
        const base = baseTransform || ({})
        if (!gestureActive || String(identifier) !== gestureLayerId)
            return base
        const candidate = Object.assign({}, base, gesturePatch)
        const position = widgetIndex(identifier)
        const layer = layerByIdRaw(identifier)
        return constrainForSpace(layer, candidate)
    }

    function layerByIdRaw(identifier) {
        const layers = editableLayers
        for (let index = 0; index < layers.length; index += 1) {
            if (String(layers[index].id) === String(identifier))
                return layers[index]
        }
        return null
    }

    function desktopTopbarRect() {
        // The segmented bar owns three separate regions, including islands
        // clipped against both screen edges. Reserve only its shallow top row
        // while keeping the rest of the Desktop canvas freely editable.
        return { x: 0, y: 0, width: 1600,
                 height: Math.max(54, Number(config.topbarHeight || 52) + 10) }
    }

    function constrainDesktopTopbar(layer, value) {
        const result = Object.assign({}, value || ({}))
        if (!layer || editSpace !== "desktop")
            return result
        const width = Number(layer.baseWidth || config.moduleSize(layer.type)[0])
            * Number(result.scale || 1)
        const height = Number(layer.baseHeight || config.moduleSize(layer.type)[1])
            * Number(result.scale || 1)
        const box = desktopTopbarRect()
        const x = Number(result.x || 0)
        const y = Number(result.y || 0)
        const intersects = x < box.x + box.width && x + width > box.x
            && y < box.y + box.height && y + height > box.y
        if (intersects)
            result.y = box.y + box.height
        return result
    }

    function constrainForSpace(layer, value) {
        let result = Object.assign({}, value || ({}))
        const position = layer ? widgetIndex(layer.id) : -1
        if (position >= 0)
            result = config.constrainWidgetTransform(config.sharedWidgets[position], result)
        return constrainDesktopTopbar(layer, result)
    }

    function patchSnapshotTransform(value, identifier, patch) {
        const widgetPosition = widgetIndex(identifier, value.widgets)
        if (widgetPosition >= 0) {
            const key = editSpace === "desktop" ? "desktop" : "lock"
            const candidate = Object.assign({},
                value.widgets[widgetPosition][key] || {}, patch || {})
            value.widgets[widgetPosition][key] = config.constrainWidgetTransform(
                value.widgets[widgetPosition], candidate)
            return true
        }
        const position = sceneIndex(identifier, value.scene)
        if (position < 0)
            return false
        const target = editSpace === "desktop" ? "desktop" : "lock"
        const candidate = Object.assign({}, value.scene[position][target]
            || value.scene[position].transform || {}, patch || {})
        const editable = Object.assign({}, value.scene[position], {
            transform: candidate
        })
        value.scene[position][target] = constrainForSpace(editable, candidate)
        if (target === "lock")
            value.scene[position].transform = clone(value.scene[position].lock)
        return true
    }

    function clearGestureState() {
        gestureActive = false
        gestureLayerId = ""
        gestureBefore = ({})
        gesturePatch = ({})
    }

    function select(identifier) {
        const next = layerIndex(identifier) >= 0 ? String(identifier) : ""
        if (selectedLayerId === next)
            return
        selectedLayerId = next
        selectionChanged(next)
    }

    function clearSelection() { select("") }

    function setEditSpace(value) {
        const next = String(value) === "desktop" ? "desktop" : "lock"
        if (editSpace === next)
            return false
        cancelGesture()
        editSpace = next
        clearSelection()
        return true
    }

    function pushHistory(before) {
        let next = undoStack.slice(0)
        next.push(clone(before))
        if (next.length > historyLimit)
            next = next.slice(next.length - historyLimit)
        undoStack = next
        redoStack = []
        historyChanged()
    }

    function commitChange(before, after) {
        if (JSON.stringify(before) === JSON.stringify(after))
            return false
        pushHistory(before)
        return applySnapshot(after, true)
    }

    function beginGesture(identifier) {
        const layer = layerById(identifier)
        if (!layer || layer.locked)
            return false
        gestureActive = true
        gestureLayerId = String(identifier)
        gestureBefore = snapshot()
        gesturePatch = ({})
        select(identifier)
        return true
    }

    function previewTransform(identifier, patch) {
        if (!gestureActive || String(identifier) !== gestureLayerId)
            return false
        const position = widgetIndex(identifier)
        const layer = layerByIdRaw(identifier)
        if (position >= 0) {
            const key = editSpace === "desktop" ? "desktop" : "lock"
            const base = gestureBefore.widgets[position][key] || ({})
            const candidate = Object.assign({}, base, gesturePatch, patch || {})
            const constrained = constrainForSpace(layer, candidate)
            gesturePatch = constrained
        } else {
            const scenePosition = sceneIndex(identifier, gestureBefore.scene)
            if (scenePosition < 0)
                return false
            const key = editSpace === "desktop" ? "desktop" : "lock"
            const base = gestureBefore.scene[scenePosition][key]
                || gestureBefore.scene[scenePosition].transform || ({})
            gesturePatch = constrainForSpace(layer,
                Object.assign({}, base, gesturePatch, patch || {}))
        }
        return true
    }

    function finishGesture() {
        if (!gestureActive)
            return false
        const before = clone(gestureBefore)
        const after = clone(gestureBefore)
        const identifier = gestureLayerId
        const patch = clone(gesturePatch)
        if (!patchSnapshotTransform(after, identifier, patch)) {
            clearGestureState()
            return false
        }
        if (editSpace === "desktop" && widgetIndex(identifier, after.widgets) >= 0)
            after.widgetLayout.template = "custom"
        clearGestureState()
        return commitChange(before, after)
    }

    function cancelGesture() {
        if (!gestureActive)
            return false
        clearGestureState()
        return true
    }

    function updateLayer(identifier, patch) {
        const before = snapshot()
        const next = clone(before)
        const widgetPosition = widgetIndex(identifier, next.widgets)
        const source = patch || ({})
        if (widgetPosition >= 0) {
            const widget = next.widgets[widgetPosition]
            for (const key in source) {
                if (key === "transform") {
                    const target = editSpace === "desktop" ? "desktop" : "lock"
                    const editable = Object.assign({}, widget, {
                        type: widget.kind,
                        transform: widget[target]
                    })
                    widget[target] = constrainForSpace(editable,
                        Object.assign({}, widget[target], source.transform))
                } else if (key === "visible") {
                    if (editSpace === "desktop")
                        widget.desktopEnabled = Boolean(source.visible)
                    else
                        widget.lockEnabled = Boolean(source.visible)
                } else if (key === "locked") {
                    widget.locked = Boolean(source.locked)
                } else if (key === "style") {
                    const targetStyle = editSpace === "desktop"
                        ? "desktopStyle" : "lockStyle"
                    widget[targetStyle] = Object.assign(
                        {}, widget[targetStyle] || {}, source.style || {})
                } else if (key === "variantId") {
                    widget.variantId = String(source.variantId || "inherit")
                } else if (key === "baseWidth" || key === "baseHeight") {
                    const sizeKey = editSpace === "desktop"
                        ? "desktopSize" : "lockSize"
                    const current = Object.assign({
                        width: widget.baseWidth,
                        height: widget.baseHeight
                    }, widget[sizeKey] || ({}))
                    const field = key === "baseWidth" ? "width" : "height"
                    current[field] = Math.max(8, Math.min(
                        8192, Number(source[key])))
                    widget[sizeKey] = current
                }
            }
            if (editSpace === "desktop")
                next.widgetLayout.template = "custom"
            return commitChange(before, next)
        }
        const position = sceneIndex(identifier, next.scene)
        if (position < 0)
            return false
        const layer = next.scene[position]
        const target = editSpace === "desktop" ? "desktop" : "lock"
        for (const key in source) {
            if (key === "transform") {
                layer[target] = constrainForSpace(
                    Object.assign({}, layer, { transform: layer[target] }),
                    Object.assign({}, layer[target] || layer.transform || {},
                                  source.transform))
                if (target === "lock")
                    layer.transform = clone(layer.lock)
            } else if (key === "visible") {
                if (target === "desktop")
                    layer.desktopEnabled = Boolean(source.visible)
                else {
                    layer.lockEnabled = Boolean(source.visible)
                    layer.visible = Boolean(source.visible)
                }
            } else if (key === "style") {
                const styleKey = target + "Style"
                layer[styleKey] = Object.assign(
                    {}, layer[styleKey] || {}, source.style || {})
            } else {
                layer[key] = source[key]
            }
        }
        return commitChange(before, next)
    }

    function setTransform(identifier, field, value) {
        const accepted = ["x", "y", "scale", "rotation", "opacity", "flipX"]
        if (!accepted.includes(String(field)))
            return false
        const patch = ({})
        patch[String(field)] = value
        return updateLayer(identifier, { transform: patch })
    }

    function newIdentifier(prefix) {
        return String(prefix) + "-" + Date.now() + "-"
            + Math.floor(Math.random() * 1000000)
    }

    function defaultStyle() {
        return { material: "inherit", solidColor: "#20222a",
            surfaceOpacity: 0.82, radius: 28, fontFamily: "Poppins",
            displayFontFamily: "", fontAsset: "", fontScale: 1,
            fontWeight: 500, letterSpacing: 0, textColor: "",
            accentColor: "", galleryLayout: "feature", gap: 10 }
    }

    function addCustomLayer(type, values) {
        const before = snapshot()
        const next = clone(before)
        let maximumOrder = 0
        for (let index = 0; index < next.scene.length; index += 1)
            maximumOrder = Math.max(maximumOrder, Number(next.scene[index].order || 0))
        const source = values || ({})
        const identifier = newIdentifier(type)
        const size = config.moduleSize(type)
        const initial = { x: editSpace === "desktop" ? 640 : 640,
            y: editSpace === "desktop" ? 290 : 330, scale: 1,
            rotation: 0, opacity: 1, flipX: false }
        const layer = {
            id: identifier, type: type,
            name: String(source.name || (type === "text" ? "Texto"
                : (type === "photoGrid" ? "Galeria" : "Imagem"))).slice(0, 80),
            plane: "abovePanel", order: maximumOrder + 10,
            desktopEnabled: editSpace === "desktop",
            lockEnabled: editSpace === "lock", visible: editSpace === "lock",
            locked: false,
            baseWidth: Number(source.baseWidth || size[0]),
            baseHeight: Number(source.baseHeight || size[1]),
            desktop: clone(initial), lock: clone(initial), transform: clone(initial),
            desktopStyle: defaultStyle(), lockStyle: defaultStyle(),
            crop: source.crop || { x: 0, y: 0, width: 1, height: 1 },
            variantId: "inherit"
        }
        if (type === "image")
            layer.source = String(source.source || "")
        else if (type === "text")
            layer.text = String(source.text || "Novo texto")
        else if (type === "photoGrid") {
            layer.items = Array.isArray(source.items) ? clone(source.items).slice(0, 16) : []
            layer.desktopStyle.material = "inherit"
            layer.lockStyle.material = "inherit"
            layer.desktopStyle.galleryLayout = String(source.layout || "grid2")
            layer.lockStyle.galleryLayout = String(source.layout || "grid2")
        }
        next.scene.push(layer)
        if (!commitChange(before, next))
            return ""
        select(identifier)
        return identifier
    }

    function addImage(source, name) {
        return addCustomLayer("image", { source: source, name: name })
    }

    function addText(text) {
        return addCustomLayer("text", { text: text || "Novo texto", name: "Texto" })
    }

    function addPhotoGrid(items, layout, name) {
        return addCustomLayer("photoGrid", {
            items: items || [], layout: layout || "grid2", name: name || "Galeria"
        })
    }

    function setItemStyle(identifier, field, value) {
        const accepted = ["material", "solidColor", "surfaceOpacity", "radius",
            "fontFamily", "displayFontFamily", "fontAsset", "fontScale",
            "fontWeight", "letterSpacing", "textColor", "accentColor",
            "galleryLayout", "gap"]
        if (!accepted.includes(String(field)))
            return false
        const style = ({})
        style[String(field)] = value
        return updateLayer(identifier, { style: style })
    }

    function setCrop(identifier, crop) {
        return updateLayer(identifier, { crop: crop })
    }

    function setPhotoItems(identifier, items) {
        return updateLayer(identifier, { items: Array.isArray(items)
            ? clone(items).slice(0, 16) : [] })
    }

    function setBuiltInVisible(kind, visible) {
        const position = config.sharedWidgets.findIndex(function(widget) {
            return String(widget.kind) === String(kind)
        })
        if (position < 0)
            return false
        return updateLayer(config.sharedWidgets[position].id, { visible: visible })
    }

    function duplicateSelected() {
        const current = layerById(selectedLayerId)
        if (!current || current.sharedWidget)
            return false
        const before = snapshot()
        const next = clone(before)
        const position = sceneIndex(selectedLayerId, next.scene)
        if (position < 0)
            return false
        const copy = clone(next.scene[position])
        copy.id = newIdentifier(copy.type)
        copy.name = String(copy.name || copy.type) + " cópia"
        copy.order = Number(copy.order || 0) + 1
        const target = editSpace === "desktop" ? "desktop" : "lock"
        copy[target].x = Number(copy[target].x || 0) + 24
        copy[target].y = Number(copy[target].y || 0) + 24
        if (target === "lock")
            copy.transform = clone(copy.lock)
        next.scene.push(copy)
        if (!commitChange(before, next))
            return false
        select(copy.id)
        return true
    }

    function removeSelected() {
        const layer = layerById(selectedLayerId)
        if (!layer)
            return false
        if (layer.sharedWidget)
            return updateLayer(layer.id, { visible: false })
        const before = snapshot()
        const next = clone(before)
        next.scene = next.scene.filter(function(entry) {
            return String(entry.id) !== root.selectedLayerId
        })
        clearSelection()
        return commitChange(before, next)
    }

    function moveSelected(direction) {
        const current = layerById(selectedLayerId)
        if (!current || current.sharedWidget)
            return false
        const before = snapshot()
        const next = clone(before)
        const samePlane = next.scene.filter(function(layer) {
            return layer.plane === current.plane
        }).sort(function(first, second) { return first.order - second.order })
        const position = samePlane.findIndex(function(layer) {
            return String(layer.id) === root.selectedLayerId
        })
        const target = Math.max(0, Math.min(samePlane.length - 1,
                                             position + Number(direction)))
        if (position < 0 || target === position)
            return false
        const own = sceneIndex(selectedLayerId, next.scene)
        const other = sceneIndex(samePlane[target].id, next.scene)
        const order = next.scene[own].order
        next.scene[own].order = next.scene[other].order
        next.scene[other].order = order
        return commitChange(before, next)
    }

    function setPlane(identifier, plane) {
        if (isShared(identifier))
            return false
        const before = snapshot()
        const next = clone(before)
        const position = sceneIndex(identifier, next.scene)
        if (position < 0)
            return false
        const targetPlane = String(plane) === "belowPanel" ? "belowPanel" : "abovePanel"
        let maximumOrder = 0
        for (let index = 0; index < next.scene.length; index += 1) {
            if (next.scene[index].plane === targetPlane)
                maximumOrder = Math.max(maximumOrder, Number(next.scene[index].order || 0))
        }
        next.scene[position].plane = targetPlane
        next.scene[position].order = maximumOrder + 10
        return commitChange(before, next)
    }

    function beginLayoutTransition() {
        layoutTransitioning = true
        layoutTransitionTimer.restart()
    }

    function applyDesktopTemplate(name) {
        if (editSpace !== "desktop")
            return false
        const before = snapshot()
        beginLayoutTransition()
        config.applyDesktopTemplate(name)
        const after = snapshot()
        if (JSON.stringify(before) === JSON.stringify(after))
            return false
        pushHistory(before)
        return true
    }

    function restoreDesktopLayout() {
        if (editSpace !== "desktop")
            return false
        const before = snapshot()
        beginLayoutTransition()
        config.restoreDesktopLayout()
        const after = snapshot()
        if (JSON.stringify(before) === JSON.stringify(after))
            return false
        pushHistory(before)
        return true
    }

    function advanceDesktopTemplate() {
        if (editSpace !== "desktop")
            return false
        const before = snapshot()
        beginLayoutTransition()
        config.advanceDesktopTemplate()
        const after = snapshot()
        if (JSON.stringify(before) === JSON.stringify(after))
            return false
        pushHistory(before)
        return true
    }

    function applyDesktopPreset(name) {
        return applyDesktopTemplate(String(name) === "center"
            ? "side-column" : "split-corners")
    }

    function undo() {
        if (!canUndo || gestureActive)
            return false
        const undoValues = undoStack.slice(0)
        const target = undoValues.pop()
        const redoValues = redoStack.slice(0)
        redoValues.push(snapshot())
        undoStack = undoValues
        redoStack = redoValues
        applySnapshot(target, true)
        if (layerIndex(selectedLayerId) < 0)
            clearSelection()
        historyChanged()
        return true
    }

    function redo() {
        if (!canRedo || gestureActive)
            return false
        const redoValues = redoStack.slice(0)
        const target = redoValues.pop()
        const undoValues = undoStack.slice(0)
        undoValues.push(snapshot())
        undoStack = undoValues.slice(Math.max(0, undoValues.length - historyLimit))
        redoStack = redoValues
        applySnapshot(target, true)
        historyChanged()
        return true
    }

    function resetHistory() {
        gestureActive = false
        gestureLayerId = ""
        gestureBefore = ({})
        gesturePatch = ({})
        undoStack = []
        redoStack = []
        clearSelection()
        historyChanged()
    }

    Timer {
        id: layoutTransitionTimer
        interval: root.config.reducedMotion ? 1 : 820
        repeat: false
        onTriggered: root.layoutTransitioning = false
    }
}
