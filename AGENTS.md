# AGENTS.md - MyHome Project

## Quick Reference for Future Agents

### Project Overview
MyHome is a real estate and shared-housing marketplace connecting verified property owners with people looking for apartments, private rentals, shared rentals, student accommodation, and expatriate accommodation.

### Essential Documents to Read First
1. **AGENTS.md** (this file) - Quick reference
2. **docs/00_MASTER_PLAN.md** - Complete master plan
3. **docs/05_IMPLEMENTATION_PROGRESS.md** - Current progress status
4. **docs/14_AGENT_HANDOFF.md** - Handoff details
5. **docs/13_FILE_CLASS_INVENTORY.md** - File class inventory
6. **docs/23_SOURCE_CODE_AUDIT.md** - Source code audit
7. **docs/24_ERROR_REPAIR_TRACKER.md** - Error repair tracker
8. **docs/25_BUILD_TEST_RESULTS.md** - Build and test results

### Project Structure
```
MyHome/
├── UI/                    # Original UI screenshot references
├── docs/                  # Documentation directory
├── myhome_flutter/        # Flutter application (actual path)
├── backend_fastapi/       # Active Python/FastAPI backend
├── infrastructure/        # Docker and infrastructure
└── artifacts/             # Local ignored screenshots and build logs
```

### Current Phase
Check docs/05_IMPLEMENTATION_PROGRESS.md for the current phase and task status.

### Current requirements and implementation (2026-11-17)
- Latest visual increment: read `docs/47_ARCHITECTURAL_HEADERS_AND_GUIDE_POSES.md`. Three local WebP architectural header backgrounds are integrated through AppScaffold with scene variants, theme tint/fade and decorative pointer/semantic exclusion. Four transparent guide poses alternate beside explanations in user guide/About; only intro page one has the duo. Explicit reduced-motion page jump fixes zero-duration animate assertion. 142 Flutter tests, clean analyzer/Ruff, 32 render previews; exact generation prompts/provenance in design/visuals/. No backend/schema change; head `20261116_fixed_admins`. Guide47 contains final delivery evidence and supersedes guide46's repeated-duo visual arrangement.
- Latest increment: read `docs/46_OPERATOR_DASHBOARD_GUIDES_AND_MOBILE.md`. Only fooda/amr are fixed admin usernames; other admins are inactive, sessions revoked, history preserved. No third-admin creation: staff form allows lawyer/reviewer and broker/field_agent only. Admin Home is a dashboard with red numeric review badges and no Favorites/My properties/groups/property inbox or listing ability. Profile password change checks old password, serializes login/change, revokes other sessions and audits. Transparent two-presenter first-run/replayable guides explain actual features. Native API defaults to stable HTTPS, Web same-origin; explicit overrides remain. Main/demo backed up and provisioned with data fingerprints unchanged except requested admin authority. Head `20261116_fixed_admins`; 130 Flutter / 142 PostgreSQL, 11 Worker tests, clean analyzer/Ruff, 20 render previews. See guide46 for actual build/public evidence. Older create-another-admin and emulator-default claims below are superseded.
- Latest operator increment: read `docs/45_ADMIN_ACCOUNTS_AND_MOBILE_SERVER.md`. Admin-only internal account creation supports administrator, lawyer/document_reviewer and broker/field_agent using the existing endpoint/profiles. Public signup cannot escalate. `tools/prepare_admin.py` reuses known active admin credentials or creates a separate operator without resetting/promoting existing users; local credentials are in ignored, ACL-restricted `admin/ADMIN_LOGIN.txt` and `admin/credentials.json`, never in Git/logs. Worker/Caddy block `/admin` root paths. `Start_MyHome_Mobile.cmd` uses shared `-Mobile -NoBrowser`: PostgreSQL/API/public sharing without Flutter/ADB/device/build. Existing Web/APK/data retained. Source checks: 121 Flutter / 137 PostgreSQL, 11 Worker tests, analyzer/Ruff clean and four admin render scenarios. No migration; see guide45 for actual runtime evidence.
- Latest correction: read `docs/44_IDENTITY_VALIDATION_AND_HOME_REFINEMENTS.md`. Language only in Profile (globe), guest Sign in/header account shortcut; Home results map removed; smaller horizontal picture/category labels. Unsigned floor input 0–100 and numeric quantity inputs. Precise validation and real-calendar national-ID/DOB matching; owner-only consent-gated nonpersistent `/identity/scan` with Arabic/English Tesseract, demo OCR enabled and final upload rechecks. Identity consent alone uses a native Checkbox. Finishing illustrations restored; distinct transparent Ultra artwork wired into review. 115 Flutter / 126 PostgreSQL tests, analyzer/Ruff clean, eight render scenarios. Head unchanged `20261116_finish_options`; see guide44 for actual delivery evidence and OCR limits.
- Latest increment: read `docs/43_PROPERTY_EXPERIENCE_AND_OPTIONAL_FEATURES.md`. Screenshot-based responsive photo gallery, final-price/contact sidebar, merged Features & utilities, visible similar listings and property-context chat with draft-only quick replies. Optional nullable compound/security/internet/garage/orientation/kitchen; Ultra Super Lux extends furnishing and filtering. Owner eye/bookmark counts are inside each card. Migration head `20261116_finish_options`; no reset/reseed. Source checks: 111 Flutter / 113 PostgreSQL tests, clean analyzer/Ruff, eight render scenarios. See guide43 for actual delivery evidence. Figma URL was empty; no exact Figma inspection is claimed.
- Latest increment: read `docs/42_ADDRESS_PROPERTY_DETAILS_AND_OWNER_ENGAGEMENT.md`. Mandatory new street/building/floor/unit and property_kind; preserve legacy NULLs. Migration head `20261116_address_engagement`, backups before rollout. Property details show final price and Buy/Rent + independent Contact owner, facts use matching pictures/captions underneath. My properties opens newest all-category/all-state three-row cursor list; owner-only distinct-visitor/save counts and saver-name contacts + property-chat inbox reuse existing moderation/encryption. Area attribution moves to About, OSM attribution stays on maps. Source verification: 99 Flutter / 101 PostgreSQL tests, clean analyzer/Ruff and four render scenarios. Check guide42 for build/public evidence and platform limits; no reset/reseed.
- Latest owner correction: read `docs/41_PICTURE_SELECTION_AND_FURNISHING_FILTER.md`. Use transparent distinct choice pictures alongside native tool icons, not blanket picture removal. SelectionTile replaces authored checkboxes/radio decorations while preserving explicit consent. Furnished filter appears for Lux/Super Lux and reaches the real boolean discovery query; NULL remains unknown. No new migration. Details and verified counts are in guide 41. The native-only rule in guide 40 below is superseded.
- Latest UI amendment: read `docs/40_RESPONSIVE_LAYOUT_AND_ICONS.md`. Manual title/description controls are removed; generated copy remains. Shared `AppLayout`/`AppScaffold` and viewport-aware theme scale all screens. Native `AppIcon`/distinct `FeatureSymbol` replace raster substitutions; atlases remain archived outside the Flutter bundle. Translation control shows target language. Current verification: 87 Flutter tests, 4 responsive render scenarios, analyzer clean. Older illustration instructions below are historical.

### Previous verified increment (2026-11-15)
- Read `docs/39_VISUAL_LISTING_AND_OPEN_MAPS.md` first for the latest increment: illustrated auto-copy listing flow, precise validation feedback, Add property in owner drawer, net/gross area, capacity only for shared housing, grouped utilities, conditional furnishing and protected owner covers. Current checks: 78 Flutter, 80 PostgreSQL, 11 Worker tests, 8 render tests; analyzer/Ruff clean. Web/APK and both local APIs updated.
- Map stack: FlutterMap 8.3.2 + open-source dragmarker/geolocator; no paid API/key/geocoding. Explicit device permission, independent validated coordinates, draggable pin, detail/current-page discovery maps, tile failure fallback. OSM attribution, native UA, normal HTTP caching, zero pan prefetch; configurable source via `/locations/map-config`. Keep the PC/Docker online for the Worker gateway.
- New migration head `20261116_listing_details`: nullable legacy area_measurement/furnished/location_url and optional nonshared capacity; 6,081 pinned open-data area records added, preserving old IDs. Main/demo backed up before additive migration. No reseed/reset. Data attribution/license is bundled in `backend_fastapi/app/data/` and the area selector. All remaining old reports below are historical snapshots.
- Latest increment: two-family owner/seeker onboarding without pricing; final listing step contains price, duration and automatic server calculator, with current-result gating. See `docs/37_ONBOARDING_AND_PRICE_CALCULATOR.md`. Existing fees/roles are preserved; no schema migration.
- Existing Cloudflare `myhome` Worker now serves as a stable gateway at `https://myhome.mohamed-fooda-mtf.workers.dev`. Web/API/Postgres remain local: keep PC/Docker online. `Deploy_Cloudflare.cmd` sets up publishing; normal Start reconnects automatically after initial setup. Node.js 22.12+/Wrangler auth required. See `docs/38_CLOUDFLARE_WORKER.md`; private deployment/source backups stay in ignored artifacts.
- One-click test startup: `Start_MyHome.cmd`, optional `-Android`, `-Local`, `-NoBrowser`, `-Rebuild`; stop with `Stop_MyHome.cmd`. See `docs/36_ONE_CLICK_DEMO.md`. Public HTTPS shares only demo-web/demo-api, with a same-origin `/api/v1`; PostgreSQL/main API stay private. Daily startup seeds only if empty and preserves user edits. Cache/logs/APK/share URL are ignored under `artifacts/`.
- Read `docs/35_ALL_IN_SUPERVISED_DEALS.md` before historical pricing/chat claims. All-in fees are approved and active: sale 1% total, half per party, frozen original-price reference; rent uses the documented duration schedule. Old rent uses a 12-month fee reference only, 3/4 month total and mandatory human legal eligibility. Special fees need both consents.
- Owner counts, remote title autocomplete, exact 3-item signed cursor pages, pause/restore, sold/rented history and favorite tombstones remain implemented.
- Supervised deal/viewing/offer/terms/document-review flows and a manually reconciled fee ledger exist. Staff profiles are created internally by admins. Real bank QR and reviewed legal terms are supplied through admin UI. Consent records are not a qualified signature or automatic legal validation.
- The owner chose server-inspected text followed by encryption at rest; this supersedes earlier E2EE message requirements. Trade and housing-group chats exist. Do not claim E2EE or perfect detection of arbitrary covert contact sharing. Calls/matching remain pending.
- Active API: Python/FastAPI, SQLAlchemy/Alembic in `backend_fastapi/`, PostgreSQL/Docker. Flutter uses Clean Architecture boundaries and Cubit/BLoC. Old NestJS was removed with authorization; preserve historical docs.
- Demo API 3001, database `myhome_demo`, UI 8081; random credentials ignored in `artifacts/demo-accounts.json`. `tools/start_demo.ps1` is isolated; `tools/smoke_demo.py` checks actual restricted-role HTTP operations. Ten accounts, 13 properties, one group, two conversations.
- Latest checks: 80 PostgreSQL tests, 78 Flutter tests, 11 Worker tests and 8 listing/onboarding/calculator render tests; analyzer/Ruff clean; Web/Android debug builds; actual Worker deployment and public auth/chat/permission/catalogue/map-link/private-photo HTTP smoke passed. Migration head `20261116_listing_details`; never reset volumes or real databases for tests. Backups/secrets/private media stay ignored. Browser GUI/physical-device testing is not claimed.
- Selected logo 02 remains installed; masters/prompts in `design/branding/selected/`. Preserve native icons and existing desktop runners. Web/Android/iOS are primary targets; iOS requires macOS. No complete marketplace phase is declared done.

### Historical audited baseline (2026-11-09)
- Current work is Phase 1/2, not completed property management. Authentication is implemented; property/search/media/chat/group modules remain pending.
- Read the current audit sections at the top of progress/handoff/build documents; historical status claims below them are superseded.
- Flutter uses Cubit; backend uses TypeORM with explicit migrations and no auto-sync. No Prisma implementation exists.
- Use `npm.cmd` on Windows. Setup, networking and test commands: `docs/28_LOCAL_DEVELOPMENT.md`.
- UI reference mapping: `docs/07_UI_SCREEN_SPECIFICATIONS.md`. Arabic status summary: `docs/27_CURRENT_STATE_AND_NEXT_STEPS.md`.

### How to Resume
1. Read docs/05_IMPLEMENTATION_PROGRESS.md to see current state
2. Read docs/14_AGENT_HANDOFF.md for last completed task and next task
3. Run relevant tests to verify state
4. Follow the implementation phases in order (Phase 0 through Phase 9)
5. Never mark a task DONE without verifying all criteria

### Task Tracking
- Tasks use ID format: AUTH-001, PROP-001, SEARCH-001, CHAT-001, GROUP-001
- Statuses: [ ] TODO, [-] IN PROGRESS, [x] DONE, [!] BLOCKED
- DONE comments: <!-- DONE: TASK_ID | Files: ... | Tests: ... | Verified: YYYY-MM-DD -->
- Track separately: UI, State management, Backend, Database, Security, Localization, Tests, Platform builds

### Critical Guidelines
- Never mark a partially implemented feature fully DONE
- Never delete task history
- Always update progress documents after verified tasks
- Inspect existing code before implementing - do not duplicate completed work
- All role permissions must be enforced on the backend
- Client-side role checks are only for UI presentation
- Use Arabic and English localization throughout
- Support all platforms: Android, iOS, Web, Windows, macOS, Linux

### Recent Changes
- docs/ created and populated with requirement documents
- UI screens identified from 7 screenshot groups
- Implementation phases defined in order

### Resume Commands
(Dependent on current phase - check progress document)
