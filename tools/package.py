"""Build the desktop game and embedded level editor from the current sources."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import tempfile
import shutil
import re
import os
import sys

root = Path(__file__).resolve().parents[1]
paths = set()
for pattern in ('main.lua', 'conf.lua', 'src/**/*.lua', 'assets/**/*',
                'tests/*.lua', 'tests/*.json', 'designer/*.lua', 'designer/*.json', 'designer/*.png'):
    for path in root.glob(pattern):
        if (path.is_file() and not any(part.startswith('.') or part == '__pycache__' for part in path.relative_to(root).parts)
                and (path.suffix in ('.lua', '.glsl', '.ttf', '.otf', '.png', '.json', '.svg', '.mp3')
                     or path.relative_to(root).as_posix() == 'assets/fonts/OFL.txt')
                and 'branding' not in path.relative_to(root).parts
                and 'prompt' not in path.name.lower()
                and not re.search(r' \d+\.[^.]+$', path.name) and path.suffix not in ('.tmp', '.updated', '.pyc', '.log')):
            paths.add(path)
with tempfile.TemporaryDirectory(prefix='silken-build-') as folder:
    output = Path(folder) / 'game.love'
    with ZipFile(output, 'w', ZIP_DEFLATED) as archive:
        for path in sorted(paths):
            archive.write(path, path.relative_to(root))
    dist = root / 'dist'
    dist.mkdir(exist_ok=True)
    staged = dist / 'game.love.tmp'
    shutil.copyfile(output, staged)
    staged.replace(dist / 'game.love')
    if sys.platform == 'darwin':
        cache = Path.home() / 'Library/Application Support/Silken Hell'
    elif sys.platform == 'win32':
        cache = Path(os.environ.get('LOCALAPPDATA', Path.home() / 'AppData/Local')) / 'Silken Hell'
    else:
        cache = Path(os.environ.get('XDG_DATA_HOME', Path.home() / '.local/share')) / 'silken-hell'
    cache.mkdir(parents=True, exist_ok=True)
    staged = cache / 'Silken Hell.love.new'
    shutil.copyfile(output, staged)
    staged.replace(cache / 'Silken Hell.love')
print(f'dist/game.love : {len(paths)} fichiers, jeu et éditeur à jour')
