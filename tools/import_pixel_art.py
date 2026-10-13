"""Install an ImageGen redraw without editing its pixels; retain collision masks."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('target')
    parser.add_argument('generated', type=Path)
    parser.add_argument('--prompt-file', type=Path, required=True)
    parser.add_argument('--reviewed-atlas', action='store_true')
    args = parser.parse_args()
    manifest_path = ROOT / 'output/pixel2/manifest.json'
    manifest = json.loads(manifest_path.read_text())
    row = next(r for r in manifest if r['path'] == args.target)
    if row['protected']:
        raise SystemExit('Player skins are protected.')
    target = ROOT / args.target
    with Image.open(args.generated) as image:
        if row['transparent'] and image.mode != 'RGBA':
            raise SystemExit('The generated sprite must retain transparency.')
        alpha = image.convert('RGBA').getchannel('A')
        if row['transparent'] and alpha.getextrema()[0] != 0:
            raise SystemExit('The generated sprite has an opaque background.')
        mask = alpha.point(lambda value: 255 if value >= 128 else 0)
        bounds = mask.getbbox()
        transparent = alpha.getextrema()[0] == 0
        if not bounds:
            raise SystemExit('Empty generated sprite.')
        size = list(image.size)
    # Review atlas layouts separately before changing their source dimensions.
    atlas_paths = ['assets/environments/paradis/encre-atlas.json',
                   'assets/environments/paradis/characters-ink.json',
                   'assets/monstres/serviteurs/frames.json']
    for path in atlas_paths:
        frames = json.loads((ROOT / path).read_text())
        matches = [frame for frame in frames.values() if frame['path'] == args.target]
        if matches:
            if not args.reviewed_atlas:
                raise SystemExit('Atlas asset: review layout before import.')
            backup = ROOT / 'output/pixel2/atlas-originals' / Path(path).name
            if not backup.exists():
                write_json(backup, frames)
            originals = json.loads(backup.read_text())
            for key, frame in frames.items():
                if frame['path'] != args.target:
                    continue
                box = bounds
                if len(matches) > 1:
                    old = originals[key]
                    columns, rows = 2, (1 if len(matches) == 2 else 2)
                    col = int((old['x'] + old['w']/2) / row['size'][0] * columns)
                    line = int((old['y'] + old['h']/2) / row['size'][1] * rows)
                    x0, y0 = col*size[0]//columns, line*size[1]//rows
                    region = (x0, y0, (col+1)*size[0]//columns, (line+1)*size[1]//rows)
                    local = mask.crop(region).getbbox()
                    if not local:
                        raise SystemExit('Empty atlas frame: ' + key)
                    box = (local[0]+x0, local[1]+y0, local[2]+x0, local[3]+y0)
                x, y, right, bottom = box
                frame.update(x=x, y=y, w=right-x, h=bottom-y)
                if 'iw' in frame:
                    frame.update(iw=size[0], ih=size[1])
            write_json(ROOT / path, frames)
    shutil.copyfile(args.generated, target)
    registry_path = ROOT / 'assets/pixel-art.json'
    registry = json.loads(registry_path.read_text()) if registry_path.exists() else {}
    registry[args.target] = {'sourceSize': row['size'], 'size': size,
                             'binaryAlpha': transparent}
    write_json(registry_path, registry)
    metadata_path = ROOT / 'assets/art-metadata.json'
    metadata = json.loads(metadata_path.read_text())
    if args.target in metadata:
        entry = metadata[args.target]
        x, y, right, bottom = bounds
        entry.update(x=x, y=y, w=right-x, h=bottom-y, fileSize=target.stat().st_size)
        write_json(metadata_path, metadata)
    row.update(status='installed', generated=str(args.generated), generatedSize=size,
               generatedSha256=hashlib.sha256(target.read_bytes()).hexdigest(),
               prompt=args.prompt_file.read_text())
    write_json(manifest_path, manifest)
    print(f'Installed {args.target}: {size[0]}x{size[1]}')


if __name__ == '__main__':
    main()
