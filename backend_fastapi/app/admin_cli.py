"""Only fooda/amr may be operators. Retire old authority, preserve history."""

import argparse

import bcrypt
from sqlalchemy import func, or_, select, update
from sqlalchemy.orm import Session

from app.models import AuditEvent, AuthSession, User
from app.security import now

OPERATOR_NAMES = ("fooda", "amr")


def reconcile_operators(db: Session, passwords: dict[str, str]) -> dict:
    """Caller backs up first and saves generated passwords before this commit."""
    db.execute(select(func.pg_advisory_xact_lock(178231115)))
    affected = select(User.id).where(or_(User.role == "admin", User.username.in_(OPERATOR_NAMES)))
    # Password changes and login also take the user lock before session mutation.
    list(db.scalars(select(User).where(User.id.in_(affected)).order_by(User.id).with_for_update()))
    list(
        db.scalars(
            select(AuthSession).where(AuthSession.user_id.in_(affected)).order_by(AuthSession.id).with_for_update()
        )
    )
    previous = list(db.scalars(select(User).where(User.role == "admin").order_by(User.id).with_for_update()))
    identities, created = {}, []
    for name in OPERATOR_NAMES:
        user = db.scalar(select(User).where(User.username == name).with_for_update())
        if user is None:
            email = f"operator-{name}@myhome.example.com"
            if db.scalar(select(User.id).where(User.email == email)):
                raise RuntimeError("Reserved operator email conflict; do not promote another account")
            password = passwords[name]
            if not 12 <= len(password.encode()) <= 72:
                raise ValueError("Operator password must contain 12–72 bytes")
            user = User(
                name=name,
                username=name,
                email=email,
                role="admin",
                active=True,
                onboarding_complete=True,
                owner_verified=False,
                password_hash=bcrypt.hashpw(password.encode(), bcrypt.gensalt(12)).decode(),
            )
            db.add(user)
            db.flush()
            created.append(name)
            db.add(AuditEvent(actor_id=user.id, action="operator.named_admin_created", target_id=user.id))
        else:
            user.role, user.active, user.onboarding_complete = "admin", True, True
        identities[name] = user.id
    retired = 0
    for user in previous:
        if user.username not in OPERATOR_NAMES:
            user.active, user.role = False, "user"
            retired += 1
            db.execute(
                update(AuthSession)
                .where(AuthSession.user_id == user.id, AuthSession.revoked_at.is_(None))
                .values(revoked_at=now())
            )
            db.add(AuditEvent(actor_id=identities["fooda"], action="operator.legacy_admin_retired", target_id=user.id))
    db.commit()
    return {"created": created, "retired_admin_accounts": retired, "active_admin_usernames": list(OPERATOR_NAMES)}


def main():
    parser = argparse.ArgumentParser(description="Email-based admin grants are retired")
    parser.parse_args()
    parser.error("Run tools/prepare_admin.py; it backs up before reconciling fooda/amr")


if __name__ == "__main__":
    main()
