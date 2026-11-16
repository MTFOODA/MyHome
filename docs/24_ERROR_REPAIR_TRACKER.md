## Addresses, illustrated details and owner engagement - 2026-11-16

[x] Area source footer removed from selection and credited in About with license/source links.

[x] Optional location description replaced by mandatory street/building/floor/unit and complete preview.

[x] Public-facing details no longer dump the financial ledger or stacked fact rows; final price/actions and uniform picture cards are used.

[x] My properties opens rows directly, retains three-row remote loading and marks pending/closed cards gray.

[x] Owner-only unique visitor/save counts and current-saver messaging added with participant authorization.

Validation and build/runtime limits are recorded in guide42.

Read [guide 42](42_ADDRESS_PROPERTY_DETAILS_AND_OWNER_ENGAGEMENT.md). Previous entries remain historical.

---

## Picture choices and furnishing search - 2026-11-16

[x] Furnishing filter missing: added conditional All/Furnished/Unfurnished options and boolean API query.

[x] Blanket image removal: restored distinct transparent pictures selectively and retained familiar tool icons.

[x] Checkbox/radio ornament beside selected cards: removed; shared card background/border now communicates selection with accessibility semantics.

[x] Narrow picture cards: stack artwork/text when the inner width is small. Financial approval remains explicit and revocable before submission.

Read [guide 41](41_PICTURE_SELECTION_AND_FURNISHING_FILTER.md). Previous entries are preserved as history.

---

## Responsive layout and meaningful icons - 2026-11-16

[x] Manual title/description section removed from listing information.

[x] Repeated white-backed image substitutions removed; property choices use distinct symbols and controls use familiar native glyphs.

[x] Narrow fixed form widths and small actions replaced by shared responsive dimensions; actions stack on narrow screens.

[x] Language control identifies translation and target language; drawer/header accommodate larger text.

Verification: 87 Flutter tests, 4 render scenarios and clean analyzer. Owner-list test now settles scroll-triggered list layout before interacting; hide/search behavior is preserved.

Read [guide 40](40_RESPONSIVE_LAYOUT_AND_ICONS.md). Earlier entries below are historical.

---

## Visual listing, complete source catalogue and open maps - 2026-11-15

The current increment is documented in [guide 39](39_VISUAL_LISTING_AND_OPEN_MAPS.md): owner drawer Add property, precise Continue validation, generated title/description from illustrated choices, net/gross area, capacity only in shared housing, utilities in one step, conditional furnishing, and authenticated owner covers before approval. Backgrounds follow `UI/ui .jpeg` in the existing teal light/dark palette; authored icons use bundled raster artwork.

FlutterMap/OpenStreetMap replaces the proposed Google integration: tap and drag a pin, explicit device permission, independent bounded latitude/longitude persistence, pasted-link parsing without geocoding, protected details/current-results discovery maps, visible attribution and tile-offline fallback. No paid map API/key/billing. Source and attribution can change through API environment config. The public OSM tile service has usage limits; caching/UA/Referer and zero pan prefetch are configured.

Migration head: `20261116_listing_details`; main/demo backups retained before additive migration. Pinned CC BY 4.0 data adds 6,081 districts/shiyakhas across all 27 governorates and retains every old project area ID. No reset/reseed, no assumed net/gross or furnishing values for old listings. Unknown informal/development names remain describable with a landmark/pin.

Verified: **78 Flutter tests, 80 PostgreSQL tests, 11 Worker tests and 8 render tests**; analyzer/Ruff clean. Web release/Android debug and local main/demo API deployment; public Worker HTTP smoke evidence is kept in ignored artifacts. Calls/matching and production banking remain pending. Windows/iOS native builds, physical GPS and browser GUI tests are not claimed. The stable Worker URL still requires the PC/Docker/internet online. Earlier reports below remain historical.

---

## Current onboarding, final-step calculator and stable Worker gateway - 2026-11-15

This verified increment supersedes earlier onboarding fee-placement and temporary-link-only instructions; historical reports remain below. First login uses owner/seeker families with explicit subtypes and multiple intents. Pricing and commission details appear only in the final listing pricing step, with easy rental duration selection and an automatic server-calculated all-in quote. Existing fixed-reference money rules and backend role enforcement are preserved; no database/schema migration was added.

The existing `myhome` Cloudflare Worker is deployed at **https://myhome.mohamed-fooda-mtf.workers.dev** as a stable gateway for local demo Web/API services. Keep the PC, Docker and internet running. `Deploy_Cloudflare.cmd` publishes it; normal `Start_MyHome.cmd` reconnects automatically after first setup, retains data and can recover an expired temporary tunnel. PostgreSQL/main API remain private. Node.js 22.12+ and authorized Wrangler login are needed for publishing.

Verified: **58 Flutter tests, 66 real PostgreSQL API tests, 11 Worker tests**, 4 new onboarding/calculator render tests, analyzer/Ruff clean, Web release and Android debug builds. Actual deployed Worker checks passed for the latest Web bundle, auth/logout, permissions, text/group messaging, owner pagination, favorites, and five financial quote cases. Private paths return 404; responses are uncached. Repeated CMD startup reused the healthy deployment and stable URL. No browser GUI/physical-device/iOS build claim; calls/matching/production banking and full marketplace completion remain pending.

Read [onboarding/calculator implementation](37_ONBOARDING_AND_PRICE_CALCULATOR.md) and [Worker operation, evidence and rollback](38_CLOUDFLARE_WORKER.md). Migration head remains `20261115_communications`. Private accounts, tokens, Worker backup and deployment/runtime evidence stay under ignored local paths.

---

## One-click demo startup and HTTPS sharing - 2026-11-15

Implemented `Start_MyHome.cmd` and `Stop_MyHome.cmd`, backed by `tools/run_myhome.ps1`, optional Caddy/cloudflared Docker services and same-origin Web API configuration. The default launcher starts PostgreSQL and the isolated demo, builds/caches Web and prints a public HTTPS mobile/test link. `-Android` builds an APK for that link; `-Local` disables sharing. Daily startup seeds only if empty and preserves edits/preferences. Stopping sharing preserves the database and the main API.

Verified: actual CMD start/stop/restart, Web release/Android debug builds, cached repeated launch with changed account preference retained, 46 Flutter tests and analyzer clean; public HTTPS HTTP login/chat/permission/pricing/logout smoke and private-path 404 checks. Browser GUI/physical-phone testing is not claimed. Read [the launcher guide and limits](36_ONE_CLICK_DEMO.md). Previous reports remain as history; no whole marketplace phase is declared complete.

---

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

# Current repair tracker — 2026-11-14
<!-- CURRENT_AUDIT_2026_11_14 -->

| ID | Repair | Verification | Status |
|---|---|---|---|
| BACK-201 | Active NestJS backend replaced by requested FastAPI; old source preserved | Docker healthy, /health identifies fastapi, live Flutter contract | VERIFIED |
| DB-201 | Additive adoption of old auth schema and new structured marketplace tables | Alembic on legacy application DB and isolated test DB; old rows retained | VERIFIED |
| DB-202 | Location IDs exceeded original starter length | 32-character governorate keys and complete 27-governorate seed | VERIFIED |
| NET-201 | localhost/IPv6 delayed host psycopg connections | 127.0.0.1 + explicit five-second connection timeout | VERIFIED |
| AUTH-201 | Single role could not represent owner/student and multiple needs | Normalized intents, independent persona, editable active mode | VERIFIED |
| UI-201 | App originally forced authentication before showing homes | Public root, top login CTA, gated protected actions | VERIFIED |
| AUTH-202 | Roommate tab previously visible for all | Current active-mode UI and independent backend policy tests | VERIFIED |
| DATA-201 | Out-of-order search responses could replace newer filters | Request-generation check in DiscoveryBloc | VERIFIED |
| PROP-201 | Mandatory booleans could be implicit defaults | All Yes/No start unset, strict boolean API validation | VERIFIED |
| SEC-201 | Identity docs must not become listing photos | Separate encrypted private storage, owner/admin guard, audit, no-store | VERIFIED |
| GROUP-201 | Last available bed and co-admin eligibility | Real PostgreSQL row-lock concurrency tests and accepted tenancy requirement | VERIFIED |
| OCR-201 | OCR unavailable on host | Tesseract eng+ara in Docker, successful synthetic comparison; manual review fallback | VERIFIED (limited scope) |
| QA-201 | Dark hero used pale primary with white text | Fixed dark teal hero; theme-aware surfaces; visual rerender | VERIFIED |
| CHAT/VOICE | Encryption and call transports | No implementation; no plaintext substitute | TODO |
| IOS-201 | iOS release/build/runtime QA | Requires macOS/Xcode | TODO |

---

## Historical repair trackers — superseded

# MyHome — Current repair tracker
<!-- CURRENT_AUDIT_2026_11_09 -->
Updated: 2026-11-09. Historical reports are retained below.

| ID | Issue | Repair | Verification | Current status |
|---|---|---|---|---|
| BUILD-101 | Empty Flutter manifest and invalid localization resources | Valid pubspec/ARB/l10n configuration | Dependency resolution, localization generation, analyze, tests, Web/Android build | VERIFIED |
| DART-101 | Broken imports, localization extension and GetIt registration | Correct paths, generated localization, DI and Cubits | Analyzer + 15 tests | VERIFIED |
| TS-101 | Invalid package manifest and incomplete authentication | Proper JSON/scripts/dependencies, rebuilt auth module/strategies/service/DTOs | npm run build + 16 scenarios | VERIFIED |
| DB-101 | Invalid timestamp and destructive auto-sync design | Explicit PostgreSQL users/session migration, constraints/indexes | Isolated PostgreSQL tests + Docker migration | VERIFIED |
| AUTH-101 | Arbitrary role/verification escalation | Server whitelist, forbidden extra fields, current database user checks | Role/flag/disabled-user/guard API tests | VERIFIED |
| AUTH-102 | Non-revocable refresh/access design | Hashed opaque refresh, CAS rotation, active DB sessions and logout | Concurrency/replay/logout/expiry tests | VERIFIED |
| BUILD-102 | Host DB port 5432 unavailable | Configurable loopback port, default 55432 | Healthy Postgres container + integration tests | VERIFIED |
| BUILD-103 | Kotlin C:/D: incremental cache failure | kotlin.incremental=false for this project | Android debug APK built | VERIFIED |
| SEC-101 | Vulnerable production transitive dependencies | Scoped multer/glob overrides | Production audit 0 findings; PostgreSQL/Docker rerun | VERIFIED |
| BUILD-104 | Windows plugin symlink setup | Windows Developer Mode still required | pub get diagnostic; desktop build not verified | OPEN |
| TEST-101 | Native secure storage/runtime platforms | Runners/entitlements exist; device tests remain | No native runtime claim | TODO |
| INFRA-102 | Automatic backups/isolated restore | No implementation yet | None | TODO |

Original TS-001/002 and BUILD-001..004 terminal-availability blockers are superseded: npm.cmd, TypeScript, Flutter analysis/tests and native Android/Web builds now execute successfully. A full dependency audit still reports seven low-severity development-tool findings; production dependencies report none at this date.

---

## Historical repair tracker — superseded

# Error Repair Tracker

## Dart Errors

| ID | File | Line | Error Message | Root Cause | Affected Feature | Severity | Repair Action | Verification Command | Final Status |
|----|------|------|---------------|------------|------------------|----------|-------------|----------------------|--------------|
| DART-001 | lib/core/di/locator.dart | N/A | Missing file | Project recovery operation | Navigation | CRITICAL | Created locator.dart with GetIt import and setupLocator function | dart analyze lib/core/di/locator.dart | FIXED |
| DART-002 | lib/core/di/injection_container.dart | N/A | Missing file | Project recovery operation | Dependency Injection | CRITICAL | Created injection_container.dart with setupGetIt function | dart analyze lib/core/di/injection_container.dart | FIXED |
| DART-003 | lib/core/config/theme_config.dart | N/A | Missing file | Project recovery operation | theming | CRITICAL | Created theme_config.dart with light/dark theme methods | dart analyze lib/core/config/theme_config.dart | FIXED |
| DART-004 | lib/core/config/locale_config.dart | N/A | Missing file | Project recovery operation | Localization | CRITICAL | Created locale_config.dart with Arabic/English locale methods | dart analyze lib/core/config/locale_config.dart | FIXED |
| DART-005 | lib/app/app.dart | N/A | Missing file | Project recovery operation | App initialization | CRITICAL | Created app.dart with MaterialApp configuration including localization delegates | dart analyze lib/app/app.dart | FIXED |
| DART-006 | lib/localizations/app_en.arb | N/A | Missing file | Project recovery operation | Localization | CRITICAL | Created app_en.arb with basic localization keys | dart analyze lib/localizations/app_en.arb | FIXED |
| DART-007 | lib/localizations/app_ar.arb | N/A | Missing file | Project recovery operation | Localization | CRITICAL | Created app_ar.arb with basic localization keys | dart analyze lib/localizations/app_ar.arb | FIXED |

## TypeScript Errors

| ID | File | Line | Error Message | Root Cause | Affected Feature | Severity | Repair Action | Verification Command | Final Status |
|----|------|------|---------------|------------|------------------|----------|-------------|----------------------|--------------|
| TS-001 | backend/src/auth/jwt.strategy.ts | 11 | `this.validate = this.validate;` | Redundant self-assignment | Authentication | HIGH | Remove redundant self-assignment line | tsc verify | BLOCKED |
| TS-002 | backend/src/... | N/A | Cannot verify | npm not installed | All backend features | CRITICAL | Install npm dependencies | npm install | BLOCKED |

## Build Errors

| ID | Component | Error | Root Cause | Severity | Status |
|----|-----------|-------|------------|----------|--------|
| BUILD-001 | Flutter | Cannot run flutter pub get | Terminal environment limitation | CRITICAL | BLOCKED |
| BUILD-002 | Flutter | Cannot run flutter analyze | Terminal environment limitation | CRITICAL | BLOCKED |
| BUILD-003 | Backend | Cannot run npm install | PowerShell script execution policy | CRITICAL | BLOCKED |
| BUILD-004 | Backend | Cannot run npm test | Missing node_modules | CRITICAL | BLOCKED |

## Status Legend
- TODO: Task not started
- IN PROGRESS: Task in progress
- FIXED: Error has been repaired
- VERIFIED: Repair confirmed by analyzer/compiler
- BLOCKED: Error cannot be fixed due to environmental limitations