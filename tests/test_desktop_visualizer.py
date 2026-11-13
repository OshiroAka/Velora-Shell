"""Native desktop response and publication timing, isolated from real audio."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]

class DesktopVisualizerTests(unittest.TestCase):
    def test_absolute_dynamics_onsets_decay_and_frequency_coverage(self):
        if not shutil.which('c++'):
            self.skipTest('C++ unavailable')
        with tempfile.TemporaryDirectory(prefix='velora-desktop-audio-') as directory:
            binary=str(Path(directory)/'response')
            flags=subprocess.check_output(['pkg-config','--cflags','--libs','fftw3f'],text=True).split()
            result=subprocess.run(['c++','-std=c++23','-Wall','-Wextra','-Wconversion',
                '-I',str(ROOT/'native/visualizer'),str(ROOT/'tests/fixtures/desktop-response.cpp'),
                '-o',binary,*flags],text=True,capture_output=True,timeout=30)
            self.assertEqual(result.returncode,0,result.stderr)
            result=subprocess.run([binary],text=True,capture_output=True,timeout=5)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertIn('DESKTOP_RESPONSE_OK',result.stdout)
            print(result.stdout.strip())

    def test_desktop_publication_follows_display_frames_and_stops_at_rest(self):
        qs=shutil.which('qs')
        if not qs:self.skipTest('Quickshell unavailable')
        with tempfile.TemporaryDirectory(prefix='velora-desktop-pacing-') as directory:
            base=Path(directory)
            for name in ('components','core','platform','assets'):
                (base/name).symlink_to(ROOT/name,target_is_directory=True)
            (base/'runtime').mkdir(mode=0o700)
            (base/'shell.qml').write_text((ROOT/'tests/fixtures/desktop-material-pacing.qml').read_text().replace('"../../','"./'))
            env=dict(os.environ,QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software',VELORA_VALIDATE='1',
                XDG_RUNTIME_DIR=str(base/'runtime'),XDG_CACHE_HOME=str(base/'cache'))
            env.pop('WAYLAND_DISPLAY',None)
            result=subprocess.run([qs,'-p',str(base)],env=env,text=True,capture_output=True,timeout=8)
            output=result.stdout+result.stderr
            self.assertEqual(result.returncode,0,output)
            self.assertIn('DESKTOP_MATERIAL_PACING_OK',output)
            for error in ('DESKTOP_MATERIAL_PACING_FAILED','TypeError:','ReferenceError:','Binding loop'):
                self.assertNotIn(error,output)
            print('\n'.join(line for line in output.splitlines() if 'DESKTOP_PACING' in line))
