"""Generate SteamPipe scripts only; never log in, upload or set a build live."""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SYSTEMS = ("windows", "macos", "linux")

def generate(config, output, templates=False, upload=False):
    ids = [config.get("app_id")] + [config.get("depots", {}).get(s) for s in SYSTEMS]
    if not templates:
        if any(type(i) is not int or i <= 0 for i in ids) or len(set(ids[1:])) != 3:
            raise ValueError("Renseigne l’App ID et trois Depot IDs distincts dans steam/config.local.json.")
    app = str(ids[0]) if ids[0] else "APP_ID_A_RENSEIGNER"
    suffix = ".vdf.template" if templates else ".vdf"
    output.mkdir(parents=True, exist_ok=True)
    refs = []
    for system, depot in zip(SYSTEMS, ids[1:]):
        depot = str(depot) if depot else "DEPOT_" + system.upper() + "_A_RENSEIGNER"
        filename = "depot_" + system + suffix
        # Relative to this script, independent of the directory steamcmd runs in.
        (output / filename).write_text(
            '"DepotBuild"\n{\n'
            f'  "DepotID" "{depot}"\n'
            f'  "ContentRoot" "../content/{system}"\n'
            '  "FileMapping"\n  {\n    "LocalPath" "*"\n    "DepotPath" "."\n    "Recursive" "1"\n  }\n'
            '}\n', encoding="utf-8")
        refs.append(f'    "{depot}" "{filename}"')
    (output / ("app_build" + suffix)).write_text(
        '"AppBuild"\n{\n'
        f'  "AppID" "{app}"\n  "Desc" "Silken Hell - Windows macOS Linux"\n'
        f'  "Preview" "{0 if upload and not templates else 1}"\n'
        '  "ContentRoot" "../content"\n  "BuildOutput" "../build-output"\n'
        '  "Depots"\n  {\n' + "\n".join(refs) + '\n  }\n}\n', encoding="utf-8")

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--config", type=Path, default=ROOT / "steam/config.local.json")
    p.add_argument("--templates", action="store_true")
    p.add_argument("--upload", action="store_true", help="Generate upload scripts, but do not run SteamCMD")
    p.add_argument("--output", type=Path, default=ROOT / "dist/steam/scripts")
    args = p.parse_args()
    config = json.loads(args.config.read_text()) if args.config.exists() else {}
    generate(config, args.output, args.templates, args.upload)
    print(args.output)
