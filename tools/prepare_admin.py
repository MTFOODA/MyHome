"""Back up, then reconcile only fooda/amr. Never print/reset chosen passwords."""

import json
import os
import secrets
import subprocess
import sys
from datetime import datetime
from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from sqlalchemy.orm import Session

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "backend_fastapi"))
from app.admin_cli import reconcile_operators
from app.operator_files import secure_folder, write_private


def main():
    folder = ROOT / "admin"
    if subprocess.run(
        ["git", "check-ignore", "-q", str(folder / "operators.json")],
        cwd=ROOT,
        check=False,
    ).returncode:
        raise RuntimeError("Ignore admin/ before provisioning")
    folder.mkdir(exist_ok=True, mode=0o700)
    secure_folder(folder)
    path = folder / "operators.json"
    records = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}
    settings = dict(
        line.split("=", 1)
        for line in (ROOT / "infrastructure/.env")
        .read_text(encoding="utf-8-sig")
        .splitlines()
        if "=" in line and not line.startswith("#")
    )
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    (ROOT / "artifacts").mkdir(exist_ok=True)
    for database in ("myhome", "myhome_demo"):
        backup = ROOT / "artifacts" / f"{database}-before-fixed-operators-{stamp}.dump"
        with backup.open("wb") as output:
            subprocess.run(
                [
                    "docker",
                    "compose",
                    "--env-file",
                    "infrastructure/.env",
                    "-f",
                    "infrastructure/compose.yaml",
                    "exec",
                    "-T",
                    "postgres",
                    "pg_dump",
                    "-U",
                    "postgres",
                    "-Fc",
                    database,
                ],
                cwd=ROOT,
                stdout=output,
                check=True,
            )
        if backup.stat().st_size < 1000:
            raise RuntimeError("Database backup is unexpectedly small")
    # Both backups must finish before either schema or account is changed.
    for database in ("myhome", "myhome_demo"):
        migration_env = os.environ.copy()
        migration_env.update(
            DATABASE_URL=URL.create(
                "postgresql+psycopg",
                username="postgres",
                password=settings["POSTGRES_PASSWORD"],
                host="127.0.0.1",
                port=int(settings.get("POSTGRES_PORT", "55432")),
                database=database,
            ).render_as_string(hide_password=False),
            JWT_SECRET=settings["JWT_SECRET"],
            DOCUMENT_KEY=settings["DOCUMENT_KEY"],
        )
        subprocess.run(
            [sys.executable, "-m", "alembic", "upgrade", "head"],
            cwd=ROOT / "backend_fastapi",
            env=migration_env,
            check=True,
        )
    reports = {}
    for environment, database in (("main", "myhome"), ("demo", "myhome_demo")):
        operators = records.setdefault(environment, {})
        for name in ("fooda", "amr"):
            operators.setdefault(
                name, {"username": name, "password": secrets.token_urlsafe(30)}
            )
        write_private(path, json.dumps(records, indent=2) + "\n")
        engine = create_engine(
            URL.create(
                "postgresql+psycopg",
                username="myhome",
                password=settings["APP_DB_PASSWORD"],
                host="127.0.0.1",
                port=int(settings.get("POSTGRES_PORT", "55432")),
                database=database,
            ),
            hide_parameters=True,
        )
        try:
            with Session(engine) as db:
                reports[environment] = reconcile_operators(
                    db, {name: record["password"] for name, record in operators.items()}
                )
        finally:
            engine.dispose()
    lines = [
        "MyHome / بيتي — fooda و amr فقط",
        "الدخول باسم المستخدم. كلمات المرور أولية؛ بعد تغييرها استخدم اختيارك الجديد.",
        "الموقع والموبايل الحاليان يستخدمان حسابات demo. لا تشارك هذا الملف.",
    ]
    for environment, operators in records.items():
        lines.extend(["", environment])
        for name, record in operators.items():
            lines.extend(
                [f"Username: {name}", f"Initial password: {record['password']}"]
            )
    write_private(folder / "ADMIN_LOGIN.txt", "\n".join(lines) + "\n")
    write_private(folder / "credentials.json", json.dumps(records, indent=2) + "\n")
    (ROOT / "artifacts/fixed-operators-report.json").write_text(
        json.dumps(reports, indent=2)
    )
    print(
        "Only fooda/amr are administrators. Old logins revoked; history retained. Open admin/ADMIN_LOGIN.txt."
    )


if __name__ == "__main__":
    main()
