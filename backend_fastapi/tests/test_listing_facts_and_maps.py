from uuid import UUID

import pytest

from app.models import Property
from tests.test_marketplace import payload, upload


def test_full_catalog_preserves_old_ids_and_covers_all_governorates(client):
    data = client.get("/api/v1/locations").json()
    assert len(data["governorates"]) == 27
    areas = data["areas"]
    assert len({a["id"] for a in areas}) == len(areas)
    source = [a for a in areas if a["id"].startswith("oad-")]
    assert len(source) == 6081
    assert {a["governorate_id"] for a in source} == {g["id"] for g in data["governorates"]}
    assert any(a["id"] == "maadi" for a in areas)


def test_new_facts_and_independent_coordinates_persist_without_nonshared_occupancy(client, db, signup):
    owner = signup(["owner_sale_cash"])
    body = payload("sale_cash") | dict(
        area_measurement="net",
        finishing="lux",
        furnished=False,
        latitude="30.1234567",
        longitude="31.2345678",
        location_url="https://www.openstreetmap.org/?mlat=30.1234567&mlon=31.2345678",
    )
    body.pop("capacity")
    created = client.post("/api/v1/properties", headers=owner["headers"], json=body)
    assert created.status_code == 201, created.text
    identity = created.json()["id"]
    result = client.get(f"/api/v1/properties/{identity}", headers=owner["headers"]).json()
    assert result["capacity"] is None
    assert result["area_measurement"] == "net" and result["furnished"] is False
    assert result["latitude"] == "30.1234567" and result["longitude"] == "31.2345678"
    prop = db.get(Property, UUID(identity))
    assert prop.capacity is None and prop.latitude != prop.longitude


@pytest.mark.parametrize(
    "changes",
    [
        {"latitude": "30.1"},
        {"latitude": "0", "longitude": "31"},
        {"latitude": "30", "longitude": "180"},
        {"area_measurement": "estimated"},
        {"finishing": "plastered", "furnished": True},
        {"finishing": "lux", "furnished": "yes"},
        {"location_url": "https://www.google.com.evil.example/maps?q=30,31"},
    ],
)
def test_invalid_coordinates_and_listing_facts_rejected(client, signup, changes):
    owner = signup(["owner_sale_cash"])
    assert (
        client.post("/api/v1/properties", headers=owner["headers"], json=payload("sale_cash") | changes).status_code
        == 422
    )


def test_shared_housing_still_requires_real_capacity(client, signup):
    owner = signup(["owner_shared_rental"])
    body = payload("shared_rental")
    body.pop("capacity")
    assert client.post("/api/v1/properties", headers=owner["headers"], json=body).status_code == 422


def test_pending_photo_is_returned_privately_to_owner_but_never_public(client, signup):
    owner = signup(["owner_sale_cash"])
    other = signup()
    identity = client.post("/api/v1/properties", headers=owner["headers"], json=payload("sale_cash")).json()["id"]
    photos = [upload(client, owner["headers"], "photo").json()["id"] for _ in range(2)]
    assert client.put(f"/api/v1/properties/{identity}/photos", headers=owner["headers"], json=photos).status_code == 200
    item = client.get("/api/v1/properties/mine/page?group=sale", headers=owner["headers"]).json()["items"][0]
    assert item["cover_id"] == photos[0] and item["cover_private"] is True
    assert client.get(f"/api/v1/assets/{photos[0]}").status_code == 404
    assert client.get(f"/api/v1/private-assets/{photos[0]}", headers=owner["headers"]).status_code == 200
    assert client.get(f"/api/v1/private-assets/{photos[0]}", headers=other["headers"]).status_code == 404


@pytest.mark.parametrize(
    "url",
    [
        "https://www.openstreetmap.org/?mlat=30.1&mlon=31.2#map=17/30.1/31.2",
        "https://www.google.com/maps/search/?api=1&query=30.1,31.2",
    ],
)
def test_map_link_parser_works_locally_without_geocoding(client, signup, url):
    actor = signup()
    data = client.post("/api/v1/locations/parse-link", headers=actor["headers"], json={"url": url}).json()
    assert data["coordinates"] == dict(latitude="30.1000000", longitude="31.2000000")


def test_short_link_needs_explicit_pin_and_unsafe_links_are_rejected(client, signup):
    actor = signup()
    path = "/api/v1/locations/parse-link"
    result = client.post(path, headers=actor["headers"], json={"url": "https://maps.app.goo.gl/example"})
    assert result.json()["needs_map_selection"] is True
    for url in [
        "http://127.0.0.1/maps",
        "https://evil.example/",
        "https://google.com@evil.example/maps",
        "https://www.openstreetmap.org:443/",
    ]:
        assert client.post(path, headers=actor["headers"], json={"url": url}).status_code == 422
