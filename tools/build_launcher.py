"""Build the single official Finder launcher from the current sources."""
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
app = root / 'Silken Hell.app'
icon_source = app / 'Contents/Resources/SilkenGame-v2.icns'
if not icon_source.exists():
    icon_source = root / 'assets/icons/SilkenHell.icns'
with tempfile.TemporaryDirectory(prefix='silken-launcher-') as folder:
    staged_app = Path(folder) / 'Silken Hell.app'
    contents = staged_app / 'Contents'
    executable = Path(folder) / 'SilkenLauncher'
    subprocess.run(['clang', '-fobjc-arc', '-framework', 'AppKit',
                    str(root / 'tools/launcher.m'), '-o', str(executable)], check=True)
    (contents / 'MacOS').mkdir(parents=True, exist_ok=True)
    (contents / 'Resources').mkdir(exist_ok=True)
    shutil.copyfile(executable, contents / 'MacOS/SilkenLauncher')
    icon = contents / 'Resources/SilkenGame-v2.icns'
    shutil.copyfile(icon_source, icon)
    (contents / 'MacOS/SilkenLauncher').chmod(0o755)
    info = dict(CFBundleDisplayName='Silken Hell', CFBundleName='Silken Hell',
                CFBundleExecutable='SilkenLauncher', CFBundleIconFile=icon.name,
                CFBundleIdentifier='dev.silkenhell.launcher', CFBundlePackageType='APPL',
                CFBundleShortVersionString='1.0', CFBundleVersion='2',
                LSMinimumSystemVersion='11.0', LSUIElement=True,
                NSHighResolutionCapable=True, SilkenLaunchScript='Lancer Silken Hell.command')
    (contents / 'Info.plist').write_bytes(plistlib.dumps(info))
    (root / 'Lancer Silken Hell.command').chmod(0o755)
    subprocess.run(['codesign', '--force', '--sign', '-', str(staged_app)], check=True)
    subprocess.run(['codesign', '--verify', '--strict', str(staged_app)], check=True)
    if app.exists():
        shutil.rmtree(app)
    shutil.copytree(staged_app, app, copy_function=shutil.copyfile)
    (app / 'Contents/MacOS/SilkenLauncher').chmod(0o755)
print(app.name)
