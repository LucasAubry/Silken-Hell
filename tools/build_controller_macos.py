"""Build the optional macOS USB controller backend (Intel + Apple Silicon).

SDL is used only for input; LÖVE keeps its existing video/audio/runtime.
libusb remains a separate, replaceable LGPL library. Sources are pinned in
 desktop_dependencies.json; no Steam installation or Steam files are used.
"""
from pathlib import Path
import os
import shutil
import subprocess
import tarfile
import tempfile
import sys
from build_desktop import download, ROOT


def run(args, **kwargs):
    subprocess.run(args, check=True, **kwargs)


def build():
    if sys.platform != 'darwin':
        raise RuntimeError('Build this universal backend on macOS.')
    output = ROOT / 'assets/native/macos'
    with tempfile.TemporaryDirectory(prefix='silken-input-') as tmp:
        work = Path(tmp)
        for key in ('sdl3-input-source', 'libusb-input-source'):
            with tarfile.open(download(key)) as archive:
                archive.extractall(work, filter='data')
        usb = work / 'libusb-1.0.30'
        sdl = work / 'SDL3-3.4.18'
        prefix = work / 'prefix'
        flags = '-O2 -arch arm64 -arch x86_64 -mmacosx-version-min=11.0'
        env = dict(os.environ, CFLAGS=flags, LDFLAGS=flags)
        run([str(usb / 'configure'), '--prefix=' + str(prefix), '--enable-shared', '--disable-static'], cwd=usb, env=env)
        run(['make', '-j4'], cwd=usb)
        run(['make', 'install'], cwd=usb)
        # Link to the replaceable dynamic libusb directly, with a relative install name.
        usb_lib = prefix / 'lib/libusb-1.0.0.dylib'
        run(['install_name_tool', '-id', '@loader_path/libusb-1.0.0.dylib', str(usb_lib)])
        env = dict(os.environ, PKG_CONFIG_PATH=str(prefix / 'lib/pkgconfig'))
        run(['cmake', '-S', str(sdl), '-B', str(work / 'sdl-build'),
             '-DCMAKE_BUILD_TYPE=Release', '-DCMAKE_OSX_ARCHITECTURES=arm64;x86_64',
             '-DCMAKE_OSX_DEPLOYMENT_TARGET=11.0', '-DSDL_SHARED=ON', '-DSDL_STATIC=OFF',
             '-DSDL_TESTS=OFF', '-DSDL_EXAMPLES=OFF', '-DSDL_TEST_LIBRARY=OFF',
             '-DSDL_VIDEO=OFF', '-DSDL_RENDER=OFF', '-DSDL_GPU=OFF', '-DSDL_AUDIO=OFF',
             '-DSDL_CAMERA=OFF', '-DSDL_DIALOG=OFF', '-DSDL_TRAY=OFF',
             '-DSDL_HIDAPI_LIBUSB=ON', '-DSDL_HIDAPI_LIBUSB_SHARED=OFF',
             '-DCMAKE_PREFIX_PATH=' + str(prefix)], env=env)
        run(['cmake', '--build', str(work / 'sdl-build'), '--parallel', '4'])
        output.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(work / 'sdl-build/libSDL3.0.dylib', output / 'libSDL3.0.dylib')
        shutil.copyfile(usb_lib, output / 'libusb-1.0.0.dylib')
        shutil.copyfile(sdl / 'LICENSE.txt', output / 'SDL-LICENSE.txt')
        shutil.copyfile(usb / 'COPYING', output / 'libusb-COPYING.txt')
        shutil.copyfile(download('libusb-input-source'), output / 'libusb-1.0.30.tar.bz2')
        for name in ('libSDL3.0.dylib', 'libusb-1.0.0.dylib'):
            run(['codesign', '--force', '--sign', '-', '--timestamp=none', str(output / name)])
            run(['lipo', str(output / name), '-verify_arch', 'arm64', 'x86_64'])
        dependencies = subprocess.check_output(['otool', '-L', str(output / 'libSDL3.0.dylib')], text=True)
        if '@loader_path/libusb-1.0.0.dylib' not in dependencies or str(work) in dependencies:
            raise RuntimeError('The backend must link its bundled libusb, never a build-machine path.')
    print('PASS macOS USB input backend built for Intel and Apple Silicon')


if __name__ == '__main__':
    build()
