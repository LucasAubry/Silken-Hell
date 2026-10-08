"""Render the current brown skin, build both macOS icons and refresh launchers."""
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
RUNTIME = Path.home() / 'Library/Application Support/Silken Hell/runtime/love.app/Contents/MacOS/love'
REGISTER = '/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister'

with tempfile.TemporaryDirectory(prefix='silken-icons-') as temp:
    folder = Path(temp)
    env = dict(os.environ, SILKEN_TEST='1', SILKEN_EXPORT_ICONS=str(folder))
    subprocess.run([str(RUNTIME), str(ROOT)], env=env, check=True)
    for kind, app, resource, canonical, fallback, version in [
        ('game', 'Jouer à Silken Hell.app', 'SilkenGame-v2.icns', 'SilkenHell.icns', 'GameIcon.icns', '4'),
        ('editor', 'Concepteur Silken Hell.app', 'SilkenEditor-v2.icns', 'SilkenEditor.icns', 'applet.icns', '3'),
    ]:
        iconset = folder / (kind + '.iconset')
        iconset.mkdir()
        for size in [16, 32, 128, 256, 512]:
            for scale in [1, 2]:
                name = f'icon_{size}x{size}' + ('@2x' if scale == 2 else '') + '.png'
                shutil.copyfile(folder / f'{kind}-{size * scale}.png', iconset / name)
        target = ROOT / 'assets/icons' / canonical
        subprocess.run(['iconutil', '-c', 'icns', str(iconset), '-o', str(target)], check=True)
        shutil.copyfile(folder / f'{kind}-1024.png', ROOT / 'assets/icons' / ('silken-hell.png' if kind == 'game' else 'silken-editor.png'))
        bundle = ROOT / app
        resources = bundle / 'Contents/Resources'
        plist_path = bundle / 'Contents/Info.plist'
        plist = plistlib.loads(plist_path.read_bytes())
        old = resources / plist['CFBundleIconFile']
        shutil.copyfile(target, resources / resource)
        shutil.copyfile(target, resources / fallback)
        plist['CFBundleIconFile'] = resource
        plist['CFBundleVersion'] = version
        plist_path.write_bytes(plistlib.dumps(plist, sort_keys=False))
        if old.name not in [resource, fallback] and old.exists():
            old.unlink()
        # Finder metadata copied with these local launchers invalidates signing.
        # Remove only these unsupported attributes, preserving all other metadata.
        attributes = subprocess.check_output(['xattr', '-r', str(bundle)], text=True)
        for attribute in ['com.apple.FinderInfo', 'com.apple.ResourceFork']:
            if attribute in attributes:
                subprocess.run(['xattr', '-r', '-d', attribute, str(bundle)], check=True)
        subprocess.run([REGISTER, '-f', str(bundle)], check=True)
        # LaunchServices can recreate FinderInfo while registering the bundle.
        attributes = subprocess.check_output(['xattr', '-r', str(bundle)], text=True)
        for attribute in ['com.apple.FinderInfo', 'com.apple.ResourceFork']:
            if attribute in attributes:
                subprocess.run(['xattr', '-r', '-d', attribute, str(bundle)], check=True)
        subprocess.run(['codesign', '--force', '--sign', '-', str(bundle)], check=True)
        subprocess.run(['codesign', '--verify', '--strict', str(bundle)], check=True)
    preview = ROOT / 'output/app-icons'
    preview.mkdir(parents=True, exist_ok=True)
    for png in folder.glob('*.png'):
        shutil.copyfile(png, preview / png.name)
print('Game and editor icons installed with identical frame and spider dimensions.')
