## Identity validation and Home corrections - 2026-11-16

New `core/input/egyptian_identity.dart`, `test/identity_refinement_test.dart`, `test/render_identity_refinement.dart`, `backend_fastapi/tests/test_identity_scan.py` and `assets/illustrations/ultra-finish-v1.png` with prompt/provenance. Existing navigation/discovery, listing quantity/address/verification, repositories and backend assets/router safeguards extended. No new table, migration or duplicated OCR dependency. See [guide 44](44_IDENTITY_VALIDATION_AND_HOME_REFINEMENTS.md).

---

## Responsive property and messaging experience - 2026-11-16

New Flutter widgets: `property_gallery.dart`, `property_features_grid.dart`, `similar_properties.dart`, `listing_optional_features.dart`, `conversation_list.dart`; formatter `core/config/price_text.dart`. Existing repositories/Cubits/details/chat/cards extended. New backend migrations `20261116_optional_features.py` and `20261116_finish_options.py`, regression `tests/test_optional_features.py`. Flutter regressions `property_experience_test.dart` and `render_property_experience.dart`, with existing owner/filter/address tests extended. API metadata, inbox preview and similar-property queries reuse existing authorization and summaries. See [guide 43](43_PROPERTY_EXPERIENCE_AND_OPTIONAL_FEATURES.md).

---

## Addresses, illustrated details and owner engagement - 2026-11-16

New: backend `listing_address.py`, `PropertyVisit`, structured Property columns and property/seeker Conversation target; migration `20261116_address_engagement.py`; tests `test_address_engagement.py`. Flutter adds `structured_address.dart`, `property_facts_grid.dart`, `contact_pages.dart` (ContactsCubit/page), `address_details_test.dart`, `render_address_details.dart` and `assets/illustrations/property-facts-v3.png`. Repository interfaces carry interested/inbox/property-conversation operations; existing chat/owner Cubits are extended. Full source/provenance details in guide42 and design/illustrations/PROPERTY_FACTS_V3.md.

Read [guide 42](42_ADDRESS_PROPERTY_DETAILS_AND_OWNER_ENGAGEMENT.md). Previous entries remain historical.

---

## Picture choices and furnishing search - 2026-11-16

New: `core/widgets/choice_artwork.dart` and `selection_tile.dart`; bundled `assets/illustrations/choice-atlas-v2.png`; `test/selection_tile_test.dart`; `test/render_picture_choices.dart`; artwork prompt in `design/illustrations/CHOICE_ARTWORK_V2.md`. Updated discovery route accepts nullable `furnished` boolean; six real PostgreSQL filter regressions added. Listing/onboarding/deal consent cards reuse one component and keep existing state management.

Read [guide 41](41_PICTURE_SELECTION_AND_FURNISHING_FILTER.md). Previous entries are preserved as history.

---

## Responsive layout and meaningful icons - 2026-11-16

New shared presentation components: `core/widgets/app_layout.dart` (`AppLayout`, `AppScaffold`) and `core/widgets/app_icon.dart` (`AppIcon`, `ColorSymbol`, `FeatureSymbol`). The obsolete `property_illustration.dart` is removed. `test/responsive_layout_test.dart` adds 10 behavior/layout checks; `test/render_responsive_layout.dart` renders four platform-size scenarios. Atlases are archived under `design/illustrations/masters/`, outside Flutter assets. No domain/repository/API duplication or schema changes.

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

Current added files: `listing_pricing_step.dart` owns conditional final-step inputs; `price_calculator_result.dart` formats server money/percentages; `test_calculator.py` checks reference bases; `onboarding_pricing_test.dart` checks role/calculator behavior; `pricing_test_data.dart` provides synthetic fixtures; `render_onboarding_pricing.dart` writes screenshots. `infrastructure/cloudflare/src/worker.js` is the gateway, `test/worker.test.js` its contract tests, `scripts/wrangler-network.mjs` a CLI-only bounded TLS connection helper. `publish_cloudflare.ps1` verifies the target account, preserves version inventory, publishes, checks health and caches state; `Deploy_Cloudflare.cmd` delegates to the shared launcher. Documentation 37/38 describes both increments.

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

## Selected logo applied - 2026-11-14

The owner selected proposal 02 (Arabic architectural wordmark). It is installed in the home header/drawer, authentication and About screens, Android/iOS launch assets, Web/PWA and Android/iOS/macOS/Windows icons. Earlier statements that selection is pending are historical. See [selected-logo implementation](32_SELECTED_LOGO.md) and [brand masters/prompts](../design/branding/README.md).

---

## Branding/search/cleanup update - 2026-11-14

Product: بيتي / MyHome. The old NestJS backend was removed after migration and explicit user authorization. Search now follows the supplied capsule/filter-panel reference and supports server-side text queries. Four logo proposals await selection. See [increment details](31_BRANDING_CLEANUP_AND_SEARCH.md) and [logo options](../design/branding/README.md).

Flutter: 28 tests passed; analyzer clean. FastAPI: 19 PostgreSQL tests passed; Ruff clean. AR/EN light/dark screenshots are in docs/screenshots/. iOS localized labels were checked structurally, not built on Windows. E2EE, calls and roommate matching remain pending.

---

# Current file inventory — 2026-11-14
<!-- CURRENT_AUDIT_2026_11_14 -->

| Path | Responsibility |
|---|---|
| backend_fastapi/app/main.py | Factory, HTTP guards, bounded single-instance rate limiter, CORS, health and route composition |
| app/config.py, database.py | Validated environment, dedicated document key, request DB sessions and connection timeouts |
| app/models.py | Users/sessions/intents/persona, locations, properties/assets/verifications/favorites, applications/tenancies/groups and audit |
| app/schemas.py | Strict input contracts and category-dependent validations |
| app/security.py, auth.py, policy.py | JWT/bcrypt/sessions, refresh locks/rotation, public DTO, roles and active mode |
| app/properties.py | Database discovery, draft/update/photos/submit/details/favorites and admin review |
| app/assets.py | Validated bounded image upload, recompression, encryption, OCR/date comparison, protected file reads |
| app/groups.py | Shared seeker policy, applications, atomic acceptance and eligible group metadata |
| app/admin_cli.py | Explicit local operator promotion; no seeded admin credentials |
| app/seed_locations.py | Curated 27-governorate starter catalog with a subset of areas |
| backend_fastapi/migrations/ | Frozen adoption SQL + additive housing/audit and persona migrations |
| backend_fastapi/tests/ | 19 PostgreSQL API/security/concurrency scenarios |
| myhome_flutter/lib/app/app.dart | Public home root, first-login onboarding and sign-in navigation helper |
| lib/features/auth/domain/, data/, presentation/ | Account multi-intent contract, secure API adapter, AuthCubit and login/onboarding |
| lib/features/properties/domain/property_repository.dart | Typed summaries, location catalog, uploads and repository contract |
| lib/features/properties/data/api_property_repository.dart | Public/authorized API operations; protected binary document reads |
| lib/features/properties/presentation/discovery_bloc.dart | Search request ordering and loading/result/error states |
| lib/features/properties/presentation/discovery_page.dart | Public capsule search, quick categories, applied filters and pagination |
| lib/features/properties/presentation/property_filters_sheet.dart | Isolated filter draft, sort/type pills, collapsible sections, numeric validation and sticky apply |
| lib/features/properties/presentation/listing_cubit.dart, listing_page.dart | Conditional wizard, mandatory answers, exact totals, media/proofs and retry-safe same-draft submission |
| lib/features/properties/presentation/property_card.dart, property_details_page.dart | Summary cards, protected details/gallery and shared-housing requests |
| lib/features/properties/presentation/property_list_page.dart | Server favorites and owner listing states |
| lib/features/properties/presentation/admin_review_page.dart | Private document review and approve/correct decisions |
| lib/features/properties/presentation/housing_group_page.dart | Owner applications and accepted tenant co-admin selection |
| lib/features/home/home_page.dart | Role-aware tabs/drawer, protected actions and owner/admin entry points |
| lib/features/search/search_page.dart | Shared-only authorized empty roommate placeholder; no matching engine |
| lib/core/config/marketplace_strings.dart | Paired AR/EN marketplace labels alongside original generated ARB localization |
| lib/core/input/number_input.dart | Arabic/Persian input digit normalization |
| myhome_flutter/test/ | 25 standard tests, explicit live API test and explicit preview renderer |
| infrastructure/compose.yaml | Active FastAPI migration/API, PostgreSQL and persistent private media |

Legacy backend/ NestJS and the earlier inventory remain below for history. The original simple favorites/comparison page classes remain preserved; active favorites navigation now uses the server-backed PropertyListPage.

---

## Historical inventories — superseded

# MyHome — Current implementation inventory
<!-- CURRENT_AUDIT_2026_11_09 -->
Updated: 2026-11-09. All current Flutter paths start at myhome_flutter/; the old apps/myhome_flutter/ paths below are historical.

| Path | Main types/responsibility |
|---|---|
| myhome_flutter/lib/main.dart | Await DI, initialize Flutter and start MyHome |
| lib/app/app.dart | MyHome providers, MaterialApp and session/guest gate |
| lib/core/di/locator.dart | Dio/auth repository/preferences registration |
| lib/core/config/api_config.dart | Platform defaults and API_BASE_URL override |
| lib/core/config/settings_cubit.dart | AppSettings, SettingsCubit, persisted locale/theme |
| lib/core/config/theme_config.dart | ThemeConfig; petroleum header and light/dark tokens |
| lib/core/config/locale_config.dart | LocaleConfig and localized context extension |
| lib/features/auth/domain/auth_repository.dart | Account, AuthRepository, typed AuthException/failures |
| lib/features/auth/data/api_auth_repository.dart | Dio API calls, secure token rotation/restoration/logout |
| lib/features/auth/presentation/auth_cubit.dart | AuthState/AuthStatus and workflow state |
| lib/features/auth/presentation/auth_page.dart | Reference-inspired login/registration, role choice, validation |
| lib/features/home/home_page.dart | HomePage navigation/drawer, category overview and EmptyHomes |
| lib/features/profile/profile_page.dart | Public account, verification status, refresh/logout/preferences |
| lib/features/search/search_page.dart | Empty presentation shell; no search implementation |
| lib/features/favorites/favorites_page.dart | Empty presentation shell; no persistence |
| lib/features/comparison/property_comparison_page.dart | Empty comparison presentation shell |
| lib/features/support/info_page.dart | Localized introductory guide/about |
| lib/localizations/app_*.arb | Paired translations; app_localizations*.dart generated |
| myhome_flutter/test/*_test.dart | 15 Cubit/repository/widget scenarios |
| myhome_flutter/test/live_api_auth.dart | Explicit live Docker API contract test |
| myhome_flutter/test/render_previews.dart | Explicit local Windows screenshot renderer |
| backend/src/main.ts, app.module.ts | Bootstrap, module integration, throttling and DB health |
| backend/src/config/ | HTTP setup, strict environment validation, TypeORM options and CLI source |
| backend/src/user/user.entity.ts | User/UserRole and publicUser projection |
| backend/src/auth/auth.dto.ts | LoginDto/RegisterDto/RefreshDto validation and role whitelist |
| backend/src/auth/auth.service.ts | Credentials, registration, token issue/rotation, session revocation |
| backend/src/auth/auth.controller.ts | Version-prefixed auth endpoint handlers |
| backend/src/auth/session.entity.ts | Indexed, expiring/revocable AuthSession |
| backend/src/auth/*.strategy.ts | Injectable Passport local/JWT strategies |
| backend/src/auth/auth.guard.ts, roles.guard.ts | JWT, role and verified-owner guards |
| backend/src/auth/auth.module.ts | Auth DI, Passport/JWT and entity wiring |
| backend/src/migrations/1794182400000-initial-auth.ts | Explicit normalized users/session schema |
| backend/test/auth.spec.ts | 16 API/security scenarios, pg-mem or isolated PostgreSQL |
| backend/Dockerfile | Non-root multi-stage runtime image |
| infrastructure/compose.yaml, init-db.sh | PostgreSQL, privilege setup, migrations and healthy API |
| myhome_flutter/{android,ios,web,windows,macos,linux}/ | Generated platform runners; all not runtime verified |

No property entity/module/form/media service, message/group/call implementation or admin dashboard exists. Full future scope is registered in 03_FEATURE_REGISTRY.md.

---

## Historical inventory — superseded

## Flutter Source Files

### main.dart
- **Path**: `apps/myhome_flutter/lib/main.dart`
- **Responsibilities**: App entry point
- **Dependencies**: provider, get_it, locator, app.dart
- **Status**: Partially implemented

### home_page.dart
- **Path**: `apps/myhome_flutter/lib/features/home/home_page.dart`
- **Responsibilities**: Home screen with localized text, bottom navigation bar
- **Dependencies**: theme_config.dart, locale_config.dart, failures.dart
- **Status**: Implemented

### search_page.dart
- **Path**: `apps/myhome_flutter/lib/features/search/search_page.dart`
- **Responsibilities**: Search screen with advanced filter UI
- **Dependencies**: theme_config.dart, locale_config.dart, failures.dart
- **Status**: Implemented

### favorites_page.dart
- **Path**: `apps/myhome_flutter/lib/features/favorites/favorites_page.dart`
- **Responsibilities**: Favorites management screen
- **Dependencies**: theme_config.dart, locale_config.dart, failures.dart
- **Status**: Implemented

### property_comparison_page.dart
- **Path**: `apps/myhome_flutter/lib/features/comparison/property_comparison_page.dart`
- **Responsibilities**: Property comparison view
- **Dependencies**: theme_config.dart, locale_config.dart, failures.dart
- **Status**: Implemented

## Localization Files

### app_en.arb
- **Path**: `apps/myhome_flutter/lib/localizations/app_en.arb`
- **Responsibilities**: English localization arb file
- **Related Features**: English language UI support
- **Status**: Created

### app_ar.arb
- **Path**: `apps/myhome_flutter/lib/localizations/app_ar.arb`
- **Responsibilities**: Arabic localization arb file
- **Related Features**: Arabic language UI support, RTL layout
- **Status**: Created
## Backend Source Files

### app.module.ts
- **Path**: `backend/src/app.module.ts`
- **Class**: AppModule
- **Responsibilities**: Root NestJS module, TypeOrm configuration, CORS, port 3000
- **Dependencies**: @nestjs/core, @nestjs/typeorm, @nestjs/config
- **Status**: Initialized

### main.ts
- **Path**: `backend/src/main.ts`
- **Responsibilities**: NestJS bootstrap, CORS enabling, port 3000 listening
- **Dependencies**: reflect-metadata, @nestjs/core, app.module
- **Status**: Initialized

### auth.service.ts
- **Path**: `backend/src/auth/auth.service.ts`
- **Class**: AuthService
- **Responsibilities**: Login, register, validateUser, JWT token generation, bcrypt password hashing
- **Dependencies**: @nestjs/common, @nestjs/jwt, @nestjs/typeorm, typeorm, bcrypt, user.entity
- **Status**: Initialized

### user.entity.ts
- **Path**: `backend/src/user/user.entity.ts`
- **Class**: User
- **Responsibilities**: TypeORM entity, user relationships, property ownership
- **Dependencies**: typeorm (Entity, PrimaryGeneratedColumn, Column, Unique)
- **Status**: Initialized

### jwt.strategy.ts
- **Path**: `backend/src/auth/jwt.strategy.ts`
- **Class**: JwtStrategy
- **Responsibilities**: JWT token validation, payload extraction and validation
- **Dependencies**: @nestjs/jwt, @nestjs/config, user.entity
- **Status**: Initialized

### local.strategy.ts
- **Path**: `backend/src/auth/local.strategy.ts`
- **Class**: LocalStrategy
- **Responsibilities**: Passport-local strategy for email/password authentication
- **Dependencies**: passport-local, @nestjs/passport, auth.service, user.entity
- **Status**: Initialized

### auth.guard.ts
- **Path**: `backend/src/auth/auth.guard.ts`
- **Class**: JwtAuthGuard
- **Responsibilities**: JWT authentication guard, token validation, request user assignment
- **Dependencies**: @nestjs/common, auth.service
- **Status**: Initialized

### auth.controller.ts
- **Path**: `backend/src/auth/auth.controller.ts`
- **Class**: AuthController
- **Responsibilities**: Login, register, profile endpoints
- **Dependencies**: @nestjs/common, auth.service, auth.strategies, user.entity
- **Status**: Initialized
