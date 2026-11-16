import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class InfiniteDesktopMorphTests(unittest.TestCase):
    def test_fade_sequence_frame_rendering_reversal_and_reduced_motion(self):
        # Quickshell registers embedded QML plugins inside its own process;
        # qmltestrunner cannot resolve their native singleton dependencies.
        with tempfile.TemporaryDirectory(prefix="velora-infinite-morph-") as temporary:
            base = Path(temporary)
            for name in ("core", "components", "features", "platform", "services", "assets", "shaders"):
                (base/name).symlink_to(ROOT/name, target_is_directory=True)
            fixture=(ROOT/"tests/fixtures/tst_infinite_desktop_transition.qml").read_text()
            (base/"shell.qml").write_text(fixture.replace('"../../','"./'))
            env=dict(os.environ, HOME=temporary, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
                VELORA_VALIDATE="1", XDG_RUNTIME_DIR=str(base/"runtime"),
                XDG_CONFIG_HOME=str(base/"config"), XDG_DATA_HOME=str(base/"data"),
                XDG_STATE_HOME=str(base/"state"), XDG_CACHE_HOME=str(base/"cache"),
                DBUS_SESSION_BUS_ADDRESS="unix:path=/nonexistent")
            for key in ("WAYLAND_DISPLAY","DISPLAY","HYPRLAND_INSTANCE_SIGNATURE"):
                env.pop(key,None)
            result=subprocess.run(["qs","-p",str(base)],capture_output=True,text=True,env=env,timeout=15)
            output=result.stdout+result.stderr
            self.assertEqual(result.returncode,0,output)
            self.assertIn("INFINITE_MORPH_OK",output)
            for error in ("INFINITE_MORPH_FAILED","FAIL!","TypeError","ReferenceError","Binding loop"):
                self.assertNotIn(error,output)

    def test_sidebar_keeps_its_topbar_offset_until_workspaces_have_returned(self):
        import re
        source=(ROOT/"ShellController.qml").read_text()
        reserve=re.search(r"readonly property int barReserveWidth: ([^\n]+)",source)[1]
        host=source[source.index("exclusiveZone: root.barReserveWidth"):]
        layer=host.split("WlrLayershell.layer:",1)[1].split("WlrLayershell.namespace:",1)[0].strip()
        script=r'''
const assert=require('assert/strict');
const WlrLayer={Bottom:1,Top:2,Overlay:3};
const root={};
const infiniteDesktopTransition={effectiveActive:false};
function geometry(enabled,progress,drawer=false,whatsapp=false) {
    root.infiniteDesktopMorphProgress=progress;
    root.infiniteDesktopBarsActive=enabled;
    infiniteDesktopTransition.effectiveActive=enabled;
    const sideBarLayoutEnabled=true,barPanelWidth=63,infiniteDesktopBarsActive=enabled;
    const wantsDrawerKeyboard=drawer,whatsappKeyboard=whatsapp;
    const exclusiveZone=RESERVE_EXPRESSION;
    const sidebarLayer=LAYER_EXPRESSION;
    const surfaces=[{name:'topbar',layer:WlrLayer.Top,zone:40},
        {name:'sidebar',layer:sidebarLayer,zone:exclusiveZone}].sort((a,b)=>a.layer-b.layer);
    // Hyprland arrangeLayerArray: positive reservations are arranged first,
    // in layer order; zero-zone surfaces then use the remaining usable area.
    let usableTop=0,sidebarY=-1;
    for (const exclusive of [true,false]) for (const surface of surfaces) {
        if ((surface.zone>0)!==exclusive) continue;
        if (surface.name==='sidebar') sidebarY=usableTop;
        if (surface.name==='topbar' && surface.zone>0) usableTop+=surface.zone;
    }
    return {y:sidebarY,height:1080-sidebarY,zone:exclusiveZone,layer:sidebarLayer};
}
for (const drawer of [false,true]) for (const whatsapp of [false,true]) {
    for (const enabled of [true,false]) {
        const poses=enabled ? [0,.01,.28,.49,.5,.68,.99,1] : [1,.99,.68,.5,.49,.28,.01,0];
        for (const progress of poses) {
            const pose=geometry(enabled,progress,drawer,whatsapp);
            assert.equal(pose.y,40,`Sidebar occupies the workspace strip while enabled=${enabled} at progress=${progress}`);
            assert.equal(pose.height,1040,'Sidebar height changes when the workspace strip appears');
            assert.equal(pose.zone,enabled?0:63,'Reservation must change once with the mode');
        }
    }
}
// Quick reversals must retain the same geometry before the source icons return.
for (const [enabled,progress] of [[true,.15],[false,.15],[true,.6],[false,.6]])
    assert.equal(geometry(enabled,progress).y,40);
'''.replace("RESERVE_EXPRESSION",reserve).replace("LAYER_EXPRESSION",layer)
        result=subprocess.run(["node","-e",script],capture_output=True,text=True,timeout=10)
        self.assertEqual(result.returncode,0,result.stderr)

    def test_native_morph_damages_only_its_monitor_and_border_bands(self):
        source=(ROOT/"native/hyprland/plugin.cpp").read_text()
        def function(signature):
            start=source.index(signature)
            opening=source.index("{",start)
            depth,end=1,opening+1
            while depth:
                depth+=(source[end]=="{")-(source[end]=="}")
                end+=1
            return source[start:end]
        program=r'''#include <algorithm>
#include <cassert>
#include <cmath>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>
struct CBox { double x,y,width,height; };
struct Point { double x,y; };
struct Monitor { std::string m_name; Point m_position,m_size; };
struct Monitors { std::vector<std::shared_ptr<Monitor>> values;
 auto& monitors() { return values; } };
namespace State { Monitors state; Monitors* monitorState() { return &state; } }
struct Renderer { std::vector<CBox> boxes; void damageBox(CBox box) { boxes.push_back(box); } };
Renderer renderer; Renderer* g_pHyprRenderer=&renderer;
struct Topbar { double barHeight; };
std::unordered_map<std::string,Topbar> g_connectedTopbars;
'''
        program+=function("CBox infiniteDesktopBottomBox(")+"\n"+function("void damageInfiniteDesktopMorph(")
        program+=r'''
int main() {
 for (auto size : {Point{1920,1080},Point{1536,864},Point{800,600},Point{1080,1920}}) {
  State::state.values={std::make_shared<Monitor>(Monitor{"target",{120.5,80.25},size}),
      std::make_shared<Monitor>(Monitor{"other",{4000,0},{3840,2160}})};
  g_connectedTopbars["target"]={40/size.y};
  renderer.boxes.clear(); damageInfiniteDesktopMorph("target");
  assert(renderer.boxes.size()==2);
  double area=0;
  for (const auto& box : renderer.boxes) {
   assert(box.x==120.5 && box.width==size.x);
   assert(box.y>=80.25 && box.y+box.height<=80.25+size.y+.0001);
   area+=box.width*box.height;
  }
  assert(area<size.x*size.y*.3); // source rails have separate, existing damage
  const auto bottom=renderer.boxes[1];
  const double unit=std::min({1.,size.x/1280.,(size.y-40)/720.});
  assert(bottom.y<=80.25+size.y-128*unit);
  renderer.boxes.clear(); damageInfiniteDesktopMorph("target",182.0);
  assert(renderer.boxes.size()==2);
  assert(renderer.boxes[1].height>=std::min(size.y,186.0));
  assert(renderer.boxes[1].height<size.y); // reveal damage stays on the bottom band
  renderer.boxes.clear(); damageInfiniteDesktopMorph("absent");
  assert(renderer.boxes.empty());
 }
}
'''
        with tempfile.TemporaryDirectory(prefix="velora-morph-damage-") as temporary:
            base=Path(temporary); (base/"damage.cpp").write_text(program)
            result=subprocess.run(["c++","-std=c++20",str(base/"damage.cpp"),"-o",str(base/"damage")],capture_output=True,text=True)
            self.assertEqual(result.returncode,0,result.stderr)
            result=subprocess.run([str(base/"damage")],capture_output=True,text=True)
            self.assertEqual(result.returncode,0,result.stderr)


if __name__ == '__main__':
    unittest.main()
