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

    def test_removed_surfaces_and_routes_cannot_enter_legacy_lifecycle(self):
        for name in ("VeloraSidePopup.qml", "VeloraWallpaperSelector.qml", "VeloraWhatsAppPreview.qml"):
            self.assertFalse((ROOT / "components" / name).exists(), name)
        self.assertFalse((ROOT / "features/widgets/CalendarCard.qml").exists())
        shell = (ROOT / "ShellController.qml").read_text()
        for name in ("VeloraSidePopup", "VeloraWallpaperSelector", "inlineQuickPopupLoader", "inlineWallpaperLoader"):
            self.assertNotIn(name, shell)
        script = "const assert=require('node:assert/strict'); function exitFocus(){throw Error('Retired lifecycle');}\n"
        script += function(shell, "openQuickPopup") + "\n" + function(shell, "openAdaptiveBarPopup") + "\n" + function(shell, "previewAdaptiveBarPopup")
        script += "\nfor(const kind of ['time','agenda','weatherPanel','files','browser','wallpaperVisibility']) {openQuickPopup(kind,0,0);openAdaptiveBarPopup(kind,0);previewAdaptiveBarPopup(kind,0);}"
        result = subprocess.run(["node", "-e", script], capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
