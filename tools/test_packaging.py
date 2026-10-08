import json
from pathlib import Path
import tempfile
import unittest
import zipfile
from steam_config import generate
from build_desktop import unzip, zip_tree

class PackagingTests(unittest.TestCase):
    def test_steam_ids_preview_and_roots(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            with self.assertRaises(ValueError):
                generate({}, root)
            generate({}, root, templates=True)
            self.assertFalse(list(root.glob("*.vdf")))
            cfg = {"app_id": 123, "depots": {"windows": 124, "macos": 125, "linux": 126}}
            generate(cfg, root)
            script = (root / "app_build.vdf").read_text()
            self.assertIn('"Preview" "1"', script)
            self.assertNotIn("SetLive", script)
            for system in cfg["depots"]:
                self.assertIn(f'"ContentRoot" "../content/{system}"', (root / f"depot_{system}.vdf").read_text())
            generate(cfg, root, upload=True)
            self.assertIn('"Preview" "0"', (root / "app_build.vdf").read_text())
            cfg["depots"]["linux"] = 124
            with self.assertRaises(ValueError): generate(cfg, root)

    def test_safe_archive_and_symlinks(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            with zipfile.ZipFile(root / "unsafe.zip", "w") as z:
                z.writestr("../escaped", "bad")
            with self.assertRaises(ValueError): unzip(root / "unsafe.zip", root / "out")
            original = root / "original";original.mkdir()
            (original / "binary").write_text("data")
            (original / "binary").chmod(0o755)
            (original / "link").symlink_to("binary")
            zip_tree(original, root / "safe.zip")
            unzip(root / "safe.zip", root / "unpacked")
            self.assertTrue((root / "unpacked/link").is_symlink())
            self.assertEqual((root / "unpacked/link").read_text(), "data")
            self.assertEqual((root / "unpacked/binary").stat().st_mode & 0o777, 0o755)

if __name__ == "__main__": unittest.main()
