import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class InfiniteDockTests(unittest.TestCase):
    def test_vector_apps_and_menu_share_the_same_stroke_at_dock_size(self):
        from PIL import Image
        with tempfile.TemporaryDirectory(prefix="velora-glyphs-") as directory:
            base = Path(directory)
            for name in ("components", "core"):
                (base / name).symlink_to(ROOT / name, target_is_directory=True)
            (base / "shell.qml").write_text((ROOT / "tests/fixtures/app-glyphs.qml").read_text().replace('"../../', '"./'))
            preview = base / "preview.png"
            env = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
                       XDG_RUNTIME_DIR=str(base / "runtime"), XDG_CACHE_HOME=str(base / "cache"),
                       VELORA_GLYPHS_PREVIEW=str(preview))
            env.pop("WAYLAND_DISPLAY", None)
            result = subprocess.run(["qs", "-p", str(base)], env=env, capture_output=True, text=True, timeout=10)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("GLYPHS_OK", output)
            for error in ("GLYPHS_FAILED", "TypeError", "ReferenceError"):
                self.assertNotIn(error, output)
            image = Image.open(preview).convert("RGB")
            coverage = []
            for index in range(7):
                icon = image.crop((46+84*index, 34, 74+84*index, 62))
                ink = sum(1 for red, green, blue in icon.get_flattened_data() if min(red, green, blue)>150)
                self.assertGreater(ink, 70, "App drawing must render at 28 pixels")
                coverage.append(ink)
            for ink in coverage[:4]:
                self.assertLessEqual(ink, max(coverage[4:]) * 1.15, "App glyphs must keep the same open weight as the menu")

    def test_upright_controls_fit_inside_the_corner_at_both_sizes(self):
        geometry = (ROOT / "core/InfiniteDockGeometry.js").read_text().replace(".pragma library", "")
        script = "const assert=require('assert/strict');\n" + geometry + r'''
for (const scale of [.625,.8,1]) for (const size of [.68,.78,.88])
 for (const width of [20,30,50]) for (let index=-.4;index<2.41;index+=.1) {
  const w=width*size*1.18,h=26*size*1.18;
  const p=controlPosition(index,scale,w,h);
  for (const dx of [-w/2,w/2]) for (const dy of [-h/2,h/2]) {
   const x=p.x/scale+dx,y=p.y/scale+dy;
   const inner=192-188*Math.sqrt(Math.max(0,1-Math.pow((y+128)/124,2)));
   assert(x>=0 && y<=-4,`outside the screen: ${index} ${width} ${x},${y}`);
   assert(x<=inner,`outside the curve: ${index} ${width} ${x},${y}`);
  }
 }
const centre=controlPosition(1,1,20*.88*1.18,26*.88*1.18);
const timer=controlPosition(2,1,48*.68,23*.68);
assert(timer.x-24*.68-centre.x-10*.88*1.18>10,'Timer preview is pressed against the centre icon');
'''
        result = subprocess.run(["node", "-e", script], text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_settings_pin_reorder_remove_persist_and_render_curved_workspaces(self):
        with tempfile.TemporaryDirectory(prefix="velora-dock-test-") as temporary:
            directory = Path(temporary)
            for name in ("core", "config", "components", "features", "platform", "services", "assets", "shaders"):
                (directory / name).symlink_to(ROOT / name, target_is_directory=True)
            (directory / "shell.qml").write_text((ROOT / "tests/fixtures/infinite-dock.qml").read_text().replace('"../../', '"./'))
            applications = directory / "data/applications"
            applications.mkdir(parents=True)
            (applications / "dock-test.desktop").write_text("[Desktop Entry]\nType=Application\nName=Dock Test\nExec=true\nIcon=application-x-executable\n")
            env = dict(os.environ, HOME=temporary, XDG_CONFIG_HOME=str(directory / "preferences"),
                       XDG_DATA_HOME=str(directory / "data"), XDG_DATA_DIRS=str(directory / "data"),
                       XDG_CACHE_HOME=str(directory / "cache"), XDG_STATE_HOME=str(directory / "state"),
                       XDG_RUNTIME_DIR=str(directory / "runtime"), QT_QPA_PLATFORM="offscreen",
                       QT_QUICK_BACKEND="software", VELORA_VALIDATE="1", DBUS_SESSION_BUS_ADDRESS="unix:path=/nonexistent")
            for key in ("WAYLAND_DISPLAY", "DISPLAY", "HYPRLAND_INSTANCE_SIGNATURE"):
                env.pop(key, None)
            for reload in ("0", "1"):
                process = subprocess.run(["qs", "-p", str(directory)], env=dict(env, VELORA_DOCK_RELOAD=reload),
                                         text=True, capture_output=True, timeout=20)
                output = process.stdout + process.stderr
                self.assertEqual(process.returncode, 0, output)
                self.assertIn("INFINITE_DOCK_OK", output)
                for message in ("FAIL!", "INFINITE_DOCK_FAILED", "TypeError", "ReferenceError", "Binding loop", "Cannot assign"):
                    self.assertNotIn(message, output)


if __name__ == "__main__":
    unittest.main()
