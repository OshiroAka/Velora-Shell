import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class DepthMotionTests(unittest.TestCase):
    def test_connected_spring_parallax_input_and_reduced_motion(self):
        if not shutil.which('qs'): self.skipTest('Quickshell unavailable')
        with tempfile.TemporaryDirectory(prefix='velora-depth-') as directory:
            base = Path(directory)
            for name in ['core','components','features','platform','services','assets','shaders']:
                (base/name).symlink_to(ROOT/name,target_is_directory=True)
            (base/'shell.qml').write_text((ROOT/'tests/fixtures/depth-motion.qml').read_text().replace('"../../','"./'))
            (base/'runtime').mkdir(mode=0o700)
            env=dict(os.environ,QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software',VELORA_VALIDATE='1',
                XDG_RUNTIME_DIR=str(base/'runtime'),XDG_CACHE_HOME=str(base/'cache'))
            env.pop('WAYLAND_DISPLAY',None)
            result=subprocess.run(['qs','-p',str(base)],env=env,capture_output=True,text=True,timeout=10)
            output=result.stdout+result.stderr
            self.assertEqual(result.returncode,0,output)
            self.assertIn('DEPTH_MOTION_OK',output)
            for error in ['DEPTH_MOTION_FAILED','TypeError','ReferenceError','Binding loop','Cannot assign','QWARN']:
                self.assertNotIn(error,output)

    def test_native_light_following_stops_and_inherits_motion_preferences(self):
        with tempfile.TemporaryDirectory(prefix='velora-parallax-') as directory:
            base=Path(directory)
            source=(ROOT/'native/hyprland/plugin.cpp').read_text()
            start=source.index('SDispatchResult appearanceDispatcher(')
            (base/'parallax-appearance.inc').write_text(source[start:source.index('\nSDispatchResult lockLayoutDispatcher',start)])
            flags=subprocess.check_output(['pkg-config','--cflags','--libs','hyprutils'],text=True).split()
            result=subprocess.run(['c++','-std=c++23','-I',str(base),'-I',str(ROOT/'native/hyprland'),
                str(ROOT/'tests/fixtures/light-parallax.cpp'),'-o',str(base/'parallax'),*flags],capture_output=True,text=True,timeout=30)
            self.assertEqual(result.returncode,0,result.stderr)
            result=subprocess.run([str(base/'parallax')],capture_output=True,text=True,timeout=5)
            self.assertEqual(result.returncode,0,result.stdout+result.stderr)
            self.assertIn('LIGHT_PARALLAX_OK',result.stdout)

    def test_connected_spring_bounds_at_screen_edges(self):
        script=r'''
const fs=require('fs'),vm=require('vm'),assert=require('assert/strict');
const context=vm.createContext({});
vm.runInContext(fs.readFileSync('features/topbar/TimerGeometry.js','utf8').replace('.pragma library',''),context);
for(const width of [320,800,1920]) for(const height of [300,720,1200])
for(const anchor of [8,width/2,width-8]) for(const corner of [0,.5,1])
for(const progress of [0,.3,.99,1,1.01]) {
 const rect=context.panel(width,height,40,anchor,64,380,420,progress,8,8,corner,Math.max(0,progress-1));
 assert(rect.x>=8 && rect.x+rect.width<=width-8+1e-6);
 assert(rect.y>=40 && rect.y+rect.height<=height);
}
const fixed=context.panel(1920,1200,40,600,64,380,420,1,8,8,0);
const elastic=context.panel(1920,1200,40,600,64,380,420,1.01,8,8,0,.01);
assert(elastic.width>fixed.width && elastic.height>fixed.height);
assert(elastic.width<fixed.width*1.015 && elastic.height<fixed.height*1.015);
'''
        subprocess.run(['node','-e',script],cwd=ROOT,check=True,capture_output=True,text=True)


if __name__ == '__main__': unittest.main()
