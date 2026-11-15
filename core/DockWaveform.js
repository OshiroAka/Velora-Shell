.pragma library

function response(frame) {
    const values = frame.map(value => Math.max(0, Math.min(1, Number(value) || 0)))
    function energy(start, end) {
        if (!values.length) return 0
        const a = Math.floor(start*values.length), b = Math.max(a+1, Math.ceil(end*values.length))
        let sum = 0
        for (let i=a;i<b;i++) sum += values[i]*values[i]
        return Math.sqrt(sum/(b-a))
    }
    return {level: energy(0,1), bass: energy(0,.32), treble: energy(.65,1)}
}

function points(width, height, level, bass, treble, phase) {
    const count = Math.max(96, Math.min(256, Math.ceil(width)))
    const amplitude = Math.max(0, Math.min(1, level)) * height*.86
    const result = []
    for (let i=0;i<=count;i++) {
        const t = i/count, center = t-.5
        const envelope = Math.exp(-Math.pow(center/(.13+bass*.025),2)*1.5)
        const carrier = Math.sin(center*Math.PI*(18+treble*4)+phase)
        const detail = .12*treble*Math.sin(center*Math.PI*38-phase*.5)
        const crest = .5+.5*(carrier+detail)/(1+.12*treble)
        result.push({x:t*width,y:height-crest*envelope*amplitude})
    }
    return result
}
