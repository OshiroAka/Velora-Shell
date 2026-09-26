#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float waveAmplitude;
    float waveFrequency;
    float edgeSoftness;
    float directionX;
    float directionY;
    float wavePhase;
    float transitionMode;
} ubuf;

layout(binding = 1) uniform sampler2D source;

const float PI = 3.14159265358979323846;

void main()
{
    vec2 uv = qt_TexCoord0;
    float p = clamp(ubuf.progress, 0.0, 1.0);
    float envelope = sin(PI * p);

    if (ubuf.transitionMode >= 0.5) {
        vec2 centered = uv - vec2(0.5);
        centered.x *= 1.6;
        float radialDistance = length(centered) / 0.944;
        float softness = 0.018 + envelope * 0.022;
        float front;
        float oldFrameMask;

        if (ubuf.transitionMode < 1.5) {
            // Grow: the new wallpaper expands from the centre.
            front = mix(-0.05, 1.05, p);
            oldFrameMask = smoothstep(front - softness, front + softness, radialDistance);
        } else {
            // Outer: the new wallpaper closes in from the outside edges.
            front = mix(1.05, -0.05, p);
            oldFrameMask = 1.0 - smoothstep(front - softness, front + softness, radialDistance);
        }

        float edgeDistance = abs(radialDistance - front);
        float edgeWarp = exp(-edgeDistance * edgeDistance / 0.0038) * envelope;
        vec2 radialDirection = length(centered) > 0.0001 ? normalize(centered) : vec2(0.0);
        vec2 sampleUv = clamp(uv + radialDirection * edgeWarp * 0.010, vec2(0.001), vec2(0.999));
        fragColor = texture(source, sampleUv) * (oldFrameMask * ubuf.qt_Opacity);
        return;
    }

    vec2 direction = vec2(ubuf.directionX, ubuf.directionY);
    if (length(direction) < 0.5)
        direction = vec2(1.0, 0.0);
    direction = normalize(direction);
    vec2 perpendicular = vec2(-direction.y, direction.x);

    float projection = dot(uv, direction);
    float projectionMin = min(0.0, direction.x) + min(0.0, direction.y);
    float projectionMax = max(0.0, direction.x) + max(0.0, direction.y);
    float travel = (projection - projectionMin) / max(0.001, projectionMax - projectionMin);
    float waveCoordinate = dot(uv, perpendicular);

    float primary = sin((waveCoordinate * ubuf.waveFrequency + p * 1.35) * 2.0 * PI + ubuf.wavePhase);
    float secondary = sin((waveCoordinate * (ubuf.waveFrequency * 2.17) - p * 2.1) * 2.0 * PI - ubuf.wavePhase * 0.63);
    float ripple = (primary * 0.78 + secondary * 0.22) * ubuf.waveAmplitude * envelope;

    float front = mix(-0.10, 1.10, p) + ripple;
    float softness = ubuf.edgeSoftness + 0.010 * envelope;
    float oldFrameMask = smoothstep(front - softness, front + softness, travel);

    float frontDistance = abs(travel - front);
    float localWarp = exp(-frontDistance * frontDistance / 0.0055) * envelope;
    vec2 sampleUv = uv;
    sampleUv += direction * (ripple * 0.34 * localWarp);
    sampleUv += perpendicular * (sin((travel * 8.0 - p * 2.5) * 2.0 * PI + ubuf.wavePhase) * 0.0045 * localWarp);
    sampleUv = clamp(sampleUv, vec2(0.001), vec2(0.999));

    vec4 oldFrame = texture(source, sampleUv);
    fragColor = oldFrame * (oldFrameMask * ubuf.qt_Opacity);
}
