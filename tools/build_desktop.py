"""Build standalone Steam depot folders. No Steam account or upload is used."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import plistlib
import shutil
import stat
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
LOCK = json.loads((ROOT / "tools/desktop_dependencies.json").read_text())
CACHE = ROOT / "dist/downloads"
CONTENT = ROOT / "dist/steam/content"
LAUNCH = {"windows": "SilkenHell.exe", "macos": "Silken Hell.app", "linux": "SilkenHell.sh"}

def download(key):
    spec = LOCK[key]
    path = CACHE / spec["url"].rsplit("/", 1)[-1]
    CACHE.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        tmp = path.with_suffix(path.suffix + ".part")
        with urllib.request.urlopen(spec["url"], timeout=120) as response, tmp.open("wb") as out:
            shutil.copyfileobj(response, out)
        tmp.replace(path)
    if hashlib.sha256(path.read_bytes()).hexdigest() != spec["sha256"]:
        raise RuntimeError(f"Checksum mismatch: {path}. No binary will be packaged.")
    return path

def unzip(source, destination):
    destination.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(source) as z:
        for item in z.infolist():
            target = destination / item.filename
            if not target.resolve().is_relative_to(destination.resolve()):
                raise ValueError("Unsafe archive member")
            mode = item.external_attr >> 16
            if item.is_dir():
                target.mkdir(parents=True, exist_ok=True)
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                data = z.read(item)
                if stat.S_ISLNK(mode):
                    link = data.decode()
                    if not (target.parent / link).resolve().is_relative_to(destination.resolve()):
                        raise ValueError("Unsafe archive symlink")
                    target.symlink_to(link)
                else:
                    target.write_bytes(data)
                    target.chmod((mode & 0o777) or 0o644)

def zip_tree(folder, output):
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as z:
        for path in sorted(folder.rglob("*")):
            name = path.relative_to(folder).as_posix()
            if path.is_symlink():
                info = zipfile.ZipInfo(name)
                info.create_system = 3
                info.external_attr = (stat.S_IFLNK | 0o777) << 16
                z.writestr(info, os.readlink(path))
            elif path.is_file():
                z.write(path, name)

def manifest(folder, platform):
    files = {}
    for path in sorted(folder.rglob("*")):
        if path.is_file() and not path.is_symlink():
            files[path.relative_to(folder).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
    data = {"platform": platform, "love": "11.5", "launch": LAUNCH[platform],
            "commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
            "steam_uploaded": False, "files": files}
    (folder / "build-manifest.json").write_text(json.dumps(data, indent=2) + "\n")

def windows(folder, work):
    unzip(download("love-windows"), work / "love")
    runtime = next((work / "love").glob("love-*"))
    for item in runtime.iterdir():
        if item.suffix.lower() == ".dll" or item.name == "license.txt":
            shutil.copy2(item, folder / item.name)
    with (folder / "SilkenHell.exe").open("wb") as out:
        for source in (runtime / "love.exe", ROOT / "dist/game.love"):
            with source.open("rb") as f: shutil.copyfileobj(f, out)
    unzip(download("curl-windows"), work / "curl")
    curl = next((work / "curl").glob("curl-*"))
    network = folder / "network"
    network.mkdir()
    shutil.copy2(curl / "bin/curl.exe", network / "curl.exe")
    shutil.copy2(curl / "bin/curl-ca-bundle.crt", network / "cacert.pem")
    shutil.copytree(curl / "dep", network / "licenses")
    shutil.copy2(curl / "COPYING.txt", network / "licenses/curl.txt")

def macos(folder, work):
    if sys.platform != "darwin":
        raise RuntimeError("Build the macOS app on macOS to sign and verify it.")
    unzip(download("love-macos"), work)
    app = folder / "Silken Hell.app"
    shutil.move(work / "love.app", app)
    resources = app / "Contents/Resources"
    shutil.copy2(ROOT / "dist/game.love", resources / "game.love")
    shutil.copy2(ROOT / "assets/icons/SilkenHell.icns", resources / "GameIcon.icns")
    path = app / "Contents/Info.plist"
    info = plistlib.loads(path.read_bytes())
    info.update(CFBundleIdentifier="com.silkenhell.game", CFBundleName="Silken Hell",
                CFBundleDisplayName="Silken Hell", CFBundleIconFile="GameIcon.icns",
                CFBundleShortVersionString="0.1.0", CFBundleVersion="1")
    # This game must not register itself as the machine's .love file handler.
    info.pop("CFBundleDocumentTypes", None)
    info.pop("UTExportedTypeDeclarations", None)
    info.pop("UTImportedTypeDeclarations", None)
    path.write_bytes(plistlib.dumps(info))
    identity = os.environ.get("MACOS_SIGN_IDENTITY", "-")
    command = ["codesign", "--force", "--deep", "--sign", identity]
    if identity == "-": command += ["--timestamp=none"]
    else: command += ["--options", "runtime", "--timestamp"]
    entitlements = work / "entitlements.plist"
    entitlements.write_bytes(plistlib.dumps({
        "com.apple.security.cs.allow-jit": True,
        "com.apple.security.cs.allow-unsigned-executable-memory": True,
        "com.apple.security.cs.disable-library-validation": True,
    }))
    subprocess.run(["xattr", "-cr", str(app)], check=True)
    subprocess.run(command + ["--entitlements", str(entitlements), str(app)], check=True)
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
    (folder / "SIGNATURE.txt").write_text(
        "Signature locale ad-hoc ; Developer ID et notarisation Apple restent à effectuer.\n"
        if identity == "-" else "Developer ID signé ; notarisation Apple à vérifier avant publication.\n")

def linux(folder, work):
    if not sys.platform.startswith("linux"):
        raise RuntimeError("The Linux bundle is built on Linux (CI provides it).")
    image = download("love-linux")
    image.chmod(0o755)
    subprocess.run([str(image), "--appimage-extract"], cwd=work, check=True, stdout=subprocess.DEVNULL)
    shutil.move(work / "squashfs-root", folder / "runtime")
    # No FUSE mount or system LÖVE installation is needed.
    shutil.copy2(ROOT / "dist/game.love", folder / "game.love")
    curl = ROOT / "dist/linux-network"
    if not (curl / "curl").exists():
        download("curl-source")
        subprocess.run(["docker", "run", "--rm", "-v", f"{ROOT}:/work", "alpine:3.22",
                        "sh", "/work/tools/build_linux_curl.sh"], check=True)
    shutil.copytree(curl, folder / "network")
    shutil.copy2(download("ca-bundle"), folder / "network/cacert.pem")
    (folder / "network/curl").chmod(0o755)
    script = folder / "SilkenHell.sh"
    script.write_text("""#!/bin/sh
set -eu
BASE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export SILKEN_BUNDLE_ROOT="$BASE"
exec "$BASE/runtime/AppRun" "$BASE/game.love" "$@"
""")
    script.chmod(0o755)
    # Fail if the network helper accidentally acquired host-library dependencies.
    probe = subprocess.run(["ldd", str(folder / "network/curl")], capture_output=True, text=True)
    if "=>" in probe.stdout:
        raise RuntimeError("Linux curl must be statically linked")

def build(platform):
    game = ROOT / "dist/game.love"
    if not game.exists(): raise RuntimeError("Run python tools/package.py first")
    CONTENT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="desktop-build-") as tmp:
        work = Path(tmp);folder = work / platform;folder.mkdir()
        globals()[platform](folder, work / "unpack" if platform != "linux" else work)
        manifest(folder, platform)
        final = CONTENT / platform
        if final.exists(): shutil.rmtree(final)
        shutil.move(folder, final)
    archive = ROOT / "dist/steam" / f"Silken-Hell-{platform}.{'tar.gz' if platform == 'linux' else 'zip'}"
    if platform == "linux":
        with tarfile.open(archive, "w:gz") as t: t.add(final, arcname="Silken-Hell")
    else: zip_tree(final, archive)
    print(archive)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--platform", choices=["windows", "macos", "linux"], required=True)
    parser.add_argument("--download-only", action="store_true")
    args = parser.parse_args()
    if args.download_only:
        for key in ("love-" + args.platform, "curl-source" if args.platform == "linux" else "curl-windows" if args.platform == "windows" else "love-macos"):
            print(download(key))
    else: build(args.platform)
