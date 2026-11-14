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
