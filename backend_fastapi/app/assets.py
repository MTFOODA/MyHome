import io
import re
import warnings
from datetime import date
from uuid import UUID, uuid4

import pytesseract
from cryptography.fernet import Fernet
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from fastapi.responses import Response
from PIL import Image, ImageOps, UnidentifiedImageError
from sqlalchemy.orm import Session

from app.config import settings
from app.database import db_session
from app.models import Asset, AuditEvent, Property, User, UserIntent
from app.policy import require_owner
from app.security import authenticated

router = APIRouter(tags=["media"])
Image.MAX_IMAGE_PIXELS = 20_000_000


def identity_dob(number: str) -> date:
    if not re.fullmatch(r"[23]\d{13}", number):
        raise ValueError("INVALID_NATIONAL_ID")
    result = date((1900 if number[0] == "2" else 2000) + int(number[1:3]), int(number[3:5]), int(number[5:7]))
    if result >= date.today():
        raise ValueError("INVALID_BIRTH_DATE")
    return result


def compare_ocr(text: str, entered: str) -> str:
    candidates = ocr_numbers(text)
    if entered in candidates:
        return "matched"
    return "mismatch" if candidates else "unreadable"


def ocr_numbers(text: str) -> list[str]:
    normalized = text.translate(str.maketrans("٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹", "01234567890123456789"))
    return list(
        dict.fromkeys(
            re.sub(r"[ \t]", "", candidate)
            for candidate in re.findall(r"(?<![0-9])[23](?:[ \t]*[0-9]){13}(?![ \t]*[0-9])", normalized)
        )
    )


def identity_text(image: Image.Image) -> str:
    prepared = ImageOps.autocontrast(ImageOps.grayscale(image))
    prepared.thumbnail((2400, 2400))
    if prepared.width < 1600:
        scale = min(2, 1600 / prepared.width)
        prepared = prepared.resize((int(prepared.width * scale), int(prepared.height * scale)))
    return pytesseract.image_to_string(prepared, lang="eng+ara", config="--psm 6", timeout=15)


@router.post("/identity/scan")
def scan_identity(
    file: UploadFile = File(...),
    consent: bool = Form(False),
    context=Depends(authenticated),
    db: Session = Depends(db_session),
):
    require_owner(db, context[0])
    if not consent:
        raise HTTPException(400, "REVIEW_CONSENT_REQUIRED")
    raw = file.file.read(8 * 1024 * 1024 + 1)
    file.file.close()
    if not raw or len(raw) > 8 * 1024 * 1024:
        raise HTTPException(413, "IMAGE_MAX_8MB")
    image = decode_image(raw)
    if not settings().ocr_enabled:
        raise HTTPException(503, "OCR_UNAVAILABLE")
    try:
        candidates = []
        for number in ocr_numbers(identity_text(image)):
            try:
                candidates.append((number, identity_dob(number)))
            except ValueError:
                continue
    except (RuntimeError, pytesseract.TesseractNotFoundError, pytesseract.TesseractError):
        raise HTTPException(503, "OCR_UNAVAILABLE") from None
    if not candidates:
        raise HTTPException(422, "OCR_UNREADABLE")
    if len(candidates) != 1:
        raise HTTPException(422, "OCR_MULTIPLE_NUMBERS")
    # This preflight does not persist the image, extracted text or number.
    number, birth_date = candidates[0]
    return {"national_id": number, "birth_date": birth_date.isoformat(), "requires_manual_review": True}


def decode_image(raw: bytes) -> Image.Image:
    try:
        with warnings.catch_warnings():
            warnings.simplefilter("error", Image.DecompressionBombWarning)
            image = Image.open(io.BytesIO(raw))
            if image.format not in ("JPEG", "PNG", "WEBP"):
                raise ValueError()
            image.load()
            return ImageOps.exif_transpose(image).convert("RGB")
    except (UnidentifiedImageError, OSError, ValueError, Image.DecompressionBombError, Image.DecompressionBombWarning):
        raise HTTPException(400, "INVALID_IMAGE") from None


@router.post("/assets", status_code=201)
def upload(
    file: UploadFile = File(...),
    kind: str = Form(...),
    national_id: str | None = Form(None),
    birth_date: date | None = Form(None),
    context=Depends(authenticated),
    db: Session = Depends(db_session),
):
    user = context[0]
    require_owner(db, user)
    if kind not in ("photo", "identity", "ownership"):
        raise HTTPException(400, "INVALID_ASSET_KIND")
    raw = file.file.read(8 * 1024 * 1024 + 1)
    file.file.close()
    if not raw or len(raw) > 8 * 1024 * 1024:
        raise HTTPException(413, "IMAGE_MAX_8MB")
    image = decode_image(raw)
    cipher = Fernet(settings().document_key)
    encrypted_id = None
    ocr_status = None
    if kind == "identity":
        try:
            expected_date = identity_dob(national_id or "")
        except ValueError:
            raise HTTPException(400, "INVALID_NATIONAL_ID") from None
        if expected_date != birth_date:
            raise HTTPException(400, "NATIONAL_ID_BIRTH_DATE_MISMATCH")
        encrypted_id = cipher.encrypt(national_id.encode())
        ocr_status = "unavailable"
        if settings().ocr_enabled:
            try:
                text = identity_text(image)
                ocr_status = compare_ocr(text, national_id)
            except (RuntimeError, pytesseract.TesseractNotFoundError, pytesseract.TesseractError):
                ocr_status = "unavailable"
        if ocr_status == "mismatch":
            raise HTTPException(400, "OCR_NUMBER_MISMATCH")
    image.thumbnail((2400, 2400))
    output = io.BytesIO()
    image.save(output, "JPEG", quality=88)  # Re-encode and strip EXIF/GPS metadata.
    payload = output.getvalue()
    name = f"{uuid4()}.bin" if kind != "photo" else f"{uuid4()}.jpg"
    if kind != "photo":
        payload = cipher.encrypt(payload)
    storage = settings().storage_path
    storage.mkdir(parents=True, exist_ok=True, mode=0o700)
    path = storage / name
    path.write_bytes(payload)
    path.chmod(0o600)
    asset = Asset(
        owner_id=user.id,
        kind=kind,
        storage_name=name,
        national_id_cipher=encrypted_id,
        dob=birth_date if kind == "identity" else None,
        ocr_status=ocr_status,
    )
    db.add(asset)
    try:
        db.commit()
    except Exception:
        path.unlink(missing_ok=True)
        raise
    return dict(id=str(asset.id), kind=kind, ocrStatus=ocr_status, requiresManualReview=kind != "photo")


@router.get("/assets/{asset_id}")
def get_asset(asset_id: UUID, db: Session = Depends(db_session)):
    # Public endpoint only serves photographs attached to currently approved listings.
    asset = db.get(Asset, asset_id)
    prop = db.get(Property, asset.property_id) if asset and asset.property_id else None
    owner = db.get(User, prop.owner_id) if prop else None
    if (
        not asset
        or asset.kind != "photo"
        or not prop
        or prop.status != "approved"
        or prop.availability != "active"
        or not owner.active
        or not owner.owner_verified
        or not db.get(UserIntent, (owner.id, "owner_" + prop.category))
    ):
        raise HTTPException(404, "MEDIA_NOT_FOUND")
    return Response(
        (settings().storage_path / asset.storage_name).read_bytes(),
        media_type="image/jpeg",
        headers={"Cache-Control": "no-store", "X-Content-Type-Options": "nosniff"},
    )


@router.get("/private-assets/{asset_id}")
def private_asset(asset_id: UUID, context=Depends(authenticated), db: Session = Depends(db_session)):
    asset = db.get(Asset, asset_id)
    if not asset or (asset.owner_id != context[0].id and context[0].role != "admin"):
        raise HTTPException(404, "MEDIA_NOT_FOUND")
    raw = (settings().storage_path / asset.storage_name).read_bytes()
    if asset.kind != "photo":
        raw = Fernet(settings().document_key).decrypt(raw)
        db.add(AuditEvent(actor_id=context[0].id, action="private_document.read", target_id=asset.id))
        db.commit()
    return Response(
        raw, media_type="image/jpeg", headers={"Cache-Control": "no-store", "X-Content-Type-Options": "nosniff"}
    )
