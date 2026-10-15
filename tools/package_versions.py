"""Build the frozen pre-scenery edition and the current new-deccors edition."""
from pathlib import Path
import json
import re
import subprocess
import sys
import tempfile
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
config = json.loads((root / 'tools/game_versions.json').read_text())
branch = subprocess.check_output(['git', 'branch', '--show-current'], cwd=root, text=True).strip()
if branch != config['new_branch']:
    raise SystemExit('Passe sur la branche new-deccors avant de reconstruire les deux éditions.')
subprocess.run([sys.executable, str(root / 'tools/package.py')], check=True)
destination = root / 'dist/versions'
destination.mkdir(exist_ok=True)
with tempfile.TemporaryDirectory(prefix='silken-classic-') as folder:
    source = Path(folder) / 'source.zip'
    subprocess.run(['git', 'archive', '--format=zip', '-o', str(source), config['classic_ref'],
                    'main.lua', 'conf.lua', 'custom_levels.json', 'src', 'assets', 'tests', 'designer'],
                   cwd=root, check=True)
    staged = destination / 'classique.love.tmp'
    with ZipFile(source) as original, ZipFile(staged, 'w', ZIP_DEFLATED) as output:
        for item in original.infolist():
            path = Path(item.filename)
            if item.is_dir() or any(part.startswith('.') for part in path.parts):
                continue
            if 'branding' in path.parts or 'prompt' in path.name.lower() or re.search(r' \d+\.[^.]+$', path.name):
                continue
            # Include the historical sources and their licenses, not modern replacements.
            if path.suffix not in {'.lua', '.glsl', '.ttf', '.otf', '.png', '.json', '.svg', '.mp3', '.dylib', '.txt', '.dat', '.bz2'}:
                continue
            output.writestr(item.filename, original.read(item))
    staged.replace(destination / 'classique.love')
(destination / 'versions.json').write_text(json.dumps(config, indent=2) + '\n')
print('Deux éditions prêtes : classique (avant les décors) et new-deccors.')
