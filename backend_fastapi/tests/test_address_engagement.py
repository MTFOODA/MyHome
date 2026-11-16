from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

import pytest
from sqlalchemy import func, select

from app.models import Conversation, Deal, Favorite, Message, Property, User
from tests.test_marketplace import payload
from tests.test_portfolio import listing


@pytest.mark.parametrize("field", ["street_address", "building_number", "floor_number", "unit_number", "property_kind"])
def test_new_listing_requires_complete_address(client, signup, field):
    owner = signup(["owner_sale_cash"])
    body = payload("sale_cash")
    body.pop(field)
    assert client.post("/api/v1/properties", headers=owner["headers"], json=body).status_code == 422


@pytest.mark.parametrize(
    "changes",
    [
        {"street_address": "  "},
        {"building_number": " "},
        {"floor_number": 101},
        {"unit_number": ""},
        {"property_kind": "castle"},
    ],
)
def test_invalid_address_rejected(client, signup, changes):
    owner = signup(["owner_sale_cash"])
    assert (
        client.post("/api/v1/properties", headers=owner["headers"], json=payload("sale_cash") | changes).status_code
        == 422
    )


def test_address_roundtrip_and_legacy_read_without_fabrication(client, db, signup):
    owner = signup(["owner_sale_cash"])
    identity = listing(client, db, owner, "sale_cash")
    data = client.get(f"/api/v1/properties/{identity}", headers=owner["headers"]).json()
    assert data["street_address"] == "Test street" and data["building_number"] == "7"
    assert data["floor_number"] == 4 and data["unit_number"] == "12"
    assert data["full_address_en"].startswith("7 Test street") and "Apartment 12" in data["full_address_en"]
    assert "street_address" not in client.get("/api/v1/properties").json()["items"][0]
    prop = db.get(Property, UUID(identity))
    for field in ["street_address", "building_number", "floor_number", "unit_number", "property_kind"]:
        setattr(prop, field, None)
    prop.approximate_location = "Legacy known location"
    prop.capacity = 4  # Older non-shared rows can retain their historical column value.
    db.commit()
    old = client.get(f"/api/v1/properties/{identity}", headers=owner["headers"])
    assert old.status_code == 200 and old.json()["full_address_en"] == "Legacy known location"
    assert old.json()["capacity"] is None


def test_visitors_are_unique_and_savers_are_owner_only(client, db, signup):
    owner = signup(["owner_sale_cash"])
    visitors = [signup(), signup()]
    outsider = signup(["owner_sale_cash"])
    identity = listing(client, db, owner, "sale_cash")
    path = f"/api/v1/properties/{identity}"
    assert client.get(path).status_code == 401
    for account in [owner, owner, visitors[0], visitors[0], visitors[1]]:
        assert client.get(path, headers=account["headers"]).status_code == 200
    for account in [visitors[0], visitors[0], visitors[1], owner]:
        assert client.put(f"/api/v1/favorites/{identity}", headers=account["headers"]).status_code == 204
    item = client.get("/api/v1/properties/mine/page?group=all&scope=all", headers=owner["headers"]).json()["items"][0]
    assert item["visitor_count"] == 2 and item["saved_count"] == 2
    public = client.get("/api/v1/properties").json()["items"]
    assert all("visitor_count" not in p and "saved_count" not in p for p in public)
    people = client.get(path + "/interested", headers=owner["headers"]).json()["items"]
    assert {p["id"] for p in people} == {v["user"]["id"] for v in visitors}
    assert all(set(p) == {"id", "name"} for p in people)
    assert client.get(path + "/interested", headers=outsider["headers"]).status_code == 404
    assert client.get(path + "/interested", headers=visitors[0]["headers"]).status_code == 404
    client.delete(f"/api/v1/favorites/{identity}", headers=visitors[1]["headers"])
    assert len(client.get(path + "/interested", headers=owner["headers"]).json()["items"]) == 1


def test_all_owner_properties_page_newest_three_including_pending_and_closed(client, db, signup):
    owner = signup(["owner_sale_cash", "owner_sale_installments", "owner_private_rental", "owner_shared_rental"])
    identities = []
    for n, category in enumerate(["sale_cash", "private_rental", "shared_rental", "sale_installments", "sale_cash"]):
        identity = listing(client, db, owner, category)
        prop = db.get(Property, UUID(identity))
        prop.created_at = datetime.now(UTC) + timedelta(seconds=n)
        if n < 2:
            prop.status = "draft" if n == 0 else "pending"
        if n == 3:
            prop.availability, prop.closed_at = "sold", datetime.now(UTC)
        identities.append(identity)
    db.commit()
    first = client.get("/api/v1/properties/mine/page?group=all&scope=all", headers=owner["headers"]).json()
    assert first["total"] == 5 and first["page_size"] == 3
    assert [p["id"] for p in first["items"]] == identities[::-1][:3]
    last = client.get(
        "/api/v1/properties/mine/page",
        headers=owner["headers"],
        params={"group": "all", "scope": "all", "cursor": first["next_cursor"]},
    ).json()
    assert [p["id"] for p in last["items"]] == identities[::-1][3:] and last["next_cursor"] is None
    other = signup()
    assert (
        client.get(
            "/api/v1/properties/mine/page",
            headers=other["headers"],
            params={"group": "all", "scope": "all", "cursor": first["next_cursor"]},
        ).status_code
        == 400
    )


def test_property_chat_is_independent_private_moderated_and_reusable(client, db, signup):
    owner = signup(["owner_sale_cash"])
    buyer, stranger = signup(), signup()
    identity = listing(client, db, owner, "sale_cash")
    path = f"/api/v1/properties/{identity}/conversation"
    assert client.post(path, headers=owner["headers"], params={"seeker_id": buyer["user"]["id"]}).status_code == 404
    opened = client.post(path, headers=buyer["headers"])
    assert opened.status_code == 200, opened.text
    conversation = opened.json()["id"]
    client.put(f"/api/v1/favorites/{identity}", headers=buyer["headers"])
    assert (
        client.post(path, headers=owner["headers"], params={"seeker_id": buyer["user"]["id"]}).json()["id"]
        == conversation
    )
    assert db.scalar(select(func.count()).select_from(Deal).where(Deal.property_id == UUID(identity))) == 0
    assert client.post(path, headers=stranger["headers"], params={"seeker_id": buyer["user"]["id"]}).status_code == 404
    messages = f"/api/v1/conversations/{conversation}/messages"
    assert client.post(messages, headers=buyer["headers"], json={"text": "01012345678"}).status_code == 422
    sent = client.post(messages, headers=buyer["headers"], json={"text": "Can I arrange a viewing?"})
    assert sent.status_code == 201
    row = db.get(Message, sent.json()["id"])
    assert b"viewing" not in row.body_cipher
    assert client.get(messages, headers=owner["headers"]).json()["items"][0]["text"] == "Can I arrange a viewing?"
    assert client.get(messages, headers=stranger["headers"]).status_code == 404
    assert client.get("/api/v1/conversations/inbox", headers=owner["headers"]).json()["items"][0]["id"] == conversation
    assert client.get("/api/v1/conversations/inbox", headers=buyer["headers"]).json()["items"][0]["id"] == conversation
    assert client.get("/api/v1/conversations/inbox", headers=stranger["headers"]).json()["items"] == []
    other = client.post(path, headers=stranger["headers"]).json()["id"]
    assert other != conversation and db.get(Conversation, UUID(other)).seeker_id == UUID(stranger["user"]["id"])


def test_saver_pagination_is_bound_to_property_and_owner(client, db, signup):
    owner = signup(["owner_sale_cash"])
    identity = listing(client, db, owner, "sale_cash")
    base = db.get(User, UUID(owner["user"]["id"]))
    for n in range(22):
        user = User(
            id=uuid4(), name=f"Interested {n}", email=f"{uuid4()}@example.com", password_hash=base.password_hash
        )
        db.add(user)
        db.flush()
        db.add(Favorite(user_id=user.id, property_id=UUID(identity)))
    db.commit()
    path = f"/api/v1/properties/{identity}/interested"
    first = client.get(path, headers=owner["headers"]).json()
    last = client.get(path, headers=owner["headers"], params={"before": first["next_cursor"]}).json()
    assert len(first["items"]) == 20 and len(last["items"]) == 2
    assert len({p["id"] for p in first["items"] + last["items"]}) == 22
    other_property = listing(client, db, owner, "sale_cash")
    assert (
        client.get(
            f"/api/v1/properties/{other_property}/interested",
            headers=owner["headers"],
            params={"before": first["next_cursor"]},
        ).status_code
        == 400
    )
