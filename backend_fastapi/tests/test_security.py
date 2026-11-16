from datetime import UTC, datetime, timedelta
from uuid import UUID

import jwt
from fastapi.testclient import TestClient

from app.config import settings
from app.main import create_app
from app.models import User


def test_authentication_rejects_forged_expired_and_disabled_accounts(client, signup, db):
    account = signup()
    payload = {
        "sub": account["user"]["id"],
        "sid": account["refreshToken"].split(".")[0],
        "exp": datetime.now(UTC) - timedelta(seconds=1),
        "iss": "myhome-api",
        "aud": "myhome-app",
    }
    expired = jwt.encode(payload, settings().jwt_secret, algorithm="HS256")
    for token in (expired, account["refreshToken"], account["accessToken"] + "bad"):
        assert client.get("/api/v1/auth/profile", headers={"Authorization": "Bearer " + token}).status_code == 401
    db.get(User, UUID(account["user"]["id"])).active = False
    db.commit()
    assert client.get("/api/v1/auth/profile", headers=account["headers"]).status_code == 401
    assert client.post("/api/v1/auth/refresh", json={"refreshToken": account["refreshToken"]}).status_code == 401


def test_rate_limiter_is_active_and_validation_does_not_echo_passwords():
    config = settings()
    original = config.rate_limit
    config.rate_limit = 2
    try:
        with TestClient(create_app()) as client:
            for _ in range(2):
                response = client.post(
                    "/api/v1/auth/login", json={"email": "invalid", "password": "sensitive-test-value"}
                )
                assert response.status_code == 422
                assert "sensitive-test-value" not in response.text
            assert client.post("/api/v1/auth/login", json={}).status_code == 429
            for _ in range(2):
                response = client.post(
                    "/api/v1/auth/password",
                    json={"current_password": "sensitive-test-value", "new_password": "temporary-test-value"},
                )
                assert response.status_code == 401 and "sensitive-test-value" not in response.text
            assert client.post("/api/v1/auth/password", json={}).status_code == 429
    finally:
        config.rate_limit = original
