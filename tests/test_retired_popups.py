"""Retired menu removal must preserve routing to the current controls."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


def function(source, name):
    start = source.index("    function " + name + "(")
    opening = source.index("{", start)
    depth, end = 1, opening + 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return source[start:end]


class RetiredPopupTests(unittest.TestCase):
    def test_settings_and_public_routes_use_current_controls(self):
        node = shutil.which("node")
        if not node:
            self.skipTest("Node unavailable")
        shell = (ROOT/"ShellController.qml").read_text()
        content = (ROOT/"features/editor/SettingsContent.qml").read_text()
        script = """const assert=require('node:assert/strict');
let calls=[],closed=0;
function openAdaptiveBarPopup(kind,center){calls.push([kind,center]);}
function defaultQuickPopupCenterY(){return 300;}
function exitFocus(){throw Error('Retired popup entered legacy lifecycle');}
""" + function(shell,"openQuickPopup") + """
openQuickPopup('volume',88);openQuickPopup('notifications',0);
assert.deepEqual(calls,[['volume',88],['notifications',300]]);
calls=[];
let pendingSystemTool='',page='';
const Qt={callLater(callback){callback();}};
function revealSystemTool(){calls.push(pendingSystemTool);}
const controller={setSettingsPage(value){page=value;}, hide(){closed++;}, shell:{
 openAdaptiveBarPopup,defaultQuickPopupCenterY,
 openQuickPopup(){throw Error('Settings requested a legacy popup');}}};
""" + function(content,"openTool") + """
openTool('volume');openTool('notifications');
if(page==='system'){
 assert.deepEqual(calls,['volume','notifications']);assert.equal(closed,0);
}else{
 assert.deepEqual(calls,[['volume',300],['notifications',300]]);assert.equal(closed,2);
}
"""
        result = subprocess.run([node,"-e",script],capture_output=True,text=True,timeout=10)
        self.assertEqual(result.returncode,0,result.stderr)

    def test_deleted_popup_identifiers_cannot_enter_the_old_host(self):
        node = shutil.which("node")
        if not node:
            self.skipTest("Node unavailable")
        source = (ROOT/"ShellController.qml").read_text()
        script = """const assert=require('node:assert/strict');
let settings=0,searches=0,calls=[];
let sideBarLayoutEnabled=true;
const sidebarPanels={instances:[{wifiMenu:{toggle(){calls.push('wifi');}},
bluetoothMenu:{toggle(){calls.push('bluetooth');}}}]};
function openUnifiedSettings(){settings++;}
function toggleTopSearch(){searches++;}
function defaultQuickPopupCenterY(){return 300;}
function openAdaptiveBarPopup(kind){calls.push(kind);}
function exitFocus(){throw Error('Deleted popup entered the old host');}
""" + function(source,"openQuickPopup") + """
for(const kind of ['quickSettings','settingsQuick','settings']) openQuickPopup(kind,0,0);
for(const kind of ['search','apps']) openQuickPopup(kind,0,0);
for(const kind of ['wifi','bluetooth','brightness']) openQuickPopup(kind,0,0);
assert.equal(settings,3);assert.equal(searches,2);
assert.deepEqual(calls,['wifi','bluetooth','brightness']);
"""
        result = subprocess.run([node,"-e",script],capture_output=True,text=True,timeout=10)
        self.assertEqual(result.returncode,0,result.stderr)

    def test_removed_files_and_remaining_popup_component_load(self):
        for name in ("VeloraNotificationsPopup.qml","VeloraPopupCard.qml","VeloraSearchPopup.qml"):
            self.assertFalse((ROOT/"components/popups"/name).exists(),name)
        source = (ROOT/"components/VeloraSidePopup.qml").read_text()
        for removed in ("component VolumeView:","SoundPresetButton","notificationQuery",
                        "notificationsModelOverride","AudioBars","VeloraNotificationsPopup",
                        "QuickSettingsView", "SettingsQuickView", "WifiViewAndroid",
                        "BluetoothViewAndroid", "BrightnessView", "SearchView"):
            self.assertNotIn(removed,source)
        for name in ("VeloraDashboard", "VeloraSettingsPanel", "VeloraLeftDetailPanel",
                     "VeloraRailMediaPopover", "VeloraMediaPanel", "VeloraLeftOverview"):
            self.assertFalse((ROOT/"components"/(name+".qml")).exists(), name)
        self.assertFalse((ROOT/"scripts/velora-audio-control").exists())
        executable = shutil.which("qs")
        if not executable:
            self.skipTest("Quickshell unavailable")
        with tempfile.TemporaryDirectory(prefix="velora-retired-popups-") as directory:
            base=Path(directory)
            for name in ("components","features","services","core","platform","assets","shaders"):
                (base/name).symlink_to(ROOT/name,target_is_directory=True)
            (base/"runtime").mkdir(mode=0o700)
            (base/"shell.qml").write_text('''import QtQuick
import Quickshell
import "components" as Components
ShellRoot {
    Components.VeloraTheme { id: theme }
    Components.VeloraSidePopup {
        theme: theme; width: 500; height: 600; open: false; visible: false
        popupType: "battery"
    }
    Timer { interval: 200; running: true; onTriggered: {console.info("REMAINING_POPUP_OK");Qt.quit()} }
}
''')
            env=dict(os.environ,HOME=str(base),QT_QPA_PLATFORM="offscreen",QT_QUICK_BACKEND="software",
                     VELORA_VALIDATE="1",XDG_RUNTIME_DIR=str(base/"runtime"),
                     XDG_CONFIG_HOME=str(base/"config"),XDG_STATE_HOME=str(base/"state"),
                     XDG_CACHE_HOME=str(base/"cache"))
            env.pop("WAYLAND_DISPLAY",None)
            result=subprocess.run([executable,"-p",str(base)],env=env,capture_output=True,text=True,timeout=12)
            output=result.stdout+result.stderr
            self.assertEqual(result.returncode,0,output)
            self.assertIn("REMAINING_POPUP_OK",output)
            for error in ("TypeError:","ReferenceError:","Cannot assign","is not a type","Binding loop"):
                self.assertNotIn(error,output)
