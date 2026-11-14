#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float phase;
    float strength;
    vec2 itemSize;
    vec2 designOrigin;
    float designScale;
    float designRotation;
    float cornerRadius;
} ubuf;

vec2 causticsHash(vec2 cell) {
    return fract(sin(vec2(dot(cell, vec2(127.1, 311.7)),
                          dot(cell, vec2(269.5, 183.3)))) * 43758.5453);
}

float poolCaustics(vec2 designPoint, float phase) {
    vec2 point = designPoint / 112.0;
    point += vec2(sin(point.y * 1.31 + phase * 0.23),
                  cos(point.x * 1.17 - phase * 0.19)) * 0.16;
    vec2 baseCell = floor(point);
    vec2 localPoint = fract(point);
    float nearest = 16.0;
    float secondNearest = 16.0;
    for (int cellY = -1; cellY <= 1; ++cellY) {
        for (int cellX = -1; cellX <= 1; ++cellX) {
            vec2 cell = vec2(float(cellX), float(cellY));
            vec2 random = causticsHash(baseCell + cell);
            vec2 feature = 0.5 + 0.38 * sin(
                phase * vec2(0.31, -0.27) + random * 6.2831853);
            vec2 delta = cell + feature - localPoint;
            float distanceSquared = dot(delta, delta);
            if (distanceSquared < nearest) {
                secondNearest = nearest;
                nearest = distanceSquared;
            } else if (distanceSquared < secondNearest) {
                secondNearest = distanceSquared;
            }
        }
    }

    float edgeGap = sqrt(secondNearest) - sqrt(nearest);
    float ridge = 1.0 - smoothstep(0.012, 0.068, edgeGap);
    float shimmer = 0.84 + 0.16 * sin(
        designPoint.x * 0.018 - designPoint.y * 0.014 + phase * 0.41);
    return pow(clamp(ridge, 0.0, 1.0), 1.55) * shimmer;
}

float roundedBoxSdf(vec2 point, vec2 halfSize, float radius) {
    vec2 q = abs(point) - halfSize + vec2(radius);
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - radius;
}

void main() {
    vec2 localPoint = qt_TexCoord0 * ubuf.itemSize;
    float angle = radians(ubuf.designRotation);
    mat2 rotation = mat2(cos(angle), sin(angle),
                         -sin(angle), cos(angle));
    vec2 designPoint = ubuf.designOrigin
        + rotation * (localPoint * ubuf.designScale);
    float light = poolCaustics(designPoint, ubuf.phase);

    vec2 halfSize = ubuf.itemSize * 0.5;
    float radius = min(ubuf.cornerRadius, min(halfSize.x, halfSize.y));
    float sdf = roundedBoxSdf(localPoint - halfSize, halfSize, radius);
    float coverage = 1.0 - smoothstep(-1.25, 1.25, sdf);

    float strength = clamp(ubuf.strength, 0.0, 1.0);
    float alpha = coverage * ubuf.qt_Opacity * strength
        * (0.014 + light * 0.13);
    vec3 waterLight = mix(vec3(0.06, 0.16, 0.22),
                          vec3(0.90, 0.98, 1.0), light);
    fragColor = vec4(waterLight * alpha, alpha);
}
