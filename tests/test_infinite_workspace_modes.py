"""Independent workspace toggles, migration, global opt-out and QML transitions."""
import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[1]


class WorkspaceModesTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix="velora-workspace-modes-")
        self.addCleanup(self.temp.cleanup); self.base=Path(self.temp.name)
        self.env=dict(os.environ,HOME=str(self.base),XDG_CONFIG_HOME=str(self.base/"config"),XDG_RUNTIME_DIR=str(self.base/"runtime"))
        (self.base/"runtime").mkdir()
        self.config=self.base/"config/velora-shell/config.json";self.config.parent.mkdir(parents=True)
        self.config.write_text('{"infiniteDesk":{"workspaceIndependent":true}}')
        with patch.dict(os.environ,self.env):
            loader=importlib.machinery.SourceFileLoader("workspace_helper",str(ROOT/"scripts/infinite-desktop"))
            spec=importlib.util.spec_from_loader(loader.name,loader);self.module=importlib.util.module_from_spec(spec);loader.exec_module(self.module)
        # Never touch the historical /tmp marker in an isolated test.
        self.module.STATE_FILES=(self.base/"runtime/old.enabled",)
        self.workspace=1;self.calls=[]
        def query(name):
            if name=="activeworkspace":return {"id":self.workspace}
            if name=="monitors":return [{"name":"DP-1","activeWorkspace":{"id":self.workspace}}]
            raise AssertionError(name)
        self.stack=[]
        for target,kwargs in [("hyprctl_json",dict(side_effect=query)),("camera_action",dict(side_effect=lambda *args:self.calls.append(args))),
                              ("save_canvas_layout",dict(return_value=(0,str(self.workspace)))),("tile_canvas_windows",dict(return_value=0)),
                              ("restore_canvas_layout",dict(return_value=0)),("notify",dict())]:
            mock=patch.object(self.module,target,**kwargs);self.stack.append(mock);mock.start();self.addCleanup(mock.stop)
        env=patch.dict(os.environ,self.env);env.start();self.addCleanup(env.stop)

    def test_requested_sequence_and_restart_preserve_only_one_and_four(self):
        m=self.module
        m.toggle(False);self.assertTrue(m.enabled())
        self.workspace=2;self.assertFalse(m.enabled());m.toggle(False);self.assertTrue(m.enabled())
        m.toggle(False);self.assertFalse(m.enabled())
        self.workspace=1;self.assertTrue(m.enabled())
        self.workspace=4;m.toggle(False)
        for i in range(1,11):
            self.workspace=i;self.assertEqual(m.enabled(),i in (1,4),f"workspace {i}")
        # Reload reads disk, without depending on process globals or active focus.
        self.assertEqual(m.read_modes()["workspaces"],{"1":True,"4":True})
        self.workspace=4;m.toggle(False)
        self.assertEqual(m.read_modes()["workspaces"],{"1":True})
        self.assertIn(("disable 4","DP-1"),self.calls)

    def test_global_setting_can_be_disabled_without_erasing_individual_modes(self):
        m=self.module;m.toggle(False);self.workspace=4;m.toggle(False)
        self.config.write_text('{"infiniteDesk":{"workspaceIndependent":false}}')
        m.sync_state()
        for i in range(1,11):self.workspace=i;self.assertTrue(m.enabled())
        self.workspace=2;m.toggle(False)
        for i in range(1,11):self.workspace=i;self.assertFalse(m.enabled())
        self.config.write_text('{"infiniteDesk":{"workspaceIndependent":true}}')
        m.sync_state()
        for i in range(1,11):self.workspace=i;self.assertEqual(m.enabled(),i in (1,4))
        state=json.loads(m.UI_STATE_FILE.read_text());self.assertEqual(state["workspaces"],{"1":True,"4":True})

    def test_legacy_global_marker_migrates_only_current_workspace(self):
        m=self.module;m.STATE_FILES[0].touch();self.workspace=3;m.sync_state()
        self.assertEqual(m.read_modes()["workspaces"],{"3":True})
        self.workspace=2;self.assertFalse(m.enabled())
        self.workspace=3;self.assertTrue(m.enabled())

    def test_failed_camera_command_does_not_commit_a_mode(self):
        m=self.module
        with patch.object(m,"camera_action",side_effect=m.HyprlandError("workspace moved")):
            with self.assertRaises(m.HyprlandError):m.toggle(False)
        self.assertFalse(m.WORKSPACE_STATE_FILE.exists())

    def test_tiling_uses_captured_workspace_after_focus_moves(self):
        # Replace the scenario mocks with the real tile function and simulate
        # focus moving to 2 while the activation request for 1 is in flight.
        for mock in self.stack: mock.stop()
        clients=[{"address":"0x1","floating":True,"workspace":{"id":1}},
                 {"address":"0x2","floating":True,"workspace":{"id":2}}]
        with patch.object(self.module,"hyprctl_json",return_value=clients), patch.object(self.module,"hyprctl_batch") as batch:
            self.assertEqual(self.module.tile_canvas_windows(1),1)
            batch.assert_called_once_with(["dispatch settiled address:0x1"])

    def test_qml_workspace_selection_and_reversal(self):
        base=self.base
        for directory in ("core",): (base/directory).symlink_to(ROOT/directory,target_is_directory=True)
        (base/"shell.qml").write_text('''import QtQuick
import Quickshell
import "core" as Core
ShellRoot {
 Core.InfiniteDesktopWorkspaceState { id:state;workspaceId:1 }
 Core.InfiniteDesktopTransition { id:motion;active:state.active }
 property int step:0
 function check(value,message){if(!value)throw Error(message)}
 Component.onCompleted: {
  check(state.apply("enabled=1") && state.active,"legacy UI compatibility")
  state.workspaceId=2;check(state.active,"old state stays global until native upgrade")
  state.workspaceId=1
  check(state.apply(JSON.stringify({version:1,independent:true,global:false,workspaces:{1:true,4:true}})),"registry")
  for(let i=1;i<=10;i++){state.workspaceId=i;check(state.active===(i===1||i===4),"workspace "+i)}
  state.workspaceId=1
 }
 Timer {interval:70;running:true;repeat:true;onTriggered:{try {
  if(step===0){check(motion.progress>0,"opening");state.workspaceId=2}
  else if(step===1){check(!state.active,"normal desktop");state.workspaceId=1}
  else if(step===2){state.workspaceId=4;check(state.active,"four stays active")}
  else if(step===3){state.apply(JSON.stringify({version:1,independent:false,global:false,workspaces:{1:true,4:true}}));check(!state.active,"global off")}
  else if(step===4){state.workspaceId=1;check(!state.active,"global follows focus");state.apply(JSON.stringify({version:1,independent:true,global:false,workspaces:{1:true,4:true}}));check(state.active,"restore individual")}
  else if(step===5){motion.reducedMotion=true;check(motion.progress===1,"reduced motion");state.workspaceId=8;check(motion.progress===0,"normal reduced");console.info("WORKSPACE_MODES_OK");Qt.quit()}
  step++
 }catch(error){console.error("WORKSPACE_MODES_FAILED",error.message);Qt.quit()}}}
}''')
        env=dict(self.env,QT_QPA_PLATFORM="offscreen",QT_QUICK_BACKEND="software")
        env.pop("WAYLAND_DISPLAY",None)
        result=subprocess.run(["qs","-p",str(base)],env=env,text=True,capture_output=True,timeout=8)
        output=result.stdout+result.stderr
        self.assertIn("WORKSPACE_MODES_OK",output,output)
        self.assertNotIn("WORKSPACE_MODES_FAILED",output)


if __name__=="__main__":unittest.main()
