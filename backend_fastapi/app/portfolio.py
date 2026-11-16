import base64
import hashlib
import hmac
import json
from datetime import datetime
from typing import Literal
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select, tuple_
from sqlalchemy.orm import Session

from app.config import settings
from app.database import db_session
from app.models import AuditEvent, Deal, Favorite, Property, PropertyVisit, User
from app.policy import intents_for
from app.properties import owned, summary, text_filter
from app.schemas import StrictModel
from app.security import authenticated, now

router = APIRouter(tags=["owner-portfolio"])
GROUPS = {
    "sale": ("sale_cash", "sale_installments"),
    "private_rental": ("private_rental",),
    "shared_rental": ("shared_rental",),
}
Group = Literal["all", "sale", "private_rental", "shared_rental"]
Scope = Literal["all", "current", "history"]


@router.get("/properties/mine/overview")
def overview(context=Depends(authenticated), db: Session = Depends(db_session)):
    user = context[0]
    rows = db.execute(
        select(Property.category, Property.availability, Property.status, func.count())
        .where(Property.owner_id == user.id)
        .group_by(Property.category, Property.availability, Property.status)
    ).all()
    selected = {intent.removeprefix("owner_") for intent in intents_for(db, user) if intent.startswith("owner_")}
    selected.update(row[0] for row in rows)
    items = []
    for group, categories in GROUPS.items():
        if not selected.intersection(categories):
            continue
        counts = dict(current=0, published=0, paused=0, history=0, awaiting=0)
        for category, availability, status, count in rows:
            if category not in categories:
                continue
            if availability in ("sold", "rented"):
                counts["history"] += count
            else:
                counts["current"] += count
                counts["published"] += count if status == "approved" and availability == "active" else 0
                counts["paused"] += count if availability == "paused" else 0
                counts["awaiting"] += count if status != "approved" else 0
        items.append(dict(group=group, **counts))
    return {"items": items}


def owner_query(user_id, group, scope, q, availability):
    query = select(Property).where(Property.owner_id == user_id)
    if group != "all":
        query = query.where(Property.category.in_(GROUPS[group]))
    if scope != "all":
        query = query.where(Property.closed_at.is_not(None) if scope == "history" else Property.closed_at.is_(None))
    if availability != "all" and scope == "current":
        query = query.where(Property.availability == availability)
    return text_filter(query, q)


def cursor_encode(values):
    raw = json.dumps(values, separators=(",", ":")).encode()
    signature = hmac.new(settings().jwt_secret.encode(), raw, hashlib.sha256).digest()
    return base64.urlsafe_b64encode(signature + raw).decode()


def cursor_decode(value, binding):
    try:
        data = base64.b64decode(value, altchars=b"-_", validate=True)
        signature, raw = data[:32], data[32:]
        if not hmac.compare_digest(signature, hmac.new(settings().jwt_secret.encode(), raw, hashlib.sha256).digest()):
            raise ValueError()
        values = json.loads(raw)
        if values["binding"] != binding:
            raise ValueError()
        return datetime.fromisoformat(values["time"]), UUID(values["id"])
    except (ValueError, KeyError, TypeError):
        raise HTTPException(400, "INVALID_CURSOR") from None


@router.get("/properties/mine/page")
def page(
    group: Group = "all",
    scope: Scope = "current",
    q: str = Query("", max_length=120),
    availability: Literal["all", "active", "paused"] = "all",
    cursor: str | None = Query(None, max_length=1024),
    context=Depends(authenticated),
    db: Session = Depends(db_session),
):
    user_id = context[0].id
    query = owner_query(user_id, group, scope, q, availability)
    total = db.scalar(select(func.count()).select_from(query.subquery()))
    column = Property.closed_at if scope == "history" else Property.created_at
    binding = hashlib.sha256(json.dumps([str(user_id), group, scope, q.strip(), availability]).encode()).hexdigest()
    if cursor:
        timestamp, identity = cursor_decode(cursor, binding)
        query = query.where(tuple_(column, Property.id) < tuple_(timestamp, identity))
    props = list(db.scalars(query.order_by(column.desc(), Property.id.desc()).limit(4)))
    more = len(props) > 3
    props = props[:3]
    identities = [prop.id for prop in props]
    views = dict(
        db.execute(
            select(PropertyVisit.property_id, func.count())
            .where(PropertyVisit.property_id.in_(identities))
            .group_by(PropertyVisit.property_id)
        ).all()
    )
    saves = dict(
        db.execute(
            select(Favorite.property_id, func.count())
            .join(User, User.id == Favorite.user_id)
            .where(Favorite.property_id.in_(identities), User.active.is_(True), Favorite.user_id != user_id)
            .group_by(Favorite.property_id)
        ).all()
    )
    next_cursor = (
        cursor_encode(dict(binding=binding, time=getattr(props[-1], column.key).isoformat(), id=str(props[-1].id)))
        if more
        else None
    )
    return dict(
        items=[
            summary(db, prop, owner_media=True)
            | {
                "owner_price": str(prop.price),
                "visitor_count": views.get(prop.id, 0),
                "saved_count": saves.get(prop.id, 0),
            }
            for prop in props
        ],
        total=total,
        next_cursor=next_cursor,
        page_size=3,
    )


@router.get("/properties/mine/suggestions")
def suggestions(
    group: Group = "all",
    scope: Scope = "current",
    q: str = Query("", max_length=120),
    context=Depends(authenticated),
    db: Session = Depends(db_session),
):
    query = owner_query(context[0].id, group, scope, q, "all")
    props = db.scalars(query.order_by(Property.created_at.desc(), Property.id.desc()).limit(8))
    return {"items": [dict(id=str(prop.id), title=prop.title) for prop in props]}


class AvailabilityInput(StrictModel):
    availability: Literal["active", "paused", "sold", "rented"]


@router.get("/properties/{property_id}/interested")
def interested(
    property_id: UUID,
    before: str | None = Query(None, max_length=1024),
    context=Depends(authenticated),
    db: Session = Depends(db_session),
):
    prop = db.get(Property, property_id)
    if not prop or prop.owner_id != context[0].id:
        raise HTTPException(404, "PROPERTY_NOT_FOUND")
    query = (
        select(Favorite, User)
        .join(User, User.id == Favorite.user_id)
        .where(Favorite.property_id == prop.id, User.active.is_(True), User.id != prop.owner_id)
    )
    binding = f"interested:{prop.id}:{prop.owner_id}"
    if before:
        time, identity = cursor_decode(before, binding)
        query = query.where(tuple_(Favorite.created_at, Favorite.user_id) < tuple_(time, identity))
    rows = db.execute(query.order_by(Favorite.created_at.desc(), Favorite.user_id.desc()).limit(21)).all()
    more = len(rows) > 20
    rows = rows[:20]
    return {
        "items": [{"id": str(user.id), "name": user.name} for _, user in rows],
        "next_cursor": cursor_encode(
            dict(binding=binding, time=rows[-1][0].created_at.isoformat(), id=str(rows[-1][1].id))
        )
        if more
        else None,
    }


@router.put("/properties/{property_id}/availability")
def change_availability(
    property_id: UUID, body: AvailabilityInput, context=Depends(authenticated), db: Session = Depends(db_session)
):
    prop = owned(db, context[0], property_id)
    if body.availability in ("sold", "rented") and db.scalar(
        select(Deal.id).where(Deal.property_id == prop.id, Deal.stage.in_(["open", "accepted"]))
    ):
        raise HTTPException(409, "ACTIVE_DEAL_WORKFLOW_REQUIRED")
    if body.availability == "active" and db.scalar(
        select(Deal.id).where(Deal.property_id == prop.id, Deal.stage == "accepted", Deal.category != "shared_rental")
    ):
        raise HTTPException(409, "ACTIVE_DEAL_WORKFLOW_REQUIRED")
    target = body.availability
    if prop.availability == target:
        return summary(db, prop, owner_media=True)
    if prop.closed_at is not None or prop.status != "approved":
        raise HTTPException(409, "APPROVED_OPEN_LISTING_REQUIRED")
    expected = "sold" if prop.category.startswith("sale_") else "rented"
    if target in ("sold", "rented") and target != expected:
        raise HTTPException(400, "INVALID_CLOSURE_CATEGORY")
    previous = prop.availability
    prop.availability = target
    if target in ("sold", "rented"):
        prop.closed_at = now()
        if prop.category == "shared_rental":
            prop.available_beds = 0
    db.add(AuditEvent(actor_id=context[0].id, action=f"listing.{previous}.{target}", target_id=prop.id))
    db.commit()
    return summary(db, prop, owner_media=True)
