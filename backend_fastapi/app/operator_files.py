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


def write_operator_login_guides(folder, records):
    """Keep public credentials unambiguous; never mix passwords from two DBs."""
    for environment in ("demo", "main"):
        if environment not in records:
            raise ValueError("Both operator environments are required")
        if any(name not in records[environment] for name in ("fooda", "amr")):
            raise ValueError("Both fixed operator usernames are required")
    public = [
        "بيتي / MyHome — بيانات دخول الموقع والموبايل",
        "استخدم الحسابين دول في نفس صفحة تسجيل الدخول العادية. بعد الدخول هتظهر لوحة الأدمن تلقائيًا.",
        "الموقع: https://myhome.mohamed-fooda-mtf.workers.dev",
        "تصلح أيضًا لنسخة Android الحالية وللويب المحلي على http://localhost:8082",
        "لازم الكمبيوتر وDocker والإنترنت يكونوا شغالين.",
        "البيانات دي لبيئة الموقع demo. بيانات السيرفر المحلي المنفصل موجودة في ADMIN_LOCAL_LOGIN.txt.",
        "كلمات المرور أولية؛ لو غيّرتها من البروفايل استخدم كلمتك الجديدة. لا تشارك هذا الملف.",
    ]
    local = [
        "بيتي / MyHome — السيرفر المحلي المنفصل فقط (main)",
        "هذه البيانات لا تعمل على الموقع العام أو APK المتصل بالموقع.",
        "API: http://127.0.0.1:3000/api/v1",
        "استخدمها فقط مع Flutter الموجّه صراحةً إلى هذا الـAPI.",
        "للدخول المعتاد على الموقع والموبايل افتح ADMIN_LOGIN.txt.",
        "كلمات المرور أولية؛ بعد تغييرها استخدم اختيارك الجديد. لا تشارك هذا الملف.",
    ]
    for environment, lines in (("demo", public), ("main", local)):
        for name in ("fooda", "amr"):
            lines.extend(["", f"Username: {name}", f"Initial password: {records[environment][name]['password']}"])
    write_private(folder / "ADMIN_LOGIN.txt", "\n".join(public) + "\n")
    write_private(folder / "ADMIN_LOCAL_LOGIN.txt", "\n".join(local) + "\n")
