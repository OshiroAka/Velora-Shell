#include "InfiniteDesktopCamera.hpp"
#include <cassert>
#include <iostream>
#include <memory>
#include <vector>
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
struct Monitor { Vector2D m_position; double m_scale = 1.; };
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
struct View { Camera camera; PHLMONITORREF monitor; };
static View view;
static bool selected = true;
View* viewFor(const PHLWINDOW&) { return selected ? &view : nullptr; }
bool transformed(const View* value) { return value && !value->camera.identity(value->monitor->m_position); }
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

    auto window = std::make_shared<Window>();
    auto monitor = std::make_shared<Monitor>();
    WindowCamera transformer(window);
    auto pixels = std::make_shared<int>(42);
    Render::CRenderContext ctx;
    view.monitor = monitor;
    for (Vector2D origin : {Vector2D{0,0},{-1920,0},{1920,-540}}) {
        monitor->m_position = origin;
        for (double scale : {1.,1.25,1.5,2.}) for (double zoom : {.2,.5,.85,1.,2.,3.}) {
            monitor->m_scale = scale;
            view.camera = {origin+Vector2D{960+200,540-100},{1920,1080},zoom};
            const CBox source{-400*scale,-300*scale,1200*scale,800*scale};
            const Render::SWindowTransformBuffer input{pixels,source};
            auto output = transformer.transform(ctx,input,{monitor});
            auto expected = view.camera.project(source.copy().scale(1/scale).translate(origin)).scale(scale);
            assert(near(output.box,expected));
            assert(output.framebuffer == input.framebuffer && *output.framebuffer == 42);
            assert(near(input.box,source));
            assert(!transformer.allocatesOutputBuffer());
            assert(transformer.blocksDirectScanout());
            CBox logical{-400,-300,1200,800};
            assert(near(transformer.transformedExtents(logical),view.camera.project(logical.copy().translate(origin))));
            auto damage = transformer.transformBoxForDamage(logical.copy().translate(origin));
            assert(near(damage,transformer.transformedExtents(logical).translate(origin).expand(2)));
            auto recovered = transformer.sourceBoxForOutput(transformer.transformedExtents(logical),logical);
            assert(near(recovered,logical));
        }
    }
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
    std::cout << "INFINITE_CAMERA_OK: camera, input inverse, native transformer, live framebuffer, damage, fractional outputs\n";
}
