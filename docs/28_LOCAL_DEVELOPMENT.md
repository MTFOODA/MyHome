# Historical setup — current commands moved
<!-- CURRENT_AUDIT_2026_11_14 -->
The active backend is now Python/FastAPI. Use docs/30_FASTAPI_LOCAL_SETUP.md.
The NestJS/TypeORM commands below apply only to preserved legacy source and should not be used to start the current API.

---


# MyHome — Local development
Updated: 2026-11-09. Run shell commands from the workspace root unless a section changes directory.

## Requirements
- Flutter 3.47.7 / Dart 3.13.5 (versions used for this verification).
- Node.js 24 and npm; on Windows use npm.cmd to avoid PowerShell script-policy problems.
- Docker Desktop running Linux containers.
- Windows Developer Mode is needed for desktop plugin symlinks. iOS/macOS builds require macOS/Xcode. Linux secure storage needs libsecret and an available keyring service.

## Local containers
The working directory is myhome_flutter/, not apps/myhome_flutter/. Original image references remain in UI/.

    Copy-Item infrastructure/.env.example infrastructure/.env
Edit the three secret values. Use separate long random hexadecimal values; hex avoids URL-escaping surprises in the local database connection string. Never commit .env files.
This work session already generated an ignored infrastructure/.env with random secrets, so do not overwrite that existing file.

    docker compose --env-file infrastructure/.env -f infrastructure/compose.yaml up -d --build api

Services:
- PostgreSQL: localhost:55432 by default, persistent project-specific volume.
- Migration job: runs as database administrator and exits after migrations succeed.
- API: http://localhost:3000/api/v1, runs as the non-superuser myhome database role and non-root container OS user.
- Health: http://localhost:3000/api/v1/health.
- CORS permits http://localhost:8080 by default; configure CORS_ORIGINS for a different development origin.

    docker compose --env-file infrastructure/.env -f infrastructure/compose.yaml ps
    docker compose --env-file infrastructure/.env -f infrastructure/compose.yaml logs api
    docker compose --env-file infrastructure/.env -f infrastructure/compose.yaml stop

Stopping retains database data. Do not remove volumes or run migration:revert against an existing user database casually. Auto-backup scheduling and restore verification remain unimplemented.

## Flutter
    cd myhome_flutter
    flutter pub get
    flutter run -d chrome --web-port 8080

Current defaults (guide 46): Web uses same-origin /api/v1; native apps use the stable HTTPS Worker API. For an emulator-only local main API explicitly pass --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1. Physical phones cannot reach the PC through their own localhost or the emulator alias.
For another target:
    flutter run --dart-define=API_BASE_URL=https://your-api.example/api/v1

10.0.2.2 only maps the Android emulator's host; a physical phone needs a reachable host address and explicit network binding. Compose intentionally binds ports to host loopback. Release clients should use HTTPS. Local Android debug HTTP is enabled only in the debug manifest; release uses the platform network policy.
Web secure storage requires HTTPS or localhost. Native Keychain/Keystore behavior still needs device QA even when host tests pass.

## Run backend directly
    cd backend
    npm.cmd ci
    Copy-Item .env.example .env
Replace DATABASE_URL with the myhome application-role URL using the password from infrastructure/.env, and set JWT_SECRET to the same secret used by Docker if the clients must share sessions.
Do not use the sample password as real configuration.
For the initial migration, use the database administrator connection temporarily:
    npm.cmd run migration:run
Then run the API with the application role:
    npm.cmd run build
    npm.cmd start

The Docker path handles this privilege split automatically. synchronize is disabled. TypeORM is the only implemented ORM; there is no Prisma schema/client.

## Tests
From backend/:
    npm.cmd test
    npm.cmd run build
    npm.cmd audit --omit=dev
Default API tests use pg-mem with the real migrations, validation, guards, hashing and token code.

For PostgreSQL integration, create the isolated database once from the workspace root:
    docker compose --env-file infrastructure/.env -f infrastructure/compose.yaml exec -T postgres createdb -U postgres myhome_test

Then from backend/ in PowerShell:
    $myhomeSecrets = Get-Content ../infrastructure/.env -Raw | ConvertFrom-StringData
    $env:TEST_DATABASE_URL = 'postgresql://postgres:' + $myhomeSecrets.POSTGRES_PASSWORD + '@localhost:55432/myhome_test'
    npm.cmd test
    Remove-Item Env:TEST_DATABASE_URL

The test suite refuses any database path except /myhome_test and removes only users created with its own random run prefix.

From myhome_flutter/:
    flutter analyze --no-pub
    flutter test --no-pub
    flutter build web --no-pub
    flutter build apk --debug --no-pub

Opt-in live Flutter-to-API test (API must already be running):
    flutter test test/live_api_auth.dart --no-pub
This creates one identifiable local test account with a flutter-live- prefix and revokes its session. It is excluded from the default *_test.dart suite.

Rendered design previews (local Windows utility):
    flutter test test/render_previews.dart --no-pub --update-goldens
PNG output is placed in artifacts/ at the workspace root.

## API contract
| Method | Path (prefix /api/v1) | Behavior |
|---|---|---|
| POST | /auth/register | name/email/password/role; returns tokens and public user; rejects extra fields and admin role |
| POST | /auth/login | email/password; returns session |
| POST | /auth/refresh | refreshToken; rotates the token once; does not extend the original seven-day lifetime |
| GET | /auth/profile | Bearer access token; returns public user only |
| POST | /auth/logout | Bearer access token; returns 204 and immediately revokes its session |
| GET | /health | Database query and status |

Access tokens last 15 minutes and require issuer/audience/signature/expiry validation plus an active database session/user. Refresh tokens are opaque random credentials; only SHA-256 hashes are stored in PostgreSQL. Flutter persists only the refresh token using flutter_secure_storage and keeps access tokens in memory.
Production horizontal scaling needs shared rate-limit storage; the current in-memory limiter is intended for this single-instance setup. Expired-session cleanup, browser HttpOnly-cookie authentication, mail delivery, owner review/audit, backups and deployment hardening are separate pending tasks.
