"""Framing preference reaches static/video paths without cropping user assets."""
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[1]
SPEC=importlib.util.spec_from_file_location('wallpaper_fit',ROOT/'scripts/wallpaper_fit.py')
fit=importlib.util.module_from_spec(SPEC);SPEC.loader.exec_module(fit)

class WallpaperFitTests(unittest.TestCase):
    def test_saved_mode_defaults_validation_and_explicit_apply_override(self):
        with tempfile.TemporaryDirectory() as directory:
            base=Path(directory);config=base/'velora-shell/config.json';config.parent.mkdir()
            with patch.dict(os.environ,{'XDG_CONFIG_HOME':directory,'VELORA_WALLPAPER_FIT':''}):
                self.assertEqual(fit.mode(),'cover')
                config.write_text(json.dumps({'desktop':{'wallpaperFit':'contain'}}))
                self.assertEqual(fit.mode(),'contain')
                self.assertEqual(dict(fit.mpv_properties())['panscan'],0)
                self.assertTrue(dict(fit.mpv_properties())['keepaspect'])
                self.assertEqual(dict(fit.mpv_properties())['background-color'],'#FF000000')
                config.write_text(json.dumps({'desktop':{'wallpaperFit':'untrusted'}}))
                self.assertEqual(fit.mode(),'cover')
                with patch.dict(os.environ,{'VELORA_WALLPAPER_FIT':'contain'}):self.assertEqual(fit.mode(),'contain')

    def test_contain_keeps_the_original_image_and_static_background_is_black(self):
        source=(ROOT/'scripts/velora-wallpaper-apply').read_text()
        function=re.search(r'^static_display_image\(\) \{.*?^\}',source,re.M|re.S).group(0)
        with tempfile.TemporaryDirectory() as directory:
            image=Path(directory)/'ultrawide.png';image.write_bytes(b'original')
            script='set -euo pipefail\nwallpaper_fit_mode=contain\n'+function+'\nstatic_display_image "$1"\n'
            result=subprocess.run(['bash','-c',script,'fixture',str(image)],text=True,capture_output=True,timeout=2)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertEqual(result.stdout.strip(),str(image))
            self.assertEqual(image.read_bytes(),b'original')
            cache=Path(directory)/'.cache/velora-shell/current_wallpaper';cache.parent.mkdir(parents=True)
            cache.write_text(f'static|{image}|{image}\n')
            with patch.object(fit.Path,'home',return_value=Path(directory)), patch.object(fit.shutil,'which',return_value='/bin/awww'), patch.object(fit.subprocess,'run') as run:
                fit.apply('contain')
                command=run.call_args.args[0]
                self.assertEqual(command[command.index('--resize')+1],'fit')
                self.assertEqual(command[command.index('--fill-color')+1],'000000')
                self.assertEqual(command[2],str(image))

    def test_existing_video_changes_framing_without_reloading_or_seeking(self):
        class Connection:
            def __init__(self):self.commands=[]
            def __enter__(self):return self
            def __exit__(self,*args):pass
            def settimeout(self,value):pass
            def connect(self,path):pass
            def sendall(self,data):self.commands.append(json.loads(data))
            def makefile(self,mode):return self
            def readline(self):return (json.dumps({'request_id':self.commands[-1]['request_id'],'error':'success'})+'\n').encode()
        connection=Connection()
        with patch.object(fit.socket,'socket',return_value=connection):fit.update_video(Path('/fixture.sock'),'contain')
        properties={entry['command'][1]:entry['command'][2] for entry in connection.commands}
        self.assertEqual(properties['panscan'],0)
        self.assertTrue(properties['keepaspect'])
        self.assertEqual(properties['background'],'color')
        self.assertEqual(properties['border-background'],'color')
        self.assertEqual(properties['background-color'],'#FF000000')
        self.assertTrue(all(entry['command'][0]=='set_property' for entry in connection.commands))
