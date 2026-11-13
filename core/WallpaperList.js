.pragma library

function key(entry) {
    return entry ? String(entry.key || (String(entry.kind || "static")+":"+String(entry.path || ""))) : ""
}

// A ListModel survives scans; only rows whose identity/data changed are touched.
function reconcile(model, previous, incoming, now) {
    const old = new Map(previous.map(entry=>[key(entry),entry]))
    const keys = []
    for (let i=0;i<model.count;i++) keys.push(model.get(i).entryKey)
    const wanted = new Set(incoming.map(key))
    const added = []
    for (let i=keys.length-1;i>=0;i--) {
        if (!wanted.has(keys[i])) { model.remove(i);keys.splice(i,1) }
    }
    for (let i=0;i<incoming.length;i++) {
        const entry=incoming[i], identity=key(entry)
        const at=keys.indexOf(identity,i)
        if (at<0) {
            model.insert(i,{entryKey:identity,entryData:entry,arrivedAt:now})
            keys.splice(i,0,identity)
            added.push(identity)
        } else {
            if (at!==i) { model.move(at,i,1);keys.splice(at,1);keys.splice(i,0,identity) }
            if (JSON.stringify(old.get(identity))!==JSON.stringify(entry)) model.setProperty(i,"entryData",entry)
        }
    }
    return added
}
