"""Real catalog previews, pointer actions, persistence and native grammar."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class EditorWidgetCatalogTests(unittest.TestCase):
    def test_visual_catalog_actions_history_and_persistence(self):
        self.exercise_fixture("editor-widget-catalog.qml", "EDITOR_WIDGET_CATALOG_OK", "VELORA_CATALOG_RELOAD")

    def test_selection_controls_follow_widgets_and_commit_changes(self):
        self.exercise_fixture("editor-selection-controls.qml", "EDITOR_SELECTION_CONTROLS_OK", "VELORA_SELECTION_RELOAD")

    def exercise_fixture(self, fixture_name, success_marker, reload_variable):
        if not shutil.which("qs"):
            self.skipTest("Quickshell unavailable")
        with tempfile.TemporaryDirectory(prefix="velora-widget-catalog-") as temporary:
            base = Path(temporary)
            for name in ("core", "features", "components", "services", "platform", "assets", "config", "shaders"):
                (base/name).symlink_to(ROOT/name, target_is_directory=True)
            scripts = base/"scripts"
            scripts.mkdir()
            for source in (ROOT/"scripts").iterdir():
                if source.is_file():
                    helper = scripts/source.name
                    if source.name == "velora-theme-state":
                        helper.symlink_to(source)
                    else:
                        helper.write_text('#!/usr/bin/env python3\nprint("{}")\n')
                        helper.chmod(0o755)
            (base/"shell.qml").write_text((ROOT/"tests/fixtures"/fixture_name).read_text().replace('"../../', '"./'))
            (base/"runtime").mkdir(mode=0o700)
            environment = dict(os.environ, HOME=str(base), VELORA_VALIDATE="1", QT_QPA_PLATFORM="offscreen",
                               QT_QUICK_BACKEND="software", XDG_CONFIG_HOME=str(base/"user-config"),
                               XDG_DATA_HOME=str(base/"data"), XDG_STATE_HOME=str(base/"state"),
                               XDG_CACHE_HOME=str(base/"cache"), XDG_RUNTIME_DIR=str(base/"runtime"))
            environment.pop("WAYLAND_DISPLAY", None)
            for reload in ("0", "1"):
                result = subprocess.run(["qs", "-p", str(base)], env=dict(environment, **{reload_variable: reload}),
                                        capture_output=True, text=True, timeout=16)
                output = result.stdout + result.stderr
                if os.environ.get("VELORA_CATALOG_TEST_LOG"):
                    Path(os.environ["VELORA_CATALOG_TEST_LOG"]+"."+fixture_name+"."+reload).write_text(output)
                self.assertEqual(result.returncode, 0, output)
                self.assertIn(success_marker, output)
                for error in ("EDITOR_WIDGET_CATALOG_FAILED", "EDITOR_SELECTION_CONTROLS_FAILED", "TypeError:", "ReferenceError:", "Binding loop", "Cannot assign", "FAIL!"):
                    self.assertNotIn(error, output)

    def test_native_combined_toolbar_and_catalog_parser(self):
        if not shutil.which("c++"):
            self.skipTest("C++ unavailable")
        source = (ROOT/"native/hyprland/plugin.cpp").read_text()
        start = source.index("SDispatchResult settingsConnectedDispatcher(")
        opening = source.index("{", start)
        depth, end = 1, opening+1
        while depth:
            depth += (source[end] == "{") - (source[end] == "}")
            end += 1
        program = r'''
#include <array>
#include <cassert>
#include <cmath>
#include <sstream>
#include <string>
#include <unordered_map>
struct STopbarMorph {
    float x=0,y=0,width=0,height=0,radius=0,joinSize=0;
    bool active=false;
    std::array<float,6> catalogPanel{};
};
struct SDispatchResult { bool success=true; std::string error; };
std::unordered_map<std::string,STopbarMorph> g_bottomSettings;
std::unordered_map<std::string,bool> g_settingsOnRight;
void damageAllMonitors() {}
'''+source[start:end]+r'''
int main() {
    assert(settingsConnectedDispatcher("eDP-1 1 .3 .8 .4 .1 .02 .02").success);
    assert(!g_settingsOnRight["eDP-1"]);
    assert(settingsConnectedDispatcher("eDP-1 1 .3 .8 .4 .1 .02 .02 catalog .7 .04 .3 .96 .02 .02").success);
    assert(g_bottomSettings["eDP-1"].catalogPanel[2] == .3F);
    assert(settingsConnectedDispatcher("HDMI-A-1 1 .7 .1 .3 .8 .02 .02 right").success);
    assert(g_settingsOnRight["HDMI-A-1"]);
    for (const auto& suffix : {"catalog .7 .04 0 .96 .02 .02", "catalog .7 .04 .3 -1 .02 .02", "catalog .7 .04 .3 .96 .02", "catalog .7 .04 .3 .96 .02 .02 unexpected", "left"}) {
        assert(!settingsConnectedDispatcher(std::string("eDP-1 1 .3 .8 .4 .1 .02 .02 ")+suffix).success);
        assert(g_bottomSettings["eDP-1"].catalogPanel[2] == .3F);
    }
    assert(settingsConnectedDispatcher("eDP-1 1 .3 .8 .4 .1 .02 .02").success);
    assert(g_bottomSettings["eDP-1"].catalogPanel[2] == 0.F);
    assert(settingsConnectedDispatcher("eDP-1 0").success);
    assert(!g_bottomSettings.contains("eDP-1") && g_bottomSettings.contains("HDMI-A-1"));
}
'''
        with tempfile.TemporaryDirectory(prefix="velora-catalog-parser-") as temporary:
            base = Path(temporary)
            (base/"parser.cpp").write_text(program)
            compiled = subprocess.run(["c++", "-std=c++20", str(base/"parser.cpp"), "-o", str(base/"parser")], capture_output=True, text=True, timeout=30)
            self.assertEqual(compiled.returncode, 0, compiled.stderr)
            result = subprocess.run([str(base/"parser")], capture_output=True, text=True, timeout=5)
            self.assertEqual(result.returncode, 0, result.stderr)
