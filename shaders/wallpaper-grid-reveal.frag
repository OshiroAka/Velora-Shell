#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    vec2 viewSize;
} ubuf;
layout(binding = 1) uniform sampler2D source;
void main() {
    // Project physical coordinates onto (1, 1): the fade travels down/right
    // at 45 degrees even when the viewport is much wider than it is tall.
    vec2 point = qt_TexCoord0 * ubuf.viewSize;
    float distance = (point.x + point.y) / max(1.0, ubuf.viewSize.x + ubuf.viewSize.y);
    const float feather = 0.32;
    float edge = clamp(ubuf.progress, 0.0, 1.0) * (1.0 + feather);
    float coverage = 1.0 - smoothstep(edge - feather, edge, distance);
    fragColor = texture(source, qt_TexCoord0) * coverage * ubuf.qt_Opacity;
}
