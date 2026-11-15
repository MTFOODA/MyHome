## One-click demo startup and HTTPS sharing - 2026-11-15

Implemented `Start_MyHome.cmd` and `Stop_MyHome.cmd`, backed by `tools/run_myhome.ps1`, optional Caddy/cloudflared Docker services and same-origin Web API configuration. The default launcher starts PostgreSQL and the isolated demo, builds/caches Web and prints a public HTTPS mobile/test link. `-Android` builds an APK for that link; `-Local` disables sharing. Daily startup seeds only if empty and preserves edits/preferences. Stopping sharing preserves the database and the main API.

Verified: actual CMD start/stop/restart, Web release/Android debug builds, cached repeated launch with changed account preference retained, 46 Flutter tests and analyzer clean; public HTTPS HTTP login/chat/permission/pricing/logout smoke and private-path 404 checks. Browser GUI/physical-phone testing is not claimed. Read [the launcher guide and limits](36_ONE_CLICK_DEMO.md). Previous reports remain as history; no whole marketplace phase is declared complete.

---

## Approved all-in pricing, supervised deals and moderated chat - 2026-11-15

This section supersedes the preview-only and E2EE-message statements below, retained as history. The owner approved fixed original-price fees split equally, server-inspected text encrypted at rest, and mandatory legal eligibility for old rent. Read [the current implementation and operating guide](35_ALL_IN_SUPERVISED_DEALS.md).

Verified: 56 real PostgreSQL tests, 43 Flutter tests, 6 preview-render tests; analyzer/Ruff clean; Web and Android debug builds passed. Main/demo additive migrations applied after a private DB backup, both APIs healthy. Isolated demo: 10 accounts, 13 listings, one shared group, an open deal and two encrypted conversations; actual restricted-role HTTP smoke passed. iOS requires macOS. No full marketplace phase is declared complete.

Calls, roommate matching and production banking/signature integrations remain pending. Explicit consent is recorded, not a certified signature. Operators supply reviewed terms, qualified staff and the real InstaPay QR through admin UI. The server can inspect messages; this is not E2EE.

---

| Check | 2026-11-15 result |
|---|---|
| Backend/PostgreSQL | PASS: 56 tests, artifacts/all-in-backend-tests.log |
| Flutter | PASS: 43 tests, artifacts/all-in-flutter-tests.log |
| Ruff / Flutter analyzer | PASS, app/tests/migrations and lib/test |
| Rendered previews | PASS: 6 tests; actual AR/EN light/dark screenshots inspected |
| Web | PASS: artifacts/all-in-web-build.log |
| Android debug | PASS: artifacts/all-in-apk-build.log |
| Main/runtime | Backup retained; additive migration head 20261115_communications; API healthy |
| Demo/runtime | PASS: 10 accounts, 13 listings, one group/two conversations; artifacts/all-in-demo-runtime.json |
| iOS/desktop release builds | Not run on Windows; existing platform runners retained |

Non-fatal toolchain notices: Starlette TestClient/httpx deprecation, existing Web Wasm dry-run/plugin notices and unused Cupertino font-family notice. Standard JS Web and Android builds succeed. No automatic bank integration or certified e-signature is claimed.

## Owner portfolio, lifecycle and demo - 2026-11-14

| Check | Latest result |
|---|---|
| PostgreSQL suite | PASS: 25 tests, `artifacts/portfolio-api-final.log` |
| Ruff | PASS: app/tests/migrations |
| Flutter suite | PASS: 33 tests, `artifacts/portfolio-flutter-tests-final.log` |
| Analyzer | PASS: `artifacts/portfolio-analyze-final.log` |
| Visual previews | PASS: AR/EN owner dashboards/lists, `docs/screenshots/owner-*.png` |
| Web | PASS: `artifacts/portfolio-web.log`, build/web |
| Android debug | PASS: `artifacts/portfolio-apk.log`, build/app/outputs/flutter-apk/app-debug.apk |
| Application migration/runtime | Additive portfolio migration applied; volumes and existing data retained |
| Demo seed | PASS: 8 users, 13 properties, 3-member shared group; `artifacts/demo-scenario-results.json` |
| Docker demo runtime | PASS: restricted-role API health/login/3+2 pages/favorite states/group isolation/logout |
| Chat/calls | NOT IMPLEMENTED; no conversation test or E2EE claim |
| iOS | Not built on Windows |

Non-failing existing Starlette TestClient deprecation and Web CupertinoIcons font diagnostics remain as previously recorded. No production payment/settlement system is claimed by commission previews.

Current increment: grouped owner counts; remote quick search; exactly 3 listings per cursor page; pause/restore; sold/rented history; safe saved-property status cards; own-photo access and group membership list. Pricing proposal is configurable, preview-only and disabled pending approval. See [owner/demo guide](33_OWNER_PORTFOLIO_AND_DEMO.md) and [fee proposal](34_COMMISSION_PROPOSAL.md).

Verified: 33 Flutter tests, analyzer clean; 25 real PostgreSQL tests, Ruff clean; Web/Android debug builds. Separate myhome_demo fixtures: 8 accounts, 13 listings, one owner/two-tenant group and private random credentials. Actual Docker runtime smoke passed. E2EE communication/calls and real conversations remain unimplemented; membership metadata is not chat.

---

## Selected logo applied - 2026-11-14

| Check | Result |
|---|---|
| Flutter analyzer | PASS: no issues, `artifacts/analyze-logo.log` |
| Flutter tests | PASS: 28 tests, `artifacts/tests-logo.log` |
| Visual QA | PASS: home, drawer, login, registration and dark-login AR/EN previews; `artifacts/previews-logo-final.log` and `docs/screenshots/` |
| Native asset validation | PASS: 45 icon entries, correct sizes, opaque RGB Apple icons, valid Windows ICO frames and Android/iOS XML |
| Android debug build | PASS: `artifacts/apk-logo.log`, APK at `myhome_flutter/build/app/outputs/flutter-apk/app-debug.apk` |
| Web final build | PASS: `artifacts/web-logo-final.log`; output contains selected brand assets, favicon/PWA icons and updated browser metadata |
| iOS/macOS/Windows runtime/build | Not run for this branding increment; assets validated structurally only |

The API/database are unchanged by this increment; earlier PostgreSQL test evidence remains applicable to the unchanged backend.

The owner selected proposal 02 (Arabic architectural wordmark). It is installed in the home header/drawer, authentication and About screens, Android/iOS launch assets, Web/PWA and Android/iOS/macOS/Windows icons. Earlier statements that selection is pending are historical. See [selected-logo implementation](32_SELECTED_LOGO.md) and [brand masters/prompts](../design/branding/README.md).

---

## Branding/search/cleanup update - 2026-11-14

| Latest check | Result |
|---|---|
| Flutter unit/widget suite | PASS: 28 tests, `artifacts/tests-branding.log` |
| Analyzer | PASS: no issues, `artifacts/analyze-branding-final.log` |
| PostgreSQL API tests | PASS: 19 tests, includes text search/literal wildcard cases |
| Web build | PASS: `build/web`, `artifacts/web-branding.log` |
| Android debug build | PASS: `build/app/outputs/flutter-apk/app-debug.apk`, `artifacts/apk-branding.log` |
| AR/EN light/dark previews | PASS: rendered and reviewed, `docs/screenshots/` |
| Docker health | PASS: FastAPI and PostgreSQL healthy after API rebuild |
| Native labels | Android XML and iOS plist/Xcode reference checks pass; no iOS build on Windows |
| Publication scan | 270 source/reference files, no actual local secrets, tokens, private keys or private runtime paths |

Web build emitted a non-failing missing CupertinoIcons font diagnostic despite no direct CupertinoIcons use in app source; MaterialIcons rendering was verified in previews. One Starlette TestClient deprecation warning remains in API tests. Neither is reported as a failed build.

Product: بيتي / MyHome. The old NestJS backend was removed after migration and explicit user authorization. Search now follows the supplied capsule/filter-panel reference and supports server-side text queries. Four logo proposals await selection. See [increment details](31_BRANDING_CLEANUP_AND_SEARCH.md) and [logo options](../design/branding/README.md).

Flutter: 28 tests passed; analyzer clean. FastAPI: 19 PostgreSQL tests passed; Ruff clean. AR/EN light/dark screenshots are in docs/screenshots/. iOS localized labels were checked structurally, not built on Windows. E2EE, calls and roommate matching remain pending.

---

# Verified results — 2026-11-14
<!-- CURRENT_AUDIT_2026_11_14 -->
Current API is FastAPI. Historical NestJS results below are retained but do not describe the running backend.

| Check | Result / scope |
|---|---|
| Python/FastAPI | Python 3.11.9; FastAPI 0.162.7, SQLAlchemy 2.0.57, Alembic 1.20.1 installed in project .venv |
| Ruff + compilation | PASS: app/tests/migrations lint and Python compile check |
| FastAPI pytest | PASS: 19 scenarios against real isolated PostgreSQL myhome_fastapi_test |
| Existing DB adoption | PASS: original 1 user and 1 session preserved immediately after migration; 27 governorates seeded |
| Private media | Fernet encryption, UUID filenames, JPEG re-encoding/EXIF stripping, owner/admin access and no-store responses implemented |
| Real OCR | PASS: Tesseract eng+ara in Docker matched a synthetic ID-number image; not a real ID accuracy/authenticity/face test |
| Runtime Docker | PASS: FastAPI + PostgreSQL healthy, migration job exits successfully, /health reports backend=fastapi |
| Flutter tests | PASS: 25 repository/Cubit/BLoC/widget scenarios |
| Flutter live API contract | PASS: register/refresh/profile/logout against current FastAPI; native storage plugin mocked by host test |
| Flutter analyze | PASS: no issues |
| Web build | PASS: final build/web generated |
| Android build | PASS: final debug APK generated; Kotlin cross-drive workaround retained |
| iOS | Configured only; macOS/Xcode build and device QA pending |
| Visual previews | Rendered AR/EN home/login/register/roles/listing and dark home; reviewed from artifacts/20261114-*.png |

## FastAPI test coverage
Public home/health, protected details/favorites, forbidden admin/verification fields, normalized credentials, login/rotation/replay/logout, multiple intent selection, current mode enforcement, mandatory utilities/finishing/location fields, installment arithmetic, shared bed constraints, owner-only creation, private-document access, submit/review/publication, API favorites, object ownership, image validation, ID/date check, Arabic OCR digit comparison, location seeds, expired/tampered tokens, suspended accounts, rate limiting and password-free validation errors.
Concurrency tests verify one winner for two refreshes and one winner for two last-bed acceptances. Group metadata rejects a non-tenant co-admin and rejects creation after owner role removal.
Tests use actual PostgreSQL row locks and Alembic migrations; no SQLite substitute.

## Flutter test coverage
6 auth repository tests, 4 AuthCubit tests, 1 stale-response DiscoveryBloc test, 6 listing validation/retry tests, 8 widget/responsive cases.
Home is public at launch, protected taps open authentication before repository calls, roles are selected after registration, switching away from shared mode removes roommate navigation, Arabic RTL and dark settings work at 320/768/1440px.
Exact minor-unit installment arithmetic, explicit unselected Yes/No values, ID/date match, Arabic/Persian digits, mandatory steps, clearing private buffers and reuse of the same failed draft are covered.
Preview property records exist in test fakes only and are not inserted into the application database.

## Outputs
- myhome_flutter/build/app/outputs/flutter-apk/app-debug.apk
- myhome_flutter/build/web/
- artifacts/web-20261114-final.log
- artifacts/apk-20261114-final.log
- artifacts/fastapi-up-final.log
- artifacts/20261114-home-ar.png and other preview PNGs
- artifacts/myhome-before-fastapi-20261114.dump (private, ignored, pre-migration backup)

## Known verification limits
- One Starlette TestClient httpx deprecation warning remains; API tests pass. No production security conclusion is inferred from it.
- OCR engine availability/one synthetic match does not establish fraud detection, biometric identity verification or real-card OCR accuracy.
- No E2EE, voice-call, full roommate search or native Keychain/Keystore device result is claimed.
- No iOS build on this Windows host, release signing, automated scheduled backups or restore drill is claimed.
- Private media and DOCUMENT_KEY must be retained together. Document expiry, orphan cleanup and operational retention policies remain pending.
- Earlier npm production audit results apply to legacy NestJS only; no current FastAPI dependency security audit is claimed.

---

## Historical build/test reports — superseded

# MyHome — Verified build and test results
<!-- CURRENT_AUDIT_2026_11_09 -->
Verified: 2026-11-09 (Africa/Cairo). This section supersedes earlier statements that tools were unavailable.

| Check | Result | Evidence/scope |
|---|---|---|
| Flutter SDK | PASS | Flutter 3.47.7, Dart 3.13.5 |
| npm/Node | PASS | Node 24.20.0, npm 11.19.0; npm.cmd works on Windows |
| flutter pub get | PARTIAL operational result | Dependencies/lock/localization generated; desktop symlink setup requests Windows Developer Mode |
| flutter analyze --no-pub | PASS | No issues found |
| flutter test --no-pub | PASS | 15 tests: 4 Cubit, 6 API repository, 5 widget/responsive scenarios |
| Flutter rendered previews | PASS | 2 explicit rendering scenarios, eight PNGs in artifacts/ |
| Flutter live API test | PASS | Real Docker API: registration, restart/restore, token rotation, profile, logout; host secure-storage plugin mocked |
| npm.cmd run build | PASS | TypeScript compiles into backend/dist/ |
| npm.cmd test (default pg-mem) | PASS | 16 API/authorization scenarios with real migrations and actual hashing/JWT code |
| npm.cmd test (TEST_DATABASE_URL) | PASS | Same 16 scenarios against PostgreSQL 17 in isolated myhome_test, rerun after dependency fixes |
| Docker build/up | PASS | Multi-stage Node image; migration job succeeds; API/PostgreSQL both healthy |
| GET /api/v1/health | PASS | {"status":"ok"}, includes database query |
| npm.cmd audit --omit=dev | PASS at verification time | 0 known vulnerabilities after scoped transitive overrides |
| Full dependency audit | Follow-up | 7 low severity dev-tool findings; dev packages excluded from production image |

## Backend coverage
Registration validation/normalization/hash/public DTO; invalid and admin roles; forged verification/status fields; short and >72 UTF-8 byte passwords; duplicate email; login and incorrect passwords; missing/tampered/expired/refresh-as-access tokens; refresh rotation and replay; concurrent refresh CAS; logout revocation and independent sessions; regular/unverified owner restrictions; current database role/verification changes; disabled user and expired session; authentication rate limiting.

Publishing/admin checks use test-only protected controllers. Production property/admin modules remain absent, so these tests verify the reusable guards, not finished publishing/admin workflows.
PostgreSQL integration executes the migration; rollback/restore testing is still pending.

## Flutter coverage and visual QA
- Required fields and confirmation prevent invalid submissions.
- Selected registration role reaches the repository; admin is absent from onboarding.
- Login switches to home; account exposes verification-needed state; logout returns to login.
- Restore failures preserve the stored credential on network errors; rejected sessions are cleared.
- Profile refresh retries once after a 401; logout revokes before clearing storage.
- Arabic RTL/navigation/dark mode at 320, 768 and 1440 logical pixels.
- Rendered English/Arabic login, registration, home and guest account reviewed; test previews explicitly load text/icon fonts.
- Secure Keychain/Keystore itself is not exercised by host-side mocked plugin tests.

## Platform matrix
| Platform | Result | Remaining |
|---|---|---|
| Web | Built | Browser end-to-end/accessibility/production hosting QA |
| Android | Debug APK built | Device install/run, release signing, native secure-storage QA |
| Windows | Runner generated | Enable Developer Mode for plugin symlinks, then native build/run |
| iOS | Runner + entitlements configured | macOS/Xcode build, signing and device tests |
| macOS | Runner + keychain/client-network entitlements configured | macOS build and runtime QA |
| Linux | Runner generated | Linux toolchain/libsecret/keyring build and runtime QA |

Outputs: myhome_flutter/build/web/ and myhome_flutter/build/app/outputs/flutter-apk/app-debug.apk.
Android's first build failed because Kotlin incremental caches cannot relativize plugin sources on C: against the D: workspace. Project kotlin.incremental=false fixed the build; the successful retry completed in 82 seconds. See artifacts/flutter-build-apk.log.
Default port 5432 could not be bound; project Compose now defaults to loopback 55432.

## Dependency remediation
NestJS 11 / TypeORM 0.3 were retained instead of an untested major framework upgrade. Scoped overrides use multer >=2.5.0 under platform-express and glob >=14.0.4 under TypeORM. Real PostgreSQL/API tests and Docker migrations pass with the overrides.
References: [Multer advisory](https://github.com/advisories/GHSA-q7qp-rjg7-q26m), [Glob advisory](https://github.com/advisories/GHSA-3g3m-2fjr-6pw4), [Minimatch advisory](https://github.com/advisories/GHSA-g3hv-75wg-m249).
Kotlin option reference: [Compilation and caches](https://kotlinlang.org/docs/gradle-compilation-and-caches.html).

---

## Historical results — unverified claims retained for traceability

# Build & Test Results

## Flutter Build Analysis

### flutter pub get
- Status: CONFIGURATION COMPLETE - pubspec.yaml verified with correct dependencies
- Dependencies: flutter sdk, cupertino_icons, provider (removed - not used by feature pages), get_it, intl, dio, shared_preferences, json_serializable, equatable, flutter_lints, build_runner
- Note: flutter_gen_flutter removed (invalid package), flutter_localizations added, generate: true flag added
- Verification: pubspec.yaml syntax validated; actual command execution blocked by terminal environment

### flutter analyze
- Status: PENDING - Cannot verify in current terminal environment
- Previous runs: 177 issues (mostly Flutter SDK package resolution limitations)
- Project files verified for syntax correctness: all 15 Dart source files
- Dependency configuration: validated (pubspec.yaml changes confirmed via editor)

### flutter test
- Status: NO TEST DIRECTORY - test/ folder does not exist
- Action needed: Create test directory and test files

### dart format
- Status: PENDING - Will verify after full SDK setup

## Backend Build Analysis

### npm run build
- Status: BLOCKED - npm not installed due to script execution policy
- Expected: Compiled JavaScript output in lib/ directory
- Current: TypeScript source files are syntactically valid

### npm test
- Status: BLOCKED - node_modules not installed
- Expected: Passing unit and integration tests
- Current: No test infrastructure available

### npm run test:e2e
- Status: BLOCKED - No e2e test configuration
- Expected: End-to-end tests running against backend API
- Current: No test infrastructure available

### TypeScript Compilation
- Status: PENDING - Cannot verify without tsc
- Expected: No errors using project's tsconfig.json
- Current: All inspected .ts files have valid syntax

## Database Verification

### TypeORM Configuration
- Status: PENDING - Cannot verify without npm/build
- Expected: Valid database configuration with PostgreSQL
- Current: database.config.ts and user.entity.ts have valid syntax

### Migrations
- Status: UNKNOWN - No migration files inspected
- Expected: Consistent migration history
- Current: Not verifiable

## Authorization Tests

### JWT Guard
- Status: CODE REVIEW - Guard implementation visible
- Expected: Valid JWT validation preventing unauthenticated access
- Current: auth.guard.ts implements CanActivate with token validation

### Role Authorization
- Status: PENDING - Cannot verify without backend runtime
- Expected: Role-based access control enforced
- Current: User entity has role field, but authorization logic needs verification

## Platform Builds

### Android
- Status: UNKNOWN - Cannot build without flutter tools
- Expected: Successful APK generation
- Current: Flutter SDK available but cannot build

### Web
- Status: UNKNOWN - Cannot build without flutter tools
- Expected: Successful web deployment
- Current: Flutter SDK available but cannot build

### Windows
- Status: UNKNOWN - Cannot build without flutter tools
- Expected: Successful Windows executable
- Current: Flutter SDK available but cannot build

### iOS
- status: UNKNOWN - Cannot build on Windows platform
- Expected: Successful iOS IPA generation
- Current: Operating system limitation

### macOS
- status: UNKNOWN - Cannot build on Windows platform
- Expected: Successful macOS app bundle
- Current: Operating system limitation

### Linux
- status: UNKNOWN - Cannot build on Windows platform
- Expected: Successful Linux deployment
- Current: Operating system limitation
