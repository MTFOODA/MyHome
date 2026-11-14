# Current architecture — 2026-11-14
<!-- CURRENT_AUDIT_2026_11_14 -->
Explicit user instruction supersedes the prior TypeORM retention decision. The active API is backend_fastapi/ with FastAPI, SQLAlchemy, PostgreSQL and additive Alembic migrations. Legacy backend/ NestJS source is retained, not active.
Flutter separates domain repository contracts, Dio data adapters and Cubit/BLoC presentation. DiscoveryBloc handles concurrent search; AuthCubit/SettingsCubit/ListingCubit handle their own workflows. Flutter does not connect directly to PostgreSQL.
Normalized user intents and an independent persona replace a single-role product model. Sessions/current database authorization are checked server-side. Private documents and public listing media have separate access paths. E2EE message/call services are future separate modules, not a plaintext extension of group metadata.
The Python API currently uses modular routers/services/policies with direct SQLAlchemy sessions; full Python domain repository abstraction remains future refactoring.
Primary releases are Web/Android/iOS. Existing desktop runners remain preserved. Detailed current inventory and tests are at the top of docs/13 and docs/25.

---


# MyHome — Implemented architecture decision (2026-11-09)
<!-- CURRENT_AUDIT_2026_11_09 -->
The current application is at myhome_flutter/ (not apps/myhome_flutter/).
Flutter now uses Cubit via flutter_bloc, get_it, typed domain repository interfaces, Dio data implementations and generated Arabic/English localization. SharedPreferences holds display preferences; flutter_secure_storage holds only the refresh token; access tokens are memory-only.
Backend currently uses NestJS 11, Passport, JWT and TypeORM 0.3 with PostgreSQL. TypeORM was already the direction of the existing source; it is retained as the single ORM to avoid maintaining parallel data-access stacks. The original Prisma technology choice below remains historical and is not an implemented dependency. Explicit migrations replace synchronize=true.
Authentication is wired through DTOs, guards, service, repository injection and database sessions. Other business modules remain future work; the backend is not yet fully layered into domain/repository adapters.
Docker runs a separate admin migration job and a non-superuser application connection. Native runners exist for six platforms, but only Web and Android debug have been built.
Screen guidance: 07_UI_SCREEN_SPECIFICATIONS.md. Current evidence: 25_BUILD_TEST_RESULTS.md.

---

## Original architecture plan and history

# MyHome - Project Architecture

## Overview
MyHome follows Clean Architecture with separated concerns and dependency injection. The application is divided into layers with clear boundaries.

## Architecture Layers

### 1. Flutter App (Presentation Layer)
- Widgets and UI components
- BLoC/Cubit state management
- User-facing screens/pages
- Localization and theming
- Platform-specific code

### 2. Flutter Core Layer
- **config/**: Application configuration, themes, routes
- **core/**: Shared utilities, errors, network security, localization
- **di/**: Dependency injection setup
- **errors/**: Error classes and handlers
- **network/**: Network utilities, API client
- **security/**: Security constants, encryption helpers
- **theme/**: Color tokens, typography, spacing
- **localization/**: ARB files, locale handling
- **utils/**: Helper functions and extensions

### 3. Flutter Features (Feature Layer)
Each feature follows the structure:
- data/: datasources, models, repositories
- domain/: entities, repositories, usecases
- presentation/: bloc/cubit, pages, widgets

### 4. NestJS Backend (Server Layer)
- Modules separated by business responsibility
- Controllers, services, providers
- Prisma database integration
- REST APIs and authenticated WebSockets
- Guard clauses for authorization

### 5. Database (PostgreSQL)
- Normalized schema with UUIDs
- Foreign key constraints
- Indexes for performance
- Safe deletion policies
- Migration system with Prisma

### 6. Infrastructure (Docker)
- Docker Compose for service orchestration
- PostgreSQL with persistent volumes
- Backend API service
- Optional Redis for caching

## Key Principles

### Clean Architecture Boundaries
- Business logic out of widgets
- Database access out of Flutter
- Dependency injection throughout
- No circular dependencies
- Features kept independent

### Dependency Flow
- Flutter -> Core -> Features -> (optional) Backend
- Backend -> Database
- No backward flow

### Error Handling
- Flutter: Error widgets, try/catch, user-friendly messages
- NestJS: Exception filters, HTTP exceptions, proper status codes
- Shared error types between backend and frontend where needed

### State Management
- BLoC for complex event-driven workflows (property search, messaging)
- Cubit for simpler state transitions (profile settings, form states)
- Never mix business logic with widget build methods
- State classes are immutable where possible

## File Organization

### Flutter lib/ Structure
```
lib/
├── app/
├── core/
│   ├── config/
│   ├── constants/
│   ├── di/
│   ├── errors/
│   ├── network/
│   ├── security/
│   ├── theme/
│   ├── localization/
│   └── utils/
├── shared/
│   ├── widgets/
│   ├── animations/
│   └── extensions/
└── features/
    ├── auth/
    ├── onboarding/
    ├── properties/
    ├── property_search/
    ├── favorites/
    ├── roommates/
    ├── messaging/
    ├── voice_calls/
    ├── housing_groups/
    ├── maintenance/
    ├── profiles/
    ├── notifications/
    ├── settings/
    └── admin/
```

### NestJS Modules
```
src/
├── common/
│   ├── decorators/
│   ├── guards/
│   ├── pipes/
│   └── interceptors/
├── config/
├── database/
├── security/
├── realtime/
└── modules/
    ├── auth/
    ├── users/
    ├── properties/
    ├── messaging/
    ├── groups/
    ├── maintenance/
    ├── notifications/
    └── admin/
```

## Design System Integration
- Color tokens: deep teal identity, clean white, soft neutral backgrounds
- Typography scale with clear hierarchy
- Spacing scale (8px base rhythm)
- Radius: consistent rounded corners
- Elevation: shadow values for depth
- Icon styles: consistent iconography
- Motion durations: purposeful animations
- Responsive breakpoints for different layouts

## Database Design Principles
- Normalized schema (avoid unrestricted JSON)
- UUIDs for primary keys
- Foreign keys with proper constraints
- Check constraints for data validation
- Indexes on frequently queried columns
- Timestamps on all tables
- Safe deletion policies (soft delete)
- Transactions for multi-entity operations

## Security Architecture
- Role-based authorization (server-enforced)
- Object-level authorization
- Secure document storage
- Rate limiting at API level
- Audit logging for all mutations
- Distinguish: identity verified, ownership verified, listing approved
- Never grant verification merely for selecting owner role

## Testing Architecture
- Unit tests for services and utilities
- Widget tests for UI components
- BLoC/Cubit tests for state management
- Repository tests for data layer
- API tests for endpoint validation
- Database integration tests
- Authorization and security tests
- Localization tests
- Navigation and responsive tests