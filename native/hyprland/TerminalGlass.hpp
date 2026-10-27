#pragma once

#include <string_view>
#include <string>
#include <cmath>
#include <optional>
#include <sstream>

constexpr float TERMINAL_REFRACTION_PIXELS = 8.F;
constexpr float TERMINAL_RIM_WIDTH = 48.F;
constexpr float TERMINAL_MAX_STRENGTH = 3.F;
struct STerminalGlassControl { bool enabled = true; float strength = 1.F; };
inline std::optional<STerminalGlassControl> parseTerminalGlassControl(std::string_view text) {
    std::istringstream input{std::string{text}};
    int enabled = -1;
    float strength = 0.F;
    std::string trailing;
    if (!(input >> enabled >> strength) || (input >> trailing)
            || (enabled != 0 && enabled != 1) || !std::isfinite(strength)
            || strength < 0.F || strength > TERMINAL_MAX_STRENGTH)
        return std::nullopt;
    return STerminalGlassControl{enabled == 1, strength};
}

inline bool kittyClass(std::string_view name) {
    constexpr std::string_view expected = "kitty";
    if (name.size() != expected.size()) return false;
    for (size_t i = 0; i < name.size(); ++i) {
        const char lower = name[i] >= 'A' && name[i] <= 'Z' ? name[i] + ('a' - 'A') : name[i];
        if (lower != expected[i]) return false;
    }
    return true;
}

// A custom --class does not change the Wayland client's executable.
inline bool kittyExecutable(std::string_view path) {
    constexpr std::string_view deleted = " (deleted)";
    if (path.ends_with(deleted)) path.remove_suffix(deleted.size());
    const auto slash = path.find_last_of('/');
    return path.substr(slash == path.npos ? 0 : slash + 1) == "kitty";
}

constexpr auto TERMINAL_GLASS_OPTICS = R"GLSL(
// Shared by Kitty and matching bars. Pure geometry/material calculation;
// client text, surface masks and each consumer's composition stay separate.
vec4 terminalGlassOptics(vec2 local, vec2 halfSize, float depth,
                        float strength, float refractionPixels, float contrast) {
    halfSize = max(halfSize, vec2(1.0));
    vec2 q = clamp(local / halfSize, vec2(-1.0), vec2(1.0));
    strength = clamp(strength, 0.0, 3.0);
    float opticalStrength = 1.4 * strength / (1.0 + 0.4 * strength);
    float shortSide = min(halfSize.x, halfSize.y);
    float rimWidth = max(1.0, min(contrast, shortSide * 0.65));
    vec2 axisDepth = max(halfSize - abs(local), vec2(0.0));
    vec2 edge = 1.0 - smoothstep(vec2(0.0), vec2(rimWidth), axisDepth);
    // Axis slopes avoid nearest-edge normal seams and terminate before the
    // medial axis, even in small terminals and narrow bars.
    vec2 edgeSlope = sign(local) * edge * edge;
    float rimDisplacement = min(refractionPixels * opticalStrength, rimWidth * 0.28);
    vec2 aspect = vec2(shortSide) / halfSize;
    float bodyShape = (1.0 - q.x * q.x) * (1.0 - q.y * q.y);
    vec2 bodyRay = local * aspect * aspect * (0.14 * opticalStrength * bodyShape);
    float rim = 1.0 - smoothstep(0.0, rimWidth, depth);
    float lens = rim * rim;
    float clarity = clamp(opticalStrength * (0.42 + 0.58 * lens), 0.0, 1.0);
    vec2 normal = edgeSlope / max(length(edgeSlope), 0.0001);
    float light = 0.5 + 0.5 * dot(normal, normalize(vec2(-0.65, 0.76)));
    float outline = 1.0 - smoothstep(0.35, 1.6, depth);
    float reflection = opticalStrength * (0.012 * lens * light
        + 0.055 * outline * light - 0.008 * lens * (1.0 - light));
    return vec4(bodyRay + edgeSlope * rimDisplacement, clarity, reflection);
}
)GLSL";

inline std::string withTerminalGlassOptics(std::string_view source) {
    std::string result{source};
    constexpr std::string_view marker = "// TERMINAL_GLASS_OPTICS";
    if (const auto position = result.find(marker); position != std::string::npos)
        result.replace(position, marker.size(), TERMINAL_GLASS_OPTICS);
    return result;
}

constexpr auto TERMINAL_GLASS_FRAGMENT = R"GLSL(#version 300 es
precision highp float;
in vec2 v_texcoord;
uniform highp sampler2D tex;
uniform highp sampler2D blurredBG;
uniform vec2 fullSize;
uniform vec2 bottomRight;
uniform float radius;
uniform float roundingPower;
uniform float distort;
uniform float contrast;
uniform float vibrancy;
uniform float alpha;
out vec4 fragColor;

// TERMINAL_GLASS_OPTICS

float distanceToRim(vec2 p) {
    vec2 halfSize = bottomRight * 0.5;
    float r = clamp(radius, 0.0, min(halfSize.x, halfSize.y));
    vec2 q = abs(p - halfSize) - (halfSize - r);
    vec2 outside = max(q, vec2(0.0));
    float power = max(roundingPower, 2.0);
    return pow(pow(outside.x, power) + pow(outside.y, power), 1.0 / power)
        + min(max(q.x, q.y), 0.0) - r;
}

void main() {
    float depth = max(0.0, -distanceToRim(v_texcoord * bottomRight));
    vec4 optics = terminalGlassOptics((v_texcoord - 0.5) * bottomRight,
        bottomRight * 0.5, depth, alpha, distort, contrast);
    vec2 uv = clamp((gl_FragCoord.xy - optics.xy) / fullSize,
        0.5 / fullSize, 1.0 - 0.5 / fullSize);
    vec3 material = mix(texture(blurredBG, uv).rgb, texture(tex, uv).rgb, vibrancy * optics.z);
    material += vec3(optics.w);
    // This is an intermediate backdrop. Hyprland's original surface shader
    // still owns client alpha, text, graphics, clipping, rounding and fades.
    fragColor = vec4(max(material, vec3(0.0)), 1.0);
}
)GLSL";
