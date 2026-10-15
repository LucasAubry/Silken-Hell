"""Build two Finder buttons using the existing native launcher and icon."""
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
original = next(root.glob('Jouer*Silken Hell.app'))
with tempfile.TemporaryDirectory(prefix='silken-buttons-') as folder:
    executable = Path(folder) / 'SilkenLauncher'
    subprocess.run(['clang', '-fobjc-arc', '-framework', 'AppKit',
                    str(root / 'tools/launcher.m'), '-o', str(executable)], check=True)
    for label, edition, script in [
        ('Ancienne version', 'classique', 'Lancer Ancienne version.command'),
        ('New deccors', 'new-deccors', 'Lancer New deccors.command'),
    ]:
        name = 'Silken Hell - ' + label
        app = root / (name + '.app')
        contents = app / 'Contents'
        (contents / 'MacOS').mkdir(parents=True, exist_ok=True)
        (contents / 'Resources').mkdir(exist_ok=True)
        shutil.copy2(executable, contents / 'MacOS/SilkenLauncher')
        shutil.copy2(original / 'Contents/Resources/SilkenGame-v2.icns', contents / 'Resources/SilkenGame-v2.icns')
        info = dict(CFBundleDisplayName=name, CFBundleName=name,
                    CFBundleExecutable='SilkenLauncher', CFBundleIconFile='SilkenGame-v2.icns',
                    CFBundleIdentifier='dev.silkenhell.launcher.' + edition,
                    CFBundlePackageType='APPL', CFBundleShortVersionString='1.0',
                    CFBundleVersion='1', LSMinimumSystemVersion='11.0',
                    LSUIElement=True, NSHighResolutionCapable=True, SilkenLaunchScript=script)
        (contents / 'Info.plist').write_bytes(plistlib.dumps(info))
        (root / script).chmod(0o755)
        subprocess.run(['codesign', '--force', '--sign', '-', str(app)], check=True)
        print(app.name)
