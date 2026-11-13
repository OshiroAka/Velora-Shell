"""Exercise launcher feedback and startup failures without a desktop session."""
import importlib.machinery
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


class LauncherTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='velora-launcher-test-')
        self.addCleanup(temporary.cleanup)
        self.base = Path(temporary.name)
        self.scripts = self.base / 'scripts'
        self.scripts.mkdir()
        self.qs = self.base / 'qs'
        self.qs.write_text('#!/bin/sh\nif [ "$FIXTURE_RUNNING" = 1 ]; then\n'
                           'printf "Config path: %s/shell.qml\\n" "$FIXTURE_ROOT"\nfi\n')
        self.qs.chmod(0o755)
        self.preflight = self.scripts / 'preflight'
        self.preflight.write_text('import os,sys\n'
                                  'if "--runtime" in sys.argv:\n'
                                  ' print("Obrigatório ausente/incompatível: fixture-required")\n'
                                  ' sys.exit(1)\n'
                                  'print(os.environ["FIXTURE_QS"])\n')
        self.env = dict(os.environ, FIXTURE_ROOT=str(self.base), FIXTURE_QS=str(self.qs),
                        FIXTURE_RUNNING='0', WAYLAND_DISPLAY='fixture',
                        HYPRLAND_INSTANCE_SIGNATURE='fixture')

    def test_default_command_starts_and_reports_progress(self):
        shutil.copy2(ROOT / 'scripts/velora', self.scripts / 'velora')
        runner = self.scripts / 'run'
        runner.write_text('#!/bin/sh\nprintf "FIXTURE_START %s\\n" "$1"\n')
        runner.chmod(0o755)
        result = subprocess.run([str(self.scripts / 'velora')], env=self.env,
                                text=True, capture_output=True, timeout=5)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('iniciando', result.stdout)
        self.assertIn('FIXTURE_START -d', result.stdout)

    def test_existing_instance_is_reported_without_restarting(self):
        shutil.copy2(ROOT / 'scripts/velora', self.scripts / 'velora')
        result = subprocess.run([str(self.scripts / 'velora')],
                                env=dict(self.env, FIXTURE_RUNNING='1'),
                                text=True, capture_output=True, timeout=5)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('já está em execução', result.stdout)

    def test_missing_requirement_is_visible_and_returns_failure(self):
        shutil.copy2(ROOT / 'scripts/velora', self.scripts / 'velora')
        shutil.copy2(ROOT / 'scripts/run', self.scripts / 'run')
        result = subprocess.run([str(self.scripts / 'velora')], env=self.env,
                                text=True, capture_output=True, timeout=5)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('fixture-required', result.stderr)

    def test_notification_claim_accepts_empty_quickshell_listing(self):
        loader = importlib.machinery.SourceFileLoader('launcher_notifications', str(ROOT / 'scripts/velora-notifications'))
        spec = importlib.util.spec_from_loader(loader.name, loader)
        module = importlib.util.module_from_spec(spec)
        loader.exec_module(module)
        results = [SimpleNamespace(stdout='b true'), SimpleNamespace(returncode=0, stdout='u 123'),
                   SimpleNamespace(stdout='/usr/bin/qs'),
                   SimpleNamespace(stdout='No running instances for "fixture/shell.qml"\nUse --all to list all instances.')]
        with patch.object(module, 'call', side_effect=results), \
             patch.object(module.os, 'readlink', return_value='/usr/bin/dunst'):
            state = module.status()
        self.assertTrue(state['conflict'])
        self.assertEqual(state['unit'], 'dunst.service')


if __name__ == '__main__':
    unittest.main()
