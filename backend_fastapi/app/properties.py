from decimal import Decimal
from uuid import UUID

from cryptography.fernet import Fernet
from fastapi import APIRouter, Depends, HTTPException, Query, Response
from sqlalchemy import delete, exists, func, or_, select
from sqlalchemy.orm import Session

from app.config import settings
from app.database import db_session
from app.financial import Reference, settle
from app.listing_address import full_address
from app.models import (
    Area,
    Asset,
    AuditEvent,
    Deal,
    Favorite,
    Property,
    PropertyVisit,
    Tenancy,
    User,
    UserIntent,
    Verification,
)
from app.policy import require_owner
from app.pricing import set_listing_price
from app.schemas import Category, Finishing, ListingInput, Review, SubmitVerification
from app.security import administrator, authenticated

router = APIRouter(tags=["properties"])


def owned(db, user, property_id):
    prop = db.scalar(select(Property).where(Property.id == property_id).with_for_update())
    if not prop or prop.owner_id != user.id:
        raise HTTPException(404, "PROPERTY_NOT_FOUND")
    require_owner(db, user, prop.category)
    return prop


def summary(db, prop, *, owner_media=False):
    photo = db.scalar(select(Asset).where(Asset.property_id == prop.id, Asset.kind == "photo").order_by(Asset.position))
    area = db.get(Area, prop.area_id)
    return dict(
        id=str(prop.id),
        title=prop.title,
        category=prop.category,
        price=str(prop.display_price),
        negotiable=prop.negotiable,
        area_m2=str(prop.area_m2),
        bedrooms=prop.bedrooms,
        bathrooms=prop.bathrooms,
        capacity=prop.capacity if prop.category == "shared_rental" else None,
        area_measurement=prop.area_measurement,
        furnished=prop.furnished,
        latitude=str(prop.latitude) if prop.latitude is not None else None,
        longitude=str(prop.longitude) if prop.longitude is not None else None,
        area_id=prop.area_id,
        location_ar=area.name_ar,
        location_en=area.name_en,
        status=prop.status,
        availability=prop.availability,
        closed_at=prop.closed_at.isoformat() if prop.closed_at else None,
        platform_fee=str(prop.platform_fee),
        pricing_policy=prop.pricing_policy,
        original_price=str(prop.original_price),
        buyer_fee=str(prop.buyer_fee),
        seller_fee=str(prop.seller_fee),
        reference_months=prop.reference_months,
        all_in=prop.pricing_policy not in ("manual-fee-required", "eligibility-pending")
        and (prop.rental_period != "old_rent" or prop.legal_eligibility == "eligible"),
        legal_eligibility=prop.legal_eligibility,
        price_basis="first_payment"
        if prop.rental_period == "old_rent"
        else "bed_month"
        if prop.category == "shared_rental"
        else "month"
        if prop.reference_months
        else "sale",
        cover_id=str(photo.id)
        if photo and (owner_media or (prop.status == "approved" and prop.availability == "active"))
        else None,
        cover_private=owner_media,
    )


def visible_query():
    return (
        select(Property)
        .join(User, Property.owner_id == User.id)
        .where(
            Property.status == "approved",
            Property.availability == "active",
            User.active.is_(True),
            User.owner_verified.is_(True),
            exists().where(UserIntent.user_id == User.id, UserIntent.intent == ("owner_" + Property.category)),
        )
    )


def text_filter(query, q):
    if not q or not q.strip():
        return query
    escaped = q.strip().replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
    pattern = "%" + escaped + "%"
    matching_areas = select(Area.id).where(
        or_(Area.name_ar.ilike(pattern, escape="\\"), Area.name_en.ilike(pattern, escape="\\"))
    )
    return query.where(
        or_(
            Property.title.ilike(pattern, escape="\\"),
            Property.approximate_location.ilike(pattern, escape="\\"),
            Property.area_id.in_(matching_areas),
        )
    )


def saved_tombstone(favorite, prop):
    return dict(
        id=str(prop.id),
        title=favorite.title_snapshot,
        category=favorite.category_snapshot,
        price=str(favorite.price_snapshot),
        status="approved",
        availability=prop.availability if prop.availability != "active" else "unavailable",
        unavailable=True,
        area_m2="0",
        bedrooms=0,
        bathrooms=0,
        capacity=0,
        location_ar="",
        location_en="",
        negotiable=False,
        cover_id=None,
        photo_ids=[],
        description="",
    )


@router.get("/properties")
def discover(
    q: str | None = Query(None, min_length=1, max_length=120),
    category: Category | None = None,
    governorate_id: str | None = None,
    area_id: str | None = None,
    min_price: Decimal | None = Query(None, ge=0),
    max_price: Decimal | None = Query(None, ge=0),
    min_area: Decimal | None = Query(None, ge=0),
    bedrooms: int | None = Query(None, ge=0),
    finishing: Finishing | None = None,
    furnished: bool | None = None,
    water: bool | None = None,
    electricity: bool | None = None,
    gas: bool | None = None,
    elevator: bool | None = None,
    negotiable: bool | None = None,
    rental_period: str | None = None,
    sort: str = Query("newest", pattern="^(newest|price_asc|price_desc)$"),
    page: int = Query(1, ge=1),
    page_size: int = Query(12, ge=1, le=48),
    db: Session = Depends(db_session),
):
    if min_price is not None and max_price is not None and min_price > max_price:
        raise HTTPException(400, "INVALID_PRICE_RANGE")
    query = text_filter(visible_query(), q)
    if governorate_id:
        query = query.join(Area, Property.area_id == Area.id).where(Area.governorate_id == governorate_id)
    for name, value in dict(
        category=category,
        area_id=area_id,
        bedrooms=bedrooms,
        finishing=finishing,
        furnished=furnished,
        water=water,
        electricity=electricity,
        gas=gas,
        elevator=elevator,
        negotiable=negotiable,
        rental_period=rental_period,
    ).items():
        if value is not None:
            query = query.where(getattr(Property, name) == value)
    if min_price is not None:
        query = query.where(Property.display_price >= min_price)
    if max_price is not None:
        query = query.where(Property.display_price <= max_price)
    if min_area is not None:
        query = query.where(Property.area_m2 >= min_area)
    count = db.scalar(select(func.count()).select_from(query.subquery()))
    ordering = {
        "newest": Property.created_at.desc(),
        "price_asc": Property.display_price.asc(),
        "price_desc": Property.display_price.desc(),
    }[sort]
    props = db.scalars(query.order_by(ordering, Property.id).offset((page - 1) * page_size).limit(page_size)).all()
    return dict(items=[summary(db, prop) for prop in props], total=count, page=page, page_size=page_size)


@router.get("/properties/mine")
def mine(context=Depends(authenticated), db: Session = Depends(db_session)):
    return {
        "items": [
            summary(db, prop, owner_media=True)
            for prop in db.scalars(
                select(Property)
                .where(Property.owner_id == context[0].id)
                .order_by(Property.created_at.desc(), Property.id.desc())
                .limit(3)
            )
        ]
    }


@router.post("/properties", status_code=201)
def create(body: ListingInput, context=Depends(authenticated), db: Session = Depends(db_session)):
    user = context[0]
    require_owner(db, user, body.category)
    if not db.get(Area, body.area_id):
        raise HTTPException(400, "UNKNOWN_AREA")
    prop = Property(owner_id=user.id, **body.model_dump())
    prop.approximate_location = full_address(db, prop)
    set_listing_price(prop, db)
    db.add(prop)
    db.commit()
    return summary(db, prop)


@router.put("/properties/{property_id}")
def edit(property_id: UUID, body: ListingInput, context=Depends(authenticated), db: Session = Depends(db_session)):
    prop = owned(db, context[0], property_id)
    if db.scalar(select(Deal.id).where(Deal.property_id == prop.id, Deal.stage == "accepted")):
        raise HTTPException(409, "RESERVED_DEAL_LISTING_IMMUTABLE")
    if prop.closed_at:
        raise HTTPException(409, "ARCHIVED_LISTING_IMMUTABLE")
    changed_basis = any(
        getattr(prop, field) != getattr(body, field) for field in ("category", "rental_period", "custom_months")
    )
    if changed_basis:
        if db.scalar(select(Deal.id).where(Deal.property_id == prop.id, Deal.stage == "open")):
            raise HTTPException(409, "OPEN_DEAL_PRICING_BASIS_IMMUTABLE")
        # Changing the transaction type/term before a deal is distinct from a price discount.
        # Preserve the original price, but prepare the applicable duration/type schedule.
        prop.pricing_policy = "none"
        prop.legal_eligibility = "pending"
        prop.eligibility_reviewer_id = None
        prop.eligibility_reference = None
        prop.eligibility_note = None
        db.add(AuditEvent(actor_id=context[0].id, action="property.pricing_basis_changed", target_id=prop.id))
    occupants = db.scalar(
        select(func.count()).select_from(Tenancy).where(Tenancy.property_id == prop.id, Tenancy.active.is_(True))
    )
    if occupants and (
        body.category != "shared_rental" or body.total_beds is None or body.available_beds > body.total_beds - occupants
    ):
        raise HTTPException(409, "ACTIVE_TENANCIES_REQUIRE_AVAILABLE_BED_CONSISTENCY")
    require_owner(db, context[0], body.category)
    if not db.get(Area, body.area_id):
        raise HTTPException(400, "UNKNOWN_AREA")
    for name, value in body.model_dump().items():
        setattr(prop, name, value)
    prop.approximate_location = full_address(db, prop)
    prop.status = "draft"  # Any material edit removes public approval.
    set_listing_price(prop, db)
    db.commit()
    return summary(db, prop)


@router.put("/properties/{property_id}/photos")
def photos(property_id: UUID, asset_ids: list[UUID], context=Depends(authenticated), db: Session = Depends(db_session)):
    prop = owned(db, context[0], property_id)
    if db.scalar(select(Deal.id).where(Deal.property_id == prop.id, Deal.stage == "accepted")):
        raise HTTPException(409, "RESERVED_DEAL_LISTING_IMMUTABLE")
    if prop.closed_at:
        raise HTTPException(409, "ARCHIVED_LISTING_IMMUTABLE")
    if not 2 <= len(asset_ids) <= 12 or len(set(asset_ids)) != len(asset_ids):
        raise HTTPException(400, "REQUIRE_2_TO_12_PHOTOS")
    assets = db.scalars(select(Asset).where(Asset.id.in_(asset_ids)).with_for_update()).all()
    if len(assets) != len(asset_ids) or any(
        a.owner_id != context[0].id or a.kind != "photo" or (a.property_id and a.property_id != prop.id) for a in assets
    ):
        raise HTTPException(400, "INVALID_PHOTO_OWNERSHIP")
    previous = db.scalars(select(Asset).where(Asset.property_id == prop.id, Asset.kind == "photo")).all()
    for asset in previous:
        asset.position = None
        asset.property_id = None
    db.flush()
    lookup = {asset.id: asset for asset in assets}
    for position, asset_id in enumerate(asset_ids):
        lookup[asset_id].property_id, lookup[asset_id].position = prop.id, position
    prop.status = "draft"
    db.commit()
    return {"photo_ids": [str(asset_id) for asset_id in asset_ids]}


@router.post("/properties/{property_id}/submit")
def submit(
    property_id: UUID, body: SubmitVerification, context=Depends(authenticated), db: Session = Depends(db_session)
):
    prop = owned(db, context[0], property_id)
    if prop.closed_at:
        raise HTTPException(409, "ARCHIVED_LISTING_IMMUTABLE")
    count = db.scalar(
        select(func.count()).select_from(Asset).where(Asset.property_id == prop.id, Asset.kind == "photo")
    )
    if count < 2:
        raise HTTPException(400, "PHOTOS_REQUIRED")
    for asset_id, kind in [(body.identity_asset_id, "identity"), (body.ownership_asset_id, "ownership")]:
        asset = db.get(Asset, asset_id)
        if (
            not asset
            or asset.owner_id != context[0].id
            or asset.kind != kind
            or asset.property_id not in (None, prop.id)
        ):
            raise HTTPException(400, "INVALID_VERIFICATION_DOCUMENT")
        asset.property_id = prop.id
    verification = db.scalar(select(Verification).where(Verification.property_id == prop.id))
    if verification is None:
        verification = Verification(property_id=prop.id)
        db.add(verification)
    verification.identity_asset_id, verification.ownership_asset_id = body.identity_asset_id, body.ownership_asset_id
    verification.status, verification.reviewer_id, verification.review_note = "pending", None, None
    prop.status = "pending"
    db.commit()
    return {"status": "pending", "requiresManualReview": True}


@router.get("/properties/{property_id}")
def details(property_id: UUID, context=Depends(authenticated), db: Session = Depends(db_session)):
    prop = db.scalar(visible_query().where(Property.id == property_id))
    public = prop is not None
    if not prop:
        candidate = db.get(Property, property_id)
        if candidate and (candidate.owner_id == context[0].id or context[0].role == "admin"):
            prop = candidate
    if not prop:
        candidate = db.get(Property, property_id)
        favorite = db.get(Favorite, (context[0].id, property_id))
        if candidate and favorite:
            return saved_tombstone(favorite, candidate)
        raise HTTPException(404, "PROPERTY_NOT_FOUND")
    result = summary(db, prop, owner_media=prop.owner_id == context[0].id)
    # Existing records may have no structured address; do not fabricate one or
    # validate legacy output against today's mandatory creation form.
    result.update(
        {
            field: str(value) if isinstance(value, Decimal) else value
            for field in ListingInput.model_fields
            if (value := getattr(prop, field)) is not None
        }
    )
    result["full_address_ar"] = full_address(db, prop)
    result["full_address_en"] = full_address(db, prop, arabic=False)
    if prop.category != "shared_rental":
        result["capacity"] = None
    if public and prop.owner_id != context[0].id and context[0].role != "admin":
        from sqlalchemy.dialects.postgresql import insert

        db.execute(insert(PropertyVisit).values(property_id=prop.id, user_id=context[0].id).on_conflict_do_nothing())
        db.commit()
    result["photo_ids"] = [
        str(value)
        for value in db.scalars(
            select(Asset.id).where(Asset.property_id == prop.id, Asset.kind == "photo").order_by(Asset.position)
        )
    ]
    result["ownerVerified"] = db.get(User, prop.owner_id).owner_verified
    result["owner_id"] = str(prop.owner_id)
    result["price"] = str(prop.display_price)
    result["platform_fee"] = str(prop.platform_fee)
    result["financial"] = settle(
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
    )
    if prop.category == "sale_installments":
        result["down_payment"] = str(prop.down_payment + prop.buyer_fee)
    if prop.owner_id == context[0].id:
        result["owner_price"] = str(prop.price)
    return result


@router.get("/favorites")
def favorites(context=Depends(authenticated), db: Session = Depends(db_session)):
    pairs = db.execute(
        select(Favorite, Property)
        .join(Property, Favorite.property_id == Property.id)
        .where(Favorite.user_id == context[0].id)
        .order_by(Favorite.created_at.desc(), Favorite.property_id)
    ).all()
    visible_ids = set(
        db.scalars(visible_query().with_only_columns(Property.id).where(Property.id.in_([p.id for _, p in pairs])))
    )
    return {
        "items": [summary(db, prop) if prop.id in visible_ids else saved_tombstone(fav, prop) for fav, prop in pairs]
    }


@router.put("/favorites/{property_id}", status_code=204)
def favorite(property_id: UUID, context=Depends(authenticated), db: Session = Depends(db_session)):
    prop = db.scalar(visible_query().where(Property.id == property_id).with_for_update(of=Property))
    if not prop:
        raise HTTPException(404, "PROPERTY_NOT_FOUND")
    # PostgreSQL upsert makes concurrent saves idempotent.
    from sqlalchemy.dialects.postgresql import insert

    db.execute(
        insert(Favorite)
        .values(
            user_id=context[0].id,
            property_id=property_id,
            title_snapshot=prop.title,
            category_snapshot=prop.category,
            price_snapshot=prop.display_price,
        )
        .on_conflict_do_nothing()
    )
    db.commit()
    return Response(status_code=204)


@router.delete("/favorites/{property_id}", status_code=204)
def unfavorite(property_id: UUID, context=Depends(authenticated), db: Session = Depends(db_session)):
    db.execute(delete(Favorite).where(Favorite.user_id == context[0].id, Favorite.property_id == property_id))
    db.commit()
    return Response(status_code=204)


@router.get("/admin/verifications")
def queue(admin=Depends(administrator), db: Session = Depends(db_session)):
    records = [
        dict(
            id=str(v.id),
            property_id=str(v.property_id),
            title=db.get(Property, v.property_id).title,
            location=db.get(Property, v.property_id).approximate_location,
            identity_asset_id=str(v.identity_asset_id),
            ownership_asset_id=str(v.ownership_asset_id),
            ocrStatus=db.get(Asset, v.identity_asset_id).ocr_status,
            declaredNationalId=Fernet(settings().document_key)
            .decrypt(db.get(Asset, v.identity_asset_id).national_id_cipher)
            .decode(),
            birthDate=db.get(Asset, v.identity_asset_id).dob.isoformat(),
        )
        for v in db.scalars(select(Verification).where(Verification.status == "pending"))
    ]
    for record in records:
        db.add(AuditEvent(actor_id=admin.id, action="verification.queue_read", target_id=UUID(record["id"])))
    db.commit()
    return records


@router.post("/admin/verifications/{verification_id}/review")
def review(verification_id: UUID, body: Review, admin=Depends(administrator), db: Session = Depends(db_session)):
    verification = db.get(Verification, verification_id)
    if not verification:
        raise HTTPException(404, "VERIFICATION_NOT_FOUND")
    prop = db.scalar(select(Property).where(Property.id == verification.property_id).with_for_update())
    verification = db.scalar(
        select(Verification)
        .where(Verification.id == verification_id)
        .with_for_update()
        .execution_options(populate_existing=True)
    )
    owner = db.get(User, prop.owner_id)
    if prop.status != "pending" or verification.status != "pending":
        raise HTTPException(409, "NOT_PENDING")
    if owner.id == admin.id:
        raise HTTPException(403, "SELF_REVIEW_FORBIDDEN")
    if body.approved:
        require_owner(db, owner, prop.category)
        if not owner.active:
            raise HTTPException(409, "OWNER_INACTIVE")
    verification.status = "approved" if body.approved else "rejected"
    verification.reviewer_id, verification.review_note = admin.id, body.note
    prop.status = verification.status
    if body.approved:
        owner.owner_verified = True
    db.add(AuditEvent(actor_id=admin.id, action="verification." + verification.status, target_id=verification.id))
    db.commit()
    return {"status": verification.status}
