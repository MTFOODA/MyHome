import hashlib
import secrets
from datetime import UTC, datetime, timedelta
from uuid import UUID

import bcrypt
import jwt
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.config import settings
from app.database import db_session
from app.models import AuthSession, User
from app.policy import intents_for

bearer = HTTPBearer(auto_error=False)
dummy_hash = bcrypt.hashpw(b"myhome-dummy-password", bcrypt.gensalt(12))


def now():
    return datetime.now(UTC)


def digest(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


def public_user(db: Session, user: User):
    return dict(
        id=str(user.id),
        name=user.name,
        email=user.email,
        role=user.role,
        ownerVerified=user.owner_verified,
        intents=intents_for(db, user),
        activeIntent=user.active_intent,
        housingPersona=user.housing_persona,
        onboardingComplete=user.onboarding_complete,
    )


def tokens(db: Session, user: User, session: AuthSession, secret: str):
    timestamp = now()
    access = jwt.encode(
        {
            "sub": str(user.id),
            "sid": str(session.id),
            "iat": timestamp,
            "exp": timestamp + timedelta(minutes=15),
            "iss": "myhome-api",
            "aud": "myhome-app",
        },
        settings().jwt_secret,
        algorithm="HS256",
    )
    return dict(accessToken=access, refreshToken=f"{session.id}.{secret}", expiresIn=900, user=public_user(db, user))


def login_session(db: Session, user: User):
    secret = secrets.token_hex(48)
    session = AuthSession(user_id=user.id, refresh_hash=digest(secret), expires_at=now() + timedelta(days=7))
    db.add(session)
    db.flush()
    result = tokens(db, user, session, secret)
    db.commit()
    return result


def refresh_session(db: Session, token: str):
    try:
        sid, secret = token.split(".")
        session_id = UUID(sid)
        if len(secret) != 96 or any(ch not in "0123456789abcdef" for ch in secret):
            raise ValueError()
    except ValueError:
        raise HTTPException(401, "INVALID_SESSION") from None
    # Lock order is session then user in all session mutations. CAS prevents replay.
    row = db.scalar(select(AuthSession).where(AuthSession.id == session_id).with_for_update())
    if (
        not row
        or row.revoked_at
        or row.expires_at <= now()
        or not secrets.compare_digest(row.refresh_hash, digest(secret))
    ):
        raise HTTPException(401, "INVALID_SESSION")
    user = db.get(User, row.user_id)
    if not user or not user.active:
        raise HTTPException(401, "INVALID_SESSION")
    next_secret = secrets.token_hex(48)
    changed = db.execute(
        update(AuthSession)
        .where(AuthSession.id == row.id, AuthSession.refresh_hash == digest(secret), AuthSession.revoked_at.is_(None))
        .values(refresh_hash=digest(next_secret))
    )
    if changed.rowcount != 1:
        raise HTTPException(401, "INVALID_SESSION")
    result = tokens(db, user, row, next_secret)
    db.commit()
    return result


def authenticated(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer), db: Session = Depends(db_session)
):
    if not credentials:
        raise HTTPException(401, "AUTHENTICATION_REQUIRED", headers={"WWW-Authenticate": "Bearer"})
    try:
        payload = jwt.decode(
            credentials.credentials,
            settings().jwt_secret,
            algorithms=["HS256"],
            issuer="myhome-api",
            audience="myhome-app",
            options={"require": ["exp", "sub", "sid"]},
        )
        user_id, session_id = UUID(payload["sub"]), UUID(payload["sid"])
    except (jwt.PyJWTError, ValueError, KeyError, TypeError):
        raise HTTPException(401, "INVALID_SESSION") from None
    session = db.scalar(
        select(AuthSession).where(
            AuthSession.id == session_id,
            AuthSession.user_id == user_id,
            AuthSession.revoked_at.is_(None),
            AuthSession.expires_at > now(),
        )
    )
    user = db.get(User, user_id) if session else None
    if not user or not user.active:
        raise HTTPException(401, "INVALID_SESSION")
    return user, session


def administrator(context=Depends(authenticated)):
    user, _ = context
    if user.role != "admin":
        raise HTTPException(403, "ADMIN_REQUIRED")
    return user
