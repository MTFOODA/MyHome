"""Assigned human eligibility review and bilateral special old-rent fee agreements."""

import hashlib
import json
from decimal import Decimal
from uuid import UUID

from cryptography.fernet import Fernet
from fastapi import APIRouter, Depends, HTTPException, Response
from pydantic import Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import settings
from app.database import db_session
from app.deals import Assignment, ConsentInput, ContractReview, audit, dto, scoped, specialty
from app.financial import Reference, settle, split_total
from app.models import Asset, DealOffer, Property, SpecialFeeProposal, StaffMember, User, Verification
from app.pricing import set_listing_price
from app.schemas import StrictModel
from app.security import administrator, authenticated, now

router = APIRouter(tags=["legal-eligibility"])


def reviewable(db, user, property_id, lock=False):
    query = select(Property).where(Property.id == property_id, Property.rental_period == "old_rent")
    prop = db.scalar(query.with_for_update() if lock else query)
    if not prop or not (
        user.role == "admin" or (specialty(db, user) == "document_reviewer" and prop.eligibility_reviewer_id == user.id)
    ):
        raise HTTPException(404, "ELIGIBILITY_REVIEW_NOT_FOUND")
    return prop


@router.get("/eligibility-reviews")
def pending_eligibility(context=Depends(authenticated), db: Session = Depends(db_session)):
    user = context[0]
    query = select(Property).where(Property.rental_period == "old_rent")
    if user.role != "admin":
        if specialty(db, user) != "document_reviewer":
            raise HTTPException(403, "DOCUMENT_REVIEWER_REQUIRED")
        query = query.where(Property.eligibility_reviewer_id == user.id)
    return {
        "items": [
            dict(
                id=str(p.id),
                title=p.title,
                eligibility=p.legal_eligibility,
                assigned=p.eligibility_reviewer_id is not None,
            )
            for p in db.scalars(query.order_by(Property.created_at.desc()).limit(100))
        ]
    }


@router.put("/admin/properties/{property_id}/eligibility-reviewer")
def assign_eligibility(
    property_id: UUID, body: Assignment, admin=Depends(administrator), db: Session = Depends(db_session)
):
    prop = reviewable(db, admin, property_id, True)
    staff = db.get(StaffMember, body.staff_id)
    worker = db.get(User, body.staff_id)
    if (
        not staff
        or not staff.active
        or staff.specialty != "document_reviewer"
        or not worker.active
        or worker.id == prop.owner_id
    ):
        raise HTTPException(400, "ELIGIBLE_DOCUMENT_REVIEWER_REQUIRED")
    prop.eligibility_reviewer_id = worker.id
    audit(db, admin, "eligibility.reviewer_assigned", prop.id)
    db.commit()
    return {"status": prop.legal_eligibility}


@router.get("/eligibility-reviews/{property_id}/documents")
def eligibility_documents(property_id: UUID, context=Depends(authenticated), db: Session = Depends(db_session)):
    prop = reviewable(db, context[0], property_id)
    record = db.scalar(select(Verification).where(Verification.property_id == prop.id))
    return {
        "items": []
        if not record
        else [
            dict(id=str(record.identity_asset_id), kind="identity"),
            dict(id=str(record.ownership_asset_id), kind="ownership"),
        ]
    }


@router.get("/eligibility-reviews/{property_id}/documents/{asset_id}")
def eligibility_image(
    property_id: UUID, asset_id: UUID, context=Depends(authenticated), db: Session = Depends(db_session)
):
    if str(asset_id) not in [i["id"] for i in eligibility_documents(property_id, context, db)["items"]]:
        raise HTTPException(404, "DOCUMENT_NOT_FOUND")
    asset = db.get(Asset, asset_id)
    data = Fernet(settings().document_key).decrypt((settings().storage_path / asset.storage_name).read_bytes())
    audit(db, context[0], "eligibility.document_read", asset.id)
    db.commit()
    return Response(
        data, media_type="image/jpeg", headers={"Cache-Control": "no-store", "X-Content-Type-Options": "nosniff"}
    )


@router.post("/eligibility-reviews/{property_id}/decision")
def eligibility_decision(
    property_id: UUID, body: ContractReview, context=Depends(authenticated), db: Session = Depends(db_session)
):
    user = context[0]
    prop = reviewable(db, user, property_id, True)
    if (
        specialty(db, user) != "document_reviewer"
        or prop.eligibility_reviewer_id != user.id
        or prop.owner_id == user.id
    ):
        raise HTTPException(403, "ASSIGNED_DOCUMENT_REVIEWER_REQUIRED")
    record = db.scalar(select(Verification).where(Verification.property_id == prop.id))
    if body.approved and (prop.status != "approved" or not record or record.status != "approved"):
        raise HTTPException(409, "VERIFIED_PROPERTY_DOCUMENTS_REQUIRED")
    prop.legal_eligibility = "eligible" if body.approved else "ineligible"
    prop.eligibility_note = body.note
    prop.eligibility_reference = body.contract_reference
    if body.approved:
        set_listing_price(prop, db)
    audit(db, user, "eligibility." + prop.legal_eligibility, prop.id)
    db.commit()
    return {"status": prop.legal_eligibility, "commission_reference_months": 12, "legal_contract_months": None}


class SpecialFeeInput(StrictModel):
    total: Decimal = Field(ge=0, max_digits=14, decimal_places=2)
    reason: str = Field(min_length=20, max_length=2000)
    legal_reference: str = Field(min_length=6, max_length=250)


@router.post("/admin/deals/{deal_id}/special-fees", status_code=201)
def propose_special_fee(
    deal_id: UUID, body: SpecialFeeInput, admin=Depends(administrator), db: Session = Depends(db_session)
):
    deal = scoped(db, admin, deal_id, True)
    if (
        deal.stage != "open"
        or deal.rental_period != "old_rent"
        or db.get(Property, deal.property_id).legal_eligibility != "eligible"
    ):
        raise HTTPException(409, "ELIGIBLE_OPEN_OLD_RENT_DEAL_REQUIRED")
    buyer = split_total(body.total)[0]
    settle(
        Reference(deal.category, deal.base_price, body.total, buyer, body.total - buyer, 12, True), deal.asking_price
    )
    for previous in db.scalars(
        select(SpecialFeeProposal).where(SpecialFeeProposal.deal_id == deal.id, SpecialFeeProposal.status == "pending")
    ):
        previous.status = "rejected"
    for offer in db.scalars(select(DealOffer).where(DealOffer.deal_id == deal.id, DealOffer.status == "open")):
        offer.status = "superseded"
    db.flush()
    digest = hashlib.sha256(
        json.dumps([str(deal.id), str(deal.base_price), str(body.total), body.reason, body.legal_reference]).encode()
    ).hexdigest()
    proposal = SpecialFeeProposal(
        deal_id=deal.id,
        created_by=admin.id,
        previous_total=deal.fee_total,
        total=body.total,
        reason=body.reason,
        legal_reference=body.legal_reference,
        digest=digest,
    )
    db.add(proposal)
    db.flush()
    audit(db, admin, "fee.special_proposed", proposal.id)
    db.commit()
    return dto(db, deal, admin)


@router.post("/special-fees/{proposal_id}/consent")
def consent_special_fee(
    proposal_id: UUID, body: ConsentInput, context=Depends(authenticated), db: Session = Depends(db_session)
):
    user = context[0]
    proposal = db.get(SpecialFeeProposal, proposal_id)
    if not proposal:
        raise HTTPException(404, "SPECIAL_FEE_NOT_FOUND")
    deal = scoped(db, user, proposal.deal_id, True)
    if db.get(Property, deal.property_id).legal_eligibility != "eligible":
        raise HTTPException(409, "LEGAL_ELIGIBILITY_REQUIRED")
    proposal = db.scalar(
        select(SpecialFeeProposal)
        .where(SpecialFeeProposal.id == proposal_id)
        .with_for_update()
        .execution_options(populate_existing=True)
    )
    if (
        user.id not in (deal.buyer_id, deal.seller_id)
        or deal.stage != "open"
        or proposal.status != "pending"
        or proposal.digest != body.digest
    ):
        raise HTTPException(409, "CURRENT_BILATERAL_SPECIAL_FEE_REQUIRED")
    if not body.accepted:
        proposal.status = "rejected"
    else:
        if user.id == deal.buyer_id:
            proposal.buyer_accepted_at = now()
        else:
            proposal.seller_accepted_at = now()
        if proposal.buyer_accepted_at and proposal.seller_accepted_at:
            buyer = split_total(proposal.total)[0]
            deal.fee_total = proposal.total
            deal.buyer_fee = buyer
            deal.seller_fee = proposal.total - buyer
            proposal.status = "applied"
    audit(db, user, "fee.special_consent_recorded", proposal.id)
    db.commit()
    return dto(db, deal, user)
