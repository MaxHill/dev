"""Run with: python3 -m unittest discover -s scripts/tests."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class ThemeTest(unittest.TestCase):
    def test_swaync_palette_matches_kitty(self):
        style = (ROOT / 'configs/swaync/.config/swaync/style.css').read_text()
        self.assertIn('@import "../theme/colors.css";', style)
        self.assertIn('@define-color cc-bg @surface_background;', style)
        self.assertIn('@define-color text-color @surface_foreground;', style)
        for name, background, foreground in (
            ('dark', '0, 0, 0', '#d4be98'),
            ('light', '251, 241, 199', '#3c3836'),
        ):
            palette = (ROOT / 'themes' / name / 'colors.css').read_text()
            self.assertIn(f'@define-color surface_background rgba({background}, 0.85);', palette)
            self.assertIn(f'@define-color surface_foreground {foreground};', palette)

    def test_switch_reloads_swaync_after_installing_palette(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            (home / 'dev').mkdir()
            shutil.copytree(ROOT / 'themes', home / 'dev/themes')
            lib = home / '.local/lib/lua'
            lib.mkdir(parents=True)
            shutil.copy(ROOT / 'scripts/lib/lib.lua', lib)
            binaries = home / 'bin'
            binaries.mkdir()
            for name in ('pkill', 'hyprpaper', 'swaync-client'):
                path = binaries / name
                path.write_text('#!/bin/sh\n' + (
                    'echo "$*" >> "$HOME/reloads"\ncp "$XDG_CONFIG_HOME/theme/colors.css" "$HOME/reloaded.css"\n'
                    if name == 'swaync-client' else 'exit 0\n'))
                path.chmod(0o755)
            env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / 'config'),
                       PATH=f'{binaries}:' + os.environ['PATH'])
            env.pop('HYPRLAND_INSTANCE_SIGNATURE', None)
            for name in ('dark', 'light', 'dark'):
                subprocess.run(['lua', str(ROOT / 'scripts/theme'), name], env=env,
                               check=True, capture_output=True)
                self.assertTrue((home / 'reloads').exists(), 'SwayNC CSS was not reloaded')
                self.assertEqual((home / 'reloaded.css').read_text(),
                                 (ROOT / 'themes' / name / 'colors.css').read_text())
            self.assertEqual((home / 'reloads').read_text().splitlines(), ['-sw -rs'] * 3)


if __name__ == '__main__':
    unittest.main()
