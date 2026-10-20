"""Run one macOS LÖVE test hidden, using an archive outside protected folders."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('flag', help='Test selector, e.g. SILKEN_ABYSS_INTRO_TEST')
    parser.add_argument('--editor', action='store_true')
    parser.add_argument('--preview-layout', type=Path, help='Launch a game preview of this JSON layout in the test profile.')
    parser.add_argument('--archive', type=Path,
                        help='Test this already-built edition without rebuilding it.')
    parser.add_argument('--reuse-package', action='store_true',
                        help='Test the last packaged archive without rebuilding it.')
    args = parser.parse_args()
    if sys.platform != 'darwin':
        parser.error('This launcher is for macOS.')
    if not args.flag.startswith('SILKEN_') or not args.flag.endswith('_TEST'):
        parser.error('Expected a SILKEN_*_TEST selector.')
    if args.preview_layout and args.editor:
        parser.error('--preview-layout is for the game, not the editor.')
    root = Path(__file__).resolve().parents[1]
    cache = Path.home() / 'Library/Application Support/Silken Hell'
    if args.archive:
        if not args.archive.is_file():
            parser.error('The requested edition archive does not exist.')
    elif not args.reuse_package:
        subprocess.run([sys.executable, str(root / 'tools/package.py')], check=True)
    elif not (cache / 'Silken Hell.love').is_file():
        parser.error('No packaged archive exists; run without --reuse-package first.')
    runtime = cache / 'runtime/love.app'
    if not runtime.exists():
        runtime = Path('/Applications/love.app')
    if not runtime.exists():
        raise SystemExit('LÖVE runtime not found.')
    # LÖVE never opens the repository on Desktop; only this immutable test copy.
    with tempfile.TemporaryDirectory(prefix='test-', dir=cache) as folder:
        folder = Path(folder)
        archive = folder / 'test.love'
        shutil.copyfile(args.archive or cache / 'Silken Hell.love', archive)
        stdout, stderr = folder / 'stdout.log', folder / 'stderr.log'
        mode = 'SILKEN_DESIGNER_TEST' if args.editor else 'SILKEN_TEST'
        command = ['open', '-g', '-j', '-n', '-W', '-a', str(runtime),
                   '--env', f'{mode}=1', '--env', f'{args.flag}=1',
                   '--stdout', str(stdout), '--stderr', str(stderr),
                   '--args', str(archive)]
        if args.editor:
            command.append('--editor')
        env = {k: v for k, v in os.environ.items() if not k.startswith('SILKEN_')}
        request_path = None
        previous_request = None
        if args.preview_layout:
            layout = json.loads(args.preview_layout.read_text())
            request_path = Path.home() / 'Library/Application Support/LOVE/silken-hell-tests/preview-request.json'
            request_path.parent.mkdir(parents=True, exist_ok=True)
            previous_request = request_path.read_bytes() if request_path.exists() else None
            request_path.write_text(json.dumps({'ticket': folder.name, 'layout': layout, 'workshop': False}))
            command.append('--preview')
        try:
            result = subprocess.run(command, cwd=cache, env=env, timeout=180)
        finally:
            if request_path:
                if previous_request is None:
                    request_path.unlink(missing_ok=True)
                else:
                    request_path.write_bytes(previous_request)
        output = stdout.read_text() if stdout.exists() else ''
        errors = stderr.read_text() if stderr.exists() else ''
        print(output, end='')
        print(errors, end='', file=sys.stderr)
        # Launch Services does not propagate the test process exit status.
        if result.returncode or 'PASS' not in output or 'stack traceback:' in output + errors:
            raise SystemExit('Test did not report success.')


if __name__ == '__main__':
    main()
