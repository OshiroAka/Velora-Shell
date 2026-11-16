"""Wallpapers leave the global composition intact even with legacy saves present."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class WallpaperGlobalStateTests(unittest.TestCase):
    def test_wallpaper_paths_picker_queue_external_updates_and_restart(self):
        executable = shutil.which("qs")
        if not executable:
            self.skipTest("Quickshell unavailable")
        # The production composition must not mount a separate persistence engine.
        composition = (ROOT / "CompositionController.qml").read_text()
        for name in ("CompositionProfileService", "WallpaperCompositionService", "profileApply", "profileUpdate"):
            self.assertNotIn(name, composition)
        with tempfile.TemporaryDirectory(prefix="velora-wallpaper-global-") as temporary:
            base = Path(temporary)
            for name in ("core", "features", "components", "services", "platform", "assets", "config"):
                (base / name).symlink_to(ROOT / name, target_is_directory=True)
            (base / "runtime").mkdir(mode=0o700)
            scripts = base / "scripts"
            scripts.mkdir()
            helper = scripts / "velora-composition-wallpaper-apply"
            helper.write_text('''#!/usr/bin/env python3
import os,pathlib,sys,time
p=pathlib.Path(os.environ["XDG_CACHE_HOME"])/"velora-shell/current_wallpaper"
time.sleep(.08)
p.write_text("static|"+sys.argv[1]+"|"+sys.argv[1])
''')
            helper.chmod(0o755)
            fixture = (ROOT / "tests/fixtures/wallpaper-global-state.qml").read_text().replace('"../../', '"./')
            (base / "shell.qml").write_text(fixture)
            configdir = base / "user-config/velora-shell"
            configdir.mkdir(parents=True)
            config = json.loads((ROOT / "config/default.json").read_text())
            config["appearance"].update(reducedMotion=True, accentMode="custom", accentColor="#abc123")
            config["profile"]["displayName"] = "Global"
            clock = config["lockPreview"]["sharedWidgets"]["items"][0]
            clock["desktop"].update(x=321, y=123)
            clock["variantId"] = "dots"
            config["lockPreview"]["scene"]["layers"] = []
            (configdir / "config.json").write_text(json.dumps(config))
            # Poisoned old saves must stay inert and byte-identical, not be migrated.
            legacy = {"profiles.json": {"schemaVersion": 1, "activeProfileId": "old", "profiles": [
                {"id": "old", "name": "Old", "composition": {"profile": {"displayName": "Poisoned"}}}]},
                "wallpaper-compositions.json": {"schemaVersion": 1, "wallpapers": {
                    "/tmp/global-a.png": {"composition": {"sharedWidgets": {"items": []}}},
                    "/tmp/global-b.png": {"composition": {"profile": {"displayName": "Poisoned"}}}}}}
            originals = {}
            for name, document in legacy.items():
                path = configdir / name
                path.write_text(json.dumps(document))
                originals[name] = (path.read_bytes(), path.stat().st_mtime_ns)
            cache = base / "cache/velora-shell"
            cache.mkdir(parents=True)
            (cache / "current_wallpaper").write_text("static|/tmp/global-a.png|/tmp/global-a.png")
            env = dict(os.environ, HOME=str(base), XDG_CONFIG_HOME=str(base / "user-config"),
                       XDG_CACHE_HOME=str(base / "cache"), XDG_STATE_HOME=str(base / "state"),
                       XDG_DATA_HOME=str(base / "data"), XDG_RUNTIME_DIR=str(base / "runtime"),
                       QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software", VELORA_VALIDATE="1")
            env.pop("WAYLAND_DISPLAY", None)
            for reload in ("0", "1"):
                result = subprocess.run([executable, "-p", str(base)], env=dict(env, VELORA_GLOBAL_RELOAD=reload),
                                        text=True, capture_output=True, timeout=22)
                output = result.stdout + result.stderr
                if os.environ.get("VELORA_GLOBAL_TEST_LOG"):
                    Path(os.environ["VELORA_GLOBAL_TEST_LOG"] + "." + reload).write_text(output)
                self.assertEqual(result.returncode, 0, output)
                self.assertIn("WALLPAPER_GLOBAL_RELOAD_OK" if reload == "1" else "WALLPAPER_GLOBAL_OK", output)
                for error in ("WALLPAPER_GLOBAL_FAILED", "ReferenceError:", "TypeError:", "Cannot assign", "Binding loop"):
                    self.assertNotIn(error, output)
                for name, original in originals.items():
                    path = configdir / name
                    self.assertEqual((path.read_bytes(), path.stat().st_mtime_ns), original)
            self.assertFalse((base / "data/velora-shell/composition-profiles").exists())
            saved = json.loads((configdir / "config.json").read_text())
            self.assertEqual(saved["lockPreview"]["sharedWidgets"]["items"][0]["desktop"]["y"], 234)
