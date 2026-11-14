# Current roadmap — 2026-11-14
<!-- CURRENT_AUDIT_2026_11_14 -->
Latest user instruction changes the backend to FastAPI and defines public home/multiple-role behavior; see docs/29. Current API/setup is docs/30.
Verified increments cover FastAPI adoption/auth, multiple intents, public discovery with protected actions, structured listing/proof submission and review, and an initial shared-application/group-authorization slice.

Next:
1. Complete missing original property fields, persistent draft edit/resume/delete flows and feature-level QA.
2. Implement opt-in roommate profiles/preferences and actual server filtering; the current shared-only screen is an honest empty shell.
3. Implement email verification, password recovery and complete profile/account lifecycle.
4. Implement separately audited E2EE messaging/calling and device/group-key revocation; membership metadata alone is not communication.
5. Complete original support/admin modules, backup/media/key recovery, retention/cleanup, release audit and native devices/iOS build.

No entire phase has met all original acceptance criteria. Earlier roadmap below remains history; do not follow NestJS startup instructions.

---


# MyHome — Implementation roadmap
Updated: 2026-11-09. The audited status in 05_IMPLEMENTATION_PROGRESS.md takes precedence over historical logs.

| Phase | Status | Remaining acceptance work |
|---|---|---|
| 0 — Documentation and UI analysis | [-] | Seven reference groups mapped in 07_UI_SCREEN_SPECIFICATIONS.md; extend per-feature specifications before implementing them. |
| 1 — Foundation | [-] | Flutter/NestJS runnable; migrations and test infrastructure exist. Finish backup/restore verification, native builds and CI. |
| 2 — Authentication and roles | [-] | Registration/login/refresh/logout/profile implemented. Email verification, recovery, editable profile and private owner verification workflow remain. |
| 3 — Property management | [ ] | Structured schema, ownership checks, seven-step form, media access controls, rental/installment/shared validation. |
| 4 — Discovery | [-] UI shell only | Server filtering, sorting, pagination, listing details/gallery, persistent favorites, saved searches, comparison and inquiries. |
| 5 — Shared housing | [ ] | Preferences, matching, applications, transactional bed availability, membership and revocation. |
| 6 — Communication | [ ] | Audited E2EE library integration, device keys, encrypted attachments, authorized sockets, calling and notifications. |
| 7 — Supporting features | [-] | Introductory guide/about and preferences exist. Full FAQ, maintenance requests, reviews and account lifecycle remain. |
| 8 — Administration | [ ] | Owner review, listing moderation, reports and audit events. No public admin self-registration. |
| 9 — Quality/release | [ ] | Full authorization/integration/security tests, platform matrix, accessibility, performance and backup recovery. |

## Execution order
1. Finish Phase 1 operational verification and Phase 2 recovery/verification/profile flows.
2. Implement private owner verification submission/review before opening property publishing.
3. Implement Phase 3 from docs/01_PROJECT_REQUIREMENTS.md, including every mandatory field and explicit Yes/No answers without preselection.
4. Connect discovery to approved, publicly visible listings using indexed PostgreSQL queries. Do not substitute client-side filtering or sample data for a search backend.
5. Implement shared housing, then communication, supporting features and administration in dependency order.

Every feature must record UI, state, backend, database, security, localization, tests and builds separately. Backend guard tests for publishing currently use test-only routes; the production property endpoints do not exist yet and must apply the guards themselves.
