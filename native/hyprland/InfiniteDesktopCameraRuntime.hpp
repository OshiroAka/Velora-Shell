#pragma once
#define VELORA_INFINITE_CAMERA_RUNTIME 1

#include "InfiniteDesktopCamera.hpp"
#include <hyprland/src/desktop/state/FocusState.hpp>
#include <hyprland/src/desktop/state/ViewState.hpp>
#include <hyprland/src/desktop/state/ViewHitTester.hpp>
#include <hyprland/src/desktop/state/WindowState.hpp>
#include <hyprland/src/desktop/view/window/WindowEffectsController.hpp>
#include <hyprland/src/desktop/view/window/WindowPresentation.hpp>
#include <hyprland/src/desktop/view/Popup.hpp>
#include <hyprland/src/layout/target/Target.hpp>
#include <hyprland/src/layout/supplementary/DragController.hpp>
#include <hyprland/src/managers/SessionLockManager.hpp>
#include <hyprland/src/managers/fullscreen/FullscreenController.hpp>
#include <hyprland/src/pointer/PointerManager.hpp>
#include <hyprland/src/render/transformer/TransformerList.hpp>
#include <hyprland/src/workspace/HLWorkspace.hpp>
#include <unordered_map>

namespace Velora::InfiniteDesk {
struct View {
    Camera camera, from, target;
    PHLMONITORREF monitor;
    PHLWORKSPACEREF workspace;
    std::chrono::steady_clock::time_point started;
    bool animating = false;
};
inline std::unordered_map<const Workspace::CHLWorkspace*, View> views;
inline bool enabled = false, unloading = false, drawingWallpaper = false;
inline HANDLE handle = nullptr;
inline SP<CEventLoopTimer> animationTimer;
inline CHyprSignalListener openListener;
inline std::vector<CFunctionHook*> hooks;
inline std::unordered_map<const Desktop::View::CWindow*, PHLWINDOWREF> attached;
inline SP<VeloraCompat::StatusCommand> statusCommand;
inline bool readingDragCoords = false;
inline PHLWORKSPACEREF dragWorkspace;

inline bool available(PHLMONITOR monitor) {
    return enabled && !unloading && monitor && monitor->m_activeWorkspace && !monitor->m_activeSpecialWorkspace
        && !g_pSessionLockManager->isSessionLocked()
        && !Fullscreen::controller()->hasFullscreen(monitor->m_activeWorkspace);
}
inline View* viewFor(PHLMONITOR monitor) {
    if (!available(monitor)) return nullptr;
    const auto found = views.find(monitor->m_activeWorkspace.get());
    if (found == views.end() || found->second.workspace != monitor->m_activeWorkspace) return nullptr;
    auto& view = found->second;
    if (view.monitor != monitor || view.camera.viewport != monitor->m_size) {
        // A moved workspace or changed output retains its world centre and zoom.
        view.monitor = monitor;
        view.camera.viewport = view.from.viewport = view.target.viewport = monitor->m_size;
    }
    return &view;
}
inline View* viewFor(const PHLWINDOW& window) {
    if (!window || !window->mapped() || !window->isFloating() || window->isHidden()
        || (window->m_state & Desktop::View::WINDOW_STATE_PINNED) || !window->m_workspace) return nullptr;
    auto monitor = window->m_workspace->m_monitor.lock();
    auto view = viewFor(monitor);
    return view && view->workspace == window->m_workspace ? view : nullptr;
}
inline bool transformed(const View* view) {
    return view && view->monitor && !view->camera.identity(view->monitor->m_position);
}
inline void damage(View& view) {
    if (auto monitor = view.monitor.lock()) {
        monitor->m_blurFBDirty = true;
        g_pHyprRenderer->damageMonitor(monitor);
    }
}
inline Render::SRenderModifData modifiers(const View& view) {
    auto monitor = view.monitor.lock();
    Render::SRenderModifData result;
    result.modifs.emplace_back(Render::SRenderModifData::RMOD_TYPE_SCALE, float(view.camera.zoom));
    result.modifs.emplace_back(Render::SRenderModifData::RMOD_TYPE_TRANSLATE,
        (view.camera.viewport / 2. + (monitor->m_position - view.camera.center) * view.camera.zoom) * monitor->m_scale);
    return result;
}

class WindowCamera final : public Render::IWindowTransformer {
    PHLWINDOWREF window;
  public:
    explicit WindowCamera(PHLWINDOWREF value) : window(value) {}
    int priority() const override { return 100000; }
    bool active() const override { return transformed(viewFor(window.lock())); }
    bool allocatesOutputBuffer() const override { return false; }
    bool blocksDirectScanout() const override { return transformed(viewFor(window.lock())); }
    CBox transformedExtents(const CBox& input) const override {
        auto view = viewFor(window.lock());
        return transformed(view) ? view->camera.project(input.copy().translate(view->monitor->m_position)) : input;
    }
    CBox sourceBoxForOutput(const CBox& output, const CBox& input) const override {
        auto view = viewFor(window.lock());
        return transformed(view) ? view->camera.unproject(output).translate(-view->monitor->m_position).intersection(input) : output.intersection(input);
    }
    CBox transformBoxForDamage(const CBox& input) const override {
        auto view = viewFor(window.lock());
        return transformed(view) ? view->camera.project(input).translate(view->monitor->m_position).expand(2) : input;
    }
    Render::SWindowTransformBuffer transform(Render::CRenderContext&, const Render::SWindowTransformBuffer& input,
                                              const Render::SWindowTransformContext& context) override {
        auto view = viewFor(window.lock());
        if (!transformed(view) || !context.monitor || context.monitor != view->monitor) return input;
        auto result = input;
        const double scale = context.monitor->m_scale;
        // Reuse the live client framebuffer. The destination box changes, not
        // its pixels, dimensions, configure serial, or the application's layout.
        result.box = view->camera.project(input.box.copy().scale(1. / scale).translate(context.monitor->m_position)).scale(scale);
        return result;
    }
};
inline void attach(const PHLWINDOW& window) {
    if (!viewFor(window) || !window->effects().transformers()) return;
    auto& list = *window->effects().transformers();
    if (!list.get<WindowCamera>()) {
        list.emplace<WindowCamera>(window);
        attached.insert_or_assign(window.get(), window);
    }
}

using VisibleFn = bool (*)(Render::IHyprRenderer*, PHLWINDOW, PHLMONITOR);
inline CFunctionHook* visibleHook = nullptr;
inline bool visible(Render::IHyprRenderer* renderer, PHLWINDOW window, PHLMONITOR monitor) {
    auto view = viewFor(window);
    if (transformed(view)) { attach(window); return view->monitor == monitor; }
    return reinterpret_cast<VisibleFn>(visibleHook->m_original)(renderer, window, monitor);
}

using HitFn = PHLWINDOW (*)(const Desktop::CViewHitTester*, const Vector2D&, uint16_t, PHLWINDOW);
using SurfaceFn = SP<CWLSurfaceResource> (*)(const Desktop::CViewHitTester*, const Vector2D&, PHLWINDOW, Vector2D&);
using LocalFn = Vector2D (*)(const Desktop::CViewHitTester*, const Vector2D&, PHLWINDOW, SP<CWLSurfaceResource>);
inline CFunctionHook *hitHook = nullptr, *surfaceHook = nullptr, *localHook = nullptr;
inline PHLWINDOW hit(const Desktop::CViewHitTester* tester, const Vector2D& point, uint16_t flags, PHLWINDOW ignore) {
    const auto original = reinterpret_cast<HitFn>(hitHook->m_original);
    if (readingDragCoords && dragWorkspace)
        return tester->windowAtWorkspace(point, dragWorkspace.lock(), flags, ignore);
    auto monitor = State::monitorState()->query().vec(point).run();
    auto view = viewFor(monitor);
    if (!transformed(view)) return original(tester, point, flags, ignore);
    auto normal = original(tester, point, flags, ignore);
    if (normal && ((normal->m_state & Desktop::View::WINDOW_STATE_PINNED) || normal->priorityFocus())) return normal;
    auto projected = tester->windowAtWorkspace(view->camera.unproject(point - monitor->m_position), monitor->m_activeWorkspace,
                                             flags | Desktop::View::FLOATING_ONLY, ignore);
    return projected && viewFor(projected) ? projected : normal && !viewFor(normal) ? normal : nullptr;
}
inline SP<CWLSurfaceResource> surface(const Desktop::CViewHitTester* tester, const Vector2D& point, PHLWINDOW window, Vector2D& local) {
    auto view = viewFor(window);
    const auto world = !readingDragCoords && transformed(view) ? view->camera.unproject(point - view->monitor->m_position) : point;
    return reinterpret_cast<SurfaceFn>(surfaceHook->m_original)(tester, world, window, local);
}
inline Vector2D local(const Desktop::CViewHitTester* tester, const Vector2D& point, PHLWINDOW window, SP<CWLSurfaceResource> resource) {
    auto view = viewFor(window);
    const auto world = !readingDragCoords && transformed(view) ? view->camera.unproject(point - view->monitor->m_position) : point;
    return reinterpret_cast<LocalFn>(localHook->m_original)(tester, world, window, resource);
}

// Xwayland's legacy input path computes local positions directly rather than
// through windowSurfaceAt. Correct its coordinates at the seat boundary too.
inline Vector2D x11Local(SP<CWLSurfaceResource> resource, Vector2D fallback) {
    if (!enabled || !resource) return fallback;
    for (const auto& window : Desktop::windowState()->windows()) {
        if (!window->backend().isX11() || window->wlSurface()->resource() != resource) continue;
        auto view = viewFor(window);
        if (!transformed(view)) break;
        return window->backend().surfaceLocalToBuffer(view->camera.unproject(Pointer::mgr()->untransformedPosition() - view->monitor->m_position)
            - window->position(Desktop::View::IGeometric::GEOMETRIC_CURRENT));
    }
    return fallback;
}
using SeatFocusFn = void (*)(CSeatManager*, SP<CWLSurfaceResource>, const Vector2D&);
using SeatMotionFn = void (*)(CSeatManager*, uint32_t, const Vector2D&);
inline CFunctionHook *seatFocusHook = nullptr, *seatMotionHook = nullptr;
inline void seatFocus(CSeatManager* seat, SP<CWLSurfaceResource> resource, const Vector2D& point) {
    reinterpret_cast<SeatFocusFn>(seatFocusHook->m_original)(seat, resource, x11Local(resource, point));
}
inline void seatMotion(CSeatManager* seat, uint32_t time, const Vector2D& point) {
    reinterpret_cast<SeatMotionFn>(seatMotionHook->m_original)(seat, time, x11Local(seat->m_state.pointerFocus.lock(), point));
}

// Surface commits outside the physical output must still schedule the output
// on which the camera displays them. Native damageWindow handles transformers.
using DamageSurfaceFn = void (*)(Render::IHyprRenderer*, SP<CWLSurfaceResource>, double, double, double);
inline CFunctionHook* damageHook = nullptr;
inline void damageSurface(Render::IHyprRenderer* renderer, SP<CWLSurfaceResource> resource, double x, double y, double scale) {
    reinterpret_cast<DamageSurfaceFn>(damageHook->m_original)(renderer, resource, x, y, scale);
    if (!enabled) return;
    auto wl = Desktop::View::CWLSurface::fromResource(resource);
    if (!wl) return;
    auto client = dynamicPointerCast<Desktop::View::CWindow>(wl->view());
    if (!client) for (const auto& candidate : Desktop::windowState()->windows()) {
        if (!viewFor(candidate)) continue;
        bool belongs = false;
        const auto find = [&](SP<CWLSurfaceResource> item, const Vector2D&, void*) { belongs = belongs || item == resource; };
        candidate->wlSurface()->resource()->breadthfirst(find, nullptr);
        if (!belongs && candidate->popupHead()) candidate->popupHead()->breadthfirst([&](SP<Desktop::View::CPopup> popup, void*) {
            if (popup->resource()) popup->resource()->breadthfirst(find, nullptr);
        }, nullptr);
        if (belongs) { client = candidate; break; }
    }
    auto view = viewFor(client);
    if (!transformed(view)) return;
    auto box = wl->getSurfaceBoxGlobal();
    if (box) {
        auto projected = view->camera.project(*box).expand(2).intersection(CBox{{}, view->camera.viewport});
        if (!projected.empty()) view->monitor->addDamage(projected.scale(view->monitor->m_scale).round());
    }
}


struct Drag {
    PHLWINDOWREF window;
    Camera camera;
    Vector2D origin;
    Layout::Supplementary::CDragStateController* controller = nullptr;
};
inline std::optional<Drag> drag;
using CoordsFn = Vector2D (*)(CInputManager*);
using DragBeginFn = void (*)(Layout::Supplementary::CDragStateController*, SP<Layout::ITarget>, eMouseBindMode,
                             std::optional<Layout::eRectCorner>, bool);
using DragMoveFn = void (*)(Layout::Supplementary::CDragStateController*, const Vector2D&);
using DragEndFn = bool (*)(Layout::Supplementary::CDragStateController*);
inline CFunctionHook *coordsHook = nullptr, *dragBeginHook = nullptr, *dragMoveHook = nullptr, *dragEndHook = nullptr;
inline Vector2D mouseCoords(CInputManager* input) {
    const auto point = reinterpret_cast<CoordsFn>(coordsHook->m_original)(input);
    return readingDragCoords && drag ? drag->camera.unproject(point - drag->origin) : point;
}
inline void beginDrag(Layout::Supplementary::CDragStateController* controller, SP<Layout::ITarget> target,
                       eMouseBindMode mode, std::optional<Layout::eRectCorner> edge, bool exclusive) {
    const auto window = target ? target->window() : PHLWINDOW{};
    auto view = viewFor(window);
    if (transformed(view)) drag = Drag{window, view->camera, view->monitor->m_position, controller};
    else drag.reset();
    dragWorkspace = drag ? window->m_workspace : PHLWORKSPACE{};
    const bool previous = readingDragCoords;
    readingDragCoords = bool(drag);
    Hyprutils::Utils::CScopeGuard restore{[previous] { readingDragCoords = previous; }};
    reinterpret_cast<DragBeginFn>(dragBeginHook->m_original)(controller, target, mode, edge, exclusive);
}
inline bool endDrag(Layout::Supplementary::CDragStateController* controller);
inline void moveDrag(Layout::Supplementary::CDragStateController* controller, const Vector2D& point) {
    if (drag && !transformed(viewFor(drag->window.lock()))) {
        endDrag(controller);
        return;
    }
    const bool previous = readingDragCoords;
    readingDragCoords = drag && transformed(viewFor(drag->window.lock()));
    Hyprutils::Utils::CScopeGuard restore{[previous] { readingDragCoords = previous; }};
    const auto mapped = readingDragCoords ? drag->camera.unproject(point - drag->origin) : point;
    reinterpret_cast<DragMoveFn>(dragMoveHook->m_original)(controller, mapped);
}
inline bool endDrag(Layout::Supplementary::CDragStateController* controller) {
    const bool previous = readingDragCoords;
    readingDragCoords = bool(drag);
    Hyprutils::Utils::CScopeGuard restore{[previous] { readingDragCoords = previous; drag.reset(); dragWorkspace.reset(); }};
    return reinterpret_cast<DragEndFn>(dragEndHook->m_original)(controller);
}

inline void animate() {
    bool again = false;
    const auto now = std::chrono::steady_clock::now();
    for (auto& [_, view] : views) {
        if (!view.animating) continue;
        const auto t = std::clamp(std::chrono::duration<double>(now - view.started).count() / .18, 0., 1.);
        const auto eased = 1. - std::pow(1. - t, 3.);
        view.camera.center = view.from.center + (view.target.center - view.from.center) * eased;
        view.camera.zoom = view.from.zoom + (view.target.zoom - view.from.zoom) * eased;
        view.animating = t < 1.;
        again = again || view.animating;
        damage(view);
    }
    if (again && animationTimer) animationTimer->updateTimeout(std::chrono::milliseconds(8));
}
inline void update(View& view, const Camera& target, bool smooth) {
    view.from = view.camera;
    view.target = target;
    view.started = std::chrono::steady_clock::now();
    view.animating = smooth;
    if (smooth) animate();
    else { view.camera = target; damage(view); }
}
inline SDispatchResult dispatch(std::string arguments) {
    std::istringstream input(arguments);
    std::string action, extra;
    input >> action;
    auto monitor = Desktop::focusState()->monitor();
    if (action.starts_with('@')) {
        monitor.reset();
        for (const auto& output : State::monitorState()->monitors())
            if (output->m_name == action.substr(1)) { monitor = output; break; }
        input >> action;
    }
    if (drag) return {.success = false, .error = "Finish moving or resizing the window before changing the camera"};
    if (action == "disable") {
        if (input >> extra) return {.success = false, .error = "Unexpected camera argument"};
        enabled = false; drag.reset();
        for (auto& [_, view] : views) { view.animating = false; damage(view); }
        views.clear(); return {};
    }
    if (!monitor || !monitor->m_activeWorkspace) return {.success = false, .error = "No active camera output"};
    auto workspace = monitor->m_activeWorkspace;
    if (action != "enable" && action != "zoom" && action != "pan" && action != "center" && action != "reset")
        return {.success = false, .error = "Unknown camera action"};
    double x = 0, y = 0;
    std::string direction;
    if (action == "zoom") {
        input >> direction;
        if (direction != "in" && direction != "out") return {.success = false, .error = "Expected zoom in or out"};
    } else if (action == "pan" || action == "center") {
        if (!(input >> x >> y) || !std::isfinite(x) || !std::isfinite(y) || std::abs(x) > 1e7 || std::abs(y) > 1e7)
            return {.success = false, .error = "Invalid camera coordinates"};
    }
    if (input >> extra) return {.success = false, .error = "Unexpected camera argument"};
    enabled = true;
    if (!available(monitor)) return {.success = false, .error = "Camera suspended on this workspace"};
    auto [found, inserted] = views.try_emplace(workspace.get());
    auto& view = found->second;
    if (inserted || view.workspace != workspace) {
        view = {}; view.monitor = monitor; view.workspace = workspace;
        view.camera = Camera{monitor->m_position + monitor->m_size / 2., monitor->m_size};
        view.from = view.target = view.camera;
    }
    viewFor(monitor);
    for (auto& window : Desktop::windowState()->windows()) attach(window);
    auto target = view.target;
    if (action == "zoom") target.zoomAt(target.zoom * (direction == "out" ? .85 : 1. / .85), target.viewport / 2.);
    else if (action == "pan") target.pan({x, y});
    else if (action == "center") target.center = {x, y};
    else if (action == "reset") target = Camera{monitor->m_position + monitor->m_size / 2., monitor->m_size};
    update(view, target, action == "zoom" || action == "center" || action == "reset");
    return {};
}
inline bool activeMonitor(PHLMONITOR monitor) { return transformed(viewFor(monitor)); }

using DrawSurfaceFn = void (*)(Render::IElementRenderer*, Render::CRenderContext&, WP<CSurfacePassElement>, const CRegion&);
inline CFunctionHook* wallpaperHook = nullptr;
inline void wallpaper(Render::IElementRenderer* renderer, Render::CRenderContext& ctx,
                      WP<CSurfacePassElement> element, const CRegion& damageRegion) {
    const auto original = reinterpret_cast<DrawSurfaceFn>(wallpaperHook->m_original);
    // Popups are excluded from Hyprland's main-window transformer. Render
    // their existing surface passes under the parent's camera with source
    // clipping disabled; no large canvas or snapshot is needed.
    auto parentView = element && element->m_data.popup ? viewFor(element->m_data.pWindow) : nullptr;
    if (transformed(parentView) && ctx.m_mode == Render::RENDER_MODE_NORMAL
        && !ctx.m_renderingSnapshot && !ctx.m_data.renderingTransformedSource) {
        auto state = ctx.saveDrawState();
        ctx.m_data.renderModif = modifiers(*parentView);
        ctx.m_data.renderingTransformedSource = true;
        original(renderer, ctx, element, damageRegion);
        return;
    }
    const auto layer = element ? element->m_data.pLS : PHLLS{};
    const bool background = layer && layer->m_layer == 0 && (layer->m_namespace == "mpvpaper"
        || layer->m_namespace == "awww-daemon" || layer->m_namespace == "swww-daemon");
    auto view = background ? viewFor(layer->m_monitor.lock()) : nullptr;
    if (!transformed(view) || ctx.m_mode != Render::RENDER_MODE_NORMAL || ctx.m_renderingSnapshot || drawingWallpaper) {
        original(renderer, ctx, element, damageRegion); return;
    }
    const auto source = element->getTexBox();
    if (source.empty()) return;
    auto state = ctx.saveDrawState();
    ctx.m_data.renderModif = modifiers(*view);
    ctx.m_data.renderingTransformedSource = true;
    drawingWallpaper = true;
    Hyprutils::Utils::CScopeGuard restore{[] { drawingWallpaper = false; }};
    // Repeat the existing wallpaper buffer in world space. This works with live
    // wallpapers too and avoids stretching it or allocating a giant desktop FB.
    auto world = view->camera.unproject(CBox{{}, view->camera.viewport}).translate(-layer->m_monitor->m_position);
    const int left = std::floor((world.x - source.x) / source.w), right = std::ceil((world.x + world.w - source.x) / source.w);
    const int top = std::floor((world.y - source.y) / source.h), bottom = std::ceil((world.y + world.h - source.y) / source.h);
    for (int y = top; y < bottom; ++y) for (int x = left; x < right; ++x) {
        auto data = element->m_data;
        data.pos += Vector2D{x * source.w, y * source.h};
        const auto tile = makeShared<CSurfacePassElement>(data);
        original(renderer, ctx, tile, damageRegion);
    }
}

inline std::string status(VeloraCompat::OutputFormat, std::string) {
    std::string result = std::format(R"({{"enabled":{},"views":[)", enabled ? "true" : "false");
    bool first = true;
    for (const auto& [_, view] : views) {
        if (!view.monitor || !view.workspace) continue;
        if (!first) result += ',';
        first = false;
        result += std::format(R"({{"monitor":"{}","zoom":{},"center":[{},{}],"viewport":[{},{}],"animating":{},"active":{}}})",
            view.monitor->m_name, view.camera.zoom, view.camera.center.x, view.camera.center.y,
            view.camera.viewport.x, view.camera.viewport.y, view.animating ? "true" : "false",
            view.monitor->m_activeWorkspace == view.workspace ? "true" : "false");
    }
    return result + "]}";
}

inline CFunctionHook* installHook(const std::string& name, const std::string& signature, const void* function) {
    for (const auto& match : HyprlandAPI::findFunctionsByName(handle, name)) {
        if (!match.demangled.contains(signature)) continue;
        auto hook = HyprlandAPI::createFunctionHook(handle, match.address, function);
        if (hook && hook->hook()) { hooks.push_back(hook); return hook; }
        break;
    }
    throw std::runtime_error("Infinite Desk camera hook unavailable: " + signature);
}
inline void exit();
inline void init(HANDLE plugin) {
    handle = plugin; unloading = false;
    try {
    visibleHook = installHook("shouldRenderWindow", "IHyprRenderer::shouldRenderWindow(Hyprutils::Memory::CSharedPointer<Desktop::View::CWindow>,", reinterpret_cast<const void*>(&visible));
    hitHook = installHook("windowAt", "CViewHitTester::windowAt(", reinterpret_cast<const void*>(&hit));
    surfaceHook = installHook("windowSurfaceAt", "CViewHitTester::windowSurfaceAt(", reinterpret_cast<const void*>(&surface));
    localHook = installHook("surfaceLocalAt", "CViewHitTester::surfaceLocalAt(", reinterpret_cast<const void*>(&local));
    seatFocusHook = installHook("setPointerFocus", "CSeatManager::setPointerFocus(", reinterpret_cast<const void*>(&seatFocus));
    seatMotionHook = installHook("sendPointerMotion", "CSeatManager::sendPointerMotion(", reinterpret_cast<const void*>(&seatMotion));
    damageHook = installHook("damageSurface", "IHyprRenderer::damageSurface(", reinterpret_cast<const void*>(&damageSurface));
    wallpaperHook = installHook("drawSurface", "IElementRenderer::drawSurface(", reinterpret_cast<const void*>(&wallpaper));
    openListener = Event::bus()->m_events.window.open.listen([](PHLWINDOW window) { if (enabled) attach(window); });
    coordsHook = installHook("getMouseCoordsInternal", "CInputManager::getMouseCoordsInternal(", reinterpret_cast<const void*>(&mouseCoords));
    dragBeginHook = installHook("dragBegin", "CDragStateController::dragBegin(", reinterpret_cast<const void*>(&beginDrag));
    dragMoveHook = installHook("mouseMove", "CDragStateController::mouseMove(", reinterpret_cast<const void*>(&moveDrag));
    dragEndHook = installHook("dragEnd", "CDragStateController::dragEnd(", reinterpret_cast<const void*>(&endDrag));
    animationTimer = makeShared<CEventLoopTimer>(std::nullopt, [](SP<CEventLoopTimer>, void*) { animate(); }, nullptr);
    g_pEventLoopManager->addTimer(animationTimer);
    auto command = VeloraCompat::statusCommand(status);
    command.name = "velora-infinite-camera-status";
    statusCommand = HyprlandAPI::registerHyprCtlCommand(handle, command);
    if (!statusCommand) throw std::runtime_error("Could not register Infinite Desk camera status");
    } catch (...) {
        exit();
        throw;
    }
}
inline void exit() {
    if (drag && dragEndHook) endDrag(drag->controller);
    enabled = false; unloading = true; drag.reset();
    dragWorkspace.reset(); readingDragCoords = false;
    openListener.reset();
    if (animationTimer) g_pEventLoopManager->removeTimer(animationTimer);
    animationTimer.reset();
    if (statusCommand) HyprlandAPI::unregisterHyprCtlCommand(handle, statusCommand);
    statusCommand.reset();
    // Closed windows can still be retained by compositor fadeouts. Remove our
    // vtables from all surviving owners before the library is unloaded.
    for (auto& [_, weak] : attached)
        if (auto window = weak.lock(); window && window->effects().transformers()) window->effects().transformers()->removeInactive();
    attached.clear();
    for (auto hook : hooks) hook->unhook();
    hooks.clear();
    for (auto& [_, view] : views) damage(view);
    views.clear();
}
}
