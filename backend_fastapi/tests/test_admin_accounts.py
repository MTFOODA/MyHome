from uuid import UUID, uuid4

import bcrypt
import pytest
from sqlalchemy import func, select

from app.admin_cli import reconcile_operators
from app.models import AuditEvent, User
from tests.test_deals import administrator


def body(kind="field_agent"):
    return {
        "name": "Internal Test Account",
        "email": f"team-{uuid4()}@example.com",
        "password": "internal-account-test-123",
        "specialty": kind,
        **({"professional_reference": "TEST-REFERENCE-NOT-A-LICENSE"} if kind == "document_reviewer" else {}),
    }


@pytest.mark.parametrize("kind", ["document_reviewer", "field_agent"])
def test_admin_creates_internal_accounts_with_correct_authority(client, db, signup, kind):
    admin = administrator(signup, db)
    data = body(kind)
    response = client.post("/api/v1/admin/staff", headers=admin["headers"], json=data)
    assert response.status_code == 201, response.text
    identity = UUID(response.json()["id"])
    account = db.get(User, identity)
    assert account.role == "user"
    assert not account.owner_verified and account.onboarding_complete
    assert "password" not in response.json() and "password_hash" not in response.json()
    login = client.post("/api/v1/auth/login", json={key: data[key] for key in ("email", "password")}).json()
    assert login["user"]["staffRole"] == kind
    rows = client.get("/api/v1/admin/staff", headers=admin["headers"]).json()["items"]
    assert any(row["id"] == str(identity) and row["specialty"] == kind for row in rows)
    assert db.scalar(
        select(AuditEvent.id).where(
            AuditEvent.actor_id == UUID(admin["user"]["id"]),
            AuditEvent.target_id == identity,
            AuditEvent.action == "staff.created",
        )
    )
    own_headers = {"Authorization": "Bearer " + login["accessToken"]}
    created = client.post("/api/v1/admin/staff", headers=own_headers, json=body())
    assert created.status_code == 403


def test_internal_creation_is_not_public_and_duplicate_email_is_safe(client, db, signup):
    ordinary = signup(["owner_sale_cash"])
    assert client.post("/api/v1/admin/staff", json=body()).status_code == 401
    assert client.post("/api/v1/admin/staff", headers=ordinary["headers"], json=body()).status_code == 403
    assert client.get("/api/v1/admin/staff", headers=ordinary["headers"]).status_code == 403
    data = body()
    assert client.post("/api/v1/auth/register", json=data).status_code == 422
    admin = administrator(signup, db)
    first = client.post("/api/v1/admin/staff", headers=admin["headers"], json=data)
    assert first.status_code == 201
    assert client.post("/api/v1/admin/staff", headers=admin["headers"], json=data).status_code == 409


@pytest.mark.parametrize(
    "changes",
    [
        {"specialty": "root"},
        {"specialty": "admin"},
        {"name": "  "},
        {"password": "short"},
        {"email": "bad"},
        {"password": "ع" * 40},
        {"specialty": "document_reviewer"},
    ],
)
def test_internal_accounts_validate_input(client, db, signup, changes):
    admin = administrator(signup, db)
    assert client.post("/api/v1/admin/staff", headers=admin["headers"], json=body() | changes).status_code == 422


def test_fixed_admins_retire_old_authority_keep_history_and_preserve_chosen_password(client, db, signup):
    admin = administrator(signup, db)
    old = db.get(User, UUID(admin["user"]["id"]))
    old_hash = old.password_hash
    passwords = {"fooda": "initial-fooda-test-123", "amr": "initial-amr-test-123"}
    # The isolated test DB is intentionally reusable; initialize known fixture
    # passwords only here, never through the production reconciliation function.
    for name, password in passwords.items():
        existing = db.scalar(select(User).where(User.username == name))
        if existing:
            existing.password_hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt(12)).decode()
    db.commit()
    result = reconcile_operators(db, passwords)
    assert result["active_admin_usernames"] == ["fooda", "amr"]
    assert not old.active and old.role == "user" and old.password_hash == old_hash
    assert client.get("/api/v1/auth/profile", headers=admin["headers"]).status_code == 401
    for name in passwords:
        user = db.scalar(select(User).where(User.username == name))
        login = client.post("/api/v1/auth/login", json={"email": name.upper(), "password": passwords[name]})
        assert login.status_code == 200 and login.json()["user"]["username"] == name
        assert (
            client.post("/api/v1/auth/login", json={"email": user.email, "password": passwords[name]}).status_code
            == 401
        )
    chosen = "a-new-operator-password-123"
    headers = {"Authorization": "Bearer " + login.json()["accessToken"]}
    assert (
        client.post(
            "/api/v1/auth/password",
            headers=headers,
            json={"current_password": passwords["amr"], "new_password": chosen},
        ).status_code
        == 204
    )
    db.expire_all()
    fingerprints = {u.username: u.password_hash for u in db.scalars(select(User).where(User.role == "admin"))}
    again = reconcile_operators(db, passwords)
    assert again["created"] == []
    assert fingerprints == {u.username: u.password_hash for u in db.scalars(select(User).where(User.role == "admin"))}
    assert db.scalar(select(func.count()).select_from(User).where(User.role == "admin", User.active.is_(True))) == 2
    assert client.post("/api/v1/auth/login", json={"email": "amr", "password": chosen}).status_code == 200
