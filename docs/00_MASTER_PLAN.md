## Responsive layout and meaningful icons - 2026-11-16

The latest owner feedback replaces the all-raster icon rule: use distinct semantic native icons for controls and property types. Listing title/description are generated automatically; manual editing is removed. Responsive shared page widths and control sizes are applied throughout Flutter. Backend permissions, all-in pricing and open maps are preserved.

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

## Approved all-in pricing, supervised deals and moderated chat - 2026-11-15

This section supersedes the preview-only and E2EE-message statements below, retained as history. The owner approved fixed original-price fees split equally, server-inspected text encrypted at rest, and mandatory legal eligibility for old rent. Read [the current implementation and operating guide](35_ALL_IN_SUPERVISED_DEALS.md).

Verified: 56 real PostgreSQL tests, 43 Flutter tests, 6 preview-render tests; analyzer/Ruff clean; Web and Android debug builds passed. Main/demo additive migrations applied after a private DB backup, both APIs healthy. Isolated demo: 10 accounts, 13 listings, one shared group, an open deal and two encrypted conversations; actual restricted-role HTTP smoke passed. iOS requires macOS. No full marketplace phase is declared complete.

Calls, roommate matching and production banking/signature integrations remain pending. Explicit consent is recorded, not a certified signature. Operators supply reviewed terms, qualified staff and the real InstaPay QR through admin UI. The server can inspect messages; this is not E2EE.

---

# Current product/stack amendment — 2026-11-14
<!-- CURRENT_AUDIT_2026_11_14 -->
The latest explicit request uses Flutter Clean Architecture with Cubit/BLoC, Python/FastAPI, local PostgreSQL and Docker, with Web/Android/iOS as primary release targets. This supersedes earlier NestJS/TypeORM/Prisma implementation plans.
Use 29_PRODUCT_REQUIREMENTS_2026_11_14.md for current user requirements and 30_FASTAPI_LOCAL_SETUP.md for startup. Public property home, protected detail/favorites, multiple needs with active mode, conditional roommate search, private ID/proof review and separate E2EE communication are the current product rules.
Some property/discovery/shared-housing slices now exist, but no full phase is complete. See current audited progress. Old plans below are preserved.

---


# MyHome - Master Plan

## Project Overview
MyHome is a trusted real estate and shared-housing marketplace that connects verified property owners with people looking for apartments, private rentals, shared rentals, student accommodation, and expatriate accommodation.

## Market
- Initial market: Egypt, EGP
- Designed to support Egyptian governorates, cities, districts
- Designed for future geographic expansion

## Core Features
- Property discovery (search, filters, categories)
- Property creation and management
- Roommate matching and housing groups
- Secure private messaging
- Encrypted voice calling
- Maintenance services
- Owner verification
- Administration dashboard

## User Roles
- Guest: Browse public listings and search
- Regular User: Search, save favorites, compare, contact owners, submit inquiries
- Student: Search student housing, create roommate preferences, request shared accommodation
- Expatriate: Search housing, create roommate preferences, request shared accommodation
- Property Owner: Manage verified properties, publish listings after approval, manage inquiries, create shared-housing groups
- Maintenance Provider: Manage verified maintenance services and assigned requests
- Administrator: Manage verification, listing moderation, reports, platform settings

## Implementation Phases
- Phase 0: Documentation & UI analysis
- Phase 1: Foundation (Flutter, NestJS, Docker, DB, Design System)
- Phase 2: Authentication & roles
- Phase 3: Property management
- Phase 4: Discovery (home, search, filters, details)
- Phase 5: Shared housing (roommate finder, groups)
- Phase 6: Communication (messaging, voice calling)
- Phase 7: Supporting features (maintenance, settings, help)
- Phase 8: Administration
- Phase 9: Quality & release

## Screenshot Groups Analyzed
1. user guide.png - User guide, how it works, property types, key features, FAQ
2. room mate rooms widget.png - Roommate finder, roommate cards, filters, property listing cards, property details, maintenance services
3. Chat Call.png - Message list, conversation details, recent calls, messaging states, calling actions
4. account profile.png - Profile, account settings, help, FAQ, edit profile
5. about us.png - About us, company information, team information, location information
6. navigation home search.png - Home, navigation drawer, search, search filters, featured properties, bottom navigation
7. login register.png - Login, registration, validation states, success state, password recovery, social authentication UI

## UI Screens Identified
See `07_UI_SCREEN_SPECIFICATIONS.md` for the seven reference groups, current implementations, visual evidence and remaining requirements (audited 2026-11-09). Current status is at the top of `05_IMPLEMENTATION_PROGRESS.md`; historical phase-completion claims are superseded there.

## Design System
- Deep teal identity color
- Clean white surfaces
- Soft neutral backgrounds
- Rounded cards
- Elegant property photography
- Subtle shadows
- Clear typography
- Spacious layouts
- Consistent iconography

## Architecture
- Clean Architecture boundaries
- Separation of business logic from widgets
- Dependency injection
- Database access abstracted from Flutter
- BLoC for complex event-driven workflows
- Cubit for simpler state transitions

## Target Platforms
- Android
- iOS
- Web
- Windows
- macOS
- Linux

## Security Requirements
- Owner identity verification
- Role-based authorization (server-enforced)
- Object-level authorization
- Secure sessions
- Audit logging
- Data encryption for messaging and voice calls

## Testing Requirements
- Unit tests
- Widget tests
- BLoC/Cubit tests
- Repository tests
- API tests
- Database integration tests
- Authorization tests
- Security tests
- Localization tests
- Navigation tests
- Responsive tests

## Agent Handoff
- AGENTS.md in project root
- docs/14_AGENT_HANDOFF.md
- All task statuses tracked with DONE comments
- Progress documented in docs/05_IMPLEMENTATION_PROGRESS.md
