import json
import os
from pathlib import Path
import subprocess
import shutil
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/velora-monitor-control"


class MonitorControlTests(unittest.TestCase):
    def test_compact_panel_keeps_controls_and_loops_without_hover(self):
        if not shutil.which("qs"):
            self.skipTest("Quickshell is required")
        with tempfile.TemporaryDirectory(prefix="velora-monitor-compact-") as directory:
            base=Path(directory)
            for name in ("components","core","features","platform","services","assets"):
                (base/name).symlink_to(ROOT/name,target_is_directory=True)
            (base/"scripts").mkdir()
            (base/"scripts/velora-monitor-control").symlink_to(SCRIPT)
            (base/"bin").mkdir()
            fake=base/"bin/hyprctl"
            data=[{"name":"eDP-1","width":1920,"height":1200,"refreshRate":60,"scale":1,"availableModes":["1920x1200@60.00Hz"]},
                  {"name":"HDMI-A-1","width":1920,"height":1080,"refreshRate":60,"scale":1,"availableModes":["1920x1080@60.00Hz"]}]
            fake.write_text("#!/usr/bin/env python3\nprint("+repr(json.dumps(data))+")\n")
            fake.chmod(0o700)
            (base/"runtime").mkdir(mode=0o700)
            (base/"shell.qml").write_text((ROOT/"tests/fixtures/monitor-compact.qml").read_text().replace('"../../','"./'))
            env=dict(os.environ,QT_QPA_PLATFORM="offscreen",QT_QUICK_BACKEND="software",VELORA_VALIDATE="1",
                XDG_RUNTIME_DIR=str(base/"runtime"),XDG_CONFIG_HOME=str(base/"config"),XDG_STATE_HOME=str(base/"state"),
                XDG_CACHE_HOME=str(base/"cache"),PATH=str(base/"bin")+os.pathsep+os.environ["PATH"])
            env.pop("WAYLAND_DISPLAY",None)
            result=subprocess.run(["qs","-p",str(base)],env=env,text=True,capture_output=True,timeout=12)
            output=result.stdout+result.stderr
            self.assertEqual(result.returncode,0,output)
            self.assertIn("MONITOR_COMPACT_OK",output)
            for error in ("FAILED","TypeError","ReferenceError","Binding loop","Cannot assign"):
                self.assertNotIn(error,output)

    def test_mirror_confirm_and_revert_with_fake_hyprland(self):
        with tempfile.TemporaryDirectory(prefix="velora-monitor-") as temporary:
            base = Path(temporary)
            fake = base / "hyprctl"
            fake.write_text('''#!/usr/bin/env python3
import json,os,sys
from pathlib import Path
if sys.argv[1:4] == ["-j", "monitors", "all"]:
    print(json.dumps([
        {"name":"eDP-1","width":1920,"height":1200,"refreshRate":60,"x":0,"y":0,"scale":1,"availableModes":["1920x1200@60.00Hz"],"mirrorOf":"none"},
        {"name":"HDMI-A-1","width":1920,"height":1080,"refreshRate":60,"x":1920,"y":0,"scale":1,"availableModes":["1920x1080@60.00Hz"],"mirrorOf":"none"}]))
elif sys.argv[1:3] == ["keyword", "monitor"]:
    with open(os.environ["MONITOR_LOG"], "a") as stream: stream.write(sys.argv[3] + "\\n")
    print("ok")
else: sys.exit(2)
''')
            fake.chmod(0o700)
            log = base / "commands.log"
            env = dict(os.environ, PATH=str(base) + os.pathsep + os.environ["PATH"],
                       XDG_RUNTIME_DIR=str(base), MONITOR_LOG=str(log))

            def run(*args):
                return subprocess.run([str(SCRIPT), *args], env=env, text=True,
                                      capture_output=True, timeout=8, check=True).stdout.strip()

            token = run("apply", "mirror", "eDP-1", "1920x1200@60.00", "1.25")
            self.assertTrue(token.startswith("monitor-"))
            self.assertIn("HDMI-A-1,preferred,auto,1,mirror,eDP-1", log.read_text())
            run("revert", token)
            self.assertIn("HDMI-A-1,1920x1080@60.00,1920x0,1", log.read_text())
            token = run("apply", "extend", "eDP-1", "1920x1200@60.00", "1.00")
            run("confirm", token)
            self.assertFalse((base / "velora-shell/monitor-pending" / token).exists())


if __name__ == "__main__":
    unittest.main()
