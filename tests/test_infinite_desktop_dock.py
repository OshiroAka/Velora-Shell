import os
import re
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class InfiniteDockTests(unittest.TestCase):
    def test_automatic_icon_contours_keep_alpha_and_interior_details(self):
        from PIL import Image, ImageDraw
        with tempfile.TemporaryDirectory(prefix="velora-icon-render-") as directory:
            base = Path(directory)
            shader = (ROOT / "shaders/app-outline.frag").read_text()
            shader = shader.replace("#version 440", "#version 300 es\nprecision highp float;")
            shader = shader.replace("layout(location = 0) in", "in")
            shader = re.sub(r"layout\(std140, binding = 0\) uniform buf \{.*?\} ubuf;",
                            "uniform float qt_Opacity; uniform vec2 pixelStep; uniform vec4 ink; uniform float symbolic;", shader, flags=re.S)
            shader = shader.replace("layout(binding = 1) uniform", "uniform").replace("ubuf.", "")
            (base / "icon.frag").write_text(shader)
            flags = subprocess.check_output(["pkg-config", "--cflags", "--libs", "egl", "glesv2"], text=True).split()
            subprocess.run(["c++", "-std=c++20", str(ROOT / "tests/fixtures/app-outline.cpp"),
                            "-o", str(base / "render"), *flags], check=True, capture_output=True)
            for background in [(0, 0, 0, 0), (20, 40, 180, 255)]:
                image = Image.new("RGBA", (112, 112), background)
                draw = ImageDraw.Draw(image)
                draw.rectangle((24, 24, 87, 87), fill=(240, 70, 20, 255))
                draw.rectangle((48, 40, 63, 71), fill=(255, 255, 255, 255))
                (base / "input").write_bytes(image.tobytes())
                result = subprocess.run([str(base / "render"), str(base / "icon.frag"),
                                         str(base / "input"), str(base / "output")],
                                        env=dict(os.environ, EGL_PLATFORM="surfaceless", LIBGL_ALWAYS_SOFTWARE="1"),
                                        capture_output=True, text=True, timeout=10)
                self.assertEqual(result.returncode, 0, result.stderr)
                output = Image.frombytes("RGBA", (112, 112), (base / "output").read_bytes())
                self.assertEqual(output.getpixel((35, 56))[3], 0, "Solid fill must become transparent")
                self.assertGreater(output.getpixel((24, 56))[3], 120, "Outer contour must remain")
                self.assertGreater(output.getpixel((48, 56))[3], 120, "Interior logo details must remain")
                for red, green, blue, alpha in output.get_flattened_data():
                    self.assertEqual((red, green, blue), (alpha, alpha, alpha), "Contours must use one premultiplied ink")

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
