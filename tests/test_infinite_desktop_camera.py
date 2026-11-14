import copy
import importlib.machinery
import importlib.util
import json
import os
import re
import shutil
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


def helper():
    loader = importlib.machinery.SourceFileLoader('infinite_camera', str(ROOT / 'scripts/infinite-desktop'))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


class InfiniteDesktopCameraTests(unittest.TestCase):
    def test_camera_hook_signatures_exist_in_installed_compositor(self):
        executable = shutil.which('Hyprland')
        if not executable: self.skipTest('Hyprland is not installed')
        source = (ROOT / 'native/hyprland/InfiniteDesktopCameraRuntime.hpp').read_text()
        signatures = re.findall(r'= installHook\("[^"]+", "([^"]+)"', source)
        symbols = subprocess.check_output(['nm', '-D', '--demangle', executable], text=True)
        self.assertGreaterEqual(len(signatures), 10)
        for signature in signatures:
            self.assertEqual(sum(signature in line for line in symbols.splitlines()), 1, signature)

    def test_native_transformer_preserves_live_buffers_and_world_geometry(self):
        with tempfile.TemporaryDirectory(prefix='velora-camera-test-') as directory:
            base = Path(directory)
            source = (ROOT / 'native/hyprland/InfiniteDesktopCameraRuntime.hpp').read_text()
            production = source[source.index('class WindowCamera final'):source.index('\ninline void attach(')]
            (base / 'camera-transformer.inc').write_text(production)
            (base / 'camera-view.inc').write_text(source[source.index('struct View {'):source.index('\ninline std::unordered_map')])
            start = source.index('inline double panTime(')
            (base / 'camera-pan.inc').write_text(source[start:source.index('\nstruct PanGesture', start)])
            start = source.index('struct PanPreferences {')
            (base / 'camera-pan-settings.inc').write_text(source[start:source.index('\ninline std::filesystem::path marker', start)])
            axis = (ROOT / 'native/hyprland/InfiniteDesktopInput.hpp').read_text()
            (base / 'camera-axis.inc').write_text(axis[axis.index('inline bool (*infiniteDesktopNativeScroll)'):])
            plugin = (ROOT / 'native/hyprland/plugin.cpp').read_text()
            start = plugin.index('bool isKittySurface(')
            (base / 'camera-kitty.inc').write_text(plugin[start:plugin.index('\n}\n', start) + 3])
            flags = subprocess.check_output(['pkg-config', '--cflags', '--libs', 'hyprutils', 'Qt6Core'], text=True).split()
            result = subprocess.run(['c++', '-std=c++23', '-DQT_NO_KEYWORDS', '-I', str(base), '-I', str(ROOT / 'native/hyprland'),
                str(ROOT / 'tests/fixtures/infinite-camera.cpp'), '-o', str(base / 'camera'), *flags], capture_output=True, text=True, timeout=30)
            self.assertEqual(result.returncode, 0, result.stderr)
            result = subprocess.run([str(base / 'camera')], capture_output=True, text=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn('INFINITE_CAMERA_OK', result.stdout)

    def test_zoom_pan_and_focus_do_not_send_geometry_or_cursor_commands(self):
        module = helper()
        windows = [{'address': '0x1', 'at': [3000, -800], 'size': [1000, 600]},
                   {'address': '0x2', 'at': [5000, 200], 'size': [1200, 800]}]
        before = copy.deepcopy(windows)
        with patch.object(module, 'enabled', return_value=True), \
                patch.object(module, 'active_canvas', return_value=(windows, windows[0], (960, 540))), \
                patch.object(module, 'hyprctl_batch') as batch, patch.object(module, 'inverted', return_value=False):
            module.zoom_canvas('out')
            module.pan_direction('left')
            module.focus_direction('right')
            commands = [command for call in batch.call_args_list for command in call.args[0]]
        self.assertEqual(windows, before)
        self.assertIn('dispatch velora-blur:infinite-camera zoom out', commands)
        self.assertIn('dispatch velora-blur:infinite-camera pan 180 0', commands)
        self.assertIn('dispatch velora-blur:infinite-camera center 5600.000000 600.000000', commands)
        self.assertFalse(any('windowpixel' in command or 'movecursor' in command for command in commands))

    def test_missing_native_camera_fails_without_resizing_fallback(self):
        module = helper()
        windows = [{'address': '0x1', 'at': [0, 0], 'size': [1000, 600]}]
        module._hyprland_backend = 'legacy'
        with patch.object(module, 'enabled', return_value=True), \
                patch.object(module, 'active_canvas', return_value=(windows, windows[0], (960, 540))), \
                patch.object(module.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, 'Invalid dispatcher', '')) as run:
            with self.assertRaises(module.HyprlandError): module.zoom_canvas('out')
        self.assertNotIn('resizewindowpixel', str(run.call_args))

    def test_lua_transport_calls_plugin_without_wrapping_its_return_as_an_action(self):
        module = helper()
        module._hyprland_backend = 'lua'
        with patch.object(module.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, '', '')) as run:
            module.camera_action('zoom out')
        self.assertEqual(run.call_args.args[0], ['hyprctl', 'eval', 'hl.plugin.velora.dispatch("infinite-camera","zoom out")'])

    def test_disabled_canvas_keeps_workspace_navigation(self):
        module = helper()
        with patch.object(module, 'enabled', return_value=False), patch.object(module, 'hyprctl_batch') as batch:
            module.zoom_canvas('out')
        batch.assert_called_once_with(['dispatch workspace e+1'])

    def test_gesture_monitor_selects_its_workspace_with_fractional_rotated_geometry(self):
        module = helper()
        clients = [{'address': '0x1', 'floating': True, 'workspace': {'id': 1}},
                   {'address': '0x2', 'floating': True, 'workspace': {'id': 2}}]
        def query(name):
            return {'monitors': [
                {'name': 'DP-1', 'focused': True, 'x': 0, 'y': 0, 'width': 1920, 'height': 1080},
                {'name': 'DP-2', 'x': -1920, 'y': 0, 'width': 1920, 'height': 1080, 'scale': 1.5,
                 'transform': 1, 'activeWorkspace': {'id': 2}}],
                'clients': clients, 'activewindow': clients[0]}[name]
        with patch.object(module, 'hyprctl_json', side_effect=query):
            windows, _, center = module.active_canvas('DP-2')
        self.assertEqual(windows, [clients[1]])
        self.assertEqual(center, (-1560, 640))
        module._hyprland_backend = 'legacy'
        with patch.object(module, 'hyprctl_batch') as batch:
            module.camera_action('pan 12 -6', 'DP-2')
        batch.assert_called_once_with(['dispatch velora-blur:infinite-camera @DP-2 pan 12 -6'])

    def test_empty_desktop_drag_uses_projected_client_positions(self):
        module = helper()
        def query(name):
            return {'velora-infinite-camera-status': {'enabled': True, 'views': [
                {'monitor': 'DP-1', 'active': True, 'zoom': .25, 'viewport': [1920, 1080], 'center': [960, 540]}]},
                'monitors': [{'name': 'DP-1', 'x': 0, 'y': 0}],
                'clients': [{'mapped': True, 'visible': True, 'at': [3000, -800], 'size': [1000, 600]}]}[name]
        with patch.object(module, 'hyprctl_json', side_effect=query):
            self.assertTrue(module.cursor_over_client((1595, 280)))
            self.assertFalse(module.cursor_over_client((100, 100)))
