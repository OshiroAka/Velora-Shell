"""Widget choices exercise the production Settings, scene, and saved old layouts."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class WidgetVariantTests(unittest.TestCase):
    def test_legacy_layout_selection_scene_and_restart(self):
        executable = shutil.which("qs")
        if not executable:
            self.skipTest("Quickshell unavailable")
        with tempfile.TemporaryDirectory(prefix="velora-widget-variants-") as temporary:
            base = Path(temporary)
            for name in ("core", "features", "components", "services", "platform", "assets", "config", "shaders"):
                (base / name).symlink_to(ROOT / name, target_is_directory=True)
            (base / "scripts").mkdir()
            (base / "scripts/velora-theme-state").symlink_to(ROOT / "scripts/velora-theme-state")
            (base / "shell.qml").write_text((ROOT / "tests/fixtures/widget-variants.qml").read_text().replace('"../../', '"./'))
            (base / "runtime").mkdir(mode=0o700)
            config_dir = base / "user-config/velora-shell"
            config_dir.mkdir(parents=True)
            original = json.loads((ROOT / "config/default.json").read_text())
            items = original["lockPreview"]["sharedWidgets"]["items"]
            original["lockPreview"]["sharedWidgets"]["items"] = items[:6]
            items[0]["desktop"].update(x=120, y=112)
            original["lockPreview"]["scene"]["layers"] = []
            (config_dir / "config.json").write_text(json.dumps(original))
            env = dict(os.environ, HOME=str(base), XDG_RUNTIME_DIR=str(base / "runtime"),
                       XDG_CONFIG_HOME=str(base / "user-config"), XDG_CACHE_HOME=str(base / "cache"),
                       XDG_DATA_HOME=str(base / "data"), XDG_STATE_HOME=str(base / "state"),
                       QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software", VELORA_VALIDATE="1")
            env.pop("WAYLAND_DISPLAY", None)
            for reload in ("0", "1"):
                result = subprocess.run([executable, "-p", str(base)], env=dict(env, VELORA_WIDGET_RELOAD=reload),
                                        text=True, capture_output=True, timeout=15)
                output = result.stdout + result.stderr
                if os.environ.get("VELORA_WIDGET_TEST_LOG"):
                    Path(os.environ["VELORA_WIDGET_TEST_LOG"] + "." + reload).write_text(output)
                self.assertEqual(result.returncode, 0, output)
                self.assertIn("WIDGET_VARIANTS_RELOAD_OK" if reload == "1" else "WIDGET_VARIANTS_OK", output)
                for error in ("WIDGET_VARIANTS_FAILED", "TypeError:", "ReferenceError:", "Cannot assign", "Binding loop", "is not a function"):
                    self.assertNotIn(error, output)
