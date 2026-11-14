import os
from uuid import uuid4

import pytest
from alembic import command
from alembic.config import Config
from cryptography.fernet import Fernet
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

# Explicitly isolated DB only; never use the application database for cleanup.
url = os.environ.get("TEST_DATABASE_URL", "")
if not url.endswith("/myhome_fastapi_test"):
    raise RuntimeError("TEST_DATABASE_URL must point to isolated /myhome_fastapi_test")
os.environ["DATABASE_URL"] = url
os.environ["JWT_SECRET"] = "test-secret-only-with-at-least-32-characters"
os.environ["DOCUMENT_KEY"] = Fernet.generate_key().decode()
os.environ["OCR_ENABLED"] = "false"
os.environ["RATE_LIMIT"] = "1000"

from app.config import settings
from app.database import engine
from app.main import create_app


@pytest.fixture(scope="session", autouse=True)
def schema(tmp_path_factory):
    os.environ["STORAGE_PATH"] = str(tmp_path_factory.mktemp("myhome-private-test-assets"))
    settings.cache_clear()
    command.upgrade(Config("alembic.ini"), "head")
    yield
    engine().dispose()


@pytest.fixture
def db(schema):
    with Session(engine(), expire_on_commit=False) as session:
        yield session


@pytest.fixture
def client(schema):
    with TestClient(create_app()) as test_client:
        yield test_client


@pytest.fixture
def signup(client):
    def create(intents=None, active=None):
        email = f"test-{uuid4()}@example.com"
        response = client.post(
            "/api/v1/auth/register", json={"name": "Local Test", "email": email, "password": "password-for-tests-123"}
        )
        assert response.status_code == 201, response.text
        result = response.json()
        result["headers"] = {"Authorization": "Bearer " + result["accessToken"]}
        if intents:
            updated = client.put(
                "/api/v1/auth/intents",
                headers=result["headers"],
                json={"intents": intents, "activeIntent": active or intents[0], "housingPersona": "student"},
            )
            assert updated.status_code == 200, updated.text
            result["user"] = updated.json()
        return result

    return create
