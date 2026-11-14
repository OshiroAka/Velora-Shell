#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <algorithm>
#include <array>
#include <cstdint>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <hyprutils/utils/ScopeGuard.hpp>
#include "../../native/hyprland/BarRefraction.hpp"
#include "../../native/hyprland/OpticalDamage.hpp"
using Hyprutils::Math::CRegion;
using Hyprutils::Math::CBox;
bool operator==(const CRegion& a, const CRegion& b) {
    return a.copy().subtract(b).empty() && b.copy().subtract(a).empty();
}

template<class T> using SP = std::shared_ptr<T>;
template<class T, class... A> auto makeShared(A&&... args) { return std::make_shared<T>(std::forward<A>(args)...); }
template<class T, class U> auto sc(U value) { return static_cast<T>(value); }
template<class T, class U> auto dc(U value) { return dynamic_cast<T>(value); }
void check(bool value, const char* message) { if (!value) throw std::runtime_error(message); }
#define VELORA_HAS_RENDER_CONTEXT 1
constexpr int FORMAT = 1;
struct Size { int x = 0, y = 0; };

// The backend's public setters skip redundant GL calls. External raw writes
// must not invalidate that contract. No live compositor or session is used.
struct CachedGL {
    GLuint draw = 0, read = 0;
    GLenum unit = GL_TEXTURE0;
    std::array<GLint, 4> viewport{};
    bool scissor = false;
    void bindFramebuffer(GLenum target, GLuint fb) {
        const bool d = target != GL_READ_FRAMEBUFFER, r = target != GL_DRAW_FRAMEBUFFER;
        if ((!d || draw == fb) && (!r || read == fb)) return;
        glBindFramebuffer(target, fb);
        if (d) draw = fb;
        if (r) read = fb;
    }
    void setActiveTexture(GLenum value) {
        if (unit == value) return;
        glActiveTexture(value); unit = value;
    }
    void setViewport(GLint x, GLint y, GLsizei w, GLsizei h) {
        const std::array<GLint, 4> value{x,y,w,h};
        if (viewport == value) return;
        glViewport(x,y,w,h); viewport = value;
    }
    void setCapStatus(int cap, bool enabled) {
        check(cap == GL_SCISSOR_TEST, "Unexpected cached capability");
        if (scissor == enabled) return;
        if (enabled) glEnable(cap); else glDisable(cap);
        scissor = enabled;
    }
};
namespace Render {
struct ITexture {
    GLuint id = 0;
    Size m_size;
    ITexture() { glGenTextures(1,&id); }
    ~ITexture() { glDeleteTextures(1,&id); }
    void bind() const { glBindTexture(GL_TEXTURE_2D,id); }
    void unbind() const { glBindTexture(GL_TEXTURE_2D,0); }
    void setTexParameter(GLenum name, GLint value) { glTexParameteri(GL_TEXTURE_2D,name,value); }
};
struct IFramebuffer {
    Size m_size;
    int m_drmFormat = FORMAT;
    SP<ITexture> texture = makeShared<ITexture>();
    virtual ~IFramebuffer() = default;
    SP<ITexture> getTexture() const { return texture; }
};
namespace GL {
SP<CachedGL> g_pHyprOpenGL = makeShared<CachedGL>();
struct CGLFramebuffer : IFramebuffer {
    GLuint id = 0;
    bool failAllocation = false;
    explicit CGLFramebuffer(const std::string&) { glGenFramebuffers(1,&id); }
    ~CGLFramebuffer() { glDeleteFramebuffers(1,&id); }
    GLuint getFBID() { return id; }
    bool alloc(int w, int h, int format) {
        if (failAllocation) return false;
        if (m_size.x == w && m_size.y == h && m_drmFormat == format) return true;
        auto& gl = *g_pHyprOpenGL;
        const auto draw = gl.draw, read = gl.read;
        const auto viewport = gl.viewport;
        texture->bind();
        glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,w,h,0,GL_RGBA,GL_UNSIGNED_BYTE,nullptr);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
        gl.bindFramebuffer(GL_FRAMEBUFFER,id);
        glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,texture->id,0);
        check(glCheckFramebufferStatus(GL_FRAMEBUFFER)==GL_FRAMEBUFFER_COMPLETE,"Incomplete test FBO");
        gl.bindFramebuffer(GL_READ_FRAMEBUFFER,read);
        gl.bindFramebuffer(GL_DRAW_FRAMEBUFFER,draw);
        gl.setViewport(viewport[0],viewport[1],viewport[2],viewport[3]);
        m_size = {w,h}; texture->m_size = m_size; m_drmFormat = format;
        return true;
    }
};
}
}
struct Renderer {
    void setViewport(int x,int y,int w,int h) { Render::GL::g_pHyprOpenGL->setViewport(x,y,w,h); }
    void expandBlurDamage(CRegion& damage) { damage.expand(3); }
};
Renderer renderer;
Renderer* g_pHyprRenderer = &renderer;
SP<Render::GL::CGLFramebuffer> g_clearBackdrop;
uint64_t g_clearBackdropCopies = 0, g_terminalBarMatchDraws = 0;
struct SFrameFusionBackdrop { SP<Render::GL::CGLFramebuffer> sharp, blurred; };
namespace VeloraCompat {
struct RenderContext {
    struct { SP<Render::IFramebuffer> currentFB; bool noSimplify = false; CRegion finalDamage; } m_data;
    uint64_t frame = 0;
};
auto& renderData(RenderContext& ctx) { return ctx.m_data; }
uint64_t frameStamp(RenderContext& ctx) { return ctx.frame; }
void bindFB(RenderContext& ctx, const SP<Render::IFramebuffer>& fb) {
    ctx.m_data.currentFB = fb;
    Render::GL::g_pHyprOpenGL->bindFramebuffer(GL_DRAW_FRAMEBUFFER,dc<Render::GL::CGLFramebuffer*>(fb.get())->getFBID());
}
void scissor(RenderContext&, const void*) { Render::GL::g_pHyprOpenGL->setCapStatus(GL_SCISSOR_TEST,false); }
SP<Render::GL::CGLFramebuffer> blurResult;
int blurBinding = 0;
SP<Render::ITexture> blurTexture(RenderContext& ctx, const SP<Render::IFramebuffer>& source,
        const CRegion&, SP<Render::IFramebuffer>* result = nullptr) {
    if (result) *result = blurResult;
    if (!blurResult) return nullptr;
    // Both are legal: callers must use the returned framebuffer, irrespective
    // of the work buffer/target the provider leaves bound after a nested pass.
    bindFB(ctx,blurBinding ? blurResult : source);
    return blurResult->getTexture();
}
}
namespace Render {
using CRenderContext = VeloraCompat::RenderContext;
struct CRenderPass {};
using IHyprRenderer = Renderer;
struct Window { bool kitty = true; };
struct SBlurContext { std::weak_ptr<Window> owner; };
}
struct Hook { void* m_original; };
bool g_unloading = false;
int testPadding = 0, g_opticalDamagePadding = 0;
uint64_t g_opticalDamageFrames = 0, g_opticalBlurExpansions = 0, g_staleBackdropRefreshes = 0;
using RenderPassFn = CRegion (*)(Render::CRenderPass*, Render::CRenderContext&, const CRegion&);
using BlurMainFn = SP<Render::IFramebuffer> (*)(Render::IHyprRenderer*, Render::CRenderContext&, float, const CRegion&, const Render::SBlurContext&);
CRegion receivedDamage;
bool receivedNoSimplify = false, requireFullScene = false;
CRegion originalPass(Render::CRenderPass*, Render::CRenderContext& ctx, const CRegion& damage) {
    receivedDamage = requireFullScene ? CRegion{CBox{0,0,64,64}} : damage;
    receivedNoSimplify = ctx.m_data.noSimplify;
    ctx.m_data.finalDamage = receivedDamage;
    return receivedDamage;
}
SP<Render::IFramebuffer> originalBlur(Render::IHyprRenderer*, Render::CRenderContext& ctx, float, const CRegion& damage, const Render::SBlurContext&) {
    receivedDamage = damage; return ctx.m_data.currentFB;
}
Hook passHook{reinterpret_cast<void*>(&originalPass)}, blurHook{reinterpret_cast<void*>(&originalBlur)};
Hook* g_renderPass = &passHook;
Hook* g_blurMain = &blurHook;
int nativeSamplingPadding(VeloraCompat::RenderContext&, bool = false) { return testPadding; }
bool isKittyWindow(const SP<Render::Window>& window) { return window && window->kitty; }
std::unordered_map<std::string,SP<Render::GL::CGLFramebuffer>> g_frameBackdrops;
std::unordered_map<std::string,uint64_t> g_frameBackdropStamps;
#include "production.inc"

auto framebuffer(int w,int h,std::array<float,4> color) {
    auto fb = makeShared<Render::GL::CGLFramebuffer>("test");
    fb->alloc(w,h,FORMAT);
    auto& gl = *Render::GL::g_pHyprOpenGL;
    gl.bindFramebuffer(GL_FRAMEBUFFER,fb->id);
    gl.setCapStatus(GL_SCISSOR_TEST,false);
    glClearColor(color[0],color[1],color[2],color[3]); glClear(GL_COLOR_BUFFER_BIT);
    return fb;
}
auto pixel(const SP<Render::GL::CGLFramebuffer>& fb) {
    Render::GL::g_pHyprOpenGL->bindFramebuffer(GL_READ_FRAMEBUFFER,fb->id);
    std::array<unsigned char,4> value{};
    glReadPixels(0,0,1,1,GL_RGBA,GL_UNSIGNED_BYTE,value.data());
    return value;
}
void coherent(const char* message) {
    auto& gl = *Render::GL::g_pHyprOpenGL;
    GLint draw,read,unit; std::array<GLint,4> viewport;
    glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING,&draw); glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING,&read);
    glGetIntegerv(GL_ACTIVE_TEXTURE,&unit); glGetIntegerv(GL_VIEWPORT,viewport.data());
    check(draw==GLint(gl.draw) && read==GLint(gl.read) && unit==GLint(gl.unit)
        && viewport==gl.viewport && bool(glIsEnabled(GL_SCISSOR_TEST))==gl.scissor,message);
}
int main(int argc,char** argv) {
    try {
        if (argc!=2) return 2;
        auto display=eglGetPlatformDisplay(EGL_PLATFORM_SURFACELESS_MESA,EGL_DEFAULT_DISPLAY,nullptr);
        if (!eglInitialize(display,nullptr,nullptr)) return 77;
        eglBindAPI(EGL_OPENGL_ES_API);
        const EGLint attributes[]={EGL_SURFACE_TYPE,EGL_PBUFFER_BIT,EGL_RENDERABLE_TYPE,EGL_OPENGL_ES3_BIT,
            EGL_RED_SIZE,8,EGL_GREEN_SIZE,8,EGL_BLUE_SIZE,8,EGL_ALPHA_SIZE,8,EGL_NONE};
        EGLConfig config; EGLint count;
        if (!eglChooseConfig(display,attributes,&config,1,&count) || !count) return 77;
        const EGLint contextAttributes[]={EGL_CONTEXT_CLIENT_VERSION,3,EGL_NONE};
        const auto context=eglCreateContext(display,config,EGL_NO_CONTEXT,contextAttributes);
        const EGLint surfaceAttributes[]={EGL_WIDTH,64,EGL_HEIGHT,64,EGL_NONE};
        const auto surface=eglCreatePbufferSurface(display,config,surfaceAttributes);
        if (!eglMakeCurrent(display,surface,surface,context)) return 77;
        auto& gl=*Render::GL::g_pHyprOpenGL;
        gl.setViewport(0,0,64,64);
        auto source=framebuffer(64,64,{.7F,.2F,.1F,1});
        auto blur=framebuffer(64,64,{.1F,.6F,.3F,1});
        auto other=framebuffer(64,64,{.1F,.2F,.9F,1});
        VeloraCompat::RenderContext ctx;
        const std::string mode=argv[1];
        if (mode=="textures") {
            SFrameFusionBackdrop fusion{source,blur};
            // Previous compositor draws can leave any sampler active. Repeat
            // the real bindings across sharp/blur/fusion/Kitty material paths.
            for (int iteration=0;iteration<64;++iteration) for (int unit=0;unit<5;++unit)
                for (bool match : {false,true}) for (bool useFusion : {false,true})
                    for (bool nativeBlur : {false,true}) for (int bubbles : {0,1}) {
                        gl.setActiveTexture(GL_TEXTURE0+unit);
                        materialBindings(match,useFusion,nativeBlur,source,blur->getTexture(),&fusion,bubbles);
                        coherent("Material left active texture outside the compositor cache (black sampler)");
                        // A following compositor draw must bind on the unit it
                        // requests, even when that request equals its cache.
                        gl.setActiveTexture(GL_TEXTURE0+unit);
                        other->getTexture()->bind();
                        GLint actual; glGetIntegerv(GL_ACTIVE_TEXTURE,&actual);
                        check(actual==GLint(GL_TEXTURE0+unit),"Next compositor sampler used the wrong unit");
                    }
        } else if (mode=="blur") {
            gl.setActiveTexture(GL_TEXTURE0);
            VeloraCompat::blurResult=blur;
            SP<Render::GL::CGLFramebuffer> retained;
            for (int iteration=0;iteration<12;++iteration) for (int bound : {0,1}) {
                VeloraCompat::bindFB(ctx,other);
                gl.setViewport(3,5,29,31);
                VeloraCompat::blurBinding=bound;
                const auto result=barBackdropTexture(ctx,source,{},true,&retained);
                check(result && retained,"No retained blur");
                const auto actual=pixel(retained), expected=pixel(blur);
                check(actual==expected,"Retained blur copied the bound source instead of the returned blur (wrong frame)");
                check(ctx.m_data.currentFB==other,"Blur leaked its nested render target");
                coherent("Blur copy corrupted cached GL state");
            }
            // Failure must not expose the previous successful retained image.
            retained->failAllocation = true;
            VeloraCompat::bindFB(ctx,other);
            check(barBackdropTexture(ctx,source,{},true,&retained)==blur->getTexture()
                && !retained,"A failed copy retained an obsolete blur");
            retained=source;
            VeloraCompat::blurResult.reset();
            check(!barBackdropTexture(ctx,source,{},true,&retained) && !retained,
                "A failed blur retained an obsolete image");
            check(ctx.m_data.currentFB==other,"Failure leaked the blur render target");
            coherent("Failure corrupted cached GL state");
        } else if (mode=="damage") {
            VeloraCompat::bindFB(ctx,source);
            const CRegion patch{CBox{23,0,3,4}};
            testPadding=12;
            const CRegion expectedScene{CBox{0,0,53,31}}, expectedOutput{CBox{8,0,33,19}};
            check(hkRenderPass(nullptr,ctx,patch)==expectedScene,"Scene composition omitted the second optical sampling halo");
            check(receivedDamage==expectedScene,"Expanded damage did not reach the scene planner");
            check(ctx.m_data.finalDamage==expectedOutput,"The unprepared outer halo reached presentation");
            check(receivedNoSimplify && !ctx.m_data.noSimplify,"Opaque clients culled optical sources or simplification leaked");
            requireFullScene=true;
            hkRenderPass(nullptr,ctx,patch);
            check(ctx.m_data.finalDamage==CRegion{CBox{0,0,64,64}},"A required complete scene was clipped");
            requireFullScene=false;
            ctx.m_data.noSimplify=true;
            hkRenderPass(nullptr,ctx,patch);
            check(ctx.m_data.noSimplify,"Caller simplification state was lost");
            ctx.m_data.noSimplify=false;
            auto window=makeShared<Render::Window>();
            Render::SBlurContext context{window};
            hkBlurMain(g_pHyprRenderer,ctx,1,patch,context);
            check(receivedDamage==CRegion{CBox{11,0,27,16}},"Live window blur omitted refracted/diffusion pixels outside the client");
            window->kitty=false;
            hkBlurMain(g_pHyprRenderer,ctx,1,patch,context);
            check(receivedDamage==patch,"Unrelated windows received a custom optical blur");
            testPadding=0;
            check(hkRenderPass(nullptr,ctx,patch)==patch,"Inactive optics inflated scene damage");
            testPadding=12;
            check(hkRenderPass(nullptr,ctx,{}).empty(),"Optics created damage while idle");
            g_unloading=true;
            check(hkRenderPass(nullptr,ctx,patch)==patch,"Unloading retained custom scene damage");
        } else if (mode=="frame") {
            ctx.frame=1;
            VeloraCompat::bindFB(ctx,source);
            check(captureFrame(ctx,"display-a",true,false),"Topbar capture failed");
            check(pixel(g_frameBackdrops.at("display-a"))==pixel(source),"Topbar captured the wrong source");
            ctx.frame=2;
            VeloraCompat::bindFB(ctx,blur);
            check(captureFrame(ctx,"display-a",false,true),"Sidebar capture failed");
            check(pixel(g_frameBackdrops.at("display-a"))==pixel(blur),"Sidebar reused a backdrop from an older frame");
            check(captureFrame(ctx,"display-b",true,false),"Second output capture failed");
            VeloraCompat::bindFB(ctx,other);
            check(captureFrame(ctx,"display-a",false,true),"Shared frame lookup failed");
            check(pixel(g_frameBackdrops.at("display-a"))==pixel(blur),"Same-frame source was captured twice after shading");
            other->alloc(32,32,FORMAT);
            VeloraCompat::bindFB(ctx,other);
            check(captureFrame(ctx,"display-a",false,true),"Resized output capture failed");
            check(g_frameBackdrops.at("display-a")->m_size.x==32,"Sidebar reused a backdrop with an obsolete output size");
        } else if (mode=="capture") {
            SP<Render::GL::CGLFramebuffer> captured;
            for (int size : {64,64,32,32,64}) {
                source->alloc(size,size,FORMAT);
                gl.bindFramebuffer(GL_FRAMEBUFFER,source->id);
                gl.setCapStatus(GL_SCISSOR_TEST,false);
                glClearColor(.7F,.2F,.1F,1); glClear(GL_COLOR_BUFFER_BIT);
                for (bool clipped : {true,false}) {
                    VeloraCompat::bindFB(ctx,source);
                    gl.bindFramebuffer(GL_READ_FRAMEBUFFER,other->id);
                    gl.setViewport(3,5,29,31);
                    glScissor(5,6,7,8); gl.setCapStatus(GL_SCISSOR_TEST,clipped);
                    check(captureClearBackdrop(ctx,captured),"Backdrop capture failed");
                    coherent("Capture corrupted cached bindings/viewport/scissor");
                    check(gl.draw==source->id && gl.read==other->id
                        && gl.viewport==std::array<GLint,4>{3,5,29,31} && gl.scissor==clipped,
                        "Capture failed to restore caller state");
                    gl.setCapStatus(GL_SCISSOR_TEST,false);
                    check(pixel(captured)==pixel(source),"Capture clipped or sampled a different framebuffer");
                }
            }
        } else return 2;
        check(glGetError()==GL_NO_ERROR,"Unexpected GL error in regression");
        std::cout<<"RENDER_STATE_OK "<<mode<<'\n';
    } catch (const std::exception& error) { std::cerr<<error.what()<<'\n'; return 1; }
}
