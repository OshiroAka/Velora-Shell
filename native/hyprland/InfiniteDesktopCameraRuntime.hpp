#pragma once
#define VELORA_INFINITE_CAMERA_RUNTIME 1

#include "InfiniteDesktopCamera.hpp"
#include "InfiniteDesktopWorkspaceMode.hpp"
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
#include <fstream>
#pragma push_macro("HANDLE")
#undef HANDLE
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#pragma pop_macro("HANDLE")
#include <unistd.h>

namespace Velora::InfiniteDesk {
struct View {
    Camera camera, from, target;
    PanBatch pan;
    PanInertia inertia;
    FocusBookmark focus;
    std::optional<Vector2D> zoomAnchor;
    PHLMONITORREF monitor;
    PHLWORKSPACEREF workspace;
    std::chrono::steady_clock::time_point started;
    bool animating = false;
    double duration = .18;
    CameraMotion motion = CameraMotion::STANDARD;
    std::chrono::steady_clock::time_point lastPanFrame;
    double panIntervalTotal = 0., panIntervalMax = 0.;
    uint64_t panIntervals = 0;
};
inline std::unordered_map<const Workspace::CHLWorkspace*, View> views;
inline bool enabled = false, unloading = false;
inline WorkspaceModes workspaceModes;
inline HANDLE handle = nullptr;
inline SP<CEventLoopTimer> animationTimer;
inline CHyprSignalListener openListener, panButtonListener, panMotionListener, panFrameListener;
inline std::vector<CFunctionHook*> hooks;
inline std::unordered_map<const Desktop::View::CWindow*, PHLWINDOWREF> attached;
inline SP<VeloraCompat::StatusCommand> statusCommand;
inline bool readingDragCoords = false;
inline PHLWORKSPACEREF dragWorkspace;

inline bool available(PHLMONITOR monitor) {
    return enabled && !unloading && monitor && monitor->m_activeWorkspace && !monitor->m_activeSpecialWorkspace
        && workspaceModes.active(monitor->m_activeWorkspace->numberedID().value_or(0))
        && !g_pSessionLockManager->isSessionLocked()
        && !Fullscreen::controller()->hasFullscreen(monitor->m_activeWorkspace);
}
inline View* viewFor(PHLWORKSPACE workspace) {
    if (!enabled || unloading || !workspace || !workspaceModes.active(workspace->numberedID().value_or(0))
        || g_pSessionLockManager->isSessionLocked()
        || Fullscreen::controller()->hasFullscreen(workspace)) return nullptr;
    const auto monitor = workspace->m_monitor.lock();
    if (!monitor) return nullptr;
    const auto found = views.find(workspace.get());
    if (found == views.end() || found->second.workspace != workspace) return nullptr;
    auto& view = found->second;
    if (view.monitor != monitor || view.camera.viewport != monitor->m_size) {
        // A moved workspace or changed output retains its world centre and zoom.
        view.monitor = monitor;
        view.camera.viewport = view.from.viewport = view.target.viewport = monitor->m_size;
    }
    return &view;
}
inline View* viewFor(PHLMONITOR monitor) {
    return available(monitor) ? viewFor(monitor->m_activeWorkspace) : nullptr;
}
inline View* viewFor(const PHLWINDOW& window) {
    if (!window || !window->mapped() || !window->isFloating() || window->isHidden()
        || (window->m_state & Desktop::View::WINDOW_STATE_PINNED) || !window->m_workspace) return nullptr;
    // Outgoing windows still render during the compositor's workspace slide.
    // Keep their own camera until the entire transition has finished.
    return viewFor(window->m_workspace);
}
inline View* ensureView(PHLMONITOR monitor) {
    if (!available(monitor)) return nullptr;
    const auto workspace = monitor->m_activeWorkspace;
    auto [found, inserted] = views.try_emplace(workspace.get());
    auto& view = found->second;
    if (inserted || view.workspace != workspace) {
        view = {}; view.monitor = monitor; view.workspace = workspace;
        view.camera = Camera{monitor->m_position + monitor->m_size / 2., monitor->m_size};
        view.from = view.target = view.camera;
    }
    return viewFor(monitor);
}
inline bool transformed(const View* view) {
    return view && view->monitor && !view->camera.identity(view->monitor->m_position);
}
inline bool workspaceRenderable(const View& view) {
    return view.workspace && (view.workspace->visible() || view.workspace->m_forceRendering
        || view.workspace->m_renderOffset->isBeingAnimated() || view.workspace->m_alpha->isBeingAnimated());
}
inline Vector2D workspaceOffset(const View& view) {
    return view.workspace ? view.workspace->m_renderOffset->value() : Vector2D{};
}
inline void damage(View& view) {
    if (auto monitor = view.monitor.lock()) {
        monitor->m_blurFBDirty = true;
        g_pHyprRenderer->damageMonitor(monitor);
    }
}

inline std::unordered_map<std::string, std::string> widgetCameraPublished;
inline std::string widgetCameraPose(PHLMONITOR monitor) {
    const auto view = viewFor(monitor);
    QJsonObject pose{{"monitor", QString::fromStdString(monitor->m_name)}, {"active", bool(view)}};
    if (view) {
        pose.insert("workspace", qint64(view->workspace->numberedID().value_or(0)));
        pose.insert("zoom", view->camera.zoom);
        pose.insert("center", QJsonArray{view->camera.center.x, view->camera.center.y});
        pose.insert("origin", QJsonArray{monitor->m_position.x, monitor->m_position.y});
        pose.insert("viewport", QJsonArray{view->camera.viewport.x, view->camera.viewport.y});
    }
    return QJsonDocument(pose).toJson(QJsonDocument::Compact).toStdString();
}
inline void publishWidgetCamera(PHLMONITOR monitor) {
    if (!monitor) return;
    const auto payload = widgetCameraPose(monitor);
    auto& previous = widgetCameraPublished[monitor->m_name];
    if (payload == previous) return;
#if __has_include(<hyprland/src/ipc/s2/S2.hpp>)
    if (!IPC::Socket2::sock()) return;
    IPC::Socket2::sock()->postEvent({"velora-infinite-camera", payload});
#else
    if (!g_pEventManager) return;
    g_pEventManager->postEvent({"velora-infinite-camera", payload});
#endif
    previous = payload;
}
inline void publishWidgetCameras() {
    for (const auto& monitor : State::monitorState()->monitors()) publishWidgetCamera(monitor);
}
inline std::string widgetCameraSnapshot() {
    std::string result = "[";
    for (const auto& monitor : State::monitorState()->monitors()) {
        if (!monitor) continue;
        if (result.size() > 1) result += ',';
        result += widgetCameraPose(monitor);
    }
    return result + "]";
}
inline Render::SRenderModifData modifiers(const View& view) {
    auto monitor = view.monitor.lock();
    Render::SRenderModifData result;
    result.modifs.emplace_back(Render::SRenderModifData::RMOD_TYPE_SCALE, float(view.camera.zoom));
    result.modifs.emplace_back(Render::SRenderModifData::RMOD_TYPE_TRANSLATE,
        (view.camera.viewport / 2. + (monitor->m_position - view.camera.center) * view.camera.zoom
            + workspaceOffset(view) * (1. - view.camera.zoom)) * monitor->m_scale);
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
        return transformed(view) ? view->camera.project(input.copy().translate(view->monitor->m_position), workspaceOffset(*view)) : input;
    }
    CBox sourceBoxForOutput(const CBox& output, const CBox& input) const override {
        auto view = viewFor(window.lock());
        return transformed(view) ? view->camera.unproject(output, workspaceOffset(*view)).translate(-view->monitor->m_position).intersection(input) : output.intersection(input);
    }
    CBox transformBoxForDamage(const CBox& input) const override {
        auto view = viewFor(window.lock());
        return transformed(view) ? view->camera.project(input, workspaceOffset(*view)).translate(view->monitor->m_position).expand(2) : input;
    }
    Render::SWindowTransformBuffer transform(Render::CRenderContext&, const Render::SWindowTransformBuffer& input,
                                              const Render::SWindowTransformContext& context) override {
        auto view = viewFor(window.lock());
        if (!transformed(view) || !context.monitor || context.monitor != view->monitor) return input;
        auto result = input;
        const double scale = context.monitor->m_scale;
        // Reuse the live client framebuffer. The destination box changes, not
        // its pixels, dimensions, configure serial, or the application's layout.
        result.box = view->camera.project(input.box.copy().scale(1. / scale).translate(context.monitor->m_position), workspaceOffset(*view)).scale(scale);
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
    if (transformed(view)) { attach(window); return view->monitor == monitor && workspaceRenderable(*view); }
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

struct PanPreferences {
    double sensitivity = 1.15, direction = 1.;
    static PanPreferences parse(const std::string& text, bool inverted) {
        PanPreferences prefs;
        prefs.direction = inverted ? -1. : 1.;
        const auto value = QJsonDocument::fromJson(QByteArray::fromStdString(text)).object()
            .value("infiniteDesk").toObject().value("dragSensitivity");
        if (value.isDouble() && std::isfinite(value.toDouble())) prefs.sensitivity = std::clamp(value.toDouble(), .1, 4.);
        return prefs;
    }
};
inline std::filesystem::path marker(const char* suffix, bool fallback = false) {
    const char* runtime = fallback ? nullptr : std::getenv("XDG_RUNTIME_DIR");
    return std::filesystem::path(runtime ? runtime : "/tmp") / ("infinite-desktop-" + std::to_string(getuid()) + "." + suffix);
}
inline bool hasMarker(const char* suffix) {
    std::error_code error;
    return std::filesystem::exists(marker(suffix), error) || std::filesystem::exists(marker(suffix, true), error);
}
inline PanPreferences panPreferences() {
    const auto xdg = std::getenv("XDG_CONFIG_HOME"), home = std::getenv("HOME");
    const auto base = xdg ? std::filesystem::path(xdg) : std::filesystem::path(home ? home : "") / ".config";
    std::ifstream file(base / "velora-shell/config.json");
    const std::string text((std::istreambuf_iterator<char>(file)), {});
    return PanPreferences::parse(text, hasMarker("inverted"));
}
inline double panTime() {
    return std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
}
inline bool queuePan(PHLMONITOR monitor, Vector2D delta, bool kinetic = false) {
    if (drag) return false;
    auto view = ensureView(monitor);
    if (!view) return false;
    const bool pending = view->pan.pending != Vector2D{};
    if (!view->pan.add(delta)) return true;
    if (kinetic) view->inertia.sample(delta, panTime());
    else view->inertia = {};
    // A direct gesture takes over at the currently presented camera position.
    // There is no trailing interpolation that could add lag behind the pointer.
    view->animating = false;
    view->zoomAnchor.reset();
    if (!pending) damage(*view);
    return true;
}
inline void panFrame(PHLMONITOR monitor) {
    auto view = viewFor(monitor);
    if (!view) return;
    view->pan.pending += view->inertia.step(panTime());
    if (!view->pan.apply(view->camera)) return;
    view->from = view->target = view->camera;
    const auto now = std::chrono::steady_clock::now();
    const auto interval = std::chrono::duration<double>(now - view->lastPanFrame).count();
    if (interval > .001 && interval < .1) {
        view->panIntervalTotal += interval;
        view->panIntervalMax = std::max(view->panIntervalMax, interval);
        ++view->panIntervals;
    }
    view->lastPanFrame = now;
    if (view->inertia.active) damage(*view);
}
struct PanGesture {
    PHLMONITORREF monitor;
    PHLWORKSPACEREF workspace;
    PanPreferences prefs;
    Vector2D last;
    uint32_t button = 0;
};
inline std::optional<PanGesture> panGesture;
inline bool relativePanMotion = false;
inline bool focusButtonHeld = false;
inline uint64_t focusPresses = 0;
inline std::string focusResult = "idle";
inline bool focusClick(PHLMONITOR monitor, const Vector2D& point);
inline bool panGestureActive() {
    return panGesture && available(panGesture->monitor.lock())
        && panGesture->monitor->m_activeWorkspace == panGesture->workspace;
}
inline void panButton(const IPointer::SButtonEvent& event, Event::SCallbackInfo& info) {
    if (event.button == 274 && event.state == WL_POINTER_BUTTON_STATE_PRESSED) {
        ++focusPresses; focusResult = info.cancelled ? "cancelled" : "pressed";
    }
    if (focusButtonHeld && event.button == 274 && event.state == WL_POINTER_BUTTON_STATE_RELEASED) {
        focusButtonHeld = false; info.cancelled = true; return;
    }
    if (panGesture && event.button == panGesture->button && event.state == WL_POINTER_BUTTON_STATE_RELEASED) {
        if (panGestureActive()) {
            auto view = viewFor(panGesture->monitor.lock());
            if (view && view->inertia.release(panTime())) damage(*view);
        }
        panGesture.reset(); info.cancelled = true; return;
    }
    if (info.cancelled || drag || event.state != WL_POINTER_BUTTON_STATE_PRESSED || !enabled || g_pInputManager->isConstrained()) return;
    const auto point = Pointer::mgr()->untransformedPosition();
    const auto monitor = State::monitorState()->query().vec(point).run();
    if (auto view = viewFor(monitor)) view->inertia = {};
    const uint32_t mods = uint32_t(g_pInputManager->getModsFromAllKBs()) & (64U | 1U | 4U | 8U);
    if (event.button == 274 && mods == 0 && !panGesture && focusClick(monitor, point)) {
        focusButtonHeld = true; info.cancelled = true; return;
    }
    const bool fallbackDrag = event.button == 272 && mods == (64U | 8U);
    if (!fallbackDrag && (event.button != 273 || !infiniteDesktopGestureFocused(monitor))) return;
    if (!ensureView(monitor)) return;
    ensureView(monitor)->inertia.begin(panTime());
    panGesture = PanGesture{monitor, monitor->m_activeWorkspace, panPreferences(), point, event.button};
    info.cancelled = true;
}
inline void panMotion(const Vector2D& point, Event::SCallbackInfo& info) {
    if (!panGesture) return;
    if (panGestureActive() && !relativePanMotion)
        queuePan(panGesture->monitor.lock(), (point - panGesture->last) * panGesture->prefs.sensitivity * panGesture->prefs.direction, true);
    panGesture->last = point;
    info.cancelled = true;
}
using RelativeMotionFn = void (*)(CInputManager*, IPointer::SMotionEvent);
inline CFunctionHook* relativeMotionHook = nullptr;
inline void relativeMotion(CInputManager* input, IPointer::SMotionEvent event) {
    const bool previous = relativePanMotion;
    relativePanMotion = panGestureActive();
    if (relativePanMotion)
        queuePan(panGesture->monitor.lock(), event.delta * panGesture->prefs.sensitivity * panGesture->prefs.direction, true);
    Hyprutils::Utils::CScopeGuard restore{[previous] { relativePanMotion = previous; }};
    reinterpret_cast<RelativeMotionFn>(relativeMotionHook->m_original)(input, event);
}
inline PHLMONITORREF scrollMonitor;
inline PHLWORKSPACEREF scrollWorkspace;
inline PanPreferences scrollPreferences;
inline std::chrono::steady_clock::time_point lastScroll;
inline bool scroll(PHLMONITOR monitor, double dx, double dy) {
    if (!available(monitor)) return false;
    const auto now = std::chrono::steady_clock::now();
    if (monitor != scrollMonitor || monitor->m_activeWorkspace != scrollWorkspace || now - lastScroll > std::chrono::milliseconds(220)) {
        scrollPreferences = panPreferences(); scrollMonitor = monitor; scrollWorkspace = monitor->m_activeWorkspace;
        if (auto view = ensureView(monitor)) view->inertia.begin(panTime());
    }
    lastScroll = now;
    if (dx == 0. && dy == 0.) {
        auto view = viewFor(monitor);
        if (view && view->inertia.release(panTime())) damage(*view);
        return true;
    }
    return queuePan(monitor, Vector2D{dx, dy} * scrollPreferences.sensitivity * scrollPreferences.direction, true);
}

inline void animate() {
    bool again = false;
    const auto now = std::chrono::steady_clock::now();
    for (auto& [_, view] : views) {
        if (!view.animating) continue;
        const auto t = std::clamp(std::chrono::duration<double>(now - view.started).count() / view.duration, 0., 1.);
        view.camera = animateCamera(view.from, view.target, t, view.motion, view.zoomAnchor);
        view.animating = t < 1.;
        again = again || view.animating;
        damage(view);
    }
    if (again && animationTimer) animationTimer->updateTimeout(std::chrono::milliseconds(8));
}
inline void update(View& view, const Camera& target, bool smooth, std::optional<Vector2D> anchor = {}, double duration = .18, CameraMotion motion = CameraMotion::STANDARD) {
    view.inertia = {};
    view.from = view.camera;
    view.target = target;
    view.zoomAnchor = anchor;
    view.duration = duration;
    view.motion = motion;
    view.started = std::chrono::steady_clock::now();
    view.animating = smooth;
    if (smooth) animate();
    else { view.camera = target; damage(view); }
}
inline bool focusClick(PHLMONITOR monitor, const Vector2D& point) {
    const auto rejected = [](const char* reason) { focusResult = reason; return false; };
    if (!available(monitor) || !g_pSeatManager) return rejected("unavailable");
    const auto resource = g_pSeatManager->m_state.pointerFocus.lock();
    const auto surface = Desktop::View::CWLSurface::fromResource(resource);
    if (!surface || !surface->view()) return rejected("no-surface");
    const auto type = surface->view()->type();
    const bool canvas = infiniteDesktopGestureFocused(monitor);
    if (type == Desktop::View::VIEW_TYPE_POPUP || (type == Desktop::View::VIEW_TYPE_LAYER_SURFACE && !canvas)) return rejected("overlay");
    auto window = Desktop::viewState()->hitTest().windowAt(point, Desktop::View::INPUT_EXTENTS | Desktop::View::ALLOW_FLOATING);
    auto view = ensureView(monitor);
    if (!view || (!view->focus.returnTo && (!window || viewFor(window) != view))) return rejected("no-window");
    if (!window && !canvas) return rejected("outside-canvas");
    auto usable = monitor->m_reservedArea.apply(CBox{{}, monitor->m_size});
    if (usable.w > 64. && usable.h > 64.) usable.expand(-24.);
    const bool returning = view->focus.returnTo.has_value();
    auto target = view->focus.toggle(view->camera, window ? window->getFullWindowBoundingBox() : CBox{}, usable);
    if (!target) return rejected("invalid-bounds");
    view->pan.pending = {};
    if (!returning && window) {
        attach(window);
        Desktop::focusState()->fullWindowFocus(window, Desktop::FOCUS_REASON_CLICK);
    }
    update(*view, *target, true, {}, .5, CameraMotion::FOCUS);
    focusResult = returning ? "restored" : "focused";
    return true;
}
inline SDispatchResult dispatch(std::string arguments) {
    std::istringstream input(arguments);
    std::string action, extra;
    input >> action;
    auto monitor = Desktop::focusState()->monitor();
    const bool explicitMonitor = action.starts_with('@');
    if (action.starts_with('@')) {
        monitor.reset();
        for (const auto& output : State::monitorState()->monitors())
            if (output->m_name == action.substr(1)) { monitor = output; break; }
        input >> action;
    }
    if (drag) return {.success = false, .error = "Finish moving or resizing the window before changing the camera"};
    if (action == "enable" || action == "disable") {
        std::string expected;
        if (input >> expected) {
            if (expected.find_first_not_of("0123456789") != std::string::npos || !monitor || !monitor->m_activeWorkspace)
                return {.success = false, .error = "Invalid expected workspace"};
            try {
                if (std::stoull(expected) != monitor->m_activeWorkspace->numberedID().value_or(0))
                    return {.success = false, .error = "Workspace changed before camera action"};
            } catch (...) { return {.success = false, .error = "Invalid expected workspace"}; }
            if (input >> extra) return {.success = false, .error = "Unexpected camera argument"};
        }
        input.clear();
    }
    if (action == "scope") {
        std::string arguments; std::getline(input, arguments);
        auto next = workspaceModes;
        if (!next.configure(arguments)) return {.success = false, .error = "Invalid workspace scope"};
        if (next == workspaceModes) return {};
        workspaceModes = next; enabled = workspaceModes.any();
        for (auto& [_, view] : views) {
            if (!view.workspace || !workspaceModes.active(view.workspace->numberedID().value_or(0))) {
                view.animating = false; view.pan.pending = {}; view.inertia = {};
            }
            damage(view);
        }
        for (const auto& output : State::monitorState()->monitors()) {
            if (available(output)) ensureView(output);
            g_pHyprRenderer->damageMonitor(output);
        }
        for (auto& window : Desktop::windowState()->windows()) attach(window);
        publishWidgetCameras(); return {};
    }
    if (!monitor || !monitor->m_activeWorkspace) return {.success = false, .error = "No active camera output"};
    if (action == "disable") {
        if (input >> extra) return {.success = false, .error = "Unexpected camera argument"};
        workspaceModes.set(monitor->m_activeWorkspace->numberedID().value_or(0), false);
        for (auto it = views.begin(); it != views.end();) {
            if (!it->second.workspace || !workspaceModes.active(it->second.workspace->numberedID().value_or(0))) {
                damage(it->second); it = views.erase(it);
            } else ++it;
        }
        enabled = workspaceModes.any();
        publishWidgetCameras(); return {};
    }
    if (action != "enable" && action != "zoom" && action != "pan" && action != "center" && action != "reset" && action != "restore")
        return {.success = false, .error = "Unknown camera action"};
    double x = 0, y = 0, zoom = 1.;
    // Restore an exact camera after a native-module update without replaying
    // zoom animations or changing any client geometry.
    if (action == "restore" && (!(input >> zoom) || !std::isfinite(zoom) || zoom < Camera::MIN_ZOOM || zoom > Camera::MAX_ZOOM))
        return {.success = false, .error = "Invalid camera zoom"};
    std::string direction;
    if (action == "zoom") {
        input >> direction;
        if (direction != "in" && direction != "out") return {.success = false, .error = "Expected zoom in or out"};
    } else if (action == "pan" || action == "center" || action == "restore") {
        if (!(input >> x >> y) || !std::isfinite(x) || !std::isfinite(y) || std::abs(x) > 1e7 || std::abs(y) > 1e7)
            return {.success = false, .error = "Invalid camera coordinates"};
    }
    if (input >> extra) return {.success = false, .error = "Unexpected camera argument"};
    if (action == "zoom" && !explicitMonitor) {
        if (auto pointerMonitor = State::monitorState()->query().vec(Pointer::mgr()->untransformedPosition()).run()) monitor = pointerMonitor;
    }
    if ((action == "enable" || action == "restore") && (monitor->m_activeSpecialWorkspace
        || g_pSessionLockManager->isSessionLocked() || Fullscreen::controller()->hasFullscreen(monitor->m_activeWorkspace)))
        return {.success = false, .error = "Camera suspended on this workspace"};
    if (action == "enable" || action == "restore") {
        workspaceModes.set(monitor->m_activeWorkspace->numberedID().value_or(0), true);
        enabled = workspaceModes.any();
    }
    if (!available(monitor)) return {.success = false, .error = "Camera suspended on this workspace"};
    auto& view = *ensureView(monitor);
    if (action == "pan") { queuePan(monitor, {x, y}); return {}; }
    for (auto& window : Desktop::windowState()->windows()) attach(window);
    auto target = view.target;
    std::optional<Vector2D> anchor;
    if (action == "zoom") {
        const auto point = Pointer::mgr()->untransformedPosition() - monitor->m_position;
        anchor = Vector2D{std::clamp(point.x, 0., view.camera.viewport.x), std::clamp(point.y, 0., view.camera.viewport.y)};
        const auto zoom = target.zoom * (direction == "out" ? Camera::ZOOM_STEP : 1. / Camera::ZOOM_STEP);
        target = view.camera;
        target.zoomAt(zoom, *anchor);
    }
    else if (action == "center") target.center = {x, y};
    else if (action == "reset") target = Camera{monitor->m_position + monitor->m_size / 2., monitor->m_size};
    else if (action == "restore") { target.zoom = zoom; target.center = {x, y}; }
    if (action == "reset" || action == "restore") view.focus.returnTo.reset();
    view.pan.pending = {};
    update(view, target, action == "zoom" || action == "center" || action == "reset", anchor,
        action == "center" ? NAVIGATION_DURATION : .18,
        action == "center" ? CameraMotion::NAVIGATION : CameraMotion::STANDARD);
    return {};
}
inline bool activeMonitor(PHLMONITOR monitor) {
    if (!enabled || unloading || g_pSessionLockManager->isSessionLocked()) return false;
    for (const auto& [_, view] : views)
        if (view.monitor == monitor && view.workspace && workspaceModes.active(view.workspace->numberedID().value_or(0))
            && workspaceRenderable(view) && transformed(&view)) return true;
    return false;
}

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
    // Wallpaper and shell surfaces remain in physical screen space. Only
    // application surfaces and their popups follow the camera.
    original(renderer, ctx, element, damageRegion);
}

inline std::string status(VeloraCompat::OutputFormat, std::string) {
    std::string result = std::format(R"({{"enabled":{},"panTransport":"native-input-vblank","wallpaper":"fixed","focusPresses":{},"focusResult":"{}","views":[)", enabled ? "true" : "false", focusPresses, focusResult);
    bool first = true;
    for (const auto& [_, view] : views) {
        if (!view.monitor || !view.workspace) continue;
        if (!first) result += ',';
        first = false;
        result += std::format(R"({{"monitor":"{}","workspace":{},"zoom":{},"center":[{},{}],"viewport":[{},{}],"animating":{},"active":{},"panInputs":{},"panFrames":{},"panFps":{},"panMaxIntervalMs":{},"coasting":{},"focused":{}}})",
            view.monitor->m_name, view.workspace->numberedID().value_or(0), view.camera.zoom, view.camera.center.x, view.camera.center.y,
            view.camera.viewport.x, view.camera.viewport.y, view.animating ? "true" : "false",
            view.monitor->m_activeWorkspace == view.workspace ? "true" : "false", view.pan.inputs, view.pan.frames,
            view.panIntervalTotal > 0 ? view.panIntervals / view.panIntervalTotal : 0., view.panIntervalMax * 1000., view.inertia.active ? "true" : "false", view.focus.returnTo ? "true" : "false");
    }
    return result + "],\"widgetViews\":" + widgetCameraSnapshot() + "}";
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
    relativeMotionHook = installHook("onMouseMoved", "CInputManager::onMouseMoved(", reinterpret_cast<const void*>(&relativeMotion));
    panButtonListener = Event::bus()->m_events.input.mouse.button.listen(panButton);
    panMotionListener = Event::bus()->m_events.input.mouse.move.listen(panMotion);
    panFrameListener = Event::bus()->m_events.render.pre.listen([](PHLMONITOR monitor) {
        if (available(monitor) && !viewFor(monitor)) {
            ensureView(monitor);
            for (auto& window : Desktop::windowState()->windows()) attach(window);
        }
        panFrame(monitor);
        // Publish the actual pose after this output consumed its input batch.
        // Deduplication leaves idle outputs silent; no QML per-frame subprocess.
        publishWidgetCamera(monitor);
    });
    infiniteDesktopNativeScroll = scroll;
    workspaceModes = {};
    std::ifstream modesFile(marker("workspaces.json"));
    const std::string modesText((std::istreambuf_iterator<char>(modesFile)), std::istreambuf_iterator<char>());
    const auto modes = QJsonDocument::fromJson(QByteArray::fromStdString(modesText)).object();
    if (modes.value("version").toInt() == 1) {
        workspaceModes.independent = modes.value("independent").toBool(true);
        workspaceModes.global = modes.value("global").toBool(false);
        const auto entries = modes.value("workspaces").toObject();
        for (auto it = entries.begin(); it != entries.end(); ++it) {
            bool ok = false; const auto id = it.key().toUInt(&ok);
            if (ok && id > 0 && it.value().toBool(false)) workspaceModes.workspaces.insert(id);
        }
    } else if (hasMarker("enabled")) {
        const auto monitor = Desktop::focusState()->monitor();
        if (monitor && monitor->m_activeWorkspace) workspaceModes.set(monitor->m_activeWorkspace->numberedID().value_or(0), true);
    }
    enabled = workspaceModes.any();
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
    publishWidgetCameras();
    widgetCameraPublished.clear();
    dragWorkspace.reset(); readingDragCoords = false;
    openListener.reset(); panButtonListener.reset(); panMotionListener.reset(); panFrameListener.reset();
    infiniteDesktopNativeScroll = nullptr;
    panGesture.reset(); scrollMonitor.reset(); scrollWorkspace.reset();
    focusButtonHeld = false;
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
