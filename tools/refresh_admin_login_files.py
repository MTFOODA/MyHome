"""Refresh the private instructions only; no database or password changes."""

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "backend_fastapi"))
from app.operator_files import secure_folder, write_operator_login_guides


def main():
    folder = ROOT / "admin"
    if subprocess.run(
        ["git", "check-ignore", "-q", str(folder / "operators.json")],
        cwd=ROOT,
        check=False,
    ).returncode:
        raise RuntimeError("The credentials directory must stay ignored")
    records = json.loads((folder / "operators.json").read_text(encoding="utf-8"))
    secure_folder(folder)
    write_operator_login_guides(folder, records)
    print(
        "Public/mobile credentials: admin/ADMIN_LOGIN.txt; separate local API: admin/ADMIN_LOCAL_LOGIN.txt. No password changed."
    )


if __name__ == "__main__":
    main()
