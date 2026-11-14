from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database import db_session
from app.models import AuditEvent, HousingApplication, HousingGroup, Property, Tenancy, User, UserIntent
from app.policy import require_owner, require_shared_seeker
from app.schemas import GroupInput
from app.security import authenticated

router = APIRouter(tags=["shared-housing"])


@router.post("/properties/{property_id}/applications", status_code=201)
def apply(property_id: UUID, context=Depends(authenticated), db: Session = Depends(db_session)):
    user = context[0]
    require_shared_seeker(db, user)
    prop = db.get(Property, property_id)
    if not prop or prop.category != "shared_rental" or prop.status != "approved" or prop.owner_id == user.id:
        raise HTTPException(404, "PROPERTY_NOT_FOUND")
    application = HousingApplication(property_id=prop.id, user_id=user.id)
    db.add(application)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "ALREADY_APPLIED") from None
    return {"id": str(application.id), "status": application.status}


@router.get("/properties/{property_id}/applications")
def applications(property_id: UUID, context=Depends(authenticated), db: Session = Depends(db_session)):
    prop = db.get(Property, property_id)
    if not prop or prop.owner_id != context[0].id:
        raise HTTPException(404, "PROPERTY_NOT_FOUND")
    require_owner(db, context[0], "shared_rental")
    return [
        dict(id=str(a.id), user_id=str(a.user_id), name=db.get(User, a.user_id).name, status=a.status)
        for a in db.scalars(select(HousingApplication).where(HousingApplication.property_id == prop.id))
    ]


@router.post("/applications/{application_id}/accept")
def accept(application_id: UUID, context=Depends(authenticated), db: Session = Depends(db_session)):
    application = db.scalar(select(HousingApplication).where(HousingApplication.id == application_id).with_for_update())
    if not application:
        raise HTTPException(404, "APPLICATION_NOT_FOUND")
    prop = db.scalar(select(Property).where(Property.id == application.property_id).with_for_update())
    user = context[0]
    require_owner(db, user, "shared_rental")
    if prop.owner_id != user.id or prop.status != "approved" or not user.owner_verified:
        raise HTTPException(403, "VERIFIED_PROPERTY_OWNER_REQUIRED")
    if application.status != "pending":
        raise HTTPException(409, "NOT_PENDING")
    tenant = db.get(User, application.user_id)
    if not tenant.active or not db.get(UserIntent, (tenant.id, "tenant_shared")):
        raise HTTPException(409, "TENANT_INELIGIBLE")
    if prop.available_beds is None or prop.available_beds < 1:
        raise HTTPException(409, "NO_BEDS_AVAILABLE")
    # The property row lock serializes competing acceptances for the last bed.
    prop.available_beds -= 1
    application.status = "accepted"
    db.add(Tenancy(property_id=prop.id, user_id=application.user_id))
    db.add(AuditEvent(actor_id=user.id, action="housing_application.accepted", target_id=application.id))
    db.commit()
    return {"status": "accepted", "available_beds": prop.available_beds}


@router.get("/roommates")
def roommates(context=Depends(authenticated), db: Session = Depends(db_session)):
    require_shared_seeker(db, context[0])
    # Preferences/contact consent must be implemented before exposing searchable profiles.
    return {"items": [], "total": 0}


@router.post("/groups", status_code=201)
def create_group(body: GroupInput, context=Depends(authenticated), db: Session = Depends(db_session)):
    user = db.scalar(
        select(User).where(User.id == context[0].id).with_for_update().execution_options(populate_existing=True)
    )
    require_owner(db, user, "shared_rental")
    if user.active_intent != "owner_shared_rental" or not user.owner_verified:
        raise HTTPException(403, "VERIFIED_ACTIVE_SHARED_OWNER_REQUIRED")
    prop = db.get(Property, body.property_id)
    if not prop or prop.owner_id != user.id or prop.category != "shared_rental" or prop.status != "approved":
        raise HTTPException(404, "PROPERTY_NOT_FOUND")
    tenancy = db.get(Tenancy, (prop.id, body.tenant_admin_id))
    tenant = db.get(User, body.tenant_admin_id)
    if not tenancy or not tenancy.active or not tenant or not tenant.active or tenant.id == user.id:
        raise HTTPException(400, "ACTIVE_TENANT_ADMIN_REQUIRED")
    if not db.get(UserIntent, (tenant.id, "tenant_shared")):
        raise HTTPException(400, "SHARED_TENANT_ADMIN_REQUIRED")
    group = HousingGroup(property_id=prop.id, owner_id=user.id, tenant_admin_id=tenant.id)
    db.add(group)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "GROUP_ALREADY_EXISTS") from None
    # This creates membership metadata only, not a plaintext message transport.
    return {"id": str(group.id), "owner_id": str(user.id), "tenant_admin_id": str(tenant.id), "messagingReady": False}
