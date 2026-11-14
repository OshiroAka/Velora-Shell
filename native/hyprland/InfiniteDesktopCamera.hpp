#pragma once

#include <hyprutils/math/Box.hpp>
#include <hyprutils/math/Vector2D.hpp>
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <optional>

namespace Velora::InfiniteDesk {
using Hyprutils::Math::CBox;
using Hyprutils::Math::Vector2D;

// World coordinates are logical compositor coordinates. Only the view changes;
// client geometry and its buffer resolution never participate in camera updates.
struct Camera {
    Vector2D center, viewport;
    double zoom = 1.;
    static constexpr double MIN_ZOOM = .2, MAX_ZOOM = 3.;
    static constexpr double ZOOM_STEP = .85;

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

inline Camera interpolateCamera(const Camera& from, const Camera& target, double progress, std::optional<Vector2D> anchor = {}) {
    Camera result = from;
    result.zoom += (target.zoom - from.zoom) * progress;
    result.center = anchor ? from.unproject(*anchor) - (*anchor - result.viewport / 2.) / result.zoom
                           : from.center + (target.center - from.center) * progress;
    return result;
}

enum class CameraMotion { STANDARD, FOCUS, NAVIGATION };
inline constexpr double NAVIGATION_DURATION = .6;
inline double navigationProgress(double progress) {
    if (progress <= 0.) return 0.;
    if (progress >= 1.) return 1.;
    // The former window movement used Hyprland's "easy" spring (mass 1,
    // stiffness 238.1191, damping 24.21279333). Keep its subtle 1.9% overshoot.
    const double decay = 24.21279333 / 2.;
    const double frequency = std::sqrt(238.1191 - decay * decay);
    const double time = progress * NAVIGATION_DURATION;
    return 1. - std::exp(-decay * time) * (std::cos(frequency * time) + decay / frequency * std::sin(frequency * time));
}
inline Camera animateCamera(const Camera& from, const Camera& target, double progress, CameraMotion motion, std::optional<Vector2D> anchor = {}) {
    const auto t = std::clamp(progress, 0., 1.);
    const auto eased = motion == CameraMotion::FOCUS ? t*t*t*(t*(t*6. - 15.) + 10.) : 1. - std::pow(1. - t, 3.);
    auto result = interpolateCamera(from, target, eased, anchor);
    if (motion == CameraMotion::NAVIGATION)
        result.center = from.center + (target.center - from.center) * navigationProgress(t);
    return result;
}

struct FocusBookmark {
    std::optional<Camera> returnTo;
    std::optional<Camera> toggle(const Camera& current, const CBox& window, const CBox& usable) {
        if (returnTo) {
            auto restored = *returnTo;
            restored.viewport = current.viewport;
            returnTo.reset();
            return restored;
        }
        if (window.empty() || usable.empty()) return {};
        auto focused = current;
        // Native scale keeps text sharp; oversized windows fit the usable area.
        focused.zoom = std::clamp(std::min({1., usable.w / window.w, usable.h / window.h}), Camera::MIN_ZOOM, Camera::MAX_ZOOM);
        focused.center = window.middle() - (usable.middle() - current.viewport / 2.) / focused.zoom;
        returnTo = current;
        return focused;
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
