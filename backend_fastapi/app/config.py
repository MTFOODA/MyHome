from functools import lru_cache
from pathlib import Path

from pydantic import Field
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


@lru_cache
def settings() -> Settings:
    return Settings()
