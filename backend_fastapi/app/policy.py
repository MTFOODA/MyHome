from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import User, UserIntent

OWNER_INTENTS = {"owner_sale_cash", "owner_sale_installments", "owner_private_rental", "owner_shared_rental"}


def intents_for(db: Session, user: User) -> list[str]:
    return list(db.scalars(select(UserIntent.intent).where(UserIntent.user_id == user.id).order_by(UserIntent.intent)))


def require_owner(db: Session, user: User, category: str | None = None):
    intents = set(intents_for(db, user))
    expected = "owner_" + category if category else None
    if not user.active or not (intents & OWNER_INTENTS) or (expected and expected not in intents):
        raise HTTPException(403, "OWNER_ROLE_REQUIRED")


def require_shared_seeker(db: Session, user: User):
    if user.active_intent != "tenant_shared" or "tenant_shared" not in intents_for(db, user):
        raise HTTPException(403, "SHARED_RENTAL_ROLE_REQUIRED")
