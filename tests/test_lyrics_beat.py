import os
import importlib.machinery
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
import shutil
from unittest.mock import patch
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]


class LyricsBeatTests(unittest.TestCase):
    def test_palette_uses_cover_colors_ignores_letterboxes_and_caches(self):
        loader = importlib.machinery.SourceFileLoader("album_palette", str(ROOT / "scripts/velora-album-palette"))
        spec = importlib.util.spec_from_loader(loader.name, loader)
        helper = importlib.util.module_from_spec(spec)
        loader.exec_module(helper)
        image = Image.new("RGB", (100,100),"black")
        draw = ImageDraw.Draw(image)
        draw.rectangle((0,20,64,79),fill=(220,30,40))
        draw.rectangle((65,20,99,79),fill=(25,60,225))
        colors = helper.extract(image)
        self.assertTrue(helper.valid(colors))
        pairs=[colors[:3],colors[3:]]
        self.assertTrue(any(c[0]>.7 and c[1]<.2 for c in pairs), pairs)
        self.assertTrue(any(c[2]>.7 and c[0]<.2 for c in pairs), pairs)
        self.assertTrue(all(max(c)>.7 for c in pairs),'Black letterboxes must not become an accent')
        gray = helper.extract(Image.new("RGB", (20,20),(110,110,110)))
        self.assertTrue(helper.valid(gray))
        self.assertEqual(gray[0],gray[1]); self.assertEqual(gray[1],gray[2])
        self.assertEqual(helper.extract(Image.new("RGBA",(20,20),(255,0,0,0))),[])
        with tempfile.TemporaryDirectory(prefix="velora-album-test-") as temporary:
            path=Path(temporary)/"capa com espaços.png"; image.save(path)
            with patch.dict(os.environ, {"XDG_CACHE_HOME":temporary}):
                first=helper.album_palette(path.as_uri())
                with patch.object(helper,"extract",side_effect=AssertionError("cache should be reused")):
                    self.assertEqual(helper.album_palette(path.as_uri()),first)
                Image.new("RGB",(100,100),(20,200,70)).save(path)
                self.assertNotEqual(helper.album_palette(path.as_uri()),first)

    def test_percussion_onsets_reject_sustain_ramps_noise_and_high_bands(self):
        source = (ROOT / "services/PercussionDetector.js").read_text().replace(".pragma library", "")
        script = source + r'''
const assert = require('node:assert/strict');
const frame = (low, high=0) => Array.from({length:96},(_,i)=> {
    const hz=35*Math.pow(7600/35,i/95);
    return hz>=40 && hz<=180 ? low : hz>=800 ? high : 0;
});
function run(generator,count=160) {
    const state=create(), beats=[];
    for(let i=0;i<count;i++) {
        const strength=update(state,generator(i),i*16);
        if(strength) beats.push({time:i*16,strength});
    }
    return beats;
}
assert.equal(run(()=>frame(0)).length,0,'silence');
assert.equal(run(()=>frame(.6)).length,0,'sustained bass');
assert.equal(run(i=>frame(Math.min(.75,i*.004))).length,0,'slow bass swell');
assert.equal(run(i=>frame(i%30<4 ? .025 : 0)).length,0,'low noise floor');
assert.equal(run(i=>frame(0,i%30<4 ? .85 : 0)).length,0,'voice/treble-only attacks');
for(const level of [.09,.35,.8]) {
    const beats=run(i=>frame(i>=35 && (i-35)%30<4 ? level : 0),200);
    assert.ok(beats.length>=5 && beats.length<=6,'kick attacks at '+level+': '+JSON.stringify(beats));
    assert.ok(beats.every(beat=>beat.strength>=.3 && beat.strength<=1));
}
const fast=run(i=>frame(i>=35 && i%8<2 ? .7 : 0),240);
assert.ok(fast.length>3);
for(let i=1;i<fast.length;i++) assert.ok(fast[i].time-fast[i-1].time>=200,'refractory interval');
const state=create();
for(let i=0;i<60;i++) update(state,frame(0),i*16);
assert.equal(update(state,frame(1),5000),0,'resume must rearm before reacting');
console.log('PERCUSSION_OK');
'''
        result = subprocess.run(["node", "-e", script], text=True, capture_output=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("PERCUSSION_OK", result.stdout)

    def test_shared_capture_lifecycle(self):
        with tempfile.TemporaryDirectory(prefix="velora-lyrics-beat-") as temporary:
            env = dict(os.environ, HOME=temporary, XDG_RUNTIME_DIR=temporary,
                       QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software")
            env.pop("WAYLAND_DISPLAY", None)
            result = subprocess.run(["/usr/lib/qt6/bin/qmltestrunner", "-input",
                                     str(ROOT / "tests/fixtures/tst_lyrics_beat.qml")],
                                    env=env, text=True, capture_output=True, timeout=15)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            for message in ["QWARN", "TypeError", "ReferenceError", "Binding loop"]:
                self.assertNotIn(message, output)

    def test_palette_service_rejects_stale_results_and_loads_actual_cover(self):
        with tempfile.TemporaryDirectory(prefix="velora-album-service-") as temporary:
            path=Path(temporary)/"album.png"
            Image.new("RGB",(64,64),(220,25,40)).save(path)
            config=Path(temporary)/"config"
            (config/"services").mkdir(parents=True)
            (config/"scripts").mkdir()
            shutil.copy2(ROOT/"services/AlbumPaletteService.qml",config/"services/AlbumPaletteService.qml")
            shutil.copy2(ROOT/"scripts/velora-album-palette",config/"scripts/velora-album-palette")
            fixture=(ROOT/"tests/fixtures/album-palette.qml").read_text().replace('"../../services"','"services"')
            (config/"shell.qml").write_text(fixture)
            env=dict(os.environ, HOME=temporary, XDG_RUNTIME_DIR=temporary,
                     XDG_CACHE_HOME=temporary+"/cache", QT_QPA_PLATFORM="offscreen",
                     QT_QUICK_BACKEND="software", VELORA_TEST_ALBUM=path.as_uri())
            env.pop("WAYLAND_DISPLAY",None)
            result=subprocess.run(["qs","-p",str(config)],
                                  env=env,text=True,capture_output=True,timeout=10)
            output=result.stdout+result.stderr
            self.assertEqual(result.returncode,0,output)
            self.assertIn("ALBUM_PALETTE_OK",output)
            for message in ["TypeError","ReferenceError","Binding loop","ERROR"]:
                self.assertNotIn(message,output)
