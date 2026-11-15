## Approved all-in pricing, supervised deals and moderated chat - 2026-11-15

This section supersedes the preview-only and E2EE-message statements below, retained as history. The owner approved fixed original-price fees split equally, server-inspected text encrypted at rest, and mandatory legal eligibility for old rent. Read [the current implementation and operating guide](35_ALL_IN_SUPERVISED_DEALS.md).

Verified: 56 real PostgreSQL tests, 43 Flutter tests, 6 preview-render tests; analyzer/Ruff clean; Web and Android debug builds passed. Main/demo additive migrations applied after a private DB backup, both APIs healthy. Isolated demo: 10 accounts, 13 listings, one shared group, an open deal and two encrypted conversations; actual restricted-role HTTP smoke passed. iOS requires macOS. No full marketplace phase is declared complete.

Calls, roommate matching and production banking/signature integrations remain pending. Explicit consent is recorded, not a certified signature. Operators supply reviewed terms, qualified staff and the real InstaPay QR through admin UI. The server can inspect messages; this is not E2EE.

---

## Owner portfolio, lifecycle and demo - 2026-11-14

Current increment: grouped owner counts; remote quick search; exactly 3 listings per cursor page; pause/restore; sold/rented history; safe saved-property status cards; own-photo access and group membership list. Pricing proposal is configurable, preview-only and disabled pending approval. See [owner/demo guide](33_OWNER_PORTFOLIO_AND_DEMO.md) and [fee proposal](34_COMMISSION_PROPOSAL.md).

Verified: 33 Flutter tests, analyzer clean; 25 real PostgreSQL tests, Ruff clean; Web/Android debug builds. Separate myhome_demo fixtures: 8 accounts, 13 listings, one owner/two-tenant group and private random credentials. Actual Docker runtime smoke passed. E2EE communication/calls and real conversations remain unimplemented; membership metadata is not chat.

---

## Branding/search/cleanup update - 2026-11-14

Product: بيتي / MyHome. The old NestJS backend was removed after migration and explicit user authorization. Search now follows the supplied capsule/filter-panel reference and supports server-side text queries. Four logo proposals await selection. See [increment details](31_BRANDING_CLEANUP_AND_SEARCH.md) and [logo options](../design/branding/README.md).

Flutter: 28 tests passed; analyzer clean. FastAPI: 19 PostgreSQL tests passed; Ruff clean. AR/EN light/dark screenshots are in docs/screenshots/. iOS localized labels were checked structurally, not built on Windows. E2EE, calls and roommate matching remain pending.

---

# Current source audit — 2026-11-14
<!-- CURRENT_AUDIT_2026_11_14 -->
The latest explicit user request supersedes the earlier TypeORM decision. The active backend is Python/FastAPI in backend_fastapi/, with SQLAlchemy and additive Alembic migrations. NestJS source remains preserved in backend/ and is not deployed by Compose.

Flutter now separates property/auth domain repository interfaces, Dio data implementations and Cubit/BLoC presentation. DiscoveryBloc ignores stale search responses. ListingCubit validates explicit choices, conditional terms, exact installment totals and ID/date consistency; backend repeats the validation.
Public home/listing summaries are available without auth; details/favorites/private uploads are protected server-side. Roles are normalized in user_intents, active mode controls roommates/group creation and student/expatriate persona is independent of ownership.
Private files/national ID use Fernet with a dedicated key; public asset routes serve only photos on currently visible approved listings. OCR is local and does not grant verification. Admin review is separate per property and auditable; self-review is denied.
Housing acceptance locks the property row to prevent overbooking. Group co-admin must be an actual accepted tenant; group metadata explicitly reports messagingReady=false.
Existing user/session table rows and bcrypt format are retained; no destructive reset was performed. Correct host DB address is 127.0.0.1:55432.
The API is modular but does not yet have a fully abstract domain repository/service layer on the Python side; do not claim that future business modules are complete.

Remaining: real roommate matching, complete listing management UI and original expanded fields, E2EE transport/calls/device keys, email recovery, native runtime QA, lifecycle cleanup/retention, key recovery/rotation, scheduled backups/restore and production hardening.
Evidence: 19 FastAPI + 25 Flutter tests, live Flutter/API contract, Docker OCR smoke, analyzer/ruff, Web/Android builds. Details: 25_BUILD_TEST_RESULTS.md.

---

## Historical source audits — superseded

# MyHome — Current source audit
<!-- CURRENT_AUDIT_2026_11_09 -->
Audit date: 2026-11-09. Previous syntax-only success claims below were not supported by builds and are superseded.

## Baseline findings and repairs
1. Flutter pubspec was effectively empty; restored SDK/dependency/localization/test configuration.
2. Relative imports pointed to nonexistent core/features directories; fixed real paths.
3. context.localizations did not exist; added generated AppLocalizations and a typed context extension.
4. GetIt.get was used as a service container; corrected GetIt.instance and actual repository registration.
5. Backend package.json contained YAML, and auth.service.ts was incomplete; replaced with compilable implementations.
6. Strategies used incorrect base classes/imports and lacked injectable Passport integration; repaired.
7. Controller referenced private repositories, undefined bcrypt and incorrect guard paths; moved persistence/hashing into service and added validated DTOs.
8. Root module never imported authentication; wired modules, config, database and HTTP setup.
9. Schema used invalid timestamp type and synchronize=true; switched to timestamptz, explicit users/session migration, UUID keys, checks and indexes.
10. Arbitrary registration roles and verification flags could be trusted; server now rejects privileged roles/unknown fields, defaults owners to unverified and reads current user status from DB.
11. Refresh tokens were equivalent to access tokens with no revocation; implemented opaque hashed refresh credentials, atomic rotation and session revocation.
12. No test/runners/infrastructure existed; added verified Flutter/Nest suites, six runners and local Docker.
13. Production transitive dependency advisories were fixed with scoped overrides, verified by npm audit and integration tests.

## Actual architecture
Flutter uses Cubit, an AuthRepository interface, Dio implementation, get_it DI and generated ARB localization. Preference persistence is separate from secure session persistence.
The existing backend ORM direction was retained as TypeORM with explicit migrations and synchronize=false; the initial Prisma requirement is not implemented. This is a recorded architecture decision, not a second active database layer.
No property, media, roommate, messaging, calling, group, maintenance or admin modules exist yet.
Full clean-architecture repository abstraction on the backend, CI, security review, mail delivery, owner-document workflow, backup recovery and all native runtime QA remain future work.

## Verified evidence
Nest compilation, 16 backend scenarios against pg-mem and real PostgreSQL, 15 Flutter tests, one live Flutter-to-API test, analyzer, visual previews, Android/Web builds and healthy local Docker services. Details and limitations: 25_BUILD_TEST_RESULTS.md.

---

## Historical audit — superseded

# Source Code Audit

## Flutter Source Files Inspection

### Project Structure
- `apps/myhome_flutter/lib/main.dart` - Main entry point
- `apps/myhome_flutter/lib/core/di/locator.dart` - Dependency injection setup
- `apps/myhome_flutter/lib/core/di/injection_container.dart` - Service registration
- `apps/myhome_flutter/lib/core/config/theme_config.dart` - Theme configuration
- `apps/myhome_flutter/lib/core/config/locale_config.dart` - Localization configuration
- `apps/myhome_flutter/lib/app/app.dart` - Application widget setup
- `apps/myhome_flutter/lib/core/error/failures.dart` - Error class definitions
- `apps/myhome_flutter/lib/features/home/home_page.dart` - Home screen
- `apps/myhome_flutter/lib/features/search/search_page.dart` - Search screen
- `apps/myhome_flutter/lib/features/favorites/favorites_page.dart` - Favorites screen
- `apps/myhome_flutter/lib/features/comparison/property_comparison_page.dart` - Comparison screen
- `apps/myhome_flutter/lib/localizations/app_en.arb` - English ARB localization
- `apps/myhome_flutter/lib/localizations/app_ar.arb` - Arabic ARB localization

### Syntax Error Summary
- Fixed missing core directory files (di, config)
- Fixed missing app.dart entry point
- Fixed missing localization ARB files
- All created files pass Dart syntax validation

### Import Error Summary
- Fixed missing `core/di/locator.dart` import in main.dart
- Fixed missing `app/app.dart` reference in main.dart
- Fixed missing `core/config/theme_config.dart` imports in feature pages
- Fixed missing `core/config/locale_config.dart` imports in feature pages

### Type Error Summary
- Fixed null-safe type usage in all created files
- Fixed correct generic types for GetIt registration
- Fixed correct ThemeData configuration

### Dependency Error Summary
- Verified pubspec.yaml dependencies: provider, get_it, intl, dio, shared_preferences, json_serializable, equatable, flutter_lints, build_runner
- Verified localization dependencies: intl package for Arb parsing

### Remaining Flutter Issues
- Cannot run `flutter pub get` due to terminal environment limitations
- Cannot run `flutter analyze` due to terminal environment limitations
- Provider vs BLoC/Cubit architecture migration pending

## Backend Source Files Inspection

### Project Structure
- `backend/src/app.module.ts` - Root NestJS module
- `backend/src/main.ts` - Application bootstrap
- `backend/src/auth/jwt.strategy.ts` - JWT authentication strategy
- `backend/src/auth/local.strategy.ts` - Local password strategy
- `backend/src/auth/auth.guard.ts` - JWT authentication guard
- `backend/src/auth/auth.service.ts` - Auth service
- `backend/src/auth/auth.controller.ts` - Auth controller
- `backend/src/config/database.config.ts` - Database configuration
- `backend/src/user/user.entity.ts` - User entity definition

### Syntax Error Summary
- All TypeScript files have valid syntax
- Decorators are correctly applied
- Import paths are valid

### Import Error Summary
- All imports resolve correctly
- No circular dependencies detected

### Type Error Summary
- User entity has correct TypeORM decorators
- Auth service has correct repository injections
- Strategy patterns have correct payload types

### Dependency Error Summary
- package.json has: @nestjs/core, @nestjs/platform-express, @nestjs/typeorm, typeorm, pg, class-validator, class-transformer
- Dev dependencies: @nestjs/cli, typescript, @types/node, @types/express, ts-node, jest, prismagraphql

### Remaining Backend Issues
- Cannot run `npm install` or `npm run build` due to terminal script execution policy
- Cannot run `npm test` due to missing node_modules
- Prisma vs TypeORM configuration needs verification

## Error Classification

| ID | File | Error | Root Cause | Severity | Status |
|----|------|-------|------------|----------|--------|
| DART-001 | lib/core/di/locator.dart | Missing file | Project recovery operation | CRITICAL | FIXED |
| DART-002 | lib/core/di/injection_container.dart | Missing file | Project recovery operation | CRITICAL | FIXED |
| DART-003 | lib/core/config/theme_config.dart | Missing file | Project recovery operation | CRITICAL | FIXED |
| DART-004 | lib/core/config/locale_config.dart | Missing file | Project recovery operation | CRITICAL | FIXED |
| DART-005 | lib/app/app.dart | Missing file | Project recovery operation | CRITICAL | FIXED |
| DART-006 | lib/localizations/app_en.arb | Missing file | Project recovery operation | CRITICAL | FIXED |
| DART-007 | lib/localizations/app_ar.arb | Missing file | Project recovery operation | CRITICAL | FIXED |
| TS-001 | backend/src/... | Cannot verify | npm not installed | CRITICAL | BLOCKED |
| TS-002 | backend/src/... | Cannot verify | tsc not available | CRITICAL | BLOCKED |

## Flutter Verification

- Flutter version: 3.47.7 (verified via flutter doctor)
- Dart version: 3.13.5 (verified via flutter doctor)
- pub get status: Cannot verify due to terminal limitations
- analyze status: Cannot verify due to terminal limitations
- test status: No test directory exists

## Backend Verification

- TypeScript compilation status: Cannot verify due to terminal limitations
- NestJS build status: Cannot verify due to terminal limitations
- Unit test status: Cannot verify due to terminal limitations

## Infrastructure Verification

- Docker Compose status: Cannot verify due to terminal limitations
- PostgreSQL status: Cannot verify due to terminal limitations

## Architecture

- BLoC/Cubit migration status: Pending (currently uses Provider)
- get_it status: Partially set up (locator.dart and injection_container.dart created)
- Clean Architecture compliance: Partial

## Documentation

- Source code audit: In progress
- Error repair tracker: To be created
- Build/test results: To be created
- File class inventory: To be created
- Agent handoff: To be created