from decimal import Decimal

import pytest

from app.config import settings
from app.financial import make_reference, settle
from app.pricing import calculate


@pytest.mark.parametrize(
    "category,price,period,months,platform,owner,basis",
    [
        ("sale_cash", "2000000", None, None, "1", "99.5", "sale_price"),
        ("sale_installments", "2000000", None, None, "1", "99.5", "sale_price"),
        ("private_rental", "12000", "one_year", 12, "4.1667", "97.9167", "contract_rent"),
        ("private_rental", "19200", "three_years", 36, "2.0833", "98.9583", "contract_rent"),
        ("private_rental", "12000", "five_years", 60, "1.6667", "99.1667", "contract_rent"),
        ("shared_rental", "3000", "one_year", 12, "2.0833", "98.9583", "contract_rent"),
        ("shared_rental", "7200", "three_years", 36, "1.0417", "99.4792", "contract_rent"),
        ("private_rental", "10000", "old_rent", 12, "75", "62.5", "monthly_rent"),
    ],
)
def test_server_calculator_percentages_have_explicit_reference_bases(
    category, price, period, months, platform, owner, basis
):
    reference = make_reference(category, Decimal(price), months, settings(), rental_period=period)
    quote = settle(reference, Decimal(price))
    result = quote["calculator"]
    assert result["platform_percent"] == platform and result["owner_net_percent"] == owner
    assert result["reference_basis"] == basis
    negotiated = settle(reference, Decimal(price) * Decimal(".95"))
    for field in ("platform_percent", "buyer_percent", "seller_percent", "reference_amount", "reference_basis"):
        assert negotiated["calculator"][field] == result[field]
    assert negotiated["platform_fee"] == quote["platform_fee"]


def test_sale_quote_does_not_inherit_hidden_old_rent_fields():
    quote = calculate("sale_cash", "2000000", "old_rent")
    assert quote["price_basis"] == "sale" and quote["months"] is None
    assert quote["requires_legal_eligibility"] is False and quote["old_rent"] is False
    assert quote["calculator"]["platform_percent"] == "1"


def test_live_quote_api_returns_money_and_percentages_from_the_same_reference(client, signup):
    actor = signup(["owner_sale_cash"])
    response = client.post(
        "/api/v1/pricing/quote",
        headers=actor["headers"],
        json={"category": "sale_cash", "price": "2000000", "area_id": "maadi"},
    )
    assert response.status_code == 200, response.text
    result = response.json()
    assert result["display_price"] == "2010000.00" and result["seller_net"] == "1990000.00"
    assert result["calculator"]["buyer_percent"] == "0.5"
    assert result["calculator"]["seller_percent"] == "0.5"
