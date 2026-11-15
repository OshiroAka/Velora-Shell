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
