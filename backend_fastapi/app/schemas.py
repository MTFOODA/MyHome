from decimal import Decimal
from typing import Annotated, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field, StrictBool, field_validator, model_validator

Intent = Literal[
    "owner_sale_cash",
    "owner_sale_installments",
    "owner_private_rental",
    "owner_shared_rental",
    "buyer_cash",
    "buyer_installments",
    "tenant_private",
    "tenant_shared",
]
Category = Literal["sale_cash", "sale_installments", "private_rental", "shared_rental"]
Finishing = Literal["red_brick", "plastered", "lux", "super_lux", "ultra_super_lux"]
RentalPeriod = Literal["one_year", "three_years", "five_years", "old_rent", "custom"]
Money = Annotated[Decimal, Field(gt=0, max_digits=14, decimal_places=2)]


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid", populate_by_name=True)


class Login(StrictModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=72)

    @field_validator("email", mode="before")
    @classmethod
    def normalize(cls, value):
        return value.strip().lower() if isinstance(value, str) else value

    @field_validator("password")
    @classmethod
    def password_bytes(cls, value):
        if len(value.encode()) > 72:
            raise ValueError("PASSWORD_TOO_LONG")
        return value


class Register(Login):
    name: str = Field(min_length=2, max_length=100)
    password: str = Field(min_length=8, max_length=72)
    role: Literal["user", "student", "expatriate", "owner", "maintenance_provider"] = "user"

    @field_validator("name", mode="before")
    @classmethod
    def trim_name(cls, value):
        return value.strip() if isinstance(value, str) else value


class Refresh(StrictModel):
    refreshToken: str = Field(min_length=80, max_length=200)


class Intents(StrictModel):
    intents: list[Intent] = Field(min_length=1, max_length=8)
    activeIntent: Intent
    housingPersona: Literal["regular", "student", "expatriate"] = "regular"

    @model_validator(mode="after")
    def validate_intents(self):
        if len(set(self.intents)) != len(self.intents) or self.activeIntent not in self.intents:
            raise ValueError("INVALID_ACTIVE_INTENT")
        return self


class ListingInput(StrictModel):
    @field_validator("title", "description", "approximate_location", mode="before")
    @classmethod
    def trim_listing_text(cls, value):
        return value.strip() if isinstance(value, str) else value

    title: str = Field(min_length=5, max_length=150)
    description: str = Field(min_length=20, max_length=5000)
    category: Category
    area_id: str = Field(max_length=40)
    approximate_location: str = Field(min_length=5, max_length=500)
    street_address: str = Field(min_length=3, max_length=160)
    building_number: str = Field(min_length=1, max_length=20)
    floor_number: int = Field(ge=0, le=100)
    unit_number: str = Field(min_length=1, max_length=20)
    property_kind: Literal["apartment", "studio", "duplex", "villa", "room"]
    latitude: Decimal | None = Field(default=None, ge=22, le=32)
    longitude: Decimal | None = Field(default=None, ge=24, le=37)
    area_m2: Decimal = Field(gt=0, le=100000, decimal_places=2)
    area_measurement: Literal["net", "gross"] | None = None
    furnished: StrictBool | None = None
    compound: StrictBool | None = None
    security: StrictBool | None = None
    internet: StrictBool | None = None
    garage: StrictBool | None = None
    orientation: Literal["north", "south", "east", "west", "north_south"] | None = None
    kitchen_type: Literal["closed_kitchen", "american_kitchen"] | None = None
    location_url: str | None = Field(default=None, max_length=2048)
    bedrooms: int = Field(ge=0, le=100)
    bathrooms: int = Field(ge=1, le=100)
    capacity: int | None = Field(default=None, ge=1, le=500)
    water: StrictBool
    electricity: StrictBool
    gas: StrictBool
    elevator: StrictBool
    finishing: Finishing
    price: Money
    negotiable: StrictBool
    rental_period: RentalPeriod | None = None
    custom_months: int | None = Field(default=None, ge=1, le=1200)
    deposit: Decimal | None = Field(default=None, ge=0, max_digits=14, decimal_places=2)
    down_payment: Decimal | None = Field(default=None, ge=0, max_digits=14, decimal_places=2)
    installment_count: int | None = Field(default=None, ge=1, le=600)
    installment_amount: Money | None = None
    total_beds: int | None = Field(default=None, ge=1, le=500)
    available_beds: int | None = Field(default=None, ge=0, le=500)

    @model_validator(mode="after")
    def conditional_fields(self):
        for name in ("street_address", "building_number", "unit_number"):
            value = getattr(self, name).strip()
            if not value or (name == "street_address" and len(value) < 3):
                raise ValueError("COMPLETE_ADDRESS_REQUIRED")
            setattr(self, name, value)
        if self.category != "shared_rental":
            self.capacity = None  # Not an occupancy claim for sale or private rental.
        if self.finishing not in ("lux", "super_lux", "ultra_super_lux") and self.furnished is not None:
            raise ValueError("FURNISHING_NOT_APPLICABLE")
        if self.location_url:
            from app.map_links import validate_map_url
            self.location_url = validate_map_url(self.location_url)
        if (self.latitude is None) != (self.longitude is None):
            raise ValueError("COORDINATES_REQUIRE_BOTH")
        rental = self.category in ("private_rental", "shared_rental")
        if rental and (self.rental_period is None or self.deposit is None):
            raise ValueError("RENTAL_TERMS_REQUIRED")
        if not rental and any(v is not None for v in (self.rental_period, self.deposit, self.custom_months)):
            raise ValueError("RENTAL_TERMS_NOT_APPLICABLE")
        if self.rental_period == "custom" and self.custom_months is None:
            raise ValueError("CUSTOM_PERIOD_REQUIRED")
        if self.rental_period != "custom" and self.custom_months is not None:
            raise ValueError("CUSTOM_PERIOD_NOT_APPLICABLE")
        if self.category == "sale_installments":
            if any(v is None for v in (self.down_payment, self.installment_count, self.installment_amount)):
                raise ValueError("INSTALLMENT_TERMS_REQUIRED")
            if self.down_payment + self.installment_count * self.installment_amount != self.price:
                raise ValueError("INSTALLMENT_TOTAL_MISMATCH")
        elif any(v is not None for v in (self.down_payment, self.installment_count, self.installment_amount)):
            raise ValueError("INSTALLMENTS_NOT_APPLICABLE")
        if self.category == "shared_rental":
            if (
                self.total_beds is None
                or self.available_beds is None
                or self.capacity is None
                or self.available_beds > self.total_beds
                or self.total_beds > self.capacity
            ):
                raise ValueError("BED_COUNTS_INVALID")
        elif self.total_beds is not None or self.available_beds is not None:
            raise ValueError("BEDS_NOT_APPLICABLE")
        return self


class SubmitVerification(StrictModel):
    identity_asset_id: UUID
    ownership_asset_id: UUID


class Review(StrictModel):
    approved: StrictBool
    note: str = Field(min_length=5, max_length=1000)


class GroupInput(StrictModel):
    property_id: UUID
    tenant_admin_id: UUID
