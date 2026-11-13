"""Library discovery must follow media format and invalidate cached inventories."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import select
import shutil
import unittest

ROOT = Path(__file__).resolve().parents[1]


class WallpaperScanTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='velora-library-scan-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.library = self.base / 'Pictures/Wallpapers'
        self.library.mkdir(parents=True)
        binary = self.base / 'bin'
        binary.mkdir()
        for command in ('ffmpeg', 'magick'):
            path = binary / command
            path.write_text('#!/bin/bash\nfor output; do :; done\nif [ "$output" = info: ]; then printf 808080; else printf thumbnail > "$output"; fi\n')
            path.chmod(0o755)
        runtime = self.base / 'runtime'
        runtime.mkdir()
        self.env = dict(os.environ, HOME=str(self.base), XDG_RUNTIME_DIR=str(runtime),
                        PATH=str(binary) + ':' + os.environ['PATH'])

    def add(self, name):
        path = self.library / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(b'fixture-media')
        return path

    def scan(self, json_mode=False, refresh=False):
        args = [str(ROOT / 'scripts/velora-wallpaper-scan')]
        if json_mode:
            args.append('--json')
        if refresh:
            args.append('--refresh')
        result = subprocess.run(args, env=self.env, text=True, capture_output=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stderr)
        lines = result.stdout.splitlines()
        self.assertEqual((lines[0], lines[-1]), ('BEGIN', 'END'))
        return [json.loads(line) if json_mode else dict(zip(('kind', 'path', 'preview', 'title'), line.split('|')))
                for line in lines[1:-1]]

    def test_formats_detected_across_directories_without_duplicates(self):
        expected = {self.add(name): kind for name, kind in [
            ('static/new.MP4', 'live'), ('static/nested/clip.webm', 'live'),
            ('live/picture.JPG', 'static'), ('top.png', 'static'),
            ('WallpaperSelector/nested/art.webp', 'static'),
            ('static/still.gif', 'static'), ('live/animation.gif', 'live')]}
        self.add('notes.txt')
        for json_mode in (False, True):
            rows = self.scan(json_mode=json_mode)
            self.assertEqual(len(rows), len(expected))
            self.assertEqual({Path(row['path']): row['kind'].lower() for row in rows}, expected)

    def test_add_remove_and_replace_invalidate_both_warm_caches(self):
        first = self.add('static/old.png')
        for mode in (False, True):
            self.assertEqual(len(self.scan(json_mode=mode)), 1)
        new = self.add('static/new.mp4')
        for mode in (False, True):
            self.assertEqual({row['path'] for row in self.scan(json_mode=mode)}, {str(first), str(new)})
        before = self.scan(json_mode=True)[1]['preview']
        new.write_bytes(b'changed-media-content')
        after = self.scan(json_mode=True)[1]['preview']
        self.assertNotEqual(before, after)
        first.unlink()
        new.unlink()
        for mode in (False, True):
            self.assertEqual(self.scan(json_mode=mode), [])
            self.assertEqual(self.scan(json_mode=mode, refresh=True), [])

    def test_same_video_names_have_distinct_thumbnails(self):
        self.add('static/first/clip.mp4')
        self.add('live/second/clip.mp4')
        rows = self.scan(json_mode=True)
        self.assertEqual(len({row['preview'] for row in rows}), 2)

    def test_quick_inventory_skips_media_tools_and_remembers_discovery(self):
        for name in ('ffmpeg', 'magick'):
            (self.base/'bin'/name).write_text('#!/bin/bash\ntouch "$HOME/unexpected-media-decode"\nsleep 3\n')
        old = self.add('static/old.png')
        os.utime(old, (time.time()-86400, time.time()-86400))
        def quick():
            started=time.monotonic()
            result=subprocess.run([str(ROOT/'scripts/velora-wallpaper-scan'),'--json','--quick'],
                                  env=self.env,capture_output=True,text=True,timeout=2)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertLess(time.monotonic()-started,1.5)
            self.assertEqual(result.stdout.splitlines()[-1],'END')
            return [json.loads(line) for line in result.stdout.splitlines()[1:-1]]
        first=quick()
        self.assertEqual(first[0]['addedAt'],0)
        added=self.add('live/brand-new.mp4')
        os.utime(added,(time.time()-86400,time.time()-86400))
        rows=quick()
        entry=next(row for row in rows if row['path']==str(added))
        self.assertGreater(entry['addedAt'],time.time()-2)
        self.assertEqual(entry['preview'],'')
        self.assertFalse((self.base/'unexpected-media-decode').exists())
        self.assertEqual(next(row for row in quick() if row['path']==str(added))['addedAt'],entry['addedAt'])
        added.unlink()
        self.assertEqual(len(quick()),1)

    def test_watch_detects_completed_files_nested_moves_and_library_recreation(self):
        process=subprocess.Popen(['python3',str(ROOT/'scripts/velora-wallpaper-index'),'--watch'],
                                 env=self.env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,bufsize=0)
        self.addCleanup(lambda: process.poll() is None and process.kill())
        def line(expected,timeout=2):
            self.assertTrue(select.select([process.stdout],[],[],timeout)[0], 'watcher did not notify')
            self.assertEqual(process.stdout.readline().decode().strip(),expected)
        line('READY')
        self.add('one.png');line('CHANGED')
        nested=self.library/'nested';nested.mkdir();line('CHANGED')
        self.add('nested/two.mp4');line('CHANGED')
        outside=self.base/'moved';outside.mkdir()
        (outside/'three.jpg').write_bytes(b'image')
        outside.rename(self.library/'moved');line('CHANGED')
        self.add('moved/four.jpg');line('CHANGED')
        shutil.rmtree(self.library)
        while select.select([process.stdout],[],[],.1)[0]:
            os.read(process.stdout.fileno(),65536)
        self.library.mkdir();line('CHANGED')
        self.add('after-recreate.png');line('CHANGED')
        process.terminate();process.communicate(timeout=3)

    def test_service_publishes_inventory_before_slow_previews_and_updates_new_files(self):
        base=self.base
        (base/'services').symlink_to(ROOT/'services',target_is_directory=True)
        (base/'scripts').mkdir()
        for name in ('velora-wallpaper-index','velora-wallpaper-scan'):
            (base/'scripts'/name).symlink_to(ROOT/'scripts'/name)
        self.add('old1.png');self.add('old2.png')
        (base/'bin/magick').write_text('''#!/bin/bash
sleep .15
for output; do :; done
if [ "$output" = info: ];then printf 808080;else printf preview > "$output";fi
''')
        (base/'shell.qml').write_text((ROOT/'tests/fixtures/wallpaper-library.qml').read_text().replace('"../../','"./'))
        env=dict(self.env,QT_QPA_PLATFORM='offscreen',QT_QUICK_BACKEND='software',VELORA_VALIDATE='1')
        env.pop('WAYLAND_DISPLAY',None)
        result=subprocess.run(['qs','-p',str(base)],env=env,text=True,capture_output=True,timeout=15)
        output=result.stdout+result.stderr
        self.assertEqual(result.returncode,0,output)
        self.assertIn('WALLPAPER_LIBRARY_OK',output)
        for error in ('LIBRARY_FAILED','TypeError:','ReferenceError:','Invalid write','Binding loop'):
            self.assertNotIn(error,output)


if __name__ == '__main__':
    unittest.main()
