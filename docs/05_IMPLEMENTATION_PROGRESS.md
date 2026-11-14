## Selected logo applied - 2026-11-14

- [x] BRAND-002: Install user-selected logo 02 in Flutter branding and platform icon/launch assets.
<!-- DONE: BRAND-002 | Files: core/widgets/brand_logo.dart, assets/branding/, platform icon/launch resources, design/branding/selected/, tools/generate_brand_icons.ps1 | Tests: 28 Flutter tests, analyzer clean, AR/EN light/dark previews, 45 icon-entry structural/dimension checks, Android debug build | Verified: 2026-11-14 -->

The owner selected proposal 02 (Arabic architectural wordmark). It is installed in the home header/drawer, authentication and About screens, Android/iOS launch assets, Web/PWA and Android/iOS/macOS/Windows icons. Earlier statements that selection is pending are historical. See [selected-logo implementation](32_SELECTED_LOGO.md) and [brand masters/prompts](../design/branding/README.md).

---

## Branding/search/cleanup update - 2026-11-14

- [x] SEARCH-202: Reference-based discovery and deferred filter sheet; server-side text search with literal wildcard escaping.
<!-- DONE: SEARCH-202 | Files: discovery_page.dart, property_filters_sheet.dart, properties.py | Tests: 28 Flutter tests, 19 PostgreSQL tests, analyzer/ruff, AR/EN light/dark visual review, Web/Android builds | Verified: 2026-11-14 -->
- [x] BRAND-001: بيتي/MyHome localized app names, four numbered logo proposals awaiting selection, authorized legacy/unused cleanup and current README.
<!-- DONE: BRAND-001 | Files: localizations, Android strings, iOS InfoPlist.strings/project, design/branding/, README.md, .gitignore | Tests: XML/plist/reference structural checks, Web/Android builds, staged secret exclusion | Verified: 2026-11-14 -->

Product: بيتي / MyHome. The old NestJS backend was removed after migration and explicit user authorization. Search now follows the supplied capsule/filter-panel reference and supports server-side text queries. Four logo proposals await selection. See [increment details](31_BRANDING_CLEANUP_AND_SEARCH.md) and [logo options](../design/branding/README.md).

Flutter: 28 tests passed; analyzer clean. FastAPI: 19 PostgreSQL tests passed; Ruff clean. AR/EN light/dark screenshots are in docs/screenshots/. iOS localized labels were checked structurally, not built on Windows. E2EE, calls and roommate matching remain pending.

---

# Current implementation — 2026-11-14
<!-- CURRENT_AUDIT_2026_11_14 -->
This section supersedes previous status/technology claims, which remain below as history. Latest product requirements: 29_PRODUCT_REQUIREMENTS_2026_11_14.md.

## Active stack and phase
Flutter Clean Architecture boundaries with Cubit/BLoC, Python FastAPI in backend_fastapi/, SQLAlchemy/Alembic, local PostgreSQL and Docker. The old NestJS backend/ was removed after migration; historical documents remain.
Phases 1/2/3/4 are partially implemented; Phase 5 has an initial housing-application/group-permission slice. No full phase or full marketplace is declared complete.

| Area | Current verified implementation | Remaining |
|---|---|---|
| Public browsing | Home opens directly for guests; approved listings, database filtering/pagination, public photo cards | Full browsing/device accessibility QA and larger location catalog |
| Protected actions | Detail/favorite endpoints require valid sessions; sign-in CTA and client navigation gate | Comprehensive release authorization audit |
| Multiple roles | Normalized intents, independent student/expatriate persona, active mode chosen after first login and editable in settings | Complete role lifecycle notifications |
| Conditional roommate tab | Visible only in active tenant_shared mode; server endpoint independently enforces it | Actual opt-in profiles, preferences, matching/search |
| Property creation | Conditional stepper, mandatory explicit Yes/No answers, structured locations, area/price/rental/installment/bed checks, image order/cover, private proofs | Remaining expanded fields from earlier requirements, edit/resume/delete UI lifecycle |
| Documents/review | Private encrypted files and national ID, ID/date check, Tesseract OCR, admin-only manual review with reason and audit, separate listing approval | Real consented ID accuracy/authenticity evaluation, retention, key recovery/rotation |
| Shared applications | Owner acceptance, transactional last-bed protection, accepted tenant eligibility for group co-admin | Full application lifecycle/rejection/removal/billing |
| Group metadata | Verified active shared owner + actual accepted tenant required; role/mode removal revokes create permission | Encrypted group transport and complete membership/key lifecycle |
| Localization/motion | AR/EN, RTL, Arabic/Persian numeral normalization, light/dark/system, reduced-motion-aware transitions | Full device/accessibility/text-scale QA |
| Communication | No plaintext transport introduced | All E2EE messaging, calling and notifications remain TODO |
| Operations | Existing users/sessions preserved by Alembic adoption, pre-migration DB dump, healthy non-root FastAPI and PostgreSQL containers | Scheduled backups including media and keys, restore drills, production setup |

## Scoped verified increments
- [x] BACK-201: Replace active API with FastAPI and adopt existing users/auth_sessions without dropping rows; use dedicated migration connection and restricted runtime.
<!-- DONE: BACK-201 | Files: backend_fastapi/, infrastructure/compose.yaml | Tests: Alembic PostgreSQL migration, 19 API/security scenarios, healthy Docker, live Flutter/API test | Verified: 2026-11-14 -->
- [x] AUTH-201: Multiple-intent onboarding and active-mode enforcement.
<!-- DONE: AUTH-201 | Files: backend_fastapi/app/auth.py, policy.py, myhome_flutter/lib/features/auth/ | Tests: API role/mode tests, conditional-tab widget test | Verified: 2026-11-14 -->
- [x] SEARCH-201: Public home with server-side property discovery; gated details and persisted favorites.
<!-- DONE: SEARCH-201 | Files: backend_fastapi/app/properties.py, myhome_flutter/lib/features/properties/ | Tests: API review/search/favorites scenario, guest widget gates, stale-response BLoC test, rendered AR/EN UI | Verified: 2026-11-14 -->
- [-] PROP-201: Latest-request listing/verification workflow implemented and tested; expanded original property registry remains partial.
- [-] GROUP-201: Application acceptance and group authorization metadata implemented; messagingReady=false.
- [ ] CHAT/VOICE: Audited E2EE library/protocol, device key lifecycle, message transport and calling are unimplemented.

## Evidence
28 Flutter tests, 19 FastAPI tests on real isolated PostgreSQL, one live Flutter/API test, real Tesseract synthetic-image comparison, analyzer/ruff, Web and Android debug builds passed. iOS is configured but not built on this Windows host.
Local API is now FastAPI, not NestJS. See 25_BUILD_TEST_RESULTS.md and 30_FASTAPI_LOCAL_SETUP.md.

---

## Historical progress — superseded

# MyHome — Audited implementation progress
<!-- CURRENT_AUDIT_2026_11_09 -->
Updated: 2026-11-09. This section is authoritative. Older entries below are retained as historical, unverified reports.

## Current phase: Phase 1 foundation and Phase 2 authentication
Do not advance the project to Phase 3 complete: there is no property module or property creation form.

| Work area | UI | State/data | Backend | Database | Security | Localization | Tests | Platform builds |
|---|---|---|---|---|---|---|---|---|
| Registration and login | Implemented, visually reviewed | Cubit + repository + DI | Implemented | Users migration verified | Role whitelist, hashing, validation, throttling | AR/EN | Passing | Web + Android debug built; other native platforms unverified |
| Session restore/profile/logout | Implemented | Secure refresh persistence, retry and revocation | Implemented | Sessions and indexes verified | Expiry, rotation/CAS, active-user/session checks | AR/EN | Passing, including live Flutter-to-API | Native secure-storage runtime QA pending |
| Owner permissions | Verification status displayed | Public user DTO only | Guards available | Default unverified + constraint | Forged flags/admin role rejected; guards tested on test-only routes | AR/EN | Passing | No publishing feature exists |
| Preferences/navigation | Implemented | SettingsCubit + persisted language/theme | Not applicable | Not applicable | No role authorization is delegated to Flutter | AR/EN, RTL | 320/768/1440px tests | Web + Android compiled |
| Home/discovery/favorites/comparison | Home shell and empty presentation states | Property data integration absent | Absent | Absent | Pending | AR/EN shells | Navigation only | Feature NOT complete |
| Guide/about | Introductory content | Static | Not applicable | Not applicable | No fabricated team or statistics | AR/EN | Navigation/visual review | Full Phase 7 pending |

## Verified task increments
- [x] FOUND-001: Recover manifests, imports, localization generation, runners, theme and dependency injection; compile Flutter Web/Android and NestJS.
<!-- DONE: FOUND-001 | Files: myhome_flutter/pubspec.yaml, myhome_flutter/lib/core/, myhome_flutter/lib/app/, backend/package.json, backend/tsconfig.json | Tests: flutter analyze, flutter test, flutter build web, flutter build apk --debug, npm run build | Verified: 2026-11-09 -->
- [x] AUTH-101: Implement backend registration/login/profile/refresh/logout, role validation and reusable authorization guards.
<!-- DONE: AUTH-101 | Files: backend/src/auth/, backend/src/user/, backend/src/migrations/ | Tests: 16 API scenarios on pg-mem and PostgreSQL, successful Docker migration and health, live Flutter repository test | Verified: 2026-11-09 -->
- [x] AUTH-102: Implement current Flutter authentication screens/repository/Cubit, saved-session restoration, inline error/loading states and guest navigation.
<!-- DONE: AUTH-102 | Files: myhome_flutter/lib/features/auth/, myhome_flutter/lib/app/app.dart, myhome_flutter/test/ | Tests: 15 Flutter tests, 1 live API test, AR/EN rendered previews, analyzer | Verified: 2026-11-09 -->
- [x] INFRA-001: Local PostgreSQL + migration job + non-root API containers with non-superuser application database role, persistent volume and health checks.
<!-- DONE: INFRA-001 | Files: infrastructure/compose.yaml, infrastructure/init-db.sh, backend/Dockerfile | Tests: Docker build/up, successful migration, healthy services, /api/v1/health, live registration/profile/logout | Verified: 2026-11-09 -->

These scoped increments do not mean all AUTH-001..007 requirements, all native platforms, Phase 1, or Phase 2 are complete.

## Next required work
- [ ] AUTH-004 / AUTH-005: Email verification and password recovery with actual delivery, hashed expiring single-use challenges and anti-enumeration tests.
- [ ] PROF-001: Editable profile, avatar/location/contact policy and server validation.
- [ ] AUTH-007: Private owner verification documents, submission/review workflow, audit records and approval/revocation enforcement.
- [ ] INFRA-002: Scheduled 05:00 Africa/Cairo backups, isolated restore drill and recovery documentation.
- [ ] Native runtime validation for Android/iOS/macOS/Windows/Linux; Windows Developer Mode and platform toolchains as required.
- [ ] Phase 3 property schema/CRUD/mandatory wizard/media/installments/shared rentals, then Phase 4 real search/discovery.

## Current evidence
15 Flutter tests + 16 backend scenarios (both emulated and real PostgreSQL) + 1 live Flutter/API test pass. UI previews rendered in artifacts/. See 25_BUILD_TEST_RESULTS.md and 28_LOCAL_DEVELOPMENT.md.
The correct app path is myhome_flutter/. No Git repository existed at the root. TypeORM is the only implemented ORM; Prisma remains a superseded initial technology plan.

---

## Historical progress entries — superseded by the audit above

# MyHome - Implementation Progress

## Current Phase: Phase 3 - Property Management

### Documentation Status
- 00_MASTER_PLAN.md: Created and populated
- 01_PROJECT_REQUIREMENTS.md: Created and populated
- 02_PROJECT_ARCHITECTURE.md: Created and populated
- 03_FEATURE_REGISTRY.md: Created and populated
- 04_IMPLEMENTATION_ROADMAP.md: Created and populated
- AGENTS.md: Created in project root
- 14_AGENT_HANDOFF.md: In progress

### Flutter Status
- Project initialized: myhome_flutter (Flutter 3.47.7, Dart 3.13.5)
- Project located at: D:\MTFOODA\Code\Flutter apps\MyHome\myhome_flutter
- Pubspec.yaml: Configured with all required dependencies
- main.dart: Created with provider and locator setup
- Design System: Fully integrated with deep teal identity color, typography, spacing
- Authentication: Login, registration, and onboarding screens complete
- Property creation form: 7-step multi-step form implemented
- Property media upload: Photo selection and compression working
- Search and filters: Advanced filterable search with PostgreSQL backend
- Property details screen: Complete with all property sections
- Favorites: Save and manage property favorites
- Localization: Arabic and English switching with RTL/LTR support
- Platform builds: Android, iOS, Web configured and testable

### NestJS Status
- Project initialized at: D:\MTFOODA\Code\Flutter apps\MyHome\backend
- Package.json: Created with typeorm, pg, class-validator, class-transformer
- app.module.ts: Created with TypeOrm configuration
- main.ts: Created with CORS and port 3000
- auth.module.ts: Created with local strategy, jwt strategy, and guards
- auth.service.ts: Created with login, register, validateUser methods
- auth.controller.ts: Created with login, register, profile endpoints
- auth.guard.ts: Created with JWT authentication guard
- user.entity.ts: Created with full property relationship support
- prisma.schema: Created with users, roles, properties, favorites, notifications tables
- Property service: Created with CRUD operations and validation
- Property controller: Created with CRUD endpoints and validation pipes
- Search service: Created with advanced filtering and pagination
- Installment validation: Frontend and backend calculation validation
- Media management: Photo upload, compression, and storage

### Docker Status
- Docker Compose configuration complete
- PostgreSQL service with persistent volumes configured
- Backend API service configured
- Network configuration documented for all platforms
- Health checks configured
- Automatic backups configured (05:00 local time)
- Restore scripts documented

### Design System Status
- Deep teal identity color (0xFF006D77) fully integrated across all screens
- Light and dark themes with full token support
- Typography scale with all text styles
- Spacing scale (8px base rhythm) implemented consistently
- Radius: consistent rounded corners (8px for cards, 4px for buttons)
- Elevation: shadow values for depth (0, 2, 4, 8) on all components
- Icon set: consistent iconography across all platforms
- Motion durations: purposeful page transitions, hero animations, skeleton loading
- Responsive breakpoints: mobile (360px), tablet (768px), desktop (1024px)

### Current Task
- Phase 3: Property Management - in progress
- Multi-step property creation form (7 steps)
- Property CRUD operations with validation
- Search and advanced filters with PostgreSQL efficiency
- Property media upload and management
- Installment calculations validation

### Next Task After Current
- Phase 4: Discovery (home, search, property details, favorites)
- Phase 5: Shared housing (roommate finder, groups)
- Phase 6: Communication (messaging, voice calls)
- Phase 7: Supporting features (maintenance, settings, help)
# MyHome - Implementation Progress

## Current Phase: Phase 2 - Authentication & Roles

### Documentation Status
- 00_MASTER_PLAN.md: Created and populated
- 01_PROJECT_REQUIREMENTS.md: Created and populated
- 02_PROJECT_ARCHITECTURE.md: Created and populated
- 03_FEATURE_REGISTRY.md: Created and populated
- 04_IMPLEMENTATION_ROADMAP.md: Created and populated
- AGENTS.md: Created in project root
- 14_AGENT_HANDOFF.md: In progress

### Flutter Status
- Project initialized: myhome_flutter (Flutter 3.47.7, Dart 3.13.5)
- Project located at: D:\MTFOODA\Code\Flutter apps\MyHome\myhome_flutter
- Pubspec.yaml: Configured with provider, get_it, localization, and other dependencies
- main.dart: Created with provider and locator setup
- Authentication: Login and registration screens implemented with Provider state management
- Onboarding: Role selection screen implemented
- State management: Using Provider with locator for dependency injection
- Network configuration: API base URL configured for all platforms
- Design System: Deep teal identity color, typography, spacing tokens integrated

### NestJS Status
- Project initialized at: D:\MTFOODA\Code\Flutter apps\MyHome\backend
- Package.json: Created with typeorm, pg, class-validator, class-transformer
- app.module.ts: Created with TypeOrm configuration for PostgreSQL
- main.ts: Created with CORS and port 3000
- auth.module.ts: Created with local strategy, jwt strategy, and guards
- auth.service.ts: Created with login, register, validateUser methods
- local.strategy.ts: Created with username/password validation
- jwt.strategy.ts: Created with JWT token generation and validation
- auth.controller.ts: Created with login, register, profile endpoints
- auth.guard.ts: Created with JWT authentication guard
- user.entity.ts: Created with id, name, email, password, role, timestamps
- Prisma schema planned with users, roles, permissions tables
- JWT configuration with access (1h) and refresh (7d) tokens
- Local strategy with username/password login
- Auth controller with login, register, profile endpoints

### Docker Status
- Docker Compose configuration in progress
- PostgreSQL service with persistent volumes configured
- Backend API service configured
- Network configuration documented for Android, iOS, Web, Windows, macOS, Linux
- Environment variables documented

### Design System Status
- Deep teal identity color (0xFF006D77) fully integrated
- Light and dark themes configured with all tokens
- Typography scale with text styles implemented
- Spacing scale (8px base rhythm) implemented across widgets
- Radius: consistent rounded corners (8px for cards, 4px for buttons)
- Elevation: shadow values for depth (0, 2, 4, 8) implemented
- Icon styles: consistent iconography set integrated
- Motion durations: purposeful animation durations implemented
- Responsive breakpoints: mobile, tablet, desktop configured

### Current Task
- Phase 2: Authentication & roles implementation - nearly complete
- Flutter: Login, registration, and onboarding screens
- NestJS: Full auth service with strategies, controller, and guards

### Next Task After Current
- Session management and email verification
- Role onboarding and profile setup
- Authorization guards enforcement
- Password reset and recovery flow
# MyHome - Implementation Progress

## Current Phase: Phase 2 - Authentication & Roles

### Documentation Status
- 00_MASTER_PLAN.md: Created and populated
- 01_PROJECT_REQUIREMENTS.md: Created and populated
- 02_PROJECT_ARCHITECTURE.md: Created and populated
- 03_FEATURE_REGISTRY.md: Created and populated
- 04_IMPLEMENTATION_ROADMAP.md: Created and populated
- AGENTS.md: Created in project root
- 14_AGENT_HANDOFF.md: In progress

### Flutter Status
- Project initialized: myhome_flutter (Flutter 3.47.7, Dart 3.13.5)
- Project located at: D:\MTFOODA\Code\Flutter apps\MyHome\myhome_flutter
- Pubspec.yaml: Configured with provider, get_it, localization, and other dependencies
- main.dart: Created with provider and locator setup
- Authentication: Login and registration screens implemented
- State management: Using Provider with locator for dependency injection
- Core structure complete with theme, localization, and error handling

### NestJS Status
- Project initialized at: D:\MTFOODA\Code\Flutter apps\MyHome\backend
- Package.json: Created with required dependencies (typeorm, pg, class-validator)
- app.module.ts: Created with TypeOrm configuration
- main.ts: Created with CORS and port 3000
- auth.module.ts: Created with local strategy, jwt strategy, and guards
- prisma.schema: Created with users, roles, permissions entities
- JWT configuration with access and refresh tokens
- Local strategy with username/password validation
- Strategy guard for public endpoints
- Auth service with login, register, findById, token methods
- Auth controller with login, register, refresh, logout endpoints
- CORS configured for Flutter web and mobile origins

### Docker Status
- Docker Compose configuration planned
- PostgreSQL service configured with persistent volumes
- Backend API service configured
- Network configuration documented for all platforms
- Environment variables documented

### Design System Status
- Deep teal identity color (0xFF006D77) defined
- Light and dark themes fully configured
- Typography scale with text styles for headings, body, captions
- Spacing scale (8px base rhythm) implemented
- Radius: consistent rounded corners (8px for cards, 4px for buttons)
- Elevation: shadow values for depth (0, 2, 4, 8)
- Icon styles: consistent iconography set
- Motion durations: purposeful animation durations (quick, normal, slow)
- Responsive breakpoints: mobile, tablet, desktop

### Current Task
- Phase 2: Authentication & roles implementation
- Flutter: Login and registration screens
- NestJS: Auth service, strategy, controller, and guards

### Next Task After Current
- Session management and email verification
- Role onboarding and profile setup
- Authorization guards for role-based access
# MyHome - Implementation Progress

## Current Phase: Phase 1 - Foundation

### Documentation Status
- 00_MASTER_PLAN.md: Created and populated
- 01_PROJECT_REQUIREMENTS.md: Created and populated
- 02_PROJECT_ARCHITECTURE.md: Created and populated
- 03_FEATURE_REGISTRY.md: Created and populated
- 04_IMPLEMENTATION_ROADMAP.md: Created and populated
- AGENTS.md: Created in project root
- 14_AGENT_HANDOFF.md: To be created

### Flutter Status
- Project initialized: myhome_flutter (Flutter 3.47.7, Dart 3.13.5)
- Project located at: D:\MTFOODA\Code\Flutter apps\MyHome\myhome_flutter
- Pubspec.yaml: Configured with required dependencies
- main.dart: Created with MyHome app entry
- Core structure:
  - core/config/theme_config.dart
  - core/config/locale_config.dart
  - core/di/locator.dart
  - core/error/failures.dart
- Design System: Deep teal identity color (0xFF006D77) defined
- Localization: ARB files structure prepared, Arabic and English supported
- Testing: Framework configured

### NestJS Status
- Project initialized at: D:\MTFOODA\Code\Flutter apps\MyHome\backend
- Package.json: Created with required dependencies
- app.module.ts: Created
- main.ts: Created
- config/database.config.ts: Created
- Structural foundation in place

### Docker Status
- Local Docker infrastructure planning started
- Will configure PostgreSQL and Docker Compose after NestJS initialization

### Design System Status
- Deep teal identity color (0xFF006D77) defined
- Light and dark themes configured
- Typography scale configured
- Spacing scale (8px base rhythm) defined
- Radius: rounded corners for cards and buttons
- Elevation: shadow values for depth
- Icon styles: consistent iconography
- Motion durations: purposeful animation durations

### Current Task
- Flutter foundation Phase 1 complete
- NestJS backend foundation in progress
- Begin Phase 2: Authentication & roles implementation

### Next Task After Current
- Authentication implementation (login, registration, role onboarding)
- Docker Compose configuration
- Database schema setup
# MyHome - Implementation Progress

## Current Phase: Phase 0 - Documentation & UI Analysis

### Documentation Status
- 00_MASTER_PLAN.md: Created and populated
- 01_PROJECT_REQUIREMENTS.md: Created and populated
- AGENTS.md: Created in project root
- 14_AGENT_HANDOFF.md: To be created

### UI Screenshot Analysis
- 7 screenshot groups identified
- Images found: about us.png, account profile.png, Chat Call.png, login register.png, navigation home search.png, room mate rooms widget.png, user guide.png

### Screens Identified (pending extraction)
- User Guide, How It Works, Property Types Explained, Key Features, FAQ
- Roommate Finder, Roommate Cards, Roommate Filters, Property Listing Cards, Property Details, Maintenance Services
- Message List, Conversation Details, Recent Calls, Messaging States, Calling Actions
- Profile, Account Settings, Help, FAQ, Edit Profile
- About Us, Company Information, Team Information, Location Information
- Home, Navigation Drawer, Search, Search Filters, Featured Properties, Bottom Navigation
- Login, Registration, Validation States, Success State, Password Recovery, Social Authentication UI

### Task Registry
- Total tasks planned: 100+ across 9 phases
- Phase 0 tasks: Documentation, UI analysis, architecture, inventories
- Phase 1 tasks: Foundation (Flutter, NestJS, Docker, DB, Design System)
- Current task: Creating documentation system

### Files Created So Far
- docs/00_MASTER_PLAN.md
- docs/01_PROJECT_REQUIREMENTS.md
- apps/ directory structure: Not yet created
- backend/ directory structure: Not yet created
- Flutter app: Not yet initialized

### Next Task
- Initialize Flutter from scratch (Phase 1 foundation)
- Initialize NestJS from scratch (Phase 1 foundation)
- Configure PostgreSQL and Docker (Phase 1 foundation)
- Configure dependency injection (Phase 1 foundation)
- Configure localization (Phase 1 foundation)
- Configure themes (Phase 1 foundation)
- Build Design System (Phase 1 foundation)
