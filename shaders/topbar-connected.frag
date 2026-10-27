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
    vec4 chargingPanel;
    vec4 chargingMetrics;
    float chargingRadius;
    vec4 chargingLight;
    vec4 timerLight;
    vec4 timerPanel;
    vec4 timerMetrics;
    float timerRadius;
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
            vec2(metrics.z, gap * 0.5 + min(cornerRadius * 10.0 / 18.0, halfSize.y)),
            min(cornerRadius / 3.0, halfSize.y));
        float k = min(metrics.w, panel.w);
        d = joined(joined(d, neck, max(k, 0.01)), body, max(k, 0.01));
    }
    return d;
}
// Same field as the native topbar: color moves inside the existing material.
vec3 barLightColor(vec3 base, vec2 point, vec4 light, float span, bool alert) {
    if (light.w <= 0.001) return base;
    float t = clamp(light.z, 0.0, 1.0);
    vec2 offset = point - light.xy;
    float distance = length(offset);
    float reach = 36.0 + max(span, 320.0) * 0.82 * t;
    float band = 50.0 + reach * 0.30;
    float wave = exp(-pow((distance - reach) / band, 2.0));
    float wake = exp(-distance / max(55.0, reach * 0.82)) * 0.32;
    float vertical = exp(-abs(offset.y) / (85.0 + reach * 1.10));
    float spectrum = 0.5 + 0.5 * sin((point.x - light.x) * 0.012 - t * 5.0 + point.y * 0.018);
    vec3 hue = mix(vec3(0.25, 0.50, 0.93), vec3(0.84, 0.32, 0.58), spectrum);
    hue = mix(hue, vec3(0.53, 0.36, 0.86), 0.30 + 0.18 * sin(t * 6.0 + distance * 0.008));
    if (alert) hue = vec3(0.84, 0.32, 0.38);
    float weight = clamp((wave * 0.78 + wake) * vertical * light.w, 0.0, 0.60);
    return mix(base, hue, weight) + hue * weight * 0.035;
}
void main() {
    vec2 p = qt_TexCoord0 * ubuf.surfaceSize;
    float d = attach(p.y - ubuf.shapeMetrics.x, p, ubuf.panel, ubuf.shapeMetrics, 18.0);
    d = attach(d, p, ubuf.executionPanel, ubuf.executionMetrics, ubuf.executionRadius);
    d = attach(d, p, ubuf.chargingPanel, ubuf.chargingMetrics, ubuf.chargingRadius);
    d = attach(d, p, ubuf.timerPanel, ubuf.timerMetrics, ubuf.timerRadius);
    float aa = max(fwidth(d), 0.65);
    float coverage = 1.0 - smoothstep(-aa, aa, d);
    float rim = 1.0 - smoothstep(0.0, 1.1, abs(d + 0.5));
    // A single fill and inside stroke: there is no alpha overlap at the neck.
    vec4 fill = ubuf.fillColor;
    if (fill.a > 0.001) {
        vec3 color = barLightColor(fill.rgb / fill.a, p, ubuf.chargingLight, ubuf.surfaceSize.x, false);
        fill.rgb = barLightColor(color, p, ubuf.timerLight, ubuf.surfaceSize.x, true) * fill.a;
    }
    fragColor = mix(fill, ubuf.lineColor, rim * ubuf.lineColor.a) * coverage * ubuf.qt_Opacity;
}
