from decimal import Decimal
from uuid import UUID, uuid4

import pytest

from app.models import Property, Tenancy
from tests.test_deals import administrator, attended_viewing, employee, terms, verified_sale
from tests.test_marketplace import picture


@pytest.mark.parametrize(
    "category,period,price,offer,total,net,fee",
    [
        ("private_rental", "one_year", "12000", "11250", "135000.00", "129000.00", "6000.00"),
        ("shared_rental", "three_years", "3000", "2915.62", "104962.32", "103837.68", "1124.64"),
        ("private_rental", "old_rent", "10000", "12750", "12750.00", "5250.00", "7500.00"),
    ],
)
def test_rental_negotiation_consent_payment_and_completion(
    client, db, signup, monkeypatch, category, period, price, offer, total, net, fee
):
    admin = administrator(signup, db)
    shared = category == "shared_rental"
    owner = signup(["owner_shared_rental" if shared else "owner_private_rental"])
    tenant = signup(["tenant_shared" if shared else "tenant_private"])
    agent, reviewer = employee(client, admin, "field_agent"), employee(client, admin, "document_reviewer")
    values = {"price": price, "rental_period": period}
    if shared:
        values.update(total_beds=2, available_beds=2)
    identity, _ = verified_sale(client, db, owner, admin, category, values)
    if period == "old_rent":
        assert (
            client.put(
                f"/api/v1/admin/properties/{identity}/eligibility-reviewer",
                headers=admin["headers"],
                json={"staff_id": reviewer["id"]},
            ).status_code
            == 200
        )
        assert (
            client.post(
                f"/api/v1/eligibility-reviews/{identity}/decision",
                headers=reviewer["headers"],
                json={
                    "approved": True,
                    "contract_reference": "TEST-LEGAL-ELIGIBILITY",
                    "note": "Synthetic eligible transaction only; not a statement about actual rental rights.",
                },
            ).status_code
            == 200
        )
    started = client.post("/api/v1/deals", headers=tenant["headers"], json={"property_id": identity})
    assert started.status_code == 201, started.text
    deal = started.json()["id"]
    attended_viewing(client, db, deal, owner, tenant, admin, agent, monkeypatch)
    proposed = client.post(f"/api/v1/deals/{deal}/offers", headers=tenant["headers"], json={"amount": offer})
    assert proposed.status_code == 201, proposed.text
    terms(client, admin)
    offer_id = proposed.json()["offers"][0]["id"]
    accepted = client.put(f"/api/v1/offers/{offer_id}/decision", headers=owner["headers"], json={"approved": True})
    assert accepted.status_code == 200, accepted.text
    assert accepted.json()["buyer_total"] == total and accepted.json()["seller_net"] == net
    assert accepted.json()["fee_total"] == fee
    for actor in (owner, tenant):
        assert (
            client.post(
                f"/api/v1/deals/{deal}/consent",
                headers=actor["headers"],
                json={"accepted": True, "digest": accepted.json()["terms"]["digest"]},
            ).status_code
            == 200
        )
    assert (
        client.put(
            f"/api/v1/admin/deals/{deal}/reviewer", headers=admin["headers"], json={"staff_id": reviewer["id"]}
        ).status_code
        == 200
    )
    assert (
        client.post(
            "/api/v1/admin/payment-destination",
            headers=admin["headers"],
            data={"recipient_name": "SYNTHETIC TEST DESTINATION"},
            files={"file": ("test.png", picture(), "image/png")},
        ).status_code
        == 201
    )
    reviewed = client.post(
        f"/api/v1/deals/{deal}/contract-review",
        headers=reviewer["headers"],
        json={
            "approved": True,
            "contract_reference": "TEST-RENTAL-CONTRACT",
            "note": "Synthetic contract reviewed solely for the automated test transaction.",
        },
    )
    assert reviewed.status_code == 200, reviewed.text
    if period == "old_rent":
        for eligible in (False, True):
            assert (
                client.post(
                    f"/api/v1/eligibility-reviews/{identity}/decision",
                    headers=reviewer["headers"],
                    json={
                        "approved": eligible,
                        "contract_reference": "TEST-RECHECK-ELIGIBILITY",
                        "note": "Synthetic eligibility revocation and reassessment before payment.",
                    },
                ).status_code
                == 200
            )
            assert client.get(f"/api/v1/deals/{deal}/payment-qr", headers=tenant["headers"]).status_code == (
                200 if eligible else 409
            )
    for actor in (owner, tenant):
        claim = client.post(
            f"/api/v1/deals/{deal}/payment-claims", headers=actor["headers"], json={"reference": "TEST-" + uuid4().hex}
        )
        assert claim.status_code == 201, claim.text
        assert (
            client.put(
                f"/api/v1/admin/payment-claims/{claim.json()['claims'][0]['id']}/review",
                headers=admin["headers"],
                json={
                    "approved": True,
                    "note": "Synthetic reconciliation of external transfer evidence; no actual money moved.",
                },
            ).status_code
            == 200
        )
    finished = client.post(f"/api/v1/admin/deals/{deal}/complete", headers=admin["headers"])
    assert finished.status_code == 200, finished.text
    result = finished.json()
    assert result["buyer_total"] == total and result["seller_net"] == net
    assert Decimal(result["buyer_remaining_total"]) + Decimal(result["buyer_platform_paid"]) == Decimal(total)
    assert result["remaining_platform_buyer"] == "0.00"
    db.expire_all()
    prop = db.get(Property, UUID(identity))
    if shared:
        assert prop.available_beds == 1 and prop.availability == "active"
        assert db.get(Tenancy, (prop.id, UUID(tenant["user"]["id"]))).active
        # The remaining bed stays discoverable; the completed bed is in the tenant's ledger.
        assert client.get(f"/api/v1/properties/{identity}", headers=tenant["headers"]).status_code == 200
    else:
        assert prop.availability == "rented" and prop.closed_at is not None
