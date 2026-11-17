import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


def helper():
    loader = importlib.machinery.SourceFileLoader("terminal_rectangle", str(ROOT / "scripts/infinite-desktop"))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


class TerminalRectangleTests(unittest.TestCase):
    def test_world_rectangle_reverse_drag_zoom_and_monitor_origin(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            (base / "test.cpp").write_text(r'''#include "InfiniteDesktopTerminal.hpp"
#include <cassert>
#include <iostream>
using namespace Velora::InfiniteDesk;
int main() {
    Camera pose{{-2000, 700}, {1920, 1080}, .5};
    TerminalRectangle r(pose, {1500, 800});
    r.update({300, 200});
    auto screen=r.screen(), world=r.world();
    assert(screen.x==300 && screen.y==200 && screen.w==1200 && screen.h==600);
    assert(world.x==-3320 && world.y==20 && world.w==2400 && world.h==1200);
    assert(r.usable());
    r.update({1490, 795});assert(!r.usable());
    r.update({-100, 3000});screen=r.screen();
    assert(screen.x==0 && screen.y==800 && screen.w==1500 && screen.h==280);
    Camera identity{{-960,540},{1920,1080},1};
    TerminalRectangle leftMonitor(identity,{100,200});leftMonitor.update({700,600});
    world=leftMonitor.world();assert(world.x==-1820 && world.y==200 && world.w==600 && world.h==400);
    std::cout << "TERMINAL_RECTANGLE_OK";
}
''')
            flags = subprocess.check_output(["pkg-config", "--cflags", "--libs", "hyprutils"], text=True).split()
            subprocess.run(["c++", "-std=c++23", "-I", str(ROOT / "native/hyprland"), str(base / "test.cpp"), "-o", str(base / "test"), *flags], check=True, capture_output=True)
            result = subprocess.run([str(base / "test")], check=True, capture_output=True, text=True)
            self.assertIn("TERMINAL_RECTANGLE_OK", result.stdout)

    def test_native_super_drag_preserves_windows_and_cancels_changed_camera(self):
        with tempfile.TemporaryDirectory() as directory:
            base=Path(directory)
            source=(ROOT/"native/hyprland/InfiniteDesktopCameraRuntime.hpp").read_text()
            (base/"terminal-input.inc").write_text(source[source.index("struct TerminalGesture {"):source.index("using RelativeMotionFn =")])
            flags=subprocess.check_output(["pkg-config","--cflags","--libs","hyprutils","Qt6Core"],text=True).split()
            result=subprocess.run(["c++","-std=c++23","-fPIC","-DQT_NO_KEYWORDS","-I",str(base),"-I",str(ROOT/"native/hyprland"),str(ROOT/"tests/fixtures/terminal-rectangle-input.cpp"),"-o",str(base/"test"),*flags],capture_output=True,text=True)
            self.assertEqual(result.returncode,0,result.stderr)
            result=subprocess.run([str(base/"test")],capture_output=True,text=True)
            self.assertEqual(result.returncode,0,result.stdout+result.stderr)
            self.assertIn("TERMINAL_NATIVE_INPUT_OK",result.stdout)

    def test_float_commands_are_idempotent_with_hyprland_lua_actions(self):
        # Hyprland parseToggleStr accepts enable/on and disable/off. Unknown
        # strings (including set/unset) fall back to toggle. Exercise emitted
        # dispatches in Lua instead of checking their spelling alone.
        m=helper();m._hyprland_backend="lua"
        prefix = '''
local floating = true
local count = 0
hl = {dsp = {window = {}}}
function hl.dsp.window.float(value) return value end
function hl.dispatch(value)
    assert(value.window == "address:0x12", "Wrong target")
    local action = value.action
    if action == "enable" or action == "on" then floating = true
    elseif action == "disable" or action == "off" then floating = false
    else floating = not floating end
    count = count + 1
    if count <= 2 then assert(floating, "Already-floating terminal was tiled")
    else assert(not floating, "Already-tiled window was floated") end
end
'''
        real_run=subprocess.run
        def execute(args, **kwargs):
            return real_run(["lua","-"],input=prefix+args[2],capture_output=True,text=True)
        with patch.object(m.subprocess,"run",side_effect=execute):
            m.hyprctl_batch(["dispatch setfloating address:0x12"]*2 + ["dispatch settiled address:0x12"]*2)

    def test_spawn_matches_only_new_terminal_and_never_focuses_other_workspace(self):
        for backend in ("lua", "legacy"):
            with self.subTest(backend=backend):
                m = helper();m._hyprland_backend=backend
                calls=[]; spawn=[]; queries=0
                def run(args, **kwargs):
                    spawn.append(args)
                    return subprocess.CompletedProcess(args, 0, "ok", "")
                def query(name):
                    nonlocal queries
                    if name=="monitors":return [{"name":"DP-1","x":-1920,"y":0,"activeWorkspace":{"id":4}}]
                    if name=="clients":
                        queries+=1
                        return [{"address":"0x99","mapped":True,"initialClass":"kitty","workspace":{"id":4}},
                                {"address":"0x12","mapped":True,"initialClass":"velora-drawn-fixture","workspace":{"id":4}}]
                    raise AssertionError(name)
                with patch.object(m,"hyprctl_json",side_effect=query), patch.object(m,"current_workspace",side_effect=[4,2]), patch.object(m,"enabled",return_value=True), patch.object(m.shutil,"which",return_value="/usr/bin/kitty"), patch.object(m.uuid,"uuid4") as identity, patch.object(m.subprocess,"run",side_effect=run), patch.object(m,"hyprctl_batch",side_effect=lambda commands:calls.extend(commands)):
                    identity.return_value.hex="fixture"
                    self.assertEqual(m.terminal_rectangle("DP-1",4,[-3200,20,2400,1200]),0)
                self.assertEqual(queries,1)
                self.assertEqual(len(calls),3)
                self.assertTrue(all("address:0x12" in c for c in calls))
                self.assertIn("exact -3200 20",calls[-1])
                self.assertNotIn("focuswindow"," ".join(calls))
                payload=spawn[0][-1]
                self.assertIn("velora-drawn-fixture",payload)
                if backend=="lua":
                    self.assertIn("no_initial_focus=true",payload)
                    self.assertIn("move={-1280,20}",payload)
                    self.assertIn('workspace="4 silent"',payload)

    def test_rejects_invalid_geometry_and_changed_context_without_launch(self):
        m=helper()
        with patch.object(m.subprocess,"run") as spawn:
            for box in ([0,0,float("nan"),100],[0,0,0,20],[0,0,40000,500]):
                with self.assertRaises(m.HyprlandError):m.terminal_rectangle("DP-1",1,box)
            with patch.object(m,"hyprctl_json",return_value=[{"name":"DP-1","activeWorkspace":{"id":2}}]):
                self.assertEqual(m.terminal_rectangle("DP-1",1,[0,0,640,480]),0)
            spawn.assert_not_called()

    def test_qml_preview_cancel_validation_and_launch_queue(self):
        with tempfile.TemporaryDirectory(prefix="velora-terminal-qml-") as directory:
            base=Path(directory)
            (base/"components").symlink_to(ROOT/"components",target_is_directory=True)
            (base/"shell.qml").write_text((ROOT/"tests/fixtures/terminal-rectangle.qml").read_text().replace('"../../','"./'))
            bridge=base/"bridge"
            bridge.write_text("#!/usr/bin/env python3\nimport os,sys,json,time\nwith open(os.environ['RECT_LOG'],'a') as f:f.write(json.dumps(sys.argv[1:])+'\\n')\ntime.sleep(.1)\n")
            bridge.chmod(0o755)
            env=dict(os.environ,HOME=directory,XDG_RUNTIME_DIR=directory,XDG_CONFIG_HOME=directory+"/config",XDG_CACHE_HOME=directory+"/cache",QT_QPA_PLATFORM="offscreen",QT_QUICK_BACKEND="software",VELORA_VALIDATE="1",RECT_BRIDGE=str(bridge),RECT_LOG=str(base/"records"),DBUS_SESSION_BUS_ADDRESS="unix:path=/nonexistent")
            for name in ("WAYLAND_DISPLAY","DISPLAY","HYPRLAND_INSTANCE_SIGNATURE"):env.pop(name,None)
            result=subprocess.run(["qs","-p",directory],env=env,text=True,capture_output=True,timeout=8)
            output=result.stdout+result.stderr
            self.assertEqual(result.returncode,0,output)
            self.assertIn("TERMINAL_QML_OK",output)
            for error in ("FAILED","TypeError","ReferenceError","Binding loop"):self.assertNotIn(error,output)
            records=[json.loads(line) for line in (base/"records").read_text().splitlines()]
            self.assertEqual(len(records),2)
            self.assertEqual(records[0],["terminal-rectangle","DP-1","4","-3200","20","2400","1200"])
            self.assertEqual(records[1],records[0])
