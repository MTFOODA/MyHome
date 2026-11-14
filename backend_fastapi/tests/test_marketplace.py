import io
from datetime import date
from uuid import UUID

import pytest
from PIL import Image
from sqlalchemy import select

from app.assets import compare_ocr, identity_dob
from app.models import User, Verification


def payload(category="private_rental"):
    result = dict(
        title="A spacious apartment",
        description="A bright apartment with enough detail for this test.",
        category=category,
        area_id="maadi",
        approximate_location="Near the main street",
        area_m2="120.00",
        bedrooms=2,
        bathrooms=1,
        capacity=4,
        water=True,
        electricity=True,
        gas=False,
        elevator=False,
        finishing="plastered",
        price="10000.00",
        negotiable=False,
    )
    if category in ("private_rental", "shared_rental"):
        result.update(rental_period="one_year", deposit="5000.00")
    if category == "sale_installments":
        result.update(down_payment="2000.00", installment_count=8, installment_amount="1000.00")
    if category == "shared_rental":
        result.update(total_beds=4, available_beds=2)
    return result


def picture():
    output = io.BytesIO()
    Image.new("RGB", (100, 100), "blue").save(output, "PNG")
    return output.getvalue()


def upload(client, headers, kind, **extra):
    return client.post(
        "/api/v1/assets",
        headers=headers,
        data={"kind": kind, **extra},
        files={"file": ("image.png", picture(), "image/png")},
    )


def test_guest_discovery_and_protected_details(client):
    assert client.get("/api/v1/health").json()["backend"] == "fastapi"
    assert client.get("/api/v1/properties").status_code == 200
    assert client.get("/api/v1/favorites").status_code == 401
    assert client.get("/api/v1/properties/00000000-0000-0000-0000-000000000001").status_code == 401


def test_registration_normalization_and_privilege_rejection(client, signup):
    for extra in [{"role": "admin"}, {"ownerVerified": True}, {"active": True}, {"onboardingComplete": True}]:
        response = client.post(
            "/api/v1/auth/register",
            json={"name": "Test User", "email": "test@example.com", "password": "password-123", **extra},
        )
        assert response.status_code == 422
    response = client.post(
        "/api/v1/auth/register",
        json={"name": " Test User ", "email": " UPPER@EXAMPLE.COM ", "password": "password-123"},
    )
    assert response.status_code in (201, 409)
    if response.status_code == 201:
        user = response.json()["user"]
        assert user["email"] == "upper@example.com" and user["name"] == "Test User"
        assert not user["onboardingComplete"] and not user["ownerVerified"]
        assert "password_hash" not in user


def test_refresh_rotation_logout_and_legacy_password_compatibility(client, signup):
    account = signup()
    assert (
        client.post("/api/v1/auth/login", json={"email": account["user"]["email"], "password": "wrong"}).status_code
        == 401
    )
    login = client.post(
        "/api/v1/auth/login", json={"email": account["user"]["email"], "password": "password-for-tests-123"}
    )
    assert login.status_code == 200
    refreshed = client.post("/api/v1/auth/refresh", json={"refreshToken": account["refreshToken"]})
    assert refreshed.status_code == 200
    assert client.post("/api/v1/auth/refresh", json={"refreshToken": account["refreshToken"]}).status_code == 401
    assert client.post("/api/v1/auth/logout", headers=account["headers"]).status_code == 204
    assert client.get("/api/v1/auth/profile", headers=account["headers"]).status_code == 401
    assert (
        client.post("/api/v1/auth/refresh", json={"refreshToken": refreshed.json()["refreshToken"]}).status_code == 401
    )


def test_multiple_intents_active_mode_and_server_roommate_gate(client, signup):
    account = signup(["owner_shared_rental", "tenant_shared"], "tenant_shared")
    assert client.get("/api/v1/roommates", headers=account["headers"]).status_code == 200
    response = client.put(
        "/api/v1/auth/intents",
        headers=account["headers"],
        json={"intents": ["tenant_private"], "activeIntent": "tenant_private"},
    )
    assert response.status_code == 200
    assert response.json()["role"] == "user"
    assert client.get("/api/v1/roommates", headers=account["headers"]).status_code == 403
    assert (
        client.post(
            "/api/v1/groups",
            headers=account["headers"],
            json={"property_id": str(UUID(int=1)), "tenant_admin_id": str(UUID(int=2))},
        ).status_code
        == 403
    )
    assert (
        client.put(
            "/api/v1/auth/intents",
            headers=account["headers"],
            json={"intents": ["tenant_private"], "activeIntent": "tenant_shared"},
        ).status_code
        == 422
    )


@pytest.mark.parametrize("field", ["water", "electricity", "gas", "elevator", "negotiable", "finishing", "area_id"])
def test_mandatory_fields_cannot_be_omitted(client, signup, field):
    account = signup(["owner_private_rental"])
    data = payload()
    del data[field]
    assert client.post("/api/v1/properties", headers=account["headers"], json=data).status_code == 422


def test_conditional_validation_and_owner_authorization(client, signup):
    owner = signup(["owner_sale_installments", "owner_shared_rental"])
    regular = signup(["tenant_private"])
    assert client.post("/api/v1/properties", headers=regular["headers"], json=payload()).status_code == 403
    bad = payload("sale_installments") | {"installment_amount": "999.00"}
    assert client.post("/api/v1/properties", headers=owner["headers"], json=bad).status_code == 422
    bad = payload("shared_rental") | {"available_beds": 5}
    assert client.post("/api/v1/properties", headers=owner["headers"], json=bad).status_code == 422
    assert (
        client.post("/api/v1/properties", headers=owner["headers"], json=payload("sale_installments")).status_code
        == 201
    )
    assert client.post("/api/v1/properties", headers=owner["headers"], json=payload("shared_rental")).status_code == 201


def test_full_listing_verification_public_search_and_favorite(client, signup, db):
    owner = signup(["owner_private_rental"])
    viewer = signup(["tenant_private"])
    admin = signup()
    admin_user = db.get(User, UUID(admin["user"]["id"]))
    admin_user.role = "admin"
    db.commit()
    response = client.post("/api/v1/properties", headers=owner["headers"], json=payload())
    assert response.status_code == 201, response.text
    pid = response.json()["id"]
    assert client.get(f"/api/v1/properties/{pid}", headers=viewer["headers"]).status_code == 404
    assert (
        client.post(
            f"/api/v1/properties/{pid}/submit",
            headers=owner["headers"],
            json={"identity_asset_id": str(UUID(int=1)), "ownership_asset_id": str(UUID(int=2))},
        ).status_code
        == 400
    )
    photos = [upload(client, owner["headers"], "photo").json()["id"] for _ in range(2)]
    assert client.put(f"/api/v1/properties/{pid}/photos", headers=owner["headers"], json=photos).status_code == 200
    identity = upload(client, owner["headers"], "identity", national_id="30001011234567", birth_date="2000-01-01")
    assert identity.status_code == 201, identity.text
    identity_id = identity.json()["id"]
    assert identity.json()["ocrStatus"] == "unavailable"
    ownership_id = upload(client, owner["headers"], "ownership").json()["id"]
    assert client.get(f"/api/v1/assets/{identity_id}").status_code == 404
    assert client.get(f"/api/v1/private-assets/{identity_id}", headers=viewer["headers"]).status_code == 404
    assert (
        client.post(
            f"/api/v1/properties/{pid}/submit",
            headers=owner["headers"],
            json={"identity_asset_id": identity_id, "ownership_asset_id": ownership_id},
        ).status_code
        == 200
    )
    verification = db.scalar(select(Verification).where(Verification.property_id == UUID(pid)))
    vid = str(verification.id)
    assert (
        client.post(
            f"/api/v1/admin/verifications/{vid}/review",
            headers=owner["headers"],
            json={"approved": True, "note": "I approve myself"},
        ).status_code
        == 403
    )
    assert (
        client.post(
            f"/api/v1/admin/verifications/{vid}/review",
            headers=admin["headers"],
            json={"approved": True, "note": "Reviewed test documents"},
        ).status_code
        == 200
    )
    listing = client.get(
        "/api/v1/properties", params={"area_id": "maadi", "water": True, "negotiable": False, "max_price": "10000"}
    ).json()
    assert pid in [item["id"] for item in listing["items"]]
    for term in ["apartment", "MAADI", "المعادي"]:
        searched = client.get(
            "/api/v1/properties", params={"q": term, "area_id": "maadi", "category": "private_rental"}
        ).json()
        assert pid in [item["id"] for item in searched["items"]]
    assert client.get("/api/v1/properties", params={"q": "%_unlikely_literal"}).json()["total"] == 0
    assert client.get(f"/api/v1/assets/{photos[0]}").status_code == 200
    assert client.get(f"/api/v1/properties/{pid}").status_code == 401
    assert client.get(f"/api/v1/properties/{pid}", headers=viewer["headers"]).status_code == 200
    for _ in range(2):
        assert client.put(f"/api/v1/favorites/{pid}", headers=viewer["headers"]).status_code == 204
    assert pid in [item["id"] for item in client.get("/api/v1/favorites", headers=viewer["headers"]).json()["items"]]
    assert client.put(f"/api/v1/properties/{pid}", headers=viewer["headers"], json=payload()).status_code == 404
    assert client.put(f"/api/v1/properties/{pid}", headers=owner["headers"], json=payload()).status_code == 200
    assert client.get(f"/api/v1/assets/{photos[0]}").status_code == 404


def test_identity_validation_and_digit_comparison(client, signup):
    assert identity_dob("30001011234567") == date(2000, 1, 1)
    assert compare_ocr("رقم ٣٠٠٠١٠١١٢٣٤٥٦٧", "30001011234567") == "matched"
    assert compare_ocr("30001011234568", "30001011234567") == "mismatch"
    assert compare_ocr("Unreadable image", "30001011234567") == "unreadable"
    owner = signup(["owner_sale_cash"])
    assert (
        upload(client, owner["headers"], "identity", national_id="30001011234567", birth_date="2001-01-01").status_code
        == 400
    )
    assert (
        client.post(
            "/api/v1/assets",
            headers=owner["headers"],
            data={"kind": "photo"},
            files={"file": ("x.jpg", b"not an image", "image/jpeg")},
        ).status_code
        == 400
    )


def test_locations_seeded_and_unknown_area_rejected(client, signup):
    locations = client.get("/api/v1/locations").json()
    assert len(locations["governorates"]) == 27
    assert any(area["id"] == "maadi" and area["governorate_id"] == "cairo" for area in locations["areas"])
    owner = signup(["owner_private_rental"])
    assert (
        client.post(
            "/api/v1/properties", headers=owner["headers"], json=payload() | {"area_id": "invented-area"}
        ).status_code
        == 400
    )
