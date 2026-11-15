"""Create independent, ignored demo signing/encryption keys without replacing them."""
import base64
from pathlib import Path
import secrets

destination = Path(__file__).resolve().parents[1] / "infrastructure/.env.demo"
try:
    with destination.open("x", encoding="utf-8") as file:
        file.write(f"DEMO_JWT_SECRET={secrets.token_hex(48)}\n")
        file.write(f"DEMO_DOCUMENT_KEY={base64.urlsafe_b64encode(secrets.token_bytes(32)).decode()}\n")
except FileExistsError:
    print("Existing demo keys retained.")
else:
    print("Created private infrastructure/.env.demo keys.")
