import time
from collections import OrderedDict
from threading import Lock

from cryptography.fernet import Fernet
from fastapi import Depends, FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.orm import Session

from app import assets, auth, catalog, deals, groups, legal_eligibility, messages, portfolio, pricing, properties
from app.config import settings
from app.database import db_session


def create_app():
    config = settings()
    Fernet(config.document_key)  # Fail at startup for a missing/invalid private document key.
    application = FastAPI(title="MyHome API", version="0.2.0", docs_url="/api/docs", redoc_url=None)

    @application.exception_handler(RequestValidationError)
    async def invalid_input(request, error):
        return JSONResponse(
            {
                "detail": [
                    {"loc": list(item["loc"]), "msg": item["msg"], "type": item["type"]} for item in error.errors()
                ]
            },
            422,
        )

    application.add_middleware(
        CORSMiddleware,
        allow_origins=[value.strip() for value in config.cors_origins.split(",")],
        allow_credentials=False,
        allow_methods=["GET", "POST", "PUT", "DELETE"],
        allow_headers=["Authorization", "Content-Type"],
    )
    counters = OrderedDict()
    lock = Lock()

    @application.middleware("http")
    async def safeguards(request: Request, call_next):
        path = request.url.path
        if path in ("/api/v1/assets", "/api/v1/admin/payment-destination") and request.method == "POST":
            chunks = []
            size = 0
            async for chunk in request.stream():
                size += len(chunk)
                if size > (3 if path.endswith("payment-destination") else 9) * 1024 * 1024:
                    return JSONResponse({"detail": "IMAGE_MAX_8MB"}, 413)
                chunks.append(chunk)
            request._body = b"".join(chunks)
        # Single-instance limiter with bounded memory; never trust caller-supplied IP headers.
        if path in ("/api/v1/auth/login", "/api/v1/auth/register", "/api/v1/auth/refresh", "/api/v1/assets"):
            key = (request.client.host if request.client else "unknown", path)
            timestamp = time.monotonic()
            with lock:
                count, start = counters.get(key, (0, timestamp))
                if timestamp - start > 60:
                    count, start = 0, timestamp
                counters[key] = (count + 1, start)
                counters.move_to_end(key)
                while len(counters) > 10000:
                    counters.popitem(last=False)
            if count >= config.rate_limit:
                return JSONResponse({"detail": "RATE_LIMITED"}, 429, headers={"Retry-After": "60"})
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["Referrer-Policy"] = "no-referrer"
        if (
            "auth" in path
            or "private-assets" in path
            or "admin" in path
            or any(
                part in path
                for part in (
                    "/deals",
                    "/conversations",
                    "/eligibility-reviews",
                    "/groups",
                    "/favorites",
                    "/properties/mine",
                )
            )
        ):
            response.headers["Cache-Control"] = "no-store"
        return response

    for router in (
        auth.router,
        catalog.router,
        portfolio.router,
        properties.router,
        assets.router,
        groups.router,
        pricing.router,
        deals.router,
        legal_eligibility.router,
        messages.router,
    ):
        application.include_router(router, prefix="/api/v1")

    @application.get("/api/v1/health")
    def health(db: Session = Depends(db_session)):
        db.execute(text("SELECT 1"))
        return {"status": "ok", "backend": "fastapi"}

    return application
