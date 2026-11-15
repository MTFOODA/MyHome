"""Single source of truth for immutable all-in commission references and settlements."""

from dataclasses import dataclass
from decimal import ROUND_DOWN, ROUND_HALF_UP, Decimal

from fastapi import HTTPException

CENT = Decimal(".01")
MAX_MONEY = Decimal("999999999999.99")


def split_total(total):
    total = Decimal(total).quantize(CENT, rounding=ROUND_HALF_UP)
    buyer = (total / 2).quantize(CENT, rounding=ROUND_HALF_UP)
    return buyer, total - buyer


@dataclass(frozen=True)
class Reference:
    category: str
    original_price: Decimal
    total_fee: Decimal
    buyer_fee: Decimal
    seller_fee: Decimal
    months: int | None
    old_rent: bool = False


def make_reference(category, price, months, config, multiplier=Decimal(1), rental_period=None):
    price = Decimal(price)
    if category in ("sale_cash", "sale_installments"):
        total = (price * config.commission_sale_rate * multiplier).quantize(CENT, rounding=ROUND_HALF_UP)
        buyer, seller = split_total(total)
        return Reference(category, price, total, buyer, seller, None)
    if not months:
        raise HTTPException(400, "RENTAL_FEE_AGREEMENT_REQUIRED")
    if rental_period == "old_rent":
        total = (price * config.commission_old_rent * multiplier).quantize(CENT, rounding=ROUND_HALF_UP)
        buyer, seller = split_total(total)
        return Reference(category, price, total, buyer, seller, 12, True)
    prefix = "commission_shared_" if category == "shared_rental" else "commission_private_"
    factor = getattr(config, prefix + ("one" if months <= 12 else "three" if months <= 36 else "long"))
    raw = price * factor * multiplier * min(Decimal(months) / 12, Decimal(1))
    # Reduce sub-piaster residues, so both shares and the posted monthly all-in price are exact.
    monthly_share = (raw / (2 * months)).quantize(CENT, rounding=ROUND_DOWN)
    share = monthly_share * months
    return Reference(category, price, share * 2, share, share, months)


def settle(reference: Reference, negotiated_price):
    unit = Decimal(negotiated_price)
    periods = 1 if reference.old_rent else reference.months or 1
    component = unit * periods
    if unit <= 0 or component < reference.seller_fee or component + reference.buyer_fee > MAX_MONEY:
        raise HTTPException(400, "INVALID_NET_OFFER")
    displayed = unit + reference.buyer_fee / periods
    return dict(
        original_price=str(reference.original_price),
        negotiated_price=str(unit),
        property_component=str(component.quantize(CENT)),
        buyer_fee=str(reference.buyer_fee),
        seller_fee=str(reference.seller_fee),
        platform_fee=str(reference.total_fee),
        display_price=str(displayed.quantize(CENT)),
        buyer_total=str((component + reference.buyer_fee).quantize(CENT)),
        seller_net=str((component - reference.seller_fee).quantize(CENT)),
        seller_monthly_net=str((unit - reference.seller_fee / periods).quantize(CENT)),
        months=reference.months,
        fee_is_fixed=True,
        no_additional_platform_fee=True,
        old_rent=reference.old_rent,
        commission_reference_months=reference.months,
        contract_months=None if reference.old_rent else reference.months,
        contract_total_known=not reference.old_rent,
        subsequent_monthly_price=str(unit) if reference.old_rent else None,
    )
