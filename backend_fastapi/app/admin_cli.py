"""Local operator tool. No public API can create an administrator."""

import argparse

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import engine
from app.models import AuditEvent, User


def main():
    parser = argparse.ArgumentParser(description="Grant admin to an existing local MyHome account")
    parser.add_argument("--email", required=True)
    args = parser.parse_args()
    with Session(engine()) as db:
        user = db.scalar(select(User).where(User.email == args.email.strip().lower()).with_for_update())
        if not user or not user.active:
            parser.error("Active existing account required")
        # Approval of property documents is independent of operator privileges.
        user.owner_verified = False
        user.role = "admin"
        db.add(AuditEvent(actor_id=user.id, action="operator.admin_grant", target_id=user.id))
        db.commit()
    print("Administrator granted to the selected existing account.")


if __name__ == "__main__":
    main()
