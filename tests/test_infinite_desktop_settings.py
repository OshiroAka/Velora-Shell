import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import re
import random
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[1]


def helper():
    loader=importlib.machinery.SourceFileLoader('infinite_settings',str(ROOT/'scripts/infinite-desktop'))
    spec=importlib.util.spec_from_loader(loader.name,loader)
    module=importlib.util.module_from_spec(spec);loader.exec_module(module)
    return module


class InfiniteDesktopSettingsTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='velora-infinite-settings-')
        self.addCleanup(self.temp.cleanup);self.home=Path(self.temp.name)
        self.env=dict(os.environ,HOME=str(self.home),XDG_CONFIG_HOME=str(self.home/'user-config'),
            XDG_RUNTIME_DIR=str(self.home/'runtime'),XDG_STATE_HOME=str(self.home/'state'),
            XDG_DATA_HOME=str(self.home/'data'),XDG_CACHE_HOME=str(self.home/'cache'),
            QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software',VELORA_VALIDATE='1',
            DBUS_SESSION_BUS_ADDRESS='unix:path=/nonexistent')
        for name in ('WAYLAND_DISPLAY','DISPLAY','HYPRLAND_INSTANCE_SIGNATURE'):self.env.pop(name,None)
        (self.home/'runtime').mkdir(mode=0o700)
        self.path=self.home/'user-config/velora-shell/config.json';self.path.parent.mkdir(parents=True)

    def save(self,values):
        self.path.write_text(json.dumps({'schemaVersion':8,'infiniteDesk':values}))

    def test_page_edits_adds_removes_and_persists_values_used_by_helper(self):
        for name in ('core','config','features','components','services','platform','assets','shaders'):
            (self.home/name).symlink_to(ROOT/name,target_is_directory=True)
        (self.home/'shell.qml').write_text((ROOT/'tests/fixtures/infinite-settings.qml').read_text().replace('"../../','"./'))
        for reload in ('0','1'):
            env=dict(self.env,VELORA_DESK_RELOAD=reload)
            if os.environ.get('VELORA_DESK_EVIDENCE'):
                env['VELORA_DESK_SCREENSHOT']=os.environ['VELORA_DESK_EVIDENCE']+'/'+('compact' if reload=='1' else 'settings')+'.png'
            result=subprocess.run(['qs','-p',str(self.home)],env=env,text=True,capture_output=True,timeout=10)
            output=result.stdout+result.stderr
            self.assertEqual(result.returncode,0,output);self.assertIn('INFINITE_SETTINGS_OK',output)
            for message in ('FAILED','TypeError','ReferenceError','Binding loop','Cannot assign'):self.assertNotIn(message,output)
        with patch.dict(os.environ,self.env):
            self.assertEqual(helper().read_settings(),(4.,[(960,640)],3.))

    def test_scatter_uses_configured_sizes_and_does_not_overlap(self):
        module=helper()
        windows=[{'address':f'0x{i:x}','at':[0,0],'size':[500,500]} for i in range(12)]
        for presets,spacing in ((presets,spacing) for presets in
                ([(960,640)],[(800,600),(1040,500),(1280,400)],[(400+i*100,300+i*60) for i in range(5)])
                for spacing in (0.,1.,3.)):
            self.save({'scatterSizes':[dict(width=w,height=h) for w,h in presets],'windowSpacing':spacing})
            with patch.dict(os.environ,self.env),patch.object(module,'enabled',return_value=True), \
                    patch.object(module,'float_active_workspace_clients'), \
                    patch.object(module,'active_canvas',return_value=(windows,windows[0],(960,600))), \
                    patch.object(module,'hyprctl_batch') as dispatch, \
                    patch.object(module.random,'SystemRandom',return_value=random.Random(7)):
                self.assertEqual(module.scatter_random_canvas(),0)
            sizes={};positions={}
            for command in dispatch.call_args.args[0]:
                match=re.fullmatch(r'dispatch (resize|move)windowpixel exact (-?\d+) (-?\d+),address:(0x[0-9a-f]+)',command)
                if match:(sizes if match[1]=='resize' else positions)[match[4]]=(int(match[2]),int(match[3]))
            self.assertEqual(set(sizes.values()),set(presets));self.assertEqual(len(positions),len(windows))
            boxes=[(*positions[address],*sizes[address]) for address in positions]
            for i,(x,y,w,h) in enumerate(boxes):
                for xx,yy,ww,hh in boxes[i+1:]:
                    self.assertTrue(x+w<=xx or xx+ww<=x or y+h<=yy or yy+hh<=y)
                    self.assertTrue(x+w+90*spacing<=xx+1 or xx+ww+90*spacing<=x+1
                        or y+h+70*spacing<=yy+1 or yy+hh+70*spacing<=y+1)

    def test_stream_uses_saved_sensitivity_on_both_axes(self):
        for speed,expected in ((.5,'pan 5 -1'),(2,'pan 20 -7')):
            self.save({'dragSensitivity':speed})
            script='''import importlib.machinery,importlib.util,json,sys
loader=importlib.machinery.SourceFileLoader("desk",sys.argv[1]);spec=importlib.util.spec_from_loader(loader.name,loader)
m=importlib.util.module_from_spec(spec);loader.exec_module(m)
m.require_enabled=lambda:True;m.inverted=lambda:False
m.active_canvas=lambda:([{"address":"0x1","at":[100,100]}],None,(0,0))
m.camera_action=lambda action:print(json.dumps({"camera":action}),flush=True)
sys.exit(m.stream_drag_canvas())'''
            result=subprocess.run(['python3','-c',script,str(ROOT/'scripts/infinite-desktop')],env=self.env,
                input='MOVE 10.4 -3.5\nEND\n',capture_output=True,text=True,timeout=3)
            self.assertEqual(result.returncode,0,result.stderr)
            movements=[json.loads(line) for line in result.stdout.splitlines() if line.startswith('{')]
            self.assertEqual(movements[-1]['camera'],expected)

    def test_invalid_preferences_fall_back_and_dimensions_are_bounded(self):
        module=helper()
        for values in ({'dragSensitivity':True,'scatterSizes':[],'windowSpacing':True},
                       {'dragSensitivity':'fast','scatterSizes':[None,{'width':True,'height':400}],'windowSpacing':'far'}):
            self.save(values)
            with patch.dict(os.environ,self.env):self.assertEqual(module.read_settings(),(1.15,module.DEFAULT_SCATTER_SIZES,1.))
        self.save({'dragSensitivity':100,'scatterSizes':[{'width':1,'height':99999}],'windowSpacing':100})
        with patch.dict(os.environ,self.env):self.assertEqual(module.read_settings(),(4.,[(320,4320)],3.))
