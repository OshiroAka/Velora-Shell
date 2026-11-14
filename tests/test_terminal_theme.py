import importlib.util
from pathlib import Path
import tempfile
import unittest


class TerminalAutoThemeTests(unittest.TestCase):
    def setUp(self):
        script = Path(__file__).resolve().parents[1] / "scripts/velora-terminal-theme.py"
        spec = importlib.util.spec_from_file_location("terminal_theme", script)
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.module.KITTY_DIR = self.root

    def test_existing_os_themes_follow_successive_wallpapers_with_original_backup(self):
        for mode in ("dark", "light", "no-preference"):
            (self.root / f"{mode}-theme.auto.conf").write_text("background #1b1f32\n")
        for color in ("#123456", "#abcdef"):
            palette = f"background {color}\n"
            self.module.sync_kitty_auto_themes(palette)
            for mode in ("dark", "light", "no-preference"):
                path = self.root / f"{mode}-theme.auto.conf"
                self.assertEqual(path.read_text(), self.module.AUTO_THEME_MARKER + palette)
                backups = list(self.root.glob(f"{path.name}.before-velora-*"))
                self.assertEqual(len(backups), 1)
                self.assertEqual(backups[0].read_text(), "background #1b1f32\n")

    def test_does_not_enable_unused_automatic_themes(self):
        self.module.sync_kitty_auto_themes("background #123456\n")
        self.assertEqual(list(self.root.iterdir()), [])

    def test_preserves_opacity_and_remote_control_settings(self):
        self.module.KITTY_CONF = self.root / "kitty.conf"
        settings = ('background_opacity 0.7\ndynamic_background_opacity yes\n'
                    'allow_remote_control password\nremote_control_password "" set-background-opacity\n')
        self.module.KITTY_CONF.write_text(settings)
        self.module.ensure_kitty_include()
        self.module.ensure_kitty_include()
        result = self.module.KITTY_CONF.read_text()
        self.assertEqual(result.count("include velora-pywal.conf"), 1)
        for line in settings.splitlines():
            self.assertIn(line, result.splitlines())

    def test_follow_bar_preserves_exact_tint_and_alpha_without_independent_clamps(self):
        self.module.load_live_velora_palette = lambda: {
            "terminalFollowBar": True, "barColor": "#261d24",
            "barOpacity": .5576297305045874 * .30, "bar": "#2b261d24"}
        self.module.strong_colors_enabled = lambda: True
        value = self.module.palette_from_theme({"themeMode": "dark"}, {})
        self.assertEqual(value["background"], "#261d24")
        self.assertAlmostEqual(value["background_opacity"], .1672889191513762)
        self.assertTrue(value["follows_bar"])
        rendered = self.module.generate_kitty_theme(value)
        self.assertIn("background_opacity 0.16728892", rendered)
        independent = self.module.palette_from_theme({"themeMode": "dark"}, {}, independent=True)
        self.assertFalse(independent["follows_bar"])
        self.assertEqual(independent["background_opacity"], .4)
        for opacity in (.024, .24, .8, 1):
            explicit = self.module.palette_from_theme({}, {}, ("#010203", opacity))
            self.assertEqual((explicit["background"], explicit["background_opacity"]), ("#010203", opacity))
        for material in (("#bad", .2), ("#123456", float("nan")), ("#123456", -1), ("#123456", 2)):
            with self.assertRaises(ValueError):
                self.module.palette_from_theme({}, {}, material)
