"""Explicit synthetic demo fixtures. Refuses the real application/test databases."""

import argparse
import json
import secrets
from pathlib import Path
from urllib.parse import urlparse
from uuid import UUID

from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.admin_cli import reconcile_operators
from app.config import settings
from app.database import engine
from app.main import create_app
from app.models import AuditEvent, Favorite, HousingApplication, HousingGroup, Message, Property, User
from app.operator_files import secure_folder, write_private


def run(credentials_path: Path, report_path: Path):
    if urlparse(settings().database_url).path != "/myhome_demo":
        raise RuntimeError("Demo seed is restricted to /myhome_demo; application data is never seeded or reset.")
    actors = {
        "owner_all": ["owner_sale_cash", "owner_sale_installments", "owner_private_rental", "owner_shared_rental"],
        "owner_other": ["owner_sale_installments", "owner_private_rental"],
        "student": ["tenant_shared"],
        "expatriate": ["tenant_shared"],
        "roommate": ["tenant_shared"],
        "viewer": ["buyer_cash", "tenant_private"],
        "outsider": ["tenant_private"],
    }
    credentials_path.parent.mkdir(parents=True, exist_ok=True)
    credentials = json.loads(credentials_path.read_text()) if credentials_path.exists() else {}
    for key in actors:
        credentials.setdefault(key, {"email": f"demo-{key}@example.com", "password": secrets.token_urlsafe(24)})
    credentials_path.write_text(json.dumps(credentials, indent=2), encoding="utf-8")
    accounts = {}
    with TestClient(create_app()) as client, Session(engine(), expire_on_commit=False) as db:
        # Fresh demo setup uses the same two reserved operators, never a third admin.
        folder = Path(__file__).resolve().parents[2] / "admin"
        secure_folder(folder)
        operator_path = folder / "operators.json"
        operator_records = json.loads(operator_path.read_text(encoding="utf-8")) if operator_path.exists() else {}
        operators = operator_records.setdefault("demo", {})
        existing_admins = list(db.scalars(select(User).where(User.role == "admin")))
        if any(user.username not in ("fooda", "amr") for user in existing_admins):
            raise RuntimeError(
                "Run tools/prepare_admin.py first; retiring legacy administrators requires its database backups."
            )
        for name in ("fooda", "amr"):
            operators.setdefault(name, {"username": name, "password": secrets.token_urlsafe(30)})
        write_private(operator_path, json.dumps(operator_records, indent=2) + "\n")
        reconcile_operators(db, {name: operators[name]["password"] for name in ("fooda", "amr")})
        data = client.post("/api/v1/auth/login", json={"email": "fooda", "password": operators["fooda"]["password"]})
        if data.status_code != 200:
            raise RuntimeError(
                "Operator password was changed; explicit reseeding needs the current operator login. Existing data is preserved."
            )
        operator_session = data.json()
        accounts["reviewer"] = {
            "id": operator_session["user"]["id"],
            "headers": {"Authorization": "Bearer " + operator_session["accessToken"]},
        }

        def request(method, path, actor=None, **kwargs):
            response = client.request(
                method, "/api/v1" + path, headers=accounts[actor]["headers"] if actor else None, **kwargs
            )
            if response.status_code not in (200, 201, 204):
                raise RuntimeError(f"Demo check failed: {method} {path}: {response.status_code}")
            return response.json() if response.content else None

        for key, intents in actors.items():
            login = credentials[key]
            existing = db.scalar(select(User).where(User.email == login["email"]))
            data = (
                request("POST", "/auth/login", json=login)
                if existing
                else request("POST", "/auth/register", json={"name": "DEMO | " + key, **login})
            )
            accounts[key] = {"id": data["user"]["id"], "headers": {"Authorization": "Bearer " + data["accessToken"]}}
            request(
                "PUT",
                "/auth/intents",
                key,
                json={
                    "intents": intents,
                    "activeIntent": "owner_shared_rental" if key == "owner_all" else intents[0],
                    "housingPersona": "student"
                    if key == "student"
                    else "expatriate"
                    if key == "expatriate"
                    else "regular",
                },
            )
            user = db.get(User, UUID(data["user"]["id"]))
            user.owner_verified = key.startswith("owner_")
            db.commit()

        for key in ("field_agent", "document_reviewer"):
            credentials.setdefault(key, {"email": f"demo-{key}@example.com", "password": secrets.token_urlsafe(24)})
            login = credentials[key]
            if not db.scalar(select(User).where(User.email == login["email"])):
                request(
                    "POST",
                    "/admin/staff",
                    "reviewer",
                    json={
                        "name": "DEMO | " + key,
                        **login,
                        "specialty": key,
                        "professional_reference": "SYNTHETIC DEMO PROFILE - NOT A REAL LICENSE"
                        if key == "document_reviewer"
                        else None,
                    },
                )
            data = request("POST", "/auth/login", json=login)
            accounts[key] = {"id": data["user"]["id"], "headers": {"Authorization": "Bearer " + data["accessToken"]}}
        credentials_path.write_text(json.dumps(credentials, indent=2), encoding="utf-8")

        def make_listing(actor, category, title):
            owner_id = UUID(accounts[actor]["id"])
            existing = db.scalar(select(Property).where(Property.owner_id == owner_id, Property.title == title))
            if existing:
                return str(existing.id)
            rental = category in ("private_rental", "shared_rental")
            body = dict(
                title=title,
                description="Synthetic demo fixture only. Not an actual property or identity verification.",
                category=category,
                area_id="maadi",
                approximate_location="DEMO area only - no real address",
                area_m2="100",
                bedrooms=2,
                bathrooms=1,
                capacity=4,
                water=True,
                electricity=True,
                gas=False,
                elevator=True,
                finishing="lux",
                price="3000" if category == "shared_rental" else "6000" if rental else "1000000",
                negotiable=False,
            )
            if rental:
                body.update(rental_period="one_year", deposit="3000")
            if category == "shared_rental":
                body.update(total_beds=4, available_beds=4)
            if category == "sale_installments":
                body.update(down_payment="200000", installment_count=80, installment_amount="10000")
            result = request("POST", "/properties", actor, json=body)
            prop = db.get(Property, UUID(result["id"]))
            prop.status = "approved"
            db.add(AuditEvent(actor_id=owner_id, action="demo.synthetic_listing", target_id=prop.id))
            db.commit()
            return result["id"]

        sales = [make_listing("owner_all", "sale_cash", f"DEMO | Sale apartment {n}") for n in range(1, 7)]
        rentals = [make_listing("owner_all", "private_rental", f"DEMO | Rental apartment {n}") for n in range(1, 5)]
        shared = make_listing("owner_all", "shared_rental", "DEMO | Shared student residence")
        make_listing("owner_other", "sale_installments", "DEMO | Other owner installments")
        make_listing("owner_other", "private_rental", "DEMO | Other owner private rental")
        for pid in [sales[0], sales[-1], rentals[0], rentals[-1]]:
            if not db.get(Favorite, (UUID(accounts["viewer"]["id"]), UUID(pid))):
                request("PUT", f"/favorites/{pid}", "viewer")
        for pid, target in [(sales[-1], "sold"), (rentals[-1], "rented"), (rentals[0], "paused")]:
            request("PUT", f"/properties/{pid}/availability", "owner_all", json={"availability": target})
        for key in ["student", "expatriate"]:
            application = db.scalar(
                select(HousingApplication).where(
                    HousingApplication.property_id == UUID(shared),
                    HousingApplication.user_id == UUID(accounts[key]["id"]),
                )
            )
            aid = (
                str(application.id) if application else request("POST", f"/properties/{shared}/applications", key)["id"]
            )
            db.expire_all()
            application = db.get(HousingApplication, UUID(aid))
            if application.status == "pending":
                request("POST", f"/applications/{aid}/accept", "owner_all")
        group = db.scalar(select(HousingGroup).where(HousingGroup.property_id == UUID(shared)))
        gid = (
            str(group.id)
            if group
            else request(
                "POST",
                "/groups",
                "owner_all",
                json={"property_id": shared, "tenant_admin_id": accounts["student"]["id"]},
            )["id"]
        )
        overview = request("GET", "/properties/mine/overview", "owner_all")["items"]
        assert {v["group"]: v["current"] for v in overview} == {"sale": 5, "private_rental": 3, "shared_rental": 1}
        first = request("GET", "/properties/mine/page", "owner_all", params={"group": "sale"})
        second = request(
            "GET", "/properties/mine/page", "owner_all", params={"group": "sale", "cursor": first["next_cursor"]}
        )
        assert len(first["items"]) == 3 and len(second["items"]) == 2
        favorites = request("GET", "/favorites", "viewer")["items"]
        assert {v["availability"] for v in favorites} == {"active", "paused", "sold", "rented"}
        assert gid in [g["id"] for g in request("GET", "/groups", "student")["items"]]
        assert request("GET", "/groups", "outsider")["items"] == []
        deal = request("POST", "/deals", "viewer", json={"property_id": sales[1]})
        trade_chat = request("POST", f"/deals/{deal['id']}/conversation", "viewer")["id"]
        group_chat = request("POST", f"/groups/{gid}/conversation", "student")["id"]
        for cid, messages in (
            (
                trade_chat,
                [
                    ("viewer", "DEMO: Can we arrange an accompanied viewing next week?"),
                    ("owner_all", "DEMO: Yes, please request a viewing inside the app."),
                ],
            ),
            (
                group_chat,
                [
                    ("student", "DEMO: Welcome to our shared residence group."),
                    ("owner_all", "DEMO: Use this group to coordinate residence matters."),
                    ("expatriate", "DEMO: Thank you, the shared kitchen schedule works for me."),
                ],
            ),
        ):
            if not db.scalar(select(Message.id).where(Message.conversation_id == UUID(cid)).limit(1)):
                for actor, text in messages:
                    request("POST", f"/conversations/{cid}/messages", actor, json={"text": text})
        blocked = client.post(
            f"/api/v1/conversations/{trade_chat}/messages",
            headers=accounts["viewer"]["headers"],
            json={"text": "DEMO rejected contact 01012345678"},
        )
        assert blocked.status_code == 422
        assert (
            client.get(
                f"/api/v1/conversations/{group_chat}/messages", headers=accounts["outsider"]["headers"]
            ).status_code
            == 404
        )
        trade_messages = request("GET", f"/conversations/{trade_chat}/messages", "viewer")["items"]
        group_messages = request("GET", f"/conversations/{group_chat}/messages", "student")["items"]
        for message in trade_messages + group_messages:
            assert message["text"].encode() not in db.get(Message, message["id"]).body_cipher
        report = {
            "database": "myhome_demo",
            "users": len(accounts),
            "properties": 13,
            "overview": overview,
            "sale_page_sizes": [3, 2],
            "favorite_states": [v["availability"] for v in favorites],
            "group_id": gid,
            "group_members": 3,
            "tenant_admin": "student",
            "messaging": {
                "status": "server_moderated_encrypted_at_rest",
                "trade_conversation": trade_chat,
                "group_conversation": group_chat,
                "messages": len(trade_messages) + len(group_messages),
                "contact_rejection": blocked.status_code,
                "end_to_end_encrypted": False,
            },
            "credentials_file": str(credentials_path),
        }
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
        for key in accounts:
            request("POST", "/auth/logout", key)
    print(
        f"Demo verified: {len(accounts)} accounts, 13 properties, 1 group, 2 conversations. Private credentials: {credentials_path}. Report: {report_path}"
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--credentials-path", type=Path, default=Path("../artifacts/demo-accounts.json"))
    parser.add_argument("--report-path", type=Path, default=Path("../artifacts/demo-scenario-results.json"))
    args = parser.parse_args()
    run(args.credentials_path, args.report_path)
