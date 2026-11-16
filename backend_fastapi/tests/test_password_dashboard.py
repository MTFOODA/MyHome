from concurrent.futures import ThreadPoolExecutor
from threading import Barrier
from uuid import UUID, uuid4

from sqlalchemy import select

from app.models import (
    AuditEvent,
    Deal,
    FeeInvoice,
    PaymentClaim,
    Property,
    StaffMember,
    User,
    UserIntent,
    Verification,
    Viewing,
)
from app.security import now
from tests.test_deals import administrator, verified_sale
from tests.test_marketplace import payload


def test_password_change_checks_old_password_and_revokes_other_sessions(client, db, signup):
    user = signup()
    previous = "password-for-tests-123"
    second = client.post("/api/v1/auth/login", json={"email": user["user"]["email"], "password": previous}).json()
    second_headers = {"Authorization": "Bearer " + second["accessToken"]}

    def change(old, new):
        return client.post(
            "/api/v1/auth/password", headers=user["headers"], json={"current_password": old, "new_password": new}
        )

    assert (
        client.post(
            "/api/v1/auth/password", json={"current_password": previous, "new_password": "new-password-123"}
        ).status_code
        == 401
    )
    assert change("wrong-password", "new-password-123").json()["detail"] == "CURRENT_PASSWORD_INCORRECT"
    assert change(previous, previous).json()["detail"] == "NEW_PASSWORD_SAME"
    assert change(previous, "short").status_code == 422
    assert change(previous, "ع" * 40).status_code == 422
    assert change(previous, "new-password-123").status_code == 204
    assert client.get("/api/v1/auth/profile", headers=user["headers"]).status_code == 200
    assert client.get("/api/v1/auth/profile", headers=second_headers).status_code == 401
    assert client.post("/api/v1/auth/refresh", json={"refreshToken": second["refreshToken"]}).status_code == 401
    assert (
        client.post("/api/v1/auth/login", json={"email": user["user"]["email"], "password": previous}).status_code
        == 401
    )
    result = client.post("/api/v1/auth/login", json={"email": user["user"]["email"], "password": "new-password-123"})
    assert result.status_code == 200 and "password" not in result.text
    assert db.scalar(
        select(AuditEvent.id).where(
            AuditEvent.actor_id == UUID(user["user"]["id"]), AuditEvent.action == "account.password_changed"
        )
    )


def test_dashboard_counts_people_once_per_category_excludes_staff_and_inactive(client, db, signup):
    admin = administrator(signup, db)
    assert client.get("/api/v1/admin/dashboard").status_code == 401
    ordinary = signup()
    assert client.get("/api/v1/admin/dashboard", headers=ordinary["headers"]).status_code == 403

    def counts():
        response = client.get("/api/v1/admin/dashboard", headers=admin["headers"])
        assert response.status_code == 200
        assert all(type(value) is int and value >= 0 for value in response.json().values())
        return response.json()

    baseline = counts()
    signup(
        [
            "owner_sale_cash",
            "owner_private_rental",
            "buyer_cash",
            "buyer_installments",
            "tenant_private",
            "tenant_shared",
        ]
    )
    staff = signup(["owner_sale_cash", "buyer_cash", "tenant_private"])
    db.add(StaffMember(user_id=UUID(staff["user"]["id"]), specialty="field_agent"))
    disabled = signup(["owner_sale_cash", "buyer_cash", "tenant_private"])
    db.get(User, UUID(disabled["user"]["id"])).active = False
    db.commit()
    result = counts()
    for key in ("owners", "buyers", "renters"):
        assert result[key] == baseline[key] + 1


def test_concurrent_password_changes_allow_only_one_old_password_and_no_deadlock(client, signup):
    user = signup()
    second = client.post(
        "/api/v1/auth/login", json={"email": user["user"]["email"], "password": "password-for-tests-123"}
    ).json()
    gate = Barrier(2)

    def change(index):
        gate.wait(timeout=10)
        token = user["accessToken"] if index == 0 else second["accessToken"]
        result = client.post(
            "/api/v1/auth/password",
            headers={"Authorization": "Bearer " + token},
            json={"current_password": "password-for-tests-123", "new_password": f"new-concurrent-password-{index}"},
        )
        return index, result.status_code

    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(change, (0, 1)))
    assert sorted(status for _, status in results) in ([204, 400], [204, 401])
    winner = next(index for index, status in results if status == 204)
    assert (
        client.post(
            "/api/v1/auth/login", json={"email": user["user"]["email"], "password": f"new-concurrent-password-{winner}"}
        ).status_code
        == 200
    )


def test_admin_cannot_become_owner_and_review_badge_clears_after_decision(client, db, signup):
    admin = administrator(signup, db)
    db.add(UserIntent(user_id=UUID(admin["user"]["id"]), intent="owner_sale_cash"))
    db.commit()
    assert (
        client.put(
            "/api/v1/auth/intents",
            headers=admin["headers"],
            json={"intents": ["owner_sale_cash"], "activeIntent": "owner_sale_cash"},
        ).status_code
        == 403
    )
    assert client.post("/api/v1/properties", headers=admin["headers"], json=payload("sale_cash")).status_code == 403
    baseline = client.get("/api/v1/admin/dashboard", headers=admin["headers"]).json()
    owner = signup(["owner_sale_cash"])
    identity, _ = verified_sale(client, db, owner, admin)
    prop = db.get(Property, UUID(identity))
    verification = db.scalar(select(Verification).where(Verification.property_id == prop.id))
    prop.status, verification.status = "pending", "pending"
    db.commit()
    waiting = client.get("/api/v1/admin/dashboard", headers=admin["headers"]).json()
    assert waiting["property_reviews"] == baseline["property_reviews"] + 1
    assert (
        client.post(
            f"/api/v1/admin/verifications/{verification.id}/review",
            headers=admin["headers"],
            json={"approved": True, "note": "Synthetic isolated review decision for dashboard test"},
        ).status_code
        == 200
    )
    result = client.get("/api/v1/admin/dashboard", headers=admin["headers"]).json()
    assert result["properties"] == baseline["properties"] + 1
    assert result["published_properties"] == baseline["published_properties"] + 1
    assert result["property_reviews"] == baseline["property_reviews"]
    assert result["pending_total"] == sum(
        result[key]
        for key in (
            "property_reviews",
            "eligibility_reviews",
            "payment_reviews",
            "contract_reviews",
            "viewing_assignments",
        )
    )


def test_deal_review_counters_track_only_pending_actions(client, db, signup):
    admin = administrator(signup, db)
    owner, buyer = signup(["owner_sale_cash"]), signup(["buyer_cash"])
    identity, _ = verified_sale(client, db, owner, admin)
    result = client.post("/api/v1/deals", headers=buyer["headers"], json={"property_id": identity})
    assert result.status_code == 201
    deal = db.get(Deal, UUID(result.json()["id"]))
    baseline = client.get("/api/v1/admin/dashboard", headers=admin["headers"]).json()
    deal.stage = "accepted"
    viewing = Viewing(
        deal_id=deal.id, reference=uuid4().hex, scheduled_at=now(), status="confirmed", owner_confirmed=True
    )
    invoice = FeeInvoice(deal_id=deal.id, payer_id=UUID(buyer["user"]["id"]), amount=deal.buyer_fee)
    db.add_all([viewing, invoice])
    db.flush()
    claim = PaymentClaim(invoice_id=invoice.id, reference=uuid4().hex)
    db.add(claim)
    db.commit()
    pending = client.get("/api/v1/admin/dashboard", headers=admin["headers"]).json()
    for key in ("contract_reviews", "viewing_assignments", "payment_reviews"):
        assert pending[key] == baseline[key] + 1
    assert pending["deal_actions"] == baseline["deal_actions"] + 3
    deal.review_status, viewing.status, claim.status = "approved", "completed", "verified"
    invoice.status = "verified"
    db.commit()
    resolved = client.get("/api/v1/admin/dashboard", headers=admin["headers"]).json()
    for key in ("contract_reviews", "viewing_assignments", "payment_reviews", "deal_actions"):
        assert resolved[key] == baseline[key]
