import uuid
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    LargeBinary,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    Uuid,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class Timestamps:
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class User(Timestamps, Base):
    __tablename__ = "users"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(100))
    email: Mapped[str] = mapped_column(String(254), unique=True)
    password_hash: Mapped[str] = mapped_column(String)
    role: Mapped[str] = mapped_column(String(30), default="user")  # Legacy primary role retained for compatibility.
    owner_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    onboarding_complete: Mapped[bool] = mapped_column(Boolean, default=False)
    active_intent: Mapped[str | None] = mapped_column(String(32))
    housing_persona: Mapped[str] = mapped_column(String(20), default="regular")


class UserIntent(Base):
    __tablename__ = "user_intents"
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    intent: Mapped[str] = mapped_column(String(32), primary_key=True)


class AuthSession(Timestamps, Base):
    __tablename__ = "auth_sessions"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    refresh_hash: Mapped[str] = mapped_column(String(64))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class Governorate(Base):
    __tablename__ = "governorates"
    id: Mapped[str] = mapped_column(String(32), primary_key=True)
    name_ar: Mapped[str] = mapped_column(String(80))
    name_en: Mapped[str] = mapped_column(String(80))


class Area(Base):
    __tablename__ = "areas"
    id: Mapped[str] = mapped_column(String(40), primary_key=True)
    governorate_id: Mapped[str] = mapped_column(ForeignKey("governorates.id"), index=True)
    name_ar: Mapped[str] = mapped_column(String(100))
    name_en: Mapped[str] = mapped_column(String(100))


class Property(Timestamps, Base):
    __tablename__ = "properties"
    __table_args__ = (
        CheckConstraint("area_m2 > 0 AND price > 0 AND bedrooms >= 0 AND bathrooms > 0 AND capacity > 0"),
        CheckConstraint("status IN ('draft','pending','approved','rejected')"),
        Index("properties_discovery_idx", "status", "area_id", "category", "price"),
    )
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    title: Mapped[str] = mapped_column(String(150))
    description: Mapped[str] = mapped_column(Text)
    category: Mapped[str] = mapped_column(String(32))
    area_id: Mapped[str] = mapped_column(ForeignKey("areas.id"), index=True)
    approximate_location: Mapped[str] = mapped_column(String(250))
    latitude: Mapped[Decimal | None] = mapped_column(Numeric(10, 7))
    longitude: Mapped[Decimal | None] = mapped_column(Numeric(10, 7))
    area_m2: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    bedrooms: Mapped[int] = mapped_column(Integer)
    bathrooms: Mapped[int] = mapped_column(Integer)
    capacity: Mapped[int] = mapped_column(Integer)
    water: Mapped[bool] = mapped_column(Boolean)
    electricity: Mapped[bool] = mapped_column(Boolean)
    gas: Mapped[bool] = mapped_column(Boolean)
    elevator: Mapped[bool] = mapped_column(Boolean)
    finishing: Mapped[str] = mapped_column(String(25))
    price: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    negotiable: Mapped[bool] = mapped_column(Boolean)
    rental_period: Mapped[str | None] = mapped_column(String(20))
    custom_months: Mapped[int | None] = mapped_column(Integer)
    deposit: Mapped[Decimal | None] = mapped_column(Numeric(14, 2))
    down_payment: Mapped[Decimal | None] = mapped_column(Numeric(14, 2))
    installment_count: Mapped[int | None] = mapped_column(Integer)
    installment_amount: Mapped[Decimal | None] = mapped_column(Numeric(14, 2))
    total_beds: Mapped[int | None] = mapped_column(Integer)
    available_beds: Mapped[int | None] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(20), default="draft")


class Asset(Timestamps, Base):
    __tablename__ = "assets"
    __table_args__ = (UniqueConstraint("property_id", "position", name="asset_photo_position_unique"),)
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    property_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("properties.id"), index=True)
    kind: Mapped[str] = mapped_column(String(20))  # photo / identity / ownership
    storage_name: Mapped[str] = mapped_column(String(80), unique=True)
    position: Mapped[int | None] = mapped_column(Integer)
    national_id_cipher: Mapped[bytes | None] = mapped_column(LargeBinary)
    dob: Mapped[date | None] = mapped_column(Date)
    ocr_status: Mapped[str | None] = mapped_column(String(20))


class Verification(Timestamps, Base):
    __tablename__ = "property_verifications"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.id"), unique=True)
    identity_asset_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("assets.id"), index=True)
    ownership_asset_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("assets.id"), index=True)
    status: Mapped[str] = mapped_column(String(20), default="pending")
    reviewer_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id"), index=True)
    review_note: Mapped[str | None] = mapped_column(String(1000))


class Favorite(Timestamps, Base):
    __tablename__ = "property_favorites"
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    property_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("properties.id", ondelete="CASCADE"), primary_key=True, index=True
    )


class HousingGroup(Timestamps, Base):
    __tablename__ = "housing_groups"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.id"), unique=True)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    tenant_admin_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)


class Tenancy(Timestamps, Base):
    __tablename__ = "tenancies"
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.id"), primary_key=True)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), primary_key=True, index=True)
    active: Mapped[bool] = mapped_column(Boolean, default=True)


class HousingApplication(Timestamps, Base):
    __tablename__ = "housing_applications"
    __table_args__ = (UniqueConstraint("property_id", "user_id"),)
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.id"), index=True)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    status: Mapped[str] = mapped_column(String(20), default="pending")


class AuditEvent(Base):
    __tablename__ = "audit_events"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    actor_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    action: Mapped[str] = mapped_column(String(40))
    target_id: Mapped[uuid.UUID] = mapped_column(Uuid)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
