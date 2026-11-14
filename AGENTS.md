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

### Current requirements and implementation (2026-11-14)
- Latest user scope is in `docs/29_PRODUCT_REQUIREMENTS_2026_11_14.md`; active setup is `docs/30_FASTAPI_LOCAL_SETUP.md`.
- Active API is Python/FastAPI with SQLAlchemy/Alembic in `backend_fastapi/`. The old NestJS `backend/` was removed at the user's request after migration; historical docs are retained.
- Flutter has public property discovery, protected details/favorites, multiple-intent onboarding, conditional roommate navigation, listing steps, private proof submission and reviewer UI.
- Shared housing application/group authorization exists; actual roommate matching, encrypted messaging and calls are NOT implemented.
- Current verified results: 28 Flutter tests, 19 PostgreSQL API tests, live Flutter/FastAPI authentication, synthetic real OCR, Web and Android debug builds. iOS build/runtime remains pending on macOS.
- Read the 2026-11-14 sections at the top of progress/handoff/test documents before historical reports. No full marketplace phase is complete.
- Primary release targets: Web, Android and iOS; preserve existing desktop runners.

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
