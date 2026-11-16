"""Operational aggregates with no personal details in dashboard responses."""

from fastapi import APIRouter, Depends
from sqlalchemy import exists, func, select
from sqlalchemy.orm import Session

from app.database import db_session
from app.models import Deal, PaymentClaim, Property, StaffMember, User, UserIntent, Verification, Viewing
from app.security import administrator

router = APIRouter(tags=["administration"])


@router.get("/admin/dashboard")
def dashboard(admin=Depends(administrator), db: Session = Depends(db_session)):
    def count(model, *conditions):
        return db.scalar(select(func.count()).select_from(model).where(*conditions)) or 0

    def people(*intents):
        return count(
            User,
            User.active.is_(True),
            User.role != "admin",
            ~exists().where(StaffMember.user_id == User.id),
            exists().where(UserIntent.user_id == User.id, UserIntent.intent.in_(intents)),
        )

    property_reviews = count(
        Verification,
        Verification.status == "pending",
        exists().where(Property.id == Verification.property_id, Property.status == "pending"),
    )
    eligibility_reviews = count(
        Property,
        Property.rental_period == "old_rent",
        Property.status == "approved",
        Property.legal_eligibility == "pending",
    )
    payment_reviews = count(PaymentClaim, PaymentClaim.status == "reported")
    contract_reviews = count(Deal, Deal.stage == "accepted", Deal.review_status == "pending")
    viewing_assignments = count(Viewing, Viewing.status == "confirmed", Viewing.staff_id.is_(None))
    return {
        "properties": count(Property),
        "published_properties": count(Property, Property.status == "approved", Property.availability == "active"),
        "owners": people("owner_sale_cash", "owner_sale_installments", "owner_private_rental", "owner_shared_rental"),
        "buyers": people("buyer_cash", "buyer_installments"),
        "renters": people("tenant_private", "tenant_shared"),
        "property_reviews": property_reviews,
        "eligibility_reviews": eligibility_reviews,
        "payment_reviews": payment_reviews,
        "contract_reviews": contract_reviews,
        "viewing_assignments": viewing_assignments,
        "deal_actions": payment_reviews + contract_reviews + viewing_assignments,
        "pending_total": property_reviews
        + eligibility_reviews
        + payment_reviews
        + contract_reviews
        + viewing_assignments,
    }
