from decimal import Decimal
from uuid import UUID

from sqlalchemy import select

from app.config import settings
from app.models import AuditEvent, Property, User
from app.pricing import calculate
from tests.test_marketplace import payload, upload


def listing(client, db, owner, category="private_rental", title="Portfolio apartment"):
    response = client.post("/api/v1/properties", headers=owner["headers"], json=payload(category) | {"title": title})
    assert response.status_code == 201, response.text
    identity = response.json()["id"]
    prop = db.get(Property, UUID(identity))
    prop.status = "approved"  # Synthetic test fixture; document review is tested separately.
    db.get(User, UUID(owner["user"]["id"])).owner_verified = True
    db.commit()
    return identity


def test_portfolio_counts_three_at_a_time_and_owner_isolation(client, db, signup):
    owner = signup(["owner_sale_cash", "owner_private_rental", "owner_shared_rental"])
    other = signup(["owner_sale_cash"])
    sale_ids = {listing(client, db, owner, "sale_cash", f"Portfolio sale {n}") for n in range(5)}
    for n in range(3):
        listing(client, db, owner, title=f"Portfolio rent {n}")
    listing(client, db, owner, "shared_rental")
    foreign = listing(client, db, other, "sale_cash", "Foreign owner secret")
    overview = client.get("/api/v1/properties/mine/overview", headers=owner["headers"]).json()["items"]
    assert {v["group"]: v["current"] for v in overview} == {"sale": 5, "private_rental": 3, "shared_rental": 1}
    url = "/api/v1/properties/mine/page"
    first = client.get(url, params={"group": "sale"}, headers=owner["headers"]).json()
    assert len(first["items"]) == 3 and first["page_size"] == 3 and first["total"] == 5
    assert foreign not in [p["id"] for p in first["items"]]
    # Removing an already-read row must not cause OFFSET-style skips on the next page.
    first_id = first["items"][0]["id"]
    assert (
        client.put(
            f"/api/v1/properties/{first_id}/availability", headers=owner["headers"], json={"availability": "sold"}
        ).status_code
        == 200
    )
    second = client.get(url, params={"group": "sale", "cursor": first["next_cursor"]}, headers=owner["headers"]).json()
    assert len(second["items"]) == 2 and second["next_cursor"] is None
    assert {p["id"] for p in first["items"] + second["items"]} == sale_ids
    assert (
        client.get(url, params={"group": "sale", "cursor": first["next_cursor"]}, headers=other["headers"]).status_code
        == 400
    )
    assert (
        client.get(
            url, params={"group": "private_rental", "cursor": first["next_cursor"]}, headers=owner["headers"]
        ).status_code
        == 400
    )
    assert client.get(url, params={"group": "sale", "cursor": "tampered"}, headers=owner["headers"]).status_code == 400
    suggestions = client.get(
        "/api/v1/properties/mine/suggestions", params={"group": "sale", "q": "sale"}, headers=owner["headers"]
    ).json()["items"]
    assert len(suggestions) == 4 and all(p["title"].startswith("Portfolio sale") for p in suggestions)
    assert client.get(url, params={"group": "sale", "q": "%_"}, headers=owner["headers"]).json()["total"] == 0


def test_pause_favorite_tombstone_resume_and_completed_history(client, db, signup):
    owner = signup(["owner_private_rental"])
    saver, outsider = signup(), signup()
    identity = listing(client, db, owner)
    photo_ids = [upload(client, owner["headers"], "photo").json()["id"] for _ in range(2)]
    assert (
        client.put(f"/api/v1/properties/{identity}/photos", headers=owner["headers"], json=photo_ids).status_code == 200
    )
    db.expire_all()
    db.get(Property, UUID(identity)).status = "approved"
    db.commit()
    path = f"/api/v1/properties/{identity}"
    assert client.put(f"/api/v1/favorites/{identity}", headers=saver["headers"]).status_code == 204
    assert (
        client.put(path + "/availability", headers=outsider["headers"], json={"availability": "paused"}).status_code
        == 404
    )
    assert (
        client.put(path + "/availability", headers=owner["headers"], json={"availability": "sold"}).status_code == 400
    )
    assert (
        client.put(path + "/availability", headers=owner["headers"], json={"availability": "paused"}).status_code == 200
    )
    assert identity not in [p["id"] for p in client.get("/api/v1/properties").json()["items"]]
    assert client.get(path, headers=outsider["headers"]).status_code == 404
    assert client.get(f"/api/v1/assets/{photo_ids[0]}").status_code == 404
    assert client.get(f"/api/v1/private-assets/{photo_ids[0]}", headers=owner["headers"]).status_code == 200
    assert client.put(f"/api/v1/favorites/{identity}", headers=outsider["headers"]).status_code == 404
    saved = client.get(path, headers=saver["headers"]).json()
    assert saved["availability"] == "paused" and saved["unavailable"] is True
    assert "owner_id" not in saved and saved["photo_ids"] == [] and "approximate_location" not in saved
    assert (
        client.put(path + "/availability", headers=owner["headers"], json={"availability": "active"}).status_code == 200
    )
    assert client.get(path, headers=outsider["headers"]).status_code == 200
    assert (
        client.put(path + "/availability", headers=owner["headers"], json={"availability": "rented"}).status_code == 200
    )
    saved_items = client.get("/api/v1/favorites", headers=saver["headers"]).json()["items"]
    assert next(p for p in saved_items if p["id"] == identity)["availability"] == "rented"
    current = client.get(
        "/api/v1/properties/mine/page", params={"group": "private_rental"}, headers=owner["headers"]
    ).json()
    history = client.get(
        "/api/v1/properties/mine/page", params={"group": "private_rental", "scope": "history"}, headers=owner["headers"]
    ).json()
    assert current["total"] == 0 and history["total"] == 1 and history["items"][0]["closed_at"]
    assert (
        client.put(path + "/availability", headers=owner["headers"], json={"availability": "active"}).status_code == 409
    )
    assert client.put(path, headers=owner["headers"], json=payload()).status_code == 409
    assert db.scalar(
        select(AuditEvent).where(AuditEvent.target_id == UUID(identity), AuditEvent.action == "listing.active.rented")
    )


def test_unpublished_edits_do_not_leak_into_saved_tombstones(client, db, signup):
    owner, saver = signup(["owner_private_rental"]), signup()
    identity = listing(client, db, owner, title="Original approved title")
    client.put(f"/api/v1/favorites/{identity}", headers=saver["headers"])
    client.put(
        f"/api/v1/properties/{identity}",
        headers=owner["headers"],
        json=payload() | {"title": "Private draft changed title"},
    )
    saved = client.get(f"/api/v1/properties/{identity}", headers=saver["headers"]).json()
    assert saved["title"] == "Original approved title" and saved["availability"] == "unavailable"


def test_commission_preview_and_exact_enabled_display_price(client, db, signup):
    owner = signup(["owner_sale_installments"])
    quote = client.post(
        "/api/v1/pricing/quote",
        headers=owner["headers"],
        json={"category": "sale_cash", "price": "1000000.00", "area_id": "maadi"},
    ).json()
    assert quote["enabled"] is True and Decimal(quote["display_price"]) == Decimal("1005000")
    assert calculate("private_rental", "12000", "one_year")["display_price"] == "12250.00"
    assert Decimal(calculate("private_rental", "1000", "three_years")["platform_fee"]) <= Decimal("750")
    assert calculate("shared_rental", "3000", "one_year", total_beds=4)["display_price"] == "3031.25"
    assert calculate("shared_rental", "3000", "three_years")["platform_fee"] == "1124.64"
    assert calculate("shared_rental", "3000", "five_years")["platform_fee"] == "1500.00"
    assert calculate("shared_rental", "1200", "custom", custom_months=3)["platform_fee"] == "75.00"
    assert calculate("private_rental", "3000", "old_rent")["requires_legal_eligibility"] is True
    assert (
        client.post(
            "/api/v1/pricing/quote",
            headers=owner["headers"],
            json={"category": "sale_cash", "price": "1.001", "area_id": "maadi"},
        ).status_code
        == 422
    )
    config = settings()
    previous = config.commission_enabled
    try:
        config.commission_enabled = True
        identity = listing(client, db, owner, "sale_installments")
        details = client.get(f"/api/v1/properties/{identity}", headers=owner["headers"]).json()
        assert Decimal(details["price"]) == Decimal("10050.00")
        assert Decimal(details["down_payment"]) + details["installment_count"] * Decimal(
            details["installment_amount"]
        ) == Decimal(details["price"])
        assert (
            client.get("/api/v1/properties", params={"min_price": "10001", "max_price": "10100"}).json()["total"] >= 1
        )
        assert db.get(Property, UUID(identity)).pricing_policy == "all-in-v1"
    finally:
        config.commission_enabled = previous


def test_region_discount_is_server_controlled_and_does_not_reprice_saved_listings(client, db, signup):
    config = settings()
    previous, enabled = config.commission_region_discounts, config.commission_enabled
    owner = signup(["owner_sale_cash"])
    try:
        config.commission_enabled = True
        config.commission_region_discounts = {"governorate:cairo": Decimal(".10"), "area:maadi": Decimal(".20")}
        values = {"category": "sale_cash", "price": "1000000", "area_id": "maadi"}
        quote = client.post("/api/v1/pricing/quote", headers=owner["headers"], json=values).json()
        assert quote["regional_multiplier"] == "0.80" and Decimal(quote["platform_fee"]) == Decimal("8000")
        assert (
            client.post(
                "/api/v1/pricing/quote", headers=owner["headers"], json=values | {"regional_multiplier": "0"}
            ).status_code
            == 422
        )
        identity = listing(client, db, owner, "sale_cash")
        snap = db.get(Property, UUID(identity)).display_price
        config.commission_region_discounts = {}
        assert db.get(Property, UUID(identity)).display_price == snap
        too_large = client.post(
            "/api/v1/properties", headers=owner["headers"], json=payload("sale_cash") | {"price": "999999999999.99"}
        )
        assert too_large.status_code == 400
    finally:
        config.commission_region_discounts = previous
        config.commission_enabled = enabled


def test_shared_pause_prevents_applications_and_group_membership_is_private(client, db, signup):
    owner, tenant, other = signup(["owner_shared_rental"]), signup(["tenant_shared"]), signup()
    identity = listing(client, db, owner, "shared_rental")
    application = client.post(f"/api/v1/properties/{identity}/applications", headers=tenant["headers"]).json()["id"]
    assert client.post(f"/api/v1/applications/{application}/accept", headers=owner["headers"]).status_code == 200
    group = client.post(
        "/api/v1/groups",
        headers=owner["headers"],
        json={"property_id": identity, "tenant_admin_id": tenant["user"]["id"]},
    )
    assert group.status_code == 201 and group.json()["messagingReady"] is True
    gid = group.json()["id"]
    assert gid in [g["id"] for g in client.get("/api/v1/groups", headers=tenant["headers"]).json()["items"]]
    assert client.get("/api/v1/groups", headers=other["headers"]).json()["items"] == []
    client.put(f"/api/v1/properties/{identity}/availability", headers=owner["headers"], json={"availability": "paused"})
    other_shared = signup(["tenant_shared"])
    assert (
        client.post(f"/api/v1/properties/{identity}/applications", headers=other_shared["headers"]).status_code == 404
    )
