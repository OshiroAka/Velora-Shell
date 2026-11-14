import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class BarMaterialTests(unittest.TestCase):
    def test_legacy_attached_panels_keep_the_bar_tint_with_native_material(self):
        if not shutil.which("node"):
            self.skipTest("Node unavailable")
        source = (ROOT / "ShellController.qml").read_text()
        functions = []
        for name in ["sidebarBarMaterialColor", "batteryNeutralPanelColor", "quickPopupSurfaceGlass"]:
            match = re.search(r"    function " + name + r"\([^)]*\)\s*\{", source)
            self.assertIsNotNone(match, name)
            end, depth = match.end(), 1
            while depth:
                depth += (source[end] == "{") - (source[end] == "}")
                end += 1
            functions.append(source[match.start():end])
        script = "const assert=require('assert/strict'); let root={};\n" + "\n".join(functions)
        script += """
for (const nativeBarMaterial of [true,false]) {
    root.composition={nativeBarMaterial,unifiedBarSurface:'bar-tint'};
    for (const type of ['battery','search','agenda','volume','notifications','wifi'])
        assert.equal(quickPopupSurfaceGlass(type),'bar-tint',type);
}
"""
        result = subprocess.run(["node", "-e", script], text=True, capture_output=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_reload_generation_rejects_stale_bubbles_and_keeps_current_shapes(self):
        if not shutil.which("c++"):
            self.skipTest("C++ unavailable")
        source = (ROOT / "native/hyprland/plugin.cpp").read_text()
        start = source.index("bool acceptBarBubbleEpoch(")
        opening = source.index("{", start)
        depth, end = 1, opening + 1
        while depth:
            depth += (source[end] == "{") - (source[end] == "}")
            end += 1
        header = str(ROOT / "native/hyprland/BarBubble.hpp")
        program = '#include "' + header + '"\n#include <unordered_map>\n#include <cassert>\n'
        program += 'std::unordered_map<std::string,std::unordered_map<std::string,SBarBubble>> g_barBubbles;\n'
        program += 'std::unordered_map<std::string,std::uint64_t> g_barBubbleEpochs;\n' + source[start:end]
        program += r'''
int main() {
    g_barBubbles["eDP-1|sidebar"]["old"]={};
    assert(acceptBarBubbleEpoch("eDP-1|sidebar",100));
    assert(!g_barBubbles.contains("eDP-1|sidebar"));
    g_barBubbles["eDP-1|sidebar"]["current"]={};
    assert(acceptBarBubbleEpoch("eDP-1|sidebar",100));
    assert(g_barBubbles["eDP-1|sidebar"].contains("current"));
    assert(!acceptBarBubbleEpoch("eDP-1|sidebar",99));
    assert(g_barBubbles["eDP-1|sidebar"].contains("current"));
    assert(acceptBarBubbleEpoch("HDMI-A-1|sidebar",99));
    assert(g_barBubbles["eDP-1|sidebar"].contains("current"));
    assert(acceptBarBubbleEpoch("eDP-1|sidebar",101));
    assert(!g_barBubbles.contains("eDP-1|sidebar"));
    assert(!parseBarBubbleEpoch("18446744073709551616"));
    assert(parseBarBubble("eDP-1 sidebar legacy 0")->epoch==0);
    assert(parseBarBubble("eDP-1 sidebar 101_bubble 0")->epoch==101);
}
'''
        with tempfile.TemporaryDirectory(prefix="velora-bubble-epochs-") as directory:
            base = Path(directory)
            (base / "epoch.cpp").write_text(program)
            compiled = subprocess.run(["c++", "-std=c++20", str(base / "epoch.cpp"), "-o", str(base / "epoch")],
                                      capture_output=True, text=True, timeout=30)
            self.assertEqual(compiled.returncode, 0, compiled.stderr)
            result = subprocess.run([str(base / "epoch")], capture_output=True, text=True, timeout=5)
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_connected_panels_and_desktop_wave_render_without_clipping_or_overlap(self):
        if not shutil.which("c++") or not shutil.which("pkg-config"):
            self.skipTest("C++/EGL toolchain unavailable")
        flags = subprocess.run(["pkg-config", "--cflags", "--libs", "egl", "glesv2"],
                               capture_output=True, text=True)
        if flags.returncode:
            self.skipTest("EGL/GLES development files unavailable")
        source = (ROOT / "native/hyprland/plugin.cpp").read_text()
        with tempfile.TemporaryDirectory(prefix="velora-bar-render-") as temporary:
            directory = Path(temporary)
            shaders = []
            for name in ["LIQUID_GLASS_VERTEX", "LIQUID_GLASS_FRAGMENT", "OPTICAL_BLUR_FRAGMENT"]:
                match = re.search(name + r' = R"GLSL\((.*?)\)GLSL";', source, re.S)
                self.assertIsNotNone(match, name)
                path = directory / name
                path.write_text(match.group(1))
                shaders.append(str(path))
            binary = directory / "bar-material"
            compiled = subprocess.run(["c++", "-std=c++20", str(ROOT / "tests/fixtures/bar-material.cpp"),
                                       "-o", str(binary), *flags.stdout.split()],
                                      capture_output=True, text=True, timeout=60)
            self.assertEqual(compiled.returncode, 0, compiled.stderr)
            environment = dict(os.environ, EGL_PLATFORM="surfaceless", LIBGL_ALWAYS_SOFTWARE="1")
            rendered = subprocess.run([str(binary), *shaders], env=environment,
                                      capture_output=True, text=True, timeout=30)
            if rendered.returncode == 77:
                self.skipTest("Surfaceless EGL unavailable")
            self.assertEqual(rendered.returncode, 0, rendered.stderr)
            environment["VELORA_TEST_OPTICAL_JOINS"] = "1"
            optical = subprocess.run([str(binary), *shaders], env=environment,
                                     capture_output=True, text=True, timeout=30)
            self.assertEqual(optical.returncode, 0, optical.stderr)
