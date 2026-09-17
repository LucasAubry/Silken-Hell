"""Build the desktop game and embedded level editor from the current sources."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import tempfile
import shutil

root = Path(__file__).resolve().parents[1]
paths = set()
for pattern in ('*.lua', '*.glsl', '*.ttf', 'levels/**/*.lua', 'assets/**/*',
                'texture/**/*.png', 'tests/*.lua', 'designer/**/*'):
    for path in root.glob(pattern):
        if (path.is_file() and not any(part.startswith('.') or part == '__pycache__' for part in path.relative_to(root).parts)
                and path.suffix not in ('.tmp', '.updated', '.pyc', '.log')):
            paths.add(path)
# Build outside iCloud, then publish a complete archive atomically.
with tempfile.TemporaryDirectory(prefix='silken-build-') as folder:
    output = Path(folder) / 'game.love'
    with ZipFile(output, 'w', ZIP_DEFLATED) as archive:
        for path in sorted(paths):
            archive.write(path, path.relative_to(root))
    staged = root / 'game.love.tmp'
    shutil.copyfile(output, staged)
    staged.replace(root / 'game.love')
print(f'game.love : {len(paths)} fichiers, jeu et éditeur à jour')
