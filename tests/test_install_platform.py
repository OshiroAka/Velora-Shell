"""Clean-system simulations: no host package manager or service may be executed."""
import importlib.machinery
import importlib.util
import io
import contextlib
import os
from pathlib import Path
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


def load(name):
    loader = importlib.machinery.SourceFileLoader(name.replace('-', '_'), str(ROOT / 'scripts' / name))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


def result(code=0, stdout=''):
    return SimpleNamespace(returncode=code, stdout=stdout, stderr='')


class PlatformTests(unittest.TestCase):
    def setUp(self):
        self.m = load('install-platform')
        self.args = SimpleNamespace(aur_helper='both', install_deps=True, non_interactive=True)
        self.enterContext(contextlib.redirect_stdout(io.StringIO()))
        self.enterContext(patch.object(self.m, 'arch_system', return_value=True))
        self.enterContext(patch.object(self.m.os, 'geteuid', return_value=1000))
        self.enterContext(patch.object(self.m.shutil, 'which', side_effect=lambda n: '/usr/bin/' + n))
        # All subprocesses are intercepted, including ones added to the implementation later.
        self.run = self.enterContext(patch.object(self.m, 'run', return_value=result(stdout='flathub\n')))

    def test_clean_arch_uses_full_upgrade_then_repository_and_aur_routes(self):
        with patch.object(self.m, 'repository_package', side_effect=lambda p: p != 'mpvpaper'):
            self.assertTrue(self.m.provision(['hyprland', 'flatpak', 'mpvpaper'], self.args, lambda *a: True))
        calls = [c.args[0] for c in self.run.call_args_list]
        self.assertEqual(calls[0][:4], ['sudo', 'pacman', '-Syu', '--needed'])
        self.assertTrue(any(c[:3] == ['sudo', 'pacman', '-S'] and 'hyprland' in c for c in calls))
        self.assertIn(['yay', '-S', '--needed', '--noconfirm', '--', 'mpvpaper'], calls)
        self.assertTrue(any(c[:3] == ['flatpak', 'remote-add', '--user'] for c in calls))
        self.assertFalse(any(c[:2] == ['sudo', 'yay'] or '-Sy' in c for c in calls))

    def test_missing_helpers_built_as_normal_user_without_assuming_other_helper(self):
        installed = set()
        def which(name): return '/usr/bin/' + name if name not in ('yay', 'paru') or name in installed else None
        def execute(argv, **kw):
            if argv[:2] == ['git', 'clone']:
                dest = Path(argv[-1]); dest.mkdir(); (dest / 'PKGBUILD').write_text('pkgname=' + dest.name)
            if argv[0] == 'makepkg': installed.add(Path(kw['cwd']).name)
            return result()
        with patch.object(self.m.shutil, 'which', side_effect=which), \
             patch.object(self.m, 'repository_package', return_value=False):
            self.run.side_effect = execute
            self.m.bootstrap_helper('yay', self.args)
            self.m.bootstrap_helper('paru', self.args)
        self.assertEqual(installed, {'yay', 'paru'})
        self.assertEqual(sum(c.args[0][0] == 'makepkg' for c in self.run.call_args_list), 2)
        self.assertFalse(any(c.args[0][:2] == ['sudo', 'makepkg'] for c in self.run.call_args_list))

    def test_failed_upgrade_does_not_continue_to_builds(self):
        self.run.return_value = result(1)
        with self.assertRaises(RuntimeError): self.m.provision(['hyprland'], self.args, lambda *a: True)
        self.assertEqual(self.run.call_count, 1)

    def test_unavailable_unknown_package_never_goes_to_aur(self):
        with patch.object(self.m, 'repository_package', return_value=False):
            with self.assertRaisesRegex(RuntimeError, 'repositórios'): self.m.provision(['not-a-known-package'], self.args, lambda *a: True)
        self.assertFalse(any(c.args[0][0] in ('yay', 'paru', 'git') for c in self.run.call_args_list))

    def test_no_consent_no_package_commands(self):
        self.assertFalse(self.m.provision(['hyprland'], self.args, lambda *a: False))
        self.run.assert_not_called()

    def test_root_and_missing_sudo_stop_before_mutation(self):
        with patch.object(self.m.os, 'geteuid', return_value=0):
            with self.assertRaisesRegex(RuntimeError, 'normal'): self.m.provision([], self.args, lambda *a: True)
        with patch.object(self.m.shutil, 'which', side_effect=lambda n: None if n == 'sudo' else '/bin/' + n):
            with self.assertRaisesRegex(RuntimeError, 'sudo ausente'): self.m.provision([], self.args, lambda *a: True)
        self.run.assert_not_called()

    def test_non_arch_has_explicit_boundary(self):
        with patch.object(self.m, 'arch_system', return_value=False):
            with self.assertRaisesRegex(RuntimeError, 'Arch Linux'): self.m.provision([], self.args, lambda *a: True)
        self.run.assert_not_called()

    def test_existing_broken_helper_blocks_with_rebuild_message(self):
        self.run.return_value = result(1)
        with self.assertRaisesRegex(RuntimeError, 'libalpm'): self.m.bootstrap_helper('yay', self.args)

    def test_missing_package_inventory_includes_session_infrastructure_and_helpers(self):
        self.run.return_value = result(1)
        missing = self.m.missing_packages(self.args)
        self.assertTrue({'base-devel', 'yay', 'paru', 'flatpak', 'hyprpolkitagent', 'pipewire-pulse',
                         'xdg-desktop-portal-hyprland', 'upower'}.issubset(missing))

    def test_other_network_manager_is_not_stopped(self):
        def execute(argv, **kw): return result(0 if 'systemd-networkd.service' in argv else 1)
        self.run.side_effect = execute
        with self.assertRaisesRegex(RuntimeError, 'systemd-networkd'): self.m.enable_services()
        self.assertFalse(any('enable' in c.args[0] or 'stop' in c.args[0] for c in self.run.call_args_list))

    def test_flathub_failures_do_not_report_success(self):
        self.run.return_value = result(1)
        with self.assertRaises(RuntimeError): self.m.ensure_flathub()

    def test_compositor_upgrade_requires_login(self):
        with patch.dict(os.environ, HYPRLAND_INSTANCE_SIGNATURE='test'):
            self.run.side_effect = [result(stdout='{"version":"0.57.2","commit":"new"}'),
                                    result(stdout='{"version":"0.56.2","commit":"old"}')]
            self.assertTrue(self.m.compositor_changed())

    def test_matching_compositor_does_not_require_login(self):
        with patch.dict(os.environ, HYPRLAND_INSTANCE_SIGNATURE='test'):
            self.run.return_value = result(stdout='{"version":"0.57.2","commit":"same"}')
            self.assertFalse(self.m.compositor_changed())


class BootstrapTests(unittest.TestCase):
    def test_no_python_dry_run_works_with_only_bash_and_dirname(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary); binary = base / 'bin'; binary.mkdir()
            (binary / 'dirname').symlink_to('/usr/bin/dirname')
            env = dict(os.environ, PATH=str(binary), HOME=str(base))
            run = subprocess.run(['/usr/bin/bash', str(ROOT / 'install.sh'), '--dry-run'], env=env,
                                 capture_output=True, text=True)
            self.assertEqual(run.returncode, 1)
            self.assertIn('Python ausente', run.stdout)
            self.assertIn('yay/paru', run.stdout)
            self.assertEqual(sorted(p.name for p in base.iterdir()), ['bin'])

    def test_no_python_no_pacman_fails_without_attempting_other_distribution(self):
        with tempfile.TemporaryDirectory() as temporary:
            binary = Path(temporary); (binary / 'dirname').symlink_to('/usr/bin/dirname')
            run = subprocess.run(['/usr/bin/bash', str(ROOT / 'install.sh'), '--install-deps', '--non-interactive'],
                env=dict(os.environ, PATH=str(binary)), capture_output=True, text=True)
            self.assertNotEqual(run.returncode, 0)
            self.assertIn('exige Arch', run.stderr)


class AgentStartupTests(unittest.TestCase):
    def test_agent_startup_preserves_existing_agent_and_starts_missing_one(self):
        for present in (True, False):
            with self.subTest(present=present), tempfile.TemporaryDirectory() as temporary:
                base = Path(temporary)
                (base / 'id').symlink_to('/usr/bin/id')
                (base / 'pgrep').write_text('#!/bin/bash\nexit ' + ('0' if present else '1') + '\n')
                (base / 'systemctl').write_text('#!/bin/bash\nprintf "%s\\n" "$*" > "$VELORA_TEST_CALL"\n')
                for name in ('pgrep', 'systemctl'): (base / name).chmod(0o755)
                log = base / 'called'
                run = subprocess.run(['/usr/bin/bash', str(ROOT / 'scripts/velora-session-agent')],
                    env=dict(os.environ, PATH=str(base), VELORA_TEST_CALL=str(log)), capture_output=True, text=True)
                self.assertEqual(run.returncode, 0, run.stderr)
                self.assertEqual(log.exists(), not present)
                if not present: self.assertEqual(log.read_text().strip(), '--user start hyprpolkitagent.service')
