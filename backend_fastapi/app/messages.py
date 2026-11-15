"""Member-only moderated text chat, encrypted at rest. This is deliberately not E2EE."""

import base64
import json
import re
import unicodedata
from datetime import timedelta
from uuid import UUID, uuid4

from cryptography.fernet import Fernet, InvalidToken
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import Field
from sqlalchemy import func, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

from app.config import settings
from app.database import db_session
from app.deals import audit, scoped
from app.models import Conversation, HousingGroup, Message, Tenancy, User
from app.schemas import StrictModel
from app.security import authenticated, now

router = APIRouter(tags=["moderated-chat"])
WORDS = {
    "zero": "0",
    "one": "1",
    "two": "2",
    "three": "3",
    "four": "4",
    "five": "5",
    "six": "6",
    "seven": "7",
    "eight": "8",
    "nine": "9",
    "صفر": "0",
    "زيرو": "0",
    "واحد": "1",
    "اثنين": "2",
    "اتنين": "2",
    "اثنان": "2",
    "ثلاثه": "3",
    "ثلاثة": "3",
    "تلاته": "3",
    "تلاتة": "3",
    "اربعه": "4",
    "اربعة": "4",
    "خمسه": "5",
    "خمسة": "5",
    "سته": "6",
    "ستة": "6",
    "سبعه": "7",
    "سبعة": "7",
    "ثمانيه": "8",
    "ثمانية": "8",
    "تمانيه": "8",
    "تسعه": "9",
    "تسعة": "9",
}


def canonical(text):
    return (
        "".join(c for c in unicodedata.normalize("NFKC", text).lower() if unicodedata.category(c) not in ("Cf", "Mn"))
        .replace("أ", "ا")
        .replace("إ", "ا")
        .replace("آ", "ا")
    )


def digit_sequence(text):
    result = []
    for token in re.findall(r"\w+", canonical(text)):
        if token in WORDS:
            result.append(WORDS[token])
        else:
            for char in token:
                try:
                    result.append(str(unicodedata.decimal(char)))
                except ValueError:
                    pass
    return "".join(result)


def contact_blocked(text, recent=()):
    value = canonical(text)
    if re.search(
        r"(https?\s*:|www\s*\.|wa\s*\.\s*me|whats\s*app|واتس|تلجرام|telegram|t\s*\.\s*me|tel\s*:|[\w.+-]+\s*@\s*[\w.-]+)",
        value,
    ):
        return True
    digits = digit_sequence(value)
    return len(digits) >= 7 or (bool(digits) and len(digit_sequence(" ".join([*recent, text]))) >= 7)


def cipher_for(conversation_id):
    key = HKDF(
        algorithm=hashes.SHA256(), length=32, salt=None, info=b"myhome.message-storage.v1/" + conversation_id.bytes
    ).derive(base64.urlsafe_b64decode(settings().document_key))
    return Fernet(base64.urlsafe_b64encode(key))


def decode(row):
    try:
        content = json.loads(cipher_for(row.conversation_id).decrypt(row.body_cipher))
        if (
            content["id"] != row.id
            or content["conversation"] != str(row.conversation_id)
            or content["sender"] != str(row.sender_id)
        ):
            raise ValueError()
        return content["text"]
    except (InvalidToken, ValueError, KeyError, TypeError):
        raise HTTPException(503, "MESSAGE_INTEGRITY_ERROR") from None


def group_member(db, user, group_id):
    group = db.get(HousingGroup, group_id)
    tenancy = db.get(Tenancy, (group.property_id, user.id)) if group else None
    if not group or not (group.owner_id == user.id or (tenancy and tenancy.active)):
        raise HTTPException(404, "CONVERSATION_NOT_FOUND")
    return group


def conversation_for(db, user, identity):
    row = db.get(Conversation, identity)
    if not row:
        raise HTTPException(404, "CONVERSATION_NOT_FOUND")
    if row.deal_id:
        scoped(db, user, row.deal_id)
    else:
        group_member(db, user, row.group_id)
    return row


def ensure_conversation(db, **target):
    key, value = next(iter(target.items()))
    identity = db.scalar(
        insert(Conversation)
        .values(id=uuid4(), **target)
        .on_conflict_do_nothing(index_elements=[key])
        .returning(Conversation.id)
    )
    if not identity:
        identity = db.scalar(select(Conversation.id).where(getattr(Conversation, key) == value))
    db.commit()
    return {
        "id": str(identity),
        "kind": "deal" if key == "deal_id" else "group",
        "moderated": True,
        "encrypted_at_rest": True,
        "end_to_end_encrypted": False,
    }


@router.post("/deals/{deal_id}/conversation")
def deal_conversation(deal_id: UUID, context=Depends(authenticated), db: Session = Depends(db_session)):
    scoped(db, context[0], deal_id)
    return ensure_conversation(db, deal_id=deal_id)


@router.post("/groups/{group_id}/conversation")
def group_conversation(group_id: UUID, context=Depends(authenticated), db: Session = Depends(db_session)):
    group_member(db, context[0], group_id)
    return ensure_conversation(db, group_id=group_id)


def message_data(row, user):
    return dict(
        id=row.id,
        text=decode(row),
        mine=row.sender_id == user.id,
        sender_alias="member-" + str(row.sender_id)[:6],
        created_at=row.created_at.isoformat(),
    )


@router.get("/conversations/{conversation_id}/messages")
def read_messages(
    conversation_id: UUID,
    before_id: int | None = Query(None, ge=1),
    after_id: int | None = Query(None, ge=0),
    context=Depends(authenticated),
    db: Session = Depends(db_session),
):
    conversation_for(db, context[0], conversation_id)
    if before_id is not None and after_id is not None:
        raise HTTPException(400, "ONE_MESSAGE_CURSOR_REQUIRED")
    query = select(Message).where(Message.conversation_id == conversation_id)
    if after_id is not None:
        rows = list(db.scalars(query.where(Message.id > after_id).order_by(Message.id).limit(30)))
        return {"items": [message_data(r, context[0]) for r in rows], "next_before": None}
    if before_id is not None:
        query = query.where(Message.id < before_id)
    rows = list(db.scalars(query.order_by(Message.id.desc()).limit(31)))
    more = len(rows) > 30
    rows = rows[:30]
    rows.reverse()
    return {"items": [message_data(r, context[0]) for r in rows], "next_before": rows[0].id if more else None}


class MessageInput(StrictModel):
    text: str = Field(min_length=1, max_length=2000)


@router.post("/conversations/{conversation_id}/messages", status_code=201)
def send_message(
    conversation_id: UUID, body: MessageInput, context=Depends(authenticated), db: Session = Depends(db_session)
):
    user = context[0]
    db.scalar(select(User).where(User.id == user.id).with_for_update())
    conversation_for(db, user, conversation_id)
    text = body.text.strip()
    if not text:
        raise HTTPException(422, "MESSAGE_TEXT_REQUIRED")
    count = db.scalar(
        select(func.count())
        .select_from(Message)
        .where(Message.sender_id == user.id, Message.created_at > now() - timedelta(minutes=1))
    )
    if count >= 40:
        raise HTTPException(429, "MESSAGE_RATE_LIMITED")
    previous = list(
        db.scalars(
            select(Message)
            .where(
                Message.conversation_id == conversation_id,
                Message.sender_id == user.id,
                Message.created_at > now() - timedelta(minutes=5),
            )
            .order_by(Message.id.desc())
            .limit(10)
        )
    )
    if contact_blocked(text, [decode(r) for r in previous]):
        audit(db, user, "message.contact_blocked", conversation_id)
        db.commit()
        raise HTTPException(422, "CONTACT_DETAILS_BLOCKED")
    row = Message(conversation_id=conversation_id, sender_id=user.id, body_cipher=b"")
    db.add(row)
    db.flush()
    content = json.dumps(
        {"id": row.id, "conversation": str(conversation_id), "sender": str(user.id), "text": text}, ensure_ascii=False
    ).encode()
    row.body_cipher = cipher_for(conversation_id).encrypt(content)
    audit(db, user, "message.sent", conversation_id)
    db.commit()
    return message_data(row, user)
