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

### Current requirements and implementation (2026-11-15)
- Latest increment: two-family owner/seeker onboarding without pricing; final listing step contains price, duration and automatic server calculator, with current-result gating. See `docs/37_ONBOARDING_AND_PRICE_CALCULATOR.md`. Existing fees/roles are preserved; no schema migration.
- Existing Cloudflare `myhome` Worker now serves as a stable gateway at `https://myhome.mohamed-fooda-mtf.workers.dev`. Web/API/Postgres remain local: keep PC/Docker online. `Deploy_Cloudflare.cmd` sets up publishing; normal Start reconnects automatically after initial setup. Node.js 22.12+/Wrangler auth required. See `docs/38_CLOUDFLARE_WORKER.md`; private deployment/source backups stay in ignored artifacts.
- One-click test startup: `Start_MyHome.cmd`, optional `-Android`, `-Local`, `-NoBrowser`, `-Rebuild`; stop with `Stop_MyHome.cmd`. See `docs/36_ONE_CLICK_DEMO.md`. Public HTTPS shares only demo-web/demo-api, with a same-origin `/api/v1`; PostgreSQL/main API stay private. Daily startup seeds only if empty and preserves user edits. Cache/logs/APK/share URL are ignored under `artifacts/`.
- Read `docs/35_ALL_IN_SUPERVISED_DEALS.md` before historical pricing/chat claims. All-in fees are approved and active: sale 1% total, half per party, frozen original-price reference; rent uses the documented duration schedule. Old rent uses a 12-month fee reference only, 3/4 month total and mandatory human legal eligibility. Special fees need both consents.
- Owner counts, remote title autocomplete, exact 3-item signed cursor pages, pause/restore, sold/rented history and favorite tombstones remain implemented.
- Supervised deal/viewing/offer/terms/document-review flows and a manually reconciled fee ledger exist. Staff profiles are created internally by admins. Real bank QR and reviewed legal terms are supplied through admin UI. Consent records are not a qualified signature or automatic legal validation.
- The owner chose server-inspected text followed by encryption at rest; this supersedes earlier E2EE message requirements. Trade and housing-group chats exist. Do not claim E2EE or perfect detection of arbitrary covert contact sharing. Calls/matching remain pending.
- Active API: Python/FastAPI, SQLAlchemy/Alembic in `backend_fastapi/`, PostgreSQL/Docker. Flutter uses Clean Architecture boundaries and Cubit/BLoC. Old NestJS was removed with authorization; preserve historical docs.
- Demo API 3001, database `myhome_demo`, UI 8081; random credentials ignored in `artifacts/demo-accounts.json`. `tools/start_demo.ps1` is isolated; `tools/smoke_demo.py` checks actual restricted-role HTTP operations. Ten accounts, 13 properties, one group, two conversations.
- Latest checks: 66 PostgreSQL tests, 58 Flutter tests, 11 Worker tests and 4 new onboarding/calculator preview renders; analyzer/Ruff clean; Web/Android debug builds; actual Worker deployment, public login/chat/permission/calculator HTTP smoke and repeat CMD startup passed. Migration head `20261115_communications`; never reset volumes or real databases for tests. Backups/secrets/private media stay ignored. Browser GUI/physical-device testing is not claimed.
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
