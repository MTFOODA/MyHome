from decimal import Decimal
from uuid import UUID

import pytest

from app.config import settings
from app.financial import make_reference, settle
from app.models import Property
from app.pricing import calculate
from tests.test_deals import administrator, employee, verified_sale
from tests.test_marketplace import payload


@pytest.mark.parametrize(
    "category,price,months,period,custom",
    [
        ("sale_cash", "2000000", None, None, None),
        ("sale_installments", "2000000", None, None, None),
        ("private_rental", "12000", 12, "one_year", None),
        ("private_rental", "19200", 36, "three_years", None),
        ("private_rental", "12000", 60, "five_years", None),
        ("shared_rental", "3000", 12, "one_year", None),
        ("shared_rental", "7200", 36, "three_years", None),
        ("shared_rental", "1200", 3, "custom", 3),
        ("private_rental", "1200", 6, "custom", 6),
        ("private_rental", "10000", 12, "old_rent", None),
    ],
)
def test_frozen_all_in_math_every_category_and_negotiation(category, price, months, period, custom):
    reference = make_reference(category, Decimal(price), months, settings(), rental_period=period)
    initial = settle(reference, Decimal(price))
    discounted = settle(reference, Decimal(price) * Decimal(".95"))
    assert Decimal(initial["buyer_total"]) - Decimal(initial["seller_net"]) == reference.total_fee
    assert Decimal(discounted["buyer_total"]) - Decimal(discounted["seller_net"]) == reference.total_fee
    assert discounted["buyer_fee"] == initial["buyer_fee"] and discounted["seller_fee"] == initial["seller_fee"]
    assert discounted["original_price"] == price
    assert discounted["no_additional_platform_fee"] is True
    assert calculate(category, price, period, custom)["display_price"] == initial["display_price"]
    if period == "old_rent":
        assert initial["contract_months"] is None and initial["commission_reference_months"] == 12
        assert initial["platform_fee"] == "7500.00" and initial["display_price"] == "13750.00"
        assert initial["subsequent_monthly_price"] == "10000"


def test_mandatory_two_million_example_and_ad_edits_preserve_original_reference(client, db, signup):
    owner = signup(["owner_sale_cash"])
    values = payload("sale_cash") | {"price": "2000000"}
    created = client.post("/api/v1/properties", headers=owner["headers"], json=values)
    assert created.status_code == 201, created.text
    identity = created.json()["id"]
    original = client.get(f"/api/v1/properties/{identity}", headers=owner["headers"]).json()["financial"]
    assert original["buyer_fee"] == "10000.00" and original["seller_fee"] == "10000.00"
    assert original["display_price"] == "2010000.00" and original["seller_net"] == "1990000.00"
    assert (
        client.put(
            f"/api/v1/properties/{identity}", headers=owner["headers"], json=values | {"price": "1900000"}
        ).status_code
        == 200
    )
    reduced = client.get(f"/api/v1/properties/{identity}", headers=owner["headers"]).json()["financial"]
    assert reduced["buyer_total"] == "1910000.00" and reduced["seller_net"] == "1890000.00"
    assert reduced["platform_fee"] == "20000.00" and reduced["original_price"] == "2000000.00"
    assert (
        client.put(
            f"/api/v1/properties/{identity}",
            headers=owner["headers"],
            json=values | {"price": "1900000", "original_price": "1900000"},
        ).status_code
        == 422
    )
    db.expire_all()
    assert db.get(Property, UUID(identity)).original_price == Decimal("2000000")
    quote = client.post(
        "/api/v1/pricing/quote",
        headers=owner["headers"],
        json={"property_id": identity, "category": "sale_cash", "price": "1800000", "area_id": "maadi"},
    )
    assert quote.status_code == 200, quote.text
    assert quote.json()["buyer_fee"] == "10000.00" and quote.json()["display_price"] == "1810000.00"


def test_old_rent_eligibility_then_bilateral_special_fee_before_commitment(client, db, signup):
    admin = administrator(signup, db)
    owner, buyer = signup(["owner_private_rental"]), signup(["tenant_private"])
    reviewer = employee(client, admin, "document_reviewer")
    identity, _ = verified_sale(
        client, db, owner, admin, "private_rental", {"price": "10000", "rental_period": "old_rent"}
    )
    details = client.get(f"/api/v1/properties/{identity}", headers=buyer["headers"]).json()
    assert details["all_in"] is False and details["financial"]["contract_months"] is None
    assert client.post("/api/v1/deals", headers=buyer["headers"], json={"property_id": identity}).status_code == 409
    assert (
        client.put(
            f"/api/v1/admin/properties/{identity}/eligibility-reviewer",
            headers=admin["headers"],
            json={"staff_id": reviewer["id"]},
        ).status_code
        == 200
    )
    decision = {
        "approved": True,
        "contract_reference": "TEST-ONLY-ELIGIBILITY",
        "note": "Synthetic review of transaction eligibility, not a declaration about real old-rent rights.",
    }
    assert (
        client.post(
            f"/api/v1/eligibility-reviews/{identity}/decision", headers=owner["headers"], json=decision
        ).status_code
        == 404
    )
    reviewed = client.post(
        f"/api/v1/eligibility-reviews/{identity}/decision", headers=reviewer["headers"], json=decision
    )
    assert reviewed.status_code == 200, reviewed.text
    assert reviewed.json()["legal_contract_months"] is None
    started = client.post("/api/v1/deals", headers=buyer["headers"], json={"property_id": identity})
    assert started.status_code == 201, started.text
    deal = started.json()["id"]
    assert started.json()["buyer_total"] == "13750.00" and started.json()["seller_net"] == "6250.00"
    proposal = client.post(
        f"/api/v1/admin/deals/{deal}/special-fees",
        headers=admin["headers"],
        json={
            "total": "5000",
            "reason": "Synthetic case-specific exception approved for test only.",
            "legal_reference": "TEST-ONLY-SPECIAL-REFERENCE",
        },
    )
    assert proposal.status_code == 201, proposal.text
    pending = proposal.json()["special_fee_proposals"][0]
    assert proposal.json()["fee_total"] == "7500.00"
    consent = {"accepted": True, "digest": pending["digest"]}
    first = client.post(f"/api/v1/special-fees/{pending['id']}/consent", headers=owner["headers"], json=consent)
    assert first.status_code == 200 and first.json()["fee_total"] == "7500.00"
    second = client.post(f"/api/v1/special-fees/{pending['id']}/consent", headers=buyer["headers"], json=consent)
    assert second.status_code == 200 and second.json()["fee_total"] == "5000.00"
    assert second.json()["financial"]["original_price"] == "10000.00"
    assert second.json()["buyer_total"] == "12500.00" and second.json()["seller_net"] == "7500.00"
    assert pending["financial"]["buyer_fee"] == "2500.00"
    assert pending["financial"]["buyer_total"] == "12500.00"
    other = client.post(
        f"/api/v1/admin/deals/{deal}/special-fees",
        headers=admin["headers"],
        json={
            "total": "4000",
            "reason": "Another synthetic exception for revocation testing.",
            "legal_reference": "TEST-REVOKED",
        },
    ).json()["special_fee_proposals"][0]
    assert (
        client.post(
            f"/api/v1/eligibility-reviews/{identity}/decision",
            headers=reviewer["headers"],
            json=decision | {"approved": False},
        ).status_code
        == 200
    )
    assert (
        client.post(
            f"/api/v1/special-fees/{other['id']}/consent",
            headers=buyer["headers"],
            json={"accepted": True, "digest": other["digest"]},
        ).status_code
        == 409
    )
