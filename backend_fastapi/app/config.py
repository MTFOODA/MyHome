from decimal import Decimal
from functools import lru_cache
from pathlib import Path

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
    database_url: str
    jwt_secret: str = Field(min_length=32)
    document_key: str  # Dedicated Fernet key, never reuse the JWT secret.
    storage_path: Path = Path("storage")
    cors_origins: str = "http://localhost:8080"
    ocr_enabled: bool = False
    rate_limit: int = 20
    commission_enabled: bool = True  # Approved all-in policy; persisted references govern existing listings.
    commission_old_rent: Decimal = Field(Decimal(".75"), ge=0, le=2)
    commission_sale_rate: Decimal = Field(Decimal(".01"), ge=0, le=Decimal(".10"))
    commission_private_one: Decimal = Field(Decimal(".5"), ge=0, le=2)
    commission_private_three: Decimal = Field(Decimal(".75"), ge=0, le=2)
    commission_private_long: Decimal = Field(Decimal("1"), ge=0, le=2)
    commission_shared_one: Decimal = Field(Decimal(".25"), ge=0, le=1)
    commission_shared_three: Decimal = Field(Decimal(".375"), ge=0, le=1)
    commission_shared_long: Decimal = Field(Decimal(".5"), ge=0, le=1)
    commission_policy_version: str = Field("all-in-v1", min_length=1, max_length=40, pattern=r"^[a-zA-Z0-9_.-]+$")
    commission_region_discounts: dict[str, Decimal] = Field(default_factory=dict)

    @field_validator("commission_region_discounts")
    @classmethod
    def region_discounts(cls, value):
        if any(
            not k.startswith(("area:", "governorate:")) or not v.is_finite() or not Decimal(0) <= v <= Decimal(".30")
            for k, v in value.items()
        ):
            raise ValueError("Region discounts must be 0..0.30, keyed by area:ID or governorate:ID")
        return value


@lru_cache
def settings() -> Settings:
    return Settings()
