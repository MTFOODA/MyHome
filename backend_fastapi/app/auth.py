import bcrypt
from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy import delete, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database import db_session
from app.models import User, UserIntent
from app.policy import OWNER_INTENTS
from app.schemas import Intents, Login, Refresh, Register
from app.security import authenticated, dummy_hash, login_session, now, public_user, refresh_session

router = APIRouter(prefix="/auth", tags=["authentication"])


@router.post("/register", status_code=201)
def register(body: Register, db: Session = Depends(db_session)):
    user = User(
        name=body.name,
        email=str(body.email),
        role=body.role,
        password_hash=bcrypt.hashpw(body.password.encode(), bcrypt.gensalt(12)).decode(),
    )
    db.add(user)
    try:
        db.flush()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "EMAIL_IN_USE") from None
    return login_session(db, user)


@router.post("/login")
def login(body: Login, db: Session = Depends(db_session)):
    user = db.scalar(select(User).where(User.email == str(body.email)))
    valid = bcrypt.checkpw(body.password.encode(), user.password_hash.encode() if user else dummy_hash)
    if not user or not user.active or not valid:
        raise HTTPException(401, "INVALID_CREDENTIALS")
    return login_session(db, user)


@router.post("/refresh")
def refresh(body: Refresh, db: Session = Depends(db_session)):
    return refresh_session(db, body.refreshToken)


@router.get("/profile")
def profile(context=Depends(authenticated), db: Session = Depends(db_session)):
    return public_user(db, context[0])


@router.post("/logout", status_code=204)
def logout(context=Depends(authenticated), db: Session = Depends(db_session)):
    context[1].revoked_at = now()
    db.commit()
    return Response(status_code=204)


@router.put("/intents")
def update_intents(body: Intents, context=Depends(authenticated), db: Session = Depends(db_session)):
    user = db.scalar(
        select(User).where(User.id == context[0].id).with_for_update().execution_options(populate_existing=True)
    )
    db.execute(delete(UserIntent).where(UserIntent.user_id == user.id))
    db.add_all(UserIntent(user_id=user.id, intent=intent) for intent in body.intents)
    # Public onboarding must never create an administrator role.
    if user.role != "admin":
        user.role = (
            "owner"
            if set(body.intents) & OWNER_INTENTS
            else {"regular": "user", "student": "student", "expatriate": "expatriate"}[body.housingPersona]
        )
    if not set(body.intents) & OWNER_INTENTS:
        user.owner_verified = False
    user.active_intent = body.activeIntent
    user.housing_persona = body.housingPersona
    user.onboarding_complete = True
    db.flush()
    result = public_user(db, user)
    db.commit()
    return result
