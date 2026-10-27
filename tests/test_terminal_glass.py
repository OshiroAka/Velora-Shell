import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
HYPR_SHADERS = Path('/usr/include/hyprland/src/render/shaders')


class TerminalGlassTests(unittest.TestCase):
    def test_terminal_commands_remember_strength_and_validate_before_saving(self):
        if not shutil.which('node'):
            self.skipTest('Node unavailable')
        source = (ROOT / 'CompositionController.qml').read_text()
        functions = []
        for name in ('syncTerminalLiquid', 'syncKittyBarMaterial', 'controlTerminalLiquid'):
            match = re.search(r'    function ' + name + r'\([^)]*\)\s*\{', source)
            self.assertIsNotNone(match)
            end, depth = match.end(), 1
            while depth:
                depth += (source[end] == '{') - (source[end] == '}')
                end += 1
            functions.append(source[match.start():end])
        script = "const assert=require('assert/strict'); const calls=[]; let writes=0;\n"
        script += """
const Platform={NativeBlur:{supports:name=>name==='terminal-glass-control',dispatch:value=>calls.push(value)}};
const config={ready:true,terminalLiquidEnabled:true,terminalRefraction:1,
 setValue(path,value){writes++;if(path.endsWith('Enabled'))this.terminalLiquidEnabled=value;
 else this.terminalRefraction=value;syncTerminalLiquid();}};
""" + '\n'.join(functions) + """
const command=(name,value=1)=>JSON.parse(controlTerminalLiquid(name,value));
assert.equal(command('strength',2.5).strength,2.5);
assert.equal(command('off').enabled,false);assert.equal(config.terminalRefraction,2.5);
assert.equal(calls.at(-1),'velora-blur:terminal-glass-control 0 2.5000');
assert.equal(command('on').enabled,true);
assert.equal(calls.at(-1),'velora-blur:terminal-glass-control 1 2.5000');
assert.equal(command('toggle').enabled,false);
const before=writes;command('status');assert.equal(writes,before);
for(const value of [-1,3.1,NaN,Infinity])assert(command('strength',value).error);
assert(command('unexpected').error);assert.equal(writes,before);
config.ready=false;assert(command('on').error);assert.equal(writes,before);
"""
        result = subprocess.run(['node','-e',script],capture_output=True,text=True,timeout=10)
        self.assertEqual(result.returncode,0,result.stderr)

    def test_cli_routes_terminal_controls_without_starting_or_stopping_shell(self):
        import json
        with tempfile.TemporaryDirectory(prefix='velora-liquid-cli-') as temporary:
            directory=Path(temporary);scripts=directory/'scripts';scripts.mkdir()
            shutil.copy2(ROOT/'scripts/velora',scripts/'velora')
            qs=directory/'qs'
            qs.write_text('#!/usr/bin/env python3\nimport json,sys\nprint(json.dumps(sys.argv[1:]))\n')
            qs.chmod(0o755)
            preflight=scripts/'preflight'
            preflight.write_text('#!/usr/bin/env python3\nprint('+repr(str(qs))+')\n')
            environment=dict(os.environ,HOME=str(directory),XDG_RUNTIME_DIR=str(directory/'runtime'))
            for arguments,action,value in [([], 'toggle','1'),(['off'],'off','1'),(['on'],'on','1'),
                    (['status'],'status','1'),(['strength','2.5'],'strength','2.5')]:
                result=subprocess.run([str(scripts/'velora'),'liquid',*arguments],env=environment,
                    capture_output=True,text=True,timeout=10)
                self.assertEqual(result.returncode,0,result.stderr)
                self.assertEqual(json.loads(result.stdout),['-p',str(directory),'ipc','call','composition','terminalLiquid',action,value])
            for arguments in (['strength'],['unexpected'],['off','extra']):
                result=subprocess.run([str(scripts/'velora'),'liquid',*arguments],env=environment,
                    capture_output=True,text=True,timeout=10)
                self.assertNotEqual(result.returncode,0)
                self.assertEqual(result.stdout,'')

    def test_native_backdrop_and_original_client_composition(self):
        if not shutil.which('c++') or not shutil.which('pkg-config'):
            self.skipTest('C++/EGL toolchain unavailable')
        flags = subprocess.run(['pkg-config', '--cflags', '--libs', 'egl', 'glesv2', 'hyprutils'],
                               capture_output=True, text=True)
        if flags.returncode or not (HYPR_SHADERS / 'surface.frag.inc').exists():
            self.skipTest('EGL/GLES or Hyprland shader headers unavailable')
        source = (ROOT / 'native/hyprland/plugin.cpp').read_text()
        vertex = re.search(r'LIQUID_GLASS_VERTEX = R"GLSL\((.*?)\)GLSL";', source, re.S)
        self.assertIsNotNone(vertex)
        # Compile the installed compositor's real client shader, with its blur
        # and rounding branches enabled, rather than duplicating its blend math.
        def shader(name):
            text = (HYPR_SHADERS / (name + '.inc')).read_text()
            return text.removeprefix('R"#(').removesuffix('\n').removesuffix(')#"')

        surface = shader('surface.frag')
        features = ('#define USE_RGBA 1\n#define USE_BLUR 1\n#define USE_ROUNDING 1\n'
                    '#define USE_DISCARD 1\n#define USE_BLUR_ALPHA_MASK 0\n'
                    '#define USE_BLUR_MATTE 0\n#define USE_TINT 0\n'
                    '#define USE_MOTION_BLUR 0\n#define USE_CM 0\n#define USE_MIRROR 0\n')
        surface = surface.replace('#include "defines.h"', features)
        surface = surface.replace('#extension GL_ARB_shading_language_include : enable', '')
        surface = surface.replace('#include "rounding.glsl"', shader('rounding.glsl'))
        # Unused branches still need includes expanded before GLES compilation.
        surface = re.sub(r'#include "[^"]+"', '', surface)
        with tempfile.TemporaryDirectory(prefix='velora-terminal-glass-') as temporary:
            directory = Path(temporary)
            (directory / 'vertex').write_text(vertex.group(1))
            (directory / 'surface').write_text(surface)
            binary = directory / 'terminal-glass'
            compiled = subprocess.run(['c++', '-std=c++20',
                str(ROOT / 'tests/fixtures/terminal-glass.cpp'), '-o', str(binary),
                *flags.stdout.split()], capture_output=True, text=True, timeout=60)
            self.assertEqual(compiled.returncode, 0, compiled.stderr)
            rendered = subprocess.run([str(binary), str(directory / 'vertex'), str(directory / 'surface')],
                env=dict(os.environ, EGL_PLATFORM='surfaceless', LIBGL_ALWAYS_SOFTWARE='1'),
                capture_output=True, text=True, timeout=30)
            if rendered.returncode == 77:
                self.skipTest('Surfaceless EGL unavailable')
            self.assertEqual(rendered.returncode, 0, rendered.stderr)
            bar = re.search(r'LIQUID_GLASS_FRAGMENT = R"GLSL\((.*?)\)GLSL";', source, re.S)
            self.assertIsNotNone(bar)
            (directory / 'bar').write_text(bar.group(1))
            followed = subprocess.run([str(binary), str(directory / 'vertex'), str(directory / 'surface'),
                '--follow-bar', str(directory / 'bar')],
                env=dict(os.environ, EGL_PLATFORM='surfaceless', LIBGL_ALWAYS_SOFTWARE='1'),
                capture_output=True, text=True, timeout=30)
            self.assertEqual(followed.returncode, 0, followed.stderr)
            clipped = subprocess.run([str(binary), str(directory / 'vertex'), str(directory / 'surface'),
                '--follow-bar', str(directory / 'bar')],
                env=dict(os.environ, EGL_PLATFORM='surfaceless', LIBGL_ALWAYS_SOFTWARE='1', VELORA_KITTY_FOLLOW_8BIT='1'),
                capture_output=True, text=True, timeout=30)
            self.assertEqual(clipped.returncode, 1, clipped.stderr)
            self.assertIn('Final Kitty colour/opacity differs', clipped.stderr)
            # The same optical shader without the client compensation must
            # fail: comparing two pre-client backgrounds misses double tint.
            (directory / 'uncompensated').write_text(bar.group(1).replace(
                'if (terminalBackdrop > 0.5) glass = kittyBackdropFor(glass);', ''))
            negative = subprocess.run([str(binary), str(directory / 'vertex'), str(directory / 'surface'),
                '--follow-bar', str(directory / 'uncompensated')],
                env=dict(os.environ, EGL_PLATFORM='surfaceless', LIBGL_ALWAYS_SOFTWARE='1'),
                capture_output=True, text=True, timeout=30)
            self.assertEqual(negative.returncode, 1, negative.stderr)
            self.assertIn('Final Kitty colour/opacity differs', negative.stderr)
            blurred_only = subprocess.run([str(binary), str(directory / 'vertex'),
                str(directory / 'surface'), '--blur-only'],
                env=dict(os.environ, EGL_PLATFORM='surfaceless', LIBGL_ALWAYS_SOFTWARE='1'),
                capture_output=True, text=True, timeout=30)
            self.assertEqual(blurred_only.returncode, 1, blurred_only.stderr)
            self.assertIn('Liquid is imperceptible after realistic Kitty opacity', blurred_only.stderr)


if __name__ == '__main__':
    unittest.main()
