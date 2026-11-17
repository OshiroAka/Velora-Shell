#include "InfiniteDesktopTerminal.hpp"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <cassert>
#include <memory>
#include <string>
#include <vector>
#include <iostream>
#include <wayland-client-protocol.h>
using namespace Velora::InfiniteDesk;
template<class T> struct Ref {
    std::shared_ptr<T> p;
    Ref()=default;Ref(std::shared_ptr<T> v):p(v){}
    auto lock() const{return p;} auto operator->()const{return p.get();}
    explicit operator bool()const{return bool(p);}
    bool operator==(const Ref&)const=default;
    bool operator==(const std::shared_ptr<T>& other)const{return p==other;}
};
struct Offset {bool animating=false;bool isBeingAnimated(){return animating;}};
struct Workspace {std::shared_ptr<Offset> m_renderOffset=std::make_shared<Offset>();int numberedID(){return 4;}};
// Match optional workspace IDs used by the production runtime.
struct IDWorkspace:Workspace {std::optional<int> numberedID(){return 4;}};
using PHLWORKSPACEREF=Ref<IDWorkspace>;
struct Monitor {Vector2D m_position{-1920,0};std::string m_name="DP-1";std::shared_ptr<IDWorkspace> m_activeWorkspace=std::make_shared<IDWorkspace>();};
using PHLMONITOR=std::shared_ptr<Monitor>;using PHLMONITORREF=Ref<Monitor>;
struct Inertia {void begin(double){}bool release(double){return false;}};
struct View {Camera camera{{-2000,700},{1920,1080},.5},from,target;PanBatch pan;Inertia inertia;bool animating=true;};
static View view;static bool active=true,canvas=true,window=false,enabled=true,drag=false;
static auto monitor=std::make_shared<Monitor>();
View* viewFor(PHLMONITOR m){return active&&m?&view:nullptr;}
View* ensureView(PHLMONITOR m){return viewFor(m);}
bool available(PHLMONITOR m){return viewFor(m);}
bool infiniteDesktopGestureFocused(PHLMONITOR){return canvas;}
struct PointerManager {Vector2D point{-1620,200};auto untransformedPosition(){return point;}};
namespace Pointer {static auto pointer=std::make_shared<PointerManager>();auto mgr(){return pointer;}}
namespace State {struct Query {Query& vec(Vector2D){return *this;}auto run(){return monitor;}};struct Monitors {Query query(){return {};}};auto monitorState(){return std::make_shared<Monitors>();}}
namespace Desktop {namespace View {enum{INPUT_EXTENTS=1,ALLOW_FLOATING=2};}struct Hit {bool windowAt(Vector2D,int){return window;}};struct Views {Hit hitTest(){return {};}};auto viewState(){return std::make_shared<Views>();}}
struct Input {uint32_t mods=64;auto getModsFromAllKBs(){return mods;}bool isConstrained(){return false;}};
static auto g_pInputManager=std::make_shared<Input>();
struct IPointer {struct SButtonEvent{uint32_t button,state;};};
struct IKeyboard {struct SKeyEvent{uint32_t keycode;wl_keyboard_key_state state;};};
namespace Event {struct SCallbackInfo{bool cancelled=false;};}
struct CHyprSignalListener{};
namespace IPC::Socket2 {struct Socket {struct Message{std::string name,payload;};std::vector<Message> events;void postEvent(Message m){events.push_back(m);}};static Socket socket;auto sock(){return &socket;}}
struct PanPreferences {double sensitivity=1,direction=1;};
PanPreferences panPreferences(){return {};}
struct PanGesture {PHLMONITORREF monitor;PHLWORKSPACEREF workspace;PanPreferences prefs;Vector2D last;uint32_t button;};
static std::optional<PanGesture> panGesture;static bool focusButtonHeld=false,relativePanMotion=false;static uint64_t focusPresses=0;static std::string focusResult;
bool focusClick(PHLMONITOR,const Vector2D&){return false;}
bool panGestureActive(){return false;}
double panTime(){return 0;}
void damage(View&){}
void queuePan(PHLMONITOR,Vector2D,bool){}
#include "terminal-input.inc"
std::string phase(){return QJsonDocument::fromJson(QByteArray::fromStdString(IPC::Socket2::socket.events.back().payload)).object()["phase"].toString().toStdString();}
void button(uint32_t b,uint32_t state,bool consumed){Event::SCallbackInfo info;panButton({b,state},info);assert(info.cancelled==consumed);}
int main(){
    button(272,1,true);assert(terminalGesture&&phase()=="begin");
    Event::SCallbackInfo motion;panMotion({-420,800},motion);assert(motion.cancelled&&phase()=="update");
    Pointer::pointer->point={-420,800};button(272,0,true);assert(!terminalGesture&&phase()=="end");
    g_pInputManager->mods=0;button(272,1,false);assert(!terminalGesture);
    g_pInputManager->mods=64;window=true;button(272,1,false);assert(!terminalGesture);
    window=false;canvas=false;button(272,1,false);assert(!terminalGesture);
    canvas=true;button(272,1,true);
    Event::SCallbackInfo key;terminalKey({1,WL_KEYBOARD_KEY_STATE_PRESSED},key);assert(key.cancelled&&phase()=="cancel");
    Event::SCallbackInfo release;terminalKey({1,WL_KEYBOARD_KEY_STATE_RELEASED},release);assert(release.cancelled);
    button(272,0,true);assert(!terminalButtonHeld);
    button(272,1,true);active=false;button(272,0,true);assert(phase()=="cancel"&&!terminalGesture);
    active=true;button(272,1,true);view.camera.zoom=1;button(272,0,true);assert(phase()=="cancel");
    button(272,1,true);button(272,0,true);assert(phase()=="cancel");
    std::cout<<"TERMINAL_NATIVE_INPUT_OK";
}
