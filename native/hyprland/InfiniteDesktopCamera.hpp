#pragma once

#include <hyprutils/math/Box.hpp>
#include <hyprutils/math/Vector2D.hpp>
#include <algorithm>
#include <cmath>

namespace Velora::InfiniteDesk {
using Hyprutils::Math::CBox;
using Hyprutils::Math::Vector2D;

// World coordinates are logical compositor coordinates. Only the view changes;
// client geometry and its buffer resolution never participate in camera updates.
struct Camera {
    Vector2D center, viewport;
    double zoom = 1.;
    static constexpr double MIN_ZOOM = .2, MAX_ZOOM = 3.;

    Vector2D project(Vector2D world) const { return (world - center) * zoom + viewport / 2.; }
    Vector2D unproject(Vector2D screen) const { return (screen - viewport / 2.) / zoom + center; }
    CBox project(const CBox& box) const { return {project(box.pos()), box.size() * zoom}; }
    CBox unproject(const CBox& box) const { return {unproject(box.pos()), box.size() / zoom}; }
    void pan(Vector2D screenDelta) { center -= screenDelta / zoom; }
    void zoomAt(double value, Vector2D anchor) {
        if (!std::isfinite(value)) return;
        const auto world = unproject(anchor);
        zoom = std::clamp(value, MIN_ZOOM, MAX_ZOOM);
        center = world - (anchor - viewport / 2.) / zoom;
    }
    bool identity(Vector2D monitorOrigin) const {
        return std::abs(zoom - 1.) < 1e-9 && (center - monitorOrigin - viewport / 2.).size() < 1e-7;
    }
};
}
