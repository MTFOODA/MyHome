import uuid
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import (
    BigInteger,
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Identity,
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
        CheckConstraint(
            "area_m2 > 0 AND price > 0 AND bedrooms >= 0 AND bathrooms > 0 AND (capacity IS NULL OR capacity > 0)"
        ),
        CheckConstraint("category <> 'shared_rental' OR capacity IS NOT NULL"),
        CheckConstraint("area_measurement IS NULL OR area_measurement IN ('net','gross')"),
        CheckConstraint(
            "furnished IS NULL OR finishing IN ('lux','super_lux','ultra_super_lux')", name="property_furnishing_valid"
        ),
        CheckConstraint(
            "finishing IN ('red_brick','plastered','lux','super_lux','ultra_super_lux')",
            name="property_finishing_valid",
        ),
        CheckConstraint(
            "orientation IS NULL OR orientation IN ('north','south','east','west','north_south')",
            name="property_orientation_valid",
        ),
        CheckConstraint(
            "kitchen_type IS NULL OR kitchen_type IN ('closed_kitchen','american_kitchen')",
            name="property_kitchen_valid",
        ),
        CheckConstraint("floor_number IS NULL OR floor_number BETWEEN -5 AND 100", name="property_floor_valid"),
        CheckConstraint(
            "num_nonnulls(street_address,building_number,floor_number,unit_number) IN (0,4)",
            name="property_address_complete",
        ),
        CheckConstraint(
            "property_kind IS NULL OR property_kind IN ('apartment','studio','duplex','villa','room')",
            name="property_kind_valid",
        ),
        CheckConstraint("status IN ('draft','pending','approved','rejected')"),
        Index("properties_discovery_idx", "status", "area_id", "category", "price"),
    )
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    title: Mapped[str] = mapped_column(String(150))
    description: Mapped[str] = mapped_column(Text)
    category: Mapped[str] = mapped_column(String(32))
    area_id: Mapped[str] = mapped_column(ForeignKey("areas.id"), index=True)
    approximate_location: Mapped[str] = mapped_column(String(500))
    street_address: Mapped[str | None] = mapped_column(String(160))
    building_number: Mapped[str | None] = mapped_column(String(20))
    floor_number: Mapped[int | None] = mapped_column(Integer)
    unit_number: Mapped[str | None] = mapped_column(String(20))
    property_kind: Mapped[str | None] = mapped_column(String(16))
    latitude: Mapped[Decimal | None] = mapped_column(Numeric(10, 7))
    longitude: Mapped[Decimal | None] = mapped_column(Numeric(10, 7))
    area_m2: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    area_measurement: Mapped[str | None] = mapped_column(String(10))
    location_url: Mapped[str | None] = mapped_column(String(2048))
    furnished: Mapped[bool | None] = mapped_column(Boolean)
    compound: Mapped[bool | None] = mapped_column(Boolean)
    security: Mapped[bool | None] = mapped_column(Boolean)
    internet: Mapped[bool | None] = mapped_column(Boolean)
    garage: Mapped[bool | None] = mapped_column(Boolean)
    orientation: Mapped[str | None] = mapped_column(String(16))
    kitchen_type: Mapped[str | None] = mapped_column(String(20))
    bedrooms: Mapped[int] = mapped_column(Integer)
    bathrooms: Mapped[int] = mapped_column(Integer)
    capacity: Mapped[int | None] = mapped_column(Integer)
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
    availability: Mapped[str] = mapped_column(String(12), default="active", server_default="active")
    closed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    display_price: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    platform_fee: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0, server_default="0")
    pricing_policy: Mapped[str] = mapped_column(String(40), default="none", server_default="none")
    original_price: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    buyer_fee: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0, server_default="0")
    seller_fee: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0, server_default="0")
    reference_months: Mapped[int | None] = mapped_column(Integer)
    legal_eligibility: Mapped[str] = mapped_column(String(20), default="pending", server_default="pending")
    eligibility_reviewer_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id"), index=True)
    eligibility_note: Mapped[str | None] = mapped_column(String(2000))
    eligibility_reference: Mapped[str | None] = mapped_column(String(250))


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
    title_snapshot: Mapped[str] = mapped_column(String(150), default="Property")
    category_snapshot: Mapped[str] = mapped_column(String(32), default="sale_cash")
    price_snapshot: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)


class PropertyVisit(Base):
    __tablename__ = "property_visits"
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.id", ondelete="CASCADE"), primary_key=True)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), primary_key=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


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


class StaffMember(Timestamps, Base):
    __tablename__ = "staff_members"
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), primary_key=True)
    specialty: Mapped[str] = mapped_column(String(24))
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    professional_reference: Mapped[str | None] = mapped_column(String(150))


class BrokerageTerms(Timestamps, Base):
    __tablename__ = "brokerage_terms"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    version: Mapped[str] = mapped_column(String(60), unique=True)
    body_ar: Mapped[str] = mapped_column(Text)
    body_en: Mapped[str] = mapped_column(Text)
    due_condition: Mapped[str] = mapped_column(String(2000))
    legal_reference: Mapped[str] = mapped_column(String(250))
    created_by: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)


class PaymentDestination(Timestamps, Base):
    __tablename__ = "payment_destinations"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    qr_asset_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("assets.id"), index=True)
    recipient_name: Mapped[str] = mapped_column(String(150))
    created_by: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)


class Deal(Timestamps, Base):
    __tablename__ = "deals"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    property_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("properties.id"), index=True)
    buyer_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    seller_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    property_title: Mapped[str] = mapped_column(String(150))
    base_price: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    category: Mapped[str] = mapped_column(String(32))
    rental_months: Mapped[int | None] = mapped_column(Integer)
    rental_period: Mapped[str | None] = mapped_column(String(20))
    asking_price: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    bed_reserved: Mapped[bool] = mapped_column(Boolean, default=False, server_default="false")
    fee_total: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    buyer_fee: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    seller_fee: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    stage: Mapped[str] = mapped_column(String(20), default="open")
    terms_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("brokerage_terms.id"), index=True)
    reviewer_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id"), index=True)
    review_status: Mapped[str] = mapped_column(String(20), default="pending")
    contract_reference: Mapped[str | None] = mapped_column(String(250))
    review_note: Mapped[str | None] = mapped_column(String(2000))
    destination_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("payment_destinations.id"), index=True)


class Viewing(Timestamps, Base):
    __tablename__ = "deal_viewings"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    deal_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("deals.id"), index=True)
    reference: Mapped[str] = mapped_column(String(40), unique=True)
    scheduled_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    staff_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id"), index=True)
    owner_confirmed: Mapped[bool] = mapped_column(Boolean, default=False)
    status: Mapped[str] = mapped_column(String(20), default="requested")
    completion_note: Mapped[str | None] = mapped_column(String(1000))


class DealOffer(Timestamps, Base):
    __tablename__ = "deal_offers"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    deal_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("deals.id"), index=True)
    created_by: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    status: Mapped[str] = mapped_column(String(20), default="open")


class DealConsent(Base):
    __tablename__ = "deal_consents"
    deal_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("deals.id"), primary_key=True)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), primary_key=True, index=True)
    digest: Mapped[str] = mapped_column(String(64))
    evidence_digest: Mapped[str] = mapped_column(String(64))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class FeeInvoice(Timestamps, Base):
    __tablename__ = "fee_invoices"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    deal_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("deals.id"), index=True)
    payer_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    status: Mapped[str] = mapped_column(String(20), default="unpaid")


class PaymentClaim(Timestamps, Base):
    __tablename__ = "payment_claims"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    invoice_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("fee_invoices.id"), index=True)
    reference: Mapped[str] = mapped_column(String(100), unique=True)
    status: Mapped[str] = mapped_column(String(20), default="reported")
    verifier_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id"), index=True)
    verification_note: Mapped[str | None] = mapped_column(String(2000))


class SpecialFeeProposal(Timestamps, Base):
    __tablename__ = "special_fee_proposals"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    deal_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("deals.id"), index=True)
    created_by: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    previous_total: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    total: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    reason: Mapped[str] = mapped_column(String(2000))
    legal_reference: Mapped[str] = mapped_column(String(250))
    digest: Mapped[str] = mapped_column(String(64))
    buyer_accepted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    seller_accepted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    status: Mapped[str] = mapped_column(String(16), default="pending")


class Conversation(Timestamps, Base):
    __tablename__ = "conversations"
    __table_args__ = (
        UniqueConstraint("property_id", "seeker_id", name="uq_property_inquiry"),
        CheckConstraint(
            "num_nonnulls(deal_id,group_id,property_id)=1 AND ((property_id IS NOT NULL)=(seeker_id IS NOT NULL))",
            name="conversation_target_valid",
        ),
    )
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    deal_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("deals.id"), unique=True)
    group_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("housing_groups.id"), unique=True)
    property_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("properties.id"))
    seeker_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id"), index=True)


class Message(Base):
    __tablename__ = "messages"
    id: Mapped[int] = mapped_column(BigInteger, Identity(), primary_key=True)
    conversation_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("conversations.id"), index=True)
    sender_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"), index=True)
    body_cipher: Mapped[bytes] = mapped_column(LargeBinary)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
