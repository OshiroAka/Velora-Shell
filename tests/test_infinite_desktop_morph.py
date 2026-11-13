import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class InfiniteDesktopMorphTests(unittest.TestCase):
    def test_fade_sequence_frame_rendering_reversal_and_reduced_motion(self):
        runner = Path('/usr/lib/qt6/bin/qmltestrunner')
        if not runner.is_file():
            self.skipTest('Qt Quick Test is required')
        with tempfile.TemporaryDirectory(prefix='velora-infinite-morph-') as directory:
            env = dict(os.environ, QT_QPA_PLATFORM='offscreen', XDG_RUNTIME_DIR=directory,
                       QSG_RHI_BACKEND='opengl', LIBGL_ALWAYS_SOFTWARE='1')
            env.pop('WAYLAND_DISPLAY', None)
            # Let offscreen Qt pick its supported renderer. Forcing the old
            # 'rhi' plugin aborts on this Qt build; GPU-only checks gate on
            # GraphicsInfo while state/Canvas checks also run in software.
            env.pop('QT_QUICK_BACKEND', None)
            result = subprocess.run([str(runner), '-input', str(ROOT / 'tests/fixtures/tst_infinite_desktop_transition.qml')],
                                    capture_output=True, text=True, env=env, timeout=20)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertNotIn('QWARN', output)


if __name__ == '__main__':
    unittest.main()
