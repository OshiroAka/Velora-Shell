#pragma once
#include <hyprutils/math/Vector2D.hpp>
#include <algorithm>
#include <cmath>

namespace Velora {
struct LightParallax {
    Hyprutils::Math::Vector2D current, target;
    bool aim(Hyprutils::Math::Vector2D normalized) {
        if (!std::isfinite(normalized.x) || !std::isfinite(normalized.y)) return false;
        const Hyprutils::Math::Vector2D next{std::clamp(normalized.x, -1., 1.) * .12,
                                            std::clamp(normalized.y, -1., 1.) * .12};
        if ((next - target).size() < 1e-6) return false;
        target = next;
        return true;
    }
    bool moving() const { return (target - current).size() > 1e-6; }
    bool advance(double seconds) {
        if (!moving() || !std::isfinite(seconds) || seconds <= 0.) return false;
        current += (target - current) * -std::expm1(-std::min(seconds, .05) / .055);
        if ((target - current).size() < .00015) current = target;
        return true;
    }
};
}
