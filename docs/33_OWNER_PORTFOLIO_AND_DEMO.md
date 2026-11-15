## Approved all-in pricing, supervised deals and moderated chat - 2026-11-15

This section supersedes the preview-only and E2EE-message statements below, retained as history. The owner approved fixed original-price fees split equally, server-inspected text encrypted at rest, and mandatory legal eligibility for old rent. Read [the current implementation and operating guide](35_ALL_IN_SUPERVISED_DEALS.md).

Verified: 56 real PostgreSQL tests, 43 Flutter tests, 6 preview-render tests; analyzer/Ruff clean; Web and Android debug builds passed. Main/demo additive migrations applied after a private DB backup, both APIs healthy. Isolated demo: 10 accounts, 13 listings, one shared group, an open deal and two encrypted conversations; actual restricted-role HTTP smoke passed. iOS requires macOS. No full marketplace phase is declared complete.

Calls, roommate matching and production banking/signature integrations remain pending. Explicit consent is recorded, not a certified signature. Operators supply reviewed terms, qualified staff and the real InstaPay QR through admin UI. The server can inspect messages; this is not E2EE.

---

# Owner portfolio and isolated demo — 2026-11-14

## Current delivered slice

Every signed-in user can open **My properties / عقاراتي**. Cards are grouped into sale (cash + installments), private rental and shared rental. Selected owner intents appear even with zero listings; historical owned categories remain readable after role removal. Each card separates current, publicly published, paused, awaiting-review/draft and completed counts.

Selecting a card opens current listings and a History segment, remote quick-search autocomplete, visibility filter and scroll loading. The database returns **three rows per request**. Signed cursors bind the page to the authenticated owner, category, scope and filters. `(created_at,id)` keyset paging prevents OFFSET skips when earlier listings move into history; history uses `(closed_at,id)`. Row ownership and role/category permissions are enforced server-side.

The eye button pauses/restores an approved open listing without removing its approval. Public discovery, direct detail access, new favorites, public photo URLs and new shared-housing applications stop exposing paused listings. Closing as sold/rented checks the category, records an audited timestamp, moves the listing into history and prevents reopening, editing, attaching photos or resubmitting the archived listing. Closing a shared listing sets available beds to zero. Existing group/tenancy records remain intact.

Existing favorites retain a safe unavailable card. Snapshot title/category/price are captured at save time, so subsequent unpublished edits cannot leak through favorites. Paused/sold/rented labels remain visible to saved viewers; unavailable photos, description, owner and precise details are withheld. Unrelated viewers receive 404. Owners can still retrieve their own listing photographs through the authenticated private-media route.

Group membership metadata can now be listed through `GET /groups`; owners and active tenants see their groups, while outsiders see none. Flutter exposes **My housing groups / مجموعات السكن**. This is membership metadata only: no messaging transport is claimed.

## API and implementation

- `GET /properties/mine/overview`: grouped server counts.
- `GET /properties/mine/page?group=sale&scope=current`: exactly 3 listings and `next_cursor`; scope also accepts `history`.
- `GET /properties/mine/suggestions`: at most 8 owner-scoped autocomplete titles.
- `PUT /properties/{id}/availability`: active / paused / sold / rented, with ownership, approval and terminal-state checks.
- `POST /pricing/quote`: authoritative fee preview; [proposed policy and configuration](34_COMMISSION_PROPOSAL.md).
- Additive Alembic revision `20261115_portfolio`; existing prices and favorites are backfilled without dropping records. Runtime role privileges are retained.
- Flutter: owner dashboard, OwnerListingsCubit, paged list, shared PropertySummary availability state and PriceQuotePanel.

## Demo setup and actual results

The synthetic fixtures live in **myhome_demo**, not the application database or automated-test database. Separate signing/document keys, API port 3001 and private-media volume are used. The seed tool refuses any database other than `/myhome_demo`. It contains no real property, real ID document or seeded known administrator password. Fixture publication/verification flags are explicit CLI-only synthetic setup, not evidence of document review; that workflow is tested separately in the PostgreSQL suite.

Start normal PostgreSQL first, install `backend_fastapi/requirements-dev.txt` into the backend virtual environment, then from the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/start_demo.ps1
cd myhome_flutter
flutter run -d chrome --web-port 8081 --dart-define=API_BASE_URL=http://localhost:3001/api/v1
```

Credentials are random per account and saved only in ignored `artifacts/demo-accounts.json`. Do not commit/share that file. `artifacts/demo-scenario-results.json` contains the local report. Re-running the seed reuses untouched fixtures; it never resets/deletes a database. If you alter fixtures interactively, the expected-count checks can intentionally fail rather than overwrite your changes.

| Scenario | Verified data/result |
|---|---|
| Accounts | 8: two owners, three shared-rental users (student/expatriate/roommate), saved-property viewer, outsider and reviewer |
| Properties | 13 synthetic listings across the four property categories |
| Main owner's current dashboard | 5 sale, 3 private rental, 1 shared rental |
| History | One sold sale and one completed private rental |
| Pagination | Sale page returns 3, then 2; owner isolation verified |
| Favorites | Active, paused, sold and rented states retained |
| Shared group | Owner + two accepted tenants; student is tenant co-admin |
| Runtime smoke | Actual Docker API with restricted DB role: login, pages, favorites, group privacy and logout passed |
| Conversations | **Not created/tested:** E2EE messaging/calling is not implemented; no plaintext or simulated conversation is presented as real |

The standalone group metadata and existing housing-application authorization are tested. Complete membership removal/key lifecycle, E2EE conversations/calls and matching remain future work.

## Validation and limits

33 Flutter tests; analyzer clean; Web and Android debug builds; 25 real PostgreSQL tests including cursor isolation, terminal states, saved snapshots, hidden-media authorization and commission configuration. AR/EN dashboard/list previews are in `docs/screenshots/owner-*.png`. iOS build/runtime remains unverified on Windows. This increment does not complete the listing edit/resume/delete workflow, payments or E2EE communication.
