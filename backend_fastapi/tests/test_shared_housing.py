from concurrent.futures import ThreadPoolExecutor
from uuid import UUID

from app.models import Property, User
from tests.test_marketplace import payload


def test_last_bed_cannot_be_overbooked_and_group_requires_a_real_tenant(client, signup, db):
    owner = signup(["owner_shared_rental"])
    first = signup(["tenant_shared"])
    second = signup(["tenant_shared"])
    outsider = signup(["tenant_shared"])
    created = client.post(
        "/api/v1/properties", headers=owner["headers"], json=payload("shared_rental") | {"available_beds": 1}
    )
    assert created.status_code == 201, created.text
    pid = created.json()["id"]
    # Fixture setup simulates independently completed document review.
    db.get(Property, UUID(pid)).status = "approved"
    db.get(User, UUID(owner["user"]["id"])).owner_verified = True
    db.commit()
    ids = []
    for tenant in (first, second):
        response = client.post(f"/api/v1/properties/{pid}/applications", headers=tenant["headers"])
        assert response.status_code == 201, response.text
        ids.append(response.json()["id"])

    def accept(aid):
        return client.post(f"/api/v1/applications/{aid}/accept", headers=owner["headers"])

    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(accept, ids))
    assert sorted(result.status_code for result in results) == [200, 409]
    group = {"property_id": pid, "tenant_admin_id": outsider["user"]["id"]}
    assert client.post("/api/v1/groups", headers=owner["headers"], json=group).status_code == 400
    winner = (first, second)[next(i for i, r in enumerate(results) if r.status_code == 200)]
    group["tenant_admin_id"] = winner["user"]["id"]
    created_group = client.post("/api/v1/groups", headers=owner["headers"], json=group)
    assert created_group.status_code == 201, created_group.text
    assert created_group.json()["messagingReady"] is False
    client.put(
        "/api/v1/auth/intents",
        headers=owner["headers"],
        json={"intents": ["tenant_private"], "activeIntent": "tenant_private"},
    )
    assert client.post("/api/v1/groups", headers=owner["headers"], json=group).status_code == 403


def test_refresh_is_single_use_even_for_concurrent_requests(client, signup):
    account = signup()
    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(
            pool.map(
                lambda _: client.post("/api/v1/auth/refresh", json={"refreshToken": account["refreshToken"]}), range(2)
            )
        )
    assert sorted(result.status_code for result in results) == [200, 401]
