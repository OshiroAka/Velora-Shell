#include "InfiniteDesktopCamera.hpp"
#include <cassert>
#include <iostream>
#include <memory>
#include <vector>
#include <chrono>
#include <QJsonDocument>
#include <QJsonObject>
#include <array>
#include <format>
#include <wayland-client-protocol.h>
using namespace Velora::InfiniteDesk;

template<class T> using SP = std::shared_ptr<T>;
template<class T> using WP = std::shared_ptr<T>;
template<class T> struct Ref {
    SP<T> pointer;
    Ref() = default;
    Ref(SP<T> p) : pointer(p) {}
    SP<T> lock() const { return pointer; }
    T* operator->() const { return pointer.get(); }
    explicit operator bool() const { return bool(pointer); }
    bool operator==(const Ref&) const = default;
};
struct LayerResource { Ref<int> m_surface; };
struct Layer { std::string m_namespace; Ref<LayerResource> m_layerSurface; };
struct Monitor {
    Vector2D m_position; double m_scale = 1.; std::string m_name = "QA-1";
    std::array<std::vector<Ref<Layer>>,4> m_layerSurfaceLayers;
};
struct Workspace {};
namespace Desktop::View { enum { VIEW_TYPE_WINDOW }; }
struct LogicalView { virtual ~LogicalView() = default; virtual int type() const { return Desktop::View::VIEW_TYPE_WINDOW; } };
struct Window : LogicalView {
    bool kitty = true;
    SP<int> mainSurface = std::make_shared<int>(1);
    SP<int> resource() const { return mainSurface; }
    static SP<Window> fromView(SP<LogicalView> value) { return std::dynamic_pointer_cast<Window>(value); }
};
using PHLWINDOW = SP<Window>;
using PHLWINDOWREF = Ref<Window>;
using PHLMONITORREF = Ref<Monitor>;
using PHLMONITOR = SP<Monitor>;
using PHLWORKSPACEREF = Ref<Workspace>;
namespace Render {
struct CRenderContext {};
struct SWindowTransformBuffer { SP<int> framebuffer; CBox box; bool success = true; };
struct SWindowTransformContext { PHLMONITORREF monitor; };
struct IWindowTransformer {
    virtual ~IWindowTransformer() = default;
    virtual int priority() const = 0;
    virtual bool active() const = 0;
    virtual bool allocatesOutputBuffer() const = 0;
    virtual bool blocksDirectScanout() const = 0;
    virtual CBox transformedExtents(const CBox&) const = 0;
    virtual CBox sourceBoxForOutput(const CBox&, const CBox&) const = 0;
    virtual CBox transformBoxForDamage(const CBox&) const = 0;
    virtual SWindowTransformBuffer transform(CRenderContext&, const SWindowTransformBuffer&, const SWindowTransformContext&) = 0;
};
}
#include "camera-view.inc"
static View view;
static bool selected = true;
static Vector2D slideOffset;
Vector2D workspaceOffset(const View&) { return slideOffset; }
View* viewFor(const PHLWINDOW&) { return selected ? &view : nullptr; }
bool transformed(const View* value) { return value && !value->camera.identity(value->monitor->m_position); }
View* viewFor(PHLMONITOR) { return selected ? &view : nullptr; }
View* ensureView(PHLMONITOR monitor) { return viewFor(monitor); }
static bool drag = false;
static int damageCalls = 0;
void damage(View&) { ++damageCalls; }
#include "camera-pan.inc"
#include "camera-pan-settings.inc"
struct InputManager { uint32_t mods = 64; uint32_t getModsFromAllKBs() { return mods; } };
struct Seat { struct { Ref<int> pointerFocus; } m_state; };
static auto g_pInputManager = std::make_shared<InputManager>();
static auto g_pSeatManager = std::make_shared<Seat>();
namespace State {
struct MonitorState { std::vector<PHLMONITOR> outputs; const auto& monitors() { return outputs; } };
inline auto state = std::make_shared<MonitorState>();
auto monitorState() { return state; }
}
struct IPointer { struct SAxisEvent { uint32_t source, axis; double delta; }; };
namespace Event { struct SCallbackInfo { bool cancelled = false; }; }
namespace IPC::Socket2 {
struct Server {
    struct Message { std::string name,payload; };
    int sent = 0;
    void postEvent(Message) { ++sent; }
};
inline auto server = std::make_shared<Server>();
auto sock() { return server; }
}
#include "camera-axis.inc"
static int nativeAxisCalls = 0;
bool routeScroll(PHLMONITOR monitor, double dx, double dy) { ++nativeAxisCalls; return queuePan(monitor,{dx,dy}); }
// The Python harness extracts this class directly from the production header.
#include "camera-transformer.inc"

namespace Desktop::View {
using CWindow = ::Window;
struct CWLSurface {
    SP<LogicalView> owner;
    inline static SP<CWLSurface> registered;
    SP<LogicalView> view() { return owner; }
    static SP<CWLSurface> fromResource(SP<int>) { return registered; }
};
}
struct CTexPassElement {
    struct { SP<int> surface, blurAlphaMatte; bool currentLS = false; PHLWINDOWREF blurOwner; } m_data;
};
bool isKittyWindow(PHLWINDOW window) { return window && window->kitty; }
#include "camera-kitty.inc"

bool near(Vector2D a, Vector2D b) { return (a - b).size() < 1e-6; }
bool near(CBox a, CBox b) { return near(a.pos(), b.pos()) && near(a.size(), b.size()); }
int main() {
    Camera camera{{960,540},{1920,1080},1};
    const CBox client{3000,-800,1000,600};
    for (double zoom : {.2,.3333333333,.85,1.,2.,3.}) {
        camera.zoom = zoom;
        for (Vector2D point : {Vector2D{0,0},{-4300,2700},{5120,-1920},{960,540}})
            assert(near(camera.unproject(camera.project(point)),point));
        auto visual = camera.project(client);
        assert(near(visual.size(),client.size()*zoom));
        assert(client == CBox(3000,-800,1000,600));
    }
    camera.zoom = .25;
    assert(client.intersection(CBox{{},camera.viewport}).empty());
    assert(!camera.project(client).intersection(CBox{{},camera.viewport}).empty());
    const Vector2D anchor{1440,250};
    const auto world = camera.unproject(anchor);
    for (int i = 0; i < 1000; ++i) { camera.zoomAt(.8,anchor); camera.zoomAt(.25,anchor); }
    assert(near(camera.unproject(anchor),world));
    auto point = camera.project(Vector2D{200,300});
    camera.pan({70,-90});
    assert(near(camera.project(Vector2D{200,300}),point+Vector2D(70,-90)));
    camera.zoomAt(-100,anchor); assert(camera.zoom == Camera::MIN_ZOOM);
    camera.zoomAt(100,anchor); assert(camera.zoom == Camera::MAX_ZOOM);
    const auto valid = camera.center;
    camera.zoomAt(NAN,anchor); assert(near(valid,camera.center));

    for (Vector2D cursor : {Vector2D{25,50},Vector2D{1740,800},Vector2D{960,540}}) {
        Camera from{{-2300,1800},{1920,1080},.377149515625};
        auto target = from; target.zoomAt(.85,cursor);
        const auto world = from.unproject(cursor);
        for (int frame=0; frame<=144; ++frame) {
            auto presented = interpolateCamera(from,target,double(frame)/144.,cursor);
            assert(near(presented.project(world),cursor));
            assert(presented.zoom >= from.zoom && presented.zoom <= target.zoom);
        }
        // A new wheel event anchors the point currently under the new cursor,
        // including when the preceding animation has only partly completed.
        auto halfway = interpolateCamera(from,target,.4,cursor);
        auto next = halfway; const auto moved = cursor+Vector2D{17,-12};
        next.zoomAt(1.,moved);
        for (int frame=0; frame<=60; ++frame)
            assert(near(interpolateCamera(halfway,next,frame/60.,moved).project(halfway.unproject(moved)),moved));
    }
    Camera overview{{2369.101101,766.929391},{1920,1200},.377149515625};
    const CBox usable{87,64,1809,1112}, focusWindow{3000,-800,1000,600};
    FocusBookmark bookmark;
    assert(!bookmark.toggle(overview,{},usable) && !bookmark.returnTo);
    auto focused = bookmark.toggle(overview,focusWindow,usable);
    assert(focused && focused->zoom == 1. && bookmark.returnTo);
    assert(near(focused->project(focusWindow.middle()),usable.middle()));
    // Restoring works even after closing the window or manually panning.
    auto changed = *focused; changed.pan({83,-34}); changed.zoomAt(.85,{100,200});
    auto restored = bookmark.toggle(changed,{},usable);
    assert(restored && restored->zoom == overview.zoom && near(restored->center,overview.center) && !bookmark.returnTo);
    auto large = bookmark.toggle(overview,{-4000,500,4000,2000},usable);
    assert(large && large->zoom < 1. && large->project(CBox{-4000,500,4000,2000}).w <= usable.w+.001);
    assert(large->project(CBox{-4000,500,4000,2000}).h <= usable.h+.001);
    auto resized = *large; resized.viewport = {2560,1440};
    restored = bookmark.toggle(resized,{},{});
    assert(restored->viewport == resized.viewport && restored->center == overview.center && restored->zoom == overview.zoom);
    for (int rate : {60,120,144}) for (Vector2D direction : {Vector2D{1200,0},Vector2D{-1200,0},Vector2D{0,900},Vector2D{0,-900}}) {
        Camera from{{-300,700},{1920,1200},.377149515625}, target = from;
        target.center += direction;
        double peak = 0.;
        for (int frame=0; frame<=std::ceil(rate*NAVIGATION_DURATION); ++frame) {
            const auto t = double(frame)/rate/NAVIGATION_DURATION;
            auto presented = animateCamera(from,target,t,CameraMotion::NAVIGATION);
            const auto along = (presented.center-from.center).size()/direction.size();
            peak = std::max(peak,along);
            assert(presented.zoom == from.zoom);
            assert(near(presented.center,from.center+direction*navigationProgress(t)));
            // Click focus stays bounded; wheel zoom remains anchored at every frame.
            auto focus = animateCamera(from,target,t,CameraMotion::FOCUS);
            assert((focus.center-from.center).size() <= direction.size()+1e-6);
            auto zoomed = from; zoomed.zoomAt(.85,anchor);
            assert(near(animateCamera(from,zoomed,t,CameraMotion::STANDARD,anchor).project(from.unproject(anchor)),anchor));
        }
        assert(peak > 1.015 && peak < 1.02);
        assert(near(animateCamera(from,target,0.,CameraMotion::NAVIGATION).center,from.center));
        assert(near(animateCamera(from,target,1.,CameraMotion::NAVIGATION).center,target.center));
        const auto interrupted = animateCamera(from,target,.4,CameraMotion::NAVIGATION);
        assert(near(animateCamera(interrupted,from,0.,CameraMotion::NAVIGATION).center,interrupted.center));
    }

    auto window = std::make_shared<Window>();
    auto monitor = std::make_shared<Monitor>();
    WindowCamera transformer(window);
    auto pixels = std::make_shared<int>(42);
    Render::CRenderContext ctx;
    view.monitor = monitor;
    for (Vector2D origin : {Vector2D{0,0},{-1920,0},{1920,-540}}) {
        monitor->m_position = origin;
        for (double scale : {1.,1.25,1.5,2.}) for (double zoom : {.2,.5,.85,1.,2.,3.})
        for (Vector2D offset : {Vector2D{},Vector2D{960,0},Vector2D{-1920,0},Vector2D{0,-1080}}) {
            slideOffset = offset;
            monitor->m_scale = scale;
            view.camera = {origin+Vector2D{960+200,540-100},{1920,1080},zoom};
            const CBox base{-400*scale,-300*scale,1200*scale,800*scale};
            const CBox source = base.copy().translate(offset*scale);
            const Render::SWindowTransformBuffer input{pixels,source};
            auto output = transformer.transform(ctx,input,{monitor});
            auto expected = view.camera.project(base.copy().scale(1/scale).translate(origin)).translate(offset).scale(scale);
            assert(near(output.box,expected));
            assert(output.framebuffer == input.framebuffer && *output.framebuffer == 42);
            assert(near(input.box,source));
            assert(!transformer.allocatesOutputBuffer());
            assert(transformer.blocksDirectScanout());
            CBox logical = CBox{-400,-300,1200,800}.translate(offset);
            assert(near(transformer.transformedExtents(logical),expected.copy().scale(1/scale)));
            auto damage = transformer.transformBoxForDamage(logical.copy().translate(origin));
            assert(near(damage,transformer.transformedExtents(logical).translate(origin).expand(2)));
            auto recovered = transformer.sourceBoxForOutput(transformer.transformedExtents(logical),logical);
            assert(near(recovered,logical));
        }
    }
    slideOffset = {};
    selected = false;
    Render::SWindowTransformBuffer input{pixels,client};
    assert(!transformer.active());
    assert(near(transformer.transform(ctx,input,{monitor}).box,client));
    assert(near(transformer.transformBoxForDamage(client),client));
    // The final transformed client has a blur owner and matte, without a
    // wl_surface. It must retain Kitty optics; anonymous/layer textures must not.
    auto composite = std::make_shared<CTexPassElement>();
    composite->m_data.blurOwner = window;
    composite->m_data.blurAlphaMatte = pixels;
    assert(isKittySurface(composite));
    window->kitty = false; assert(!isKittySurface(composite)); window->kitty = true;
    composite->m_data.blurAlphaMatte.reset(); assert(!isKittySurface(composite));
    composite->m_data.blurAlphaMatte = pixels;
    composite->m_data.currentLS = true; assert(!isKittySurface(composite));
    composite->m_data.currentLS = false;
    composite->m_data.surface = window->resource();
    Desktop::View::CWLSurface::registered = std::make_shared<Desktop::View::CWLSurface>();
    Desktop::View::CWLSurface::registered->owner = window;
    assert(isKittySurface(composite));
    composite->m_data.surface = std::make_shared<int>(2); assert(!isKittySurface(composite));
    // 240 input samples per second must preserve subpixels while producing
    // exactly one camera application per available output frame, at 60/120/144Hz.
    for (int rate : {60,120,144}) {
        Camera camera{{960,540},{1920,1080},.25};
        PanBatch batch;
        for (int i = 0; i < 240; ++i) {
            assert(batch.add({.125,-.0625}));
            if ((i+1)*rate/240 > i*rate/240) assert(batch.apply(camera));
        }
        assert(batch.inputs == 240 && batch.frames == uint64_t(rate));
        assert(near(camera.center,{840,600}));
        assert(!batch.apply(camera));
        assert(!batch.add({double(NAN),1.}) && !batch.add({0,0}));
        assert(batch.inputs == 240);
    }
    // Release follows screen velocity with time-based decay at any refresh rate.
    Vector2D coastReference;
    for (int rate : {60,120,144}) {
        PanInertia coast;
        coast.begin(0.);
        for (int i=1; i<=240; ++i) coast.sample({2.,-1.}, i/240.);
        assert(coast.release(1.));
        const auto speed = coast.velocity.size();
        Vector2D travel;
        int frames = 0;
        for (int i=1; i<rate*2 && coast.active; ++i) {
            travel += coast.step(1.+double(i)/rate); ++frames;
            assert(coast.velocity.size() < speed);
        }
        assert(!coast.active && frames > rate/3 && frames < rate);
        assert(travel.x > 70. && travel.x < 80. && travel.y < -35.);
        if (rate == 60) coastReference = travel;
        else assert((travel-coastReference).size() < .2);
        coast.begin(2.);
        assert(!coast.active && coast.velocity == Vector2D{});
        for (int i=1; i<=30; ++i) coast.sample({-4.,2.}, 2.+i/240.);
        assert(coast.release(2.125) && coast.velocity.x < 0.);
        assert(coast.step(2.4) == Vector2D{} && !coast.active);
        coast.begin(3.);
        for (int i=1; i<=30; ++i) coast.sample({4.,0.}, 3.+i/240.);
        assert(!coast.release(3.3)); // Pausing before releasing must not fling.
    }
    selected = true;
    view = {}; view.monitor = monitor;
    view.camera = {{960,540},{1920,1080},.5};
    view.animating = true; view.target.zoom = 2;
    for (int i=0; i<8; ++i) assert(queuePan(monitor,{.25,-.125}));
    assert(damageCalls == 1 && view.pan.inputs == 8 && view.pan.frames == 0);
    assert(near(view.camera.center,{960,540}) && !view.animating);
    panFrame(monitor);
    assert(view.pan.frames == 1 && near(view.camera.center,{956,542}));
    assert(near(view.target.center,view.camera.center) && view.target.zoom == .5);
    for(int i=0;i<100;++i) panFrame(monitor);
    assert(view.pan.frames == 1 && damageCalls == 1);
    drag = true; assert(!queuePan(monitor,{10,10})); drag = false;
    selected = false; assert(!queuePan(monitor,{10,10}));
    assert(PanPreferences::parse("",false).sensitivity == 1.15);
    assert(PanPreferences::parse(R"({"infiniteDesk":{"dragSensitivity":true}})",false).sensitivity == 1.15);
    assert(PanPreferences::parse(R"({"infiniteDesk":{"dragSensitivity":0}})",false).sensitivity == .1);
    assert(PanPreferences::parse(R"({"infiniteDesk":{"dragSensitivity":5}})",false).sensitivity == 4.);
    const auto prefs = PanPreferences::parse(R"({"infiniteDesk":{"dragSensitivity":0.5}})",true);
    assert(prefs.sensitivity == .5 && prefs.direction == -1.);
    // Real routing code: native touchpad input must bypass the socket bridge,
    // while wheels, applications and other modifiers retain their own input.
    selected = true; view = {}; view.monitor = monitor;
    view.camera = {{960,540},{1920,1080},1};
    State::state->outputs = {monitor};
    auto focus = std::make_shared<int>(9); g_pSeatManager->m_state.pointerFocus = focus;
    auto layer = std::make_shared<Layer>(); layer->m_namespace = "velora-infinite-desktop-gesture";
    auto layerResource = std::make_shared<LayerResource>(); layerResource->m_surface = focus;
    layer->m_layerSurface = layerResource; monitor->m_layerSurfaceLayers[1] = {layer};
    infiniteDesktopNativeScroll = routeScroll;
    IPointer::SAxisEvent axis{WL_POINTER_AXIS_SOURCE_FINGER,WL_POINTER_AXIS_HORIZONTAL_SCROLL,4.5};
    Event::SCallbackInfo info;
    infiniteDesktopAxis(axis,info);
    assert(info.cancelled && nativeAxisCalls == 1 && IPC::Socket2::server->sent == 0);
    assert(near(view.pan.pending,{-4.5,0.}));
    layer->m_namespace = "velora-shell-shared-widgets";
    assert(infiniteDesktopGestureFocused(monitor));
    info = {}; infiniteDesktopAxis(axis,info);
    assert(info.cancelled && nativeAxisCalls == 2 && IPC::Socket2::server->sent == 0);
    layer->m_namespace = "settings"; info = {};
    infiniteDesktopAxis(axis,info); assert(!info.cancelled && nativeAxisCalls == 2);
    assert(!infiniteDesktopGestureFocused(monitor));
    layer->m_namespace = "velora-infinite-desktop-gesture";
    nativeAxisCalls = 1; info = {};
    info = {}; axis.source = WL_POINTER_AXIS_SOURCE_WHEEL; infiniteDesktopAxis(axis,info);
    assert(!info.cancelled && nativeAxisCalls == 1);
    axis.source = WL_POINTER_AXIS_SOURCE_FINGER; g_pInputManager->mods = 68;
    infiniteDesktopAxis(axis,info); assert(!info.cancelled && nativeAxisCalls == 1);
    g_pInputManager->mods = 64; g_pSeatManager->m_state.pointerFocus = std::make_shared<int>(10);
    infiniteDesktopAxis(axis,info); assert(!info.cancelled && nativeAxisCalls == 1);
    g_pSeatManager->m_state.pointerFocus = focus; infiniteDesktopNativeScroll = nullptr;
    infiniteDesktopAxis(axis,info); assert(info.cancelled && IPC::Socket2::server->sent == 1);
    std::cout << "INFINITE_CAMERA_OK: camera, input inverse, native transformer, live framebuffer, damage, fractional outputs\n";
}
