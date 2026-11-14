#pragma once

#include <hyprutils/math/Box.hpp>
#include <hyprutils/math/Region.hpp>
#include <utility>

inline Hyprutils::Math::CRegion opticalSamplingDamage(
        const Hyprutils::Math::CRegion& damage, const Hyprutils::Math::CBox& bounds, int padding) {
    auto prepared = damage.copy();
    if (padding > 0 && !prepared.empty()) prepared.expand(padding);
    prepared.intersect(bounds);
    return prepared;
}

struct SOpticalDamagePlan {
    Hyprutils::Math::CRegion output;
    Hyprutils::Math::CRegion scene;
};

inline SOpticalDamagePlan opticalDamagePlan(const Hyprutils::Math::CRegion& damage,
        const Hyprutils::Math::CBox& bounds, int padding) {
    auto output = opticalSamplingDamage(damage, bounds, padding);
    // Changed source pixels affect neighbouring output pixels. Those output
    // pixels in turn need their own source halo. Only the inner area is safe
    // to present; displaying the scratch edge exposes cleared work buffers.
    auto scene = opticalSamplingDamage(output, bounds, padding);
    return {std::move(output), std::move(scene)};
}
