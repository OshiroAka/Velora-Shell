#pragma once

#include <algorithm>
#include <cmath>
#include <optional>
#include <sstream>
#include <string>
#include <string_view>

constexpr float BAR_DEFAULT_REFRACTION = 1.F;
constexpr float BAR_MAX_REFRACTION = 10.F;

inline int opticalGlassSamplePadding(float strength, float scale, float span = 0.F) {
    // Includes the refracted rim, body lens and the Gaussian source halo.
    const float unit = std::max(scale, 0.1F);
    return static_cast<int>(std::ceil((64.F*unit + 0.064F*std::max(0.F,span))
        * std::clamp(strength,0.F,BAR_MAX_REFRACTION) + 12.F*unit));
}

// Maximum per-axis displacement of the output-wide lens in the GLSL:
// max |(uv-.5) * (1-(2*uv-1)^2)| = 1 / (3*sqrt(3)). Include
// the local rim/flow/dispersion and the bilinear footprint as well. This is
// sampling damage only; expanding the painted geometry would add seams.
inline int barRefractionSamplePadding(float strength, float span, float localPixels) {
    const float gain = std::clamp(strength, 0.F, BAR_MAX_REFRACTION);
    return static_cast<int>(std::ceil(std::max(0.F, localPixels)
        + 0.03F * std::max(0.F, gain - 1.F) * span / (3.F * std::sqrt(3.F)) + 2.F));
}

inline std::optional<float> parseBarRefraction(std::string_view text) {
    std::istringstream input{std::string{text}};
    float strength = 0.F;
    std::string trailing;
    if (!(input >> strength) || (input >> trailing) || !std::isfinite(strength)
            || strength < 0.F || strength > BAR_MAX_REFRACTION)
        return std::nullopt;
    return strength;
}
