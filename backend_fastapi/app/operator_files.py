"""Local credential files, deliberately outside API and Flutter asset roots."""

import csv
import os
import subprocess


def write_private(path, text):
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(text, encoding="utf-8")
    temporary.chmod(0o600)
    temporary.replace(path)


def secure_folder(folder):
    folder.mkdir(exist_ok=True, parents=True, mode=0o700)
    if os.name == "nt":
        sid = next(
            csv.reader(subprocess.check_output(["whoami", "/user", "/fo", "csv", "/nh"], text=True).splitlines())
        )[1]
        subprocess.run(
            [
                "icacls",
                str(folder),
                "/inheritance:r",
                "/grant:r",
                f"*{sid}:(OI)(CI)F",
                "*S-1-5-18:(OI)(CI)F",
                "*S-1-5-32-544:(OI)(CI)F",
            ],
            check=True,
            stdout=subprocess.DEVNULL,
        )
    else:
        folder.chmod(0o700)
