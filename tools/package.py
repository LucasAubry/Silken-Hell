from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import tempfile
import shutil
root = Path(__file__).resolve().parents[1]
# Build outside iCloud and publish only once the archive is complete.
with tempfile.TemporaryDirectory(prefix='silken-build-') as folder:
    output = Path(folder) / 'game.love'
    with ZipFile(output, 'w', ZIP_DEFLATED) as archive:
        for pattern in ('*.lua', '*.glsl', '*.ttf', 'levels/*.lua', 'assets/**/*', 'texture/**/*.png', 'tests/*.lua'):
            for path in sorted(root.glob(pattern)):
                if path.is_file(): archive.write(path, path.relative_to(root))
    staged = root / 'game.love.tmp'
    shutil.copyfile(output, staged)
    staged.replace(root / 'game.love')
print('game.love : sources et assets à jour')
