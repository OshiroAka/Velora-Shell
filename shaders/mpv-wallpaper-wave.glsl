//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Velora wallpaper wave transition
//!COMPONENTS 4

const float PI = 3.14159265358979323846;
// These defaults are replaced in the generated cache copy for every transition.
const float veloraDurationFrames = 180.0; // VELORA_DURATION_FRAMES
const float veloraDirectionX = 1.0; // VELORA_DIRECTION_X
const float veloraDirectionY = 0.0; // VELORA_DIRECTION_Y
const float veloraWavePhase = 0.0; // VELORA_WAVE_PHASE
const float veloraTransitionMode = 0.0; // VELORA_TRANSITION_MODE
const float veloraWaveAmplitude = 0.052;

vec4 hook()
{
    vec2 uv = HOOKED_pos;
    float progress = clamp(float(frame) / max(1.0, veloraDurationFrames), 0.0, 1.0);
    float envelope = sin(PI * progress);

    if (veloraTransitionMode >= 0.5) {
        vec2 centered = uv - vec2(0.5);
        centered.x *= 1.6;
        float radialDistance = length(centered) / 0.944;
        float softness = 0.018 + envelope * 0.022;
        float front;
        float oldMask;

        if (veloraTransitionMode < 1.5) {
            front = mix(-0.05, 1.05, progress);
            oldMask = smoothstep(front - softness, front + softness, radialDistance);
        } else {
            front = mix(1.05, -0.05, progress);
            oldMask = 1.0 - smoothstep(front - softness, front + softness, radialDistance);
        }

        float edgeDistance = abs(radialDistance - front);
        float edgeWarp = exp(-edgeDistance * edgeDistance / 0.0038) * envelope;
        vec2 radialDirection = length(centered) > 0.0001 ? normalize(centered) : vec2(0.0);
        vec2 sampleUv = clamp(uv + radialDirection * edgeWarp * 0.010, vec2(0.001), vec2(0.999));
        vec4 radialColor = HOOKED_tex(sampleUv);
        radialColor.rgb *= oldMask;
        radialColor.a *= oldMask;
        return radialColor;
    }

    vec2 direction = vec2(veloraDirectionX, veloraDirectionY);
    if (length(direction) < 0.5)
        direction = vec2(1.0, 0.0);
    direction = normalize(direction);
    vec2 perpendicular = vec2(-direction.y, direction.x);

    float projection = dot(uv, direction);
    float projectionMin = min(0.0, direction.x) + min(0.0, direction.y);
    float projectionMax = max(0.0, direction.x) + max(0.0, direction.y);
    float travel = (projection - projectionMin) / max(0.001, projectionMax - projectionMin);
    float waveCoordinate = dot(uv, perpendicular);

    float primary = sin((waveCoordinate * 5.5 + progress * 1.35) * 2.0 * PI + veloraWavePhase);
    float secondary = sin((waveCoordinate * 11.935 - progress * 2.1) * 2.0 * PI - veloraWavePhase * 0.63);
    float ripple = (primary * 0.78 + secondary * 0.22) * veloraWaveAmplitude * envelope;
    float front = mix(-0.10, 1.10, progress) + ripple;
    float softness = 0.018 + 0.010 * envelope;
    float oldMask = smoothstep(front - softness, front + softness, travel);

    float frontDistance = abs(travel - front);
    float localWarp = exp(-frontDistance * frontDistance / 0.0055) * envelope;
    vec2 sampleUv = uv;
    sampleUv += direction * (ripple * 0.34 * localWarp);
    sampleUv += perpendicular * (sin((travel * 8.0 - progress * 2.5) * 2.0 * PI + veloraWavePhase) * 0.0045 * localWarp);
    sampleUv = clamp(sampleUv, vec2(0.001), vec2(0.999));

    vec4 color = HOOKED_tex(sampleUv);
    color.rgb *= oldMask;
    color.a *= oldMask;
    return color;
}
