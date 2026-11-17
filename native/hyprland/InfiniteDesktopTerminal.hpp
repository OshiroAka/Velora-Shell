#pragma once
#include "InfiniteDesktopCamera.hpp"

namespace Velora::InfiniteDesk {
// Capture the presented camera once. A drag is always measured in logical
// screen pixels, even when the eventual client is much larger at low zoom.
struct TerminalRectangle {
    Camera camera;
    Vector2D start, end;
    TerminalRectangle(const Camera& pose, Vector2D point) : camera(pose), start(point), end(point) {}
    void update(Vector2D point) {
        end = {std::clamp(point.x, 0., camera.viewport.x), std::clamp(point.y, 0., camera.viewport.y)};
    }
    CBox screen() const {
        return {std::min(start.x, end.x), std::min(start.y, end.y),
                std::abs(start.x - end.x), std::abs(start.y - end.y)};
    }
    CBox world() const { return camera.unproject(screen()); }
    bool usable() const { const auto box = screen(); return box.w >= 80. && box.h >= 48.; }
};
}
