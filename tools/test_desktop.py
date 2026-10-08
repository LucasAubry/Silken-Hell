"""Run native integration tests; also used by the three-OS CI matrix."""
import os
import argparse
from pathlib import Path
import shutil
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--standalone", choices=["windows", "macos", "linux"])
args = parser.parse_args()
runtime = os.environ.get("LOVE_BIN") or shutil.which("love")
if not runtime and sys.platform == "darwin":
    runtime = str(Path.home() / "Library/Application Support/Silken Hell/runtime/love.app/Contents/MacOS/love")
if not runtime and not args.standalone:
    raise SystemExit("Install LÖVE 11.5 or set LOVE_BIN.")
archive = str(root / "dist/game.love")
if args.standalone:
    folder = root / "dist/steam/content" / args.standalone
    runtime = str(folder / {"windows": "SilkenHell.exe", "macos": "Silken Hell.app/Contents/MacOS/love", "linux": "SilkenHell.sh"}[args.standalone])
    base = [runtime]
else:
    base = [runtime, archive]
standalone = args.standalone
prefix = ["xvfb-run", "-a"] if sys.platform.startswith("linux") and not os.environ.get("DISPLAY") else []
tests = [
    ({"SILKEN_TEST": "1", "SILKEN_PLATFORM_TEST": "1"}, []),
    ({"SILKEN_TEST": "1", "SILKEN_WORKSHOP_ACCESS_TEST": "1"}, []),
    ({"SILKEN_TEST": "1", "SILKEN_CREATOR_PROJECT_TEST": "1"}, []),
    ({"SILKEN_TEST": "1", "SILKEN_RICOCHET_TEST": "1"}, []),
    ({"SILKEN_DESIGNER_TEST": "1", "SILKEN_CREATOR_PROJECT_TEST": "1"}, ["--editor"]),
]
for flags, args in tests:
    env = {k: v for k, v in os.environ.items() if not k.startswith("SILKEN_")}
    env.update(flags)
    if standalone and flags.get("SILKEN_PLATFORM_TEST"): env["SILKEN_PLATFORM_HTTP_TEST"] = "1"
    if os.environ.get("CI"): env["ALSOFT_DRIVERS"] = "null"
    print("Testing", ", ".join(flags), *args, flush=True)
    subprocess.run(prefix + base + args, cwd=root, env=env, check=True, timeout=180)
