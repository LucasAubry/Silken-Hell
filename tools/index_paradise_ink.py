"""Measure ink sprites without altering their pixels or transparency."""
from pathlib import Path
import json
from PIL import Image

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'output/paradis-style/manifest.json').read_text())
frames = {}
rejected_spiders = {f'{kind}_{pose}' for kind in ('original', 'spider') for pose in ('down', 'up', 'left')}

def measure(path):
    with Image.open(root / path) as image:
        alpha = image.convert('RGBA').getchannel('A')
        bounds = alpha.point(lambda value: 255 if value > 30 else 0).getbbox()
        assert bounds, f'Empty sprite: {path}'
        x, y, right, bottom = bounds
        return dict(x=x, y=y, w=right-x, h=bottom-y, iw=image.width, ih=image.height)

for asset in manifest['assets']:
    # These old generated spiders had only three pairs of legs and were removed.
    if asset['key'] in rejected_spiders:
        continue
    path = f"assets/environments/paradis/characters-ink/{asset['key']}.png"
    bounds = measure(path)
    frames[asset['key']] = dict(path=path, **bounds, source=measure(asset['source']))

(root / 'assets/environments/paradis/characters-ink.json').write_text(json.dumps(frames, indent=2)+'\n')
print(f'Indexed {len(frames)} ink sprites; original pixels preserved')
