from decimal import Decimal
from uuid import UUID

from cryptography.fernet import Fernet
from fastapi import APIRouter, Depends, HTTPException, Query, Response
from sqlalchemy import delete, exists, func, or_, select
from sqlalchemy.orm import Session

from app.config import settings
from app.database import db_session
from app.models import Area, Asset, AuditEvent, Favorite, Property, Tenancy, User, UserIntent, Verification
from app.policy import require_owner
from app.schemas import Category, Finishing, ListingInput, Review, SubmitVerification
from app.security import administrator, authenticated

router = APIRouter(tags=["properties"])


def owned(db, user, property_id):
    prop = db.scalar(select(Property).where(Property.id == property_id).with_for_update())
    if not prop or prop.owner_id != user.id:
        raise HTTPException(404, "PROPERTY_NOT_FOUND")
    require_owner(db, user, prop.category)
    return prop


def summary(db, prop):
    photo = db.scalar(select(Asset).where(Asset.property_id == prop.id, Asset.kind == "photo").order_by(Asset.position))
    area = db.get(Area, prop.area_id)
    return dict(
        id=str(prop.id),
        title=prop.title,
        category=prop.category,
        price=str(prop.price),
        negotiable=prop.negotiable,
        area_m2=str(prop.area_m2),
        bedrooms=prop.bedrooms,
        bathrooms=prop.bathrooms,
        capacity=prop.capacity,
        area_id=prop.area_id,
        location_ar=area.name_ar,
        location_en=area.name_en,
        status=prop.status,
        cover_id=str(photo.id) if photo else None,
    )


def visible_query():
    return (
        select(Property)
        .join(User, Property.owner_id == User.id)
        .where(
            Property.status == "approved",
            User.active.is_(True),
            User.owner_verified.is_(True),
            exists().where(UserIntent.user_id == User.id, UserIntent.intent == ("owner_" + Property.category)),
        )
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
    query = visible_query()
    if q and q.strip():
        escaped = q.strip().replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
        pattern = "%" + escaped + "%"
        matching_areas = select(Area.id).where(
            or_(Area.name_ar.ilike(pattern, escape="\\"), Area.name_en.ilike(pattern, escape="\\"))
        )
        query = query.where(
            or_(
                Property.title.ilike(pattern, escape="\\"),
                Property.approximate_location.ilike(pattern, escape="\\"),
                Property.area_id.in_(matching_areas),
            )
        )
    if governorate_id:
        query = query.join(Area, Property.area_id == Area.id).where(Area.governorate_id == governorate_id)
    for name, value in dict(
        category=category,
        area_id=area_id,
        bedrooms=bedrooms,
        finishing=finishing,
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
        query = query.where(Property.price >= min_price)
    if max_price is not None:
        query = query.where(Property.price <= max_price)
    if min_area is not None:
        query = query.where(Property.area_m2 >= min_area)
    count = db.scalar(select(func.count()).select_from(query.subquery()))
    ordering = {
        "newest": Property.created_at.desc(),
        "price_asc": Property.price.asc(),
        "price_desc": Property.price.desc(),
    }[sort]
    props = db.scalars(query.order_by(ordering, Property.id).offset((page - 1) * page_size).limit(page_size)).all()
    return dict(items=[summary(db, prop) for prop in props], total=count, page=page, page_size=page_size)


@router.get("/properties/mine")
def mine(context=Depends(authenticated), db: Session = Depends(db_session)):
    return {
        "items": [
            summary(db, prop)
            for prop in db.scalars(
                select(Property).where(Property.owner_id == context[0].id).order_by(Property.created_at.desc())
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
    db.add(prop)
    db.commit()
    return summary(db, prop)


@router.put("/properties/{property_id}")
def edit(property_id: UUID, body: ListingInput, context=Depends(authenticated), db: Session = Depends(db_session)):
    prop = owned(db, context[0], property_id)
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
    prop.status = "draft"  # Any material edit removes public approval.
    db.commit()
    return summary(db, prop)


@router.put("/properties/{property_id}/photos")
def photos(property_id: UUID, asset_ids: list[UUID], context=Depends(authenticated), db: Session = Depends(db_session)):
    prop = owned(db, context[0], property_id)
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
    if not prop:
        candidate = db.get(Property, property_id)
        if candidate and (candidate.owner_id == context[0].id or context[0].role == "admin"):
            prop = candidate
    if not prop:
        raise HTTPException(404, "PROPERTY_NOT_FOUND")
    result = summary(db, prop)
    result.update(
        ListingInput.model_validate({field: getattr(prop, field) for field in ListingInput.model_fields}).model_dump(
            mode="json"
        )
    )
    result["photo_ids"] = [
        str(value)
        for value in db.scalars(
            select(Asset.id).where(Asset.property_id == prop.id, Asset.kind == "photo").order_by(Asset.position)
        )
    ]
    result["ownerVerified"] = db.get(User, prop.owner_id).owner_verified
    result["owner_id"] = str(prop.owner_id)
    return result


@router.get("/favorites")
def favorites(context=Depends(authenticated), db: Session = Depends(db_session)):
    query = visible_query().join(Favorite, Favorite.property_id == Property.id).where(Favorite.user_id == context[0].id)
    return {"items": [summary(db, prop) for prop in db.scalars(query)]}


@router.put("/favorites/{property_id}", status_code=204)
def favorite(property_id: UUID, context=Depends(authenticated), db: Session = Depends(db_session)):
    if not db.scalar(visible_query().where(Property.id == property_id)):
        raise HTTPException(404, "PROPERTY_NOT_FOUND")
    # PostgreSQL upsert makes concurrent saves idempotent.
    from sqlalchemy.dialects.postgresql import insert

    db.execute(insert(Favorite).values(user_id=context[0].id, property_id=property_id).on_conflict_do_nothing())
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
