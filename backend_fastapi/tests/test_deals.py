from datetime import timedelta
from decimal import Decimal
from uuid import UUID, uuid4

from sqlalchemy import select

import app.deals as workflow
from app.models import Deal, Property, User, Verification
from app.security import now
from tests.test_marketplace import payload, picture, upload


def administrator(signup, db):
    actor = signup()
    db.get(User, UUID(actor["user"]["id"])).role = "admin"
    db.commit()
    return actor


def employee(client, admin, specialty):
    data = {
        "name": "Synthetic " + specialty,
        "email": f"staff-{uuid4()}@example.com",
        "password": "staff-test-password-only-123",
        "specialty": specialty,
    }
    if specialty == "document_reviewer":
        data["professional_reference"] = "TEST-ONLY-NOT-A-REAL-LICENSE"
    response = client.post("/api/v1/admin/staff", headers=admin["headers"], json=data)
    assert response.status_code == 201, response.text
    session = client.post("/api/v1/auth/login", json={k: data[k] for k in ("email", "password")}).json()
    assert session["user"]["staffRole"] == specialty
    return {"id": response.json()["id"], "headers": {"Authorization": "Bearer " + session["accessToken"]}}


def verified_sale(client, db, owner, admin, category="sale_cash", values=None):
    response = client.post(
        "/api/v1/properties", headers=owner["headers"], json=payload(category) | {"price": "2000000"} | (values or {})
    )
    assert response.status_code == 201, response.text
    identity = response.json()["id"]
    photos = [upload(client, owner["headers"], "photo").json()["id"] for _ in range(2)]
    assert client.put(f"/api/v1/properties/{identity}/photos", headers=owner["headers"], json=photos).status_code == 200
    card = upload(client, owner["headers"], "identity", national_id="30001011234567", birth_date="2000-01-01").json()[
        "id"
    ]
    proof = upload(client, owner["headers"], "ownership").json()["id"]
    assert (
        client.post(
            f"/api/v1/properties/{identity}/submit",
            headers=owner["headers"],
            json={"identity_asset_id": card, "ownership_asset_id": proof},
        ).status_code
        == 200
    )
    db.expire_all()
    verification = db.scalar(select(Verification).where(Verification.property_id == UUID(identity)))
    assert (
        client.post(
            f"/api/v1/admin/verifications/{verification.id}/review",
            headers=admin["headers"],
            json={"approved": True, "note": "Synthetic fixtures approved in isolated test only"},
        ).status_code
        == 200
    )
    return identity, card


def terms(client, admin):
    data = {
        "version": "TEST-" + uuid4().hex,
        "body_ar": "TEST ONLY synthetic brokerage content, not legal terms. " * 4,
        "body_en": "TEST ONLY synthetic brokerage content, not legal terms. " * 4,
        "due_condition": "TEST ONLY: commission due on a synthetic completed contract.",
        "legal_reference": "TEST ONLY external review reference",
        "legal_reviewed": True,
    }
    response = client.post("/api/v1/admin/brokerage-terms", headers=admin["headers"], json=data)
    assert response.status_code == 201, response.text
    return data


def attended_viewing(client, db, deal, owner, buyer, admin, agent, monkeypatch):
    when = (now() + timedelta(days=2)).replace(minute=0, second=0, microsecond=0)
    response = client.post(
        f"/api/v1/deals/{deal}/viewings", headers=buyer["headers"], json={"scheduled_at": when.isoformat()}
    )
    assert response.status_code == 201, response.text
    identity = response.json()["viewings"][0]["id"]
    assert client.post(f"/api/v1/viewings/{identity}/owner-confirm", headers=owner["headers"]).status_code == 200
    assert (
        client.put(
            f"/api/v1/admin/viewings/{identity}/assign", headers=admin["headers"], json={"staff_id": agent["id"]}
        ).status_code
        == 200
    )
    note = {"note": "Synthetic attendance checked; no real-world attendance implied."}
    assert client.post(f"/api/v1/viewings/{identity}/complete", headers=agent["headers"], json=note).status_code == 409
    monkeypatch.setattr(workflow, "now", lambda: when + timedelta(hours=1))
    assert client.post(f"/api/v1/viewings/{identity}/complete", headers=agent["headers"], json=note).status_code == 200
    return identity


def test_complete_supervised_sale_fixed_split_fee_and_manual_payment_verification(client, db, signup, monkeypatch):
    admin = administrator(signup, db)
    owner, buyer, outsider = signup(["owner_sale_cash"]), signup(["buyer_cash"]), signup()
    agent, reviewer = employee(client, admin, "field_agent"), employee(client, admin, "document_reviewer")
    identity, card = verified_sale(client, db, owner, admin)
    assert client.put(f"/api/v1/favorites/{identity}", headers=buyer["headers"]).status_code == 204
    response = client.post("/api/v1/deals", headers=buyer["headers"], json={"property_id": identity})
    assert response.status_code == 201, response.text
    deal = response.json()["id"]
    assert (
        response.json()["fee_total"] == "20000.00"
        and response.json()["buyer_fee"] == "10000.00"
        and response.json()["seller_fee"] == "10000.00"
    )
    assert owner["user"]["email"] not in response.text and "national_id" not in response.text
    assert client.get(f"/api/v1/deals/{deal}", headers=outsider["headers"]).status_code == 404
    assert (
        client.post(f"/api/v1/deals/{deal}/offers", headers=buyer["headers"], json={"amount": "1950000"}).status_code
        == 409
    )
    attended_viewing(client, db, deal, owner, buyer, admin, agent, monkeypatch)
    first = client.post(f"/api/v1/deals/{deal}/offers", headers=buyer["headers"], json={"amount": "1950000"})
    assert first.status_code == 201
    counter = client.post(f"/api/v1/deals/{deal}/offers", headers=owner["headers"], json={"amount": "1910000"}).json()
    offer = next(o for o in counter["offers"] if o["status"] == "open")["id"]
    assert (
        client.put(f"/api/v1/offers/{offer}/decision", headers=owner["headers"], json={"approved": True}).status_code
        == 409
    )
    terms(client, admin)
    response = client.put(f"/api/v1/offers/{offer}/decision", headers=buyer["headers"], json={"approved": True})
    assert response.status_code == 200, response.text
    assert response.json()["buyer_total"] == "1910000.00" and response.json()["seller_net"] == "1890000.00"
    assert response.json()["fee_total"] == "20000.00"  # Fixed on the original two million.
    assert (
        client.put(
            f"/api/v1/properties/{identity}/availability", headers=owner["headers"], json={"availability": "sold"}
        ).status_code
        == 409
    )
    assert (
        client.put(f"/api/v1/properties/{identity}", headers=owner["headers"], json=payload("sale_cash")).status_code
        == 409
    )
    assert (
        client.put(
            f"/api/v1/admin/deals/{deal}/reviewer", headers=admin["headers"], json={"staff_id": reviewer["id"]}
        ).status_code
        == 200
    )
    digest = response.json()["terms"]["digest"]
    assert (
        client.post(
            f"/api/v1/deals/{deal}/consent", headers=buyer["headers"], json={"accepted": True, "digest": "0" * 64}
        ).status_code
        == 409
    )
    assert (
        client.post(
            f"/api/v1/deals/{deal}/consent", headers=buyer["headers"], json={"accepted": True, "digest": digest}
        ).status_code
        == 200
    )
    assert client.get(f"/api/v1/deals/{deal}/documents", headers=reviewer["headers"]).status_code == 403
    assert (
        client.post(
            f"/api/v1/deals/{deal}/consent", headers=owner["headers"], json={"accepted": True, "digest": digest}
        ).status_code
        == 200
    )
    assert client.get(f"/api/v1/deals/{deal}/documents", headers=reviewer["headers"]).status_code == 200
    assert client.get(f"/api/v1/deals/{deal}/documents/{card}", headers=reviewer["headers"]).status_code == 200
    assert client.get(f"/api/v1/deals/{deal}/documents/{card}", headers=buyer["headers"]).status_code == 403
    assert client.get(f"/api/v1/deals/{deal}/documents/{card}", headers=agent["headers"]).status_code == 403
    qr = client.post(
        "/api/v1/admin/payment-destination",
        headers=admin["headers"],
        data={"recipient_name": "TEST ONLY - NOT A PAYMENT ACCOUNT"},
        files={"file": ("synthetic.png", picture(), "image/png")},
    )
    assert qr.status_code == 201, qr.text
    assert client.get(f"/api/v1/deals/{deal}/payment-qr", headers=buyer["headers"]).status_code == 409
    review = {
        "approved": True,
        "contract_reference": "TEST-ONLY-SYNTHETIC-CONTRACT",
        "note": "Synthetic reviewer attestation for automated tests, no real legal contract.",
    }
    assert (
        client.post(f"/api/v1/deals/{deal}/contract-review", headers=owner["headers"], json=review).status_code == 403
    )
    approved = client.post(f"/api/v1/deals/{deal}/contract-review", headers=reviewer["headers"], json=review)
    assert approved.status_code == 200, approved.text
    assert client.get(f"/api/v1/deals/{deal}/payment-qr", headers=buyer["headers"]).status_code == 200
    assert client.get(f"/api/v1/deals/{deal}/payment-qr", headers=outsider["headers"]).status_code == 404
    assert client.post(f"/api/v1/admin/deals/{deal}/complete", headers=admin["headers"]).status_code == 409
    reference = "TEST-" + uuid4().hex
    claim = client.post(f"/api/v1/deals/{deal}/payment-claims", headers=buyer["headers"], json={"reference": reference})
    assert claim.status_code == 201, claim.text
    claim_id = claim.json()["claims"][0]["id"]
    assert next(i for i in claim.json()["invoices"] if i["mine"])["status"] == "reported"
    evidence = {"approved": True, "note": "TEST ONLY: external ledger manually reconciled by synthetic administrator."}
    assert (
        client.put(
            f"/api/v1/admin/payment-claims/{claim_id}/review", headers=buyer["headers"], json=evidence
        ).status_code
        == 403
    )
    assert (
        client.put(
            f"/api/v1/admin/payment-claims/{claim_id}/review", headers=admin["headers"], json=evidence
        ).status_code
        == 200
    )
    assert (
        client.post(
            f"/api/v1/deals/{deal}/payment-claims", headers=owner["headers"], json={"reference": reference}
        ).status_code
        == 409
    )
    seller_claim = client.post(
        f"/api/v1/deals/{deal}/payment-claims", headers=owner["headers"], json={"reference": "TEST-" + uuid4().hex}
    )
    assert seller_claim.status_code == 201
    seller_claim_id = seller_claim.json()["claims"][0]["id"]
    assert (
        client.put(
            f"/api/v1/admin/payment-claims/{seller_claim_id}/review", headers=admin["headers"], json=evidence
        ).status_code
        == 200
    )
    finished = client.post(f"/api/v1/admin/deals/{deal}/complete", headers=admin["headers"])
    assert finished.status_code == 200 and finished.json()["stage"] == "completed", finished.text
    assert finished.json()["buyer_remaining_total"] == "1900000.00"
    assert finished.json()["buyer_platform_paid"] == "10000.00"
    assert finished.json()["remaining_platform_buyer"] == "0.00"
    saved = client.get("/api/v1/favorites", headers=buyer["headers"]).json()["items"]
    assert next(p for p in saved if p["id"] == identity)["availability"] == "sold"
    db.expire_all()
    assert db.get(Deal, UUID(deal)).base_price == Decimal("2000000")
    assert db.get(Property, UUID(identity)).availability == "sold"


def test_staff_registration_and_configuration_are_admin_only(client, db, signup):
    ordinary = signup()
    data = {
        "name": "Test field worker",
        "email": f"{uuid4()}@example.com",
        "password": "staff-test-password-only-123",
        "specialty": "field_agent",
    }
    assert client.post("/api/v1/admin/staff", headers=ordinary["headers"], json=data).status_code == 403
    assert client.post("/api/v1/auth/register", json=data | {"role": "admin"}).status_code == 422
    assert client.get("/api/v1/admin/staff", headers=ordinary["headers"]).status_code == 403
    admin = administrator(signup, db)
    actor = employee(client, admin, "field_agent")
    assert (
        client.put(
            f"/api/v1/admin/staff/{actor['id']}", headers=ordinary["headers"], json={"active": False}
        ).status_code
        == 403
    )
    assert (
        client.put(f"/api/v1/admin/staff/{actor['id']}", headers=admin["headers"], json={"active": False}).status_code
        == 200
    )
    profile = client.get("/api/v1/auth/profile", headers=actor["headers"]).json()
    assert profile["staffRole"] is None
    assert (
        client.post(
            "/api/v1/admin/payment-destination",
            headers=ordinary["headers"],
            data={"recipient_name": "Untrusted"},
            files={"file": ("x.png", picture(), "image/png")},
        ).status_code
        == 403
    )
