from datetime import date

import pytest
from sqlalchemy import func, select

from app import assets
from app.config import settings
from app.models import Asset
from tests.test_marketplace import picture, upload


def scan(client, headers=None, consent=True):
    return client.post(
        "/api/v1/identity/scan",
        headers=headers or {},
        data={"consent": str(consent).lower()},
        files={"file": ("id.png", picture(), "image/png")},
    )


@pytest.mark.parametrize(
    "number", ["30013011234567", "30002301234567", "29902291234567", "39901011234567", "10001011234567"]
)
def test_identity_rejects_invalid_calendar_dates(number):
    with pytest.raises(ValueError):
        assets.identity_dob(number)
    assert assets.identity_dob("30002291234567") == date(2000, 2, 29)


def test_scan_authorization_consent_and_no_persistence(client, db, signup, monkeypatch):
    owner = signup(["owner_sale_cash"])
    viewer = signup()
    assert scan(client).status_code == 401
    assert scan(client, viewer["headers"]).status_code == 403
    assert scan(client, owner["headers"], False).json()["detail"] == "REVIEW_CONSENT_REQUIRED"
    monkeypatch.setattr(settings(), "ocr_enabled", True)
    monkeypatch.setattr(assets, "identity_text", lambda image: "رقم ٣ ٠ ٠ ٠ ١ ٠ ١ ١ ٢ ٣ ٤ ٥ ٦ ٧")
    before = db.scalar(select(func.count()).select_from(Asset))
    response = scan(client, owner["headers"])
    assert response.status_code == 200
    assert response.json() == {
        "national_id": "30001011234567",
        "birth_date": "2000-01-01",
        "requires_manual_review": True,
    }
    assert response.headers["cache-control"] == "no-store"
    assert db.scalar(select(func.count()).select_from(Asset)) == before


@pytest.mark.parametrize(
    ("text", "code"),
    [
        ("unclear", "OCR_UNREADABLE"),
        ("30013011234567", "OCR_UNREADABLE"),
        ("30001011234567\n30002021234567", "OCR_MULTIPLE_NUMBERS"),
    ],
)
def test_scan_returns_specific_retake_errors(client, signup, monkeypatch, text, code):
    owner = signup(["owner_sale_cash"])
    monkeypatch.setattr(settings(), "ocr_enabled", True)
    monkeypatch.setattr(assets, "identity_text", lambda image: text)
    response = scan(client, owner["headers"])
    assert response.status_code == 422 and response.json()["detail"] == code


def test_unavailable_scanner_has_explicit_error(client, signup):
    owner = signup(["owner_sale_cash"])
    assert scan(client, owner["headers"]).json()["detail"] == "OCR_UNAVAILABLE"


def test_final_identity_upload_checks_both_dob_and_image_number(client, signup, monkeypatch):
    owner = signup(["owner_sale_cash"])
    monkeypatch.setattr(settings(), "ocr_enabled", True)
    monkeypatch.setattr(assets, "identity_text", lambda image: "30002021234567")
    response = upload(client, owner["headers"], "identity", national_id="30001011234567", birth_date="2000-01-01")
    assert response.status_code == 400 and response.json()["detail"] == "OCR_NUMBER_MISMATCH"
    response = upload(client, owner["headers"], "identity", national_id="30001011234567", birth_date="2000-02-02")
    assert response.status_code == 400 and response.json()["detail"] == "NATIONAL_ID_BIRTH_DATE_MISMATCH"
    monkeypatch.setattr(assets, "identity_text", lambda image: "٣٠٠٠١٠١١٢٣٤٥٦٧")
    response = upload(client, owner["headers"], "identity", national_id="30001011234567", birth_date="2000-01-01")
    assert response.status_code == 201 and response.json()["ocrStatus"] == "matched"
