"""Supervised sales: explicit consent records and manually verified external payments."""

import hashlib
import hmac
import io
import json
from datetime import UTC, timedelta
from decimal import Decimal
from typing import Literal
from uuid import UUID, uuid4

import bcrypt
from cryptography.fernet import Fernet
from fastapi import APIRouter, Depends, File, Form, HTTPException, Request, Response, UploadFile
from pydantic import AwareDatetime, EmailStr, Field, StrictBool, field_validator, model_validator
from sqlalchemy import exists, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.assets import decode_image
from app.config import settings
from app.database import db_session
from app.financial import Reference, settle, split_total
from app.models import (
    Asset,
    AuditEvent,
    BrokerageTerms,
    Deal,
    DealConsent,
    DealOffer,
    FeeInvoice,
    HousingApplication,
    PaymentClaim,
    PaymentDestination,
    Property,
    SpecialFeeProposal,
    StaffMember,
    Tenancy,
    User,
    Verification,
    Viewing,
)
from app.policy import intents_for
from app.properties import visible_query
from app.schemas import Login, Money, StrictModel
from app.security import administrator, authenticated, now

router = APIRouter(tags=["supervised-sales"])


def audit(db, user, action, target):
    db.add(AuditEvent(actor_id=user.id, action=action, target_id=target))


def specialty(db, user):
    staff = db.get(StaffMember, user.id)
    return staff.specialty if staff and staff.active and user.active else None


def scoped(db, user, identity, lock=False):
    query = select(Deal).where(Deal.id == identity)
    deal = db.scalar(query.with_for_update() if lock else query)
    allowed = deal and (user.role == "admin" or user.id in (deal.buyer_id, deal.seller_id))
    kind = specialty(db, user)
    if deal and kind == "document_reviewer" and deal.reviewer_id == user.id:
        allowed = True
    if (
        deal
        and kind == "field_agent"
        and db.scalar(select(Viewing.id).where(Viewing.deal_id == deal.id, Viewing.staff_id == user.id))
    ):
        allowed = True
    if not allowed:
        raise HTTPException(404, "DEAL_NOT_FOUND")
    return deal


def party(deal, user):
    if user.id not in (deal.buyer_id, deal.seller_id):
        raise HTTPException(403, "DEAL_PARTY_REQUIRED")


def eligibility_required(db, deal):
    if deal.rental_period == "old_rent" and db.get(Property, deal.property_id).legal_eligibility != "eligible":
        raise HTTPException(409, "OLD_RENT_ELIGIBILITY_REQUIRED")
    if db.scalar(
        select(SpecialFeeProposal.id).where(
            SpecialFeeProposal.deal_id == deal.id, SpecialFeeProposal.status == "pending"
        )
    ):
        raise HTTPException(409, "SPECIAL_FEE_CONSENTS_REQUIRED")


def digest_for(db, deal):
    offer = db.scalar(select(DealOffer).where(DealOffer.deal_id == deal.id, DealOffer.status == "accepted"))
    terms = db.get(BrokerageTerms, deal.terms_id) if deal.terms_id else None
    if not offer or not terms:
        return None
    content = dict(
        deal=str(deal.id),
        terms=terms.version,
        ar=terms.body_ar,
        en=terms.body_en,
        due=terms.due_condition,
        base=str(deal.base_price),
        category=deal.category,
        rental_period=deal.rental_period,
        reference_months=deal.rental_months,
        offer=str(offer.amount),
        total=str(deal.fee_total),
        buyer=str(deal.buyer_fee),
        seller=str(deal.seller_fee),
    )
    return hashlib.sha256(json.dumps(content, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


def consented(db, deal):
    expected = digest_for(db, deal)
    return expected and all(
        (row := db.get(DealConsent, (deal.id, identity))) and row.digest == expected
        for identity in (deal.buyer_id, deal.seller_id)
    )


def dto(db, deal, user):
    offers = list(
        db.scalars(
            select(DealOffer).where(DealOffer.deal_id == deal.id).order_by(DealOffer.created_at.desc()).limit(30)
        )
    )
    accepted = next((o for o in offers if o.status == "accepted"), None)
    terms = db.get(BrokerageTerms, deal.terms_id) if deal.terms_id else None
    invoices = list(db.scalars(select(FeeInvoice).where(FeeInvoice.deal_id == deal.id)))
    side = (
        "buyer"
        if user.id == deal.buyer_id
        else "seller"
        if user.id == deal.seller_id
        else "admin"
        if user.role == "admin"
        else specialty(db, user)
    )
    reference = Reference(
        deal.category,
        deal.base_price,
        deal.fee_total,
        deal.buyer_fee,
        deal.seller_fee,
        deal.rental_months,
        deal.rental_period == "old_rent",
    )
    financial = settle(reference, accepted.amount if accepted else deal.asking_price)
    buyer_paid = sum((i.amount for i in invoices if i.payer_id == deal.buyer_id and i.status == "verified"), Decimal(0))
    seller_paid = sum(
        (i.amount for i in invoices if i.payer_id == deal.seller_id and i.status == "verified"), Decimal(0)
    )
    return dict(
        id=str(deal.id),
        property_id=str(deal.property_id),
        title=deal.property_title,
        stage=deal.stage,
        my_side=side,
        base_price=str(deal.base_price),
        fee_total=str(deal.fee_total),
        buyer_fee=str(deal.buyer_fee),
        seller_fee=str(deal.seller_fee),
        negotiated_price=str(accepted.amount) if accepted else None,
        buyer_total=financial["buyer_total"],
        seller_net=financial["seller_net"],
        financial=financial,
        buyer_platform_paid=str(buyer_paid),
        seller_platform_paid=str(seller_paid),
        buyer_remaining_total=str(Decimal(financial["buyer_total"]) - buyer_paid),
        remaining_platform_buyer=str(deal.buyer_fee - buyer_paid),
        remaining_platform_seller=str(deal.seller_fee - seller_paid),
        offers=[
            dict(
                id=str(o.id),
                amount=settle(reference, o.amount)["display_price"],
                property_amount=str(o.amount),
                status=o.status,
                from_side="buyer" if o.created_by == deal.buyer_id else "seller",
                can_respond=o.created_by != user.id
                and side in ("buyer", "seller")
                and o.status == "open"
                and deal.stage == "open",
            )
            for o in offers
        ],
        viewings=[
            dict(
                id=str(v.id),
                reference=v.reference,
                scheduled_at=v.scheduled_at.isoformat(),
                status=v.status,
                owner_confirmed=v.owner_confirmed,
                staff_assigned=v.staff_id is not None,
                my_assignment=v.staff_id == user.id,
            )
            for v in db.scalars(select(Viewing).where(Viewing.deal_id == deal.id).order_by(Viewing.scheduled_at.desc()))
        ],
        terms=dict(
            version=terms.version,
            body_ar=terms.body_ar,
            body_en=terms.body_en,
            due_condition=terms.due_condition,
            digest=digest_for(db, deal),
            signature_method="explicit_consent_record",
        )
        if terms
        else None,
        buyer_consented=bool(db.get(DealConsent, (deal.id, deal.buyer_id))),
        seller_consented=bool(db.get(DealConsent, (deal.id, deal.seller_id))),
        review_status=deal.review_status,
        reviewer_assigned=deal.reviewer_id is not None,
        qr_ready=deal.destination_id is not None,
        invoices=[
            dict(
                id=str(i.id),
                side="buyer" if i.payer_id == deal.buyer_id else "seller",
                amount=str(i.amount),
                status=i.status,
                mine=i.payer_id == user.id,
            )
            for i in invoices
        ],
        claims=[
            dict(id=str(c.id), invoice_id=str(c.invoice_id), reference=c.reference, status=c.status)
            for c in db.scalars(
                select(PaymentClaim)
                .where(
                    PaymentClaim.invoice_id.in_(
                        [i.id for i in invoices if i.payer_id == user.id or user.role == "admin"]
                    )
                )
                .order_by(PaymentClaim.created_at.desc())
            )
        ],
        special_fee_proposals=[
            dict(
                id=str(p.id),
                total=str(p.total),
                financial=settle(
                    Reference(
                        deal.category,
                        deal.base_price,
                        p.total,
                        *split_total(p.total),
                        deal.rental_months,
                        deal.rental_period == "old_rent",
                    ),
                    deal.asking_price,
                ),
                previous_total=str(p.previous_total),
                reason=p.reason,
                digest=p.digest,
                status=p.status,
                buyer_accepted=p.buyer_accepted_at is not None,
                seller_accepted=p.seller_accepted_at is not None,
            )
            for p in db.scalars(
                select(SpecialFeeProposal)
                .where(SpecialFeeProposal.deal_id == deal.id)
                .order_by(SpecialFeeProposal.created_at.desc())
                .limit(10)
            )
        ],
        payment_recipient=db.get(PaymentDestination, deal.destination_id).recipient_name
        if deal.destination_id and side in ("buyer", "seller", "admin")
        else None,
        messaging_ready=True,
    )


class StaffInput(Login):
    email: EmailStr
    name: str = Field(min_length=2, max_length=100)
    password: str = Field(min_length=12, max_length=72)
    specialty: Literal["field_agent", "document_reviewer"]
    professional_reference: str | None = Field(None, max_length=150)

    @field_validator("name", mode="before")
    @classmethod
    def trim_name(cls, value):
        return value.strip() if isinstance(value, str) else value

    @model_validator(mode="after")
    def qualification(self):
        if self.specialty == "document_reviewer" and not (
            self.professional_reference and len(self.professional_reference.strip()) >= 5
        ):
            raise ValueError("PROFESSIONAL_REFERENCE_REQUIRED")
        return self


@router.post("/admin/staff", status_code=201)
def create_staff(body: StaffInput, admin=Depends(administrator), db: Session = Depends(db_session)):
    user = User(
        name=body.name.strip(),
        email=str(body.email),
        password_hash=bcrypt.hashpw(body.password.encode(), bcrypt.gensalt(12)).decode(),
        role="user",
        onboarding_complete=True,
    )
    db.add(user)
    try:
        db.flush()
        db.add(
            StaffMember(user_id=user.id, specialty=body.specialty, professional_reference=body.professional_reference)
        )
        audit(db, admin, "staff.created", user.id)
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "EMAIL_IN_USE") from None
    return dict(id=str(user.id), name=user.name, specialty=body.specialty)


@router.get("/admin/staff")
def list_staff(admin=Depends(administrator), db: Session = Depends(db_session)):
    return {
        "items": [
            dict(
                id=str(u.id),
                name=u.name,
                specialty="admin" if u.role == "admin" else s.specialty,
                active=u.active and (s.active if s and u.role != "admin" else True),
            )
            for s, u in db.execute(
                select(StaffMember, User)
                .select_from(User)
                .outerjoin(StaffMember, User.id == StaffMember.user_id)
                .where(or_(User.role == "admin", StaffMember.user_id.is_not(None)))
                .order_by(User.name, User.id)
                .limit(100)
            )
        ]
    }


class StaffState(StrictModel):
    active: StrictBool


@router.put("/admin/staff/{user_id}")
def staff_state(user_id: UUID, body: StaffState, admin=Depends(administrator), db: Session = Depends(db_session)):
    row = db.scalar(select(StaffMember).where(StaffMember.user_id == user_id).with_for_update())
    if not row:
        raise HTTPException(404, "STAFF_NOT_FOUND")
    row.active = body.active
    audit(db, admin, "staff.state_changed", user_id)
    db.commit()
    return {"active": row.active}


class TermsInput(StrictModel):
    version: str = Field(min_length=3, max_length=60)
    body_ar: str = Field(min_length=100, max_length=20000)
    body_en: str = Field(min_length=100, max_length=20000)
    due_condition: str = Field(min_length=20, max_length=2000)
    legal_reference: str = Field(min_length=5, max_length=250)
    legal_reviewed: StrictBool


@router.post("/admin/brokerage-terms", status_code=201)
def publish_terms(body: TermsInput, admin=Depends(administrator), db: Session = Depends(db_session)):
    if not body.legal_reviewed:
        raise HTTPException(400, "LEGAL_REVIEW_REQUIRED")
    row = BrokerageTerms(**body.model_dump(exclude={"legal_reviewed"}), created_by=admin.id)
    db.add(row)
    try:
        db.flush()
        audit(db, admin, "brokerage.terms_published", row.id)
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "TERMS_VERSION_EXISTS") from None
    return {"id": str(row.id), "version": row.version}


@router.post("/admin/payment-destination", status_code=201)
def configure_destination(
    recipient_name: str = Form(..., min_length=3, max_length=150),
    file: UploadFile = File(...),
    admin=Depends(administrator),
    db: Session = Depends(db_session),
):
    raw = file.file.read(2 * 1024 * 1024 + 1)
    file.file.close()
    if len(recipient_name.strip()) < 3:
        raise HTTPException(422, "RECIPIENT_NAME_REQUIRED")
    if not raw or len(raw) > 2 * 1024 * 1024:
        raise HTTPException(413, "QR_MAX_2MB")
    image = decode_image(raw)
    image.thumbnail((1600, 1600))
    output = io.BytesIO()
    image.save(output, "PNG")
    name = f"{uuid4()}.bin"
    path = settings().storage_path / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(Fernet(settings().document_key).encrypt(output.getvalue()))
    path.chmod(0o600)
    try:
        asset = Asset(owner_id=admin.id, kind="payment_qr", storage_name=name)
        db.add(asset)
        db.flush()
        destination = PaymentDestination(
            qr_asset_id=asset.id, recipient_name=recipient_name.strip(), created_by=admin.id
        )
        db.add(destination)
        db.flush()
        audit(db, admin, "payment.destination_configured", destination.id)
        db.commit()
    except Exception:
        db.rollback()
        path.unlink(missing_ok=True)
        raise
    return {"id": str(destination.id), "recipient_name": destination.recipient_name}


class DealInput(StrictModel):
    property_id: UUID


@router.post("/deals", status_code=201)
def start_deal(body: DealInput, context=Depends(authenticated), db: Session = Depends(db_session)):
    user = context[0]
    prop = db.scalar(visible_query().where(Property.id == body.property_id).with_for_update(of=Property))
    if not prop or prop.owner_id == user.id:
        raise HTTPException(404, "PROPERTY_NOT_FOUND")
    if prop.pricing_policy in ("manual-fee-required", "eligibility-pending") or (
        prop.rental_period == "old_rent" and prop.legal_eligibility != "eligible"
    ):
        raise HTTPException(409, "RENTAL_FEE_AGREEMENT_REQUIRED")
    required = {
        "sale_cash": "buyer_cash",
        "sale_installments": "buyer_installments",
        "private_rental": "tenant_private",
        "shared_rental": "tenant_shared",
    }[prop.category]
    if required not in intents_for(db, user):
        raise HTTPException(403, "BUYER_INTENT_REQUIRED")
    existing = db.scalar(
        select(Deal).where(Deal.property_id == prop.id, Deal.buyer_id == user.id, Deal.stage.in_(["open", "accepted"]))
    )
    if existing:
        return dto(db, existing, user)
    total, buyer = prop.platform_fee, prop.buyer_fee
    deal = Deal(
        property_id=prop.id,
        buyer_id=user.id,
        seller_id=prop.owner_id,
        property_title=prop.title,
        base_price=prop.original_price,
        category=prop.category,
        rental_months=prop.reference_months,
        rental_period=prop.rental_period,
        asking_price=prop.price,
        fee_total=total,
        buyer_fee=buyer,
        seller_fee=total - buyer,
    )
    db.add(deal)
    db.flush()
    audit(db, user, "deal.opened", deal.id)
    db.commit()
    return dto(db, deal, user)


@router.get("/deals")
def my_deals(context=Depends(authenticated), db: Session = Depends(db_session)):
    user = context[0]
    query = select(Deal)
    if user.role != "admin":
        kind = specialty(db, user)
        query = query.where(
            or_(
                Deal.buyer_id == user.id,
                Deal.seller_id == user.id,
                Deal.reviewer_id == user.id if kind == "document_reviewer" else False,
                exists().where(Viewing.deal_id == Deal.id, Viewing.staff_id == user.id)
                if kind == "field_agent"
                else False,
            )
        )
    return {
        "items": [
            dict(
                id=str(d.id),
                title=d.property_title,
                stage=d.stage,
                base_price=str(d.base_price),
                fee_total=str(d.fee_total),
            )
            for d in db.scalars(query.order_by(Deal.created_at.desc(), Deal.id).limit(100))
        ]
    }


@router.get("/deals/{deal_id}")
def get_deal(deal_id: UUID, context=Depends(authenticated), db: Session = Depends(db_session)):
    return dto(db, scoped(db, context[0], deal_id), context[0])


class ViewingInput(StrictModel):
    scheduled_at: AwareDatetime


@router.post("/deals/{deal_id}/viewings", status_code=201)
def request_viewing(
    deal_id: UUID, body: ViewingInput, context=Depends(authenticated), db: Session = Depends(db_session)
):
    user = context[0]
    deal = scoped(db, user, deal_id, True)
    if user.id != deal.buyer_id or deal.stage != "open":
        raise HTTPException(403, "BUYER_OPEN_DEAL_REQUIRED")
    when = body.scheduled_at.astimezone(UTC)
    if not now() < when < now() + timedelta(days=180) or any((when.minute, when.second, when.microsecond)):
        raise HTTPException(400, "FUTURE_HOURLY_SLOT_REQUIRED")
    if db.scalar(select(Viewing).where(Viewing.deal_id == deal.id, Viewing.status.in_(["requested", "confirmed"]))):
        raise HTTPException(409, "VIEWING_ALREADY_PENDING")
    row = Viewing(deal_id=deal.id, reference="MH-" + uuid4().hex[:16].upper(), scheduled_at=when)
    db.add(row)
    db.flush()
    audit(db, user, "viewing.requested", row.id)
    db.commit()
    return dto(db, deal, user)


@router.post("/viewings/{viewing_id}/owner-confirm")
def owner_confirm(viewing_id: UUID, context=Depends(authenticated), db: Session = Depends(db_session)):
    row = db.scalar(select(Viewing).where(Viewing.id == viewing_id).with_for_update())
    if not row:
        raise HTTPException(404, "VIEWING_NOT_FOUND")
    deal = scoped(db, context[0], row.deal_id, True)
    if context[0].id != deal.seller_id or deal.stage != "open" or row.status != "requested":
        raise HTTPException(403, "SELLER_CONFIRMATION_REQUIRED")
    row.owner_confirmed = True
    audit(db, context[0], "viewing.owner_confirmed", row.id)
    db.commit()
    return dto(db, deal, context[0])


class Assignment(StrictModel):
    staff_id: UUID


@router.put("/admin/viewings/{viewing_id}/assign")
def assign_viewing(viewing_id: UUID, body: Assignment, admin=Depends(administrator), db: Session = Depends(db_session)):
    row = db.scalar(select(Viewing).where(Viewing.id == viewing_id).with_for_update())
    staff = db.scalar(select(StaffMember).where(StaffMember.user_id == body.staff_id).with_for_update())
    worker = db.get(User, body.staff_id)
    if not row or not row.owner_confirmed or row.status != "requested":
        raise HTTPException(409, "OWNER_CONFIRMED_VIEWING_REQUIRED")
    deal = db.get(Deal, row.deal_id)
    if (
        deal.stage != "open"
        or not staff
        or not staff.active
        or not worker.active
        or staff.specialty != "field_agent"
        or worker.id in (deal.buyer_id, deal.seller_id)
    ):
        raise HTTPException(400, "ELIGIBLE_FIELD_AGENT_REQUIRED")
    if db.scalar(
        select(Viewing.id).where(
            Viewing.staff_id == worker.id,
            Viewing.scheduled_at == row.scheduled_at,
            Viewing.status.in_(["confirmed", "completed"]),
        )
    ):
        raise HTTPException(409, "STAFF_SLOT_UNAVAILABLE")
    row.staff_id = worker.id
    row.status = "confirmed"
    audit(db, admin, "viewing.assigned", row.id)
    db.commit()
    return dto(db, deal, admin)


class Note(StrictModel):
    note: str = Field(min_length=10, max_length=1000)


@router.post("/viewings/{viewing_id}/complete")
def complete_viewing(viewing_id: UUID, body: Note, context=Depends(authenticated), db: Session = Depends(db_session)):
    user = context[0]
    row = db.scalar(select(Viewing).where(Viewing.id == viewing_id).with_for_update())
    if not row:
        raise HTTPException(404, "VIEWING_NOT_FOUND")
    deal = scoped(db, user, row.deal_id, True)
    if user.role != "admin" and not (row.staff_id == user.id and specialty(db, user) == "field_agent"):
        raise HTTPException(403, "ASSIGNED_FIELD_AGENT_REQUIRED")
    if row.status != "confirmed" or row.scheduled_at > now() or deal.stage != "open":
        raise HTTPException(409, "CONFIRMED_DUE_VIEWING_REQUIRED")
    row.status = "completed"
    row.completion_note = body.note
    audit(db, user, "viewing.completed", row.id)
    db.commit()
    return dto(db, deal, user)


class OfferInput(StrictModel):
    amount: Money
    basis: Literal["all_in", "property"] = "all_in"


@router.post("/deals/{deal_id}/offers", status_code=201)
def offer(deal_id: UUID, body: OfferInput, context=Depends(authenticated), db: Session = Depends(db_session)):
    user = context[0]
    deal = scoped(db, user, deal_id, True)
    party(deal, user)
    eligibility_required(db, deal)
    if deal.stage != "open":
        raise HTTPException(409, "OPEN_DEAL_REQUIRED")
    if not db.scalar(select(Viewing.id).where(Viewing.deal_id == deal.id, Viewing.status == "completed")):
        raise HTTPException(409, "COMPLETED_VIEWING_REQUIRED")
    reference = Reference(
        deal.category,
        deal.base_price,
        deal.fee_total,
        deal.buyer_fee,
        deal.seller_fee,
        deal.rental_months,
        deal.rental_period == "old_rent",
    )
    periods = 1 if reference.old_rent else reference.months or 1
    amount = body.amount - deal.buyer_fee / periods if body.basis == "all_in" else body.amount
    settle(reference, amount)
    for row in db.scalars(select(DealOffer).where(DealOffer.deal_id == deal.id, DealOffer.status == "open")):
        row.status = "superseded"
    db.flush()
    db.add(DealOffer(deal_id=deal.id, created_by=user.id, amount=amount))
    audit(db, user, "deal.offer_created", deal.id)
    db.commit()
    return dto(db, deal, user)


class Decision(StrictModel):
    approved: StrictBool


@router.put("/offers/{offer_id}/decision")
def decide_offer(offer_id: UUID, body: Decision, context=Depends(authenticated), db: Session = Depends(db_session)):
    user = context[0]
    row = db.get(DealOffer, offer_id)
    if not row:
        raise HTTPException(404, "OFFER_NOT_FOUND")
    deal = scoped(db, user, row.deal_id, True)
    party(deal, user)
    eligibility_required(db, deal)
    row = db.scalar(
        select(DealOffer).where(DealOffer.id == offer_id).with_for_update().execution_options(populate_existing=True)
    )
    if deal.stage != "open" or row.status != "open" or row.created_by == user.id:
        raise HTTPException(409, "OTHER_PARTY_OPEN_OFFER_REQUIRED")
    if body.approved:
        prop = db.scalar(select(Property).where(Property.id == deal.property_id).with_for_update())
        existing_tenant = db.get(Tenancy, (prop.id, deal.buyer_id)) if deal.category == "shared_rental" else None
        if prop.status != "approved" or (
            prop.availability != "active" and not (existing_tenant and existing_tenant.active)
        ):
            raise HTTPException(409, "PROPERTY_NOT_AVAILABLE")
        terms = db.scalar(select(BrokerageTerms).order_by(BrokerageTerms.created_at.desc(), BrokerageTerms.id).limit(1))
        if not terms:
            raise HTTPException(409, "REVIEWED_TERMS_NOT_CONFIGURED")
        if deal.category != "shared_rental" and db.scalar(
            select(Deal.id).where(Deal.property_id == prop.id, Deal.stage.in_(["accepted", "completed"]))
        ):
            raise HTTPException(409, "PROPERTY_RESERVED")
        deal.stage = "accepted"
        deal.terms_id = terms.id
        if deal.category == "shared_rental":
            if not (existing_tenant and existing_tenant.active):
                if not prop.available_beds:
                    raise HTTPException(409, "NO_BEDS_AVAILABLE")
                prop.available_beds -= 1
                deal.bed_reserved = True
            if prop.available_beds == 0:
                prop.availability = "paused"
        else:
            prop.availability = "paused"
    row.status = "accepted" if body.approved else "rejected"
    audit(db, user, "deal.offer_" + row.status, deal.id)
    db.commit()
    return dto(db, deal, user)


class ConsentInput(StrictModel):
    digest: str = Field(pattern=r"^[0-9a-f]{64}$")
    accepted: StrictBool


@router.post("/deals/{deal_id}/consent")
def consent(
    deal_id: UUID,
    body: ConsentInput,
    request: Request,
    context=Depends(authenticated),
    db: Session = Depends(db_session),
):
    user = context[0]
    deal = scoped(db, user, deal_id, True)
    party(deal, user)
    eligibility_required(db, deal)
    if deal.stage != "accepted" or not body.accepted or body.digest != digest_for(db, deal):
        raise HTTPException(409, "CURRENT_AGREEMENT_CONSENT_REQUIRED")
    if not db.get(DealConsent, (deal.id, user.id)):
        evidence = json.dumps(
            [
                str(user.id),
                body.digest,
                request.client.host if request.client else "",
                request.headers.get("user-agent", "")[:512],
                now().isoformat(),
            ]
        ).encode()
        db.add(
            DealConsent(
                deal_id=deal.id,
                user_id=user.id,
                digest=body.digest,
                evidence_digest=hmac.new(settings().document_key.encode(), evidence, hashlib.sha256).hexdigest(),
            )
        )
        audit(db, user, "deal.consent_recorded", deal.id)
        db.commit()
    return dto(db, deal, user)


@router.put("/admin/deals/{deal_id}/reviewer")
def assign_reviewer(deal_id: UUID, body: Assignment, admin=Depends(administrator), db: Session = Depends(db_session)):
    deal = scoped(db, admin, deal_id, True)
    staff = db.get(StaffMember, body.staff_id)
    worker = db.get(User, body.staff_id)
    if (
        deal.stage != "accepted"
        or not staff
        or not staff.active
        or staff.specialty != "document_reviewer"
        or not worker.active
        or body.staff_id in (deal.buyer_id, deal.seller_id)
    ):
        raise HTTPException(400, "ELIGIBLE_DOCUMENT_REVIEWER_REQUIRED")
    if deal.review_status == "approved":
        raise HTTPException(409, "CONTRACT_ALREADY_REVIEWED")
    deal.reviewer_id = body.staff_id
    audit(db, admin, "deal.reviewer_assigned", deal.id)
    db.commit()
    return dto(db, deal, admin)


@router.get("/deals/{deal_id}/documents")
def documents(deal_id: UUID, context=Depends(authenticated), db: Session = Depends(db_session)):
    user = context[0]
    deal = scoped(db, user, deal_id)
    if not (
        user.role == "admin" or (specialty(db, user) == "document_reviewer" and deal.reviewer_id == user.id)
    ) or not consented(db, deal):
        raise HTTPException(403, "ASSIGNED_REVIEWER_AND_CONSENTS_REQUIRED")
    verification = db.scalar(select(Verification).where(Verification.property_id == deal.property_id))
    if not verification:
        return {"items": []}
    return {
        "items": [
            dict(id=str(verification.identity_asset_id), kind="identity"),
            dict(id=str(verification.ownership_asset_id), kind="ownership"),
        ]
    }


@router.get("/deals/{deal_id}/documents/{asset_id}")
def document_image(deal_id: UUID, asset_id: UUID, context=Depends(authenticated), db: Session = Depends(db_session)):
    allowed = documents(deal_id, context, db)["items"]
    if str(asset_id) not in [item["id"] for item in allowed]:
        raise HTTPException(404, "DOCUMENT_NOT_FOUND")
    asset = db.get(Asset, asset_id)
    raw = Fernet(settings().document_key).decrypt((settings().storage_path / asset.storage_name).read_bytes())
    audit(db, context[0], "deal.document_read", asset.id)
    db.commit()
    return Response(
        raw, media_type="image/jpeg", headers={"Cache-Control": "no-store", "X-Content-Type-Options": "nosniff"}
    )


class ContractReview(Decision):
    contract_reference: str = Field(min_length=6, max_length=250)
    note: str = Field(min_length=20, max_length=2000)


@router.post("/deals/{deal_id}/contract-review")
def contract_review(
    deal_id: UUID, body: ContractReview, context=Depends(authenticated), db: Session = Depends(db_session)
):
    user = context[0]
    deal = scoped(db, user, deal_id, True)
    eligibility_required(db, deal)
    if (
        specialty(db, user) != "document_reviewer"
        or deal.reviewer_id != user.id
        or user.id in (deal.buyer_id, deal.seller_id)
    ):
        raise HTTPException(403, "ASSIGNED_DOCUMENT_REVIEWER_REQUIRED")
    if deal.stage != "accepted" or not consented(db, deal) or deal.review_status == "approved":
        raise HTTPException(409, "CONSENTED_UNREVIEWED_CONTRACT_REQUIRED")
    verification = db.scalar(select(Verification).where(Verification.property_id == deal.property_id))
    if body.approved and (not verification or verification.status != "approved"):
        raise HTTPException(409, "VERIFIED_PROPERTY_DOCUMENTS_REQUIRED")
    deal.review_status = "approved" if body.approved else "rejected"
    deal.contract_reference = body.contract_reference
    deal.review_note = body.note
    if body.approved:
        destination = db.scalar(
            select(PaymentDestination).order_by(PaymentDestination.created_at.desc(), PaymentDestination.id).limit(1)
        )
        deal.destination_id = destination.id if destination else None
        for identity, amount in [(deal.buyer_id, deal.buyer_fee), (deal.seller_id, deal.seller_fee)]:
            db.add(
                FeeInvoice(
                    deal_id=deal.id, payer_id=identity, amount=amount, status="verified" if amount == 0 else "unpaid"
                )
            )
    audit(db, user, "deal.contract_" + deal.review_status, deal.id)
    db.commit()
    return dto(db, deal, user)


@router.post("/admin/deals/{deal_id}/payment-destination")
def prepare_payment(deal_id: UUID, admin=Depends(administrator), db: Session = Depends(db_session)):
    deal = scoped(db, admin, deal_id, True)
    eligibility_required(db, deal)
    if deal.review_status != "approved" or deal.stage != "accepted":
        raise HTTPException(409, "REVIEWED_CONTRACT_REQUIRED")
    if not deal.destination_id:
        destination = db.scalar(
            select(PaymentDestination).order_by(PaymentDestination.created_at.desc(), PaymentDestination.id).limit(1)
        )
        if not destination:
            raise HTTPException(409, "PAYMENT_DESTINATION_NOT_CONFIGURED")
        deal.destination_id = destination.id
        audit(db, admin, "deal.payment_destination_set", deal.id)
        db.commit()
    return dto(db, deal, admin)


@router.get("/deals/{deal_id}/payment-qr")
def payment_qr(deal_id: UUID, context=Depends(authenticated), db: Session = Depends(db_session)):
    user = context[0]
    deal = scoped(db, user, deal_id)
    eligibility_required(db, deal)
    if user.role != "admin":
        party(deal, user)
    if deal.review_status != "approved" or not consented(db, deal) or not deal.destination_id:
        raise HTTPException(409, "PAYMENT_NOT_READY")
    destination = db.get(PaymentDestination, deal.destination_id)
    asset = db.get(Asset, destination.qr_asset_id)
    raw = Fernet(settings().document_key).decrypt((settings().storage_path / asset.storage_name).read_bytes())
    audit(db, user, "payment.qr_read", deal.id)
    db.commit()
    return Response(
        raw, media_type="image/png", headers={"Cache-Control": "no-store", "X-Content-Type-Options": "nosniff"}
    )


class ClaimInput(StrictModel):
    reference: str = Field(min_length=6, max_length=100, pattern=r"^[A-Za-z0-9_-]+$")


@router.post("/deals/{deal_id}/payment-claims", status_code=201)
def report_payment(deal_id: UUID, body: ClaimInput, context=Depends(authenticated), db: Session = Depends(db_session)):
    user = context[0]
    deal = scoped(db, user, deal_id, True)
    party(deal, user)
    eligibility_required(db, deal)
    invoice = db.scalar(
        select(FeeInvoice).where(FeeInvoice.deal_id == deal.id, FeeInvoice.payer_id == user.id).with_for_update()
    )
    if (
        deal.stage != "accepted"
        or deal.review_status != "approved"
        or not deal.destination_id
        or not invoice
        or invoice.status not in ("unpaid", "rejected")
    ):
        raise HTTPException(409, "UNPAID_READY_INVOICE_REQUIRED")
    claim = PaymentClaim(invoice_id=invoice.id, reference=body.reference.upper())
    db.add(claim)
    invoice.status = "reported"
    try:
        db.flush()
        audit(db, user, "payment.claim_reported", claim.id)
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "TRANSFER_REFERENCE_ALREADY_USED") from None
    return dto(db, deal, user)


class PaymentReview(Decision):
    note: str = Field(min_length=20, max_length=2000)


@router.put("/admin/payment-claims/{claim_id}/review")
def verify_payment(
    claim_id: UUID, body: PaymentReview, admin=Depends(administrator), db: Session = Depends(db_session)
):
    claim = db.scalar(select(PaymentClaim).where(PaymentClaim.id == claim_id).with_for_update())
    if not claim:
        raise HTTPException(404, "PAYMENT_CLAIM_NOT_FOUND")
    invoice = db.scalar(select(FeeInvoice).where(FeeInvoice.id == claim.invoice_id).with_for_update())
    if invoice.payer_id == admin.id:
        raise HTTPException(403, "SELF_PAYMENT_REVIEW_FORBIDDEN")
    if claim.status != "reported" or invoice.status != "reported":
        raise HTTPException(409, "REPORTED_CLAIM_REQUIRED")
    claim.status = "verified" if body.approved else "rejected"
    invoice.status = claim.status
    claim.verifier_id = admin.id
    claim.verification_note = body.note
    audit(db, admin, "payment.claim_" + claim.status, claim.id)
    db.commit()
    return dto(db, db.get(Deal, invoice.deal_id), admin)


@router.post("/admin/deals/{deal_id}/complete")
def complete_deal(deal_id: UUID, admin=Depends(administrator), db: Session = Depends(db_session)):
    deal = scoped(db, admin, deal_id, True)
    eligibility_required(db, deal)
    invoices = list(db.scalars(select(FeeInvoice).where(FeeInvoice.deal_id == deal.id).with_for_update()))
    if (
        deal.stage != "accepted"
        or deal.review_status != "approved"
        or not consented(db, deal)
        or len(invoices) != 2
        or any(i.status != "verified" for i in invoices)
    ):
        raise HTTPException(409, "REVIEW_AND_BOTH_VERIFIED_PAYMENTS_REQUIRED")
    prop = db.scalar(select(Property).where(Property.id == deal.property_id).with_for_update())
    if prop.closed_at or prop.status != "approved":
        raise HTTPException(409, "PROPERTY_ALREADY_CLOSED_OR_UNAPPROVED")
    deal.stage = "completed"
    if deal.category == "shared_rental":
        tenancy = db.get(Tenancy, (prop.id, deal.buyer_id))
        if tenancy:
            tenancy.active = True
        else:
            db.add(Tenancy(property_id=prop.id, user_id=deal.buyer_id))
        application = db.scalar(
            select(HousingApplication).where(
                HousingApplication.property_id == prop.id, HousingApplication.user_id == deal.buyer_id
            )
        )
        if application:
            application.status = "accepted"
        else:
            db.add(HousingApplication(property_id=prop.id, user_id=deal.buyer_id, status="accepted"))
        if prop.available_beds == 0 and not db.scalar(
            select(Deal.id).where(Deal.property_id == prop.id, Deal.stage == "accepted", Deal.id != deal.id)
        ):
            prop.availability = "rented"
            prop.closed_at = now()
    else:
        prop.availability = "sold" if deal.category.startswith("sale_") else "rented"
        prop.closed_at = now()
    audit(db, admin, "deal.completed", deal.id)
    db.commit()
    return dto(db, deal, admin)


@router.post("/deals/{deal_id}/cancel")
def cancel_deal(deal_id: UUID, body: Note, context=Depends(authenticated), db: Session = Depends(db_session)):
    user = context[0]
    deal = scoped(db, user, deal_id, True)
    if user.role != "admin":
        party(deal, user)
    if deal.stage not in ("open", "accepted") or (deal.stage == "accepted" and user.role != "admin"):
        raise HTTPException(409, "ADMIN_REQUIRED_FOR_ACCEPTED_CANCELLATION")
    if db.scalar(
        select(FeeInvoice.id).where(
            FeeInvoice.deal_id == deal.id, FeeInvoice.status.in_(["reported", "verified"]), FeeInvoice.amount > 0
        )
    ):
        raise HTTPException(409, "PAYMENT_RECONCILIATION_REQUIRED")
    prop = db.scalar(select(Property).where(Property.id == deal.property_id).with_for_update())
    if deal.bed_reserved and deal.category == "shared_rental" and not prop.closed_at:
        prop.available_beds = min(prop.total_beds, prop.available_beds + 1)
        deal.bed_reserved = False
    deal.stage = "cancelled"
    for v in db.scalars(
        select(Viewing).where(Viewing.deal_id == deal.id, Viewing.status.in_(["requested", "confirmed"]))
    ):
        v.status = "cancelled"
    audit(db, user, "deal.cancelled", deal.id)
    db.commit()
    return dto(db, deal, user)
