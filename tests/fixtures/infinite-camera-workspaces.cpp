#include "InfiniteDesktopCamera.hpp"
#include <cassert>
#include <chrono>
#include <iostream>
#include <memory>
#include <unordered_map>
using namespace Velora::InfiniteDesk;
template<class T> using SP = std::shared_ptr<T>;
template<class T> struct Ref {
    SP<T> pointer;
    Ref() = default;
    Ref(SP<T> p) : pointer(p) {}
    SP<T> lock() const { return pointer; }
    T* operator->() const { return pointer.get(); }
    explicit operator bool() const { return bool(pointer); }
    bool operator==(const Ref&) const = default;
};
struct Monitor;
namespace Workspace { struct CHLWorkspace; }
using PHLMONITOR = SP<Monitor>;
using PHLMONITORREF = Ref<Monitor>;
using PHLWORKSPACE = SP<Workspace::CHLWorkspace>;
using PHLWORKSPACEREF = Ref<Workspace::CHLWorkspace>;
template<class T> struct Animated {
    T current{};
    bool animating = false;
    T value() const { return current; }
    bool isBeingAnimated() const { return animating; }
};
namespace Workspace {
struct CHLWorkspace {
    PHLMONITORREF m_monitor;
    bool shown = true, m_forceRendering = false, fullscreen = false;
    SP<Animated<Vector2D>> m_renderOffset = std::make_shared<Animated<Vector2D>>();
    SP<Animated<float>> m_alpha = std::make_shared<Animated<float>>();
    bool visible() const { return shown; }
};
}
struct Monitor {
    Vector2D m_position, m_size{1920,1080};
    PHLWORKSPACE m_activeWorkspace, m_activeSpecialWorkspace;
};
namespace Desktop::View { enum { WINDOW_STATE_PINNED = 1 }; }
struct Window {
    PHLWORKSPACE m_workspace;
    int m_state = 0;
    bool mapped() const { return true; }
    bool isFloating() const { return true; }
    bool isHidden() const { return false; }
};
using PHLWINDOW = SP<Window>;
struct Lock { bool locked = false; bool isSessionLocked() const { return locked; } };
static auto g_pSessionLockManager = std::make_shared<Lock>();
namespace Fullscreen {
struct Controller { bool hasFullscreen(PHLWORKSPACE workspace) { return workspace->fullscreen; } };
Controller* controller() { static Controller instance; return &instance; }
}
#include "camera-view.inc"
static std::unordered_map<const Workspace::CHLWorkspace*,View> views;
static bool enabled = true, unloading = false;
#include "camera-workspaces.inc"
#include "camera-active-monitor.inc"

int main() {
    auto monitor = std::make_shared<Monitor>();
    auto first = std::make_shared<Workspace::CHLWorkspace>(), second = std::make_shared<Workspace::CHLWorkspace>();
    first->m_monitor = second->m_monitor = monitor;
    monitor->m_activeWorkspace = first;
    auto outgoing = std::make_shared<Window>(); outgoing->m_workspace = first;
    auto a = ensureView(monitor);
    a->camera.zoom = .25; a->camera.center = {3000,-800};
    const auto saved = a->camera;
    monitor->m_activeWorkspace = second; first->shown = false;
    first->m_renderOffset->animating = true; first->m_renderOffset->current = {-800,0};
    // Rendering keeps the outgoing camera, while input selects the incoming one.
    assert(viewFor(outgoing) == a && workspaceRenderable(*a));
    assert(!viewFor(monitor));
    assert(activeMonitor(monitor)); // No simplification even with an unzoomed destination.
    auto b = ensureView(monitor);
    assert(b != a && b->camera.zoom == 1. && viewFor(monitor) == b);
    b->camera.zoom = .5; b->camera.center = {-400,900};
    first->m_renderOffset->animating = false;
    assert(!workspaceRenderable(*a)); // Hidden desktops must not leak into the scene.
    second->shown = false;
    assert(!activeMonitor(monitor));
    first->m_alpha->animating = true; assert(workspaceRenderable(*a));
    first->m_alpha->animating = false; first->m_forceRendering = true;
    assert(workspaceRenderable(*a)); first->m_forceRendering = false;
    for (int i=0; i<10; ++i) {
        monitor->m_activeWorkspace = first; first->shown = true; second->shown = false;
        first->m_renderOffset->current = {};
        assert(viewFor(monitor) == a && a->camera.zoom == saved.zoom && a->camera.center == saved.center);
        monitor->m_activeWorkspace = second; first->shown = false; second->shown = true;
        assert(viewFor(monitor) == b && b->camera.zoom == .5 && b->camera.center == Vector2D(-400,900));
    }
    g_pSessionLockManager->locked = true;
    assert(!viewFor(outgoing) && !activeMonitor(monitor));
    g_pSessionLockManager->locked = false; first->fullscreen = true;
    assert(!viewFor(outgoing)); first->fullscreen = false;
    outgoing->m_state = Desktop::View::WINDOW_STATE_PINNED; assert(!viewFor(outgoing)); outgoing->m_state = 0;
    monitor->m_activeSpecialWorkspace = first; assert(!viewFor(monitor));
    assert(viewFor(outgoing) == a); // Regular workspace keeps its camera behind the overlay.
    enabled = false; assert(!viewFor(outgoing) && !activeMonitor(monitor));
    std::cout << "INFINITE_CAMERA_WORKSPACES_OK\n";
}
