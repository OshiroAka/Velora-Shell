#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 surfaceSize;
    vec4 panel;
    vec4 shapeMetrics;
    vec4 fillColor;
    vec4 lineColor;
    vec4 executionPanel;
    vec4 executionMetrics;
    float executionRadius;
} ubuf;
float box(vec2 p, vec2 halfSize, float r) {
    vec2 q = abs(p) - halfSize + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}
float joined(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}
float attach(float d, vec2 p, vec4 panel, vec4 metrics, float cornerRadius) {
    if (panel.w > 0.01) {
        vec2 halfSize = panel.zw * 0.5;
        float radius = min(cornerRadius, halfSize.y);
        float body = box(p - panel.xy - halfSize, halfSize, radius);
        float gap = panel.y - metrics.x;
        float neck = box(p - vec2(metrics.y, metrics.x + gap * 0.5),
            vec2(metrics.z, gap * 0.5 + min(10.0, halfSize.y)), min(6.0, halfSize.y));
        float k = min(metrics.w, panel.w);
        d = joined(joined(d, neck, max(k, 0.01)), body, max(k, 0.01));
    }
    return d;
}
void main() {
    vec2 p = qt_TexCoord0 * ubuf.surfaceSize;
    float d = attach(p.y - ubuf.shapeMetrics.x, p, ubuf.panel, ubuf.shapeMetrics, 18.0);
    d = attach(d, p, ubuf.executionPanel, ubuf.executionMetrics, ubuf.executionRadius);
    float aa = max(fwidth(d), 0.65);
    float coverage = 1.0 - smoothstep(-aa, aa, d);
    float rim = 1.0 - smoothstep(0.0, 1.1, abs(d + 0.5));
    // A single fill and inside stroke: there is no alpha overlap at the neck.
    fragColor = mix(ubuf.fillColor, ubuf.lineColor, rim * ubuf.lineColor.a) * coverage * ubuf.qt_Opacity;
}
