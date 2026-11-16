"""Saved screenshot attachments and notification interactions, without personal data."""
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


class ScreenshotNotificationTests(unittest.TestCase):
    def test_capture_history_keeps_distinct_files_and_opens_the_selected_file(self):
        if not shutil.which("node"):
            self.skipTest("Node required")
        shell = (ROOT / "ShellController.qml").read_text()
        media = (ROOT / "core/NotificationMedia.js").read_text().replace(".pragma library", "")
        script = "const assert=require('node:assert/strict');\nconst NotificationMedia=(()=>{\n" + media + "\nreturn {attachment};})();\n"
        script += """
let rows=[], trackedNotificationObjects={}, notificationToastId='2', hidden=0, opened=[], invoked=0;
const notificationHistoryModel={get count(){return rows.length},get(i){return rows[i]},
 set(i,row){rows[i]=row},insert(i,row){rows.splice(i,0,row)},remove(i){rows.splice(i,1)},
 move(from,to){rows.splice(to,0,rows.splice(from,1)[0])}};
const Qt={LeftButton:1,RightButton:2,formatTime(){return '13:45'},formatDateTime(){return '13:45'},
 openUrlExternally(url){opened.push(url);return true;}};
function hideNotificationToast(){hidden++;}
"""
        for name in ("notificationCleanText", "notificationField", "notificationIconKey", "notificationTimeText",
                     "notificationActionsJson", "normalizeNotification", "upsertNotificationHistory",
                     "activateNotificationHistory", "clickNotificationToast"):
            script += function(shell, name) + "\n"
        script += """
function capture(id,path){return {id,appName:'Velora screenshot',summary:'Captura de tela',
 body:'Salvo e copiado',hints:{'x-velora-screenshot-path':path},actions:[]};}
const first=capture('1','/tmp/Prints com espaço # & <imagem> ç.png');
const second=capture('2','/tmp/second.png');
upsertNotificationHistory(first);upsertNotificationHistory(second);
assert.equal(rows.length,2,'Separate screenshots must stay in history even with identical text');
upsertNotificationHistory({...first,summary:'Captura atualizada'});
assert.equal(rows.length,2,'Replacement ID updates the attachment without duplicating it');
assert.equal(rows[0].id,'1');assert.equal(rows[0].actionable,true);
// The capture process may have exited; the saved file must still open from history.
trackedNotificationObjects={};
assert.equal(activateNotificationHistory('1'),true);
assert.deepEqual(opened,['file:///tmp/Prints%20com%20espa%C3%A7o%20%23%20%26%20%3Cimagem%3E%20%C3%A7.png']);
clickNotificationToast('1',Qt.LeftButton);
assert.equal(hidden,0,'An old displayed notification cannot dismiss a newer toast');
assert.equal(opened.length,2);
clickNotificationToast('2',Qt.RightButton);
assert.equal(opened.length,2,'Right-click dismisses without opening the image');assert.equal(hidden,1);
clickNotificationToast('2',Qt.LeftButton);
assert.equal(opened.at(-1),'file:///tmp/second.png');assert.equal(hidden,2);
const actionable={id:'3',summary:'Application',appName:'Fixture',actions:[{identifier:'default',text:'Open',invoke(){invoked++;}}]};
upsertNotificationHistory(actionable);assert.equal(rows[0].actionable,true);
assert.equal(activateNotificationHistory('3'),true);assert.equal(invoked,1);
upsertNotificationHistory({id:'4',summary:'Plain text',actions:[]});
assert.equal(rows[0].imageSource,'');assert.equal(rows[0].actionable,false);
assert.equal(activateNotificationHistory('unknown'),false);
console.log('SCREENSHOT_HISTORY_OK');
"""
        result = subprocess.run(["node", "-e", script], capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("SCREENSHOT_HISTORY_OK", result.stdout)

    def test_preview_and_real_mouse_keyboard_interaction(self):
        if not shutil.which("qs"):
            self.skipTest("Quickshell required")
        with tempfile.TemporaryDirectory(prefix="velora-notification-images-") as temporary:
            base = Path(temporary)
            for name in ("components", "features", "core", "services", "platform", "assets"):
                (base / name).symlink_to(ROOT / name, target_is_directory=True)
            source = (ROOT / "tests/fixtures/tst_notification_images.qml").read_text().replace('"../../', '"./')
            (base / "shell.qml").write_text(source)
            shutil.copy2(ROOT / "tests/fixtures/notification-preview.svg", base)
            (base / "runtime").mkdir(mode=0o700)
            env = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
                       XDG_RUNTIME_DIR=str(base / "runtime"), HOME=str(base),
                       XDG_CONFIG_HOME=str(base / "config"), XDG_DATA_HOME=str(base / "data"),
                       XDG_CACHE_HOME=str(base / "cache"), XDG_STATE_HOME=str(base / "state"))
            env.pop("WAYLAND_DISPLAY", None)
            result = subprocess.run(["qs", "-p", str(base)], env=env, capture_output=True, text=True, timeout=35)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("NOTIFICATION_IMAGES_OK", output, output)
            for error in ("NOTIFICATION_IMAGES_FAILED", "TypeError", "ReferenceError", "Binding loop", "Cannot assign"):
                self.assertNotIn(error, output, output)


if __name__ == "__main__":
    unittest.main()
