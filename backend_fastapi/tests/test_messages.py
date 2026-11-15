from uuid import UUID

import pytest
from sqlalchemy import func, select

from app.messages import decode
from app.models import Message, Tenancy
from tests.test_portfolio import listing


def trade_chat(client, db, signup):
    owner, buyer, outsider = signup(["owner_sale_cash"]), signup(["buyer_cash"]), signup()
    prop = listing(client, db, owner, "sale_cash")
    deal = client.post("/api/v1/deals", headers=buyer["headers"], json={"property_id": prop}).json()["id"]
    conversation = client.post(f"/api/v1/deals/{deal}/conversation", headers=buyer["headers"]).json()
    assert conversation["encrypted_at_rest"] is True and conversation["end_to_end_encrypted"] is False
    return owner, buyer, outsider, conversation["id"]


@pytest.mark.parametrize(
    "text",
    [
        "Call 01012345678 please",
        "٠١٠ ١٢٣٤ ٥٦٧٨",
        "۰۱۰-۱۲۳۴-۵۶۷۸",
        "０１０１２３４５６７８",
        "0\u200b1\u200b0\u200b1\u200b2\u200b3\u200b4\u200b5\u200b6\u200b7\u200b8",
        "zero one zero one two three four five six seven eight",
        "صفر واحد صفر واحد اتنين تلاتة اربعة خمسة ستة سبعة تمانية",
        "https://wa.me/201012345678",
        "Reach me at contact@example.com",
    ],
)
def test_contacts_rejected_on_server_before_storage(client, db, signup, text):
    _, buyer, _, identity = trade_chat(client, db, signup)
    response = client.post(f"/api/v1/conversations/{identity}/messages", headers=buyer["headers"], json={"text": text})
    assert response.status_code == 422 and response.json()["detail"] == "CONTACT_DETAILS_BLOCKED"
    assert db.scalar(select(func.count()).select_from(Message).where(Message.conversation_id == UUID(identity))) == 0


def test_member_only_encrypted_storage_paging_and_split_number_block(client, db, signup):
    owner, buyer, outsider, identity = trade_chat(client, db, signup)
    endpoint = f"/api/v1/conversations/{identity}/messages"
    plain = "Can we arrange an accompanied viewing next week?"
    created = client.post(endpoint, headers=buyer["headers"], json={"text": plain})
    assert created.status_code == 201, created.text
    row = db.get(Message, created.json()["id"])
    assert plain.encode() not in row.body_cipher and decode(row) == plain
    assert client.get(endpoint, headers=outsider["headers"]).status_code == 404
    assert client.post(endpoint, headers=outsider["headers"], json={"text": "unauthorized"}).status_code == 404
    assert client.get(endpoint, headers=owner["headers"]).json()["items"][0]["mine"] is False
    assert (
        client.get(endpoint, headers=buyer["headers"], params={"after_id": created.json()["id"]}).json()["items"] == []
    )
    assert client.post(endpoint, headers=buyer["headers"], json={"text": "010123"}).status_code == 201
    assert client.post(endpoint, headers=buyer["headers"], json={"text": "45678"}).status_code == 422
    assert len(client.get(endpoint, headers=owner["headers"]).json()["items"]) == 2


def test_ciphertext_binds_sender_and_conversation_metadata(client, db, signup):
    owner, buyer, _, identity = trade_chat(client, db, signup)
    endpoint = f"/api/v1/conversations/{identity}/messages"
    created = client.post(endpoint, headers=buyer["headers"], json={"text": "A legitimate synthetic message."}).json()
    row = db.get(Message, created["id"])
    original = row.sender_id
    row.sender_id = UUID(owner["user"]["id"])
    db.commit()
    assert client.get(endpoint, headers=owner["headers"]).status_code == 503
    row.sender_id = original
    db.commit()


def test_shared_group_chat_membership_revocation_and_bounded_history(client, db, signup):
    owner, tenant, outsider = signup(["owner_shared_rental"]), signup(["tenant_shared"]), signup()
    pid = listing(client, db, owner, "shared_rental")
    applied = client.post(f"/api/v1/properties/{pid}/applications", headers=tenant["headers"]).json()
    assert client.post(f"/api/v1/applications/{applied['id']}/accept", headers=owner["headers"]).status_code == 200
    group = client.post(
        "/api/v1/groups", headers=owner["headers"], json={"property_id": pid, "tenant_admin_id": tenant["user"]["id"]}
    )
    assert group.status_code == 201, group.text
    cid = client.post(f"/api/v1/groups/{group.json()['id']}/conversation", headers=tenant["headers"]).json()["id"]
    endpoint = f"/api/v1/conversations/{cid}/messages"
    for _ in range(32):
        assert (
            client.post(endpoint, headers=owner["headers"], json={"text": "Synthetic group message"}).status_code == 201
        )
    first = client.get(endpoint, headers=tenant["headers"]).json()
    assert len(first["items"]) == 30 and first["next_before"] is not None
    older = client.get(endpoint, headers=tenant["headers"], params={"before_id": first["next_before"]}).json()
    assert len(older["items"]) == 2 and older["next_before"] is None
    assert not {m["id"] for m in first["items"]} & {m["id"] for m in older["items"]}
    assert client.get(endpoint, headers=outsider["headers"]).status_code == 404
    tenancy = db.get(Tenancy, (UUID(pid), UUID(tenant["user"]["id"])))
    tenancy.active = False
    db.commit()
    assert client.get(endpoint, headers=tenant["headers"]).status_code == 404
    assert client.post(endpoint, headers=tenant["headers"], json={"text": "Removed tenant"}).status_code == 404
