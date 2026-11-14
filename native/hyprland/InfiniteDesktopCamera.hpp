#pragma once

#include <hyprutils/math/Box.hpp>
#include <hyprutils/math/Vector2D.hpp>
#include <algorithm>
#include <cmath>
#include <cstdint>

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
    // Workspace slides are screen translations, applied after camera zoom.
    CBox project(const CBox& box, Vector2D screenOffset) const { return project(box.copy().translate(-screenOffset)).translate(screenOffset); }
    CBox unproject(const CBox& box, Vector2D screenOffset) const { return unproject(box.copy().translate(-screenOffset)).translate(screenOffset); }
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

// Input can arrive faster than the output refreshes. Preserve every fractional
// delta, but apply their sum once when the compositor starts that output frame.
struct PanBatch {
    Vector2D pending;
    uint64_t inputs = 0, frames = 0;
    bool add(Vector2D delta) {
        if (!std::isfinite(delta.x) || !std::isfinite(delta.y) || delta == Vector2D{}) return false;
        pending += delta;
        ++inputs;
        return true;
    }
    bool apply(Camera& camera) {
        if (pending == Vector2D{}) return false;
        camera.pan(pending);
        pending = {};
        ++frames;
        return true;
    }
};

struct PanInertia {
    Vector2D velocity, sampleDelta;
    double sampleStarted = 0., lastMotion = 0., lastStep = 0.;
    bool active = false;
    static constexpr double DECAY = .16;

    void begin(double now) { *this = {}; sampleStarted = lastMotion = now; }
    void sample(Vector2D delta, double now) {
        active = false;
        if (now - lastMotion > .09) { velocity = {}; sampleDelta = {}; sampleStarted = now - 1. / 60.; }
        sampleDelta += delta;
        const auto dt = now - sampleStarted;
        // Combine axes and very fast samples before estimating screen velocity.
        if (dt >= 1. / 240.) {
            auto measured = sampleDelta / dt;
            const auto speed = measured.size();
            if (speed > 3200.) measured *= 3200. / speed;
            const auto weight = -std::expm1(-dt / .035);
            velocity += (measured - velocity) * weight;
            sampleDelta = {}; sampleStarted = now;
        }
        lastMotion = now;
    }
    bool release(double now) {
        const auto idle = std::max(0., now - lastMotion);
        velocity *= std::exp(-idle / .035);
        active = idle < .09 && velocity.size() >= 18.;
        lastStep = now;
        return active;
    }
    Vector2D step(double now) {
        if (!active) return {};
        const auto dt = std::max(0., now - lastStep);
        lastStep = now;
        if (dt > .1) { active = false; return {}; }
        const auto decay = std::exp(-dt / DECAY);
        const auto delta = velocity * (DECAY * (1. - decay));
        velocity *= decay;
        if (velocity.size() < 10.) active = false;
        return delta;
    }
};
}
