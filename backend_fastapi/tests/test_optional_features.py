from uuid import UUID

import pytest
from sqlalchemy import select

from app.models import Property, User
from tests.test_marketplace import payload
from tests.test_portfolio import listing


@pytest.mark.parametrize("finishing", ["lux", "super_lux", "ultra_super_lux"])
def test_optional_features_roundtrip_and_furnishing_discovery(client, db, signup, finishing):
    owner = signup(["owner_sale_cash"])
    body = payload("sale_cash") | {
        "finishing": finishing,
        "furnished": True,
        "compound": True,
        "security": False,
        "internet": True,
        "garage": False,
        "orientation": "north_south",
        "kitchen_type": "american_kitchen",
    }
    response = client.post("/api/v1/properties", headers=owner["headers"], json=body)
    assert response.status_code == 201, response.text
    identity = response.json()["id"]
    prop = db.get(Property, UUID(identity))
    assert prop.compound is True and prop.security is False and prop.garage is False
    assert prop.orientation == "north_south" and prop.kitchen_type == "american_kitchen"
    detail = client.get(f"/api/v1/properties/{identity}", headers=owner["headers"]).json()
    for name in ("finishing", "furnished", "compound", "security", "internet", "garage", "orientation", "kitchen_type"):
        assert detail[name] == body[name]
    prop.status = "approved"
    db.get(User, UUID(owner["user"]["id"])).owner_verified = True
    db.commit()
    matches = client.get(
        "/api/v1/properties", params={"finishing": finishing, "furnished": True, "sort": "newest"}
    ).json()["items"]
    assert identity in {item["id"] for item in matches}
    # Existing listings that omit the new answers remain unknown.
    other = client.post("/api/v1/properties", headers=owner["headers"], json=payload("sale_cash")).json()["id"]
    legacy = db.get(Property, UUID(other))
    assert all(
        getattr(legacy, key) is None
        for key in ("compound", "security", "internet", "garage", "orientation", "kitchen_type")
    )


@pytest.mark.parametrize(
    "changes",
    [
        {"compound": "yes"},
        {"security": 1},
        {"internet": "true"},
        {"garage": 0},
        {"orientation": "random"},
        {"kitchen_type": "random"},
        {"finishing": "red_brick", "furnished": True},
    ],
)
def test_optional_features_validate_types(client, signup, changes):
    owner = signup(["owner_sale_cash"])
    assert (
        client.post("/api/v1/properties", headers=owner["headers"], json=payload("sale_cash") | changes).status_code
        == 422
    )


def test_similar_properties_follow_public_visibility_and_region_price_order(client, db, signup):
    owner = signup(["owner_sale_cash", "owner_private_rental"])
    viewer = signup()
    source = listing(client, db, owner, "sale_cash")
    preferred = listing(client, db, owner, "sale_cash", "Similar preferred home")
    hidden = listing(client, db, owner, "sale_cash", "Hidden recommendation")
    wrong_type = listing(client, db, owner, "private_rental")
    prop = db.get(Property, UUID(hidden))
    prop.availability = "paused"
    db.commit()
    path = f"/api/v1/properties/{source}/similar"
    assert client.get(path).status_code == 401
    response = client.get(path, headers=viewer["headers"])
    assert response.status_code == 200
    items = response.json()["items"]
    ids = [p["id"] for p in items]
    assert preferred in ids and len(ids) <= 6 and source not in ids and hidden not in ids and wrong_type not in ids
    assert all(
        p["category"] == "sale_cash" and p["status"] == "approved" and p["availability"] == "active" for p in items
    )
    assert all("owner_name" not in p and "street_address" not in p for p in items)
    # A saved/previously-known hidden listing cannot be used as a public recommendation source.
    assert client.get(f"/api/v1/properties/{hidden}/similar", headers=viewer["headers"]).status_code == 404
    assert db.scalar(select(Property.id).where(Property.id == UUID(source)))


def test_chat_context_and_preview_are_participant_only(client, db, signup):
    owner = signup(["owner_sale_cash"])
    buyer, outsider = signup(), signup()
    identity = listing(client, db, owner, "sale_cash")
    conversation = client.post(f"/api/v1/properties/{identity}/conversation", headers=buyer["headers"]).json()["id"]
    url = f"/api/v1/conversations/{conversation}"
    assert client.get(url, headers=outsider["headers"]).status_code == 404
    assert client.get(url).status_code == 401
    data = client.get(url, headers=buyer["headers"]).json()
    assert data["property"]["id"] == identity and data["owner_verified"] is True
    assert data["name"] == owner["user"]["name"]
    assert not ({"email", "phone", "street_address", "national_id"} & set(data))
    sent = client.post(url + "/messages", headers=buyer["headers"], json={"text": "May we schedule a viewing?"})
    assert sent.status_code == 201 and sent.json()["created_at"]
    inbox = client.get("/api/v1/conversations/inbox", headers=owner["headers"]).json()["items"]
    row = next(item for item in inbox if item["id"] == conversation)
    assert row["last_message"] == "May we schedule a viewing?" and row["property"]["id"] == identity
    prop = db.get(Property, UUID(identity))
    prop.availability = "paused"
    db.commit()
    assert client.get(url, headers=buyer["headers"]).json()["property"]["cover_id"] is None
    assert client.get(url, headers=outsider["headers"]).status_code == 404
