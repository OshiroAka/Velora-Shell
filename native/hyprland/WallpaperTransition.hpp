#pragma once
#include <algorithm>
#include <chrono>
#include <string>

// Timing belongs to the compositor, not to the application request or video
// frame count. The renderer owns and releases its temporary GPU textures.
struct SWallpaperTransitionTiming {
    using Clock = std::chrono::steady_clock;
    std::string token;
    float duration = .42F;
    bool revealing = false;
    Clock::time_point prepared = Clock::now(), started = prepared;

    bool matches(const std::string& value) const { return !token.empty() && token == value; }
    float progress(Clock::time_point now = Clock::now()) const {
        if (!revealing) return 0.F;
        const float t = std::clamp(std::chrono::duration<float>(now - started).count() / duration, 0.F, 1.F);
        return t * t * (3.F - 2.F * t);
    }
    bool expired(Clock::time_point now = Clock::now()) const {
        return token.empty() || (revealing ? progress(now) >= 1.F
            : now - prepared >= std::chrono::seconds(5));
    }
};

constexpr auto WALLPAPER_TRANSITION_FRAGMENT = R"GLSL(#version 300 es
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
uniform vec2 fullSize;
uniform vec2 direction;
uniform float progress;
uniform float phase;
uniform float mode;
out vec4 fragColor;
void main() {
    vec2 uv = v_texcoord;
    float p = clamp(progress, 0.0, 1.0);
    if (p <= 0.0) { fragColor = texture(tex, uv); return; }
    if (p >= 1.0) { fragColor = vec4(0.0); return; }
    if (mode > 2.5 && mode < 3.5) { fragColor = texture(tex, uv) * (1.0 - p); return; }
    vec2 metric = max(fullSize, vec2(1.0)) / max(max(fullSize.x, fullSize.y), 1.0);
    float envelope = 4.0 * p * (1.0 - p);
    float distanceToFront;
    float softness;
    float mask;
    vec2 warpDirection;
    float ripple = 0.0;
    if (mode >= 0.5 && mode < 2.5) {
        vec2 centered = (uv - 0.5) * metric;
        float travel = length(centered) / max(length(metric * .5), .001);
        float front = mix(-.04, 1.04, p);
        if (mode > 1.5) front = 1.0 - front;
        distanceToFront = travel - front;
        softness = .015 + .01 * envelope;
        mask = smoothstep(-softness, softness, distanceToFront);
        if (mode > 1.5) mask = 1.0 - mask;
        warpDirection = centered / max(length(centered), .001) / metric;
    } else {
        vec2 d = dot(direction, direction) < .01 ? vec2(1.0, 0.0) : normalize(direction);
        float span = max(dot(abs(d), metric), .001);
        float travel = (dot(uv * metric, d) - dot(min(d, vec2(0.0)), metric)) / span;
        if (mode < .5) {
            float angle = dot(uv * metric, vec2(-d.y, d.x)) * 15.0796447 + phase - p * 2.2;
            ripple = (sin(angle) * .065 + sin(angle * 2.03 + 1.1) * .012) * envelope;
        }
        distanceToFront = travel - (mix(-.10, 1.10, p) + ripple);
        softness = max(.007, 1.5 / max(max(fullSize.x, fullSize.y), 1.0) / span);
        mask = smoothstep(-softness, softness, distanceToFront);
        warpDirection = d / metric;
    }
    if (mask <= 0.0) { fragColor = vec4(0.0); return; }
    float band = 1.0 - smoothstep(0.0, .065, abs(distanceToFront));
    vec2 sampleUv = uv + warpDirection * (.009 + ripple * .16) * band * envelope;
    if (mode > 3.5) sampleUv = uv;
    vec2 halfTexel = .5 / max(fullSize, vec2(1.0));
    fragColor = texture(tex, clamp(sampleUv, halfTexel, 1.0 - halfTexel)) * mask;
}
)GLSL";
