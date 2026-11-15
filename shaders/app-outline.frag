#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 pixelStep;
    vec4 ink;
    float symbolic;
} ubuf;
layout(binding = 1) uniform sampler2D source;
// Ignore small chromatic changes and gradients in full-colour artwork.
// A perceptual Sobel field preserves the logo's structure with a single stroke.
vec2 field(vec2 uv) {
    vec4 p = texture(source, uv);
    return vec2(dot(p.rgb, vec3(0.2126, 0.7152, 0.0722)), p.a);
}
vec2 gradient(vec2 uv) {
    vec2 d = ubuf.pixelStep;
    vec2 tl=field(uv-d), tc=field(uv-vec2(0,d.y)), tr=field(uv+vec2(d.x,-d.y));
    vec2 ml=field(uv-vec2(d.x,0)), mr=field(uv+vec2(d.x,0));
    vec2 bl=field(uv+vec2(-d.x,d.y)), bc=field(uv+vec2(0,d.y)), br=field(uv+d);
    vec2 gx=(tr+2.0*mr+br-tl-2.0*ml-bl)*0.25;
    vec2 gy=(bl+2.0*bc+br-tl-2.0*tc-tr)*0.25;
    return dot(vec2(gx.y,gy.y),vec2(gx.y,gy.y)) > dot(vec2(gx.x,gy.x),vec2(gx.x,gy.x))
        ? vec2(gx.y,gy.y) : vec2(gx.x,gy.x);
}
void main() {
    if (ubuf.symbolic > 0.5) {
        fragColor = ubuf.ink * texture(source, qt_TexCoord0).a * ubuf.qt_Opacity;
        return;
    }
    vec2 g = gradient(qt_TexCoord0);
    float strength = length(g);
    vec2 direction = g / max(strength, 0.0001) * ubuf.pixelStep;
    // Suppress the sides of each edge instead of drawing thick double borders.
    float neighbour = max(length(gradient(qt_TexCoord0 + direction)), length(gradient(qt_TexCoord0 - direction)));
    float thin = smoothstep(-0.06, 0.06, strength - neighbour * 0.85);
    float alpha = smoothstep(0.10, 0.32, strength) * thin;
    fragColor = ubuf.ink * alpha * ubuf.qt_Opacity;
}
