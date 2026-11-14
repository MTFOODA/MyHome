# FastAPI local setup — current backend
Updated: 2026-11-14. This replaces NestJS/TypeORM startup commands for current development.

## Layout
- Flutter: myhome_flutter/, domain repositories and Cubit/BLoC presentation.
- API: backend_fastapi/app/; FastAPI routers, authorization policies, validated schemas and SQLAlchemy models.
- Migrations: backend_fastapi/migrations/versions/.
- Old NestJS backend/: removed after migration and explicit cleanup request.
- Database and private media volumes: infrastructure/compose.yaml.
- Original UI PNGs and newer JPEG references remain in UI/.

## Start
Existing infrastructure/.env contains ignored local secrets. Do not overwrite or display it.
A new machine can run `python tools/setup_local.py` from the repository root to create all secrets safely (existing settings are never overwritten). Alternatively, copy infrastructure/.env.example and set POSTGRES_PASSWORD, APP_DB_PASSWORD and JWT_SECRET to separate random values, then generate DOCUMENT_KEY:
    python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
Use a Python environment with requirements.txt installed for this command. DOCUMENT_KEY must be backed up separately and retained across restarts; losing it makes private documents unreadable.

    docker compose --env-file infrastructure/.env -f infrastructure/compose.yaml up -d --build api

The migration job uses the administrator DB connection, while the API uses the restricted myhome role and OS user 10001. Existing users/auth_sessions and bcrypt password hashes are adopted without deleting their rows. Alembic creates the additional tables and seeds location choices.
- API: http://127.0.0.1:3000/api/v1
- API docs: http://127.0.0.1:3000/api/docs
- Health: /api/v1/health returns backend=fastapi.
- PostgreSQL: 127.0.0.1:55432.
- Web development origin: http://localhost:8080.
- Native OCR packages are built into the API image; OCR_ENABLED=true in Compose.
- Private media is persisted in myhome-local_private_media; never expose that directory as a static server.

    cd myhome_flutter
    flutter pub get
    flutter run -d chrome --web-port 8080

Android emulator API uses 10.0.2.2:3000. Host development uses localhost:3000. For a different target, use --dart-define=API_BASE_URL=https://your-api.example/api/v1. Physical phones need a reachable HTTPS host or explicit local networking configuration; Docker currently binds to loopback intentionally.

## Python without Docker
    cd backend_fastapi
    python -m venv .venv
    ./.venv/Scripts/python.exe -m pip install -r requirements-dev.txt
    ./.venv/Scripts/python.exe -m uvicorn app.main:create_app --factory --host 127.0.0.1 --port 3000

The ignored .env created in this session uses the application DB role. .env.migration contains the local migration connection and is also ignored. Do not run another API on 3000 while the Docker API is running.
For migrations prefer the Docker migration job. Host PostgreSQL URLs use 127.0.0.1 because localhost/IPv6 connection attempts were slow on this Windows installation. Database connections time out after five seconds.

## Operator review
Register a separate reviewer account through the app. A local operator can promote an existing account:
    docker compose --env-file infrastructure/.env -f infrastructure/compose.yaml exec api python -m app.admin_cli --email reviewer@example.com
No reviewer account or known administrator password is seeded.
The reviewer signs in and opens Ownership review from the drawer. Review photos/declared number/date, provide a reason, then approve or request correction. Self-review is denied. Approval applies only to the reviewed listing.
The initial local administrator grant is itself audited. Production administrator onboarding and permissions need an operational policy.

## Test
Create the isolated DB once:
    docker compose --env-file infrastructure/.env -f infrastructure/compose.yaml exec -T postgres createdb -U postgres myhome_fastapi_test

From backend_fastapi/ in PowerShell:
    $taskSecrets = Get-Content ../infrastructure/.env -Raw | ConvertFrom-StringData
    $env:TEST_DATABASE_URL = 'postgresql://postgres:' + $taskSecrets.POSTGRES_PASSWORD + '@127.0.0.1:55432/myhome_fastapi_test'
    ./.venv/Scripts/python.exe -m pytest -q --tb=short
    ./.venv/Scripts/python.exe -m ruff check app tests migrations

Tests refuse any database path other than /myhome_fastapi_test, use the actual Alembic migrations and real PostgreSQL, and keep their synthetic fixtures only in that isolated database. They never truncate the application database.
The test suite checks authorization, strict mandatory answers, installment arithmetic, document access, review/publishing, favorites, concurrent refresh, last-bed concurrency and group co-admin eligibility.

From myhome_flutter/:
    flutter test --no-pub
    flutter analyze --no-pub
    flutter test test/live_api_auth.dart --no-pub
    flutter test test/render_previews.dart --no-pub --update-goldens
    flutter build web --no-pub
    flutter build apk --debug --no-pub

The live test leaves an identifiable flutter-live-* synthetic account and revokes its session. Preview fixtures exist only in test code; no demo property or synthetic identity document is published to the application database.

## API highlights
Public: GET /locations, GET /properties with database filters/pagination, GET /assets/{photo_id} for approved listing photographs.
Authenticated: /auth/profile, PUT /auth/intents, property details, /favorites, property draft create/update/photos/submit, asset uploads, eligible /roommates, housing applications and /groups metadata.
Admin: /admin/verifications and its review action. /private-assets/{id} enforces owner/admin access and no-store responses.
Roles are normalized in user_intents; active_intent is checked for roommate search and group creation. Public clients cannot register admin, assign verification, bypass listing review, read identity documents or nominate a non-tenant group administrator.

## Operational limits
- The in-memory limiter is for a single API instance. Shared rate-limit storage is required before scaling.
- Private file cleanup, key rotation, retention/deletion policies and scheduled backup/restore are not complete.
- A pre-migration PostgreSQL dump is saved in ignored artifacts/myhome-before-fastapi-20261114.dump; it contains private application data and should remain local.
- No downgrade command drops user data. Use an isolated backup restore when testing rollback.
- OCR synthetic-image smoke passed; this is not a real ID accuracy, authenticity or biometric test.
- Browser secure storage requires HTTPS or localhost; device Keychain/Keystore still needs actual device tests.
- Messaging/calling E2EE is not implemented. /groups currently returns messagingReady=false.
- No iOS build can be verified on this Windows host; use macOS/Xcode for that platform.
