"""Inline system controls stay in Settings and keep safe monitor rollback."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class SettingsInlineTests(unittest.TestCase):
    def test_cards_controls_collapse_reversal_and_monitor_rollback(self):
        executable = shutil.which("qs")
        if not executable:
            self.skipTest("Quickshell unavailable")
        with tempfile.TemporaryDirectory(prefix="velora-settings-inline-") as directory:
            base = Path(directory)
            for name in ("core", "features", "components", "services", "platform", "assets", "config", "shaders"):
                (base / name).symlink_to(ROOT / name, target_is_directory=True)
            (base / "runtime").mkdir(mode=0o700)
            (base / "scripts").mkdir()
            helper = base / "scripts/velora-monitor-control"
            helper.write_text('''#!/usr/bin/env python3
import json,os,sys,pathlib
p=pathlib.Path(os.environ["XDG_STATE_HOME"]);p.mkdir(parents=True,exist_ok=True)
with (p/"monitor-calls").open("a") as f:f.write(sys.argv[1]+"\\n")
if sys.argv[1]=="probe":print(json.dumps([{"name":"Fixture","width":1920,"height":1080,"refreshRate":60,"scale":1,"availableModes":["1920x1080@60.00Hz","1280x720@60.00Hz"]}]))
elif sys.argv[1]=="apply":print("monitor-0123456789abcdef.json")
''')
            helper.chmod(0o755)
            (base / "shell.qml").write_text((ROOT / "tests/fixtures/settings-system-inline.qml").read_text().replace('"../../', '"./'))
            env = dict(os.environ, HOME=str(base), QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
                       VELORA_VALIDATE="1", XDG_RUNTIME_DIR=str(base / "runtime"), XDG_CONFIG_HOME=str(base / "config-user"),
                       XDG_STATE_HOME=str(base / "state"), XDG_CACHE_HOME=str(base / "cache"), XDG_DATA_HOME=str(base / "data"))
            env.pop("WAYLAND_DISPLAY", None)
            result = subprocess.run([executable, "-p", str(base)], env=env, capture_output=True, text=True, timeout=12)
            output = result.stdout + result.stderr
            if os.environ.get("VELORA_INLINE_LOG"):
                Path(os.environ["VELORA_INLINE_LOG"]).write_text(output)
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("SETTINGS_INLINE_OK", output)
            for error in ("SETTINGS_INLINE_FAILED", "TypeError:", "ReferenceError:", "Binding loop", "Cannot assign"):
                self.assertNotIn(error, output)
            calls = (base / "state/monitor-calls").read_text().splitlines()
            self.assertIn("apply", calls)
            self.assertIn("revert", calls)
            self.assertNotIn("confirm", calls)
