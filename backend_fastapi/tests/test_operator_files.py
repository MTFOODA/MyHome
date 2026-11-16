import tempfile
import unittest
from pathlib import Path

from app.operator_files import write_operator_login_guides


class OperatorLoginFileTests(unittest.TestCase):
    def test_default_file_contains_only_public_credentials_and_local_file_is_separate(self):
        records = {
            environment: {name: {"password": f"synthetic-{environment}-{name}-test-only"} for name in ("fooda", "amr")}
            for environment in ("main", "demo")
        }
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            write_operator_login_guides(folder, records)
            public = (folder / "ADMIN_LOGIN.txt").read_text(encoding="utf-8")
            local = (folder / "ADMIN_LOCAL_LOGIN.txt").read_text(encoding="utf-8")
            self.assertIn("https://myhome.mohamed-fooda-mtf.workers.dev", public)
            self.assertEqual(public.count("Username:"), 2)
            self.assertEqual(local.count("Username:"), 2)
            for name in ("fooda", "amr"):
                self.assertIn(records["demo"][name]["password"], public)
                self.assertNotIn(records["main"][name]["password"], public)
                self.assertIn(records["main"][name]["password"], local)
                self.assertNotIn(records["demo"][name]["password"], local)

    def test_missing_environment_fails_before_writing_a_partial_guide(self):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            existing = folder / "ADMIN_LOGIN.txt"
            existing.write_text("keep previous instructions", encoding="utf-8")
            with self.assertRaises(ValueError):
                write_operator_login_guides(folder, {"demo": {}})
            self.assertEqual(existing.read_text(), "keep previous instructions")
            self.assertFalse((folder / "ADMIN_LOCAL_LOGIN.txt").exists())
