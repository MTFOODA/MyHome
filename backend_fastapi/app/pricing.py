"""Approved all-in pricing, with fixed original-price references and decimal arithmetic."""

from decimal import Decimal
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import Field
from sqlalchemy.orm import Session

from app.config import settings
from app.database import db_session
from app.financial import Reference, make_reference, settle
from app.models import Area, Property
from app.schemas import Category, Money, RentalPeriod, StrictModel
from app.security import authenticated

router = APIRouter(tags=["pricing"])
CENT = Decimal("0.01")


class QuoteInput(StrictModel):
    category: Category
    price: Money
    area_id: str
    rental_period: RentalPeriod | None = None
    custom_months: int | None = Field(None, ge=1, le=1200)
    total_beds: int = Field(1, ge=1, le=500)
    property_id: UUID | None = None


def calculate(category, price, rental_period=None, custom_months=None, total_beds=1, regional_multiplier=Decimal(1)):
    price = Decimal(price)
    config = settings()
    policy = config.commission_policy_version
    rental = category in ("private_rental", "shared_rental")
    months = {"one_year": 12, "three_years": 36, "five_years": 60, "custom": custom_months, "old_rent": 12}.get(
        rental_period
    )
    if rental and not months:
        return dict(requires_agreement=True, owner_price=str(price), policy=policy, enabled=False)
    reference = make_reference(category, price, months if rental else None, config, regional_multiplier, rental_period)
    result = settle(reference, price)
    return result | dict(
        requires_agreement=False,
        owner_price=str(price),
        months=months if rental else None,
        price_basis="first_payment"
        if rental_period == "old_rent"
        else "bed_month"
        if category == "shared_rental"
        else "month"
        if rental
        else "sale",
        estimated_full_occupancy_fee=str(reference.total_fee * total_beds) if category == "shared_rental" else None,
        policy=policy,
        regional_multiplier=str(regional_multiplier),
        enabled=True,
        requires_legal_eligibility=rental_period == "old_rent",
    )


def region_multiplier(db, area_id):
    area = db.get(Area, area_id)
    discounts = settings().commission_region_discounts
    discount = discounts.get("area:" + area_id, discounts.get("governorate:" + area.governorate_id, Decimal(0)))
    return Decimal(1) - discount


def set_listing_price(prop, db):
    if prop.original_price is None:
        prop.original_price = Decimal(prop.price)
    if prop.pricing_policy not in (None, "none", "manual-fee-required", "eligibility-pending"):
        reference = Reference(
            prop.category,
            prop.original_price,
            prop.platform_fee,
            prop.buyer_fee,
            prop.seller_fee,
            prop.reference_months,
            prop.rental_period == "old_rent",
        )
        prop.display_price = Decimal(settle(reference, prop.price)["display_price"])
        return
    quote = calculate(
        prop.category,
        prop.original_price,
        prop.rental_period,
        prop.custom_months,
        prop.total_beds or 1,
        region_multiplier(db, prop.area_id),
    )
    if quote["requires_agreement"]:
        prop.display_price = prop.price
        prop.platform_fee = prop.buyer_fee = prop.seller_fee = Decimal(0)
        prop.pricing_policy = "manual-fee-required"
        return
    prop.platform_fee = Decimal(quote["platform_fee"])
    prop.buyer_fee = Decimal(quote["buyer_fee"])
    prop.seller_fee = Decimal(quote["seller_fee"])
    prop.reference_months = quote["months"]
    prop.pricing_policy = quote["policy"]
    prop.display_price = Decimal(
        settle(
            Reference(
                prop.category,
                prop.original_price,
                prop.platform_fee,
                prop.buyer_fee,
                prop.seller_fee,
                prop.reference_months,
                prop.rental_period == "old_rent",
            ),
            prop.price,
        )["display_price"]
    )


@router.post("/pricing/quote")
def quote(body: QuoteInput, context=Depends(authenticated), db: Session = Depends(db_session)):
    if body.property_id:
        prop = db.get(Property, body.property_id)
        if not prop or prop.owner_id != context[0].id:
            raise HTTPException(404, "PROPERTY_NOT_FOUND")
        changed_basis = any(
            getattr(prop, field) != getattr(body, field) for field in ("category", "rental_period", "custom_months")
        )
        if changed_basis:
            preview = calculate(
                body.category,
                prop.original_price,
                body.rental_period,
                body.custom_months,
                body.total_beds,
                region_multiplier(db, prop.area_id),
            )
            if preview["requires_agreement"]:
                return preview
            reference = Reference(
                body.category,
                prop.original_price,
                Decimal(preview["platform_fee"]),
                Decimal(preview["buyer_fee"]),
                Decimal(preview["seller_fee"]),
                preview["months"],
                body.rental_period == "old_rent",
            )
            return preview | settle(reference, body.price) | {"owner_price": str(body.price)}
        result = settle(
            Reference(
                prop.category,
                prop.original_price,
                prop.platform_fee,
                prop.buyer_fee,
                prop.seller_fee,
                prop.reference_months,
                prop.rental_period == "old_rent",
            ),
            body.price,
        )
        return result | dict(
            requires_agreement=False,
            owner_price=str(body.price),
            price_basis="first_payment"
            if prop.rental_period == "old_rent"
            else "bed_month"
            if prop.category == "shared_rental"
            else "month"
            if prop.reference_months
            else "sale",
            enabled=True,
            requires_legal_eligibility=prop.rental_period == "old_rent" and prop.legal_eligibility != "eligible",
        )
    if not db.get(Area, body.area_id):
        raise HTTPException(400, "UNKNOWN_AREA")
    result = calculate(
        **body.model_dump(exclude={"area_id", "property_id"}), regional_multiplier=region_multiplier(db, body.area_id)
    )
    result["area_id"] = body.area_id
    return result
