import importlib.machinery
import importlib.util
import io
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import urllib.error
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def helper():
    loader = importlib.machinery.SourceFileLoader('velyrics_font', str(ROOT / 'scripts/install-velyrics-font'))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec); loader.exec_module(module)
    return module


class VelyricsFontInstallTests(unittest.TestCase):
    def setUp(self):
        self.source = helper()
        self.tmp = tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.directory = Path(self.tmp.name)
        self.enterContext(patch.dict(os.environ, XDG_DATA_HOME=str(self.directory)))

    def bundle(self, name='Pixelon.ttf'):
        output = io.BytesIO()
        with zipfile.ZipFile(output, 'w') as archive:
            archive.writestr(name, b'fixture-font')
            archive.writestr('README.txt', 'Fixture author notice')
        return output.getvalue()

    def test_download_install_is_user_scoped_and_repeatable(self):
        target = self.source.font_path()
        pending = {'ready': False, 'path': str(target)}
        ready = {'ready': True, 'path': str(target)}
        with patch.object(self.source, 'status', side_effect=[pending, ready, ready]), \
             patch.object(self.source, 'font_family', return_value=True) as scan, \
             patch.object(self.source, 'download', return_value=self.bundle('../../Pixelon.ttf')) as download, \
             patch.object(self.source.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, '', '')) as cache:
            self.source.install(); self.source.install()
            download.assert_called_once()
            scan.assert_called_once()
            cache.assert_called_once()
        self.assertEqual(target.read_bytes(), b'fixture-font')
        self.assertFalse((self.directory.parent / 'Pixelon.ttf').exists())
        self.assertTrue((target.parent / 'Pixelon-source.json').is_file())
        self.assertEqual((target.parent / 'Pixelon-author-notice.txt').read_text(), 'Fixture author notice')

    def test_invalid_font_is_not_published(self):
        with patch.object(self.source, 'status', return_value={'ready': False}), \
             patch.object(self.source, 'download', return_value=self.bundle()), \
             patch.object(self.source, 'font_family', return_value=False):
            with self.assertRaisesRegex(RuntimeError, 'fc-scan'):
                self.source.install()
        self.assertFalse(self.source.font_path().exists())

    def test_download_failure_leaves_fonts_untouched(self):
        with patch.object(self.source, 'status', return_value={'ready': False}), \
             patch.object(self.source, 'download', side_effect=urllib.error.URLError('offline')):
            with self.assertRaises(urllib.error.URLError): self.source.install()
        self.assertFalse(self.source.font_path().parent.exists())

    def test_author_download_has_limit_and_validates_archive(self):
        response = io.BytesIO(b'x' * (self.source.MAX_DOWNLOAD + 1))
        with patch.object(self.source.urllib.request, 'urlopen', return_value=response):
            with self.assertRaises(RuntimeError): self.source.download()
        with patch.object(self.source, 'status', return_value={'ready': False}), \
             patch.object(self.source, 'download', return_value=self.bundle('Other.ttf')):
            with self.assertRaisesRegex(RuntimeError, 'Pixelon.ttf'): self.source.install()
        self.assertFalse(self.source.font_path().exists())

    def test_real_font_scan_rejects_other_families(self):
        self.assertFalse(self.source.font_family(ROOT / 'assets/fonts/Orbitron-Variable.ttf'))


if __name__ == '__main__': unittest.main()
