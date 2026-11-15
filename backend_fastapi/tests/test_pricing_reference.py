from concurrent.futures import ThreadPoolExecutor
from uuid import UUID, uuid4

from app.models import Property, Viewing
from app.security import now
from tests.test_deals import administrator, terms
from tests.test_marketplace import payload
from tests.test_portfolio import listing


def test_draft_term_change_uses_original_price_and_matches_quote(client, db, signup):
    owner = signup(["owner_private_rental"])
    body = payload("private_rental") | {"price": "12000", "rental_period": "one_year"}
    created = client.post("/api/v1/properties", headers=owner["headers"], json=body).json()
    identity = created["id"]
    quote = client.post(
        "/api/v1/pricing/quote",
        headers=owner["headers"],
        json={
            "property_id": identity,
            "price": "11000",
            "category": "private_rental",
            "area_id": "maadi",
            "rental_period": "three_years",
        },
    )
    assert quote.status_code == 200, quote.text
    edited = client.put(
        f"/api/v1/properties/{identity}",
        headers=owner["headers"],
        json=body | {"price": "11000", "rental_period": "three_years"},
    )
    assert edited.status_code == 200, edited.text
    actual = client.get(f"/api/v1/properties/{identity}", headers=owner["headers"]).json()["financial"]
    for field in ("original_price", "buyer_fee", "seller_fee", "buyer_total", "seller_net", "display_price"):
        assert actual[field] == quote.json()[field]
    assert actual["original_price"] == "12000.00"


def test_concurrent_shared_deal_acceptance_reserves_last_bed_once_and_cancel_releases_it(client, db, signup):
    admin = administrator(signup, db)
    owner = signup(["owner_shared_rental"])
    tenants = [signup(["tenant_shared"]), signup(["tenant_shared"])]
    pid = listing(client, db, owner, "shared_rental", "Synthetic last-bed deal")
    db.get(Property, UUID(pid)).available_beds = 1
    db.commit()
    terms(client, admin)
    deals, offers = [], []
    for tenant in tenants:
        deal = client.post("/api/v1/deals", headers=tenant["headers"], json={"property_id": pid}).json()["id"]
        deals.append(deal)
        # Independent attendance fixture; actual booking/assignment permissions have dedicated API tests.
        db.add(
            Viewing(
                deal_id=UUID(deal),
                reference="TEST-" + uuid4().hex,
                scheduled_at=now(),
                owner_confirmed=True,
                status="completed",
                completion_note="SYNTHETIC FIXTURE",
            )
        )
        db.commit()
        offered = client.post(f"/api/v1/deals/{deal}/offers", headers=tenant["headers"], json={"amount": "3100"})
        assert offered.status_code == 201, offered.text
        offers.append(offered.json()["offers"][0]["id"])
    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(
            pool.map(
                lambda offer: client.put(
                    f"/api/v1/offers/{offer}/decision", headers=owner["headers"], json={"approved": True}
                ),
                offers,
            )
        )
    assert sorted(r.status_code for r in results) == [200, 409]
    db.expire_all()
    prop = db.get(Property, UUID(pid))
    assert prop.available_beds == 0 and prop.availability == "paused"
    winner = next(i for i, r in enumerate(results) if r.status_code == 200)
    cancelled = client.post(
        f"/api/v1/deals/{deals[winner]}/cancel",
        headers=admin["headers"],
        json={"note": "Synthetic cancellation before any payment or financial commitment."},
    )
    assert cancelled.status_code == 200, cancelled.text
    db.expire_all()
    assert db.get(Property, UUID(pid)).available_beds == 1
    assert db.get(Property, UUID(pid)).availability == "paused"  # Restore is an explicit owner action.
