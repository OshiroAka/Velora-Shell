#include "InfiniteDesktopCamera.hpp"
#include "InfiniteDesktopWorkspaceMode.hpp"
#include <cassert>
#include <chrono>
#include <iostream>
#include <memory>
#include <unordered_map>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
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
    unsigned id = 1;
    std::optional<unsigned> numberedID() const { return id; }
    PHLMONITORREF m_monitor;
    bool shown = true, m_forceRendering = false, fullscreen = false;
    SP<Animated<Vector2D>> m_renderOffset = std::make_shared<Animated<Vector2D>>();
    SP<Animated<float>> m_alpha = std::make_shared<Animated<float>>();
    bool visible() const { return shown; }
};
}
struct Monitor {
    std::string m_name = "DP-1";
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
static WorkspaceModes workspaceModes{false,true,{}};
#include "camera-workspaces.inc"
#include "camera-active-monitor.inc"

namespace State {
struct MonitorState {
    std::vector<PHLMONITOR> outputs;
    const auto& monitors() { return outputs; }
};
inline auto state = std::make_shared<MonitorState>();
auto monitorState() { return state; }
}
namespace IPC::Socket2 {
struct Server {
    struct Message { std::string name, payload; };
    std::vector<Message> sent;
    void postEvent(Message value) { sent.push_back(value); }
};
inline auto server = std::make_shared<Server>();
auto sock() { return server; }
}
#include "camera-widget-publish.inc"

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
    // Exercise the actual event serializer/publisher: idle deduplication,
    // fractional/negative output origins, inactive desktops and lifecycle reset.
    State::state->outputs = {monitor};
    monitor->m_position = {-1920., 24.5}; monitor->m_name = "DP-1\"test";
    monitor->m_activeSpecialWorkspace.reset(); monitor->m_activeWorkspace = first;
    auto eventPose = [&]() { return QJsonDocument::fromJson(QByteArray::fromStdString(IPC::Socket2::server->sent.back().payload)).object(); };
    publishWidgetCameras();
    assert(IPC::Socket2::server->sent.size() == 1 && !eventPose()["active"].toBool());
    for (int i=0;i<100;i++) publishWidgetCameras();
    assert(IPC::Socket2::server->sent.size() == 1);
    enabled = true; publishWidgetCameras();
    assert(eventPose()["active"].toBool() && eventPose()["monitor"].toString().toStdString() == monitor->m_name);
    assert(eventPose()["origin"].toArray()[0].toDouble() == -1920.);
    assert(eventPose()["origin"].toArray()[1].toDouble() == 24.5);
    a->camera.center.x += .125; publishWidgetCameras();
    assert(eventPose()["center"].toArray()[0].toDouble() == a->camera.center.x);
    auto secondOutput = std::make_shared<Monitor>(); secondOutput->m_name = "DP-2";
    State::state->outputs.push_back(secondOutput);
    publishWidgetCameras(); assert(!eventPose()["active"].toBool());
    assert(eventPose()["monitor"].toString() == "DP-2");
    const auto snapshot = QJsonDocument::fromJson(QByteArray::fromStdString(widgetCameraSnapshot())).array();
    assert(snapshot.size() == 2 && snapshot[0].toObject()["active"].toBool());
    first->fullscreen = true; publishWidgetCamera(monitor); assert(!eventPose()["active"].toBool());
    first->fullscreen = false; publishWidgetCamera(monitor); assert(eventPose()["active"].toBool());
    monitor->m_activeWorkspace = second; publishWidgetCamera(monitor);
    assert(eventPose()["center"].toArray()[0].toDouble() == b->camera.center.x);
    monitor->m_activeSpecialWorkspace = first; publishWidgetCamera(monitor); assert(!eventPose()["active"].toBool());
    monitor->m_activeSpecialWorkspace.reset(); g_pSessionLockManager->locked = true;
    publishWidgetCamera(monitor); assert(!eventPose()["active"].toBool());
    g_pSessionLockManager->locked = false; publishWidgetCamera(monitor); assert(eventPose()["active"].toBool());
    unloading = true; publishWidgetCameras();
    assert(!QJsonDocument::fromJson(QByteArray::fromStdString(widgetCameraSnapshot())).array()[0].toObject()["active"].toBool());
    // Workspace 1 and 4 keep independent cameras; ordinary desktops never
    // acquire a view merely because another workspace has enabled the canvas.
    unloading = false; enabled = true;
    workspaceModes = WorkspaceModes{true,false,{1,4}};
    first->id = 1; second->id = 4;
    const auto retainedCenter = a->camera.center;
    monitor->m_activeWorkspace = first;
    assert(viewFor(monitor) == a && a->camera.zoom == saved.zoom);
    for (unsigned id=2;id<=10;id++) {
        if (id==4) continue;
        auto normal=std::make_shared<Workspace::CHLWorkspace>();normal->id=id;normal->m_monitor=monitor;
        monitor->m_activeWorkspace=normal;
        assert(!available(monitor) && !ensureView(monitor) && !viewFor(monitor));
    }
    monitor->m_activeWorkspace=second; assert(viewFor(monitor)==b);
    workspaceModes.set(4,false); assert(!viewFor(monitor));
    monitor->m_activeWorkspace=first; assert(viewFor(monitor)==a && a->camera.center==retainedCenter);
    assert(workspaceModes.configure("global 1 1"));
    monitor->m_activeWorkspace=second; assert(viewFor(monitor)==b);
    workspaceModes.set(4,false); assert(!workspaceModes.active(1) && !viewFor(monitor));
    assert(workspaceModes.configure("workspace 0 1"));
    monitor->m_activeWorkspace=first; assert(viewFor(monitor)==a);
    const auto modes=workspaceModes;
    for (const auto& invalid : {"workspace 2 1", "global 0 -1", "workspace 0 4294967296", "other 0 1"}) {
        assert(!workspaceModes.configure(invalid) && workspaceModes==modes);
    }
    // Destroyed workspaces leave weak references until their view is pruned.
    views[nullptr] = View{}; views[nullptr].monitor = monitor;
    workspaceModes.workspaces.clear();
    assert(!activeMonitor(monitor));
    std::cout << "INFINITE_CAMERA_WORKSPACES_OK\n";
}
